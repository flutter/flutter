// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_H_

#include <cstddef>

// Each source set owns only the implementation for its GTK version.
#if defined(FLUTTER_LINUX_GTK4)
#include "flutter/shell/platform/linux/fl_gtk_gtk4.h"  // nogncheck
#else
#include "flutter/shell/platform/linux/fl_gtk_gtk3.h"  // nogncheck
#endif

static inline size_t fl_gtk_size_to_pixels(double logical_size, double scale) {
  return logical_size <= 0.0 || scale <= 0.0
             ? 0
             : static_cast<size_t>(logical_size * scale + 0.5);
}

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK_H_
