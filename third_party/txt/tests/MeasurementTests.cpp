/*
 * Copyright (C) 2017 The Android Open Source Project
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

#include <gtest/gtest.h>
#include <minikin/Measurement.h>
#include "UnicodeUtils.h"

namespace minikin {

float getAdvance(const float* advances, const char* src) {
  const size_t BUF_SIZE = 256;
  uint16_t buf[BUF_SIZE];
  size_t offset;
  size_t size;
  ParseUnicode(buf, BUF_SIZE, src, &size, &offset);
  return getRunAdvance(advances, buf, 0, size, offset);
}

// Latin fi
TEST(Measurement, getRunAdvance_fi) {
  const float unligated[] = {30.0, 20.0};
  EXPECT_EQ(0.0, getAdvance(unligated, "| 'f' 'i'"));
  EXPECT_EQ(30.0, getAdvance(unligated, "'f' | 'i'"));
  EXPECT_EQ(50.0, getAdvance(unligated, "'f' 'i' |"));

  const float ligated[] = {40.0, 0.0};
  EXPECT_EQ(0.0, getAdvance(ligated, "| 'f' 'i'"));
  EXPECT_EQ(20.0, getAdvance(ligated, "'f' | 'i'"));
  EXPECT_EQ(40.0, getAdvance(ligated, "'f' 'i' |"));
}

// Devanagari ka+virama+ka
TEST(Measurement, getRunAdvance_kka) {
  const float unligated[] = {30.0, 0.0, 30.0};
  EXPECT_EQ(0.0, getAdvance(unligated, "| U+0915 U+094D U+0915"));
  EXPECT_EQ(30.0, getAdvance(unligated, "U+0915 | U+094D U+0915"));
  EXPECT_EQ(30.0, getAdvance(unligated, "U+0915 U+094D | U+0915"));
  EXPECT_EQ(60.0, getAdvance(unligated, "U+0915 U+094D U+0915 |"));

  const float ligated[] = {30.0, 0.0, 0.0};
  EXPECT_EQ(0.0, getAdvance(ligated, "| U+0915 U+094D U+0915"));
  EXPECT_EQ(30.0, getAdvance(ligated, "U+0915 | U+094D U+0915"));
  EXPECT_EQ(30.0, getAdvance(ligated, "U+0915 U+094D | U+0915"));
  EXPECT_EQ(30.0, getAdvance(ligated, "U+0915 U+094D U+0915 |"));
}

}  // namespace minikin
