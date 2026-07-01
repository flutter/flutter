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

  // TRUE if have got the first frame to render.
  gboolean have_first_frame;

  // Combines and stores frames.
  FlCompositorSoftware* compositor;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // Ensure Flutter and GTK can access the frame stored in the compositor.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlViewRendererSoftware,
              fl_view_renderer_software,
              fl_view_renderer_get_type())

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlViewRendererSoftware) self = FL_VIEW_RENDERER_SOFTWARE(user_data);

  if (self->compositor == nullptr) {
    return G_SOURCE_REMOVE;
  }

  if (!self->have_first_frame) {
    self->have_first_frame = TRUE;
    fl_view_renderer_emit_first_frame(FL_VIEW_RENDERER(self));
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
  {
    g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);
    fl_compositor_software_get_frame_size(self->compositor, &frame_width,
                                          &frame_height);
  }
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
    fl_compositor_software_get_frame_size(self->compositor, &frame_width,
                                          &frame_height);
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

  gboolean result =
      fl_compositor_software_render(self->compositor, cr, scale_factor);

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
  fl_compositor_software_composite_layers(self->compositor, layers,
                                          layers_count);
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
