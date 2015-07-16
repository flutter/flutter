// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GPU_SERVICE_TEST_H_
#define GPU_COMMAND_BUFFER_SERVICE_GPU_SERVICE_TEST_H_

#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "testing/gmock/include/gmock/gmock.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "ui/gl/gl_mock.h"

namespace gfx {
class GLContextStubWithExtensions;
}

namespace gpu {
namespace gles2 {

// Base class for tests that need mock GL bindings.
class GpuServiceTest : public testing::Test {
 public:
  GpuServiceTest();
  ~GpuServiceTest() override;

 protected:
  void SetUpWithGLVersion(const char* gl_version, const char* gl_extensions);
  void SetUp() override;
  void TearDown() override;
  gfx::GLContext* GetGLContext();

  scoped_ptr< ::testing::StrictMock< ::gfx::MockGLInterface> > gl_;

 private:
  bool ran_setup_;
  bool ran_teardown_;
  scoped_refptr<gfx::GLContextStubWithExtensions> context_;
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GPU_SERVICE_TEST_H_
