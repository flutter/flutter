// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/strings/string_util.h"

#include <math.h>
#include <stdarg.h>

#include <algorithm>

#include "base/basictypes.h"
#include "base/strings/string16.h"
#include "base/strings/utf_string_conversions.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"

using ::testing::ElementsAre;

namespace base {

static const struct trim_case {
  const wchar_t* input;
  const TrimPositions positions;
  const wchar_t* output;
  const TrimPositions return_value;
} trim_cases[] = {
  {L" Google Video ", TRIM_LEADING, L"Google Video ", TRIM_LEADING},
  {L" Google Video ", TRIM_TRAILING, L" Google Video", TRIM_TRAILING},
  {L" Google Video ", TRIM_ALL, L"Google Video", TRIM_ALL},
  {L"Google Video", TRIM_ALL, L"Google Video", TRIM_NONE},
  {L"", TRIM_ALL, L"", TRIM_NONE},
  {L"  ", TRIM_LEADING, L"", TRIM_LEADING},
  {L"  ", TRIM_TRAILING, L"", TRIM_TRAILING},
  {L"  ", TRIM_ALL, L"", TRIM_ALL},
  {L"\t\rTest String\n", TRIM_ALL, L"Test String", TRIM_ALL},
  {L"\x2002Test String\x00A0\x3000", TRIM_ALL, L"Test String", TRIM_ALL},
};

static const struct trim_case_ascii {
  const char* input;
  const TrimPositions positions;
  const char* output;
  const TrimPositions return_value;
} trim_cases_ascii[] = {
  {" Google Video ", TRIM_LEADING, "Google Video ", TRIM_LEADING},
  {" Google Video ", TRIM_TRAILING, " Google Video", TRIM_TRAILING},
  {" Google Video ", TRIM_ALL, "Google Video", TRIM_ALL},
  {"Google Video", TRIM_ALL, "Google Video", TRIM_NONE},
  {"", TRIM_ALL, "", TRIM_NONE},
  {"  ", TRIM_LEADING, "", TRIM_LEADING},
  {"  ", TRIM_TRAILING, "", TRIM_TRAILING},
  {"  ", TRIM_ALL, "", TRIM_ALL},
  {"\t\rTest String\n", TRIM_ALL, "Test String", TRIM_ALL},
};

namespace {

// Helper used to test TruncateUTF8ToByteSize.
bool Truncated(const std::string& input,
               const size_t byte_size,
               std::string* output) {
    size_t prev = input.length();
    TruncateUTF8ToByteSize(input, byte_size, output);
    return prev != output->length();
}

}  // namespace

TEST(StringUtilTest, TruncateUTF8ToByteSize) {
  std::string output;

  // Empty strings and invalid byte_size arguments
  EXPECT_FALSE(Truncated(std::string(), 0, &output));
  EXPECT_EQ(output, "");
  EXPECT_TRUE(Truncated("\xe1\x80\xbf", 0, &output));
  EXPECT_EQ(output, "");
  EXPECT_FALSE(Truncated("\xe1\x80\xbf", static_cast<size_t>(-1), &output));
  EXPECT_FALSE(Truncated("\xe1\x80\xbf", 4, &output));

  // Testing the truncation of valid UTF8 correctly
  EXPECT_TRUE(Truncated("abc", 2, &output));
  EXPECT_EQ(output, "ab");
  EXPECT_TRUE(Truncated("\xc2\x81\xc2\x81", 2, &output));
  EXPECT_EQ(output.compare("\xc2\x81"), 0);
  EXPECT_TRUE(Truncated("\xc2\x81\xc2\x81", 3, &output));
  EXPECT_EQ(output.compare("\xc2\x81"), 0);
  EXPECT_FALSE(Truncated("\xc2\x81\xc2\x81", 4, &output));
  EXPECT_EQ(output.compare("\xc2\x81\xc2\x81"), 0);

  {
    const char array[] = "\x00\x00\xc2\x81\xc2\x81";
    const std::string array_string(array, arraysize(array));
    EXPECT_TRUE(Truncated(array_string, 4, &output));
    EXPECT_EQ(output.compare(std::string("\x00\x00\xc2\x81", 4)), 0);
  }

  {
    const char array[] = "\x00\xc2\x81\xc2\x81";
    const std::string array_string(array, arraysize(array));
    EXPECT_TRUE(Truncated(array_string, 4, &output));
    EXPECT_EQ(output.compare(std::string("\x00\xc2\x81", 3)), 0);
  }

  // Testing invalid UTF8
  EXPECT_TRUE(Truncated("\xed\xa0\x80\xed\xbf\xbf", 6, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xed\xa0\x8f", 3, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xed\xbf\xbf", 3, &output));
  EXPECT_EQ(output.compare(""), 0);

  // Testing invalid UTF8 mixed with valid UTF8
  EXPECT_FALSE(Truncated("\xe1\x80\xbf", 3, &output));
  EXPECT_EQ(output.compare("\xe1\x80\xbf"), 0);
  EXPECT_FALSE(Truncated("\xf1\x80\xa0\xbf", 4, &output));
  EXPECT_EQ(output.compare("\xf1\x80\xa0\xbf"), 0);
  EXPECT_FALSE(Truncated("a\xc2\x81\xe1\x80\xbf\xf1\x80\xa0\xbf",
              10, &output));
  EXPECT_EQ(output.compare("a\xc2\x81\xe1\x80\xbf\xf1\x80\xa0\xbf"), 0);
  EXPECT_TRUE(Truncated("a\xc2\x81\xe1\x80\xbf\xf1""a""\x80\xa0",
              10, &output));
  EXPECT_EQ(output.compare("a\xc2\x81\xe1\x80\xbf\xf1""a"), 0);
  EXPECT_FALSE(Truncated("\xef\xbb\xbf" "abc", 6, &output));
  EXPECT_EQ(output.compare("\xef\xbb\xbf" "abc"), 0);

  // Overlong sequences
  EXPECT_TRUE(Truncated("\xc0\x80", 2, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xc1\x80\xc1\x81", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xe0\x80\x80", 3, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xe0\x82\x80", 3, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xe0\x9f\xbf", 3, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf0\x80\x80\x8D", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf0\x80\x82\x91", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf0\x80\xa0\x80", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf0\x8f\xbb\xbf", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf8\x80\x80\x80\xbf", 5, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xfc\x80\x80\x80\xa0\xa5", 6, &output));
  EXPECT_EQ(output.compare(""), 0);

  // Beyond U+10FFFF (the upper limit of Unicode codespace)
  EXPECT_TRUE(Truncated("\xf4\x90\x80\x80", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf8\xa0\xbf\x80\xbf", 5, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xfc\x9c\xbf\x80\xbf\x80", 6, &output));
  EXPECT_EQ(output.compare(""), 0);

  // BOMs in UTF-16(BE|LE) and UTF-32(BE|LE)
  EXPECT_TRUE(Truncated("\xfe\xff", 2, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xff\xfe", 2, &output));
  EXPECT_EQ(output.compare(""), 0);

  {
    const char array[] = "\x00\x00\xfe\xff";
    const std::string array_string(array, arraysize(array));
    EXPECT_TRUE(Truncated(array_string, 4, &output));
    EXPECT_EQ(output.compare(std::string("\x00\x00", 2)), 0);
  }

  // Variants on the previous test
  {
    const char array[] = "\xff\xfe\x00\x00";
    const std::string array_string(array, 4);
    EXPECT_FALSE(Truncated(array_string, 4, &output));
    EXPECT_EQ(output.compare(std::string("\xff\xfe\x00\x00", 4)), 0);
  }
  {
    const char array[] = "\xff\x00\x00\xfe";
    const std::string array_string(array, arraysize(array));
    EXPECT_TRUE(Truncated(array_string, 4, &output));
    EXPECT_EQ(output.compare(std::string("\xff\x00\x00", 3)), 0);
  }

  // Non-characters : U+xxFFF[EF] where xx is 0x00 through 0x10 and <FDD0,FDEF>
  EXPECT_TRUE(Truncated("\xef\xbf\xbe", 3, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf0\x8f\xbf\xbe", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xf3\xbf\xbf\xbf", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xef\xb7\x90", 3, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_TRUE(Truncated("\xef\xb7\xaf", 3, &output));
  EXPECT_EQ(output.compare(""), 0);

  // Strings in legacy encodings that are valid in UTF-8, but
  // are invalid as UTF-8 in real data.
  EXPECT_TRUE(Truncated("caf\xe9", 4, &output));
  EXPECT_EQ(output.compare("caf"), 0);
  EXPECT_TRUE(Truncated("\xb0\xa1\xb0\xa2", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
  EXPECT_FALSE(Truncated("\xa7\x41\xa6\x6e", 4, &output));
  EXPECT_EQ(output.compare("\xa7\x41\xa6\x6e"), 0);
  EXPECT_TRUE(Truncated("\xa7\x41\xa6\x6e\xd9\xee\xe4\xee", 7,
              &output));
  EXPECT_EQ(output.compare("\xa7\x41\xa6\x6e"), 0);

  // Testing using the same string as input and output.
  EXPECT_FALSE(Truncated(output, 4, &output));
  EXPECT_EQ(output.compare("\xa7\x41\xa6\x6e"), 0);
  EXPECT_TRUE(Truncated(output, 3, &output));
  EXPECT_EQ(output.compare("\xa7\x41"), 0);

  // "abc" with U+201[CD] in windows-125[0-8]
  EXPECT_TRUE(Truncated("\x93" "abc\x94", 5, &output));
  EXPECT_EQ(output.compare("\x93" "abc"), 0);

  // U+0639 U+064E U+0644 U+064E in ISO-8859-6
  EXPECT_TRUE(Truncated("\xd9\xee\xe4\xee", 4, &output));
  EXPECT_EQ(output.compare(""), 0);

  // U+03B3 U+03B5 U+03B9 U+03AC in ISO-8859-7
  EXPECT_TRUE(Truncated("\xe3\xe5\xe9\xdC", 4, &output));
  EXPECT_EQ(output.compare(""), 0);
}

TEST(StringUtilTest, TrimWhitespace) {
  string16 output;  // Allow contents to carry over to next testcase
  for (size_t i = 0; i < arraysize(trim_cases); ++i) {
    const trim_case& value = trim_cases[i];
    EXPECT_EQ(value.return_value,
              TrimWhitespace(WideToUTF16(value.input), value.positions,
                             &output));
    EXPECT_EQ(WideToUTF16(value.output), output);
  }

  // Test that TrimWhitespace() can take the same string for input and output
  output = ASCIIToUTF16("  This is a test \r\n");
  EXPECT_EQ(TRIM_ALL, TrimWhitespace(output, TRIM_ALL, &output));
  EXPECT_EQ(ASCIIToUTF16("This is a test"), output);

  // Once more, but with a string of whitespace
  output = ASCIIToUTF16("  \r\n");
  EXPECT_EQ(TRIM_ALL, TrimWhitespace(output, TRIM_ALL, &output));
  EXPECT_EQ(string16(), output);

  std::string output_ascii;
  for (size_t i = 0; i < arraysize(trim_cases_ascii); ++i) {
    const trim_case_ascii& value = trim_cases_ascii[i];
    EXPECT_EQ(value.return_value,
              TrimWhitespace(value.input, value.positions, &output_ascii));
    EXPECT_EQ(value.output, output_ascii);
  }
}

static const struct collapse_case {
  const wchar_t* input;
  const bool trim;
  const wchar_t* output;
} collapse_cases[] = {
  {L" Google Video ", false, L"Google Video"},
  {L"Google Video", false, L"Google Video"},
  {L"", false, L""},
  {L"  ", false, L""},
  {L"\t\rTest String\n", false, L"Test String"},
  {L"\x2002Test String\x00A0\x3000", false, L"Test String"},
  {L"    Test     \n  \t String    ", false, L"Test String"},
  {L"\x2002Test\x1680 \x2028 \tString\x00A0\x3000", false, L"Test String"},
  {L"   Test String", false, L"Test String"},
  {L"Test String    ", false, L"Test String"},
  {L"Test String", false, L"Test String"},
  {L"", true, L""},
  {L"\n", true, L""},
  {L"  \r  ", true, L""},
  {L"\nFoo", true, L"Foo"},
  {L"\r  Foo  ", true, L"Foo"},
  {L" Foo bar ", true, L"Foo bar"},
  {L"  \tFoo  bar  \n", true, L"Foo bar"},
  {L" a \r b\n c \r\n d \t\re \t f \n ", true, L"abcde f"},
};

TEST(StringUtilTest, CollapseWhitespace) {
  for (size_t i = 0; i < arraysize(collapse_cases); ++i) {
    const collapse_case& value = collapse_cases[i];
    EXPECT_EQ(WideToUTF16(value.output),
              CollapseWhitespace(WideToUTF16(value.input), value.trim));
  }
}

static const struct collapse_case_ascii {
  const char* input;
  const bool trim;
  const char* output;
} collapse_cases_ascii[] = {
  {" Google Video ", false, "Google Video"},
  {"Google Video", false, "Google Video"},
  {"", false, ""},
  {"  ", false, ""},
  {"\t\rTest String\n", false, "Test String"},
  {"    Test     \n  \t String    ", false, "Test String"},
  {"   Test String", false, "Test String"},
  {"Test String    ", false, "Test String"},
  {"Test String", false, "Test String"},
  {"", true, ""},
  {"\n", true, ""},
  {"  \r  ", true, ""},
  {"\nFoo", true, "Foo"},
  {"\r  Foo  ", true, "Foo"},
  {" Foo bar ", true, "Foo bar"},
  {"  \tFoo  bar  \n", true, "Foo bar"},
  {" a \r b\n c \r\n d \t\re \t f \n ", true, "abcde f"},
};

TEST(StringUtilTest, CollapseWhitespaceASCII) {
  for (size_t i = 0; i < arraysize(collapse_cases_ascii); ++i) {
    const collapse_case_ascii& value = collapse_cases_ascii[i];
    EXPECT_EQ(value.output, CollapseWhitespaceASCII(value.input, value.trim));
  }
}

TEST(StringUtilTest, IsStringUTF8) {
  EXPECT_TRUE(IsStringUTF8("abc"));
  EXPECT_TRUE(IsStringUTF8("\xc2\x81"));
  EXPECT_TRUE(IsStringUTF8("\xe1\x80\xbf"));
  EXPECT_TRUE(IsStringUTF8("\xf1\x80\xa0\xbf"));
  EXPECT_TRUE(IsStringUTF8("a\xc2\x81\xe1\x80\xbf\xf1\x80\xa0\xbf"));
  EXPECT_TRUE(IsStringUTF8("\xef\xbb\xbf" "abc"));  // UTF-8 BOM

  // surrogate code points
  EXPECT_FALSE(IsStringUTF8("\xed\xa0\x80\xed\xbf\xbf"));
  EXPECT_FALSE(IsStringUTF8("\xed\xa0\x8f"));
  EXPECT_FALSE(IsStringUTF8("\xed\xbf\xbf"));

  // overlong sequences
  EXPECT_FALSE(IsStringUTF8("\xc0\x80"));  // U+0000
  EXPECT_FALSE(IsStringUTF8("\xc1\x80\xc1\x81"));  // "AB"
  EXPECT_FALSE(IsStringUTF8("\xe0\x80\x80"));  // U+0000
  EXPECT_FALSE(IsStringUTF8("\xe0\x82\x80"));  // U+0080
  EXPECT_FALSE(IsStringUTF8("\xe0\x9f\xbf"));  // U+07ff
  EXPECT_FALSE(IsStringUTF8("\xf0\x80\x80\x8D"));  // U+000D
  EXPECT_FALSE(IsStringUTF8("\xf0\x80\x82\x91"));  // U+0091
  EXPECT_FALSE(IsStringUTF8("\xf0\x80\xa0\x80"));  // U+0800
  EXPECT_FALSE(IsStringUTF8("\xf0\x8f\xbb\xbf"));  // U+FEFF (BOM)
  EXPECT_FALSE(IsStringUTF8("\xf8\x80\x80\x80\xbf"));  // U+003F
  EXPECT_FALSE(IsStringUTF8("\xfc\x80\x80\x80\xa0\xa5"));  // U+00A5

  // Beyond U+10FFFF (the upper limit of Unicode codespace)
  EXPECT_FALSE(IsStringUTF8("\xf4\x90\x80\x80"));  // U+110000
  EXPECT_FALSE(IsStringUTF8("\xf8\xa0\xbf\x80\xbf"));  // 5 bytes
  EXPECT_FALSE(IsStringUTF8("\xfc\x9c\xbf\x80\xbf\x80"));  // 6 bytes

  // BOMs in UTF-16(BE|LE) and UTF-32(BE|LE)
  EXPECT_FALSE(IsStringUTF8("\xfe\xff"));
  EXPECT_FALSE(IsStringUTF8("\xff\xfe"));
  EXPECT_FALSE(IsStringUTF8(std::string("\x00\x00\xfe\xff", 4)));
  EXPECT_FALSE(IsStringUTF8("\xff\xfe\x00\x00"));

  // Non-characters : U+xxFFF[EF] where xx is 0x00 through 0x10 and <FDD0,FDEF>
  EXPECT_FALSE(IsStringUTF8("\xef\xbf\xbe"));  // U+FFFE)
  EXPECT_FALSE(IsStringUTF8("\xf0\x8f\xbf\xbe"));  // U+1FFFE
  EXPECT_FALSE(IsStringUTF8("\xf3\xbf\xbf\xbf"));  // U+10FFFF
  EXPECT_FALSE(IsStringUTF8("\xef\xb7\x90"));  // U+FDD0
  EXPECT_FALSE(IsStringUTF8("\xef\xb7\xaf"));  // U+FDEF
  // Strings in legacy encodings. We can certainly make up strings
  // in a legacy encoding that are valid in UTF-8, but in real data,
  // most of them are invalid as UTF-8.
  EXPECT_FALSE(IsStringUTF8("caf\xe9"));  // cafe with U+00E9 in ISO-8859-1
  EXPECT_FALSE(IsStringUTF8("\xb0\xa1\xb0\xa2"));  // U+AC00, U+AC001 in EUC-KR
  EXPECT_FALSE(IsStringUTF8("\xa7\x41\xa6\x6e"));  // U+4F60 U+597D in Big5
  // "abc" with U+201[CD] in windows-125[0-8]
  EXPECT_FALSE(IsStringUTF8("\x93" "abc\x94"));
  // U+0639 U+064E U+0644 U+064E in ISO-8859-6
  EXPECT_FALSE(IsStringUTF8("\xd9\xee\xe4\xee"));
  // U+03B3 U+03B5 U+03B9 U+03AC in ISO-8859-7
  EXPECT_FALSE(IsStringUTF8("\xe3\xe5\xe9\xdC"));

  // Check that we support Embedded Nulls. The first uses the canonical UTF-8
  // representation, and the second uses a 2-byte sequence. The second version
  // is invalid UTF-8 since UTF-8 states that the shortest encoding for a
  // given codepoint must be used.
  static const char kEmbeddedNull[] = "embedded\0null";
  EXPECT_TRUE(IsStringUTF8(
      std::string(kEmbeddedNull, sizeof(kEmbeddedNull))));
  EXPECT_FALSE(IsStringUTF8("embedded\xc0\x80U+0000"));
}

TEST(StringUtilTest, IsStringASCII) {
  static char char_ascii[] =
      "0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF";
  static char16 char16_ascii[] = {
      '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'A',
      'B', 'C', 'D', 'E', 'F', '0', '1', '2', '3', '4', '5', '6',
      '7', '8', '9', '0', 'A', 'B', 'C', 'D', 'E', 'F', 0 };
  static std::wstring wchar_ascii(
      L"0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF");

  // Test a variety of the fragment start positions and lengths in order to make
  // sure that bit masking in IsStringASCII works correctly.
  // Also, test that a non-ASCII character will be detected regardless of its
  // position inside the string.
  {
    const size_t string_length = arraysize(char_ascii) - 1;
    for (size_t offset = 0; offset < 8; ++offset) {
      for (size_t len = 0, max_len = string_length - offset; len < max_len;
           ++len) {
        EXPECT_TRUE(IsStringASCII(StringPiece(char_ascii + offset, len)));
        for (size_t char_pos = offset; char_pos < len; ++char_pos) {
          char_ascii[char_pos] |= '\x80';
          EXPECT_FALSE(IsStringASCII(StringPiece(char_ascii + offset, len)));
          char_ascii[char_pos] &= ~'\x80';
        }
      }
    }
  }

  {
    const size_t string_length = arraysize(char16_ascii) - 1;
    for (size_t offset = 0; offset < 4; ++offset) {
      for (size_t len = 0, max_len = string_length - offset; len < max_len;
           ++len) {
        EXPECT_TRUE(IsStringASCII(StringPiece16(char16_ascii + offset, len)));
        for (size_t char_pos = offset; char_pos < len; ++char_pos) {
          char16_ascii[char_pos] |= 0x80;
          EXPECT_FALSE(
              IsStringASCII(StringPiece16(char16_ascii + offset, len)));
          char16_ascii[char_pos] &= ~0x80;
          // Also test when the upper half is non-zero.
          char16_ascii[char_pos] |= 0x100;
          EXPECT_FALSE(
              IsStringASCII(StringPiece16(char16_ascii + offset, len)));
          char16_ascii[char_pos] &= ~0x100;
        }
      }
    }
  }

  {
    const size_t string_length = wchar_ascii.length();
    for (size_t len = 0; len < string_length; ++len) {
      EXPECT_TRUE(IsStringASCII(wchar_ascii.substr(0, len)));
      for (size_t char_pos = 0; char_pos < len; ++char_pos) {
        wchar_ascii[char_pos] |= 0x80;
        EXPECT_FALSE(
            IsStringASCII(wchar_ascii.substr(0, len)));
        wchar_ascii[char_pos] &= ~0x80;
        wchar_ascii[char_pos] |= 0x100;
        EXPECT_FALSE(
            IsStringASCII(wchar_ascii.substr(0, len)));
        wchar_ascii[char_pos] &= ~0x100;
#if defined(WCHAR_T_IS_UTF32)
        wchar_ascii[char_pos] |= 0x10000;
        EXPECT_FALSE(
            IsStringASCII(wchar_ascii.substr(0, len)));
        wchar_ascii[char_pos] &= ~0x10000;
#endif  // WCHAR_T_IS_UTF32
      }
    }
  }
}

TEST(StringUtilTest, ConvertASCII) {
  static const char* const char_cases[] = {
    "Google Video",
    "Hello, world\n",
    "0123ABCDwxyz \a\b\t\r\n!+,.~"
  };

  static const wchar_t* const wchar_cases[] = {
    L"Google Video",
    L"Hello, world\n",
    L"0123ABCDwxyz \a\b\t\r\n!+,.~"
  };

  for (size_t i = 0; i < arraysize(char_cases); ++i) {
    EXPECT_TRUE(IsStringASCII(char_cases[i]));
    string16 utf16 = ASCIIToUTF16(char_cases[i]);
    EXPECT_EQ(WideToUTF16(wchar_cases[i]), utf16);

    std::string ascii = UTF16ToASCII(WideToUTF16(wchar_cases[i]));
    EXPECT_EQ(char_cases[i], ascii);
  }

  EXPECT_FALSE(IsStringASCII("Google \x80Video"));

  // Convert empty strings.
  string16 empty16;
  std::string empty;
  EXPECT_EQ(empty, UTF16ToASCII(empty16));
  EXPECT_EQ(empty16, ASCIIToUTF16(empty));

  // Convert strings with an embedded NUL character.
  const char chars_with_nul[] = "test\0string";
  const int length_with_nul = arraysize(chars_with_nul) - 1;
  std::string string_with_nul(chars_with_nul, length_with_nul);
  string16 string16_with_nul = ASCIIToUTF16(string_with_nul);
  EXPECT_EQ(static_cast<string16::size_type>(length_with_nul),
            string16_with_nul.length());
  std::string narrow_with_nul = UTF16ToASCII(string16_with_nul);
  EXPECT_EQ(static_cast<std::string::size_type>(length_with_nul),
            narrow_with_nul.length());
  EXPECT_EQ(0, string_with_nul.compare(narrow_with_nul));
}

TEST(StringUtilTest, ToUpperASCII) {
  EXPECT_EQ('C', ToUpperASCII('C'));
  EXPECT_EQ('C', ToUpperASCII('c'));
  EXPECT_EQ('2', ToUpperASCII('2'));

  EXPECT_EQ(L'C', ToUpperASCII(L'C'));
  EXPECT_EQ(L'C', ToUpperASCII(L'c'));
  EXPECT_EQ(L'2', ToUpperASCII(L'2'));

  std::string in_place_a("Cc2");
  StringToUpperASCII(&in_place_a);
  EXPECT_EQ("CC2", in_place_a);

  std::wstring in_place_w(L"Cc2");
  StringToUpperASCII(&in_place_w);
  EXPECT_EQ(L"CC2", in_place_w);

  std::string original_a("Cc2");
  std::string upper_a = StringToUpperASCII(original_a);
  EXPECT_EQ("CC2", upper_a);

  std::wstring original_w(L"Cc2");
  std::wstring upper_w = StringToUpperASCII(original_w);
  EXPECT_EQ(L"CC2", upper_w);
}

TEST(StringUtilTest, LowerCaseEqualsASCII) {
  static const struct {
    const char*    src_a;
    const char*    dst;
  } lowercase_cases[] = {
    { "FoO", "foo" },
    { "foo", "foo" },
    { "FOO", "foo" },
  };

  for (size_t i = 0; i < arraysize(lowercase_cases); ++i) {
    EXPECT_TRUE(LowerCaseEqualsASCII(ASCIIToUTF16(lowercase_cases[i].src_a),
                                     lowercase_cases[i].dst));
    EXPECT_TRUE(LowerCaseEqualsASCII(lowercase_cases[i].src_a,
                                     lowercase_cases[i].dst));
  }
}

TEST(StringUtilTest, FormatBytesUnlocalized) {
  static const struct {
    int64 bytes;
    const char* expected;
  } cases[] = {
    // Expected behavior: we show one post-decimal digit when we have
    // under two pre-decimal digits, except in cases where it makes no
    // sense (zero or bytes).
    // Since we switch units once we cross the 1000 mark, this keeps
    // the display of file sizes or bytes consistently around three
    // digits.
    {0, "0 B"},
    {512, "512 B"},
    {1024*1024, "1.0 MB"},
    {1024*1024*1024, "1.0 GB"},
    {10LL*1024*1024*1024, "10.0 GB"},
    {99LL*1024*1024*1024, "99.0 GB"},
    {105LL*1024*1024*1024, "105 GB"},
    {105LL*1024*1024*1024 + 500LL*1024*1024, "105 GB"},
    {~(1LL << 63), "8192 PB"},

    {99*1024 + 103, "99.1 kB"},
    {1024*1024 + 103, "1.0 MB"},
    {1024*1024 + 205 * 1024, "1.2 MB"},
    {1024*1024*1024 + (927 * 1024*1024), "1.9 GB"},
    {10LL*1024*1024*1024, "10.0 GB"},
    {100LL*1024*1024*1024, "100 GB"},
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    EXPECT_EQ(ASCIIToUTF16(cases[i].expected),
              FormatBytesUnlocalized(cases[i].bytes));
  }
}
TEST(StringUtilTest, ReplaceSubstringsAfterOffset) {
  static const struct {
    const char* str;
    string16::size_type start_offset;
    const char* find_this;
    const char* replace_with;
    const char* expected;
  } cases[] = {
    {"aaa", 0, "a", "b", "bbb"},
    {"abb", 0, "ab", "a", "ab"},
    {"Removing some substrings inging", 0, "ing", "", "Remov some substrs "},
    {"Not found", 0, "x", "0", "Not found"},
    {"Not found again", 5, "x", "0", "Not found again"},
    {" Making it much longer ", 0, " ", "Four score and seven years ago",
     "Four score and seven years agoMakingFour score and seven years agoit"
     "Four score and seven years agomuchFour score and seven years agolonger"
     "Four score and seven years ago"},
    {"Invalid offset", 9999, "t", "foobar", "Invalid offset"},
    {"Replace me only me once", 9, "me ", "", "Replace me only once"},
    {"abababab", 2, "ab", "c", "abccc"},
  };

  for (size_t i = 0; i < arraysize(cases); i++) {
    string16 str = ASCIIToUTF16(cases[i].str);
    ReplaceSubstringsAfterOffset(&str, cases[i].start_offset,
                                 ASCIIToUTF16(cases[i].find_this),
                                 ASCIIToUTF16(cases[i].replace_with));
    EXPECT_EQ(ASCIIToUTF16(cases[i].expected), str);
  }
}

TEST(StringUtilTest, ReplaceFirstSubstringAfterOffset) {
  static const struct {
    const char* str;
    string16::size_type start_offset;
    const char* find_this;
    const char* replace_with;
    const char* expected;
  } cases[] = {
    {"aaa", 0, "a", "b", "baa"},
    {"abb", 0, "ab", "a", "ab"},
    {"Removing some substrings inging", 0, "ing", "",
      "Remov some substrings inging"},
    {"Not found", 0, "x", "0", "Not found"},
    {"Not found again", 5, "x", "0", "Not found again"},
    {" Making it much longer ", 0, " ", "Four score and seven years ago",
     "Four score and seven years agoMaking it much longer "},
    {"Invalid offset", 9999, "t", "foobar", "Invalid offset"},
    {"Replace me only me once", 4, "me ", "", "Replace only me once"},
    {"abababab", 2, "ab", "c", "abcabab"},
  };

  for (size_t i = 0; i < arraysize(cases); i++) {
    string16 str = ASCIIToUTF16(cases[i].str);
    ReplaceFirstSubstringAfterOffset(&str, cases[i].start_offset,
                                     ASCIIToUTF16(cases[i].find_this),
                                     ASCIIToUTF16(cases[i].replace_with));
    EXPECT_EQ(ASCIIToUTF16(cases[i].expected), str);
  }
}

TEST(StringUtilTest, HexDigitToInt) {
  EXPECT_EQ(0, HexDigitToInt('0'));
  EXPECT_EQ(1, HexDigitToInt('1'));
  EXPECT_EQ(2, HexDigitToInt('2'));
  EXPECT_EQ(3, HexDigitToInt('3'));
  EXPECT_EQ(4, HexDigitToInt('4'));
  EXPECT_EQ(5, HexDigitToInt('5'));
  EXPECT_EQ(6, HexDigitToInt('6'));
  EXPECT_EQ(7, HexDigitToInt('7'));
  EXPECT_EQ(8, HexDigitToInt('8'));
  EXPECT_EQ(9, HexDigitToInt('9'));
  EXPECT_EQ(10, HexDigitToInt('A'));
  EXPECT_EQ(11, HexDigitToInt('B'));
  EXPECT_EQ(12, HexDigitToInt('C'));
  EXPECT_EQ(13, HexDigitToInt('D'));
  EXPECT_EQ(14, HexDigitToInt('E'));
  EXPECT_EQ(15, HexDigitToInt('F'));

  // Verify the lower case as well.
  EXPECT_EQ(10, HexDigitToInt('a'));
  EXPECT_EQ(11, HexDigitToInt('b'));
  EXPECT_EQ(12, HexDigitToInt('c'));
  EXPECT_EQ(13, HexDigitToInt('d'));
  EXPECT_EQ(14, HexDigitToInt('e'));
  EXPECT_EQ(15, HexDigitToInt('f'));
}

TEST(StringUtilTest, JoinString) {
  std::string separator(", ");
  std::vector<std::string> parts;
  EXPECT_EQ(std::string(), JoinString(parts, separator));

  parts.push_back("a");
  EXPECT_EQ("a", JoinString(parts, separator));

  parts.push_back("b");
  parts.push_back("c");
  EXPECT_EQ("a, b, c", JoinString(parts, separator));

  parts.push_back(std::string());
  EXPECT_EQ("a, b, c, ", JoinString(parts, separator));
  parts.push_back(" ");
  EXPECT_EQ("a|b|c|| ", JoinString(parts, "|"));
}

TEST(StringUtilTest, JoinString16) {
  string16 separator = ASCIIToUTF16(", ");
  std::vector<string16> parts;
  EXPECT_EQ(string16(), JoinString(parts, separator));

  parts.push_back(ASCIIToUTF16("a"));
  EXPECT_EQ(ASCIIToUTF16("a"), JoinString(parts, separator));

  parts.push_back(ASCIIToUTF16("b"));
  parts.push_back(ASCIIToUTF16("c"));
  EXPECT_EQ(ASCIIToUTF16("a, b, c"), JoinString(parts, separator));

  parts.push_back(ASCIIToUTF16(""));
  EXPECT_EQ(ASCIIToUTF16("a, b, c, "), JoinString(parts, separator));
  parts.push_back(ASCIIToUTF16(" "));
  EXPECT_EQ(ASCIIToUTF16("a|b|c|| "), JoinString(parts, ASCIIToUTF16("|")));
}

TEST(StringUtilTest, StartsWith) {
  EXPECT_TRUE(StartsWith("javascript:url", "javascript",
                         base::CompareCase::SENSITIVE));
  EXPECT_FALSE(StartsWith("JavaScript:url", "javascript",
                          base::CompareCase::SENSITIVE));
  EXPECT_TRUE(StartsWith("javascript:url", "javascript",
                         base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(StartsWith("JavaScript:url", "javascript",
                         base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(StartsWith("java", "javascript", base::CompareCase::SENSITIVE));
  EXPECT_FALSE(StartsWith("java", "javascript",
                          base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(StartsWith(std::string(), "javascript",
                          base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(StartsWith(std::string(), "javascript",
                          base::CompareCase::SENSITIVE));
  EXPECT_TRUE(StartsWith("java", std::string(),
                         base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(StartsWith("java", std::string(), base::CompareCase::SENSITIVE));

  EXPECT_TRUE(StartsWith(ASCIIToUTF16("javascript:url"),
                         ASCIIToUTF16("javascript"),
                         base::CompareCase::SENSITIVE));
  EXPECT_FALSE(StartsWith(ASCIIToUTF16("JavaScript:url"),
                          ASCIIToUTF16("javascript"),
                          base::CompareCase::SENSITIVE));
  EXPECT_TRUE(StartsWith(ASCIIToUTF16("javascript:url"),
                         ASCIIToUTF16("javascript"),
                         base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(StartsWith(ASCIIToUTF16("JavaScript:url"),
                         ASCIIToUTF16("javascript"),
                         base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(StartsWith(ASCIIToUTF16("java"), ASCIIToUTF16("javascript"),
                          base::CompareCase::SENSITIVE));
  EXPECT_FALSE(StartsWith(ASCIIToUTF16("java"), ASCIIToUTF16("javascript"),
                          base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(StartsWith(string16(), ASCIIToUTF16("javascript"),
                          base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(StartsWith(string16(), ASCIIToUTF16("javascript"),
                          base::CompareCase::SENSITIVE));
  EXPECT_TRUE(StartsWith(ASCIIToUTF16("java"), string16(),
                         base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(StartsWith(ASCIIToUTF16("java"), string16(),
                         base::CompareCase::SENSITIVE));
}

TEST(StringUtilTest, EndsWith) {
  EXPECT_TRUE(EndsWith(ASCIIToUTF16("Foo.plugin"), ASCIIToUTF16(".plugin"),
                       base::CompareCase::SENSITIVE));
  EXPECT_FALSE(EndsWith(ASCIIToUTF16("Foo.Plugin"), ASCIIToUTF16(".plugin"),
                        base::CompareCase::SENSITIVE));
  EXPECT_TRUE(EndsWith(ASCIIToUTF16("Foo.plugin"), ASCIIToUTF16(".plugin"),
                       base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(EndsWith(ASCIIToUTF16("Foo.Plugin"), ASCIIToUTF16(".plugin"),
                       base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(EndsWith(ASCIIToUTF16(".plug"), ASCIIToUTF16(".plugin"),
                        base::CompareCase::SENSITIVE));
  EXPECT_FALSE(EndsWith(ASCIIToUTF16(".plug"), ASCIIToUTF16(".plugin"),
                        base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(EndsWith(ASCIIToUTF16("Foo.plugin Bar"), ASCIIToUTF16(".plugin"),
                        base::CompareCase::SENSITIVE));
  EXPECT_FALSE(EndsWith(ASCIIToUTF16("Foo.plugin Bar"), ASCIIToUTF16(".plugin"),
                        base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(EndsWith(string16(), ASCIIToUTF16(".plugin"),
                        base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_FALSE(EndsWith(string16(), ASCIIToUTF16(".plugin"),
                        base::CompareCase::SENSITIVE));
  EXPECT_TRUE(EndsWith(ASCIIToUTF16("Foo.plugin"), string16(),
                       base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(EndsWith(ASCIIToUTF16("Foo.plugin"), string16(),
                       base::CompareCase::SENSITIVE));
  EXPECT_TRUE(EndsWith(ASCIIToUTF16(".plugin"), ASCIIToUTF16(".plugin"),
                       base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(EndsWith(ASCIIToUTF16(".plugin"), ASCIIToUTF16(".plugin"),
                       base::CompareCase::SENSITIVE));
  EXPECT_TRUE(
      EndsWith(string16(), string16(), base::CompareCase::INSENSITIVE_ASCII));
  EXPECT_TRUE(EndsWith(string16(), string16(), base::CompareCase::SENSITIVE));
}

TEST(StringUtilTest, GetStringFWithOffsets) {
  std::vector<string16> subst;
  subst.push_back(ASCIIToUTF16("1"));
  subst.push_back(ASCIIToUTF16("2"));
  std::vector<size_t> offsets;

  ReplaceStringPlaceholders(ASCIIToUTF16("Hello, $1. Your number is $2."),
                            subst,
                            &offsets);
  EXPECT_EQ(2U, offsets.size());
  EXPECT_EQ(7U, offsets[0]);
  EXPECT_EQ(25U, offsets[1]);
  offsets.clear();

  ReplaceStringPlaceholders(ASCIIToUTF16("Hello, $2. Your number is $1."),
                            subst,
                            &offsets);
  EXPECT_EQ(2U, offsets.size());
  EXPECT_EQ(25U, offsets[0]);
  EXPECT_EQ(7U, offsets[1]);
  offsets.clear();
}

TEST(StringUtilTest, ReplaceStringPlaceholdersTooFew) {
  // Test whether replacestringplaceholders works as expected when there
  // are fewer inputs than outputs.
  std::vector<string16> subst;
  subst.push_back(ASCIIToUTF16("9a"));
  subst.push_back(ASCIIToUTF16("8b"));
  subst.push_back(ASCIIToUTF16("7c"));

  string16 formatted =
      ReplaceStringPlaceholders(
          ASCIIToUTF16("$1a,$2b,$3c,$4d,$5e,$6f,$1g,$2h,$3i"), subst, NULL);

  EXPECT_EQ(formatted, ASCIIToUTF16("9aa,8bb,7cc,d,e,f,9ag,8bh,7ci"));
}

TEST(StringUtilTest, ReplaceStringPlaceholders) {
  std::vector<string16> subst;
  subst.push_back(ASCIIToUTF16("9a"));
  subst.push_back(ASCIIToUTF16("8b"));
  subst.push_back(ASCIIToUTF16("7c"));
  subst.push_back(ASCIIToUTF16("6d"));
  subst.push_back(ASCIIToUTF16("5e"));
  subst.push_back(ASCIIToUTF16("4f"));
  subst.push_back(ASCIIToUTF16("3g"));
  subst.push_back(ASCIIToUTF16("2h"));
  subst.push_back(ASCIIToUTF16("1i"));

  string16 formatted =
      ReplaceStringPlaceholders(
          ASCIIToUTF16("$1a,$2b,$3c,$4d,$5e,$6f,$7g,$8h,$9i"), subst, NULL);

  EXPECT_EQ(formatted, ASCIIToUTF16("9aa,8bb,7cc,6dd,5ee,4ff,3gg,2hh,1ii"));
}

TEST(StringUtilTest, ReplaceStringPlaceholdersMoreThan9Replacements) {
  std::vector<string16> subst;
  subst.push_back(ASCIIToUTF16("9a"));
  subst.push_back(ASCIIToUTF16("8b"));
  subst.push_back(ASCIIToUTF16("7c"));
  subst.push_back(ASCIIToUTF16("6d"));
  subst.push_back(ASCIIToUTF16("5e"));
  subst.push_back(ASCIIToUTF16("4f"));
  subst.push_back(ASCIIToUTF16("3g"));
  subst.push_back(ASCIIToUTF16("2h"));
  subst.push_back(ASCIIToUTF16("1i"));
  subst.push_back(ASCIIToUTF16("0j"));
  subst.push_back(ASCIIToUTF16("-1k"));
  subst.push_back(ASCIIToUTF16("-2l"));
  subst.push_back(ASCIIToUTF16("-3m"));
  subst.push_back(ASCIIToUTF16("-4n"));

  string16 formatted =
      ReplaceStringPlaceholders(
          ASCIIToUTF16("$1a,$2b,$3c,$4d,$5e,$6f,$7g,$8h,$9i,"
                       "$10j,$11k,$12l,$13m,$14n,$1"), subst, NULL);

  EXPECT_EQ(formatted, ASCIIToUTF16("9aa,8bb,7cc,6dd,5ee,4ff,3gg,2hh,"
                                    "1ii,0jj,-1kk,-2ll,-3mm,-4nn,9a"));
}

TEST(StringUtilTest, StdStringReplaceStringPlaceholders) {
  std::vector<std::string> subst;
  subst.push_back("9a");
  subst.push_back("8b");
  subst.push_back("7c");
  subst.push_back("6d");
  subst.push_back("5e");
  subst.push_back("4f");
  subst.push_back("3g");
  subst.push_back("2h");
  subst.push_back("1i");

  std::string formatted =
      ReplaceStringPlaceholders(
          "$1a,$2b,$3c,$4d,$5e,$6f,$7g,$8h,$9i", subst, NULL);

  EXPECT_EQ(formatted, "9aa,8bb,7cc,6dd,5ee,4ff,3gg,2hh,1ii");
}

TEST(StringUtilTest, ReplaceStringPlaceholdersConsecutiveDollarSigns) {
  std::vector<std::string> subst;
  subst.push_back("a");
  subst.push_back("b");
  subst.push_back("c");
  EXPECT_EQ(ReplaceStringPlaceholders("$$1 $$$2 $$$$3", subst, NULL),
            "$1 $$2 $$$3");
}

TEST(StringUtilTest, LcpyTest) {
  // Test the normal case where we fit in our buffer.
  {
    char dst[10];
    wchar_t wdst[10];
    EXPECT_EQ(7U, strlcpy(dst, "abcdefg", arraysize(dst)));
    EXPECT_EQ(0, memcmp(dst, "abcdefg", 8));
    EXPECT_EQ(7U, wcslcpy(wdst, L"abcdefg", arraysize(wdst)));
    EXPECT_EQ(0, memcmp(wdst, L"abcdefg", sizeof(wchar_t) * 8));
  }

  // Test dst_size == 0, nothing should be written to |dst| and we should
  // have the equivalent of strlen(src).
  {
    char dst[2] = {1, 2};
    wchar_t wdst[2] = {1, 2};
    EXPECT_EQ(7U, strlcpy(dst, "abcdefg", 0));
    EXPECT_EQ(1, dst[0]);
    EXPECT_EQ(2, dst[1]);
    EXPECT_EQ(7U, wcslcpy(wdst, L"abcdefg", 0));
    EXPECT_EQ(static_cast<wchar_t>(1), wdst[0]);
    EXPECT_EQ(static_cast<wchar_t>(2), wdst[1]);
  }

  // Test the case were we _just_ competely fit including the null.
  {
    char dst[8];
    wchar_t wdst[8];
    EXPECT_EQ(7U, strlcpy(dst, "abcdefg", arraysize(dst)));
    EXPECT_EQ(0, memcmp(dst, "abcdefg", 8));
    EXPECT_EQ(7U, wcslcpy(wdst, L"abcdefg", arraysize(wdst)));
    EXPECT_EQ(0, memcmp(wdst, L"abcdefg", sizeof(wchar_t) * 8));
  }

  // Test the case were we we are one smaller, so we can't fit the null.
  {
    char dst[7];
    wchar_t wdst[7];
    EXPECT_EQ(7U, strlcpy(dst, "abcdefg", arraysize(dst)));
    EXPECT_EQ(0, memcmp(dst, "abcdef", 7));
    EXPECT_EQ(7U, wcslcpy(wdst, L"abcdefg", arraysize(wdst)));
    EXPECT_EQ(0, memcmp(wdst, L"abcdef", sizeof(wchar_t) * 7));
  }

  // Test the case were we are just too small.
  {
    char dst[3];
    wchar_t wdst[3];
    EXPECT_EQ(7U, strlcpy(dst, "abcdefg", arraysize(dst)));
    EXPECT_EQ(0, memcmp(dst, "ab", 3));
    EXPECT_EQ(7U, wcslcpy(wdst, L"abcdefg", arraysize(wdst)));
    EXPECT_EQ(0, memcmp(wdst, L"ab", sizeof(wchar_t) * 3));
  }
}

TEST(StringUtilTest, WprintfFormatPortabilityTest) {
  static const struct {
    const wchar_t* input;
    bool portable;
  } cases[] = {
    { L"%ls", true },
    { L"%s", false },
    { L"%S", false },
    { L"%lS", false },
    { L"Hello, %s", false },
    { L"%lc", true },
    { L"%c", false },
    { L"%C", false },
    { L"%lC", false },
    { L"%ls %s", false },
    { L"%s %ls", false },
    { L"%s %ls %s", false },
    { L"%f", true },
    { L"%f %F", false },
    { L"%d %D", false },
    { L"%o %O", false },
    { L"%u %U", false },
    { L"%f %d %o %u", true },
    { L"%-8d (%02.1f%)", true },
    { L"% 10s", false },
    { L"% 10ls", true }
  };
  for (size_t i = 0; i < arraysize(cases); ++i)
    EXPECT_EQ(cases[i].portable, IsWprintfFormatPortable(cases[i].input));
}

TEST(StringUtilTest, RemoveChars) {
  const char kRemoveChars[] = "-/+*";
  std::string input = "A-+bc/d!*";
  EXPECT_TRUE(RemoveChars(input, kRemoveChars, &input));
  EXPECT_EQ("Abcd!", input);

  // No characters match kRemoveChars.
  EXPECT_FALSE(RemoveChars(input, kRemoveChars, &input));
  EXPECT_EQ("Abcd!", input);

  // Empty string.
  input.clear();
  EXPECT_FALSE(RemoveChars(input, kRemoveChars, &input));
  EXPECT_EQ(std::string(), input);
}

TEST(StringUtilTest, ReplaceChars) {
  struct TestData {
    const char* input;
    const char* replace_chars;
    const char* replace_with;
    const char* output;
    bool result;
  } cases[] = {
    { "", "", "", "", false },
    { "test", "", "", "test", false },
    { "test", "", "!", "test", false },
    { "test", "z", "!", "test", false },
    { "test", "e", "!", "t!st", true },
    { "test", "e", "!?", "t!?st", true },
    { "test", "ez", "!", "t!st", true },
    { "test", "zed", "!?", "t!?st", true },
    { "test", "t", "!?", "!?es!?", true },
    { "test", "et", "!>", "!>!>s!>", true },
    { "test", "zest", "!", "!!!!", true },
    { "test", "szt", "!", "!e!!", true },
    { "test", "t", "test", "testestest", true },
  };

  for (size_t i = 0; i < arraysize(cases); ++i) {
    std::string output;
    bool result = ReplaceChars(cases[i].input,
                               cases[i].replace_chars,
                               cases[i].replace_with,
                               &output);
    EXPECT_EQ(cases[i].result, result);
    EXPECT_EQ(cases[i].output, output);
  }
}

TEST(StringUtilTest, ContainsOnlyChars) {
  // Providing an empty list of characters should return false but for the empty
  // string.
  EXPECT_TRUE(ContainsOnlyChars(std::string(), std::string()));
  EXPECT_FALSE(ContainsOnlyChars("Hello", std::string()));

  EXPECT_TRUE(ContainsOnlyChars(std::string(), "1234"));
  EXPECT_TRUE(ContainsOnlyChars("1", "1234"));
  EXPECT_TRUE(ContainsOnlyChars("1", "4321"));
  EXPECT_TRUE(ContainsOnlyChars("123", "4321"));
  EXPECT_FALSE(ContainsOnlyChars("123a", "4321"));

  EXPECT_TRUE(ContainsOnlyChars(std::string(), kWhitespaceASCII));
  EXPECT_TRUE(ContainsOnlyChars(" ", kWhitespaceASCII));
  EXPECT_TRUE(ContainsOnlyChars("\t", kWhitespaceASCII));
  EXPECT_TRUE(ContainsOnlyChars("\t \r \n  ", kWhitespaceASCII));
  EXPECT_FALSE(ContainsOnlyChars("a", kWhitespaceASCII));
  EXPECT_FALSE(ContainsOnlyChars("\thello\r \n  ", kWhitespaceASCII));

  EXPECT_TRUE(ContainsOnlyChars(string16(), kWhitespaceUTF16));
  EXPECT_TRUE(ContainsOnlyChars(ASCIIToUTF16(" "), kWhitespaceUTF16));
  EXPECT_TRUE(ContainsOnlyChars(ASCIIToUTF16("\t"), kWhitespaceUTF16));
  EXPECT_TRUE(ContainsOnlyChars(ASCIIToUTF16("\t \r \n  "), kWhitespaceUTF16));
  EXPECT_FALSE(ContainsOnlyChars(ASCIIToUTF16("a"), kWhitespaceUTF16));
  EXPECT_FALSE(ContainsOnlyChars(ASCIIToUTF16("\thello\r \n  "),
                                  kWhitespaceUTF16));
}

TEST(StringUtilTest, CompareCaseInsensitiveASCII) {
  EXPECT_EQ(0, CompareCaseInsensitiveASCII("", ""));
  EXPECT_EQ(0, CompareCaseInsensitiveASCII("Asdf", "aSDf"));

  // Differing lengths.
  EXPECT_EQ(-1, CompareCaseInsensitiveASCII("Asdf", "aSDfA"));
  EXPECT_EQ(1, CompareCaseInsensitiveASCII("AsdfA", "aSDf"));

  // Differing values.
  EXPECT_EQ(-1, CompareCaseInsensitiveASCII("AsdfA", "aSDfb"));
  EXPECT_EQ(1, CompareCaseInsensitiveASCII("Asdfb", "aSDfA"));
}

TEST(StringUtilTest, EqualsCaseInsensitiveASCII) {
  EXPECT_TRUE(EqualsCaseInsensitiveASCII("", ""));
  EXPECT_TRUE(EqualsCaseInsensitiveASCII("Asdf", "aSDF"));
  EXPECT_FALSE(EqualsCaseInsensitiveASCII("bsdf", "aSDF"));
  EXPECT_FALSE(EqualsCaseInsensitiveASCII("Asdf", "aSDFz"));
}

class WriteIntoTest : public testing::Test {
 protected:
  static void WritesCorrectly(size_t num_chars) {
    std::string buffer;
    char kOriginal[] = "supercali";
    strncpy(WriteInto(&buffer, num_chars + 1), kOriginal, num_chars);
    // Using std::string(buffer.c_str()) instead of |buffer| truncates the
    // string at the first \0.
    EXPECT_EQ(std::string(kOriginal,
                          std::min(num_chars, arraysize(kOriginal) - 1)),
              std::string(buffer.c_str()));
    EXPECT_EQ(num_chars, buffer.size());
  }
};

TEST_F(WriteIntoTest, WriteInto) {
  // Validate that WriteInto reserves enough space and
  // sizes a string correctly.
  WritesCorrectly(1);
  WritesCorrectly(2);
  WritesCorrectly(5000);

  // Validate that WriteInto doesn't modify other strings
  // when using a Copy-on-Write implementation.
  const char kLive[] = "live";
  const char kDead[] = "dead";
  const std::string live = kLive;
  std::string dead = live;
  strncpy(WriteInto(&dead, 5), kDead, 4);
  EXPECT_EQ(kDead, dead);
  EXPECT_EQ(4u, dead.size());
  EXPECT_EQ(kLive, live);
  EXPECT_EQ(4u, live.size());
}

}  // namespace base
