// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_IOS_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_IOS_H_

#include <memory>
#include <vector>

#include "flutter/lib/ui/semantics/semantics_node.h"

@class UIView;

namespace flutter {
class FlutterPlatformViewsController;

/// Interface that represents an accessibility bridge for iOS.
class AccessibilityBridgeIos {
 public:
  virtual ~AccessibilityBridgeIos() = default;
  virtual UIView* view() const = 0;
  virtual UIView<UITextInput>* textInputView() = 0;
  virtual void DispatchSemanticsAction(int32_t id, flutter::SemanticsAction action) = 0;
  virtual void DispatchSemanticsAction(int32_t id,
                                       flutter::SemanticsAction action,
                                       std::vector<uint8_t> args) = 0;
  /**
   * A callback that is called when a SemanticObject receives focus.
   *
   * The input id is the uid of the newly focused SemanticObject.
   */
  virtual void AccessibilityObjectDidBecomeFocused(int32_t id) = 0;
  /**
   * A callback that is called when a SemanticObject loses focus
   *
   * The input id is the uid of the newly focused SemanticObject.
   */
  virtual void AccessibilityObjectDidLoseFocus(int32_t id) = 0;
  virtual std::shared_ptr<FlutterPlatformViewsController> GetPlatformViewsController() const = 0;
};

}  // namespace flutter

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_IOS_H_
