// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Defines base::PathProviderMac which replaces base::PathProviderPosix for Mac
// in base/path_service.cc.

#include <dlfcn.h>
#import <Foundation/Foundation.h>
#include <mach-o/dyld.h>

#include "base/base_paths.h"
#include "base/compiler_specific.h"
#include "base/files/file_path.h"
#include "base/files/file_util.h"
#include "base/logging.h"
#include "base/mac/foundation_util.h"
#include "base/path_service.h"
#include "base/strings/string_util.h"
#include "build/build_config.h"

namespace {

void GetNSExecutablePath(base::FilePath* path) {
  DCHECK(path);
  // Executable path can have relative references ("..") depending on
  // how the app was launched.
  uint32_t executable_length = 0;
  _NSGetExecutablePath(NULL, &executable_length);
  DCHECK_GT(executable_length, 1u);
  std::string executable_path;
  int rv = _NSGetExecutablePath(
      base::WriteInto(&executable_path, executable_length),
                      &executable_length);
  DCHECK_EQ(rv, 0);

  // _NSGetExecutablePath may return paths containing ./ or ../ which makes
  // FilePath::DirName() work incorrectly, convert it to absolute path so that
  // paths such as DIR_SOURCE_ROOT can work, since we expect absolute paths to
  // be returned here.
  *path = base::MakeAbsoluteFilePath(base::FilePath(executable_path));
}

// Returns true if the module for |address| is found. |path| will contain
// the path to the module. Note that |path| may not be absolute.
bool GetModulePathForAddress(base::FilePath* path,
                             const void* address) WARN_UNUSED_RESULT;

bool GetModulePathForAddress(base::FilePath* path, const void* address) {
  Dl_info info;
  if (dladdr(address, &info) == 0)
    return false;
  *path = base::FilePath(info.dli_fname);
  return true;
}

}  // namespace

namespace base {

bool PathProviderMac(int key, base::FilePath* result) {
  switch (key) {
    case base::FILE_EXE:
      GetNSExecutablePath(result);
      return true;
    case base::FILE_MODULE:
      return GetModulePathForAddress(result,
          reinterpret_cast<const void*>(&base::PathProviderMac));
    case base::DIR_APP_DATA: {
      bool success = base::mac::GetUserDirectory(NSApplicationSupportDirectory,
                                                 result);
#if defined(OS_IOS)
      // On IOS, this directory does not exist unless it is created explicitly.
      if (success && !base::PathExists(*result))
        success = base::CreateDirectory(*result);
#endif  // defined(OS_IOS)
      return success;
    }
    case base::DIR_SOURCE_ROOT:
      // Go through PathService to catch overrides.
      if (!PathService::Get(base::FILE_EXE, result))
        return false;

      // Start with the executable's directory.
      *result = result->DirName();

#if !defined(OS_IOS)
      if (base::mac::AmIBundled()) {
        // The bundled app executables (Chromium, TestShell, etc) live five
        // levels down, eg:
        // src/xcodebuild/{Debug|Release}/Chromium.app/Contents/MacOS/Chromium
        *result = result->DirName().DirName().DirName().DirName().DirName();
      } else {
        // Unit tests execute two levels deep from the source root, eg:
        // src/xcodebuild/{Debug|Release}/base_unittests
        *result = result->DirName().DirName();
      }
#endif
      return true;
    case base::DIR_USER_DESKTOP:
#if defined(OS_IOS)
      // iOS does not have desktop directories.
      NOTIMPLEMENTED();
      return false;
#else
      return base::mac::GetUserDirectory(NSDesktopDirectory, result);
#endif
    case base::DIR_CACHE:
      return base::mac::GetUserDirectory(NSCachesDirectory, result);
    default:
      return false;
  }
}

}  // namespace base
