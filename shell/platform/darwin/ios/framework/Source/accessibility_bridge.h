// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_

#include <memory>
#include <unordered_map>
#include <unordered_set>
#include <vector>

#include "flutter/fml/platform/darwin/scoped_nsobject.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "lib/fxl/macros.h"
#include "third_party/skia/include/core/SkMatrix44.h"
#include "third_party/skia/include/core/SkRect.h"

namespace shell {
class AccessibilityBridge;
}  // namespace shell

@interface SemanticsObject : NSObject

/**
 * The globally unique identifier for this node.
 */
@property(nonatomic, readonly) int32_t uid;

/**
 * The parent of this node in the node tree. Will be nil for the root node and
 * during transient state changes.
 */
@property(nonatomic, strong) SemanticsObject* parent;

- (instancetype)init __attribute__((unavailable("Use initWithBridge instead")));
- (instancetype)initWithBridge:(shell::AccessibilityBridge*)bridge
                           uid:(int32_t)uid NS_DESIGNATED_INITIALIZER;

@end

namespace shell {
class PlatformViewIOS;

class AccessibilityBridge final {
 public:
  AccessibilityBridge(UIView* view, PlatformViewIOS* platform_view);
  ~AccessibilityBridge();

  void UpdateSemantics(std::vector<blink::SemanticsNode> nodes);
  void DispatchSemanticsAction(int32_t id, blink::SemanticsAction action);

  UIView* view() const { return view_; }

 private:
  SemanticsObject* GetOrCreateObject(int32_t id);
  void VisitObjectsRecursivelyAndRemove(SemanticsObject* object, NSMutableArray<NSNumber*>* doomed_uids);
  void ReleaseObjects(std::unordered_map<int, SemanticsObject*>& objects);

  UIView* view_;
  PlatformViewIOS* platform_view_;
  fml::scoped_nsobject<NSMutableDictionary<NSNumber*, SemanticsObject*>> objects_;

  FXL_DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
