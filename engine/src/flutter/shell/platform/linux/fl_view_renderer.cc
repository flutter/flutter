// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer.h"

typedef struct {
  // Background color drawn behind the Flutter frame.
  GdkRGBA* background_color;
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

void fl_view_renderer_emit_first_frame(FlViewRenderer* self) {
  g_return_if_fail(FL_IS_VIEW_RENDERER(self));

  g_signal_emit(self, fl_view_renderer_signals[SIGNAL_FIRST_FRAME], 0);
}
