// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer.h"

#include "flutter/shell/platform/embedder/embedder.h"

G_DEFINE_QUARK(fl_renderer_error_quark, fl_renderer_error)

typedef struct {
  EGLDisplay egl_display;
  EGLSurface egl_surface;
  EGLContext egl_context;

  EGLSurface resource_surface;
  EGLContext resource_context;
} FlRendererPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FlRenderer, fl_renderer, G_TYPE_OBJECT)

// Gets a string representation of the last EGL error.
static const gchar* get_egl_error() {
  EGLint error = eglGetError();
  switch (error) {
    case EGL_SUCCESS:
      return "Success";
    case EGL_NOT_INITIALIZED:
      return "Not Initialized";
    case EGL_BAD_ACCESS:
      return "Bad Access";
    case EGL_BAD_ALLOC:
      return "Bad Allocation";
    case EGL_BAD_ATTRIBUTE:
      return "Bad Attribute";
    case EGL_BAD_CONTEXT:
      return "Bad Context";
    case EGL_BAD_CONFIG:
      return "Bad Configuration";
    case EGL_BAD_CURRENT_SURFACE:
      return "Bad Current Surface";
    case EGL_BAD_DISPLAY:
      return "Bad Display";
    case EGL_BAD_SURFACE:
      return "Bad Surface";
    case EGL_BAD_MATCH:
      return "Bad Match";
    case EGL_BAD_PARAMETER:
      return "Bad Parameter";
    case EGL_BAD_NATIVE_PIXMAP:
      return "Bad Native Pixmap";
    case EGL_BAD_NATIVE_WINDOW:
      return "Bad Native Window";
    case EGL_CONTEXT_LOST:
      return "Context Lost";
    default:
      return "Unknown Error";
  }
}

// Creates a resource surface.
static void create_resource_surface(FlRenderer* self, EGLConfig config) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  const EGLint resource_context_attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1,
                                             EGL_NONE};
  priv->resource_surface = eglCreatePbufferSurface(priv->egl_display, config,
                                                   resource_context_attribs);
  if (priv->resource_surface == nullptr) {
    g_warning("Failed to create EGL resource surface: %s", get_egl_error());
    return;
  }

  priv->resource_context = eglCreateContext(
      priv->egl_display, config, priv->egl_context, context_attributes);
  if (priv->resource_context == nullptr)
    g_warning("Failed to create EGL resource context: %s", get_egl_error());
}

// Default implementation for the start virtual method.
// Provided so subclasses can chain up to here.
static gboolean fl_renderer_real_start(FlRenderer* self, GError** error) {
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
  EGLConfig egl_config;
  EGLint n_config;
  if (!eglChooseConfig(priv->egl_display, attributes, &egl_config, 1,
                       &n_config)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to choose EGL config: %s", get_egl_error());
    return FALSE;
  }
  if (n_config == 0) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to find appropriate EGL config: %s", get_egl_error());
    return FALSE;
  }
  if (!eglBindAPI(EGL_OPENGL_ES_API)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to bind EGL OpenGL ES API: %s", get_egl_error());
    return FALSE;
  }

  priv->egl_surface = FL_RENDERER_GET_CLASS(self)->create_surface(
      self, priv->egl_display, egl_config);
  if (priv->egl_surface == nullptr) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL surface: %s", get_egl_error());
    return FALSE;
  }
  EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};
  priv->egl_context = eglCreateContext(priv->egl_display, egl_config,
                                       EGL_NO_CONTEXT, context_attributes);
  if (priv->egl_context == nullptr) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL context: %s", get_egl_error());
    return FALSE;
  }

  create_resource_surface(self, egl_config);

  EGLint value;
  eglQueryContext(priv->egl_display, priv->egl_context,
                  EGL_CONTEXT_CLIENT_VERSION, &value);

  return TRUE;
}

static void fl_renderer_class_init(FlRendererClass* klass) {
  klass->start = fl_renderer_real_start;
}

static void fl_renderer_init(FlRenderer* self) {}

gboolean fl_renderer_start(FlRenderer* self, GError** error) {
  return FL_RENDERER_GET_CLASS(self)->start(self, error);
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
                "Failed to make EGL context current: %s", get_egl_error());
    return FALSE;
  }

  return TRUE;
}

gboolean fl_renderer_make_resource_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (priv->resource_surface == nullptr || priv->resource_context == nullptr)
    return FALSE;

  if (!eglMakeCurrent(priv->egl_display, priv->resource_surface,
                      priv->resource_surface, priv->resource_context)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to make EGL context current: %s", get_egl_error());
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
                "Failed to clear EGL context: %s", get_egl_error());
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
                "Failed to swap EGL buffers: %s", get_egl_error());
    return FALSE;
  }

  return TRUE;
}
