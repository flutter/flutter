// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_software.h"

#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"

// Maximum time to wait for a frame to be ready before giving up and rendering.
static constexpr gint64 kRenderTimeoutMicroseconds = 100000;  // 100ms

struct _FlViewRendererSoftware {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // Combines and stores frames.
  FlCompositorSoftware* compositor;

  // Surface the current frame is composited into.
  cairo_surface_t* surface;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // Ensure Flutter and GTK can access the frame stored in the compositor.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlViewRendererSoftware,
              fl_view_renderer_software,
              fl_view_renderer_get_type())

// Get the size of the current frame in pixels. The size is zero if there is no
// frame yet. Must be called with the frame mutex held.
static void get_frame_size(FlViewRendererSoftware* self,
                           size_t* width,
                           size_t* height) {
  if (self->surface != nullptr) {
    *width = cairo_image_surface_get_width(self->surface);
    *height = cairo_image_surface_get_height(self->surface);
  } else {
    *width = 0;
    *height = 0;
  }
}

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlViewRendererSoftware) self = FL_VIEW_RENDERER_SOFTWARE(user_data);

  if (self->compositor == nullptr) {
    return G_SOURCE_REMOVE;
  }

  fl_view_renderer_notify_frame(FL_VIEW_RENDERER(self));

  // If Flutter is controlling the window size, then resize the view if
  // necessary. The redraw happens once the resized frame arrives.
  if (self->sized_to_content) {
    size_t frame_width, frame_height;
    g_mutex_lock(&self->frame_mutex);
    get_frame_size(self, &frame_width, &frame_height);
    g_mutex_unlock(&self->frame_mutex);
    if (fl_view_renderer_resize_to_frame(FL_VIEW_RENDERER(self), frame_width,
                                         frame_height)) {
      return G_SOURCE_REMOVE;
    }
  }

  gtk_widget_queue_draw(GTK_WIDGET(self));

  return G_SOURCE_REMOVE;
}

// Wait for a frame matching the window size to be ready, or until the timeout
// expires. Must be called with the frame mutex held; the mutex is still held
// when this function returns.
static void wait_for_frame(FlViewRendererSoftware* self,
                           GdkWindow* window,
                           gint scale_factor) {
  gint64 expiry_time = g_get_monotonic_time() + kRenderTimeoutMicroseconds;
  while (true) {
    size_t width = gdk_window_get_width(window) * scale_factor;
    size_t height = gdk_window_get_height(window) * scale_factor;
    size_t frame_width, frame_height;
    get_frame_size(self, &frame_width, &frame_height);
    if (frame_width == width && frame_height == height) {
      break;
    }

    if (g_get_monotonic_time() > expiry_time) {
      g_warning(
          "Timed out waiting for software frame of size %zdx%zd (have "
          "%zdx%zd)",
          width, height, frame_width, frame_height);
      break;
    }

    g_mutex_unlock(&self->frame_mutex);
    fl_task_runner_wait(self->task_runner, expiry_time);
    g_mutex_lock(&self->frame_mutex);
  }
}

// Implements GtkWidget::realize.
static void fl_view_renderer_software_realize(GtkWidget* widget) {
  FlViewRendererSoftware* self = FL_VIEW_RENDERER_SOFTWARE(widget);

  GTK_WIDGET_CLASS(fl_view_renderer_software_parent_class)->realize(widget);

  self->task_runner =
      FL_TASK_RUNNER(g_object_ref(fl_engine_get_task_runner(self->engine)));
  self->compositor = fl_compositor_software_new();
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_software_draw(GtkWidget* widget, cairo_t* cr) {
  FlViewRendererSoftware* self = FL_VIEW_RENDERER_SOFTWARE(widget);

  fl_view_renderer_paint_background(FL_VIEW_RENDERER(self), cr);

  // The compositor is created when the widget is realized; if it is not yet
  // available there is nothing to render beyond the background.
  if (self->compositor == nullptr) {
    return TRUE;
  }

  GdkWindow* window = gtk_widget_get_window(widget);
  gint scale_factor = gdk_window_get_scale_factor(window);

  g_mutex_lock(&self->frame_mutex);

  // If frame not ready, then wait for it.
  if (!self->sized_to_content) {
    wait_for_frame(self, window, scale_factor);
  }

  gboolean result = FALSE;
  if (self->surface != nullptr) {
    cairo_save(cr);
    cairo_scale(cr, 1.0 / scale_factor, 1.0 / scale_factor);
    cairo_set_source_surface(cr, self->surface, 0.0, 0.0);
    cairo_paint(cr);
    cairo_restore(cr);
    result = TRUE;
  }

  g_mutex_unlock(&self->frame_mutex);

  return result;
}

// Implements FlViewRenderer::present_layers.
static void fl_view_renderer_software_present_layers(
    FlViewRenderer* renderer,
    const FlutterLayer** layers,
    size_t layers_count) {
  FlViewRendererSoftware* self = FL_VIEW_RENDERER_SOFTWARE(renderer);

  // Frames may be presented before the widget is realized and the compositor
  // is set up; ignore them.
  if (self->compositor == nullptr) {
    return;
  }

  g_mutex_lock(&self->frame_mutex);
  if (layers_count > 0) {
    size_t width = layers[0]->size.width;
    size_t height = layers[0]->size.height;

    // Recreate the surface if the frame size has changed.
    if (self->surface == nullptr ||
        static_cast<size_t>(cairo_image_surface_get_width(self->surface)) !=
            width ||
        static_cast<size_t>(cairo_image_surface_get_height(self->surface)) !=
            height) {
      g_clear_pointer(&self->surface, cairo_surface_destroy);
      self->surface =
          cairo_image_surface_create(CAIRO_FORMAT_ARGB32, width, height);
    }

    cairo_t* cr = cairo_create(self->surface);
    fl_compositor_software_composite_layers(self->compositor, cr, layers,
                                            layers_count);
    cairo_destroy(cr);
    cairo_surface_flush(self->surface);
  }
  g_mutex_unlock(&self->frame_mutex);

  // Wake up the GTK thread if it is waiting for this frame.
  fl_task_runner_stop_wait(self->task_runner);

  // Perform the redraw in the GTK thread.
  g_idle_add(redraw_cb, g_object_ref(self));
}

static void fl_view_renderer_software_dispose(GObject* object) {
  FlViewRendererSoftware* self = FL_VIEW_RENDERER_SOFTWARE(object);

  g_clear_object(&self->engine);
  g_clear_object(&self->task_runner);
  g_mutex_clear(&self->frame_mutex);

  G_OBJECT_CLASS(fl_view_renderer_software_parent_class)->dispose(object);
}

static void fl_view_renderer_software_finalize(GObject* object) {
  FlViewRendererSoftware* self = FL_VIEW_RENDERER_SOFTWARE(object);

  // The compositor is released here rather than in dispose() so it outlives a
  // forced dispose (e.g. gtk_widget_destroy()) and is only freed once the last
  // reference is dropped. This keeps it alive for the raster thread, which
  // holds a strong reference on the view (and thus this renderer) while
  // presenting.
  g_clear_object(&self->compositor);
  g_clear_pointer(&self->surface, cairo_surface_destroy);

  G_OBJECT_CLASS(fl_view_renderer_software_parent_class)->finalize(object);
}

static void fl_view_renderer_software_class_init(
    FlViewRendererSoftwareClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_view_renderer_software_dispose;
  object_class->finalize = fl_view_renderer_software_finalize;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_renderer_software_realize;
  widget_class->draw = fl_view_renderer_software_draw;

  FlViewRendererClass* renderer_class = FL_VIEW_RENDERER_CLASS(klass);
  renderer_class->present_layers = fl_view_renderer_software_present_layers;
}

static void fl_view_renderer_software_init(FlViewRendererSoftware* self) {
  g_mutex_init(&self->frame_mutex);
}

FlViewRendererSoftware* fl_view_renderer_software_new(
    FlEngine* engine,
    gboolean sized_to_content) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlViewRendererSoftware* self = FL_VIEW_RENDERER_SOFTWARE(
      g_object_new(fl_view_renderer_software_get_type(), nullptr));
  self->engine = FL_ENGINE(g_object_ref(engine));
  self->sized_to_content = sized_to_content;
  return self;
}
