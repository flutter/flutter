// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_H_

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

#include <glib-object.h>

#include "fl_dart_project.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlEngine, fl_engine, FL, ENGINE, GObject)

/**
 * FlEngine:
 *
 * #FlEngine is an object that contains a running Flutter engine.
 */

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ENGINE_H_
