// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Implementation based on sample code from
// http://developer.apple.com/library/mac/#qa/qa1340/_index.html.

#include "base/power_monitor/power_monitor_device_source.h"

#include "base/power_monitor/power_monitor.h"
#include "base/power_monitor/power_monitor_source.h"

#include <IOKit/IOMessage.h>
#include <IOKit/pwr_mgt/IOPMLib.h>

namespace base {

void ProcessPowerEventHelper(PowerMonitorSource::PowerEvent event) {
  PowerMonitorSource::ProcessPowerEvent(event);
}

namespace {

io_connect_t g_system_power_io_port = 0;
IONotificationPortRef g_notification_port_ref = 0;
io_object_t g_notifier_object = 0;

void SystemPowerEventCallback(void*,
                              io_service_t service,
                              natural_t message_type,
                              void* message_argument) {
  switch (message_type) {
    // If this message is not handled the system may delay sleep for 30 seconds.
    case kIOMessageCanSystemSleep:
      IOAllowPowerChange(g_system_power_io_port,
          reinterpret_cast<intptr_t>(message_argument));
      break;
    case kIOMessageSystemWillSleep:
      ProcessPowerEventHelper(base::PowerMonitorSource::SUSPEND_EVENT);
      IOAllowPowerChange(g_system_power_io_port,
          reinterpret_cast<intptr_t>(message_argument));
      break;

    case kIOMessageSystemWillPowerOn:
      ProcessPowerEventHelper(PowerMonitorSource::RESUME_EVENT);
      break;
  }
}

}  // namespace

// The reason we can't include this code in the constructor is because
// PlatformInit() requires an active runloop and the IO port needs to be
// allocated at sandbox initialization time, before there's a runloop.
// See crbug.com/83783 .

// static
void PowerMonitorDeviceSource::AllocateSystemIOPorts() {
  DCHECK_EQ(g_system_power_io_port, 0u);

  // Notification port allocated by IORegisterForSystemPower.
  g_system_power_io_port = IORegisterForSystemPower(
      NULL, &g_notification_port_ref, SystemPowerEventCallback,
      &g_notifier_object);

  DCHECK_NE(g_system_power_io_port, 0u);
}

void PowerMonitorDeviceSource::PlatformInit() {
  // Need to call AllocateSystemIOPorts() before creating a PowerMonitor
  // object.
  DCHECK_NE(g_system_power_io_port, 0u);
  if (g_system_power_io_port == 0)
    return;

  // Add the notification port to the application runloop
  CFRunLoopAddSource(
      CFRunLoopGetCurrent(),
      IONotificationPortGetRunLoopSource(g_notification_port_ref),
      kCFRunLoopCommonModes);
}

void PowerMonitorDeviceSource::PlatformDestroy() {
  DCHECK_NE(g_system_power_io_port, 0u);
  if (g_system_power_io_port == 0)
    return;

  // Remove the sleep notification port from the application runloop
  CFRunLoopRemoveSource(
      CFRunLoopGetCurrent(),
      IONotificationPortGetRunLoopSource(g_notification_port_ref),
      kCFRunLoopCommonModes);

  // Deregister for system sleep notifications
  IODeregisterForSystemPower(&g_notifier_object);

  // IORegisterForSystemPower implicitly opens the Root Power Domain IOService,
  // so we close it here.
  IOServiceClose(g_system_power_io_port);

  g_system_power_io_port = 0;

  // Destroy the notification port allocated by IORegisterForSystemPower.
  IONotificationPortDestroy(g_notification_port_ref);
}

}  // namespace base
