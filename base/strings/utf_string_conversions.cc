// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/utf_string_conversions.h"

#include "base/strings/string_piece.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversion_utils.h"

namespace base {

namespace {

// Generalized Unicode converter -----------------------------------------------

// Converts the given source Unicode character type to the given destination
// Unicode character type as a STL string. The given input buffer and size
// determine the source, and the given output STL string will be replaced by
// the result.
template<typename SRC_CHAR, typename DEST_STRING>
bool ConvertUnicode(const SRC_CHAR* src,
                    size_t src_len,
                    DEST_STRING* output) {
  // ICU requires 32-bit numbers.
  bool success = true;
  int32 src_len32 = static_cast<int32>(src_len);
  for (int32 i = 0; i < src_len32; i++) {
    uint32 code_point;
    if (ReadUnicodeCharacter(src, src_len32, &i, &code_point)) {
      WriteUnicodeCharacter(code_point, output);
    } else {
      WriteUnicodeCharacter(0xFFFD, output);
      success = false;
    }
  }

  return success;
}

}  // namespace

// UTF-8 <-> Wide --------------------------------------------------------------

bool WideToUTF8(const wchar_t* src, size_t src_len, std::string* output) {
  if (IsStringASCII(std::wstring(src, src_len))) {
    output->assign(src, src + src_len);
    return true;
  } else {
    PrepareForUTF8Output(src, src_len, output);
    return ConvertUnicode(src, src_len, output);
  }
}

std::string WideToUTF8(const std::wstring& wide) {
  if (IsStringASCII(wide)) {
    return std::string(wide.data(), wide.data() + wide.length());
  }

  std::string ret;
  PrepareForUTF8Output(wide.data(), wide.length(), &ret);
  ConvertUnicode(wide.data(), wide.length(), &ret);
  return ret;
}

bool UTF8ToWide(const char* src, size_t src_len, std::wstring* output) {
  if (IsStringASCII(StringPiece(src, src_len))) {
    output->assign(src, src + src_len);
    return true;
  } else {
    PrepareForUTF16Or32Output(src, src_len, output);
    return ConvertUnicode(src, src_len, output);
  }
}

std::wstring UTF8ToWide(const StringPiece& utf8) {
  if (IsStringASCII(utf8)) {
    return std::wstring(utf8.begin(), utf8.end());
  }

  std::wstring ret;
  PrepareForUTF16Or32Output(utf8.data(), utf8.length(), &ret);
  ConvertUnicode(utf8.data(), utf8.length(), &ret);
  return ret;
}

// UTF-16 <-> Wide -------------------------------------------------------------

#if defined(WCHAR_T_IS_UTF16)

// When wide == UTF-16, then conversions are a NOP.
bool WideToUTF16(const wchar_t* src, size_t src_len, string16* output) {
  output->assign(src, src_len);
  return true;
}

string16 WideToUTF16(const std::wstring& wide) {
  return wide;
}

bool UTF16ToWide(const char16* src, size_t src_len, std::wstring* output) {
  output->assign(src, src_len);
  return true;
}

std::wstring UTF16ToWide(const string16& utf16) {
  return utf16;
}

#elif defined(WCHAR_T_IS_UTF32)

bool WideToUTF16(const wchar_t* src, size_t src_len, string16* output) {
  output->clear();
  // Assume that normally we won't have any non-BMP characters so the counts
  // will be the same.
  output->reserve(src_len);
  return ConvertUnicode(src, src_len, output);
}

string16 WideToUTF16(const std::wstring& wide) {
  string16 ret;
  WideToUTF16(wide.data(), wide.length(), &ret);
  return ret;
}

bool UTF16ToWide(const char16* src, size_t src_len, std::wstring* output) {
  output->clear();
  // Assume that normally we won't have any non-BMP characters so the counts
  // will be the same.
  output->reserve(src_len);
  return ConvertUnicode(src, src_len, output);
}

std::wstring UTF16ToWide(const string16& utf16) {
  std::wstring ret;
  UTF16ToWide(utf16.data(), utf16.length(), &ret);
  return ret;
}

#endif  // defined(WCHAR_T_IS_UTF32)

// UTF16 <-> UTF8 --------------------------------------------------------------

#if defined(WCHAR_T_IS_UTF32)

bool UTF8ToUTF16(const char* src, size_t src_len, string16* output) {
  if (IsStringASCII(StringPiece(src, src_len))) {
    output->assign(src, src + src_len);
    return true;
  } else {
    PrepareForUTF16Or32Output(src, src_len, output);
    return ConvertUnicode(src, src_len, output);
  }
}

string16 UTF8ToUTF16(const StringPiece& utf8) {
  if (IsStringASCII(utf8)) {
    return string16(utf8.begin(), utf8.end());
  }

  string16 ret;
  PrepareForUTF16Or32Output(utf8.data(), utf8.length(), &ret);
  // Ignore the success flag of this call, it will do the best it can for
  // invalid input, which is what we want here.
  ConvertUnicode(utf8.data(), utf8.length(), &ret);
  return ret;
}

bool UTF16ToUTF8(const char16* src, size_t src_len, std::string* output) {
  if (IsStringASCII(StringPiece16(src, src_len))) {
    output->assign(src, src + src_len);
    return true;
  } else {
    PrepareForUTF8Output(src, src_len, output);
    return ConvertUnicode(src, src_len, output);
  }
}

std::string UTF16ToUTF8(const string16& utf16) {
  if (IsStringASCII(utf16)) {
    return std::string(utf16.begin(), utf16.end());
  }

  std::string ret;
  // Ignore the success flag of this call, it will do the best it can for
  // invalid input, which is what we want here.
  UTF16ToUTF8(utf16.data(), utf16.length(), &ret);
  return ret;
}

#elif defined(WCHAR_T_IS_UTF16)
// Easy case since we can use the "wide" versions we already wrote above.

bool UTF8ToUTF16(const char* src, size_t src_len, string16* output) {
  return UTF8ToWide(src, src_len, output);
}

string16 UTF8ToUTF16(const StringPiece& utf8) {
  return UTF8ToWide(utf8);
}

bool UTF16ToUTF8(const char16* src, size_t src_len, std::string* output) {
  return WideToUTF8(src, src_len, output);
}

std::string UTF16ToUTF8(const string16& utf16) {
  return WideToUTF8(utf16);
}

#endif

string16 ASCIIToUTF16(const StringPiece& ascii) {
  DCHECK(IsStringASCII(ascii)) << ascii;
  return string16(ascii.begin(), ascii.end());
}

std::string UTF16ToASCII(const string16& utf16) {
  DCHECK(IsStringASCII(utf16)) << UTF16ToUTF8(utf16);
  return std::string(utf16.begin(), utf16.end());
}

}  // namespace base
