// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_controller.h"

#include "flutter/fml/message_loop.h"
#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/runtime_delegate.h"
#include "lib/tonic/dart_message_handler.h"

namespace blink {

RuntimeController::RuntimeController(
    RuntimeDelegate& p_client,
    const DartVM* p_vm,
    TaskRunners p_task_runners,
    fml::WeakPtr<GrContext> p_resource_context,
    fxl::RefPtr<flow::SkiaUnrefQueue> p_unref_queue)
    : RuntimeController(p_client,
                        p_vm,
                        std::move(p_task_runners),
                        std::move(p_resource_context),
                        std::move(p_unref_queue),
                        WindowData{/* default window data */}) {}

RuntimeController::RuntimeController(
    RuntimeDelegate& p_client,
    const DartVM* p_vm,
    TaskRunners p_task_runners,
    fml::WeakPtr<GrContext> p_resource_context,
    fxl::RefPtr<flow::SkiaUnrefQueue> p_unref_queue,
    WindowData p_window_data)
    : client_(p_client),
      vm_(p_vm),
      task_runners_(p_task_runners),
      resource_context_(p_resource_context),
      unref_queue_(p_unref_queue),
      window_data_(std::move(p_window_data)),
      root_isolate_(
          DartIsolate::CreateRootIsolate(vm_,
                                         vm_->GetIsolateSnapshot(),
                                         task_runners_,
                                         std::make_unique<Window>(this),
                                         resource_context_,
                                         unref_queue_)) {
  root_isolate_->SetReturnCodeCallback([this](uint32_t code) {
    root_isolate_return_code_ = {true, code};
  });
  if (auto window = GetWindowIfAvailable()) {
    tonic::DartState::Scope scope(root_isolate_.get());
    window->DidCreateIsolate();
    if (!FlushRuntimeStateToIsolate()) {
      FXL_DLOG(ERROR) << "Could not setup intial isolate state.";
    }
  } else {
    FXL_DCHECK(false) << "RuntimeController created without window binding.";
  }
  FXL_DCHECK(Dart_CurrentIsolate() == nullptr);
}

RuntimeController::~RuntimeController() {
  FXL_DCHECK(Dart_CurrentIsolate() == nullptr);
  if (root_isolate_) {
    root_isolate_->SetReturnCodeCallback(nullptr);
    auto result = root_isolate_->Shutdown();
    if (!result) {
      FXL_DLOG(ERROR) << "Could not shutdown the root isolate.";
    }
    root_isolate_ = {};
  }
}

std::unique_ptr<RuntimeController> RuntimeController::Clone() const {
  return std::unique_ptr<RuntimeController>(new RuntimeController(
      client_,            //
      vm_,                //
      task_runners_,      //
      resource_context_,  //
      unref_queue_,       //
      window_data_        //
      ));
}

bool RuntimeController::FlushRuntimeStateToIsolate() {
  return SetViewportMetrics(window_data_.viewport_metrics) &&
         SetLocale(window_data_.language_code, window_data_.country_code) &&
         SetSemanticsEnabled(window_data_.semantics_enabled);
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

bool RuntimeController::BeginFrame(fxl::TimePoint frame_time) {
  if (auto window = GetWindowIfAvailable()) {
    window->BeginFrame(frame_time);
    return true;
  }
  return false;
}

bool RuntimeController::NotifyIdle(int64_t deadline) {
  if (!root_isolate_) {
    return false;
  }

  tonic::DartState::Scope scope(root_isolate_.get());
  Dart_NotifyIdle(deadline);
  return true;
}

bool RuntimeController::DispatchPlatformMessage(
    fxl::RefPtr<PlatformMessage> message) {
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
  return root_isolate_ ? root_isolate_->window() : nullptr;
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
    client_.UpdateSemantics(update->takeNodes());
  }
}

void RuntimeController::HandlePlatformMessage(
    fxl::RefPtr<PlatformMessage> message) {
  client_.HandlePlatformMessage(std::move(message));
}

Dart_Port RuntimeController::GetMainPort() {
  return root_isolate_ ? root_isolate_->main_port() : ILLEGAL_PORT;
}

std::string RuntimeController::GetIsolateName() {
  return root_isolate_ ? root_isolate_->debug_name() : "";
}

bool RuntimeController::HasLivePorts() {
  if (!root_isolate_) {
    return false;
  }
  tonic::DartState::Scope scope(root_isolate_.get());
  return Dart_HasLivePorts();
}

tonic::DartErrorHandleType RuntimeController::GetLastError() {
  return root_isolate_ ? root_isolate_->message_handler().isolate_last_error()
                       : tonic::kNoError;
}

fml::WeakPtr<DartIsolate> RuntimeController::GetRootIsolate() {
  return root_isolate_;
}

std::pair<bool, uint32_t> RuntimeController::GetRootIsolateReturnCode() {
  return root_isolate_return_code_;
}

}  // namespace blink
