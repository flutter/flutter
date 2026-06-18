// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer.h"

#include <gdk/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"

struct _FlViewRenderer {
  GtkDrawingArea parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // Rendering context when using OpenGL.
  GdkGLContext* render_context;

  // Combines layers into frame.
  FlCompositor* compositor;

  // Background color.
  GdkRGBA* background_color;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // TRUE if have got the first frame to render.
  gboolean have_first_frame;
};

enum { SIGNAL_FIRST_FRAME, LAST_SIGNAL };

static guint fl_view_renderer_signals[LAST_SIGNAL];

G_DEFINE_TYPE(FlViewRenderer, fl_view_renderer, GTK_TYPE_DRAWING_AREA)

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlViewRenderer) self = FL_VIEW_RENDERER(user_data);

  if (self->compositor == nullptr) {
    return G_SOURCE_REMOVE;
  }

  if (!self->have_first_frame) {
    self->have_first_frame = TRUE;
    g_signal_emit(self, fl_view_renderer_signals[SIGNAL_FIRST_FRAME], 0);
  }

  // If Flutter is controlling the window size, then resize the view if
  // necessary.
  GtkWidget* render_widget = GTK_WIDGET(self);
  GtkAllocation allocation;
  gtk_widget_get_allocation(render_widget, &allocation);
  gint scale_factor = gtk_widget_get_scale_factor(render_widget);
  size_t width = allocation.width * scale_factor;
  size_t height = allocation.height * scale_factor;
  size_t frame_width, frame_height;
  fl_compositor_get_frame_size(self->compositor, &frame_width, &frame_height);
  gboolean frame_size_matches = width == frame_width && height == frame_height;
  if (self->sized_to_content && !frame_size_matches) {
    gtk_widget_set_size_request(render_widget, frame_width / scale_factor,
                                frame_height / scale_factor);
    GtkWidget* toplevel = gtk_widget_get_toplevel(render_widget);
    if (GTK_IS_WINDOW(toplevel)) {
      // Resize to smallest size, so that the window will shrink to fit the new
      // size of the render area.
      gtk_window_resize(GTK_WINDOW(toplevel), 1, 1);
    }
    return G_SOURCE_REMOVE;
  }

  gtk_widget_queue_draw(render_widget);

  return G_SOURCE_REMOVE;
}

static void setup_opengl(FlViewRenderer* self) {
  g_autoptr(GError) error = nullptr;

  self->render_context = gdk_window_create_gl_context(
      gtk_widget_get_window(GTK_WIDGET(self)), &error);
  if (self->render_context == nullptr) {
    g_warning("Failed to create OpenGL context: %s", error->message);
    return;
  }

  if (!gdk_gl_context_realize(self->render_context, &error)) {
    g_warning("Failed to realize OpenGL context: %s", error->message);
    return;
  }

  // If using Wayland, then EGL is in use and we can access the frame
  // from the Flutter context using EGLImage. If not (i.e. X11 using GLX)
  // then we have to copy the texture via the CPU.
  gboolean shareable =
      GDK_IS_WAYLAND_DISPLAY(gtk_widget_get_display(GTK_WIDGET(self)));
  self->compositor = FL_COMPOSITOR(fl_compositor_opengl_new(
      fl_engine_get_task_runner(self->engine),
      fl_engine_get_opengl_manager(self->engine), shareable));
}

static void setup_software(FlViewRenderer* self) {
  self->compositor = FL_COMPOSITOR(
      fl_compositor_software_new(fl_engine_get_task_runner(self->engine)));
}

static void paint_background(FlViewRenderer* self, cairo_t* cr) {
  // Don't bother drawing if fully transparent - the widget above this will
  // already be drawn by GTK.
  if (self->background_color->red == 0 && self->background_color->green == 0 &&
      self->background_color->blue == 0 && self->background_color->alpha == 0) {
    return;
  }

  gdk_cairo_set_source_rgba(cr, self->background_color);
  cairo_paint(cr);
}

// Implements GtkWidget::realize.
static void fl_view_renderer_realize(GtkWidget* widget) {
  FlViewRenderer* self = FL_VIEW_RENDERER(widget);

  GTK_WIDGET_CLASS(fl_view_renderer_parent_class)->realize(widget);

  switch (fl_engine_get_renderer_type(self->engine)) {
    case kOpenGL:
      setup_opengl(self);
      break;
    case kSoftware:
      setup_software(self);
      break;
    default:
      break;
  }
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_draw(GtkWidget* widget, cairo_t* cr) {
  FlViewRenderer* self = FL_VIEW_RENDERER(widget);

  paint_background(self, cr);

  // The compositor is created when the widget is realized; if it is not yet
  // available there is nothing to render beyond the background.
  if (self->compositor == nullptr) {
    return TRUE;
  }

  if (self->render_context) {
    gdk_gl_context_make_current(self->render_context);
  }

  gboolean wait_for_frame = !self->sized_to_content;
  gboolean result = fl_compositor_render(
      self->compositor, cr, gtk_widget_get_window(widget), wait_for_frame);

  if (self->render_context) {
    gdk_gl_context_clear_current();
  }

  return result;
}

static void fl_view_renderer_dispose(GObject* object) {
  FlViewRenderer* self = FL_VIEW_RENDERER(object);

  g_clear_object(&self->render_context);
  g_clear_object(&self->compositor);
  g_clear_object(&self->engine);
  g_clear_pointer(&self->background_color, gdk_rgba_free);

  G_OBJECT_CLASS(fl_view_renderer_parent_class)->dispose(object);
}

static void fl_view_renderer_class_init(FlViewRendererClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_view_renderer_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_renderer_realize;
  widget_class->draw = fl_view_renderer_draw;

  fl_view_renderer_signals[SIGNAL_FIRST_FRAME] =
      g_signal_new("first-frame", fl_view_renderer_get_type(),
                   G_SIGNAL_RUN_LAST, 0, NULL, NULL, NULL, G_TYPE_NONE, 0);
}

static void fl_view_renderer_init(FlViewRenderer* self) {
  GdkRGBA default_background = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  self->background_color = gdk_rgba_copy(&default_background);
}

FlViewRenderer* fl_view_renderer_new(FlEngine* engine,
                                     gboolean sized_to_content) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlViewRenderer* self =
      FL_VIEW_RENDERER(g_object_new(fl_view_renderer_get_type(), nullptr));

  self->engine = FL_ENGINE(g_object_ref(engine));
  self->sized_to_content = sized_to_content;

  return self;
}

void fl_view_renderer_set_background_color(FlViewRenderer* self,
                                           const GdkRGBA* color) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));
  gdk_rgba_free(self->background_color);
  self->background_color = gdk_rgba_copy(color);
}

void fl_view_renderer_present_layers(FlViewRenderer* self,
                                     const FlutterLayer** layers,
                                     size_t layers_count) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  // Frames may be presented before the widget is realized and the compositor
  // is set up; ignore them.
  if (self->compositor == nullptr) {
    return;
  }

  fl_compositor_present_layers(self->compositor, layers, layers_count);

  // Perform the redraw in the GTK thread.
  g_idle_add(redraw_cb, g_object_ref(self));
}
