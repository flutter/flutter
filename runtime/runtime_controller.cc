// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_controller.h"

#include "flutter/fml/message_loop.h"
#include "flutter/fml/trace_event.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/runtime_delegate.h"
#include "third_party/tonic/dart_message_handler.h"

#ifdef ERROR
#undef ERROR
#endif

namespace blink {

RuntimeController::RuntimeController(
    RuntimeDelegate& p_client,
    DartVM* p_vm,
    fml::RefPtr<DartSnapshot> p_isolate_snapshot,
    fml::RefPtr<DartSnapshot> p_shared_snapshot,
    TaskRunners p_task_runners,
    fml::WeakPtr<GrContext> p_resource_context,
    fml::RefPtr<flow::SkiaUnrefQueue> p_unref_queue,
    std::string p_advisory_script_uri,
    std::string p_advisory_script_entrypoint)
    : RuntimeController(p_client,
                        p_vm,
                        std::move(p_isolate_snapshot),
                        std::move(p_shared_snapshot),
                        std::move(p_task_runners),
                        std::move(p_resource_context),
                        std::move(p_unref_queue),
                        std::move(p_advisory_script_uri),
                        std::move(p_advisory_script_entrypoint),
                        WindowData{/* default window data */}) {}

RuntimeController::RuntimeController(
    RuntimeDelegate& p_client,
    DartVM* p_vm,
    fml::RefPtr<DartSnapshot> p_isolate_snapshot,
    fml::RefPtr<DartSnapshot> p_shared_snapshot,
    TaskRunners p_task_runners,
    fml::WeakPtr<GrContext> p_resource_context,
    fml::RefPtr<flow::SkiaUnrefQueue> p_unref_queue,
    std::string p_advisory_script_uri,
    std::string p_advisory_script_entrypoint,
    WindowData p_window_data)
    : client_(p_client),
      vm_(p_vm),
      isolate_snapshot_(std::move(p_isolate_snapshot)),
      shared_snapshot_(std::move(p_shared_snapshot)),
      task_runners_(p_task_runners),
      resource_context_(p_resource_context),
      unref_queue_(p_unref_queue),
      advisory_script_uri_(p_advisory_script_uri),
      advisory_script_entrypoint_(p_advisory_script_entrypoint),
      window_data_(std::move(p_window_data)),
      root_isolate_(
          DartIsolate::CreateRootIsolate(vm_,
                                         isolate_snapshot_,
                                         shared_snapshot_,
                                         task_runners_,
                                         std::make_unique<Window>(this),
                                         resource_context_,
                                         unref_queue_,
                                         p_advisory_script_uri,
                                         p_advisory_script_entrypoint)) {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  root_isolate->SetReturnCodeCallback([this](uint32_t code) {
    root_isolate_return_code_ = {true, code};
  });
  if (auto window = GetWindowIfAvailable()) {
    tonic::DartState::Scope scope(root_isolate);
    window->DidCreateIsolate();
    if (!FlushRuntimeStateToIsolate()) {
      FML_DLOG(ERROR) << "Could not setup intial isolate state.";
    }
  } else {
    FML_DCHECK(false) << "RuntimeController created without window binding.";
  }
  FML_DCHECK(Dart_CurrentIsolate() == nullptr);
}

RuntimeController::~RuntimeController() {
  FML_DCHECK(Dart_CurrentIsolate() == nullptr);
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  if (root_isolate) {
    root_isolate->SetReturnCodeCallback(nullptr);
    auto result = root_isolate->Shutdown();
    if (!result) {
      FML_DLOG(ERROR) << "Could not shutdown the root isolate.";
    }
    root_isolate_ = {};
  }
}

bool RuntimeController::IsRootIsolateRunning() const {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  if (root_isolate) {
    return root_isolate->GetPhase() == DartIsolate::Phase::Running;
  }
  return false;
}

std::unique_ptr<RuntimeController> RuntimeController::Clone() const {
  return std::unique_ptr<RuntimeController>(new RuntimeController(
      client_,                      //
      vm_,                          //
      isolate_snapshot_,            //
      shared_snapshot_,             //
      task_runners_,                //
      resource_context_,            //
      unref_queue_,                 //
      advisory_script_uri_,         //
      advisory_script_entrypoint_,  //
      window_data_                  //
      ));
}

bool RuntimeController::FlushRuntimeStateToIsolate() {
  return SetViewportMetrics(window_data_.viewport_metrics) &&
         SetLocale(window_data_.language_code, window_data_.country_code) &&
         SetSemanticsEnabled(window_data_.semantics_enabled) &&
         SetAccessibilityFeatures(window_data_.accessibility_feature_flags_);
}

bool RuntimeController::SetViewportMetrics(const ViewportMetrics& metrics) {
  window_data_.viewport_metrics = metrics;

  if (auto window = GetWindowIfAvailable()) {
    window->UpdateWindowMetrics(metrics);
    return true;
  }
  return false;
}

bool RuntimeController::SetLocale(const std::string& language_code,
                                  const std::string& country_code) {
  window_data_.language_code = language_code;
  window_data_.country_code = country_code;

  if (auto window = GetWindowIfAvailable()) {
    window->UpdateLocale(window_data_.language_code, window_data_.country_code);
    return true;
  }

  return false;
}

bool RuntimeController::SetUserSettingsData(const std::string& data) {
  window_data_.user_settings_data = data;

  if (auto window = GetWindowIfAvailable()) {
    window->UpdateUserSettingsData(window_data_.user_settings_data);
    return true;
  }

  return false;
}

bool RuntimeController::SetSemanticsEnabled(bool enabled) {
  window_data_.semantics_enabled = enabled;

  if (auto window = GetWindowIfAvailable()) {
    window->UpdateSemanticsEnabled(window_data_.semantics_enabled);
    return true;
  }

  return false;
}

bool RuntimeController::SetAccessibilityFeatures(int32_t flags) {
  window_data_.accessibility_feature_flags_ = flags;
  if (auto window = GetWindowIfAvailable()) {
    window->UpdateAccessibilityFeatures(
        window_data_.accessibility_feature_flags_);
    return true;
  }

  return false;
}

bool RuntimeController::BeginFrame(fml::TimePoint frame_time) {
  if (auto window = GetWindowIfAvailable()) {
    window->BeginFrame(frame_time);
    return true;
  }
  return false;
}

bool RuntimeController::NotifyIdle(int64_t deadline) {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  if (!root_isolate) {
    return false;
  }

  tonic::DartState::Scope scope(root_isolate);
  Dart_NotifyIdle(deadline);
  return true;
}

bool RuntimeController::DispatchPlatformMessage(
    fml::RefPtr<PlatformMessage> message) {
  if (auto window = GetWindowIfAvailable()) {
    TRACE_EVENT1("flutter", "RuntimeController::DispatchPlatformMessage",
                 "mode", "basic");
    window->DispatchPlatformMessage(std::move(message));
    return true;
  }
  return false;
}

bool RuntimeController::DispatchPointerDataPacket(
    const PointerDataPacket& packet) {
  if (auto window = GetWindowIfAvailable()) {
    TRACE_EVENT1("flutter", "RuntimeController::DispatchPointerDataPacket",
                 "mode", "basic");
    window->DispatchPointerDataPacket(packet);
    return true;
  }
  return false;
}

bool RuntimeController::DispatchSemanticsAction(int32_t id,
                                                SemanticsAction action,
                                                std::vector<uint8_t> args) {
  TRACE_EVENT1("flutter", "RuntimeController::DispatchSemanticsAction", "mode",
               "basic");
  if (auto window = GetWindowIfAvailable()) {
    window->DispatchSemanticsAction(id, action, std::move(args));
    return true;
  }
  return false;
}

Window* RuntimeController::GetWindowIfAvailable() {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  return root_isolate ? root_isolate->window() : nullptr;
}

std::string RuntimeController::DefaultRouteName() {
  return client_.DefaultRouteName();
}

void RuntimeController::ScheduleFrame() {
  client_.ScheduleFrame();
}

void RuntimeController::Render(Scene* scene) {
  client_.Render(scene->takeLayerTree());
}

void RuntimeController::UpdateSemantics(SemanticsUpdate* update) {
  if (window_data_.semantics_enabled) {
    client_.UpdateSemantics(update->takeNodes(), update->takeActions());
  }
}

void RuntimeController::HandlePlatformMessage(
    fml::RefPtr<PlatformMessage> message) {
  client_.HandlePlatformMessage(std::move(message));
}

FontCollection& RuntimeController::GetFontCollection() {
  return client_.GetFontCollection();
}

Dart_Port RuntimeController::GetMainPort() {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  return root_isolate ? root_isolate->main_port() : ILLEGAL_PORT;
}

std::string RuntimeController::GetIsolateName() {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  return root_isolate ? root_isolate->debug_name() : "";
}

bool RuntimeController::HasLivePorts() {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  if (!root_isolate) {
    return false;
  }
  tonic::DartState::Scope scope(root_isolate);
  return Dart_HasLivePorts();
}

tonic::DartErrorHandleType RuntimeController::GetLastError() {
  std::shared_ptr<DartIsolate> root_isolate = root_isolate_.lock();
  return root_isolate ? root_isolate->GetLastError() : tonic::kNoError;
}

std::weak_ptr<DartIsolate> RuntimeController::GetRootIsolate() {
  return root_isolate_;
}

std::pair<bool, uint32_t> RuntimeController::GetRootIsolateReturnCode() {
  return root_isolate_return_code_;
}

}  // namespace blink
