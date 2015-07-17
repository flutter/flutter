// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "crypto/openssl_bio_string.h"

#include <openssl/bio.h>

#include "crypto/scoped_openssl_types.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace crypto {

TEST(OpenSSLBIOString, TestWrite) {
  std::string s;
  const std::string expected1("a one\nb 2\n");
  const std::string expected2("c d e f");
  const std::string expected3("g h i");
  {
    ScopedBIO bio(BIO_new_string(&s));
    ASSERT_TRUE(bio.get());

    EXPECT_EQ(static_cast<int>(expected1.size()),
              BIO_printf(bio.get(), "a %s\nb %i\n", "one", 2));
    EXPECT_EQ(expected1, s);

    EXPECT_EQ(1, BIO_flush(bio.get()));
    EXPECT_EQ(expected1, s);

    EXPECT_EQ(static_cast<int>(expected2.size()),
              BIO_write(bio.get(), expected2.data(), expected2.size()));
    EXPECT_EQ(expected1 + expected2, s);

    EXPECT_EQ(static_cast<int>(expected3.size()),
              BIO_puts(bio.get(), expected3.c_str()));
    EXPECT_EQ(expected1 + expected2 + expected3, s);
  }
  EXPECT_EQ(expected1 + expected2 + expected3, s);
}

TEST(OpenSSLBIOString, TestReset) {
  std::string s;
  const std::string expected1("a b c\n");
  const std::string expected2("d e f g\n");
  {
    ScopedBIO bio(BIO_new_string(&s));
    ASSERT_TRUE(bio.get());

    EXPECT_EQ(static_cast<int>(expected1.size()),
              BIO_write(bio.get(), expected1.data(), expected1.size()));
    EXPECT_EQ(expected1, s);

    EXPECT_EQ(1, BIO_reset(bio.get()));
    EXPECT_EQ(std::string(), s);

    EXPECT_EQ(static_cast<int>(expected2.size()),
              BIO_write(bio.get(), expected2.data(), expected2.size()));
    EXPECT_EQ(expected2, s);
  }
  EXPECT_EQ(expected2, s);
}

}  // namespace crypto
