// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_PROCESSOR_H_
#define UI_EVENTS_EVENT_PROCESSOR_H_

#include "ui/events/event_dispatcher.h"
#include "ui/events/event_source.h"

namespace ui {

// EventProcessor receives an event from an EventSource and dispatches it to a
// tree of EventTargets.
class EVENTS_EXPORT EventProcessor : public EventDispatcherDelegate {
 public:
  ~EventProcessor() override {}

  // Returns the root of the tree this event processor owns.
  virtual EventTarget* GetRootTarget() = 0;

  // Dispatches an event received from the EventSource to the tree of
  // EventTargets (whose root is returned by GetRootTarget()).  The co-ordinate
  // space of the source must be the same as the root target, except that the
  // target may have a high-dpi scale applied.
  // TODO(tdanderson|sadrul): This is only virtual for testing purposes. It
  //                          should not be virtual at all.
  virtual EventDispatchDetails OnEventFromSource(Event* event)
      WARN_UNUSED_RESULT;

 protected:
  // Invoked at the start of processing, before an EventTargeter is used to
  // find the target of the event. If processing should not take place, marks
  // |event| as handled. Otherwise updates |event| so that the targeter can
  // operate correctly (e.g., it can be used to update the location of the
  // event when dispatching from an EventSource in high-DPI) and updates any
  // members in the event processor as necessary.
  virtual void OnEventProcessingStarted(Event* event);

  // Invoked when the processing of |event| has finished (i.e., when no further
  // dispatching of |event| will be performed by this EventProcessor). Note
  // that the last target to which |event| was dispatched may have been
  // destroyed.
  virtual void OnEventProcessingFinished(Event* event);
};

}  // namespace ui

#endif  // UI_EVENTS_EVENT_PROCESSOR_H_
