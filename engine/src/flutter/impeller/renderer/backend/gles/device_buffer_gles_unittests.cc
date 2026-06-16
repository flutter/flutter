// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"  // IWYU pragma: keep
#include "gtest/gtest.h"
#include "impeller/renderer/backend/gles/device_buffer_gles.h"
#include "impeller/renderer/backend/gles/test/mock_gles.h"

namespace impeller {
namespace testing {

using ::testing::_;

namespace {
class TestWorker : public ReactorGLES::Worker {
 public:
  bool CanReactorReactOnCurrentThreadNow(
      const ReactorGLES& reactor) const override {
    return true;
  }
};
}  // namespace

// A Flush() that lands while BindAndUploadDataIfNecessary is mid-upload (as
// happens when another thread writes to a host-visible buffer during the GL
// upload) must not be discarded; the next bind must upload the new range.
TEST(DeviceBufferGLESTest, FlushDuringUploadIsNotDiscarded) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  DeviceBufferGLES* device_buffer_ptr = nullptr;
  int upload_count = 0;
  EXPECT_CALL(*mock_gles_impl, BufferSubData(_, _, _, _))
      .Times(2)
      .WillRepeatedly([&](GLenum target, GLintptr offset, GLsizeiptr size,
                          const void* data) {
        ++upload_count;
        if (upload_count == 1) {
          // Simulates a writer thread flushing new data during the upload.
          device_buffer_ptr->Flush(Range{0, 4});
        }
      });

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{16}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = 16}, reactor,
                                 std::move(backing_store));
  device_buffer_ptr = &device_buffer;

  device_buffer.Flush(Range{0, 4});
  // First bind uploads the flushed range; the mock flushes again mid-upload.
  EXPECT_TRUE(device_buffer.BindAndUploadDataIfNecessary(
      DeviceBufferGLES::BindingType::kArrayBuffer));
  // Second bind must see the mid-upload flush and upload again.
  EXPECT_TRUE(device_buffer.BindAndUploadDataIfNecessary(
      DeviceBufferGLES::BindingType::kArrayBuffer));
  EXPECT_EQ(upload_count, 2);
}

TEST(DeviceBufferGLESTest, BindUniformData) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();

  EXPECT_CALL(*mock_gles_impl, GenBuffers(1, _)).Times(1);

  std::shared_ptr<MockGLES> mock_gled =
      MockGLES::Init(std::move(mock_gles_impl));
  ProcTableGLES::Resolver resolver = kMockResolverGLES;
  auto proc_table = std::make_unique<ProcTableGLES>(resolver);
  auto worker = std::make_shared<TestWorker>();
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);

  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{sizeof(float)}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = sizeof(float)},
                                 reactor, std::move(backing_store));
  EXPECT_FALSE(device_buffer.GetHandle().has_value());
  EXPECT_TRUE(device_buffer.BindAndUploadDataIfNecessary(
      DeviceBufferGLES::BindingType::kUniformBuffer));
  EXPECT_TRUE(device_buffer.GetHandle().has_value());
}

}  // namespace testing
}  // namespace impeller
