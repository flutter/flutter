// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_ACCESSIBLE_NODE_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_ACCESSIBLE_NODE_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_gtk4_accessible_node.h"

#if defined(FLUTTER_LINUX_GTK4_NATIVE_ACCESSIBILITY_TREE)
// Shared only by the native node and its text subclasses. Tree reconciliation
// uses the opaque node API and must not depend on this layout.
struct _FlGtk4AccessibleNode {
  // GTK exports AT-SPI actions through GtkWidget's action muxer. These nodes
  // are hidden children of the render surface for GTK lifecycle support.
  // The surface never measures, allocates, or snapshots them.
  GtkWidget parent_instance;

  FlView* view;
  FlutterViewId view_id;
  GtkAccessibleRole role;
  GtkATContext* at_context;
  guint64 semantics_revision;
  int32_t semantics_id;
  uint64_t actions;
  gboolean actions_enabled;
  gboolean text_actions_enabled;
  gboolean text_editable;

  gchar* text;
  // Protected text keeps only character-to-UTF-16 boundaries, never raw text.
  GArray* protected_text_offsets;
  guint text_selection_base;
  guint text_selection_extent;

  GPtrArray* children;
  FlGtk4AccessibleNode* parent;
  FlGtk4AccessibleNode* next_sibling;

  gboolean focusable;
  gboolean focused;
  gboolean active;
  gboolean has_bounds;
  int bounds_x;
  int bounds_y;
  int bounds_width;
  int bounds_height;
};

struct _FlGtk4AccessibleNodeClass {
  GtkWidgetClass parent_class;
};

enum {
  PROP_GTK4_ACCESSIBLE_NODE_0,
  PROP_GTK4_ACCESSIBLE_NODE_ACCESSIBLE_ROLE,
  LAST_GTK4_ACCESSIBLE_NODE_PROPERTY,
};

#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GTK4_ACCESSIBLE_NODE_PRIVATE_H_
