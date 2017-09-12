// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAEAGLLayer.h>

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "lib/fxl/macros.h"

namespace shell {

class IOSGLContext {
 public:
  IOSGLContext(PlatformView::SurfaceConfig config, CAEAGLLayer* layer);

  ~IOSGLContext();

  bool IsValid() const;

  bool PresentRenderBuffer() const;

  GLuint framebuffer() const { return framebuffer_; }

  bool UpdateStorageSizeIfNecessary();

  bool MakeCurrent();

  bool ResourceMakeCurrent();

  sk_sp<SkColorSpace> ColorSpace() const { return color_space_; }

 private:
  fml::scoped_nsobject<CAEAGLLayer> layer_;
  fml::scoped_nsobject<EAGLContext> context_;
  fml::scoped_nsobject<EAGLContext> resource_context_;
  GLuint framebuffer_;
  GLuint colorbuffer_;
  GLuint depthbuffer_;
  GLuint stencilbuffer_;
  GLuint depth_stencil_packed_buffer_;
  GLint storage_size_width_;
  GLint storage_size_height_;
  sk_sp<SkColorSpace> color_space_;
  bool valid_;

  FXL_DISALLOW_COPY_AND_ASSIGN(IOSGLContext);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_CONTEXT_H_
