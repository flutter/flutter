// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/test/test_event_target.h"

#include "ui/events/event.h"
#include "ui/events/event_target_iterator.h"
#include "ui/events/event_targeter.h"

namespace ui {
namespace test {

TestEventTarget::TestEventTarget()
    : parent_(NULL),
      mark_events_as_handled_(false),
      recorder_(NULL),
      target_name_("unknown") {}
TestEventTarget::~TestEventTarget() {}

void TestEventTarget::AddChild(scoped_ptr<TestEventTarget> child) {
  TestEventTarget* child_r = child.get();
  if (child->parent()) {
    AddChild(child->parent()->RemoveChild(child.release()));
  } else {
    children_.push_back(child.release());
  }
  child_r->set_parent(this);
}

scoped_ptr<TestEventTarget> TestEventTarget::RemoveChild(TestEventTarget *c) {
  ScopedVector<TestEventTarget>::iterator iter = std::find(children_.begin(),
                                                           children_.end(),
                                                           c);
  if (iter != children_.end()) {
    children_.weak_erase(iter);
    c->set_parent(NULL);
    return scoped_ptr<TestEventTarget>(c);
  }
  return scoped_ptr<TestEventTarget>();
}

void TestEventTarget::SetEventTargeter(scoped_ptr<EventTargeter> targeter) {
  targeter_ = targeter.Pass();
}

bool TestEventTarget::DidReceiveEvent(ui::EventType type) const {
  return received_.count(type) > 0;
}

void TestEventTarget::ResetReceivedEvents() {
  received_.clear();
}

////////////////////////////////////////////////////////////////////////////////
// TestEventTarget, protected

bool TestEventTarget::CanAcceptEvent(const ui::Event& event) {
  return true;
}

EventTarget* TestEventTarget::GetParentTarget() {
  return parent_;
}

scoped_ptr<EventTargetIterator> TestEventTarget::GetChildIterator() {
  return scoped_ptr<EventTargetIterator>(
      new EventTargetIteratorImpl<TestEventTarget>(children_.get()));
}

EventTargeter* TestEventTarget::GetEventTargeter() {
  return targeter_.get();
}

void TestEventTarget::OnEvent(Event* event) {
  if (recorder_)
    recorder_->push_back(target_name_);
  received_.insert(event->type());
  EventTarget::OnEvent(event);
  if (!event->handled() && mark_events_as_handled_)
    event->SetHandled();
}

////////////////////////////////////////////////////////////////////////////////
// TestEventTarget, private

bool TestEventTarget::Contains(TestEventTarget* target) const {
  while (target && target != this)
    target = target->parent();
  return target == this;
}

}  // namespace test
}  // namespace ui
