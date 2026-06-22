// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"

#if FLUTTER_LINUX_GTK4

#include <dlfcn.h>

static gboolean gtk_runtime_at_least(int major, int minor, int micro) {
  return gtk_check_version(major, minor, micro) == nullptr;
}

template <typename T>
static T lookup_symbol(const char* name) {
  return reinterpret_cast<T>(dlsym(RTLD_DEFAULT, name));
}

const FlGtkRuntimeApi* fl_gtk_runtime_api_get() {
  static FlGtkRuntimeApi api = {};
  if (api.checked) {
    return &api;
  }

  api.checked = TRUE;
  api.gtk_at_least_4_10 = gtk_runtime_at_least(4, 10, 0);
  api.gtk_at_least_4_14 = gtk_runtime_at_least(4, 14, 0);
  api.gtk_at_least_4_18 = gtk_runtime_at_least(4, 18, 0);

  api.gtk_accessible_get_platform_state =
      lookup_symbol<decltype(api.gtk_accessible_get_platform_state)>(
          "gtk_accessible_get_platform_state");
  api.gtk_accessible_get_accessible_parent =
      lookup_symbol<decltype(api.gtk_accessible_get_accessible_parent)>(
          "gtk_accessible_get_accessible_parent");
  api.gtk_accessible_set_accessible_parent =
      lookup_symbol<decltype(api.gtk_accessible_set_accessible_parent)>(
          "gtk_accessible_set_accessible_parent");
  api.gtk_accessible_get_first_accessible_child =
      lookup_symbol<decltype(api.gtk_accessible_get_first_accessible_child)>(
          "gtk_accessible_get_first_accessible_child");
  api.gtk_accessible_get_next_accessible_sibling =
      lookup_symbol<decltype(api.gtk_accessible_get_next_accessible_sibling)>(
          "gtk_accessible_get_next_accessible_sibling");
  api.gtk_accessible_update_next_accessible_sibling = lookup_symbol<
      decltype(api.gtk_accessible_update_next_accessible_sibling)>(
      "gtk_accessible_update_next_accessible_sibling");
  api.gtk_accessible_update_state_value =
      lookup_symbol<decltype(api.gtk_accessible_update_state_value)>(
          "gtk_accessible_update_state_value");
  api.gtk_accessible_update_property_value =
      lookup_symbol<decltype(api.gtk_accessible_update_property_value)>(
          "gtk_accessible_update_property_value");
  api.gtk_accessible_update_relation_value =
      lookup_symbol<decltype(api.gtk_accessible_update_relation_value)>(
          "gtk_accessible_update_relation_value");
  api.gtk_accessible_state_init_value =
      lookup_symbol<decltype(api.gtk_accessible_state_init_value)>(
          "gtk_accessible_state_init_value");
  api.gtk_accessible_property_init_value =
      lookup_symbol<decltype(api.gtk_accessible_property_init_value)>(
          "gtk_accessible_property_init_value");
  api.gtk_accessible_relation_init_value =
      lookup_symbol<decltype(api.gtk_accessible_relation_init_value)>(
          "gtk_accessible_relation_init_value");
  api.gtk_accessible_announce =
      lookup_symbol<decltype(api.gtk_accessible_announce)>(
          "gtk_accessible_announce");

  return &api;
}

void fl_gtk_runtime_accessible_set_accessible_parent(
    GtkAccessible* self,
    GtkAccessible* parent,
    GtkAccessible* next_sibling) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_10 &&
      api->gtk_accessible_set_accessible_parent != nullptr) {
    api->gtk_accessible_set_accessible_parent(self, parent, next_sibling);
    return;
  }
#else
#if GTK_CHECK_VERSION(4, 10, 0)
  gtk_accessible_set_accessible_parent(self, parent, next_sibling);
#else
  (void)self;
  (void)parent;
  (void)next_sibling;
#endif
#endif
}

void fl_gtk_runtime_accessible_update_state_value(GtkAccessible* self,
                                                  int n_states,
                                                  GtkAccessibleState states[],
                                                  const GValue values[]) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_accessible_update_state_value != nullptr) {
    api->gtk_accessible_update_state_value(self, n_states, states, values);
    return;
  }
#endif
  gtk_accessible_update_state_value(self, n_states, states, values);
}

void fl_gtk_runtime_accessible_update_property_value(
    GtkAccessible* self,
    int n_properties,
    GtkAccessibleProperty properties[],
    const GValue values[]) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_accessible_update_property_value != nullptr) {
    api->gtk_accessible_update_property_value(self, n_properties, properties,
                                              values);
    return;
  }
#endif
  gtk_accessible_update_property_value(self, n_properties, properties, values);
}

void fl_gtk_runtime_accessible_update_relation_value(
    GtkAccessible* self,
    int n_relations,
    GtkAccessibleRelation relations[],
    const GValue values[]) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_accessible_update_relation_value != nullptr) {
    api->gtk_accessible_update_relation_value(self, n_relations, relations,
                                              values);
    return;
  }
#endif
  gtk_accessible_update_relation_value(self, n_relations, relations, values);
}

void fl_gtk_runtime_accessible_state_init_value(GtkAccessibleState state,
                                                GValue* value) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_accessible_state_init_value != nullptr) {
    api->gtk_accessible_state_init_value(state, value);
    return;
  }
#endif
  gtk_accessible_state_init_value(state, value);
}

void fl_gtk_runtime_accessible_property_init_value(
    GtkAccessibleProperty property,
    GValue* value) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_accessible_property_init_value != nullptr) {
    api->gtk_accessible_property_init_value(property, value);
    return;
  }
#endif
  gtk_accessible_property_init_value(property, value);
}

void fl_gtk_runtime_accessible_relation_init_value(
    GtkAccessibleRelation relation,
    GValue* value) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_accessible_relation_init_value != nullptr) {
    api->gtk_accessible_relation_init_value(relation, value);
    return;
  }
#endif
  gtk_accessible_relation_init_value(relation, value);
}

void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_14 && api->gtk_accessible_announce != nullptr) {
    api->gtk_accessible_announce(self, message, priority);
    return;
  }
#endif
  (void)self;
  (void)message;
  (void)priority;
}

#endif  // FLUTTER_LINUX_GTK4
