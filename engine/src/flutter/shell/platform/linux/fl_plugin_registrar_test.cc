// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <gtk/gtk.h>

// Included first as it collides with the X11 headers.
#include "gtest/gtest.h"

#include "flutter/shell/platform/linux/fl_binary_messenger_private.h"
#include "flutter/shell/platform/linux/fl_texture_registrar_private.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registrar.h"
#include "flutter/shell/platform/linux/testing/fl_test.h"

G_DECLARE_FINAL_TYPE(FlMockPluginRegistrar,
                     fl_mock_plugin_registrar,
                     FL,
                     MOCK_PLUGIN_REGISTRAR,
                     GObject)

struct _FlMockPluginRegistrar {
  GObject parent_instance;

  FlView* view;
  FlBinaryMessenger* messenger;
  FlTextureRegistrar* texture_registrar;
};

static void fl_mock_plugin_registrar_iface_init(
    FlPluginRegistrarInterface* iface);

G_DEFINE_TYPE_WITH_CODE(
    FlMockPluginRegistrar,
    fl_mock_plugin_registrar,
    G_TYPE_OBJECT,
    G_IMPLEMENT_INTERFACE(fl_plugin_registrar_get_type(),
                          fl_mock_plugin_registrar_iface_init))

static void fl_mock_plugin_registrar_dispose(GObject* object) {
  FlMockPluginRegistrar* self = FL_MOCK_PLUGIN_REGISTRAR(object);

  g_clear_object(&self->view);
  g_clear_object(&self->messenger);
  g_clear_object(&self->texture_registrar);

  G_OBJECT_CLASS(fl_mock_plugin_registrar_parent_class)->dispose(object);
}

static void fl_mock_plugin_registrar_class_init(
    FlMockPluginRegistrarClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_mock_plugin_registrar_dispose;
}

static FlBinaryMessenger* get_messenger(FlPluginRegistrar* registrar) {
  FlMockPluginRegistrar* self = FL_MOCK_PLUGIN_REGISTRAR(registrar);
  return self->messenger;
}

static FlTextureRegistrar* get_texture_registrar(FlPluginRegistrar* registrar) {
  FlMockPluginRegistrar* self = FL_MOCK_PLUGIN_REGISTRAR(registrar);
  return self->texture_registrar;
}

static FlView* get_view(FlPluginRegistrar* registrar) {
  FlMockPluginRegistrar* self = FL_MOCK_PLUGIN_REGISTRAR(registrar);
  return self->view;
}

static void fl_mock_plugin_registrar_iface_init(
    FlPluginRegistrarInterface* iface) {
  iface->get_messenger = get_messenger;
  iface->get_texture_registrar = get_texture_registrar;
  iface->get_view = get_view;
}

static void fl_mock_plugin_registrar_init(FlMockPluginRegistrar* self) {}

static FlPluginRegistrar* fl_mock_plugin_registrar_new(
    FlView* view,
    FlBinaryMessenger* messenger,
    FlTextureRegistrar* texture_registrar) {
  FlMockPluginRegistrar* registrar = FL_MOCK_PLUGIN_REGISTRAR(
      g_object_new(fl_mock_plugin_registrar_get_type(), NULL));
  registrar->view = FL_VIEW(g_object_ref(view));
  registrar->messenger = FL_BINARY_MESSENGER(g_object_ref(messenger));
  registrar->texture_registrar =
      FL_TEXTURE_REGISTRAR(g_object_ref(texture_registrar));
  return FL_PLUGIN_REGISTRAR(registrar);
}

// Checks can make a mock registrar.
TEST(FlPluginRegistrarTest, FlMockRegistrar) {
  gtk_init(NULL, NULL);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  g_autoptr(FlEngine) engine = make_mock_engine();
  g_autoptr(FlView) view = fl_view_new(project);
  g_autoptr(FlBinaryMessenger) messenger = fl_binary_messenger_new(engine);
  g_autoptr(FlTextureRegistrar) texture_registrar =
      fl_texture_registrar_new(engine);

  g_autoptr(FlPluginRegistrar) registrar =
      fl_mock_plugin_registrar_new(view, messenger, texture_registrar);
  EXPECT_TRUE(FL_IS_MOCK_PLUGIN_REGISTRAR(registrar));

  EXPECT_EQ(fl_plugin_registrar_get_messenger(registrar), messenger);
  EXPECT_EQ(fl_plugin_registrar_get_texture_registrar(registrar),
            texture_registrar);
  EXPECT_EQ(fl_plugin_registrar_get_view(registrar), view);
}
