// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_SYSTEM_MONITOR_SYSTEM_MONITOR_H_
#define BASE_SYSTEM_MONITOR_SYSTEM_MONITOR_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/memory/ref_counted.h"
#include "base/observer_list_threadsafe.h"
#include "build/build_config.h"

namespace base {

// Class for monitoring various system-related subsystems
// such as power management, network status, etc.
// TODO(mbelshe):  Add support beyond just power management.
class BASE_EXPORT SystemMonitor {
 public:
  // Type of devices whose change need to be monitored, such as add/remove.
  enum DeviceType {
    DEVTYPE_AUDIO_CAPTURE,  // Audio capture device, e.g., microphone.
    DEVTYPE_VIDEO_CAPTURE,  // Video capture device, e.g., webcam.
    DEVTYPE_UNKNOWN,  // Other devices.
  };

  // Create SystemMonitor. Only one SystemMonitor instance per application
  // is allowed.
  SystemMonitor();
  ~SystemMonitor();

  // Get the application-wide SystemMonitor (if not present, returns NULL).
  static SystemMonitor* Get();

  class BASE_EXPORT DevicesChangedObserver {
   public:
    // Notification that the devices connected to the system have changed.
    // This is only implemented on Windows currently.
    virtual void OnDevicesChanged(DeviceType device_type) {}

   protected:
    virtual ~DevicesChangedObserver() {}
  };

  // Add a new observer.
  // Can be called from any thread.
  // Must not be called from within a notification callback.
  void AddDevicesChangedObserver(DevicesChangedObserver* obs);

  // Remove an existing observer.
  // Can be called from any thread.
  // Must not be called from within a notification callback.
  void RemoveDevicesChangedObserver(DevicesChangedObserver* obs);

  // The ProcessFoo() style methods are a broken pattern and should not
  // be copied. Any significant addition to this class is blocked on
  // refactoring to improve the state of affairs. See http://crbug.com/149059

  // Cross-platform handling of a device change event.
  void ProcessDevicesChanged(DeviceType device_type);

 private:
  // Functions to trigger notifications.
  void NotifyDevicesChanged(DeviceType device_type);

  scoped_refptr<ObserverListThreadSafe<DevicesChangedObserver> >
      devices_changed_observer_list_;

  DISALLOW_COPY_AND_ASSIGN(SystemMonitor);
};

}  // namespace base

#endif  // BASE_SYSTEM_MONITOR_SYSTEM_MONITOR_H_
