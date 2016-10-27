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
#include "flutter/runtime/asset_font_selector.h"
#include "flutter/runtime/dart_controller.h"
#include "flutter/runtime/dart_init.h"
#include "flutter/runtime/runtime_init.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "lib/ftl/files/path.h"
#include "lib/ftl/functional/make_copyable.h"
#include "mojo/public/cpp/application/connect.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace shell {
namespace {

constexpr char kAssetChannel[] = "flutter/assets";
constexpr char kLifecycleChannel[] = "flutter/lifecycle";
constexpr char kNavigationChannel[] = "flutter/navigation";
constexpr char kLocalizationChannel[] = "flutter/localization";

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

}  // namespace

Engine::Engine(PlatformView* platform_view)
    : platform_view_(platform_view->GetWeakPtr()),
      animator_(std::make_unique<Animator>(
          platform_view->rasterizer().GetWeakRasterizerPtr(),
          platform_view->GetVsyncWaiter(),
          this)),
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

void Engine::SetViewportMetrics(const blink::ViewportMetrics& metrics) {
  viewport_metrics_ = metrics;
  if (runtime_)
    runtime_->SetViewportMetrics(viewport_metrics_);
}

void Engine::DispatchPlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kLifecycleChannel) {
    if (HandleLifecyclePlatformMessage(message.get()))
      return;
  } else if (message->channel() == kLocalizationChannel) {
    if (HandleLocalizationPlatformMessage(std::move(message)))
      return;
  }

  if (runtime_) {
    runtime_->DispatchPlatformMessage(std::move(message));
    return;
  }

  // If there's no runtime_, we need to buffer some navigation messages.
  if (message->channel() == kNavigationChannel)
    HandleNavigationPlatformMessage(std::move(message));
}

bool Engine::HandleLifecyclePlatformMessage(blink::PlatformMessage* message) {
  const auto& data = message->data();
  std::string state(reinterpret_cast<const char*>(data.data()), data.size());
  if (state == "AppLifecycleState.paused") {
    activity_running_ = false;
    StopAnimator();
  } else if (state == "AppLifecycleState.resumed") {
    activity_running_ = true;
    StartAnimatorIfPossible();
  }
  return false;
}

bool Engine::HandleNavigationPlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  FTL_DCHECK(!runtime_);
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || method->value != "pushRoute")
    return false;

  pending_push_route_message_ = std::move(message);
  return true;
}

bool Engine::HandleLocalizationPlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd() || method->value != "setLocale")
    return false;

  auto args = root.FindMember("args");
  if (args == root.MemberEnd() || !args->value.IsArray())
    return false;

  const auto& language = args->value[0];
  const auto& country = args->value[1];

  if (!language.IsString() || !country.IsString())
    return false;

  language_code_ = language.GetString();
  country_code_ = country.GetString();
  if (runtime_)
    runtime_->SetLocale(language_code_, country_code_);
  return true;
}

void Engine::DispatchPointerDataPacket(const PointerDataPacket& packet) {
  if (runtime_)
    runtime_->DispatchPointerDataPacket(packet);
}

void Engine::DispatchSemanticsAction(int id, blink::SemanticsAction action) {
  if (runtime_)
    runtime_->DispatchSemanticsAction(id, action);
}

void Engine::SetSemanticsEnabled(bool enabled) {
  semantics_enabled_ = enabled;
  if (runtime_)
    runtime_->SetSemanticsEnabled(semantics_enabled_);
}

void Engine::RunFromSnapshotStream(
    const std::string& script_uri,
    mojo::ScopedDataPipeConsumerHandle snapshot) {
  TRACE_EVENT0("flutter", "Engine::RunFromSnapshotStream");
  ConfigureRuntime(script_uri);
  snapshot_drainer_.reset(new glue::DrainDataPipeJob(
      std::move(snapshot), [this](std::vector<uint8_t> snapshot) {
        FTL_DCHECK(runtime_);
        FTL_DCHECK(runtime_->dart_controller());
        runtime_->dart_controller()->RunFromSnapshot(snapshot.data(),
                                                     snapshot.size());
      }));
}

void Engine::ConfigureAssetBundle(const std::string& path) {
  struct stat stat_result = {0};

  directory_asset_bundle_.reset();
  zip_asset_bundle_.reset();

  if (::stat(path.c_str(), &stat_result) != 0) {
    LOG(INFO) << "Could not configure asset bundle at path: " << path;
    return;
  }

  if (S_ISDIR(stat_result.st_mode)) {
    // Directory asset bundle.
    directory_asset_bundle_ = std::make_unique<blink::DirectoryAssetBundle>(
        mojo::GetProxy(&root_bundle_), path, blink::Threads::IO());
    return;
  }

  if (S_ISREG(stat_result.st_mode)) {
    // Zip asset bundle.
    asset_store_ = ftl::MakeRefCounted<blink::ZipAssetStore>(
        blink::GetUnzipperProviderForPath(path), blink::Threads::IO());
    zip_asset_bundle_ = std::make_unique<blink::ZipAssetBundle>(
        mojo::GetProxy(&root_bundle_), asset_store_);
    return;
  }
}

void Engine::ConfigureRuntime(const std::string& script_uri) {
  snapshot_drainer_.reset();
  runtime_ = blink::RuntimeController::Create(this);
  runtime_->CreateDartController(std::move(script_uri));
  runtime_->SetViewportMetrics(viewport_metrics_);
  runtime_->SetLocale(language_code_, country_code_);
  runtime_->SetSemanticsEnabled(semantics_enabled_);
  if (pending_push_route_message_)
    runtime_->DispatchPlatformMessage(std::move(pending_push_route_message_));
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

void Engine::DidCreateMainIsolate(Dart_Isolate isolate) {
  if (asset_store_)
    blink::AssetFontSelector::Install(asset_store_);
}

void Engine::DidCreateSecondaryIsolate(Dart_Isolate isolate) {}

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

  SkISize frame_size = SkISize::Make(viewport_metrics_.physical_width,
                                     viewport_metrics_.physical_height);
  if (frame_size.isEmpty())
    return;

  layer_tree->set_frame_size(frame_size);
  animator_->Render(std::move(layer_tree));
}

void Engine::UpdateSemantics(std::vector<blink::SemanticsNode> update) {
  blink::Threads::Platform()->PostTask(ftl::MakeCopyable(
      [ platform_view = platform_view_, update = std::move(update) ]() mutable {
        if (platform_view)
          platform_view->UpdateSemantics(std::move(update));
      }));
}

void Engine::HandlePlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kAssetChannel) {
    HandleAssetPlatformMessage(std::move(message));
    return;
  }
  blink::Threads::Platform()->PostTask([
    platform_view = platform_view_, message = std::move(message)
  ]() mutable {
    if (platform_view)
      platform_view->HandlePlatformMessage(std::move(message));
  });
}

void Engine::HandleAssetPlatformMessage(
    ftl::RefPtr<blink::PlatformMessage> message) {
  ftl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (!response)
    return;
  const auto& data = message->data();
  std::string asset_name(reinterpret_cast<const char*>(data.data()),
                         data.size());
  std::vector<uint8_t> asset_data;
  if ((directory_asset_bundle_ &&
       directory_asset_bundle_->GetAsBuffer(asset_name, &asset_data)) ||
      (asset_store_ && asset_store_->GetAsBuffer(asset_name, &asset_data))) {
    response->Complete(std::move(asset_data));
  } else {
    response->CompleteWithError();
  }
}

}  // namespace shell
