// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_EVENT_HANDLER_H_
#define UI_EVENTS_EVENT_HANDLER_H_

#include <stack>
#include <vector>

#include "base/basictypes.h"
#include "ui/events/event_constants.h"
#include "ui/events/events_export.h"

namespace ui {

class CancelModeEvent;
class Event;
class EventDispatcher;
class EventTarget;
class GestureEvent;
class KeyEvent;
class MouseEvent;
class ScrollEvent;
class TouchEvent;

// Dispatches events to appropriate targets.  The default implementations of
// all of the specific handlers (e.g. OnKeyEvent, OnMouseEvent) do nothing.
class EVENTS_EXPORT EventHandler {
 public:
  EventHandler();
  virtual ~EventHandler();

  // This is called for all events. The default implementation routes the event
  // to one of the event-specific callbacks (OnKeyEvent, OnMouseEvent etc.). If
  // this is overridden, then normally, the override should chain into the
  // default implementation for un-handled events.
  virtual void OnEvent(Event* event);

  virtual void OnKeyEvent(KeyEvent* event);

  virtual void OnMouseEvent(MouseEvent* event);

  virtual void OnScrollEvent(ScrollEvent* event);

  virtual void OnTouchEvent(TouchEvent* event);

  virtual void OnGestureEvent(GestureEvent* event);

  virtual void OnCancelMode(CancelModeEvent* event);

 private:
  friend class EventDispatcher;

  // EventDispatcher pushes itself on the top of this stack while dispatching
  // events to this then pops itself off when done.
  std::stack<EventDispatcher*> dispatchers_;

  DISALLOW_COPY_AND_ASSIGN(EventHandler);
};

typedef std::vector<EventHandler*> EventHandlerList;

}  // namespace ui

#endif  // UI_EVENTS_EVENT_HANDLER_H_
