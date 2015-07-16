// Copyright (c) 2006-2008 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/json/string_escape.h"

#include <string>

#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversion_utils.h"
#include "base/strings/utf_string_conversions.h"
#include "base/third_party/icu/icu_utf.h"

namespace base {

namespace {

// Format string for printing a \uXXXX escape sequence.
const char kU16EscapeFormat[] = "\\u%04X";

// The code point to output for an invalid input code unit.
const uint32 kReplacementCodePoint = 0xFFFD;

// Used below in EscapeSpecialCodePoint().
COMPILE_ASSERT('<' == 0x3C, less_than_sign_is_0x3c);

// Try to escape the |code_point| if it is a known special character. If
// successful, returns true and appends the escape sequence to |dest|. This
// isn't required by the spec, but it's more readable by humans.
bool EscapeSpecialCodePoint(uint32 code_point, std::string* dest) {
  // WARNING: if you add a new case here, you need to update the reader as well.
  // Note: \v is in the reader, but not here since the JSON spec doesn't
  // allow it.
  switch (code_point) {
    case '\b':
      dest->append("\\b");
      break;
    case '\f':
      dest->append("\\f");
      break;
    case '\n':
      dest->append("\\n");
      break;
    case '\r':
      dest->append("\\r");
      break;
    case '\t':
      dest->append("\\t");
      break;
    case '\\':
      dest->append("\\\\");
      break;
    case '"':
      dest->append("\\\"");
      break;
    // Escape < to prevent script execution; escaping > is not necessary and
    // not doing so save a few bytes.
    case '<':
      dest->append("\\u003C");
      break;
    default:
      return false;
  }
  return true;
}

template <typename S>
bool EscapeJSONStringImpl(const S& str, bool put_in_quotes, std::string* dest) {
  bool did_replacement = false;

  if (put_in_quotes)
    dest->push_back('"');

  // Casting is necessary because ICU uses int32. Try and do so safely.
  CHECK_LE(str.length(), static_cast<size_t>(kint32max));
  const int32 length = static_cast<int32>(str.length());

  for (int32 i = 0; i < length; ++i) {
    uint32 code_point;
    if (!ReadUnicodeCharacter(str.data(), length, &i, &code_point)) {
      code_point = kReplacementCodePoint;
      did_replacement = true;
    }

    if (EscapeSpecialCodePoint(code_point, dest))
      continue;

    // Escape non-printing characters.
    if (code_point < 32)
      base::StringAppendF(dest, kU16EscapeFormat, code_point);
    else
      WriteUnicodeCharacter(code_point, dest);
  }

  if (put_in_quotes)
    dest->push_back('"');

  return !did_replacement;
}

}  // namespace

bool EscapeJSONString(const StringPiece& str,
                      bool put_in_quotes,
                      std::string* dest) {
  return EscapeJSONStringImpl(str, put_in_quotes, dest);
}

bool EscapeJSONString(const StringPiece16& str,
                      bool put_in_quotes,
                      std::string* dest) {
  return EscapeJSONStringImpl(str, put_in_quotes, dest);
}

std::string GetQuotedJSONString(const StringPiece& str) {
  std::string dest;
  bool ok = EscapeJSONStringImpl(str, true, &dest);
  DCHECK(ok);
  return dest;
}

std::string GetQuotedJSONString(const StringPiece16& str) {
  std::string dest;
  bool ok = EscapeJSONStringImpl(str, true, &dest);
  DCHECK(ok);
  return dest;
}

std::string EscapeBytesAsInvalidJSONString(const StringPiece& str,
                                           bool put_in_quotes) {
  std::string dest;

  if (put_in_quotes)
    dest.push_back('"');

  for (StringPiece::const_iterator it = str.begin(); it != str.end(); ++it) {
    unsigned char c = *it;
    if (EscapeSpecialCodePoint(c, &dest))
      continue;

    if (c < 32 || c > 126)
      base::StringAppendF(&dest, kU16EscapeFormat, c);
    else
      dest.push_back(*it);
  }

  if (put_in_quotes)
    dest.push_back('"');

  return dest;
}

}  // namespace base
