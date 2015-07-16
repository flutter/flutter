// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/timer/hi_res_timer_manager.h"

// On POSIX we don't need to do anything special with the system timer.

namespace base {

HighResolutionTimerManager::HighResolutionTimerManager()
    : hi_res_clock_available_(false) {
}

HighResolutionTimerManager::~HighResolutionTimerManager() {
}

void HighResolutionTimerManager::OnPowerStateChange(bool on_battery_power) {
}

void HighResolutionTimerManager::UseHiResClock(bool use) {
}

}  // namespace base
