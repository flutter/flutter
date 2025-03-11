// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_WINDOWING_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_WINDOWING_H_

#include <gtk/gtk.h>

#include "flutter/shell/platform/linux/public/flutter_linux/fl_engine.h"

G_BEGIN_DECLS

G_DECLARE_DERIVABLE_TYPE(FlWindowingController,
                         fl_windowing_controller,
                         FL,
                         WINDOWING_CONTROLLER,
                         GObject);

struct _FlWindowingControllerClass {
  GObjectClass parent_class;
};

FlWindowingController* fl_windowing_controller_new(FlEngine* engine);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_WINDOWING_H_
