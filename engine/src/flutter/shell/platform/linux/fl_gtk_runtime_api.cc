// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_gtk_runtime_api.h"

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

  api.gtk_accessible_set_accessible_parent =
      lookup_symbol<decltype(api.gtk_accessible_set_accessible_parent)>(
          "gtk_accessible_set_accessible_parent");

  return &api;
}

#endif  // FLUTTER_LINUX_GTK4
