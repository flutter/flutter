// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_DEVICE_HOTPLUG_EVENT_OBSERVER_H_
#define UI_EVENTS_DEVICE_HOTPLUG_EVENT_OBSERVER_H_

#include "ui/events/events_base_export.h"
#include "ui/events/touchscreen_device.h"

namespace ui {

// Listener for specific input device hotplug events.
class EVENTS_BASE_EXPORT DeviceHotplugEventObserver {
 public:
  virtual ~DeviceHotplugEventObserver() {}

  // On a hotplug event this is called with the list of available devices.
  virtual void OnTouchscreenDevicesUpdated(
      const std::vector<TouchscreenDevice>& devices) = 0;
};

}  // namespace ui

#endif  // UI_EVENTS_DEVICE_HOTPLUG_EVENT_OBSERVER_H_
