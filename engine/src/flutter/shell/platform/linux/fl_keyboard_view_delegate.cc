// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_keyboard_view_delegate.h"

G_DEFINE_INTERFACE(FlKeyboardViewDelegate,
                   fl_keyboard_view_delegate,
                   G_TYPE_OBJECT)

static void fl_keyboard_view_delegate_default_init(
    FlKeyboardViewDelegateInterface* iface) {}

void fl_keyboard_view_delegate_send_key_event(FlKeyboardViewDelegate* self,
                                              const FlutterKeyEvent* event,
                                              FlutterKeyEventCallback callback,
                                              void* user_data) {
  g_return_if_fail(FL_IS_KEYBOARD_VIEW_DELEGATE(self));
  g_return_if_fail(event != nullptr);

  FL_KEYBOARD_VIEW_DELEGATE_GET_IFACE(self)->send_key_event(
      self, event, callback, user_data);
}

gboolean fl_keyboard_view_delegate_text_filter_key_press(
    FlKeyboardViewDelegate* self,
    FlKeyEvent* event) {
  g_return_val_if_fail(FL_IS_KEYBOARD_VIEW_DELEGATE(self), false);
  g_return_val_if_fail(event != nullptr, false);

  return FL_KEYBOARD_VIEW_DELEGATE_GET_IFACE(self)->text_filter_key_press(
      self, event);
}

void fl_keyboard_view_delegate_redispatch_event(FlKeyboardViewDelegate* self,
                                                FlKeyEvent* event) {
  g_return_if_fail(FL_IS_KEYBOARD_VIEW_DELEGATE(self));
  g_return_if_fail(event != nullptr);

  return FL_KEYBOARD_VIEW_DELEGATE_GET_IFACE(self)->redispatch_event(self,
                                                                     event);
}

guint fl_keyboard_view_delegate_lookup_key(FlKeyboardViewDelegate* self,
                                           const GdkKeymapKey* key) {
  g_return_val_if_fail(FL_IS_KEYBOARD_VIEW_DELEGATE(self), 0);

  return FL_KEYBOARD_VIEW_DELEGATE_GET_IFACE(self)->lookup_key(self, key);
}

GHashTable* fl_keyboard_view_delegate_get_keyboard_state(
    FlKeyboardViewDelegate* self) {
  g_return_val_if_fail(FL_IS_KEYBOARD_VIEW_DELEGATE(self), nullptr);

  return FL_KEYBOARD_VIEW_DELEGATE_GET_IFACE(self)->get_keyboard_state(self);
}
