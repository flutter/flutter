// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_PLATFORM_HANDLER_GTK4_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_PLATFORM_HANDLER_GTK4_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_method_channel.h"

G_BEGIN_DECLS

FlMethodResponse* fl_platform_handler_gtk4_clipboard_set_data(
    FlMethodCall* method_call,
    const gchar* text);

FlMethodResponse* fl_platform_handler_gtk4_clipboard_get_data(
    FlMethodCall* method_call,
    const gchar* format);

FlMethodResponse* fl_platform_handler_gtk4_clipboard_has_strings(
    FlMethodCall* method_call);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_PLATFORM_HANDLER_GTK4_H_
