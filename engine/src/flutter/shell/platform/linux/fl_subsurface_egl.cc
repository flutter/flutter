// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_subsurface_egl.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <wayland-client.h>
#include <wayland-egl.h>

struct _FlSubsurfaceEGL {
  GObject parent_instance;

  // OpenGL manager providing the shared EGL display and context. The display is
  // owned by the engine and must not be terminated here.
  FlOpenGLManager* opengl_manager;

  // Native Wayland window backing the EGL surface.
  struct wl_egl_window* egl_window;

  // EGL context used to blit engine frames. Shares resources with the engine's
  // render context.
  EGLContext egl_context;

  // EGL surface that draws onto egl_window.
  EGLSurface egl_surface;
};

G_DEFINE_TYPE(FlSubsurfaceEGL, fl_subsurface_egl, G_TYPE_OBJECT)

// Gets the EGL display the engine renders to. The subsurface shares this
// display so its context can access the engine's frame texture directly.
static EGLDisplay get_display(FlSubsurfaceEGL* self) {
  return fl_opengl_manager_get_display(self->opengl_manager);
}

// Sets up the EGL context and window surface for the subsurface.
static gboolean setup(FlSubsurfaceEGL* self,
                      struct wl_surface* surface,
                      size_t width,
                      size_t height,
                      gint scale) {
  // Share the engine's EGL display and render context so the engine's frame
  // texture can be accessed directly, without using EGLImage.
  EGLDisplay egl_display = get_display(self);
  if (egl_display == EGL_NO_DISPLAY) {
    g_warning("Failed to get EGL display for subsurface");
    return FALSE;
  }

  static const EGLint config_attributes[] = {EGL_SURFACE_TYPE,
                                             EGL_WINDOW_BIT,
                                             EGL_RENDERABLE_TYPE,
                                             EGL_OPENGL_ES2_BIT,
                                             EGL_RED_SIZE,
                                             8,
                                             EGL_GREEN_SIZE,
                                             8,
                                             EGL_BLUE_SIZE,
                                             8,
                                             EGL_ALPHA_SIZE,
                                             8,
                                             EGL_NONE};
  EGLConfig egl_config;
  EGLint num_config;
  if (!eglChooseConfig(egl_display, config_attributes, &egl_config, 1,
                       &num_config) ||
      num_config == 0) {
    g_warning("Failed to choose EGL config for subsurface");
    return FALSE;
  }

  eglBindAPI(EGL_OPENGL_ES_API);

  static const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                              EGL_NONE};
  EGLContext share_context =
      fl_opengl_manager_get_context(self->opengl_manager);
  self->egl_context = eglCreateContext(egl_display, egl_config, share_context,
                                       context_attributes);
  if (self->egl_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL context for subsurface");
    return FALSE;
  }

  self->egl_window =
      wl_egl_window_create(surface, width * scale, height * scale);
  if (self->egl_window == nullptr) {
    g_warning("Failed to create wl_egl_window for subsurface");
    return FALSE;
  }

  self->egl_surface = eglCreateWindowSurface(
      egl_display, egl_config,
      reinterpret_cast<EGLNativeWindowType>(self->egl_window), nullptr);
  if (self->egl_surface == EGL_NO_SURFACE) {
    g_warning("Failed to create EGL window surface for subsurface");
    return FALSE;
  }

  wl_surface_set_buffer_scale(surface, scale);

  eglMakeCurrent(egl_display, self->egl_surface, self->egl_surface,
                 self->egl_context);
  eglSwapInterval(egl_display, 0);
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
  return TRUE;
}

static void fl_subsurface_egl_dispose(GObject* object) {
  FlSubsurfaceEGL* self = FL_SUBSURFACE_EGL(object);

  // The EGL display is owned by the engine (same Wayland display), so only the
  // surface and context created here are destroyed; the display must not be
  // terminated.
  if (self->opengl_manager != nullptr) {
    EGLDisplay egl_display = get_display(self);
    if (self->egl_surface != EGL_NO_SURFACE) {
      eglDestroySurface(egl_display, self->egl_surface);
      self->egl_surface = EGL_NO_SURFACE;
    }
    if (self->egl_context != EGL_NO_CONTEXT) {
      eglDestroyContext(egl_display, self->egl_context);
      self->egl_context = EGL_NO_CONTEXT;
    }
  }
  if (self->egl_window != nullptr) {
    wl_egl_window_destroy(self->egl_window);
    self->egl_window = nullptr;
  }
  g_clear_object(&self->opengl_manager);

  G_OBJECT_CLASS(fl_subsurface_egl_parent_class)->dispose(object);
}

static void fl_subsurface_egl_class_init(FlSubsurfaceEGLClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_subsurface_egl_dispose;
}

static void fl_subsurface_egl_init(FlSubsurfaceEGL* self) {
  self->egl_context = EGL_NO_CONTEXT;
  self->egl_surface = EGL_NO_SURFACE;
}

FlSubsurfaceEGL* fl_subsurface_egl_new(FlOpenGLManager* opengl_manager,
                                       struct wl_surface* surface,
                                       size_t width,
                                       size_t height,
                                       gint scale) {
  FlSubsurfaceEGL* self =
      FL_SUBSURFACE_EGL(g_object_new(fl_subsurface_egl_get_type(), nullptr));
  self->opengl_manager = FL_OPENGL_MANAGER(g_object_ref(opengl_manager));

  if (!setup(self, surface, width, height, scale)) {
    g_object_unref(self);
    return nullptr;
  }

  return self;
}

void fl_subsurface_egl_resize(FlSubsurfaceEGL* self,
                              size_t width,
                              size_t height) {
  g_return_if_fail(FL_IS_SUBSURFACE_EGL(self));

  if (self->egl_window != nullptr) {
    wl_egl_window_resize(self->egl_window, width, height, 0, 0);
  }
}

void fl_subsurface_egl_present(FlSubsurfaceEGL* self,
                               GLuint texture_id,
                               size_t width,
                               size_t height) {
  g_return_if_fail(FL_IS_SUBSURFACE_EGL(self));

  // Blit the composited frame directly to the subsurface window surface using
  // the subsurface's own EGL context.
  EGLDisplay egl_display = get_display(self);
  eglMakeCurrent(egl_display, self->egl_surface, self->egl_surface,
                 self->egl_context);

  EGLint surface_width, surface_height;
  eglQuerySurface(egl_display, self->egl_surface, EGL_WIDTH, &surface_width);
  eglQuerySurface(egl_display, self->egl_surface, EGL_HEIGHT, &surface_height);
  if (static_cast<size_t>(surface_width) != width ||
      static_cast<size_t>(surface_height) != height) {
    wl_egl_window_resize(self->egl_window, width, height, 0, 0);
  }

  // The subsurface context shares resources with the engine, so the engine's
  // frame texture can be read directly. Attach it to a framebuffer and blit it
  // to the subsurface window surface. The framebuffer is created and deleted
  // while the context is current.
  GLuint read_framebuffer;
  glGenFramebuffers(1, &read_framebuffer);
  glBindFramebuffer(GL_READ_FRAMEBUFFER, read_framebuffer);
  glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D, texture_id, 0);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
  glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                    GL_COLOR_BUFFER_BIT, GL_NEAREST);
  eglSwapBuffers(egl_display, self->egl_surface);
  glDeleteFramebuffers(1, &read_framebuffer);

  // Restore the engine's rendering context so the raster thread can continue
  // rendering after this present.
  fl_opengl_manager_make_current(self->opengl_manager);
}
