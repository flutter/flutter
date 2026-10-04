// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_signal_handler.h"

namespace flutter {
namespace testing {

SignalHandler::SignalHandler(gpointer instance,
                             const gchar* name,
                             GCallback callback) {
  id_ = g_signal_connect_data(instance, name, callback, this, nullptr,
                              G_CONNECT_SWAPPED);
  g_weak_ref_init(&instance_, instance);
}

SignalHandler::~SignalHandler() {
  g_autoptr(GObject) instance = G_OBJECT(g_weak_ref_get(&instance_));
  if (instance != nullptr) {
    g_signal_handler_disconnect(instance, id_);
  }
  g_weak_ref_clear(&instance_);
}

}  // namespace testing
}  // namespace flutter
