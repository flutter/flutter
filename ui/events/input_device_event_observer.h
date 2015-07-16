// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_EVENTS_INPUT_DEVICE_EVENT_OBSERVER_H_
#define UI_EVENTS_INPUT_DEVICE_EVENT_OBSERVER_H_

namespace ui {

// DeviceDataManager observer used to announce input hotplug events.
class InputDeviceEventObserver {
 public:
  virtual ~InputDeviceEventObserver() {}

  virtual void OnInputDeviceConfigurationChanged() = 0;
};

}  // namespace ui

#endif  // UI_EVENTS_INPUT_DEVICE_EVENT_OBSERVER_H_
