// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/sys_info.h"

#include <windows.h>

#include "base/files/file_path.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/stringprintf.h"
#include "base/threading/thread_restrictions.h"
#include "base/win/windows_version.h"

namespace {

int64 AmountOfMemory(DWORDLONG MEMORYSTATUSEX::* memory_field) {
  MEMORYSTATUSEX memory_info;
  memory_info.dwLength = sizeof(memory_info);
  if (!GlobalMemoryStatusEx(&memory_info)) {
    NOTREACHED();
    return 0;
  }

  int64 rv = static_cast<int64>(memory_info.*memory_field);
  return rv < 0 ? kint64max : rv;
}

}  // namespace

namespace base {

// static
int SysInfo::NumberOfProcessors() {
  return win::OSInfo::GetInstance()->processors();
}

// static
int64 SysInfo::AmountOfPhysicalMemory() {
  return AmountOfMemory(&MEMORYSTATUSEX::ullTotalPhys);
}

// static
int64 SysInfo::AmountOfAvailablePhysicalMemory() {
  return AmountOfMemory(&MEMORYSTATUSEX::ullAvailPhys);
}

// static
int64 SysInfo::AmountOfVirtualMemory() {
  return 0;
}

// static
int64 SysInfo::AmountOfFreeDiskSpace(const FilePath& path) {
  ThreadRestrictions::AssertIOAllowed();

  ULARGE_INTEGER available, total, free;
  if (!GetDiskFreeSpaceExW(path.value().c_str(), &available, &total, &free))
    return -1;

  int64 rv = static_cast<int64>(available.QuadPart);
  return rv < 0 ? kint64max : rv;
}

std::string SysInfo::OperatingSystemName() {
  return "Windows NT";
}

// static
std::string SysInfo::OperatingSystemVersion() {
  win::OSInfo* os_info = win::OSInfo::GetInstance();
  win::OSInfo::VersionNumber version_number = os_info->version_number();
  std::string version(StringPrintf("%d.%d", version_number.major,
                                   version_number.minor));
  win::OSInfo::ServicePack service_pack = os_info->service_pack();
  if (service_pack.major != 0) {
    version += StringPrintf(" SP%d", service_pack.major);
    if (service_pack.minor != 0)
      version += StringPrintf(".%d", service_pack.minor);
  }
  return version;
}

// TODO: Implement OperatingSystemVersionComplete, which would include
// patchlevel/service pack number.
// See chrome/browser/feedback/feedback_util.h, FeedbackUtil::SetOSVersion.

// static
std::string SysInfo::OperatingSystemArchitecture() {
  win::OSInfo::WindowsArchitecture arch =
      win::OSInfo::GetInstance()->architecture();
  switch (arch) {
    case win::OSInfo::X86_ARCHITECTURE:
      return "x86";
    case win::OSInfo::X64_ARCHITECTURE:
      return "x86_64";
    case win::OSInfo::IA64_ARCHITECTURE:
      return "ia64";
    default:
      return "";
  }
}

// static
std::string SysInfo::CPUModelName() {
  return win::OSInfo::GetInstance()->processor_model_name();
}

// static
size_t SysInfo::VMAllocationGranularity() {
  return win::OSInfo::GetInstance()->allocation_granularity();
}

// static
void SysInfo::OperatingSystemVersionNumbers(int32* major_version,
                                            int32* minor_version,
                                            int32* bugfix_version) {
  win::OSInfo* os_info = win::OSInfo::GetInstance();
  *major_version = os_info->version_number().major;
  *minor_version = os_info->version_number().minor;
  *bugfix_version = 0;
}

}  // namespace base
