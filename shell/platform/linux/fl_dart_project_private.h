// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_DART_PROJECT_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_DART_PROJECT_PRIVATE_H_

#include <glib-object.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_dart_project.h"

G_BEGIN_DECLS

/**
 * fl_dart_project_get_switches:
 * @project: an #FlDartProject.
 *
 * Determines the engine switches that should be passed to the Flutter engine.
 *
 * Returns: an array of switches to pass to the Flutter engine.
 */
GPtrArray* fl_dart_project_get_switches(FlDartProject* project);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_DART_PROJECT_PRIVATE_H_
