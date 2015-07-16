// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/icu_util.h"

#if defined(OS_WIN)
#include <windows.h>
#endif

#include <string>

#include "base/debug/alias.h"
#include "base/files/file_path.h"
#include "base/files/memory_mapped_file.h"
#include "base/logging.h"
#include "base/path_service.h"
#include "base/strings/string_util.h"
#include "base/strings/sys_string_conversions.h"
#include "third_party/icu/source/common/unicode/putil.h"
#include "third_party/icu/source/common/unicode/udata.h"
#if defined(OS_LINUX) && !defined(OS_CHROMEOS)
#include "third_party/icu/source/i18n/unicode/timezone.h"
#endif

#if defined(OS_MACOSX)
#include "base/mac/foundation_util.h"
#endif

#define ICU_UTIL_DATA_FILE   0
#define ICU_UTIL_DATA_SHARED 1
#define ICU_UTIL_DATA_STATIC 2

namespace base {
namespace i18n {

// Use an unversioned file name to simplify a icu version update down the road.
// No need to change the filename in multiple places (gyp files, windows
// build pkg configurations, etc). 'l' stands for Little Endian.
// This variable is exported through the header file.
const char kIcuDataFileName[] = "icudtl.dat";
#if ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_SHARED
#define ICU_UTIL_DATA_SYMBOL "icudt" U_ICU_VERSION_SHORT "_dat"
#if defined(OS_WIN)
#define ICU_UTIL_DATA_SHARED_MODULE_NAME "icudt.dll"
#endif
#endif

namespace {

#if !defined(NDEBUG)
// Assert that we are not called more than once.  Even though calling this
// function isn't harmful (ICU can handle it), being called twice probably
// indicates a programming error.
#if !defined(OS_NACL)
bool g_called_once = false;
#endif
bool g_check_called_once = true;
#endif
}

#if !defined(OS_NACL)
bool InitializeICUWithFileDescriptor(
    PlatformFile data_fd,
    MemoryMappedFile::Region data_region) {
#if !defined(NDEBUG)
  DCHECK(!g_check_called_once || !g_called_once);
  g_called_once = true;
#endif

#if (ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_STATIC)
  // The ICU data is statically linked.
  return true;
#elif (ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_FILE)
  CR_DEFINE_STATIC_LOCAL(MemoryMappedFile, mapped_file, ());
  if (!mapped_file.IsValid()) {
    if (!mapped_file.Initialize(File(data_fd), data_region)) {
      LOG(ERROR) << "Couldn't mmap icu data file";
      return false;
    }
  }
  UErrorCode err = U_ZERO_ERROR;
  udata_setCommonData(const_cast<uint8*>(mapped_file.data()), &err);
  return err == U_ZERO_ERROR;
#endif // ICU_UTIL_DATA_FILE
}


bool InitializeICU() {
#if !defined(NDEBUG)
  DCHECK(!g_check_called_once || !g_called_once);
  g_called_once = true;
#endif

  bool result;
#if (ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_SHARED)
  // We expect to find the ICU data module alongside the current module.
  FilePath data_path;
  PathService::Get(DIR_MODULE, &data_path);
  data_path = data_path.AppendASCII(ICU_UTIL_DATA_SHARED_MODULE_NAME);

  HMODULE module = LoadLibrary(data_path.value().c_str());
  if (!module) {
    LOG(ERROR) << "Failed to load " << ICU_UTIL_DATA_SHARED_MODULE_NAME;
    return false;
  }

  FARPROC addr = GetProcAddress(module, ICU_UTIL_DATA_SYMBOL);
  if (!addr) {
    LOG(ERROR) << ICU_UTIL_DATA_SYMBOL << ": not found in "
               << ICU_UTIL_DATA_SHARED_MODULE_NAME;
    return false;
  }

  UErrorCode err = U_ZERO_ERROR;
  udata_setCommonData(reinterpret_cast<void*>(addr), &err);
  result = (err == U_ZERO_ERROR);
#elif (ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_STATIC)
  // The ICU data is statically linked.
  result = true;
#elif (ICU_UTIL_DATA_IMPL == ICU_UTIL_DATA_FILE)
  // If the ICU data directory is set, ICU won't actually load the data until
  // it is needed.  This can fail if the process is sandboxed at that time.
  // Instead, we map the file in and hand off the data so the sandbox won't
  // cause any problems.

  // Chrome doesn't normally shut down ICU, so the mapped data shouldn't ever
  // be released.
  CR_DEFINE_STATIC_LOCAL(MemoryMappedFile, mapped_file, ());
  if (!mapped_file.IsValid()) {
#if !defined(OS_MACOSX)
    FilePath data_path;
#if defined(OS_WIN)
    // The data file will be in the same directory as the current module.
    bool path_ok = PathService::Get(DIR_MODULE, &data_path);
    wchar_t tmp_buffer[_MAX_PATH] = {0};
    wcscpy_s(tmp_buffer, data_path.value().c_str());
    debug::Alias(tmp_buffer);
    CHECK(path_ok);  // TODO(scottmg): http://crbug.com/445616
#elif defined(OS_ANDROID)
    bool path_ok = PathService::Get(DIR_ANDROID_APP_DATA, &data_path);
#else
    // For now, expect the data file to be alongside the executable.
    // This is sufficient while we work on unit tests, but will eventually
    // likely live in a data directory.
    bool path_ok = PathService::Get(DIR_EXE, &data_path);
#endif
    DCHECK(path_ok);
    data_path = data_path.AppendASCII(kIcuDataFileName);

#if defined(OS_WIN)
    // TODO(scottmg): http://crbug.com/445616
    wchar_t tmp_buffer2[_MAX_PATH] = {0};
    wcscpy_s(tmp_buffer2, data_path.value().c_str());
    debug::Alias(tmp_buffer2);
#endif

#else
    // Assume it is in the framework bundle's Resources directory.
    ScopedCFTypeRef<CFStringRef> data_file_name(
        SysUTF8ToCFStringRef(kIcuDataFileName));
    FilePath data_path =
      mac::PathForFrameworkBundleResource(data_file_name);
    if (data_path.empty()) {
      LOG(ERROR) << kIcuDataFileName << " not found in bundle";
      return false;
    }
#endif  // OS check
    if (!mapped_file.Initialize(data_path)) {
#if defined(OS_WIN)
      CHECK(false);  // TODO(scottmg): http://crbug.com/445616
#endif
      LOG(ERROR) << "Couldn't mmap " << data_path.AsUTF8Unsafe();
      return false;
    }
  }
  UErrorCode err = U_ZERO_ERROR;
  udata_setCommonData(const_cast<uint8*>(mapped_file.data()), &err);
  result = (err == U_ZERO_ERROR);
#if defined(OS_WIN)
  CHECK(result);  // TODO(scottmg): http://crbug.com/445616
#endif
#endif

// To respond to the timezone change properly, the default timezone
// cache in ICU has to be populated on starting up.
// TODO(jungshik): Some callers do not care about tz at all. If necessary,
// add a boolean argument to this function to init'd the default tz only
// when requested.
#if defined(OS_LINUX) && !defined(OS_CHROMEOS)
  if (result)
    scoped_ptr<icu::TimeZone> zone(icu::TimeZone::createDefault());
#endif
  return result;
}
#endif

void AllowMultipleInitializeCallsForTesting() {
#if !defined(NDEBUG)
  g_check_called_once = false;
#endif
}

}  // namespace i18n
}  // namespace base
