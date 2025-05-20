// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/tools/licenses_cpp/src/catalog.h"
#include "gtest/gtest.h"

TEST(CatalogTest, Simple) {
  Catalog::Entries entries;
  entries["foo"] = std::make_unique<RE2>("(.*foo.*)");
  Catalog catalog(std::make_unique<RE2>("(.*foo.*)"), std::move(entries));

  absl::StatusOr<bool> has_match = catalog.HasMatch("foo");
  ASSERT_TRUE(has_match.ok());
  ASSERT_TRUE(*has_match);
}
