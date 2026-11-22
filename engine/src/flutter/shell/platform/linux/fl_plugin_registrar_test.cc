// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_texture_registrar_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registrar.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registry.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"
#include "flutter/shell/platform/linux/testing/linux_test.h"
#include "flutter/shell/platform/linux/testing/mock_gtk.h"
#include "flutter/shell/platform/linux/testing/mock_plugin_registrar.h"

class FlPluginRegistrarTest : public flutter::testing::LinuxTest {};

// Checks can make a mock registrar.
TEST_F(FlPluginRegistrarTest, FlMockRegistrar) {
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextureRegistrar) texture_registrar =
      fl_texture_registrar_new(engine);

  g_autoptr(FlPluginRegistrar) registrar =
      fl_mock_plugin_registrar_new(messenger, texture_registrar);
  EXPECT_TRUE(FL_IS_MOCK_PLUGIN_REGISTRAR(registrar));

  EXPECT_EQ(fl_plugin_registrar_get_messenger(registrar), messenger);
  EXPECT_EQ(fl_plugin_registrar_get_texture_registrar(registrar),
            texture_registrar);
  EXPECT_EQ(fl_plugin_registrar_get_view(registrar), nullptr);
  EXPECT_EQ(fl_plugin_registrar_get_view_by_id(registrar, 0), nullptr);
}

TEST_F(FlPluginRegistrarTest, GetViewById) {
  FlView* implicit_view = fl_view_new(project);
  FlEngine* view_engine = fl_view_get_engine(implicit_view);
  StartEngine(view_engine);

  FlView* secondary_view = fl_view_new_for_engine(view_engine);
  int64_t implicit_view_id = fl_view_get_id(implicit_view);
  int64_t secondary_view_id = fl_view_get_id(secondary_view);
  EXPECT_NE(implicit_view_id, secondary_view_id);

  // Verify lookups using registrar obtained from the engine.
  g_autoptr(FlPluginRegistrar) engine_registrar =
      fl_plugin_registry_get_registrar_for_plugin(
          FL_PLUGIN_REGISTRY(view_engine), "test_plugin");
  EXPECT_EQ(fl_plugin_registrar_get_view(engine_registrar), implicit_view);
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(engine_registrar, implicit_view_id),
      implicit_view);
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(engine_registrar, secondary_view_id),
      secondary_view);
  EXPECT_EQ(fl_plugin_registrar_get_view_by_id(engine_registrar, 999), nullptr);

  // Verify lookups using registrar obtained from a view.
  g_autoptr(FlPluginRegistrar) view_registrar =
      fl_plugin_registry_get_registrar_for_plugin(
          FL_PLUGIN_REGISTRY(implicit_view), "test_plugin");
  EXPECT_EQ(fl_plugin_registrar_get_view(view_registrar), implicit_view);
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(view_registrar, implicit_view_id),
      implicit_view);
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(view_registrar, secondary_view_id),
      secondary_view);
  EXPECT_EQ(fl_plugin_registrar_get_view_by_id(view_registrar, 999), nullptr);

  // Destroying the secondary view removes it from lookup.
  fl_gtk_widget_destroy(GTK_WIDGET(secondary_view));
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(engine_registrar, secondary_view_id),
      nullptr);
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(engine_registrar, implicit_view_id),
      implicit_view);

  fl_gtk_widget_destroy(GTK_WIDGET(implicit_view));
  EXPECT_EQ(
      fl_plugin_registrar_get_view_by_id(engine_registrar, implicit_view_id),
      nullptr);
  EXPECT_EQ(fl_plugin_registrar_get_view(engine_registrar), nullptr);
}

TEST_F(FlPluginRegistrarTest, GetViewByIdHeadless) {
  g_autoptr(FlEngine) headless_engine = fl_engine_new_headless(project);
  g_autoptr(FlPluginRegistrar) registrar =
      fl_plugin_registry_get_registrar_for_plugin(
          FL_PLUGIN_REGISTRY(headless_engine), "test_plugin");

  EXPECT_EQ(fl_plugin_registrar_get_view(registrar), nullptr);
  EXPECT_EQ(fl_plugin_registrar_get_view_by_id(registrar, 0), nullptr);
  EXPECT_EQ(fl_plugin_registrar_get_view_by_id(registrar, 1), nullptr);
}
