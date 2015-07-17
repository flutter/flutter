// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// =============================================================================
// PLEASE READ
//
// In general, you should not be adding stuff to this file.
//
// - If your thing is only used in one place, just put it in a reasonable
//   location in or near that one place. It's nice you want people to be able
//   to re-use your function, but realistically, if it hasn't been necessary
//   before after so many years of development, it's probably not going to be
//   used in other places in the future unless you know of them now.
//
// - If your thing is used by multiple callers and is UI-related, it should
//   probably be in app/win/ instead. Try to put it in the most specific file
//   possible (avoiding the *_util files when practical).
//
// =============================================================================

#ifndef BASE_WIN_WIN_UTIL_H_
#define BASE_WIN_WIN_UTIL_H_

#include <windows.h>

#include <string>

#include "base/base_export.h"
#include "base/strings/string16.h"

struct IPropertyStore;
struct _tagpropertykey;
typedef _tagpropertykey PROPERTYKEY;

// This is the same as NONCLIENTMETRICS except that the
// unused member |iPaddedBorderWidth| has been removed.
struct NONCLIENTMETRICS_XP {
    UINT    cbSize;
    int     iBorderWidth;
    int     iScrollWidth;
    int     iScrollHeight;
    int     iCaptionWidth;
    int     iCaptionHeight;
    LOGFONTW lfCaptionFont;
    int     iSmCaptionWidth;
    int     iSmCaptionHeight;
    LOGFONTW lfSmCaptionFont;
    int     iMenuWidth;
    int     iMenuHeight;
    LOGFONTW lfMenuFont;
    LOGFONTW lfStatusFont;
    LOGFONTW lfMessageFont;
};

namespace base {
namespace win {

BASE_EXPORT void GetNonClientMetrics(NONCLIENTMETRICS_XP* metrics);

// Returns the string representing the current user sid.
BASE_EXPORT bool GetUserSidString(std::wstring* user_sid);

// Returns true if the shift key is currently pressed.
BASE_EXPORT bool IsShiftPressed();

// Returns true if the ctrl key is currently pressed.
BASE_EXPORT bool IsCtrlPressed();

// Returns true if the alt key is currently pressed.
BASE_EXPORT bool IsAltPressed();

// Returns true if the altgr key is currently pressed.
// Windows does not have specific key code and modifier bit and Alt+Ctrl key is
// used as AltGr key in Windows.
BASE_EXPORT bool IsAltGrPressed();

// Returns false if user account control (UAC) has been disabled with the
// EnableLUA registry flag. Returns true if user account control is enabled.
// NOTE: The EnableLUA registry flag, which is ignored on Windows XP
// machines, might still exist and be set to 0 (UAC disabled), in which case
// this function will return false. You should therefore check this flag only
// if the OS is Vista or later.
BASE_EXPORT bool UserAccountControlIsEnabled();

// Sets the boolean value for a given key in given IPropertyStore.
BASE_EXPORT bool SetBooleanValueForPropertyStore(
    IPropertyStore* property_store,
    const PROPERTYKEY& property_key,
    bool property_bool_value);

// Sets the string value for a given key in given IPropertyStore.
BASE_EXPORT bool SetStringValueForPropertyStore(
    IPropertyStore* property_store,
    const PROPERTYKEY& property_key,
    const wchar_t* property_string_value);

// Sets the application id in given IPropertyStore. The function is intended
// for tagging application/chromium shortcut, browser window and jump list for
// Win7.
BASE_EXPORT bool SetAppIdForPropertyStore(IPropertyStore* property_store,
                                          const wchar_t* app_id);

// Adds the specified |command| using the specified |name| to the AutoRun key.
// |root_key| could be HKCU or HKLM or the root of any user hive.
BASE_EXPORT bool AddCommandToAutoRun(HKEY root_key, const string16& name,
                                     const string16& command);
// Removes the command specified by |name| from the AutoRun key. |root_key|
// could be HKCU or HKLM or the root of any user hive.
BASE_EXPORT bool RemoveCommandFromAutoRun(HKEY root_key, const string16& name);

// Reads the command specified by |name| from the AutoRun key. |root_key|
// could be HKCU or HKLM or the root of any user hive. Used for unit-tests.
BASE_EXPORT bool ReadCommandFromAutoRun(HKEY root_key,
                                        const string16& name,
                                        string16* command);

// Sets whether to crash the process during exit. This is inspected by DLLMain
// and used to intercept unexpected terminations of the process (via calls to
// exit(), abort(), _exit(), ExitProcess()) and convert them into crashes.
// Note that not all mechanisms for terminating the process are covered by
// this. In particular, TerminateProcess() is not caught.
BASE_EXPORT void SetShouldCrashOnProcessDetach(bool crash);
BASE_EXPORT bool ShouldCrashOnProcessDetach();

// Adjusts the abort behavior so that crash reports can be generated when the
// process is aborted.
BASE_EXPORT void SetAbortBehaviorForCrashReporting();

// A tablet is a device that is touch enabled and also is being used
// "like a tablet".  This is used primarily for metrics in order to gain some
// insight into how users use Chrome.
BASE_EXPORT bool IsTabletDevice();

// A slate is a touch device that may have a keyboard attached. This function
// returns true if a keyboard is attached and optionally will set the reason
// parameter to the detection method that was used to detect the keyboard.
BASE_EXPORT bool IsKeyboardPresentOnSlate(std::string* reason);

// Get the size of a struct up to and including the specified member.
// This is necessary to set compatible struct sizes for different versions
// of certain Windows APIs (e.g. SystemParametersInfo).
#define SIZEOF_STRUCT_WITH_SPECIFIED_LAST_MEMBER(struct_name, member) \
    offsetof(struct_name, member) + \
    (sizeof static_cast<struct_name*>(NULL)->member)

// Displays the on screen keyboard on Windows 8 and above. Returns true on
// success.
BASE_EXPORT bool DisplayVirtualKeyboard();

// Dismisses the on screen keyboard if it is being displayed on Windows 8 and.
// above. Returns true on success.
BASE_EXPORT bool DismissVirtualKeyboard();

// Returns true if the machine is enrolled to a domain.
BASE_EXPORT bool IsEnrolledToDomain();

// Used by tests to mock any wanted state. Call with |state| set to true to
// simulate being in a domain and false otherwise.
BASE_EXPORT void SetDomainStateForTesting(bool state);

// Returns true if the current operating system has support for SHA-256
// certificates. As its name indicates, this function provides a best-effort
// answer, which is solely based on comparing version numbers. The function
// may be re-implemented in the future to return a reliable value, based on
// run-time detection of this capability.
BASE_EXPORT bool MaybeHasSHA256Support();

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_WIN_UTIL_H_
