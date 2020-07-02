// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer.h"

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/egl_utils.h"

G_DEFINE_QUARK(fl_renderer_error_quark, fl_renderer_error)

typedef struct {
  EGLDisplay egl_display;
  EGLConfig egl_config;
  EGLSurface egl_surface;
  EGLContext egl_context;

  EGLSurface resource_surface;
  EGLContext resource_context;
} FlRendererPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FlRenderer, fl_renderer, G_TYPE_OBJECT)

// Creates a resource surface.
static void create_resource_surface(FlRenderer* self, EGLConfig config) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  const EGLint resource_context_attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1,
                                             EGL_NONE};
  priv->resource_surface = eglCreatePbufferSurface(priv->egl_display, config,
                                                   resource_context_attribs);
  if (priv->resource_surface == EGL_NO_SURFACE) {
    g_warning("Failed to create EGL resource surface: %s",
              egl_error_to_string(eglGetError()));
    return;
  }

  priv->resource_context = eglCreateContext(
      priv->egl_display, config, priv->egl_context, context_attributes);
  if (priv->resource_context == EGL_NO_CONTEXT)
    g_warning("Failed to create EGL resource context: %s",
              egl_error_to_string(eglGetError()));
}

static void fl_renderer_class_init(FlRendererClass* klass) {}

static void fl_renderer_init(FlRenderer* self) {}

gboolean fl_renderer_setup(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  // Note the use of EGL_DEFAULT_DISPLAY rather than sharing an existing
  // display connection (e.g. an X11 connection from GTK). This is because
  // this EGL display is going to be accessed by a thread from Flutter. In the
  // case of GTK/X11 the display connection is not thread safe and this would
  // cause a crash.
  priv->egl_display = eglGetDisplay(EGL_DEFAULT_DISPLAY);

  if (!eglInitialize(priv->egl_display, nullptr, nullptr)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to initialze EGL");
    return FALSE;
  }

  EGLint attributes[] = {EGL_RENDERABLE_TYPE,
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
  EGLint n_config;
  if (!eglChooseConfig(priv->egl_display, attributes, &priv->egl_config, 1,
                       &n_config)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to choose EGL config: %s",
                egl_error_to_string(eglGetError()));
    return FALSE;
  }

  if (n_config == 0) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to find appropriate EGL config: %s",
                egl_error_to_string(eglGetError()));
    return FALSE;
  }

  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    g_autofree gchar* config_string =
        egl_config_to_string(priv->egl_display, priv->egl_config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to bind EGL OpenGL ES API using configuration (%s): %s",
                config_string, egl_error_to_string(eglGetError()));
    return FALSE;
  }

  return TRUE;
}

GdkVisual* fl_renderer_get_visual(FlRenderer* self,
                                  GdkScreen* screen,
                                  GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  EGLint visual_id;
  if (!eglGetConfigAttrib(priv->egl_display, priv->egl_config,
                          EGL_NATIVE_VISUAL_ID, &visual_id)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to determine EGL configuration visual");
    return nullptr;
  }

  GdkVisual* visual =
      FL_RENDERER_GET_CLASS(self)->get_visual(self, screen, visual_id);
  if (visual == nullptr) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to find visual 0x%x", visual_id);
    return nullptr;
  }

  return visual;
}

gboolean fl_renderer_start(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  priv->egl_surface = FL_RENDERER_GET_CLASS(self)->create_surface(
      self, priv->egl_display, priv->egl_config);
  if (priv->egl_surface == EGL_NO_SURFACE) {
    g_autofree gchar* config_string =
        egl_config_to_string(priv->egl_display, priv->egl_config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL surface using configuration (%s): %s",
                config_string, egl_error_to_string(eglGetError()));
    return FALSE;
  }

  EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  priv->egl_context = eglCreateContext(priv->egl_display, priv->egl_config,
                                       EGL_NO_CONTEXT, context_attributes);
  if (priv->egl_context == EGL_NO_CONTEXT) {
    g_autofree gchar* config_string =
        egl_config_to_string(priv->egl_display, priv->egl_config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL context using configuration (%s): %s",
                config_string, egl_error_to_string(eglGetError()));
    return FALSE;
  }

  create_resource_surface(self, priv->egl_config);

  return TRUE;
}

void* fl_renderer_get_proc_address(FlRenderer* self, const char* name) {
  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

gboolean fl_renderer_make_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (!eglMakeCurrent(priv->egl_display, priv->egl_surface, priv->egl_surface,
                      priv->egl_context)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to make EGL context current: %s",
                egl_error_to_string(eglGetError()));
    return FALSE;
  }

  return TRUE;
}

gboolean fl_renderer_make_resource_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (priv->resource_surface == EGL_NO_SURFACE ||
      priv->resource_context == EGL_NO_CONTEXT)
    return FALSE;

  if (!eglMakeCurrent(priv->egl_display, priv->resource_surface,
                      priv->resource_surface, priv->resource_context)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to make EGL context current: %s",
                egl_error_to_string(eglGetError()));
    return FALSE;
  }

  return TRUE;
}

gboolean fl_renderer_clear_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (!eglMakeCurrent(priv->egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                      EGL_NO_CONTEXT)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to clear EGL context: %s",
                egl_error_to_string(eglGetError()));
    return FALSE;
  }

  return TRUE;
}

guint32 fl_renderer_get_fbo(FlRenderer* self) {
  // There is only one frame buffer object - always return that.
  return 0;
}

gboolean fl_renderer_present(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (!eglSwapBuffers(priv->egl_display, priv->egl_surface)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to swap EGL buffers: %s",
                egl_error_to_string(eglGetError()));
    return FALSE;
  }

  return TRUE;
}
