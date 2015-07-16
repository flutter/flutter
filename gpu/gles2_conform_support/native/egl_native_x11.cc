// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <EGL/egl.h>
#include <EGL/eglext.h>

extern "C" {
#if defined(GLES2_CONFORM_SUPPORT_ONLY)
#include "gpu/gles2_conform_support/gtf/gtf_stubs.h"
#else
#include "third_party/gles2_conform/GTF_ES/glsl/GTF/Source/eglNative.h"
#endif

EGLImageKHR GTFCreateEGLImage(int width, int height,
                              GLenum format, GLenum type) {
  PFNEGLCREATEIMAGEKHRPROC egl_create_image_khr_;
  egl_create_image_khr_ = reinterpret_cast<PFNEGLCREATEIMAGEKHRPROC>
                            (eglGetProcAddress("eglCreateImageKHR"));

  static const EGLint attrib[] = {
    EGL_IMAGE_PRESERVED_KHR, EGL_TRUE,
    EGL_GL_TEXTURE_LEVEL_KHR, 0,
    EGL_NONE
  };

  if (format != GL_RGBA && format != GL_RGB)
    return static_cast<EGLImageKHR>(NULL);

  if (type != GL_UNSIGNED_BYTE)
    return static_cast<EGLImageKHR>(NULL);

  GLuint texture;
  glGenTextures(1, &texture);
  glBindTexture(GL_TEXTURE_2D, texture);
  glTexImage2D(GL_TEXTURE_2D,
               0,
               format,
               width,
               height,
               0,
               format,
               type,
               NULL);

  // Disable mip-maps because we do not require it.
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);

  if(glGetError() != GL_NO_ERROR)
    return static_cast<EGLImageKHR>(NULL);

  EGLImageKHR egl_image =
      egl_create_image_khr_(eglGetCurrentDisplay(),
                            eglGetCurrentContext(),
                            EGL_GL_TEXTURE_2D_KHR,
                            reinterpret_cast<EGLClientBuffer>(texture),
                            attrib);

  if (eglGetError() == EGL_SUCCESS)
    return egl_image;
  else
    return static_cast<EGLImageKHR>(NULL);
}

void GTFDestroyEGLImage(EGLImageKHR image) {
  PFNEGLDESTROYIMAGEKHRPROC egl_destroy_image_khr_;
  egl_destroy_image_khr_ = reinterpret_cast<PFNEGLDESTROYIMAGEKHRPROC>
                             (eglGetProcAddress("eglDestroyImageKHR"));

  egl_destroy_image_khr_(eglGetCurrentDisplay(), image);
}

}  // extern "C"
