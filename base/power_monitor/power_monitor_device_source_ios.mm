// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/power_monitor/power_monitor_device_source.h"

#import <UIKit/UIKit.h>

namespace base {

void PowerMonitorDeviceSource::PlatformInit() {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  id foreground =
      [nc addObserverForName:UIApplicationWillEnterForegroundNotification
                      object:nil
                       queue:nil
                  usingBlock:^(NSNotification* notification) {
                      ProcessPowerEvent(RESUME_EVENT);
                  }];
  id background =
      [nc addObserverForName:UIApplicationDidEnterBackgroundNotification
                      object:nil
                       queue:nil
                  usingBlock:^(NSNotification* notification) {
                      ProcessPowerEvent(SUSPEND_EVENT);
                  }];
  notification_observers_.push_back(foreground);
  notification_observers_.push_back(background);
}

void PowerMonitorDeviceSource::PlatformDestroy() {
  NSNotificationCenter* nc = [NSNotificationCenter defaultCenter];
  for (std::vector<id>::iterator it = notification_observers_.begin();
       it != notification_observers_.end(); ++it) {
    [nc removeObserver:*it];
  }
  notification_observers_.clear();
}

}  // namespace base
