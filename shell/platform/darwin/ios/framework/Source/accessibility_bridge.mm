// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_text_entry.h"

#include <utility>
#include <vector>

#import <UIKit/UIKit.h>

#include "flutter/fml/logging.h"
#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"

namespace {

constexpr int32_t kRootNodeId = 0;

blink::SemanticsAction GetSemanticsActionForScrollDirection(
    UIAccessibilityScrollDirection direction) {
  // To describe scroll direction, UIAccessibilityScrollDirection uses the direction the scroll bar
  // moves in and SemanticsAction uses the direction the finger moves in. Both move in opposite
  // directions, which is why the following maps left to right and vice versa.
  switch (direction) {
    case UIAccessibilityScrollDirectionRight:
    case UIAccessibilityScrollDirectionPrevious:  // TODO(abarth): Support RTL using
                                                  // _node.textDirection.
      return blink::SemanticsAction::kScrollLeft;
    case UIAccessibilityScrollDirectionLeft:
    case UIAccessibilityScrollDirectionNext:  // TODO(abarth): Support RTL using
                                              // _node.textDirection.
      return blink::SemanticsAction::kScrollRight;
    case UIAccessibilityScrollDirectionUp:
      return blink::SemanticsAction::kScrollDown;
    case UIAccessibilityScrollDirectionDown:
      return blink::SemanticsAction::kScrollUp;
  }
  FML_DCHECK(false);  // Unreachable
  return blink::SemanticsAction::kScrollUp;
}

}  // namespace

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
@interface SemanticsObjectContainer : NSObject
- (instancetype)init __attribute__((unavailable("Use initWithSemanticsObject instead")));
- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject
                                 bridge:(fml::WeakPtr<shell::AccessibilityBridge>)bridge
    NS_DESIGNATED_INITIALIZER;
@end

@implementation SemanticsObject {
  SemanticsObjectContainer* _container;
}

#pragma mark - Override base class designated initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - Designated initializers

- (instancetype)initWithBridge:(fml::WeakPtr<shell::AccessibilityBridge>)bridge uid:(int32_t)uid {
  FML_DCHECK(bridge) << "bridge must be set";
  FML_DCHECK(uid >= kRootNodeId);
  self = [super init];

  if (self) {
    _bridge = bridge;
    _uid = uid;
    self.children = [[[NSMutableArray alloc] init] autorelease];
  }

  return self;
}

- (void)dealloc {
  for (SemanticsObject* child in _children) {
    child.parent = nil;
  }
  [_children removeAllObjects];
  [_children dealloc];
  _parent = nil;
  [_container release];
  _container = nil;
  [super dealloc];
}

#pragma mark - Semantic object methods

- (void)setSemanticsNode:(const blink::SemanticsNode*)node {
  _node = *node;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a layout change.
 */
- (BOOL)nodeWillCauseLayoutChange:(const blink::SemanticsNode*)node {
  return [self node].rect != node->rect || [self node].transform != node->transform;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a scroll event.
 */
- (BOOL)nodeWillCauseScroll:(const blink::SemanticsNode*)node {
  return !isnan([self node].scrollPosition) && !isnan(node->scrollPosition) &&
         [self node].scrollPosition != node->scrollPosition;
}

- (BOOL)hasChildren {
  return [self.children count] != 0;
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.

  //  We enforce in the framework that no other useful semantics are merged with these nodes.
  if ([self node].HasFlag(blink::SemanticsFlags::kScopesRoute))
    return false;
  return ([self node].flags != 0 &&
          [self node].flags != static_cast<int32_t>(blink::SemanticsFlags::kIsHidden)) ||
         ![self node].label.empty() || ![self node].value.empty() || ![self node].hint.empty() ||
         ([self node].actions & ~blink::kScrollableSemanticsActions) != 0;
}

- (void)collectRoutes:(NSMutableArray<SemanticsObject*>*)edges {
  if ([self node].HasFlag(blink::SemanticsFlags::kScopesRoute))
    [edges addObject:self];
  if ([self hasChildren]) {
    for (SemanticsObject* child in self.children) {
      [child collectRoutes:edges];
    }
  }
}

- (BOOL)onCustomAccessibilityAction:(FlutterCustomAccessibilityAction*)action {
  if (![self node].HasAction(blink::SemanticsAction::kCustomAction))
    return NO;
  int32_t action_id = action.uid;
  std::vector<uint8_t> args;
  args.push_back(3);  // type=int32.
  args.push_back(action_id);
  args.push_back(action_id >> 8);
  args.push_back(action_id >> 16);
  args.push_back(action_id >> 24);
  [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kCustomAction, args);
  return YES;
}

- (NSString*)routeName {
  // Returns the first non-null and non-empty semantic label of a child
  // with an NamesRoute flag. Otherwise returns nil.
  if ([self node].HasFlag(blink::SemanticsFlags::kNamesRoute)) {
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
  if ([self node].label.empty())
    return nil;
  return @([self node].label.data());
}

- (NSString*)accessibilityHint {
  if ([self node].hint.empty())
    return nil;
  return @([self node].hint.data());
}

- (NSString*)accessibilityValue {
  if ([self node].value.empty())
    return nil;
  return @([self node].value.data());
}

- (CGRect)accessibilityFrame {
  if ([self node].HasFlag(blink::SemanticsFlags::kIsHidden)) {
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
  rect.set(quad, 4);

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
      _container = [[SemanticsObjectContainer alloc] initWithSemanticsObject:self
                                                                      bridge:[self bridge]];
    return _container;
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
  if (![self node].HasAction(blink::SemanticsAction::kTap))
    return NO;
  [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kTap);
  return YES;
}

- (void)accessibilityIncrement {
  if ([self node].HasAction(blink::SemanticsAction::kIncrease)) {
    [self node].value = [self node].increasedValue;
    [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kIncrease);
  }
}

- (void)accessibilityDecrement {
  if ([self node].HasAction(blink::SemanticsAction::kDecrease)) {
    [self node].value = [self node].decreasedValue;
    [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kDecrease);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  blink::SemanticsAction action = GetSemanticsActionForScrollDirection(direction);
  if (![self node].HasAction(action))
    return NO;
  [self bridge] -> DispatchSemanticsAction([self uid], action);
  return YES;
}

- (BOOL)accessibilityPerformEscape {
  if (![self node].HasAction(blink::SemanticsAction::kDismiss))
    return NO;
  [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kDismiss);
  return YES;
}

#pragma mark UIAccessibilityFocus overrides

- (void)accessibilityElementDidBecomeFocused {
  if ([self node].HasFlag(blink::SemanticsFlags::kIsHidden)) {
    [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kShowOnScreen);
  }
  if ([self node].HasAction(blink::SemanticsAction::kDidGainAccessibilityFocus)) {
    [self bridge] -> DispatchSemanticsAction([self uid],
                                             blink::SemanticsAction::kDidGainAccessibilityFocus);
  }
}

- (void)accessibilityElementDidLoseFocus {
  if ([self node].HasAction(blink::SemanticsAction::kDidLoseAccessibilityFocus)) {
    [self bridge] -> DispatchSemanticsAction([self uid],
                                             blink::SemanticsAction::kDidLoseAccessibilityFocus);
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

- (instancetype)initWithBridge:(fml::WeakPtr<shell::AccessibilityBridge>)bridge uid:(int32_t)uid {
  self = [super initWithBridge:bridge uid:uid];
  return self;
}

#pragma mark - UIAccessibility overrides

- (UIAccessibilityTraits)accessibilityTraits {
  UIAccessibilityTraits traits = UIAccessibilityTraitNone;
  if ([self node].HasAction(blink::SemanticsAction::kIncrease) ||
      [self node].HasAction(blink::SemanticsAction::kDecrease)) {
    traits |= UIAccessibilityTraitAdjustable;
  }
  // TODO(jonahwilliams): switches should have a value of "on" or "off"
  if ([self node].HasFlag(blink::SemanticsFlags::kIsSelected) ||
      [self node].HasFlag(blink::SemanticsFlags::kIsToggled) ||
      [self node].HasFlag(blink::SemanticsFlags::kIsChecked)) {
    traits |= UIAccessibilityTraitSelected;
  }
  if ([self node].HasFlag(blink::SemanticsFlags::kIsButton)) {
    traits |= UIAccessibilityTraitButton;
  }
  if ([self node].HasFlag(blink::SemanticsFlags::kHasEnabledState) &&
      ![self node].HasFlag(blink::SemanticsFlags::kIsEnabled)) {
    traits |= UIAccessibilityTraitNotEnabled;
  }
  if ([self node].HasFlag(blink::SemanticsFlags::kIsHeader)) {
    traits |= UIAccessibilityTraitHeader;
  }
  if ([self node].HasFlag(blink::SemanticsFlags::kIsImage)) {
    traits |= UIAccessibilityTraitImage;
  }
  if ([self node].HasFlag(blink::SemanticsFlags::kIsLiveRegion)) {
    traits |= UIAccessibilityTraitUpdatesFrequently;
  }
  return traits;
}

@end

@implementation SemanticsObjectContainer {
  SemanticsObject* _semanticsObject;
  fml::WeakPtr<shell::AccessibilityBridge> _bridge;
}

#pragma mark - initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject
                                 bridge:(fml::WeakPtr<shell::AccessibilityBridge>)bridge {
  FML_DCHECK(semanticsObject != nil) << "semanticsObject must be set";
  self = [super init];

  if (self) {
    _semanticsObject = semanticsObject;
    // The pointer is managed manually.
    [_semanticsObject retain];
    _bridge = bridge;
  }

  return self;
}

- (void)dealloc {
  [_semanticsObject release];
  [super dealloc];
}

#pragma mark - UIAccessibilityContainer overrides

- (NSInteger)accessibilityElementCount {
  return [[_semanticsObject children] count] + 1;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  if (index < 0 || index >= [self accessibilityElementCount])
    return nil;
  if (index == 0)
    return _semanticsObject;
  SemanticsObject* child = [_semanticsObject children][index - 1];
  if ([child hasChildren])
    return [child accessibilityContainer];
  return child;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  if (element == _semanticsObject)
    return 0;
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

namespace shell {

AccessibilityBridge::AccessibilityBridge(UIView* view, PlatformViewIOS* platform_view)
    : view_(view),
      platform_view_(platform_view),
      objects_([[NSMutableDictionary alloc] init]),
      weak_factory_(this),
      previous_route_id_(0),
      previous_routes_({}) {
  accessibility_channel_.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/accessibility"
      binaryMessenger:platform_view->GetOwnerViewController().get()
                codec:[FlutterStandardMessageCodec sharedInstance]]);
  [accessibility_channel_.get() setMessageHandler:^(id message, FlutterReply reply) {
    HandleEvent((NSDictionary*)message);
  }];
}

AccessibilityBridge::~AccessibilityBridge() {
  view_.accessibilityElements = nil;
  [accessibility_channel_.get() setMessageHandler:nil];
}

UIView<UITextInput>* AccessibilityBridge::textInputView() {
  return [platform_view_->GetTextInputPlugin() textInputView];
}

void AccessibilityBridge::UpdateSemantics(blink::SemanticsNodeUpdates nodes,
                                          blink::CustomAccessibilityActionUpdates actions) {
  BOOL layoutChanged = NO;
  BOOL scrollOccured = NO;
  for (const auto& entry : actions) {
    const blink::CustomAccessibilityAction& action = entry.second;
    actions_[action.id] = action;
  }
  for (const auto& entry : nodes) {
    const blink::SemanticsNode& node = entry.second;
    SemanticsObject* object = GetOrCreateObject(node.id, nodes);
    layoutChanged = layoutChanged || [object nodeWillCauseLayoutChange:&node];
    scrollOccured = scrollOccured || [object nodeWillCauseScroll:&node];
    [object setSemanticsNode:&node];
    const NSUInteger newChildCount = node.childrenInTraversalOrder.size();
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
        blink::CustomAccessibilityAction& action = actions_[action_id];
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

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid, blink::SemanticsAction action) {
  std::vector<uint8_t> args;
  platform_view_->DispatchSemanticsAction(uid, action, args);
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid,
                                                  blink::SemanticsAction action,
                                                  std::vector<uint8_t> args) {
  platform_view_->DispatchSemanticsAction(uid, action, args);
}

SemanticsObject* AccessibilityBridge::GetOrCreateObject(int32_t uid,
                                                        blink::SemanticsNodeUpdates& updates) {
  SemanticsObject* object = objects_.get()[@(uid)];
  if (!object) {
    // New node case: simply create a new SemanticsObject.
    blink::SemanticsNode node = updates[uid];
    if (node.HasFlag(blink::SemanticsFlags::kIsTextField)) {
      // Text fields are backed by objects that implement UITextInput.
      object = [[[TextInputSemanticsObject alloc] initWithBridge:GetWeakPtr() uid:uid] autorelease];
    } else {
      object = [[[FlutterSemanticsObject alloc] initWithBridge:GetWeakPtr() uid:uid] autorelease];
    }

    objects_.get()[@(uid)] = object;
  } else {
    // Existing node case
    auto nodeEntry = updates.find(object.node.id);
    if (nodeEntry != updates.end()) {
      // There's an update for this node
      blink::SemanticsNode node = nodeEntry->second;
      BOOL isTextField = node.HasFlag(blink::SemanticsFlags::kIsTextField);
      BOOL wasTextField = object.node.HasFlag(blink::SemanticsFlags::kIsTextField);
      if (wasTextField != isTextField) {
        // The node changed its type from text field to something else, or vice versa. In this
        // case, we cannot reuse the existing SemanticsObject implementation. Instead, we replace
        // it with a new instance.
        NSUInteger positionInChildlist = [object.parent.children indexOfObject:object];
        [objects_ removeObjectForKey:@(node.id)];
        if (isTextField) {
          // Text fields are backed by objects that implement UITextInput.
          object = [[[TextInputSemanticsObject alloc] initWithBridge:GetWeakPtr()
                                                                 uid:uid] autorelease];
        } else {
          object = [[[FlutterSemanticsObject alloc] initWithBridge:GetWeakPtr()
                                                               uid:uid] autorelease];
        }
        [object.parent.children replaceObjectAtIndex:positionInChildlist withObject:object];
        objects_.get()[@(node.id)] = object;
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

}  // namespace shell
