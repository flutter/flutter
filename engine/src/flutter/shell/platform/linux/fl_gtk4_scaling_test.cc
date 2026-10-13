// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/linux_test.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <vector>
#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"
#include "flutter/shell/platform/linux/fl_render_texture_gtk4.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
#include "flutter/shell/platform/linux/fl_display_monitor.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_gtk.h"

namespace {

class FlGtk4ScalingTest : public flutter::testing::LinuxTest {};

struct ScaleCase {
  double scale;
  size_t width;
  size_t height;
};

TEST_F(FlGtk4ScalingTest, FractionalBackingDimensions) {
  // Fixed expectations catch accidental conversion to the integer GTK scale.
  const ScaleCase cases[] = {{1.0, 1000, 600},
                             {1.25, 1250, 750},
                             {1.5, 1500, 900},
                             {1.75, 1750, 1050},
                             {2.0, 2000, 1200}};
  for (const auto& test : cases) {
    SCOPED_TRACE(test.scale);
    EXPECT_EQ(fl_gtk_size_to_pixels(1000, test.scale), test.width);
    EXPECT_EQ(fl_gtk_size_to_pixels(600, test.scale), test.height);
  }
}

TEST_F(FlGtk4ScalingTest, OddDimensionsRoundToNearestPhysicalPixel) {
  const ScaleCase cases[] = {{1.0, 1001, 603},
                             {1.25, 1251, 754},
                             {1.5, 1502, 905},
                             {1.75, 1752, 1055},
                             {2.0, 2002, 1206}};
  for (const auto& test : cases) {
    SCOPED_TRACE(test.scale);
    EXPECT_EQ(fl_gtk_size_to_pixels(1001, test.scale), test.width);
    EXPECT_EQ(fl_gtk_size_to_pixels(603, test.scale), test.height);
    EXPECT_EQ(fl_gtk_size_to_pixels(0, test.scale), 0u);
  }
}

TEST_F(FlGtk4ScalingTest, WindowMetricsPreserveFractionalScaleChanges) {
  StartEngine();
  std::vector<FlutterWindowMetricsEvent> events;
  // This tests the engine metrics boundary, not GDK notification delivery.
  // MOCK_ENGINE_PROC retains its capture until the next replacement.
  // NOLINTNEXTLINE(clang-analyzer-core.StackAddressEscape)
  fl_engine_get_embedder_api(engine)->SendWindowMetricsEvent = MOCK_ENGINE_PROC(
      SendWindowMetricsEvent,
      ([&events](auto engine, const FlutterWindowMetricsEvent* event) {
        events.push_back(*event);
        return kSuccess;
      }));

  // The logical size stays fixed. The first three scales all round up to 2
  // through GDK's integer API; neither upward nor downward changes may be lost.
  const ScaleCase cases[] = {{1.25, 1251, 754},  {1.5, 1502, 905},
                             {1.75, 1752, 1055}, {1.5, 1502, 905},
                             {1.0, 1001, 603},   {2.0, 2002, 1206}};
  for (const auto& test : cases) {
    const size_t width = fl_gtk_size_to_pixels(1001, test.scale);
    const size_t height = fl_gtk_size_to_pixels(603, test.scale);
    fl_engine_send_window_metrics_event(engine, 99, 1, width, height, width,
                                        height, test.scale);
  }
  ASSERT_EQ(events.size(), std::size(cases));
  for (size_t i = 0; i < events.size(); i++) {
    SCOPED_TRACE(i);
    const auto& event = events[i];
    EXPECT_EQ(event.display_id, 99u);
    EXPECT_EQ(event.view_id, 1);
    EXPECT_DOUBLE_EQ(event.pixel_ratio, cases[i].scale);
    EXPECT_EQ(event.width, cases[i].width);
    EXPECT_EQ(event.height, cases[i].height);
    EXPECT_TRUE(event.has_constraints);
    EXPECT_EQ(event.min_width_constraint, cases[i].width);
    EXPECT_EQ(event.max_width_constraint, cases[i].width);
    EXPECT_EQ(event.min_height_constraint, cases[i].height);
    EXPECT_EQ(event.max_height_constraint, cases[i].height);
  }
}

TEST_F(FlGtk4ScalingTest, RuntimeScaleFallbackAndFractionalDiscovery) {
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_object_ref_sink(gtk_window_new()));
  gtk_window_present(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  GdkSurface* surface = gtk_native_get_surface(GTK_NATIVE(window));
  ASSERT_NE(surface, nullptr);
  FlGtkRuntimeApi unavailable = {};
  EXPECT_DOUBLE_EQ(fl_gtk_surface_get_scale_with_api(surface, &unavailable),
                   gdk_surface_get_scale_factor(surface));
  FlGtkRuntimeApi available = {};
  available.gdk_surface_get_scale = [](GdkSurface*) { return 1.25; };
  EXPECT_DOUBLE_EQ(fl_gtk_surface_get_scale_with_api(surface, &available),
                   1.25);
  available.gdk_surface_get_scale = [](GdkSurface*) { return 1.75; };
  EXPECT_DOUBLE_EQ(fl_gtk_surface_get_scale_with_api(surface, &available),
                   1.75);
  g_autoptr(GdkMonitor) monitor = GDK_MONITOR(g_list_model_get_item(
      gdk_display_get_monitors(gtk_widget_get_display(GTK_WIDGET(window))), 0));
  EXPECT_DOUBLE_EQ(fl_gtk_monitor_get_scale_with_api(monitor, &unavailable),
                   gdk_monitor_get_scale_factor(monitor));
  available.gdk_monitor_get_scale = [](GdkMonitor*) { return 1.5; };
  EXPECT_DOUBLE_EQ(fl_gtk_monitor_get_scale_with_api(monitor, &available), 1.5);
  gtk_window_destroy(window);
}

TEST_F(FlGtk4ScalingTest, ExternalWaylandScaleChanges) {
  if (g_strcmp0(g_getenv("FLUTTER_TEST_WAYLAND_SCALE"), "1") != 0) {
    GTEST_SKIP() << "Requires the private Wayland scale driver";
  }
  ASSERT_NE(fl_gtk_runtime_api_get()->gdk_surface_get_scale, nullptr);
  std::vector<FlutterEngineDisplay> displays;
  auto display_callback = MOCK_ENGINE_PROC(
      NotifyDisplayUpdate,
      ([&displays](auto, auto, const FlutterEngineDisplay* info, size_t count) {
        displays.clear();
        for (size_t i = 0; i < count; i++)
          displays.push_back(info[i]);
        return kSuccess;
      }));
  const bool content_sized =
      g_strcmp0(g_getenv("FLUTTER_TEST_WAYLAND_CONTENT_SIZE"), "1") == 0;
  if (content_sized) {
    fl_engine_get_embedder_api(engine)->NotifyDisplayUpdate = display_callback;
    StartEngine();
  }
  g_autoptr(FlView) view = content_sized ? fl_view_new_sized_to_content(engine)
                                         : fl_view_new(project);
  g_object_ref_sink(view);
  FlEngine* view_engine = fl_view_get_engine(view);
  fl_engine_get_embedder_api(view_engine)->NotifyDisplayUpdate =
      display_callback;
  std::vector<FlutterWindowMetricsEvent> metrics;
  fl_engine_get_embedder_api(view_engine)->SendWindowMetricsEvent =
      MOCK_ENGINE_PROC(
          SendWindowMetricsEvent,
          ([&metrics](auto, const FlutterWindowMetricsEvent* event) {
            metrics.push_back(*event);
            return kSuccess;
          }));
  std::vector<FlutterPointerEvent> pointers;
  std::vector<FlutterPointerEvent> scrolls;
  fl_engine_get_embedder_api(view_engine)->SendPointerEvent = MOCK_ENGINE_PROC(
      SendPointerEvent,
      ([&pointers, &scrolls](auto, const FlutterPointerEvent* events,
                             size_t count) {
        for (size_t i = 0; i < count; i++) {
          if (events[i].phase == kDown)
            pointers.push_back(events[i]);
          if (events[i].signal_kind == kFlutterPointerSignalKindScroll)
            scrolls.push_back(events[i]);
        }
        return kSuccess;
      }));
  g_autoptr(GtkWindow) window = GTK_WINDOW(g_object_ref_sink(gtk_window_new()));
  gtk_window_set_decorated(window, FALSE);
  gtk_window_set_title(window, "Flutter fractional scale probe");
  gtk_window_set_default_size(window, 1001, 603);
  gtk_window_set_child(window, GTK_WIDGET(view));
  g_autoptr(GBytes) pixels =
      g_bytes_new_take(g_malloc0(1001 * 603 * 4), 1001 * 603 * 4);
  g_autoptr(GdkTexture) texture =
      gdk_memory_texture_new(1001, 603, GDK_MEMORY_DEFAULT, pixels, 1001 * 4);
  fl_render_texture_gtk4_set_texture(FL_RENDER_TEXTURE_GTK4(view->render_area),
                                     texture);
  gtk_window_present(window);
  const double scales[] = {1, 1.25, 1.5, 1.75, 1.5, 1,
                           2, 1,    1.5, 1.5,  1.5, 1.5};
  FlutterEngineDisplayId first_display_id = 0, second_display_id = 0;
  for (size_t phase = 0; phase < std::size(scales); phase++) {
    const gint64 deadline = g_get_monotonic_time() + 15 * G_TIME_SPAN_SECOND;
    const int logical_width = phase == 8 ? 997 : phase >= 9 ? 991 : 1001;
    const int logical_height = phase == 8 ? 599 : phase >= 9 ? 587 : 603;
    bool ready = false;
    while (g_get_monotonic_time() < deadline) {
      while (g_main_context_iteration(nullptr, FALSE)) {
      }
      if (!metrics.empty() && metrics.back().pixel_ratio == scales[phase] &&
          gtk_widget_get_width(view->render_area) == logical_width &&
          gtk_widget_get_height(view->render_area) == logical_height &&
          (phase != 10 || metrics.back().display_id == second_display_id) &&
          (phase != 11 || metrics.back().display_id == first_display_id)) {
        ready = true;
        break;
      }
      g_usleep(1000);
    }
    ASSERT_TRUE(ready) << "Missing scale notification at phase " << phase
                       << " metrics " << metrics.size() << " surface scale "
                       << fl_gtk_widget_get_scale(view->render_area)
                       << " width " << gtk_widget_get_width(view->render_area);
    const auto event = metrics.back();
    if (content_sized) {
      EXPECT_EQ(event.width, 1u);
      EXPECT_EQ(event.height, 1u);
      EXPECT_EQ(event.min_width_constraint, 1u);
      EXPECT_EQ(event.min_height_constraint, 1u);
      EXPECT_EQ(event.max_width_constraint, SIZE_MAX);
      EXPECT_EQ(event.max_height_constraint, SIZE_MAX);
    } else {
      EXPECT_EQ(event.width,
                fl_gtk_size_to_pixels(gtk_widget_get_width(view->render_area),
                                      scales[phase]));
      EXPECT_EQ(event.height,
                fl_gtk_size_to_pixels(gtk_widget_get_height(view->render_area),
                                      scales[phase]));
    }
    EXPECT_DOUBLE_EQ(fl_gtk_widget_get_scale(view->render_area), scales[phase]);
    GdkSurface* native_surface = gtk_native_get_surface(GTK_NATIVE(window));
    GdkMonitor* native_monitor = gdk_display_get_monitor_at_surface(
        gtk_widget_get_display(GTK_WIDGET(window)), native_surface);
    ASSERT_NE(native_monitor, nullptr);
    const auto expected_display_id = fl_display_monitor_get_display_id(
        fl_engine_get_display_monitor(view_engine), native_monitor);
    EXPECT_EQ(event.display_id, expected_display_id);
    auto current_display =
        std::find_if(displays.begin(), displays.end(), [&](const auto& info) {
          return info.display_id == expected_display_id;
        });
    ASSERT_NE(current_display, displays.end());
    GdkRectangle monitor_geometry;
    gdk_monitor_get_geometry(native_monitor, &monitor_geometry);
    const double monitor_scale = fl_gtk_monitor_get_scale(native_monitor);
    EXPECT_DOUBLE_EQ(current_display->device_pixel_ratio, monitor_scale);
    EXPECT_EQ(current_display->width,
              fl_gtk_size_to_pixels(monitor_geometry.width, monitor_scale));
    EXPECT_EQ(current_display->height,
              fl_gtk_size_to_pixels(monitor_geometry.height, monitor_scale));
    if (phase == 0)
      first_display_id = event.display_id;
    if (phase == 6) {
      second_display_id = event.display_id;
      EXPECT_NE(first_display_id, second_display_id);
    }
    g_print("DISPLAY_PHASE %zu %llu %.6f %zu %zu\n", phase,
            static_cast<unsigned long long>(event.display_id), monitor_scale,
            current_display->width, current_display->height);

    for (auto orientation :
         {GTK_ORIENTATION_HORIZONTAL, GTK_ORIENTATION_VERTICAL}) {
      int minimum, natural;
      gtk_widget_measure(view->render_area, orientation, -1, &minimum, &natural,
                         nullptr, nullptr);
      EXPECT_EQ(minimum, 0);
      EXPECT_EQ(natural,
                ceil((orientation == GTK_ORIENTATION_HORIZONTAL ? 1001 : 603) /
                     scales[phase]));
    }
    FlutterSemanticsFlags flags = {};
    FlutterSemanticsNode2 node = {};
    node.id = 0;
    node.flags2 = &flags;
    node.label = "Fractional bounds";
    node.rect = {125, 75, 375, 225};
    FlutterSemanticsNode2* nodes[] = {&node};
    FlutterSemanticsUpdate2 update = {};
    update.view_id = fl_view_get_id(view);
    update.node_count = 1;
    update.nodes = nodes;
    fl_view_gtk4_accessibility_handle_update(view->accessibility_backend,
                                             &update);
    g_autoptr(GtkAccessible) root =
        fl_view_gtk4_accessibility_ref_native_root_for_testing(
            view->accessibility_backend);
    int x, y, width, height;
    ASSERT_TRUE(fl_view_gtk4_accessibility_get_native_bounds_for_testing(
        root, &x, &y, &width, &height));
    EXPECT_EQ(x, floor(125 / scales[phase]));
    EXPECT_EQ(y, floor(75 / scales[phase]));
    EXPECT_EQ(width, ceil(375 / scales[phase]) - floor(125 / scales[phase]));
    EXPECT_EQ(height, ceil(225 / scales[phase]) - floor(75 / scales[phase]));
    g_print("SCALE_PHASE %zu %.2f %zu %zu\n", phase, scales[phase], event.width,
            event.height);
    fflush(stdout);
    const size_t previous_clicks = phase;
    const gint64 pointer_deadline =
        g_get_monotonic_time() + 5 * G_TIME_SPAN_SECOND;
    while (pointers.size() == previous_clicks &&
           g_get_monotonic_time() < pointer_deadline) {
      g_main_context_iteration(nullptr, FALSE);
      g_usleep(1000);
    }
    ASSERT_EQ(pointers.size(), previous_clicks + 1);
    double native_x = 0, native_y = 0;
    GdkSurface* surface = gtk_native_get_surface(GTK_NATIVE(window));
    GdkDevice* device = gdk_seat_get_pointer(gdk_display_get_default_seat(
        gtk_widget_get_display(GTK_WIDGET(window))));
    gdk_surface_get_device_position(surface, device, &native_x, &native_y,
                                    nullptr);
    g_print("POINTER_NATIVE %.2f %.2f PHYSICAL %.2f %.2f\n", native_x, native_y,
            pointers.back().x, pointers.back().y);
    EXPECT_NEAR(pointers.back().x, 100 * scales[phase], 1);
    EXPECT_NEAR(pointers.back().y, 80 * scales[phase], 1);
    while (scrolls.size() <= phase &&
           g_get_monotonic_time() < pointer_deadline) {
      g_main_context_iteration(nullptr, FALSE);
      g_usleep(1000);
    }
    ASSERT_EQ(scrolls.size(), phase + 1);
    EXPECT_NEAR(scrolls.back().x, 100 * scales[phase], 1);
    EXPECT_NEAR(scrolls.back().y, 80 * scales[phase], 1);
    EXPECT_NEAR(scrolls.back().scroll_delta_y, 53 * scales[phase], 0.01);
    g_print("POINTER_PHASE %zu\n", phase);
    fflush(stdout);
    // Wait for the driver to change scale before evaluating the next phase.
    if (phase + 1 < std::size(scales)) {
      while (g_get_monotonic_time() < deadline &&
             fl_gtk_widget_get_scale(view->render_area) == scales[phase] &&
             gtk_widget_get_width(view->render_area) == logical_width &&
             gtk_widget_get_height(view->render_area) == logical_height &&
             metrics.back().display_id == event.display_id) {
        g_main_context_iteration(nullptr, FALSE);
        g_usleep(1000);
      }
    }
  }
  gtk_window_destroy(window);
  while (g_main_context_iteration(nullptr, FALSE)) {
  }
  EXPECT_EQ(view->scale_surface, nullptr);
  EXPECT_EQ(view->scale_changed_id, 0u);
  EXPECT_EQ(view->enter_monitor_id, 0u);
  EXPECT_EQ(view->leave_monitor_id, 0u);
}

}  // namespace
