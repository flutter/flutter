// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_plugin.h"
#include "flutter/shell/platform/linux/fl_view_accessible.h"

struct _FlAccessibilityPlugin {
  GObject parent_instance;

  FlView* view;
};

G_DEFINE_TYPE(FlAccessibilityPlugin, fl_accessibility_plugin, G_TYPE_OBJECT)

static void fl_accessibility_plugin_dispose(GObject* object) {
  FlAccessibilityPlugin* self = FL_ACCESSIBILITY_PLUGIN(object);

  if (self->view != nullptr) {
    g_object_remove_weak_pointer(G_OBJECT(self),
                                 reinterpret_cast<gpointer*>(&(self->view)));
    self->view = nullptr;
  }

  G_OBJECT_CLASS(fl_accessibility_plugin_parent_class)->dispose(object);
}

static void fl_accessibility_plugin_class_init(
    FlAccessibilityPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_accessibility_plugin_dispose;
}

static void fl_accessibility_plugin_init(FlAccessibilityPlugin* self) {}

FlAccessibilityPlugin* fl_accessibility_plugin_new(FlView* view) {
  FlAccessibilityPlugin* self = FL_ACCESSIBILITY_PLUGIN(
      g_object_new(fl_accessibility_plugin_get_type(), nullptr));

  self->view = view;
  g_object_add_weak_pointer(G_OBJECT(self),
                            reinterpret_cast<gpointer*>(&(self->view)));

  return self;
}

void fl_accessibility_plugin_handle_update_semantics_node(
    FlAccessibilityPlugin* self,
    const FlutterSemanticsNode* node) {
  if (self->view == nullptr) {
    return;
  }

  AtkObject* accessible = gtk_widget_get_accessible(GTK_WIDGET(self->view));
  fl_view_accessible_handle_update_semantics_node(
      FL_VIEW_ACCESSIBLE(accessible), node);
}
