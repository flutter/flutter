// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ATK_COMPAT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ATK_COMPAT_H_

#ifdef __cplusplus
#include <type_traits>
#endif

#if !FLUTTER_LINUX_GTK4
// Workaround missing C code compatibility in ATK header.
// Fixed in https://gitlab.gnome.org/GNOME/at-spi2-core/-/merge_requests/219
#ifdef __cplusplus
extern "C" {
#endif
#include <atk/atk.h>
#ifdef __cplusplus
}
#endif
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ATK_COMPAT_H_
