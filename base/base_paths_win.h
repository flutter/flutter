// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_BASE_PATHS_WIN_H_
#define BASE_BASE_PATHS_WIN_H_

// This file declares windows-specific path keys for the base module.
// These can be used with the PathService to access various special
// directories and files.

namespace base {

enum {
  PATH_WIN_START = 100,

  DIR_WINDOWS,  // Windows directory, usually "c:\windows"
  DIR_SYSTEM,   // Usually c:\windows\system32"
  //                         32-bit     32-bit on 64-bit   64-bit on 64-bit
  // DIR_PROGRAM_FILES         1               2                  1
  // DIR_PROGRAM_FILESX86      1               2                  2
  // DIR_PROGRAM_FILES6432     1               1                  1
  // 1 - C:\Program Files   2 - C:\Program Files (x86)
  DIR_PROGRAM_FILES,      // See table above.
  DIR_PROGRAM_FILESX86,   // See table above.
  DIR_PROGRAM_FILES6432,  // See table above.

  DIR_IE_INTERNET_CACHE,  // Temporary Internet Files directory.
  DIR_COMMON_START_MENU,  // Usually "C:\Documents and Settings\All Users\
                          // Start Menu\Programs"
  DIR_START_MENU,         // Usually "C:\Documents and Settings\<user>\
                          // Start Menu\Programs"
  DIR_APP_DATA,           // Application Data directory under the user profile.
  DIR_LOCAL_APP_DATA,     // "Local Settings\Application Data" directory under
                          // the user profile.
  DIR_COMMON_APP_DATA,    // W2K, XP, W2K3: "C:\Documents and Settings\
                          // All Users\Application Data".
                          // Vista, W2K8 and above: "C:\ProgramData".
  DIR_APP_SHORTCUTS,      // Where tiles on the start screen are stored, only
                          // for Windows 8. Maps to "Local\AppData\Microsoft\
                          // Windows\Application Shortcuts\".
  DIR_COMMON_DESKTOP,     // Directory for the common desktop (visible
                          // on all user's Desktop).
  DIR_USER_QUICK_LAUNCH,  // Directory for the quick launch shortcuts.
  DIR_TASKBAR_PINS,       // Directory for the shortcuts pinned to taskbar via
                          // base::win::TaskbarPinShortcutLink().
  DIR_WINDOWS_FONTS,      // Usually C:\Windows\Fonts.

  PATH_WIN_END
};

}  // namespace base

#endif  // BASE_BASE_PATHS_WIN_H_
