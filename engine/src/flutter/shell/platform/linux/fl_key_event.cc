// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_event.h"

static void dispose_origin_from_gdk_event(gpointer origin) {
  g_return_if_fail(origin != nullptr);
  gdk_event_free(reinterpret_cast<GdkEvent*>(origin));
}

FlKeyEvent* fl_key_event_new_from_gdk_event(GdkEvent* raw_event) {
  g_return_val_if_fail(raw_event != nullptr, nullptr);
  GdkEventKey* event = reinterpret_cast<GdkEventKey*>(raw_event);
  GdkEventType type = event->type;
  g_return_val_if_fail(type == GDK_KEY_PRESS || type == GDK_KEY_RELEASE,
                       nullptr);
  FlKeyEvent* result = g_new(FlKeyEvent, 1);

  result->time = event->time;
  result->is_press = type == GDK_KEY_PRESS;
  result->keycode = event->hardware_keycode;
  result->keyval = event->keyval;
  result->state = event->state;
  result->string = g_strdup(event->string);
  result->group = event->group;
  result->origin = event;
  result->dispose_origin = dispose_origin_from_gdk_event;

  return result;
}

void fl_key_event_dispose(FlKeyEvent* event) {
  if (event->string != nullptr) {
    g_free(const_cast<char*>(event->string));
  }
  if (event->dispose_origin != nullptr) {
    event->dispose_origin(event->origin);
  }
  g_free(event);
}

FlKeyEvent* fl_key_event_clone(const FlKeyEvent* event) {
  FlKeyEvent* new_event = g_new(FlKeyEvent, 1);
  *new_event = *event;
  new_event->string = g_strdup(event->string);
  return new_event;
}
