// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/break_iterator.h"

#include "base/logging.h"
#include "third_party/icu/source/common/unicode/ubrk.h"
#include "third_party/icu/source/common/unicode/uchar.h"
#include "third_party/icu/source/common/unicode/ustring.h"

namespace base {
namespace i18n {

const size_t npos = static_cast<size_t>(-1);

BreakIterator::BreakIterator(const StringPiece16& str, BreakType break_type)
    : iter_(NULL),
      string_(str),
      break_type_(break_type),
      prev_(npos),
      pos_(0) {
}

BreakIterator::BreakIterator(const StringPiece16& str, const string16& rules)
    : iter_(NULL),
      string_(str),
      rules_(rules),
      break_type_(RULE_BASED),
      prev_(npos),
      pos_(0) {
}

BreakIterator::~BreakIterator() {
  if (iter_)
    ubrk_close(static_cast<UBreakIterator*>(iter_));
}

bool BreakIterator::Init() {
  UErrorCode status = U_ZERO_ERROR;
  UParseError parse_error;
  UBreakIteratorType break_type;
  switch (break_type_) {
    case BREAK_CHARACTER:
      break_type = UBRK_CHARACTER;
      break;
    case BREAK_WORD:
      break_type = UBRK_WORD;
      break;
    case BREAK_LINE:
    case BREAK_NEWLINE:
    case RULE_BASED: // (Keep compiler happy, break_type not used in this case)
      break_type = UBRK_LINE;
      break;
    default:
      NOTREACHED() << "invalid break_type_";
      return false;
  }
  if (break_type_ == RULE_BASED) {
    iter_ = ubrk_openRules(rules_.c_str(),
                           static_cast<int32_t>(rules_.length()),
                           string_.data(),
                           static_cast<int32_t>(string_.size()),
                           &parse_error,
                           &status);
    if (U_FAILURE(status)) {
      NOTREACHED() << "ubrk_openRules failed to parse rule string at line "
          << parse_error.line << ", offset " << parse_error.offset;
    }
  } else {
    iter_ = ubrk_open(break_type,
                      NULL,
                      string_.data(),
                      static_cast<int32_t>(string_.size()),
                      &status);
    if (U_FAILURE(status)) {
      NOTREACHED() << "ubrk_open failed for type " << break_type
          << " with error " << status;
    }
  }

  if (U_FAILURE(status)) {
    return false;
  }

  // Move the iterator to the beginning of the string.
  ubrk_first(static_cast<UBreakIterator*>(iter_));
  return true;
}

bool BreakIterator::Advance() {
  int32_t pos;
  int32_t status;
  prev_ = pos_;
  switch (break_type_) {
    case BREAK_CHARACTER:
    case BREAK_WORD:
    case BREAK_LINE:
    case RULE_BASED:
      pos = ubrk_next(static_cast<UBreakIterator*>(iter_));
      if (pos == UBRK_DONE) {
        pos_ = npos;
        return false;
      }
      pos_ = static_cast<size_t>(pos);
      return true;
    case BREAK_NEWLINE:
      do {
        pos = ubrk_next(static_cast<UBreakIterator*>(iter_));
        if (pos == UBRK_DONE)
          break;
        pos_ = static_cast<size_t>(pos);
        status = ubrk_getRuleStatus(static_cast<UBreakIterator*>(iter_));
      } while (status >= UBRK_LINE_SOFT && status < UBRK_LINE_SOFT_LIMIT);
      if (pos == UBRK_DONE && prev_ == pos_) {
        pos_ = npos;
        return false;
      }
      return true;
    default:
      NOTREACHED() << "invalid break_type_";
      return false;
  }
}

bool BreakIterator::SetText(const base::char16* text, const size_t length) {
  UErrorCode status = U_ZERO_ERROR;
  ubrk_setText(static_cast<UBreakIterator*>(iter_),
               text, length, &status);
  pos_ = 0;  // implicit when ubrk_setText is done
  prev_ = npos;
  if (U_FAILURE(status)) {
    NOTREACHED() << "ubrk_setText failed";
    return false;
  }
  string_ = StringPiece16(text, length);
  return true;
}

bool BreakIterator::IsWord() const {
  int32_t status = ubrk_getRuleStatus(static_cast<UBreakIterator*>(iter_));
  if (break_type_ != BREAK_WORD && break_type_ != RULE_BASED)
    return false;
  return status != UBRK_WORD_NONE;
}

bool BreakIterator::IsEndOfWord(size_t position) const {
  if (break_type_ != BREAK_WORD && break_type_ != RULE_BASED)
    return false;

  UBreakIterator* iter = static_cast<UBreakIterator*>(iter_);
  UBool boundary = ubrk_isBoundary(iter, static_cast<int32_t>(position));
  int32_t status = ubrk_getRuleStatus(iter);
  return (!!boundary && status != UBRK_WORD_NONE);
}

bool BreakIterator::IsStartOfWord(size_t position) const {
  if (break_type_ != BREAK_WORD && break_type_ != RULE_BASED)
    return false;

  UBreakIterator* iter = static_cast<UBreakIterator*>(iter_);
  UBool boundary = ubrk_isBoundary(iter, static_cast<int32_t>(position));
  ubrk_next(iter);
  int32_t next_status = ubrk_getRuleStatus(iter);
  return (!!boundary && next_status != UBRK_WORD_NONE);
}

bool BreakIterator::IsGraphemeBoundary(size_t position) const {
  if (break_type_ != BREAK_CHARACTER)
    return false;

  UBreakIterator* iter = static_cast<UBreakIterator*>(iter_);
  return !!ubrk_isBoundary(iter, static_cast<int32_t>(position));
}

string16 BreakIterator::GetString() const {
  return GetStringPiece().as_string();
}

StringPiece16 BreakIterator::GetStringPiece() const {
  DCHECK(prev_ != npos && pos_ != npos);
  return string_.substr(prev_, pos_ - prev_);
}

}  // namespace i18n
}  // namespace base
