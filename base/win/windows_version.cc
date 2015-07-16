// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/win/windows_version.h"

#include <windows.h>

#include "base/logging.h"
#include "base/strings/utf_string_conversions.h"
#include "base/win/registry.h"

namespace {
typedef BOOL (WINAPI *GetProductInfoPtr)(DWORD, DWORD, DWORD, DWORD, PDWORD);
}

namespace base {
namespace win {

// static
OSInfo* OSInfo::GetInstance() {
  // Note: we don't use the Singleton class because it depends on AtExitManager,
  // and it's convenient for other modules to use this classs without it. This
  // pattern is copied from gurl.cc.
  static OSInfo* info;
  if (!info) {
    OSInfo* new_info = new OSInfo();
    if (InterlockedCompareExchangePointer(
        reinterpret_cast<PVOID*>(&info), new_info, NULL)) {
      delete new_info;
    }
  }
  return info;
}

OSInfo::OSInfo()
    : version_(VERSION_PRE_XP),
      architecture_(OTHER_ARCHITECTURE),
      wow64_status_(GetWOW64StatusForProcess(GetCurrentProcess())) {
  OSVERSIONINFOEX version_info = { sizeof version_info };
  ::GetVersionEx(reinterpret_cast<OSVERSIONINFO*>(&version_info));
  version_number_.major = version_info.dwMajorVersion;
  version_number_.minor = version_info.dwMinorVersion;
  version_number_.build = version_info.dwBuildNumber;
  if ((version_number_.major == 5) && (version_number_.minor > 0)) {
    // Treat XP Pro x64, Home Server, and Server 2003 R2 as Server 2003.
    version_ = (version_number_.minor == 1) ? VERSION_XP : VERSION_SERVER_2003;
  } else if (version_number_.major == 6) {
    switch (version_number_.minor) {
      case 0:
        // Treat Windows Server 2008 the same as Windows Vista.
        version_ = VERSION_VISTA;
        break;
      case 1:
        // Treat Windows Server 2008 R2 the same as Windows 7.
        version_ = VERSION_WIN7;
        break;
      case 2:
        // Treat Windows Server 2012 the same as Windows 8.
        version_ = VERSION_WIN8;
        break;
      default:
        DCHECK_EQ(version_number_.minor, 3);
        version_ = VERSION_WIN8_1;
        break;
    }
  } else if (version_number_.major == 10) {
    version_ = VERSION_WIN10;
  } else if (version_number_.major > 6) {
    NOTREACHED();
    version_ = VERSION_WIN_LAST;
  }
  service_pack_.major = version_info.wServicePackMajor;
  service_pack_.minor = version_info.wServicePackMinor;

  SYSTEM_INFO system_info = { 0 };
  ::GetNativeSystemInfo(&system_info);
  switch (system_info.wProcessorArchitecture) {
    case PROCESSOR_ARCHITECTURE_INTEL: architecture_ = X86_ARCHITECTURE; break;
    case PROCESSOR_ARCHITECTURE_AMD64: architecture_ = X64_ARCHITECTURE; break;
    case PROCESSOR_ARCHITECTURE_IA64:  architecture_ = IA64_ARCHITECTURE; break;
  }
  processors_ = system_info.dwNumberOfProcessors;
  allocation_granularity_ = system_info.dwAllocationGranularity;

  GetProductInfoPtr get_product_info;
  DWORD os_type;

  if (version_info.dwMajorVersion == 6 || version_info.dwMajorVersion == 10) {
    // Only present on Vista+.
    get_product_info = reinterpret_cast<GetProductInfoPtr>(
        ::GetProcAddress(::GetModuleHandle(L"kernel32.dll"), "GetProductInfo"));

    get_product_info(version_info.dwMajorVersion, version_info.dwMinorVersion,
                     0, 0, &os_type);
    switch (os_type) {
      case PRODUCT_CLUSTER_SERVER:
      case PRODUCT_DATACENTER_SERVER:
      case PRODUCT_DATACENTER_SERVER_CORE:
      case PRODUCT_ENTERPRISE_SERVER:
      case PRODUCT_ENTERPRISE_SERVER_CORE:
      case PRODUCT_ENTERPRISE_SERVER_IA64:
      case PRODUCT_SMALLBUSINESS_SERVER:
      case PRODUCT_SMALLBUSINESS_SERVER_PREMIUM:
      case PRODUCT_STANDARD_SERVER:
      case PRODUCT_STANDARD_SERVER_CORE:
      case PRODUCT_WEB_SERVER:
        version_type_ = SUITE_SERVER;
        break;
      case PRODUCT_PROFESSIONAL:
      case PRODUCT_ULTIMATE:
      case PRODUCT_ENTERPRISE:
      case PRODUCT_BUSINESS:
        version_type_ = SUITE_PROFESSIONAL;
        break;
      case PRODUCT_HOME_BASIC:
      case PRODUCT_HOME_PREMIUM:
      case PRODUCT_STARTER:
      default:
        version_type_ = SUITE_HOME;
        break;
    }
  } else if (version_info.dwMajorVersion == 5 &&
             version_info.dwMinorVersion == 2) {
    if (version_info.wProductType == VER_NT_WORKSTATION &&
        system_info.wProcessorArchitecture == PROCESSOR_ARCHITECTURE_AMD64) {
      version_type_ = SUITE_PROFESSIONAL;
    } else if (version_info.wSuiteMask & VER_SUITE_WH_SERVER ) {
      version_type_ = SUITE_HOME;
    } else {
      version_type_ = SUITE_SERVER;
    }
  } else if (version_info.dwMajorVersion == 5 &&
             version_info.dwMinorVersion == 1) {
    if(version_info.wSuiteMask & VER_SUITE_PERSONAL)
      version_type_ = SUITE_HOME;
    else
      version_type_ = SUITE_PROFESSIONAL;
  } else {
    // Windows is pre XP so we don't care but pick a safe default.
    version_type_ = SUITE_HOME;
  }
}

OSInfo::~OSInfo() {
}

std::string OSInfo::processor_model_name() {
  if (processor_model_name_.empty()) {
    const wchar_t kProcessorNameString[] =
        L"HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\0";
    base::win::RegKey key(HKEY_LOCAL_MACHINE, kProcessorNameString, KEY_READ);
    string16 value;
    key.ReadValue(L"ProcessorNameString", &value);
    processor_model_name_ = UTF16ToUTF8(value);
  }
  return processor_model_name_;
}

// static
OSInfo::WOW64Status OSInfo::GetWOW64StatusForProcess(HANDLE process_handle) {
  typedef BOOL (WINAPI* IsWow64ProcessFunc)(HANDLE, PBOOL);
  IsWow64ProcessFunc is_wow64_process = reinterpret_cast<IsWow64ProcessFunc>(
      GetProcAddress(GetModuleHandle(L"kernel32.dll"), "IsWow64Process"));
  if (!is_wow64_process)
    return WOW64_DISABLED;
  BOOL is_wow64 = FALSE;
  if (!(*is_wow64_process)(process_handle, &is_wow64))
    return WOW64_UNKNOWN;
  return is_wow64 ? WOW64_ENABLED : WOW64_DISABLED;
}

Version GetVersion() {
  return OSInfo::GetInstance()->version();
}

}  // namespace win
}  // namespace base
