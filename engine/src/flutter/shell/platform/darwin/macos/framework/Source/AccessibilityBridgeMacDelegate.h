// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_ACCESSIBILITYBRIDGEMACDELEGATE_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_ACCESSIBILITYBRIDGEMACDELEGATE_H_

#import <Cocoa/Cocoa.h>

#include "flutter/shell/platform/common/accessibility_bridge.h"

@class FlutterEngine;
@class FlutterViewController;

namespace flutter {

//------------------------------------------------------------------------------
/// The macOS implementation of AccessibilityBridge::AccessibilityBridgeDelegate.
/// This delegate is used to create AccessibilityBridge in the macOS embedding.
class AccessibilityBridgeMacDelegate : public AccessibilityBridge::AccessibilityBridgeDelegate {
 public:
  //---------------------------------------------------------------------------
  /// @brief      Creates an AccessibilityBridgeMacDelegate.
  /// @param[in]  flutter_engine     The weak reference to the FlutterEngine.
  /// @param[in]  view_controller    The weak reference to the FlutterViewController.
  explicit AccessibilityBridgeMacDelegate(__weak FlutterEngine* flutter_engine,
                                          __weak FlutterViewController* view_controller);
  virtual ~AccessibilityBridgeMacDelegate() = default;

  // |AccessibilityBridge::AccessibilityBridgeDelegate|
  void OnAccessibilityEvent(ui::AXEventGenerator::TargetedEvent targeted_event) override;

  // |AccessibilityBridge::AccessibilityBridgeDelegate|
  void DispatchAccessibilityAction(AccessibilityNodeId target,
                                   FlutterSemanticsAction action,
                                   fml::MallocMapping data) override;

  // |AccessibilityBridge::AccessibilityBridgeDelegate|
  std::shared_ptr<FlutterPlatformNodeDelegate> CreateFlutterPlatformNodeDelegate() override;

 private:
  /// A wrapper structure to wraps macOS native accessibility events.
  struct NSAccessibilityEvent {
    NSAccessibilityNotificationName name;
    gfx::NativeViewAccessible target;
    NSDictionary* user_info;
  };

  //---------------------------------------------------------------------------
  /// @brief      Posts the given event against the given node to the macOS
  ///             accessibility notification system.
  /// @param[in]  native_node       The event target, must not be nil.
  /// @param[in]  mac_notification  The event name, must not be nil.
  virtual void DispatchMacOSNotification(gfx::NativeViewAccessible native_node,
                                         NSAccessibilityNotificationName mac_notification);

  //---------------------------------------------------------------------------
  /// @brief      Posts the given event against the given node with the
  ///             additional attributes to the macOS accessibility notification
  ///             system.
  /// @param[in]  native_node       The event target, must not be nil.
  /// @param[in]  mac_notification  The event name, must not be nil.
  /// @param[in]  user_info         The additional attributes, must not be nil.
  void DispatchMacOSNotificationWithUserInfo(gfx::NativeViewAccessible native_node,
                                             NSAccessibilityNotificationName mac_notification,
                                             NSDictionary* user_info);

  //---------------------------------------------------------------------------
  /// @brief      Whether the given event is in current pending events.
  /// @param[in]  event_type        The event to look up.
  bool HasPendingEvent(ui::AXEventGenerator::Event event) const;

  //---------------------------------------------------------------------------
  /// @brief      Converts the give ui::AXEventGenerator::Event into
  ///             macOS native accessibility event[s]
  /// @param[in]  event_type        The original event type.
  /// @param[in]  ax_node           The original event target.
  std::vector<NSAccessibilityEvent> MacOSEventsFromAXEvent(ui::AXEventGenerator::Event event_type,
                                                           const ui::AXNode& ax_node) const;

  __weak FlutterEngine* flutter_engine_;
  __weak FlutterViewController* view_controller_;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_MACOS_FRAMEWORK_SOURCE_ACCESSIBILITYBRIDGEMACDELEGATE_H_
