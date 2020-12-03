// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_text_input_plugin.h"

G_BEGIN_DECLS

G_DECLARE_FINAL_TYPE(FlMockTextInputPlugin,
                     fl_mock_text_input_plugin,
                     FL,
                     MOCK_TEXT_INPUT_PLUGIN,
                     FlTextInputPlugin)

FlMockTextInputPlugin* fl_mock_text_input_plugin_new(
    gboolean (*filter_keypress)(FlTextInputPlugin* self, GdkEventKey* event));

G_END_DECLS
