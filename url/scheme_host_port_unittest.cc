// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "testing/gtest/include/gtest/gtest.h"
#include "url/gurl.h"
#include "url/scheme_host_port.h"

namespace {

TEST(SchemeHostPortTest, Invalid) {
  url::SchemeHostPort invalid;
  EXPECT_EQ("", invalid.scheme());
  EXPECT_EQ("", invalid.host());
  EXPECT_EQ(0, invalid.port());
  EXPECT_TRUE(invalid.IsInvalid());
  EXPECT_TRUE(invalid.Equals(invalid));

  const char* urls[] = {"data:text/html,Hello!",
                        "javascript:alert(1)",
                        "file://example.com:443/etc/passwd",
                        "blob:https://example.com/uuid-goes-here",
                        "filesystem:https://example.com/temporary/yay.png"};

  for (const auto& test : urls) {
    SCOPED_TRACE(test);
    GURL url(test);
    url::SchemeHostPort tuple(url);
    EXPECT_EQ("", tuple.scheme());
    EXPECT_EQ("", tuple.host());
    EXPECT_EQ(0, tuple.port());
    EXPECT_TRUE(tuple.IsInvalid());
    EXPECT_TRUE(tuple.Equals(tuple));
    EXPECT_TRUE(tuple.Equals(invalid));
    EXPECT_TRUE(invalid.Equals(tuple));
  }
}

TEST(SchemeHostPortTest, ExplicitConstruction) {
  struct TestCases {
    const char* scheme;
    const char* host;
    uint16 port;
  } cases[] = {
      {"http", "example.com", 80},
      {"http", "example.com", 123},
      {"https", "example.com", 443},
      {"https", "example.com", 123},
      {"file", "", 0},
      {"file", "example.com", 0},
  };

  for (const auto& test : cases) {
    SCOPED_TRACE(testing::Message() << test.scheme << "://" << test.host << ":"
                                    << test.port);
    url::SchemeHostPort tuple(test.scheme, test.host, test.port);
    EXPECT_EQ(test.scheme, tuple.scheme());
    EXPECT_EQ(test.host, tuple.host());
    EXPECT_EQ(test.port, tuple.port());
    EXPECT_FALSE(tuple.IsInvalid());
    EXPECT_TRUE(tuple.Equals(tuple));
  }
}

TEST(SchemeHostPortTest, GURLConstruction) {
  struct TestCases {
    const char* url;
    const char* scheme;
    const char* host;
    uint16 port;
  } cases[] = {
      {"http://192.168.9.1/", "http", "192.168.9.1", 80},
      {"http://[2001:db8::1]/", "http", "[2001:db8::1]", 80},
      {"http://☃.net/", "http", "xn--n3h.net", 80},
      {"http://example.com/", "http", "example.com", 80},
      {"http://example.com:123/", "http", "example.com", 123},
      {"https://example.com/", "https", "example.com", 443},
      {"https://example.com:123/", "https", "example.com", 123},
      {"file:///etc/passwd", "file", "", 0},
      {"file://example.com/etc/passwd", "file", "example.com", 0},
      {"http://u:p@example.com/", "http", "example.com", 80},
      {"http://u:p@example.com/path", "http", "example.com", 80},
      {"http://u:p@example.com/path?123", "http", "example.com", 80},
      {"http://u:p@example.com/path?123#hash", "http", "example.com", 80},
  };

  for (const auto& test : cases) {
    SCOPED_TRACE(test.url);
    GURL url(test.url);
    EXPECT_TRUE(url.is_valid());
    url::SchemeHostPort tuple(url);
    EXPECT_EQ(test.scheme, tuple.scheme());
    EXPECT_EQ(test.host, tuple.host());
    EXPECT_EQ(test.port, tuple.port());
    EXPECT_FALSE(tuple.IsInvalid());
    EXPECT_TRUE(tuple.Equals(tuple));
  }
}

TEST(SchemeHostPortTest, Serialization) {
  struct TestCases {
    const char* url;
    const char* expected;
  } cases[] = {
      {"http://192.168.9.1/", "http://192.168.9.1"},
      {"http://[2001:db8::1]/", "http://[2001:db8::1]"},
      {"http://☃.net/", "http://xn--n3h.net"},
      {"http://example.com/", "http://example.com"},
      {"http://example.com:123/", "http://example.com:123"},
      {"https://example.com/", "https://example.com"},
      {"https://example.com:123/", "https://example.com:123"},
      {"file:///etc/passwd", "file://"},
      {"file://example.com/etc/passwd", "file://example.com"},
  };

  for (const auto& test : cases) {
    SCOPED_TRACE(test.url);
    GURL url(test.url);
    url::SchemeHostPort tuple(url);
    EXPECT_EQ(test.expected, tuple.Serialize());
  }
}

TEST(SchemeHostPortTest, Comparison) {
  // These tuples are arranged in increasing order:
  struct SchemeHostPorts {
    const char* scheme;
    const char* host;
    uint16 port;
  } tuples[] = {
      {"http", "a", 80},
      {"http", "b", 80},
      {"https", "a", 80},
      {"https", "b", 80},
      {"http", "a", 81},
      {"http", "b", 81},
      {"https", "a", 81},
      {"https", "b", 81},
  };

  for (size_t i = 0; i < arraysize(tuples); i++) {
    url::SchemeHostPort current(tuples[i].scheme, tuples[i].host,
                                tuples[i].port);
    for (size_t j = i; j < arraysize(tuples); j++) {
      url::SchemeHostPort to_compare(tuples[j].scheme, tuples[j].host,
                                     tuples[j].port);
      EXPECT_EQ(i < j, current < to_compare) << i << " < " << j;
      EXPECT_EQ(j < i, to_compare < current) << j << " < " << i;
    }
  }
}

}  // namespace url
