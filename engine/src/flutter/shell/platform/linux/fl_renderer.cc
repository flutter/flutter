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

static void fl_renderer_class_init(FlRendererClass* klass) {}

static void fl_renderer_init(FlRenderer* self) {}

// Initializes EGL and gets a valid EGL OpenGL ES configuration.
static gboolean setup_egl_display(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (priv->egl_display != EGL_NO_DISPLAY) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "EGL display already set up");
    return FALSE;
  }

  priv->egl_display = FL_RENDERER_GET_CLASS(self)->create_display(self);

  if (priv->egl_display == EGL_NO_DISPLAY) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL display");
    return FALSE;
  }

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
    EGLint egl_error = eglGetError();  // Must be before egl_config_to_string().
    g_autofree gchar* config_string =
        egl_config_to_string(priv->egl_display, priv->egl_config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to bind EGL OpenGL ES API using configuration (%s): %s",
                config_string, egl_error_to_string(egl_error));
    return FALSE;
  }

  return TRUE;
}

// Creates a GDK window that can be rendered to using EGL.
static gboolean setup_gdk_window(FlRenderer* self,
                                 GtkWidget* widget,
                                 GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (priv->egl_display == EGL_NO_DISPLAY) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Can not set up GDK window: EGL display not created");
    return FALSE;
  }

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);

  GdkWindowAttr window_attributes;
  window_attributes.window_type = GDK_WINDOW_CHILD;
  window_attributes.x = allocation.x;
  window_attributes.y = allocation.y;
  window_attributes.width = allocation.width;
  window_attributes.height = allocation.height;
  window_attributes.wclass = GDK_INPUT_OUTPUT;
  window_attributes.event_mask =
      gtk_widget_get_events(widget) | GDK_EXPOSURE_MASK |
      GDK_POINTER_MOTION_MASK | GDK_BUTTON_PRESS_MASK |
      GDK_BUTTON_RELEASE_MASK | GDK_SCROLL_MASK | GDK_SMOOTH_SCROLL_MASK |
      GDK_KEY_PRESS_MASK | GDK_KEY_RELEASE_MASK;

  gint window_attributes_mask = GDK_WA_X | GDK_WA_Y;

  if (FL_RENDERER_GET_CLASS(self)->setup_window_attr) {
    if (!FL_RENDERER_GET_CLASS(self)->setup_window_attr(
            self, widget, priv->egl_display, priv->egl_config,
            &window_attributes, &window_attributes_mask, error)) {
      return FALSE;
    }
  }

  GdkWindow* window =
      gdk_window_new(gtk_widget_get_parent_window(widget), &window_attributes,
                     window_attributes_mask);
  gtk_widget_register_window(widget, window);
  gtk_widget_set_window(widget, window);

  return TRUE;
}

// Creates the EGL surfaces that Flutter will render to.
static gboolean setup_egl_surfaces(FlRenderer* self,
                                   GtkWidget* widget,
                                   GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (priv->egl_surface != EGL_NO_SURFACE ||
      priv->resource_surface != EGL_NO_SURFACE) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "setup_egl_surfaces() called after surfaces already created");
    return FALSE;
  }

  if (!FL_RENDERER_GET_CLASS(self)->create_surfaces(
          self, widget, priv->egl_display, priv->egl_config, &priv->egl_surface,
          &priv->resource_surface, error)) {
    return FALSE;
  }

  EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE};

  priv->egl_context = eglCreateContext(priv->egl_display, priv->egl_config,
                                       EGL_NO_CONTEXT, context_attributes);
  priv->resource_context =
      eglCreateContext(priv->egl_display, priv->egl_config, priv->egl_context,
                       context_attributes);
  if (priv->egl_context == EGL_NO_CONTEXT ||
      priv->resource_context == EGL_NO_CONTEXT) {
    EGLint egl_error = eglGetError();  // Must be before egl_config_to_string().
    g_autofree gchar* config_string =
        egl_config_to_string(priv->egl_display, priv->egl_config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL contexts using configuration (%s): %s",
                config_string, egl_error_to_string(egl_error));
    return FALSE;
  }

  return TRUE;
}

gboolean fl_renderer_start(FlRenderer* self,
                           GtkWidget* widget,
                           GError** error) {
  g_return_val_if_fail(FL_IS_RENDERER(self), FALSE);

  if (!setup_egl_display(self, error)) {
    return FALSE;
  }

  if (!setup_gdk_window(self, widget, error)) {
    return FALSE;
  }

  if (!setup_egl_surfaces(self, widget, error)) {
    return FALSE;
  }

  return TRUE;
}

void fl_renderer_set_geometry(FlRenderer* self,
                              GdkRectangle* geometry,
                              gint scale) {
  g_return_if_fail(FL_IS_RENDERER(self));

  if (FL_RENDERER_GET_CLASS(self)->set_geometry) {
    FL_RENDERER_GET_CLASS(self)->set_geometry(self, geometry, scale);
  }
}

void* fl_renderer_get_proc_address(FlRenderer* self, const char* name) {
  return reinterpret_cast<void*>(eglGetProcAddress(name));
}

gboolean fl_renderer_make_current(FlRenderer* self, GError** error) {
  FlRendererPrivate* priv =
      static_cast<FlRendererPrivate*>(fl_renderer_get_instance_private(self));

  if (priv->egl_surface == EGL_NO_SURFACE ||
      priv->egl_context == EGL_NO_CONTEXT) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to make EGL context current: No surface created");
    return FALSE;
  }

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
      priv->resource_context == EGL_NO_CONTEXT) {
    g_set_error(
        error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
        "Failed to make EGL resource context current: No surface created");
    return FALSE;
  }

  if (!eglMakeCurrent(priv->egl_display, priv->resource_surface,
                      priv->resource_surface, priv->resource_context)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to make EGL resource context current: %s",
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
