// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_WIN_METRO_H_
#define BASE_WIN_METRO_H_

#include <windows.h>

#include "base/base_export.h"
#include "base/callback.h"
#include "base/files/file_path.h"
#include "base/strings/string16.h"

namespace base {
namespace win {

// Identifies the type of the metro launch.
enum MetroLaunchType {
  METRO_LAUNCH,
  METRO_SEARCH,
  METRO_SHARE,
  METRO_FILE,
  METRO_PROTOCOL,
  METRO_LAUNCH_ERROR,
  METRO_LASTLAUNCHTYPE,
};

// In metro mode, this enum identifies the last execution state, i.e. whether
// we crashed, terminated, etc.
enum MetroPreviousExecutionState {
  NOTRUNNING,
  RUNNING,
  SUSPENDED,
  TERMINATED,
  CLOSEDBYUSER,
  LASTEXECUTIONSTATE,
};

// Enum values for UMA histogram reporting of site-specific tile pinning.
// TODO(tapted): Move this to win8/util when ready (http://crbug.com/160288).
enum MetroSecondaryTilePinUmaResult {
  METRO_PIN_STATE_NONE,
  METRO_PIN_INITIATED,
  METRO_PIN_LOGO_READY,
  METRO_PIN_REQUEST_SHOW_ERROR,
  METRO_PIN_RESULT_CANCEL,
  METRO_PIN_RESULT_OK,
  METRO_PIN_RESULT_OTHER,
  METRO_PIN_RESULT_ERROR,
  METRO_UNPIN_INITIATED,
  METRO_UNPIN_REQUEST_SHOW_ERROR,
  METRO_UNPIN_RESULT_CANCEL,
  METRO_UNPIN_RESULT_OK,
  METRO_UNPIN_RESULT_OTHER,
  METRO_UNPIN_RESULT_ERROR,
  METRO_PIN_STATE_LIMIT
};

// Contains information about the currently displayed tab in metro mode.
struct CurrentTabInfo {
  wchar_t* title;
  wchar_t* url;
};

// Returns the handle to the metro dll loaded in the process. A NULL return
// indicates that the metro dll was not loaded in the process.
BASE_EXPORT HMODULE GetMetroModule();

// Returns true if this process is running as an immersive program
// in Windows Metro mode.
BASE_EXPORT bool IsMetroProcess();

// Returns true if the process identified by the handle passed in is an
// immersive (Metro) process.
BASE_EXPORT bool IsProcessImmersive(HANDLE process);

// Allocates and returns the destination string via the LocalAlloc API after
// copying the src to it.
BASE_EXPORT wchar_t* LocalAllocAndCopyString(const string16& src);

// Returns the type of launch and the activation params. For example if the
// the launch is for METRO_PROTOCOL then the params is a url.
BASE_EXPORT MetroLaunchType GetMetroLaunchParams(string16* params);

// Handler function for the buttons on a metro dialog box
typedef void (*MetroDialogButtonPressedHandler)();

// Handler function invoked when a metro style notification is clicked.
typedef void (*MetroNotificationClickedHandler)(const wchar_t* context);

// Function to display metro style notifications.
typedef void (*MetroNotification)(const char* origin_url,
                                  const char* icon_url,
                                  const wchar_t* title,
                                  const wchar_t* body,
                                  const wchar_t* display_source,
                                  const char* notification_id,
                                  MetroNotificationClickedHandler handler,
                                  const wchar_t* handler_context);

// Function to cancel displayed notification.
typedef bool (*MetroCancelNotification)(const char* notification_id);

// Callback for UMA invoked by Metro Pin and UnPin functions after user gesture.
typedef base::Callback<void(MetroSecondaryTilePinUmaResult)>
    MetroPinUmaResultCallback;

// Function to pin a site-specific tile (bookmark) to the start screen.
typedef void (*MetroPinToStartScreen)(
    const string16& tile_id,
    const string16& title,
    const string16& url,
    const FilePath& logo_path,
    const MetroPinUmaResultCallback& callback);

// Function to un-pin a site-specific tile (bookmark) from the start screen.
typedef void (*MetroUnPinFromStartScreen)(
    const string16& title_id,
    const MetroPinUmaResultCallback& callback);

}  // namespace win
}  // namespace base

#endif  // BASE_WIN_METRO_H_
