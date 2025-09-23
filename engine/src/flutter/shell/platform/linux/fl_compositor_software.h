// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_

#include <cairo/cairo.h>

#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlCompositorSoftware,
                     fl_compositor_software,
                     FL,
                     COMPOSITOR_SOFTWARE,
                     FlCompositor)

/**
 * FlCompositorSoftware:
 *
 * #FlCompositorSoftware is a class that implements compositing using software
 * rendering.
 */

/**
 * fl_compositor_software_new:
 * @task_runner: an #FlTaskRunnner.
 *
 * Creates a new software rendering compositor.
 *
 * Returns: a new #FlCompositorSoftware.
 */
FlCompositorSoftware* fl_compositor_software_new(FlTaskRunner* task_runner);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_SOFTWARE_H_
