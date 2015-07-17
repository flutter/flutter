// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_STRINGS_STRING_SPLIT_H_
#define BASE_STRINGS_STRING_SPLIT_H_

#include <string>
#include <utility>
#include <vector>

#include "base/base_export.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"

namespace base {

enum WhitespaceHandling {
  KEEP_WHITESPACE,
  TRIM_WHITESPACE,
};

enum SplitResult {
  // Strictly return all results.
  //
  // If the input is ",," and the separator is ',' this will return a
  // vector of three empty strings.
  SPLIT_WANT_ALL,

  // Only nonempty results will be added to the results. Multiple separators
  // will be coalesced. Separators at the beginning and end of the input will
  // be ignored. With TRIM_WHITESPACE, whitespace-only results will be dropped.
  //
  // If the input is ",," and the separator is ',', this will return an empty
  // vector.
  SPLIT_WANT_NONEMPTY,
};

// Split the given string on ANY of the given separators, returning copies of
// the result.
//
// To split on either commas or semicolons, keeping all whitespace:
//
//   std::vector<std::string> tokens = base::SplitString(
//       input, ",;", base::KEEP_WHITESPACE, base::SPLIT_WANT_ALL);
BASE_EXPORT std::vector<std::string> SplitString(
    StringPiece input,
    StringPiece separators,
    WhitespaceHandling whitespace,
    SplitResult result_type);
BASE_EXPORT std::vector<string16> SplitString(
    StringPiece16 input,
    StringPiece16 separators,
    WhitespaceHandling whitespace,
    SplitResult result_type);

// Like SplitString above except it returns a vector of StringPieces which
// reference the original buffer without copying. Although you have to be
// careful to keep the original string unmodified, this provides an efficient
// way to iterate through tokens in a string.
//
// To iterate through all whitespace-separated tokens in an input string:
//
//   for (const auto& cur :
//        base::SplitStringPiece(input, base::kWhitespaceASCII,
//                               base::KEEP_WHITESPACE,
//                               base::SPLIT_WANT_NONEMPTY)) {
//     ...
BASE_EXPORT std::vector<StringPiece> SplitStringPiece(
    StringPiece input,
    StringPiece separators,
    WhitespaceHandling whitespace,
    SplitResult result_type);
BASE_EXPORT std::vector<StringPiece16> SplitStringPiece(
    StringPiece16 input,
    StringPiece16 separators,
    WhitespaceHandling whitespace,
    SplitResult result_type);

using StringPairs = std::vector<std::pair<std::string, std::string>>;

// Splits |line| into key value pairs according to the given delimiters and
// removes whitespace leading each key and trailing each value. Returns true
// only if each pair has a non-empty key and value. |key_value_pairs| will
// include ("","") pairs for entries without |key_value_delimiter|.
BASE_EXPORT bool SplitStringIntoKeyValuePairs(const std::string& line,
                                              char key_value_delimiter,
                                              char key_value_pair_delimiter,
                                              StringPairs* key_value_pairs);

// Similar to SplitString, but use a substring delimiter instead of a list of
// characters that are all possible delimiters.
//
// TODO(brettw) this should probably be changed and expanded to provide a
// mirror of the SplitString[Piece] API above, just with the different
// delimiter handling.
BASE_EXPORT void SplitStringUsingSubstr(const string16& str,
                                        const string16& s,
                                        std::vector<string16>* r);
BASE_EXPORT void SplitStringUsingSubstr(const std::string& str,
                                        const std::string& s,
                                        std::vector<std::string>* r);

// -----------------------------------------------------------------------------
// Backwards-compat wrappers
//
// New code should use one of the more general variants above.
// TODO(brettw) remove these and convert to the versions above.

// Splits |str| into a vector of strings delimited by |c|, placing the results
// in |r|. If several instances of |c| are contiguous, or if |str| begins with
// or ends with |c|, then an empty string is inserted.
//
// Every substring is trimmed of any leading or trailing white space.
// NOTE: |c| must be in BMP (Basic Multilingual Plane)
BASE_EXPORT void SplitString(const string16& str,
                             char16 c,
                             std::vector<string16>* r);

// |str| should not be in a multi-byte encoding like Shift-JIS or GBK in which
// the trailing byte of a multi-byte character can be in the ASCII range.
// UTF-8, and other single/multi-byte ASCII-compatible encodings are OK.
// Note: |c| must be in the ASCII range.
BASE_EXPORT void SplitString(const std::string& str,
                             char c,
                             std::vector<std::string>* r);

// The same as SplitString, but don't trim white space.
// NOTE: |c| must be in BMP (Basic Multilingual Plane)
BASE_EXPORT void SplitStringDontTrim(StringPiece16 str,
                                     char16 c,
                                     std::vector<string16>* r);
// |str| should not be in a multi-byte encoding like Shift-JIS or GBK in which
// the trailing byte of a multi-byte character can be in the ASCII range.
// UTF-8, and other single/multi-byte ASCII-compatible encodings are OK.
// Note: |c| must be in the ASCII range.
BASE_EXPORT void SplitStringDontTrim(StringPiece str,
                                     char c,
                                     std::vector<std::string>* result);

// WARNING: this uses whitespace as defined by the HTML5 spec (ASCII whitespace
// only).
//
// The difference between this and calling SplitString with the whitespace
// characters as separators is the treatment of the first element when the
// string starts with whitespace.
//
// Input        SplitString      SplitStringAlongWhitespace
// --------------------------------------------------------
// " a "        "", "a"          "a"
BASE_EXPORT void SplitStringAlongWhitespace(const string16& str,
                                            std::vector<string16>* result);
BASE_EXPORT void SplitStringAlongWhitespace(const std::string& str,
                                            std::vector<std::string>* result);

}  // namespace base

#endif  // BASE_STRINGS_STRING_SPLIT_H_
