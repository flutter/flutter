// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_PLATFORM_NODE_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_PLATFORM_NODE_DELEGATE_H_

#include "flutter/shell/platform/common/flutter_platform_node_delegate.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node.h"

namespace flutter {

class FlutterWindowsEngine;

// The Windows UWP implementation of FlutterPlatformNodeDelegate.
//
// This class implements a wrapper around the Windows UWP accessibility objects
// that compose the accessibility tree.
class FlutterPlatformNodeDelegateWinUWP : public FlutterPlatformNodeDelegate {
 public:
  explicit FlutterPlatformNodeDelegateWinUWP(FlutterWindowsEngine* engine);
  virtual ~FlutterPlatformNodeDelegateWinUWP();

  // |ui::AXPlatformNodeDelegate|
  void Init(std::weak_ptr<OwnerBridge> bridge, ui::AXNode* node) override;

  // |ui::AXPlatformNodeDelegate|
  gfx::NativeViewAccessible GetNativeViewAccessible() override;

  // |FlutterPlatformNodeDelegate|
  gfx::NativeViewAccessible GetParent() override;

  // |FlutterPlatformNodeDelegate|
  gfx::Rect GetBoundsRect(
      const ui::AXCoordinateSystem coordinate_system,
      const ui::AXClippingBehavior clipping_behavior,
      ui::AXOffscreenResult* offscreen_result) const override;

 private:
  ui::AXPlatformNode* ax_platform_node_;
  FlutterWindowsEngine* engine_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_FLUTTER_PLATFORM_NODE_DELEGATE_H_
