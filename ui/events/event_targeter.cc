// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/event_targeter.h"

#include "ui/events/event.h"
#include "ui/events/event_target.h"
#include "ui/events/event_target_iterator.h"

namespace ui {

EventTargeter::~EventTargeter() {
}

EventTarget* EventTargeter::FindTargetForEvent(EventTarget* root,
                                               Event* event) {
  if (event->IsMouseEvent() ||
      event->IsScrollEvent() ||
      event->IsTouchEvent() ||
      event->IsGestureEvent()) {
    return FindTargetForLocatedEvent(root,
                                     static_cast<LocatedEvent*>(event));
  }
  return root;
}

EventTarget* EventTargeter::FindTargetForLocatedEvent(EventTarget* root,
                                                      LocatedEvent* event) {
  scoped_ptr<EventTargetIterator> iter = root->GetChildIterator();
  if (iter) {
    EventTarget* target = root;
    for (EventTarget* child = iter->GetNextTarget(); child;
         child = iter->GetNextTarget()) {
      EventTargeter* targeter = child->GetEventTargeter();
      if (!targeter)
        targeter = this;
      if (!targeter->SubtreeShouldBeExploredForEvent(child, *event))
        continue;
      target->ConvertEventToTarget(child, event);
      target = child;
      EventTarget* child_target =
          targeter->FindTargetForLocatedEvent(child, event);
      if (child_target)
        return child_target;
    }
    target->ConvertEventToTarget(root, event);
  }
  return root->CanAcceptEvent(*event) ? root : NULL;
}

bool EventTargeter::SubtreeShouldBeExploredForEvent(EventTarget* target,
                                                    const LocatedEvent& event) {
  return SubtreeCanAcceptEvent(target, event) &&
         EventLocationInsideBounds(target, event);
}

EventTarget* EventTargeter::FindNextBestTarget(EventTarget* previous_target,
                                               Event* event) {
  return NULL;
}

bool EventTargeter::SubtreeCanAcceptEvent(EventTarget* target,
                                          const LocatedEvent& event) const {
  return true;
}

bool EventTargeter::EventLocationInsideBounds(EventTarget* target,
                                              const LocatedEvent& event) const {
  return true;
}

}  // namespace ui
