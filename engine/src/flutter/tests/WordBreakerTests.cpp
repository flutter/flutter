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

#include <gtest/gtest.h>
#include "ICUTestBase.h"
#include "UnicodeUtils.h"
#include <minikin/WordBreaker.h>
#include <unicode/locid.h>
#include <unicode/uclean.h>
#include <unicode/udata.h>

#define LOG_TAG "Minikin"
#include <cutils/log.h>

#ifndef NELEM
#define NELEM(x) ((sizeof(x) / sizeof((x)[0])))
#endif

using namespace android;

typedef ICUTestBase WordBreakerTest;

TEST_F(WordBreakerTest, basic) {
    uint16_t buf[] = {'h', 'e', 'l', 'l' ,'o', ' ', 'w', 'o', 'r', 'l', 'd'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(6, breaker.next());  // after "hello "
    EXPECT_EQ(0, breaker.wordStart());  // "hello"
    EXPECT_EQ(5, breaker.wordEnd());
    EXPECT_EQ(6, breaker.current());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(6, breaker.wordStart());  // "world"
    EXPECT_EQ(11, breaker.wordEnd());
    EXPECT_EQ(11, breaker.current());
}

TEST_F(WordBreakerTest, softHyphen) {
    uint16_t buf[] = {'h', 'e', 'l', 0x00AD, 'l' ,'o', ' ', 'w', 'o', 'r', 'l', 'd'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(7, breaker.next());  // after "hel{SOFT HYPHEN}lo "
    EXPECT_EQ(0, breaker.wordStart());  // "hel{SOFT HYPHEN}lo"
    EXPECT_EQ(6, breaker.wordEnd());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(7, breaker.wordStart());  // "world"
    EXPECT_EQ(12, breaker.wordEnd());
}

TEST_F(WordBreakerTest, punct) {
    uint16_t buf[] = {0x00A1, 0x00A1, 'h', 'e', 'l', 'l' ,'o', ',', ' ', 'w', 'o', 'r', 'l', 'd',
        '!', '!'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(9, breaker.next());  // after "¡¡hello, "
    EXPECT_EQ(2, breaker.wordStart());  // "hello"
    EXPECT_EQ(7, breaker.wordEnd());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(9, breaker.wordStart());  // "world"
    EXPECT_EQ(14, breaker.wordEnd());
}
