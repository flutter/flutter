// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_MAC_MAC_UTIL_H_
#define BASE_MAC_MAC_UTIL_H_

#include <AvailabilityMacros.h>
#include <Carbon/Carbon.h>
#include <string>

#include "base/base_export.h"
#include "base/logging.h"

#if defined(__OBJC__)
#import <Foundation/Foundation.h>
#else  // __OBJC__
class NSImage;
#endif  // __OBJC__

namespace base {

class FilePath;

namespace mac {

// Full screen modes, in increasing order of priority.  More permissive modes
// take predecence.
enum FullScreenMode {
  kFullScreenModeHideAll = 0,
  kFullScreenModeHideDock = 1,
  kFullScreenModeAutoHideAll = 2,
  kNumFullScreenModes = 3,

  // kFullScreenModeNormal is not a valid FullScreenMode, but it is useful to
  // other classes, so we include it here.
  kFullScreenModeNormal = 10,
};

BASE_EXPORT std::string PathFromFSRef(const FSRef& ref);
BASE_EXPORT bool FSRefFromPath(const std::string& path, FSRef* ref);

// Returns an sRGB color space.  The return value is a static value; do not
// release it!
BASE_EXPORT CGColorSpaceRef GetSRGBColorSpace();

// Returns the generic RGB color space. The return value is a static value; do
// not release it!
BASE_EXPORT CGColorSpaceRef GetGenericRGBColorSpace();

// Returns the color space being used by the main display.  The return value
// is a static value; do not release it!
BASE_EXPORT CGColorSpaceRef GetSystemColorSpace();

// Add a full screen request for the given |mode|.  Must be paired with a
// ReleaseFullScreen() call for the same |mode|.  This does not by itself create
// a fullscreen window; rather, it manages per-application state related to
// hiding the dock and menubar.  Must be called on the main thread.
BASE_EXPORT void RequestFullScreen(FullScreenMode mode);

// Release a request for full screen mode.  Must be matched with a
// RequestFullScreen() call for the same |mode|.  As with RequestFullScreen(),
// this does not affect windows directly, but rather manages per-application
// state.  For example, if there are no other outstanding
// |kFullScreenModeAutoHideAll| requests, this will reshow the menu bar.  Must
// be called on main thread.
BASE_EXPORT void ReleaseFullScreen(FullScreenMode mode);

// Convenience method to switch the current fullscreen mode.  This has the same
// net effect as a ReleaseFullScreen(from_mode) call followed immediately by a
// RequestFullScreen(to_mode).  Must be called on the main thread.
BASE_EXPORT void SwitchFullScreenModes(FullScreenMode from_mode,
                                       FullScreenMode to_mode);

// Set the visibility of the cursor.
BASE_EXPORT void SetCursorVisibility(bool visible);

// Activates the process with the given PID.
BASE_EXPORT void ActivateProcess(pid_t pid);

// Returns true if this process is in the foreground, meaning that it's the
// frontmost process, the one whose menu bar is shown at the top of the main
// display.
BASE_EXPORT bool AmIForeground();

// Excludes the file given by |file_path| from being backed up by Time Machine.
BASE_EXPORT bool SetFileBackupExclusion(const FilePath& file_path);

// Checks if the current application is set as a Login Item, so it will launch
// on Login. If a non-NULL pointer to is_hidden is passed, the Login Item also
// is queried for the 'hide on launch' flag.
BASE_EXPORT bool CheckLoginItemStatus(bool* is_hidden);

// Adds current application to the set of Login Items with specified "hide"
// flag. This has the same effect as adding/removing the application in
// SystemPreferences->Accounts->LoginItems or marking Application in the Dock
// as "Options->Open on Login".
// Does nothing if the application is already set up as Login Item with
// specified hide flag.
BASE_EXPORT void AddToLoginItems(bool hide_on_startup);

// Removes the current application from the list Of Login Items.
BASE_EXPORT void RemoveFromLoginItems();

// Returns true if the current process was automatically launched as a
// 'Login Item' or via Lion's Resume. Used to suppress opening windows.
BASE_EXPORT bool WasLaunchedAsLoginOrResumeItem();

// Returns true if the current process was automatically launched as a
// 'Login Item' or via Resume, and the 'Reopen windows when logging back in'
// checkbox was selected by the user.  This indicates that the previous
// session should be restored.
BASE_EXPORT bool WasLaunchedAsLoginItemRestoreState();

// Returns true if the current process was automatically launched as a
// 'Login Item' with 'hide on startup' flag. Used to suppress opening windows.
BASE_EXPORT bool WasLaunchedAsHiddenLoginItem();

// Remove the quarantine xattr from the given file. Returns false if there was
// an error, or true otherwise.
BASE_EXPORT bool RemoveQuarantineAttribute(const FilePath& file_path);

// Run-time OS version checks. Use these instead of
// base::SysInfo::OperatingSystemVersionNumbers. Prefer the "OrEarlier" and
// "OrLater" variants to those that check for a specific version, unless you
// know for sure that you need to check for a specific version.

// Snow Leopard is Mac OS X 10.6, Darwin 10.
BASE_EXPORT bool IsOSSnowLeopard();

// Lion is Mac OS X 10.7, Darwin 11.
BASE_EXPORT bool IsOSLion();
BASE_EXPORT bool IsOSLionOrEarlier();
BASE_EXPORT bool IsOSLionOrLater();

// Mountain Lion is Mac OS X 10.8, Darwin 12.
BASE_EXPORT bool IsOSMountainLion();
BASE_EXPORT bool IsOSMountainLionOrEarlier();
BASE_EXPORT bool IsOSMountainLionOrLater();

// Mavericks is Mac OS X 10.9, Darwin 13.
BASE_EXPORT bool IsOSMavericks();
BASE_EXPORT bool IsOSMavericksOrEarlier();
BASE_EXPORT bool IsOSMavericksOrLater();

// Yosemite is Mac OS X 10.10, Darwin 14.
BASE_EXPORT bool IsOSYosemite();
BASE_EXPORT bool IsOSYosemiteOrLater();

// This should be infrequently used. It only makes sense to use this to avoid
// codepaths that are very likely to break on future (unreleased, untested,
// unborn) OS releases, or to log when the OS is newer than any known version.
BASE_EXPORT bool IsOSLaterThanYosemite_DontCallThis();

// Inline functions that are redundant due to version ranges being mutually-
// exclusive.
inline bool IsOSLionOrEarlier() { return !IsOSMountainLionOrLater(); }
inline bool IsOSMountainLionOrEarlier() { return !IsOSMavericksOrLater(); }
inline bool IsOSMavericksOrEarlier() { return !IsOSYosemiteOrLater(); }

// When the deployment target is set, the code produced cannot run on earlier
// OS releases. That enables some of the IsOS* family to be implemented as
// constant-value inline functions. The MAC_OS_X_VERSION_MIN_REQUIRED macro
// contains the value of the deployment target.

#if defined(MAC_OS_X_VERSION_10_7) && \
    MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7
#define BASE_MAC_MAC_UTIL_H_INLINED_GE_10_7
inline bool IsOSSnowLeopard() { return false; }
inline bool IsOSLionOrLater() { return true; }
#endif

#if defined(MAC_OS_X_VERSION_10_7) && \
    MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_7
#define BASE_MAC_MAC_UTIL_H_INLINED_GT_10_7
inline bool IsOSLion() { return false; }
#endif

#if defined(MAC_OS_X_VERSION_10_8) && \
    MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_8
#define BASE_MAC_MAC_UTIL_H_INLINED_GE_10_8
inline bool IsOSMountainLionOrLater() { return true; }
#endif

#if defined(MAC_OS_X_VERSION_10_8) && \
    MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_8
#define BASE_MAC_MAC_UTIL_H_INLINED_GT_10_8
inline bool IsOSMountainLion() { return false; }
#endif

#if defined(MAC_OS_X_VERSION_10_9) && \
    MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_9
#define BASE_MAC_MAC_UTIL_H_INLINED_GE_10_9
inline bool IsOSMavericksOrLater() { return true; }
#endif

#if defined(MAC_OS_X_VERSION_10_9) && \
    MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_9
#define BASE_MAC_MAC_UTIL_H_INLINED_GT_10_9
inline bool IsOSMavericks() { return false; }
#endif

#if defined(MAC_OS_X_VERSION_10_10) && \
    MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_10
#define BASE_MAC_MAC_UTIL_H_INLINED_GE_10_10
inline bool IsOSYosemiteOrLater() { return true; }
#endif

#if defined(MAC_OS_X_VERSION_10_10) && \
    MAC_OS_X_VERSION_MIN_REQUIRED > MAC_OS_X_VERSION_10_10
#define BASE_MAC_MAC_UTIL_H_INLINED_GT_10_10
inline bool IsOSYosemite() { return false; }
inline bool IsOSLaterThanYosemite_DontCallThis() { return true; }
#endif

// Retrieve the system's model identifier string from the IOKit registry:
// for example, "MacPro4,1", "MacBookPro6,1". Returns empty string upon
// failure.
BASE_EXPORT std::string GetModelIdentifier();

// Parse a model identifier string; for example, into ("MacBookPro", 6, 1).
// If any error occurs, none of the input pointers are touched.
BASE_EXPORT bool ParseModelIdentifier(const std::string& ident,
                                      std::string* type,
                                      int32* major,
                                      int32* minor);

}  // namespace mac
}  // namespace base

#endif  // BASE_MAC_MAC_UTIL_H_
