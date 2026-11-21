// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_glib_compat.h"

#include <cstring>

#include "gtest/gtest.h"

TEST(FlGlibCompatTest, CopiesBinaryDataIntoIndependentStorage) {
  const guint8 source[] = {0x00, 0x7f, 0x80, 0xff, 0x00};
  g_autofree guint8* copy =
      static_cast<guint8*>(g_memdup2(source, sizeof(source)));

  ASSERT_NE(copy, nullptr);
  EXPECT_NE(copy, source);
  EXPECT_EQ(memcmp(copy, source, sizeof(source)), 0);
  copy[1] = 0;
  EXPECT_EQ(source[1], 0x7f);
}

TEST(FlGlibCompatTest, NullSourceReturnsNull) {
  EXPECT_EQ(g_memdup2(nullptr, 10), nullptr);
}

TEST(FlGlibCompatTest, ZeroSizeReturnsNull) {
  const guint8 source = 0x7f;
  EXPECT_EQ(g_memdup2(&source, 0), nullptr);
  EXPECT_EQ(g_memdup2(nullptr, 0), nullptr);
}

#if !GLIB_CHECK_VERSION(2, 68, 0) && GLIB_SIZEOF_SIZE_T > 4
TEST(FlGlibCompatTest, RejectsSizesThatWouldTruncate) {
  const guint8 source = 0x7f;
  // Without the guard this wraps to one byte in the legacy guint API.
  const gsize size = static_cast<gsize>(G_MAXUINT) + 2;
  g_test_expect_message(nullptr, G_LOG_LEVEL_CRITICAL,
                        "*byte_size <= G_MAXUINT*");
  g_autofree gpointer copy = g_memdup2(&source, size);
  EXPECT_EQ(copy, nullptr);
  g_test_assert_expected_messages();
}
#endif
