// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/time/default_clock.h"

namespace base {

DefaultClock::~DefaultClock() {}

Time DefaultClock::Now() {
  return Time::Now();
}

}  // namespace base
