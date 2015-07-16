// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/scoped_binders.h"
#include "ui/gl/gl_bindings.h"
#include "ui/gl/gl_context.h"
#include "ui/gl/gl_state_restorer.h"

namespace gfx {

ScopedFrameBufferBinder::ScopedFrameBufferBinder(unsigned int fbo)
    : state_restorer_(!GLContext::GetCurrent()
                          ? NULL
                          : GLContext::GetCurrent()->GetGLStateRestorer()),
      old_fbo_(-1) {
  if (!state_restorer_)
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old_fbo_);
  glBindFramebufferEXT(GL_FRAMEBUFFER, fbo);
}

ScopedFrameBufferBinder::~ScopedFrameBufferBinder() {
  if (state_restorer_) {
    DCHECK(!!GLContext::GetCurrent());
    DCHECK_EQ(state_restorer_, GLContext::GetCurrent()->GetGLStateRestorer());
    state_restorer_->RestoreFramebufferBindings();
  } else {
    glBindFramebufferEXT(GL_FRAMEBUFFER, old_fbo_);
  }
}

ScopedTextureBinder::ScopedTextureBinder(unsigned int target, unsigned int id)
    : state_restorer_(!GLContext::GetCurrent()
                          ? NULL
                          : GLContext::GetCurrent()->GetGLStateRestorer()),
      target_(target),
      old_id_(-1) {
  if (!state_restorer_) {
    GLenum target_getter = 0;
    switch (target) {
      case GL_TEXTURE_2D:
        target_getter = GL_TEXTURE_BINDING_2D;
        break;
      case GL_TEXTURE_CUBE_MAP:
        target_getter = GL_TEXTURE_BINDING_CUBE_MAP;
        break;
      case GL_TEXTURE_EXTERNAL_OES:
        target_getter = GL_TEXTURE_BINDING_EXTERNAL_OES;
        break;
      default:
        NOTIMPLEMENTED() << "Target not part of OpenGL ES 2.0 spec.";
    }
    glGetIntegerv(target_getter, &old_id_);
  }
  glBindTexture(target_, id);
}

ScopedTextureBinder::~ScopedTextureBinder() {
  if (state_restorer_) {
    DCHECK(!!GLContext::GetCurrent());
    DCHECK_EQ(state_restorer_, GLContext::GetCurrent()->GetGLStateRestorer());
    state_restorer_->RestoreActiveTextureUnitBinding(target_);
  } else {
    glBindTexture(target_, old_id_);
  }
}

}  // namespace gfx
