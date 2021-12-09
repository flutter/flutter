// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_BRIDGE_DELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_BRIDGE_DELEGATE_H_

#include "flutter/shell/platform/common/accessibility_bridge.h"

#include "flutter/shell/platform/windows/flutter_platform_node_delegate_win32.h"
#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

class FlutterWindowsEngine;

// The Win32 implementation of AccessibilityBridgeDelegate.
//
// Handles requests from the accessibility bridge to interact with Windows
// accessibility APIs. This includes routing accessibility events fired from
// the framework to Windows, routing native Windows accessibility events to the
// framework, and creating Windows-specific FlutterPlatformNodeDelegate objects
// for each node in the semantics tree.
class AccessibilityBridgeDelegateWin32
    : public AccessibilityBridge::AccessibilityBridgeDelegate {
 public:
  explicit AccessibilityBridgeDelegateWin32(FlutterWindowsEngine* engine);
  virtual ~AccessibilityBridgeDelegateWin32() = default;

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

  // Dispatches a Windows accessibility event of the specified type, generated
  // by the accessibility node associated with the specified semantics node.
  virtual void DispatchWinAccessibilityEvent(
      std::shared_ptr<FlutterPlatformNodeDelegateWin32> node_delegate,
      DWORD event_type);

  // Sets the accessibility focus to the accessibility node associated with the
  // specified semantics node.
  virtual void SetFocus(
      std::shared_ptr<FlutterPlatformNodeDelegateWin32> node_delegate);

 private:
  FlutterWindowsEngine* engine_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_ACCESSIBILITY_BRIDGE_DELEGATE_H_
