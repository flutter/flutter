// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/bidi_line_iterator.h"

#include "base/logging.h"

namespace base {
namespace i18n {

BiDiLineIterator::BiDiLineIterator() : bidi_(NULL) {
}

BiDiLineIterator::~BiDiLineIterator() {
  if (bidi_) {
    ubidi_close(bidi_);
    bidi_ = NULL;
  }
}

bool BiDiLineIterator::Open(const string16& text, bool right_to_left) {
  DCHECK(!bidi_);
  UErrorCode error = U_ZERO_ERROR;
  bidi_ = ubidi_openSized(static_cast<int>(text.length()), 0, &error);
  if (U_FAILURE(error))
    return false;
  ubidi_setPara(bidi_, text.data(), static_cast<int>(text.length()),
                right_to_left ? UBIDI_DEFAULT_RTL : UBIDI_DEFAULT_LTR,
                NULL, &error);
  return (U_SUCCESS(error) == TRUE);
}

int BiDiLineIterator::CountRuns() {
  DCHECK(bidi_ != NULL);
  UErrorCode error = U_ZERO_ERROR;
  const int runs = ubidi_countRuns(bidi_, &error);
  return U_SUCCESS(error) ? runs : 0;
}

UBiDiDirection BiDiLineIterator::GetVisualRun(int index,
                                              int* start,
                                              int* length) {
  DCHECK(bidi_ != NULL);
  return ubidi_getVisualRun(bidi_, index, start, length);
}

void BiDiLineIterator::GetLogicalRun(int start,
                                     int* end,
                                     UBiDiLevel* level) {
  DCHECK(bidi_ != NULL);
  ubidi_getLogicalRun(bidi_, start, end, level);
}

}  // namespace i18n
}  // namespace base
