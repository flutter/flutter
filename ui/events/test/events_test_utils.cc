// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/test/events_test_utils.h"

#include "ui/events/event_source.h"

namespace ui {

EventTestApi::EventTestApi(Event* event) : event_(event) {}
EventTestApi::~EventTestApi() {}

LocatedEventTestApi::LocatedEventTestApi(LocatedEvent* event)
    : EventTestApi(event),
      located_event_(event) {}
LocatedEventTestApi::~LocatedEventTestApi() {}

KeyEventTestApi::KeyEventTestApi(KeyEvent* event)
    : EventTestApi(event),
      key_event_(event) {}
KeyEventTestApi::~KeyEventTestApi() {}

EventTargetTestApi::EventTargetTestApi(EventTarget* target)
    : target_(target) {}

EventSourceTestApi::EventSourceTestApi(EventSource* event_source)
    : event_source_(event_source) {
  DCHECK(event_source);
}

EventDispatchDetails EventSourceTestApi::SendEventToProcessor(Event* event) {
  return event_source_->SendEventToProcessor(event);
}

}  // namespace ui
