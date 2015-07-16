// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_TARGET_H_
#define UI_EVENTS_EVENT_TARGET_H_

#include <vector>

#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/memory/scoped_ptr.h"
#include "ui/events/event_handler.h"
#include "ui/events/events_export.h"

namespace ui {

class EventDispatcher;
class EventTargeter;
class EventTargetIterator;
class LocatedEvent;

class EVENTS_EXPORT EventTarget : public EventHandler {
 public:
  class DispatcherApi {
   public:
    explicit DispatcherApi(EventTarget* target) : target_(target) {}

    const EventHandlerList& pre_target_list() const {
      return target_->pre_target_list_;
    }

   private:
    DispatcherApi();
    EventTarget* target_;

    DISALLOW_COPY_AND_ASSIGN(DispatcherApi);
  };

  EventTarget();
  ~EventTarget() override;

  virtual bool CanAcceptEvent(const Event& event) = 0;

  // Returns the parent EventTarget in the event-target tree.
  virtual EventTarget* GetParentTarget() = 0;

  // Returns an iterator an EventTargeter can use to iterate over the list of
  // child EventTargets.
  virtual scoped_ptr<EventTargetIterator> GetChildIterator() = 0;

  // Returns the EventTargeter that should be used to find the target for an
  // event in the subtree rooted at this EventTarget.
  virtual EventTargeter* GetEventTargeter() = 0;

  // Updates the states in |event| (e.g. location) to be suitable for |target|,
  // so that |event| can be dispatched to |target|.
  virtual void ConvertEventToTarget(EventTarget* target,
                                    LocatedEvent* event);

  // Adds a handler to receive events before the target. The handler must be
  // explicitly removed from the target before the handler is destroyed. The
  // EventTarget does not take ownership of the handler.
  void AddPreTargetHandler(EventHandler* handler);

  // Same as AddPreTargetHandler except that the |handler| is added to the front
  // of the list so it is the first one to receive events.
  void PrependPreTargetHandler(EventHandler* handler);
  void RemovePreTargetHandler(EventHandler* handler);

  // Adds a handler to receive events after the target. The handler must be
  // explicitly removed from the target before the handler is destroyed. The
  // EventTarget does not take ownership of the handler.
  void AddPostTargetHandler(EventHandler* handler);
  void RemovePostTargetHandler(EventHandler* handler);

  // Returns true if the event pre target list is empty.
  bool IsPreTargetListEmpty() const;

  void set_target_handler(EventHandler* handler) {
    target_handler_ = handler;
  }

 protected:
  EventHandler* target_handler() { return target_handler_; }

  // Overridden from EventHandler:
  void OnEvent(Event* event) override;
  void OnKeyEvent(KeyEvent* event) override;
  void OnMouseEvent(MouseEvent* event) override;
  void OnScrollEvent(ScrollEvent* event) override;
  void OnTouchEvent(TouchEvent* event) override;
  void OnGestureEvent(GestureEvent* event) override;

 private:
  friend class EventDispatcher;
  friend class EventTargetTestApi;

  // Returns the list of handlers that should receive the event before the
  // target. The handlers from the outermost target are first in the list, and
  // the handlers on |this| are the last in the list.
  void GetPreTargetHandlers(EventHandlerList* list);

  // Returns the list of handlers that should receive the event after the
  // target. The handlers from the outermost target are last in the list, and
  // the handlers on |this| are the first in the list.
  void GetPostTargetHandlers(EventHandlerList* list);

  EventHandlerList pre_target_list_;
  EventHandlerList post_target_list_;
  EventHandler* target_handler_;

  DISALLOW_COPY_AND_ASSIGN(EventTarget);
};

}  // namespace ui

#endif  // UI_EVENTS_EVENT_TARGET_H_
