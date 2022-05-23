// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/linux/fl_scrolling_view_delegate.h"

G_DEFINE_INTERFACE(FlScrollingViewDelegate,
                   fl_scrolling_view_delegate,
                   G_TYPE_OBJECT)

static void fl_scrolling_view_delegate_default_init(
    FlScrollingViewDelegateInterface* iface) {}

void fl_scrolling_view_delegate_send_mouse_pointer_event(
    FlScrollingViewDelegate* self,
    FlutterPointerPhase phase,
    size_t timestamp,
    double x,
    double y,
    double scroll_delta_x,
    double scroll_delta_y,
    int64_t buttons) {
  g_return_if_fail(FL_IS_SCROLLING_VIEW_DELEGATE(self));

  FL_SCROLLING_VIEW_DELEGATE_GET_IFACE(self)->send_mouse_pointer_event(
      self, phase, timestamp, x, y, scroll_delta_x, scroll_delta_y, buttons);
}
void fl_scrolling_view_delegate_send_pointer_pan_zoom_event(
    FlScrollingViewDelegate* self,
    size_t timestamp,
    double x,
    double y,
    FlutterPointerPhase phase,
    double pan_x,
    double pan_y,
    double scale,
    double rotation) {
  g_return_if_fail(FL_IS_SCROLLING_VIEW_DELEGATE(self));

  FL_SCROLLING_VIEW_DELEGATE_GET_IFACE(self)->send_pointer_pan_zoom_event(
      self, timestamp, x, y, phase, pan_x, pan_y, scale, rotation);
}
