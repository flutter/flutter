// flutter/shell/platform/linux/fl_glib_compat.h

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GLIB_COMPAT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GLIB_COMPAT_H_

#include <glib.h>

#if !GLIB_CHECK_VERSION(2, 68, 0)
inline gpointer g_memdup2(gconstpointer mem, gsize byte_size) {
  g_return_val_if_fail(byte_size <= G_MAXUINT, nullptr);
  return g_memdup(mem, static_cast<guint>(byte_size));
}
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GLIB_COMPAT_H_
