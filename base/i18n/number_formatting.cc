// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/number_formatting.h"

#include "base/format_macros.h"
#include "base/lazy_instance.h"
#include "base/logging.h"
#include "base/memory/scoped_ptr.h"
#include "base/strings/string_util.h"
#include "base/strings/stringprintf.h"
#include "base/strings/utf_string_conversions.h"
#include "third_party/icu/source/common/unicode/ustring.h"
#include "third_party/icu/source/i18n/unicode/numfmt.h"

namespace base {

namespace {

// A simple wrapper around icu::NumberFormat that allows for resetting it
// (as LazyInstance does not).
struct NumberFormatWrapper {
  NumberFormatWrapper() {
    Reset();
  }

  void Reset() {
    // There's no ICU call to destroy a NumberFormat object other than
    // operator delete, so use the default Delete, which calls operator delete.
    // This can cause problems if a different allocator is used by this file
    // than by ICU.
    UErrorCode status = U_ZERO_ERROR;
    number_format.reset(icu::NumberFormat::createInstance(status));
    DCHECK(U_SUCCESS(status));
  }

  scoped_ptr<icu::NumberFormat> number_format;
};

LazyInstance<NumberFormatWrapper> g_number_format_int =
    LAZY_INSTANCE_INITIALIZER;
LazyInstance<NumberFormatWrapper> g_number_format_float =
    LAZY_INSTANCE_INITIALIZER;

}  // namespace

string16 FormatNumber(int64 number) {
  icu::NumberFormat* number_format =
      g_number_format_int.Get().number_format.get();

  if (!number_format) {
    // As a fallback, just return the raw number in a string.
    return UTF8ToUTF16(StringPrintf("%" PRId64, number));
  }
  icu::UnicodeString ustr;
  number_format->format(number, ustr);

  return string16(ustr.getBuffer(), static_cast<size_t>(ustr.length()));
}

string16 FormatDouble(double number, int fractional_digits) {
  icu::NumberFormat* number_format =
      g_number_format_float.Get().number_format.get();

  if (!number_format) {
    // As a fallback, just return the raw number in a string.
    return UTF8ToUTF16(StringPrintf("%f", number));
  }
  number_format->setMaximumFractionDigits(fractional_digits);
  number_format->setMinimumFractionDigits(fractional_digits);
  icu::UnicodeString ustr;
  number_format->format(number, ustr);

  return string16(ustr.getBuffer(), static_cast<size_t>(ustr.length()));
}

namespace testing {

void ResetFormatters() {
  g_number_format_int.Get().Reset();
  g_number_format_float.Get().Reset();
}

}  // namespace testing

}  // namespace base
