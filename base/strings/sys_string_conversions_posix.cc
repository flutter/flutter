// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/sys_string_conversions.h"

#include <wchar.h>

#include "base/strings/string_piece.h"
#include "base/strings/utf_string_conversions.h"

namespace base {

std::string SysWideToUTF8(const std::wstring& wide) {
  // In theory this should be using the system-provided conversion rather
  // than our ICU, but this will do for now.
  return WideToUTF8(wide);
}
std::wstring SysUTF8ToWide(const StringPiece& utf8) {
  // In theory this should be using the system-provided conversion rather
  // than our ICU, but this will do for now.
  std::wstring out;
  UTF8ToWide(utf8.data(), utf8.size(), &out);
  return out;
}

#if defined(SYSTEM_NATIVE_UTF8) || defined(OS_ANDROID)
// TODO(port): Consider reverting the OS_ANDROID when we have wcrtomb()
// support and a better understanding of what calls these routines.

std::string SysWideToNativeMB(const std::wstring& wide) {
  return WideToUTF8(wide);
}

std::wstring SysNativeMBToWide(const StringPiece& native_mb) {
  return SysUTF8ToWide(native_mb);
}

#else

std::string SysWideToNativeMB(const std::wstring& wide) {
  mbstate_t ps;

  // Calculate the number of multi-byte characters.  We walk through the string
  // without writing the output, counting the number of multi-byte characters.
  size_t num_out_chars = 0;
  memset(&ps, 0, sizeof(ps));
  for (size_t i = 0; i < wide.size(); ++i) {
    const wchar_t src = wide[i];
    // Use a temp buffer since calling wcrtomb with an output of NULL does not
    // calculate the output length.
    char buf[16];
    // Skip NULLs to avoid wcrtomb's special handling of them.
    size_t res = src ? wcrtomb(buf, src, &ps) : 0;
    switch (res) {
      // Handle any errors and return an empty string.
      case static_cast<size_t>(-1):
        return std::string();
        break;
      case 0:
        // We hit an embedded null byte, keep going.
        ++num_out_chars;
        break;
      default:
        num_out_chars += res;
        break;
    }
  }

  if (num_out_chars == 0)
    return std::string();

  std::string out;
  out.resize(num_out_chars);

  // We walk the input string again, with |i| tracking the index of the
  // wide input, and |j| tracking the multi-byte output.
  memset(&ps, 0, sizeof(ps));
  for (size_t i = 0, j = 0; i < wide.size(); ++i) {
    const wchar_t src = wide[i];
    // We don't want wcrtomb to do its funkiness for embedded NULLs.
    size_t res = src ? wcrtomb(&out[j], src, &ps) : 0;
    switch (res) {
      // Handle any errors and return an empty string.
      case static_cast<size_t>(-1):
        return std::string();
        break;
      case 0:
        // We hit an embedded null byte, keep going.
        ++j;  // Output is already zeroed.
        break;
      default:
        j += res;
        break;
    }
  }

  return out;
}

std::wstring SysNativeMBToWide(const StringPiece& native_mb) {
  mbstate_t ps;

  // Calculate the number of wide characters.  We walk through the string
  // without writing the output, counting the number of wide characters.
  size_t num_out_chars = 0;
  memset(&ps, 0, sizeof(ps));
  for (size_t i = 0; i < native_mb.size(); ) {
    const char* src = native_mb.data() + i;
    size_t res = mbrtowc(NULL, src, native_mb.size() - i, &ps);
    switch (res) {
      // Handle any errors and return an empty string.
      case static_cast<size_t>(-2):
      case static_cast<size_t>(-1):
        return std::wstring();
        break;
      case 0:
        // We hit an embedded null byte, keep going.
        i += 1;  // Fall through.
      default:
        i += res;
        ++num_out_chars;
        break;
    }
  }

  if (num_out_chars == 0)
    return std::wstring();

  std::wstring out;
  out.resize(num_out_chars);

  memset(&ps, 0, sizeof(ps));  // Clear the shift state.
  // We walk the input string again, with |i| tracking the index of the
  // multi-byte input, and |j| tracking the wide output.
  for (size_t i = 0, j = 0; i < native_mb.size(); ++j) {
    const char* src = native_mb.data() + i;
    wchar_t* dst = &out[j];
    size_t res = mbrtowc(dst, src, native_mb.size() - i, &ps);
    switch (res) {
      // Handle any errors and return an empty string.
      case static_cast<size_t>(-2):
      case static_cast<size_t>(-1):
        return std::wstring();
        break;
      case 0:
        i += 1;  // Skip null byte.
        break;
      default:
        i += res;
        break;
    }
  }

  return out;
}

#endif  // OS_CHROMEOS

}  // namespace base
