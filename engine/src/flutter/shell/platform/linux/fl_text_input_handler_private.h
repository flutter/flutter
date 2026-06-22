// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_TEXT_INPUT_HANDLER_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_TEXT_INPUT_HANDLER_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_text_input_channel.h"
#include "flutter/shell/platform/linux/fl_text_input_handler.h"

namespace flutter {
class TextInputModel;
}

struct _FlTextInputHandler {
  GObject parent_instance;

  FlTextInputChannel* channel;

  // The widget with input focus.
  GtkWidget* widget;

  // Client ID provided by Flutter to report events with.
  int64_t client_id;

  // Input action to perform when enter pressed.
  gchar* input_action;

  // The type of the input method.
  FlTextInputType input_type;

  // Whether to enable that the engine sends text input updates to the
  // framework as TextEditingDeltas or as one TextEditingValue.
  // For more information on the delta model, see:
  // https://master-api.flutter.dev/flutter/services/
  // TextInputConfiguration/enableDeltaModel.html
  gboolean enable_delta_model;

  // Input method.
  GtkIMContext* im_context;

  flutter::TextInputModel* text_model;

  // A 4x4 matrix that maps from `EditableText` local coordinates to the
  // coordinate system of `PipelineOwner.rootNode`.
  double editabletext_transform[4][4];

  // The smallest rect, in local coordinates, of the text in the composing
  // range, or of the caret in the case where there is no current composing
  // range. This value is updated via `TextInput.setMarkedTextRect` messages
  // over the text input channel.
  GdkRectangle composing_rect;

  GCancellable* cancellable;
};

#if FLUTTER_LINUX_GTK4
void fl_text_input_handler_gtk4_update_im_cursor_position(
    FlTextInputHandler* self);

void fl_text_input_handler_gtk4_set_widget(FlTextInputHandler* self,
                                           GtkWidget* widget);
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_TEXT_INPUT_HANDLER_PRIVATE_H_
