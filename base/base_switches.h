// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Defines all the "base" command-line switches.

#ifndef BASE_BASE_SWITCHES_H_
#define BASE_BASE_SWITCHES_H_

#include "build/build_config.h"

namespace switches {

extern const char kDisableBreakpad[];
extern const char kEnableCrashReporter[];
extern const char kFullMemoryCrashReport[];
extern const char kEnableLowEndDeviceMode[];
extern const char kDisableLowEndDeviceMode[];
extern const char kNoErrorDialogs[];
extern const char kProfilerTiming[];
extern const char kProfilerTimingDisabledValue[];
extern const char kTestChildProcess[];
extern const char kTraceToConsole[];
extern const char kTraceToFile[];
extern const char kTraceToFileName[];
extern const char kV[];
extern const char kVModule[];
extern const char kWaitForDebugger[];

#if defined(OS_POSIX)
extern const char kEnableCrashReporterForTesting[];
#endif

}  // namespace switches

#endif  // BASE_BASE_SWITCHES_H_
