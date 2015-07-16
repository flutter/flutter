// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_X11_TOUCH_FACTORY_X11_H_
#define UI_EVENTS_PLATFORM_X11_TOUCH_FACTORY_X11_H_

#include <bitset>
#include <map>
#include <set>
#include <utility>
#include <vector>

#include "base/timer/timer.h"
#include "ui/events/events_base_export.h"
#include "ui/gfx/sequential_id_generator.h"

template <typename T>
struct DefaultSingletonTraits;

typedef unsigned long Cursor;
typedef unsigned long Window;
typedef struct _XDisplay Display;
typedef union _XEvent XEvent;

namespace ui {

// Functions related to determining touch devices.
class EVENTS_BASE_EXPORT TouchFactory {
 private:
  TouchFactory();
  ~TouchFactory();

 public:
  // Returns the TouchFactory singleton.
  static TouchFactory* GetInstance();

  // Sets the touch devices from the command line.
  static void SetTouchDeviceListFromCommandLine();

  // Updates the list of devices.
  void UpdateDeviceList(Display* display);

  // Checks whether an XI2 event should be processed or not (i.e. if the event
  // originated from a device we are interested in).
  bool ShouldProcessXI2Event(XEvent* xevent);

  // Setup an X Window for XInput2 events.
  void SetupXI2ForXWindow(::Window xid);

  // Keeps a list of touch devices so that it is possible to determine if a
  // pointer event is a touch-event or a mouse-event. The list is reset each
  // time this is called.
  void SetTouchDeviceList(const std::vector<unsigned int>& devices);

  // Is the device a touch-device?
  bool IsTouchDevice(unsigned int deviceid) const;

  // Is the device a real multi-touch-device? (see doc. for |touch_device_list_|
  // below for more explanation.)
  bool IsMultiTouchDevice(unsigned int deviceid) const;

  // Tries to find an existing slot ID mapping to tracking ID. Returns true
  // if the slot is found and it is saved in |slot|, false if no such slot
  // can be found.
  bool QuerySlotForTrackingID(uint32 tracking_id, int* slot);

  // Tries to find an existing slot ID mapping to tracking ID. If there
  // isn't one already, allocates a new slot ID and sets up the mapping.
  int GetSlotForTrackingID(uint32 tracking_id);

  // Increases the number of times |ReleaseSlotForTrackingID| needs to be called
  // on a given tracking id before it will actually be released.
  void AcquireSlotForTrackingID(uint32 tracking_id);

  // Releases the slot ID mapping to tracking ID.
  void ReleaseSlotForTrackingID(uint32 tracking_id);

  // Whether any touch device is currently present and enabled.
  bool IsTouchDevicePresent();

  // Pairs of <vendor id, product id> of external touch screens.
  const std::set<std::pair<int, int>>& GetTouchscreenIds() const {
    return touchscreen_ids_;
  }

  // Return maximum simultaneous touch points supported by device.
  int GetMaxTouchPoints() const;

  // Resets the TouchFactory singleton.
  void ResetForTest();

  // Sets up the device id in the list |devices| as multi-touch capable
  // devices and enables touch events processing. This function is only
  // for test purpose, and it does not query from X server.
  void SetTouchDeviceForTest(const std::vector<unsigned int>& devices);

  // Sets up the device id in the list |devices| as pointer devices.
  // This function is only for test purpose, and it does not query from
  // X server.
  void SetPointerDeviceForTest(const std::vector<unsigned int>& devices);

 private:
  // Requirement for Singleton
  friend struct DefaultSingletonTraits<TouchFactory>;

  void CacheTouchscreenIds(Display* display, int id);

  // NOTE: To keep track of touch devices, we currently maintain a lookup table
  // to quickly decide if a device is a touch device or not. We also maintain a
  // list of the touch devices. Ideally, there will be only one touch device,
  // and instead of having the lookup table and the list, there will be a single
  // identifier for the touch device. This can be completed after enough testing
  // on real touch devices.

  static const int kMaxDeviceNum = 128;

  // A quick lookup table for determining if events from the pointer device
  // should be processed.
  std::bitset<kMaxDeviceNum> pointer_device_lookup_;

  // A quick lookup table for determining if a device is a touch device.
  std::bitset<kMaxDeviceNum> touch_device_lookup_;

  // Indicates whether touch events are explicitly disabled.
  bool touch_events_disabled_;

  // The list of touch devices. For testing/debugging purposes, a single-pointer
  // device (mouse or touch screen without sufficient X/driver support for MT)
  // can sometimes be treated as a touch device. The key in the map represents
  // the device id, and the value represents if the device is multi-touch
  // capable.
  std::map<int, bool> touch_device_list_;

  // Touch screen <vid, pid>s.
  std::set<std::pair<int, int>> touchscreen_ids_;

  // Maps from a tracking id to the number of times |ReleaseSlotForTrackingID|
  // must be called before the tracking id is released.
  std::map<uint32, int> tracking_id_refcounts_;

  // Maximum simultaneous touch points supported by device. In the case of
  // devices with multiple digitizers (e.g. multiple touchscreens), the value
  // is the maximum of the set of maximum supported contacts by each individual
  // digitizer.
  int max_touch_points_;

  // Device ID of the virtual core keyboard.
  int virtual_core_keyboard_device_;

  SequentialIDGenerator id_generator_;

  DISALLOW_COPY_AND_ASSIGN(TouchFactory);
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_X11_TOUCH_FACTORY_X11_H_
