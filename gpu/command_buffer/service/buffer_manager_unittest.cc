// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/buffer_manager.h"
#include "gpu/command_buffer/service/error_state_mock.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/mocks.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::testing::_;
using ::testing::Return;
using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

class BufferManagerTestBase : public GpuServiceTest {
 protected:
  void SetUpBase(
      MemoryTracker* memory_tracker,
      FeatureInfo* feature_info,
      const char* extensions) {
    GpuServiceTest::SetUp();
    if (feature_info) {
      TestHelper::SetupFeatureInfoInitExpectations(gl_.get(), extensions);
      feature_info->Initialize();
    }
    error_state_.reset(new MockErrorState());
    manager_.reset(new BufferManager(memory_tracker, feature_info));
  }

  void TearDown() override {
    manager_->Destroy(false);
    manager_.reset();
    error_state_.reset();
    GpuServiceTest::TearDown();
  }

  GLenum GetTarget(const Buffer* buffer) const {
    return buffer->target();
  }

  void DoBufferData(
      Buffer* buffer, GLsizeiptr size, GLenum usage, const GLvoid* data,
      GLenum error) {
    TestHelper::DoBufferData(
        gl_.get(), error_state_.get(), manager_.get(),
        buffer, size, usage, data, error);
  }

  bool DoBufferSubData(
      Buffer* buffer, GLintptr offset, GLsizeiptr size,
      const GLvoid* data) {
    bool success = true;
    if (!buffer->CheckRange(offset, size)) {
      EXPECT_CALL(*error_state_, SetGLError(_, _, GL_INVALID_VALUE, _, _))
         .Times(1)
         .RetiresOnSaturation();
      success = false;
    } else if (!buffer->IsClientSideArray()) {
      EXPECT_CALL(*gl_, BufferSubData(
          buffer->target(), offset, size, _))
          .Times(1)
          .RetiresOnSaturation();
    }
    manager_->DoBufferSubData(
        error_state_.get(), buffer, offset, size, data);
    return success;
  }

  scoped_ptr<BufferManager> manager_;
  scoped_ptr<MockErrorState> error_state_;
};

class BufferManagerTest : public BufferManagerTestBase {
 protected:
  void SetUp() override { SetUpBase(NULL, NULL, ""); }
};

class BufferManagerMemoryTrackerTest : public BufferManagerTestBase {
 protected:
  void SetUp() override {
    mock_memory_tracker_ = new StrictMock<MockMemoryTracker>();
    SetUpBase(mock_memory_tracker_.get(), NULL, "");
  }

  scoped_refptr<MockMemoryTracker> mock_memory_tracker_;
};

class BufferManagerClientSideArraysTest : public BufferManagerTestBase {
 protected:
  void SetUp() override {
    feature_info_ = new FeatureInfo();
    feature_info_->workarounds_.use_client_side_arrays_for_stream_buffers =
      true;
    SetUpBase(NULL, feature_info_.get(), "");
  }

  scoped_refptr<FeatureInfo> feature_info_;
};

#define EXPECT_MEMORY_ALLOCATION_CHANGE(old_size, new_size, pool)   \
  EXPECT_CALL(*mock_memory_tracker_.get(),                          \
              TrackMemoryAllocatedChange(old_size, new_size, pool)) \
      .Times(1).RetiresOnSaturation()

TEST_F(BufferManagerTest, Basic) {
  const GLuint kClientBuffer1Id = 1;
  const GLuint kServiceBuffer1Id = 11;
  const GLsizeiptr kBuffer1Size = 123;
  const GLuint kClientBuffer2Id = 2;
  // Check we can create buffer.
  manager_->CreateBuffer(kClientBuffer1Id, kServiceBuffer1Id);
  // Check buffer got created.
  Buffer* buffer1 = manager_->GetBuffer(kClientBuffer1Id);
  ASSERT_TRUE(buffer1 != NULL);
  EXPECT_EQ(0u, GetTarget(buffer1));
  EXPECT_EQ(0, buffer1->size());
  EXPECT_EQ(static_cast<GLenum>(GL_STATIC_DRAW), buffer1->usage());
  EXPECT_FALSE(buffer1->IsDeleted());
  EXPECT_FALSE(buffer1->IsClientSideArray());
  EXPECT_EQ(kServiceBuffer1Id, buffer1->service_id());
  GLuint client_id = 0;
  EXPECT_TRUE(manager_->GetClientId(buffer1->service_id(), &client_id));
  EXPECT_EQ(kClientBuffer1Id, client_id);
  manager_->SetTarget(buffer1, GL_ELEMENT_ARRAY_BUFFER);
  EXPECT_EQ(static_cast<GLenum>(GL_ELEMENT_ARRAY_BUFFER), GetTarget(buffer1));
  // Check we and set its size.
  DoBufferData(buffer1, kBuffer1Size, GL_DYNAMIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_EQ(kBuffer1Size, buffer1->size());
  EXPECT_EQ(static_cast<GLenum>(GL_DYNAMIC_DRAW), buffer1->usage());
  // Check we get nothing for a non-existent buffer.
  EXPECT_TRUE(manager_->GetBuffer(kClientBuffer2Id) == NULL);
  // Check trying to a remove non-existent buffers does not crash.
  manager_->RemoveBuffer(kClientBuffer2Id);
  // Check that it gets deleted when the last reference is released.
  EXPECT_CALL(*gl_, DeleteBuffersARB(1, ::testing::Pointee(kServiceBuffer1Id)))
      .Times(1)
      .RetiresOnSaturation();
  // Check we can't get the buffer after we remove it.
  manager_->RemoveBuffer(kClientBuffer1Id);
  EXPECT_TRUE(manager_->GetBuffer(kClientBuffer1Id) == NULL);
}

TEST_F(BufferManagerMemoryTrackerTest, Basic) {
  const GLuint kClientBuffer1Id = 1;
  const GLuint kServiceBuffer1Id = 11;
  const GLsizeiptr kBuffer1Size1 = 123;
  const GLsizeiptr kBuffer1Size2 = 456;
  // Check we can create buffer.
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 0, MemoryTracker::kManaged);
  manager_->CreateBuffer(kClientBuffer1Id, kServiceBuffer1Id);
  // Check buffer got created.
  Buffer* buffer1 = manager_->GetBuffer(kClientBuffer1Id);
  ASSERT_TRUE(buffer1 != NULL);
  manager_->SetTarget(buffer1, GL_ELEMENT_ARRAY_BUFFER);
  // Check we and set its size.
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, kBuffer1Size1, MemoryTracker::kManaged);
  DoBufferData(buffer1, kBuffer1Size1, GL_DYNAMIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_MEMORY_ALLOCATION_CHANGE(kBuffer1Size1, 0, MemoryTracker::kManaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, kBuffer1Size2, MemoryTracker::kManaged);
  DoBufferData(buffer1, kBuffer1Size2, GL_DYNAMIC_DRAW, NULL, GL_NO_ERROR);
  // On delete it will get freed.
  EXPECT_MEMORY_ALLOCATION_CHANGE(kBuffer1Size2, 0, MemoryTracker::kManaged);
}

TEST_F(BufferManagerTest, Destroy) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  // Check we can create buffer.
  manager_->CreateBuffer(kClient1Id, kService1Id);
  // Check buffer got created.
  Buffer* buffer1 = manager_->GetBuffer(kClient1Id);
  ASSERT_TRUE(buffer1 != NULL);
  EXPECT_CALL(*gl_, DeleteBuffersARB(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  manager_->Destroy(true);
  // Check the resources were released.
  buffer1 = manager_->GetBuffer(kClient1Id);
  ASSERT_TRUE(buffer1 == NULL);
}

TEST_F(BufferManagerTest, DoBufferSubData) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const uint8 data[] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ELEMENT_ARRAY_BUFFER);
  DoBufferData(buffer, sizeof(data), GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_TRUE(DoBufferSubData(buffer, 0, sizeof(data), data));
  EXPECT_TRUE(DoBufferSubData(buffer, sizeof(data), 0, data));
  EXPECT_FALSE(DoBufferSubData(buffer, sizeof(data), 1, data));
  EXPECT_FALSE(DoBufferSubData(buffer, 0, sizeof(data) + 1, data));
  EXPECT_FALSE(DoBufferSubData(buffer, -1, sizeof(data), data));
  EXPECT_FALSE(DoBufferSubData(buffer, 0, -1, data));
  DoBufferData(buffer, 1, GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  const int size = 0x20000;
  scoped_ptr<uint8[]> temp(new uint8[size]);
  EXPECT_FALSE(DoBufferSubData(buffer, 0 - size, size, temp.get()));
  EXPECT_FALSE(DoBufferSubData(buffer, 1, size / 2, temp.get()));
}

TEST_F(BufferManagerTest, GetRange) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const GLsizeiptr kDataSize = 10;
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ELEMENT_ARRAY_BUFFER);
  DoBufferData(buffer, kDataSize, GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  const char* buf =
      static_cast<const char*>(buffer->GetRange(0, kDataSize));
  ASSERT_TRUE(buf != NULL);
  const char* buf1 =
      static_cast<const char*>(buffer->GetRange(1, kDataSize - 1));
  EXPECT_EQ(buf + 1, buf1);
  EXPECT_TRUE(buffer->GetRange(kDataSize, 1) == NULL);
  EXPECT_TRUE(buffer->GetRange(0, kDataSize + 1) == NULL);
  EXPECT_TRUE(buffer->GetRange(-1, kDataSize) == NULL);
  EXPECT_TRUE(buffer->GetRange(-0, -1) == NULL);
  const int size = 0x20000;
  DoBufferData(buffer, size / 2, GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_TRUE(buffer->GetRange(0 - size, size) == NULL);
  EXPECT_TRUE(buffer->GetRange(1, size / 2) == NULL);
}

TEST_F(BufferManagerTest, GetMaxValueForRangeUint8) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const uint8 data[] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
  const uint8 new_data[] = {100, 120, 110};
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ELEMENT_ARRAY_BUFFER);
  DoBufferData(buffer, sizeof(data), GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_TRUE(DoBufferSubData(buffer, 0, sizeof(data), data));
  GLuint max_value;
  // Check entire range succeeds.
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      0, 10, GL_UNSIGNED_BYTE, &max_value));
  EXPECT_EQ(10u, max_value);
  // Check sub range succeeds.
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      4, 3, GL_UNSIGNED_BYTE, &max_value));
  EXPECT_EQ(6u, max_value);
  // Check changing sub range succeeds.
  EXPECT_TRUE(DoBufferSubData(buffer, 4, sizeof(new_data), new_data));
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      4, 3, GL_UNSIGNED_BYTE, &max_value));
  EXPECT_EQ(120u, max_value);
  max_value = 0;
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      0, 10, GL_UNSIGNED_BYTE, &max_value));
  EXPECT_EQ(120u, max_value);
  // Check out of range fails.
  EXPECT_FALSE(buffer->GetMaxValueForRange(
      0, 11, GL_UNSIGNED_BYTE, &max_value));
  EXPECT_FALSE(buffer->GetMaxValueForRange(
      10, 1, GL_UNSIGNED_BYTE, &max_value));
}

TEST_F(BufferManagerTest, GetMaxValueForRangeUint16) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const uint16 data[] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
  const uint16 new_data[] = {100, 120, 110};
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ELEMENT_ARRAY_BUFFER);
  DoBufferData(buffer, sizeof(data), GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_TRUE(DoBufferSubData(buffer, 0, sizeof(data), data));
  GLuint max_value;
  // Check entire range succeeds.
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      0, 10, GL_UNSIGNED_SHORT, &max_value));
  EXPECT_EQ(10u, max_value);
  // Check odd offset fails for GL_UNSIGNED_SHORT.
  EXPECT_FALSE(buffer->GetMaxValueForRange(
      1, 10, GL_UNSIGNED_SHORT, &max_value));
  // Check sub range succeeds.
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      8, 3, GL_UNSIGNED_SHORT, &max_value));
  EXPECT_EQ(6u, max_value);
  // Check changing sub range succeeds.
  EXPECT_TRUE(DoBufferSubData(buffer, 8, sizeof(new_data), new_data));
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      8, 3, GL_UNSIGNED_SHORT, &max_value));
  EXPECT_EQ(120u, max_value);
  max_value = 0;
  EXPECT_TRUE(buffer->GetMaxValueForRange(
      0, 10, GL_UNSIGNED_SHORT, &max_value));
  EXPECT_EQ(120u, max_value);
  // Check out of range fails.
  EXPECT_FALSE(buffer->GetMaxValueForRange(
      0, 11, GL_UNSIGNED_SHORT, &max_value));
  EXPECT_FALSE(buffer->GetMaxValueForRange(
      20, 1, GL_UNSIGNED_SHORT, &max_value));
}

TEST_F(BufferManagerTest, GetMaxValueForRangeUint32) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const uint32 data[] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
  const uint32 new_data[] = {100, 120, 110};
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ELEMENT_ARRAY_BUFFER);
  DoBufferData(buffer, sizeof(data), GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  EXPECT_TRUE(DoBufferSubData(buffer, 0, sizeof(data), data));
  GLuint max_value;
  // Check entire range succeeds.
  EXPECT_TRUE(
      buffer->GetMaxValueForRange(0, 10, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(10u, max_value);
  // Check non aligned offsets fails for GL_UNSIGNED_INT.
  EXPECT_FALSE(
      buffer->GetMaxValueForRange(1, 10, GL_UNSIGNED_INT, &max_value));
  EXPECT_FALSE(
      buffer->GetMaxValueForRange(2, 10, GL_UNSIGNED_INT, &max_value));
  EXPECT_FALSE(
      buffer->GetMaxValueForRange(3, 10, GL_UNSIGNED_INT, &max_value));
  // Check sub range succeeds.
  EXPECT_TRUE(buffer->GetMaxValueForRange(16, 3, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(6u, max_value);
  // Check changing sub range succeeds.
  EXPECT_TRUE(DoBufferSubData(buffer, 16, sizeof(new_data), new_data));
  EXPECT_TRUE(buffer->GetMaxValueForRange(16, 3, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(120u, max_value);
  max_value = 0;
  EXPECT_TRUE(buffer->GetMaxValueForRange(0, 10, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(120u, max_value);
  // Check out of range fails.
  EXPECT_FALSE(
      buffer->GetMaxValueForRange(0, 11, GL_UNSIGNED_INT, &max_value));
  EXPECT_FALSE(
      buffer->GetMaxValueForRange(40, 1, GL_UNSIGNED_INT, &max_value));
}

TEST_F(BufferManagerTest, UseDeletedBuffer) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const GLsizeiptr kDataSize = 10;
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  scoped_refptr<Buffer> buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer.get() != NULL);
  manager_->SetTarget(buffer.get(), GL_ARRAY_BUFFER);
  // Remove buffer
  manager_->RemoveBuffer(kClientBufferId);
  // Use it after removing
  DoBufferData(buffer.get(), kDataSize, GL_STATIC_DRAW, NULL, GL_NO_ERROR);
  // Check that it gets deleted when the last reference is released.
  EXPECT_CALL(*gl_, DeleteBuffersARB(1, ::testing::Pointee(kServiceBufferId)))
      .Times(1)
      .RetiresOnSaturation();
  buffer = NULL;
}

// Test buffers get shadowed when they are supposed to be.
TEST_F(BufferManagerClientSideArraysTest, StreamBuffersAreShadowed) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  static const uint32 data[] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ARRAY_BUFFER);
  DoBufferData(buffer, sizeof(data), GL_STREAM_DRAW, data, GL_NO_ERROR);
  EXPECT_TRUE(buffer->IsClientSideArray());
  EXPECT_EQ(0, memcmp(data, buffer->GetRange(0, sizeof(data)), sizeof(data)));
  DoBufferData(buffer, sizeof(data), GL_DYNAMIC_DRAW, data, GL_NO_ERROR);
  EXPECT_FALSE(buffer->IsClientSideArray());
}

TEST_F(BufferManagerTest, MaxValueCacheClearedCorrectly) {
  const GLuint kClientBufferId = 1;
  const GLuint kServiceBufferId = 11;
  const uint32 data1[] = {10, 9, 8, 7, 6, 5, 4, 3, 2, 1};
  const uint32 data2[] = {11, 12, 13, 14, 15, 16, 17, 18, 19, 20};
  const uint32 data3[] = {30, 29, 28};
  manager_->CreateBuffer(kClientBufferId, kServiceBufferId);
  Buffer* buffer = manager_->GetBuffer(kClientBufferId);
  ASSERT_TRUE(buffer != NULL);
  manager_->SetTarget(buffer, GL_ELEMENT_ARRAY_BUFFER);
  GLuint max_value;
  // Load the buffer with some initial data, and then get the maximum value for
  // a range, which has the side effect of caching it.
  DoBufferData(buffer, sizeof(data1), GL_STATIC_DRAW, data1, GL_NO_ERROR);
  EXPECT_TRUE(
      buffer->GetMaxValueForRange(0, 10, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(10u, max_value);
  // Check that any cached values are invalidated if the buffer is reloaded
  // with the same amount of data (but different content)
  ASSERT_EQ(sizeof(data2), sizeof(data1));
  DoBufferData(buffer, sizeof(data2), GL_STATIC_DRAW, data2, GL_NO_ERROR);
  EXPECT_TRUE(
      buffer->GetMaxValueForRange(0, 10, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(20u, max_value);
  // Check that any cached values are invalidated if the buffer is reloaded
  // with entirely different content.
  ASSERT_NE(sizeof(data3), sizeof(data1));
  DoBufferData(buffer, sizeof(data3), GL_STATIC_DRAW, data3, GL_NO_ERROR);
  EXPECT_TRUE(
      buffer->GetMaxValueForRange(0, 3, GL_UNSIGNED_INT, &max_value));
  EXPECT_EQ(30u, max_value);
}

}  // namespace gles2
}  // namespace gpu


