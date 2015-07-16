// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/string_search.h"
#include "base/logging.h"

#include "third_party/icu/source/i18n/unicode/usearch.h"

namespace base {
namespace i18n {

FixedPatternStringSearchIgnoringCaseAndAccents::
FixedPatternStringSearchIgnoringCaseAndAccents(const string16& find_this)
    : find_this_(find_this) {
  // usearch_open requires a valid string argument to be searched, even if we
  // want to set it by usearch_setText afterwards. So, supplying a dummy text.
  const string16& dummy = find_this_;

  UErrorCode status = U_ZERO_ERROR;
  search_ = usearch_open(find_this_.data(), find_this_.size(),
                         dummy.data(), dummy.size(),
                         uloc_getDefault(),
                         NULL,  // breakiter
                         &status);
  if (U_SUCCESS(status)) {
    UCollator* collator = usearch_getCollator(search_);
    ucol_setStrength(collator, UCOL_PRIMARY);
    usearch_reset(search_);
  }
}

FixedPatternStringSearchIgnoringCaseAndAccents::
~FixedPatternStringSearchIgnoringCaseAndAccents() {
  if (search_)
    usearch_close(search_);
}

bool FixedPatternStringSearchIgnoringCaseAndAccents::Search(
    const string16& in_this, size_t* match_index, size_t* match_length) {
  UErrorCode status = U_ZERO_ERROR;
  usearch_setText(search_, in_this.data(), in_this.size(), &status);

  // Default to basic substring search if usearch fails. According to
  // http://icu-project.org/apiref/icu4c/usearch_8h.html, usearch_open will fail
  // if either |find_this| or |in_this| are empty. In either case basic
  // substring search will give the correct return value.
  if (!U_SUCCESS(status)) {
    size_t index = in_this.find(find_this_);
    if (index == string16::npos) {
      return false;
    } else {
      if (match_index)
        *match_index = index;
      if (match_length)
        *match_length = find_this_.size();
      return true;
    }
  }

  int32_t index = usearch_first(search_, &status);
  if (!U_SUCCESS(status) || index == USEARCH_DONE)
    return false;
  if (match_index)
    *match_index = static_cast<size_t>(index);
  if (match_length)
    *match_length = static_cast<size_t>(usearch_getMatchedLength(search_));
  return true;
}

bool StringSearchIgnoringCaseAndAccents(const string16& find_this,
                                        const string16& in_this,
                                        size_t* match_index,
                                        size_t* match_length) {
  return FixedPatternStringSearchIgnoringCaseAndAccents(find_this).Search(
      in_this, match_index, match_length);
}

}  // namespace i18n
}  // namespace base
