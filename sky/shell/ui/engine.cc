// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/sky/shell/ui/engine.h"

#include <unistd.h>

#include "flutter/assets/directory_asset_bundle.h"
#include "flutter/assets/zip_asset_bundle.h"
#include "flutter/tonic/dart_library_provider_files.h"
#include "flutter/glue/movable_wrapper.h"
#include "flutter/glue/trace_event.h"
#include "lib/ftl/files/path.h"
#include "mojo/public/cpp/application/connect.h"
#include "flutter/sky/engine/bindings/mojo_services.h"
#include "flutter/sky/engine/core/script/dart_init.h"
#include "flutter/sky/engine/core/script/ui_dart_state.h"
#include "flutter/sky/engine/public/platform/Platform.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "flutter/sky/shell/shell.h"
#include "flutter/sky/shell/ui/animator.h"
#include "flutter/sky/shell/ui/flutter_font_selector.h"
#include "flutter/sky/shell/ui/platform_impl.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace sky {
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

PlatformImpl* g_platform_impl = nullptr;

}  // namespace

Engine::Config::Config() {}

Engine::Config::~Config() {}

Engine::Engine(const Config& config, rasterizer::RasterizerPtr rasterizer)
    : config_(config),
      animator_(new Animator(config, rasterizer.Pass(), this)),
      binding_(this),
      activity_running_(false),
      have_surface_(false),
      weak_factory_(this) {}

Engine::~Engine() {}

ftl::WeakPtr<Engine> Engine::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void Engine::Init() {
  TRACE_EVENT0("flutter", "Engine::Init");

  DCHECK(!g_platform_impl);
  g_platform_impl = new PlatformImpl();
  blink::initialize(g_platform_impl);
}

void Engine::BeginFrame(ftl::TimePoint frame_time) {
  TRACE_EVENT0("flutter", "Engine::BeginFrame");
  if (sky_view_)
    sky_view_->BeginFrame(frame_time);
}

void Engine::RunFromSource(const std::string& main,
                           const std::string& packages,
                           const std::string& assets_directory) {
  TRACE_EVENT0("flutter", "Engine::RunFromSource");
  // Assets.
  ConfigureDirectoryAssetBundle(assets_directory);
  // .packages.
  std::string packages_path = packages;
  if (packages_path.empty())
    packages_path = FindPackagesPath(main);
  DartLibraryProviderFiles* provider = new DartLibraryProviderFiles();
  dart_library_provider_.reset(provider);
  if (!packages_path.empty())
    provider->LoadPackagesMap(packages_path);
  RunFromLibrary(main);
}

Dart_Port Engine::GetUIIsolateMainPort() {
  if (!sky_view_) {
    return ILLEGAL_PORT;
  }
  return sky_view_->GetMainPort();
}

void Engine::ConnectToEngine(mojo::InterfaceRequest<SkyEngine> request) {
  binding_.Bind(request.Pass());
}

void Engine::OnOutputSurfaceCreated(const ftl::Closure& gpu_continuation) {
  config_.gpu_task_runner->PostTask(gpu_continuation);
  have_surface_ = true;
  StartAnimatorIfPossible();
  if (sky_view_)
    ScheduleFrame();
}

void Engine::OnOutputSurfaceDestroyed(const ftl::Closure& gpu_continuation) {
  have_surface_ = false;
  StopAnimator();
  config_.gpu_task_runner->PostTask(gpu_continuation);
}

void Engine::SetServices(ServicesDataPtr services) {
  services_ = services.Pass();

  if (services_->incoming_services) {
    incoming_services_ =
        mojo::ServiceProviderPtr::Create(services_->incoming_services.Pass());
    service_provider_impl_.set_fallback_service_provider(
        incoming_services_.get());
  }

  if (services_->frame_scheduler) {
    animator_->Reset();
    animator_->set_frame_scheduler(services_->frame_scheduler.Pass());
  } else {
#if defined(OS_ANDROID) || defined(OS_IOS) || defined(OS_MACOSX)
    vsync::VSyncProviderPtr vsync_provider;
    if (services_->shell) {
      // We bind and unbind our Shell here, since this is the only place we use
      // it in this class.
      auto shell = mojo::ShellPtr::Create(services_->shell.Pass());
      mojo::ConnectToService(shell.get(), "mojo:vsync",
                             mojo::GetProxy(&vsync_provider));
      services_->shell = shell.Pass();
    } else {
      mojo::ConnectToService(incoming_services_.get(),
                             mojo::GetProxy(&vsync_provider));
    }
    animator_->Reset();
    animator_->set_vsync_provider(vsync_provider.Pass());
#endif
  }
}

void Engine::OnViewportMetricsChanged(ViewportMetricsPtr metrics) {
  viewport_metrics_ = metrics.Pass();
  if (sky_view_)
    sky_view_->SetViewportMetrics(viewport_metrics_);
}

void Engine::OnLocaleChanged(const mojo::String& language_code,
                             const mojo::String& country_code) {
  language_code_ = language_code;
  country_code_ = country_code;
  if (sky_view_)
    sky_view_->SetLocale(language_code_, country_code_);
}

void Engine::OnPointerPacket(pointer::PointerPacketPtr packet) {
  TRACE_EVENT0("flutter", "Engine::OnPointerPacket");

  // Convert the pointers' x and y coordinates to logical pixels.
  for (auto it = packet->pointers.begin(); it != packet->pointers.end(); ++it) {
    (*it)->x /= viewport_metrics_->device_pixel_ratio;
    (*it)->y /= viewport_metrics_->device_pixel_ratio;
  }

  if (sky_view_)
    sky_view_->HandlePointerPacket(packet);
}

void Engine::RunFromLibrary(const std::string& name) {
  TRACE_EVENT0("flutter", "Engine::RunFromLibrary");
  sky_view_ = blink::SkyView::Create(this);
  sky_view_->CreateView(name);
  sky_view_->RunFromLibrary(name, dart_library_provider_.get());
  sky_view_->SetViewportMetrics(viewport_metrics_);
  sky_view_->SetLocale(language_code_, country_code_);
  if (!initial_route_.empty())
    sky_view_->PushRoute(initial_route_);
}

void Engine::RunFromSnapshotStream(
    const std::string& script_uri,
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  TRACE_EVENT0("flutter", "Engine::RunFromSnapshotStream");
  sky_view_ = blink::SkyView::Create(this);
  sky_view_->CreateView(script_uri);
  sky_view_->RunFromSnapshot(snapshot.Pass());
  sky_view_->SetViewportMetrics(viewport_metrics_);
  sky_view_->SetLocale(language_code_, country_code_);
  if (!initial_route_.empty())
    sky_view_->PushRoute(initial_route_);
}

void Engine::ConfigureZipAssetBundle(const mojo::String& path) {
  asset_store_ = ftl::MakeRefCounted<blink::ZipAssetStore>(
      path.get(), ftl::RefPtr<ftl::TaskRunner>(
                      blink::Platform::current()->GetIOTaskRunner()));
  new blink::ZipAssetBundle(mojo::GetProxy(&root_bundle_), asset_store_);
}

void Engine::ConfigureDirectoryAssetBundle(const std::string& path) {
  new blink::DirectoryAssetBundle(
      mojo::GetProxy(&root_bundle_), path,
      ftl::RefPtr<ftl::TaskRunner>(
          blink::Platform::current()->GetIOTaskRunner()));
}

void Engine::RunFromPrecompiledSnapshot(const mojo::String& bundle_path) {
  TRACE_EVENT0("flutter", "Engine::RunFromPrecompiledSnapshot");

  ConfigureZipAssetBundle(bundle_path);

  sky_view_ = blink::SkyView::Create(this);
  sky_view_->CreateView("http://localhost");
  sky_view_->RunFromPrecompiledSnapshot();
  sky_view_->SetViewportMetrics(viewport_metrics_);
  sky_view_->SetLocale(language_code_, country_code_);
  if (!initial_route_.empty())
    sky_view_->PushRoute(initial_route_);
}

void Engine::RunFromFile(const mojo::String& main,
                         const mojo::String& packages,
                         const mojo::String& bundle) {
  TRACE_EVENT0("flutter", "Engine::RunFromFile");
  std::string main_dart(main);
  if (bundle.size() != 0) {
    // The specification of an FLX bundle is optional.
    ConfigureZipAssetBundle(bundle);
  }
  std::string packages_path = packages;
  if (packages_path.empty())
    packages_path = FindPackagesPath(main_dart);
  DartLibraryProviderFiles* provider = new DartLibraryProviderFiles();
  dart_library_provider_.reset(provider);
  if (!packages_path.empty())
    provider->LoadPackagesMap(packages_path);
  RunFromLibrary(main_dart);
}

void Engine::RunFromBundle(const mojo::String& script_uri,
                           const mojo::String& path) {
  TRACE_EVENT0("flutter", "Engine::RunFromBundle");

  ConfigureZipAssetBundle(path);
  mojo::DataPipe pipe;
  asset_store_->GetAsStream(blink::kSnapshotAssetKey,
                            std::move(pipe.producer_handle));
  RunFromSnapshotStream(script_uri, std::move(pipe.consumer_handle));
}

void Engine::RunFromBundleAndSnapshot(const mojo::String& script_uri,
                                      const mojo::String& bundle_path,
                                      const mojo::String& snapshot_path) {
  TRACE_EVENT0("flutter", "Engine::RunFromBundleAndSnapshot");

  ConfigureZipAssetBundle(bundle_path);

  asset_store_->AddOverlayFile(blink::kSnapshotAssetKey, snapshot_path);
  mojo::DataPipe pipe;
  asset_store_->GetAsStream(blink::kSnapshotAssetKey,
                            std::move(pipe.producer_handle));
  RunFromSnapshotStream(script_uri, std::move(pipe.consumer_handle));
}

void Engine::PushRoute(const mojo::String& route) {
  if (sky_view_)
    sky_view_->PushRoute(route);
  else
    initial_route_ = route;
}

void Engine::PopRoute() {
  if (sky_view_)
    sky_view_->PopRoute();
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

  if (sky_view_)
    sky_view_->OnAppLifecycleStateChanged(state);
}

void Engine::DidCreateMainIsolate(Dart_Isolate isolate) {
  mojo::ServiceProviderPtr services_from_embedder;
  service_provider_bindings_.AddBinding(
      &service_provider_impl_, mojo::GetProxy(&services_from_embedder));

  blink::MojoServices::Create(isolate, services_.Pass(),
                              services_from_embedder.Pass(),
                              root_bundle_.Pass());

  if (asset_store_)
    FlutterFontSelector::Install(asset_store_);
}

void Engine::DidCreateSecondaryIsolate(Dart_Isolate isolate) {
  mojo::ServiceProviderPtr services_from_embedder;
  auto request = glue::WrapMovable(mojo::GetProxy(&services_from_embedder));
  ftl::WeakPtr<Engine> engine = weak_factory_.GetWeakPtr();
  blink::Platform::current()->GetUITaskRunner()->PostTask(
      [engine, request]() mutable {
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

void Engine::FlushRealTimeEvents() {
  animator_->FlushRealTimeEvents();
}

void Engine::Render(std::unique_ptr<flow::LayerTree> layer_tree) {
  if (!layer_tree)
    return;
  if (viewport_metrics_) {
    layer_tree->set_scene_version(viewport_metrics_->scene_version);
    layer_tree->set_frame_size(SkISize::Make(
        viewport_metrics_->physical_width, viewport_metrics_->physical_height));
  } else {
    layer_tree->set_scene_version(0);
    layer_tree->set_frame_size(SkISize::Make(0, 0));
  }
  animator_->Render(std::move(layer_tree));
}

}  // namespace shell
}  // namespace sky
