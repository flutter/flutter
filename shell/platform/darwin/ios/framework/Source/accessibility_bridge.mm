// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_text_entry.h"

#include <utility>
#include <vector>

#import <UIKit/UIKit.h>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/FlutterPlatformViews_Internal.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

namespace {

constexpr int32_t kRootNodeId = 0;

flutter::SemanticsAction GetSemanticsActionForScrollDirection(
    UIAccessibilityScrollDirection direction) {
  // To describe the vertical scroll direction, UIAccessibilityScrollDirection uses the
  // direction the scroll bar moves in and SemanticsAction uses the direction the finger
  // moves in. However, the horizontal scroll direction matches the SemanticsAction direction.
  // That is way the following maps vertical opposite of the SemanticsAction, but the horizontal
  // maps directly.
  switch (direction) {
    case UIAccessibilityScrollDirectionRight:
    case UIAccessibilityScrollDirectionPrevious:  // TODO(abarth): Support RTL using
                                                  // _node.textDirection.
      return flutter::SemanticsAction::kScrollRight;
    case UIAccessibilityScrollDirectionLeft:
    case UIAccessibilityScrollDirectionNext:  // TODO(abarth): Support RTL using
                                              // _node.textDirection.
      return flutter::SemanticsAction::kScrollLeft;
    case UIAccessibilityScrollDirectionUp:
      return flutter::SemanticsAction::kScrollDown;
    case UIAccessibilityScrollDirectionDown:
      return flutter::SemanticsAction::kScrollUp;
  }
  FML_DCHECK(false);  // Unreachable
  return flutter::SemanticsAction::kScrollUp;
}

}  // namespace

/// A proxy class for SemanticsObject and UISwitch.  For most Accessibility and
/// SemanticsObject methods it delegates to the semantics object, otherwise it
/// sends messages to the UISwitch.
@interface FlutterSwitchSemanticsObject : UISwitch
@end

@implementation FlutterSwitchSemanticsObject {
  SemanticsObject* _semanticsObject;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject {
  self = [super init];
  if (self) {
    _semanticsObject = [semanticsObject retain];
  }
  return self;
}

- (void)dealloc {
  [_semanticsObject release];
  [super dealloc];
}

- (NSMethodSignature*)methodSignatureForSelector:(SEL)sel {
  NSMethodSignature* result = [super methodSignatureForSelector:sel];
  if (!result) {
    result = [_semanticsObject methodSignatureForSelector:sel];
  }
  return result;
}

- (void)forwardInvocation:(NSInvocation*)anInvocation {
  [anInvocation setTarget:_semanticsObject];
  [anInvocation invoke];
}

- (CGRect)accessibilityFrame {
  return [_semanticsObject accessibilityFrame];
}

- (id)accessibilityContainer {
  return [_semanticsObject accessibilityContainer];
}

- (NSString*)accessibilityLabel {
  return [_semanticsObject accessibilityLabel];
}

- (NSString*)accessibilityHint {
  return [_semanticsObject accessibilityHint];
}

- (NSString*)accessibilityValue {
  if ([_semanticsObject node].HasFlag(flutter::SemanticsFlags::kIsToggled) ||
      [_semanticsObject node].HasFlag(flutter::SemanticsFlags::kIsChecked)) {
    self.on = YES;
  } else {
    self.on = NO;
  }

  if (![_semanticsObject isAccessibilityBridgeAlive]) {
    return nil;
  } else {
    return [super accessibilityValue];
  }
}

@end  // FlutterSwitchSemanticsObject

@implementation FlutterCustomAccessibilityAction {
}
@end

/**
 * Represents a semantics object that has children and hence has to be presented to the OS as a
 * UIAccessibilityContainer.
 *
 * The SemanticsObject class cannot implement the UIAccessibilityContainer protocol because an
 * object that returns YES for isAccessibilityElement cannot also implement
 * UIAccessibilityContainer.
 *
 * With the help of SemanticsObjectContainer, the hierarchy of semantic objects received from
 * the framework, such as:
 *
 * SemanticsObject1
 *     SemanticsObject2
 *         SemanticsObject3
 *         SemanticsObject4
 *
 * is translated into the following hierarchy, which is understood by iOS:
 *
 * SemanticsObjectContainer1
 *     SemanticsObject1
 *     SemanticsObjectContainer2
 *         SemanticsObject2
 *         SemanticsObject3
 *         SemanticsObject4
 *
 * From Flutter's view of the world (the first tree seen above), we construct iOS's view of the
 * world (second tree) as follows: We replace each SemanticsObjects that has children with a
 * SemanticsObjectContainer, which has the original SemanticsObject and its children as children.
 *
 * SemanticsObjects have semantic information attached to them which is interpreted by
 * VoiceOver (they return YES for isAccessibilityElement). The SemanticsObjectContainers are just
 * there for structure and they don't provide any semantic information to VoiceOver (they return
 * NO for isAccessibilityElement).
 */
@interface SemanticsObjectContainer : UIAccessibilityElement
- (instancetype)init __attribute__((unavailable("Use initWithSemanticsObject instead")));
- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject
                                 bridge:(fml::WeakPtr<flutter::AccessibilityBridge>)bridge
    NS_DESIGNATED_INITIALIZER;

@property(nonatomic, weak) SemanticsObject* semanticsObject;

@end

@implementation SemanticsObject {
  fml::scoped_nsobject<SemanticsObjectContainer> _container;
}

#pragma mark - Override base class designated initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - Designated initializers

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridge>)bridge uid:(int32_t)uid {
  FML_DCHECK(bridge) << "bridge must be set";
  FML_DCHECK(uid >= kRootNodeId);
  // Initialize with the UIView as the container.
  // The UIView will not necessarily be accessibility parent for this object.
  // The bridge informs the OS of the actual structure via
  // `accessibilityContainer` and `accessibilityElementAtIndex`.
  self = [super initWithAccessibilityContainer:bridge->view()];

  if (self) {
    _bridge = bridge;
    _uid = uid;
    _children = [[NSMutableArray alloc] init];
  }

  return self;
}

- (void)dealloc {
  for (SemanticsObject* child in _children) {
    child.parent = nil;
  }
  [_children removeAllObjects];
  [_children release];
  _parent = nil;
  _container.get().semanticsObject = nil;
  [_platformViewSemanticsContainer release];
  [super dealloc];
}

#pragma mark - Semantic object methods

- (BOOL)isAccessibilityBridgeAlive {
  return [self bridge].get() != nil;
}

- (void)setSemanticsNode:(const flutter::SemanticsNode*)node {
  _node = *node;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a layout change.
 */
- (BOOL)nodeWillCauseLayoutChange:(const flutter::SemanticsNode*)node {
  return [self node].rect != node->rect || [self node].transform != node->transform;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a scroll event.
 */
- (BOOL)nodeWillCauseScroll:(const flutter::SemanticsNode*)node {
  return !isnan([self node].scrollPosition) && !isnan(node->scrollPosition) &&
         [self node].scrollPosition != node->scrollPosition;
}

- (BOOL)hasChildren {
  if (_node.IsPlatformViewNode()) {
    return YES;
  }
  return [self.children count] != 0;
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  if (![self isAccessibilityBridgeAlive])
    return false;

  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.

  //  We enforce in the framework that no other useful semantics are merged with these nodes.
  if ([self node].HasFlag(flutter::SemanticsFlags::kScopesRoute))
    return false;

  // If the only flag(s) set are scrolling related AND
  // The only flags set are not kIsHidden OR
  // The node doesn't have a label, value, or hint OR
  // The only actions set are scrolling related actions.
  //
  // The kIsHidden flag set with any other flag just means this node is now
  // hidden but still is a valid target for a11y focus in the tree, e.g. a list
  // item that is currently off screen but the a11y navigation needs to know
  // about.
  return (([self node].flags & ~flutter::kScrollableSemanticsFlags) != 0 &&
          [self node].flags != static_cast<int32_t>(flutter::SemanticsFlags::kIsHidden)) ||
         ![self node].label.empty() || ![self node].value.empty() || ![self node].hint.empty() ||
         ([self node].actions & ~flutter::kScrollableSemanticsActions) != 0;
}

- (void)collectRoutes:(NSMutableArray<SemanticsObject*>*)edges {
  if ([self node].HasFlag(flutter::SemanticsFlags::kScopesRoute))
    [edges addObject:self];
  if ([self hasChildren]) {
    for (SemanticsObject* child in self.children) {
      [child collectRoutes:edges];
    }
  }
}

- (BOOL)onCustomAccessibilityAction:(FlutterCustomAccessibilityAction*)action {
  if (![self node].HasAction(flutter::SemanticsAction::kCustomAction))
    return NO;
  int32_t action_id = action.uid;
  std::vector<uint8_t> args;
  args.push_back(3);  // type=int32.
  args.push_back(action_id);
  args.push_back(action_id >> 8);
  args.push_back(action_id >> 16);
  args.push_back(action_id >> 24);
  [self bridge] -> DispatchSemanticsAction([self uid], flutter::SemanticsAction::kCustomAction,
                                           std::move(args));
  return YES;
}

- (NSString*)routeName {
  // Returns the first non-null and non-empty semantic label of a child
  // with an NamesRoute flag. Otherwise returns nil.
  if ([self node].HasFlag(flutter::SemanticsFlags::kNamesRoute)) {
    NSString* newName = [self accessibilityLabel];
    if (newName != nil && [newName length] > 0) {
      return newName;
    }
  }
  if ([self hasChildren]) {
    for (SemanticsObject* child in self.children) {
      NSString* newName = [child routeName];
      if (newName != nil && [newName length] > 0) {
        return newName;
      }
    }
  }
  return nil;
}

- (NSString*)accessibilityLabel {
  if (![self isAccessibilityBridgeAlive])
    return nil;

  if ([self node].label.empty())
    return nil;
  return @([self node].label.data());
}

- (NSString*)accessibilityHint {
  if (![self isAccessibilityBridgeAlive])
    return nil;

  if ([self node].hint.empty())
    return nil;
  return @([self node].hint.data());
}

- (NSString*)accessibilityValue {
  if (![self isAccessibilityBridgeAlive])
    return nil;

  if (![self node].value.empty()) {
    return @([self node].value.data());
  }

  // FlutterSwitchSemanticsObject should supercede these conditionals.
  if ([self node].HasFlag(flutter::SemanticsFlags::kHasToggledState) ||
      [self node].HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    if ([self node].HasFlag(flutter::SemanticsFlags::kIsToggled) ||
        [self node].HasFlag(flutter::SemanticsFlags::kIsChecked)) {
      return @"1";
    } else {
      return @"0";
    }
  }

  return nil;
}

- (CGRect)accessibilityFrame {
  if (![self isAccessibilityBridgeAlive])
    return CGRectMake(0, 0, 0, 0);

  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHidden)) {
    return [super accessibilityFrame];
  }
  return [self globalRect];
}

- (CGRect)globalRect {
  SkMatrix44 globalTransform = [self node].transform;
  for (SemanticsObject* parent = [self parent]; parent; parent = parent.parent) {
    globalTransform = parent.node.transform * globalTransform;
  }

  SkPoint quad[4];
  [self node].rect.toQuad(quad);
  for (auto& point : quad) {
    SkScalar vector[4] = {point.x(), point.y(), 0, 1};
    globalTransform.mapScalars(vector);
    point.set(vector[0] / vector[3], vector[1] / vector[3]);
  }
  SkRect rect;
  rect.setBounds(quad, 4);

  // `rect` is in the physical pixel coordinate system. iOS expects the accessibility frame in
  // the logical pixel coordinate system. Therefore, we divide by the `scale` (pixel ratio) to
  // convert.
  CGFloat scale = [[[self bridge]->view() window] screen].scale;
  auto result =
      CGRectMake(rect.x() / scale, rect.y() / scale, rect.width() / scale, rect.height() / scale);
  return UIAccessibilityConvertFrameToScreenCoordinates(result, [self bridge] -> view());
}

#pragma mark - UIAccessibilityElement protocol

- (id)accessibilityContainer {
  if ([self hasChildren] || [self uid] == kRootNodeId) {
    if (_container == nil)
      _container.reset([[SemanticsObjectContainer alloc] initWithSemanticsObject:self
                                                                          bridge:[self bridge]]);
    return _container.get();
  }
  if ([self parent] == nil) {
    // This can happen when we have released the accessibility tree but iOS is
    // still holding onto our objects. iOS can take some time before it
    // realizes that the tree has changed.
    return nil;
  }
  return [[self parent] accessibilityContainer];
}

#pragma mark - UIAccessibilityAction overrides

- (BOOL)accessibilityActivate {
  if (![self isAccessibilityBridgeAlive])
    return NO;
  if (![self node].HasAction(flutter::SemanticsAction::kTap))
    return NO;
  [self bridge] -> DispatchSemanticsAction([self uid], flutter::SemanticsAction::kTap);
  return YES;
}

- (void)accessibilityIncrement {
  if (![self isAccessibilityBridgeAlive])
    return;
  if ([self node].HasAction(flutter::SemanticsAction::kIncrease)) {
    [self node].value = [self node].increasedValue;
    [self bridge] -> DispatchSemanticsAction([self uid], flutter::SemanticsAction::kIncrease);
  }
}

- (void)accessibilityDecrement {
  if (![self isAccessibilityBridgeAlive])
    return;
  if ([self node].HasAction(flutter::SemanticsAction::kDecrease)) {
    [self node].value = [self node].decreasedValue;
    [self bridge] -> DispatchSemanticsAction([self uid], flutter::SemanticsAction::kDecrease);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  if (![self isAccessibilityBridgeAlive])
    return NO;
  flutter::SemanticsAction action = GetSemanticsActionForScrollDirection(direction);
  if (![self node].HasAction(action))
    return NO;
  [self bridge] -> DispatchSemanticsAction([self uid], action);
  return YES;
}

- (BOOL)accessibilityPerformEscape {
  if (![self isAccessibilityBridgeAlive])
    return NO;
  if (![self node].HasAction(flutter::SemanticsAction::kDismiss))
    return NO;
  [self bridge] -> DispatchSemanticsAction([self uid], flutter::SemanticsAction::kDismiss);
  return YES;
}

#pragma mark UIAccessibilityFocus overrides

- (void)accessibilityElementDidBecomeFocused {
  if (![self isAccessibilityBridgeAlive])
    return;
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHidden)) {
    [self bridge] -> DispatchSemanticsAction([self uid], flutter::SemanticsAction::kShowOnScreen);
  }
  if ([self node].HasAction(flutter::SemanticsAction::kDidGainAccessibilityFocus)) {
    [self bridge] -> DispatchSemanticsAction([self uid],
                                             flutter::SemanticsAction::kDidGainAccessibilityFocus);
  }
}

- (void)accessibilityElementDidLoseFocus {
  if (![self isAccessibilityBridgeAlive])
    return;
  if ([self node].HasAction(flutter::SemanticsAction::kDidLoseAccessibilityFocus)) {
    [self bridge] -> DispatchSemanticsAction([self uid],
                                             flutter::SemanticsAction::kDidLoseAccessibilityFocus);
  }
}

@end

@implementation FlutterSemanticsObject {
}

#pragma mark - Override base class designated initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - Designated initializers

- (instancetype)initWithBridge:(fml::WeakPtr<flutter::AccessibilityBridge>)bridge uid:(int32_t)uid {
  self = [super initWithBridge:bridge uid:uid];
  return self;
}

#pragma mark - UIAccessibility overrides

- (UIAccessibilityTraits)accessibilityTraits {
  UIAccessibilityTraits traits = UIAccessibilityTraitNone;
  if ([self node].HasAction(flutter::SemanticsAction::kIncrease) ||
      [self node].HasAction(flutter::SemanticsAction::kDecrease)) {
    traits |= UIAccessibilityTraitAdjustable;
  }
  // FlutterSwitchSemanticsObject should supercede these conditionals.
  if ([self node].HasFlag(flutter::SemanticsFlags::kHasToggledState) ||
      [self node].HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    traits |= UIAccessibilityTraitButton;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsSelected)) {
    traits |= UIAccessibilityTraitSelected;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsButton)) {
    traits |= UIAccessibilityTraitButton;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kHasEnabledState) &&
      ![self node].HasFlag(flutter::SemanticsFlags::kIsEnabled)) {
    traits |= UIAccessibilityTraitNotEnabled;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsHeader)) {
    traits |= UIAccessibilityTraitHeader;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsImage)) {
    traits |= UIAccessibilityTraitImage;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsLiveRegion)) {
    traits |= UIAccessibilityTraitUpdatesFrequently;
  }
  if ([self node].HasFlag(flutter::SemanticsFlags::kIsLink)) {
    traits |= UIAccessibilityTraitLink;
  }
  return traits;
}

@end

@implementation FlutterPlatformViewSemanticsContainer {
  SemanticsObject* _semanticsObject;
  UIView* _platformView;
}

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)object {
  FML_CHECK(object);
  // Initialize with the UIView as the container.
  // The UIView will not necessarily be accessibility parent for this object.
  // The bridge informs the OS of the actual structure via
  // `accessibilityContainer` and `accessibilityElementAtIndex`.
  if (self = [super initWithAccessibilityContainer:object.bridge->view()]) {
    _semanticsObject = object;
    flutter::FlutterPlatformViewsController* controller =
        object.bridge->GetPlatformViewsController();
    if (controller) {
      _platformView = [controller->GetPlatformViewByID(object.node.platformViewId) view];
    }
    self.accessibilityElements = @[ _semanticsObject, _platformView ];
  }
  return self;
}

- (CGRect)accessibilityFrame {
  return _semanticsObject.accessibilityFrame;
}

- (BOOL)isAccessibilityElement {
  return NO;
}

- (id)accessibilityContainer {
  return [_semanticsObject accessibilityContainer];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [_platformView accessibilityScroll:direction];
}

@end

@implementation SemanticsObjectContainer {
  SemanticsObject* _semanticsObject;
  fml::WeakPtr<flutter::AccessibilityBridge> _bridge;
}

#pragma mark - initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject
                                 bridge:(fml::WeakPtr<flutter::AccessibilityBridge>)bridge {
  FML_DCHECK(semanticsObject) << "semanticsObject must be set";
  // Initialize with the UIView as the container.
  // The UIView will not necessarily be accessibility parent for this object.
  // The bridge informs the OS of the actual structure via
  // `accessibilityContainer` and `accessibilityElementAtIndex`.
  self = [super initWithAccessibilityContainer:bridge->view()];

  if (self) {
    _semanticsObject = semanticsObject;
    _bridge = bridge;
  }

  return self;
}

#pragma mark - UIAccessibilityContainer overrides

- (NSInteger)accessibilityElementCount {
  NSInteger count = [[_semanticsObject children] count] + 1;
  return count;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  if (index < 0 || index >= [self accessibilityElementCount])
    return nil;
  if (index == 0) {
    return _semanticsObject;
  }

  SemanticsObject* child = [_semanticsObject children][index - 1];

  // Swap the original `SemanticsObject` to a `PlatformViewSemanticsContainer`
  if (child.node.IsPlatformViewNode()) {
    child.platformViewSemanticsContainer.index = index;
    return child.platformViewSemanticsContainer;
  }

  if ([child hasChildren])
    return [child accessibilityContainer];
  return child;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  if (element == _semanticsObject)
    return 0;

  // FlutterPlatformViewSemanticsContainer is always the last element of its parent.
  if ([element isKindOfClass:[FlutterPlatformViewSemanticsContainer class]]) {
    return ((FlutterPlatformViewSemanticsContainer*)element).index;
  }

  NSMutableArray<SemanticsObject*>* children = [_semanticsObject children];
  for (size_t i = 0; i < [children count]; i++) {
    SemanticsObject* child = children[i];
    if ((![child hasChildren] && child == element) ||
        ([child hasChildren] && [child accessibilityContainer] == element))
      return i + 1;
  }
  return NSNotFound;
}

#pragma mark - UIAccessibilityElement protocol

- (BOOL)isAccessibilityElement {
  return NO;
}

- (CGRect)accessibilityFrame {
  return [_semanticsObject accessibilityFrame];
}

- (id)accessibilityContainer {
  if (!_bridge) {
    return nil;
  }
  return ([_semanticsObject uid] == kRootNodeId)
             ? _bridge->view()
             : [[_semanticsObject parent] accessibilityContainer];
}

#pragma mark - UIAccessibilityAction overrides

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  return [_semanticsObject accessibilityScroll:direction];
}

@end

#pragma mark - AccessibilityBridge impl

namespace flutter {

AccessibilityBridge::AccessibilityBridge(UIView* view,
                                         PlatformViewIOS* platform_view,
                                         FlutterPlatformViewsController* platform_views_controller)
    : view_(view),
      platform_view_(platform_view),
      platform_views_controller_(platform_views_controller),
      objects_([[NSMutableDictionary alloc] init]),
      weak_factory_(this),
      previous_route_id_(0),
      previous_routes_({}) {
  accessibility_channel_.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/accessibility"
      binaryMessenger:platform_view->GetOwnerViewController().get().engine.binaryMessenger
                codec:[FlutterStandardMessageCodec sharedInstance]]);
  [accessibility_channel_.get() setMessageHandler:^(id message, FlutterReply reply) {
    HandleEvent((NSDictionary*)message);
  }];
}

AccessibilityBridge::~AccessibilityBridge() {
  clearState();
  view_.accessibilityElements = nil;
}

UIView<UITextInput>* AccessibilityBridge::textInputView() {
  return [platform_view_->GetTextInputPlugin() textInputView];
}

void AccessibilityBridge::UpdateSemantics(flutter::SemanticsNodeUpdates nodes,
                                          flutter::CustomAccessibilityActionUpdates actions) {
  BOOL layoutChanged = NO;
  BOOL scrollOccured = NO;
  for (const auto& entry : actions) {
    const flutter::CustomAccessibilityAction& action = entry.second;
    actions_[action.id] = action;
  }
  for (const auto& entry : nodes) {
    const flutter::SemanticsNode& node = entry.second;
    SemanticsObject* object = GetOrCreateObject(node.id, nodes);
    layoutChanged = layoutChanged || [object nodeWillCauseLayoutChange:&node];
    scrollOccured = scrollOccured || [object nodeWillCauseScroll:&node];
    [object setSemanticsNode:&node];
    NSUInteger newChildCount = node.childrenInTraversalOrder.size();
    NSMutableArray* newChildren =
        [[[NSMutableArray alloc] initWithCapacity:newChildCount] autorelease];
    for (NSUInteger i = 0; i < newChildCount; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.childrenInTraversalOrder[i], nodes);
      child.parent = object;
      [newChildren addObject:child];
    }
    object.children = newChildren;
    if (node.customAccessibilityActions.size() > 0) {
      NSMutableArray<FlutterCustomAccessibilityAction*>* accessibilityCustomActions =
          [[[NSMutableArray alloc] init] autorelease];
      for (int32_t action_id : node.customAccessibilityActions) {
        flutter::CustomAccessibilityAction& action = actions_[action_id];
        if (action.overrideId != -1) {
          // iOS does not support overriding standard actions, so we ignore any
          // custom actions that have an override id provided.
          continue;
        }
        NSString* label = @(action.label.data());
        SEL selector = @selector(onCustomAccessibilityAction:);
        FlutterCustomAccessibilityAction* customAction =
            [[FlutterCustomAccessibilityAction alloc] initWithName:label
                                                            target:object
                                                          selector:selector];
        customAction.uid = action_id;
        [accessibilityCustomActions addObject:customAction];
      }
      object.accessibilityCustomActions = accessibilityCustomActions;
    }

    if (object.node.IsPlatformViewNode()) {
      FlutterPlatformViewsController* controller = GetPlatformViewsController();
      if (controller) {
        object.platformViewSemanticsContainer =
            [[FlutterPlatformViewSemanticsContainer alloc] initWithSemanticsObject:object];
      }
    } else if (object.platformViewSemanticsContainer) {
      [object.platformViewSemanticsContainer release];
    }
  }

  SemanticsObject* root = objects_.get()[@(kRootNodeId)];

  bool routeChanged = false;
  SemanticsObject* lastAdded = nil;

  if (root) {
    if (!view_.accessibilityElements) {
      view_.accessibilityElements = @[ [root accessibilityContainer] ];
    }
    NSMutableArray<SemanticsObject*>* newRoutes = [[[NSMutableArray alloc] init] autorelease];
    [root collectRoutes:newRoutes];
    for (SemanticsObject* route in newRoutes) {
      if (std::find(previous_routes_.begin(), previous_routes_.end(), [route uid]) !=
          previous_routes_.end()) {
        lastAdded = route;
      }
    }
    if (lastAdded == nil && [newRoutes count] > 0) {
      int index = [newRoutes count] - 1;
      lastAdded = [newRoutes objectAtIndex:index];
    }
    if (lastAdded != nil && [lastAdded uid] != previous_route_id_) {
      previous_route_id_ = [lastAdded uid];
      routeChanged = true;
    }
    previous_routes_.clear();
    for (SemanticsObject* route in newRoutes) {
      previous_routes_.push_back([route uid]);
    }
  } else {
    view_.accessibilityElements = nil;
  }

  NSMutableArray<NSNumber*>* doomed_uids = [NSMutableArray arrayWithArray:[objects_.get() allKeys]];
  if (root)
    VisitObjectsRecursivelyAndRemove(root, doomed_uids);
  [objects_ removeObjectsForKeys:doomed_uids];

  layoutChanged = layoutChanged || [doomed_uids count] > 0;
  if (routeChanged) {
    NSString* routeName = [lastAdded routeName];
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, routeName);
  } else if (layoutChanged) {
    // TODO(goderbauer): figure out which node to focus next.
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  }
  if (scrollOccured) {
    // TODO(tvolkert): provide meaningful string (e.g. "page 2 of 5")
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, @"");
  }
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid, flutter::SemanticsAction action) {
  platform_view_->DispatchSemanticsAction(uid, action, {});
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid,
                                                  flutter::SemanticsAction action,
                                                  std::vector<uint8_t> args) {
  platform_view_->DispatchSemanticsAction(uid, action, std::move(args));
}

static void ReplaceSemanticsObject(SemanticsObject* oldObject,
                                   SemanticsObject* newObject,
                                   NSMutableDictionary<NSNumber*, SemanticsObject*>* objects) {
  // `newObject` should represent the same id as `oldObject`.
  assert(oldObject.node.id == newObject.node.id);
  NSNumber* nodeId = @(oldObject.node.id);
  NSUInteger positionInChildlist = [oldObject.parent.children indexOfObject:oldObject];
  SemanticsObject* parent = oldObject.parent;
  [objects removeObjectForKey:nodeId];
  newObject.parent = parent;
  [newObject.parent.children replaceObjectAtIndex:positionInChildlist withObject:newObject];
  objects[nodeId] = newObject;
}

static SemanticsObject* CreateObject(const flutter::SemanticsNode& node,
                                     fml::WeakPtr<AccessibilityBridge> weak_ptr) {
  if (node.HasFlag(flutter::SemanticsFlags::kIsTextField) &&
      !node.HasFlag(flutter::SemanticsFlags::kIsReadOnly)) {
    // Text fields are backed by objects that implement UITextInput.
    return [[[TextInputSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id] autorelease];
  } else if (node.HasFlag(flutter::SemanticsFlags::kHasToggledState) ||
             node.HasFlag(flutter::SemanticsFlags::kHasCheckedState)) {
    SemanticsObject* delegateObject = [[FlutterSemanticsObject alloc] initWithBridge:weak_ptr
                                                                                 uid:node.id];
    return (SemanticsObject*)[[[FlutterSwitchSemanticsObject alloc]
        initWithSemanticsObject:delegateObject] autorelease];
    [delegateObject release];
  } else {
    return [[[FlutterSemanticsObject alloc] initWithBridge:weak_ptr uid:node.id] autorelease];
  }
}

static bool DidFlagChange(const flutter::SemanticsNode& oldNode,
                          const flutter::SemanticsNode& newNode,
                          SemanticsFlags flag) {
  return oldNode.HasFlag(flag) != newNode.HasFlag(flag);
}

SemanticsObject* AccessibilityBridge::GetOrCreateObject(int32_t uid,
                                                        flutter::SemanticsNodeUpdates& updates) {
  SemanticsObject* object = objects_.get()[@(uid)];
  if (!object) {
    object = CreateObject(updates[uid], GetWeakPtr());
    objects_.get()[@(uid)] = object;
  } else {
    // Existing node case
    auto nodeEntry = updates.find(object.node.id);
    if (nodeEntry != updates.end()) {
      // There's an update for this node
      flutter::SemanticsNode node = nodeEntry->second;
      if (DidFlagChange(object.node, node, flutter::SemanticsFlags::kIsTextField) ||
          DidFlagChange(object.node, node, flutter::SemanticsFlags::kIsReadOnly) ||
          DidFlagChange(object.node, node, flutter::SemanticsFlags::kHasCheckedState) ||
          DidFlagChange(object.node, node, flutter::SemanticsFlags::kHasToggledState)) {
        // The node changed its type. In this case, we cannot reuse the existing
        // SemanticsObject implementation. Instead, we replace it with a new
        // instance.
        SemanticsObject* newSemanticsObject = CreateObject(node, GetWeakPtr());
        ReplaceSemanticsObject(object, newSemanticsObject, objects_.get());
        object = newSemanticsObject;
      }
    }
  }
  return object;
}

void AccessibilityBridge::VisitObjectsRecursivelyAndRemove(SemanticsObject* object,
                                                           NSMutableArray<NSNumber*>* doomed_uids) {
  [doomed_uids removeObject:@(object.uid)];
  for (SemanticsObject* child in [object children])
    VisitObjectsRecursivelyAndRemove(child, doomed_uids);
}

void AccessibilityBridge::HandleEvent(NSDictionary<NSString*, id>* annotatedEvent) {
  NSString* type = annotatedEvent[@"type"];
  if ([type isEqualToString:@"announce"]) {
    NSString* message = annotatedEvent[@"data"][@"message"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message);
  }
}

fml::WeakPtr<AccessibilityBridge> AccessibilityBridge::GetWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

void AccessibilityBridge::clearState() {
  [objects_ removeAllObjects];
  previous_route_id_ = 0;
  previous_routes_.clear();
}

}  // namespace flutter
