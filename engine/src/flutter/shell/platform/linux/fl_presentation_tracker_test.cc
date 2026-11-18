// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Included first as it collides with the X11 headers.
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "gtest/gtest.h"

#include <wayland-client.h>

#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_presentation_tracker.h"
#include "flutter/shell/platform/linux/testing/mock_wayland.h"

using flutter::testing::fl_mock_wayland_free_surface;
using flutter::testing::fl_mock_wayland_get_last_callback;
using flutter::testing::fl_mock_wayland_get_surface;
using flutter::testing::fl_mock_wayland_send_callback_done;

class FlPresentationTrackerTest : public flutter::testing::LinuxTest {
 protected:
  ::testing::NiceMock<flutter::testing::MockWayland> wayland;
};

// Each commit requests exactly one frame callback, and completing it releases
// the Wayland object.
TEST_F(FlPresentationTrackerTest, RecordsOneCallbackPerCommit) {
  g_autoptr(FlPresentationTracker) tracker =
      fl_presentation_tracker_new(engine);
  ASSERT_NE(tracker, nullptr);
  struct wl_surface* surface = fl_mock_wayland_get_surface();

  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_callback")));
  fl_presentation_tracker_record_commit(tracker, surface);

  struct wl_callback* callback = fl_mock_wayland_get_last_callback();
  ASSERT_NE(callback, nullptr);

  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_callback")));
  fl_mock_wayland_send_callback_done(callback, 0);

  fl_mock_wayland_free_surface(surface);
}

// The commit-to-frame latency reported by frame callbacks reaches the engine
// and moves the presentation phase.
TEST_F(FlPresentationTrackerTest, ReportsLatencyToTheEngine) {
  StartEngine();

  g_autoptr(FlPresentationTracker) tracker =
      fl_presentation_tracker_new(engine);
  ASSERT_NE(tracker, nullptr);
  struct wl_surface* surface = fl_mock_wayland_get_surface();

  for (int i = 0; i < 9; i++) {
    EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_callback")));
    fl_presentation_tracker_record_commit(tracker, surface);

    struct wl_callback* callback = fl_mock_wayland_get_last_callback();
    ASSERT_NE(callback, nullptr);

    EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_callback")));
    // The engine's default interval is 60Hz; present the frame almost a full
    // refresh later, as a compositor that misses the deadline does.
    g_usleep(16667);
    fl_mock_wayland_send_callback_done(callback, 0);
  }

  EXPECT_GT(fl_engine_get_presentation_phase(engine), 0);
  fl_mock_wayland_free_surface(surface);
}

// No callback is requested while feedback is paused for a synchronized resize.
TEST_F(FlPresentationTrackerTest, DisabledDoesNotRequestCallbacks) {
  g_autoptr(FlPresentationTracker) tracker =
      fl_presentation_tracker_new(engine);
  ASSERT_NE(tracker, nullptr);
  struct wl_surface* surface = fl_mock_wayland_get_surface();

  fl_presentation_tracker_set_enabled(tracker, FALSE);

  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_callback"))).Times(0);
  fl_presentation_tracker_record_commit(tracker, surface);

  fl_mock_wayland_free_surface(surface);
}

// A null surface (a renderer that is not on Wayland) is ignored.
TEST_F(FlPresentationTrackerTest, NullSurfaceIsIgnored) {
  g_autoptr(FlPresentationTracker) tracker =
      fl_presentation_tracker_new(engine);
  ASSERT_NE(tracker, nullptr);

  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_callback"))).Times(0);
  fl_presentation_tracker_record_commit(tracker, nullptr);
}

// Resetting the tracker releases callbacks that have not been answered.
TEST_F(FlPresentationTrackerTest, ResetReleasesPendingCallbacks) {
  g_autoptr(FlPresentationTracker) tracker =
      fl_presentation_tracker_new(engine);
  ASSERT_NE(tracker, nullptr);
  struct wl_surface* surface = fl_mock_wayland_get_surface();

  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_callback"))).Times(2);
  fl_presentation_tracker_record_commit(tracker, surface);
  fl_presentation_tracker_record_commit(tracker, surface);

  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_callback"))).Times(2);
  fl_presentation_tracker_reset(tracker);

  fl_mock_wayland_free_surface(surface);
}

// A compositor that stops answering callbacks must not make the pending table
// grow without bound.
TEST_F(FlPresentationTrackerTest, BoundsOutstandingCallbacks) {
  g_autoptr(FlPresentationTracker) tracker =
      fl_presentation_tracker_new(engine);
  ASSERT_NE(tracker, nullptr);
  struct wl_surface* surface = fl_mock_wayland_get_surface();

  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_callback")))
      .Times(256);
  for (int i = 0; i < 300; i++) {
    fl_presentation_tracker_record_commit(tracker, surface);
  }

  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_callback")))
      .Times(256);
  fl_presentation_tracker_reset(tracker);

  fl_mock_wayland_free_surface(surface);
}
