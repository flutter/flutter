// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/tools/licenses_cpp/src/catalog.h"
#include "gtest/gtest.h"

static const char* kEntry = R"entry(google
Copyright \(c\) \d+ Google Inc
Copyright \(c\) \d+ Google Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  \* Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  \* Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

  \* Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES \(INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION\) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
\(INCLUDING NEGLIGENCE OR OTHERWISE\) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
)entry";

static const char* kSkiaLicense =
    R"entry(Copyright (c) 2011 Google Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in
    the documentation and/or other materials provided with the
    distribution.

  * Neither the name of the copyright holder nor the names of its
    contributors may be used to endorse or promote products derived
    from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
)entry";

TEST(CatalogTest, Simple) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*foo.*", ".*foo.*"}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<Catalog::Match> match = catalog->FindMatch("foo");
  ASSERT_TRUE(match.ok());
  ASSERT_EQ(match->matcher, "foobar");
}

TEST(CatalogTest, MultipleMatch) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*foo.*", ""}, {"oo", ".*oo.*", ""}});
  ASSERT_TRUE(catalog.ok()) << catalog.status();
  absl::StatusOr<Catalog::Match> has_match = catalog->FindMatch("foo");
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
  absl::StatusOr<Catalog::Match> match = catalog->FindMatch("foo");
  ASSERT_FALSE(match.ok());
  ASSERT_EQ(match.status().code(), absl::StatusCode::kNotFound);
}

TEST(CatalogTest, NoSelectionMatch) {
  absl::StatusOr<Catalog> catalog =
      Catalog::Make({{"foobar", ".*foo.*", ".*bar.*"}});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<Catalog::Match> match = catalog->FindMatch("foo");
  ASSERT_FALSE(match.ok());
  ASSERT_EQ(match.status().code(), absl::StatusCode::kNotFound);
}

TEST(CatalogTest, SimpleParseEntry) {
  std::stringstream ss;
  ss << "foobar\n";
  ss << "unique\n";
  ss << R"match(Multiline
matcher
.*)match";

  absl::StatusOr<Catalog::Entry> entry = Catalog::ParseEntry(ss);
  EXPECT_TRUE(entry.ok()) << entry.status();
  if (entry.ok()) {
    EXPECT_EQ(entry->name, "foobar");
    EXPECT_EQ(entry->unique, "unique");
    EXPECT_EQ(entry->matcher, R"match(Multiline
matcher
.*)match");
  }
}

TEST(CatalogTest, SkiaLicense) {
  std::stringstream ss;
  ss << kEntry;
  absl::StatusOr<Catalog::Entry> entry = Catalog::ParseEntry(ss);
  ASSERT_TRUE(entry.ok()) << entry.status();
  absl::StatusOr<Catalog> catalog = Catalog::Make({*entry});
  ASSERT_TRUE(catalog.ok());
  absl::StatusOr<Catalog::Match> match = catalog->FindMatch(kSkiaLicense);
  EXPECT_TRUE(match.ok()) << match.status();
}
