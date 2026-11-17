// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_FIXTURES_COMPUTE_SNAPSHOT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_FIXTURES_COMPUTE_SNAPSHOT_H_

#include <gtk/gtk.h>

// Test runner helper. Call watch_compute_snapshot(GTK_WIDGET(view)) after
// realizing the FlView. The driver supplies both paths. Capture GTK's widget
// output, independently of the Dart texture readback, after dispatch completes.
inline void watch_compute_snapshot(GtkWidget* view) {
  if (g_getenv("COMPUTE_PROBE_SNAPSHOT") == nullptr) {
    return;
  }
  if (g_getenv("COMPUTE_PROBE_QUIT") != nullptr) {
    g_timeout_add_full(
        G_PRIORITY_DEFAULT, 100,
        [](gpointer data) -> gboolean {
          if (!g_file_test(g_getenv("COMPUTE_PROBE_QUIT"),
                           G_FILE_TEST_IS_REGULAR)) {
            return G_SOURCE_CONTINUE;
          }
          GtkRoot* root = gtk_widget_get_root(GTK_WIDGET(data));
          if (GTK_IS_WINDOW(root)) {
            gtk_window_destroy(GTK_WINDOW(root));
          }
          GApplication* app = g_application_get_default();
          if (app) {
            g_application_quit(app);
          }
          return G_SOURCE_REMOVE;
        },
        g_object_ref(view), g_object_unref);
  }
  g_timeout_add_full(
      G_PRIORITY_DEFAULT, 100,
      [](gpointer data) -> gboolean {
        const char* report = g_getenv("COMPUTE_PROBE_OUTPUT");
        if (!report || !g_file_test(report, G_FILE_TEST_IS_REGULAR)) {
          return G_SOURCE_CONTINUE;
        }
        auto* widget = GTK_WIDGET(data);
        const int width = gtk_widget_get_width(widget);
        const int height = gtk_widget_get_height(widget);
        GtkNative* native = gtk_widget_get_native(widget);
        if (!native || width <= 0 || height <= 0) {
          return G_SOURCE_CONTINUE;
        }
        GskRenderer* renderer = gtk_native_get_renderer(native);
        if (!renderer) {
          return G_SOURCE_CONTINUE;
        }
        g_autoptr(GdkPaintable) paintable = gtk_widget_paintable_new(widget);
        GtkSnapshot* snapshot = gtk_snapshot_new();
        gdk_paintable_snapshot(paintable, GDK_SNAPSHOT(snapshot), width,
                               height);
        GskRenderNode* node = gtk_snapshot_free_to_node(snapshot);
        if (!node) {
          return G_SOURCE_CONTINUE;
        }
        graphene_rect_t bounds = GRAPHENE_RECT_INIT(
            0, 0, static_cast<float>(width), static_cast<float>(height));
        // GTK 4.22's renderer omits nodes already assigned to an offload
        // subsurface of its own window, even in render_texture(). Capture the
        // same scene with the same renderer class, without that surface
        // association. This checks imported pixels, not compositor scanout.
        g_autoptr(GskRenderer) capture =
            GSK_RENDERER(g_object_new(G_OBJECT_TYPE(renderer), nullptr));
        g_autoptr(GError) error = nullptr;
        if (!gsk_renderer_realize(capture, nullptr, &error)) {
          g_printerr("COMPUTE_CAPTURE_ERROR %s\n", error->message);
          gsk_render_node_unref(node);
          return G_SOURCE_REMOVE;
        }
        g_autoptr(GdkTexture) texture =
            gsk_renderer_render_texture(capture, node, &bounds);
        gsk_render_node_unref(node);
        if (!texture) {
          gsk_renderer_unrealize(capture);
          return G_SOURCE_CONTINUE;
        }
        g_printerr("COMPUTE_GTK_CAPTURE_RENDERER %s\n",
                   G_OBJECT_TYPE_NAME(capture));
        const bool saved = gdk_texture_save_to_png(
            texture, g_getenv("COMPUTE_PROBE_SNAPSHOT"));
        gsk_renderer_unrealize(capture);
        g_printerr("\nCOMPUTE_GTK_RENDERER %s\n", G_OBJECT_TYPE_NAME(renderer));
        return saved ? G_SOURCE_REMOVE : G_SOURCE_CONTINUE;
      },
      g_object_ref(view), g_object_unref);
}

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_FIXTURES_COMPUTE_SNAPSHOT_H_
