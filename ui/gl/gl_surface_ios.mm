// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/scoped_nsautorelease_pool.h"
#include "ui/gl/gl_surface_ios.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_enums.h"
#include "base/logging.h"

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/CAEAGLLayer.h>

namespace gfx {

#define WIDGET_AS_LAYER (reinterpret_cast<CAEAGLLayer*>(widget_))
#define CAST_CONTEXT(c) (reinterpret_cast<EAGLContext*>((c)))

GLSurfaceIOS::GLSurfaceIOS(gfx::AcceleratedWidget widget,
                     const gfx::SurfaceConfiguration requested_configuration)
    : GLSurface(requested_configuration),
      widget_(widget),
      framebuffer_(GL_NONE),
      colorbuffer_(GL_NONE),
      depthbuffer_(GL_NONE),
      stencilbuffer_(GL_NONE),
      depth_stencil_packed_buffer_(GL_NONE),
      last_configured_size_(),
      framebuffer_setup_complete_(false) {
}

GLSurfaceIOS::~GLSurfaceIOS() {}

#ifndef NDEBUG
static void GLSurfaceIOS_AssertFramebufferCompleteness(void) {
  GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
  DLOG_IF(FATAL, status != GL_FRAMEBUFFER_COMPLETE)
      << "Framebuffer incomplete on GLSurfaceIOS::MakeCurrent: "
      << GLEnums::GetStringEnum(status);
}
#else
#define GLSurfaceIOS_AssertFramebufferCompleteness(...)
#endif

bool GLSurfaceIOS::OnMakeCurrent(GLContext* context) {
  Size new_size = GetSize();

  if (new_size == last_configured_size_) {
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);
    GLSurfaceIOS_AssertFramebufferCompleteness();
    return true;
  }

  base::mac::ScopedNSAutoreleasePool pool;

  SetupFramebufferIfNecessary();
  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  DCHECK(glGetError() == GL_NO_ERROR);

  auto context_handle = context->GetHandle();
  DCHECK(context_handle);

  BOOL res = [CAST_CONTEXT(context_handle) renderbufferStorage:GL_RENDERBUFFER
                                                  fromDrawable:WIDGET_AS_LAYER];

  if (!res) {
    return false;
  }

  GLint width = 0;
  GLint height = 0;
  bool rebind_color_buffer = false;
  if (depthbuffer_ != GL_NONE
      || stencilbuffer_ != GL_NONE
      || depth_stencil_packed_buffer_ != GL_NONE) {
    // Fetch the dimensions of the color buffer whose backing was just updated
    // so that backing of the attachments can be updated

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,
                                 &width);
    DCHECK(glGetError() == GL_NO_ERROR);

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT,
                                 &height);
    DCHECK(glGetError() == GL_NO_ERROR);

    rebind_color_buffer = true;
  }

  if (depth_stencil_packed_buffer_ != GL_NONE) {
    glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil_packed_buffer_);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH24_STENCIL8_OES,
                          width, height);
    DCHECK(glGetError() == GL_NO_ERROR);
  }

  if (depthbuffer_ != GL_NONE) {
    glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer_);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, width, height);
    DCHECK(glGetError() == GL_NO_ERROR);
  }

  if (stencilbuffer_ != GL_NONE) {
    glBindRenderbuffer(GL_RENDERBUFFER, stencilbuffer_);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_STENCIL_INDEX8, width, height);
    DCHECK(glGetError() == GL_NO_ERROR);
  }

  if (rebind_color_buffer) {
    glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
    DCHECK(glGetError() == GL_NO_ERROR);
  }

  last_configured_size_ = new_size;
  GLSurfaceIOS_AssertFramebufferCompleteness();
  return true;
}

void GLSurfaceIOS::SetupFramebufferIfNecessary() {
  if (framebuffer_setup_complete_) {
    return;
  }

  DCHECK(framebuffer_ == GL_NONE);
  DCHECK(colorbuffer_ == GL_NONE);

  DCHECK(widget_ != kNullAcceleratedWidget);
  DCHECK(glGetError() == GL_NO_ERROR);

  // Generate the framebuffer

  glGenFramebuffers(1, &framebuffer_);
  DCHECK(framebuffer_ != GL_NONE);

  glBindFramebuffer(GL_FRAMEBUFFER, framebuffer_);
  DCHECK(glGetError() == GL_NO_ERROR);

  // Setup color attachment

  glGenRenderbuffers(1, &colorbuffer_);
  DCHECK(colorbuffer_ != GL_NONE);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  DCHECK(glGetError() == GL_NO_ERROR);

  glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                            GL_RENDERBUFFER, colorbuffer_);
  DCHECK(glGetError() == GL_NO_ERROR);

  auto config = get_surface_configuration();

  // On iOS, if both depth and stencil attachments are requested, we are
  // required to create a single renderbuffer that acts as both.

  auto requires_packed = (config.depth_bits != 0) && (config.stencil_bits != 0);

  if (requires_packed) {
    glGenRenderbuffers(1, &depth_stencil_packed_buffer_);
    glBindRenderbuffer(GL_RENDERBUFFER, depth_stencil_packed_buffer_);
    DCHECK(depth_stencil_packed_buffer_ != GL_NONE);

    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, depth_stencil_packed_buffer_);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                              GL_RENDERBUFFER, depth_stencil_packed_buffer_);
    DCHECK(depth_stencil_packed_buffer_ != GL_NONE);
  } else {
    // Setup the depth attachment if necessary

    if (config.depth_bits != 0) {
      glGenRenderbuffers(1, &depthbuffer_);
      DCHECK(depthbuffer_ != GL_NONE);

      glBindRenderbuffer(GL_RENDERBUFFER, depthbuffer_);
      DCHECK(glGetError() == GL_NO_ERROR);

      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                                GL_RENDERBUFFER, depthbuffer_);
      DCHECK(glGetError() == GL_NO_ERROR);
    }

    if (config.stencil_bits != 0) {
      // Setup the stencil attachment if necessary

      glGenRenderbuffers(1, &stencilbuffer_);
      DCHECK(stencilbuffer_ != GL_NONE);

      glBindRenderbuffer(GL_RENDERBUFFER, stencilbuffer_);
      DCHECK(glGetError() == GL_NO_ERROR);

      glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_STENCIL_ATTACHMENT,
                                GL_RENDERBUFFER, stencilbuffer_);
      DCHECK(glGetError() == GL_NO_ERROR);
    }
  }

  // The default is RGBA
  NSString *drawableColorFormat = kEAGLColorFormatRGBA8;

  if (config.red_bits <= 5
      && config.green_bits <= 6
      && config.blue_bits <= 5
      && config.alpha_bits == 0) {
    drawableColorFormat = kEAGLColorFormatRGB565;
  }

  WIDGET_AS_LAYER.drawableProperties = @{
    kEAGLDrawablePropertyColorFormat : drawableColorFormat,
    kEAGLDrawablePropertyRetainedBacking : @(NO),
  };

  framebuffer_setup_complete_ = true;
}

bool GLSurfaceIOS::SwapBuffers() {
  const GLenum discards[] = {
    GL_DEPTH_ATTACHMENT,
    GL_STENCIL_ATTACHMENT,
  };

  glDiscardFramebufferEXT(GL_FRAMEBUFFER, sizeof(discards) / sizeof(GLenum),
                          discards);

  glBindRenderbuffer(GL_RENDERBUFFER, colorbuffer_);
  return [[EAGLContext currentContext] presentRenderbuffer:GL_RENDERBUFFER];
}

unsigned int GLSurfaceIOS::GetBackingFrameBufferObject() {
  return framebuffer_;
}

bool GLSurfaceIOS::Resize(const gfx::Size& size) {
  // The backing layer has already been updated.
  return true;
}

void GLSurfaceIOS::Destroy() {
  DCHECK(glGetError() == GL_NO_ERROR);

  glDeleteFramebuffers(1, &framebuffer_);
  glDeleteRenderbuffers(1, &colorbuffer_);
  // Deletes on GL_NONEs are ignored
  glDeleteRenderbuffers(1, &depthbuffer_);
  glDeleteRenderbuffers(1, &stencilbuffer_);
  glDeleteRenderbuffers(1, &depth_stencil_packed_buffer_);

  DCHECK(glGetError() == GL_NO_ERROR);
}

bool GLSurfaceIOS::IsOffscreen() {
  return widget_ == kNullAcceleratedWidget;
}

gfx::Size GLSurfaceIOS::GetSize() {
  CGSize layer_size = WIDGET_AS_LAYER.bounds.size;
  return Size(layer_size.width, layer_size.height);
}

void* GLSurfaceIOS::GetHandle() {
  return (void*)widget_;
}

bool GLSurface::InitializeOneOffInternal() {
  // On EGL, this method is used to perfom one-time initialization tasks like
  // initializing the display, setting up config lists, etc. There is no such
  // setup on iOS.
  return true;
}

// static
scoped_refptr<GLSurface> GLSurface::CreateViewGLSurface(
      gfx::AcceleratedWidget window,
      const gfx::SurfaceConfiguration& requested_configuration) {
  DCHECK(window != kNullAcceleratedWidget);
  scoped_refptr<GLSurfaceIOS> surface =
    new GLSurfaceIOS(window, requested_configuration);

  if (!surface->Initialize())
    return NULL;

  return surface;
}

}  // namespace gfx
