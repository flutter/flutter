// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_info.h"

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/process/internal_linux.h"
#include "base/process/process_handle.h"
#include "base/time/time.h"

namespace base {

//static
const Time CurrentProcessInfo::CreationTime() {
  ProcessHandle pid = GetCurrentProcessHandle();
  int64 start_ticks =
      internal::ReadProcStatsAndGetFieldAsInt64(pid, internal::VM_STARTTIME);
  DCHECK(start_ticks);
  TimeDelta start_offset = internal::ClockTicksToTimeDelta(start_ticks);
  Time boot_time = internal::GetBootTime();
  DCHECK(!boot_time.is_null());
  return Time(boot_time + start_offset);
}

}  // namespace base
