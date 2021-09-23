// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registrar.h"
#include "flutter/shell/platform/linux/fl_plugin_registrar_private.h"

#include <gmodule.h>

struct _FlPluginRegistrar {
  GObject parent_instance;

  // View that plugin is controlling.
  FlView* view;

  // Messenger to communicate on.
  FlBinaryMessenger* messenger;

  // Texture registrar in use.
  FlTextureRegistrar* texture_registrar;
};

// Added here to stop the compiler from optimizing this function away.
G_MODULE_EXPORT GType fl_plugin_registrar_get_type();

G_DEFINE_TYPE(FlPluginRegistrar, fl_plugin_registrar, G_TYPE_OBJECT)

static void fl_plugin_registrar_dispose(GObject* object) {
  FlPluginRegistrar* self = FL_PLUGIN_REGISTRAR(object);

  if (self->view != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self->view),
                                 reinterpret_cast<gpointer*>(&(self->view)));
    self->view = nullptr;
  }
  g_clear_object(&self->messenger);
  g_clear_object(&self->texture_registrar);

  G_OBJECT_CLASS(fl_plugin_registrar_parent_class)->dispose(object);
}

static void fl_plugin_registrar_class_init(FlPluginRegistrarClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_plugin_registrar_dispose;
}

static void fl_plugin_registrar_init(FlPluginRegistrar* self) {}

FlPluginRegistrar* fl_plugin_registrar_new(
    FlView* view,
    FlBinaryMessenger* messenger,
    FlTextureRegistrar* texture_registrar) {
  g_return_val_if_fail(view == nullptr || FL_IS_VIEW(view), nullptr);
  g_return_val_if_fail(FL_IS_BINARY_MESSENGER(messenger), nullptr);
  g_return_val_if_fail(FL_IS_TEXTURE_REGISTRAR(texture_registrar), nullptr);

  FlPluginRegistrar* self = FL_PLUGIN_REGISTRAR(
      g_object_new(fl_plugin_registrar_get_type(), nullptr));

  self->view = view;
  if (view != nullptr) {
    g_object_add_weak_pointer(G_OBJECT(view),
                              reinterpret_cast<gpointer*>(&(self->view)));
  }
  self->messenger = FL_BINARY_MESSENGER(g_object_ref(messenger));
  self->texture_registrar =
      FL_TEXTURE_REGISTRAR(g_object_ref(texture_registrar));

  return self;
}

G_MODULE_EXPORT FlBinaryMessenger* fl_plugin_registrar_get_messenger(
    FlPluginRegistrar* self) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  return self->messenger;
}

G_MODULE_EXPORT FlTextureRegistrar* fl_plugin_registrar_get_texture_registrar(
    FlPluginRegistrar* self) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  return self->texture_registrar;
}

G_MODULE_EXPORT FlView* fl_plugin_registrar_get_view(FlPluginRegistrar* self) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRAR(self), nullptr);

  return self->view;
}
