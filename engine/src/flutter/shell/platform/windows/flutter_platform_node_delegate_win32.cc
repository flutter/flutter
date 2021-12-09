// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <oleacc.h>

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_win32.h"

#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

FlutterPlatformNodeDelegateWin32::FlutterPlatformNodeDelegateWin32(
    FlutterWindowsEngine* engine)
    : engine_(engine) {
  assert(engine_);
}

FlutterPlatformNodeDelegateWin32::~FlutterPlatformNodeDelegateWin32() {
  if (ax_platform_node_) {
    ax_platform_node_->Destroy();
  }
}

// |ui::AXPlatformNodeDelegate|
void FlutterPlatformNodeDelegateWin32::Init(std::weak_ptr<OwnerBridge> bridge,
                                            ui::AXNode* node) {
  FlutterPlatformNodeDelegate::Init(bridge, node);
  ax_platform_node_ = ui::AXPlatformNode::Create(this);
  assert(ax_platform_node_);
}

// |ui::AXPlatformNodeDelegate|
gfx::NativeViewAccessible
FlutterPlatformNodeDelegateWin32::GetNativeViewAccessible() {
  assert(ax_platform_node_);
  return ax_platform_node_->GetNativeViewAccessible();
}

// |FlutterPlatformNodeDelegate|
gfx::NativeViewAccessible FlutterPlatformNodeDelegateWin32::GetParent() {
  gfx::NativeViewAccessible parent = FlutterPlatformNodeDelegate::GetParent();
  if (parent) {
    return parent;
  }
  assert(engine_);
  FlutterWindowsView* view = engine_->view();
  if (!view) {
    return nullptr;
  }
  HWND hwnd = view->GetPlatformWindow();
  if (!hwnd) {
    return nullptr;
  }

  IAccessible* iaccessible_parent;
  if (SUCCEEDED(::AccessibleObjectFromWindow(
          hwnd, OBJID_WINDOW, IID_IAccessible,
          reinterpret_cast<void**>(&iaccessible_parent)))) {
    return iaccessible_parent;
  }
  return nullptr;
}

// |FlutterPlatformNodeDelegate|
gfx::Rect FlutterPlatformNodeDelegateWin32::GetBoundsRect(
    const ui::AXCoordinateSystem coordinate_system,
    const ui::AXClippingBehavior clipping_behavior,
    ui::AXOffscreenResult* offscreen_result) const {
  gfx::Rect bounds = FlutterPlatformNodeDelegate::GetBoundsRect(
      coordinate_system, clipping_behavior, offscreen_result);
  POINT origin{bounds.x(), bounds.y()};
  POINT extent{bounds.x() + bounds.width(), bounds.y() + bounds.height()};
  ClientToScreen(engine_->view()->GetPlatformWindow(), &origin);
  ClientToScreen(engine_->view()->GetPlatformWindow(), &extent);
  return gfx::Rect(origin.x, origin.y, extent.x - origin.x,
                   extent.y - origin.y);
}

void FlutterPlatformNodeDelegateWin32::DispatchWinAccessibilityEvent(
    DWORD event_type) {
  FlutterWindowsView* view = engine_->view();
  if (!view) {
    return;
  }
  HWND hwnd = view->GetPlatformWindow();
  if (!hwnd) {
    return;
  }
  assert(ax_platform_node_);
  ::NotifyWinEvent(event_type, hwnd, OBJID_CLIENT,
                   -ax_platform_node_->GetUniqueId());
}

void FlutterPlatformNodeDelegateWin32::SetFocus() {
  VARIANT varchild{};
  varchild.vt = VT_I4;
  varchild.lVal = CHILDID_SELF;
  GetNativeViewAccessible()->accSelect(SELFLAG_TAKEFOCUS, varchild);
}

}  // namespace flutter
