// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <oleacc.h>

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_winuwp.h"

#include "flutter/shell/platform/windows/flutter_windows_view.h"

namespace flutter {

FlutterPlatformNodeDelegateWinUWP::FlutterPlatformNodeDelegateWinUWP(
    FlutterWindowsEngine* engine)
    : engine_(engine) {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/93928
  assert(engine_);
}

FlutterPlatformNodeDelegateWinUWP::~FlutterPlatformNodeDelegateWinUWP() {
  if (ax_platform_node_) {
    ax_platform_node_->Destroy();
  }
}

// |ui::AXPlatformNodeDelegate|
void FlutterPlatformNodeDelegateWinUWP::Init(std::weak_ptr<OwnerBridge> bridge,
                                             ui::AXNode* node) {
  FlutterPlatformNodeDelegate::Init(bridge, node);
  ax_platform_node_ = ui::AXPlatformNode::Create(this);
  assert(ax_platform_node_);
}

// |ui::AXPlatformNodeDelegate|
gfx::NativeViewAccessible
FlutterPlatformNodeDelegateWinUWP::GetNativeViewAccessible() {
  assert(ax_platform_node_);
  return ax_platform_node_->GetNativeViewAccessible();
}

// |FlutterPlatformNodeDelegate|
gfx::NativeViewAccessible FlutterPlatformNodeDelegateWinUWP::GetParent() {
  gfx::NativeViewAccessible parent = FlutterPlatformNodeDelegate::GetParent();
  if (parent) {
    return parent;
  }
  assert(engine_);
  FlutterWindowsView* view = engine_->view();
  if (!view) {
    return nullptr;
  }
  // TODO(cbracken): https://github.com/flutter/flutter/issues/93928
  // Use FlutterWindowsView::GetPlatformView to get the root view, and return
  // the associated accessibility object.
  return nullptr;
}

// |FlutterPlatformNodeDelegate|
gfx::Rect FlutterPlatformNodeDelegateWinUWP::GetBoundsRect(
    const ui::AXCoordinateSystem coordinate_system,
    const ui::AXClippingBehavior clipping_behavior,
    ui::AXOffscreenResult* offscreen_result) const {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/93928
  return {};
}

}  // namespace flutter
