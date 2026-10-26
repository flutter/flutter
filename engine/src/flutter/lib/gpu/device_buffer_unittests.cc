// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/gpu/device_buffer.h"

#include <memory>
#include <optional>

#include "fml/memory/ref_ptr.h"
#include "gmock/gmock.h"
#include "gtest/gtest.h"
#include "impeller/core/range.h"
#include "impeller/renderer/testing/mocks.h"

namespace flutter::gpu {
namespace {

using ::testing::_;
using ::testing::Optional;

class FlushRecordingDeviceBuffer : public impeller::testing::MockDeviceBuffer {
 public:
  explicit FlushRecordingDeviceBuffer(
      const impeller::DeviceBufferDescriptor& desc)
      : MockDeviceBuffer(desc) {}

  MOCK_METHOD(void,
              Flush,
              (std::optional<impeller::Range> range),
              (const, override));
};

struct TestBuffer {
  std::shared_ptr<FlushRecordingDeviceBuffer> impeller_buffer;
  fml::RefPtr<DeviceBuffer> buffer;
};

TestBuffer MakeHostVisibleBuffer(size_t size) {
  impeller::DeviceBufferDescriptor desc;
  desc.storage_mode = impeller::StorageMode::kHostVisible;
  desc.size = size;
  auto impeller_buffer = std::make_shared<FlushRecordingDeviceBuffer>(desc);
  return {impeller_buffer, fml::MakeRefCounted<DeviceBuffer>(impeller_buffer)};
}

// `DeviceBuffer.flush()` in Dart defaults to a length of -1. That must flush
// the whole buffer, not a range of SIZE_MAX bytes.
TEST(FlutterGpuDeviceBufferTest, FlushWithNegativeLengthFlushesWholeBuffer) {
  auto [impeller_buffer, buffer] = MakeHostVisibleBuffer(64);

  EXPECT_CALL(*impeller_buffer, Flush(Optional(impeller::Range(0, 64))));

  EXPECT_TRUE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 0, -1));
}

TEST(FlutterGpuDeviceBufferTest, FlushWithNegativeLengthFlushesToTheEnd) {
  auto [impeller_buffer, buffer] = MakeHostVisibleBuffer(64);

  EXPECT_CALL(*impeller_buffer, Flush(Optional(impeller::Range(16, 48))));

  EXPECT_TRUE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 16, -1));
}

TEST(FlutterGpuDeviceBufferTest, FlushPassesExplicitRange) {
  auto [impeller_buffer, buffer] = MakeHostVisibleBuffer(64);

  EXPECT_CALL(*impeller_buffer, Flush(Optional(impeller::Range(8, 16))));

  EXPECT_TRUE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 8, 16));
}

TEST(FlutterGpuDeviceBufferTest, FlushRejectsRangesOutsideTheBuffer) {
  auto [impeller_buffer, buffer] = MakeHostVisibleBuffer(64);

  EXPECT_CALL(*impeller_buffer, Flush(_)).Times(0);

  EXPECT_FALSE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), -1, 4));
  EXPECT_FALSE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 65, -1));
  // An offset equal to the size is rejected, as DeviceBuffer.flush does.
  EXPECT_FALSE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 64, -1));
  EXPECT_FALSE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 64, 0));
  EXPECT_FALSE(InternalFlutterGpu_DeviceBuffer_Flush(buffer.get(), 32, 33));
}

}  // namespace
}  // namespace flutter::gpu
