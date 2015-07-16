// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/events/platform/platform_event_builder.h"

#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event.h"
#include "ui/events/keycodes/dom4/keycode_converter.h"
#include "ui/events/platform/x11/device_data_manager_x11.h"
#include "ui/events/platform/x11/touch_factory_x11.h"
#include "ui/events/test/events_test_utils_x11.h"

namespace ui {

class PlatformEventBuilderXTest : public testing::Test {
 public:
  PlatformEventBuilderXTest() {}
  ~PlatformEventBuilderXTest() override {}

  void SetUp() override {
    DeviceDataManagerX11::CreateInstance();
    ui::TouchFactory::GetInstance()->ResetForTest();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformEventBuilderXTest);
};

TEST_F(PlatformEventBuilderXTest, GetCharacter) {
  // For X11, test the functions with native_event() as well. crbug.com/107837
  ScopedXI2Event event;
  event.InitKeyEvent(ET_KEY_PRESSED, VKEY_RETURN, EF_CONTROL_DOWN);
  KeyEvent keyev3 = PlatformEventBuilder::BuildKeyEvent(event);
  EXPECT_EQ(10, keyev3.GetCharacter());

  event.InitKeyEvent(ET_KEY_PRESSED, VKEY_RETURN, EF_NONE);
  KeyEvent keyev4 = PlatformEventBuilder::BuildKeyEvent(event);
  EXPECT_EQ(13, keyev4.GetCharacter());
}

TEST_F(PlatformEventBuilderXTest, NormalizeKeyEventFlags) {
  // Normalize flags when KeyEvent is created from XEvent.
  ScopedXI2Event event;
  {
    event.InitKeyEvent(ET_KEY_PRESSED, VKEY_SHIFT, EF_SHIFT_DOWN);
    KeyEvent keyev = PlatformEventBuilder::BuildKeyEvent(event);
    EXPECT_EQ(EF_SHIFT_DOWN, keyev.flags());
  }
  {
    event.InitKeyEvent(ET_KEY_RELEASED, VKEY_SHIFT, EF_SHIFT_DOWN);
    KeyEvent keyev = PlatformEventBuilder::BuildKeyEvent(event);
    EXPECT_EQ(EF_NONE, keyev.flags());
  }
  {
    event.InitKeyEvent(ET_KEY_PRESSED, VKEY_CONTROL, EF_CONTROL_DOWN);
    KeyEvent keyev = PlatformEventBuilder::BuildKeyEvent(event);
    EXPECT_EQ(EF_CONTROL_DOWN, keyev.flags());
  }
  {
    event.InitKeyEvent(ET_KEY_RELEASED, VKEY_CONTROL, EF_CONTROL_DOWN);
    KeyEvent keyev = PlatformEventBuilder::BuildKeyEvent(event);
    EXPECT_EQ(EF_NONE, keyev.flags());
  }
  {
    event.InitKeyEvent(ET_KEY_PRESSED, VKEY_MENU, EF_ALT_DOWN);
    KeyEvent keyev = PlatformEventBuilder::BuildKeyEvent(event);
    EXPECT_EQ(EF_ALT_DOWN, keyev.flags());
  }
  {
    event.InitKeyEvent(ET_KEY_RELEASED, VKEY_MENU, EF_ALT_DOWN);
    KeyEvent keyev = PlatformEventBuilder::BuildKeyEvent(event);
    EXPECT_EQ(EF_NONE, keyev.flags());
  }
}

TEST_F(PlatformEventBuilderXTest, KeyEventCode) {
  const char kCodeForSpace[] = "Space";
  const uint16 kNativeCodeSpace =
      ui::KeycodeConverter::CodeToNativeKeycode(kCodeForSpace);

  // KeyEvent converts from the native keycode (XKB) to the code.
  ScopedXI2Event xevent;
  xevent.InitKeyEvent(ET_KEY_PRESSED, VKEY_SPACE, kNativeCodeSpace);
  KeyEvent key = PlatformEventBuilder::BuildKeyEvent(xevent);
  EXPECT_EQ(kCodeForSpace, key.code());
}

// TODO(erg): When we bring up mojo on Windows, we'll need to port this test to
// Windows too.
TEST_F(PlatformEventBuilderXTest, AutoRepeat) {
  const uint16 kNativeCodeA = ui::KeycodeConverter::CodeToNativeKeycode("KeyA");
  const uint16 kNativeCodeB = ui::KeycodeConverter::CodeToNativeKeycode("KeyB");
#if defined(USE_X11)
  ScopedXI2Event native_event_a_pressed;
  native_event_a_pressed.InitKeyEvent(ET_KEY_PRESSED, VKEY_A, kNativeCodeA);
  ScopedXI2Event native_event_a_released;
  native_event_a_released.InitKeyEvent(ET_KEY_RELEASED, VKEY_A, kNativeCodeA);
  ScopedXI2Event native_event_b_pressed;
  native_event_b_pressed.InitKeyEvent(ET_KEY_PRESSED, VKEY_B, kNativeCodeB);
  ScopedXI2Event native_event_a_pressed_nonstandard_state;
  native_event_a_pressed_nonstandard_state.InitKeyEvent(ET_KEY_PRESSED, VKEY_A,
                                                        kNativeCodeA);
  // IBUS-GTK uses the mask (1 << 25) to detect reposted event.
  static_cast<XEvent*>(native_event_a_pressed_nonstandard_state)->xkey.state |=
      1 << 25;
#endif
  KeyEvent key_a1 = PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_FALSE(key_a1.IsRepeat());
  KeyEvent key_a1_released =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_released);
  EXPECT_FALSE(key_a1_released.IsRepeat());

  KeyEvent key_a2 = PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_FALSE(key_a2.IsRepeat());
  KeyEvent key_a2_repeated =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_TRUE(key_a2_repeated.IsRepeat());
  KeyEvent key_a2_released =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_released);
  EXPECT_FALSE(key_a2_released.IsRepeat());

  KeyEvent key_a3 = PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_FALSE(key_a3.IsRepeat());
  KeyEvent key_b = PlatformEventBuilder::BuildKeyEvent(native_event_b_pressed);
  EXPECT_FALSE(key_b.IsRepeat());
  KeyEvent key_a3_again =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_FALSE(key_a3_again.IsRepeat());
  KeyEvent key_a3_repeated =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_TRUE(key_a3_repeated.IsRepeat());
  KeyEvent key_a3_repeated2 =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_TRUE(key_a3_repeated2.IsRepeat());
  KeyEvent key_a3_released =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_released);
  EXPECT_FALSE(key_a3_released.IsRepeat());

#if defined(USE_X11)
  KeyEvent key_a4_pressed =
      PlatformEventBuilder::BuildKeyEvent(native_event_a_pressed);
  EXPECT_FALSE(key_a4_pressed.IsRepeat());

  KeyEvent key_a4_pressed_nonstandard_state =
      PlatformEventBuilder::BuildKeyEvent(
          native_event_a_pressed_nonstandard_state);
  EXPECT_FALSE(key_a4_pressed_nonstandard_state.IsRepeat());
#endif
}

// Tests that an event only increases the click count and gets marked as a
// double click if a release event was seen for the previous click. This
// prevents the same PRESSED event from being processed twice:
// http://crbug.com/389162
TEST_F(PlatformEventBuilderXTest, DoubleClickRequiresRelease) {
  const gfx::Point origin1(0, 0);
  const gfx::Point origin2(100, 0);
  base::TimeDelta start = base::TimeDelta::FromMilliseconds(0);

  unsigned int device_id = 1;
  std::vector<unsigned int> device_list;
  device_list.push_back(device_id);
  TouchFactory::GetInstance()->SetPointerDeviceForTest(device_list);
  ScopedXI2Event native_event;

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin1,
                                      EF_LEFT_MOUSE_BUTTON);
  MouseEvent event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin1,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin2,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_RELEASED, origin2,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin2,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(2, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_RELEASED, origin2,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(2, PlatformEventBuilder::GetRepeatCount(native_event, event));

  PlatformEventBuilder::ResetLastClickForTest();
}

// Tests that clicking right and then left clicking does not generate a double
// click.
TEST_F(PlatformEventBuilderXTest, SingleClickRightLeft) {
  const gfx::Point origin(0, 0);
  base::TimeDelta start = base::TimeDelta::FromMilliseconds(0);

  unsigned int device_id = 1;
  std::vector<unsigned int> device_list;
  device_list.push_back(device_id);
  TouchFactory::GetInstance()->SetPointerDeviceForTest(device_list);
  ScopedXI2Event native_event;

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin,
                                      EF_RIGHT_MOUSE_BUTTON);
  MouseEvent event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_RELEASED, origin,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(1, PlatformEventBuilder::GetRepeatCount(native_event, event));

  native_event.InitGenericButtonEvent(device_id, ET_MOUSE_PRESSED, origin,
                                      EF_LEFT_MOUSE_BUTTON);
  event = PlatformEventBuilder::BuildMouseEvent(native_event);
  event.set_time_stamp(start);
  EXPECT_EQ(2, PlatformEventBuilder::GetRepeatCount(native_event, event));
  PlatformEventBuilder::ResetLastClickForTest();
}

}  // namespace ui
