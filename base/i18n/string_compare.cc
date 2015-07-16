// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/string_compare.h"

#include "base/logging.h"
#include "base/strings/utf_string_conversions.h"

namespace base {
namespace i18n {

// Compares the character data stored in two different string16 strings by
// specified Collator instance.
UCollationResult CompareString16WithCollator(const icu::Collator& collator,
                                             const string16& lhs,
                                             const string16& rhs) {
  UErrorCode error = U_ZERO_ERROR;
  UCollationResult result = collator.compare(
      static_cast<const UChar*>(lhs.c_str()), static_cast<int>(lhs.length()),
      static_cast<const UChar*>(rhs.c_str()), static_cast<int>(rhs.length()),
      error);
  DCHECK(U_SUCCESS(error));
  return result;
}

}  // namespace i18n
}  // namespace base
