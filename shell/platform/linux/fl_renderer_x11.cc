// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "fl_renderer_x11.h"
#ifdef GDK_WINDOWING_X11

#include <X11/X.h>

#include "flutter/shell/platform/linux/egl_utils.h"

struct _FlRendererX11 {
  FlRenderer parent_instance;

  // Connection to the X server.
  Display* display;
};

G_DEFINE_TYPE(FlRendererX11, fl_renderer_x11, fl_renderer_get_type())

static void fl_renderer_x11_dispose(GObject* object) {
  FlRendererX11* self = FL_RENDERER_X11(object);

  if (self->display != nullptr) {
    XCloseDisplay(self->display);
    self->display = nullptr;
  }

  G_OBJECT_CLASS(fl_renderer_x11_parent_class)->dispose(object);
}

// Implements FlRenderer::setup_window_attr.
static gboolean fl_renderer_x11_setup_window_attr(
    FlRenderer* renderer,
    GtkWidget* widget,
    EGLDisplay display,
    EGLConfig config,
    GdkWindowAttr* window_attributes,
    gint* mask,
    GError** error) {
  EGLint visual_id;
  if (!eglGetConfigAttrib(display, config, EGL_NATIVE_VISUAL_ID, &visual_id)) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to determine EGL configuration visual");
    return FALSE;
  }

  GdkX11Screen* screen = GDK_X11_SCREEN(gtk_widget_get_screen(widget));
  if (!screen) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "View widget is not on an X11 screen");
    return FALSE;
  }

  window_attributes->visual = gdk_x11_screen_lookup_visual(screen, visual_id);
  if (window_attributes->visual == nullptr) {
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to find visual 0x%x", visual_id);
    return FALSE;
  }

  *mask |= GDK_WA_VISUAL;

  return TRUE;
}

// Implements FlRenderer::create_display.
static EGLDisplay fl_renderer_x11_create_display(FlRenderer* renderer) {
  FlRendererX11* self = FL_RENDERER_X11(renderer);

  // Create a dedicated connection to the X server because the EGL calls are
  // made from Flutter on a different thread to GTK. Re-using the existing
  // GTK X11 connection would crash as Xlib is not thread safe.
  if (self->display == nullptr) {
    Display* display = gdk_x11_get_default_xdisplay();
    self->display = XOpenDisplay(DisplayString(display));
  }

  return eglGetDisplay(self->display);
}

// Implements FlRenderer::create_surfaces.
static gboolean fl_renderer_x11_create_surfaces(FlRenderer* renderer,
                                                GtkWidget* widget,
                                                EGLDisplay display,
                                                EGLConfig config,
                                                EGLSurface* visible,
                                                EGLSurface* resource,
                                                GError** error) {
  GdkWindow* window = gtk_widget_get_window(widget);
  if (!GDK_IS_X11_WINDOW(window)) {
    g_set_error(
        error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
        "Can not create EGL surface: view doesn't have an X11 GDK window");
    return FALSE;
  }

  *visible = eglCreateWindowSurface(display, config,
                                    gdk_x11_window_get_xid(window), nullptr);
  if (*visible == EGL_NO_SURFACE) {
    EGLint egl_error = eglGetError();  // Must be before egl_config_to_string().
    g_autofree gchar* config_string = egl_config_to_string(display, config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL surface using configuration (%s): %s",
                config_string, egl_error_to_string(egl_error));
    return FALSE;
  }

  const EGLint attribs[] = {EGL_WIDTH, 1, EGL_HEIGHT, 1, EGL_NONE};
  *resource = eglCreatePbufferSurface(display, config, attribs);
  if (*resource == EGL_NO_SURFACE) {
    EGLint egl_error = eglGetError();  // Must be before egl_config_to_string().
    g_autofree gchar* config_string = egl_config_to_string(display, config);
    g_set_error(error, fl_renderer_error_quark(), FL_RENDERER_ERROR_FAILED,
                "Failed to create EGL resource using configuration (%s): %s",
                config_string, egl_error_to_string(egl_error));
    return FALSE;
  }

  return TRUE;
}

static void fl_renderer_x11_class_init(FlRendererX11Class* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_renderer_x11_dispose;
  FL_RENDERER_CLASS(klass)->setup_window_attr =
      fl_renderer_x11_setup_window_attr;
  FL_RENDERER_CLASS(klass)->create_display = fl_renderer_x11_create_display;
  FL_RENDERER_CLASS(klass)->create_surfaces = fl_renderer_x11_create_surfaces;
}

static void fl_renderer_x11_init(FlRendererX11* self) {}

FlRendererX11* fl_renderer_x11_new() {
  return FL_RENDERER_X11(g_object_new(fl_renderer_x11_get_type(), nullptr));
}

#endif  // GDK_WINDOWING_X11
