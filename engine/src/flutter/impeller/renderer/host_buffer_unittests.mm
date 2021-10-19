// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/renderer/host_buffer.h"

namespace impeller {
namespace testing {

TEST(HostBufferTest, TestInitialization) {
  ASSERT_TRUE(HostBuffer::Create());
  // Newly allocated buffers don't touch the heap till they have to.
  ASSERT_EQ(HostBuffer::Create()->GetLength(), 0u);
  ASSERT_EQ(HostBuffer::Create()->GetReservedLength(), 0u);
}

TEST(HostBufferTest, CanEmplace) {
  struct Length2 {
    uint8_t pad[2];
  };
  static_assert(sizeof(Length2) == 2u);

  auto buffer = HostBuffer::Create();

  for (size_t i = 0; i < 12500; i++) {
    auto view = buffer->Emplace(Length2{});
    ASSERT_TRUE(view);
    ASSERT_EQ(buffer->GetLength(), (i + 1) * sizeof(Length2));
    ASSERT_EQ(view.range, Range(i * sizeof(Length2), 2u));
  }
}

TEST(HostBufferTest, CanEmplaceWithAlignment) {
  struct Length2 {
    uint8_t pad[2];
  };
  static_assert(sizeof(Length2) == 2);
  struct alignas(16) Align16 {
    uint8_t pad[2];
  };
  static_assert(alignof(Align16) == 16);
  static_assert(sizeof(Align16) == 16);

  auto buffer = HostBuffer::Create();
  ASSERT_TRUE(buffer);

  {
    auto view = buffer->Emplace(Length2{});
    ASSERT_TRUE(view);
    ASSERT_EQ(buffer->GetLength(), 2u);
    ASSERT_EQ(view.range, Range(0u, 2u));
  }

  {
    auto view = buffer->Emplace(Align16{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.range.offset, 16u);
    ASSERT_EQ(view.range.length, 16u);
    ASSERT_EQ(buffer->GetLength(), 32u);
  }
  {
    auto view = buffer->Emplace(Length2{});
    ASSERT_TRUE(view);
    ASSERT_EQ(buffer->GetLength(), 34u);
    ASSERT_EQ(view.range, Range(32u, 2u));
  }

  {
    auto view = buffer->Emplace(Align16{});
    ASSERT_TRUE(view);
    ASSERT_EQ(view.range.offset, 48u);
    ASSERT_EQ(view.range.length, 16u);
    ASSERT_EQ(buffer->GetLength(), 64u);
  }
}

}  // namespace  testing
}  // namespace impeller
