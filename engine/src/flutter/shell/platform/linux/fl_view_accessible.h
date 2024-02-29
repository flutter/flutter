// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_ACCESSIBLE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_ACCESSIBLE_H_

#if !defined(__FLUTTER_LINUX_INSIDE__) && !defined(FLUTTER_LINUX_COMPILATION)
#error "Only <flutter_linux/flutter_linux.h> can be included directly."
#endif

#include <gtk/gtk-a11y.h>

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlViewAccessible,
                     fl_view_accessible,
                     FL,
                     VIEW_ACCESSIBLE,
                     GtkContainerAccessible)

/**
 * FlViewAccessible:
 *
 * #FlViewAccessible is an object that exposes accessibility information for an
 * #FlView.
 */

/**
 * fl_view_accessible_handle_update_semantics:
 * @accessible: an #FlViewAccessible.
 * @update: semantic update information.
 *
 * Handle a semantics update from Flutter.
 */
void fl_view_accessible_handle_update_semantics(
    FlViewAccessible* accessible,
    const FlutterSemanticsUpdate2* update);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_ACCESSIBLE_H_
