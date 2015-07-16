// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_BASE_PATHS_H_
#define BASE_BASE_PATHS_H_

// This file declares path keys for the base module.  These can be used with
// the PathService to access various special directories and files.

#include "build/build_config.h"

#if defined(OS_WIN)
#include "base/base_paths_win.h"
#elif defined(OS_MACOSX)
#include "base/base_paths_mac.h"
#elif defined(OS_ANDROID)
#include "base/base_paths_android.h"
#endif

#if defined(OS_POSIX)
#include "base/base_paths_posix.h"
#endif

namespace base {

enum BasePathKey {
  PATH_START = 0,

  DIR_CURRENT,       // Current directory.
  DIR_EXE,           // Directory containing FILE_EXE.
  DIR_MODULE,        // Directory containing FILE_MODULE.
  DIR_TEMP,          // Temporary directory.
  DIR_HOME,          // User's root home directory. On Windows this will look
                     // like "C:\Users\you" (or on XP
                     // "C:\Document and Settings\you") which isn't necessarily
                     // a great place to put files.
  FILE_EXE,          // Path and filename of the current executable.
  FILE_MODULE,       // Path and filename of the module containing the code for
                     // the PathService (which could differ from FILE_EXE if the
                     // PathService were compiled into a shared object, for
                     // example).
  DIR_SOURCE_ROOT,   // Returns the root of the source tree. This key is useful
                     // for tests that need to locate various resources. It
                     // should not be used outside of test code.
  DIR_USER_DESKTOP,  // The current user's Desktop.

  DIR_TEST_DATA,     // Used only for testing.

  PATH_END
};

}  // namespace base

#endif  // BASE_BASE_PATHS_H_
