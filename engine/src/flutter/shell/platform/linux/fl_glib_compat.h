// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GLIB_COMPAT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GLIB_COMPAT_H_

#include <glib.h>

// Keep the size-safe API available with older GLib headers.
#if !GLIB_CHECK_VERSION(2, 68, 0)
inline gpointer g_memdup2(gconstpointer mem, gsize byte_size) {
  g_return_val_if_fail(byte_size <= G_MAXUINT, nullptr);
  return g_memdup(mem, static_cast<guint>(byte_size));
}
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GLIB_COMPAT_H_
