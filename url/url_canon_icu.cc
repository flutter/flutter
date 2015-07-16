// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ICU integration functions.

#include <stdlib.h>
#include <string.h>

#include "base/lazy_instance.h"
#include "base/logging.h"
#include "third_party/icu/source/common/unicode/ucnv.h"
#include "third_party/icu/source/common/unicode/ucnv_cb.h"
#include "third_party/icu/source/common/unicode/uidna.h"
#include "url/url_canon_icu.h"
#include "url/url_canon_internal.h"  // for _itoa_s

namespace url {

namespace {

// Called when converting a character that can not be represented, this will
// append an escaped version of the numerical character reference for that code
// point. It is of the form "&#1234;" and we will escape the non-digits to
// "%26%231234%3B". Why? This is what Netscape did back in the olden days.
void appendURLEscapedChar(const void* context,
                          UConverterFromUnicodeArgs* from_args,
                          const UChar* code_units,
                          int32_t length,
                          UChar32 code_point,
                          UConverterCallbackReason reason,
                          UErrorCode* err) {
  if (reason == UCNV_UNASSIGNED) {
    *err = U_ZERO_ERROR;

    const static int prefix_len = 6;
    const static char prefix[prefix_len + 1] = "%26%23";  // "&#" percent-escaped
    ucnv_cbFromUWriteBytes(from_args, prefix, prefix_len, 0, err);

    DCHECK(code_point < 0x110000);
    char number[8];  // Max Unicode code point is 7 digits.
    _itoa_s(code_point, number, 10);
    int number_len = static_cast<int>(strlen(number));
    ucnv_cbFromUWriteBytes(from_args, number, number_len, 0, err);

    const static int postfix_len = 3;
    const static char postfix[postfix_len + 1] = "%3B";   // ";" percent-escaped
    ucnv_cbFromUWriteBytes(from_args, postfix, postfix_len, 0, err);
  }
}

// A class for scoping the installation of the invalid character callback.
class AppendHandlerInstaller {
 public:
  // The owner of this object must ensure that the converter is alive for the
  // duration of this object's lifetime.
  AppendHandlerInstaller(UConverter* converter) : converter_(converter) {
    UErrorCode err = U_ZERO_ERROR;
    ucnv_setFromUCallBack(converter_, appendURLEscapedChar, 0,
                          &old_callback_, &old_context_, &err);
  }

  ~AppendHandlerInstaller() {
    UErrorCode err = U_ZERO_ERROR;
    ucnv_setFromUCallBack(converter_, old_callback_, old_context_, 0, 0, &err);
  }

 private:
  UConverter* converter_;

  UConverterFromUCallback old_callback_;
  const void* old_context_;
};

// A wrapper to use LazyInstance<>::Leaky with ICU's UIDNA, a C pointer to
// a UTS46/IDNA 2008 handling object opened with uidna_openUTS46().
//
// We use UTS46 with BiDiCheck to migrate from IDNA 2003 (with unassigned
// code points allowed) to IDNA 2008 with
// the backward compatibility in mind. What it does:
//
// 1. Use the up-to-date Unicode data.
// 2. Define a case folding/mapping with the up-to-date Unicode data as
//    in IDNA 2003.
// 3. Use transitional mechanism for 4 deviation characters (sharp-s,
//    final sigma, ZWJ and ZWNJ) for now.
// 4. Continue to allow symbols and punctuations.
// 5. Apply new BiDi check rules more permissive than the IDNA 2003 BiDI rules.
// 6. Do not apply STD3 rules
// 7. Do not allow unassigned code points.
//
// It also closely matches what IE 10 does except for the BiDi check (
// http://goo.gl/3XBhqw ).
// See http://http://unicode.org/reports/tr46/ and references therein
// for more details.
struct UIDNAWrapper {
  UIDNAWrapper() {
    UErrorCode err = U_ZERO_ERROR;
    // TODO(jungshik): Change options as different parties (browsers,
    // registrars, search engines) converge toward a consensus.
    value = uidna_openUTS46(UIDNA_CHECK_BIDI, &err);
    if (U_FAILURE(err))
      value = NULL;
  }

  UIDNA* value;
};

}  // namespace

ICUCharsetConverter::ICUCharsetConverter(UConverter* converter)
    : converter_(converter) {
}

ICUCharsetConverter::~ICUCharsetConverter() {
}

void ICUCharsetConverter::ConvertFromUTF16(const base::char16* input,
                                           int input_len,
                                           CanonOutput* output) {
  // Install our error handler. It will be called for character that can not
  // be represented in the destination character set.
  AppendHandlerInstaller handler(converter_);

  int begin_offset = output->length();
  int dest_capacity = output->capacity() - begin_offset;
  output->set_length(output->length());

  do {
    UErrorCode err = U_ZERO_ERROR;
    char* dest = &output->data()[begin_offset];
    int required_capacity = ucnv_fromUChars(converter_, dest, dest_capacity,
                                            input, input_len, &err);
    if (err != U_BUFFER_OVERFLOW_ERROR) {
      output->set_length(begin_offset + required_capacity);
      return;
    }

    // Output didn't fit, expand
    dest_capacity = required_capacity;
    output->Resize(begin_offset + dest_capacity);
  } while (true);
}

static base::LazyInstance<UIDNAWrapper>::Leaky
    g_uidna = LAZY_INSTANCE_INITIALIZER;

// Converts the Unicode input representing a hostname to ASCII using IDN rules.
// The output must be ASCII, but is represented as wide characters.
//
// On success, the output will be filled with the ASCII host name and it will
// return true. Unlike most other canonicalization functions, this assumes that
// the output is empty. The beginning of the host will be at offset 0, and
// the length of the output will be set to the length of the new host name.
//
// On error, this will return false. The output in this case is undefined.
// TODO(jungshik): use UTF-8/ASCII version of nameToASCII.
// Change the function signature and callers accordingly to avoid unnecessary
// conversions in our code. In addition, consider using icu::IDNA's UTF-8/ASCII
// version with StringByteSink. That way, we can avoid C wrappers and additional
// string conversion.
bool IDNToASCII(const base::char16* src, int src_len, CanonOutputW* output) {
  DCHECK(output->length() == 0);  // Output buffer is assumed empty.

  UIDNA* uidna = g_uidna.Get().value;
  DCHECK(uidna != NULL);
  while (true) {
    UErrorCode err = U_ZERO_ERROR;
    UIDNAInfo info = UIDNA_INFO_INITIALIZER;
    int output_length = uidna_nameToASCII(uidna, src, src_len, output->data(),
                                          output->capacity(), &info, &err);
    if (U_SUCCESS(err) && info.errors == 0) {
      output->set_length(output_length);
      return true;
    }

    // TODO(jungshik): Look at info.errors to handle them case-by-case basis
    // if necessary.
    if (err != U_BUFFER_OVERFLOW_ERROR || info.errors != 0)
      return false;  // Unknown error, give up.

    // Not enough room in our buffer, expand.
    output->Resize(output_length);
  }
}

}  // namespace url
