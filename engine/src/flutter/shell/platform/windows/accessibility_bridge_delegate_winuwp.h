// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_BRIDGE_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_BRIDGE_DELEGATE_H_

#include "flutter/shell/platform/common/accessibility_bridge.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

class FlutterWindowsEngine;

// The Windows UWP implementation of AccessibilityBridgeDelegate.
//
// Handles requests from the accessibility bridge to interact with Windows
// accessibility APIs. This includes routing accessibility events fired from
// the framework to Windows, routing native Windows accessibility events to the
// framework, and creating Windows-specific FlutterPlatformNodeDelegate objects
// for each node in the semantics tree.
class AccessibilityBridgeDelegateWinUWP
    : public AccessibilityBridge::AccessibilityBridgeDelegate {
 public:
  explicit AccessibilityBridgeDelegateWinUWP(FlutterWindowsEngine* engine);
  virtual ~AccessibilityBridgeDelegateWinUWP() = default;

  // |AccessibilityBridge::AccessibilityBridgeDelegate|
  void OnAccessibilityEvent(
      ui::AXEventGenerator::TargetedEvent targeted_event) override;

  // |AccessibilityBridge::AccessibilityBridgeDelegate|
  void DispatchAccessibilityAction(AccessibilityNodeId target,
                                   FlutterSemanticsAction action,
                                   fml::MallocMapping data) override;

  // |AccessibilityBridge::AccessibilityBridgeDelegate|
  std::shared_ptr<FlutterPlatformNodeDelegate>
  CreateFlutterPlatformNodeDelegate() override;

 private:
  FlutterWindowsEngine* engine_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_BRIDGE_DELEGATE_H_
