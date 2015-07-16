// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sys_info.h"

#include <sys/param.h>
#include <sys/shm.h>
#include <sys/sysctl.h>

#include "base/logging.h"

namespace {

int64 AmountOfMemory(int pages_name) {
  long pages = sysconf(pages_name);
  long page_size = sysconf(_SC_PAGESIZE);
  if (pages == -1 || page_size == -1) {
    NOTREACHED();
    return 0;
  }
  return static_cast<int64>(pages) * page_size;
}

}  // namespace

namespace base {

// static
int SysInfo::NumberOfProcessors() {
  int mib[] = { CTL_HW, HW_NCPU };
  int ncpu;
  size_t size = sizeof(ncpu);
  if (sysctl(mib, arraysize(mib), &ncpu, &size, NULL, 0) < 0) {
    NOTREACHED();
    return 1;
  }
  return ncpu;
}

// static
int64 SysInfo::AmountOfPhysicalMemory() {
  return AmountOfMemory(_SC_PHYS_PAGES);
}

// static
int64 SysInfo::AmountOfAvailablePhysicalMemory() {
  return AmountOfMemory(_SC_AVPHYS_PAGES);
}

// static
uint64 SysInfo::MaxSharedMemorySize() {
  int mib[] = { CTL_KERN, KERN_SHMINFO, KERN_SHMINFO_SHMMAX };
  size_t limit;
  size_t size = sizeof(limit);
  if (sysctl(mib, arraysize(mib), &limit, &size, NULL, 0) < 0) {
    NOTREACHED();
    return 0;
  }
  return static_cast<uint64>(limit);
}

// static
std::string SysInfo::CPUModelName() {
  int mib[] = { CTL_HW, HW_MODEL };
  char name[256];
  size_t len = arraysize(name);
  if (sysctl(mib, arraysize(mib), name, &len, NULL, 0) < 0) {
    NOTREACHED();
    return std::string();
  }
  return name;
}

}  // namespace base
