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
#include "flutter/shell/platform/darwin/ios/framework/Headers/FlutterChannels.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterTextInputPlugin.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterView.h"
#include "third_party/skia/include/core/SkMatrix44.h"
#include "third_party/skia/include/core/SkRect.h"

namespace shell {
class AccessibilityBridge;
}  // namespace shell

/**
 * A node in the iOS semantics tree.
 */
@interface SemanticsObject : NSObject

/**
 * The globally unique identifier for this node.
 */
@property(nonatomic, readonly) int32_t uid;

/**
 * The parent of this node in the node tree. Will be nil for the root node and
 * during transient state changes.
 */
@property(nonatomic, assign) SemanticsObject* parent;

/**
 * The accessibility bridge that this semantics object is attached to. This
 * object may use the bridge to access contextual application information. A weak pointer is used
 * because the platform view owns the accessibility bridge.
 */
@property(nonatomic, readonly) fml::WeakPtr<shell::AccessibilityBridge> bridge;

/**
 * The semantics node used to produce this semantics object.
 */
@property(nonatomic, readonly) blink::SemanticsNode node;

/**
 * Updates this semantics object using data from the `node` argument.
 */
- (void)setSemanticsNode:(const blink::SemanticsNode*)node NS_REQUIRES_SUPER;

/**
 * Whether this semantics object has child semantics objects.
 */
@property(nonatomic, readonly) BOOL hasChildren;

/**
 * Direct children of this semantics object. Each child's `parent` property must
 * be equal to this object.
 */
@property(nonatomic, strong) NSMutableArray<SemanticsObject*>* children;

- (BOOL)nodeWillCauseLayoutChange:(const blink::SemanticsNode*)node;

#pragma mark - Designated initializers

- (instancetype)init __attribute__((unavailable("Use initWithBridge instead")));
- (instancetype)initWithBridge:(fml::WeakPtr<shell::AccessibilityBridge>)bridge
                           uid:(int32_t)uid NS_DESIGNATED_INITIALIZER;

@end

/**
 * An implementation of UIAccessibilityCustomAction which also contains the
 * Flutter uid.
 */
@interface FlutterCustomAccessibilityAction : UIAccessibilityCustomAction

/**
 * The uid of the action defined by the flutter application.
 */
@property(nonatomic) int32_t uid;

@end

/**
 * The default implementation of `SemanticsObject` for most accessibility elements
 * in the iOS accessibility tree.
 *
 * Use this implementation for nodes that do not need to be expressed via UIKit-specific
 * protocols (it only implements NSObject).
 *
 * See also:
 *  * TextInputSemanticsObject, which implements `UITextInput` protocol to expose
 *    editable text widgets to a11y.
 */
@interface FlutterSemanticsObject : SemanticsObject
@end

namespace shell {
class PlatformViewIOS;

class AccessibilityBridge final {
 public:
  AccessibilityBridge(UIView* view, PlatformViewIOS* platform_view);
  ~AccessibilityBridge();

  void UpdateSemantics(blink::SemanticsNodeUpdates nodes,
                       blink::CustomAccessibilityActionUpdates actions);
  void DispatchSemanticsAction(int32_t id, blink::SemanticsAction action);
  void DispatchSemanticsAction(int32_t id,
                               blink::SemanticsAction action,
                               std::vector<uint8_t> args);

  UIView<UITextInput>* textInputView();

  UIView* view() const { return view_; }

  fml::WeakPtr<AccessibilityBridge> GetWeakPtr();

  void clearState();

 private:
  SemanticsObject* GetOrCreateObject(int32_t id, blink::SemanticsNodeUpdates& updates);
  void VisitObjectsRecursivelyAndRemove(SemanticsObject* object,
                                        NSMutableArray<NSNumber*>* doomed_uids);
  void HandleEvent(NSDictionary<NSString*, id>* annotatedEvent);

  UIView* view_;
  PlatformViewIOS* platform_view_;
  fml::scoped_nsobject<NSMutableDictionary<NSNumber*, SemanticsObject*>> objects_;
  fml::scoped_nsprotocol<FlutterBasicMessageChannel*> accessibility_channel_;
  fml::WeakPtrFactory<AccessibilityBridge> weak_factory_;
  int32_t previous_route_id_;
  std::unordered_map<int32_t, blink::CustomAccessibilityAction> actions_;
  std::vector<int32_t> previous_routes_;

  FML_DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};

}  // namespace shell

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
