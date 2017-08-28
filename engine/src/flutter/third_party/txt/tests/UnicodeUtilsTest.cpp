/*
 * Copyright (C) 2016 The Android Open Source Project
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

#include "UnicodeUtils.h"

namespace minikin {

TEST(UnicodeUtils, parse) {
  const size_t BUF_SIZE = 256;
  uint16_t buf[BUF_SIZE];
  size_t offset;
  size_t size;
  ParseUnicode(buf, BUF_SIZE, "U+000D U+1F431 | 'a'", &size, &offset);
  EXPECT_EQ(size, 4u);
  EXPECT_EQ(offset, 3u);
  EXPECT_EQ(buf[0], 0x000D);
  EXPECT_EQ(buf[1], 0xD83D);
  EXPECT_EQ(buf[2], 0xDC31);
  EXPECT_EQ(buf[3], 'a');
}

}  // namespace minikin
