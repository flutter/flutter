// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/event_target.h"

#include <algorithm>

#include "base/logging.h"
#include "ui/events/event.h"

namespace ui {

EventTarget::EventTarget()
    : target_handler_(NULL) {
}

EventTarget::~EventTarget() {
}

void EventTarget::ConvertEventToTarget(EventTarget* target,
                                       LocatedEvent* event) {
}

void EventTarget::AddPreTargetHandler(EventHandler* handler) {
  pre_target_list_.push_back(handler);
}

void EventTarget::PrependPreTargetHandler(EventHandler* handler) {
  pre_target_list_.insert(pre_target_list_.begin(), handler);
}

void EventTarget::RemovePreTargetHandler(EventHandler* handler) {
  EventHandlerList::iterator find =
      std::find(pre_target_list_.begin(),
                pre_target_list_.end(),
                handler);
  if (find != pre_target_list_.end())
    pre_target_list_.erase(find);
}

void EventTarget::AddPostTargetHandler(EventHandler* handler) {
  post_target_list_.push_back(handler);
}

void EventTarget::RemovePostTargetHandler(EventHandler* handler) {
  EventHandlerList::iterator find =
      std::find(post_target_list_.begin(),
                post_target_list_.end(),
                handler);
  if (find != post_target_list_.end())
    post_target_list_.erase(find);
}

bool EventTarget::IsPreTargetListEmpty() const {
  return pre_target_list_.empty();
}

void EventTarget::OnEvent(Event* event) {
  CHECK_EQ(this, event->target());
  if (target_handler_)
    target_handler_->OnEvent(event);
  else
    EventHandler::OnEvent(event);
}

void EventTarget::OnKeyEvent(KeyEvent* event) {
  CHECK_EQ(this, event->target());
  if (target_handler_)
    target_handler_->OnKeyEvent(event);
}

void EventTarget::OnMouseEvent(MouseEvent* event) {
  CHECK_EQ(this, event->target());
  if (target_handler_)
    target_handler_->OnMouseEvent(event);
}

void EventTarget::OnScrollEvent(ScrollEvent* event) {
  CHECK_EQ(this, event->target());
  if (target_handler_)
    target_handler_->OnScrollEvent(event);
}

void EventTarget::OnTouchEvent(TouchEvent* event) {
  CHECK_EQ(this, event->target());
  if (target_handler_)
    target_handler_->OnTouchEvent(event);
}

void EventTarget::OnGestureEvent(GestureEvent* event) {
  CHECK_EQ(this, event->target());
  if (target_handler_)
    target_handler_->OnGestureEvent(event);
}

void EventTarget::GetPreTargetHandlers(EventHandlerList* list) {
  EventTarget* target = this;
  while (target) {
    EventHandlerList::reverse_iterator it, rend;
    for (it = target->pre_target_list_.rbegin(),
            rend = target->pre_target_list_.rend();
        it != rend;
        ++it) {
      list->insert(list->begin(), *it);
    }
    target = target->GetParentTarget();
  }
}

void EventTarget::GetPostTargetHandlers(EventHandlerList* list) {
  EventTarget* target = this;
  while (target) {
    for (EventHandlerList::iterator it = target->post_target_list_.begin(),
        end = target->post_target_list_.end(); it != end; ++it) {
      list->push_back(*it);
    }
    target = target->GetParentTarget();
  }
}

}  // namespace ui
