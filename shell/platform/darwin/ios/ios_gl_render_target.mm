// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_gl_render_target.h"

#include <UIKit/UIKit.h>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace flutter {

IOSGLRenderTarget::IOSGLRenderTarget(
    fml::scoped_nsobject<CAEAGLLayer> layer,
    std::shared_ptr<IOSGLContextSwitchManager> gl_context_guard_manager)
    : layer_(std::move(layer)),
      renderer_context_switch_manager_(gl_context_guard_manager),
      framebuffer_(GL_NONE),
      colorbuffer_(GL_NONE),
      storage_size_width_(0),
      storage_size_height_(0),
      valid_(false) {
  FML_DCHECK(layer_ != nullptr);
  std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch> context_switch =
      renderer_context_switch_manager_->MakeCurrent();
  bool context_current = context_switch->GetSwitchResult();

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

IOSGLRenderTarget::~IOSGLRenderTarget() {
  std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch> context_switch =
      renderer_context_switch_manager_->MakeCurrent();
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  // Deletes on GL_NONEs are ignored
  glDeleteFramebuffers(1, &framebuffer_);
  glDeleteRenderbuffers(1, &colorbuffer_);

  FML_DCHECK(glGetError() == GL_NO_ERROR);
}

bool IOSGLRenderTarget::IsValid() const {
  return valid_;
}

bool IOSGLRenderTarget::PresentRenderBuffer() const {
  const GLenum discards[] = {
      GL_DEPTH_ATTACHMENT,
      GL_STENCIL_ATTACHMENT,
  };

  glDiscardFramebufferEXT(GL_FRAMEBUFFER, sizeof(discards) / sizeof(GLenum), discards);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  return [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
}

bool IOSGLRenderTarget::UpdateStorageSizeIfNecessary() {
  const CGSize layer_size = [layer_.get() bounds].size;
  const CGFloat contents_scale = layer_.get().contentsScale;
  const GLint size_width = layer_size.width * contents_scale;
  const GLint size_height = layer_size.height * contents_scale;

  if (size_width == storage_size_width_ && size_height == storage_size_height_) {
    // Nothing to since the stoage size is already consistent with the layer.
    return true;
  }
  TRACE_EVENT_INSTANT0("flutter", "IOSGLRenderTarget::UpdateStorageSizeIfNecessary");
  FML_DLOG(INFO) << "Updating render buffer storage size.";

  FML_DCHECK(glGetError() == GL_NO_ERROR);
  std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch> context_switch =
      renderer_context_switch_manager_->MakeCurrent();
  if (!context_switch->GetSwitchResult()) {
    return false;
  }

  FML_DCHECK(glGetError() == GL_NO_ERROR);

  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  if (![renderer_context_switch_manager_->GetContext().get() renderbufferStorage:GL_RENDERBUFFER
                                                                    fromDrawable:layer_.get()]) {
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

std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
IOSGLRenderTarget::MakeCurrent() {
  bool isUpdateSuccessful = UpdateStorageSizeIfNecessary();
  if (!isUpdateSuccessful) {
    return std::make_unique<RendererContextSwitchManager::RendererContextSwitchPureResult>(false);
  }
  return renderer_context_switch_manager_->MakeCurrent();
}

std::unique_ptr<RendererContextSwitchManager::RendererContextSwitch>
IOSGLRenderTarget::ResourceMakeCurrent() {
  return renderer_context_switch_manager_->ResourceMakeCurrent();
}

}  // namespace flutter
