// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_text_input_handler_private.h"

#include "flutter/shell/platform/common/text_input_model.h"
#include "flutter/shell/platform/linux/fl_gtk.h"

void fl_text_input_handler_gtk4_update_im_cursor_position(
    FlTextInputHandler* self) {
  // Skip update if not composing to avoid setting to position 0.
  if (!self->text_model->composing()) {
    return;
  }

  // Transform the x, y positions of the cursor from local coordinates to
  // Flutter view coordinates.
  double x = self->composing_rect.x * self->editabletext_transform[0][0] +
             self->composing_rect.y * self->editabletext_transform[1][0] +
             self->editabletext_transform[3][0] + self->composing_rect.width;
  double y = self->composing_rect.x * self->editabletext_transform[0][1] +
             self->composing_rect.y * self->editabletext_transform[1][1] +
             self->editabletext_transform[3][1] + self->composing_rect.height;

  // Transform from Flutter view coordinates to GTK window coordinates.
  GdkRectangle preedit_rect = {};
  GtkWidget* toplevel = GTK_WIDGET(gtk_widget_get_root(self->widget));
  double dest_x = 0.0;
  double dest_y = 0.0;
  gtk_widget_translate_coordinates(self->widget, toplevel, x, y, &dest_x,
                                   &dest_y);
  preedit_rect.x = static_cast<int>(dest_x);
  preedit_rect.y = static_cast<int>(dest_y);

  // Set the cursor location in window coordinates so that GTK can position
  // any system input method windows.
  gtk_im_context_set_cursor_location(self->im_context, &preedit_rect);
}

void fl_text_input_handler_gtk4_set_widget(FlTextInputHandler* self,
                                           GtkWidget* widget) {
  self->widget = widget;
  gtk_im_context_set_client_widget(self->im_context, widget);
}
