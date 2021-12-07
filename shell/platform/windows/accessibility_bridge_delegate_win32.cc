// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/accessibility_bridge_delegate_win32.h"

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_win32.h"
#include "flutter/shell/platform/windows/flutter_windows_view.h"
#include "flutter/third_party/accessibility/ax/platform/ax_platform_node_delegate_base.h"

namespace flutter {

AccessibilityBridgeDelegateWin32::AccessibilityBridgeDelegateWin32(
    FlutterWindowsEngine* engine)
    : engine_(engine) {
  assert(engine_);
}

void AccessibilityBridgeDelegateWin32::OnAccessibilityEvent(
    ui::AXEventGenerator::TargetedEvent targeted_event) {
  // TODO(cbracken): https://github.com/flutter/flutter/issues/77838
}

void AccessibilityBridgeDelegateWin32::DispatchAccessibilityAction(
    AccessibilityNodeId target,
    FlutterSemanticsAction action,
    fml::MallocMapping data) {
  engine_->DispatchSemanticsAction(target, action, std::move(data));
}

std::shared_ptr<FlutterPlatformNodeDelegate>
AccessibilityBridgeDelegateWin32::CreateFlutterPlatformNodeDelegate() {
  return std::make_shared<FlutterPlatformNodeDelegateWin32>(engine_);
}

}  // namespace flutter
