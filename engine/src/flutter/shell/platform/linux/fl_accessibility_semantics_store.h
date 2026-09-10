// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_SEMANTICS_STORE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_SEMANTICS_STORE_H_

#include <glib-object.h>

#include "flutter/shell/platform/embedder/embedder.h"

G_BEGIN_DECLS

typedef struct {
  int32_t id;
  gchar* label;
  gchar* value;
  FlutterSemanticsFlags flags;
  FlutterSemanticsAction actions;
  gint text_selection_base;
  gint text_selection_extent;
  FlutterTextDirection text_direction;
  FlutterRect rect;
  FlutterTransformation transform;
  size_t child_count;
  int32_t* children_in_traversal_order;
} FlAccessibilitySemanticsNode;

G_DECLARE_FINAL_TYPE(FlAccessibilitySemanticsStore,
                     fl_accessibility_semantics_store,
                     FL,
                     ACCESSIBILITY_SEMANTICS_STORE,
                     GObject);

FlAccessibilitySemanticsStore* fl_accessibility_semantics_store_new(
    FlutterViewId view_id);

void fl_accessibility_semantics_store_handle_update(
    FlAccessibilitySemanticsStore* self,
    const FlutterSemanticsUpdate2* update);

const FlAccessibilitySemanticsNode*
fl_accessibility_semantics_store_lookup_node(
    FlAccessibilitySemanticsStore* self,
    int32_t node_id);

gboolean fl_accessibility_semantics_store_has_root(
    FlAccessibilitySemanticsStore* self);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ACCESSIBILITY_SEMANTICS_STORE_H_
