// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_

#include "flutter/shell/platform/linux/public/flutter_linux/fl_view.h"

/**
 * fl_view_redraw:
 * @view: an #FlView.
 *
 * Indicate the view needs to redraw.
 */
void fl_view_redraw(FlView* view);

/**
 * fl_view_get_keyboard_state:
 * @view: an #FlView.
 *
 * Returns the keyboard pressed state. The hash table contains one entry per
 * pressed keys, mapping from the logical key to the physical key.*
 */
GHashTable* fl_view_get_keyboard_state(FlView* view);

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_VIEW_PRIVATE_H_
