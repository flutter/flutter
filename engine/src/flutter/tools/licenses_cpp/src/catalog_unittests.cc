// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/tools/licenses_cpp/src/catalog.h"
#include "gtest/gtest.h"

TEST(CatalogTest, Simple) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*foo.*", ".*foo.*"}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<std::string> match = catalog->FindMatch("foo");
  ASSERT_TRUE(match.ok());
  ASSERT_EQ(*match, "foobar");
}

TEST(CatalogTest, MultipleMatch) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*foo.*", ""}, {"oo", ".*oo.*", ""}});
  ASSERT_TRUE(catalog.ok()) << catalog.status();
  absl::StatusOr<std::string> has_match = catalog->FindMatch("foo");
  ASSERT_FALSE(has_match.ok());
  ASSERT_TRUE(RE2::PartialMatch(has_match.status().message(),
                                "Multiple unique matches found"))
      << has_match.status().message();
  ASSERT_TRUE(RE2::PartialMatch(has_match.status().message(), "foo"))
      << has_match.status().message();
}

TEST(CatalogTest, NoSelectorMatch) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*bar.*", ".*foo.*"}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<std::string> match = catalog->FindMatch("foo");
  ASSERT_FALSE(match.ok());
  ASSERT_EQ(match.status().code(), absl::StatusCode::kNotFound);
}

TEST(CatalogTest, NoSelectionMatch) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*foo.*", ".*bar.*"}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<std::string> match = catalog->FindMatch("foo");
  ASSERT_FALSE(match.ok());
  ASSERT_EQ(match.status().code(), absl::StatusCode::kNotFound);
}
