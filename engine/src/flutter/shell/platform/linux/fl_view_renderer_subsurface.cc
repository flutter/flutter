// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_subsurface.h"

#include <epoxy/egl.h>
#include <epoxy/gl.h>
#include <gdk/gdkwayland.h>
#include <wayland-client.h>
#include <wayland-egl.h>

#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_framebuffer.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"

// Maximum time to wait for the subsurface to be resized before giving up.
static constexpr gint64 kResizeTimeoutMicroseconds = 100000;  // 100ms

struct _FlViewRendererSubsurface {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // TRUE if have got the first frame to render.
  gboolean have_first_frame;

  // Background color.
  GdkRGBA* background_color;

  // Wayland globals used to create the subsurface.
  struct wl_compositor* wl_compositor;
  struct wl_subcompositor* wl_subcompositor;
  struct wl_surface* wl_surface;
  struct wl_subsurface* wl_subsurface;

  // EGL state for the subsurface.
  struct wl_egl_window* egl_window;
  EGLDisplay egl_display;
  EGLConfig egl_config;
  EGLContext egl_context;
  EGLSurface egl_surface;

  // Combines layers into a frame.
  FlCompositorOpenGL* compositor;

  // Task runner to wait for frames on.
  FlTaskRunner* task_runner;

  // Ensure Flutter and GTK can access the frame stored in the compositor.
  GMutex frame_mutex;

  // Synchronizes the GTK thread waiting for a resize with the render thread.
  GMutex resize_mutex;
  GCond resize_cond;
  gboolean resize_done;
  size_t resize_width;
  size_t resize_height;
};

G_DEFINE_TYPE(FlViewRendererSubsurface,
              fl_view_renderer_subsurface,
              fl_view_renderer_get_type())

// Wayland registry handling.
static void registry_global(void* data,
                            struct wl_registry* registry,
                            uint32_t name,
                            const char* interface,
                            uint32_t version) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(data);
  if (g_strcmp0(interface, wl_compositor_interface.name) == 0) {
    self->wl_compositor = static_cast<struct wl_compositor*>(wl_registry_bind(
        registry, name, &wl_compositor_interface, MIN(version, 4)));
  } else if (g_strcmp0(interface, wl_subcompositor_interface.name) == 0) {
    self->wl_subcompositor = static_cast<struct wl_subcompositor*>(
        wl_registry_bind(registry, name, &wl_subcompositor_interface, 1));
  }
}

static void registry_global_remove(void* data,
                                   struct wl_registry* registry,
                                   uint32_t name) {}

static const struct wl_registry_listener kRegistryListener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

// Block until the subsurface has been resized to the requested size, or the
// timeout expires.
static void wait_for_resize(FlViewRendererSubsurface* self,
                            size_t width,
                            size_t height) {
  g_mutex_lock(&self->resize_mutex);
  self->resize_done = FALSE;
  self->resize_width = width;
  self->resize_height = height;
  gint64 deadline = g_get_monotonic_time() + kResizeTimeoutMicroseconds;
  while (!self->resize_done) {
    if (!g_cond_wait_until(&self->resize_cond, &self->resize_mutex, deadline)) {
      break;
    }
  }
  g_mutex_unlock(&self->resize_mutex);
}

// Notify a waiting GTK thread that a frame of the requested size was presented.
static void notify_resize(FlViewRendererSubsurface* self,
                          size_t width,
                          size_t height) {
  g_mutex_lock(&self->resize_mutex);
  if (!self->resize_done && width == self->resize_width &&
      height == self->resize_height) {
    self->resize_done = TRUE;
    g_cond_signal(&self->resize_cond);
  }
  g_mutex_unlock(&self->resize_mutex);
}

// Move the subsurface to match the position of the widget in the toplevel.
static void update_subsurface_position(FlViewRendererSubsurface* self) {
  if (self->wl_subsurface == nullptr) {
    return;
  }
  GtkWidget* widget = GTK_WIDGET(self);
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  gint x, y;
  gtk_widget_translate_coordinates(widget, toplevel, 0, 0, &x, &y);
  wl_subsurface_set_position(self->wl_subsurface, x, y);
}

// Sets up the EGL context and window surface for the subsurface.
static gboolean setup_egl(FlViewRendererSubsurface* self,
                          struct wl_display* display,
                          size_t width,
                          size_t height,
                          gint scale) {
  self->egl_display =
      eglGetPlatformDisplayEXT(EGL_PLATFORM_WAYLAND_EXT, display, nullptr);
  if (self->egl_display == EGL_NO_DISPLAY) {
    g_warning("Failed to get EGL display for subsurface");
    return FALSE;
  }
  if (!eglInitialize(self->egl_display, nullptr, nullptr)) {
    g_warning("Failed to initialize EGL for subsurface");
    return FALSE;
  }

  static const EGLint config_attributes[] = {EGL_SURFACE_TYPE,
                                             EGL_WINDOW_BIT,
                                             EGL_RENDERABLE_TYPE,
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
  EGLint num_config;
  if (!eglChooseConfig(self->egl_display, config_attributes, &self->egl_config,
                       1, &num_config) ||
      num_config == 0) {
    g_warning("Failed to choose EGL config for subsurface");
    return FALSE;
  }

  eglBindAPI(EGL_OPENGL_ES_API);

  static const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                              EGL_NONE};
  self->egl_context = eglCreateContext(self->egl_display, self->egl_config,
                                       EGL_NO_CONTEXT, context_attributes);
  if (self->egl_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL context for subsurface");
    return FALSE;
  }

  self->egl_window =
      wl_egl_window_create(self->wl_surface, width * scale, height * scale);
  if (self->egl_window == nullptr) {
    g_warning("Failed to create wl_egl_window for subsurface");
    return FALSE;
  }

  self->egl_surface = eglCreateWindowSurface(
      self->egl_display, self->egl_config,
      reinterpret_cast<EGLNativeWindowType>(self->egl_window), nullptr);
  if (self->egl_surface == EGL_NO_SURFACE) {
    g_warning("Failed to create EGL window surface for subsurface");
    return FALSE;
  }

  wl_surface_set_buffer_scale(self->wl_surface, scale);

  eglMakeCurrent(self->egl_display, self->egl_surface, self->egl_surface,
                 self->egl_context);
  eglSwapInterval(self->egl_display, 0);
  eglMakeCurrent(self->egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                 EGL_NO_CONTEXT);
  return TRUE;
}

static void paint_background(FlViewRendererSubsurface* self, cairo_t* cr) {
  if (self->background_color->red == 0 && self->background_color->green == 0 &&
      self->background_color->blue == 0 && self->background_color->alpha == 0) {
    return;
  }

  gdk_cairo_set_source_rgba(cr, self->background_color);
  cairo_paint(cr);
}

// Redraw the view from the GTK thread.
static gboolean redraw_cb(gpointer user_data) {
  g_autoptr(FlViewRendererSubsurface) self =
      FL_VIEW_RENDERER_SUBSURFACE(user_data);

  if (self->compositor == nullptr) {
    return G_SOURCE_REMOVE;
  }

  if (!self->have_first_frame) {
    self->have_first_frame = TRUE;
    g_signal_emit_by_name(self, "first-frame");
  }

  GtkWidget* widget = GTK_WIDGET(self);
  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);
  gint scale_factor = gtk_widget_get_scale_factor(widget);
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
    gtk_widget_set_size_request(widget, frame_width / scale_factor,
                                frame_height / scale_factor);
    GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
    if (GTK_IS_WINDOW(toplevel)) {
      gtk_window_resize(GTK_WINDOW(toplevel), 1, 1);
    }
    return G_SOURCE_REMOVE;
  }

  gtk_widget_queue_draw(widget);

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
  struct wl_display* display = gdk_wayland_display_get_wl_display(gdk_display);

  // Bind the Wayland globals needed to create the subsurface.
  struct wl_registry* registry = wl_display_get_registry(display);
  wl_registry_add_listener(registry, &kRegistryListener, self);
  wl_display_roundtrip(display);
  wl_registry_destroy(registry);
  if (self->wl_compositor == nullptr || self->wl_subcompositor == nullptr) {
    g_warning("Required Wayland globals not available for subsurface");
    return;
  }

  // Create a subsurface on the toplevel's surface.
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  GdkWindow* gdk_window = gtk_widget_get_window(toplevel);
  struct wl_surface* parent_surface =
      gdk_wayland_window_get_wl_surface(gdk_window);
  self->wl_surface = wl_compositor_create_surface(self->wl_compositor);
  self->wl_subsurface = wl_subcompositor_get_subsurface(
      self->wl_subcompositor, self->wl_surface, parent_surface);
  wl_subsurface_set_sync(self->wl_subsurface);
  update_subsurface_position(self);

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);
  gint scale_factor = gtk_widget_get_scale_factor(widget);
  if (!setup_egl(self, display, allocation.width, allocation.height,
                 scale_factor)) {
    return;
  }

  self->task_runner =
      FL_TASK_RUNNER(g_object_ref(fl_engine_get_task_runner(self->engine)));
  // Wayland uses EGL so the engine frame can be shared via EGLImage.
  self->compositor = fl_compositor_opengl_new(
      fl_engine_get_opengl_manager(self->engine), TRUE);
}

// Implements GtkWidget::unrealize.
static void fl_view_renderer_subsurface_unrealize(GtkWidget* widget) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  g_clear_object(&self->compositor);

  if (self->egl_display != EGL_NO_DISPLAY) {
    if (self->egl_surface != EGL_NO_SURFACE) {
      eglDestroySurface(self->egl_display, self->egl_surface);
      self->egl_surface = EGL_NO_SURFACE;
    }
    if (self->egl_context != EGL_NO_CONTEXT) {
      eglDestroyContext(self->egl_display, self->egl_context);
      self->egl_context = EGL_NO_CONTEXT;
    }
    eglTerminate(self->egl_display);
    self->egl_display = EGL_NO_DISPLAY;
  }
  if (self->egl_window != nullptr) {
    wl_egl_window_destroy(self->egl_window);
    self->egl_window = nullptr;
  }
  if (self->wl_subsurface != nullptr) {
    wl_subsurface_destroy(self->wl_subsurface);
    self->wl_subsurface = nullptr;
  }
  if (self->wl_surface != nullptr) {
    wl_surface_destroy(self->wl_surface);
    self->wl_surface = nullptr;
  }
  g_clear_pointer(&self->wl_subcompositor, wl_subcompositor_destroy);
  g_clear_pointer(&self->wl_compositor, wl_compositor_destroy);

  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)->unrealize(widget);
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_subsurface_draw(GtkWidget* widget,
                                                 cairo_t* cr) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  // Flutter content is shown directly by the subsurface; only paint the
  // background behind it.
  paint_background(self, cr);

  return TRUE;
}

// Implements GtkWidget::size_allocate.
static void fl_view_renderer_subsurface_size_allocate(
    GtkWidget* widget,
    GtkAllocation* allocation) {
  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)
      ->size_allocate(widget, allocation);

  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  if (self->wl_subsurface == nullptr) {
    return;
  }

  gint scale_factor = gtk_widget_get_scale_factor(widget);
  size_t width = allocation->width * scale_factor;
  size_t height = allocation->height * scale_factor;

  update_subsurface_position(self);
  if (self->egl_window != nullptr) {
    wl_egl_window_resize(self->egl_window, width, height, 0, 0);
  }

  if (!self->sized_to_content) {
    wait_for_resize(self, width, height);
  }
}

// Implements FlViewRenderer::set_background_color.
static void fl_view_renderer_subsurface_set_background_color(
    FlViewRenderer* renderer,
    const GdkRGBA* color) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(renderer);

  gdk_rgba_free(self->background_color);
  self->background_color = gdk_rgba_copy(color);

  gtk_widget_queue_draw(GTK_WIDGET(self));
}

// Implements FlViewRenderer::present_layers.
static void fl_view_renderer_subsurface_present_layers(
    FlViewRenderer* renderer,
    const FlutterLayer** layers,
    size_t layers_count) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(renderer);

  // Frames may be presented before the widget is realized; ignore them.
  if (self->compositor == nullptr || self->egl_surface == EGL_NO_SURFACE) {
    return;
  }

  size_t width = 0;
  size_t height = 0;
  {
    g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

    // Composite the layers into the engine's shareable framebuffer.
    fl_compositor_opengl_present_layers(self->compositor, layers, layers_count);
    fl_compositor_opengl_get_frame_size(self->compositor, &width, &height);

    FlFramebuffer* framebuffer =
        fl_compositor_opengl_get_framebuffer(self->compositor);
    if (framebuffer != nullptr && fl_framebuffer_get_shareable(framebuffer)) {
      // Make the subsurface context current and blit the composited frame to
      // its window surface.
      eglMakeCurrent(self->egl_display, self->egl_surface, self->egl_surface,
                     self->egl_context);

      EGLint surface_width, surface_height;
      eglQuerySurface(self->egl_display, self->egl_surface, EGL_WIDTH,
                      &surface_width);
      eglQuerySurface(self->egl_display, self->egl_surface, EGL_HEIGHT,
                      &surface_height);
      if (static_cast<size_t>(surface_width) != width ||
          static_cast<size_t>(surface_height) != height) {
        wl_egl_window_resize(self->egl_window, width, height, 0, 0);
      }

      g_autoptr(FlFramebuffer) sibling =
          fl_framebuffer_create_sibling(framebuffer);
      glBindFramebuffer(GL_READ_FRAMEBUFFER, fl_framebuffer_get_id(sibling));
      glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
      glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                        GL_COLOR_BUFFER_BIT, GL_NEAREST);
      eglSwapBuffers(self->egl_display, self->egl_surface);
      eglMakeCurrent(self->egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE,
                     EGL_NO_CONTEXT);

      // Restore the engine's context for the next frame.
      fl_opengl_manager_make_current(
          fl_engine_get_opengl_manager(self->engine));
    }
  }

  // Wake the GTK thread if it is waiting for this resize.
  notify_resize(self, width, height);

  // Wake up the GTK thread if it is waiting for this frame.
  fl_task_runner_stop_wait(self->task_runner);

  // Perform the redraw in the GTK thread.
  g_idle_add(redraw_cb, g_object_ref(self));
}

static void fl_view_renderer_subsurface_dispose(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  g_clear_object(&self->engine);
  g_clear_object(&self->task_runner);
  g_clear_pointer(&self->background_color, gdk_rgba_free);

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
  g_mutex_clear(&self->frame_mutex);
  g_mutex_clear(&self->resize_mutex);
  g_cond_clear(&self->resize_cond);

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
  renderer_class->set_background_color =
      fl_view_renderer_subsurface_set_background_color;
  renderer_class->present_layers = fl_view_renderer_subsurface_present_layers;
}

static void fl_view_renderer_subsurface_init(FlViewRendererSubsurface* self) {
  self->egl_display = EGL_NO_DISPLAY;
  self->egl_context = EGL_NO_CONTEXT;
  self->egl_surface = EGL_NO_SURFACE;
  g_mutex_init(&self->frame_mutex);
  g_mutex_init(&self->resize_mutex);
  g_cond_init(&self->resize_cond);

  GdkRGBA default_background = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  self->background_color = gdk_rgba_copy(&default_background);
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
