// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/sky/sky_view.h"

#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/core/compositing/Scene.h"
#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/core/window/window.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/sky/sky_view_client.h"
#include "sky/engine/wtf/MakeUnique.h"

namespace blink {

std::unique_ptr<SkyView> SkyView::Create(SkyViewClient* client) {
  return std::unique_ptr<SkyView>(new SkyView(client));
}

SkyView::SkyView(SkyViewClient* client)
    : client_(client),
      weak_factory_(this) {
}

SkyView::~SkyView() {
}

void SkyView::SetDisplayMetrics(const SkyDisplayMetrics& metrics) {
  display_metrics_ = metrics;
  GetWindow()->UpdateWindowMetrics(display_metrics_);
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

void SkyView::CreateView(const String& name) {
  DCHECK(!dart_controller_);

  dart_controller_ = WTF::MakeUnique<DartController>();
  dart_controller_->CreateIsolateFor(WTF::MakeUnique<DOMDartState>(
      WTF::MakeUnique<Window>(this), name));

  DOMDartState* dart_state = dart_controller_->dart_state();
  DartState::Scope scope(dart_state);
  dart_state->window()->DidCreateIsolate();
  client_->DidCreateIsolate(dart_state->isolate());

  GetWindow()->UpdateWindowMetrics(display_metrics_);
  GetWindow()->UpdateLocale(language_code_, country_code_);
}

void SkyView::RunFromLibrary(const WebString& name,
                             DartLibraryProvider* library_provider) {
  dart_controller_->RunFromLibrary(name, library_provider);
}

void SkyView::RunFromPrecompiledSnapshot() {
  dart_controller_->RunFromPrecompiledSnapshot();
}

void SkyView::RunFromSnapshot(const WebString& name,
                              mojo::ScopedDataPipeConsumerHandle snapshot) {
  dart_controller_->RunFromSnapshot(snapshot.Pass());
}

std::unique_ptr<sky::compositor::LayerTree> SkyView::BeginFrame(
    base::TimeTicks frame_time) {
  GetWindow()->BeginFrame(frame_time);
  return std::move(layer_tree_);
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

void SkyView::Render(Scene* scene) {
  layer_tree_ = scene->takeLayerTree();
}

void SkyView::OnAppLifecycleStateChanged(sky::AppLifecycleState state) {
  GetWindow()->OnAppLifecycleStateChanged(state);
}

} // namespace blink
