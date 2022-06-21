// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_IM_CONTEXT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_IM_CONTEXT_H_

#include <gtk/gtk.h>

#include "gmock/gmock.h"

namespace flutter {
namespace testing {

class MockIMContext {
 public:
  ~MockIMContext();

  operator GtkIMContext*();

  MOCK_METHOD2(gtk_im_context_set_client_window,
               void(GtkIMContext* context, GdkWindow* window));
  MOCK_METHOD4(gtk_im_context_get_preedit_string,
               void(GtkIMContext* context,
                    gchar** str,
                    PangoAttrList** attrs,
                    gint* cursor_pos));
  MOCK_METHOD2(gtk_im_context_filter_keypress,
               gboolean(GtkIMContext* context, GdkEventKey* event));
  MOCK_METHOD1(gtk_im_context_focus_in, gboolean(GtkIMContext* context));
  MOCK_METHOD1(gtk_im_context_focus_out, void(GtkIMContext* context));
  MOCK_METHOD1(gtk_im_context_reset, void(GtkIMContext* context));
  MOCK_METHOD2(gtk_im_context_set_cursor_location,
               void(GtkIMContext* context, GdkRectangle* area));
  MOCK_METHOD2(gtk_im_context_set_use_preedit,
               void(GtkIMContext* context, gboolean use_preedit));
  MOCK_METHOD4(gtk_im_context_set_surrounding,
               void(GtkIMContext* context,
                    const gchar* text,
                    gint len,
                    gint cursor_index));
  MOCK_METHOD3(gtk_im_context_get_surrounding,
               gboolean(GtkIMContext* context,
                        gchar** text,
                        gint* cursor_index));

 private:
  GtkIMContext* instance_ = nullptr;
};

}  // namespace testing
}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_TESTING_MOCK_IM_CONTEXT_H_
