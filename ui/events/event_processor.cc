// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/event_processor.h"

#include "ui/events/event_target.h"
#include "ui/events/event_targeter.h"

namespace ui {

EventDispatchDetails EventProcessor::OnEventFromSource(Event* event) {
  EventTarget* root = GetRootTarget();
  CHECK(root);
  EventTargeter* targeter = root->GetEventTargeter();
  CHECK(targeter);

  // If |event| is in the process of being dispatched or has already been
  // dispatched, then dispatch a copy of the event instead.
  bool dispatch_original_event = event->phase() == EP_PREDISPATCH;
  Event* event_to_dispatch = event;
  scoped_ptr<Event> event_copy;
  if (!dispatch_original_event) {
    event_copy = Event::Clone(*event);
    event_to_dispatch = event_copy.get();
  }

  OnEventProcessingStarted(event_to_dispatch);
  EventTarget* target = NULL;
  if (!event_to_dispatch->handled())
    target = targeter->FindTargetForEvent(root, event_to_dispatch);

  EventDispatchDetails details;
  while (target) {
    details = DispatchEvent(target, event_to_dispatch);

    if (!dispatch_original_event) {
      if (event_to_dispatch->stopped_propagation())
        event->StopPropagation();
      else if (event_to_dispatch->handled())
        event->SetHandled();
    }

    if (details.dispatcher_destroyed)
      return details;

    if (details.target_destroyed || event->handled())
      break;

    target = targeter->FindNextBestTarget(target, event_to_dispatch);
  }

  OnEventProcessingFinished(event);
  return details;
}

void EventProcessor::OnEventProcessingStarted(Event* event) {
}

void EventProcessor::OnEventProcessingFinished(Event* event) {
}

}  // namespace ui
