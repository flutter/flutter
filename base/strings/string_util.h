// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// This file defines utility functions for working with strings.

#ifndef BASE_STRINGS_STRING_UTIL_H_
#define BASE_STRINGS_STRING_UTIL_H_

#include <ctype.h>
#include <stdarg.h>   // va_list

#include <string>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/strings/string16.h"
#include "base/strings/string_piece.h"  // For implicit conversions.

namespace base {

// C standard-library functions like "strncasecmp" and "snprintf" that aren't
// cross-platform are provided as "base::strncasecmp", and their prototypes
// are listed below.  These functions are then implemented as inline calls
// to the platform-specific equivalents in the platform-specific headers.

// Compares the two strings s1 and s2 without regard to case using
// the current locale; returns 0 if they are equal, 1 if s1 > s2, and -1 if
// s2 > s1 according to a lexicographic comparison.
int strcasecmp(const char* s1, const char* s2);

// Compares up to count characters of s1 and s2 without regard to case using
// the current locale; returns 0 if they are equal, 1 if s1 > s2, and -1 if
// s2 > s1 according to a lexicographic comparison.
int strncasecmp(const char* s1, const char* s2, size_t count);

// Same as strncmp but for char16 strings.
int strncmp16(const char16* s1, const char16* s2, size_t count);

// Wrapper for vsnprintf that always null-terminates and always returns the
// number of characters that would be in an untruncated formatted
// string, even when truncation occurs.
int vsnprintf(char* buffer, size_t size, const char* format, va_list arguments)
    PRINTF_FORMAT(3, 0);

// Some of these implementations need to be inlined.

// We separate the declaration from the implementation of this inline
// function just so the PRINTF_FORMAT works.
inline int snprintf(char* buffer, size_t size, const char* format, ...)
    PRINTF_FORMAT(3, 4);
inline int snprintf(char* buffer, size_t size, const char* format, ...) {
  va_list arguments;
  va_start(arguments, format);
  int result = vsnprintf(buffer, size, format, arguments);
  va_end(arguments);
  return result;
}

// BSD-style safe and consistent string copy functions.
// Copies |src| to |dst|, where |dst_size| is the total allocated size of |dst|.
// Copies at most |dst_size|-1 characters, and always NULL terminates |dst|, as
// long as |dst_size| is not 0.  Returns the length of |src| in characters.
// If the return value is >= dst_size, then the output was truncated.
// NOTE: All sizes are in number of characters, NOT in bytes.
BASE_EXPORT size_t strlcpy(char* dst, const char* src, size_t dst_size);
BASE_EXPORT size_t wcslcpy(wchar_t* dst, const wchar_t* src, size_t dst_size);

// Scan a wprintf format string to determine whether it's portable across a
// variety of systems.  This function only checks that the conversion
// specifiers used by the format string are supported and have the same meaning
// on a variety of systems.  It doesn't check for other errors that might occur
// within a format string.
//
// Nonportable conversion specifiers for wprintf are:
//  - 's' and 'c' without an 'l' length modifier.  %s and %c operate on char
//     data on all systems except Windows, which treat them as wchar_t data.
//     Use %ls and %lc for wchar_t data instead.
//  - 'S' and 'C', which operate on wchar_t data on all systems except Windows,
//     which treat them as char data.  Use %ls and %lc for wchar_t data
//     instead.
//  - 'F', which is not identified by Windows wprintf documentation.
//  - 'D', 'O', and 'U', which are deprecated and not available on all systems.
//     Use %ld, %lo, and %lu instead.
//
// Note that there is no portable conversion specifier for char data when
// working with wprintf.
//
// This function is intended to be called from base::vswprintf.
BASE_EXPORT bool IsWprintfFormatPortable(const wchar_t* format);

// ASCII-specific tolower.  The standard library's tolower is locale sensitive,
// so we don't want to use it here.
template <class Char> inline Char ToLowerASCII(Char c) {
  return (c >= 'A' && c <= 'Z') ? (c + ('a' - 'A')) : c;
}

// ASCII-specific toupper.  The standard library's toupper is locale sensitive,
// so we don't want to use it here.
template <class Char> inline Char ToUpperASCII(Char c) {
  return (c >= 'a' && c <= 'z') ? (c + ('A' - 'a')) : c;
}

// Function objects to aid in comparing/searching strings.

template<typename Char> struct CaseInsensitiveCompare {
 public:
  bool operator()(Char x, Char y) const {
    // TODO(darin): Do we really want to do locale sensitive comparisons here?
    // See http://crbug.com/24917
    return tolower(x) == tolower(y);
  }
};

template<typename Char> struct CaseInsensitiveCompareASCII {
 public:
  bool operator()(Char x, Char y) const {
    return ToLowerASCII(x) == ToLowerASCII(y);
  }
};

// These threadsafe functions return references to globally unique empty
// strings.
//
// It is likely faster to construct a new empty string object (just a few
// instructions to set the length to 0) than to get the empty string singleton
// returned by these functions (which requires threadsafe singleton access).
//
// Therefore, DO NOT USE THESE AS A GENERAL-PURPOSE SUBSTITUTE FOR DEFAULT
// CONSTRUCTORS. There is only one case where you should use these: functions
// which need to return a string by reference (e.g. as a class member
// accessor), and don't have an empty string to use (e.g. in an error case).
// These should not be used as initializers, function arguments, or return
// values for functions which return by value or outparam.
BASE_EXPORT const std::string& EmptyString();
BASE_EXPORT const string16& EmptyString16();

// Contains the set of characters representing whitespace in the corresponding
// encoding. Null-terminated.
BASE_EXPORT extern const wchar_t kWhitespaceWide[];
BASE_EXPORT extern const char16 kWhitespaceUTF16[];
BASE_EXPORT extern const char kWhitespaceASCII[];

// Null-terminated string representing the UTF-8 byte order mark.
BASE_EXPORT extern const char kUtf8ByteOrderMark[];

// Removes characters in |remove_chars| from anywhere in |input|.  Returns true
// if any characters were removed.  |remove_chars| must be null-terminated.
// NOTE: Safe to use the same variable for both |input| and |output|.
BASE_EXPORT bool RemoveChars(const string16& input,
                             const base::StringPiece16& remove_chars,
                             string16* output);
BASE_EXPORT bool RemoveChars(const std::string& input,
                             const base::StringPiece& remove_chars,
                             std::string* output);

// Replaces characters in |replace_chars| from anywhere in |input| with
// |replace_with|.  Each character in |replace_chars| will be replaced with
// the |replace_with| string.  Returns true if any characters were replaced.
// |replace_chars| must be null-terminated.
// NOTE: Safe to use the same variable for both |input| and |output|.
BASE_EXPORT bool ReplaceChars(const string16& input,
                              const base::StringPiece16& replace_chars,
                              const string16& replace_with,
                              string16* output);
BASE_EXPORT bool ReplaceChars(const std::string& input,
                              const base::StringPiece& replace_chars,
                              const std::string& replace_with,
                              std::string* output);

// Removes characters in |trim_chars| from the beginning and end of |input|.
// |trim_chars| must be null-terminated.
// NOTE: Safe to use the same variable for both |input| and |output|.
BASE_EXPORT bool TrimString(const string16& input,
                            const base::StringPiece16& trim_chars,
                            string16* output);
BASE_EXPORT bool TrimString(const std::string& input,
                            const base::StringPiece& trim_chars,
                            std::string* output);

// Truncates a string to the nearest UTF-8 character that will leave
// the string less than or equal to the specified byte size.
BASE_EXPORT void TruncateUTF8ToByteSize(const std::string& input,
                                        const size_t byte_size,
                                        std::string* output);

// Trims any whitespace from either end of the input string.  Returns where
// whitespace was found.
// The non-wide version has two functions:
// * TrimWhitespaceASCII()
//   This function is for ASCII strings and only looks for ASCII whitespace;
// Please choose the best one according to your usage.
// NOTE: Safe to use the same variable for both input and output.
enum TrimPositions {
  TRIM_NONE     = 0,
  TRIM_LEADING  = 1 << 0,
  TRIM_TRAILING = 1 << 1,
  TRIM_ALL      = TRIM_LEADING | TRIM_TRAILING,
};
BASE_EXPORT TrimPositions TrimWhitespace(const string16& input,
                                         TrimPositions positions,
                                         base::string16* output);
BASE_EXPORT TrimPositions TrimWhitespaceASCII(const std::string& input,
                                              TrimPositions positions,
                                              std::string* output);

// Deprecated. This function is only for backward compatibility and calls
// TrimWhitespaceASCII().
BASE_EXPORT TrimPositions TrimWhitespace(const std::string& input,
                                         TrimPositions positions,
                                         std::string* output);

// Searches  for CR or LF characters.  Removes all contiguous whitespace
// strings that contain them.  This is useful when trying to deal with text
// copied from terminals.
// Returns |text|, with the following three transformations:
// (1) Leading and trailing whitespace is trimmed.
// (2) If |trim_sequences_with_line_breaks| is true, any other whitespace
//     sequences containing a CR or LF are trimmed.
// (3) All other whitespace sequences are converted to single spaces.
BASE_EXPORT string16 CollapseWhitespace(
    const string16& text,
    bool trim_sequences_with_line_breaks);
BASE_EXPORT std::string CollapseWhitespaceASCII(
    const std::string& text,
    bool trim_sequences_with_line_breaks);

// Returns true if |input| is empty or contains only characters found in
// |characters|.
BASE_EXPORT bool ContainsOnlyChars(const StringPiece& input,
                                   const StringPiece& characters);
BASE_EXPORT bool ContainsOnlyChars(const StringPiece16& input,
                                   const StringPiece16& characters);

// Returns true if the specified string matches the criteria. How can a wide
// string be 8-bit or UTF8? It contains only characters that are < 256 (in the
// first case) or characters that use only 8-bits and whose 8-bit
// representation looks like a UTF-8 string (the second case).
//
// Note that IsStringUTF8 checks not only if the input is structurally
// valid but also if it doesn't contain any non-character codepoint
// (e.g. U+FFFE). It's done on purpose because all the existing callers want
// to have the maximum 'discriminating' power from other encodings. If
// there's a use case for just checking the structural validity, we have to
// add a new function for that.
//
// IsStringASCII assumes the input is likely all ASCII, and does not leave early
// if it is not the case.
BASE_EXPORT bool IsStringUTF8(const StringPiece& str);
BASE_EXPORT bool IsStringASCII(const StringPiece& str);
BASE_EXPORT bool IsStringASCII(const StringPiece16& str);
// A convenience adaptor for WebStrings, as they don't convert into
// StringPieces directly.
BASE_EXPORT bool IsStringASCII(const string16& str);
#if defined(WCHAR_T_IS_UTF32)
BASE_EXPORT bool IsStringASCII(const std::wstring& str);
#endif

// Converts the elements of the given string.  This version uses a pointer to
// clearly differentiate it from the non-pointer variant.
template <class str> inline void StringToLowerASCII(str* s) {
  for (typename str::iterator i = s->begin(); i != s->end(); ++i)
    *i = ToLowerASCII(*i);
}

template <class str> inline str StringToLowerASCII(const str& s) {
  // for std::string and std::wstring
  str output(s);
  StringToLowerASCII(&output);
  return output;
}

// Converts the elements of the given string.  This version uses a pointer to
// clearly differentiate it from the non-pointer variant.
template <class str> inline void StringToUpperASCII(str* s) {
  for (typename str::iterator i = s->begin(); i != s->end(); ++i)
    *i = ToUpperASCII(*i);
}

template <class str> inline str StringToUpperASCII(const str& s) {
  // for std::string and std::wstring
  str output(s);
  StringToUpperASCII(&output);
  return output;
}
//
// Compare the lower-case form of the given string against the given ASCII
// string.  This is useful for doing checking if an input string matches some
// token, and it is optimized to avoid intermediate string copies.  This API is
// borrowed from the equivalent APIs in Mozilla.
BASE_EXPORT bool LowerCaseEqualsASCII(const std::string& a, const char* b);
BASE_EXPORT bool LowerCaseEqualsASCII(const string16& a, const char* b);

// Same thing, but with string iterators instead.
BASE_EXPORT bool LowerCaseEqualsASCII(std::string::const_iterator a_begin,
                                      std::string::const_iterator a_end,
                                      const char* b);
BASE_EXPORT bool LowerCaseEqualsASCII(string16::const_iterator a_begin,
                                      string16::const_iterator a_end,
                                      const char* b);
BASE_EXPORT bool LowerCaseEqualsASCII(const char* a_begin,
                                      const char* a_end,
                                      const char* b);
BASE_EXPORT bool LowerCaseEqualsASCII(const char* a_begin,
                                      const char* a_end,
                                      const char* b_begin,
                                      const char* b_end);
BASE_EXPORT bool LowerCaseEqualsASCII(const char16* a_begin,
                                      const char16* a_end,
                                      const char* b);

// Performs a case-sensitive string compare. The behavior is undefined if both
// strings are not ASCII.
BASE_EXPORT bool EqualsASCII(const string16& a, const StringPiece& b);

}  // namespace base

#if defined(OS_WIN)
#include "base/strings/string_util_win.h"
#elif defined(OS_POSIX)
#include "base/strings/string_util_posix.h"
#else
#error Define string operations appropriately for your platform
#endif

// Returns true if str starts with search, or false otherwise.
BASE_EXPORT bool StartsWithASCII(const std::string& str,
                                 const std::string& search,
                                 bool case_sensitive);
BASE_EXPORT bool StartsWith(const base::string16& str,
                            const base::string16& search,
                            bool case_sensitive);

// Returns true if str ends with search, or false otherwise.
BASE_EXPORT bool EndsWith(const std::string& str,
                          const std::string& search,
                          bool case_sensitive);
BASE_EXPORT bool EndsWith(const base::string16& str,
                          const base::string16& search,
                          bool case_sensitive);


// Determines the type of ASCII character, independent of locale (the C
// library versions will change based on locale).
template <typename Char>
inline bool IsAsciiWhitespace(Char c) {
  return c == ' ' || c == '\r' || c == '\n' || c == '\t';
}
template <typename Char>
inline bool IsAsciiAlpha(Char c) {
  return ((c >= 'A') && (c <= 'Z')) || ((c >= 'a') && (c <= 'z'));
}
template <typename Char>
inline bool IsAsciiDigit(Char c) {
  return c >= '0' && c <= '9';
}

template <typename Char>
inline bool IsHexDigit(Char c) {
  return (c >= '0' && c <= '9') ||
         (c >= 'A' && c <= 'F') ||
         (c >= 'a' && c <= 'f');
}

template <typename Char>
inline char HexDigitToInt(Char c) {
  DCHECK(IsHexDigit(c));
  if (c >= '0' && c <= '9')
    return static_cast<char>(c - '0');
  if (c >= 'A' && c <= 'F')
    return static_cast<char>(c - 'A' + 10);
  if (c >= 'a' && c <= 'f')
    return static_cast<char>(c - 'a' + 10);
  return 0;
}

// Returns true if it's a whitespace character.
inline bool IsWhitespace(wchar_t c) {
  return wcschr(base::kWhitespaceWide, c) != NULL;
}

// Return a byte string in human-readable format with a unit suffix. Not
// appropriate for use in any UI; use of FormatBytes and friends in ui/base is
// highly recommended instead. TODO(avi): Figure out how to get callers to use
// FormatBytes instead; remove this.
BASE_EXPORT base::string16 FormatBytesUnlocalized(int64 bytes);

// Starting at |start_offset| (usually 0), replace the first instance of
// |find_this| with |replace_with|.
BASE_EXPORT void ReplaceFirstSubstringAfterOffset(
    base::string16* str,
    size_t start_offset,
    const base::string16& find_this,
    const base::string16& replace_with);
BASE_EXPORT void ReplaceFirstSubstringAfterOffset(
    std::string* str,
    size_t start_offset,
    const std::string& find_this,
    const std::string& replace_with);

// Starting at |start_offset| (usually 0), look through |str| and replace all
// instances of |find_this| with |replace_with|.
//
// This does entire substrings; use std::replace in <algorithm> for single
// characters, for example:
//   std::replace(str.begin(), str.end(), 'a', 'b');
BASE_EXPORT void ReplaceSubstringsAfterOffset(
    base::string16* str,
    size_t start_offset,
    const base::string16& find_this,
    const base::string16& replace_with);
BASE_EXPORT void ReplaceSubstringsAfterOffset(std::string* str,
                                              size_t start_offset,
                                              const std::string& find_this,
                                              const std::string& replace_with);

// Reserves enough memory in |str| to accommodate |length_with_null| characters,
// sets the size of |str| to |length_with_null - 1| characters, and returns a
// pointer to the underlying contiguous array of characters.  This is typically
// used when calling a function that writes results into a character array, but
// the caller wants the data to be managed by a string-like object.  It is
// convenient in that is can be used inline in the call, and fast in that it
// avoids copying the results of the call from a char* into a string.
//
// |length_with_null| must be at least 2, since otherwise the underlying string
// would have size 0, and trying to access &((*str)[0]) in that case can result
// in a number of problems.
//
// Internally, this takes linear time because the resize() call 0-fills the
// underlying array for potentially all
// (|length_with_null - 1| * sizeof(string_type::value_type)) bytes.  Ideally we
// could avoid this aspect of the resize() call, as we expect the caller to
// immediately write over this memory, but there is no other way to set the size
// of the string, and not doing that will mean people who access |str| rather
// than str.c_str() will get back a string of whatever size |str| had on entry
// to this function (probably 0).
template <class string_type>
inline typename string_type::value_type* WriteInto(string_type* str,
                                                   size_t length_with_null) {
  DCHECK_GT(length_with_null, 1u);
  str->reserve(length_with_null);
  str->resize(length_with_null - 1);
  return &((*str)[0]);
}

//-----------------------------------------------------------------------------

// Splits a string into its fields delimited by any of the characters in
// |delimiters|.  Each field is added to the |tokens| vector.  Returns the
// number of tokens found.
BASE_EXPORT size_t Tokenize(const base::string16& str,
                            const base::string16& delimiters,
                            std::vector<base::string16>* tokens);
BASE_EXPORT size_t Tokenize(const std::string& str,
                            const std::string& delimiters,
                            std::vector<std::string>* tokens);
BASE_EXPORT size_t Tokenize(const base::StringPiece& str,
                            const base::StringPiece& delimiters,
                            std::vector<base::StringPiece>* tokens);

// Does the opposite of SplitString().
BASE_EXPORT base::string16 JoinString(const std::vector<base::string16>& parts,
                                      base::char16 s);
BASE_EXPORT std::string JoinString(
    const std::vector<std::string>& parts, char s);

// Join |parts| using |separator|.
BASE_EXPORT std::string JoinString(
    const std::vector<std::string>& parts,
    const std::string& separator);
BASE_EXPORT base::string16 JoinString(
    const std::vector<base::string16>& parts,
    const base::string16& separator);

// Replace $1-$2-$3..$9 in the format string with |a|-|b|-|c|..|i| respectively.
// Additionally, any number of consecutive '$' characters is replaced by that
// number less one. Eg $$->$, $$$->$$, etc. The offsets parameter here can be
// NULL. This only allows you to use up to nine replacements.
BASE_EXPORT base::string16 ReplaceStringPlaceholders(
    const base::string16& format_string,
    const std::vector<base::string16>& subst,
    std::vector<size_t>* offsets);

BASE_EXPORT std::string ReplaceStringPlaceholders(
    const base::StringPiece& format_string,
    const std::vector<std::string>& subst,
    std::vector<size_t>* offsets);

// Single-string shortcut for ReplaceStringHolders. |offset| may be NULL.
BASE_EXPORT base::string16 ReplaceStringPlaceholders(
    const base::string16& format_string,
    const base::string16& a,
    size_t* offset);

// Returns true if the string passed in matches the pattern. The pattern
// string can contain wildcards like * and ?
// The backslash character (\) is an escape character for * and ?
// We limit the patterns to having a max of 16 * or ? characters.
// ? matches 0 or 1 character, while * matches 0 or more characters.
BASE_EXPORT bool MatchPattern(const base::StringPiece& string,
                              const base::StringPiece& pattern);
BASE_EXPORT bool MatchPattern(const base::string16& string,
                              const base::string16& pattern);

#endif  // BASE_STRINGS_STRING_UTIL_H_
