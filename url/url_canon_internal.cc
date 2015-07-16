// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "url/url_canon_internal.h"

#include <errno.h>
#include <stdlib.h>

#include <cstdio>
#include <string>

#include "base/strings/utf_string_conversion_utils.h"

namespace url {

namespace {

template<typename CHAR, typename UCHAR>
void DoAppendStringOfType(const CHAR* source, int length,
                          SharedCharTypes type,
                          CanonOutput* output) {
  for (int i = 0; i < length; i++) {
    if (static_cast<UCHAR>(source[i]) >= 0x80) {
      // ReadChar will fill the code point with kUnicodeReplacementCharacter
      // when the input is invalid, which is what we want.
      unsigned code_point;
      ReadUTFChar(source, &i, length, &code_point);
      AppendUTF8EscapedValue(code_point, output);
    } else {
      // Just append the 7-bit character, possibly escaping it.
      unsigned char uch = static_cast<unsigned char>(source[i]);
      if (!IsCharOfType(uch, type))
        AppendEscapedChar(uch, output);
      else
        output->push_back(uch);
    }
  }
}

// This function assumes the input values are all contained in 8-bit,
// although it allows any type. Returns true if input is valid, false if not.
template<typename CHAR, typename UCHAR>
void DoAppendInvalidNarrowString(const CHAR* spec, int begin, int end,
                                 CanonOutput* output) {
  for (int i = begin; i < end; i++) {
    UCHAR uch = static_cast<UCHAR>(spec[i]);
    if (uch >= 0x80) {
      // Handle UTF-8/16 encodings. This call will correctly handle the error
      // case by appending the invalid character.
      AppendUTF8EscapedChar(spec, &i, end, output);
    } else if (uch <= ' ' || uch == 0x7f) {
      // This function is for error handling, so we escape all control
      // characters and spaces, but not anything else since we lack
      // context to do something more specific.
      AppendEscapedChar(static_cast<unsigned char>(uch), output);
    } else {
      output->push_back(static_cast<char>(uch));
    }
  }
}

// Overrides one component, see the Replacements structure for
// what the various combionations of source pointer and component mean.
void DoOverrideComponent(const char* override_source,
                         const Component& override_component,
                         const char** dest,
                         Component* dest_component) {
  if (override_source) {
    *dest = override_source;
    *dest_component = override_component;
  }
}

// Similar to DoOverrideComponent except that it takes a UTF-16 input and does
// not actually set the output character pointer.
//
// The input is converted to UTF-8 at the end of the given buffer as a temporary
// holding place. The component identifying the portion of the buffer used in
// the |utf8_buffer| will be specified in |*dest_component|.
//
// This will not actually set any |dest| pointer like DoOverrideComponent
// does because all of the pointers will point into the |utf8_buffer|, which
// may get resized while we're overriding a subsequent component. Instead, the
// caller should use the beginning of the |utf8_buffer| as the string pointer
// for all components once all overrides have been prepared.
bool PrepareUTF16OverrideComponent(const base::char16* override_source,
                                   const Component& override_component,
                                   CanonOutput* utf8_buffer,
                                   Component* dest_component) {
  bool success = true;
  if (override_source) {
    if (!override_component.is_valid()) {
      // Non-"valid" component (means delete), so we need to preserve that.
      *dest_component = Component();
    } else {
      // Convert to UTF-8.
      dest_component->begin = utf8_buffer->length();
      success = ConvertUTF16ToUTF8(&override_source[override_component.begin],
                                   override_component.len, utf8_buffer);
      dest_component->len = utf8_buffer->length() - dest_component->begin;
    }
  }
  return success;
}

}  // namespace

// See the header file for this array's declaration.
const unsigned char kSharedCharTypeTable[0x100] = {
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0x00 - 0x0f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0x10 - 0x1f
    0,                           // 0x20  ' ' (escape spaces in queries)
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x21  !
    0,                           // 0x22  "
    0,                           // 0x23  #  (invalid in query since it marks the ref)
    CHAR_QUERY | CHAR_USERINFO,  // 0x24  $
    CHAR_QUERY | CHAR_USERINFO,  // 0x25  %
    CHAR_QUERY | CHAR_USERINFO,  // 0x26  &
    0,                           // 0x27  '  (Try to prevent XSS.)
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x28  (
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x29  )
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x2a  *
    CHAR_QUERY | CHAR_USERINFO,  // 0x2b  +
    CHAR_QUERY | CHAR_USERINFO,  // 0x2c  ,
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x2d  -
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_COMPONENT,  // 0x2e  .
    CHAR_QUERY,                  // 0x2f  /
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x30  0
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x31  1
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x32  2
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x33  3
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x34  4
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x35  5
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x36  6
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_OCT | CHAR_COMPONENT,  // 0x37  7
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_COMPONENT,             // 0x38  8
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_DEC | CHAR_COMPONENT,             // 0x39  9
    CHAR_QUERY,  // 0x3a  :
    CHAR_QUERY,  // 0x3b  ;
    0,           // 0x3c  <  (Try to prevent certain types of XSS.)
    CHAR_QUERY,  // 0x3d  =
    0,           // 0x3e  >  (Try to prevent certain types of XSS.)
    CHAR_QUERY,  // 0x3f  ?
    CHAR_QUERY,  // 0x40  @
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x41  A
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x42  B
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x43  C
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x44  D
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x45  E
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x46  F
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x47  G
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x48  H
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x49  I
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x4a  J
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x4b  K
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x4c  L
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x4d  M
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x4e  N
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x4f  O
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x50  P
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x51  Q
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x52  R
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x53  S
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x54  T
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x55  U
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x56  V
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x57  W
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_COMPONENT, // 0x58  X
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x59  Y
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x5a  Z
    CHAR_QUERY,  // 0x5b  [
    CHAR_QUERY,  // 0x5c  '\'
    CHAR_QUERY,  // 0x5d  ]
    CHAR_QUERY,  // 0x5e  ^
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x5f  _
    CHAR_QUERY,  // 0x60  `
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x61  a
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x62  b
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x63  c
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x64  d
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x65  e
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_HEX | CHAR_COMPONENT,  // 0x66  f
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x67  g
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x68  h
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x69  i
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x6a  j
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x6b  k
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x6c  l
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x6d  m
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x6e  n
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x6f  o
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x70  p
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x71  q
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x72  r
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x73  s
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x74  t
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x75  u
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x76  v
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x77  w
    CHAR_QUERY | CHAR_USERINFO | CHAR_IPV4 | CHAR_COMPONENT,  // 0x78  x
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x79  y
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x7a  z
    CHAR_QUERY,  // 0x7b  {
    CHAR_QUERY,  // 0x7c  |
    CHAR_QUERY,  // 0x7d  }
    CHAR_QUERY | CHAR_USERINFO | CHAR_COMPONENT,  // 0x7e  ~
    0,           // 0x7f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0x80 - 0x8f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0x90 - 0x9f
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0xa0 - 0xaf
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0xb0 - 0xbf
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0xc0 - 0xcf
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0xd0 - 0xdf
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0xe0 - 0xef
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,  // 0xf0 - 0xff
};

const char kHexCharLookup[0x10] = {
    '0', '1', '2', '3', '4', '5', '6', '7',
    '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
};

const char kCharToHexLookup[8] = {
    0,         // 0x00 - 0x1f
    '0',       // 0x20 - 0x3f: digits 0 - 9 are 0x30 - 0x39
    'A' - 10,  // 0x40 - 0x5f: letters A - F are 0x41 - 0x46
    'a' - 10,  // 0x60 - 0x7f: letters a - f are 0x61 - 0x66
    0,         // 0x80 - 0x9F
    0,         // 0xA0 - 0xBF
    0,         // 0xC0 - 0xDF
    0,         // 0xE0 - 0xFF
};

const base::char16 kUnicodeReplacementCharacter = 0xfffd;

void AppendStringOfType(const char* source, int length,
                        SharedCharTypes type,
                        CanonOutput* output) {
  DoAppendStringOfType<char, unsigned char>(source, length, type, output);
}

void AppendStringOfType(const base::char16* source, int length,
                        SharedCharTypes type,
                        CanonOutput* output) {
  DoAppendStringOfType<base::char16, base::char16>(
      source, length, type, output);
}

bool ReadUTFChar(const char* str, int* begin, int length,
                 unsigned* code_point_out) {
  // This depends on ints and int32s being the same thing.  If they're not, it
  // will fail to compile.
  // TODO(mmenke):  This should probably be fixed.
  if (!base::ReadUnicodeCharacter(str, length, begin, code_point_out) ||
      !base::IsValidCharacter(*code_point_out)) {
    *code_point_out = kUnicodeReplacementCharacter;
    return false;
  }
  return true;
}

bool ReadUTFChar(const base::char16* str, int* begin, int length,
                 unsigned* code_point_out) {
  // This depends on ints and int32s being the same thing.  If they're not, it
  // will fail to compile.
  // TODO(mmenke):  This should probably be fixed.
  if (!base::ReadUnicodeCharacter(str, length, begin, code_point_out) ||
      !base::IsValidCharacter(*code_point_out)) {
    *code_point_out = kUnicodeReplacementCharacter;
    return false;
  }
  return true;
}

void AppendInvalidNarrowString(const char* spec, int begin, int end,
                               CanonOutput* output) {
  DoAppendInvalidNarrowString<char, unsigned char>(spec, begin, end, output);
}

void AppendInvalidNarrowString(const base::char16* spec, int begin, int end,
                               CanonOutput* output) {
  DoAppendInvalidNarrowString<base::char16, base::char16>(
      spec, begin, end, output);
}

bool ConvertUTF16ToUTF8(const base::char16* input, int input_len,
                        CanonOutput* output) {
  bool success = true;
  for (int i = 0; i < input_len; i++) {
    unsigned code_point;
    success &= ReadUTFChar(input, &i, input_len, &code_point);
    AppendUTF8Value(code_point, output);
  }
  return success;
}

bool ConvertUTF8ToUTF16(const char* input, int input_len,
                        CanonOutputT<base::char16>* output) {
  bool success = true;
  for (int i = 0; i < input_len; i++) {
    unsigned code_point;
    success &= ReadUTFChar(input, &i, input_len, &code_point);
    AppendUTF16Value(code_point, output);
  }
  return success;
}

void SetupOverrideComponents(const char* base,
                             const Replacements<char>& repl,
                             URLComponentSource<char>* source,
                             Parsed* parsed) {
  // Get the source and parsed structures of the things we are replacing.
  const URLComponentSource<char>& repl_source = repl.sources();
  const Parsed& repl_parsed = repl.components();

  DoOverrideComponent(repl_source.scheme, repl_parsed.scheme,
                      &source->scheme, &parsed->scheme);
  DoOverrideComponent(repl_source.username, repl_parsed.username,
                      &source->username, &parsed->username);
  DoOverrideComponent(repl_source.password, repl_parsed.password,
                      &source->password, &parsed->password);

  // Our host should be empty if not present, so override the default setup.
  DoOverrideComponent(repl_source.host, repl_parsed.host,
                      &source->host, &parsed->host);
  if (parsed->host.len == -1)
    parsed->host.len = 0;

  DoOverrideComponent(repl_source.port, repl_parsed.port,
                      &source->port, &parsed->port);
  DoOverrideComponent(repl_source.path, repl_parsed.path,
                      &source->path, &parsed->path);
  DoOverrideComponent(repl_source.query, repl_parsed.query,
                      &source->query, &parsed->query);
  DoOverrideComponent(repl_source.ref, repl_parsed.ref,
                      &source->ref, &parsed->ref);
}

bool SetupUTF16OverrideComponents(const char* base,
                                  const Replacements<base::char16>& repl,
                                  CanonOutput* utf8_buffer,
                                  URLComponentSource<char>* source,
                                  Parsed* parsed) {
  bool success = true;

  // Get the source and parsed structures of the things we are replacing.
  const URLComponentSource<base::char16>& repl_source = repl.sources();
  const Parsed& repl_parsed = repl.components();

  success &= PrepareUTF16OverrideComponent(
      repl_source.scheme, repl_parsed.scheme,
      utf8_buffer, &parsed->scheme);
  success &= PrepareUTF16OverrideComponent(
      repl_source.username, repl_parsed.username,
      utf8_buffer, &parsed->username);
  success &= PrepareUTF16OverrideComponent(
      repl_source.password, repl_parsed.password,
      utf8_buffer, &parsed->password);
  success &= PrepareUTF16OverrideComponent(
      repl_source.host, repl_parsed.host,
      utf8_buffer, &parsed->host);
  success &= PrepareUTF16OverrideComponent(
      repl_source.port, repl_parsed.port,
      utf8_buffer, &parsed->port);
  success &= PrepareUTF16OverrideComponent(
      repl_source.path, repl_parsed.path,
      utf8_buffer, &parsed->path);
  success &= PrepareUTF16OverrideComponent(
      repl_source.query, repl_parsed.query,
      utf8_buffer, &parsed->query);
  success &= PrepareUTF16OverrideComponent(
      repl_source.ref, repl_parsed.ref,
      utf8_buffer, &parsed->ref);

  // PrepareUTF16OverrideComponent will not have set the data pointer since the
  // buffer could be resized, invalidating the pointers. We set the data
  // pointers for affected components now that the buffer is finalized.
  if (repl_source.scheme)   source->scheme = utf8_buffer->data();
  if (repl_source.username) source->username = utf8_buffer->data();
  if (repl_source.password) source->password = utf8_buffer->data();
  if (repl_source.host)     source->host = utf8_buffer->data();
  if (repl_source.port)     source->port = utf8_buffer->data();
  if (repl_source.path)     source->path = utf8_buffer->data();
  if (repl_source.query)    source->query = utf8_buffer->data();
  if (repl_source.ref)      source->ref = utf8_buffer->data();

  return success;
}

#ifndef WIN32

int _itoa_s(int value, char* buffer, size_t size_in_chars, int radix) {
  const char* format_str;
  if (radix == 10)
    format_str = "%d";
  else if (radix == 16)
    format_str = "%x";
  else
    return EINVAL;

  int written = snprintf(buffer, size_in_chars, format_str, value);
  if (static_cast<size_t>(written) >= size_in_chars) {
    // Output was truncated, or written was negative.
    return EINVAL;
  }
  return 0;
}

int _itow_s(int value, base::char16* buffer, size_t size_in_chars, int radix) {
  if (radix != 10)
    return EINVAL;

  // No more than 12 characters will be required for a 32-bit integer.
  // Add an extra byte for the terminating null.
  char temp[13];
  int written = snprintf(temp, sizeof(temp), "%d", value);
  if (static_cast<size_t>(written) >= size_in_chars) {
    // Output was truncated, or written was negative.
    return EINVAL;
  }

  for (int i = 0; i < written; ++i) {
    buffer[i] = static_cast<base::char16>(temp[i]);
  }
  buffer[written] = '\0';
  return 0;
}

#endif  // !WIN32

}  // namespace url
