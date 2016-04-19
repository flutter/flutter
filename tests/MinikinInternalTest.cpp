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

#include "MinikinInternal.h"

namespace android {

TEST(MinikinInternalTest, isEmojiTest) {
    EXPECT_TRUE(isEmoji(0x0023));  // NUMBER SIGN
    EXPECT_TRUE(isEmoji(0x0035));  // DIGIT FIVE
    EXPECT_TRUE(isEmoji(0x1F0CF));  // PLAYING CARD BLACK JOKER
    EXPECT_TRUE(isEmoji(0x1F1E9));  // REGIONAL INDICATOR SYMBOL LETTER D

    EXPECT_FALSE(isEmoji(0x0000));  // <control>
    EXPECT_FALSE(isEmoji(0x0061));  // LATIN SMALL LETTER A
    EXPECT_FALSE(isEmoji(0x29E3D));  // A han character.
}

}  // namespace android
