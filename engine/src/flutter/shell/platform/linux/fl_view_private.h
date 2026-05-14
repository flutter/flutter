// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_

#include "flutter/shell/platform/linux/fl_view_accessible.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

G_BEGIN_DECLS

/**
 * fl_view_get_accessible:
 * @view: an #FlView.
 *
 * Get the accessible object for this view.
 *
 * Returns: an #FlViewAccessible.
 */
FlViewAccessible* fl_view_get_accessible(FlView* view);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
