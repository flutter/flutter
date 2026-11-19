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

namespace {
// Binds |device_buffer| as a vertex buffer and as a uniform buffer and returns
// the GL handles used for each.
std::pair<std::optional<GLuint>, std::optional<GLuint>> BindAsVertexAndUniform(
    const DeviceBufferGLES& device_buffer) {
  EXPECT_TRUE(device_buffer.BindAndUploadDataIfNecessary(
      DeviceBufferGLES::BindingType::kArrayBuffer));
  EXPECT_TRUE(device_buffer.BindAndUploadDataIfNecessary(
      DeviceBufferGLES::BindingType::kUniformBuffer));
  return {device_buffer.GetHandle(), device_buffer.GetUniformHandle()};
}

// The reactor only holds a weak reference to |worker|.
std::shared_ptr<ReactorGLES> CreateReactor(
    const std::shared_ptr<TestWorker>& worker) {
  auto proc_table = std::make_unique<ProcTableGLES>(kMockResolverGLES);
  auto reactor = std::make_shared<ReactorGLES>(std::move(proc_table));
  reactor->AddWorker(worker);
  return reactor;
}

void ExpectGenBuffers(MockGLESImpl& mock_gles_impl, int count) {
  auto next_buffer = std::make_shared<GLuint>(1);
  EXPECT_CALL(mock_gles_impl, GenBuffers(1, _))
      .Times(count)
      .WillRepeatedly([next_buffer](GLsizei n, GLuint* buffers) {
        buffers[0] = (*next_buffer)++;
      });
}
}  // namespace

TEST(DeviceBufferGLESTest, UniformAndVertexDataShareBuffer) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  ExpectGenBuffers(*mock_gles_impl, 1);
  EXPECT_CALL(*mock_gles_impl, BufferSubData(_, 0, 16, _)).Times(1);

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl));
  auto worker = std::make_shared<TestWorker>();
  auto reactor = CreateReactor(worker);
  EXPECT_FALSE(
      reactor->GetProcTable().GetCapabilities()->NeedsSeparateUniformBuffers());

  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{16}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = 16}, reactor,
                                 std::move(backing_store));
  device_buffer.Flush();

  auto [vertex_handle, uniform_handle] = BindAsVertexAndUniform(device_buffer);
  ASSERT_TRUE(vertex_handle.has_value());
  EXPECT_EQ(vertex_handle, uniform_handle);
}

TEST(DeviceBufferGLESTest, UniformDataUsesSeparateBufferOnSVGA3D) {
  auto mock_gles_impl = std::make_unique<MockGLESImpl>();
  ExpectGenBuffers(*mock_gles_impl, 2);
  // Each buffer receives its own copy of every flushed range.
  EXPECT_CALL(*mock_gles_impl, BufferSubData(GL_ARRAY_BUFFER, 0, 16, _))
      .Times(1);
  EXPECT_CALL(*mock_gles_impl, BufferSubData(GL_UNIFORM_BUFFER, 0, 16, _))
      .Times(1);
  EXPECT_CALL(*mock_gles_impl, BufferSubData(GL_ARRAY_BUFFER, 4, 4, _))
      .Times(1);
  EXPECT_CALL(*mock_gles_impl, BufferSubData(GL_UNIFORM_BUFFER, 4, 4, _))
      .Times(1);

  std::shared_ptr<MockGLES> mock_gles =
      MockGLES::Init(std::move(mock_gles_impl), std::nullopt, "OpenGL ES 3.2",
                     "SVGA3D; build: RELEASE; LLVM;");
  auto worker = std::make_shared<TestWorker>();
  auto reactor = CreateReactor(worker);
  EXPECT_TRUE(
      reactor->GetProcTable().GetCapabilities()->NeedsSeparateUniformBuffers());

  auto backing_store = std::make_unique<Allocation>();
  ASSERT_TRUE(backing_store->Truncate(Bytes{16}));
  DeviceBufferGLES device_buffer(DeviceBufferDescriptor{.size = 16}, reactor,
                                 std::move(backing_store));
  device_buffer.Flush();

  auto [vertex_handle, uniform_handle] = BindAsVertexAndUniform(device_buffer);
  ASSERT_TRUE(vertex_handle.has_value());
  ASSERT_TRUE(uniform_handle.has_value());
  EXPECT_NE(vertex_handle, uniform_handle);

  device_buffer.Flush(Range{4, 4});
  BindAsVertexAndUniform(device_buffer);
}

}  // namespace testing
}  // namespace impeller
