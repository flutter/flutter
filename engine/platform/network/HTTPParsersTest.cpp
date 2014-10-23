// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "config.h"
#include "HTTPParsers.h"

#include "wtf/MathExtras.h"
#include "wtf/testing/WTFTestHelpers.h"
#include "wtf/text/AtomicString.h"

#include <gtest/gtest.h>

namespace blink {

namespace {

size_t parseHTTPHeader(const char* data, String& failureReason, AtomicString& nameStr, AtomicString& valueStr)
{
    return blink::parseHTTPHeader(data, strlen(data), failureReason, nameStr, valueStr);
}

} // namespace

TEST(HTTPParsersTest, ParseCacheControl)
{
    CacheControlHeader header;

    header = parseCacheControlDirectives("no-cache", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_TRUE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("no-cache no-store", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_TRUE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("no-store must-revalidate", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_FALSE(header.containsNoCache);
    EXPECT_TRUE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("max-age=0", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_FALSE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_EQ(0.0, header.maxAge);

    header = parseCacheControlDirectives("max-age", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_FALSE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("max-age=0 no-cache", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_FALSE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_EQ(0.0, header.maxAge);

    header = parseCacheControlDirectives("no-cache=foo", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_FALSE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("nonsense", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_FALSE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("\rno-cache\n\t\v\0\b", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_TRUE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives("      no-cache       ", AtomicString());
    EXPECT_TRUE(header.parsed);
    EXPECT_TRUE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));

    header = parseCacheControlDirectives(AtomicString(), "no-cache");
    EXPECT_TRUE(header.parsed);
    EXPECT_TRUE(header.containsNoCache);
    EXPECT_FALSE(header.containsNoStore);
    EXPECT_FALSE(header.containsMustRevalidate);
    EXPECT_TRUE(std::isnan(header.maxAge));
}

TEST(HTTPParsersTest, parseHTTPHeaderSimple)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(12u, parseHTTPHeader("foo:   bar\r\notherdata", failureReason, name, value));
    EXPECT_TRUE(failureReason.isEmpty());
    EXPECT_EQ("foo", name.string());
    EXPECT_EQ("bar", value.string());
}

TEST(HTTPParsersTest, parseHTTPHeaderEmptyName)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader(": bar\r\notherdata", failureReason, name, value));
    EXPECT_EQ("Header name is missing", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderEmptyValue)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(7u, parseHTTPHeader("foo: \r\notherdata", failureReason, name, value));
    EXPECT_TRUE(failureReason.isEmpty());
    EXPECT_EQ("foo", name.string());
    EXPECT_TRUE(value.isEmpty());
}

TEST(HTTPParsersTest, parseHTTPHeaderInvalidName)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("\xfa: \r\notherdata", failureReason, name, value));
    EXPECT_EQ("Invalid UTF-8 sequence in header name", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderInvalidValue)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("foo: \xfa\r\notherdata", failureReason, name, value));
    EXPECT_EQ("Invalid UTF-8 sequence in header value", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderEmpty)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("", failureReason, name, value));
    EXPECT_EQ("Unterminated header name", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderEmptyLine)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(2u, parseHTTPHeader("\r\notherdata", failureReason, name, value));
    EXPECT_TRUE(failureReason.isEmpty());
    EXPECT_TRUE(name.isNull());
    EXPECT_TRUE(value.isNull());
}

TEST(HTTPParsersTest, parseHTTPHeaderUnexpectedCRinName)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("foo\rotherdata\n", failureReason, name, value));
    EXPECT_EQ("Unexpected CR in name at foo", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderUnexpectedLFinName)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("foo\notherdata\n", failureReason, name, value));
    EXPECT_EQ("Unexpected LF in name at foo", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderUnexpectedLFinValue)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("foo: bar\notherdata\n", failureReason, name, value));
    EXPECT_EQ("Unexpected LF in value at bar", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderNoLFAtEndOfLine)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("foo: bar\r", failureReason, name, value));
    EXPECT_EQ("LF doesn't follow CR after value at ", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderNoLF)
{
    String failureReason;
    AtomicString name, value;
    EXPECT_EQ(0u, parseHTTPHeader("foo: bar\rhoge\r\n", failureReason, name, value));
    EXPECT_EQ("LF doesn't follow CR after value at hoge\r\n", failureReason);
}

TEST(HTTPParsersTest, parseHTTPHeaderTwoLines)
{
    const char data[] = "foo: bar\r\nhoge: fuga\r\nxxx";
    String failureReason;
    AtomicString name, value;

    EXPECT_EQ(10u, parseHTTPHeader(data, failureReason, name, value));
    EXPECT_TRUE(failureReason.isEmpty());
    EXPECT_EQ("foo", name.string());
    EXPECT_EQ("bar", value.string());

    EXPECT_EQ(12u, parseHTTPHeader(data + 10, failureReason, name, value));
    EXPECT_TRUE(failureReason.isEmpty());
    EXPECT_EQ("hoge", name.string());
    EXPECT_EQ("fuga", value.string());
}

} // namespace blink

