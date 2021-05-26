// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/testing/mock_text_input_plugin.h"

struct _FlMockTextInputPlugin {
  FlTextInputPlugin parent_instance;

  gboolean (*filter_keypress)(FlTextInputPlugin* self, FlKeyEvent* event);
};

G_DEFINE_TYPE(FlMockTextInputPlugin,
              fl_mock_text_input_plugin,
              fl_text_input_plugin_get_type())

static gboolean mock_text_input_plugin_filter_keypress(FlTextInputPlugin* self,
                                                       FlKeyEvent* event) {
  FlMockTextInputPlugin* mock_self = FL_MOCK_TEXT_INPUT_PLUGIN(self);
  if (mock_self->filter_keypress) {
    return mock_self->filter_keypress(self, event);
  }
  return FALSE;
}

static void fl_mock_text_input_plugin_class_init(
    FlMockTextInputPluginClass* klass) {
  FL_TEXT_INPUT_PLUGIN_CLASS(klass)->filter_keypress =
      mock_text_input_plugin_filter_keypress;
}

static void fl_mock_text_input_plugin_init(FlMockTextInputPlugin* self) {}

// Creates a mock text_input_plugin
FlMockTextInputPlugin* fl_mock_text_input_plugin_new(
    gboolean (*filter_keypress)(FlTextInputPlugin* self, FlKeyEvent* event)) {
  FlMockTextInputPlugin* self = FL_MOCK_TEXT_INPUT_PLUGIN(
      g_object_new(fl_mock_text_input_plugin_get_type(), nullptr));
  self->filter_keypress = filter_keypress;
  return self;
}
