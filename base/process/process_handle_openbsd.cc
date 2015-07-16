// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/process/process_handle.h"

#include <sys/sysctl.h>
#include <sys/types.h>
#include <unistd.h>

namespace base {

ProcessId GetParentProcessId(ProcessHandle process) {
  struct kinfo_proc info;
  size_t length;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process,
                sizeof(struct kinfo_proc), 0 };

  if (sysctl(mib, arraysize(mib), NULL, &length, NULL, 0) < 0)
    return -1;

  mib[5] = (length / sizeof(struct kinfo_proc));

  if (sysctl(mib, arraysize(mib), &info, &length, NULL, 0) < 0)
    return -1;

  return info.p_ppid;
}

FilePath GetProcessExecutablePath(ProcessHandle process) {
  struct kinfo_proc kp;
  size_t len;
  int mib[] = { CTL_KERN, KERN_PROC, KERN_PROC_PID, process,
                sizeof(struct kinfo_proc), 0 };

  if (sysctl(mib, arraysize(mib), NULL, &len, NULL, 0) == -1)
    return FilePath();
  mib[5] = (len / sizeof(struct kinfo_proc));
  if (sysctl(mib, arraysize(mib), &kp, &len, NULL, 0) < 0)
    return FilePath();
  if ((kp.p_flag & P_SYSTEM) != 0)
    return FilePath();
  if (strcmp(kp.p_comm, "chrome") == 0)
    return FilePath(kp.p_comm);

  return FilePath();
}

}  // namespace base
