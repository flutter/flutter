#if FLUTTER_LINUX_GTK4
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer.h"

#if FLUTTER_LINUX_GTK4
#include <gdk/wayland/gdkwayland.h>
#else
#include <gdk/gdkwayland.h>
#endif

#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/fl_compositor_opengl.h"
#include "flutter/shell/platform/linux/fl_compositor_software.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_opengl_manager.h"

struct _FlViewRenderer {
#if FLUTTER_LINUX_GTK4
  GtkWidget parent_instance;
#else
  GtkDrawingArea parent_instance;
#endif

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

#if FLUTTER_LINUX_GTK4
  // Last acquired texture to snapshot.
  GdkTexture* texture;

  // TRUE if the texture needs to be vertically flipped when snapshotting.
  gboolean flip_y;

  // TRUE if a native GTK texture has been acquired at least once.
  gboolean native_texture_ready;

  // Source ID for retrying texture acquisition when the surface is not ready.
  guint native_texture_retry_source_id;

  // Root of the native Flutter semantics tree exposed to GTK 4.10+.
  GtkAccessible* accessible_child;
#endif
};

enum { SIGNAL_FIRST_FRAME, SIGNAL_RESIZE, LAST_SIGNAL };

static guint fl_view_renderer_signals[LAST_SIGNAL];

#if FLUTTER_LINUX_GTK4
static void fl_view_renderer_accessible_iface_init(
    GtkAccessibleInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlViewRenderer,
    fl_view_renderer,
    GTK_TYPE_WIDGET,
    G_IMPLEMENT_INTERFACE(GTK_TYPE_ACCESSIBLE,
                          fl_view_renderer_accessible_iface_init))
#else
G_DEFINE_TYPE(FlViewRenderer, fl_view_renderer, GTK_TYPE_DRAWING_AREA)
#endif

#if FLUTTER_LINUX_GTK4
static GtkAccessible* fl_view_renderer_get_first_accessible_child(
    GtkAccessible* accessible) {
  FlViewRenderer* self = FL_VIEW_RENDERER(accessible);
  return self->accessible_child == nullptr
             ? nullptr
             : GTK_ACCESSIBLE(g_object_ref(self->accessible_child));
}

static void fl_view_renderer_accessible_iface_init(
    GtkAccessibleInterface* iface) {
  if (!fl_gtk_runtime_supports_native_accessibility_tree()) {
    return;
  }

  auto* iface_4_10 = reinterpret_cast<FlGtkAccessibleInterface4_10*>(iface);
  iface_4_10->get_first_accessible_child =
      fl_view_renderer_get_first_accessible_child;
}

static gboolean retry_native_texture_cb(gpointer user_data);

static void set_texture(FlViewRenderer* self, GdkTexture* texture) {
  if (texture != nullptr) {
    g_object_ref(texture);
  }
  g_clear_object(&self->texture);
  self->texture = texture;

  if (texture != nullptr) {
    gtk_widget_queue_resize(GTK_WIDGET(self));
  }
  gtk_widget_queue_draw(GTK_WIDGET(self));
}
#endif

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
  gint scale_factor = gtk_widget_get_scale_factor(render_widget);
  size_t width;
  size_t height;
#if FLUTTER_LINUX_GTK4
  width =
      static_cast<size_t>(gtk_widget_get_width(render_widget)) * scale_factor;
  height =
      static_cast<size_t>(gtk_widget_get_height(render_widget)) * scale_factor;
#else
  GtkAllocation allocation;
  gtk_widget_get_allocation(render_widget, &allocation);
  width = allocation.width * scale_factor;
  height = allocation.height * scale_factor;
#endif
  size_t frame_width, frame_height;
  fl_compositor_get_frame_size(self->compositor, &frame_width, &frame_height);
  gboolean frame_size_matches = width == frame_width && height == frame_height;
  if (self->sized_to_content && !frame_size_matches) {
    gtk_widget_set_size_request(
        render_widget, MAX(static_cast<gint>(frame_width / scale_factor), 1),
        MAX(static_cast<gint>(frame_height / scale_factor), 1));
#if FLUTTER_LINUX_GTK4
    GtkWidget* toplevel = GTK_WIDGET(gtk_widget_get_root(render_widget));
    if (GTK_IS_WINDOW(toplevel)) {
      gtk_window_set_default_size(
          GTK_WINDOW(toplevel),
          MAX(static_cast<gint>(frame_width / scale_factor), 1),
          MAX(static_cast<gint>(frame_height / scale_factor), 1));
    }
#else
    GtkWidget* toplevel = gtk_widget_get_toplevel(render_widget);
    if (GTK_IS_WINDOW(toplevel)) {
      // Resize to smallest size, so that the window will shrink to fit the new
      // size of the render area.
      gtk_window_resize(GTK_WINDOW(toplevel), 1, 1);
    }
#endif
    return G_SOURCE_REMOVE;
  }

#if FLUTTER_LINUX_GTK4
  if (!self->sized_to_content && !frame_size_matches && width > 1 &&
      height > 1) {
    g_signal_emit(self, fl_view_renderer_signals[SIGNAL_RESIZE], 0,
                  gtk_widget_get_width(render_widget),
                  gtk_widget_get_height(render_widget));
    return G_SOURCE_REMOVE;
  }

  if (width == 0 || height == 0) {
    if (self->native_texture_retry_source_id == 0) {
      self->native_texture_retry_source_id =
          g_timeout_add_full(G_PRIORITY_DEFAULT, 16, retry_native_texture_cb,
                             g_object_ref(self), g_object_unref);
    }
    return G_SOURCE_REMOVE;
  }

  g_autoptr(GdkTexture) texture = nullptr;
  FlGdkSurface* surface = fl_gtk_widget_get_surface(render_widget);
  if (surface != nullptr) {
    GdkGLContext* old_gl_context = gdk_gl_context_get_current();
    if (self->render_context != nullptr) {
      gdk_gl_context_make_current(self->render_context);
    }

    texture = fl_compositor_acquire_texture(
        self->compositor, surface, self->render_context, width, height,
        !self->sized_to_content || !self->native_texture_ready);

    if (gdk_gl_context_get_current() != old_gl_context) {
      gdk_gl_context_clear_current();
    }

    if (texture != nullptr) {
      self->flip_y = self->render_context != nullptr;
      set_texture(self, texture);
      self->native_texture_ready = TRUE;
      if (self->native_texture_retry_source_id != 0) {
        g_source_remove(self->native_texture_retry_source_id);
        self->native_texture_retry_source_id = 0;
      }
    } else if (!self->native_texture_ready &&
               self->native_texture_retry_source_id == 0) {
      self->native_texture_retry_source_id =
          g_timeout_add_full(G_PRIORITY_DEFAULT, 16, retry_native_texture_cb,
                             g_object_ref(self), g_object_unref);
    }
  }
#else
  gtk_widget_queue_draw(render_widget);
#endif

  return G_SOURCE_REMOVE;
}

#if FLUTTER_LINUX_GTK4
static gboolean retry_native_texture_cb(gpointer user_data) {
  FlViewRenderer* self = FL_VIEW_RENDERER(user_data);
  self->native_texture_retry_source_id = 0;
  redraw_cb(g_object_ref(self));
  return G_SOURCE_REMOVE;
}
#endif

static void setup_opengl(FlViewRenderer* self) {
  g_autoptr(GError) error = nullptr;

  FlGdkSurface* surface = fl_gtk_widget_get_surface(GTK_WIDGET(self));
  if (surface == nullptr) {
    return;
  }

  self->render_context = fl_gtk_surface_create_gl_context(surface, &error);
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
      GDK_IS_WAYLAND_DISPLAY(fl_gtk_surface_get_display(surface));
  self->compositor = FL_COMPOSITOR(fl_compositor_opengl_new(
      fl_engine_get_task_runner(self->engine),
      fl_engine_get_opengl_manager(self->engine), shareable));
}

static void setup_software(FlViewRenderer* self) {
  self->compositor = FL_COMPOSITOR(
      fl_compositor_software_new(fl_engine_get_task_runner(self->engine)));
}

#if !FLUTTER_LINUX_GTK4
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
#endif

#if FLUTTER_LINUX_GTK4
static void fl_view_renderer_size_allocate(GtkWidget* widget,
                                           int width,
                                           int height,
                                           int baseline) {
  GTK_WIDGET_CLASS(fl_view_renderer_parent_class)
      ->size_allocate(widget, width, height, baseline);

  g_signal_emit(widget, fl_view_renderer_signals[SIGNAL_RESIZE], 0, width,
                height);
}

static void fl_view_renderer_snapshot(GtkWidget* widget,
                                      GtkSnapshot* snapshot) {
  FlViewRenderer* self = FL_VIEW_RENDERER(widget);

  if (self->texture == nullptr) {
    return;
  }

  graphene_rect_t bounds = GRAPHENE_RECT_INIT(
      0.0f, 0.0f, static_cast<float>(gtk_widget_get_width(widget)),
      static_cast<float>(gtk_widget_get_height(widget)));
  if (self->flip_y) {
    graphene_point_t translate = GRAPHENE_POINT_INIT(
        0.0f, static_cast<float>(gtk_widget_get_height(widget)));
    gtk_snapshot_save(snapshot);
    gtk_snapshot_translate(snapshot, &translate);
    gtk_snapshot_scale(snapshot, 1.0f, -1.0f);
  }
  gtk_snapshot_append_texture(snapshot, self->texture, &bounds);
  if (self->flip_y) {
    gtk_snapshot_restore(snapshot);
  }
}

static void fl_view_renderer_measure(GtkWidget* widget,
                                     GtkOrientation orientation,
                                     int for_size,
                                     int* minimum,
                                     int* natural,
                                     int* minimum_baseline,
                                     int* natural_baseline) {
  (void)for_size;

  FlViewRenderer* self = FL_VIEW_RENDERER(widget);
  int size = 0;
  if (self->texture != nullptr) {
    size = orientation == GTK_ORIENTATION_HORIZONTAL
               ? gdk_texture_get_width(self->texture)
               : gdk_texture_get_height(self->texture);
  }

  *minimum = size;
  *natural = size;
  if (minimum_baseline != nullptr) {
    *minimum_baseline = -1;
  }
  if (natural_baseline != nullptr) {
    *natural_baseline = -1;
  }
}
#endif

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

#if !FLUTTER_LINUX_GTK4
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
#endif

static void fl_view_renderer_dispose(GObject* object) {
  FlViewRenderer* self = FL_VIEW_RENDERER(object);

#if FLUTTER_LINUX_GTK4
  if (self->native_texture_retry_source_id != 0) {
    g_source_remove(self->native_texture_retry_source_id);
    self->native_texture_retry_source_id = 0;
  }
  g_clear_object(&self->texture);
  g_clear_object(&self->accessible_child);
#endif
  g_clear_object(&self->render_context);
  g_clear_object(&self->engine);
  g_clear_pointer(&self->background_color, gdk_rgba_free);

  G_OBJECT_CLASS(fl_view_renderer_parent_class)->dispose(object);
}

static void fl_view_renderer_finalize(GObject* object) {
  FlViewRenderer* self = FL_VIEW_RENDERER(object);

  // The compositor is released here rather than in dispose() so it outlives a
  // forced dispose (e.g. gtk_widget_destroy()) and is only freed once the last
  // reference is dropped. This keeps it alive for the raster thread, which
  // holds a strong reference on the view (and thus this renderer) while
  // presenting.
  g_clear_object(&self->compositor);

  G_OBJECT_CLASS(fl_view_renderer_parent_class)->finalize(object);
}

static void fl_view_renderer_class_init(FlViewRendererClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_view_renderer_dispose;
  G_OBJECT_CLASS(klass)->finalize = fl_view_renderer_finalize;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_renderer_realize;
#if FLUTTER_LINUX_GTK4
  widget_class->size_allocate = fl_view_renderer_size_allocate;
  widget_class->snapshot = fl_view_renderer_snapshot;
  widget_class->measure = fl_view_renderer_measure;
#else
  widget_class->draw = fl_view_renderer_draw;
#endif

  fl_view_renderer_signals[SIGNAL_FIRST_FRAME] =
      g_signal_new("first-frame", fl_view_renderer_get_type(),
                   G_SIGNAL_RUN_LAST, 0, NULL, NULL, NULL, G_TYPE_NONE, 0);
  fl_view_renderer_signals[SIGNAL_RESIZE] = g_signal_new(
      "resize", fl_view_renderer_get_type(), G_SIGNAL_RUN_LAST, 0, nullptr,
      nullptr, nullptr, G_TYPE_NONE, 2, G_TYPE_INT, G_TYPE_INT);
}

static void fl_view_renderer_init(FlViewRenderer* self) {
  GdkRGBA default_background = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  self->background_color = gdk_rgba_copy(&default_background);
#if FLUTTER_LINUX_GTK4
  gtk_widget_set_overflow(GTK_WIDGET(self), GTK_OVERFLOW_HIDDEN);
#endif
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

#if FLUTTER_LINUX_GTK4
void fl_view_renderer_set_accessible_child(FlViewRenderer* renderer,
                                           GtkAccessible* accessible_child) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(renderer));
  g_return_if_fail(accessible_child == nullptr ||
                   GTK_IS_ACCESSIBLE(accessible_child));

  g_set_object(&renderer->accessible_child, accessible_child);
}
#endif

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
#else
// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer.h"

typedef struct {
  // Background color drawn behind the Flutter frame.
  GdkRGBA* background_color;

  // TRUE if have got the first frame to render.
  gboolean have_first_frame;
} FlViewRendererPrivate;

enum { SIGNAL_FIRST_FRAME, LAST_SIGNAL };

static guint fl_view_renderer_signals[LAST_SIGNAL];

G_DEFINE_TYPE_WITH_PRIVATE(FlViewRenderer,
                           fl_view_renderer,
                           GTK_TYPE_DRAWING_AREA)

// Default implementation for the abstract present_layers method. Subclasses
// must override this.
static void fl_view_renderer_present_layers_default(FlViewRenderer* self,
                                                    const FlutterLayer** layers,
                                                    size_t layers_count) {
  g_assert_not_reached();
}

static void fl_view_renderer_dispose(GObject* object) {
  FlViewRendererPrivate* priv = static_cast<FlViewRendererPrivate*>(
      fl_view_renderer_get_instance_private(FL_VIEW_RENDERER(object)));

  g_clear_pointer(&priv->background_color, gdk_rgba_free);

  G_OBJECT_CLASS(fl_view_renderer_parent_class)->dispose(object);
}

static void fl_view_renderer_class_init(FlViewRendererClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_view_renderer_dispose;

  klass->present_layers = fl_view_renderer_present_layers_default;

  fl_view_renderer_signals[SIGNAL_FIRST_FRAME] =
      g_signal_new("first-frame", fl_view_renderer_get_type(),
                   G_SIGNAL_RUN_LAST, 0, NULL, NULL, NULL, G_TYPE_NONE, 0);
}

static void fl_view_renderer_init(FlViewRenderer* self) {
  FlViewRendererPrivate* priv = static_cast<FlViewRendererPrivate*>(
      fl_view_renderer_get_instance_private(self));

  GdkRGBA default_background = {
      .red = 0.0, .green = 0.0, .blue = 0.0, .alpha = 1.0};
  priv->background_color = gdk_rgba_copy(&default_background);
}

void fl_view_renderer_set_background_color(FlViewRenderer* self,
                                           const GdkRGBA* color) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  FlViewRendererPrivate* priv = static_cast<FlViewRendererPrivate*>(
      fl_view_renderer_get_instance_private(self));

  gdk_rgba_free(priv->background_color);
  priv->background_color = gdk_rgba_copy(color);

  // Redraw so the new background color is shown.
  gtk_widget_queue_draw(GTK_WIDGET(self));
}

void fl_view_renderer_paint_background(FlViewRenderer* self, cairo_t* cr) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  FlViewRendererPrivate* priv = static_cast<FlViewRendererPrivate*>(
      fl_view_renderer_get_instance_private(self));

  // Don't bother drawing if fully transparent - the widget above this will
  // already be drawn by GTK.
  if (priv->background_color->red == 0 && priv->background_color->green == 0 &&
      priv->background_color->blue == 0 && priv->background_color->alpha == 0) {
    return;
  }

  gdk_cairo_set_source_rgba(cr, priv->background_color);
  cairo_paint(cr);
}

void fl_view_renderer_present_layers(FlViewRenderer* self,
                                     const FlutterLayer** layers,
                                     size_t layers_count) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  FlViewRendererClass* klass = FL_VIEW_RENDERER_GET_CLASS(self);
  klass->present_layers(self, layers, layers_count);
}

void fl_view_renderer_notify_frame(FlViewRenderer* self) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  FlViewRendererPrivate* priv = static_cast<FlViewRendererPrivate*>(
      fl_view_renderer_get_instance_private(self));

  if (!priv->have_first_frame) {
    priv->have_first_frame = TRUE;
    g_signal_emit(self, fl_view_renderer_signals[SIGNAL_FIRST_FRAME], 0);
  }
}
#endif
