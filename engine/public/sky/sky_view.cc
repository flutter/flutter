// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/engine/public/sky/sky_view.h"

#include "base/bind.h"
#include "base/trace_event/trace_event.h"
#include "sky/engine/core/events/GestureEvent.h"
#include "sky/engine/core/events/KeyboardEvent.h"
#include "sky/engine/core/events/PointerEvent.h"
#include "sky/engine/core/events/WheelEvent.h"
#include "sky/engine/core/script/dart_controller.h"
#include "sky/engine/core/script/dom_dart_state.h"
#include "sky/engine/core/view/View.h"
#include "sky/engine/platform/weborigin/KURL.h"
#include "sky/engine/public/platform/WebInputEvent.h"
#include "sky/engine/public/sky/sky_view_client.h"

namespace blink {

std::unique_ptr<SkyView> SkyView::Create(SkyViewClient* client) {
  return std::unique_ptr<SkyView>(new SkyView(client));
}

SkyView::SkyView(SkyViewClient* client)
    : client_(client),
      weak_factory_(this) {
}

SkyView::~SkyView() {
  // TODO(abarth): Move this work into the DartController destructor once we
  // remove the Frame code path.
  if (dart_controller_)
    dart_controller_->ClearForClose();
}

void SkyView::SetDisplayMetrics(const SkyDisplayMetrics& metrics) {
  display_metrics_ = metrics;
  view_->setDisplayMetrics(display_metrics_);
}

void SkyView::RunFromLibrary(const WebString& name,
                             DartLibraryProvider* library_provider) {
  CreateView(name);
  dart_controller_->RunFromLibrary(name, library_provider);
}

void SkyView::RunFromSnapshot(const WebString& name,
                              mojo::ScopedDataPipeConsumerHandle snapshot) {
  CreateView(name);
  dart_controller_->RunFromSnapshot(snapshot.Pass());
}

void SkyView::BeginFrame(base::TimeTicks frame_time) {
  view_->beginFrame(frame_time);
}

skia::RefPtr<SkPicture> SkyView::Paint() {
  if (Picture* picture = view_->picture())
    return skia::SharePtr(picture->toSkia());
  return skia::RefPtr<SkPicture>();
}

void SkyView::HandleInputEvent(const WebInputEvent& inputEvent) {
  TRACE_EVENT0("input", "SkyView::HandleInputEvent");

  if (WebInputEvent::isPointerEventType(inputEvent.type)) {
      const WebPointerEvent& event = static_cast<const WebPointerEvent&>(inputEvent);
      view_->handleInputEvent(PointerEvent::create(event));
  } else if (WebInputEvent::isGestureEventType(inputEvent.type)) {
      const WebGestureEvent& event = static_cast<const WebGestureEvent&>(inputEvent);
      view_->handleInputEvent(GestureEvent::create(event));
  } else if (WebInputEvent::isKeyboardEventType(inputEvent.type)) {
      const WebKeyboardEvent& event = static_cast<const WebKeyboardEvent&>(inputEvent);
      view_->handleInputEvent(KeyboardEvent::create(event));
  } else if (WebInputEvent::isWheelEventType(inputEvent.type)) {
      const WebWheelEvent& event = static_cast<const WebWheelEvent&>(inputEvent);
      view_->handleInputEvent(WheelEvent::create(event));
  } else if (inputEvent.type == WebInputEvent::Back) {
    view_->handleInputEvent(Event::create("back"));
  }

}

void SkyView::CreateView(const String& name) {
  DCHECK(!view_);
  DCHECK(!dart_controller_);

  view_ = View::create(
      base::Bind(&SkyView::ScheduleFrame, weak_factory_.GetWeakPtr()));
  view_->setDisplayMetrics(display_metrics_);

  dart_controller_ = adoptPtr(new DartController);
  dart_controller_->CreateIsolateFor(adoptPtr(new DOMDartState(nullptr, name)));
  dart_controller_->InstallView(view_.get());

  Dart_Isolate isolate = dart_controller_->dart_state()->isolate();
  DartIsolateScope scope(isolate);
  DartApiScope api_scope;
  client_->DidCreateIsolate(isolate);
}

void SkyView::ScheduleFrame() {
  client_->ScheduleFrame();
}

} // namespace blink
