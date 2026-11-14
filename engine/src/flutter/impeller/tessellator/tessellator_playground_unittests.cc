// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "gtest/gtest.h"

#include "flutter/display_list/geometry/dl_path_builder.h"
#include "impeller/geometry/path_source.h"
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

flutter::DlPath MakeCurvedPath() {
  flutter::DlPathBuilder builder;
  builder.MoveTo({0, 0});
  builder.LineTo({40, 0});
  builder.QuadraticCurveTo({50, 5}, {40, 40});
  builder.LineTo({0, 40});
  builder.Close();
  return builder.TakePath();
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

TEST_P(TessellatorPlaygroundTest, TessellateConvexCacheInsertsOnSecondUse) {
  auto tessellator = std::make_shared<Tessellator>(false);

  auto data_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());
  auto indexes_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());

  auto path = MakeCurvedPath();

  VertexBuffer first = tessellator->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 0u);

  VertexBuffer second = tessellator->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 1u);
  EXPECT_EQ(CopyBufferView<Point>(first.vertex_buffer),
            CopyBufferView<Point>(second.vertex_buffer));
  EXPECT_EQ(CopyBufferView<uint16_t>(first.index_buffer),
            CopyBufferView<uint16_t>(second.index_buffer));

  VertexBuffer third = tessellator->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 1u);
  EXPECT_EQ(CopyBufferView<Point>(first.vertex_buffer),
            CopyBufferView<Point>(third.vertex_buffer));

  // Copies share identity, so a copy of a path that has already been
  // tessellated once is a cache hit.
  VertexBuffer from_copy =
      tessellator->TessellateConvex(flutter::DlPath(path), *data_host_buffer,
                                    *indexes_host_buffer, 1.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 1u);
  EXPECT_EQ(CopyBufferView<Point>(first.vertex_buffer),
            CopyBufferView<Point>(from_copy.vertex_buffer));

  auto path2 = MakeCurvedPath();
  VertexBuffer other_first = tessellator->TessellateConvex(
      path2, *data_host_buffer, *indexes_host_buffer, 1.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 1u);
  EXPECT_EQ(CopyBufferView<Point>(first.vertex_buffer),
            CopyBufferView<Point>(other_first.vertex_buffer));
  tessellator->TessellateConvex(path2, *data_host_buffer, *indexes_host_buffer,
                                1.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 2u);

  tessellator->TessellateConvex(path, *data_host_buffer, *indexes_host_buffer,
                                2.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 2u);
  tessellator->TessellateConvex(path, *data_host_buffer, *indexes_host_buffer,
                                2.0, false, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 3u);
}

TEST_P(TessellatorPlaygroundTest, TessellateConvexCacheMissesOnRestartAndFan) {
  auto tessellator = std::make_shared<Tessellator>(true);

  auto data_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());
  auto indexes_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());

  auto path = MakeCurvedPath();

  VertexBuffer first = tessellator->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, true, true);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 0u);
  VertexBuffer second = tessellator->TessellateConvex(
      path, *data_host_buffer, *indexes_host_buffer, 1.0, true, true);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 1u);
  EXPECT_EQ(CopyBufferView<Point>(first.vertex_buffer),
            CopyBufferView<Point>(second.vertex_buffer));
  EXPECT_EQ(CopyBufferView<uint32_t>(first.index_buffer),
            CopyBufferView<uint32_t>(second.index_buffer));

  tessellator->TessellateConvex(path, *data_host_buffer, *indexes_host_buffer,
                                1.0, true, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 1u);
  tessellator->TessellateConvex(path, *data_host_buffer, *indexes_host_buffer,
                                1.0, true, false);
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 2u);
}

TEST_P(TessellatorPlaygroundTest, UncacheablePathSourceNeverEntersFillCache) {
  auto tessellator = std::make_shared<Tessellator>(true);

  auto data_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());
  auto indexes_host_buffer = HostBuffer::Create(
      GetContext()->GetResourceAllocator(), GetContext()->GetIdleWaiter(),
      GetContext()->GetCapabilities()->GetMinimumUniformAlignment());

  RectPathSource rect(Rect::MakeLTRB(0, 0, 10, 10));
  ASSERT_EQ(rect.GetCacheIdentity(), nullptr);
  for (int i = 0; i < 3; i++) {
    tessellator->TessellateConvex(rect, *data_host_buffer, *indexes_host_buffer,
                                  1.0, true, true);
  }
  EXPECT_EQ(tessellator->GetFillTessellationCacheSizeForTesting(), 0u);
}

}  // namespace testing
}  // namespace impeller
