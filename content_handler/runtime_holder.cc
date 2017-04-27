// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/runtime_holder.h"

#include <dlfcn.h>
#include <magenta/dlfcn.h>
#include <utility>

#include "application/lib/app/connect.h"
#include "dart/runtime/include/dart_api.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/common/threads.h"
#include "flutter/content_handler/rasterizer.h"
#include "flutter/content_handler/service_protocol_hooks.h"
#include "flutter/lib/snapshot/snapshot.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/runtime/asset_font_selector.h"
#include "flutter/runtime/dart_controller.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/runtime_init.h"
#include "lib/fidl/dart/sdk_ext/src/natives.h"
#include "lib/ftl/functional/make_copyable.h"
#include "lib/ftl/logging.h"
#include "lib/ftl/time/time_delta.h"
#include "lib/mtl/vmo/vector.h"
#include "lib/tonic/mx/mx_converter.h"
#include "lib/zip/create_unzipper.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/rapidjson/rapidjson/stringbuffer.h"
#include "third_party/rapidjson/rapidjson/writer.h"

using tonic::DartConverter;
using tonic::ToDart;

namespace flutter_runner {
namespace {

constexpr char kKernelKey[] = "kernel_blob.bin";
constexpr char kSnapshotKey[] = "snapshot_blob.bin";
constexpr char kDylibKey[] = "libapp.so";
constexpr char kAssetChannel[] = "flutter/assets";

// Maximum number of frames in flight.
constexpr int kMaxPipelineDepth = 3;

// When the max pipeline depth is exceeded, drain to this number of frames
// to recover before acknowleding the invalidation and scheduling more frames.
constexpr int kRecoveryPipelineDepth = 1;

blink::PointerData::Change GetChangeFromPointerEventPhase(
    mozart::PointerEvent::Phase phase) {
  switch (phase) {
    case mozart::PointerEvent::Phase::ADD:
      return blink::PointerData::Change::kAdd;
    case mozart::PointerEvent::Phase::HOVER:
      return blink::PointerData::Change::kHover;
    case mozart::PointerEvent::Phase::DOWN:
      return blink::PointerData::Change::kDown;
    case mozart::PointerEvent::Phase::MOVE:
      return blink::PointerData::Change::kMove;
    case mozart::PointerEvent::Phase::UP:
      return blink::PointerData::Change::kUp;
    case mozart::PointerEvent::Phase::REMOVE:
      return blink::PointerData::Change::kRemove;
    case mozart::PointerEvent::Phase::CANCEL:
      return blink::PointerData::Change::kCancel;
    default:
      return blink::PointerData::Change::kCancel;
  }
}

blink::PointerData::DeviceKind GetKindFromPointerType(
    mozart::PointerEvent::Type type) {
  switch (type) {
    case mozart::PointerEvent::Type::TOUCH:
      return blink::PointerData::DeviceKind::kTouch;
    case mozart::PointerEvent::Type::MOUSE:
      return blink::PointerData::DeviceKind::kMouse;
    default:
      return blink::PointerData::DeviceKind::kTouch;
  }
}

}  // namespace

RuntimeHolder::RuntimeHolder()
    : view_listener_binding_(this),
      input_listener_binding_(this),
      weak_factory_(this) {}

RuntimeHolder::~RuntimeHolder() {
  blink::Threads::Gpu()->PostTask(
      ftl::MakeCopyable([rasterizer = std::move(rasterizer_)](){
          // Deletes rasterizer.
      }));
}

void RuntimeHolder::Init(
    fidl::InterfaceHandle<app::ApplicationEnvironment> environment,
    fidl::InterfaceRequest<app::ServiceProvider> outgoing_services,
    std::vector<char> bundle) {
  FTL_DCHECK(!rasterizer_);
  rasterizer_ = Rasterizer::Create();
  FTL_DCHECK(rasterizer_);

  environment_.Bind(std::move(environment));
  environment_->GetServices(fidl::GetProxy(&environment_services_));
  ConnectToService(environment_services_.get(), fidl::GetProxy(&view_manager_));
  outgoing_services_ = std::move(outgoing_services);

  InitRootBundle(std::move(bundle));

  const uint8_t* vm_snapshot_data;
  const uint8_t* vm_snapshot_instr;
  const uint8_t* default_isolate_snapshot_data;
  const uint8_t* default_isolate_snapshot_instr;
  if (!Dart_IsPrecompiledRuntime()) {
    vm_snapshot_data = ::kDartVmSnapshotData;
    vm_snapshot_instr = ::kDartVmSnapshotInstructions;
    default_isolate_snapshot_data = ::kDartIsolateCoreSnapshotData;
    default_isolate_snapshot_instr = ::kDartIsolateCoreSnapshotInstructions;
  } else {
    std::vector<uint8_t> dylib_blob;
    if (!asset_store_->GetAsBuffer(kDylibKey, &dylib_blob)) {
      FTL_LOG(ERROR) << "Failed to extract app dylib";
      return;
    }

    mx::vmo dylib_vmo;
    if (!mtl::VmoFromVector(dylib_blob, &dylib_vmo)) {
      FTL_LOG(ERROR) << "Failed to load app dylib";
      return;
    }

    dlerror();
    dylib_handle_ = dlopen_vmo(dylib_vmo.get(), RTLD_LAZY);
    if (dylib_handle_ == nullptr) {
      FTL_LOG(ERROR) << "dlopen failed: " << dlerror();
      return;
    }
    vm_snapshot_data = reinterpret_cast<const uint8_t*>(
        dlsym(dylib_handle_, "_kDartVmSnapshotData"));
    vm_snapshot_instr = reinterpret_cast<const uint8_t*>(
        dlsym(dylib_handle_, "_kDartVmSnapshotInstructions"));
    default_isolate_snapshot_data = reinterpret_cast<const uint8_t*>(
        dlsym(dylib_handle_, "_kDartIsolateSnapshotData"));
    default_isolate_snapshot_instr = reinterpret_cast<const uint8_t*>(
        dlsym(dylib_handle_, "_kDartIsolateSnapshotInstructions"));
  }

  // TODO(rmacnak): We should generate the AOT vm snapshot separately from
  // each app so we can initialize before receiving the first app bundle.
  static bool first_app = true;
  if (first_app) {
    first_app = false;
    blink::InitRuntime(vm_snapshot_data, vm_snapshot_instr,
                       default_isolate_snapshot_data,
                       default_isolate_snapshot_instr);

    blink::SetRegisterNativeServiceProtocolExtensionHook(
        ServiceProtocolHooks::RegisterHooks);
  }
}

void RuntimeHolder::CreateView(
    const std::string& script_uri,
    fidl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
    fidl::InterfaceRequest<app::ServiceProvider> services) {
  if (view_listener_binding_.is_bound()) {
    // TODO(jeffbrown): Refactor this to support multiple view instances
    // sharing the same underlying root bundle (but with different runtimes).
    FTL_LOG(ERROR) << "The view has already been created.";
    return;
  }

  std::vector<uint8_t> kernel;
  std::vector<uint8_t> snapshot;
  if (!Dart_IsPrecompiledRuntime()) {
    if (!asset_store_->GetAsBuffer(kKernelKey, &kernel) &&
        !asset_store_->GetAsBuffer(kSnapshotKey, &snapshot)) {
      FTL_LOG(ERROR) << "Unable to load kernel or snapshot from root bundle.";
      return;
    }
  }

  mozart::ViewListenerPtr view_listener;
  view_listener_binding_.Bind(fidl::GetProxy(&view_listener));
  view_manager_->CreateView(fidl::GetProxy(&view_),
                            std::move(view_owner_request),
                            std::move(view_listener), script_uri);

  app::ServiceProviderPtr view_services;
  view_->GetServiceProvider(GetProxy(&view_services));

  // Listen for input events.
  ConnectToService(view_services.get(), GetProxy(&input_connection_));
  mozart::InputListenerPtr input_listener;
  input_listener_binding_.Bind(GetProxy(&input_listener));
  input_connection_->SetEventListener(std::move(input_listener));

  mozart::ScenePtr scene;
  view_->CreateScene(fidl::GetProxy(&scene));
  blink::Threads::Gpu()->PostTask(ftl::MakeCopyable([
    rasterizer = rasterizer_.get(), scene = std::move(scene)
  ]() mutable { rasterizer->SetScene(std::move(scene)); }));

  runtime_ = blink::RuntimeController::Create(this);

  const uint8_t* isolate_snapshot_data;
  const uint8_t* isolate_snapshot_instr;
  if (!Dart_IsPrecompiledRuntime()) {
    isolate_snapshot_data = ::kDartIsolateCoreSnapshotData;
    isolate_snapshot_instr = ::kDartIsolateCoreSnapshotInstructions;
  } else {
    isolate_snapshot_data = reinterpret_cast<const uint8_t*>(
        dlsym(dylib_handle_, "_kDartIsolateSnapshotData"));
    isolate_snapshot_instr = reinterpret_cast<const uint8_t*>(
        dlsym(dylib_handle_, "_kDartIsolateSnapshotInstructions"));
  }
  runtime_->CreateDartController(script_uri, isolate_snapshot_data,
                                 isolate_snapshot_instr);

  runtime_->SetViewportMetrics(viewport_metrics_);

  if (Dart_IsPrecompiledRuntime()) {
    runtime_->dart_controller()->RunFromPrecompiledSnapshot();
  } else if (!kernel.empty()) {
    runtime_->dart_controller()->RunFromKernel(kernel.data(), kernel.size());
  } else {
    runtime_->dart_controller()->RunFromScriptSnapshot(snapshot.data(),
                                                       snapshot.size());
  }
}

Dart_Port RuntimeHolder::GetUIIsolateMainPort() {
  if (!runtime_)
    return ILLEGAL_PORT;
  return runtime_->GetMainPort();
}

std::string RuntimeHolder::GetUIIsolateName() {
  if (!runtime_) {
    return "";
  }
  return runtime_->GetIsolateName();
}

void RuntimeHolder::ScheduleFrame() {
  if (pending_invalidation_ || deferred_invalidation_callback_)
    return;
  pending_invalidation_ = true;
  view_->Invalidate();
}

void RuntimeHolder::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!is_ready_to_draw_)
    return;  // Only draw once per frame.
  is_ready_to_draw_ = false;

  layer_tree->set_frame_size(SkISize::Make(viewport_metrics_.physical_width,
                                           viewport_metrics_.physical_height));
  layer_tree->set_scene_version(scene_version_);

  blink::Threads::Gpu()->PostTask(ftl::MakeCopyable([
    rasterizer = rasterizer_.get(), layer_tree = std::move(layer_tree),
    self = GetWeakPtr()
  ]() mutable {
    rasterizer->Draw(std::move(layer_tree), [self]() {
      if (self)
        self->OnFrameComplete();
    });
  }));
}

void RuntimeHolder::UpdateSemantics(std::vector<blink::SemanticsNode> update) {}

void RuntimeHolder::HandlePlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kAssetChannel) {
    HandleAssetPlatformMessage(std::move(message));
    return;
  }
  if (auto response = message->response())
    response->CompleteEmpty();
}

void RuntimeHolder::DidCreateMainIsolate(Dart_Isolate isolate) {
  if (asset_store_)
    blink::AssetFontSelector::Install(asset_store_);
  InitFidlInternal();
  InitMozartInternal();
}

void RuntimeHolder::InitFidlInternal() {
  fidl::InterfaceHandle<app::ApplicationEnvironment> environment;
  environment_->Duplicate(GetProxy(&environment));

  Dart_Handle fidl_internal = Dart_LookupLibrary(ToDart("dart:fidl.internal"));

  DART_CHECK_VALID(Dart_SetNativeResolver(
      fidl_internal, fidl::dart::NativeLookup, fidl::dart::NativeSymbol));

  DART_CHECK_VALID(Dart_SetField(
      fidl_internal, ToDart("_environment"),
      DartConverter<mx::channel>::ToDart(environment.PassHandle())));

  DART_CHECK_VALID(Dart_SetField(
      fidl_internal, ToDart("_outgoingServices"),
      DartConverter<mx::channel>::ToDart(outgoing_services_.PassChannel())));
}

void RuntimeHolder::InitMozartInternal() {
  fidl::InterfaceHandle<mozart::ViewContainer> view_container;
  view_->GetContainer(fidl::GetProxy(&view_container));

  Dart_Handle mozart_internal =
      Dart_LookupLibrary(ToDart("dart:mozart.internal"));

  DART_CHECK_VALID(Dart_SetField(
      mozart_internal, ToDart("_viewContainer"),
      DartConverter<mx::channel>::ToDart(view_container.PassHandle())));
}

void RuntimeHolder::InitRootBundle(std::vector<char> bundle) {
  root_bundle_data_ = std::move(bundle);
  asset_store_ = ftl::MakeRefCounted<blink::ZipAssetStore>(
      GetUnzipperProviderForRootBundle());
}

void RuntimeHolder::HandleAssetPlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  ftl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (!response)
    return;
  const auto& data = message->data();
  std::string asset_name(reinterpret_cast<const char*>(data.data()),
                         data.size());
  std::vector<uint8_t> asset_data;
  if (asset_store_ && asset_store_->GetAsBuffer(asset_name, &asset_data)) {
    response->Complete(std::move(asset_data));
  } else {
    response->CompleteEmpty();
  }
}

blink::UnzipperProvider RuntimeHolder::GetUnzipperProviderForRootBundle() {
  return [self = GetWeakPtr()]() {
    if (!self)
      return zip::UniqueUnzipper();
    return zip::CreateUnzipper(&self->root_bundle_data_);
  };
}

void RuntimeHolder::OnEvent(mozart::InputEventPtr event,
                            const OnEventCallback& callback) {
  bool handled = false;
  if (event->is_pointer()) {
    const mozart::PointerEventPtr& pointer = event->get_pointer();
    blink::PointerData pointer_data;
    pointer_data.time_stamp = pointer->event_time;
    pointer_data.change = GetChangeFromPointerEventPhase(pointer->phase);
    pointer_data.kind = GetKindFromPointerType(pointer->type);
    pointer_data.device = pointer->pointer_id;
    pointer_data.physical_x = pointer->x;
    pointer_data.physical_y = pointer->y;

    switch (pointer_data.change) {
      case blink::PointerData::Change::kDown:
        down_pointers_.insert(pointer_data.device);
        break;
      case blink::PointerData::Change::kCancel:
      case blink::PointerData::Change::kUp:
        down_pointers_.erase(pointer_data.device);
        break;
      case blink::PointerData::Change::kMove:
        if (down_pointers_.count(pointer_data.device) == 0)
          pointer_data.change = blink::PointerData::Change::kHover;
        break;
      case blink::PointerData::Change::kAdd:
      case blink::PointerData::Change::kRemove:
      case blink::PointerData::Change::kHover:
        FTL_DCHECK(down_pointers_.count(pointer_data.device) == 0);
        break;
    }

    blink::PointerDataPacket packet(1);
    packet.SetPointerData(0, pointer_data);
    runtime_->DispatchPointerDataPacket(packet);

    handled = true;
  } else if (event->is_keyboard()) {
    const mozart::KeyboardEventPtr& keyboard = event->get_keyboard();
    const char* type = nullptr;
    if (keyboard->phase == mozart::KeyboardEvent::Phase::PRESSED)
      type = "keydown";
    else if (keyboard->phase == mozart::KeyboardEvent::Phase::REPEAT)
      type = "keydown";  // TODO change this to keyrepeat
    else if (keyboard->phase == mozart::KeyboardEvent::Phase::RELEASED)
      type = "keyup";

    if (type) {
      rapidjson::Document document;
      auto& allocator = document.GetAllocator();
      document.SetObject();
      document.AddMember("type", rapidjson::Value(type, strlen(type)),
                         allocator);
      document.AddMember("keymap", rapidjson::Value("fuchsia"), allocator);
      document.AddMember("hidUsage", keyboard->hid_usage, allocator);
      document.AddMember("codePoint", keyboard->code_point, allocator);
      document.AddMember("modifiers", keyboard->modifiers, allocator);
      rapidjson::StringBuffer buffer;
      rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
      document.Accept(writer);

      const uint8_t* data =
          reinterpret_cast<const uint8_t*>(buffer.GetString());
      runtime_->DispatchPlatformMessage(
          ftl::MakeRefCounted<blink::PlatformMessage>(
              "flutter/keyevent",
              std::vector<uint8_t>(data, data + buffer.GetSize()), nullptr));
      handled = true;
    }
  }
  callback(handled);
}

void RuntimeHolder::OnInvalidation(mozart::ViewInvalidationPtr invalidation,
                                   const OnInvalidationCallback& callback) {
  FTL_DCHECK(invalidation);
  pending_invalidation_ = false;

  // Apply view property changes.
  if (invalidation->properties) {
    view_properties_ = std::move(invalidation->properties);
    viewport_metrics_.physical_width =
        view_properties_->view_layout->size->width;
    viewport_metrics_.physical_height =
        view_properties_->view_layout->size->height;
    viewport_metrics_.device_pixel_ratio = 2.0;
    // TODO(abarth): Use view_properties_->display_metrics->device_pixel_ratio
    // once that's reasonable.
    runtime_->SetViewportMetrics(viewport_metrics_);
  }

  // Remember the scene version for rendering.
  scene_version_ = invalidation->scene_version;

  // TODO(jeffbrown): Flow the frame time through the rendering pipeline.
  if (outstanding_requests_ >= kMaxPipelineDepth) {
    FTL_DCHECK(!deferred_invalidation_callback_);
    deferred_invalidation_callback_ = callback;
    return;
  }

  ++outstanding_requests_;
  BeginFrame();

  // TODO(jeffbrown): Consider running the callback earlier.
  // Note that this may result in the view processing stale view properties
  // (such as size) if it prematurely acks the frame but takes too long
  // to handle it.
  callback();
}

ftl::WeakPtr<RuntimeHolder> RuntimeHolder::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void RuntimeHolder::BeginFrame() {
  FTL_DCHECK(outstanding_requests_ > 0);
  FTL_DCHECK(outstanding_requests_ <= kMaxPipelineDepth)
      << outstanding_requests_;

  FTL_DCHECK(!is_ready_to_draw_);
  is_ready_to_draw_ = true;
  runtime_->BeginFrame(ftl::TimePoint::Now());
  const bool was_ready_to_draw = is_ready_to_draw_;
  is_ready_to_draw_ = false;

  // If we were still ready to draw when done with the frame, that means we
  // didn't draw anything this frame and we should acknowledge the frame
  // ourselves instead of waiting for the rasterizer to acknowledge it.
  if (was_ready_to_draw)
    OnFrameComplete();
}

void RuntimeHolder::OnFrameComplete() {
  FTL_DCHECK(outstanding_requests_ > 0);
  --outstanding_requests_;

  if (deferred_invalidation_callback_ &&
      outstanding_requests_ <= kRecoveryPipelineDepth) {
    // Schedule frame first to avoid potentially generating a second
    // invalidation in case the view manager already has one pending
    // awaiting acknowledgement of the deferred invalidation.
    OnInvalidationCallback callback =
        std::move(deferred_invalidation_callback_);
    ScheduleFrame();
    callback();
  }
}

}  // namespace flutter_runner
