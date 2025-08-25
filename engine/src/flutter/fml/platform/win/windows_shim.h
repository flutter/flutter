// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FML_PLATFORM_WIN_WINDOWS_SHIM_H_
#define FLUTTER_FML_PLATFORM_WIN_WINDOWS_SHIM_H_

#include <windows.h>

// Windows includes a macro for `DrawText` which conflicts with our own APIs.
#undef DrawText

#endif  // FLUTTER_FML_PLATFORM_WIN_WINDOWS_SHIM_H_
