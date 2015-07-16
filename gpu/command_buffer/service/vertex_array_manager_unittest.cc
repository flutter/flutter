// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/vertex_array_manager.h"
#include "gpu/command_buffer/service/vertex_attrib_manager.h"

#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/service/feature_info.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/test_helper.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

using ::testing::Pointee;
using ::testing::_;

namespace gpu {
namespace gles2 {

class VertexArrayManagerTest : public GpuServiceTest {
 public:
  static const uint32 kNumVertexAttribs = 8;

  VertexArrayManagerTest() {
  }

  ~VertexArrayManagerTest() override {}

 protected:
  void SetUp() override {
    GpuServiceTest::SetUpWithGLVersion("2.1", "GL_ARB_vertex_array_object");
    manager_.reset(new VertexArrayManager());
  }

  void TearDown() override {
    manager_.reset();
    GpuServiceTest::TearDown();
  }

  scoped_ptr<VertexArrayManager> manager_;
};

// GCC requires these declarations, but MSVC requires they not be present
#ifndef COMPILER_MSVC
const uint32 VertexArrayManagerTest::kNumVertexAttribs;
#endif

TEST_F(VertexArrayManagerTest, Basic) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLuint kClient2Id = 2;

  // Check we can create
  manager_->CreateVertexAttribManager(
      kClient1Id, kService1Id, kNumVertexAttribs, true);
  // Check creation success
  VertexAttribManager* info1 = manager_->GetVertexAttribManager(kClient1Id);
  ASSERT_TRUE(info1 != NULL);
  EXPECT_EQ(kService1Id, info1->service_id());
  GLuint client_id = 0;
  EXPECT_TRUE(manager_->GetClientId(info1->service_id(), &client_id));
  EXPECT_EQ(kClient1Id, client_id);
  // Check we get nothing for a non-existent name.
  EXPECT_TRUE(manager_->GetVertexAttribManager(kClient2Id) == NULL);
  // Check trying to a remove non-existent name does not crash.
  manager_->RemoveVertexAttribManager(kClient2Id);
  // Check that it gets deleted when the last reference is released.
  EXPECT_CALL(*gl_, DeleteVertexArraysOES(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  // Check we can't get the texture after we remove it.
  manager_->RemoveVertexAttribManager(kClient1Id);
  EXPECT_TRUE(manager_->GetVertexAttribManager(kClient1Id) == NULL);
}

TEST_F(VertexArrayManagerTest, Destroy) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  VertexArrayManager manager;
  // Check we can create
  manager.CreateVertexAttribManager(
      kClient1Id, kService1Id, kNumVertexAttribs, true);
  // Check creation success
  VertexAttribManager* info1 = manager.GetVertexAttribManager(kClient1Id);
  ASSERT_TRUE(info1 != NULL);
  EXPECT_CALL(*gl_, DeleteVertexArraysOES(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  manager.Destroy(true);
  // Check that resources got freed.
  info1 = manager.GetVertexAttribManager(kClient1Id);
  ASSERT_TRUE(info1 == NULL);
}

}  // namespace gles2
}  // namespace gpu


