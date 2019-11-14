// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_RENDER_TARGET_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_RENDER_TARGET_H_

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAEAGLLayer.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/shell/common/platform_view.h"
#include "flutter/shell/platform/darwin/ios/ios_gl_context_switch_manager.h"

namespace flutter {

class IOSGLRenderTarget {
 public:
  IOSGLRenderTarget(
      fml::scoped_nsobject<CAEAGLLayer> layer,
      std::shared_ptr<IOSGLContextSwitchManager> gl_context_guard_manager);

  ~IOSGLRenderTarget();

  bool IsValid() const;

  bool PresentRenderBuffer() const;

  GLuint framebuffer() const { return framebuffer_; }

  bool UpdateStorageSizeIfNecessary();

  std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
  MakeCurrent();

  std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
  ResourceMakeCurrent();

  sk_sp<SkColorSpace> ColorSpace() const { return color_space_; }

 private:
  fml::scoped_nsobject<CAEAGLLayer> layer_;
  std::shared_ptr<IOSGLContextSwitchManager> renderer_context_switch_manager_;
  GLuint framebuffer_;
  GLuint colorbuffer_;
  GLint storage_size_width_;
  GLint storage_size_height_;
  sk_sp<SkColorSpace> color_space_;
  bool valid_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOSGLRenderTarget);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_IOS_GL_RENDER_TARGET_H_
