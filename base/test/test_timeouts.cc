// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/test_timeouts.h"

#include <algorithm>

#include "base/command_line.h"
#include "base/debug/debugger.h"
#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/test/test_switches.h"

namespace {

// ASan/TSan/MSan instrument each memory access. This may slow the execution
// down significantly.
#if defined(MEMORY_SANITIZER)
// For MSan the slowdown depends heavily on the value of msan_track_origins GYP
// flag. The multiplier below corresponds to msan_track_origins=1.
static const int kTimeoutMultiplier = 6;
#elif defined(ADDRESS_SANITIZER) && defined(OS_WIN)
// Asan/Win has not been optimized yet, give it a higher
// timeout multiplier. See http://crbug.com/412471
static const int kTimeoutMultiplier = 3;
#elif defined(ADDRESS_SANITIZER) || defined(THREAD_SANITIZER) || \
    defined(SYZYASAN)
static const int kTimeoutMultiplier = 2;
#else
static const int kTimeoutMultiplier = 1;
#endif

const int kAlmostInfiniteTimeoutMs = 100000000;

// Sets value to the greatest of:
// 1) value's current value multiplied by kTimeoutMultiplier (assuming
// InitializeTimeout is called only once per value).
// 2) min_value.
// 3) the numerical value given by switch_name on the command line multiplied
// by kTimeoutMultiplier.
void InitializeTimeout(const char* switch_name, int min_value, int* value) {
  DCHECK(value);
  if (base::CommandLine::ForCurrentProcess()->HasSwitch(switch_name)) {
    std::string string_value(base::CommandLine::ForCurrentProcess()->
         GetSwitchValueASCII(switch_name));
    int timeout;
    base::StringToInt(string_value, &timeout);
    *value = std::max(*value, timeout);
  }
  *value *= kTimeoutMultiplier;
  *value = std::max(*value, min_value);
}

// Sets value to the greatest of:
// 1) value's current value multiplied by kTimeoutMultiplier.
// 2) 0
// 3) the numerical value given by switch_name on the command line multiplied
// by kTimeoutMultiplier.
void InitializeTimeout(const char* switch_name, int* value) {
  InitializeTimeout(switch_name, 0, value);
}

}  // namespace

// static
bool TestTimeouts::initialized_ = false;

// The timeout values should increase in the order they appear in this block.
// static
int TestTimeouts::tiny_timeout_ms_ = 100;
int TestTimeouts::action_timeout_ms_ = 10000;
#ifndef NDEBUG
int TestTimeouts::action_max_timeout_ms_ = 45000;
#else
int TestTimeouts::action_max_timeout_ms_ = 30000;
#endif  // NDEBUG

int TestTimeouts::test_launcher_timeout_ms_ = 45000;

// static
void TestTimeouts::Initialize() {
  if (initialized_) {
    NOTREACHED();
    return;
  }
  initialized_ = true;

  if (base::debug::BeingDebugged()) {
    fprintf(stdout,
        "Detected presence of a debugger, running without test timeouts.\n");
  }

  // Note that these timeouts MUST be initialized in the correct order as
  // per the CHECKS below.
  InitializeTimeout(switches::kTestTinyTimeout, &tiny_timeout_ms_);
  InitializeTimeout(switches::kUiTestActionTimeout,
                    base::debug::BeingDebugged() ? kAlmostInfiniteTimeoutMs
                                                 : tiny_timeout_ms_,
                    &action_timeout_ms_);
  InitializeTimeout(switches::kUiTestActionMaxTimeout, action_timeout_ms_,
                    &action_max_timeout_ms_);

  // Test launcher timeout is independent from anything above action timeout.
  InitializeTimeout(switches::kTestLauncherTimeout, action_timeout_ms_,
                    &test_launcher_timeout_ms_);

  // The timeout values should be increasing in the right order.
  CHECK(tiny_timeout_ms_ <= action_timeout_ms_);
  CHECK(action_timeout_ms_ <= action_max_timeout_ms_);

  CHECK(action_timeout_ms_ <= test_launcher_timeout_ms_);
}
