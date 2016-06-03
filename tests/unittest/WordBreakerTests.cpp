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

#define UTF16(codepoint) U16_LEAD(codepoint), U16_TRAIL(codepoint)

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
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ(6, breaker.current());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(6, breaker.wordStart());  // "world"
    EXPECT_EQ(11, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
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
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(7, breaker.wordStart());  // "world"
    EXPECT_EQ(12, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, postfixAndPrefix) {
    uint16_t buf[] = {'U', 'S', 0x00A2, ' ', 'J', 'P', 0x00A5}; // US¢ JP¥
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());

    EXPECT_EQ(4, breaker.next());  // after CENT SIGN
    EXPECT_EQ(0, breaker.wordStart());  // "US¢"
    EXPECT_EQ(3, breaker.wordEnd());

    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end of string
    EXPECT_EQ(4, breaker.wordStart());  // "JP¥"
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.wordEnd());
}

TEST_F(WordBreakerTest, MyanmarKinzi) {
    uint16_t buf[] = {0x1004, 0x103A, 0x1039, 0x1000, 0x102C};  // NGA, ASAT, VIRAMA, KA, UU
    WordBreaker breaker;
    icu::Locale burmese("my");
    breaker.setLocale(burmese);
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());

    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end of string
    EXPECT_EQ(0, breaker.wordStart());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.wordEnd());
}

TEST_F(WordBreakerTest, zwjEmojiSequences) {
    uint16_t buf[] = {
        // man + zwj + heart + zwj + man
        UTF16(0x1F468), 0x200D, 0x2764, 0x200D, UTF16(0x1F468),
        // woman + zwj + heart + zwj + kiss mark + zwj + woman
        UTF16(0x1F469), 0x200D, 0x2764, 0x200D, UTF16(0x1F48B), 0x200D, UTF16(0x1F469),
        // eye + zwj + left speech bubble
        UTF16(0x1F441), 0x200D, UTF16(0x1F5E8),
        // CAT FACE + zwj + BUST IN SILHOUETTE
        UTF16(0x1F431), 0x200D, UTF16(0x1F464),
    };
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(7, breaker.next());  // after man + zwj + heart + zwj + man
    EXPECT_EQ(0, breaker.wordStart());
    EXPECT_EQ(7, breaker.wordEnd());
    EXPECT_EQ(17, breaker.next());  // after woman + zwj + heart + zwj + woman
    EXPECT_EQ(7, breaker.wordStart());
    EXPECT_EQ(17, breaker.wordEnd());
    EXPECT_EQ(22, breaker.next());  // after eye + zwj + left speech bubble
    EXPECT_EQ(17, breaker.wordStart());
    EXPECT_EQ(22, breaker.wordEnd());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(22, breaker.wordStart());
    EXPECT_EQ(27, breaker.wordEnd());
}

TEST_F(WordBreakerTest, emojiWithModifier) {
    uint16_t buf[] = {
        UTF16(0x1F466), UTF16(0x1F3FB),  // boy + type 1-2 fitzpatrick modifier
        0x270C, 0xFE0F, UTF16(0x1F3FF)  // victory hand + emoji style + type 6 fitzpatrick modifier
    };
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(4, breaker.next());  // after man + type 6 fitzpatrick modifier
    EXPECT_EQ(0, breaker.wordStart());
    EXPECT_EQ(4, breaker.wordEnd());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(4, breaker.wordStart());
    EXPECT_EQ(8, breaker.wordEnd());
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
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(9, breaker.wordStart());  // "world"
    EXPECT_EQ(14, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, email) {
    uint16_t buf[] = {'f', 'o', 'o', '@', 'e', 'x', 'a', 'm', 'p', 'l', 'e', '.', 'c', 'o', 'm',
        ' ', 'x'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(11, breaker.next());  // after "foo@example"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(16, breaker.next());  // after ".com "
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(16, breaker.wordStart());  // "x"
    EXPECT_EQ(17, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, mailto) {
    uint16_t buf[] = {'m', 'a', 'i', 'l', 't', 'o', ':', 'f', 'o', 'o', '@',
        'e', 'x', 'a', 'm', 'p', 'l', 'e', '.', 'c', 'o', 'm', ' ', 'x'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(7, breaker.next());  // after "mailto:"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(18, breaker.next());  // after "foo@example"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(23, breaker.next());  // after ".com "
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(23, breaker.wordStart());  // "x"
    EXPECT_EQ(24, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

// The current logic always places a line break after a detected email address or URL
// and an immediately following non-ASCII character.
TEST_F(WordBreakerTest, emailNonAscii) {
    uint16_t buf[] = {'f', 'o', 'o', '@', 'e', 'x', 'a', 'm', 'p', 'l', 'e', '.', 'c', 'o', 'm',
        0x4E00};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(11, breaker.next());  // after "foo@example"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(15, breaker.next());  // after ".com"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(15, breaker.wordStart());  // "一"
    EXPECT_EQ(16, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, emailCombining) {
    uint16_t buf[] = {'f', 'o', 'o', '@', 'e', 'x', 'a', 'm', 'p', 'l', 'e', '.', 'c', 'o', 'm',
        0x0303, ' ', 'x'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(11, breaker.next());  // after "foo@example"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(17, breaker.next());  // after ".com̃ "
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(17, breaker.wordStart());  // "x"
    EXPECT_EQ(18, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, lonelyAt) {
    uint16_t buf[] = {'a', ' ', '@', ' ', 'b'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(2, breaker.next());  // after "a "
    EXPECT_EQ(0, breaker.wordStart());  // "a"
    EXPECT_EQ(1, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ(4, breaker.next());  // after "@ "
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(4, breaker.wordStart());  // "b"
    EXPECT_EQ(5, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, url) {
    uint16_t buf[] = {'h', 't', 't', 'p', ':', '/', '/', 'e', 'x', 'a', 'm', 'p', 'l', 'e',
        '.', 'c', 'o', 'm', ' ', 'x'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(5, breaker.next());  // after "http:"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(7, breaker.next());  // after "//"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(14, breaker.next());  // after "example"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(19, breaker.next());  // after ".com "
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_EQ(19, breaker.wordStart());  // "x"
    EXPECT_EQ(20, breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

// Breaks according to section 14.12 of Chicago Manual of Style, *URLs or DOIs and line breaks*
TEST_F(WordBreakerTest, urlBreakChars) {
    uint16_t buf[] = {'h', 't', 't', 'p', ':', '/', '/', 'a', '.', 'b', '/', '~', 'c', ',', 'd',
        '-', 'e', '?', 'f', '=', 'g', '&', 'h', '#', 'i', '%', 'j', '_', 'k', '/', 'l'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(5, breaker.next());  // after "http:"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(7, breaker.next());  // after "//"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(8, breaker.next());  // after "a"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(10, breaker.next());  // after ".b"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(11, breaker.next());  // after "/"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(13, breaker.next());  // after "~c"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(15, breaker.next());  // after ",d"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(17, breaker.next());  // after "-e"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(19, breaker.next());  // after "?f"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(20, breaker.next());  // after "="
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(21, breaker.next());  // after "g"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(22, breaker.next());  // after "&"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(23, breaker.next());  // after "h"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(25, breaker.next());  // after "#i"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(27, breaker.next());  // after "%j"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ(29, breaker.next());  // after "_k"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(1, breaker.breakBadness());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(0, breaker.breakBadness());
}

TEST_F(WordBreakerTest, urlNoHyphenBreak) {
    uint16_t buf[] = {'h', 't', 't', 'p', ':', '/', '/', 'a', '-', '/', 'b'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(5, breaker.next());  // after "http:"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(7, breaker.next());  // after "//"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(8, breaker.next());  // after "a"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
}

TEST_F(WordBreakerTest, urlEndsWithSlash) {
    uint16_t buf[] = {'h', 't', 't', 'p', ':', '/', '/', 'a', '/'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ(5, breaker.next());  // after "http:"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(7, breaker.next());  // after "//"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ(8, breaker.next());  // after "a"
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
}

TEST_F(WordBreakerTest, emailStartsWithSlash) {
    uint16_t buf[] = {'/', 'a', '@', 'b'};
    WordBreaker breaker;
    breaker.setLocale(icu::Locale::getEnglish());
    breaker.setText(buf, NELEM(buf));
    EXPECT_EQ(0, breaker.current());
    EXPECT_EQ((ssize_t)NELEM(buf), breaker.next());  // end
    EXPECT_TRUE(breaker.wordStart() >= breaker.wordEnd());
}
