// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "flutter/shell/platform/darwin/ios/ios_render_target_gl.h"

#include <UIKit/UIKit.h>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace flutter {

IOSRenderTargetGL::IOSRenderTargetGL(fml::scoped_nsobject<CAEAGLLayer> layer,
                                     fml::scoped_nsobject<EAGLContext> context)
    : layer_(std::move(layer)), context_(context) {
  FML_DCHECK(layer_ != nullptr);
  FML_DCHECK(context_ != nullptr);

  if (@available(iOS 9.0, *)) {
    [layer_ setPresentsWithTransaction:YES];
  }
  auto context_switch = GLContextSwitch(std::make_unique<IOSSwitchableGLContext>(context_.get()));
  [[maybe_unused]] bool context_current = context_switch.GetResult();

  FML_DCHECK(context_current);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  // Generate the framebuffer

  glGenFramebuffers(1, &framebuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);
  FML_DCHECK(framebuffer_ != GL_NONE);

  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  // Setup color attachment

  glGenRenderbuffers(1, &colorbuffer_);
  FML_DCHECK(colorbuffer_ != GL_NONE);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorbuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  NSString* drawableColorFormat = kEAGLColorFormatRGBA8;
  layer_.get().drawableProperties = @{
    kEAGLDrawablePropertyColorFormat : drawableColorFormat,
    kEAGLDrawablePropertyRetainedBacking : @(NO),
  };

  valid_ = true;
}

IOSRenderTargetGL::~IOSRenderTargetGL() {
  auto context_switch = GLContextSwitch(std::make_unique<IOSSwitchableGLContext>(context_.get()));
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  // Deletes on GL_NONEs are ignored
  glDeleteFramebuffers(1, &framebuffer_);
  glDeleteRenderbuffers(1, &colorbuffer_);

  FML_DCHECK(glGetError() == GL_NO_ERROR);
}

// |IOSRenderTarget|
bool IOSRenderTargetGL::IsValid() const {
  return valid_;
}

// |IOSRenderTarget|
intptr_t IOSRenderTargetGL::GetFramebuffer() const {
  return framebuffer_;
}

// |IOSRenderTarget|
bool IOSRenderTargetGL::PresentRenderBuffer() const {
  const GLenum discards[] = {
      GL_DEPTH_ATTACHMENT,
      GL_STENCIL_ATTACHMENT,
  };

  glDiscardFramebufferEXT(GL_FRAMEBUFFER, sizeof(discards) / sizeof(GLenum), discards);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  auto current_context = [EAGLContext currentContext];
  FML_DCHECK(current_context != nullptr);
  return [current_context presentRenderbuffer:GL_RENDERBUFFER];
}

// |IOSRenderTarget|
bool IOSRenderTargetGL::UpdateStorageSizeIfNecessary() {
  const CGSize layer_size = [layer_.get() bounds].size;
  const CGFloat contents_scale = layer_.get().contentsScale;
  const GLint size_width = layer_size.width * contents_scale;
  const GLint size_height = layer_size.height * contents_scale;

  if (size_width == storage_size_width_ && size_height == storage_size_height_) {
    // Nothing to do since the storage size is already consistent with the layer.
    return true;
  }
  TRACE_EVENT_INSTANT0("flutter", "IOSRenderTargetGL::UpdateStorageSizeIfNecessary");
  FML_DLOG(INFO) << "Updating render buffer storage size.";

  FML_DCHECK(glGetError() == GL_NO_ERROR);

  auto context_switch = GLContextSwitch(std::make_unique<IOSSwitchableGLContext>(context_.get()));
  if (!context_switch.GetResult()) {
    return false;
  }

  FML_DCHECK(glGetError() == GL_NO_ERROR);

  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  auto current_context = [EAGLContext currentContext];
  if (![current_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer_.get()]) {
    return false;
  }

  // Fetch the dimensions of the color buffer whose backing was just updated.
  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &storage_size_width_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &storage_size_height_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  FML_DCHECK(glCheckFramebufferStatus(GL_FRAMEBUFFER) == GL_FRAMEBUFFER_COMPLETE);

  return true;
}

}  // namespace flutter
