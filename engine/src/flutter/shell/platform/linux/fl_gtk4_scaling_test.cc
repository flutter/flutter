// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/linux_test.h"

#include <vector>

#include "flutter/shell/platform/embedder/test_utils/proc_table_replacement.h"
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

}  // namespace
