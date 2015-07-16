// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_PLATFORM_X11_HOTPLUG_EVENT_HANDLER_H_
#define UI_EVENTS_PLATFORM_X11_HOTPLUG_EVENT_HANDLER_H_

#include "ui/events/platform/x11/device_list_cache_x.h"

namespace ui {

class DeviceHotplugEventObserver;

// Parses X11 native devices and propagates the list of active devices to an
// observer.
class EVENTS_BASE_EXPORT HotplugEventHandlerX11 {
 public:
  explicit HotplugEventHandlerX11(DeviceHotplugEventObserver* delegate);
  ~HotplugEventHandlerX11();

  // Called on an X11 hotplug event.
  void OnHotplugEvent();

 private:
  void HandleTouchscreenDevices(const XIDeviceList& device_list);

  DeviceHotplugEventObserver* delegate_;  // Not owned.

  DISALLOW_COPY_AND_ASSIGN(HotplugEventHandlerX11);
};

}  // namespace ui

#endif  // UI_EVENTS_PLATFORM_X11_HOTPLUG_EVENT_HANDLER_H_
