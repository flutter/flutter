// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/allocator/type_profiler_control.h"

namespace base {
namespace type_profiler {

namespace {

#if defined(TYPE_PROFILING)
const bool kTypeProfilingEnabled = true;
#else
const bool kTypeProfilingEnabled = false;
#endif

bool g_enable_intercept = kTypeProfilingEnabled;

}  // namespace

// static
void Controller::Stop() {
  g_enable_intercept = false;
}

// static
bool Controller::IsProfiling() {
  return kTypeProfilingEnabled && g_enable_intercept;
}

// static
void Controller::Restart() {
  g_enable_intercept = kTypeProfilingEnabled;
}

}  // namespace type_profiler
}  // namespace base
