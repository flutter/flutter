// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/engine.h"

#include <sys/stat.h>
#include <unistd.h>
#include <utility>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/unzipper_provider.h"
#include "flutter/assets/zip_asset_bundle.h"
#include "flutter/common/threads.h"
#include "flutter/glue/movable_wrapper.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/mojo_services.h"
#include "flutter/runtime/asset_font_selector.h"
#include "flutter/runtime/dart_controller.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/runtime_init.h"
#include "flutter/shell/common/animator.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "lib/ftl/files/path.h"
#include "mojo/public/cpp/application/connect.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace shell {
namespace {

bool PathExists(const std::string& path) {
  return access(path.c_str(), R_OK) == 0;
}

std::string FindPackagesPath(const std::string& main_dart) {
  std::string directory = files::GetDirectoryName(main_dart);
  std::string packages_path = directory + "/.packages";
  if (!PathExists(packages_path)) {
    directory = files::GetDirectoryName(directory);
    packages_path = directory + "/.packages";
    if (!PathExists(packages_path))
      packages_path = std::string();
  }
  return packages_path;
}

blink::PointerData::Change GetChangeFromPointerType(pointer::PointerType type) {
  switch (type) {
    case pointer::PointerType::DOWN:
      return blink::PointerData::Change::kDown;
    case pointer::PointerType::UP:
      return blink::PointerData::Change::kUp;
    case pointer::PointerType::MOVE:
      return blink::PointerData::Change::kMove;
    case pointer::PointerType::CANCEL:
      return blink::PointerData::Change::kCancel;
  }
  FTL_NOTREACHED();
  return blink::PointerData::Change::kCancel;
}

blink::PointerData::DeviceKind GetDeviceKindFromPointerKind(
    pointer::PointerKind kind) {
  switch (kind) {
    case pointer::PointerKind::TOUCH:
      return blink::PointerData::DeviceKind::kTouch;
    case pointer::PointerKind::MOUSE:
      return blink::PointerData::DeviceKind::kMouse;
    case pointer::PointerKind::STYLUS:
      return blink::PointerData::DeviceKind::kStylus;
    case pointer::PointerKind::INVERTED_STYLUS:
      return blink::PointerData::DeviceKind::kInvertedStylus;
  }
  FTL_NOTREACHED();
  return blink::PointerData::DeviceKind::kTouch;
}

}  // namespace

Engine::Engine(Rasterizer* rasterizer)
    : animator_(new Animator(rasterizer, this)),
      binding_(this),
      activity_running_(false),
      have_surface_(false),
      weak_factory_(this) {}

Engine::~Engine() {}

ftl::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Engine::Init() {
  blink::InitRuntime();
}

void Engine::BeginFrame(ftl::TimePoint frame_time) {
  TRACE_EVENT0("flutter", "Engine::BeginFrame");
  if (runtime_)
    runtime_->BeginFrame(frame_time);
}

void Engine::RunFromSource(const std::string& main,
                           const std::string& packages,
                           const std::string& bundle) {
  TRACE_EVENT0("flutter", "Engine::RunFromSource");
  std::string packages_path = packages;
  if (packages_path.empty())
    packages_path = FindPackagesPath(main);
  if (!bundle.empty())
    ConfigureAssetBundle(bundle);
  ConfigureRuntime(main);
  runtime_->dart_controller()->RunFromSource(main, packages_path);
}

Dart_Port Engine::GetUIIsolateMainPort() {
  if (!runtime_)
    return ILLEGAL_PORT;
  return runtime_->GetMainPort();
}

std::string Engine::GetUIIsolateName() {
  if (!runtime_) {
    return "";
  }
  return runtime_->GetIsolateName();
}

void Engine::ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) {
  binding_.Bind(request.Pass());
}

void Engine::OnOutputSurfaceCreated(const ftl::Closure& gpu_continuation) {
  blink::Threads::Gpu()->PostTask(gpu_continuation);
  have_surface_ = true;
  StartAnimatorIfPossible();
  if (runtime_)
    ScheduleFrame();
}

void Engine::OnOutputSurfaceDestroyed(const ftl::Closure& gpu_continuation) {
  have_surface_ = false;
  StopAnimator();
  blink::Threads::Gpu()->PostTask(gpu_continuation);
}

void Engine::SetServices(sky::ServicesDataPtr services) {
  services_ = services.Pass();

  if (services_->incoming_services) {
    incoming_services_ =
        mojo::ServiceProviderPtr::Create(services_->incoming_services.Pass());
    service_provider_impl_.set_fallback_service_provider(
        incoming_services_.get());
  }

  vsync::VSyncProviderPtr vsync_provider;
  if (services_->shell) {
    // We bind and unbind our Shell here, since this is the only place we
    // use
    // it in this class.
    auto shell = mojo::ShellPtr::Create(services_->shell.Pass());
    mojo::ConnectToService(shell.get(), "mojo:vsync",
                           mojo::GetProxy(&vsync_provider));
    services_->shell = shell.Pass();
  } else {
    mojo::ConnectToService(incoming_services_.get(),
                           mojo::GetProxy(&vsync_provider));
  }
  animator_->set_vsync_provider(vsync_provider.Pass());
}

void Engine::OnViewportMetricsChanged(sky::ViewportMetricsPtr metrics) {
  viewport_metrics_ = metrics.Pass();
  if (runtime_)
    runtime_->SetViewportMetrics(viewport_metrics_);
}

void Engine::OnLocaleChanged(const mojo::String& language_code,
                             const mojo::String& country_code) {
  language_code_ = language_code;
  country_code_ = country_code;
  if (runtime_)
    runtime_->SetLocale(language_code_, country_code_);
}

void Engine::HandlePointerDataPacket(const PointerDataPacket& packet) {
  TRACE_EVENT0("flutter", "Engine::HandlePointerDataPacket");
  if (runtime_)
    runtime_->HandlePointerDataPacket(packet);
}

// TODO(abarth): Remove pointer::PointerPacketPtr and route PointerDataPacket
// here.
void Engine::OnPointerPacket(pointer::PointerPacketPtr packetPtr) {
  TRACE_EVENT0("flutter", "Engine::OnPointerPacket");
  if (runtime_) {
    const size_t length = packetPtr->pointers.size();
    PointerDataPacket packet(length);
    for (size_t i = 0; i < length; ++i) {
      const pointer::PointerPtr& pointer = packetPtr->pointers[i];
      blink::PointerData pointer_data;
      pointer_data.time_stamp = pointer->time_stamp;
      pointer_data.pointer = pointer->pointer;
      pointer_data.change = GetChangeFromPointerType(pointer->type);
      pointer_data.kind = GetDeviceKindFromPointerKind(pointer->kind);
      pointer_data.physical_x = pointer->x;
      pointer_data.physical_y = pointer->y;
      pointer_data.buttons = pointer->buttons;
      pointer_data.obscured = pointer->obscured ? 1 : 0;
      pointer_data.pressure = pointer->pressure;
      pointer_data.pressure_min = pointer->pressure_min;
      pointer_data.pressure_max = pointer->pressure_max;
      pointer_data.distance = pointer->distance;
      pointer_data.distance_max = pointer->distance_max;
      pointer_data.radius_major = pointer->radius_major;
      pointer_data.radius_minor = pointer->radius_minor;
      pointer_data.radius_min = pointer->radius_min;
      pointer_data.radius_max = pointer->radius_max;
      pointer_data.orientation = pointer->orientation;
      pointer_data.tilt = pointer->tilt;
      packet.SetPointerData(i, pointer_data);
    }
    runtime_->HandlePointerDataPacket(packet);
  }
}

void Engine::RunFromSnapshotStream(
    const std::string& script_uri,
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  TRACE_EVENT0("flutter", "Engine::RunFromSnapshotStream");
  ConfigureRuntime(script_uri);
  snapshot_drainer_.reset(new glue::DrainDataPipeJob(
      std::move(snapshot), [this](std::vector<char> snapshot) {
        FTL_DCHECK(runtime_);
        FTL_DCHECK(runtime_->dart_controller());
        runtime_->dart_controller()->RunFromSnapshot(
            reinterpret_cast<uint8_t*>(snapshot.data()), snapshot.size());
      }));
}

void Engine::ConfigureAssetBundle(const std::string& path) {
  struct stat stat_result = {0};

  if (::stat(path.c_str(), &stat_result) != 0) {
    LOG(INFO) << "Could not configure asset bundle at path: " << path;
    return;
  }

  if (S_ISDIR(stat_result.st_mode)) {
    // Directory asset bundle.
    new blink::DirectoryAssetBundle(mojo::GetProxy(&root_bundle_), path,
                                    blink::Threads::IO());
    return;
  }

  if (S_ISREG(stat_result.st_mode)) {
    // Zip asset bundle.
    asset_store_ = ftl::MakeRefCounted<blink::ZipAssetStore>(
        blink::GetUnzipperProviderForPath(path), blink::Threads::IO());
    new blink::ZipAssetBundle(mojo::GetProxy(&root_bundle_), asset_store_);
    return;
  }
}

void Engine::ConfigureRuntime(const std::string& script_uri) {
  snapshot_drainer_.reset();
  runtime_ = blink::RuntimeController::Create(this);
  runtime_->CreateDartController(std::move(script_uri));
  runtime_->SetViewportMetrics(viewport_metrics_);
  runtime_->SetLocale(language_code_, country_code_);
  if (!initial_route_.empty())
    runtime_->PushRoute(initial_route_);
}

void Engine::RunFromPrecompiledSnapshot(const mojo::String& bundle_path) {
  TRACE_EVENT0("flutter", "Engine::RunFromPrecompiledSnapshot");
  ConfigureAssetBundle(bundle_path.get());
  ConfigureRuntime("http://localhost");
  runtime_->dart_controller()->RunFromPrecompiledSnapshot();
}

void Engine::RunFromFile(const mojo::String& main,
                         const mojo::String& packages,
                         const mojo::String& bundle) {
  RunFromSource(main, packages, bundle);
}

void Engine::RunFromBundle(const mojo::String& script_uri,
                           const mojo::String& path) {
  TRACE_EVENT0("flutter", "Engine::RunFromBundle");
  ConfigureAssetBundle(path);
  mojo::DataPipe pipe;
  asset_store_->GetAsStream(blink::kSnapshotAssetKey,
                            std::move(pipe.producer_handle));
  RunFromSnapshotStream(script_uri, std::move(pipe.consumer_handle));
}

void Engine::RunFromBundleAndSnapshot(const mojo::String& script_uri,
                                      const mojo::String& bundle_path,
                                      const mojo::String& snapshot_path) {
  TRACE_EVENT0("flutter", "Engine::RunFromBundleAndSnapshot");

  ConfigureAssetBundle(bundle_path);

  asset_store_->AddOverlayFile(blink::kSnapshotAssetKey, snapshot_path);
  mojo::DataPipe pipe;
  asset_store_->GetAsStream(blink::kSnapshotAssetKey,
                            std::move(pipe.producer_handle));
  RunFromSnapshotStream(script_uri, std::move(pipe.consumer_handle));
}

void Engine::PushRoute(const mojo::String& route) {
  if (runtime_)
    runtime_->PushRoute(route);
  else
    initial_route_ = route;
}

void Engine::PopRoute() {
  if (runtime_)
    runtime_->PopRoute();
}

void Engine::OnAppLifecycleStateChanged(sky::AppLifecycleState state) {
  switch (state) {
    case sky::AppLifecycleState::PAUSED:
      activity_running_ = false;
      StopAnimator();
      break;

    case sky::AppLifecycleState::RESUMED:
      activity_running_ = true;
      StartAnimatorIfPossible();
      break;
  }

  if (runtime_)
    runtime_->OnAppLifecycleStateChanged(state);
}

void Engine::DidCreateMainIsolate(Dart_Isolate isolate) {
  mojo::ServiceProviderPtr services_from_embedder;
  service_provider_bindings_.AddBinding(
      &service_provider_impl_, mojo::GetProxy(&services_from_embedder));

  blink::MojoServices::Create(isolate, std::move(services_),
                              std::move(services_from_embedder),
                              std::move(root_bundle_));

  if (asset_store_)
    blink::AssetFontSelector::Install(asset_store_);
}

void Engine::DidCreateSecondaryIsolate(Dart_Isolate isolate) {
  mojo::ServiceProviderPtr services_from_embedder;
  auto request = glue::WrapMovable(mojo::GetProxy(&services_from_embedder));
  ftl::WeakPtr<Engine> engine = weak_factory_.GetWeakPtr();
  blink::Threads::UI()->PostTask([engine, request]() mutable {
    if (engine)
      engine->BindToServiceProvider(request.Unwrap());
  });
  blink::MojoServices::Create(isolate, nullptr,
                              std::move(services_from_embedder), nullptr);
}

void Engine::BindToServiceProvider(
    mojo::InterfaceRequest<mojo::ServiceProvider> request) {
  service_provider_bindings_.AddBinding(&service_provider_impl_,
                                        request.Pass());
}

void Engine::StopAnimator() {
  animator_->Stop();
}

void Engine::StartAnimatorIfPossible() {
  if (activity_running_ && have_surface_)
    animator_->Start();
}

void Engine::ScheduleFrame() {
  animator_->RequestFrame();
}

void Engine::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!layer_tree)
    return;
  if (!viewport_metrics_)
    return;

  SkISize frame_size = SkISize::Make(viewport_metrics_->physical_width,
                                     viewport_metrics_->physical_height);
  if (frame_size.isEmpty())
    return;

  layer_tree->set_scene_version(viewport_metrics_->scene_version);
  layer_tree->set_frame_size(frame_size);
  animator_->Render(std::move(layer_tree));
}

}  // namespace shell
