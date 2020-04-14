// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_H_

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

#include <gtk/gtk.h>

#include "fl_dart_project.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlView, fl_view, FL, VIEW, GtkWidget)

/**
 * FlView:
 *
 * #FlView is a GTK widget that is capable of displaying a Flutter application.
 */

/**
 * fl_view_new:
 * @project: The project to show.
 *
 * Creates a widget to show Flutter application.
 *
 * Returns: a new #FlView
 */
FlView* fl_view_new(FlDartProject* project);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_H_
