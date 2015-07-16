// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/test/test_event_handler.h"

#include "ui/events/event.h"

namespace ui {
namespace test {

TestEventHandler::TestEventHandler()
    : num_key_events_(0),
      num_mouse_events_(0),
      num_scroll_events_(0),
      num_touch_events_(0),
      num_gesture_events_(0),
      recorder_(NULL),
      handler_name_("unknown") {
}

TestEventHandler::~TestEventHandler() {}

void TestEventHandler::Reset() {
  num_key_events_ = 0;
  num_mouse_events_ = 0;
  num_scroll_events_ = 0;
  num_touch_events_ = 0;
  num_gesture_events_ = 0;
}

void TestEventHandler::OnKeyEvent(KeyEvent* event) {
  if (recorder_)
    recorder_->push_back(handler_name_);
  num_key_events_++;
  event->SetHandled();
}

void TestEventHandler::OnMouseEvent(MouseEvent* event) {
  if (recorder_)
    recorder_->push_back(handler_name_);
  num_mouse_events_++;
}

void TestEventHandler::OnScrollEvent(ScrollEvent* event) {
  if (recorder_)
    recorder_->push_back(handler_name_);
  num_scroll_events_++;
}

void TestEventHandler::OnTouchEvent(TouchEvent* event) {
  if (recorder_)
    recorder_->push_back(handler_name_);
  num_touch_events_++;
}

void TestEventHandler::OnGestureEvent(GestureEvent* event) {
  if (recorder_)
    recorder_->push_back(handler_name_);
  num_gesture_events_++;
}

}  // namespace test
}  // namespace ui
