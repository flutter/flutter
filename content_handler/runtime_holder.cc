// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/runtime_holder.h"

#include <dlfcn.h>
#include <fcntl.h>
#include <fdio/namespace.h>
#include <zircon/dlfcn.h>
#include <utility>

#include "dart-pkg/zircon/sdk_ext/handle.h"
#include "flutter/assets/zip_asset_store.h"
#include "flutter/common/threads.h"
#include "flutter/content_handler/accessibility_bridge.h"
#include "flutter/content_handler/rasterizer.h"
#include "flutter/content_handler/service_protocol_hooks.h"
#include "flutter/lib/snapshot/snapshot.h"
#include "flutter/lib/ui/window/pointer_data_packet.h"
#include "flutter/runtime/asset_font_selector.h"
#include "flutter/runtime/dart_controller.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/runtime_init.h"
#include "lib/app/cpp/connect.h"
#include "lib/fsl/vmo/vector.h"
#include "lib/fxl/files/path.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/functional/make_copyable.h"
#include "lib/fxl/logging.h"
#include "lib/fxl/time/time_delta.h"
#include "lib/tonic/logging/dart_error.h"
#include "lib/zip/create_unzipper.h"
#include "third_party/dart/runtime/include/dart_api.h"
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
constexpr char kKeyEventChannel[] = "flutter/keyevent";
constexpr char kTextInputChannel[] = "flutter/textinput";
constexpr char kFlutterPlatformChannel[] = "flutter/platform";
constexpr char kFuchsiaPackageResourceDirectory[] = "pkg/data";
constexpr char kDartPkgContentsKey[] = "dart-pkg/contents";

void SetThreadName(fxl::RefPtr<fxl::TaskRunner> runner, std::string name) {
  runner->PostTask([name]() {
    zx::thread::self().set_property(ZX_PROP_NAME, name.c_str(), name.size());
    Dart_SetThreadName(name.c_str());
  });
}

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
      text_input_binding_(this),
      weak_factory_(this) {}

RuntimeHolder::~RuntimeHolder() {
  blink::Threads::Gpu()->PostTask(
      fxl::MakeCopyable([rasterizer = std::move(rasterizer_)](){
          // Deletes rasterizer.
      }));
}

void RuntimeHolder::Init(
    fdio_ns_t* namespc,
    std::unique_ptr<app::ApplicationContext> context,
    f1dl::InterfaceRequest<app::ServiceProvider> outgoing_services,
    std::vector<char> bundle) {
  FXL_DCHECK(!rasterizer_);
  rasterizer_ = Rasterizer::Create();
  FXL_DCHECK(rasterizer_);

  namespc_ = namespc;
  dirfd_ = fdio_ns_opendir(namespc);
  if (dirfd_ == -1) {
    FXL_LOG(ERROR) << "Failed to get fd for namespace";
    return;
  }
  context_ = std::move(context);
  outgoing_services_ = std::move(outgoing_services);

  context_->ConnectToEnvironmentService(view_manager_.NewRequest());

  // TODO(zarah): remove bundle entirely once flx is removed.
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
    if (!GetAssetAsBuffer(kDylibKey, &dylib_blob)) {
      FXL_LOG(ERROR) << "Failed to extract app dylib";
      return;
    }

    fsl::SizedVmo dylib_vmo;
    if (!fsl::VmoFromVector(dylib_blob, &dylib_vmo)) {
      FXL_LOG(ERROR) << "Failed to load app dylib";
      return;
    }

    dlerror();
    dylib_handle_ = dlopen_vmo(dylib_vmo.vmo().get(), RTLD_LAZY);
    if (dylib_handle_ == nullptr) {
      FXL_LOG(ERROR) << "dlopen failed: " << dlerror();
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
                       default_isolate_snapshot_instr,
                       /* bundle_path = */ "");

    // This has to happen after the Dart runtime is initialized.
    SetThreadName(blink::Threads::UI(), "ui");
    SetThreadName(blink::Threads::Gpu(), "gpu");
    SetThreadName(blink::Threads::IO(), "io");

    blink::SetRegisterNativeServiceProtocolExtensionHook(
        ServiceProtocolHooks::RegisterHooks);
  }

  accessibility_bridge_ = std::make_unique<AccessibilityBridge>(context_.get());
}

void RuntimeHolder::CreateView(
    const std::string& script_uri,
    f1dl::InterfaceRequest<mozart::ViewOwner> view_owner_request,
    f1dl::InterfaceRequest<app::ServiceProvider> services) {
  if (view_listener_binding_.is_bound()) {
    // TODO(jeffbrown): Refactor this to support multiple view instances
    // sharing the same underlying root bundle (but with different runtimes).
    FXL_LOG(ERROR) << "The view has already been created.";
    return;
  }

  std::vector<uint8_t> kernel;
  std::vector<uint8_t> snapshot;
  bool maybe_running_from_source = false;
  if (!Dart_IsPrecompiledRuntime()) {
    if (!GetAssetAsBuffer(kKernelKey, &kernel) &&
        !GetAssetAsBuffer(kSnapshotKey, &snapshot)) {
      maybe_running_from_source = true;
      FXL_LOG(INFO) << "No kernel or snapshot in root bundle.";
    }
  }

  // Create the view.
  zx::eventpair import_token, export_token;
  zx_status_t status = zx::eventpair::create(0u, &import_token, &export_token);
  if (status != ZX_OK) {
    FXL_LOG(ERROR) << "Could not create an event pair.";
    return;
  }
  mozart::ViewListenerPtr view_listener;
  view_listener_binding_.Bind(view_listener.NewRequest());
  view_manager_->CreateView(view_.NewRequest(),             // view
                            std::move(view_owner_request),  // view owner
                            std::move(view_listener),       // view listener
                            std::move(export_token),        // export token
                            script_uri                      // diagnostic label
  );
  app::ServiceProviderPtr view_services;
  view_->GetServiceProvider(view_services.NewRequest());

  // Listen for input events.
  ConnectToService(view_services.get(), input_connection_.NewRequest());
  mozart::InputListenerPtr input_listener;
  input_listener_binding_.Bind(input_listener.NewRequest());
  input_connection_->SetEventListener(std::move(input_listener));

  // Setup the session.
  f1dl::InterfaceHandle<ui::Scenic> scenic;
  view_manager_->GetScenic(scenic.NewRequest());

  blink::Threads::Gpu()->PostTask(fxl::MakeCopyable([
    rasterizer = rasterizer_.get(),            //
    scenic = std::move(scenic),  //
    import_token = std::move(import_token),    //
    weak_runtime_holder = GetWeakPtr()
  ]() mutable {
    ASSERT_IS_GPU_THREAD;
    rasterizer->SetScene(
        std::move(scenic), std::move(import_token),
        // TODO(MZ-222): Ideally we would immediately redraw the previous layer
        // tree when the metrics change since there's no need to rerecord it.
        // However, we want to make sure there's only one outstanding frame.
        // We should improve the frame scheduling so that the rasterizer thread
        // can self-schedule re-rasterization.
        [weak_runtime_holder] {
          // This is on the GPU thread thread. Post to the Platform/UI
          // thread for the completion callback.
          ASSERT_IS_GPU_THREAD;
          blink::Threads::Platform()->PostTask([weak_runtime_holder]() {
            // On the Platform/UI thread.
            ASSERT_IS_UI_THREAD;
            if (weak_runtime_holder) {
              weak_runtime_holder->OnRedrawFrame();
            }
          });
        });
  }));
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
                                 isolate_snapshot_instr, dirfd_);

  runtime_->SetViewportMetrics(viewport_metrics_);

  if (Dart_IsPrecompiledRuntime()) {
    runtime_->dart_controller()->RunFromPrecompiledSnapshot();
  } else if (!kernel.empty()) {
    runtime_->dart_controller()->RunFromKernel(std::move(kernel));
  } else if (maybe_running_from_source) {
    std::vector<uint8_t> data;
    if (!GetAssetAsBuffer(kDartPkgContentsKey, &data)) {
      FXL_LOG(ERROR) << "Contents file not found for " << script_uri;
      return;
    }
    std::string package_name(data.begin(), data.end());
    std::string main_dart = "pkg/data/dart-pkg/" + package_name + "/lib/main.dart";
    FXL_LOG(INFO) << "Running from source with entrypoint: '" << main_dart
                  << "'";
    runtime_->dart_controller()->RunFromSource(main_dart, "pkg/data/dart-pkg/.packages");
  } else {
    runtime_->dart_controller()->RunFromScriptSnapshot(snapshot.data(),
                                                       snapshot.size());
  }

  runtime_->dart_controller()->dart_state()->SetReturnCodeCallback(
      [this](int32_t return_code) { return_code_ = return_code; });
}

Dart_Port RuntimeHolder::GetUIIsolateMainPort() {
  if (!runtime_)
    return ILLEGAL_PORT;
  return runtime_->GetMainPort();
}

void RuntimeHolder::DidShutdownMainIsolate() {
  if (main_isolate_shutdown_callback_) {
    main_isolate_shutdown_callback_();
  }
}

void RuntimeHolder::SetMainIsolateShutdownCallback(
    std::function<void()> callback) {
  main_isolate_shutdown_callback_ = callback;
}

std::string RuntimeHolder::GetUIIsolateName() {
  if (!runtime_) {
    return "";
  }
  return runtime_->GetIsolateName();
}

std::string RuntimeHolder::DefaultRouteName() {
  return "/";
}

void RuntimeHolder::ScheduleFrame(bool regenerate_layer_tree) {
  ASSERT_IS_UI_THREAD;
  // TODO(mravn): We assume regenerate_layer_tree is true (and thus ignore
  // that we may be able to reuse the current layer tree.)
  if (!frame_scheduled_) {
    frame_scheduled_ = true;
    if (!frame_outstanding_)
      PostBeginFrame();
  }
}

void RuntimeHolder::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!frame_outstanding_ || frame_rendering_) {
    // TODO(MZ-193): We probably shouldn't be discarding the layer tree here.
    // But then, Flutter shouldn't be calling Render() if we didn't call
    // BeginFrame().
    return;  // Spurious.
  }

  frame_rendering_ = true;

  layer_tree->set_construction_time(fxl::TimePoint::Now() -
                                    last_begin_frame_time_);
  layer_tree->set_frame_size(SkISize::Make(viewport_metrics_.physical_width,
                                           viewport_metrics_.physical_height));
  layer_tree->set_device_pixel_ratio(viewport_metrics_.device_pixel_ratio);

  // We are on the Platform/UI thread. Post to the GPU thread to render.
  ASSERT_IS_PLATFORM_THREAD;
  blink::Threads::Gpu()->PostTask(fxl::MakeCopyable([
    rasterizer = rasterizer_.get(),      //
    layer_tree = std::move(layer_tree),  //
    weak_runtime_holder = GetWeakPtr()   //
  ]() mutable {
    // On the GPU Thread.
    ASSERT_IS_GPU_THREAD;
    rasterizer->Draw(std::move(layer_tree), [weak_runtime_holder]() {
      // This is on the GPU thread thread. Post to the Platform/UI thread
      // for the completion callback.
      ASSERT_IS_GPU_THREAD;
      blink::Threads::Platform()->PostTask([weak_runtime_holder]() {
        // On the Platform/UI thread.
        ASSERT_IS_UI_THREAD;
        if (weak_runtime_holder) {
          weak_runtime_holder->frame_rendering_ = false;
          weak_runtime_holder->OnFrameComplete();
        }
      });
    });
  }));
}

void RuntimeHolder::UpdateSemantics(blink::SemanticsNodeUpdates update) {
  accessibility_bridge_->UpdateSemantics(update);
}

void RuntimeHolder::HandlePlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kAssetChannel) {
    if (HandleAssetPlatformMessage(message.get()))
      return;
  } else if (message->channel() == kTextInputChannel) {
    if (HandleTextInputPlatformMessage(message.get()))
      return;
  } else if (message->channel() == kFlutterPlatformChannel) {
    if (HandleFlutterPlatformMessage(message.get()))
      return;
  }
  if (auto response = message->response())
    response->CompleteEmpty();
}

void RuntimeHolder::DidCreateMainIsolate(Dart_Isolate isolate) {
  if (asset_provider_) {
    blink::AssetFontSelector::Install(asset_provider_);
  } else if (asset_store_) {
    blink::AssetFontSelector::Install(asset_store_);
  }
  InitDartIoInternal();
  InitFuchsia();
  InitZircon();
  InitScenicInternal();
}

void RuntimeHolder::InitDartIoInternal() {
  Dart_Handle io_lib = Dart_LookupLibrary(ToDart("dart:io"));

  // Set up the namespace.
  Dart_Handle namespace_type =
      Dart_GetType(io_lib, ToDart("_Namespace"), 0, nullptr);
  DART_CHECK_VALID(namespace_type);
  Dart_Handle namespace_args[1];
  namespace_args[0] = Dart_NewInteger(reinterpret_cast<intptr_t>(namespc_));
  DART_CHECK_VALID(namespace_args[0]);
  DART_CHECK_VALID(Dart_Invoke(namespace_type, ToDart("_setupNamespace"), 1,
                               namespace_args));

  // Disable dart:io exit()
  Dart_Handle embedder_config_type =
      Dart_GetType(io_lib, ToDart("_EmbedderConfig"), 0, nullptr);
  DART_CHECK_VALID(embedder_config_type);
  DART_CHECK_VALID(
      Dart_SetField(embedder_config_type, ToDart("_mayExit"), Dart_False()));
}

void RuntimeHolder::InitFuchsia() {
  f1dl::InterfaceHandle<app::ApplicationEnvironment> environment;
  context_->ConnectToEnvironmentService(environment.NewRequest());
  fuchsia::dart::Initialize(std::move(environment),
                            std::move(outgoing_services_));

  app::ServiceProviderPtr parent_env_service_provider;
  context_->environment()->GetServices(
      parent_env_service_provider.NewRequest());
  ConnectToService(parent_env_service_provider.get(), clipboard_.NewRequest());
}

void RuntimeHolder::InitZircon() {
  Dart_Handle zircon_lib = Dart_LookupLibrary(ToDart("dart:zircon"));
  DART_CHECK_VALID(zircon_lib);

  Dart_Handle namespace_type =
      Dart_GetType(zircon_lib, ToDart("_Namespace"), 0, nullptr);
  DART_CHECK_VALID(namespace_type);
  DART_CHECK_VALID(Dart_SetField(namespace_type, ToDart("_namespace"),
                                 ToDart(reinterpret_cast<intptr_t>(namespc_))));
}

void RuntimeHolder::InitScenicInternal() {
  f1dl::InterfaceHandle<mozart::ViewContainer> view_container;
  view_->GetContainer(view_container.NewRequest());

  Dart_Handle mozart_internal =
      Dart_LookupLibrary(ToDart("dart:mozart.internal"));

  DART_CHECK_VALID(Dart_SetNativeResolver(mozart_internal, mozart::NativeLookup,
                                          mozart::NativeSymbol));

  DART_CHECK_VALID(
      Dart_SetField(mozart_internal, ToDart("_context"),
                    DartConverter<uint64_t>::ToDart(reinterpret_cast<intptr_t>(
                        static_cast<mozart::NativesDelegate*>(this)))));

  DART_CHECK_VALID(Dart_SetField(mozart_internal, ToDart("_viewContainer"),
                                 ToDart(zircon::dart::Handle::Create(
                                     view_container.TakeChannel().release()))));
}

void RuntimeHolder::InitRootBundle(std::vector<char> bundle) {
  if (!bundle.empty()) {
    root_bundle_data_ = std::move(bundle);
    asset_store_ = fxl::MakeRefCounted<blink::ZipAssetStore>(
        GetUnzipperProviderForRootBundle());
  } else {
    fxl::UniqueFD root_dir(fdio_ns_opendir(namespc_));
    if (!root_dir.is_valid()) {
      FXL_LOG(ERROR) << "Unable to load root dir";
      return;
    }
    fxl::UniqueFD data_dir(openat(root_dir.get(),
                                  kFuchsiaPackageResourceDirectory,
                                  O_RDONLY | O_DIRECTORY));
    if (!data_dir.is_valid()) {
      FXL_LOG(ERROR) << "Unable to load data dir";
      return;
    }
    asset_provider_ =
        fxl::MakeRefCounted<blink::DirectoryAssetBundle>(std::move(data_dir));
  }
}

mozart::View* RuntimeHolder::GetMozartView() {
  return view_.get();
}

bool RuntimeHolder::HandleAssetPlatformMessage(
    blink::PlatformMessage* message) {
  fxl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (!response)
    return false;
  const auto& data = message->data();
  std::string asset_name(reinterpret_cast<const char*>(data.data()),
                         data.size());
  std::vector<uint8_t> asset_data;
  if (GetAssetAsBuffer(asset_name, &asset_data)) {
    response->Complete(std::move(asset_data));
  } else {
    response->CompleteEmpty();
  }
  return true;
}

bool RuntimeHolder::GetAssetAsBuffer(const std::string& name,
                                     std::vector<uint8_t>* data) {
  return (asset_provider_ &&
          asset_provider_->GetAsBuffer(name, data)) ||
         (asset_store_ && asset_store_->GetAsBuffer(name, data));
}

bool RuntimeHolder::HandleFlutterPlatformMessage(
    blink::PlatformMessage* message) {
  const auto& data = message->data();
  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject()) {
    return false;
  }

  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || !method->value.IsString()) {
    return false;
  }

  fxl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (method->value == "Clipboard.setData") {
    auto text = root["args"]["text"].GetString();
    clipboard_->Push(text);
    response->CompleteEmpty();
  } else if (method->value == "Clipboard.getData") {
    clipboard_->Peek([response](const ::f1dl::String& text) {
      rapidjson::StringBuffer json_buffer;
      rapidjson::Writer<rapidjson::StringBuffer> writer(json_buffer);
      writer.StartArray();
      writer.StartObject();
      writer.Key("text");
      writer.String(text);
      writer.EndObject();
      writer.EndArray();

      std::string result = json_buffer.GetString();
      response->Complete(std::vector<uint8_t>{result.begin(), result.end()});
    });
  } else {
    response->CompleteEmpty();
  }
  return true;
}

bool RuntimeHolder::HandleTextInputPlatformMessage(
    blink::PlatformMessage* message) {
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || !method->value.IsString())
    return false;

  if (method->value == "TextInput.show") {
    if (input_method_editor_) {
      input_method_editor_->Show();
    }
  } else if (method->value == "TextInput.hide") {
    if (input_method_editor_) {
      input_method_editor_->Hide();
    }
  } else if (method->value == "TextInput.setClient") {
    current_text_input_client_ = 0;
    if (text_input_binding_.is_bound())
      text_input_binding_.Unbind();
    input_method_editor_ = nullptr;

    auto args = root.FindMember("args");
    if (args == root.MemberEnd() || !args->value.IsArray() ||
        args->value.Size() != 2)
      return false;
    const auto& configuration = args->value[1];
    if (!configuration.IsObject())
      return false;
    // TODO(abarth): Read the keyboard type form the configuration.
    current_text_input_client_ = args->value[0].GetInt();
    mozart::TextInputStatePtr state = mozart::TextInputState::New();
    state->text = std::string();
    state->selection = mozart::TextSelection::New();
    state->composing = mozart::TextRange::New();
    input_connection_->GetInputMethodEditor(
        mozart::KeyboardType::TEXT, mozart::InputMethodAction::DONE,
        std::move(state), text_input_binding_.NewBinding(),
        input_method_editor_.NewRequest());
  } else if (method->value == "TextInput.setEditingState") {
    if (input_method_editor_) {
      auto args_it = root.FindMember("args");
      if (args_it == root.MemberEnd() || !args_it->value.IsObject())
        return false;
      const auto& args = args_it->value;
      mozart::TextInputStatePtr state = mozart::TextInputState::New();
      state->selection = mozart::TextSelection::New();
      state->composing = mozart::TextRange::New();
      // TODO(abarth): Deserialize state.
      auto text = args.FindMember("text");
      if (text != args.MemberEnd() && text->value.IsString())
        state->text = text->value.GetString();
      auto selection_base = args.FindMember("selectionBase");
      if (selection_base != args.MemberEnd() && selection_base->value.IsInt())
        state->selection->base = selection_base->value.GetInt();
      auto selection_extent = args.FindMember("selectionExtent");
      if (selection_extent != args.MemberEnd() &&
          selection_extent->value.IsInt())
        state->selection->extent = selection_extent->value.GetInt();
      auto selection_affinity = args.FindMember("selectionAffinity");
      if (selection_affinity != args.MemberEnd() &&
          selection_affinity->value.IsString() &&
          selection_affinity->value == "TextAffinity.upstream")
        state->selection->affinity = mozart::TextAffinity::UPSTREAM;
      else
        state->selection->affinity = mozart::TextAffinity::DOWNSTREAM;
      // We ignore selectionIsDirectional because that concept doesn't exist on
      // Fuchsia.
      auto composing_base = args.FindMember("composingBase");
      if (composing_base != args.MemberEnd() && composing_base->value.IsInt())
        state->composing->start = composing_base->value.GetInt();
      auto composing_extent = args.FindMember("composingExtent");
      if (composing_extent != args.MemberEnd() &&
          composing_extent->value.IsInt())
        state->composing->end = composing_extent->value.GetInt();
      input_method_editor_->SetState(std::move(state));
    }
  } else if (method->value == "TextInput.clearClient") {
    current_text_input_client_ = 0;
    if (text_input_binding_.is_bound())
      text_input_binding_.Unbind();
    input_method_editor_ = nullptr;
  } else {
    FXL_DLOG(ERROR) << "Unknown " << kTextInputChannel << " method "
                    << method->value.GetString();
  }

  return false;
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
    pointer_data.time_stamp = pointer->event_time / 1000;
    pointer_data.change = GetChangeFromPointerEventPhase(pointer->phase);
    pointer_data.kind = GetKindFromPointerType(pointer->type);
    pointer_data.device = pointer->pointer_id;
    pointer_data.physical_x = pointer->x * viewport_metrics_.device_pixel_ratio;
    pointer_data.physical_y = pointer->y * viewport_metrics_.device_pixel_ratio;
    // Buttons are single bit values starting with kMousePrimaryButton = 1.
    pointer_data.buttons = static_cast<uint64_t>(pointer->buttons);

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
        if (down_pointers_.count(pointer_data.device) != 0) {
          FXL_DLOG(ERROR) << "Received add event for down pointer.";
        }
        break;
      case blink::PointerData::Change::kRemove:
        if (down_pointers_.count(pointer_data.device) != 0) {
          FXL_DLOG(ERROR) << "Received remove event for down pointer.";
        }
        break;
      case blink::PointerData::Change::kHover:
        if (down_pointers_.count(pointer_data.device) != 0) {
          FXL_DLOG(ERROR) << "Received hover event for down pointer.";
        }
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
          fxl::MakeRefCounted<blink::PlatformMessage>(
              kKeyEventChannel,
              std::vector<uint8_t>(data, data + buffer.GetSize()), nullptr));
      handled = true;
    }
  }
  callback(handled);
}

void RuntimeHolder::OnPropertiesChanged(
    mozart::ViewPropertiesPtr properties,
    const OnPropertiesChangedCallback& callback) {
  FXL_DCHECK(properties);

  // Attempt to read the device pixel ratio.
  float pixel_ratio = 1.f;
  if (auto& metrics = properties->display_metrics) {
    pixel_ratio = metrics->device_pixel_ratio;
  }

  // Apply view property changes.
  if (auto& layout = properties->view_layout) {
    viewport_metrics_.physical_width = layout->size->width * pixel_ratio;
    viewport_metrics_.physical_height = layout->size->height * pixel_ratio;
    viewport_metrics_.physical_padding_top = layout->inset->top * pixel_ratio;
    viewport_metrics_.physical_padding_right =
        layout->inset->right * pixel_ratio;
    viewport_metrics_.physical_padding_bottom =
        layout->inset->bottom * pixel_ratio;
    viewport_metrics_.physical_padding_left = layout->inset->left * pixel_ratio;
    viewport_metrics_.device_pixel_ratio = pixel_ratio;
    runtime_->SetViewportMetrics(viewport_metrics_);
  }

  ScheduleFrame();

  callback();
}

void RuntimeHolder::DidUpdateState(mozart::TextInputStatePtr state,
                                   mozart::InputEventPtr event) {
  rapidjson::Document document;
  auto& allocator = document.GetAllocator();

  rapidjson::Value encoded_state(rapidjson::kObjectType);
  encoded_state.AddMember("text", state->text.get(), allocator);
  encoded_state.AddMember("selectionBase", state->selection->base, allocator);
  encoded_state.AddMember("selectionExtent", state->selection->extent,
                          allocator);
  switch (state->selection->affinity) {
    case mozart::TextAffinity::UPSTREAM:
      encoded_state.AddMember("selectionAffinity",
                              rapidjson::Value("TextAffinity.upstream"),
                              allocator);
      break;
    case mozart::TextAffinity::DOWNSTREAM:
      encoded_state.AddMember("selectionAffinity",
                              rapidjson::Value("TextAffinity.downstream"),
                              allocator);
      break;
  }
  encoded_state.AddMember("selectionIsDirectional", true, allocator);
  encoded_state.AddMember("composingBase", state->composing->start, allocator);
  encoded_state.AddMember("composingExtent", state->composing->end, allocator);

  rapidjson::Value args(rapidjson::kArrayType);
  args.PushBack(current_text_input_client_, allocator);
  args.PushBack(encoded_state, allocator);

  document.SetObject();
  document.AddMember("method",
                     rapidjson::Value("TextInputClient.updateEditingState"),
                     allocator);
  document.AddMember("args", args, allocator);

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);

  const uint8_t* data = reinterpret_cast<const uint8_t*>(buffer.GetString());
  runtime_->DispatchPlatformMessage(fxl::MakeRefCounted<blink::PlatformMessage>(
      kTextInputChannel, std::vector<uint8_t>(data, data + buffer.GetSize()),
      nullptr));
}

void RuntimeHolder::OnAction(mozart::InputMethodAction action) {
  rapidjson::Document document;
  auto& allocator = document.GetAllocator();

  rapidjson::Value args(rapidjson::kArrayType);
  args.PushBack(current_text_input_client_, allocator);

  // Done is currently the only text input action defined by Flutter.
  args.PushBack("TextInputAction.done", allocator);

  document.SetObject();
  document.AddMember(
      "method", rapidjson::Value("TextInputClient.performAction"), allocator);
  document.AddMember("args", args, allocator);

  rapidjson::StringBuffer buffer;
  rapidjson::Writer<rapidjson::StringBuffer> writer(buffer);
  document.Accept(writer);

  const uint8_t* data = reinterpret_cast<const uint8_t*>(buffer.GetString());
  runtime_->DispatchPlatformMessage(fxl::MakeRefCounted<blink::PlatformMessage>(
      kTextInputChannel, std::vector<uint8_t>(data, data + buffer.GetSize()),
      nullptr));
}

fxl::WeakPtr<RuntimeHolder> RuntimeHolder::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void RuntimeHolder::PostBeginFrame() {
  blink::Threads::Platform()->PostTask([weak_runtime_holder = GetWeakPtr()]() {
    // On the Platform/UI thread.
    ASSERT_IS_UI_THREAD;
    if (weak_runtime_holder) {
      weak_runtime_holder->BeginFrame();
    }
  });
}

void RuntimeHolder::BeginFrame() {
  ASSERT_IS_UI_THREAD
  FXL_DCHECK(frame_scheduled_);
  FXL_DCHECK(!frame_outstanding_);
  frame_scheduled_ = false;
  frame_outstanding_ = true;
  int64_t dart_frame_start_micros = Dart_TimelineGetMicros();
  last_begin_frame_time_ = fxl::TimePoint::Now();
  runtime_->BeginFrame(last_begin_frame_time_);

  if (frame_scheduled_) {
    // HACK(rmacnak): This assumes 16ms/frame; it should use the frame deadline
    // once we have access to it. Compare shell/common/animator.cc.
    runtime_->NotifyIdle(dart_frame_start_micros + 16000);
  } else {
    // We don't have another frame pending, so we're waiting on user input
    // or I/O. Allow the Dart VM 100 ms.
    runtime_->NotifyIdle(dart_frame_start_micros + 100000);
  }
}

void RuntimeHolder::OnFrameComplete() {
  ASSERT_IS_UI_THREAD
  FXL_DCHECK(frame_outstanding_);
  frame_outstanding_ = false;
  if (frame_scheduled_)
    PostBeginFrame();
}

void RuntimeHolder::OnRedrawFrame() {
  if (!frame_outstanding_)
    ScheduleFrame();
}

}  // namespace flutter_runner
