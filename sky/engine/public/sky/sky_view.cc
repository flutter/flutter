// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/sky/sky_view.h"

#include "flutter/lib/ui/compositing/scene.h"
#include "glue/trace_event.h"
#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/ui_dart_state.h"
#include "sky/engine/core/window/window.h"
#include "sky/engine/public/sky/sky_view_client.h"
#include "sky/engine/wtf/MakeUnique.h"

namespace blink {

std::unique_ptr<SkyView> SkyView::Create(SkyViewClient* client) {
  return std::unique_ptr<SkyView>(new SkyView(client));
}

SkyView::SkyView(SkyViewClient* client)
    : client_(client) {}

SkyView::~SkyView() {}

void SkyView::SetViewportMetrics(const sky::ViewportMetricsPtr& metrics) {
  if (metrics) {
    viewport_metrics_ = metrics->Clone();
    GetWindow()->UpdateWindowMetrics(viewport_metrics_);
  } else {
    viewport_metrics_ = nullptr;
  }
}

void SkyView::SetLocale(const std::string& language_code,
                        const std::string& country_code) {
  if (language_code_ == language_code && country_code_ == country_code)
    return;

  language_code_ = language_code;
  country_code_ = country_code;
  GetWindow()->UpdateLocale(language_code_, country_code_);
}

void SkyView::PushRoute(const std::string& route) {
  GetWindow()->PushRoute(route);
}

void SkyView::PopRoute() {
  GetWindow()->PopRoute();
}

void SkyView::CreateView(const std::string& script_uri) {
  DCHECK(!dart_controller_);

  dart_controller_ = WTF::MakeUnique<DartController>();
  dart_controller_->CreateIsolateFor(WTF::MakeUnique<UIDartState>(
      this, script_uri, WTF::MakeUnique<Window>(this)));

  UIDartState* dart_state = dart_controller_->dart_state();
  DartState::Scope scope(dart_state);
  dart_state->window()->DidCreateIsolate();
  client_->DidCreateMainIsolate(dart_state->isolate());

  if (viewport_metrics_)
    GetWindow()->UpdateWindowMetrics(viewport_metrics_);
  GetWindow()->UpdateLocale(language_code_, country_code_);
}

void SkyView::RunFromLibrary(const std::string& name,
                             DartLibraryProvider* library_provider) {
  dart_controller_->RunFromLibrary(name, library_provider);
}

void SkyView::RunFromPrecompiledSnapshot() {
  dart_controller_->RunFromPrecompiledSnapshot();
}

void SkyView::RunFromSnapshot(mojo::ScopedDataPipeConsumerHandle snapshot) {
  dart_controller_->RunFromSnapshot(snapshot.Pass());
}

void SkyView::BeginFrame(ftl::TimePoint frame_time) {
  GetWindow()->BeginFrame(frame_time);
}

void SkyView::HandlePointerPacket(const pointer::PointerPacketPtr& packet) {
  TRACE_EVENT0("input", "SkyView::HandlePointerPacket");
  GetWindow()->DispatchPointerPacket(packet);
}

Window* SkyView::GetWindow() {
  return dart_controller_->dart_state()->window();
}

void SkyView::ScheduleFrame() {
  client_->ScheduleFrame();
}

void SkyView::FlushRealTimeEvents() {
  client_->FlushRealTimeEvents();
}

void SkyView::Render(Scene* scene) {
  client_->Render(scene->takeLayerTree());
}

void SkyView::DidCreateSecondaryIsolate(Dart_Isolate isolate) {
  client_->DidCreateSecondaryIsolate(isolate);
}

void SkyView::OnAppLifecycleStateChanged(sky::AppLifecycleState state) {
  GetWindow()->OnAppLifecycleStateChanged(state);
}

Dart_Port SkyView::GetMainPort() {
  if (!dart_controller_) {
    return ILLEGAL_PORT;
  }
  if (!dart_controller_->dart_state()) {
    return ILLEGAL_PORT;
  }
  return dart_controller_->dart_state()->main_port();
}


}  // namespace blink
