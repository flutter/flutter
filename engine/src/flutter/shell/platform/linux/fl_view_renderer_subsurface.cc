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

// Maximum time to hold a frame back for GTK to paint the window it belongs to
// before showing it anyway.
static constexpr guint kSynchronizeTimeoutMilliseconds = 100;

struct _FlViewRendererSubsurface {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // Wayland subsurface the frame is rendered into.
  FlSubsurface* subsurface;

  // Scale factor of the widget when the subsurface was created.
  gint subsurface_scale;

  // The surface the subsurface was created on, and its Wayland object ID. Not
  // owned by this object, they are only used to detect when GTK has replaced
  // the surface. Both are compared because GTK may allocate the replacement at
  // the same address.
  struct wl_surface* parent_surface;
  uint32_t parent_surface_id;

  // Manages the EGL context and surface used to present frames to the
  // subsurface.
  FlSubsurfaceEGL* egl;

  // The subsurface egl was created for.
  FlSubsurface* egl_subsurface;

  // Combines layers into a frame.
  FlCompositorOpenGL* compositor;

  // Framebuffer the current frame is composited into.
  FlFramebuffer* framebuffer;

  // Size of the last frame presented to the subsurface, in pixels. Zero if no
  // frame has been presented to it yet.
  size_t presented_width;
  size_t presented_height;

  // Task runner used to wait for frames while resizing.
  FlTaskRunner* task_runner;

  // Ensure Flutter and GTK can access the frame stored in the compositor, and
  // the state below.
  GMutex frame_mutex;

  // TRUE while the subsurface is synchronized with the parent surface, which
  // holds a frame back until the window has been resized to match it. See
  // start_synchronization().
  gboolean synchronized;

  // TRUE if a frame has been presented while synchronized, so the compositor
  // is holding one back. Only one frame is held at a time: replacing it would
  // leave the compositor with a buffer it has never shown, which it can't be
  // relied on to give back before the parent surface is committed.
  gboolean frame_held;

  // TRUE if a frame was dropped while synchronized, in which case another one
  // is asked for once the subsurface is desynchronized.
  gboolean frame_dropped;

  // Size of the frame the GTK thread is resizing the window for, in pixels.
  // Zero if the frame being held is the one that set the size.
  size_t awaited_width;
  size_t awaited_height;

  // TRUE once the GTK thread has asked for the window to be painted with the
  // held frame, and TRUE once it has been. GTK commits the parent surface
  // after painting, which shows the held frame.
  gboolean paint_requested;
  gboolean painted;

  // TRUE if GTK didn't paint the window in time for the last held frame, e.g.
  // because the compositor isn't asking for frames for a window that can't be
  // seen. Frames aren't held back for the size of the window to change while
  // this is the case, as nothing would show them.
  gboolean paint_stalled;

  // Source that stops holding a frame back if GTK doesn't paint the window.
  guint synchronize_timeout_id;

  // TRUE while the raster thread is presenting a frame to the subsurface,
  // which it does without holding the frame mutex. Signalled when it is done.
  gboolean presenting;
  GCond present_cond;

  // The frame clock being watched for GTK painting the window, and the handler
  // connected to it. NULL and zero when the widget isn't realized.
  GdkFrameClock* frame_clock;
  gulong after_paint_handler;
};

G_DEFINE_TYPE(FlViewRendererSubsurface,
              fl_view_renderer_subsurface,
              fl_view_renderer_get_type())

// Wait for a frame matching the given size to be presented, or until the
// timeout expires. This blocks the GTK thread so a window resize stays in step
// with the subsurface content. Must be called with the frame mutex held; the
// mutex is still held when this function returns.
static void wait_for_frame(FlViewRendererSubsurface* self,
                           size_t width,
                           size_t height) {
  gint64 expiry_time = g_get_monotonic_time() + kRenderTimeoutMicroseconds;
  while (true) {
    // Waiting runs Flutter tasks, and the UI isolate runs on this thread, so
    // it runs Dart code. That code can destroy the window this widget is in,
    // in which case there is no frame to wait for.
    if (self->subsurface == nullptr) {
      break;
    }

    if (self->presented_width == width && self->presented_height == height) {
      break;
    }

    if (g_get_monotonic_time() > expiry_time) {
      g_warning(
          "Timed out waiting for subsurface frame of size %zdx%zd (have "
          "%zdx%zd)",
          width, height, self->presented_width, self->presented_height);
      break;
    }

    g_mutex_unlock(&self->frame_mutex);
    fl_task_runner_wait(self->task_runner, expiry_time);
    g_mutex_lock(&self->frame_mutex);
  }
}

// Gets the Wayland surface of the window this widget is inside, or nullptr if
// it doesn't have one.
static struct wl_surface* get_parent_surface(GtkWidget* widget) {
  GdkWindow* window = gtk_widget_get_window(gtk_widget_get_toplevel(widget));
  if (window == nullptr || !GDK_IS_WAYLAND_WINDOW(window)) {
    return nullptr;
  }
  return gdk_wayland_window_get_wl_surface(window);
}

// Gets the Wayland object ID of @surface, or zero if it doesn't exist.
static uint32_t get_surface_id(struct wl_surface* surface) {
  return surface == nullptr
             ? 0
             : wl_proxy_get_id(reinterpret_cast<struct wl_proxy*>(surface));
}

// Commits the surface of the window this widget is in, which shows anything
// held back in the subsurface. The surface belongs to GTK, which commits it
// itself after painting; this is for when it isn't going to.
static void commit_parent_surface(FlViewRendererSubsurface* self) {
  // GTK may have replaced or destroyed the surface since the subsurface was
  // made, see update_parent_surface().
  struct wl_surface* parent_surface = get_parent_surface(GTK_WIDGET(self));
  if (parent_surface == nullptr || parent_surface != self->parent_surface ||
      get_surface_id(parent_surface) != self->parent_surface_id) {
    return;
  }

  wl_surface_commit(parent_surface);
}

// Desynchronize the subsurface from the parent surface again, so frames are
// shown as soon as they are presented. Any frame held back while synchronized
// is shown now.
static void stop_synchronization(FlViewRendererSubsurface* self) {
  g_mutex_lock(&self->frame_mutex);

  if (self->synchronize_timeout_id != 0) {
    g_source_remove(self->synchronize_timeout_id);
    self->synchronize_timeout_id = 0;
  }

  gboolean frame_dropped = FALSE;
  if (self->synchronized) {
    if (self->subsurface != nullptr) {
      // GTK commits the parent surface after painting, which has already
      // shown the held frame. If it didn't paint, or didn't commit what it
      // painted, do that here so the frame isn't left with the compositor.
      if (self->frame_held) {
        commit_parent_surface(self);
      }
      fl_subsurface_set_desync(self->subsurface);
      frame_dropped = self->frame_dropped;
    }
    self->synchronized = FALSE;
    self->frame_held = FALSE;
    self->frame_dropped = FALSE;
    self->awaited_width = 0;
    self->awaited_height = 0;
    self->paint_requested = FALSE;
    self->painted = FALSE;
  }

  g_mutex_unlock(&self->frame_mutex);

  // Frames presented while one was being held were dropped, so what is being
  // shown may be out of date.
  if (frame_dropped) {
    fl_engine_schedule_frame(self->engine);
  }
}

// Called if GTK hasn't painted the window in time to show a held frame.
static gboolean synchronize_timeout_cb(gpointer user_data) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(user_data);

  g_mutex_lock(&self->frame_mutex);
  // The source is removed when the subsurface is desynchronized, but may have
  // been dispatched before the raster thread synchronized it again.
  guint id = g_source_get_id(g_main_current_source());
  gboolean current = self->synchronize_timeout_id == id;
  if (current) {
    self->synchronize_timeout_id = 0;
    self->paint_stalled = TRUE;
  }
  g_mutex_unlock(&self->frame_mutex);

  if (current) {
    stop_synchronization(self);
  }

  return G_SOURCE_REMOVE;
}

// Synchronize the subsurface with the parent surface, so the next frame
// presented is held back by the compositor until the parent surface is
// committed. This is used to change the size of the window and its contents
// in the same compositor update: the frame of the new size is held until GTK
// has painted the resized window, which is when it commits the parent surface.
//
// Otherwise the subsurface is desynchronized, so frames are shown as soon as
// the raster thread presents them and the GTK thread doesn't have to redraw
// the window for each one.
//
// A held frame is only shown if the parent surface is committed, and the
// compositor keeps its buffer until then, so this must always be followed by
// stop_synchronization(). That happens once GTK has painted, or after a
// timeout if it doesn't.
//
// Must be called with the frame mutex held, from either thread.
static void start_synchronization(FlViewRendererSubsurface* self) {
  if (self->synchronized) {
    return;
  }

  fl_subsurface_set_sync(self->subsurface);
  self->synchronized = TRUE;
  self->frame_held = FALSE;
  self->frame_dropped = FALSE;
  self->paint_requested = FALSE;
  self->painted = FALSE;
  self->synchronize_timeout_id = g_timeout_add_full(
      G_PRIORITY_DEFAULT, kSynchronizeTimeoutMilliseconds,
      synchronize_timeout_cb, g_object_ref(self), g_object_unref);
}

// Called after GTK has painted and committed the parent surface, which also
// showed any frame held back by the subsurface being synchronized.
static void after_paint_cb(FlViewRendererSubsurface* self) {
  g_mutex_lock(&self->frame_mutex);
  // Only a paint of this widget that was asked for once the frame was being
  // held shows it: GTK doesn't commit the parent surface unless it painted,
  // and the frame clock also runs for other reasons.
  gboolean shown = self->synchronized && self->paint_requested && self->painted;
  g_mutex_unlock(&self->frame_mutex);

  if (shown) {
    stop_synchronization(self);
  }
}

// Watch the frame clock of the window this widget is in, to know when GTK has
// painted it.
static void connect_frame_clock(FlViewRendererSubsurface* self) {
  if (self->frame_clock != nullptr) {
    return;
  }

  GdkFrameClock* frame_clock = gtk_widget_get_frame_clock(GTK_WIDGET(self));
  if (frame_clock == nullptr) {
    return;
  }

  self->frame_clock = GDK_FRAME_CLOCK(g_object_ref(frame_clock));
  // GTK commits the parent surface from its own handler for this signal, so
  // connect after it to desynchronize once that commit has been made.
  self->after_paint_handler = g_signal_connect_data(
      frame_clock, "after-paint", G_CALLBACK(after_paint_cb), self, nullptr,
      static_cast<GConnectFlags>(G_CONNECT_AFTER | G_CONNECT_SWAPPED));
}

static void disconnect_frame_clock(FlViewRendererSubsurface* self) {
  if (self->frame_clock == nullptr) {
    return;
  }

  g_signal_handler_disconnect(self->frame_clock, self->after_paint_handler);
  self->after_paint_handler = 0;
  g_clear_object(&self->frame_clock);
}

// Hold back the frame of the given size, in pixels, until GTK has painted the
// window it is being resized to. This has to be requested before the new
// window metrics reach the engine, so the frame it renders in response is the
// one held.
static void begin_synchronized_resize(FlViewRendererSubsurface* self,
                                      size_t width,
                                      size_t height) {
  // A view sized to its content is resized by the frames it is given, see
  // fl_view_renderer_subsurface_present_layers().
  if (self->subsurface == nullptr || self->sized_to_content) {
    return;
  }

  connect_frame_clock(self);

  g_mutex_lock(&self->frame_mutex);

  // A frame the raster thread is part way through presenting would be held
  // back if it is committed after the subsurface is synchronized, in place of
  // the frame the window is being resized for. Let it finish first.
  gint64 expiry_time = g_get_monotonic_time() + kRenderTimeoutMicroseconds;
  while (self->presenting && !self->synchronized) {
    if (!g_cond_wait_until(&self->present_cond, &self->frame_mutex,
                           expiry_time)) {
      break;
    }
  }
  // Nothing to resize if the subsurface was replaced or removed meanwhile.
  if (self->subsurface == nullptr) {
    g_mutex_unlock(&self->frame_mutex);
    return;
  }
  gboolean was_synchronized = self->synchronized;

  start_synchronization(self);
  if (!was_synchronized && self->presenting) {
    // Gave up waiting, so assume the compositor ends up holding that frame.
    self->frame_held = TRUE;
  }
  if (self->frame_held &&
      (width != self->awaited_width || height != self->awaited_height)) {
    // The window has been resized again before GTK painted it, which happens
    // when it is first shown. The frame being held is for a size the window
    // no longer has, so show it to make way for one that is.
    commit_parent_surface(self);
    self->frame_held = FALSE;
  }
  self->awaited_width = width;
  self->awaited_height = height;
  self->paint_requested = TRUE;
  self->painted = FALSE;
  g_mutex_unlock(&self->frame_mutex);

  // The parent surface is only committed when GTK paints, so make sure that
  // happens.
  gtk_widget_queue_draw(GTK_WIDGET(self));
}

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

static void clear_subsurface(FlViewRendererSubsurface* self) {
  if (self->subsurface == nullptr) {
    return;
  }

  // Destroy in case the raster thread still holds the object.
  fl_subsurface_destroy(self->subsurface);
  g_clear_object(&self->subsurface);
  self->presented_width = 0;
  self->presented_height = 0;
}

static void create_subsurface(FlViewRendererSubsurface* self,
                              struct wl_surface* parent_surface) {
  GtkWidget* widget = GTK_WIDGET(self);

  FlWaylandDisplay* wayland_display =
      fl_wayland_display_get_for_display(gtk_widget_get_display(widget));
  if (wayland_display == nullptr) {
    return;
  }

  self->subsurface =
      fl_wayland_display_create_subsurface(wayland_display, parent_surface);
  update_subsurface_position(self);

  // A new subsurface is synchronized with its parent, which holds back every
  // frame until the parent (GTK) surface is redrawn and committed.
  // Desynchronize it so frames are shown as soon as they are committed, which
  // leaves the GTK thread idle while Flutter is animating. It is only
  // synchronized while the size of the window is being changed, see
  // start_synchronization().
  fl_subsurface_set_desync(self->subsurface);

  self->subsurface_scale = gtk_widget_get_scale_factor(widget);
}

// GTK destroys the window's Wayland surface when it is hidden and makes a new
// one if it is shown again. The subsurface belongs to the old surface, so it is
// never shown again and using it is a protocol error. Detect this and move to
// the new surface.
static void update_parent_surface(FlViewRendererSubsurface* self) {
  // Nothing to do before the widget is realized or after it is unrealized.
  if (self->compositor == nullptr) {
    return;
  }

  struct wl_surface* parent_surface = get_parent_surface(GTK_WIDGET(self));
  uint32_t parent_surface_id = get_surface_id(parent_surface);
  if (parent_surface == self->parent_surface &&
      parent_surface_id == self->parent_surface_id) {
    return;
  }

  // Drop the old subsurface. The surface it was on may already be destroyed,
  // in which case there is nothing to replace it with until the window is
  // shown again.
  stop_synchronization(self);
  g_mutex_lock(&self->frame_mutex);
  clear_subsurface(self);
  self->parent_surface = parent_surface;
  self->parent_surface_id = parent_surface_id;
  if (parent_surface != nullptr) {
    create_subsurface(self, parent_surface);
  }
  g_mutex_unlock(&self->frame_mutex);

  if (parent_surface == nullptr) {
    return;
  }

  // The new subsurface has nothing in it, so ask for the frame to be rendered
  // again.
  fl_engine_schedule_frame(self->engine);
}

// Handle a presented frame on the GTK thread. The frame was shown by the
// subsurface when it was presented, so the widget doesn't need redrawing,
// unless the view is sized to its content.
static gboolean frame_presented_cb(gpointer user_data) {
  g_autoptr(FlViewRendererSubsurface) self =
      FL_VIEW_RENDERER_SUBSURFACE(user_data);

  if (self->compositor == nullptr) {
    return G_SOURCE_REMOVE;
  }

  fl_view_renderer_notify_frame(FL_VIEW_RENDERER(self));

  if (self->sized_to_content) {
    connect_frame_clock(self);

    size_t frame_width, frame_height;
    g_mutex_lock(&self->frame_mutex);
    frame_width = self->presented_width;
    frame_height = self->presented_height;
    // A frame of a new size is held back until the window has been resized to
    // fit it, which is asked for below. A paint from before this point isn't
    // of the resized window.
    gboolean frame_held = self->synchronized && self->frame_held;
    if (frame_held && !self->paint_requested) {
      self->paint_requested = TRUE;
      self->painted = FALSE;
    }
    g_mutex_unlock(&self->frame_mutex);
    if (fl_view_renderer_resize_to_frame(FL_VIEW_RENDERER(self), frame_width,
                                         frame_height)) {
      return G_SOURCE_REMOVE;
    }

    // The window is already the size of the held frame, which is shown when
    // the window is next committed; redraw it to make that happen.
    if (frame_held) {
      gtk_widget_queue_draw(GTK_WIDGET(self));
    }
  }

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

  // The subsurface's EGL context shares resources with the engine, so the
  // engine's frame texture is accessed directly without using EGLImage.
  self->task_runner =
      FL_TASK_RUNNER(g_object_ref(fl_engine_get_task_runner(self->engine)));
  self->compositor =
      fl_compositor_opengl_new(fl_engine_get_opengl_manager(self->engine));

  // Create a subsurface on the toplevel's surface. This asks for a frame, as
  // any rendered before this point were dropped.
  update_parent_surface(self);
}

// Implements GtkWidget::unrealize.
static void fl_view_renderer_subsurface_unrealize(GtkWidget* widget) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  stop_synchronization(self);
  disconnect_frame_clock(self);

  // Hold frame_mutex while releasing these objects so the raster thread cannot
  // be using them in present_layers concurrently. The raster thread releases
  // its EGL context on the next frame, or when this object is finalized.
  g_mutex_lock(&self->frame_mutex);
  g_clear_object(&self->compositor);
  clear_subsurface(self);
  self->parent_surface = nullptr;
  self->parent_surface_id = 0;
  g_mutex_unlock(&self->frame_mutex);

  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)->unrealize(widget);
}

// Implements GtkWidget::map.
static void fl_view_renderer_subsurface_map(GtkWidget* widget) {
  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)->map(widget);

  update_parent_surface(FL_VIEW_RENDERER_SUBSURFACE(widget));
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_subsurface_draw(GtkWidget* widget,
                                                 cairo_t* cr) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  // GTK commits the parent surface once it has painted, which shows a frame
  // being held back for it. See after_paint_cb().
  g_mutex_lock(&self->frame_mutex);
  self->painted = TRUE;
  self->paint_stalled = FALSE;
  g_mutex_unlock(&self->frame_mutex);

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

  update_parent_surface(self);
  update_subsurface_position(self);

  // Keep the frame of the new size back until GTK has committed the resized
  // parent surface. This has to be requested before the new window metrics
  // reach the engine (FlView sends them from its size-allocate handler, which
  // runs after this), so the frame it renders in response is held back.
  gint scale_factor = gtk_widget_get_scale_factor(widget);
  begin_synchronized_resize(self, allocation->width * scale_factor,
                            allocation->height * scale_factor);
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
  if (self->subsurface == nullptr || self->sized_to_content) {
    return;
  }

  gint scale_factor = gtk_widget_get_scale_factor(widget);
  size_t width = allocation->width * scale_factor;
  size_t height = allocation->height * scale_factor;

  g_mutex_lock(&self->frame_mutex);
  wait_for_frame(self, width, height);
  g_mutex_unlock(&self->frame_mutex);
}

// Release the EGL context used to present frames. Only called from the raster
// thread.
static void release_egl(FlViewRendererSubsurface* self) {
  if (self->egl == nullptr) {
    return;
  }

  g_clear_object(&self->egl);
  self->egl_subsurface = nullptr;

  // Destroying the context leaves none current, so restore the engine's.
  fl_opengl_manager_make_current(fl_engine_get_opengl_manager(self->engine));
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
  // release these objects while a frame is being composited.
  if (self->compositor == nullptr || self->subsurface == nullptr) {
    g_mutex_unlock(&self->frame_mutex);
    release_egl(self);
    return;
  }

  size_t width, height;
  if (layers_count > 0) {
    width = layers[0]->size.width;
    height = layers[0]->size.height;
  } else if (self->framebuffer != nullptr) {
    // A frame with nothing to rasterize, e.g. everything painted was fully
    // transparent, has no layers and so no size. Keep the current size and
    // present the frame, which is cleared when the layers are composited
    // below, so the previous frame is not left on screen.
    width = fl_framebuffer_get_width(self->framebuffer);
    height = fl_framebuffer_get_height(self->framebuffer);
  } else {
    // Nothing has been rendered yet, so there is nothing to clear. The GTK
    // thread is still notified below so the window is shown.
    width = 0;
    height = 0;
  }

  if (width > 0 && height > 0) {
    if (self->synchronized) {
      // Only the frame the window is being resized for is held back, and only
      // one: the compositor keeps the buffer of a held frame until the parent
      // surface is committed, and replacing it leaves the buffer of a frame
      // that was never shown with it too. A driver with no buffers left blocks
      // this thread, which every view is rendered on, until GTK commits a
      // surface it may have no reason to. Drop the frame instead; another one
      // is asked for when the subsurface is desynchronized.
      gboolean awaited =
          self->awaited_width == 0 ||
          (width == self->awaited_width && height == self->awaited_height);
      if (self->frame_held || !awaited) {
        self->frame_dropped = TRUE;
        g_mutex_unlock(&self->frame_mutex);
        return;
      }
    } else if (self->sized_to_content && !self->paint_stalled &&
               self->presented_width > 0 &&
               (width != self->presented_width ||
                height != self->presented_height)) {
      // The window is resized to fit this frame once it has been presented,
      // see frame_presented_cb(). Hold the frame back until then.
      start_synchronization(self);
    }
    if (self->synchronized) {
      self->frame_held = TRUE;
    }

    // Recreate the framebuffer if the frame size has changed. The subsurface's
    // EGL context shares resources with the engine, so the frame texture is
    // read directly and doesn't need to be shareable or copied via CPU memory.
    if (self->framebuffer == nullptr ||
        fl_framebuffer_get_width(self->framebuffer) != width ||
        fl_framebuffer_get_height(self->framebuffer) != height) {
      GLint general_format =
          fl_compositor_opengl_get_frame_format(layers, layers_count);
      g_clear_object(&self->framebuffer);
      self->framebuffer =
          fl_framebuffer_new(general_format, width, height, FALSE);
    }

    // Bind the target framebuffer so the compositor draws into it.
    GLint saved_draw_framebuffer_binding;
    glGetIntegerv(GL_DRAW_FRAMEBUFFER_BINDING, &saved_draw_framebuffer_binding);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER,
                      fl_framebuffer_get_id(self->framebuffer));

    fl_compositor_opengl_composite_layers(self->compositor, layers,
                                          layers_count);

    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, saved_draw_framebuffer_binding);
  }

  // The frame is presented below using the subsurface's own OpenGL context.
  // Sharing a texture between contexts requires the rendering to have completed
  // before the other context uses it - making a context current only flushes
  // the previous one, which guarantees the commands have been submitted, not
  // that they have finished.
  g_autoptr(FlGLFence) fence = nullptr;
  if (fl_compositor_opengl_can_fence(self->compositor)) {
    fence = fl_gl_fence_new(fl_engine_get_opengl_manager(self->engine));
  } else {
    // No fences on this driver, wait for the rendering here instead.
    glFinish();
  }

  // Keep a reference to the subsurface in case GTK replaces it. Presenting can
  // block in the driver, so release the mutex first.
  g_autoptr(FlSubsurface) subsurface =
      FL_SUBSURFACE(g_object_ref(self->subsurface));
  self->presenting = TRUE;
  gint scale = self->subsurface_scale;
  GLuint texture_id = self->framebuffer != nullptr
                          ? fl_framebuffer_get_texture_id(self->framebuffer)
                          : 0;
  g_mutex_unlock(&self->frame_mutex);

  // Present the composited frame directly to the subsurface using its own EGL
  // context. This reads the engine's frame texture directly, as the subsurface
  // context shares resources with the engine. The framebuffer is only replaced
  // by this thread, so the texture remains valid.
  if (width > 0 && height > 0) {
    // Replace the EGL context if the GTK thread has replaced the subsurface.
    if (self->egl_subsurface != subsurface) {
      release_egl(self);
      // The EGL window is sized in logical pixels, rounded up to fit the frame.
      self->egl = fl_subsurface_egl_new(
          fl_engine_get_opengl_manager(self->engine), subsurface,
          (width + scale - 1) / scale, (height + scale - 1) / scale, scale);
      self->egl_subsurface = subsurface;
    }
    fl_subsurface_egl_present(self->egl, texture_id, width, height, fence);
  }

  // Record the size now on the subsurface and wake the GTK thread in case it is
  // waiting for it in wait_for_frame().
  g_mutex_lock(&self->frame_mutex);
  if (self->subsurface == subsurface) {
    self->presented_width = width;
    self->presented_height = height;
  }
  self->presenting = FALSE;
  g_cond_broadcast(&self->present_cond);
  g_mutex_unlock(&self->frame_mutex);
  fl_task_runner_stop_wait(self->task_runner);

  // Notify the GTK thread so it can emit the first frame and resize the view.
  g_idle_add(frame_presented_cb, g_object_ref(self));
}

static void fl_view_renderer_subsurface_dispose(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  stop_synchronization(self);
  disconnect_frame_clock(self);

  G_OBJECT_CLASS(fl_view_renderer_subsurface_parent_class)->dispose(object);
}

static void fl_view_renderer_subsurface_finalize(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  // Everything present_layers and wait_for_frame use is released here rather
  // than in dispose() so it outlives a forced dispose (e.g.
  // gtk_widget_destroy()) and is only freed once the last reference is
  // dropped. This keeps it alive for the raster thread, which holds a strong
  // reference on the view (and thus this renderer) while presenting, and for
  // the GTK thread if the window is destroyed by a task run while it waits for
  // a frame.
  g_clear_object(&self->compositor);
  g_clear_object(&self->framebuffer);
  g_clear_object(&self->egl);
  g_clear_object(&self->engine);
  g_clear_object(&self->task_runner);
  g_mutex_clear(&self->frame_mutex);
  g_cond_clear(&self->present_cond);

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
  widget_class->map = fl_view_renderer_subsurface_map;
  widget_class->draw = fl_view_renderer_subsurface_draw;
  widget_class->size_allocate = fl_view_renderer_subsurface_size_allocate;

  FlViewRendererClass* renderer_class = FL_VIEW_RENDERER_CLASS(klass);
  renderer_class->present_layers = fl_view_renderer_subsurface_present_layers;
}

static void fl_view_renderer_subsurface_init(FlViewRendererSubsurface* self) {
  g_mutex_init(&self->frame_mutex);
  g_cond_init(&self->present_cond);

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
