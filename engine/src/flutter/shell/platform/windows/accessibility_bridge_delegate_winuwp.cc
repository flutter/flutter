// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/accessibility_bridge_delegate_winuwp.h"

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_winuwp.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_delegate_base.h"

namespace flutter {

AccessibilityBridgeDelegateWinUWP::AccessibilityBridgeDelegateWinUWP(
    FlutterWindowsEngine* engine)
    : engine_(engine) {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/93928
  assert(engine_);
}

void AccessibilityBridgeDelegateWinUWP::OnAccessibilityEvent(
    ui::AXEventGenerator::TargetedEvent targeted_event) {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/93928
}

void AccessibilityBridgeDelegateWinUWP::DispatchAccessibilityAction(
    AccessibilityNodeId target,
    FlutterSemanticsAction action,
    fml::MallocMapping data) {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/93928
}

std::shared_ptr<FlutterPlatformNodeDelegate>
AccessibilityBridgeDelegateWinUWP::CreateFlutterPlatformNodeDelegate() {
  return std::make_shared<FlutterPlatformNodeDelegateWinUWP>(engine_);
}

}  // namespace flutter
