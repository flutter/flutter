// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/public/flutter_linux/fl_plugin_registry.h"

#include <gmodule.h>

// Added here to stop the compiler from optimizing this function away.
G_MODULE_EXPORT GType fl_plugin_registry_get_type();

G_DEFINE_INTERFACE(FlPluginRegistry, fl_plugin_registry, G_TYPE_OBJECT)

void fl_plugin_registry_default_init(FlPluginRegistryInterface* self) {}

G_MODULE_EXPORT FlPluginRegistrar* fl_plugin_registry_get_registrar_for_plugin(
    FlPluginRegistry* self,
    const gchar* name) {
  g_return_val_if_fail(FL_IS_PLUGIN_REGISTRY(self), nullptr);
  g_return_val_if_fail(name != nullptr, nullptr);

  return FL_PLUGIN_REGISTRY_GET_IFACE(self)->get_registrar_for_plugin(self,
                                                                      name);
}
