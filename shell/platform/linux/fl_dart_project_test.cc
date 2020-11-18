// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"

#include <gmodule.h>

#include <cstdlib>

#include "flutter/shell/platform/linux/fl_dart_project_private.h"
#include "gtest/gtest.h"

TEST(FlDartProjectTest, GetPaths) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  ASSERT_TRUE(exe_path != nullptr);
  g_autofree gchar* dir = g_path_get_dirname(exe_path);
  g_autofree gchar* expected_aot_library_path =
      g_build_filename(dir, "lib", "libapp.so", nullptr);
  EXPECT_STREQ(fl_dart_project_get_aot_library_path(project),
               expected_aot_library_path);
  g_autofree gchar* expected_assets_path =
      g_build_filename(dir, "data", "flutter_assets", nullptr);
  EXPECT_STREQ(fl_dart_project_get_assets_path(project), expected_assets_path);
  g_autofree gchar* expected_icu_data_path =
      g_build_filename(dir, "data", "icudtl.dat", nullptr);
  EXPECT_STREQ(fl_dart_project_get_icu_data_path(project),
               expected_icu_data_path);
}

TEST(FlDartProjectTest, EnableMirrors) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  G_GNUC_BEGIN_IGNORE_DEPRECATIONS
  EXPECT_FALSE(fl_dart_project_get_enable_mirrors(project));
  fl_dart_project_set_enable_mirrors(project, TRUE);
  EXPECT_TRUE(fl_dart_project_get_enable_mirrors(project));
  G_GNUC_END_IGNORE_DEPRECATIONS
}

TEST(FlDartProjectTest, SwitchesEmpty) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();

  // Clear the main environment variable, since test order is not guaranteed.
  unsetenv("FLUTTER_ENGINE_SWITCHES");

  g_autoptr(GPtrArray) switches = fl_dart_project_get_switches(project);

  EXPECT_EQ(switches->len, 0U);
}

#ifndef FLUTTER_RELEASE
TEST(FlDartProjectTest, Switches) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();

  setenv("FLUTTER_ENGINE_SWITCHES", "2", 1);
  setenv("FLUTTER_ENGINE_SWITCH_1", "abc", 1);
  setenv("FLUTTER_ENGINE_SWITCH_2", "foo=\"bar, baz\"", 1);

  g_autoptr(GPtrArray) switches = fl_dart_project_get_switches(project);
  EXPECT_EQ(switches->len, 2U);
  EXPECT_STREQ(static_cast<const char*>(g_ptr_array_index(switches, 0)),
               "--abc");
  EXPECT_STREQ(static_cast<const char*>(g_ptr_array_index(switches, 1)),
               "--foo=\"bar, baz\"");

  unsetenv("FLUTTER_ENGINE_SWITCHES");
  unsetenv("FLUTTER_ENGINE_SWITCH_1");
  unsetenv("FLUTTER_ENGINE_SWITCH_2");
}
#endif  // !FLUTTER_RELEASE
