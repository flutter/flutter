// Copyright 2026 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_VULKAN_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_VULKAN_H_

#include "flutter/shell/platform/linux/fl_compositor.h"
#include "flutter/shell/platform/linux/fl_task_runner.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlCompositorVulkan,
                     fl_compositor_vulkan,
                     FL,
                     COMPOSITOR_VULKAN,
                     FlCompositor)

FlCompositorVulkan* fl_compositor_vulkan_new(FlTaskRunner* task_runner);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_COMPOSITOR_VULKAN_H_
