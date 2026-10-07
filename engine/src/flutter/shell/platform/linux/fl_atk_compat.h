// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_ATK_COMPAT_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_ATK_COMPAT_H_

// Newer GLib includes C++ support headers. Load those before entering the
// ATK C linkage block so their templates retain C++ linkage.
#include <glib.h>

// Older atkversion.h headers omit C linkage for the atk_get_*version APIs.
// Upstream fixed this in at-spi2-core 2.59.0, but distro backports may keep
// an older ATK version. GLib versions and sysroot names cannot identify the
// affected headers reliably. The wrapper also works with fixed headers, whose
// G_BEGIN_DECLS/G_END_DECLS simply nest the C linkage blocks. Remove it once
// all supported build headers contain the upstream fix.
// https://gitlab.gnome.org/GNOME/at-spi2-core/-/merge_requests/219
// https://bugs.debian.org/1145539
#ifdef __cplusplus
extern "C" {
#endif
#include <atk/atk.h>
#ifdef __cplusplus
}
#endif

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_ATK_COMPAT_H_
