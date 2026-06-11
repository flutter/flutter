// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_GDK_PLATFORM_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_GDK_PLATFORM_H_

#if FLUTTER_LINUX_GTK4
#include <gdk/wayland/gdkwayland.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/x11/gdkx.h>
#endif
#else
#include <gdk/gdkwayland.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_GDK_PLATFORM_H_
