// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include <epoxy/gl.h>
#include <gdk/gdkwayland.h>

#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_subsurface.h"
#include "flutter/shell/platform/linux/fl_subsurface_egl.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"
#include "flutter/shell/platform/linux/fl_wayland_display.h"

// Maximum time to wait for a frame to be ready before giving up and rendering.
static constexpr gint64 kRenderTimeoutMicroseconds = 100000;  // 100ms

struct _FlViewRendererSubsurface {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // Wayland subsurface the frame is rendered into.
  FlSubsurface* subsurface;

  // Manages the EGL context and surface used to present frames to the
  // subsurface.
  FlSubsurfaceEGL* egl;

  // Combines layers into a frame.
  FlCompositorOpenGL* compositor;

  // Framebuffer the current frame is composited into.
  FlFramebuffer* framebuffer;

  // Task runner used to wait for frames while resizing.
  FlTaskRunner* task_runner;

  // Ensure Flutter and GTK can access the frame stored in the compositor.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlViewRendererSubsurface,
              fl_view_renderer_subsurface,
              fl_view_renderer_get_type())

// Get the size of the current frame in pixels. The size is zero if there is no
// frame yet. Must be called with the frame mutex held.
static void get_frame_size(FlViewRendererSubsurface* self,
                           size_t* width,
                           size_t* height) {
  if (self->framebuffer != nullptr) {
    *width = fl_framebuffer_get_width(self->framebuffer);
    *height = fl_framebuffer_get_height(self->framebuffer);
  } else {
    *width = 0;
    *height = 0;
  }
}

// Wait for a frame matching the given size to be presented, or until the
// timeout expires. This blocks the GTK thread so a window resize stays in step
// with the subsurface content. Must be called with the frame mutex held; the
// mutex is still held when this function returns.
static void wait_for_frame(FlViewRendererSubsurface* self,
                           size_t width,
                           size_t height) {
  gint64 expiry_time = g_get_monotonic_time() + kRenderTimeoutMicroseconds;
  while (true) {
    size_t frame_width, frame_height;
    get_frame_size(self, &frame_width, &frame_height);
    if (frame_width == width && frame_height == height) {
      break;
    }

    if (g_get_monotonic_time() > expiry_time) {
      g_warning(
          "Timed out waiting for subsurface frame of size %zdx%zd (have "
          "%zdx%zd)",
          width, height, frame_width, frame_height);
      break;
    }

    g_mutex_unlock(&self->frame_mutex);
    fl_task_runner_wait(self->task_runner, expiry_time);
    g_mutex_lock(&self->frame_mutex);
  }
}

// Gets the EGL display the engine renders to. The subsurface shares this
// Move the subsurface to match the position of the widget in the toplevel.
static void update_subsurface_position(FlViewRendererSubsurface* self) {
  if (self->subsurface == nullptr) {
    return;
  }
  GtkWidget* widget = GTK_WIDGET(self);
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  gint x, y;
  gtk_widget_translate_coordinates(widget, toplevel, 0, 0, &x, &y);
  fl_subsurface_set_position(self->subsurface, x, y);
}

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlViewRendererSubsurface) self =
      FL_VIEW_RENDERER_SUBSURFACE(user_data);

  if (self->compositor == nullptr) {
    return G_SOURCE_REMOVE;
  }

  fl_view_renderer_notify_frame(FL_VIEW_RENDERER(self));

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

// Implements GtkWidget::realize.
static void fl_view_renderer_subsurface_realize(GtkWidget* widget) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)->realize(widget);

  GdkDisplay* gdk_display = gtk_widget_get_display(widget);
  if (!GDK_IS_WAYLAND_DISPLAY(gdk_display)) {
    g_warning("FlViewRendererSubsurface requires a Wayland display");
    return;
  }

  FlWaylandDisplay* wayland_display =
      fl_wayland_display_get_for_display(gdk_display);
  if (wayland_display == nullptr) {
    return;
  }

  // Create a subsurface on the toplevel's surface.
  GdkWindow* toplevel_window =
      gtk_widget_get_window(gtk_widget_get_toplevel(widget));
  self->subsurface = fl_wayland_display_create_subsurface(
      wayland_display, gdk_wayland_window_get_wl_surface(toplevel_window));
  update_subsurface_position(self);

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);
  gint scale_factor = gtk_widget_get_scale_factor(widget);
  self->egl = fl_subsurface_egl_new(fl_engine_get_opengl_manager(self->engine),
                                    self->subsurface, allocation.width,
                                    allocation.height, scale_factor);

  // The subsurface's EGL context shares resources with the engine, so the
  // engine's frame texture is accessed directly without using EGLImage.
  self->task_runner =
      FL_TASK_RUNNER(g_object_ref(fl_engine_get_task_runner(self->engine)));
  self->compositor =
      fl_compositor_opengl_new(fl_engine_get_opengl_manager(self->engine));
}

// Implements GtkWidget::unrealize.
static void fl_view_renderer_subsurface_unrealize(GtkWidget* widget) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  // Hold frame_mutex while releasing these objects so the raster thread cannot
  // be using them in present_layers concurrently. The unref may run their
  // destructors, so the calling code (here) owns the locking rather than the
  // objects themselves.
  g_mutex_lock(&self->frame_mutex);
  g_clear_object(&self->compositor);

  // The EGL context and surface are released here; the EGL display is owned by
  // the engine and is left untouched by FlSubsurfaceEGL.
  g_clear_object(&self->egl);
  g_clear_object(&self->subsurface);
  g_mutex_unlock(&self->frame_mutex);

  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)->unrealize(widget);
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_subsurface_draw(GtkWidget* widget,
                                                 cairo_t* cr) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  // Flutter content is shown directly by the subsurface; only paint the
  // background behind it. The composited frame is blitted to the subsurface in
  // present_layers, not here.
  fl_view_renderer_paint_background(FL_VIEW_RENDERER(self), cr);

  return TRUE;
}

// Implements GtkWidget::size_allocate.
static void fl_view_renderer_subsurface_size_allocate(
    GtkWidget* widget,
    GtkAllocation* allocation) {
  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)
      ->size_allocate(widget, allocation);

  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  if (self->subsurface == nullptr) {
    return;
  }

  gint scale_factor = gtk_widget_get_scale_factor(widget);
  size_t width = allocation->width * scale_factor;
  size_t height = allocation->height * scale_factor;

  update_subsurface_position(self);
  if (self->egl != nullptr) {
    fl_subsurface_egl_resize(self->egl, width, height);
  }
}

// Runs after the size_allocate default handler and, crucially, after FlView has
// sent the new window metrics to the engine (connected with
// g_signal_connect_after). By this point the engine is already producing a
// frame of the new size, so block the GTK thread until that frame has been
// presented to the subsurface. This keeps the subsurface in step with the
// toplevel window while resizing.
static void fl_view_renderer_subsurface_size_allocate_after(
    GtkWidget* widget,
    GdkRectangle* allocation,
    gpointer user_data) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  // Nothing to synchronize against before the subsurface exists, or when
  // Flutter controls the size (the frame drives the window size in that case).
  if (self->egl == nullptr || self->sized_to_content) {
    return;
  }

  gint scale_factor = gtk_widget_get_scale_factor(widget);
  size_t width = allocation->width * scale_factor;
  size_t height = allocation->height * scale_factor;

  g_mutex_lock(&self->frame_mutex);
  wait_for_frame(self, width, height);
  g_mutex_unlock(&self->frame_mutex);
}

// Implements FlViewRenderer::present_layers.
static void fl_view_renderer_subsurface_present_layers(
    FlViewRenderer* renderer,
    const FlutterLayer** layers,
    size_t layers_count) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(renderer);

  g_mutex_lock(&self->frame_mutex);

  // Frames may be presented before the widget is realized, or after it has been
  // unrealized; ignore them. Checked under frame_mutex so unrealize cannot
  // release these objects while a frame is being presented.
  if (self->compositor == nullptr || self->egl == nullptr) {
    g_mutex_unlock(&self->frame_mutex);
    return;
  }

  if (layers_count == 0) {
    g_mutex_unlock(&self->frame_mutex);
    return;
  }

  size_t width = layers[0]->size.width;
  size_t height = layers[0]->size.height;

  // Recreate the framebuffer if the frame size has changed. The subsurface's
  // EGL context shares resources with the engine, so the frame texture is read
  // directly and doesn't need to be shareable or copied via CPU memory.
  if (self->framebuffer == nullptr ||
      fl_framebuffer_get_width(self->framebuffer) != width ||
      fl_framebuffer_get_height(self->framebuffer) != height) {
    GLint general_format = GL_RGBA;
    if (epoxy_has_gl_extension("GL_EXT_texture_format_BGRA8888")) {
      general_format = GL_BGRA_EXT;
    }
    g_clear_object(&self->framebuffer);
    self->framebuffer =
        fl_framebuffer_new(general_format, width, height, FALSE);
  }

  // Bind the target framebuffer so the compositor draws into it.
  GLint saved_draw_framebuffer_binding;
  glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &saved_draw_framebuffer_binding);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                    fl_framebuffer_get_id(self->framebuffer));

  fl_compositor_opengl_composite_layers(self->compositor, layers, layers_count);

  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, saved_draw_framebuffer_binding);

  // Present the composited frame directly to the subsurface using its own EGL
  // context. This reads the engine's frame texture directly, as the subsurface
  // context shares resources with the engine.
  fl_subsurface_egl_present(self->egl,
                            fl_framebuffer_get_texture_id(self->framebuffer),
                            width, height);

  g_mutex_unlock(&self->frame_mutex);

  // Wake up the GTK thread if it is blocked in size_allocate waiting for this
  // frame.
  fl_task_runner_stop_wait(self->task_runner);

  // Notify the GTK thread so it can emit the first frame and resize the view.
  g_idle_add(redraw_cb, g_object_ref(self));
}

static void fl_view_renderer_subsurface_dispose(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  g_clear_object(&self->engine);
  g_clear_object(&self->task_runner);
  g_mutex_clear(&self->frame_mutex);

  G_OBJECT_CLASS(fl_view_renderer_subsurface_parent_class)->dispose(object);
}

static void fl_view_renderer_subsurface_finalize(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  // The compositor is released here rather than in dispose() so it outlives a
  // forced dispose (e.g. gtk_widget_destroy()) and is only freed once the last
  // reference is dropped. This keeps it alive for the raster thread, which
  // holds a strong reference on the view (and thus this renderer) while
  // presenting.
  g_clear_object(&self->compositor);
  g_clear_object(&self->framebuffer);

  G_OBJECT_CLASS(fl_view_renderer_subsurface_parent_class)->finalize(object);
}

static void fl_view_renderer_subsurface_class_init(
    FlViewRendererSubsurfaceClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_view_renderer_subsurface_dispose;
  object_class->finalize = fl_view_renderer_subsurface_finalize;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_renderer_subsurface_realize;
  widget_class->unrealize = fl_view_renderer_subsurface_unrealize;
  widget_class->draw = fl_view_renderer_subsurface_draw;
  widget_class->size_allocate = fl_view_renderer_subsurface_size_allocate;

  FlViewRendererClass* renderer_class = FL_VIEW_RENDERER_CLASS(klass);
  renderer_class->present_layers = fl_view_renderer_subsurface_present_layers;
}

static void fl_view_renderer_subsurface_init(FlViewRendererSubsurface* self) {
  g_mutex_init(&self->frame_mutex);

  // Connected after the default handler so this runs once FlView has sent the
  // new window metrics to the engine, allowing the frame of the new size to be
  // waited for.
  g_signal_connect_after(
      self, "size-allocate",
      G_CALLBACK(fl_view_renderer_subsurface_size_allocate_after), nullptr);
}

FlViewRendererSubsurface* fl_view_renderer_subsurface_new(
    FlEngine* engine,
    gboolean sized_to_content) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(
      g_object_new(fl_view_renderer_subsurface_get_type(), nullptr));
  self->engine = FL_ENGINE(g_object_ref(engine));
  self->sized_to_content = sized_to_content;
  return self;
}
