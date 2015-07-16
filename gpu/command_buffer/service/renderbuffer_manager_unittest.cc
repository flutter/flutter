// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/renderbuffer_manager.h"

#include <set>
#include "gpu/command_buffer/common/gles2_cmd_utils.h"
#include "gpu/command_buffer/service/gpu_service_test.h"
#include "gpu/command_buffer/service/mocks.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_implementation.h"
#include "ui/gl/gl_mock.h"

using ::testing::StrictMock;

namespace gpu {
namespace gles2 {

class RenderbufferManagerTestBase : public GpuServiceTest {
 public:
  static const GLint kMaxSize = 128;
  static const GLint kMaxSamples = 4;

 protected:
  void SetUpBase(MemoryTracker* memory_tracker, bool depth24_supported) {
    GpuServiceTest::SetUp();
    manager_.reset(new RenderbufferManager(
        memory_tracker, kMaxSize, kMaxSamples, depth24_supported));
  }

  void TearDown() override {
    manager_->Destroy(true);
    manager_.reset();
    GpuServiceTest::TearDown();
  }

  scoped_ptr<RenderbufferManager> manager_;
};

class RenderbufferManagerTest : public RenderbufferManagerTestBase {
 protected:
  void SetUp() override {
    bool depth24_supported = false;
    SetUpBase(NULL, depth24_supported);
  }
};

class RenderbufferManagerMemoryTrackerTest
    : public RenderbufferManagerTestBase {
 protected:
  void SetUp() override {
    mock_memory_tracker_ = new StrictMock<MockMemoryTracker>();
    bool depth24_supported = false;
    SetUpBase(mock_memory_tracker_.get(), depth24_supported);
  }

  scoped_refptr<MockMemoryTracker> mock_memory_tracker_;
};

#define EXPECT_MEMORY_ALLOCATION_CHANGE(old_size, new_size, pool)   \
  EXPECT_CALL(*mock_memory_tracker_.get(),                          \
              TrackMemoryAllocatedChange(old_size, new_size, pool)) \
      .Times(1).RetiresOnSaturation()

// GCC requires these declarations, but MSVC requires they not be present
#ifndef COMPILER_MSVC
const GLint RenderbufferManagerTestBase::kMaxSize;
const GLint RenderbufferManagerTestBase::kMaxSamples;
#endif

TEST_F(RenderbufferManagerTest, Basic) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  const GLuint kClient2Id = 2;
  EXPECT_EQ(kMaxSize, manager_->max_renderbuffer_size());
  EXPECT_EQ(kMaxSamples, manager_->max_samples());
  EXPECT_FALSE(manager_->HaveUnclearedRenderbuffers());
  // Check we can create renderbuffer.
  manager_->CreateRenderbuffer(kClient1Id, kService1Id);
  // Check renderbuffer got created.
  scoped_refptr<Renderbuffer> renderbuffer1 =
      manager_->GetRenderbuffer(kClient1Id);
  ASSERT_TRUE(renderbuffer1.get() != NULL);
  EXPECT_FALSE(manager_->HaveUnclearedRenderbuffers());
  EXPECT_EQ(kClient1Id, renderbuffer1->client_id());
  // Check we get nothing for a non-existent renderbuffer.
  EXPECT_TRUE(manager_->GetRenderbuffer(kClient2Id) == NULL);
  // Check trying to a remove non-existent renderbuffers does not crash.
  manager_->RemoveRenderbuffer(kClient2Id);
  // Check that the renderbuffer is deleted when the last ref is released.
  EXPECT_CALL(*gl_, DeleteRenderbuffersEXT(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  // Check we can't get the renderbuffer after we remove it.
  manager_->RemoveRenderbuffer(kClient1Id);
  EXPECT_TRUE(manager_->GetRenderbuffer(kClient1Id) == NULL);
  EXPECT_FALSE(manager_->HaveUnclearedRenderbuffers());
  EXPECT_EQ(0u, renderbuffer1->client_id());
}

TEST_F(RenderbufferManagerTest, Destroy) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  // Check we can create renderbuffer.
  manager_->CreateRenderbuffer(kClient1Id, kService1Id);
  // Check renderbuffer got created.
  Renderbuffer* renderbuffer1 =
      manager_->GetRenderbuffer(kClient1Id);
  ASSERT_TRUE(renderbuffer1 != NULL);
  EXPECT_CALL(*gl_, DeleteRenderbuffersEXT(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  manager_->Destroy(true);
  renderbuffer1 = manager_->GetRenderbuffer(kClient1Id);
  ASSERT_TRUE(renderbuffer1 == NULL);
}

TEST_F(RenderbufferManagerTest, Renderbuffer) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  // Check we can create renderbuffer.
  manager_->CreateRenderbuffer(kClient1Id, kService1Id);
  // Check renderbuffer got created.
  Renderbuffer* renderbuffer1 =
      manager_->GetRenderbuffer(kClient1Id);
  ASSERT_TRUE(renderbuffer1 != NULL);
  EXPECT_EQ(kService1Id, renderbuffer1->service_id());
  EXPECT_EQ(0, renderbuffer1->samples());
  EXPECT_EQ(static_cast<GLenum>(GL_RGBA4), renderbuffer1->internal_format());
  EXPECT_EQ(0, renderbuffer1->width());
  EXPECT_EQ(0, renderbuffer1->height());
  EXPECT_TRUE(renderbuffer1->cleared());
  EXPECT_EQ(0u, renderbuffer1->EstimatedSize());

  // Check if we set the info it gets marked as not cleared.
  const GLsizei kSamples = 4;
  const GLenum kFormat = GL_RGBA4;
  const GLsizei kWidth = 128;
  const GLsizei kHeight = 64;
  manager_->SetInfo(renderbuffer1, kSamples, kFormat, kWidth, kHeight);
  EXPECT_EQ(kSamples, renderbuffer1->samples());
  EXPECT_EQ(kFormat, renderbuffer1->internal_format());
  EXPECT_EQ(kWidth, renderbuffer1->width());
  EXPECT_EQ(kHeight, renderbuffer1->height());
  EXPECT_FALSE(renderbuffer1->cleared());
  EXPECT_FALSE(renderbuffer1->IsDeleted());
  EXPECT_TRUE(manager_->HaveUnclearedRenderbuffers());
  EXPECT_EQ(kWidth * kHeight * 4u * 4u, renderbuffer1->EstimatedSize());

  manager_->SetCleared(renderbuffer1, true);
  EXPECT_TRUE(renderbuffer1->cleared());
  EXPECT_FALSE(manager_->HaveUnclearedRenderbuffers());

  manager_->SetInfo(renderbuffer1, kSamples, kFormat, kWidth, kHeight);
  EXPECT_TRUE(manager_->HaveUnclearedRenderbuffers());

  // Check that the renderbuffer is deleted when the last ref is released.
  EXPECT_CALL(*gl_, DeleteRenderbuffersEXT(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  manager_->RemoveRenderbuffer(kClient1Id);
  EXPECT_FALSE(manager_->HaveUnclearedRenderbuffers());
}

TEST_F(RenderbufferManagerMemoryTrackerTest, Basic) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  EXPECT_MEMORY_ALLOCATION_CHANGE(0, 0, MemoryTracker::kUnmanaged);
  manager_->CreateRenderbuffer(kClient1Id, kService1Id);
  Renderbuffer* renderbuffer1 =
      manager_->GetRenderbuffer(kClient1Id);
  ASSERT_TRUE(renderbuffer1 != NULL);

  const GLsizei kSamples = 4;
  const GLenum kFormat = GL_RGBA4;
  const GLsizei kWidth = 128;
  const GLsizei kHeight1 = 64;
  const GLsizei kHeight2 = 32;
  uint32 expected_size_1 = 0;
  uint32 expected_size_2 = 0;
  manager_->ComputeEstimatedRenderbufferSize(
      kWidth, kHeight1, kSamples, kFormat, &expected_size_1);
  manager_->ComputeEstimatedRenderbufferSize(
      kWidth, kHeight2, kSamples, kFormat, &expected_size_2);
  EXPECT_MEMORY_ALLOCATION_CHANGE(
      0, expected_size_1, MemoryTracker::kUnmanaged);
  manager_->SetInfo(renderbuffer1, kSamples, kFormat, kWidth, kHeight1);
  EXPECT_MEMORY_ALLOCATION_CHANGE(
      expected_size_1, 0, MemoryTracker::kUnmanaged);
  EXPECT_MEMORY_ALLOCATION_CHANGE(
      0, expected_size_2, MemoryTracker::kUnmanaged);
  manager_->SetInfo(renderbuffer1, kSamples, kFormat, kWidth, kHeight2);
  EXPECT_MEMORY_ALLOCATION_CHANGE(
      expected_size_2, 0, MemoryTracker::kUnmanaged);
  EXPECT_CALL(*gl_, DeleteRenderbuffersEXT(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
}

TEST_F(RenderbufferManagerTest, UseDeletedRenderbufferInfo) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  manager_->CreateRenderbuffer(kClient1Id, kService1Id);
  scoped_refptr<Renderbuffer> renderbuffer1(
      manager_->GetRenderbuffer(kClient1Id));
  ASSERT_TRUE(renderbuffer1.get() != NULL);
  // Remove it.
  manager_->RemoveRenderbuffer(kClient1Id);
  // Use after removing.
  const GLsizei kSamples = 4;
  const GLenum kFormat = GL_RGBA4;
  const GLsizei kWidth = 128;
  const GLsizei kHeight = 64;
  manager_->SetInfo(renderbuffer1.get(), kSamples, kFormat, kWidth, kHeight);
  // See that it still affects manager.
  EXPECT_TRUE(manager_->HaveUnclearedRenderbuffers());
  manager_->SetCleared(renderbuffer1.get(), true);
  EXPECT_FALSE(manager_->HaveUnclearedRenderbuffers());
  // Check that the renderbuffer is deleted when the last ref is released.
  EXPECT_CALL(*gl_, DeleteRenderbuffersEXT(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
  renderbuffer1 = NULL;
}

namespace {

bool InSet(std::set<std::string>* string_set, const std::string& str) {
  std::pair<std::set<std::string>::iterator, bool> result =
      string_set->insert(str);
  return !result.second;
}

}  // anonymous namespace

TEST_F(RenderbufferManagerTest, AddToSignature) {
  const GLuint kClient1Id = 1;
  const GLuint kService1Id = 11;
  manager_->CreateRenderbuffer(kClient1Id, kService1Id);
  scoped_refptr<Renderbuffer> renderbuffer1(
      manager_->GetRenderbuffer(kClient1Id));
  ASSERT_TRUE(renderbuffer1.get() != NULL);
  const GLsizei kSamples = 4;
  const GLenum kFormat = GL_RGBA4;
  const GLsizei kWidth = 128;
  const GLsizei kHeight = 64;
  manager_->SetInfo(renderbuffer1.get(), kSamples, kFormat, kWidth, kHeight);
  std::string signature1;
  std::string signature2;
  renderbuffer1->AddToSignature(&signature1);

  std::set<std::string> string_set;
  EXPECT_FALSE(InSet(&string_set, signature1));

  // change things and see that the signatures change.
  manager_->SetInfo(
      renderbuffer1.get(), kSamples + 1, kFormat, kWidth, kHeight);
  renderbuffer1->AddToSignature(&signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetInfo(
      renderbuffer1.get(), kSamples, kFormat + 1, kWidth, kHeight);
  signature2.clear();
  renderbuffer1->AddToSignature(&signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetInfo(
      renderbuffer1.get(), kSamples, kFormat, kWidth + 1, kHeight);
  signature2.clear();
  renderbuffer1->AddToSignature(&signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  manager_->SetInfo(
      renderbuffer1.get(), kSamples, kFormat, kWidth, kHeight + 1);
  signature2.clear();
  renderbuffer1->AddToSignature(&signature2);
  EXPECT_FALSE(InSet(&string_set, signature2));

  // put it back to the same and it should be the same.
  manager_->SetInfo(renderbuffer1.get(), kSamples, kFormat, kWidth, kHeight);
  signature2.clear();
  renderbuffer1->AddToSignature(&signature2);
  EXPECT_EQ(signature1, signature2);

  // Check the set was acutally getting different signatures.
  EXPECT_EQ(5u, string_set.size());

  EXPECT_CALL(*gl_, DeleteRenderbuffersEXT(1, ::testing::Pointee(kService1Id)))
      .Times(1)
      .RetiresOnSaturation();
}

class RenderbufferManagerFormatTest : public RenderbufferManagerTestBase {
 protected:
  void SetUp() override {
    bool depth24_supported = true;
    SetUpBase(NULL, depth24_supported);
  }
};

TEST_F(RenderbufferManagerFormatTest, UpgradeDepthFormatOnGLES) {
  gfx::GLImplementation prev_impl = gfx::GetGLImplementation();
  gfx::SetGLImplementation(gfx::kGLImplementationEGLGLES2);
  GLenum impl_format =
      manager_->InternalRenderbufferFormatToImplFormat(GL_DEPTH_COMPONENT16);
  gfx::SetGLImplementation(prev_impl);
  EXPECT_EQ(static_cast<GLenum>(GL_DEPTH_COMPONENT24), impl_format);
}

TEST_F(RenderbufferManagerFormatTest, UseUnsizedDepthFormatOnNonGLES) {
  gfx::GLImplementation prev_impl = gfx::GetGLImplementation();
  gfx::SetGLImplementation(gfx::kGLImplementationDesktopGL);
  GLenum impl_format =
      manager_->InternalRenderbufferFormatToImplFormat(GL_DEPTH_COMPONENT16);
  gfx::SetGLImplementation(prev_impl);
  EXPECT_EQ(static_cast<GLenum>(GL_DEPTH_COMPONENT), impl_format);
}

}  // namespace gles2
}  // namespace gpu


