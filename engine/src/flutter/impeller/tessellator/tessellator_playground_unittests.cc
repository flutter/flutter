// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "impeller/playground/playground_test.h"
#include "impeller/tessellator/tessellator.h"

namespace impeller {
namespace testing {

using TessellatorPlaygroundTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(TessellatorPlaygroundTest);

template <typename T>
std::vector<T> CopyBufferView(const BufferView& vertex_buffer) {
  Range range = vertex_buffer.GetRange();
  uint8_t* base_ptr = vertex_buffer.GetBuffer()->OnGetContents() + range.offset;
  return std::vector<T>(reinterpret_cast<T*>(base_ptr),
                        reinterpret_cast<T*>(base_ptr + range.length));
}

TEST_P(TessellatorPlaygroundTest, TessellateConvex16or32Bit) {
  auto tessellator16 = std::make_shared<Tessellator>(false);
  auto tessellator32 = std::make_shared<Tessellator>(true);

  auto data_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());
  auto indexes_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());

  auto path = flutter::DlPath::MakeRect(Rect::MakeLTRB(0, 0, 10, 10));

  auto vertex_buffer16 = tessellator16->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, false, false);
  auto vertex_buffer32 = tessellator32->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, false, false);

  const std::vector<Point> expected = {
      {0, 0}, {10, 0}, {10, 10}, {0, 10}, {0, 0}};
  const std::vector<uint16_t> expected_indices = {0, 1, 3, 2};

  EXPECT_EQ(vertex_buffer16.index_type, IndexType::k16bit);
  EXPECT_EQ(expected, CopyBufferView<Point>(vertex_buffer16.vertex_buffer));
  EXPECT_EQ(expected_indices,
            CopyBufferView<uint16_t>(vertex_buffer16.index_buffer));

  EXPECT_EQ(vertex_buffer32.index_type, IndexType::k32bit);
  EXPECT_EQ(expected, CopyBufferView<Point>(vertex_buffer32.vertex_buffer));
  EXPECT_EQ(
      std::vector<uint32_t>(expected_indices.begin(), expected_indices.end()),
      CopyBufferView<uint32_t>(vertex_buffer32.index_buffer));
}

}  // namespace testing
}  // namespace impeller
