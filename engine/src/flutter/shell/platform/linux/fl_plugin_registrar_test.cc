// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_texture_registrar_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registrar.h"
#include "flutter/shell/platform/linux/testing/mock_plugin_registrar.h"

// Checks can make a mock registrar.
TEST(FlPluginRegistrarTest, FlMockRegistrar) {
  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = fl_engine_new(project);

  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextureRegistrar) texture_registrar =
      fl_texture_registrar_new(engine);

  g_autoptr(FlPluginRegistrar) registrar =
      fl_mock_plugin_registrar_new(messenger, texture_registrar);
  EXPECT_TRUE(FL_IS_MOCK_PLUGIN_REGISTRAR(registrar));

  EXPECT_EQ(fl_plugin_registrar_get_messenger(registrar), messenger);
  EXPECT_EQ(fl_plugin_registrar_get_texture_registrar(registrar),
            texture_registrar);
  EXPECT_EQ(fl_plugin_registrar_get_engine_id(registrar), 0);
}

G_DECLARE_FINAL_TYPE(FlLegacyFakeRegistrar,
                     fl_legacy_fake_registrar,
                     FL,
                     LEGACY_FAKE_REGISTRAR,
                     GObject)

struct _FlLegacyFakeRegistrar {
  GObject parent_instance;
};

static void fl_legacy_fake_registrar_iface_init(
    FlPluginRegistrarInterface* iface) {
  // Intentionally omit iface->get_engine_id to simulate existing third-party
  // test doubles written prior to get_engine_id being added.
}

G_DEFINE_TYPE_WITH_CODE(
    FlLegacyFakeRegistrar,
    fl_legacy_fake_registrar,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_plugin_registrar_get_type(),
                          fl_legacy_fake_registrar_iface_init))

static void fl_legacy_fake_registrar_class_init(
    FlLegacyFakeRegistrarClass* klass) {}

static void fl_legacy_fake_registrar_init(FlLegacyFakeRegistrar* self) {}

// Checks that existing fake FlPluginRegistrar implementations that do not
// populate get_engine_id remain backwards-compatible.
TEST(FlPluginRegistrarTest, LegacyFakeWithoutGetEngineId) {
  g_autoptr(FlPluginRegistrar) registrar = FL_PLUGIN_REGISTRAR(
      g_object_new(fl_legacy_fake_registrar_get_type(), nullptr));

  EXPECT_EQ(fl_plugin_registrar_get_engine_id(registrar), 0);
}
