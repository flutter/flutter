// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_OS_CRASH_DUMPS_H_
#define BASE_MAC_OS_CRASH_DUMPS_H_

#include "base/base_export.h"

namespace base {
namespace mac {

// On Mac OS X, it can take a really long time for the OS crash handler to
// process a Chrome crash when debugging symbols are available.  This
// translates into a long wait until the process actually dies.  This call
// disables Apple Crash Reporter entirely.
BASE_EXPORT void DisableOSCrashDumps();

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_OS_CRASH_DUMPS_H_
