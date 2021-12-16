// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <oleacc.h>

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_win32.h"

#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/third_party/accessibility/ax/ax_clipping_behavior.h"
#include "flutter/third_party/accessibility/ax/ax_coordinate_system.h"

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

// |ui::AXPlatformNodeDelegate|
gfx::NativeViewAccessible FlutterPlatformNodeDelegateWin32::HitTestSync(
    int screen_physical_pixel_x,
    int screen_physical_pixel_y) const {
  // If this node doesn't contain the point, return.
  ui::AXOffscreenResult result;
  gfx::Rect rect = GetBoundsRect(ui::AXCoordinateSystem::kScreenPhysicalPixels,
                                 ui::AXClippingBehavior::kUnclipped, &result);
  gfx::Point screen_point(screen_physical_pixel_x, screen_physical_pixel_y);
  if (!rect.Contains(screen_point)) {
    return nullptr;
  }

  // If any child in this node's subtree contains the point, return that child.
  auto bridge = engine_->accessibility_bridge().lock();
  assert(bridge);
  for (const ui::AXNode* child : GetAXNode()->children()) {
    std::shared_ptr<FlutterPlatformNodeDelegateWin32> win_delegate =
        std::static_pointer_cast<FlutterPlatformNodeDelegateWin32>(
            bridge->GetFlutterPlatformNodeDelegateFromID(child->id()).lock());
    assert(win_delegate);
    auto hit_view = win_delegate->HitTestSync(screen_physical_pixel_x,
                                              screen_physical_pixel_y);
    if (hit_view) {
      return hit_view;
    }
  }

  // If no children contain the point, but this node does, return this node.
  return ax_platform_node_->GetNativeViewAccessible();
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
