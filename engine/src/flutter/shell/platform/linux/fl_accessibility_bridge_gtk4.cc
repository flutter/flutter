// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_bridge_gtk4.h"

struct _FlAccessibilityBridgeGtk4 {
  GObject parent_instance;

  FlAccessibilitySemanticsStore* semantics_store;
  gchar* last_announcement;
  FlTextDirection last_text_direction;
  FlAssertiveness last_assertiveness;
};

G_DEFINE_TYPE(FlAccessibilityBridgeGtk4,
              fl_accessibility_bridge_gtk4,
              G_TYPE_OBJECT)

static void fl_accessibility_bridge_gtk4_dispose(GObject* object) {
  FlAccessibilityBridgeGtk4* self = FL_ACCESSIBILITY_BRIDGE_GTK4(object);

  g_clear_object(&self->semantics_store);
  g_clear_pointer(&self->last_announcement, g_free);

  G_OBJECT_CLASS(fl_accessibility_bridge_gtk4_parent_class)->dispose(object);
}

static void fl_accessibility_bridge_gtk4_class_init(
    FlAccessibilityBridgeGtk4Class* klass) {
  GObjectClass* object_class = G_OBJECT_CLASS(klass);
  object_class->dispose = fl_accessibility_bridge_gtk4_dispose;
}

static void fl_accessibility_bridge_gtk4_init(FlAccessibilityBridgeGtk4* self) {
  self->last_text_direction = FL_TEXT_DIRECTION_LTR;
  self->last_assertiveness = FL_ASSERTIVENESS_POLITE;
}

FlAccessibilityBridgeGtk4* fl_accessibility_bridge_gtk4_new(
    FlutterViewId view_id) {
  FlAccessibilityBridgeGtk4* self = FL_ACCESSIBILITY_BRIDGE_GTK4(
      g_object_new(fl_accessibility_bridge_gtk4_get_type(), nullptr));
  self->semantics_store = fl_accessibility_semantics_store_new(view_id);
  return self;
}

void fl_accessibility_bridge_gtk4_handle_update_semantics(
    FlAccessibilityBridgeGtk4* self,
    const FlutterSemanticsUpdate2* update) {
  g_return_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self));
  fl_accessibility_semantics_store_handle_update(self->semantics_store, update);
}

void fl_accessibility_bridge_gtk4_send_announcement(
    FlAccessibilityBridgeGtk4* self,
    const char* message,
    FlTextDirection text_direction,
    FlAssertiveness assertiveness) {
  g_return_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self));

  g_free(self->last_announcement);
  self->last_announcement = g_strdup(message);
  self->last_text_direction = text_direction;
  self->last_assertiveness = assertiveness;
}

FlAccessibilitySemanticsStore* fl_accessibility_bridge_gtk4_get_semantics_store(
    FlAccessibilityBridgeGtk4* self) {
  g_return_val_if_fail(FL_IS_ACCESSIBILITY_BRIDGE_GTK4(self), nullptr);

  return self->semantics_store;
}
