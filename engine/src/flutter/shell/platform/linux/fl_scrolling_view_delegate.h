// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_LINUX_FL_SCROLLING_VIEW_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_LINUX_FL_SCROLLING_VIEW_DELEGATE_H_

#include <gdk/gdk.h>
#include <cinttypes>
#include <memory>

#include "flutter/shell/platform/embedder/embedder.h"
#include "flutter/shell/platform/linux/fl_key_event.h"
#include "flutter/shell/platform/linux/public/flutter_linux/fl_binary_messenger.h"

G_BEGIN_DECLS

G_DECLARE_INTERFACE(FlScrollingViewDelegate,
                    fl_scrolling_view_delegate,
                    FL,
                    SCROLLING_VIEW_DELEGATE,
                    GObject);

/**
 * FlScrollingViewDelegate:
 *
 * An interface for a class that provides `FlScrollingManager` with
 * platform-related features.
 *
 * This interface is typically implemented by `FlView`.
 */

struct _FlScrollingViewDelegateInterface {
  GTypeInterface g_iface;

  void (*send_mouse_pointer_event)(FlScrollingViewDelegate* delegate,
                                   FlutterPointerPhase phase,
                                   size_t timestamp,
                                   double x,
                                   double y,
                                   double scroll_delta_x,
                                   double scroll_delta_y,
                                   int64_t buttons);

  void (*send_pointer_pan_zoom_event)(FlScrollingViewDelegate* delegate,
                                      size_t timestamp,
                                      double x,
                                      double y,
                                      FlutterPointerPhase phase,
                                      double pan_x,
                                      double pan_y,
                                      double scale,
                                      double rotation);
};

void fl_scrolling_view_delegate_send_mouse_pointer_event(
    FlScrollingViewDelegate* delegate,
    FlutterPointerPhase phase,
    size_t timestamp,
    double x,
    double y,
    double scroll_delta_x,
    double scroll_delta_y,
    int64_t buttons);
void fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
    FlScrollingViewDelegate* delegate,
    size_t timestamp,
    double x,
    double y,
    FlutterPointerPhase phase,
    double pan_x,
    double pan_y,
    double scale,
    double rotation);

G_END_DECLS

#endif  // FLUTTER_SHELL_PLATFORM_LINUX_FL_SCROLLING_VIEW_DELEGATE_H_
