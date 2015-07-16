// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/icu_string_conversions.h"

#include <vector>

#include "base/basictypes.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "third_party/icu/source/common/unicode/ucnv.h"
#include "third_party/icu/source/common/unicode/ucnv_cb.h"
#include "third_party/icu/source/common/unicode/ucnv_err.h"
#include "third_party/icu/source/common/unicode/unorm.h"
#include "third_party/icu/source/common/unicode/ustring.h"

namespace base {

namespace {
// ToUnicodeCallbackSubstitute() is based on UCNV_TO_U_CALLBACK_SUBSTITUTE
// in source/common/ucnv_err.c.

// Copyright (c) 1995-2006 International Business Machines Corporation
// and others
//
// All rights reserved.
//

// Permission is hereby granted, free of charge, to any person obtaining a
// copy of this software and associated documentation files (the "Software"),
// to deal in the Software without restriction, including without limitation
// the rights to use, copy, modify, merge, publish, distribute, and/or
// sell copies of the Software, and to permit persons to whom the Software
// is furnished to do so, provided that the above copyright notice(s) and
// this permission notice appear in all copies of the Software and that
// both the above copyright notice(s) and this permission notice appear in
// supporting documentation.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
// OF THIRD PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS
// INCLUDED IN THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT
// OR CONSEQUENTIAL DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS
// OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE
// OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE
// OR PERFORMANCE OF THIS SOFTWARE.
//
// Except as contained in this notice, the name of a copyright holder
// shall not be used in advertising or otherwise to promote the sale, use
// or other dealings in this Software without prior written authorization
// of the copyright holder.

//  ___________________________________________________________________________
//
// All trademarks and registered trademarks mentioned herein are the property
// of their respective owners.

void ToUnicodeCallbackSubstitute(const void* context,
                                 UConverterToUnicodeArgs *to_args,
                                 const char* code_units,
                                 int32_t length,
                                 UConverterCallbackReason reason,
                                 UErrorCode * err) {
  static const UChar kReplacementChar = 0xFFFD;
  if (reason <= UCNV_IRREGULAR) {
      if (context == NULL ||
          (*(reinterpret_cast<const char*>(context)) == 'i' &&
           reason == UCNV_UNASSIGNED)) {
        *err = U_ZERO_ERROR;
        ucnv_cbToUWriteUChars(to_args, &kReplacementChar, 1, 0, err);
      }
      // else the caller must have set the error code accordingly.
  }
  // else ignore the reset, close and clone calls.
}

bool ConvertFromUTF16(UConverter* converter, const UChar* uchar_src,
                      int uchar_len, OnStringConversionError::Type on_error,
                      std::string* encoded) {
  int encoded_max_length = UCNV_GET_MAX_BYTES_FOR_STRING(uchar_len,
      ucnv_getMaxCharSize(converter));
  encoded->resize(encoded_max_length);

  UErrorCode status = U_ZERO_ERROR;

  // Setup our error handler.
  switch (on_error) {
    case OnStringConversionError::FAIL:
      ucnv_setFromUCallBack(converter, UCNV_FROM_U_CALLBACK_STOP, 0,
                            NULL, NULL, &status);
      break;
    case OnStringConversionError::SKIP:
    case OnStringConversionError::SUBSTITUTE:
      ucnv_setFromUCallBack(converter, UCNV_FROM_U_CALLBACK_SKIP, 0,
                            NULL, NULL, &status);
      break;
    default:
      NOTREACHED();
  }

  // ucnv_fromUChars returns size not including terminating null
  int actual_size = ucnv_fromUChars(converter, &(*encoded)[0],
      encoded_max_length, uchar_src, uchar_len, &status);
  encoded->resize(actual_size);
  ucnv_close(converter);
  if (U_SUCCESS(status))
    return true;
  encoded->clear();  // Make sure the output is empty on error.
  return false;
}

// Set up our error handler for ToUTF-16 converters
void SetUpErrorHandlerForToUChars(OnStringConversionError::Type on_error,
                                  UConverter* converter, UErrorCode* status) {
  switch (on_error) {
    case OnStringConversionError::FAIL:
      ucnv_setToUCallBack(converter, UCNV_TO_U_CALLBACK_STOP, 0,
                          NULL, NULL, status);
      break;
    case OnStringConversionError::SKIP:
      ucnv_setToUCallBack(converter, UCNV_TO_U_CALLBACK_SKIP, 0,
                          NULL, NULL, status);
      break;
    case OnStringConversionError::SUBSTITUTE:
      ucnv_setToUCallBack(converter, ToUnicodeCallbackSubstitute, 0,
                          NULL, NULL, status);
      break;
    default:
      NOTREACHED();
  }
}

}  // namespace

// Codepage <-> Wide/UTF-16  ---------------------------------------------------

bool UTF16ToCodepage(const string16& utf16,
                     const char* codepage_name,
                     OnStringConversionError::Type on_error,
                     std::string* encoded) {
  encoded->clear();

  UErrorCode status = U_ZERO_ERROR;
  UConverter* converter = ucnv_open(codepage_name, &status);
  if (!U_SUCCESS(status))
    return false;

  return ConvertFromUTF16(converter, utf16.c_str(),
                          static_cast<int>(utf16.length()), on_error, encoded);
}

bool CodepageToUTF16(const std::string& encoded,
                     const char* codepage_name,
                     OnStringConversionError::Type on_error,
                     string16* utf16) {
  utf16->clear();

  UErrorCode status = U_ZERO_ERROR;
  UConverter* converter = ucnv_open(codepage_name, &status);
  if (!U_SUCCESS(status))
    return false;

  // Even in the worst case, the maximum length in 2-byte units of UTF-16
  // output would be at most the same as the number of bytes in input. There
  // is no single-byte encoding in which a character is mapped to a
  // non-BMP character requiring two 2-byte units.
  //
  // Moreover, non-BMP characters in legacy multibyte encodings
  // (e.g. EUC-JP, GB18030) take at least 2 bytes. The only exceptions are
  // BOCU and SCSU, but we don't care about them.
  size_t uchar_max_length = encoded.length() + 1;

  SetUpErrorHandlerForToUChars(on_error, converter, &status);
  scoped_ptr<char16[]> buffer(new char16[uchar_max_length]);
  int actual_size = ucnv_toUChars(converter, buffer.get(),
      static_cast<int>(uchar_max_length), encoded.data(),
      static_cast<int>(encoded.length()), &status);
  ucnv_close(converter);
  if (!U_SUCCESS(status)) {
    utf16->clear();  // Make sure the output is empty on error.
    return false;
  }

  utf16->assign(buffer.get(), actual_size);
  return true;
}

bool ConvertToUtf8AndNormalize(const std::string& text,
                               const std::string& charset,
                               std::string* result) {
  result->clear();
  string16 utf16;
  if (!CodepageToUTF16(
      text, charset.c_str(), OnStringConversionError::FAIL, &utf16))
    return false;

  UErrorCode status = U_ZERO_ERROR;
  size_t max_length = utf16.length() + 1;
  string16 normalized_utf16;
  scoped_ptr<char16[]> buffer(new char16[max_length]);
  int actual_length = unorm_normalize(
      utf16.c_str(), utf16.length(), UNORM_NFC, 0,
      buffer.get(), static_cast<int>(max_length), &status);
  if (!U_SUCCESS(status))
    return false;
  normalized_utf16.assign(buffer.get(), actual_length);

  return UTF16ToUTF8(normalized_utf16.data(),
                     normalized_utf16.length(), result);
}

}  // namespace base
