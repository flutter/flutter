// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/string_number_conversions.h"

#include <stdint.h>

#include <limits>

#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace util {
namespace {

TEST(StringNumberConversionsTest, NumberToString_Basic) {
  EXPECT_EQ("0", NumberToString<int32_t>(static_cast<int32_t>(0)));
  EXPECT_EQ("123", NumberToString<int32_t>(static_cast<int32_t>(123)));
  EXPECT_EQ("-456", NumberToString<int32_t>(static_cast<int32_t>(-456)));

  EXPECT_EQ("0", NumberToString<uint32_t>(static_cast<uint32_t>(0)));
  EXPECT_EQ("123", NumberToString<uint32_t>(static_cast<uint32_t>(123)));

  EXPECT_EQ("0", NumberToString<int>(0));
  EXPECT_EQ("123", NumberToString<int>(123));
  EXPECT_EQ("-456", NumberToString<int>(-456));

  EXPECT_EQ("0", NumberToString<unsigned>(0u));
  EXPECT_EQ("123", NumberToString<unsigned>(123u));

  EXPECT_EQ("1", NumberToString<int>(1));
  EXPECT_EQ("12", NumberToString<int>(12));
  EXPECT_EQ("123", NumberToString<int>(123));
  EXPECT_EQ("1234", NumberToString<int>(1234));
  EXPECT_EQ("12345", NumberToString<int>(12345));
  EXPECT_EQ("123456", NumberToString<int>(123456));
  EXPECT_EQ("1234567", NumberToString<int>(1234567));
  EXPECT_EQ("12345678", NumberToString<int>(12345678));
  EXPECT_EQ("123456789", NumberToString<int>(123456789));
  EXPECT_EQ("-1", NumberToString<int>(-1));
  EXPECT_EQ("-12", NumberToString<int>(-12));
  EXPECT_EQ("-123", NumberToString<int>(-123));
  EXPECT_EQ("-1234", NumberToString<int>(-1234));
  EXPECT_EQ("-12345", NumberToString<int>(-12345));
  EXPECT_EQ("-123456", NumberToString<int>(-123456));
  EXPECT_EQ("-1234567", NumberToString<int>(-1234567));
  EXPECT_EQ("-12345678", NumberToString<int>(-12345678));
  EXPECT_EQ("-123456789", NumberToString<int>(-123456789));
}

TEST(StringNumberConversionsTest, NumberToString_StdintTypes) {
  EXPECT_EQ("0", NumberToString<int8_t>(static_cast<int8_t>(0)));
  EXPECT_EQ("127", NumberToString<int8_t>(std::numeric_limits<int8_t>::max()));
  EXPECT_EQ("-128", NumberToString<int8_t>(std::numeric_limits<int8_t>::min()));

  EXPECT_EQ("0", NumberToString<uint8_t>(static_cast<uint8_t>(0)));
  EXPECT_EQ("255",
            NumberToString<uint8_t>(std::numeric_limits<uint8_t>::max()));

  EXPECT_EQ("0", NumberToString<int16_t>(static_cast<int16_t>(0)));
  EXPECT_EQ("32767",
            NumberToString<int16_t>(std::numeric_limits<int16_t>::max()));
  EXPECT_EQ("-32768",
            NumberToString<int16_t>(std::numeric_limits<int16_t>::min()));

  EXPECT_EQ("0", NumberToString<uint16_t>(static_cast<uint16_t>(0)));
  EXPECT_EQ("65535",
            NumberToString<uint16_t>(std::numeric_limits<uint16_t>::max()));

  EXPECT_EQ("0", NumberToString<int32_t>(static_cast<int32_t>(0)));
  EXPECT_EQ("2147483647",
            NumberToString<int32_t>(std::numeric_limits<int32_t>::max()));
  EXPECT_EQ("-2147483648",
            NumberToString<int32_t>(std::numeric_limits<int32_t>::min()));

  EXPECT_EQ("0", NumberToString<uint32_t>(static_cast<uint32_t>(0)));
  EXPECT_EQ("4294967295",
            NumberToString<uint32_t>(std::numeric_limits<uint32_t>::max()));

  EXPECT_EQ("0", NumberToString<int64_t>(static_cast<int64_t>(0)));
  EXPECT_EQ("9223372036854775807",
            NumberToString<int64_t>(std::numeric_limits<int64_t>::max()));
  EXPECT_EQ("-9223372036854775808",
            NumberToString<int64_t>(std::numeric_limits<int64_t>::min()));

  EXPECT_EQ("0", NumberToString<uint64_t>(static_cast<uint64_t>(0)));
  EXPECT_EQ("18446744073709551615",
            NumberToString<uint64_t>(std::numeric_limits<uint64_t>::max()));
}

TEST(StringNumberConversionsTest, StringToNumberWithError_Basic) {
  {
    int32_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<int32_t>("0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("123", &number));
    EXPECT_EQ(123, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("-456", &number));
    EXPECT_EQ(-456, number);
  }

  {
    uint32_t number = 42u;
    EXPECT_TRUE(StringToNumberWithError<uint32_t>("0", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(StringToNumberWithError<uint32_t>("123", &number));
    EXPECT_EQ(123u, number);
  }

  {
    int number = 42;
    EXPECT_TRUE(StringToNumberWithError<int>("0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int>("123", &number));
    EXPECT_EQ(123, number);
    EXPECT_TRUE(StringToNumberWithError<int>("-456", &number));
    EXPECT_EQ(-456, number);
  }

  {
    unsigned number = 42u;
    EXPECT_TRUE(StringToNumberWithError<unsigned>("0", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(StringToNumberWithError<unsigned>("123", &number));
    EXPECT_EQ(123u, number);
  }
}

TEST(StringNumberConversionsTest, StringToNumberWithError_Errors) {
  {
    int32_t number = 42;
    EXPECT_FALSE(StringToNumberWithError<int32_t>("", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("/", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>(":", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("A", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("0x", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("123x", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("+123", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("999999999999999", &number));
    EXPECT_EQ(42, number);
  }

  {
    uint32_t number = 42u;
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("/", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>(":", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("A", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("0x", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("123x", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("+123", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("999999999999999", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("-123", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("-0", &number));
    EXPECT_EQ(42u, number);
  }
}

TEST(StringNumberConversionsTest, StringToNumberWithError_LeadingZeros) {
  {
    int32_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<int32_t>("00", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("0123", &number));
    EXPECT_EQ(123, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("-0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("-00", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("-0456", &number));
    EXPECT_EQ(-456, number);
  }

  {
    uint32_t number = 42u;
    EXPECT_TRUE(StringToNumberWithError<uint32_t>("00", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(StringToNumberWithError<uint32_t>("0123", &number));
    EXPECT_EQ(123u, number);
  }
}

TEST(StringNumberConversionsTest, StringToNumberWithError_StdintTypes) {
  {
    int8_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<int8_t>("0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int8_t>("127", &number));
    EXPECT_EQ(std::numeric_limits<int8_t>::max(), number);
    EXPECT_TRUE(StringToNumberWithError<int8_t>("-128", &number));
    EXPECT_EQ(std::numeric_limits<int8_t>::min(), number);
    EXPECT_FALSE(StringToNumberWithError<int8_t>("128", &number));
    EXPECT_FALSE(StringToNumberWithError<int8_t>("-129", &number));
  }

  {
    uint8_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<uint8_t>("0", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(StringToNumberWithError<uint8_t>("255", &number));
    EXPECT_EQ(std::numeric_limits<uint8_t>::max(), number);
    EXPECT_FALSE(StringToNumberWithError<uint8_t>("256", &number));
    EXPECT_FALSE(StringToNumberWithError<uint8_t>("-1", &number));
  }

  {
    int16_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<int16_t>("0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int16_t>("32767", &number));
    EXPECT_EQ(std::numeric_limits<int16_t>::max(), number);
    EXPECT_TRUE(StringToNumberWithError<int16_t>("-32768", &number));
    EXPECT_EQ(std::numeric_limits<int16_t>::min(), number);
    EXPECT_FALSE(StringToNumberWithError<int16_t>("32768", &number));
    EXPECT_FALSE(StringToNumberWithError<int16_t>("-32769", &number));
  }

  {
    uint16_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<uint16_t>("0", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(StringToNumberWithError<uint16_t>("65535", &number));
    EXPECT_EQ(std::numeric_limits<uint16_t>::max(), number);
    EXPECT_FALSE(StringToNumberWithError<uint16_t>("65536", &number));
    EXPECT_FALSE(StringToNumberWithError<uint16_t>("-1", &number));
  }

  {
    int32_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<int32_t>("0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("2147483647", &number));
    EXPECT_EQ(std::numeric_limits<int32_t>::max(), number);
    EXPECT_TRUE(StringToNumberWithError<int32_t>("-2147483648", &number));
    EXPECT_EQ(std::numeric_limits<int32_t>::min(), number);
    EXPECT_FALSE(StringToNumberWithError<int32_t>("2147483648", &number));
    EXPECT_FALSE(StringToNumberWithError<int32_t>("-2147483649", &number));
  }

  {
    uint32_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<uint32_t>("0", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(StringToNumberWithError<uint32_t>("4294967295", &number));
    EXPECT_EQ(std::numeric_limits<uint32_t>::max(), number);
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("4294967296", &number));
    EXPECT_FALSE(StringToNumberWithError<uint32_t>("-1", &number));
  }

  {
    int64_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<int64_t>("0", &number));
    EXPECT_EQ(0, number);
    EXPECT_TRUE(
        StringToNumberWithError<int64_t>("9223372036854775807", &number));
    EXPECT_EQ(std::numeric_limits<int64_t>::max(), number);
    EXPECT_TRUE(
        StringToNumberWithError<int64_t>("-9223372036854775808", &number));
    EXPECT_EQ(std::numeric_limits<int64_t>::min(), number);
    EXPECT_FALSE(
        StringToNumberWithError<int64_t>("9223372036854775808", &number));
    EXPECT_FALSE(
        StringToNumberWithError<int64_t>("-9223372036854775809", &number));
  }

  {
    uint64_t number = 42;
    EXPECT_TRUE(StringToNumberWithError<uint64_t>("0", &number));
    EXPECT_EQ(0u, number);
    EXPECT_TRUE(
        StringToNumberWithError<uint64_t>("18446744073709551615", &number));
    EXPECT_EQ(std::numeric_limits<uint64_t>::max(), number);
    EXPECT_FALSE(
        StringToNumberWithError<uint64_t>("18446744073709551616", &number));
    EXPECT_FALSE(StringToNumberWithError<uint64_t>("-1", &number));
  }
}

TEST(StringNumberConversionsTest, StringToNumber_Basic) {
  EXPECT_EQ(0, StringToNumber<int32_t>("0"));
  EXPECT_EQ(123, StringToNumber<int32_t>("123"));
  EXPECT_EQ(-456, StringToNumber<int32_t>("-456"));

  EXPECT_EQ(0u, StringToNumber<uint32_t>("0"));
  EXPECT_EQ(123u, StringToNumber<uint32_t>("123"));

  EXPECT_EQ(0, StringToNumber<int>("0"));
  EXPECT_EQ(123, StringToNumber<int>("123"));
  EXPECT_EQ(-456, StringToNumber<int>("-456"));

  EXPECT_EQ(0u, StringToNumber<unsigned>("0"));
  EXPECT_EQ(123u, StringToNumber<unsigned>("123"));
}

TEST(StringNumberConversionsTest, StringToNumber_Errors) {
  EXPECT_EQ(0, StringToNumber<int32_t>(""));
  EXPECT_EQ(0, StringToNumber<int32_t>("/"));
  EXPECT_EQ(0, StringToNumber<int32_t>(":"));
  EXPECT_EQ(0, StringToNumber<int32_t>("A"));
  EXPECT_EQ(0, StringToNumber<int32_t>("0x"));
  EXPECT_EQ(0, StringToNumber<int32_t>("123x"));
  EXPECT_EQ(0, StringToNumber<int32_t>("+123"));
  EXPECT_EQ(0, StringToNumber<int32_t>("999999999999999"));

  EXPECT_EQ(0u, StringToNumber<uint32_t>(""));
  EXPECT_EQ(0u, StringToNumber<uint32_t>("/"));
  EXPECT_EQ(0u, StringToNumber<uint32_t>(":"));
  EXPECT_EQ(0u, StringToNumber<uint32_t>("A"));
  EXPECT_EQ(0u, StringToNumber<uint32_t>("0x"));
  EXPECT_EQ(0u, StringToNumber<uint32_t>("123x"));
  EXPECT_EQ(0u, StringToNumber<uint32_t>("+123"));
  EXPECT_EQ(0u, StringToNumber<uint32_t>("999999999999999"));
}

}  // namespace
}  // namespace util
}  // namespace mojo
