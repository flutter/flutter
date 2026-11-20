// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_IOS_H_
#define FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_IOS_H_

#include <memory>
#include <vector>

#import "flutter/fml/mapping.h"
#include "flutter/lib/ui/semantics/semantics_node.h"

@class UIView;
@class FlutterPlatformViewsController;
@class SemanticsObject;

namespace flutter {

/// Interface that represents an accessibility bridge for iOS.
class AccessibilityBridgeIos {
 public:
  virtual ~AccessibilityBridgeIos() = default;
  virtual UIView* view() const = 0;
  // Returns the current Flutter view without forcing the owner view controller to load its view.
  virtual UIView* ViewIfLoaded() const = 0;
  // Returns a nonnull container used only to initialize UIAccessibilityElements without loading
  // the owner view controller's view. SemanticsObject overrides accessibilityContainer, so this
  // view is never exposed as the semantics tree's actual container.
  virtual UIView* AccessibilityElementInitializationContainer() const = 0;
  virtual bool isVoiceOverRunning() const = 0;
  virtual UIView<UITextInput>* textInputView() = 0;
  virtual void DispatchSemanticsAction(int32_t id, flutter::SemanticsAction action) = 0;
  virtual void DispatchSemanticsAction(int32_t id,
                                       flutter::SemanticsAction action,
                                       fml::MallocMapping args) = 0;
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
  virtual NSString* GetDefaultLocale() = 0;
  virtual FlutterPlatformViewsController* GetPlatformViewsController() const = 0;
  /**
   * The semantics object that a Full Keyboard Access Tab or Shift+Tab
   * should move focus to, or nil if there is none.
   *
   * The iOS focus engine only considers items that are roughly on screen, so
   * with Tab it skips offscreen items in a scrollable and wraps around before
   * reaching the end of the list. To correct this,
   * -[SemanticsObject shouldUpdateFocusInContext:] rejects a Tab move that
   * disagrees with the semantics traversal order and redirects focus to the
   * correct item in two steps:
   *
   * 1. It calls `SetPendingFocusTarget` with the correct item and schedules a
   *    focus update for the next run loop turn, after the focus engine has
   *    finished rejecting the current update.
   * 2. The scheduled focus update is requested from the root SemanticsObject,
   *    because the focus engine ignores requests from an environment that does
   *    not contain the focused item. The root's `preferredFocusEnvironments`
   *    returns `GetPendingFocusTarget()`, which steers the update to the
   *    target. The target is then cleared.
   */
  virtual SemanticsObject* GetPendingFocusTarget() const = 0;
  virtual void SetPendingFocusTarget(SemanticsObject* target) = 0;
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_DARWIN_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_IOS_H_
