// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_PLATFORM_PLUGIN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_PLATFORM_PLUGIN_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlPlatformPlugin,
                     fl_platform_plugin,
                     FL,
                     PLATFORM_PLUGIN,
                     GObject);

/**
 * FlPlatformPlugin:
 *
 * #FlPlatformPlugin is a plugin that implements the shell side
 * of SystemChannels.platform from the Flutter services library.
 */

/**
 * fl_platform_plugin_new:
 * @messenger: an #FlBinaryMessenger
 *
 * Creates a new plugin that implements SystemChannels.platform from the
 * Flutter services library.
 *
 * Returns: a new #FlPlatformPlugin
 */
FlPlatformPlugin* fl_platform_plugin_new(FlBinaryMessenger* messenger);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_PLATFORM_PLUGIN_H_
