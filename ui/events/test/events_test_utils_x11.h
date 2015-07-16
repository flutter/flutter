// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_TEST_EVENTS_TEST_UTILS_X11_H_
#define UI_EVENTS_TEST_EVENTS_TEST_UTILS_X11_H_

#include "base/memory/scoped_ptr.h"
#include "ui/events/event_constants.h"
#include "ui/events/keycodes/keyboard_codes.h"
#include "ui/events/platform/x11/device_data_manager_x11.h"
#include "ui/gfx/point.h"
#include "ui/gfx/x/x11_types.h"

typedef union _XEvent XEvent;

namespace ui {

struct Valuator {
  Valuator(DeviceDataManagerX11::DataType type, double v)
      : data_type(type), value(v) {}

  DeviceDataManagerX11::DataType data_type;
  double value;
};

struct XEventDeleter {
  void operator()(XEvent* event);
};

class ScopedXI2Event {
 public:
  ScopedXI2Event();
  ~ScopedXI2Event();

  operator XEvent*() { return event_.get(); }

  // Initializes a XEvent with for the appropriate type with the specified data.
  // Note that ui::EF_ flags should be passed as |flags|, not the native ones in
  // <X11/X.h>.
  void InitKeyEvent(EventType type,
                    KeyboardCode key_code,
                    int flags);

  // Initializes an Xinput2 key event.
  // |deviceid| is the master, and |sourceid| is the slave device.
  void InitGenericKeyEvent(int deviceid,
                           int sourceid,
                           EventType type,
                           KeyboardCode key_code,
                           int flags);

  void InitGenericButtonEvent(int deviceid,
                              EventType type,
                              const gfx::Point& location,
                              int flags);

  void InitGenericMouseWheelEvent(int deviceid,
                                  int wheel_delta,
                                  int flags);

  void InitScrollEvent(int deviceid,
                       int x_offset,
                       int y_offset,
                       int x_offset_ordinal,
                       int y_offset_ordinal,
                       int finger_count);

  void InitFlingScrollEvent(int deviceid,
                            int x_velocity,
                            int y_velocity,
                            int x_velocity_ordinal,
                            int y_velocity_ordinal,
                            bool is_cancel);

  void InitTouchEvent(int deviceid,
                      int evtype,
                      int tracking_id,
                      const gfx::Point& location,
                      const std::vector<Valuator>& valuators);

 private:
  void Cleanup();

  void SetUpValuators(const std::vector<Valuator>& valuators);

  scoped_ptr<XEvent, XEventDeleter> event_;

  DISALLOW_COPY_AND_ASSIGN(ScopedXI2Event);
};

// Initializes a test touchpad device for scroll events.
void SetUpTouchPadForTest(unsigned int deviceid);

// Initializes a list of touchscreen devices for touch events.
void SetUpTouchDevicesForTest(const std::vector<unsigned int>& devices);

}  // namespace ui

#endif  // UI_EVENTS_TEST_EVENTS_TEST_UTILS_X11_H_
