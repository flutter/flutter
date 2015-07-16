// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sys_info.h"

#include <errno.h>
#include <string.h>
#include <sys/param.h>
#include <sys/resource.h>
#include <sys/utsname.h>
#include <unistd.h>

#include "base/basictypes.h"
#include "base/files/file_util.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/strings/utf_string_conversions.h"
#include "base/sys_info_internal.h"
#include "base/threading/thread_restrictions.h"

#if defined(OS_ANDROID)
#include <sys/vfs.h>
#define statvfs statfs  // Android uses a statvfs-like statfs struct and call.
#else
#include <sys/statvfs.h>
#endif

namespace {

#if !defined(OS_OPENBSD)
int NumberOfProcessors() {
  // sysconf returns the number of "logical" (not "physical") processors on both
  // Mac and Linux.  So we get the number of max available "logical" processors.
  //
  // Note that the number of "currently online" processors may be fewer than the
  // returned value of NumberOfProcessors(). On some platforms, the kernel may
  // make some processors offline intermittently, to save power when system
  // loading is low.
  //
  // One common use case that needs to know the processor count is to create
  // optimal number of threads for optimization. It should make plan according
  // to the number of "max available" processors instead of "currently online"
  // ones. The kernel should be smart enough to make all processors online when
  // it has sufficient number of threads waiting to run.
  long res = sysconf(_SC_NPROCESSORS_CONF);
  if (res == -1) {
    NOTREACHED();
    return 1;
  }

  return static_cast<int>(res);
}

base::LazyInstance<
    base::internal::LazySysInfoValue<int, NumberOfProcessors> >::Leaky
    g_lazy_number_of_processors = LAZY_INSTANCE_INITIALIZER;
#endif

int64 AmountOfVirtualMemory() {
  struct rlimit limit;
  int result = getrlimit(RLIMIT_DATA, &limit);
  if (result != 0) {
    NOTREACHED();
    return 0;
  }
  return limit.rlim_cur == RLIM_INFINITY ? 0 : limit.rlim_cur;
}

base::LazyInstance<
    base::internal::LazySysInfoValue<int64, AmountOfVirtualMemory> >::Leaky
    g_lazy_virtual_memory = LAZY_INSTANCE_INITIALIZER;

}  // namespace

namespace base {

#if !defined(OS_OPENBSD)
int SysInfo::NumberOfProcessors() {
  return g_lazy_number_of_processors.Get().value();
}
#endif

// static
int64 SysInfo::AmountOfVirtualMemory() {
  return g_lazy_virtual_memory.Get().value();
}

// static
int64 SysInfo::AmountOfFreeDiskSpace(const FilePath& path) {
  base::ThreadRestrictions::AssertIOAllowed();

  struct statvfs stats;
  if (HANDLE_EINTR(statvfs(path.value().c_str(), &stats)) != 0)
    return -1;
  return static_cast<int64>(stats.f_bavail) * stats.f_frsize;
}

#if !defined(OS_MACOSX) && !defined(OS_ANDROID)
// static
std::string SysInfo::OperatingSystemName() {
  struct utsname info;
  if (uname(&info) < 0) {
    NOTREACHED();
    return std::string();
  }
  return std::string(info.sysname);
}
#endif

#if !defined(OS_MACOSX) && !defined(OS_ANDROID)
// static
std::string SysInfo::OperatingSystemVersion() {
  struct utsname info;
  if (uname(&info) < 0) {
    NOTREACHED();
    return std::string();
  }
  return std::string(info.release);
}
#endif

// static
std::string SysInfo::OperatingSystemArchitecture() {
  struct utsname info;
  if (uname(&info) < 0) {
    NOTREACHED();
    return std::string();
  }
  std::string arch(info.machine);
  if (arch == "i386" || arch == "i486" || arch == "i586" || arch == "i686") {
    arch = "x86";
  } else if (arch == "amd64") {
    arch = "x86_64";
  }
  return arch;
}

// static
size_t SysInfo::VMAllocationGranularity() {
  return getpagesize();
}

}  // namespace base
