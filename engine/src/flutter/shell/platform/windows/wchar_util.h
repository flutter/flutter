// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_WCHAR_UTIL_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_WCHAR_UTIL_H_

#include <string>

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Convert a null terminated wchar_t buffer to a std::string using
///             Windows utilities.
///
///             The reliance on wchar_t buffers is problematic on C++20 since
///             their interop with standard library components has been
///             deprecated/removed.
///
/// @param[in]  wstr  The null terminated buffer.
///
/// @return     The converted string if conversion is possible. Empty string
///             otherwise.
///
std::string WCharBufferToString(const wchar_t* wstr);

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_WCHAR_UTIL_H_
