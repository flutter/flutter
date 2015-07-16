// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_PROCESS_PROCESS_HANDLE_H_
#define BASE_PROCESS_PROCESS_HANDLE_H_

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/files/file_path.h"
#include "build/build_config.h"

#include <sys/types.h>
#if defined(OS_WIN)
#include <windows.h>
#endif

namespace base {

// ProcessHandle is a platform specific type which represents the underlying OS
// handle to a process.
// ProcessId is a number which identifies the process in the OS.
#if defined(OS_WIN)
typedef HANDLE ProcessHandle;
typedef DWORD ProcessId;
typedef HANDLE UserTokenHandle;
const ProcessHandle kNullProcessHandle = NULL;
const ProcessId kNullProcessId = 0;
#elif defined(OS_POSIX)
// On POSIX, our ProcessHandle will just be the PID.
typedef pid_t ProcessHandle;
typedef pid_t ProcessId;
const ProcessHandle kNullProcessHandle = 0;
const ProcessId kNullProcessId = 0;
#endif  // defined(OS_WIN)

// Returns the id of the current process.
BASE_EXPORT ProcessId GetCurrentProcId();

// Returns the ProcessHandle of the current process.
BASE_EXPORT ProcessHandle GetCurrentProcessHandle();

// Returns the unique ID for the specified process. This is functionally the
// same as Windows' GetProcessId(), but works on versions of Windows before
// Win XP SP1 as well.
// DEPRECATED. New code should be using Process::Pid() instead.
BASE_EXPORT ProcessId GetProcId(ProcessHandle process);

#if defined(OS_POSIX)
// Returns the path to the executable of the given process.
BASE_EXPORT FilePath GetProcessExecutablePath(ProcessHandle process);

// Returns the ID for the parent of the given process.
BASE_EXPORT ProcessId GetParentProcessId(ProcessHandle process);
#endif

}  // namespace base

#endif  // BASE_PROCESS_PROCESS_HANDLE_H_
