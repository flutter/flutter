// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_text_input_handler.h"

struct _FlMockTextInputHandler {
  FlTextInputHandler parent_instance;

  gboolean (*filter_keypress)(FlTextInputHandler* self, FlKeyEvent* event);
};

G_DEFINE_TYPE(FlMockTextInputHandler,
              fl_mock_text_input_handler,
              fl_text_input_handler_get_type())

static gboolean mock_text_input_handler_filter_keypress(
    FlTextInputHandler* self,
    FlKeyEvent* event) {
  FlMockTextInputHandler* mock_self = FL_MOCK_TEXT_INPUT_HANDLER(self);
  if (mock_self->filter_keypress) {
    return mock_self->filter_keypress(self, event);
  }
  return FALSE;
}

static void fl_mock_text_input_handler_class_init(
    FlMockTextInputHandlerClass* klass) {
  FL_TEXT_INPUT_HANDLER_CLASS(klass)->filter_keypress =
      mock_text_input_handler_filter_keypress;
}

static void fl_mock_text_input_handler_init(FlMockTextInputHandler* self) {}

// Creates a mock text_input_handler
FlMockTextInputHandler* fl_mock_text_input_handler_new(
    gboolean (*filter_keypress)(FlTextInputHandler* self, FlKeyEvent* event)) {
  FlMockTextInputHandler* self = FL_MOCK_TEXT_INPUT_HANDLER(
      g_object_new(fl_mock_text_input_handler_get_type(), nullptr));
  self->filter_keypress = filter_keypress;
  return self;
}
