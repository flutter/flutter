// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk4_runtime_api.h"

#if FLUTTER_LINUX_GTK4

#include <dlfcn.h>
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
#include <mutex>
#endif

#include "flutter/shell/platform/linux/fl_linux_debug.h"

static gboolean gtk_runtime_at_least(int major, int minor, int micro) {
  return gtk_check_version(major, minor, micro) == nullptr;
}

template <typename T>
static T lookup_symbol(const char* name) {
  return reinterpret_cast<T>(dlsym(RTLD_DEFAULT, name));
}

#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
static void log_fallback_once(const char* symbol, const char* fallback) {
  static std::mutex mutex;
  static GHashTable* warned_symbols = nullptr;

  std::lock_guard<std::mutex> lock(mutex);
  if (warned_symbols == nullptr) {
    warned_symbols = g_hash_table_new(g_str_hash, g_str_equal);
  }
  if (g_hash_table_contains(warned_symbols, symbol)) {
    return;
  }
  g_hash_table_add(warned_symbols, const_cast<char*>(symbol));
  flutter_linux_dbg("gtk4_runtime_api", "%s unavailable, using %s", symbol,
                    fallback);
}
#endif

const FlGtkRuntimeApi* fl_gtk_runtime_api_get() {
  static const FlGtkRuntimeApi api = [] {
    FlGtkRuntimeApi result = {};
    result.gtk_at_least_4_10 = gtk_runtime_at_least(4, 10, 0);
    result.gtk_at_least_4_14 = gtk_runtime_at_least(4, 14, 0);
    result.gtk_accessible_set_accessible_parent =
        lookup_symbol<decltype(result.gtk_accessible_set_accessible_parent)>(
            "gtk_accessible_set_accessible_parent");
    result.gtk_accessible_get_first_accessible_child = lookup_symbol<
        decltype(result.gtk_accessible_get_first_accessible_child)>(
        "gtk_accessible_get_first_accessible_child");
    result.gtk_accessible_announce =
        lookup_symbol<decltype(result.gtk_accessible_announce)>(
            "gtk_accessible_announce");
    return result;
  }();
  return &api;
}

gboolean fl_gtk_runtime_supports_native_accessibility_tree() {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  return api->gtk_at_least_4_10 &&
         api->gtk_accessible_set_accessible_parent != nullptr &&
         api->gtk_accessible_get_first_accessible_child != nullptr;
#else
  return GTK_CHECK_VERSION(4, 10, 0);
#endif
}

GtkAccessible* fl_gtk_runtime_accessible_get_first_accessible_child(
    GtkAccessible* self) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_10 &&
      api->gtk_accessible_get_first_accessible_child != nullptr) {
    return api->gtk_accessible_get_first_accessible_child(self);
  }
  log_fallback_once("gtk_accessible_get_first_accessible_child",
                    "no-op compatible path");
  (void)self;
  return nullptr;
#else
#if GTK_CHECK_VERSION(4, 10, 0)
  return gtk_accessible_get_first_accessible_child(self);
#else
  (void)self;
  return nullptr;
#endif
#endif
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
  log_fallback_once("gtk_accessible_set_accessible_parent",
                    "no-op compatible path");
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

void fl_gtk_runtime_accessible_announce(GtkAccessible* self,
                                        const char* message,
                                        gint priority) {
#if defined(FLUTTER_LINUX_GTK4_RUNTIME_API_COMPAT)
  const FlGtkRuntimeApi* api = fl_gtk_runtime_api_get();
  if (api->gtk_at_least_4_14 && api->gtk_accessible_announce != nullptr) {
    api->gtk_accessible_announce(
        self, message,
        static_cast<FlGtkAccessibleAnnouncementPriority>(priority));
    return;
  }
  log_fallback_once("gtk_accessible_announce", "no-op compatible path");
  (void)self;
  (void)message;
  (void)priority;
#else
#if GTK_CHECK_VERSION(4, 14, 0)
  gtk_accessible_announce(
      self, message, static_cast<GtkAccessibleAnnouncementPriority>(priority));
#else
  (void)self;
  (void)message;
  (void)priority;
#endif
#endif
}

#endif  // FLUTTER_LINUX_GTK4
