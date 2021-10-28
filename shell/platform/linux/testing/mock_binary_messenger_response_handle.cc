// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_binary_messenger_response_handle.h"

struct _FlMockBinaryMessengerResponseHandle {
  FlBinaryMessengerResponseHandle parent_instance;
};

G_DEFINE_TYPE(FlMockBinaryMessengerResponseHandle,
              fl_mock_binary_messenger_response_handle,
              fl_binary_messenger_response_handle_get_type());

static void fl_mock_binary_messenger_response_handle_class_init(
    FlMockBinaryMessengerResponseHandleClass* klass) {}

static void fl_mock_binary_messenger_response_handle_init(
    FlMockBinaryMessengerResponseHandle* self) {}

FlMockBinaryMessengerResponseHandle*
fl_mock_binary_messenger_response_handle_new() {
  return FL_MOCK_BINARY_MESSENGER_RESPONSE_HANDLE(
      g_object_new(fl_mock_binary_messenger_response_handle_get_type(), NULL));
}
