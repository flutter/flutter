// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_key_responder.h"

G_DEFINE_INTERFACE(FlKeyResponder, fl_key_responder, G_TYPE_OBJECT)

static void fl_key_responder_default_init(FlKeyResponderInterface* iface) {}

void fl_key_responder_handle_event(FlKeyResponder* self,
                                   FlKeyEvent* event,
                                   FlKeyResponderAsyncCallback callback,
                                   gpointer user_data,
                                   uint64_t specified_logical_key) {
  g_return_if_fail(FL_IS_KEY_RESPONDER(self));
  g_return_if_fail(event != nullptr);
  g_return_if_fail(callback != nullptr);

  FL_KEY_RESPONDER_GET_IFACE(self)->handle_event(
      self, event, specified_logical_key, callback, user_data);
}
