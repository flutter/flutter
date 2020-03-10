// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_RENDER_TARGET_GL_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_RENDER_TARGET_GL_H_

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAEAGLLayer.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"

namespace flutter {

class IOSRenderTargetGL {
 public:
  IOSRenderTargetGL(fml::scoped_nsobject<CAEAGLLayer> layer,
                    fml::scoped_nsobject<EAGLContext> context,
                    fml::scoped_nsobject<EAGLContext> resource_context);

  ~IOSRenderTargetGL();

  bool IsValid() const;

  bool PresentRenderBuffer() const;

  intptr_t GetFramebuffer() const;

  bool UpdateStorageSizeIfNecessary();

 private:
  fml::scoped_nsobject<CAEAGLLayer> layer_;
  fml::scoped_nsobject<EAGLContext> context_;
  fml::scoped_nsobject<EAGLContext> resource_context_;
  GLuint framebuffer_ = GL_NONE;
  GLuint colorbuffer_ = GL_NONE;
  GLint storage_size_width_ = GL_NONE;
  GLint storage_size_height_ = GL_NONE;
  bool valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSRenderTargetGL);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_RENDER_TARGET_GL_H_
