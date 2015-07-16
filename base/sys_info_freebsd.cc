// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sys_info.h"

#include <sys/sysctl.h>

#include "base/logging.h"

namespace base {

int64 SysInfo::AmountOfPhysicalMemory() {
  int pages, page_size;
  size_t size = sizeof(pages);
  sysctlbyname("vm.stats.vm.v_page_count", &pages, &size, NULL, 0);
  sysctlbyname("vm.stats.vm.v_page_size", &page_size, &size, NULL, 0);
  if (pages == -1 || page_size == -1) {
    NOTREACHED();
    return 0;
  }
  return static_cast<int64>(pages) * page_size;
}

// static
uint64 SysInfo::MaxSharedMemorySize() {
  size_t limit;
  size_t size = sizeof(limit);
  if (sysctlbyname("kern.ipc.shmmax", &limit, &size, NULL, 0) < 0) {
    NOTREACHED();
    return 0;
  }
  return static_cast<uint64>(limit);
}

}  // namespace base
