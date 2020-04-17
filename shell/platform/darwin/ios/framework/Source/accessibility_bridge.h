// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_

#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#import <UIKit/UIKit.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/lib/ui/semantics/custom_accessibility_action.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/shell/platform/darwin/common/framework/Headers/FlutterChannels.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/SemanticsObject.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge_ios.h"
#include "third_party/skia/include/core/SkRect.h"

namespace flutter {
class PlatformViewIOS;

class AccessibilityBridge final : public AccessibilityBridgeIos {
 public:
  AccessibilityBridge(UIView* view,
                      PlatformViewIOS* platform_view,
                      FlutterPlatformViewsController* platform_views_controller);
  ~AccessibilityBridge();

  void UpdateSemantics(flutter::SemanticsNodeUpdates nodes,
                       flutter::CustomAccessibilityActionUpdates actions);
  void DispatchSemanticsAction(int32_t id, flutter::SemanticsAction action) override;
  void DispatchSemanticsAction(int32_t id,
                               flutter::SemanticsAction action,
                               std::vector<uint8_t> args) override;

  UIView<UITextInput>* textInputView() override;

  UIView* view() const override { return view_; }

  fml::WeakPtr<AccessibilityBridge> GetWeakPtr();

  FlutterPlatformViewsController* GetPlatformViewsController() const override {
    return platform_views_controller_;
  };

  void clearState();

 private:
  SemanticsObject* GetOrCreateObject(int32_t id, flutter::SemanticsNodeUpdates& updates);
  void VisitObjectsRecursivelyAndRemove(SemanticsObject* object,
                                        NSMutableArray<NSNumber*>* doomed_uids);
  void HandleEvent(NSDictionary<NSString*, id>* annotatedEvent);

  UIView* view_;
  PlatformViewIOS* platform_view_;
  FlutterPlatformViewsController* platform_views_controller_;
  fml::scoped_nsobject<NSMutableDictionary<NSNumber*, SemanticsObject*>> objects_;
  fml::scoped_nsprotocol<FlutterBasicMessageChannel*> accessibility_channel_;
  fml::WeakPtrFactory<AccessibilityBridge> weak_factory_;
  int32_t previous_route_id_;
  std::unordered_map<int32_t, flutter::CustomAccessibilityAction> actions_;
  std::vector<int32_t> previous_routes_;

  FML_DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};

}  // namespace flutter

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
