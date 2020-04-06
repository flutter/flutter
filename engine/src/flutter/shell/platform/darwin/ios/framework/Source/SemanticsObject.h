// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_SEMANTICS_OBJECT_H_
#define SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_SEMANTICS_OBJECT_H_

#import <UIKit/UIKit.h>

#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge_ios.h"

constexpr int32_t kRootNodeId = 0;

@class FlutterCustomAccessibilityAction;
@class FlutterPlatformViewSemanticsContainer;

/**
 * A node in the iOS semantics tree.
 */
@interface SemanticsObject : UIAccessibilityElement

/**
 * The globally unique identifier for this node.
 */
@property(nonatomic, readonly) int32_t uid;

/**
 * The parent of this node in the node tree. Will be nil for the root node and
 * during transient state changes.
 */
@property(nonatomic, readonly) SemanticsObject* parent;

/**
 * The accessibility bridge that this semantics object is attached to. This
 * object may use the bridge to access contextual application information. A weak
 * pointer is used because the platform view owns the accessibility bridge.
 * If you are referencing this property from an iOS callback, be sure to
 * use `isAccessibilityBridgeActive` to protect against the case where this
 * node may be orphaned.
 */
@property(nonatomic, readonly) fml::WeakPtr<flutter::AccessibilityBridgeIos> bridge;

/**
 * Due to the fact that VoiceOver may hold onto SemanticObjects even after it shuts down,
 * there can be situations where the AccessibilityBridge is shutdown, but the SemanticObject
 * will still be alive. If VoiceOver is turned on again, it may try to access this orphaned
 * SemanticObject. Methods that are called from the accessiblity framework should use
 * this to guard against this case by just returning early if its bridge has been shutdown.
 *
 * See https://github.com/flutter/flutter/issues/43795 for more information.
 */
- (BOOL)isAccessibilityBridgeAlive;

/**
 * The semantics node used to produce this semantics object.
 */
@property(nonatomic, readonly) flutter::SemanticsNode node;

/**
 * Updates this semantics object using data from the `node` argument.
 */
- (void)setSemanticsNode:(const flutter::SemanticsNode*)node NS_REQUIRES_SUPER;

/**
 * Whether this semantics object has child semantics objects.
 */
@property(nonatomic, readonly) BOOL hasChildren;

/**
 * Direct children of this semantics object. Each child's `parent` property must
 * be equal to this object.
 */
@property(nonatomic, strong) NSArray<SemanticsObject*>* children;

/**
 * Used if this SemanticsObject is for a platform view.
 */
@property(strong, nonatomic) FlutterPlatformViewSemanticsContainer* platformViewSemanticsContainer;

- (void)replaceChildAtIndex:(NSInteger)index withChild:(SemanticsObject*)child;

- (BOOL)nodeWillCauseLayoutChange:(const flutter::SemanticsNode*)node;

#pragma mark - Designated initializers

- (instancetype)init __attribute__((unavailable("Use initWithBridge instead")));
- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridgeIos>)bridge
                           uid:(int32_t)uid NS_DESIGNATED_INITIALIZER;

- (BOOL)nodeWillCauseScroll:(const flutter::SemanticsNode*)node;
- (void)collectRoutes:(NSMutableArray<SemanticsObject*>*)edges;
- (NSString*)routeName;
- (BOOL)onCustomAccessibilityAction:(FlutterCustomAccessibilityAction*)action;

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

/**
 * Designated to act as an accessibility container of a platform view.
 *
 * This object does not take any accessibility actions on its own, nor has any accessibility
 * label/value/trait/hint... on its own. The accessibility data will be handled by the platform
 * view.
 *
 * See also:
 * * `SemanticsObject` for the other type of semantics objects.
 * * `FlutterSemanticsObject` for default implementation of `SemanticsObject`.
 */
@interface FlutterPlatformViewSemanticsContainer : UIAccessibilityElement

/**
 * The position inside an accessibility container.
 */
@property(nonatomic) NSInteger index;

- (instancetype)init __attribute__((unavailable("Use initWithAccessibilityContainer: instead")));

- (instancetype)initWithSemanticsObject:(SemanticsObject*)object;

@end

/// A proxy class for SemanticsObject and UISwitch.  For most Accessibility and
/// SemanticsObject methods it delegates to the semantics object, otherwise it
/// sends messages to the UISwitch.
@interface FlutterSwitchSemanticsObject : UISwitch
- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject;
@end

#endif  // SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_SEMANTICS_OBJECT_H_
