// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/common/engine.h"

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "flutter/common/settings.h"
#include "flutter/fml/eintr_wrapper.h"
#include "flutter/fml/file.h"
#include "flutter/fml/make_copyable.h"
#include "flutter/fml/paths.h"
#include "flutter/fml/trace_event.h"
#include "flutter/fml/unique_fd.h"
#include "flutter/lib/snapshot/snapshot.h"
#include "flutter/lib/ui/text/font_collection.h"
#include "flutter/shell/common/animator.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/common/shell.h"
#include "rapidjson/document.h"
#include "third_party/dart/runtime/include/dart_tools_api.h"
#include "third_party/skia/include/core/SkCanvas.h"
#include "third_party/skia/include/core/SkPictureRecorder.h"

namespace flutter {

static constexpr char kAssetChannel[] = "flutter/assets";
static constexpr char kLifecycleChannel[] = "flutter/lifecycle";
static constexpr char kNavigationChannel[] = "flutter/navigation";
static constexpr char kLocalizationChannel[] = "flutter/localization";
static constexpr char kSettingsChannel[] = "flutter/settings";
static constexpr char kIsolateChannel[] = "flutter/isolate";

Engine::Engine(Delegate& delegate,
               const PointerDataDispatcherMaker& dispatcher_maker,
               DartVM& vm,
               fml::RefPtr<const DartSnapshot> isolate_snapshot,
               TaskRunners task_runners,
               const WindowData window_data,
               Settings settings,
               std::unique_ptr<Animator> animator,
               fml::WeakPtr<IOManager> io_manager,
               fml::RefPtr<SkiaUnrefQueue> unref_queue,
               fml::WeakPtr<SnapshotDelegate> snapshot_delegate)
    : delegate_(delegate),
      settings_(std::move(settings)),
      animator_(std::move(animator)),
      activity_running_(true),
      have_surface_(false),
      image_decoder_(task_runners,
                     vm.GetConcurrentWorkerTaskRunner(),
                     io_manager),
      task_runners_(std::move(task_runners)),
      weak_factory_(this) {
  // Runtime controller is initialized here because it takes a reference to this
  // object as its delegate. The delegate may be called in the constructor and
  // we want to be fully initilazed by that point.
  runtime_controller_ = std::make_unique<RuntimeController>(
      *this,                        // runtime delegate
      &vm,                          // VM
      std::move(isolate_snapshot),  // isolate snapshot
      task_runners_,                // task runners
      std::move(snapshot_delegate),
      std::move(io_manager),                 // io manager
      std::move(unref_queue),                // Skia unref queue
      image_decoder_.GetWeakPtr(),           // image decoder
      settings_.advisory_script_uri,         // advisory script uri
      settings_.advisory_script_entrypoint,  // advisory script entrypoint
      settings_.idle_notification_callback,  // idle notification callback
      window_data,                           // window data
      settings_.isolate_create_callback,     // isolate create callback
      settings_.isolate_shutdown_callback,   // isolate shutdown callback
      settings_.persistent_isolate_data      // persistent isolate data
  );

  pointer_data_dispatcher_ = dispatcher_maker(*this);
}

Engine::~Engine() = default;

float Engine::GetDisplayRefreshRate() const {
  return animator_->GetDisplayRefreshRate();
}

fml::WeakPtr<Engine> Engine::GetWeakPtr() const {
  return weak_factory_.GetWeakPtr();
}

bool Engine::UpdateAssetManager(
    std::shared_ptr<AssetManager> new_asset_manager) {
  if (asset_manager_ == new_asset_manager) {
    return false;
  }

  asset_manager_ = new_asset_manager;

  if (!asset_manager_) {
    return false;
  }

  // Using libTXT as the text engine.
  font_collection_.RegisterFonts(asset_manager_);

  if (settings_.use_test_fonts) {
    font_collection_.RegisterTestFonts();
  }

  return true;
}

bool Engine::Restart(RunConfiguration configuration) {
  TRACE_EVENT0("flutter", "Engine::Restart");
  if (!configuration.IsValid()) {
    FML_LOG(ERROR) << "Engine run configuration was invalid.";
    return false;
  }
  delegate_.OnPreEngineRestart();
  runtime_controller_ = runtime_controller_->Clone();
  UpdateAssetManager(nullptr);
  return Run(std::move(configuration)) == Engine::RunStatus::Success;
}

Engine::RunStatus Engine::Run(RunConfiguration configuration) {
  if (!configuration.IsValid()) {
    FML_LOG(ERROR) << "Engine run configuration was invalid.";
    return RunStatus::Failure;
  }

  last_entry_point_ = configuration.GetEntrypoint();
  last_entry_point_library_ = configuration.GetEntrypointLibrary();

  auto isolate_launch_status =
      PrepareAndLaunchIsolate(std::move(configuration));
  if (isolate_launch_status == Engine::RunStatus::Failure) {
    FML_LOG(ERROR) << "Engine not prepare and launch isolate.";
    return isolate_launch_status;
  } else if (isolate_launch_status ==
             Engine::RunStatus::FailureAlreadyRunning) {
    return isolate_launch_status;
  }

  std::shared_ptr<DartIsolate> isolate =
      runtime_controller_->GetRootIsolate().lock();

  bool isolate_running =
      isolate && isolate->GetPhase() == DartIsolate::Phase::Running;

  if (isolate_running) {
    tonic::DartState::Scope scope(isolate.get());

    if (settings_.root_isolate_create_callback) {
      settings_.root_isolate_create_callback();
    }

    if (settings_.root_isolate_shutdown_callback) {
      isolate->AddIsolateShutdownCallback(
          settings_.root_isolate_shutdown_callback);
    }

    std::string service_id = isolate->GetServiceId();
    fml::RefPtr<PlatformMessage> service_id_message =
        fml::MakeRefCounted<flutter::PlatformMessage>(
            kIsolateChannel,
            std::vector<uint8_t>(service_id.begin(), service_id.end()),
            nullptr);
    HandlePlatformMessage(service_id_message);
  }

  return isolate_running ? Engine::RunStatus::Success
                         : Engine::RunStatus::Failure;
}

Engine::RunStatus Engine::PrepareAndLaunchIsolate(
    RunConfiguration configuration) {
  TRACE_EVENT0("flutter", "Engine::PrepareAndLaunchIsolate");

  UpdateAssetManager(configuration.GetAssetManager());

  auto isolate_configuration = configuration.TakeIsolateConfiguration();

  std::shared_ptr<DartIsolate> isolate =
      runtime_controller_->GetRootIsolate().lock();

  if (!isolate) {
    return RunStatus::Failure;
  }

  // This can happen on iOS after a plugin shows a native window and returns to
  // the Flutter ViewController.
  if (isolate->GetPhase() == DartIsolate::Phase::Running) {
    FML_DLOG(WARNING) << "Isolate was already running!";
    return RunStatus::FailureAlreadyRunning;
  }

  if (!isolate_configuration->PrepareIsolate(*isolate)) {
    FML_LOG(ERROR) << "Could not prepare to run the isolate.";
    return RunStatus::Failure;
  }

  if (configuration.GetEntrypointLibrary().empty()) {
    if (!isolate->Run(configuration.GetEntrypoint(),
                      settings_.dart_entrypoint_args)) {
      FML_LOG(ERROR) << "Could not run the isolate.";
      return RunStatus::Failure;
    }
  } else {
    if (!isolate->RunFromLibrary(configuration.GetEntrypointLibrary(),
                                 configuration.GetEntrypoint(),
                                 settings_.dart_entrypoint_args)) {
      FML_LOG(ERROR) << "Could not run the isolate.";
      return RunStatus::Failure;
    }
  }

  return RunStatus::Success;
}

void Engine::BeginFrame(fml::TimePoint frame_time) {
  TRACE_EVENT0("flutter", "Engine::BeginFrame");
  runtime_controller_->BeginFrame(frame_time);
}

void Engine::ReportTimings(std::vector<int64_t> timings) {
  TRACE_EVENT0("flutter", "Engine::ReportTimings");
  runtime_controller_->ReportTimings(std::move(timings));
}

void Engine::NotifyIdle(int64_t deadline) {
  auto trace_event = std::to_string(deadline - Dart_TimelineGetMicros());
  TRACE_EVENT1("flutter", "Engine::NotifyIdle", "deadline_now_delta",
               trace_event.c_str());
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

void Engine::OnOutputSurfaceCreated() {
  have_surface_ = true;
  StartAnimatorIfPossible();
  ScheduleFrame();
}

void Engine::OnOutputSurfaceDestroyed() {
  have_surface_ = false;
  StopAnimator();
}

void Engine::SetViewportMetrics(const ViewportMetrics& metrics) {
  bool dimensions_changed =
      viewport_metrics_.physical_height != metrics.physical_height ||
      viewport_metrics_.physical_width != metrics.physical_width ||
      viewport_metrics_.physical_depth != metrics.physical_depth;
  viewport_metrics_ = metrics;
  runtime_controller_->SetViewportMetrics(viewport_metrics_);
  if (animator_) {
    if (dimensions_changed)
      animator_->SetDimensionChangePending();
    if (have_surface_)
      ScheduleFrame();
  }
}

void Engine::DispatchPlatformMessage(fml::RefPtr<PlatformMessage> message) {
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
  if (message->channel() == kNavigationChannel) {
    HandleNavigationPlatformMessage(std::move(message));
    return;
  }

  FML_DLOG(WARNING) << "Dropping platform message on channel: "
                    << message->channel();
}

bool Engine::HandleLifecyclePlatformMessage(PlatformMessage* message) {
  const auto& data = message->data();
  std::string state(reinterpret_cast<const char*>(data.data()), data.size());
  if (state == "AppLifecycleState.paused" ||
      state == "AppLifecycleState.detached") {
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
  runtime_controller_->SetLifecycleState(state);
  // Always forward these messages to the framework by returning false.
  return false;
}

bool Engine::HandleNavigationPlatformMessage(
    fml::RefPtr<PlatformMessage> message) {
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

bool Engine::HandleLocalizationPlatformMessage(PlatformMessage* message) {
  const auto& data = message->data();

  rapidjson::Document document;
  document.Parse(reinterpret_cast<const char*>(data.data()), data.size());
  if (document.HasParseError() || !document.IsObject())
    return false;
  auto root = document.GetObject();
  auto method = root.FindMember("method");
  if (method == root.MemberEnd())
    return false;
  const size_t strings_per_locale = 4;
  if (method->value == "setLocale") {
    // Decode and pass the list of locale data onwards to dart.
    auto args = root.FindMember("args");
    if (args == root.MemberEnd() || !args->value.IsArray())
      return false;

    if (args->value.Size() % strings_per_locale != 0)
      return false;
    std::vector<std::string> locale_data;
    for (size_t locale_index = 0; locale_index < args->value.Size();
         locale_index += strings_per_locale) {
      if (!args->value[locale_index].IsString() ||
          !args->value[locale_index + 1].IsString())
        return false;
      locale_data.push_back(args->value[locale_index].GetString());
      locale_data.push_back(args->value[locale_index + 1].GetString());
      locale_data.push_back(args->value[locale_index + 2].GetString());
      locale_data.push_back(args->value[locale_index + 3].GetString());
    }

    return runtime_controller_->SetLocales(locale_data);
  } else if (method->value == "setPlatformResolvedLocale") {
    // Decode and pass the single locale data onwards to dart.
    auto args = root.FindMember("args");
    if (args == root.MemberEnd() || !args->value.IsArray())
      return false;

    if (args->value.Size() != strings_per_locale)
      return false;

    std::vector<std::string> locale_data;
    if (!args->value[0].IsString() || !args->value[1].IsString())
      return false;
    locale_data.push_back(args->value[0].GetString());
    locale_data.push_back(args->value[1].GetString());
    locale_data.push_back(args->value[2].GetString());
    locale_data.push_back(args->value[3].GetString());

    return runtime_controller_->SetPlatformResolvedLocale(locale_data);
  }
  return false;
}

void Engine::HandleSettingsPlatformMessage(PlatformMessage* message) {
  const auto& data = message->data();
  std::string jsonData(reinterpret_cast<const char*>(data.data()), data.size());
  if (runtime_controller_->SetUserSettingsData(std::move(jsonData)) &&
      have_surface_) {
    ScheduleFrame();
  }
}

void Engine::DispatchPointerDataPacket(
    std::unique_ptr<PointerDataPacket> packet,
    uint64_t trace_flow_id) {
  TRACE_EVENT0("flutter", "Engine::DispatchPointerDataPacket");
  TRACE_FLOW_STEP("flutter", "PointerEvent", trace_flow_id);
  pointer_data_dispatcher_->DispatchPacket(std::move(packet), trace_flow_id);
}

void Engine::DispatchSemanticsAction(int id,
                                     SemanticsAction action,
                                     std::vector<uint8_t> args) {
  runtime_controller_->DispatchSemanticsAction(id, action, std::move(args));
}

void Engine::SetSemanticsEnabled(bool enabled) {
  runtime_controller_->SetSemanticsEnabled(enabled);
}

void Engine::SetAccessibilityFeatures(int32_t flags) {
  runtime_controller_->SetAccessibilityFeatures(flags);
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

void Engine::Render(std::unique_ptr<flutter::LayerTree> layer_tree) {
  if (!layer_tree)
    return;

  // Ensure frame dimensions are sane.
  if (layer_tree->frame_size().isEmpty() ||
      layer_tree->frame_physical_depth() <= 0.0f ||
      layer_tree->frame_device_pixel_ratio() <= 0.0f)
    return;

  animator_->Render(std::move(layer_tree));
}

void Engine::UpdateSemantics(SemanticsNodeUpdates update,
                             CustomAccessibilityActionUpdates actions) {
  delegate_.OnEngineUpdateSemantics(std::move(update), std::move(actions));
}

void Engine::HandlePlatformMessage(fml::RefPtr<PlatformMessage> message) {
  if (message->channel() == kAssetChannel) {
    HandleAssetPlatformMessage(std::move(message));
  } else {
    delegate_.OnEngineHandlePlatformMessage(std::move(message));
  }
}

void Engine::UpdateIsolateDescription(const std::string isolate_name,
                                      int64_t isolate_port) {
  delegate_.UpdateIsolateDescription(isolate_name, isolate_port);
}

void Engine::SetNeedsReportTimings(bool needs_reporting) {
  delegate_.SetNeedsReportTimings(needs_reporting);
}

FontCollection& Engine::GetFontCollection() {
  return font_collection_;
}

void Engine::DoDispatchPacket(std::unique_ptr<PointerDataPacket> packet,
                              uint64_t trace_flow_id) {
  animator_->EnqueueTraceFlowId(trace_flow_id);
  if (runtime_controller_) {
    runtime_controller_->DispatchPointerDataPacket(*packet);
  }
}

void Engine::ScheduleSecondaryVsyncCallback(const fml::closure& callback) {
  animator_->ScheduleSecondaryVsyncCallback(callback);
}

void Engine::HandleAssetPlatformMessage(fml::RefPtr<PlatformMessage> message) {
  fml::RefPtr<PlatformMessageResponse> response = message->response();
  if (!response) {
    return;
  }
  const auto& data = message->data();
  std::string asset_name(reinterpret_cast<const char*>(data.data()),
                         data.size());

  if (asset_manager_) {
    std::unique_ptr<fml::Mapping> asset_mapping =
        asset_manager_->GetAsMapping(asset_name);
    if (asset_mapping) {
      response->Complete(std::move(asset_mapping));
      return;
    }
  }

  response->CompleteEmpty();
}

const std::string& Engine::GetLastEntrypoint() const {
  return last_entry_point_;
}

const std::string& Engine::GetLastEntrypointLibrary() const {
  return last_entry_point_library_;
}

}  // namespace flutter
