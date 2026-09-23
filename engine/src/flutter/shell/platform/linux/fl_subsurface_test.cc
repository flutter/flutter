// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <wayland-client.h>

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_wayland_display.h"
#include "flutter/shell/platform/linux/testing/wayland_test.h"

using flutter::testing::fl_mock_wayland_free_surface;
using flutter::testing::fl_mock_wayland_get_display;
using flutter::testing::fl_mock_wayland_get_surface;

class FlSubsurfaceTest : public flutter::testing::WaylandTest {
 protected:
  void SetUp() override {
    display_ = fl_wayland_display_open(fl_mock_wayland_get_display());
    ASSERT_NE(display_, nullptr);
    parent_surface_ = fl_mock_wayland_get_surface();
  }

  void TearDown() override {
    g_clear_object(&display_);
    fl_mock_wayland_free_surface(parent_surface_);
  }

  FlSubsurface* CreateSubsurface() {
    return fl_wayland_display_create_subsurface(display_, parent_surface_);
  }

 private:
  FlWaylandDisplay* display_ = nullptr;
  struct wl_surface* parent_surface_ = nullptr;
};

TEST_F(FlSubsurfaceTest, Create) {
  // A surface and a subsurface attached to the parent surface are created.
  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_surface")));
  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_subsurface")));

  g_autoptr(FlSubsurface) subsurface = CreateSubsurface();
  ASSERT_NE(subsurface, nullptr);
  EXPECT_NE(fl_subsurface_get_surface(subsurface), nullptr);
}

// Input is handled by the parent (GTK) surface, so the subsurface is given an
// empty input region to let events pass through to it.
TEST_F(FlSubsurfaceTest, EmptyInputRegion) {
  ::testing::InSequence sequence;
  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_region")));
  EXPECT_CALL(wayland, Request(::testing::StrEq("wl_surface"),
                               WL_SURFACE_SET_INPUT_REGION));
  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_region")));

  g_autoptr(FlSubsurface) subsurface = CreateSubsurface();
  ASSERT_NE(subsurface, nullptr);
}

// The subsurface is synchronized with the parent surface, so its contents stay
// in step with the GTK window.
TEST_F(FlSubsurfaceTest, Synchronized) {
  EXPECT_CALL(wayland, Request(::testing::StrEq("wl_subsurface"),
                               WL_SUBSURFACE_SET_SYNC));

  g_autoptr(FlSubsurface) subsurface = CreateSubsurface();
  ASSERT_NE(subsurface, nullptr);
}

TEST_F(FlSubsurfaceTest, SetPosition) {
  g_autoptr(FlSubsurface) subsurface = CreateSubsurface();
  ASSERT_NE(subsurface, nullptr);

  EXPECT_CALL(wayland, Request(::testing::StrEq("wl_subsurface"),
                               WL_SUBSURFACE_SET_POSITION))
      .Times(2);

  fl_subsurface_set_position(subsurface, 1, 2);
  fl_subsurface_set_position(subsurface, 3, 4);
}

// The Wayland objects are released when the subsurface is destroyed.
TEST_F(FlSubsurfaceTest, Destroy) {
  FlSubsurface* subsurface = CreateSubsurface();
  ASSERT_NE(subsurface, nullptr);

  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_subsurface")));
  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_surface")));

  g_object_unref(subsurface);
}
