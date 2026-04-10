// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"

struct _FlRenderTextureGtk4 {
  GtkWidget parent_instance;

  GdkTexture* texture;
  gboolean flip_y;
};

enum {
  SIGNAL_RESIZE,
  LAST_SIGNAL,
};

static guint fl_render_texture_gtk4_signals[LAST_SIGNAL];

G_DEFINE_TYPE(FlRenderTextureGtk4, fl_render_texture_gtk4, GTK_TYPE_WIDGET)

static void fl_render_texture_gtk4_dispose(GObject* object) {
  FlRenderTextureGtk4* self = FL_RENDER_TEXTURE_GTK4(object);

  g_clear_object(&self->texture);

  G_OBJECT_CLASS(fl_render_texture_gtk4_parent_class)->dispose(object);
}

static void fl_render_texture_gtk4_measure(GtkWidget* widget,
                                           GtkOrientation orientation,
                                           int for_size,
                                           int* minimum,
                                           int* natural,
                                           int* minimum_baseline,
                                           int* natural_baseline) {
  (void)widget;
  (void)orientation;
  (void)for_size;

  *minimum = 0;
  *natural = 0;
  if (minimum_baseline != nullptr) {
    *minimum_baseline = -1;
  }
  if (natural_baseline != nullptr) {
    *natural_baseline = -1;
  }
}

static void fl_render_texture_gtk4_snapshot(GtkWidget* widget,
                                            GtkSnapshot* snapshot) {
  FlRenderTextureGtk4* self = FL_RENDER_TEXTURE_GTK4(widget);

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
  gtk_snapshot_append_texture(snapshot, GDK_TEXTURE(self->texture), &bounds);
  if (self->flip_y) {
    gtk_snapshot_restore(snapshot);
  }
}

static void fl_render_texture_gtk4_size_allocate(GtkWidget* widget,
                                                 int width,
                                                 int height,
                                                 int baseline) {
  GTK_WIDGET_CLASS(fl_render_texture_gtk4_parent_class)
      ->size_allocate(widget, width, height, baseline);

  g_signal_emit(widget, fl_render_texture_gtk4_signals[SIGNAL_RESIZE], 0, width,
                height);
}

static void fl_render_texture_gtk4_class_init(FlRenderTextureGtk4Class* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_render_texture_gtk4_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->measure = fl_render_texture_gtk4_measure;
  widget_class->snapshot = fl_render_texture_gtk4_snapshot;
  widget_class->size_allocate = fl_render_texture_gtk4_size_allocate;

  fl_render_texture_gtk4_signals[SIGNAL_RESIZE] = g_signal_new(
      "resize", fl_render_texture_gtk4_get_type(), G_SIGNAL_RUN_LAST, 0,
      nullptr, nullptr, nullptr, G_TYPE_NONE, 2, G_TYPE_INT, G_TYPE_INT);
}

static void fl_render_texture_gtk4_init(FlRenderTextureGtk4* self) {
  gtk_widget_set_overflow(GTK_WIDGET(self), GTK_OVERFLOW_HIDDEN);
}

GtkWidget* fl_render_texture_gtk4_new(void) {
  return GTK_WIDGET(g_object_new(fl_render_texture_gtk4_get_type(), nullptr));
}

void fl_render_texture_gtk4_set_flip_y(FlRenderTextureGtk4* self,
                                       gboolean flip_y) {
  g_return_if_fail(FL_IS_RENDER_TEXTURE_GTK4(self));

  if (self->flip_y == flip_y) {
    return;
  }

  self->flip_y = flip_y;
  gtk_widget_queue_draw(GTK_WIDGET(self));
}

void fl_render_texture_gtk4_set_texture(FlRenderTextureGtk4* self,
                                        GdkTexture* texture) {
  g_return_if_fail(FL_IS_RENDER_TEXTURE_GTK4(self));
  g_return_if_fail(texture == nullptr || GDK_IS_TEXTURE(texture));

  if (texture != nullptr) {
    g_object_ref(texture);
  }
  g_clear_object(&self->texture);
  self->texture = texture;
  gtk_widget_queue_draw(GTK_WIDGET(self));
}
