// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cstring>
#include <set>

#include <X11/extensions/XInput2.h>
#include <X11/XKBlib.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>

// Generically-named #defines from Xlib that conflict with symbols in GTest.
#undef Bool
#undef None

#include "base/memory/scoped_ptr.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/events/event.h"
#include "ui/events/event_constants.h"
#include "ui/events/event_utils.h"
#include "ui/events/platform/platform_event_builder.h"
#include "ui/events/platform/platform_event_utils.h"
#include "ui/events/platform/x11/device_data_manager_x11.h"
#include "ui/events/platform/x11/touch_factory_x11.h"
#include "ui/events/test/events_test_utils.h"
#include "ui/events/test/events_test_utils_x11.h"
#include "ui/gfx/point.h"

namespace ui {

namespace {

// Initializes the passed-in Xlib event.
void InitButtonEvent(XEvent* event,
                     bool is_press,
                     const gfx::Point& location,
                     int button,
                     int state) {
  memset(event, 0, sizeof(*event));

  // We don't bother setting fields that the event code doesn't use, such as
  // x_root/y_root and window/root/subwindow.
  XButtonEvent* button_event = &(event->xbutton);
  button_event->type = is_press ? ButtonPress : ButtonRelease;
  button_event->x = location.x();
  button_event->y = location.y();
  button_event->button = button;
  button_event->state = state;
}

// Initializes the passed-in Xlib event.
void InitKeyEvent(Display* display,
                  XEvent* event,
                  bool is_press,
                  int keycode,
                  int state) {
  memset(event, 0, sizeof(*event));

  // We don't bother setting fields that the event code doesn't use, such as
  // x_root/y_root and window/root/subwindow.
  XKeyEvent* key_event = &(event->xkey);
  key_event->display = display;
  key_event->type = is_press ? KeyPress : KeyRelease;
  key_event->keycode = keycode;
  key_event->state = state;
}

// Returns true if the keysym maps to a KeyEvent with the EF_FUNCTION_KEY
// flag set, or the keysym maps to a zero key code.
bool HasFunctionKeyFlagSetIfSupported(Display* display, int x_keysym) {
  XEvent event;
  int x_keycode = XKeysymToKeycode(display, x_keysym);
  // Exclude keysyms for which the server has no corresponding keycode.
  if (x_keycode) {
    InitKeyEvent(display, &event, true, x_keycode, 0);
    ui::KeyEvent ui_key_event = PlatformEventBuilder::BuildKeyEvent(&event);
    return (ui_key_event.flags() & ui::EF_FUNCTION_KEY);
  }
  return true;
}

}  // namespace

class PlatformEventUtilsXTest : public testing::Test {
 public:
  PlatformEventUtilsXTest() {}
  ~PlatformEventUtilsXTest() override {}

  void SetUp() override {
    DeviceDataManagerX11::CreateInstance();
    ui::TouchFactory::GetInstance()->ResetForTest();
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(PlatformEventUtilsXTest);
};

TEST_F(PlatformEventUtilsXTest, ButtonEvents) {
  XEvent event;
  gfx::Point location(5, 10);
  gfx::Vector2d offset;

  InitButtonEvent(&event, true, location, 1, 0);
  EXPECT_EQ(ui::ET_MOUSE_PRESSED, ui::EventTypeFromNative(&event));
  EXPECT_EQ(ui::EF_LEFT_MOUSE_BUTTON, ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));

  InitButtonEvent(&event, true, location, 2, Button1Mask | ShiftMask);
  EXPECT_EQ(ui::ET_MOUSE_PRESSED, ui::EventTypeFromNative(&event));
  EXPECT_EQ(
      ui::EF_LEFT_MOUSE_BUTTON | ui::EF_MIDDLE_MOUSE_BUTTON | ui::EF_SHIFT_DOWN,
      ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));

  InitButtonEvent(&event, false, location, 3, 0);
  EXPECT_EQ(ui::ET_MOUSE_RELEASED, ui::EventTypeFromNative(&event));
  EXPECT_EQ(ui::EF_RIGHT_MOUSE_BUTTON, ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));

  // Scroll up.
  InitButtonEvent(&event, true, location, 4, 0);
  EXPECT_EQ(ui::ET_MOUSEWHEEL, ui::EventTypeFromNative(&event));
  EXPECT_EQ(0, ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));
  offset = ui::GetMouseWheelOffset(&event);
  EXPECT_GT(offset.y(), 0);
  EXPECT_EQ(0, offset.x());

  // Scroll down.
  InitButtonEvent(&event, true, location, 5, 0);
  EXPECT_EQ(ui::ET_MOUSEWHEEL, ui::EventTypeFromNative(&event));
  EXPECT_EQ(0, ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));
  offset = ui::GetMouseWheelOffset(&event);
  EXPECT_LT(offset.y(), 0);
  EXPECT_EQ(0, offset.x());

  // Scroll left.
  InitButtonEvent(&event, true, location, 6, 0);
  EXPECT_EQ(ui::ET_MOUSEWHEEL, ui::EventTypeFromNative(&event));
  EXPECT_EQ(0, ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));
  offset = ui::GetMouseWheelOffset(&event);
  EXPECT_EQ(0, offset.y());
  EXPECT_GT(offset.x(), 0);

  // Scroll right.
  InitButtonEvent(&event, true, location, 7, 0);
  EXPECT_EQ(ui::ET_MOUSEWHEEL, ui::EventTypeFromNative(&event));
  EXPECT_EQ(0, ui::EventFlagsFromNative(&event));
  EXPECT_EQ(location, ui::EventLocationFromNative(&event));
  offset = ui::GetMouseWheelOffset(&event);
  EXPECT_EQ(0, offset.y());
  EXPECT_LT(offset.x(), 0);

  // TODO(derat): Test XInput code.
}

TEST_F(PlatformEventUtilsXTest, AvoidExtraEventsOnWheelRelease) {
  XEvent event;
  gfx::Point location(5, 10);

  InitButtonEvent(&event, true, location, 4, 0);
  EXPECT_EQ(ui::ET_MOUSEWHEEL, ui::EventTypeFromNative(&event));

  // We should return ET_UNKNOWN for the release event instead of returning
  // ET_MOUSEWHEEL; otherwise we'll scroll twice for each scrollwheel step.
  InitButtonEvent(&event, false, location, 4, 0);
  EXPECT_EQ(ui::ET_UNKNOWN, ui::EventTypeFromNative(&event));

  // TODO(derat): Test XInput code.
}

TEST_F(PlatformEventUtilsXTest, EnterLeaveEvent) {
  XEvent event;
  event.xcrossing.type = EnterNotify;
  event.xcrossing.x = 10;
  event.xcrossing.y = 20;
  event.xcrossing.x_root = 110;
  event.xcrossing.y_root = 120;

  // Mouse enter events are converted to mouse move events to be consistent with
  // the way views handle mouse enter. See comments for EnterNotify case in
  // ui::EventTypeFromNative for more details.
  EXPECT_EQ(ui::ET_MOUSE_MOVED, ui::EventTypeFromNative(&event));
  EXPECT_EQ("10,20", ui::EventLocationFromNative(&event).ToString());
  EXPECT_EQ("110,120", ui::EventSystemLocationFromNative(&event).ToString());

  event.xcrossing.type = LeaveNotify;
  event.xcrossing.x = 30;
  event.xcrossing.y = 40;
  event.xcrossing.x_root = 230;
  event.xcrossing.y_root = 240;
  EXPECT_EQ(ui::ET_MOUSE_EXITED, ui::EventTypeFromNative(&event));
  EXPECT_EQ("30,40", ui::EventLocationFromNative(&event).ToString());
  EXPECT_EQ("230,240", ui::EventSystemLocationFromNative(&event).ToString());
}

TEST_F(PlatformEventUtilsXTest, ClickCount) {
  XEvent event;
  gfx::Point location(5, 10);

  for (int i = 1; i <= 3; ++i) {
    InitButtonEvent(&event, true, location, 1, 0);
    {
      MouseEvent mouseev = PlatformEventBuilder::BuildMouseEvent(&event);
      EXPECT_EQ(ui::ET_MOUSE_PRESSED, mouseev.type());
      EXPECT_EQ(i, mouseev.GetClickCount());
    }

    InitButtonEvent(&event, false, location, 1, 0);
    {
      MouseEvent mouseev = PlatformEventBuilder::BuildMouseEvent(&event);
      EXPECT_EQ(ui::ET_MOUSE_RELEASED, mouseev.type());
      EXPECT_EQ(i, mouseev.GetClickCount());
    }
  }
}

#if defined(USE_XI2_MT)
TEST_F(PlatformEventUtilsXTest, TouchEventBasic) {
  std::vector<unsigned int> devices;
  devices.push_back(0);
  ui::SetUpTouchDevicesForTest(devices);
  std::vector<Valuator> valuators;

  // Init touch begin with tracking id 5, touch id 0.
  valuators.push_back(Valuator(DeviceDataManagerX11::DT_TOUCH_MAJOR, 20));
  valuators.push_back(
      Valuator(DeviceDataManagerX11::DT_TOUCH_ORIENTATION, 0.3f));
  valuators.push_back(Valuator(DeviceDataManagerX11::DT_TOUCH_PRESSURE, 100));
  ui::ScopedXI2Event scoped_xevent;
  scoped_xevent.InitTouchEvent(0, XI_TouchBegin, 5, gfx::Point(10, 10),
                               valuators);
  EXPECT_EQ(ui::ET_TOUCH_PRESSED, ui::EventTypeFromNative(scoped_xevent));
  EXPECT_EQ("10,10", ui::EventLocationFromNative(scoped_xevent).ToString());
  EXPECT_EQ(GetTouchId(scoped_xevent), 0);
  EXPECT_EQ(GetTouchRadiusX(scoped_xevent), 10);
  EXPECT_FLOAT_EQ(GetTouchAngle(scoped_xevent), 0.15f);
  EXPECT_FLOAT_EQ(GetTouchForce(scoped_xevent), 0.1f);

  // Touch update, with new orientation info.
  valuators.clear();
  valuators.push_back(
      Valuator(DeviceDataManagerX11::DT_TOUCH_ORIENTATION, 0.5f));
  scoped_xevent.InitTouchEvent(0, XI_TouchUpdate, 5, gfx::Point(20, 20),
                               valuators);
  EXPECT_EQ(ui::ET_TOUCH_MOVED, ui::EventTypeFromNative(scoped_xevent));
  EXPECT_EQ("20,20", ui::EventLocationFromNative(scoped_xevent).ToString());
  EXPECT_EQ(GetTouchId(scoped_xevent), 0);
  EXPECT_EQ(GetTouchRadiusX(scoped_xevent), 10);
  EXPECT_FLOAT_EQ(GetTouchAngle(scoped_xevent), 0.25f);
  EXPECT_FLOAT_EQ(GetTouchForce(scoped_xevent), 0.1f);

  // Another touch with tracking id 6, touch id 1.
  valuators.clear();
  valuators.push_back(Valuator(DeviceDataManagerX11::DT_TOUCH_MAJOR, 100));
  valuators.push_back(
      Valuator(DeviceDataManagerX11::DT_TOUCH_ORIENTATION, 0.9f));
  valuators.push_back(Valuator(DeviceDataManagerX11::DT_TOUCH_PRESSURE, 500));
  scoped_xevent.InitTouchEvent(0, XI_TouchBegin, 6, gfx::Point(200, 200),
                               valuators);
  EXPECT_EQ(ui::ET_TOUCH_PRESSED, ui::EventTypeFromNative(scoped_xevent));
  EXPECT_EQ("200,200", ui::EventLocationFromNative(scoped_xevent).ToString());
  EXPECT_EQ(GetTouchId(scoped_xevent), 1);
  EXPECT_EQ(GetTouchRadiusX(scoped_xevent), 50);
  EXPECT_FLOAT_EQ(GetTouchAngle(scoped_xevent), 0.45f);
  EXPECT_FLOAT_EQ(GetTouchForce(scoped_xevent), 0.5f);

  // Touch with tracking id 5 should have old radius/angle value and new pressue
  // value.
  valuators.clear();
  valuators.push_back(Valuator(DeviceDataManagerX11::DT_TOUCH_PRESSURE, 50));
  scoped_xevent.InitTouchEvent(0, XI_TouchEnd, 5, gfx::Point(30, 30),
                               valuators);
  EXPECT_EQ(ui::ET_TOUCH_RELEASED, ui::EventTypeFromNative(scoped_xevent));
  EXPECT_EQ("30,30", ui::EventLocationFromNative(scoped_xevent).ToString());
  EXPECT_EQ(GetTouchId(scoped_xevent), 0);
  EXPECT_EQ(GetTouchRadiusX(scoped_xevent), 10);
  EXPECT_FLOAT_EQ(GetTouchAngle(scoped_xevent), 0.25f);
  EXPECT_FLOAT_EQ(GetTouchForce(scoped_xevent), 0.05f);

  // Touch with tracking id 6 should have old angle/pressure value and new
  // radius value.
  valuators.clear();
  valuators.push_back(Valuator(DeviceDataManagerX11::DT_TOUCH_MAJOR, 50));
  scoped_xevent.InitTouchEvent(0, XI_TouchEnd, 6, gfx::Point(200, 200),
                               valuators);
  EXPECT_EQ(ui::ET_TOUCH_RELEASED, ui::EventTypeFromNative(scoped_xevent));
  EXPECT_EQ("200,200", ui::EventLocationFromNative(scoped_xevent).ToString());
  EXPECT_EQ(GetTouchId(scoped_xevent), 1);
  EXPECT_EQ(GetTouchRadiusX(scoped_xevent), 25);
  EXPECT_FLOAT_EQ(GetTouchAngle(scoped_xevent), 0.45f);
  EXPECT_FLOAT_EQ(GetTouchForce(scoped_xevent), 0.5f);
}

int GetTouchIdForTrackingId(uint32 tracking_id) {
  int slot = 0;
  bool success =
      TouchFactory::GetInstance()->QuerySlotForTrackingID(tracking_id, &slot);
  if (success)
    return slot;
  return -1;
}

TEST_F(PlatformEventUtilsXTest, TouchEventIdRefcounting) {
  std::vector<unsigned int> devices;
  devices.push_back(0);
  ui::SetUpTouchDevicesForTest(devices);
  std::vector<Valuator> valuators;

  const int kTrackingId0 = 5;
  const int kTrackingId1 = 7;

  // Increment ref count once for first touch.
  ui::ScopedXI2Event xpress0;
  xpress0.InitTouchEvent(0, XI_TouchBegin, kTrackingId0, gfx::Point(10, 10),
                         valuators);
  scoped_ptr<ui::TouchEvent> upress0(new ui::TouchEvent(xpress0));
  EXPECT_EQ(0, GetTouchIdForTrackingId(kTrackingId0));

  // Increment ref count 4 times for second touch.
  ui::ScopedXI2Event xpress1;
  xpress1.InitTouchEvent(0, XI_TouchBegin, kTrackingId1, gfx::Point(20, 20),
                         valuators);

  for (int i = 0; i < 4; ++i) {
    ui::TouchEvent upress1(xpress1);
    EXPECT_EQ(1, GetTouchIdForTrackingId(kTrackingId1));
  }

  ui::ScopedXI2Event xrelease1;
  xrelease1.InitTouchEvent(0, XI_TouchEnd, kTrackingId1, gfx::Point(10, 10),
                           valuators);

  // Decrement ref count 3 times for second touch.
  for (int i = 0; i < 3; ++i) {
    ui::TouchEvent urelease1(xrelease1);
    EXPECT_EQ(1, GetTouchIdForTrackingId(kTrackingId1));
  }

  // This should clear the touch id of the second touch.
  scoped_ptr<ui::TouchEvent> urelease1(new ui::TouchEvent(xrelease1));
  urelease1.reset();
  EXPECT_EQ(-1, GetTouchIdForTrackingId(kTrackingId1));

  // This should clear the touch id of the first touch.
  ui::ScopedXI2Event xrelease0;
  xrelease0.InitTouchEvent(0, XI_TouchEnd, kTrackingId0, gfx::Point(10, 10),
                           valuators);
  scoped_ptr<ui::TouchEvent> urelease0(new ui::TouchEvent(xrelease0));
  urelease0.reset();
  EXPECT_EQ(-1, GetTouchIdForTrackingId(kTrackingId0));
}
#endif

TEST_F(PlatformEventUtilsXTest, NumpadKeyEvents) {
  XEvent event;
  Display* display = gfx::GetXDisplay();

  struct {
    bool is_numpad_key;
    int x_keysym;
  } keys[] = {
      // XK_KP_Space and XK_KP_Equal are the extrema in the conventional
      // keysymdef.h numbering.
      {true, XK_KP_Space},
      {true, XK_KP_Equal},
      // Other numpad keysyms. (This is actually exhaustive in the current
      // list.)
      {true, XK_KP_Tab},
      {true, XK_KP_Enter},
      {true, XK_KP_F1},
      {true, XK_KP_F2},
      {true, XK_KP_F3},
      {true, XK_KP_F4},
      {true, XK_KP_Home},
      {true, XK_KP_Left},
      {true, XK_KP_Up},
      {true, XK_KP_Right},
      {true, XK_KP_Down},
      {true, XK_KP_Prior},
      {true, XK_KP_Page_Up},
      {true, XK_KP_Next},
      {true, XK_KP_Page_Down},
      {true, XK_KP_End},
      {true, XK_KP_Begin},
      {true, XK_KP_Insert},
      {true, XK_KP_Delete},
      {true, XK_KP_Multiply},
      {true, XK_KP_Add},
      {true, XK_KP_Separator},
      {true, XK_KP_Subtract},
      {true, XK_KP_Decimal},
      {true, XK_KP_Divide},
      {true, XK_KP_0},
      {true, XK_KP_1},
      {true, XK_KP_2},
      {true, XK_KP_3},
      {true, XK_KP_4},
      {true, XK_KP_5},
      {true, XK_KP_6},
      {true, XK_KP_7},
      {true, XK_KP_8},
      {true, XK_KP_9},
      // Largest keysym preceding XK_KP_Space.
      {false, XK_Num_Lock},
      // Smallest keysym following XK_KP_Equal.
      {false, XK_F1},
      // Non-numpad analogues of numpad keysyms.
      {false, XK_Tab},
      {false, XK_Return},
      {false, XK_F1},
      {false, XK_F2},
      {false, XK_F3},
      {false, XK_F4},
      {false, XK_Home},
      {false, XK_Left},
      {false, XK_Up},
      {false, XK_Right},
      {false, XK_Down},
      {false, XK_Prior},
      {false, XK_Page_Up},
      {false, XK_Next},
      {false, XK_Page_Down},
      {false, XK_End},
      {false, XK_Insert},
      {false, XK_Delete},
      {false, XK_multiply},
      {false, XK_plus},
      {false, XK_minus},
      {false, XK_period},
      {false, XK_slash},
      {false, XK_0},
      {false, XK_1},
      {false, XK_2},
      {false, XK_3},
      {false, XK_4},
      {false, XK_5},
      {false, XK_6},
      {false, XK_7},
      {false, XK_8},
      {false, XK_9},
      // Miscellaneous other keysyms.
      {false, XK_BackSpace},
      {false, XK_Scroll_Lock},
      {false, XK_Multi_key},
      {false, XK_Select},
      {false, XK_Num_Lock},
      {false, XK_Shift_L},
      {false, XK_space},
      {false, XK_A},
  };

  for (size_t k = 0; k < arraysize(keys); ++k) {
    int x_keycode = XKeysymToKeycode(display, keys[k].x_keysym);
    // Exclude keysyms for which the server has no corresponding keycode.
    if (x_keycode) {
      InitKeyEvent(display, &event, true, x_keycode, 0);
      // int keysym = XLookupKeysym(&event.xkey, 0);
      // if (keysym) {
      ui::KeyEvent ui_key_event = PlatformEventBuilder::BuildKeyEvent(&event);
      EXPECT_EQ(keys[k].is_numpad_key ? ui::EF_NUMPAD_KEY : 0,
                ui_key_event.flags() & ui::EF_NUMPAD_KEY);
    }
  }
}

TEST_F(PlatformEventUtilsXTest, FunctionKeyEvents) {
  Display* display = gfx::GetXDisplay();

  // Min  function key code minus 1.
  EXPECT_FALSE(HasFunctionKeyFlagSetIfSupported(display, XK_F1 - 1));
  // All function keys.
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F1));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F2));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F3));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F4));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F5));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F6));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F7));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F8));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F9));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F10));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F11));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F12));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F13));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F14));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F15));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F16));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F17));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F18));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F19));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F20));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F21));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F22));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F23));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F24));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F25));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F26));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F27));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F28));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F29));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F30));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F31));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F32));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F33));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F34));
  EXPECT_TRUE(HasFunctionKeyFlagSetIfSupported(display, XK_F35));
  // Max function key code plus 1.
  EXPECT_FALSE(HasFunctionKeyFlagSetIfSupported(display, XK_F35 + 1));
}

#if defined(USE_XI2_MT)
// Verifies that the type of events from a disabled keyboard is ET_UNKNOWN, but
// that an exception list of keys can still be processed.
TEST_F(PlatformEventUtilsXTest, DisableKeyboard) {
  DeviceDataManagerX11* device_data_manager =
      static_cast<DeviceDataManagerX11*>(DeviceDataManager::GetInstance());
  unsigned int blocked_device_id = 1;
  unsigned int other_device_id = 2;
  unsigned int master_device_id = 3;
  device_data_manager->DisableDevice(blocked_device_id);

  scoped_ptr<std::set<KeyboardCode>> excepted_keys(new std::set<KeyboardCode>);
  excepted_keys->insert(VKEY_B);
  device_data_manager->SetDisabledKeyboardAllowedKeys(excepted_keys.Pass());

  ScopedXI2Event xev;
  // A is not allowed on the blocked keyboard, and should return ET_UNKNOWN.
  xev.InitGenericKeyEvent(master_device_id, blocked_device_id,
                          ui::ET_KEY_PRESSED, ui::VKEY_A, 0);
  EXPECT_EQ(ui::ET_UNKNOWN, ui::EventTypeFromNative(xev));

  // The B key is allowed as an exception, and should return KEY_PRESSED.
  xev.InitGenericKeyEvent(master_device_id, blocked_device_id,
                          ui::ET_KEY_PRESSED, ui::VKEY_B, 0);
  EXPECT_EQ(ui::ET_KEY_PRESSED, ui::EventTypeFromNative(xev));

  // Both A and B are allowed on an unblocked keyboard device.
  xev.InitGenericKeyEvent(master_device_id, other_device_id, ui::ET_KEY_PRESSED,
                          ui::VKEY_A, 0);
  EXPECT_EQ(ui::ET_KEY_PRESSED, ui::EventTypeFromNative(xev));
  xev.InitGenericKeyEvent(master_device_id, other_device_id, ui::ET_KEY_PRESSED,
                          ui::VKEY_B, 0);
  EXPECT_EQ(ui::ET_KEY_PRESSED, ui::EventTypeFromNative(xev));

  device_data_manager->EnableDevice(blocked_device_id);
  device_data_manager->SetDisabledKeyboardAllowedKeys(
      scoped_ptr<std::set<KeyboardCode>>());

  // A key returns KEY_PRESSED as per usual now that keyboard was re-enabled.
  xev.InitGenericKeyEvent(master_device_id, blocked_device_id,
                          ui::ET_KEY_PRESSED, ui::VKEY_A, 0);
  EXPECT_EQ(ui::ET_KEY_PRESSED, ui::EventTypeFromNative(xev));
}

// Verifies that the type of events from a disabled mouse is ET_UNKNOWN.
TEST_F(PlatformEventUtilsXTest, DisableMouse) {
  DeviceDataManagerX11* device_data_manager =
      static_cast<DeviceDataManagerX11*>(DeviceDataManager::GetInstance());
  unsigned int blocked_device_id = 1;
  unsigned int other_device_id = 2;
  std::vector<unsigned int> device_list;
  device_list.push_back(blocked_device_id);
  device_list.push_back(other_device_id);
  TouchFactory::GetInstance()->SetPointerDeviceForTest(device_list);

  device_data_manager->DisableDevice(blocked_device_id);

  ScopedXI2Event xev;
  xev.InitGenericButtonEvent(blocked_device_id, ET_MOUSE_PRESSED, gfx::Point(),
                             EF_LEFT_MOUSE_BUTTON);
  EXPECT_EQ(ui::ET_UNKNOWN, ui::EventTypeFromNative(xev));

  xev.InitGenericButtonEvent(other_device_id, ET_MOUSE_PRESSED, gfx::Point(),
                             EF_LEFT_MOUSE_BUTTON);
  EXPECT_EQ(ui::ET_MOUSE_PRESSED, ui::EventTypeFromNative(xev));

  device_data_manager->EnableDevice(blocked_device_id);

  xev.InitGenericButtonEvent(blocked_device_id, ET_MOUSE_PRESSED, gfx::Point(),
                             EF_LEFT_MOUSE_BUTTON);
  EXPECT_EQ(ui::ET_MOUSE_PRESSED, ui::EventTypeFromNative(xev));
}
#endif  // defined(USE_XI2_MT)

#if !defined(OS_CHROMEOS)
TEST_F(PlatformEventUtilsXTest, ImeFabricatedKeyEvents) {
  Display* display = gfx::GetXDisplay();

  unsigned int state_to_be_fabricated[] = {
      0, ShiftMask, LockMask, ShiftMask | LockMask,
  };
  for (size_t i = 0; i < arraysize(state_to_be_fabricated); ++i) {
    unsigned int state = state_to_be_fabricated[i];
    for (int is_char = 0; is_char < 2; ++is_char) {
      XEvent x_event;
      InitKeyEvent(display, &x_event, true, 0, state);
      ui::KeyEvent key_event = PlatformEventBuilder::BuildKeyEvent(&x_event);
      if (is_char) {
        KeyEventTestApi test_event(&key_event);
        test_event.set_is_char(true);
      }
      EXPECT_TRUE(key_event.flags() & ui::EF_IME_FABRICATED_KEY);
    }
  }

  unsigned int state_to_be_not_fabricated[] = {
      ControlMask, Mod1Mask, Mod2Mask, ShiftMask | ControlMask,
  };
  for (size_t i = 0; i < arraysize(state_to_be_not_fabricated); ++i) {
    unsigned int state = state_to_be_not_fabricated[i];
    for (int is_char = 0; is_char < 2; ++is_char) {
      XEvent x_event;
      InitKeyEvent(display, &x_event, true, 0, state);
      ui::KeyEvent key_event = PlatformEventBuilder::BuildKeyEvent(&x_event);
      if (is_char) {
        KeyEventTestApi test_event(&key_event);
        test_event.set_is_char(true);
      }
      EXPECT_FALSE(key_event.flags() & ui::EF_IME_FABRICATED_KEY);
    }
  }
}
#endif

}  // namespace ui
