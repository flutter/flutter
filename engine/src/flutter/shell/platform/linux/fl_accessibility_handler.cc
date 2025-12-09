// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_accessibility_handler.h"

#include "flutter/shell/platform/linux/fl_accessibility_channel.h"
#include "flutter/shell/platform/linux/fl_engine_private.h"
#include "flutter/shell/platform/linux/fl_view_private.h"

typedef struct {
  GWeakRef engine;
  FlAccessibilityChannel* channel;
} FlAccessibilityHandlerPrivate;

G_DEFINE_TYPE_WITH_PRIVATE(FlAccessibilityHandler,
                           fl_accessibility_handler,
                           G_TYPE_OBJECT)

static void send_announcement(int64_t view_id,
                              const char* message,
                              FlTextDirection text_direction,
                              FlAssertiveness assertiveness,
                              gpointer user_data) {
  FlAccessibilityHandler* self = FL_ACCESSIBILITY_HANDLER(user_data);
  FlAccessibilityHandlerPrivate* priv =
      reinterpret_cast<FlAccessibilityHandlerPrivate*>(
          fl_accessibility_handler_get_instance_private(self));

  g_autoptr(FlEngine) engine = FL_ENGINE(g_weak_ref_get(&priv->engine));
  if (engine == nullptr) {
    return;
  }

  FlRenderable* renderable = fl_engine_get_renderable(engine, view_id);
  if (renderable == nullptr || !FL_IS_VIEW(renderable)) {
    return;
  }

  FlView* view = FL_VIEW(renderable);
  FlViewAccessible* accessible = fl_view_get_accessible(view);
  fl_view_accessible_send_announcement(
      accessible, message, assertiveness == FL_ASSERTIVENESS_ASSERTIVE);
}

static void fl_accessibility_handler_dispose(GObject* object) {
  FlAccessibilityHandler* self = FL_ACCESSIBILITY_HANDLER(object);
  FlAccessibilityHandlerPrivate* priv =
      reinterpret_cast<FlAccessibilityHandlerPrivate*>(
          fl_accessibility_handler_get_instance_private(self));

  g_weak_ref_clear(&priv->engine);
  g_clear_object(&priv->channel);

  G_OBJECT_CLASS(fl_accessibility_handler_parent_class)->dispose(object);
}

static void fl_accessibility_handler_class_init(
    FlAccessibilityHandlerClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = fl_accessibility_handler_dispose;
}

static void fl_accessibility_handler_init(FlAccessibilityHandler* self) {}

static FlAccessibilityChannelVTable accessibility_channel_vtable = {
    .send_announcement = send_announcement,
};

FlAccessibilityHandler* fl_accessibility_handler_new(FlEngine* engine) {
  g_return_val_if_fail(FL_IS_ENGINE(engine), nullptr);

  FlAccessibilityHandler* self = FL_ACCESSIBILITY_HANDLER(
      g_object_new(fl_accessibility_handler_get_type(), nullptr));
  FlAccessibilityHandlerPrivate* priv =
      reinterpret_cast<FlAccessibilityHandlerPrivate*>(
          fl_accessibility_handler_get_instance_private(self));

  g_weak_ref_init(&priv->engine, engine);
  priv->channel =
      fl_accessibility_channel_new(fl_engine_get_binary_messenger(engine),
                                   &accessibility_channel_vtable, self);

  return self;
}
