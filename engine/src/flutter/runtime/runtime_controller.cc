// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/runtime/runtime_controller.h"

#include "flutter/glue/trace_event.h"
#include "flutter/lib/ui/compositing/scene.h"
#include "flutter/lib/ui/ui_dart_state.h"
#include "flutter/lib/ui/window/window.h"
#include "flutter/runtime/dart_controller.h"
#include "flutter/runtime/runtime_delegate.h"

using tonic::DartState;

namespace blink {

std::unique_ptr<RuntimeController> RuntimeController::Create(
    RuntimeDelegate* client) {
  return std::unique_ptr<RuntimeController>(new RuntimeController(client));
}

RuntimeController::RuntimeController(RuntimeDelegate* client)
    : client_(client) {}

RuntimeController::~RuntimeController() {}

void RuntimeController::CreateDartController(const std::string& script_uri) {
  FTL_DCHECK(!dart_controller_);

  dart_controller_.reset(new DartController());
  std::unique_ptr<Window> window(new Window(this));
  dart_controller_->CreateIsolateFor(
      script_uri,
      std::unique_ptr<UIDartState>(new UIDartState(this, std::move(window))));

  UIDartState* dart_state = dart_controller_->dart_state();
  DartState::Scope scope(dart_state);
  dart_state->window()->DidCreateIsolate();
  client_->DidCreateMainIsolate(dart_state->isolate());

  if (viewport_metrics_)
    GetWindow()->UpdateWindowMetrics(viewport_metrics_);
  GetWindow()->UpdateLocale(language_code_, country_code_);
}

void RuntimeController::SetViewportMetrics(
    const sky::ViewportMetricsPtr& metrics) {
  if (metrics) {
    viewport_metrics_ = metrics->Clone();
    GetWindow()->UpdateWindowMetrics(viewport_metrics_);
  } else {
    viewport_metrics_ = nullptr;
  }
}

void RuntimeController::SetLocale(const std::string& language_code,
                                  const std::string& country_code) {
  if (language_code_ == language_code && country_code_ == country_code)
    return;

  language_code_ = language_code;
  country_code_ = country_code;
  GetWindow()->UpdateLocale(language_code_, country_code_);
}

void RuntimeController::PushRoute(const std::string& route) {
  GetWindow()->PushRoute(route);
}

void RuntimeController::PopRoute() {
  GetWindow()->PopRoute();
}

void RuntimeController::BeginFrame(ftl::TimePoint frame_time) {
  GetWindow()->BeginFrame(frame_time);
}

void RuntimeController::HandlePointerPacket(
    const pointer::PointerPacketPtr& packet) {
  TRACE_EVENT0("input", "RuntimeController::HandlePointerPacket");
  GetWindow()->DispatchPointerPacket(packet);
}

Window* RuntimeController::GetWindow() {
  return dart_controller_->dart_state()->window();
}

void RuntimeController::ScheduleFrame() {
  client_->ScheduleFrame();
}

void RuntimeController::Render(Scene* scene) {
  client_->Render(scene->takeLayerTree());
}

void RuntimeController::DidCreateSecondaryIsolate(Dart_Isolate isolate) {
  client_->DidCreateSecondaryIsolate(isolate);
}

void RuntimeController::OnAppLifecycleStateChanged(
    sky::AppLifecycleState state) {
  GetWindow()->OnAppLifecycleStateChanged(state);
}

Dart_Port RuntimeController::GetMainPort() {
  if (!dart_controller_) {
    return ILLEGAL_PORT;
  }
  if (!dart_controller_->dart_state()) {
    return ILLEGAL_PORT;
  }
  return dart_controller_->dart_state()->main_port();
}

std::string RuntimeController::GetIsolateName() {
  if (!dart_controller_) {
    return "";
  }
  if (!dart_controller_->dart_state()) {
    return "";
  }
  return dart_controller_->dart_state()->debug_name();
}


}  // namespace blink
