// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/i18n/timezone.h"

#include "testing/gtest/include/gtest/gtest.h"

namespace base {
namespace {

TEST(TimezoneTest, CountryCodeForCurrentTimezone) {
  std::string country_code = CountryCodeForCurrentTimezone();
  // On some systems (such as Android or some flavors of Linux), icu may come up
  // empty.
  if (!country_code.empty())
    EXPECT_EQ(2U, country_code.size());
}

}  // namespace
}  // namespace base
