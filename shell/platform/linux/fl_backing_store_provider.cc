// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_backing_store_provider.h"

#include <epoxy/gl.h>

struct _FlBackingStoreProvider {
  GObject parent_instance;

  uint32_t framebuffer_id;
  uint32_t texture_id;
  GdkRectangle geometry;
};

G_DEFINE_TYPE(FlBackingStoreProvider, fl_backing_store_provider, G_TYPE_OBJECT)

static void fl_backing_store_provider_dispose(GObject* object) {
  FlBackingStoreProvider* self = FL_BACKING_STORE_PROVIDER(object);

  glDeleteFramebuffers(1, &self->framebuffer_id);
  glDeleteTextures(1, &self->texture_id);

  G_OBJECT_CLASS(fl_backing_store_provider_parent_class)->dispose(object);
}

static void fl_backing_store_provider_class_init(
    FlBackingStoreProviderClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_backing_store_provider_dispose;
}

static void fl_backing_store_provider_init(FlBackingStoreProvider* self) {}

FlBackingStoreProvider* fl_backing_store_provider_new(int width, int height) {
  FlBackingStoreProvider* provider = FL_BACKING_STORE_PROVIDER(
      g_object_new(fl_backing_store_provider_get_type(), nullptr));

  provider->geometry = {
      .x = 0,
      .y = 0,
      .width = width,
      .height = height,
  };

  glGenTextures(1, &provider->texture_id);
  glGenFramebuffers(1, &provider->framebuffer_id);

  glBindFramebuffer(GL_FRAMEBUFFER, provider->framebuffer_id);

  glBindTexture(GL_TEXTURE_2D, provider->texture_id);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, width, height, 0, GL_RGBA,
               GL_UNSIGNED_BYTE, NULL);
  glBindTexture(GL_TEXTURE_2D, 0);

  glFramebufferTexture2D(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT,
                         GL_TEXTURE_2D, provider->texture_id, 0);

  return provider;
}

uint32_t fl_backing_store_provider_get_gl_framebuffer_id(
    FlBackingStoreProvider* self) {
  return self->framebuffer_id;
}

uint32_t fl_backing_store_provider_get_gl_texture_id(
    FlBackingStoreProvider* self) {
  return self->texture_id;
}

uint32_t fl_backing_store_provider_get_gl_target(FlBackingStoreProvider* self) {
  return GL_TEXTURE_2D;
}

uint32_t fl_backing_store_provider_get_gl_format(FlBackingStoreProvider* self) {
  // Flutter defines SK_R32_SHIFT=16, so SK_PMCOLOR_BYTE_ORDER should be BGRA.
  // In Linux kN32_SkColorType is assumed to be kBGRA_8888_SkColorType.
  // So we must choose a valid gl format to be compatible with surface format
  // BGRA8.
  // Following logic is copied from Skia GrGLCaps.cpp:
  // https://github.com/google/skia/blob/4738ed711e03212aceec3cd502a4adb545f38e63/src/gpu/ganesh/gl/GrGLCaps.cpp#L1963-L2116

  if (epoxy_is_desktop_gl()) {
    // For OpenGL.
    if (epoxy_gl_version() >= 12 || epoxy_has_gl_extension("GL_EXT_bgra")) {
      return GL_RGBA8;
    }
  } else {
    // For OpenGL ES.
    if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888") ||
        (epoxy_has_gl_extension("GL_APPLE_texture_format_BGRA8888") &&
         epoxy_gl_version() >= 30)) {
      return GL_BGRA8_EXT;
    }
  }
  g_critical("Failed to determine valid GL format for Flutter rendering");
  return GL_RGBA8;
}

GdkRectangle fl_backing_store_provider_get_geometry(
    FlBackingStoreProvider* self) {
  return self->geometry;
}
