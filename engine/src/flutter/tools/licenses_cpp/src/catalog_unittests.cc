// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/tools/licenses_cpp/src/catalog.h"
#include "gtest/gtest.h"

TEST(CatalogTest, Simple) {
  absl::StatusOr<Catalog> catalog = Catalog::Make({{".*foo.*", ".*foo.*"}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<bool> has_match = catalog->HasMatch("foo");
  ASSERT_TRUE(has_match.ok());
  ASSERT_TRUE(*has_match);
}

TEST(CatalogTest, MultipleMatch) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{".*foo.*", ""}, {".*oo.*", ""}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<bool> has_match = catalog->HasMatch("foo");
  ASSERT_FALSE(has_match.ok());
  ASSERT_TRUE(RE2::PartialMatch(has_match.status().message(),
                                "Multiple unique matches found"))
      << has_match.status().message();
  ASSERT_TRUE(RE2::PartialMatch(has_match.status().message(), "foo"))
      << has_match.status().message();
}
