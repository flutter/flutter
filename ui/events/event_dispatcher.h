// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_DISPATCHER_H_
#define UI_EVENTS_EVENT_DISPATCHER_H_

#include "base/auto_reset.h"
#include "ui/events/event.h"
#include "ui/events/event_constants.h"
#include "ui/events/event_handler.h"
#include "ui/events/events_export.h"

namespace ui {

class EventDispatcher;
class EventTarget;
class EventTargeter;

struct EventDispatchDetails {
  EventDispatchDetails()
      : dispatcher_destroyed(false),
        target_destroyed(false) {}
  bool dispatcher_destroyed;
  bool target_destroyed;
};

class EVENTS_EXPORT EventDispatcherDelegate {
 public:
  EventDispatcherDelegate();
  virtual ~EventDispatcherDelegate();

  // Returns whether an event can still be dispatched to a target. (e.g. during
  // event dispatch, one of the handlers may have destroyed the target, in which
  // case the event can no longer be dispatched to the target).
  virtual bool CanDispatchToTarget(EventTarget* target) = 0;

  // Returns the event being dispatched (or NULL if no event is being
  // dispatched).
  Event* current_event();

  // Dispatches |event| to |target|. This calls |PreDispatchEvent()| before
  // dispatching the event, and |PostDispatchEvent()| after the event has been
  // dispatched.
  EventDispatchDetails DispatchEvent(EventTarget* target, Event* event)
      WARN_UNUSED_RESULT;

 protected:
  // This is called once a target has been determined for an event, right before
  // the event is dispatched to the target. This function may modify |event| to
  // prepare it for dispatch (e.g. update event flags, location etc.).
  virtual EventDispatchDetails PreDispatchEvent(
      EventTarget* target,
      Event* event) WARN_UNUSED_RESULT;

  // This is called right after the event dispatch is completed.
  // |target| is NULL if the target was deleted during dispatch.
  virtual EventDispatchDetails PostDispatchEvent(
      EventTarget* target,
      const Event& event) WARN_UNUSED_RESULT;

 private:
  // Dispatches the event to the target.
  EventDispatchDetails DispatchEventToTarget(EventTarget* target,
                                             Event* event) WARN_UNUSED_RESULT;

  EventDispatcher* dispatcher_;

  DISALLOW_COPY_AND_ASSIGN(EventDispatcherDelegate);
};

// Dispatches events to appropriate targets.
class EVENTS_EXPORT EventDispatcher {
 public:
  explicit EventDispatcher(EventDispatcherDelegate* delegate);
  virtual ~EventDispatcher();

  void ProcessEvent(EventTarget* target, Event* event);

  const Event* current_event() const { return current_event_; }
  Event* current_event() { return current_event_; }

  bool delegate_destroyed() const { return !delegate_; }

  void OnHandlerDestroyed(EventHandler* handler);
  void OnDispatcherDelegateDestroyed();

 private:
  void DispatchEventToEventHandlers(EventHandlerList* list, Event* event);

  // Dispatches an event, and makes sure it sets ER_CONSUMED on the
  // event-handling result if the dispatcher itself has been destroyed during
  // dispatching the event to the event handler.
  void DispatchEvent(EventHandler* handler, Event* event);

  EventDispatcherDelegate* delegate_;

  Event* current_event_;

  EventHandlerList handler_list_;

  DISALLOW_COPY_AND_ASSIGN(EventDispatcher);
};

}  // namespace ui

#endif  // UI_EVENTS_EVENT_DISPATCHER_H_
