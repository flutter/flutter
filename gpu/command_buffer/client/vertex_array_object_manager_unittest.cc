// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/vertex_array_object_manager.h"

#include <GLES2/gl2ext.h>
#include "testing/gtest/include/gtest/gtest.h"

namespace gpu {
namespace gles2 {

class VertexArrayObjectManagerTest : public testing::Test {
 protected:
  static const GLuint kMaxAttribs = 4;
  static const GLuint kClientSideArrayBuffer = 0x1234;
  static const GLuint kClientSideElementArrayBuffer = 0x1235;
  static const bool kSupportClientSideArrays = true;

  void SetUp() override {
    manager_.reset(new VertexArrayObjectManager(
        kMaxAttribs,
        kClientSideArrayBuffer,
        kClientSideElementArrayBuffer,
        kSupportClientSideArrays));
  }
  void TearDown() override {}

  scoped_ptr<VertexArrayObjectManager> manager_;
};

// GCC requires these declarations, but MSVC requires they not be present
#ifndef _MSC_VER
const GLuint VertexArrayObjectManagerTest::kMaxAttribs;
const GLuint VertexArrayObjectManagerTest::kClientSideArrayBuffer;
const GLuint VertexArrayObjectManagerTest::kClientSideElementArrayBuffer;
#endif

TEST_F(VertexArrayObjectManagerTest, Basic) {
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
  // Check out of bounds access.
  uint32 param;
  void* ptr;
  EXPECT_FALSE(manager_->GetVertexAttrib(
      kMaxAttribs, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &param));
  EXPECT_FALSE(manager_->GetAttribPointer(
      kMaxAttribs, GL_VERTEX_ATTRIB_ARRAY_POINTER, &ptr));
  // Check defaults.
  for (GLuint ii = 0; ii < kMaxAttribs; ++ii) {
    EXPECT_TRUE(manager_->GetVertexAttrib(
        ii, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &param));
    EXPECT_EQ(0u, param);
    EXPECT_TRUE(manager_->GetVertexAttrib(
        ii, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &param));
    EXPECT_EQ(0u, param);
    EXPECT_TRUE(manager_->GetVertexAttrib(
        ii, GL_VERTEX_ATTRIB_ARRAY_SIZE, &param));
    EXPECT_EQ(4u, param);
    EXPECT_TRUE(manager_->GetVertexAttrib(
        ii, GL_VERTEX_ATTRIB_ARRAY_TYPE, &param));
    EXPECT_EQ(static_cast<uint32>(GL_FLOAT), param);
    EXPECT_TRUE(manager_->GetVertexAttrib(
        ii, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &param));
    EXPECT_EQ(0u, param);
    EXPECT_TRUE(manager_->GetAttribPointer(
        ii, GL_VERTEX_ATTRIB_ARRAY_POINTER, &ptr));
    EXPECT_TRUE(NULL == ptr);
  }
}

TEST_F(VertexArrayObjectManagerTest, UnbindBuffer) {
  const GLuint kBufferToUnbind = 123;
  const GLuint kBufferToRemain = 456;
  const GLuint kElementArray = 789;
  bool changed = false;
  GLuint ids[2] = { 1, 3, };
  manager_->GenVertexArrays(arraysize(ids), ids);
  // Bind buffers to attribs on 2 vaos.
  for (size_t ii = 0; ii < arraysize(ids); ++ii) {
    EXPECT_TRUE(manager_->BindVertexArray(ids[ii], &changed));
    EXPECT_TRUE(manager_->SetAttribPointer(
        kBufferToUnbind, 0, 4, GL_FLOAT, false, 0, 0));
    EXPECT_TRUE(manager_->SetAttribPointer(
        kBufferToRemain, 1, 4, GL_FLOAT, false, 0, 0));
    EXPECT_TRUE(manager_->SetAttribPointer(
        kBufferToUnbind, 2, 4, GL_FLOAT, false, 0, 0));
    EXPECT_TRUE(manager_->SetAttribPointer(
        kBufferToRemain, 3, 4, GL_FLOAT, false, 0, 0));
    for (size_t jj = 0; jj < 4u; ++jj) {
      manager_->SetAttribEnable(jj, true);
    }
    manager_->BindElementArray(kElementArray);
  }
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
  EXPECT_TRUE(manager_->BindVertexArray(ids[0], &changed));
  // Unbind the buffer.
  manager_->UnbindBuffer(kBufferToUnbind);
  manager_->UnbindBuffer(kElementArray);
  // The attribs are still enabled but their buffer is 0.
  EXPECT_TRUE(manager_->HaveEnabledClientSideBuffers());
  // Check the status of the bindings.
  static const uint32 expected[][4] = {
    { 0, kBufferToRemain, 0, kBufferToRemain, },
    { kBufferToUnbind, kBufferToRemain, kBufferToUnbind, kBufferToRemain, },
  };
  static const GLuint expected_element_array[] = {
    0, kElementArray,
  };
  for (size_t ii = 0; ii < arraysize(ids); ++ii) {
    EXPECT_TRUE(manager_->BindVertexArray(ids[ii], &changed));
    for (size_t jj = 0; jj < 4; ++jj) {
      uint32 param = 1;
      EXPECT_TRUE(manager_->GetVertexAttrib(
          jj, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &param));
      EXPECT_EQ(expected[ii][jj], param)
          << "id: " << ids[ii] << ", attrib: " << jj;
    }
    EXPECT_EQ(expected_element_array[ii],
              manager_->bound_element_array_buffer());
  }

  // The vao that was not bound still has all service side bufferws.
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());

  // Make sure unbinding 0 does not effect count incorrectly.
  EXPECT_TRUE(manager_->BindVertexArray(0, &changed));
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
  manager_->SetAttribEnable(2, true);
  manager_->UnbindBuffer(0);
  manager_->SetAttribEnable(2, false);
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
}

TEST_F(VertexArrayObjectManagerTest, GetSet) {
  const char* dummy = "dummy";
  const void* p = reinterpret_cast<const void*>(dummy);
  manager_->SetAttribEnable(1, true);
  manager_->SetAttribPointer(123, 1, 3, GL_BYTE, true, 3, p);
  uint32 param;
  void* ptr;
  EXPECT_TRUE(manager_->GetVertexAttrib(
      1, GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING, &param));
  EXPECT_EQ(123u, param);
  EXPECT_TRUE(manager_->GetVertexAttrib(
      1, GL_VERTEX_ATTRIB_ARRAY_ENABLED, &param));
  EXPECT_NE(0u, param);
  EXPECT_TRUE(manager_->GetVertexAttrib(
      1, GL_VERTEX_ATTRIB_ARRAY_SIZE, &param));
  EXPECT_EQ(3u, param);
  EXPECT_TRUE(manager_->GetVertexAttrib(
      1, GL_VERTEX_ATTRIB_ARRAY_TYPE, &param));
  EXPECT_EQ(static_cast<uint32>(GL_BYTE), param);
  EXPECT_TRUE(manager_->GetVertexAttrib(
      1, GL_VERTEX_ATTRIB_ARRAY_NORMALIZED, &param));
  EXPECT_NE(0u, param);
  EXPECT_TRUE(manager_->GetAttribPointer(
      1, GL_VERTEX_ATTRIB_ARRAY_POINTER, &ptr));
  EXPECT_EQ(p, ptr);

  // Check that getting the divisor is passed to the service.
  // This is because the divisor is an optional feature which
  // only the service can validate.
  EXPECT_FALSE(manager_->GetVertexAttrib(
      0, GL_VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE, &param));
}

TEST_F(VertexArrayObjectManagerTest, HaveEnabledClientSideArrays) {
  // Check turning on an array.
  manager_->SetAttribEnable(1, true);
  EXPECT_TRUE(manager_->HaveEnabledClientSideBuffers());
  // Check turning off an array.
  manager_->SetAttribEnable(1, false);
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
  // Check turning on an array and assigning a buffer.
  manager_->SetAttribEnable(1, true);
  manager_->SetAttribPointer(123, 1, 3, GL_BYTE, true, 3, NULL);
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
  // Check unassigning a buffer.
  manager_->SetAttribPointer(0, 1, 3, GL_BYTE, true, 3, NULL);
  EXPECT_TRUE(manager_->HaveEnabledClientSideBuffers());
  // Check disabling the array.
  manager_->SetAttribEnable(1, false);
  EXPECT_FALSE(manager_->HaveEnabledClientSideBuffers());
}

TEST_F(VertexArrayObjectManagerTest, BindElementArray) {
  bool changed = false;
  GLuint ids[2] = { 1, 3, };
  manager_->GenVertexArrays(arraysize(ids), ids);

  // Check the default element array is 0.
  EXPECT_EQ(0u, manager_->bound_element_array_buffer());
  // Check binding the same array does not need a service call.
  EXPECT_FALSE(manager_->BindElementArray(0u));
  // Check binding a new element array requires a service call.
  EXPECT_TRUE(manager_->BindElementArray(55u));
  // Check the element array was bound.
  EXPECT_EQ(55u, manager_->bound_element_array_buffer());
  // Check binding the same array does not need a service call.
  EXPECT_FALSE(manager_->BindElementArray(55u));

  // Check with a new vao.
  EXPECT_TRUE(manager_->BindVertexArray(1, &changed));
  // Check the default element array is 0.
  EXPECT_EQ(0u, manager_->bound_element_array_buffer());
  // Check binding a new element array requires a service call.
  EXPECT_TRUE(manager_->BindElementArray(11u));
  // Check the element array was bound.
  EXPECT_EQ(11u, manager_->bound_element_array_buffer());
  // Check binding the same array does not need a service call.
  EXPECT_FALSE(manager_->BindElementArray(11u));

  // check switching vao bindings returns the correct element array.
  EXPECT_TRUE(manager_->BindVertexArray(3, &changed));
  EXPECT_EQ(0u, manager_->bound_element_array_buffer());
  EXPECT_TRUE(manager_->BindVertexArray(0, &changed));
  EXPECT_EQ(55u, manager_->bound_element_array_buffer());
  EXPECT_TRUE(manager_->BindVertexArray(1, &changed));
  EXPECT_EQ(11u, manager_->bound_element_array_buffer());
}

TEST_F(VertexArrayObjectManagerTest, GenBindDelete) {
  // Check unknown array fails.
  bool changed = false;
  EXPECT_FALSE(manager_->BindVertexArray(123, &changed));
  EXPECT_FALSE(changed);

  GLuint ids[2] = { 1, 3, };
  manager_->GenVertexArrays(arraysize(ids), ids);
  // Check Genned arrays succeed.
  EXPECT_TRUE(manager_->BindVertexArray(1, &changed));
  EXPECT_TRUE(changed);
  EXPECT_TRUE(manager_->BindVertexArray(3, &changed));
  EXPECT_TRUE(changed);

  // Check binding the same array returns changed as false.
  EXPECT_TRUE(manager_->BindVertexArray(3, &changed));
  EXPECT_FALSE(changed);

  // Check deleted ararys fail to bind
  manager_->DeleteVertexArrays(2, ids);
  EXPECT_FALSE(manager_->BindVertexArray(1, &changed));
  EXPECT_FALSE(changed);
  EXPECT_FALSE(manager_->BindVertexArray(3, &changed));
  EXPECT_FALSE(changed);

  // Check binding 0 returns changed as false since it's
  // already bound.
  EXPECT_TRUE(manager_->BindVertexArray(0, &changed));
  EXPECT_FALSE(changed);
}

TEST_F(VertexArrayObjectManagerTest, IsReservedId) {
  EXPECT_TRUE(manager_->IsReservedId(kClientSideArrayBuffer));
  EXPECT_TRUE(manager_->IsReservedId(kClientSideElementArrayBuffer));
  EXPECT_FALSE(manager_->IsReservedId(0));
  EXPECT_FALSE(manager_->IsReservedId(1));
  EXPECT_FALSE(manager_->IsReservedId(2));
}

}  // namespace gles2
}  // namespace gpu

