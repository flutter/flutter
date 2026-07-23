// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_view_renderer_vulkan.h"

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_vulkan_manager.h"

struct _FlViewRendererVulkan {
  FlViewRenderer parent_instance;

  // Engine this widget is rendering.
  FlEngine* engine;

  // TRUE if the view size should be controlled by Flutter.
  gboolean sized_to_content;

  // Frame clock tick callback that drives parent-surface commits. Non-zero
  // once the widget is realized. See the tick callback comment below.
  guint tick_cb_id;
};

G_DEFINE_TYPE(FlViewRendererVulkan,
              fl_view_renderer_vulkan,
              fl_view_renderer_get_type())

// Positions the Vulkan subsurface at this widget's offset within the toplevel,
// so the swapchain renders only within the view (below the header bar), not
// over the whole decorated window. A no-op on X11, where there is no
// subsurface.
static void update_subsurface_position(FlViewRendererVulkan* self) {
  FlVulkanManager* vulkan_manager = fl_engine_get_vulkan_manager(self->engine);
  if (vulkan_manager == nullptr) {
    return;
  }
  GtkWidget* widget = GTK_WIDGET(self);
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  gint content_x = 0, content_y = 0;
  gtk_widget_translate_coordinates(widget, toplevel, 0, 0, &content_x,
                                   &content_y);
  fl_vulkan_manager_set_subsurface_position(vulkan_manager, content_x,
                                            content_y);
}

// Frame clock tick callback.
//
// Impeller renders and presents into a synchronized wl_subsurface, whose buffer
// only becomes visible when the parent (toplevel) surface commits. GTK does not
// draw the parent on its own while only the Vulkan content changes, so without
// this the presented frames would never reach the screen. Keeping a tick
// callback registered holds the frame clock running and queues a draw each
// frame; the draw handler commits the parent, flushing the subsurface's latest
// frame. The redraw is cheap because the draw handler only paints the
// background.
static gboolean tick_cb(GtkWidget* widget,
                        GdkFrameClock* frame_clock,
                        gpointer user_data) {
  gtk_widget_queue_draw(widget);
  return G_SOURCE_CONTINUE;
}

// Implements GtkWidget::realize.
static void fl_view_renderer_vulkan_realize(GtkWidget* widget) {
  FlViewRendererVulkan* self = FL_VIEW_RENDERER_VULKAN(widget);

  GTK_WIDGET_CLASS(fl_view_renderer_vulkan_parent_class)->realize(widget);

  // The toplevel window is used because GTK child widgets do not have their
  // own native windows on Wayland; the Vulkan manager creates a subsurface of
  // the toplevel and positions it at this widget's content area.
  GtkWidget* toplevel = gtk_widget_get_toplevel(widget);
  GdkWindow* window = gtk_widget_get_window(toplevel);
  if (window == nullptr) {
    g_warning("No GdkWindow available for the Vulkan renderer");
    return;
  }

  FlVulkanManager* vulkan_manager = fl_vulkan_manager_new(window);
  if (vulkan_manager == nullptr) {
    g_warning("Vulkan manager creation failed");
    return;
  }

  // Transfer ownership to the engine (it takes a ref); the engine renders
  // directly to the swapchain the manager owns.
  fl_engine_set_vulkan_manager(self->engine, vulkan_manager);
  g_object_unref(vulkan_manager);

  update_subsurface_position(self);

  // Drive parent-surface commits so the synchronized subsurface's frames reach
  // the screen.
  if (self->tick_cb_id == 0) {
    self->tick_cb_id =
        gtk_widget_add_tick_callback(widget, tick_cb, self, nullptr);
  }
}

// Implements GtkWidget::size-allocate.
static void fl_view_renderer_vulkan_size_allocate(GtkWidget* widget,
                                                  GtkAllocation* allocation) {
  GTK_WIDGET_CLASS(fl_view_renderer_vulkan_parent_class)
      ->size_allocate(widget, allocation);

  // Keep the subsurface aligned with the view as the layout changes.
  update_subsurface_position(FL_VIEW_RENDERER_VULKAN(widget));
}

// Implements GtkWidget::draw.
static gboolean fl_view_renderer_vulkan_draw(GtkWidget* widget, cairo_t* cr) {
  FlViewRendererVulkan* self = FL_VIEW_RENDERER_VULKAN(widget);

  // Painting the background gives the parent surface committed content and, on
  // Wayland, flushes the synchronized subsurface's latest presented frame.
  // Impeller presents the Flutter content into the swapchain itself, so there
  // is nothing else to draw here.
  fl_view_renderer_paint_background(FL_VIEW_RENDERER(self), cr);
  fl_view_renderer_notify_frame(FL_VIEW_RENDERER(self));
  return TRUE;
}

// Implements FlViewRenderer::present_layers.
static void fl_view_renderer_vulkan_present_layers(FlViewRenderer* renderer,
                                                   const FlutterLayer** layers,
                                                   size_t layers_count) {
  // In KHR swapchain mode Impeller owns presentation, so the compositor
  // present callback is not used for the Flutter content. This is implemented
  // only to satisfy the abstract method; a queued redraw ensures the parent
  // surface commits if this is ever reached.
  gtk_widget_queue_draw(GTK_WIDGET(renderer));
}

static void fl_view_renderer_vulkan_dispose(GObject* object) {
  FlViewRendererVulkan* self = FL_VIEW_RENDERER_VULKAN(object);

  if (self->tick_cb_id != 0) {
    gtk_widget_remove_tick_callback(GTK_WIDGET(self), self->tick_cb_id);
    self->tick_cb_id = 0;
  }
  g_clear_object(&self->engine);

  G_OBJECT_CLASS(fl_view_renderer_vulkan_parent_class)->dispose(object);
}

static void fl_view_renderer_vulkan_class_init(
    FlViewRendererVulkanClass* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_view_renderer_vulkan_dispose;

  GtkWidgetClass* widget_class = GTK_WIDGET_CLASS(klass);
  widget_class->realize = fl_view_renderer_vulkan_realize;
  widget_class->size_allocate = fl_view_renderer_vulkan_size_allocate;
  widget_class->draw = fl_view_renderer_vulkan_draw;

  FlViewRendererClass* renderer_class = FL_VIEW_RENDERER_CLASS(klass);
  renderer_class->present_layers = fl_view_renderer_vulkan_present_layers;
}

static void fl_view_renderer_vulkan_init(FlViewRendererVulkan* self) {}

FlViewRendererVulkan* fl_view_renderer_vulkan_new(FlEngine* engine,
                                                  gboolean sized_to_content) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlViewRendererVulkan* self = FL_VIEW_RENDERER_VULKAN(
      g_object_new(fl_view_renderer_vulkan_get_type(), nullptr));
  self->engine = FL_ENGINE(g_object_ref(engine));
  self->sized_to_content = sized_to_content;
  return self;
}
