// Protocol Buffers - Google's data interchange format
// Copyright 2008 Google Inc.  All rights reserved.
// http://code.google.com/p/protobuf/
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
//     * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
//     * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// from google3/strings/strutil.h

#ifndef GOOGLE_PROTOBUF_STUBS_STRUTIL_H__
#define GOOGLE_PROTOBUF_STUBS_STRUTIL_H__

#include <stdlib.h>
#include <vector>
#include <google/protobuf/stubs/common.h>

namespace google {
namespace protobuf {

#ifdef _MSC_VER
#define strtoll  _strtoi64
#define strtoull _strtoui64
#elif defined(__DECCXX) && defined(__osf__)
// HP C++ on Tru64 does not have strtoll, but strtol is already 64-bit.
#define strtoll strtol
#define strtoull strtoul
#endif

// ----------------------------------------------------------------------
// ascii_isalnum()
//    Check if an ASCII character is alphanumeric.  We can't use ctype's
//    isalnum() because it is affected by locale.  This function is applied
//    to identifiers in the protocol buffer language, not to natural-language
//    strings, so locale should not be taken into account.
// ascii_isdigit()
//    Like above, but only accepts digits.
// ----------------------------------------------------------------------

inline bool ascii_isalnum(char c) {
  return ('a' <= c && c <= 'z') ||
         ('A' <= c && c <= 'Z') ||
         ('0' <= c && c <= '9');
}

inline bool ascii_isdigit(char c) {
  return ('0' <= c && c <= '9');
}

// ----------------------------------------------------------------------
// HasPrefixString()
//    Check if a string begins with a given prefix.
// StripPrefixString()
//    Given a string and a putative prefix, returns the string minus the
//    prefix string if the prefix matches, otherwise the original
//    string.
// ----------------------------------------------------------------------
inline bool HasPrefixString(const string& str,
                            const string& prefix) {
  return str.size() >= prefix.size() &&
         str.compare(0, prefix.size(), prefix) == 0;
}

inline string StripPrefixString(const string& str, const string& prefix) {
  if (HasPrefixString(str, prefix)) {
    return str.substr(prefix.size());
  } else {
    return str;
  }
}

// ----------------------------------------------------------------------
// HasSuffixString()
//    Return true if str ends in suffix.
// StripSuffixString()
//    Given a string and a putative suffix, returns the string minus the
//    suffix string if the suffix matches, otherwise the original
//    string.
// ----------------------------------------------------------------------
inline bool HasSuffixString(const string& str,
                            const string& suffix) {
  return str.size() >= suffix.size() &&
         str.compare(str.size() - suffix.size(), suffix.size(), suffix) == 0;
}

inline string StripSuffixString(const string& str, const string& suffix) {
  if (HasSuffixString(str, suffix)) {
    return str.substr(0, str.size() - suffix.size());
  } else {
    return str;
  }
}

// ----------------------------------------------------------------------
// StripString
//    Replaces any occurrence of the character 'remove' (or the characters
//    in 'remove') with the character 'replacewith'.
//    Good for keeping html characters or protocol characters (\t) out
//    of places where they might cause a problem.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT void StripString(string* s, const char* remove,
                                    char replacewith);

// ----------------------------------------------------------------------
// LowerString()
// UpperString()
//    Convert the characters in "s" to lowercase or uppercase.  ASCII-only:
//    these functions intentionally ignore locale because they are applied to
//    identifiers used in the Protocol Buffer language, not to natural-language
//    strings.
// ----------------------------------------------------------------------

inline void LowerString(string * s) {
  string::iterator end = s->end();
  for (string::iterator i = s->begin(); i != end; ++i) {
    // tolower() changes based on locale.  We don't want this!
    if ('A' <= *i && *i <= 'Z') *i += 'a' - 'A';
  }
}

inline void UpperString(string * s) {
  string::iterator end = s->end();
  for (string::iterator i = s->begin(); i != end; ++i) {
    // toupper() changes based on locale.  We don't want this!
    if ('a' <= *i && *i <= 'z') *i += 'A' - 'a';
  }
}

// ----------------------------------------------------------------------
// StringReplace()
//    Give me a string and two patterns "old" and "new", and I replace
//    the first instance of "old" in the string with "new", if it
//    exists.  RETURN a new string, regardless of whether the replacement
//    happened or not.
// ----------------------------------------------------------------------

LIBPROTOBUF_EXPORT string StringReplace(const string& s, const string& oldsub,
                                        const string& newsub, bool replace_all);

// ----------------------------------------------------------------------
// SplitStringUsing()
//    Split a string using a character delimiter. Append the components
//    to 'result'.  If there are consecutive delimiters, this function skips
//    over all of them.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT void SplitStringUsing(const string& full, const char* delim,
                                         vector<string>* res);

// Split a string using one or more byte delimiters, presented
// as a nul-terminated c string. Append the components to 'result'.
// If there are consecutive delimiters, this function will return
// corresponding empty strings.  If you want to drop the empty
// strings, try SplitStringUsing().
//
// If "full" is the empty string, yields an empty string as the only value.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT void SplitStringAllowEmpty(const string& full,
                                              const char* delim,
                                              vector<string>* result);

// ----------------------------------------------------------------------
// JoinStrings()
//    These methods concatenate a vector of strings into a C++ string, using
//    the C-string "delim" as a separator between components. There are two
//    flavors of the function, one flavor returns the concatenated string,
//    another takes a pointer to the target string. In the latter case the
//    target string is cleared and overwritten.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT void JoinStrings(const vector<string>& components,
                                    const char* delim, string* result);

inline string JoinStrings(const vector<string>& components,
                          const char* delim) {
  string result;
  JoinStrings(components, delim, &result);
  return result;
}

// ----------------------------------------------------------------------
// UnescapeCEscapeSequences()
//    Copies "source" to "dest", rewriting C-style escape sequences
//    -- '\n', '\r', '\\', '\ooo', etc -- to their ASCII
//    equivalents.  "dest" must be sufficiently large to hold all
//    the characters in the rewritten string (i.e. at least as large
//    as strlen(source) + 1 should be safe, since the replacements
//    are always shorter than the original escaped sequences).  It's
//    safe for source and dest to be the same.  RETURNS the length
//    of dest.
//
//    It allows hex sequences \xhh, or generally \xhhhhh with an
//    arbitrary number of hex digits, but all of them together must
//    specify a value of a single byte (e.g. \x0045 is equivalent
//    to \x45, and \x1234 is erroneous).
//
//    It also allows escape sequences of the form \uhhhh (exactly four
//    hex digits, upper or lower case) or \Uhhhhhhhh (exactly eight
//    hex digits, upper or lower case) to specify a Unicode code
//    point. The dest array will contain the UTF8-encoded version of
//    that code-point (e.g., if source contains \u2019, then dest will
//    contain the three bytes 0xE2, 0x80, and 0x99).
//
//    Errors: In the first form of the call, errors are reported with
//    LOG(ERROR). The same is true for the second form of the call if
//    the pointer to the string vector is NULL; otherwise, error
//    messages are stored in the vector. In either case, the effect on
//    the dest array is not defined, but rest of the source will be
//    processed.
//    ----------------------------------------------------------------------

LIBPROTOBUF_EXPORT int UnescapeCEscapeSequences(const char* source, char* dest);
LIBPROTOBUF_EXPORT int UnescapeCEscapeSequences(const char* source, char* dest,
                                                vector<string> *errors);

// ----------------------------------------------------------------------
// UnescapeCEscapeString()
//    This does the same thing as UnescapeCEscapeSequences, but creates
//    a new string. The caller does not need to worry about allocating
//    a dest buffer. This should be used for non performance critical
//    tasks such as printing debug messages. It is safe for src and dest
//    to be the same.
//
//    The second call stores its errors in a supplied string vector.
//    If the string vector pointer is NULL, it reports the errors with LOG().
//
//    In the first and second calls, the length of dest is returned. In the
//    the third call, the new string is returned.
// ----------------------------------------------------------------------

LIBPROTOBUF_EXPORT int UnescapeCEscapeString(const string& src, string* dest);
LIBPROTOBUF_EXPORT int UnescapeCEscapeString(const string& src, string* dest,
                                             vector<string> *errors);
LIBPROTOBUF_EXPORT string UnescapeCEscapeString(const string& src);

// ----------------------------------------------------------------------
// CEscapeString()
//    Copies 'src' to 'dest', escaping dangerous characters using
//    C-style escape sequences. This is very useful for preparing query
//    flags. 'src' and 'dest' should not overlap.
//    Returns the number of bytes written to 'dest' (not including the \0)
//    or -1 if there was insufficient space.
//
//    Currently only \n, \r, \t, ", ', \ and !isprint() chars are escaped.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT int CEscapeString(const char* src, int src_len,
                                     char* dest, int dest_len);

// ----------------------------------------------------------------------
// CEscape()
//    More convenient form of CEscapeString: returns result as a "string".
//    This version is slower than CEscapeString() because it does more
//    allocation.  However, it is much more convenient to use in
//    non-speed-critical code like logging messages etc.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT string CEscape(const string& src);

namespace strings {
// Like CEscape() but does not escape bytes with the upper bit set.
LIBPROTOBUF_EXPORT string Utf8SafeCEscape(const string& src);

// Like CEscape() but uses hex (\x) escapes instead of octals.
LIBPROTOBUF_EXPORT string CHexEscape(const string& src);
}  // namespace strings

// ----------------------------------------------------------------------
// strto32()
// strtou32()
// strto64()
// strtou64()
//    Architecture-neutral plug compatible replacements for strtol() and
//    strtoul().  Long's have different lengths on ILP-32 and LP-64
//    platforms, so using these is safer, from the point of view of
//    overflow behavior, than using the standard libc functions.
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT int32 strto32_adaptor(const char *nptr, char **endptr,
                                         int base);
LIBPROTOBUF_EXPORT uint32 strtou32_adaptor(const char *nptr, char **endptr,
                                           int base);

inline int32 strto32(const char *nptr, char **endptr, int base) {
  if (sizeof(int32) == sizeof(long))
    return strtol(nptr, endptr, base);
  else
    return strto32_adaptor(nptr, endptr, base);
}

inline uint32 strtou32(const char *nptr, char **endptr, int base) {
  if (sizeof(uint32) == sizeof(unsigned long))
    return strtoul(nptr, endptr, base);
  else
    return strtou32_adaptor(nptr, endptr, base);
}

// For now, long long is 64-bit on all the platforms we care about, so these
// functions can simply pass the call to strto[u]ll.
inline int64 strto64(const char *nptr, char **endptr, int base) {
  GOOGLE_COMPILE_ASSERT(sizeof(int64) == sizeof(long long),
                        sizeof_int64_is_not_sizeof_long_long);
  return strtoll(nptr, endptr, base);
}

inline uint64 strtou64(const char *nptr, char **endptr, int base) {
  GOOGLE_COMPILE_ASSERT(sizeof(uint64) == sizeof(unsigned long long),
                        sizeof_uint64_is_not_sizeof_long_long);
  return strtoull(nptr, endptr, base);
}

// ----------------------------------------------------------------------
// FastIntToBuffer()
// FastHexToBuffer()
// FastHex64ToBuffer()
// FastHex32ToBuffer()
// FastTimeToBuffer()
//    These are intended for speed.  FastIntToBuffer() assumes the
//    integer is non-negative.  FastHexToBuffer() puts output in
//    hex rather than decimal.  FastTimeToBuffer() puts the output
//    into RFC822 format.
//
//    FastHex64ToBuffer() puts a 64-bit unsigned value in hex-format,
//    padded to exactly 16 bytes (plus one byte for '\0')
//
//    FastHex32ToBuffer() puts a 32-bit unsigned value in hex-format,
//    padded to exactly 8 bytes (plus one byte for '\0')
//
//       All functions take the output buffer as an arg.
//    They all return a pointer to the beginning of the output,
//    which may not be the beginning of the input buffer.
// ----------------------------------------------------------------------

// Suggested buffer size for FastToBuffer functions.  Also works with
// DoubleToBuffer() and FloatToBuffer().
static const int kFastToBufferSize = 32;

LIBPROTOBUF_EXPORT char* FastInt32ToBuffer(int32 i, char* buffer);
LIBPROTOBUF_EXPORT char* FastInt64ToBuffer(int64 i, char* buffer);
char* FastUInt32ToBuffer(uint32 i, char* buffer);  // inline below
char* FastUInt64ToBuffer(uint64 i, char* buffer);  // inline below
LIBPROTOBUF_EXPORT char* FastHexToBuffer(int i, char* buffer);
LIBPROTOBUF_EXPORT char* FastHex64ToBuffer(uint64 i, char* buffer);
LIBPROTOBUF_EXPORT char* FastHex32ToBuffer(uint32 i, char* buffer);

// at least 22 bytes long
inline char* FastIntToBuffer(int i, char* buffer) {
  return (sizeof(i) == 4 ?
          FastInt32ToBuffer(i, buffer) : FastInt64ToBuffer(i, buffer));
}
inline char* FastUIntToBuffer(unsigned int i, char* buffer) {
  return (sizeof(i) == 4 ?
          FastUInt32ToBuffer(i, buffer) : FastUInt64ToBuffer(i, buffer));
}
inline char* FastLongToBuffer(long i, char* buffer) {
  return (sizeof(i) == 4 ?
          FastInt32ToBuffer(i, buffer) : FastInt64ToBuffer(i, buffer));
}
inline char* FastULongToBuffer(unsigned long i, char* buffer) {
  return (sizeof(i) == 4 ?
          FastUInt32ToBuffer(i, buffer) : FastUInt64ToBuffer(i, buffer));
}

// ----------------------------------------------------------------------
// FastInt32ToBufferLeft()
// FastUInt32ToBufferLeft()
// FastInt64ToBufferLeft()
// FastUInt64ToBufferLeft()
//
// Like the Fast*ToBuffer() functions above, these are intended for speed.
// Unlike the Fast*ToBuffer() functions, however, these functions write
// their output to the beginning of the buffer (hence the name, as the
// output is left-aligned).  The caller is responsible for ensuring that
// the buffer has enough space to hold the output.
//
// Returns a pointer to the end of the string (i.e. the null character
// terminating the string).
// ----------------------------------------------------------------------

LIBPROTOBUF_EXPORT char* FastInt32ToBufferLeft(int32 i, char* buffer);
LIBPROTOBUF_EXPORT char* FastUInt32ToBufferLeft(uint32 i, char* buffer);
LIBPROTOBUF_EXPORT char* FastInt64ToBufferLeft(int64 i, char* buffer);
LIBPROTOBUF_EXPORT char* FastUInt64ToBufferLeft(uint64 i, char* buffer);

// Just define these in terms of the above.
inline char* FastUInt32ToBuffer(uint32 i, char* buffer) {
  FastUInt32ToBufferLeft(i, buffer);
  return buffer;
}
inline char* FastUInt64ToBuffer(uint64 i, char* buffer) {
  FastUInt64ToBufferLeft(i, buffer);
  return buffer;
}

// ----------------------------------------------------------------------
// SimpleItoa()
//    Description: converts an integer to a string.
//
//    Return value: string
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT string SimpleItoa(int i);
LIBPROTOBUF_EXPORT string SimpleItoa(unsigned int i);
LIBPROTOBUF_EXPORT string SimpleItoa(long i);
LIBPROTOBUF_EXPORT string SimpleItoa(unsigned long i);
LIBPROTOBUF_EXPORT string SimpleItoa(long long i);
LIBPROTOBUF_EXPORT string SimpleItoa(unsigned long long i);

// ----------------------------------------------------------------------
// SimpleDtoa()
// SimpleFtoa()
// DoubleToBuffer()
// FloatToBuffer()
//    Description: converts a double or float to a string which, if
//    passed to NoLocaleStrtod(), will produce the exact same original double
//    (except in case of NaN; all NaNs are considered the same value).
//    We try to keep the string short but it's not guaranteed to be as
//    short as possible.
//
//    DoubleToBuffer() and FloatToBuffer() write the text to the given
//    buffer and return it.  The buffer must be at least
//    kDoubleToBufferSize bytes for doubles and kFloatToBufferSize
//    bytes for floats.  kFastToBufferSize is also guaranteed to be large
//    enough to hold either.
//
//    Return value: string
// ----------------------------------------------------------------------
LIBPROTOBUF_EXPORT string SimpleDtoa(double value);
LIBPROTOBUF_EXPORT string SimpleFtoa(float value);

LIBPROTOBUF_EXPORT char* DoubleToBuffer(double i, char* buffer);
LIBPROTOBUF_EXPORT char* FloatToBuffer(float i, char* buffer);

// In practice, doubles should never need more than 24 bytes and floats
// should never need more than 14 (including null terminators), but we
// overestimate to be safe.
static const int kDoubleToBufferSize = 32;
static const int kFloatToBufferSize = 24;

// ----------------------------------------------------------------------
// NoLocaleStrtod()
//   Exactly like strtod(), except it always behaves as if in the "C"
//   locale (i.e. decimal points must be '.'s).
// ----------------------------------------------------------------------

LIBPROTOBUF_EXPORT double NoLocaleStrtod(const char* text, char** endptr);

}  // namespace protobuf
}  // namespace google

#endif  // GOOGLE_PROTOBUF_STUBS_STRUTIL_H__
