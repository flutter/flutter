// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/core/buffer_view.h"
#include "impeller/core/device_buffer.h"
#include "impeller/core/device_buffer_descriptor.h"

namespace impeller::testing {

namespace {
struct FakeDeviceBuffer : DeviceBuffer {
  FakeDeviceBuffer() : DeviceBuffer(DeviceBufferDescriptor{}) {}
  bool SetLabel(std::string_view label) override { return true; };
  bool SetLabel(std::string_view label, Range range) override { return true; }
  [[nodiscard]]
  uint8_t* OnGetContents() const override {
    return nullptr;
  }

 protected:
  bool OnCopyHostBuffer(const uint8_t* source,
                        Range source_range,
                        size_t offset) override {
    return true;
  }
};
}  // namespace

TEST(BufferViewTest, Empty) {
  BufferView buffer_view;
  EXPECT_FALSE(buffer_view);
}

TEST(BufferViewTest, TakeRaw) {
  auto device_buffer = std::make_shared<FakeDeviceBuffer>();
  auto buffer_view =
      BufferView::CreateFromWeakDeviceBuffer(device_buffer, {0, 123});
  EXPECT_TRUE(buffer_view);
  std::shared_ptr<const DeviceBuffer> taken = buffer_view.TakeBuffer();
  EXPECT_FALSE(taken);
  EXPECT_EQ(buffer_view.GetBuffer(), device_buffer.get());
}

TEST(BufferViewTest, BufferIsInvalidIfDeviceBufferGoesOutOfScope) {
  auto device_buffer = std::make_shared<FakeDeviceBuffer>();
  auto buffer_view =
      BufferView::CreateFromWeakDeviceBuffer(device_buffer, {0, 123});
  device_buffer.reset();
  EXPECT_FALSE(buffer_view);
}

#if defined(FML_OS_POSIX) && !defined(NDEBUG)

TEST(BufferViewDeathTest, GetRawFromInvalidBufferAborts) {
  auto device_buffer = std::make_shared<FakeDeviceBuffer>();
  auto buffer_view =
      BufferView::CreateFromWeakDeviceBuffer(device_buffer, {0, 123});
  device_buffer.reset();
  EXPECT_EXIT(buffer_view.GetBuffer(), ::testing::KilledBySignal(SIGABRT),
              "Buffer view no longer holds valid data");
}

#endif

}  // namespace impeller::testing
