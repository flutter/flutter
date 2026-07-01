// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_opengl.h"

#include <gdk/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"

// Maximum time to wait for a frame to be ready before giving up and rendering.
static constexpr gint64 kRenderTimeoutMicroseconds = 100000;  // 100ms

struct _FlViewRendererOpenGL {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // TRUE if have got the first frame to render.
  gboolean have_first_frame;

  // Rendering context for OpenGL.
  GdkGLContext* render_context;

  // Combines layers into frame.
  FlCompositorOpenGL* compositor;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // Ensure Flutter and GTK can access the frame stored in the compositor.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlViewRendererOpenGL,
              fl_view_renderer_opengl,
              fl_view_renderer_get_type())

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlViewRendererOpenGL) self = FL_VIEW_RENDERER_OPENGL(user_data);

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
    fl_compositor_opengl_get_frame_size(self->compositor, &frame_width,
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
static void wait_for_frame(FlViewRendererOpenGL* self,
                           GdkWindow* window,
                           gint scale_factor) {
  gint64 expiry_time = g_get_monotonic_time() + kRenderTimeoutMicroseconds;
  while (true) {
    size_t width = gdk_window_get_width(window) * scale_factor;
    size_t height = gdk_window_get_height(window) * scale_factor;
    size_t frame_width, frame_height;
    fl_compositor_opengl_get_frame_size(self->compositor, &frame_width,
                                        &frame_height);
    if (frame_width == width && frame_height == height) {
      break;
    }

    if (g_get_monotonic_time() > expiry_time) {
      g_warning(
          "Timed out waiting for OpenGL frame of size %zdx%zd (have "
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
static void fl_view_renderer_opengl_realize(GtkWidget* widget) {
  FlViewRendererOpenGL* self = FL_VIEW_RENDERER_OPENGL(widget);

  GTK_WIDGET_CLASS(fl_view_renderer_opengl_parent_class)->realize(widget);

  g_autoptr(GError) error = nullptr;
  self->render_context = gdk_window_create_gl_context(
      gtk_widget_get_window(GTK_WIDGET(self)), &error);
  if (self->render_context == nullptr) {
    g_warning("Failed to create OpenGL context: %s", error->message);
    return;
  }

  if (!gdk_gl_context_realize(self->render_context, &error)) {
    g_warning("Failed to realize OpenGL context: %s", error->message);
    g_clear_object(&self->render_context);
    return;
  }

  // If using Wayland, then EGL is in use and we can access the frame
  // from the Flutter context using EGLImage. If not (i.e. X11 using GLX)
  // then we have to copy the texture via the CPU.
  gboolean shareable =
      GDK_IS_WAYLAND_DISPLAY(gtk_widget_get_display(GTK_WIDGET(self)));
  self->task_runner =
      FL_TASK_RUNNER(g_object_ref(fl_engine_get_task_runner(self->engine)));
  self->compositor = fl_compositor_opengl_new(
      fl_engine_get_opengl_manager(self->engine), shareable);
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_opengl_draw(GtkWidget* widget, cairo_t* cr) {
  FlViewRendererOpenGL* self = FL_VIEW_RENDERER_OPENGL(widget);

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

  if (self->render_context != nullptr) {
    gdk_gl_context_make_current(self->render_context);
  }

  gboolean result = fl_compositor_opengl_render(self->compositor, cr, window);

  if (self->render_context != nullptr) {
    gdk_gl_context_clear_current();
  }

  g_mutex_unlock(&self->frame_mutex);

  return result;
}

// Implements FlViewRenderer::present_layers.
static void fl_view_renderer_opengl_present_layers(FlViewRenderer* renderer,
                                                   const FlutterLayer** layers,
                                                   size_t layers_count) {
  FlViewRendererOpenGL* self = FL_VIEW_RENDERER_OPENGL(renderer);

  // Frames may be presented before the widget is realized and the compositor
  // is set up; ignore them.
  if (self->compositor == nullptr) {
    return;
  }

  g_mutex_lock(&self->frame_mutex);
  fl_compositor_opengl_composite_layers(self->compositor, layers, layers_count);
  g_mutex_unlock(&self->frame_mutex);

  // Wake up the GTK thread if it is waiting for this frame.
  fl_task_runner_stop_wait(self->task_runner);

  // Perform the redraw in the GTK thread.
  g_idle_add(redraw_cb, g_object_ref(self));
}

static void fl_view_renderer_opengl_dispose(GObject* object) {
  FlViewRendererOpenGL* self = FL_VIEW_RENDERER_OPENGL(object);

  g_clear_object(&self->engine);
  g_clear_object(&self->render_context);
  g_clear_object(&self->task_runner);
  g_mutex_clear(&self->frame_mutex);

  G_OBJECT_CLASS(fl_view_renderer_opengl_parent_class)->dispose(object);
}

static void fl_view_renderer_opengl_finalize(GObject* object) {
  FlViewRendererOpenGL* self = FL_VIEW_RENDERER_OPENGL(object);

  // The compositor is released here rather than in dispose() so it outlives a
  // forced dispose (e.g. gtk_widget_destroy()) and is only freed once the last
  // reference is dropped. This keeps it alive for the raster thread, which
  // holds a strong reference on the view (and thus this renderer) while
  // presenting.
  g_clear_object(&self->compositor);

  G_OBJECT_CLASS(fl_view_renderer_opengl_parent_class)->finalize(object);
}

static void fl_view_renderer_opengl_class_init(
    FlViewRendererOpenGLClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_view_renderer_opengl_dispose;
  object_class->finalize = fl_view_renderer_opengl_finalize;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_renderer_opengl_realize;
  widget_class->draw = fl_view_renderer_opengl_draw;

  FlViewRendererClass* renderer_class = FL_VIEW_RENDERER_CLASS(klass);
  renderer_class->present_layers = fl_view_renderer_opengl_present_layers;
}

static void fl_view_renderer_opengl_init(FlViewRendererOpenGL* self) {
  g_mutex_init(&self->frame_mutex);
}

FlViewRendererOpenGL* fl_view_renderer_opengl_new(FlEngine* engine,
                                                  gboolean sized_to_content) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlViewRendererOpenGL* self = FL_VIEW_RENDERER_OPENGL(
      g_object_new(fl_view_renderer_opengl_get_type(), nullptr));
  self->engine = FL_ENGINE(g_object_ref(engine));
  self->sized_to_content = sized_to_content;
  return self;
}
