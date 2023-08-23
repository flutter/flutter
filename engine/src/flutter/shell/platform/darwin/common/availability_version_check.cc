// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <dispatch/dispatch.h>
#include <dlfcn.h>
#include <cstdint>

#include "flutter/fml/logging.h"

// See context in https://github.com/flutter/flutter/issues/132130 and
// https://github.com/flutter/engine/pull/44711.

// TODO(zanderso): Remove this after Clang 18 rolls into Xcode.
// https://github.com/flutter/flutter/issues/133203

namespace {

typedef uint32_t dyld_platform_t;

typedef struct {
  dyld_platform_t platform;
  uint32_t version;
} dyld_build_version_t;

typedef bool (*AvailabilityVersionCheckFn)(uint32_t count,
                                           dyld_build_version_t versions[]);

AvailabilityVersionCheckFn AvailabilityVersionCheck;

dispatch_once_t DispatchOnceCounter;

void InitializeAvailabilityCheck(void* unused) {
  if (AvailabilityVersionCheck) {
    return;
  }
  AvailabilityVersionCheck = reinterpret_cast<AvailabilityVersionCheckFn>(
      dlsym(RTLD_DEFAULT, "_availability_version_check"));
  FML_CHECK(AvailabilityVersionCheck);
}

extern "C" bool _availability_version_check(uint32_t count,
                                            dyld_build_version_t versions[]) {
  dispatch_once_f(&DispatchOnceCounter, NULL, InitializeAvailabilityCheck);
  return AvailabilityVersionCheck(count, versions);
}

}  // namespace
