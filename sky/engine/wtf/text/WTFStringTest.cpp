/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

#include <gtest/gtest.h>
#include <limits>
#include "flutter/sky/engine/wtf/MathExtras.h"
#include "flutter/sky/engine/wtf/text/CString.h"
#include "flutter/sky/engine/wtf/text/WTFString.h"

namespace {

TEST(WTF, StringCreationFromLiteral) {
  String stringFromLiteral("Explicit construction syntax");
  ASSERT_EQ(strlen("Explicit construction syntax"), stringFromLiteral.length());
  ASSERT_TRUE(stringFromLiteral == "Explicit construction syntax");
  ASSERT_TRUE(stringFromLiteral.is8Bit());
  ASSERT_TRUE(String("Explicit construction syntax") == stringFromLiteral);
}

TEST(WTF, StringASCII) {
  CString output;

  // Null String.
  output = String().ascii();
  ASSERT_STREQ("", output.data());

  // Empty String.
  output = emptyString().ascii();
  ASSERT_STREQ("", output.data());

  // Regular String.
  output = String("foobar").ascii();
  ASSERT_STREQ("foobar", output.data());
}

static void testNumberToStringECMAScript(double number, const char* reference) {
  CString numberString = String::numberToStringECMAScript(number).latin1();
  ASSERT_STREQ(reference, numberString.data());
}

TEST(WTF, StringNumberToStringECMAScriptBoundaries) {
  typedef std::numeric_limits<double> Limits;

  // Infinity.
  testNumberToStringECMAScript(Limits::infinity(), "Infinity");
  testNumberToStringECMAScript(-Limits::infinity(), "-Infinity");

  // NaN.
  testNumberToStringECMAScript(-Limits::quiet_NaN(), "NaN");

  // Zeros.
  testNumberToStringECMAScript(0, "0");
  testNumberToStringECMAScript(-0, "0");

  // Min-Max.
  testNumberToStringECMAScript(Limits::min(), "2.2250738585072014e-308");
  testNumberToStringECMAScript(Limits::max(), "1.7976931348623157e+308");
}

TEST(WTF, StringNumberToStringECMAScriptRegularNumbers) {
  // Pi.
  testNumberToStringECMAScript(piDouble, "3.141592653589793");
  testNumberToStringECMAScript(piFloat, "3.1415927410125732");
  testNumberToStringECMAScript(piOverTwoDouble, "1.5707963267948966");
  testNumberToStringECMAScript(piOverTwoFloat, "1.5707963705062866");
  testNumberToStringECMAScript(piOverFourDouble, "0.7853981633974483");
  testNumberToStringECMAScript(piOverFourFloat, "0.7853981852531433");

  // e.
  const double e = 2.71828182845904523536028747135266249775724709369995;
  testNumberToStringECMAScript(e, "2.718281828459045");

  // c, speed of light in m/s.
  const double c = 299792458;
  testNumberToStringECMAScript(c, "299792458");

  // Golen ratio.
  const double phi = 1.6180339887498948482;
  testNumberToStringECMAScript(phi, "1.618033988749895");
}

TEST(WTF, StringReplaceWithLiteral) {
  // Cases for 8Bit source.
  String testString = "1224";
  ASSERT_TRUE(testString.is8Bit());
  testString.replaceWithLiteral('2', "");
  ASSERT_STREQ("14", testString.utf8().data());

  testString = "1224";
  ASSERT_TRUE(testString.is8Bit());
  testString.replaceWithLiteral('2', "3");
  ASSERT_STREQ("1334", testString.utf8().data());

  testString = "1224";
  ASSERT_TRUE(testString.is8Bit());
  testString.replaceWithLiteral('2', "555");
  ASSERT_STREQ("15555554", testString.utf8().data());

  testString = "1224";
  ASSERT_TRUE(testString.is8Bit());
  testString.replaceWithLiteral('3', "NotFound");
  ASSERT_STREQ("1224", testString.utf8().data());

  // Cases for 16Bit source.
  testString = String::fromUTF8("résumé");
  ASSERT_FALSE(testString.is8Bit());
  testString.replaceWithLiteral(UChar(0x00E9 /*U+00E9 is 'é'*/), "e");
  ASSERT_STREQ("resume", testString.utf8().data());

  testString = String::fromUTF8("résumé");
  ASSERT_FALSE(testString.is8Bit());
  testString.replaceWithLiteral(UChar(0x00E9 /*U+00E9 is 'é'*/), "");
  ASSERT_STREQ("rsum", testString.utf8().data());

  testString = String::fromUTF8("résumé");
  ASSERT_FALSE(testString.is8Bit());
  testString.replaceWithLiteral('3', "NotFound");
  ASSERT_STREQ("résumé", testString.utf8().data());
}

TEST(WTF, StringComparisonOfSameStringVectors) {
  Vector<String> stringVector;
  stringVector.append("one");
  stringVector.append("two");

  Vector<String> sameStringVector;
  sameStringVector.append("one");
  sameStringVector.append("two");

  ASSERT_EQ(stringVector, sameStringVector);
}

TEST(WTF, SimplifyWhiteSpace) {
  String extraSpaces("  Hello  world  ");
  ASSERT_EQ(String("Hello world"), extraSpaces.simplifyWhiteSpace());
  ASSERT_EQ(String("  Hello  world  "),
            extraSpaces.simplifyWhiteSpace(WTF::DoNotStripWhiteSpace));

  String extraSpacesAndNewlines(" \nHello\n world\n ");
  ASSERT_EQ(String("Hello world"), extraSpacesAndNewlines.simplifyWhiteSpace());
  ASSERT_EQ(
      String("  Hello  world  "),
      extraSpacesAndNewlines.simplifyWhiteSpace(WTF::DoNotStripWhiteSpace));

  String extraSpacesAndTabs(" \nHello\t world\t ");
  ASSERT_EQ(String("Hello world"), extraSpacesAndTabs.simplifyWhiteSpace());
  ASSERT_EQ(String("  Hello  world  "),
            extraSpacesAndTabs.simplifyWhiteSpace(WTF::DoNotStripWhiteSpace));
}

struct CaseFoldingTestData {
  const char* sourceDescription;
  const char* source;
  const char** localeList;
  size_t localeListLength;
  const char* expected;
};

// \xC4\xB0 = U+0130 (capital dotted I)
// \xC4\xB1 = U+0131 (lowercase dotless I)
const char* turkicInput = "Isi\xC4\xB0 \xC4\xB0s\xC4\xB1I";
const char* greekInput =
    "\xCE\x9F\xCE\x94\xCE\x8C\xCE\xA3 \xCE\x9F\xCE\xB4\xCF\x8C\xCF\x82 "
    "\xCE\xA3\xCE\xBF \xCE\xA3\xCE\x9F o\xCE\xA3 \xCE\x9F\xCE\xA3 \xCF\x83 "
    "\xE1\xBC\x95\xCE\xBE";
const char* lithuanianInput =
    "I \xC3\x8F J J\xCC\x88 \xC4\xAE \xC4\xAE\xCC\x88 \xC3\x8C \xC3\x8D "
    "\xC4\xA8 xi\xCC\x87\xCC\x88 xj\xCC\x87\xCC\x88 x\xC4\xAF\xCC\x87\xCC\x88 "
    "xi\xCC\x87\xCC\x80 xi\xCC\x87\xCC\x81 xi\xCC\x87\xCC\x83 XI X\xC3\x8F XJ "
    "XJ\xCC\x88 X\xC4\xAE X\xC4\xAE\xCC\x88";

const char* turkicLocales[] = {
    "tr", "tr-TR", "tr_TR", "tr@foo=bar", "tr-US", "TR", "tr-tr", "tR",
    "az", "az-AZ", "az_AZ", "az@foo=bar", "az-US", "Az", "AZ-AZ",
};
const char* nonTurkicLocales[] = {
    "en", "en-US", "en_US", "en@foo=bar", "EN", "En",
    "ja", "el",    "fil",   "fi",         "lt",
};
const char* greekLocales[] = {
    "el", "el-GR", "el_GR", "el@foo=bar", "el-US", "EL", "el-gr", "eL",
};
const char* nonGreekLocales[] = {
    "en", "en-US", "en_US", "en@foo=bar", "EN", "En",
    "ja", "tr",    "az",    "fil",        "fi", "lt",
};
const char* lithuanianLocales[] = {
    "lt", "lt-LT", "lt_LT", "lt@foo=bar", "lt-US", "LT", "lt-lt", "lT",
};
// Should not have "tr" or "az" because "lt" and 'tr/az' rules conflict with
// each other.
const char* nonLithuanianLocales[] = {
    "en", "en-US", "en_US", "en@foo=bar", "EN", "En", "ja", "fil", "fi", "el",
};

TEST(WTF, StringToUpperLocale) {
  CaseFoldingTestData testDataList[] = {
      {
          "Turkic input",
          turkicInput,
          turkicLocales,
          sizeof(turkicLocales) / sizeof(const char*),
          "IS\xC4\xB0\xC4\xB0 \xC4\xB0SII",
      },
      {
          "Turkic input",
          turkicInput,
          nonTurkicLocales,
          sizeof(nonTurkicLocales) / sizeof(const char*),
          "ISI\xC4\xB0 \xC4\xB0SII",
      },
      {
          "Greek input",
          greekInput,
          greekLocales,
          sizeof(greekLocales) / sizeof(const char*),
          "\xCE\x9F\xCE\x94\xCE\x9F\xCE\xA3 \xCE\x9F\xCE\x94\xCE\x9F\xCE\xA3 "
          "\xCE\xA3\xCE\x9F \xCE\xA3\xCE\x9F \x4F\xCE\xA3 \xCE\x9F\xCE\xA3 "
          "\xCE\xA3 \xCE\x95\xCE\x9E",
      },
      {
          "Greek input",
          greekInput,
          nonGreekLocales,
          sizeof(nonGreekLocales) / sizeof(const char*),
          "\xCE\x9F\xCE\x94\xCE\x8C\xCE\xA3 \xCE\x9F\xCE\x94\xCE\x8C\xCE\xA3 "
          "\xCE\xA3\xCE\x9F \xCE\xA3\xCE\x9F \x4F\xCE\xA3 \xCE\x9F\xCE\xA3 "
          "\xCE\xA3 \xE1\xBC\x9D\xCE\x9E",
      },
      {
          "Lithuanian input",
          lithuanianInput,
          lithuanianLocales,
          sizeof(lithuanianLocales) / sizeof(const char*),
          "I \xC3\x8F J J\xCC\x88 \xC4\xAE \xC4\xAE\xCC\x88 \xC3\x8C \xC3\x8D "
          "\xC4\xA8 XI\xCC\x88 XJ\xCC\x88 X\xC4\xAE\xCC\x88 XI\xCC\x80 "
          "XI\xCC\x81 XI\xCC\x83 XI X\xC3\x8F XJ XJ\xCC\x88 X\xC4\xAE "
          "X\xC4\xAE\xCC\x88",
      },
      {
          "Lithuanian input",
          lithuanianInput,
          nonLithuanianLocales,
          sizeof(nonLithuanianLocales) / sizeof(const char*),
          "I \xC3\x8F J J\xCC\x88 \xC4\xAE \xC4\xAE\xCC\x88 \xC3\x8C \xC3\x8D "
          "\xC4\xA8 XI\xCC\x87\xCC\x88 XJ\xCC\x87\xCC\x88 "
          "X\xC4\xAE\xCC\x87\xCC\x88 XI\xCC\x87\xCC\x80 XI\xCC\x87\xCC\x81 "
          "XI\xCC\x87\xCC\x83 XI X\xC3\x8F XJ XJ\xCC\x88 X\xC4\xAE "
          "X\xC4\xAE\xCC\x88",
      },
  };

  for (size_t i = 0; i < sizeof(testDataList) / sizeof(testDataList[0]); ++i) {
    const char* expected = testDataList[i].expected;
    String source = String::fromUTF8(testDataList[i].source);
    for (size_t j = 0; j < testDataList[i].localeListLength; ++j) {
      const char* locale = testDataList[i].localeList[j];
      EXPECT_STREQ(expected, source.upper(locale).utf8().data())
          << testDataList[i].sourceDescription << "; locale=" << locale;
    }
  }
}

TEST(WTF, StringToLowerLocale) {
  CaseFoldingTestData testDataList[] = {
      {
          "Turkic input",
          turkicInput,
          turkicLocales,
          sizeof(turkicLocales) / sizeof(const char*),
          "\xC4\xB1sii is\xC4\xB1\xC4\xB1",
      },
      {
          "Turkic input",
          turkicInput,
          nonTurkicLocales,
          sizeof(nonTurkicLocales) / sizeof(const char*),
          // U+0130 is lowercased to U+0069 followed by U+0307
          "isii\xCC\x87 i\xCC\x87s\xC4\xB1i",
      },
      {
          "Greek input",
          greekInput,
          greekLocales,
          sizeof(greekLocales) / sizeof(const char*),
          "\xCE\xBF\xCE\xB4\xCF\x8C\xCF\x82 \xCE\xBF\xCE\xB4\xCF\x8C\xCF\x82 "
          "\xCF\x83\xCE\xBF \xCF\x83\xCE\xBF \x6F\xCF\x82 \xCE\xBF\xCF\x82 "
          "\xCF\x83 \xE1\xBC\x95\xCE\xBE",
      },
      {
          "Greek input",
          greekInput,
          nonGreekLocales,
          sizeof(greekLocales) / sizeof(const char*),
          "\xCE\xBF\xCE\xB4\xCF\x8C\xCF\x82 \xCE\xBF\xCE\xB4\xCF\x8C\xCF\x82 "
          "\xCF\x83\xCE\xBF \xCF\x83\xCE\xBF \x6F\xCF\x82 \xCE\xBF\xCF\x82 "
          "\xCF\x83 \xE1\xBC\x95\xCE\xBE",
      },
      {
          "Lithuanian input",
          lithuanianInput,
          lithuanianLocales,
          sizeof(lithuanianLocales) / sizeof(const char*),
          "i \xC3\xAF j j\xCC\x87\xCC\x88 \xC4\xAF \xC4\xAF\xCC\x87\xCC\x88 "
          "i\xCC\x87\xCC\x80 i\xCC\x87\xCC\x81 i\xCC\x87\xCC\x83 "
          "xi\xCC\x87\xCC\x88 xj\xCC\x87\xCC\x88 x\xC4\xAF\xCC\x87\xCC\x88 "
          "xi\xCC\x87\xCC\x80 xi\xCC\x87\xCC\x81 xi\xCC\x87\xCC\x83 xi "
          "x\xC3\xAF xj xj\xCC\x87\xCC\x88 x\xC4\xAF x\xC4\xAF\xCC\x87\xCC\x88",
      },
      {
          "Lithuanian input",
          lithuanianInput,
          nonLithuanianLocales,
          sizeof(nonLithuanianLocales) / sizeof(const char*),
          "\x69 \xC3\xAF \x6A \x6A\xCC\x88 \xC4\xAF \xC4\xAF\xCC\x88 \xC3\xAC "
          "\xC3\xAD \xC4\xA9 \x78\x69\xCC\x87\xCC\x88 \x78\x6A\xCC\x87\xCC\x88 "
          "\x78\xC4\xAF\xCC\x87\xCC\x88 \x78\x69\xCC\x87\xCC\x80 "
          "\x78\x69\xCC\x87\xCC\x81 \x78\x69\xCC\x87\xCC\x83 \x78\x69 "
          "\x78\xC3\xAF \x78\x6A \x78\x6A\xCC\x88 \x78\xC4\xAF "
          "\x78\xC4\xAF\xCC\x88",
      },
  };

  for (size_t i = 0; i < sizeof(testDataList) / sizeof(testDataList[0]); ++i) {
    const char* expected = testDataList[i].expected;
    String source = String::fromUTF8(testDataList[i].source);
    for (size_t j = 0; j < testDataList[i].localeListLength; ++j) {
      const char* locale = testDataList[i].localeList[j];
      EXPECT_STREQ(expected, source.lower(locale).utf8().data())
          << testDataList[i].sourceDescription << "; locale=" << locale;
    }
  }
}

}  // namespace
