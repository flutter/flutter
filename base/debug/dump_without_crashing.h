// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_DEBUG_DUMP_WITHOUT_CRASHING_H_
#define BASE_DEBUG_DUMP_WITHOUT_CRASHING_H_

#include "base/base_export.h"
#include "base/compiler_specific.h"
#include "build/build_config.h"

namespace base {

namespace debug {

// Handler to silently dump the current process without crashing.
// Before calling this function, call SetDumpWithoutCrashingFunction to pass a
// function pointer, typically chrome!DumpProcessWithoutCrash.  See example code
// in chrome_main.cc that does this for chrome.dll.
BASE_EXPORT void DumpWithoutCrashing();

// Sets a function that'll be invoked to dump the current process when
// DumpWithoutCrashing() is called.
BASE_EXPORT void SetDumpWithoutCrashingFunction(void (CDECL *function)());

}  // namespace debug

}  // namespace base

#endif  // BASE_DEBUG_DUMP_WITHOUT_CRASHING_H_
