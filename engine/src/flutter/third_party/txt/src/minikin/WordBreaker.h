/*
 * Copyright (C) 2015 The Android Open Source Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/**
 * A wrapper around ICU's line break iterator, that gives customized line
 * break opportunities, as well as identifying words for the purpose of
 * hyphenation.
 */

#ifndef MINIKIN_WORD_BREAKER_H
#define MINIKIN_WORD_BREAKER_H

#include <memory>
#include "unicode/brkiter.h"
#include "utils/WindowsUtils.h"

namespace minikin {

class WordBreaker {
 public:
  ~WordBreaker() { finish(); }

  // libtxt extension: always use the default locale so that a cached instance
  // of the ICU break iterator can be reused.
  void setLocale();

  void setText(const uint16_t* data, size_t size);

  // Advance iterator to next word break. Return offset, or -1 if EOT
  ssize_t next();

  // Current offset of iterator, equal to 0 at BOT or last return from next()
  ssize_t current() const;

  // After calling next(), wordStart() and wordEnd() are offsets defining the
  // previous word. If wordEnd <= wordStart, it's not a word for the purpose of
  // hyphenation.
  ssize_t wordStart() const;

  ssize_t wordEnd() const;

  int breakBadness() const;

  void finish();

 private:
  int32_t iteratorNext();
  void detectEmailOrUrl();
  ssize_t findNextBreakInEmailOrUrl();

  std::unique_ptr<icu::BreakIterator> mBreakIterator;
  UText mUText = UTEXT_INITIALIZER;
  const uint16_t* mText = nullptr;
  size_t mTextSize;
  ssize_t mLast;
  ssize_t mCurrent;
  bool mIteratorWasReset;

  // state for the email address / url detector
  ssize_t mScanOffset;
  bool mInEmailOrUrl;
};

}  // namespace minikin

#endif  // MINIKIN_WORD_BREAKER_H
