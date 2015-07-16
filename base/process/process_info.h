// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PROCESS_PROCESS_INFO_H_
#define BASE_PROCESS_PROCESS_INFO_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "build/build_config.h"

namespace base {

class Time;

// Vends information about the current process.
class BASE_EXPORT CurrentProcessInfo {
 public:
  // Returns the time at which the process was launched. May be empty if an
  // error occurred retrieving the information.
  static const Time CreationTime();
};

#if defined(OS_WIN)

enum IntegrityLevel {
  INTEGRITY_UNKNOWN,
  LOW_INTEGRITY,
  MEDIUM_INTEGRITY,
  HIGH_INTEGRITY,
};

// Returns the integrity level of the process. Returns INTEGRITY_UNKNOWN if the
// system does not support integrity levels (pre-Vista) or in the case of an
// underlying system failure.
BASE_EXPORT IntegrityLevel GetCurrentProcessIntegrityLevel();

#endif  // defined(OS_WIN)



}  // namespace base

#endif  // BASE_PROCESS_PROCESS_INFO_H_
