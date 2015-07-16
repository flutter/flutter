// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GL_SURFACE_MOCK_H_
#define GPU_COMMAND_BUFFER_SERVICE_GL_SURFACE_MOCK_H_

#include "ui/gl/gl_surface.h"
#include "testing/gmock/include/gmock/gmock.h"

namespace gpu {

class GLSurfaceMock : public gfx::GLSurface {
 public:
  GLSurfaceMock();

  MOCK_METHOD0(Initialize, bool());
  MOCK_METHOD0(Destroy, void());
  MOCK_METHOD1(Resize, bool(const gfx::Size& size));
  MOCK_METHOD0(IsOffscreen, bool());
  MOCK_METHOD0(SwapBuffers, bool());
  MOCK_METHOD4(PostSubBuffer, bool(int x, int y, int width, int height));
  MOCK_METHOD0(SupportsPostSubBuffer, bool());
  MOCK_METHOD0(GetSize, gfx::Size());
  MOCK_METHOD0(GetHandle, void*());
  MOCK_METHOD0(GetBackingFrameBufferObject, unsigned int());
  MOCK_METHOD1(OnMakeCurrent, bool(gfx::GLContext* context));
  MOCK_METHOD1(SetBackbufferAllocation, bool(bool allocated));
  MOCK_METHOD1(SetFrontbufferAllocation, void(bool allocated));
  MOCK_METHOD0(GetShareHandle, void*());
  MOCK_METHOD0(GetDisplay, void*());
  MOCK_METHOD0(GetConfig, void*());
  MOCK_METHOD0(GetFormat, unsigned());

 protected:
  virtual ~GLSurfaceMock();

 private:
  DISALLOW_COPY_AND_ASSIGN(GLSurfaceMock);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GL_SURFACE_MOCK_H_
