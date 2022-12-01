// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
#include "flutter/shell/platform/windows/cursor_handler.h"

#include <memory>
#include <vector>

#include "gmock/gmock.h"
#include "gtest/gtest.h"

namespace flutter {
namespace testing {
TEST(CursorHandlerTest, CreateDummyCursor) {
  // Create a 4x4 rawBGRA dummy cursor buffer.
  std::vector<uint8_t> buffer;
  for (int i = 0; i < 4 * 4 * 4; i++) {
    buffer.push_back(0);
  }
  // Create the cursor from buffer provided above.
  auto cursor = GetCursorFromBuffer(buffer, 0.0, 0.0, 4, 4);
  // Expect cursor is not null.
  EXPECT_NE(cursor, nullptr);
}

}  // namespace testing
}  // namespace flutter
