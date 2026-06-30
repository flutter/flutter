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
#include "flutter/shell/platform/linux/fl_subsurface.h"

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

  // Wayland subsurface the frame is rendered into.
  FlSubsurface* subsurface;

  // EGL state for the subsurface. The display is owned by the engine's
  // FlOpenGLManager (see get_egl_display), not by this renderer.
  struct wl_egl_window* egl_window;
  EGLContext egl_context;
  EGLSurface egl_surface;

  // Combines layers into a frame.
  FlCompositorOpenGL* compositor;

  // Ensure Flutter and GTK can access the frame stored in the compositor.
  GMutex frame_mutex;
};

G_DEFINE_TYPE(FlViewRendererSubsurface,
              fl_view_renderer_subsurface,
              fl_view_renderer_get_type())

// Gets the EGL display the engine renders to. The subsurface shares this
// display so its context can access the engine's frame texture directly.
static EGLDisplay get_egl_display(FlViewRendererSubsurface* self) {
  return fl_opengl_manager_get_display(
      fl_engine_get_opengl_manager(self->engine));
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

// Sets up the EGL context and window surface for the subsurface.
static gboolean setup_egl(FlViewRendererSubsurface* self,
                          size_t width,
                          size_t height,
                          gint scale) {
  // Share the engine's EGL display and render context so the engine's frame
  // texture can be accessed directly, without using EGLImage.
  FlOpenGLManager* opengl_manager = fl_engine_get_opengl_manager(self->engine);
  EGLDisplay egl_display = fl_opengl_manager_get_display(opengl_manager);
  if (egl_display == EGL_NO_DISPLAY) {
    g_warning("Failed to get EGL display for subsurface");
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
  EGLConfig egl_config;
  EGLint num_config;
  if (!eglChooseConfig(egl_display, config_attributes, &egl_config, 1,
                       &num_config) ||
      num_config == 0) {
    g_warning("Failed to choose EGL config for subsurface");
    return FALSE;
  }

  eglBindAPI(EGL_OPENGL_ES_API);

  static const EGLint context_attributes[] = {EGL_CONTEXT_CLIENT_VERSION, 2,
                                              EGL_NONE};
  self->egl_context =
      eglCreateContext(egl_display, egl_config,
                       fl_opengl_manager_get_context(opengl_manager),
                       context_attributes);
  if (self->egl_context == EGL_NO_CONTEXT) {
    g_warning("Failed to create EGL context for subsurface");
    return FALSE;
  }

  self->egl_window =
      wl_egl_window_create(fl_subsurface_get_surface(self->subsurface),
                           width * scale, height * scale);
  if (self->egl_window == nullptr) {
    g_warning("Failed to create wl_egl_window for subsurface");
    return FALSE;
  }

  self->egl_surface = eglCreateWindowSurface(
      egl_display, egl_config,
      reinterpret_cast<EGLNativeWindowType>(self->egl_window), nullptr);
  if (self->egl_surface == EGL_NO_SURFACE) {
    g_warning("Failed to create EGL window surface for subsurface");
    return FALSE;
  }

  wl_surface_set_buffer_scale(fl_subsurface_get_surface(self->subsurface),
                              scale);

  eglMakeCurrent(egl_display, self->egl_surface, self->egl_surface,
                 self->egl_context);
  eglSwapInterval(egl_display, 0);
  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
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
    fl_view_renderer_emit_first_frame(FL_VIEW_RENDERER(self));
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

  // Create a subsurface on the toplevel's surface.
  self->subsurface = fl_subsurface_new(widget);
  if (self->subsurface == nullptr) {
    return;
  }

  GtkAllocation allocation;
  gtk_widget_get_allocation(widget, &allocation);
  gint scale_factor = gtk_widget_get_scale_factor(widget);
  if (!setup_egl(self, allocation.width, allocation.height, scale_factor)) {
    return;
  }

  // The subsurface's EGL context shares resources with the engine, so the
  // engine's frame texture is accessed directly without using EGLImage.
  self->compositor = fl_compositor_opengl_new(
      fl_engine_get_opengl_manager(self->engine),
      FL_COMPOSITOR_OPENGL_FRAME_SHARING_SHARED_CONTEXT);
}

// Implements GtkWidget::unrealize.
static void fl_view_renderer_subsurface_unrealize(GtkWidget* widget) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  g_clear_object(&self->compositor);

  // The EGL display is owned by the engine (same Wayland display), so only the
  // surface and context created by this renderer are destroyed here; the
  // display must not be terminated.
  EGLDisplay egl_display = get_egl_display(self);
  if (self->egl_surface != EGL_NO_SURFACE) {
    eglDestroySurface(egl_display, self->egl_surface);
    self->egl_surface = EGL_NO_SURFACE;
  }
  if (self->egl_context != EGL_NO_CONTEXT) {
    eglDestroyContext(egl_display, self->egl_context);
    self->egl_context = EGL_NO_CONTEXT;
  }
  if (self->egl_window != nullptr) {
    wl_egl_window_destroy(self->egl_window);
    self->egl_window = nullptr;
  }
  g_clear_object(&self->subsurface);

  GTK_WIDGET_CLASS(fl_view_renderer_subsurface_parent_class)->unrealize(widget);
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_subsurface_draw(GtkWidget* widget,
                                                 cairo_t* cr) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(widget);

  // Flutter content is shown directly by the subsurface; only paint the
  // background behind it.
  paint_background(self, cr);

  // The compositor is created when the widget is realized; if it is not yet
  // available there is nothing to present to the subsurface.
  if (self->compositor == nullptr || self->egl_surface == EGL_NO_SURFACE) {
    return TRUE;
  }

  g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

  FlFramebuffer* framebuffer =
      fl_compositor_opengl_get_framebuffer(self->compositor);
  if (framebuffer == nullptr) {
    return TRUE;
  }

  size_t width = fl_framebuffer_get_width(framebuffer);
  size_t height = fl_framebuffer_get_height(framebuffer);

  // Blit the composited frame to the subsurface window surface using the
  // subsurface's own EGL context. This is done on the GTK thread so the
  // engine's rendering context on the raster thread is never disturbed.
  EGLDisplay egl_display = get_egl_display(self);
  eglMakeCurrent(egl_display, self->egl_surface, self->egl_surface,
                 self->egl_context);

  EGLint surface_width, surface_height;
  eglQuerySurface(egl_display, self->egl_surface, EGL_WIDTH, &surface_width);
  eglQuerySurface(egl_display, self->egl_surface, EGL_HEIGHT, &surface_height);
  if (static_cast<size_t>(surface_width) != width ||
      static_cast<size_t>(surface_height) != height) {
    wl_egl_window_resize(self->egl_window, width, height, 0, 0);
  }

  // The subsurface context shares resources with the engine, so the engine's
  // frame texture can be read directly. Attach it to a framebuffer and blit it
  // to the subsurface window surface. The framebuffer is created and deleted
  // while the context is current.
  GLuint read_framebuffer;
  glGenFramebuffers(1, &read_framebuffer);
  glBindFramebuffer(GL_READ_FRAMEBUFFER, read_framebuffer);
  glFramebufferTexture2D(GL_READ_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                         GL_TEXTURE_2D,
                         fl_framebuffer_get_texture_id(framebuffer), 0);
  glBindFramebuffer(GL_DRAW_FRAMEBUFFER, 0);
  glBlitFramebuffer(0, 0, width, height, 0, 0, width, height,
                    GL_COLOR_BUFFER_BIT, GL_NEAREST);
  eglSwapBuffers(egl_display, self->egl_surface);
  glDeleteFramebuffers(1, &read_framebuffer);

  eglMakeCurrent(egl_display, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);

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
  if (self->egl_window != nullptr) {
    wl_egl_window_resize(self->egl_window, width, height, 0, 0);
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

  {
    g_autoptr(GMutexLocker) locker = g_mutex_locker_new(&self->frame_mutex);

    // Composite the layers into the engine's framebuffer. The frame is blitted
    // to the subsurface later, on the GTK thread, so the engine's rendering
    // context is not disturbed here.
    fl_compositor_opengl_present_layers(self->compositor, layers, layers_count);
  }

  // Perform the redraw in the GTK thread.
  g_idle_add(redraw_cb, g_object_ref(self));
}

static void fl_view_renderer_subsurface_dispose(GObject* object) {
  FlViewRendererSubsurface* self = FL_VIEW_RENDERER_SUBSURFACE(object);

  g_clear_object(&self->engine);
  g_clear_pointer(&self->background_color, gdk_rgba_free);
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
  self->egl_context = EGL_NO_CONTEXT;
  self->egl_surface = EGL_NO_SURFACE;
  g_mutex_init(&self->frame_mutex);

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
