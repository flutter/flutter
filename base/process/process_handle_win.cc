// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_handle.h"

#include <windows.h>

#include "base/memory/scoped_ptr.h"
#include "base/win/scoped_handle.h"
#include "base/win/windows_version.h"

namespace base {

ProcessId GetCurrentProcId() {
  return ::GetCurrentProcessId();
}

ProcessHandle GetCurrentProcessHandle() {
  return ::GetCurrentProcess();
}

ProcessId GetProcId(ProcessHandle process) {
  // This returns 0 if we have insufficient rights to query the process handle.
  return GetProcessId(process);
}

}  // namespace base
