// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/converters/url/url_type_converters.h"

#include "mojo/public/cpp/bindings/string.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "url/gurl.h"

namespace mojo {
namespace {

TEST(UrlTypeConvertersTest, URL) {
  GURL url("mojo:foo");
  String mojo_string(String::From(url));

  ASSERT_EQ(url.spec(), mojo_string);
  EXPECT_EQ(url.spec(), mojo_string.To<GURL>().spec());
  EXPECT_EQ(url.spec(), String::From(url));

  GURL invalid = String().To<GURL>();
  ASSERT_TRUE(invalid.spec().empty());

  String string_from_invalid = String::From(invalid);
  EXPECT_FALSE(string_from_invalid.is_null());
  ASSERT_EQ(0U, string_from_invalid.size());
}

}  // namespace
}  // namespace mojo
