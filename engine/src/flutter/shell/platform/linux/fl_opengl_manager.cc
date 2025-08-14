// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <epoxy/egl.h>
#include <gdk/gdkwayland.h>
#include <gdk/gdkx.h>

#include "flutter/shell/platform/linux/fl_opengl_manager.h"

struct _FlOpenGLManager {
  GObject parent_instance;

  // Display being rendered to.
  EGLDisplay display;

  // Context used by Flutter to render.
  EGLContext render_context;

  // Context used by Flutter to share resources.
  EGLContext resource_context;
};

G_DEFINE_TYPE(FlOpenGLManager, fl_opengl_manager, G_TYPE_OBJECT)

static void fl_opengl_manager_dispose(GObject* object) {
  FlOpenGLManager* self = FL_OPENGL_MANAGER(object);

  eglDestroyContext(self->display, self->render_context);
  eglDestroyContext(self->display, self->resource_context);
  eglTerminate(self->display);

  G_OBJECT_CLASS(fl_opengl_manager_parent_class)->dispose(object);
}

static void fl_opengl_manager_class_init(FlOpenGLManagerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_opengl_manager_dispose;
}

static void fl_opengl_manager_init(FlOpenGLManager* self) {
  GdkDisplay* display = gdk_display_get_default();
  if (GDK_IS_WAYLAND_DISPLAY(display)) {
    self->display = eglGetPlatformDisplayEXT(
        EGL_PLATFORM_WAYLAND_EXT, gdk_wayland_display_get_wl_display(display),
        NULL);
  } else if (GDK_IS_X11_DISPLAY(display)) {
    self->display = eglGetPlatformDisplayEXT(
        EGL_PLATFORM_X11_EXT, gdk_x11_display_get_xdisplay(display), NULL);
  } else {
    g_critical("Unsupported GDK backend, unable to get EGL display");
  }

  eglInitialize(self->display, nullptr, nullptr);

  const EGLint config_attributes[] = {EGL_RED_SIZE,   8, EGL_GREEN_SIZE,   8,
                                      EGL_BLUE_SIZE,  8, EGL_ALPHA_SIZE,   8,
                                      EGL_DEPTH_SIZE, 8, EGL_STENCIL_SIZE, 8,
                                      EGL_NONE};
  EGLConfig config = nullptr;
  EGLint num_config = 0;
  eglChooseConfig(self->display, config_attributes, &config, 1, &num_config);

  const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  self->render_context = eglCreateContext(self->display, config, EGL_NO_CONTEXT,
                                          context_attributes);
  self->resource_context = eglCreateContext(
      self->display, config, self->render_context, context_attributes);
}

FlOpenGLManager* fl_opengl_manager_new() {
  FlOpenGLManager* self =
      FL_OPENGL_MANAGER(g_object_new(fl_opengl_manager_get_type(), nullptr));
  return self;
}

gboolean fl_opengl_manager_make_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        self->render_context) == EGL_TRUE;
}

gboolean fl_opengl_manager_make_resource_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        self->resource_context) == EGL_TRUE;
}

gboolean fl_opengl_manager_clear_current(FlOpenGLManager* self) {
  return eglMakeCurrent(self->display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                        EGL_NO_CONTEXT) == EGL_TRUE;
}
