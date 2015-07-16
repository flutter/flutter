// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <windows.h>

// Display the command line. This program is designed to be called from
// another process to display assertions. Since the other process has
// complete control of our command line, we assume that it did *not*
// add the program name as the first parameter. This allows us to just
// show the command line directly as the message.
int APIENTRY WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance,
                     LPSTR lpCmdLine, int nCmdShow) {
  LPWSTR cmdline = GetCommandLineW();
  MessageBox(NULL, cmdline, L"Kr\x00d8m", MB_TOPMOST);
  return 0;
}
