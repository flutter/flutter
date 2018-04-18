// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/engine.h"

#include <memory>
#include <utility>

#include "flutter/common/settings.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/snapshot/snapshot.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/runtime/asset_font_selector.h"
#include "flutter/runtime/platform_impl.h"
#include "flutter/runtime/test_font_selector.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "flutter/sky/engine/platform/fonts/FontFallbackList.h"
#include "flutter/sky/engine/public/web/Sky.h"
#include "lib/fxl/files/eintr_wrapper.h"
#include "lib/fxl/files/file.h"
#include "lib/fxl/files/path.h"
#include "lib/fxl/files/unique_fd.h"
#include "lib/fxl/functional/make_copyable.h"
#include "third_party/rapidjson/rapidjson/document.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

#ifdef ERROR
#undef ERROR
#endif

namespace shell {

static constexpr char kAssetChannel[] = "flutter/assets";
static constexpr char kLifecycleChannel[] = "flutter/lifecycle";
static constexpr char kNavigationChannel[] = "flutter/navigation";
static constexpr char kLocalizationChannel[] = "flutter/localization";
static constexpr char kSettingsChannel[] = "flutter/settings";

Engine::Engine(Delegate& delegate,
               const blink::DartVM& vm,
               blink::TaskRunners task_runners,
               blink::Settings settings,
               std::unique_ptr<Animator> animator,
               fml::WeakPtr<GrContext> resource_context,
               fxl::RefPtr<flow::SkiaUnrefQueue> unref_queue)
    : delegate_(delegate),
      settings_(std::move(settings)),
      animator_(std::move(animator)),
      legacy_sky_platform_(settings_.using_blink ? new blink::PlatformImpl()
                                                 : nullptr),
      load_script_error_(tonic::kNoError),
      activity_running_(false),
      have_surface_(false),
      weak_factory_(this) {
  if (legacy_sky_platform_) {
    // TODO: Remove this legacy call along with the platform. This is what makes
    // the engine unable to run from multiple threads in the legacy
    // configuration.
    blink::InitEngine(legacy_sky_platform_.get());
  }

  // Runtime controller is initialized here because it takes a reference to this
  // object as its delegate. The delegate may be called in the constructor and
  // we want to be fully initilazed by that point.
  runtime_controller_ = std::make_unique<blink::RuntimeController>(
      *this,                        // runtime delegate
      &vm,                          // VM
      std::move(task_runners),      // task runners
      std::move(resource_context),  // resource context
      std::move(unref_queue)        // skia unref queue
  );
}

Engine::~Engine() {
  if (legacy_sky_platform_) {
    blink::ShutdownEngine(/* legacy_sky_platform_ */);
  }
}

fml::WeakPtr<Engine> Engine::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

bool Engine::UpdateAssetManager(
    fxl::RefPtr<blink::AssetManager> new_asset_manager) {
  if (asset_manager_ == new_asset_manager) {
    return false;
  }

  asset_manager_ = new_asset_manager;

  if (!asset_manager_) {
    return false;
  }

  if (settings_.using_blink) {
    // Using blink as the text engine.
    blink::FontFallbackList::SetUseTestFonts(settings_.use_test_fonts);
  } else {
    // Using libTXT as the text engine.
    if (settings_.use_test_fonts) {
      blink::FontCollection::ForProcess().RegisterTestFonts();
    } else {
      blink::FontCollection::ForProcess().RegisterFonts(*asset_manager_.get());
    }
  }

  return true;
}

bool Engine::Restart(RunConfiguration configuration) {
  TRACE_EVENT0("flutter", "Engine::Restart");
  if (!configuration.IsValid()) {
    FXL_LOG(ERROR) << "Engine run configuration was invalid.";
    return false;
  }
  runtime_controller_ = runtime_controller_->Clone();
  UpdateAssetManager(nullptr);
  return Run(std::move(configuration));
}

bool Engine::Run(RunConfiguration configuration) {
  if (!configuration.IsValid()) {
    FXL_LOG(ERROR) << "Engine run configuration was invalid.";
    return false;
  }

  if (!PrepareAndLaunchIsolate(std::move(configuration))) {
    return false;
  }

  auto isolate = runtime_controller_->GetRootIsolate();

  bool isolate_running =
      isolate && isolate->GetPhase() == blink::DartIsolate::Phase::Running;

  if (isolate_running) {
    tonic::DartState::Scope scope(isolate.get());

    if (settings_.root_isolate_create_callback) {
      settings_.root_isolate_create_callback();
    }

    if (settings_.root_isolate_shutdown_callback) {
      isolate->AddIsolateShutdownCallback(
          settings_.root_isolate_shutdown_callback);
    }

    // Blink uses a per isolate font selector.
    if (settings_.using_blink) {
      if (settings_.use_test_fonts) {
        blink::TestFontSelector::Install();
      } else {
        blink::AssetFontSelector::Install(asset_manager_);
      }
    }
  }

  return isolate_running;
}

bool Engine::PrepareAndLaunchIsolate(RunConfiguration configuration) {
  TRACE_EVENT0("flutter", "Engine::PrepareAndLaunchIsolate");

  UpdateAssetManager(configuration.GetAssetManager());

  auto isolate_configuration = configuration.TakeIsolateConfiguration();

  auto isolate = runtime_controller_->GetRootIsolate();

  if (!isolate_configuration->PrepareIsolate(isolate)) {
    FXL_DLOG(ERROR) << "Could not prepare to run the isolate.";
    return false;
  }

  if (!isolate->Run(configuration.GetEntrypoint())) {
    FXL_DLOG(ERROR) << "Could not run the isolate.";
    return false;
  }

  return true;
}

void Engine::BeginFrame(fxl::TimePoint frame_time) {
  TRACE_EVENT0("flutter", "Engine::BeginFrame");
  runtime_controller_->BeginFrame(frame_time);
}

void Engine::NotifyIdle(int64_t deadline) {
  TRACE_EVENT0("flutter", "Engine::NotifyIdle");
  runtime_controller_->NotifyIdle(deadline);
}

std::pair<bool, uint32_t> Engine::GetUIIsolateReturnCode() {
  return runtime_controller_->GetRootIsolateReturnCode();
}

Dart_Port Engine::GetUIIsolateMainPort() {
  return runtime_controller_->GetMainPort();
}

std::string Engine::GetUIIsolateName() {
  return runtime_controller_->GetIsolateName();
}

bool Engine::UIIsolateHasLivePorts() {
  return runtime_controller_->HasLivePorts();
}

tonic::DartErrorHandleType Engine::GetUIIsolateLastError() {
  return runtime_controller_->GetLastError();
}

tonic::DartErrorHandleType Engine::GetLoadScriptError() {
  return load_script_error_;
}

void Engine::OnOutputSurfaceCreated() {
  have_surface_ = true;
  StartAnimatorIfPossible();
  ScheduleFrame();
}

void Engine::OnOutputSurfaceDestroyed() {
  have_surface_ = false;
  StopAnimator();
}

void Engine::SetViewportMetrics(const blink::ViewportMetrics& metrics) {
  bool dimensions_changed =
      viewport_metrics_.physical_height != metrics.physical_height ||
      viewport_metrics_.physical_width != metrics.physical_width;
  viewport_metrics_ = metrics;
  runtime_controller_->SetViewportMetrics(viewport_metrics_);
  if (animator_) {
    if (dimensions_changed)
      animator_->SetDimensionChangePending();
    if (have_surface_)
      ScheduleFrame();
  }
}

void Engine::DispatchPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kLifecycleChannel) {
    if (HandleLifecyclePlatformMessage(message.get()))
      return;
  } else if (message->channel() == kLocalizationChannel) {
    if (HandleLocalizationPlatformMessage(message.get()))
      return;
  } else if (message->channel() == kSettingsChannel) {
    HandleSettingsPlatformMessage(message.get());
    return;
  }

  if (runtime_controller_->IsRootIsolateRunning() &&
      runtime_controller_->DispatchPlatformMessage(std::move(message))) {
    return;
  }

  // If there's no runtime_, we may still need to set the initial route.
  if (message->channel() == kNavigationChannel)
    HandleNavigationPlatformMessage(std::move(message));
}

bool Engine::HandleLifecyclePlatformMessage(blink::PlatformMessage* message) {
  const auto& data = message->data();
  std::string state(reinterpret_cast<const char*>(data.data()), data.size());
  if (state == "AppLifecycleState.paused" ||
      state == "AppLifecycleState.suspending") {
    activity_running_ = false;
    StopAnimator();
  } else if (state == "AppLifecycleState.resumed" ||
             state == "AppLifecycleState.inactive") {
    activity_running_ = true;
    StartAnimatorIfPossible();
  }

  // Always schedule a frame when the app does become active as per API
  // recommendation
  // https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622956-applicationdidbecomeactive?language=objc
  if (state == "AppLifecycleState.resumed" && have_surface_) {
    ScheduleFrame();
  }
  return false;
}

bool Engine::HandleNavigationPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method->value != "setInitialRoute")
    return false;
  auto route = root.FindMember("args");
  initial_route_ = std::move(route->value.GetString());
  return true;
}

bool Engine::HandleLocalizationPlatformMessage(
    blink::PlatformMessage* message) {
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

  return runtime_controller_->SetLocale(language.GetString(),
                                        country.GetString());
}

void Engine::HandleSettingsPlatformMessage(blink::PlatformMessage* message) {
  const auto& data = message->data();
  std::string jsonData(reinterpret_cast<const char*>(data.data()), data.size());
  if (runtime_controller_->SetUserSettingsData(std::move(jsonData)) &&
      have_surface_) {
    ScheduleFrame();
  }
}

void Engine::DispatchPointerDataPacket(const blink::PointerDataPacket& packet) {
  runtime_controller_->DispatchPointerDataPacket(packet);
}

void Engine::DispatchSemanticsAction(int id,
                                     blink::SemanticsAction action,
                                     std::vector<uint8_t> args) {
  runtime_controller_->DispatchSemanticsAction(id, action, std::move(args));
}

void Engine::SetSemanticsEnabled(bool enabled) {
  runtime_controller_->SetSemanticsEnabled(enabled);
}

void Engine::StopAnimator() {
  animator_->Stop();
}

void Engine::StartAnimatorIfPossible() {
  if (activity_running_ && have_surface_)
    animator_->Start();
}

std::string Engine::DefaultRouteName() {
  if (!initial_route_.empty()) {
    return initial_route_;
  }
  return "/";
}

void Engine::ScheduleFrame(bool regenerate_layer_tree) {
  animator_->RequestFrame(regenerate_layer_tree);
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

void Engine::UpdateSemantics(blink::SemanticsNodeUpdates update) {
  delegate_.OnEngineUpdateSemantics(*this, std::move(update));
}

void Engine::HandlePlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  if (message->channel() == kAssetChannel) {
    HandleAssetPlatformMessage(std::move(message));
  } else {
    delegate_.OnEngineHandlePlatformMessage(*this, std::move(message));
  }
}

void Engine::HandleAssetPlatformMessage(
    fxl::RefPtr<blink::PlatformMessage> message) {
  fxl::RefPtr<blink::PlatformMessageResponse> response = message->response();
  if (!response) {
    return;
  }
  const auto& data = message->data();
  std::string asset_name(reinterpret_cast<const char*>(data.data()),
                         data.size());

  std::vector<uint8_t> asset_data;
  if (asset_manager_ && asset_manager_->GetAsBuffer(asset_name, &asset_data)) {
    response->Complete(std::move(asset_data));
  } else {
    response->CompleteEmpty();
  }
}

}  // namespace shell
