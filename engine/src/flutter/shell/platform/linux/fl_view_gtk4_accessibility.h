// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_GTK4_ACCESSIBILITY_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_GTK4_ACCESSIBILITY_H_

#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

G_BEGIN_DECLS

typedef struct _FlViewGtk4Accessibility FlViewGtk4Accessibility;

FlViewGtk4Accessibility* fl_view_gtk4_accessibility_new(FlView* view,
                                                        FlutterViewId view_id);
FlView* fl_view_gtk4_accessibility_get_view(FlViewGtk4Accessibility* self);
void fl_view_gtk4_accessibility_dispose(FlViewGtk4Accessibility* self);
void fl_view_gtk4_accessibility_handle_update(
    FlViewGtk4Accessibility* self,
    const FlutterSemanticsUpdate2* update);
void fl_view_gtk4_accessibility_handle_native_update(
    FlViewGtk4Accessibility* self,
    const FlutterSemanticsUpdate2* update);
void fl_view_gtk4_accessibility_update_accessible_name(
    FlViewGtk4Accessibility* self);
void fl_view_gtk4_accessibility_update_accessible_tree(
    FlViewGtk4Accessibility* self);
void fl_view_gtk4_accessibility_send_announcement(
    FlViewGtk4Accessibility* self,
    const char* message,
    gboolean assertive);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_GTK4_ACCESSIBILITY_H_
