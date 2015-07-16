// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_EVENT_PLATFORM_EVENT_BUILDER_H_
#define UI_EVENTS_PLATFORM_EVENT_PLATFORM_EVENT_BUILDER_H_

#include "base/event_types.h"
#include "base/gtest_prod_util.h"
#include "base/macros.h"

namespace ui {

class Event;
class KeyEvent;
class LocatedEvent;
class MouseEvent;
class MouseWheelEvent;
class ScrollEvent;
class TouchEvent;

// Builds ui::Events from native events.
//
// In chromium, this functionality was put inline on the individual Event
// subclasses. This was fine there since all chromium binaries included the
// system windowing system libraries. In mojo, we have small binaries which
// have want to have generic events while only the native viewport needs the
// capability to generate events from platform events.
class PlatformEventBuilder {
 public:
  static MouseEvent BuildMouseEvent(const base::NativeEvent& native_event);
  static MouseWheelEvent BuildMouseWheelEvent(
      const base::NativeEvent& native_event);
  static TouchEvent BuildTouchEvent(const base::NativeEvent& native_event);
  static KeyEvent BuildKeyEvent(const base::NativeEvent& native_event);
  static ScrollEvent BuildScrollEvent(const base::NativeEvent& native_event);

  // Returns the repeat count based on the previous mouse click, if it is
  // recent enough and within a small enough distance. Exposed for testing.
  static int GetRepeatCount(const base::NativeEvent& native_event,
                            const MouseEvent& event);

 private:
  FRIEND_TEST_ALL_PREFIXES(PlatformEventBuilderXTest,
                           DoubleClickRequiresRelease);
  FRIEND_TEST_ALL_PREFIXES(PlatformEventBuilderXTest, SingleClickRightLeft);

  // Resets the last_click_event_ for unit tests.
  static void ResetLastClickForTest();

  // Takes data from |native_event| and fills the per class details on |event|.
  static void FillEventFrom(const base::NativeEvent& native_event,
                            Event* event);
  static void FillLocatedEventFrom(const base::NativeEvent& native_event,
                                   LocatedEvent* located_event);
  static void FillMouseEventFrom(const base::NativeEvent& native_event,
                                 MouseEvent* mouse_event);
  static void FillMouseWheelEventFrom(const base::NativeEvent& native_event,
                                      MouseWheelEvent* mouse_wheel_event);
  static void FillTouchEventFrom(const base::NativeEvent& native_event,
                                 TouchEvent* touch_event);
  static void FillKeyEventFrom(const base::NativeEvent& native_event,
                               KeyEvent* key_event);
  static void FillScrollEventFrom(const base::NativeEvent& native_event,
                                  ScrollEvent* scroll_event);

  DISALLOW_COPY_AND_ASSIGN(PlatformEventBuilder);
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_EVENT_PLATFORM_EVENT_BUILDER_H_
