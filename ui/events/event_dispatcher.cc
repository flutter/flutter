// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/event_dispatcher.h"

#include <algorithm>

#include "ui/events/event_target.h"
#include "ui/events/event_targeter.h"

namespace ui {

namespace {

class ScopedDispatchHelper : public Event::DispatcherApi {
 public:
  explicit ScopedDispatchHelper(Event* event)
      : Event::DispatcherApi(event) {
    set_result(ui::ER_UNHANDLED);
  }

  virtual ~ScopedDispatchHelper() {
    set_phase(EP_POSTDISPATCH);
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(ScopedDispatchHelper);
};

}  // namespace

EventDispatcherDelegate::EventDispatcherDelegate()
    : dispatcher_(NULL) {
}

EventDispatcherDelegate::~EventDispatcherDelegate() {
  if (dispatcher_)
    dispatcher_->OnDispatcherDelegateDestroyed();
}

Event* EventDispatcherDelegate::current_event() {
  return dispatcher_ ? dispatcher_->current_event() : NULL;
}

EventDispatchDetails EventDispatcherDelegate::DispatchEvent(EventTarget* target,
                                                            Event* event) {
  CHECK(target);
  Event::DispatcherApi dispatch_helper(event);
  dispatch_helper.set_phase(EP_PREDISPATCH);
  dispatch_helper.set_result(ER_UNHANDLED);

  EventDispatchDetails details = PreDispatchEvent(target, event);
  if (!event->handled() &&
      !details.dispatcher_destroyed &&
      !details.target_destroyed) {
    details = DispatchEventToTarget(target, event);
  }
  bool target_destroyed_during_dispatch = details.target_destroyed;
  if (!details.dispatcher_destroyed) {
    details = PostDispatchEvent(target_destroyed_during_dispatch ?
        NULL : target, *event);
  }

  details.target_destroyed |= target_destroyed_during_dispatch;
  return details;
}

EventDispatchDetails EventDispatcherDelegate::PreDispatchEvent(
    EventTarget* target, Event* event) {
  return EventDispatchDetails();
}

EventDispatchDetails EventDispatcherDelegate::PostDispatchEvent(
    EventTarget* target, const Event& event) {
  return EventDispatchDetails();
}

EventDispatchDetails EventDispatcherDelegate::DispatchEventToTarget(
    EventTarget* target,
    Event* event) {
  EventDispatcher* old_dispatcher = dispatcher_;
  EventDispatcher dispatcher(this);
  dispatcher_ = &dispatcher;
  dispatcher.ProcessEvent(target, event);
  if (!dispatcher.delegate_destroyed())
    dispatcher_ = old_dispatcher;
  else if (old_dispatcher)
    old_dispatcher->OnDispatcherDelegateDestroyed();

  EventDispatchDetails details;
  details.dispatcher_destroyed = dispatcher.delegate_destroyed();
  details.target_destroyed =
      (!details.dispatcher_destroyed && !CanDispatchToTarget(target));
  return details;
}

////////////////////////////////////////////////////////////////////////////////
// EventDispatcher:

EventDispatcher::EventDispatcher(EventDispatcherDelegate* delegate)
    : delegate_(delegate),
      current_event_(NULL) {
}

EventDispatcher::~EventDispatcher() {
}

void EventDispatcher::OnHandlerDestroyed(EventHandler* handler) {
  handler_list_.erase(std::find(handler_list_.begin(),
                                handler_list_.end(),
                                handler));
}

void EventDispatcher::ProcessEvent(EventTarget* target, Event* event) {
  if (!target || !target->CanAcceptEvent(*event))
    return;

  ScopedDispatchHelper dispatch_helper(event);
  dispatch_helper.set_target(target);

  handler_list_.clear();
  target->GetPreTargetHandlers(&handler_list_);

  dispatch_helper.set_phase(EP_PRETARGET);
  DispatchEventToEventHandlers(&handler_list_, event);
  if (event->handled())
    return;

  // If the event hasn't been consumed, trigger the default handler. Note that
  // even if the event has already been handled (i.e. return result has
  // ER_HANDLED set), that means that the event should still be processed at
  // this layer, however it should not be processed in the next layer of
  // abstraction.
  if (delegate_ && delegate_->CanDispatchToTarget(target)) {
    dispatch_helper.set_phase(EP_TARGET);
    DispatchEvent(target, event);
    if (event->handled())
      return;
  }

  if (!delegate_ || !delegate_->CanDispatchToTarget(target))
    return;

  handler_list_.clear();
  target->GetPostTargetHandlers(&handler_list_);
  dispatch_helper.set_phase(EP_POSTTARGET);
  DispatchEventToEventHandlers(&handler_list_, event);
}

void EventDispatcher::OnDispatcherDelegateDestroyed() {
  delegate_ = NULL;
}

////////////////////////////////////////////////////////////////////////////////
// EventDispatcher, private:

void EventDispatcher::DispatchEventToEventHandlers(EventHandlerList* list,
                                                   Event* event) {
  for (EventHandlerList::const_iterator it = list->begin(),
           end = list->end(); it != end; ++it) {
    (*it)->dispatchers_.push(this);
  }

  while (!list->empty()) {
    EventHandler* handler = (*list->begin());
    if (delegate_ && !event->stopped_propagation())
      DispatchEvent(handler, event);

    if (!list->empty() && *list->begin() == handler) {
      // The handler has not been destroyed (because if it were, then it would
      // have been removed from the list).
      CHECK(handler->dispatchers_.top() == this);
      handler->dispatchers_.pop();
      list->erase(list->begin());
    }
  }
}

void EventDispatcher::DispatchEvent(EventHandler* handler, Event* event) {
  // If the target has been invalidated or deleted, don't dispatch the event.
  if (!delegate_->CanDispatchToTarget(event->target())) {
    if (event->cancelable())
      event->StopPropagation();
    return;
  }

  base::AutoReset<Event*> event_reset(&current_event_, event);
  handler->OnEvent(event);
  if (!delegate_ && event->cancelable())
    event->StopPropagation();
}

}  // namespace ui
