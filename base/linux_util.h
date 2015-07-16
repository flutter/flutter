// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_LINUX_UTIL_H_
#define BASE_LINUX_UTIL_H_

#include <stdint.h>
#include <sys/types.h>

#include <string>

#include "base/base_export.h"

namespace base {

// This is declared here so the crash reporter can access the memory directly
// in compromised context without going through the standard library.
BASE_EXPORT extern char g_linux_distro[];

// Get the Linux Distro if we can, or return "Unknown".
BASE_EXPORT std::string GetLinuxDistro();

// Set the Linux Distro string.
BASE_EXPORT void SetLinuxDistro(const std::string& distro);

// For a given process |pid|, look through all its threads and find the first
// thread with /proc/[pid]/task/[thread_id]/syscall whose first N bytes matches
// |expected_data|, where N is the length of |expected_data|.
// Returns the thread id or -1 on error.  If |syscall_supported| is
// set to false the kernel does not support syscall in procfs.
BASE_EXPORT pid_t FindThreadIDWithSyscall(pid_t pid,
                                          const std::string& expected_data,
                                          bool* syscall_supported);

}  // namespace base

#endif  // BASE_LINUX_UTIL_H_
