// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windows.h>

#include <cfgmgr32.h>
#include <shellapi.h>

extern "C" {

__declspec(dllexport) void ExportFunc1() {
  // Call into user32.dll.
  HWND dummy = GetDesktopWindow();
  SetWindowTextA(dummy, "dummy");
}

__declspec(dllexport) void ExportFunc2() {
  // Call into cfgmgr32.dll.
  CM_MapCrToWin32Err(CR_SUCCESS, ERROR_SUCCESS);

  // Call into shell32.dll.
  SHFILEOPSTRUCT file_operation = {0};
  SHFileOperation(&file_operation);

  // Call into kernel32.dll.
  HANDLE h = CreateEvent(NULL, FALSE, FALSE, NULL);
  CloseHandle(h);
}

}  // extern "C"
