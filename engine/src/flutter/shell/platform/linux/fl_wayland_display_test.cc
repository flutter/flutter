// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gdk/gdkwayland.h>
#include <wayland-client.h>

#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_wayland_display.h"
#include "flutter/shell/platform/linux/testing/wayland_test.h"

using flutter::testing::fl_mock_wayland_free_surface;
using flutter::testing::fl_mock_wayland_get_display;
using flutter::testing::fl_mock_wayland_get_surface;

class FlWaylandDisplayTest : public flutter::testing::WaylandTest {};

TEST_F(FlWaylandDisplayTest, Open) {
  // The registry is created to bind the globals, then released once they have
  // been received.
  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_registry")));
  EXPECT_CALL(wayland, DestroyObject(::testing::StrEq("wl_registry")));

  g_autoptr(FlWaylandDisplay) display =
      fl_wayland_display_open(fl_mock_wayland_get_display());
  EXPECT_NE(display, nullptr);
  EXPECT_FALSE(HasReceivedLogLevel(G_LOG_LEVEL_WARNING));
}

// The display can't be used if the compositor doesn't support subsurfaces.
TEST_F(FlWaylandDisplayTest, OpenMissingSubcompositor) {
  wayland.has_subcompositor = false;

  FlWaylandDisplay* display =
      fl_wayland_display_open(fl_mock_wayland_get_display());
  EXPECT_EQ(display, nullptr);
  EXPECT_TRUE(HasReceivedLogLevel(G_LOG_LEVEL_WARNING));
}

TEST_F(FlWaylandDisplayTest, OpenMissingCompositor) {
  wayland.has_compositor = false;

  FlWaylandDisplay* display =
      fl_wayland_display_open(fl_mock_wayland_get_display());
  EXPECT_EQ(display, nullptr);
  EXPECT_TRUE(HasReceivedLogLevel(G_LOG_LEVEL_WARNING));
}

// Asking for the Wayland display of a display that isn't Wayland is a
// programmer error.
TEST_F(FlWaylandDisplayTest, GetForNonWaylandDisplay) {
  // Tests are run on X11 (gdk_display_get_default() is mocked, so the display
  // manager is used to get the display actually in use).
  GdkDisplay* gdk_display =
      gdk_display_manager_get_default_display(gdk_display_manager_get());
  ASSERT_FALSE(GDK_IS_WAYLAND_DISPLAY(gdk_display));

  EXPECT_CALL(wayland, CreateObject(::testing::_)).Times(0);

  EXPECT_EQ(fl_wayland_display_get_for_display(gdk_display), nullptr);
  EXPECT_TRUE(HasReceivedLogLevel(G_LOG_LEVEL_CRITICAL));
}

// Subsurfaces are made from the globals bound when the display was opened, so
// the registry is only used once however many subsurfaces are created.
TEST_F(FlWaylandDisplayTest, CreateSubsurface) {
  g_autoptr(FlWaylandDisplay) display =
      fl_wayland_display_open(fl_mock_wayland_get_display());
  ASSERT_NE(display, nullptr);
  struct wl_surface* parent_surface = fl_mock_wayland_get_surface();

  EXPECT_CALL(wayland, CreateObject(::testing::StrEq("wl_registry"))).Times(0);

  g_autoptr(FlSubsurface) subsurface1 =
      fl_wayland_display_create_subsurface(display, parent_surface);
  g_autoptr(FlSubsurface) subsurface2 =
      fl_wayland_display_create_subsurface(display, parent_surface);
  ASSERT_NE(subsurface1, nullptr);
  ASSERT_NE(subsurface2, nullptr);
  EXPECT_NE(fl_subsurface_get_surface(subsurface1),
            fl_subsurface_get_surface(subsurface2));

  fl_mock_wayland_free_surface(parent_surface);
}
