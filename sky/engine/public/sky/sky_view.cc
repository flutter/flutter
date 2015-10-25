// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/sky/sky_view.h"

#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/PointerEvent.h"
#include "sky/engine/core/events/WheelEvent.h"
#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/core/view/View.h"
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
  view_->setDisplayMetrics(display_metrics_);
}

void SkyView::CreateView(const String& name) {
  DCHECK(!view_);
  DCHECK(!dart_controller_);

  view_ = View::create(
      base::Bind(&SkyView::ScheduleFrame, weak_factory_.GetWeakPtr()));

  dart_controller_ = WTF::MakeUnique<DartController>();
  dart_controller_->CreateIsolateFor(WTF::MakeUnique<DOMDartState>(
      WTF::MakeUnique<Window>(this), name));

  DOMDartState* dart_state = dart_controller_->dart_state();
  DartState::Scope scope(dart_state);
  dart_controller_->InstallView(view_.get());
  dart_state->window()->DidCreateIsolate();
  client_->DidCreateIsolate(dart_state->isolate());

  GetWindow()->UpdateWindowMetrics(display_metrics_);
  view_->setDisplayMetrics(display_metrics_);
}

void SkyView::RunFromLibrary(const WebString& name,
                             DartLibraryProvider* library_provider) {
  DCHECK(view_);
  dart_controller_->RunFromLibrary(name, library_provider);
}

void SkyView::RunFromPrecompiledSnapshot() {
  DCHECK(view_);
  dart_controller_->RunFromPrecompiledSnapshot();
}

void SkyView::RunFromSnapshot(const WebString& name,
                              mojo::ScopedDataPipeConsumerHandle snapshot) {
  DCHECK(view_);
  dart_controller_->RunFromSnapshot(snapshot.Pass());
}

std::unique_ptr<sky::compositor::LayerTree> SkyView::BeginFrame(
    base::TimeTicks frame_time) {
  GetWindow()->BeginFrame(frame_time);
  return view_->beginFrame(frame_time);
}

void SkyView::HandleInputEvent(const WebInputEvent& inputEvent) {
  TRACE_EVENT0("input", "SkyView::HandleInputEvent");

  RefPtr<Event> event;

  if (WebInputEvent::isPointerEventType(inputEvent.type)) {
    const WebPointerEvent& webEvent = static_cast<const WebPointerEvent&>(inputEvent);
    event = PointerEvent::create(webEvent);
  } else if (WebInputEvent::isKeyboardEventType(inputEvent.type)) {
    const WebKeyboardEvent& webEvent = static_cast<const WebKeyboardEvent&>(inputEvent);
    event = KeyboardEvent::create(webEvent);
  } else if (WebInputEvent::isWheelEventType(inputEvent.type)) {
    const WebWheelEvent& webEvent = static_cast<const WebWheelEvent&>(inputEvent);
    event = WheelEvent::create(webEvent);
  } else if (inputEvent.type == WebInputEvent::Back) {
    event = Event::create("back");
  }

  if (event) {
    GetWindow()->DispatchEvent(event.get());
    view_->handleInputEvent(event);
  }
}

Window* SkyView::GetWindow() {
  return dart_controller_->dart_state()->window();
}

void SkyView::ScheduleFrame() {
  client_->ScheduleFrame();
}

void SkyView::Render(Scene* scene) {
  client_->Render(scene->takeLayerTree());
}

void SkyView::StartDartTracing() {
  dart_controller_->StartTracing();
}

void SkyView::StopDartTracing(mojo::ScopedDataPipeProducerHandle producer) {
  dart_controller_->StopTracing(producer.Pass());
}

} // namespace blink
