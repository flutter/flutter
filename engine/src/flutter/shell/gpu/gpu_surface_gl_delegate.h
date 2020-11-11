// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_GPU_GPU_SURFACE_GL_DELEGATE_H_
#define FLUTTER_SHELL_GPU_GPU_SURFACE_GL_DELEGATE_H_

#include "flutter/common/graphics/gl_context_switch.h"
#include "flutter/flow/embedded_views.h"
#include "flutter/fml/macros.h"
#include "third_party/skia/include/core/SkMatrix.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace flutter {

// A structure to represent the frame information which is passed to the
// embedder when requesting a frame buffer object.
struct GLFrameInfo {
  uint32_t width;
  uint32_t height;
};

class GPUSurfaceGLDelegate {
 public:
  ~GPUSurfaceGLDelegate();

  // Called to make the main GL context current on the current thread.
  virtual std::unique_ptr<GLContextResult> GLContextMakeCurrent() = 0;

  // Called to clear the current GL context on the thread. This may be called on
  // either the GPU or IO threads.
  virtual bool GLContextClearCurrent() = 0;

  // Called to present the main GL surface. This is only called for the main GL
  // context and not any of the contexts dedicated for IO.
  virtual bool GLContextPresent(uint32_t fbo_id) = 0;

  // The ID of the main window bound framebuffer. Typically FBO0.
  virtual intptr_t GLContextFBO(GLFrameInfo frame_info) const = 0;

  // The rendering subsystem assumes that the ID of the main window bound
  // framebuffer remains constant throughout. If this assumption in incorrect,
  // embedders are required to return true from this method. In such cases,
  // GLContextFBO(frame_info) will be called again to acquire the new FBO ID for
  // rendering subsequent frames.
  virtual bool GLContextFBOResetAfterPresent() const;

  // Indicates whether or not the surface supports pixel readback as used in
  // circumstances such as a BackdropFilter.
  virtual bool SurfaceSupportsReadback() const;

  // A transformation applied to the onscreen surface before the canvas is
  // flushed.
  virtual SkMatrix GLContextSurfaceTransformation() const;

  virtual sk_sp<const GrGLInterface> GetGLInterface() const;

  // TODO(chinmaygarde): The presence of this method is to work around the fact
  // that not all platforms can accept a custom GL proc table. Migrate all
  // platforms to move GL proc resolution to the embedder and remove this
  // method.
  static sk_sp<const GrGLInterface> GetDefaultPlatformGLInterface();

  using GLProcResolver =
      std::function<void* /* proc name */ (const char* /* proc address */)>;
  // Provide a custom GL proc resolver. If no such resolver is present, Skia
  // will attempt to do GL proc address resolution on its own. Embedders that
  // have specific opinions on GL API selection or need to add their own
  // instrumentation to specific GL calls can specify custom GL functions
  // here.
  virtual GLProcResolver GetGLProcResolver() const;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_GPU_GPU_SURFACE_GL_DELEGATE_H_
