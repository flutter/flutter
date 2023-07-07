// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef PACKAGES_URL_LAUNCHER_URL_LAUNCHER_LINUX_LINUX_INCLUDE_URL_LAUNCHER_URL_LAUNCHER_PLUGIN_H_
#define PACKAGES_URL_LAUNCHER_URL_LAUNCHER_LINUX_LINUX_INCLUDE_URL_LAUNCHER_URL_LAUNCHER_PLUGIN_H_

// A plugin to launch URLs.

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __attribute__((visibility("default")))
#else
#define FLUTTER_PLUGIN_EXPORT
#endif

G_DECLARE_FINAL_TYPE(FlUrlLauncherPlugin, fl_url_launcher_plugin, FL,
                     URL_LAUNCHER_PLUGIN, GObject)

FLUTTER_PLUGIN_EXPORT FlUrlLauncherPlugin* fl_url_launcher_plugin_new(
    FlPluginRegistrar* registrar);

FLUTTER_PLUGIN_EXPORT void url_launcher_plugin_register_with_registrar(
    FlPluginRegistrar* registrar);

G_END_DECLS

#endif  // PACKAGES_URL_LAUNCHER_URL_LAUNCHER_LINUX_LINUX_INCLUDE_URL_LAUNCHER_URL_LAUNCHER_PLUGIN_H_
