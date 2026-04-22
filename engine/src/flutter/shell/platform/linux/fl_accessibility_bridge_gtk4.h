// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_BRIDGE_GTK4_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_BRIDGE_GTK4_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_accessibility_channel.h"
#include "flutter/shell/platform/linux/fl_accessibility_semantics_store.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlAccessibilityBridgeGtk4,
                     fl_accessibility_bridge_gtk4,
                     FL,
                     ACCESSIBILITY_BRIDGE_GTK4,
                     GObject);

FlAccessibilityBridgeGtk4* fl_accessibility_bridge_gtk4_new(
    FlutterViewId view_id);

void fl_accessibility_bridge_gtk4_handle_update_semantics(
    FlAccessibilityBridgeGtk4* self,
    const FlutterSemanticsUpdate2* update);

void fl_accessibility_bridge_gtk4_send_announcement(
    FlAccessibilityBridgeGtk4* self,
    const char* message,
    FlTextDirection text_direction,
    FlAssertiveness assertiveness);

FlAccessibilitySemanticsStore* fl_accessibility_bridge_gtk4_get_semantics_store(
    FlAccessibilityBridgeGtk4* self);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_BRIDGE_GTK4_H_
