// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef URL_URL_PARSE_INTERNAL_H_
#define URL_URL_PARSE_INTERNAL_H_

// Contains common inline helper functions used by the URL parsing routines.

#include "url/url_parse.h"

namespace url {

// We treat slashes and backslashes the same for IE compatability.
inline bool IsURLSlash(base::char16 ch) {
  return ch == '/' || ch == '\\';
}

// Returns true if we should trim this character from the URL because it is a
// space or a control character.
inline bool ShouldTrimFromURL(base::char16 ch) {
  return ch <= ' ';
}

// Given an already-initialized begin index and length, this shrinks the range
// to eliminate "should-be-trimmed" characters. Note that the length does *not*
// indicate the length of untrimmed data from |*begin|, but rather the position
// in the input string (so the string starts at character |*begin| in the spec,
// and goes until |*len|).
template<typename CHAR>
inline void TrimURL(const CHAR* spec, int* begin, int* len,
                    bool trim_path_end = true) {
  // Strip leading whitespace and control characters.
  while (*begin < *len && ShouldTrimFromURL(spec[*begin]))
    (*begin)++;

  if (trim_path_end) {
    // Strip trailing whitespace and control characters. We need the >i test
    // for when the input string is all blanks; we don't want to back past the
    // input.
    while (*len > *begin && ShouldTrimFromURL(spec[*len - 1]))
      (*len)--;
  }
}

// Counts the number of consecutive slashes starting at the given offset
// in the given string of the given length.
template<typename CHAR>
inline int CountConsecutiveSlashes(const CHAR *str,
                                   int begin_offset, int str_len) {
  int count = 0;
  while (begin_offset + count < str_len &&
         IsURLSlash(str[begin_offset + count]))
    ++count;
  return count;
}

// Internal functions in url_parse.cc that parse the path, that is, everything
// following the authority section. The input is the range of everything
// following the authority section, and the output is the identified ranges.
//
// This is designed for the file URL parser or other consumers who may do
// special stuff at the beginning, but want regular path parsing, it just
// maps to the internal parsing function for paths.
void ParsePathInternal(const char* spec,
                       const Component& path,
                       Component* filepath,
                       Component* query,
                       Component* ref);
void ParsePathInternal(const base::char16* spec,
                       const Component& path,
                       Component* filepath,
                       Component* query,
                       Component* ref);


// Given a spec and a pointer to the character after the colon following the
// scheme, this parses it and fills in the structure, Every item in the parsed
// structure is filled EXCEPT for the scheme, which is untouched.
void ParseAfterScheme(const char* spec,
                      int spec_len,
                      int after_scheme,
                      Parsed* parsed);
void ParseAfterScheme(const base::char16* spec,
                      int spec_len,
                      int after_scheme,
                      Parsed* parsed);

}  // namespace url

#endif  // URL_URL_PARSE_INTERNAL_H_
