// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_LINUX_DEBUG_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_LINUX_DEBUG_H_

#include <cstdarg>

#include <glib.h>
#include <glib/gprintf.h>

inline gboolean flutter_linux_gtk_debug_enabled() {
  const gchar* value = g_getenv("FLUTTER_LINUX_GTK_DEBUG");
  if (value == nullptr || value[0] == '\0') {
    return FALSE;
  }
  return g_ascii_strcasecmp(value, "0") != 0 &&
         g_ascii_strcasecmp(value, "false") != 0 &&
         g_ascii_strcasecmp(value, "off") != 0;
}

inline void flutter_linux_dbg(const char* event, const char* format, ...) {
  if (!flutter_linux_gtk_debug_enabled()) {
    return;
  }

  va_list args;
  g_print("flutter_linux_dbg event=%s ", event);
  va_start(args, format);
  if (format != nullptr && format[0] != '\0') {
    g_vprintf(format, args);
  }
  va_end(args);
  g_print("\n");
}

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_LINUX_DEBUG_H_
