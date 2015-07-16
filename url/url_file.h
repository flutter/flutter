// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_FILE_H_
#define URL_URL_FILE_H_

// Provides shared functions used by the internals of the parser and
// canonicalizer for file URLs. Do not use outside of these modules.

#include "url/url_parse_internal.h"

namespace url {

#ifdef WIN32

// We allow both "c:" and "c|" as drive identifiers.
inline bool IsWindowsDriveSeparator(base::char16 ch) {
  return ch == ':' || ch == '|';
}
inline bool IsWindowsDriveLetter(base::char16 ch) {
  return (ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z');
}

#endif  // WIN32

// Returns the index of the next slash in the input after the given index, or
// spec_len if the end of the input is reached.
template<typename CHAR>
inline int FindNextSlash(const CHAR* spec, int begin_index, int spec_len) {
  int idx = begin_index;
  while (idx < spec_len && !IsURLSlash(spec[idx]))
    idx++;
  return idx;
}

#ifdef WIN32

// Returns true if the start_offset in the given spec looks like it begins a
// drive spec, for example "c:". This function explicitly handles start_offset
// values that are equal to or larger than the spec_len to simplify callers.
//
// If this returns true, the spec is guaranteed to have a valid drive letter
// plus a colon starting at |start_offset|.
template<typename CHAR>
inline bool DoesBeginWindowsDriveSpec(const CHAR* spec, int start_offset,
                                      int spec_len) {
  int remaining_len = spec_len - start_offset;
  if (remaining_len < 2)
    return false;  // Not enough room.
  if (!IsWindowsDriveLetter(spec[start_offset]))
    return false;  // Doesn't start with a valid drive letter.
  if (!IsWindowsDriveSeparator(spec[start_offset + 1]))
    return false;  // Isn't followed with a drive separator.
  return true;
}

// Returns true if the start_offset in the given text looks like it begins a
// UNC path, for example "\\". This function explicitly handles start_offset
// values that are equal to or larger than the spec_len to simplify callers.
//
// When strict_slashes is set, this function will only accept backslashes as is
// standard for Windows. Otherwise, it will accept forward slashes as well
// which we use for a lot of URL handling.
template<typename CHAR>
inline bool DoesBeginUNCPath(const CHAR* text,
                             int start_offset,
                             int len,
                             bool strict_slashes) {
  int remaining_len = len - start_offset;
  if (remaining_len < 2)
    return false;

  if (strict_slashes)
    return text[start_offset] == '\\' && text[start_offset + 1] == '\\';
  return IsURLSlash(text[start_offset]) && IsURLSlash(text[start_offset + 1]);
}

#endif  // WIN32

}  // namespace url

#endif  // URL_URL_FILE_H_
