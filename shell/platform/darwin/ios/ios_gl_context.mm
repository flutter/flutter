// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/ios_gl_context.h"

#include <UIKit/UIKit.h>

#include "flutter/fml/trace_event.h"
#include "third_party/skia/include/gpu/GrContextOptions.h"
#include "third_party/skia/include/gpu/gl/GrGLInterface.h"

namespace shell {

IOSGLContext::IOSGLContext(fml::scoped_nsobject<CAEAGLLayer> layer)
    : layer_(std::move(layer)),
      framebuffer_(GL_NONE),
      colorbuffer_(GL_NONE),
      storage_size_width_(0),
      storage_size_height_(0),
      valid_(false) {
  context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3]);
  if (context_ != nullptr) {
    resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3
                                                  sharegroup:context_.get().sharegroup]);
  } else {
    context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]);
    resource_context_.reset([[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2
                                                  sharegroup:context_.get().sharegroup]);
  }

  FML_DCHECK(layer_ != nullptr);
  FML_DCHECK(context_ != nullptr);
  FML_DCHECK(resource_context_ != nullptr);

  bool context_current = [EAGLContext setCurrentContext:context_];

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

  // TODO:
  // iOS displays are more variable than just P3 or sRGB.  Reading the display
  // gamut just tells us what color space it makes sense to render into.  We
  // should use iOS APIs to perform the final correction step based on the
  // device properties.  Ex: We can indicate that we have rendered in P3, and
  // the framework will do the final adjustment for us.
  color_space_ = SkColorSpace::MakeSRGB();
  if (@available(iOS 10, *)) {
    UIDisplayGamut displayGamut = [UIScreen mainScreen].traitCollection.displayGamut;
    switch (displayGamut) {
      case UIDisplayGamutP3:
        // Should we consider using more than 8-bits of precision given that
        // P3 specifies a wider range of colors?
        color_space_ = SkColorSpace::MakeRGB(SkColorSpace::kSRGB_RenderTargetGamma,
                                             SkColorSpace::kDCIP3_D65_Gamut);
        break;
      default:
        break;
    }
  }

  NSString* drawableColorFormat = kEAGLColorFormatRGBA8;
  layer_.get().drawableProperties = @{
    kEAGLDrawablePropertyColorFormat : drawableColorFormat,
    kEAGLDrawablePropertyRetainedBacking : @(NO),
  };

  valid_ = true;
}

IOSGLContext::~IOSGLContext() {
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  // Deletes on GL_NONEs are ignored
  glDeleteFramebuffers(1, &framebuffer_);
  glDeleteRenderbuffers(1, &colorbuffer_);

  FML_DCHECK(glGetError() == GL_NO_ERROR);
}

bool IOSGLContext::IsValid() const {
  return valid_;
}

bool IOSGLContext::PresentRenderBuffer() const {
  const GLenum discards[] = {
      GL_DEPTH_ATTACHMENT,
      GL_STENCIL_ATTACHMENT,
  };

  glDiscardFramebufferEXT(GL_FRAMEBUFFER, sizeof(discards) / sizeof(GLenum), discards);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  return [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
}

bool IOSGLContext::UpdateStorageSizeIfNecessary() {
  const CGSize layer_size = [layer_.get() bounds].size;
  const CGFloat contents_scale = layer_.get().contentsScale;
  const GLint size_width = layer_size.width * contents_scale;
  const GLint size_height = layer_size.height * contents_scale;

  if (size_width == storage_size_width_ && size_height == storage_size_height_) {
    // Nothing to since the stoage size is already consistent with the layer.
    return true;
  }
  TRACE_EVENT_INSTANT0("flutter", "IOSGLContext::UpdateStorageSizeIfNecessary");
  FML_DLOG(INFO) << "Updating render buffer storage size.";

  FML_DCHECK(glGetError() == GL_NO_ERROR);

  if (![EAGLContext setCurrentContext:context_]) {
    return false;
  }

  FML_DCHECK(glGetError() == GL_NO_ERROR);

  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  FML_DCHECK(glGetError() == GL_NO_ERROR);

  if (![context_.get() renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer_.get()]) {
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

bool IOSGLContext::MakeCurrent() {
  return UpdateStorageSizeIfNecessary() && [EAGLContext setCurrentContext:context_.get()];
}

bool IOSGLContext::ResourceMakeCurrent() {
  return [EAGLContext setCurrentContext:resource_context_.get()];
}

}  // namespace shell
