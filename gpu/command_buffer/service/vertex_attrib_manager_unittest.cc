// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/vertex_attrib_manager.h"

#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/buffer_manager.h"
#include "gpu/command_buffer/service/error_state_mock.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::testing::Pointee;
using ::testing::_;

namespace gpu {
namespace gles2 {

class VertexAttribManagerTest : public GpuServiceTest {
 public:
  static const uint32 kNumVertexAttribs = 8;

  VertexAttribManagerTest() {
  }

  ~VertexAttribManagerTest() override {}

 protected:
  void SetUp() override {
    GpuServiceTest::SetUp();

    for (uint32 ii = 0; ii < kNumVertexAttribs; ++ii) {
      EXPECT_CALL(*gl_, VertexAttrib4f(ii, 0.0f, 0.0f, 0.0f, 1.0f))
          .Times(1)
          .RetiresOnSaturation();
    }

    manager_ = new VertexAttribManager();
    manager_->Initialize(kNumVertexAttribs, true);
  }

  scoped_refptr<VertexAttribManager> manager_;
};

// GCC requires these declarations, but MSVC requires they not be present
#ifndef COMPILER_MSVC
const uint32 VertexAttribManagerTest::kNumVertexAttribs;
#endif

TEST_F(VertexAttribManagerTest, Basic) {
  EXPECT_TRUE(manager_->GetVertexAttrib(kNumVertexAttribs) == NULL);
  EXPECT_FALSE(manager_->HaveFixedAttribs());

  const VertexAttribManager::VertexAttribList& enabled_attribs =
      manager_->GetEnabledVertexAttribs();
  EXPECT_EQ(0u, enabled_attribs.size());

  for (uint32 ii = 0; ii < kNumVertexAttribs; ii += kNumVertexAttribs - 1) {
    VertexAttrib* attrib = manager_->GetVertexAttrib(ii);
    ASSERT_TRUE(attrib != NULL);
    EXPECT_EQ(ii, attrib->index());
    EXPECT_TRUE(attrib->buffer() == NULL);
    EXPECT_EQ(0, attrib->offset());
    EXPECT_EQ(4, attrib->size());
    EXPECT_EQ(static_cast<GLenum>(GL_FLOAT), attrib->type());
    EXPECT_EQ(GL_FALSE, attrib->normalized());
    EXPECT_EQ(0, attrib->gl_stride());
    EXPECT_FALSE(attrib->enabled());
    manager_->Enable(ii, true);
    EXPECT_TRUE(attrib->enabled());
  }
}

TEST_F(VertexAttribManagerTest, Enable) {
  const VertexAttribManager::VertexAttribList& enabled_attribs =
      manager_->GetEnabledVertexAttribs();

  VertexAttrib* attrib1 = manager_->GetVertexAttrib(1);
  VertexAttrib* attrib2 = manager_->GetVertexAttrib(3);

  manager_->Enable(1, true);
  ASSERT_EQ(1u, enabled_attribs.size());
  EXPECT_TRUE(attrib1->enabled());
  manager_->Enable(3, true);
  ASSERT_EQ(2u, enabled_attribs.size());
  EXPECT_TRUE(attrib2->enabled());

  manager_->Enable(1, false);
  ASSERT_EQ(1u, enabled_attribs.size());
  EXPECT_FALSE(attrib1->enabled());

  manager_->Enable(3, false);
  ASSERT_EQ(0u, enabled_attribs.size());
  EXPECT_FALSE(attrib2->enabled());
}

TEST_F(VertexAttribManagerTest, SetAttribInfo) {
  BufferManager buffer_manager(NULL, NULL);
  buffer_manager.CreateBuffer(1, 2);
  Buffer* buffer = buffer_manager.GetBuffer(1);
  ASSERT_TRUE(buffer != NULL);

  VertexAttrib* attrib = manager_->GetVertexAttrib(1);

  manager_->SetAttribInfo(1, buffer, 3, GL_SHORT, GL_TRUE, 32, 32, 4);

  EXPECT_EQ(buffer, attrib->buffer());
  EXPECT_EQ(4, attrib->offset());
  EXPECT_EQ(3, attrib->size());
  EXPECT_EQ(static_cast<GLenum>(GL_SHORT), attrib->type());
  EXPECT_EQ(GL_TRUE, attrib->normalized());
  EXPECT_EQ(32, attrib->gl_stride());

  // The VertexAttribManager must be destroyed before the BufferManager
  // so it releases its buffers.
  manager_ = NULL;
  buffer_manager.Destroy(false);
}

TEST_F(VertexAttribManagerTest, HaveFixedAttribs) {
  EXPECT_FALSE(manager_->HaveFixedAttribs());
  manager_->SetAttribInfo(1, NULL, 4, GL_FIXED, GL_FALSE, 0, 16, 0);
  EXPECT_TRUE(manager_->HaveFixedAttribs());
  manager_->SetAttribInfo(3, NULL, 4, GL_FIXED, GL_FALSE, 0, 16, 0);
  EXPECT_TRUE(manager_->HaveFixedAttribs());
  manager_->SetAttribInfo(1, NULL, 4, GL_FLOAT, GL_FALSE, 0, 16, 0);
  EXPECT_TRUE(manager_->HaveFixedAttribs());
  manager_->SetAttribInfo(3, NULL, 4, GL_FLOAT, GL_FALSE, 0, 16, 0);
  EXPECT_FALSE(manager_->HaveFixedAttribs());
}

TEST_F(VertexAttribManagerTest, CanAccess) {
  MockErrorState error_state;
  BufferManager buffer_manager(NULL, NULL);
  buffer_manager.CreateBuffer(1, 2);
  Buffer* buffer = buffer_manager.GetBuffer(1);
  ASSERT_TRUE(buffer != NULL);

  VertexAttrib* attrib = manager_->GetVertexAttrib(1);

  EXPECT_TRUE(attrib->CanAccess(0));
  manager_->Enable(1, true);
  EXPECT_FALSE(attrib->CanAccess(0));

  manager_->SetAttribInfo(1, buffer, 4, GL_FLOAT, GL_FALSE, 0, 16, 0);
  EXPECT_FALSE(attrib->CanAccess(0));

  EXPECT_TRUE(buffer_manager.SetTarget(buffer, GL_ARRAY_BUFFER));
  TestHelper::DoBufferData(
      gl_.get(), &error_state, &buffer_manager, buffer, 15, GL_STATIC_DRAW,
      NULL, GL_NO_ERROR);

  EXPECT_FALSE(attrib->CanAccess(0));
  TestHelper::DoBufferData(
      gl_.get(), &error_state, &buffer_manager, buffer, 16, GL_STATIC_DRAW,
      NULL, GL_NO_ERROR);
  EXPECT_TRUE(attrib->CanAccess(0));
  EXPECT_FALSE(attrib->CanAccess(1));

  manager_->SetAttribInfo(1, buffer, 4, GL_FLOAT, GL_FALSE, 0, 16, 1);
  EXPECT_FALSE(attrib->CanAccess(0));

  TestHelper::DoBufferData(
      gl_.get(), &error_state, &buffer_manager, buffer, 32, GL_STATIC_DRAW,
      NULL, GL_NO_ERROR);
  EXPECT_TRUE(attrib->CanAccess(0));
  EXPECT_FALSE(attrib->CanAccess(1));
  manager_->SetAttribInfo(1, buffer, 4, GL_FLOAT, GL_FALSE, 0, 16, 0);
  EXPECT_TRUE(attrib->CanAccess(1));
  manager_->SetAttribInfo(1, buffer, 4, GL_FLOAT, GL_FALSE, 0, 20, 0);
  EXPECT_TRUE(attrib->CanAccess(0));
  EXPECT_FALSE(attrib->CanAccess(1));

  // The VertexAttribManager must be destroyed before the BufferManager
  // so it releases its buffers.
  manager_ = NULL;
  buffer_manager.Destroy(false);
}

TEST_F(VertexAttribManagerTest, Unbind) {
  BufferManager buffer_manager(NULL, NULL);
  buffer_manager.CreateBuffer(1, 2);
  buffer_manager.CreateBuffer(3, 4);
  Buffer* buffer1 = buffer_manager.GetBuffer(1);
  Buffer* buffer2 = buffer_manager.GetBuffer(3);
  ASSERT_TRUE(buffer1 != NULL);
  ASSERT_TRUE(buffer2 != NULL);

  VertexAttrib* attrib1 = manager_->GetVertexAttrib(1);
  VertexAttrib* attrib3 = manager_->GetVertexAttrib(3);

  // Attach to 2 buffers.
  manager_->SetAttribInfo(1, buffer1, 3, GL_SHORT, GL_TRUE, 32, 32, 4);
  manager_->SetAttribInfo(3, buffer1, 3, GL_SHORT, GL_TRUE, 32, 32, 4);
  // Check they were attached.
  EXPECT_EQ(buffer1, attrib1->buffer());
  EXPECT_EQ(buffer1, attrib3->buffer());
  // Unbind unattached buffer.
  manager_->Unbind(buffer2);
  // Should be no-op.
  EXPECT_EQ(buffer1, attrib1->buffer());
  EXPECT_EQ(buffer1, attrib3->buffer());
  // Unbind buffer.
  manager_->Unbind(buffer1);
  // Check they were detached
  EXPECT_TRUE(NULL == attrib1->buffer());
  EXPECT_TRUE(NULL == attrib3->buffer());

  // The VertexAttribManager must be destroyed before the BufferManager
  // so it releases its buffers.
  manager_ = NULL;
  buffer_manager.Destroy(false);
}

// TODO(gman): Test ValidateBindings
// TODO(gman): Test ValidateBindings with client side arrays.

}  // namespace gles2
}  // namespace gpu


