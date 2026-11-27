// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_WINDOWS_BACKDROP_TARGET_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_WINDOWS_BACKDROP_TARGET_H_

#include <cstdint>

#include "flutter/fml/closure.h"
#include "impeller/renderer/backend/gles/gles.h"

namespace impeller {

// The embedder describes the image it presents, not the underlying FBO
// attachments. Verify their current state before drawing to a named GLES 3 FBO.
template <class GL>
bool IsCompatibleWindowsBackdropTarget(const GL& gl,
                                       GLuint framebuffer,
                                       int64_t expected_width,
                                       int64_t expected_height) {
  if (!gl.IsFramebuffer(framebuffer)) {
    return false;
  }

  GLint old_draw = 0;
  GLint old_renderbuffer = 0;
  gl.GetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &old_draw);
  gl.GetIntegerv(GL_RENDERBUFFER_BINDING, &old_renderbuffer);
  if (static_cast<GLuint>(old_draw) != framebuffer) {
    gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, framebuffer);
  }
  fml::ScopedCleanupClosure restore([&] {
    gl.BindRenderbuffer(GL_RENDERBUFFER, static_cast<GLuint>(old_renderbuffer));
    if (static_cast<GLuint>(old_draw) != framebuffer) {
      gl.BindFramebuffer(GL_DRAW_FRAMEBUFFER, static_cast<GLuint>(old_draw));
    }
  });
  if (gl.CheckFramebufferStatus(GL_DRAW_FRAMEBUFFER) !=
      GL_FRAMEBUFFER_COMPLETE) {
    return false;
  }
  GLint max_draw_buffers = 0;
  gl.GetIntegerv(GL_MAX_DRAW_BUFFERS, &max_draw_buffers);
  for (GLint i = 0; i < max_draw_buffers; i++) {
    GLint draw_buffer = GL_NONE;
    gl.GetIntegerv(GL_DRAW_BUFFER0 + i, &draw_buffer);
    if (draw_buffer != (i == 0 ? GL_COLOR_ATTACHMENT0 : GL_NONE)) {
      return false;
    }
  }

  auto renderbuffer_name = [&](GLenum attachment) -> GLint {
    GLint type = GL_NONE;
    gl.GetFramebufferAttachmentParameteriv(
        GL_DRAW_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE,
        &type);
    if (type != GL_RENDERBUFFER) {
      return 0;
    }
    GLint name = 0;
    gl.GetFramebufferAttachmentParameteriv(
        GL_DRAW_FRAMEBUFFER, attachment, GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME,
        &name);
    return name;
  };
  const GLint color = renderbuffer_name(GL_COLOR_ATTACHMENT0);
  const GLint depth = renderbuffer_name(GL_DEPTH_ATTACHMENT);
  if (!color || !depth || depth != renderbuffer_name(GL_STENCIL_ATTACHMENT)) {
    return false;
  }
  auto matches = [&](GLint name, GLint expected_format) {
    gl.BindRenderbuffer(GL_RENDERBUFFER, static_cast<GLuint>(name));
    GLint format = 0, samples = 0, width = 0, height = 0;
    gl.GetRenderbufferParameteriv(GL_RENDERBUFFER,
                                  GL_RENDERBUFFER_INTERNAL_FORMAT, &format);
    gl.GetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_SAMPLES,
                                  &samples);
    gl.GetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH,
                                  &width);
    gl.GetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT,
                                  &height);
    return format == expected_format && samples == 4 &&
           width == expected_width && height == expected_height;
  };
  return matches(color, GL_BGRA8_EXT) && matches(depth, GL_DEPTH24_STENCIL8);
}

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_WINDOWS_BACKDROP_TARGET_H_
