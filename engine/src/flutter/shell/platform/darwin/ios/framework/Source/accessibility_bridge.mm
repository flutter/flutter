// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"

#include <utility>
#include <vector>

#import <UIKit/UIKit.h>

#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include "lib/fxl/logging.h"

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
  FXL_DCHECK(false);  // Unreachable
  return blink::SemanticsAction::kScrollUp;
}

bool GeometryComparator(SemanticsObject* a, SemanticsObject* b) {
  // Should a go before b?
  CGRect rectA = [a accessibilityFrame];
  CGRect rectB = [b accessibilityFrame];
  CGFloat top = rectA.origin.y - rectB.origin.y;
  if (top == 0.0)
    return rectA.origin.x - rectB.origin.x < 0.0;
  return top < 0.0;
}

}  // namespace

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
                                 bridge:(shell::AccessibilityBridge*)bridge
    NS_DESIGNATED_INITIALIZER;
@end

@implementation SemanticsObject {
  shell::AccessibilityBridge* _bridge;
  blink::SemanticsNode _node;
  std::vector<SemanticsObject*> _children;
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

- (instancetype)initWithBridge:(shell::AccessibilityBridge*)bridge uid:(int32_t)uid {
  FXL_DCHECK(bridge != nil) << "bridge must be set";
  FXL_DCHECK(uid >= kRootNodeId);
  self = [super init];

  if (self) {
    _bridge = bridge;
    _uid = uid;
  }

  return self;
}

#pragma mark - Semantic object methods

- (void)setSemanticsNode:(const blink::SemanticsNode*)node {
  _node = *node;
}

/**
 * Whether calling `setSemanticsNode:` with `node` would cause a layout change.
 */
- (BOOL)willCauseLayoutChange:(const blink::SemanticsNode*)node {
  return _node.rect != node->rect || _node.transform != node->transform;
}

- (std::vector<SemanticsObject*>*)children {
  return &_children;
}

- (BOOL)hasChildren {
  return _children.size() != 0;
}

- (void)dealloc {
  _bridge = nullptr;
  _children.clear();
  [_parent release];
  if (_container != nil)
    [_container release];
  [super dealloc];
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.
  return _node.flags != 0 || !_node.label.empty() || !_node.value.empty() || !_node.hint.empty() ||
         (_node.actions & ~blink::kScrollableSemanticsActions) != 0;
}

- (NSString*)accessibilityLabel {
  if (_node.label.empty())
    return nil;
  return @(_node.label.data());
}

- (NSString*)accessibilityHint {
  if (_node.hint.empty())
    return nil;
  return @(_node.hint.data());
}

- (NSString*)accessibilityValue {
  if (_node.value.empty())
    return nil;
  return @(_node.value.data());
}

- (UIAccessibilityTraits)accessibilityTraits {
  UIAccessibilityTraits traits = UIAccessibilityTraitNone;
  if (_node.HasAction(blink::SemanticsAction::kIncrease) ||
      _node.HasAction(blink::SemanticsAction::kDecrease)) {
    traits |= UIAccessibilityTraitAdjustable;
  }
  if (_node.HasFlag(blink::SemanticsFlags::kIsSelected) ||
      _node.HasFlag(blink::SemanticsFlags::kIsChecked)) {
    traits |= UIAccessibilityTraitSelected;
  }
  if (_node.HasFlag(blink::SemanticsFlags::kIsButton)) {
    traits |= UIAccessibilityTraitButton;
  }
  return traits;
}

- (CGRect)accessibilityFrame {
  SkMatrix44 globalTransform = _node.transform;
  for (SemanticsObject* parent = _parent; parent; parent = parent.parent) {
    globalTransform = parent->_node.transform * globalTransform;
  }

  SkPoint quad[4];
  _node.rect.toQuad(quad);
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
  CGFloat scale = [[_bridge->view() window] screen].scale;
  auto result =
      CGRectMake(rect.x() / scale, rect.y() / scale, rect.width() / scale, rect.height() / scale);
  return UIAccessibilityConvertFrameToScreenCoordinates(result, _bridge->view());
}

#pragma mark - UIAccessibilityElement protocol

- (id)accessibilityContainer {
  if ([self hasChildren] || _uid == kRootNodeId) {
    if (_container == nil)
      _container = [[SemanticsObjectContainer alloc] initWithSemanticsObject:self bridge:_bridge];
    return _container;
  }
  NSAssert(_parent != nil, @"Illegal access to non-existent parent of root semantics node");
  return [_parent accessibilityContainer];
}

#pragma mark - UIAccessibilityAction overrides

- (BOOL)accessibilityActivate {
  if (!_node.HasAction(blink::SemanticsAction::kTap))
    return NO;
  _bridge->DispatchSemanticsAction(_uid, blink::SemanticsAction::kTap);
  return YES;
}

- (void)accessibilityIncrement {
  if (_node.HasAction(blink::SemanticsAction::kIncrease)) {
    _node.value = _node.increasedValue;
    _bridge->DispatchSemanticsAction(_uid, blink::SemanticsAction::kIncrease);
  }
}

- (void)accessibilityDecrement {
  if (_node.HasAction(blink::SemanticsAction::kDecrease)) {
    _node.value = _node.decreasedValue;
    _bridge->DispatchSemanticsAction(_uid, blink::SemanticsAction::kDecrease);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  blink::SemanticsAction action = GetSemanticsActionForScrollDirection(direction);
  if (!_node.HasAction(action))
    return NO;
  _bridge->DispatchSemanticsAction(_uid, action);
  return YES;
}

@end

@implementation SemanticsObjectContainer {
  SemanticsObject* _semanticsObject;
  shell::AccessibilityBridge* _bridge;
}

#pragma mark - initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

- (instancetype)initWithSemanticsObject:(SemanticsObject*)semanticsObject
                                 bridge:(shell::AccessibilityBridge*)bridge {
  FXL_DCHECK(semanticsObject != nil) << "semanticsObject must be set";
  self = [super init];

  if (self) {
    _semanticsObject = semanticsObject;
    _bridge = bridge;
  }

  return self;
}

#pragma mark - UIAccessibilityContainer overrides

- (NSInteger)accessibilityElementCount {
  return (NSInteger)[_semanticsObject children]->size() + 1;
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  if (index < 0 || index >= [self accessibilityElementCount])
    return nil;
  if (index == 0)
    return _semanticsObject;
  SemanticsObject* child = (*[_semanticsObject children])[index - 1];
  if ([child hasChildren])
    return [child accessibilityContainer];
  return child;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  if (element == _semanticsObject)
    return 0;
  std::vector<SemanticsObject*>* children = [_semanticsObject children];
  for (size_t i = 0; i < children->size(); i++) {
    SemanticsObject* child = (*children)[i];
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
    : view_(view), platform_view_(platform_view), objects_([[NSMutableDictionary alloc] init]) {
  accessibility_channel_.reset([[FlutterBasicMessageChannel alloc]
         initWithName:@"flutter/accessibility"
      binaryMessenger:platform_view->binary_messenger()
                codec:[FlutterStandardMessageCodec sharedInstance]]);
  [accessibility_channel_.get() setMessageHandler:^(id message, FlutterReply reply) {
    HandleEvent((NSDictionary*)message);
  }];
}

AccessibilityBridge::~AccessibilityBridge() {
  view_.accessibilityElements = nil;
  [accessibility_channel_.get() setMessageHandler:nil];
}

void AccessibilityBridge::UpdateSemantics(std::vector<blink::SemanticsNode> nodes) {
  // Children are received in paint order (inverse hit testing order). We need to bring them into
  // traversal order (top left to bottom right, with hit testing order as tie breaker).
  NSMutableSet<SemanticsObject*>* childOrdersToUpdate = [[[NSMutableSet alloc] init] autorelease];
  BOOL layoutChanged = NO;

  for (const blink::SemanticsNode& node : nodes) {
    SemanticsObject* object = GetOrCreateObject(node.id);
    layoutChanged = layoutChanged || [object willCauseLayoutChange:&node];
    [object setSemanticsNode:&node];
    const size_t childrenCount = node.children.size();
    auto& children = *[object children];
    children.resize(childrenCount);
    for (size_t i = 0; i < childrenCount; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.children[i]);
      child.parent = object;
      // Reverting to get hit testing order (as tie breaker for sorting below).
      children[childrenCount - i - 1] = child;
    }

    [childOrdersToUpdate addObject:object];
    if (object.parent)
      [childOrdersToUpdate addObject:object.parent];
  }

  // Bring children into traversal order.
  for (SemanticsObject* object in childOrdersToUpdate) {
    std::vector<SemanticsObject*>* children = [object children];
    std::stable_sort(children->begin(), children->end(), GeometryComparator);
  }

  SemanticsObject* root = objects_.get()[@(kRootNodeId)];

  if (root) {
    if (!view_.accessibilityElements) {
      view_.accessibilityElements = @[ [root accessibilityContainer] ];
    }
  } else {
    view_.accessibilityElements = nil;
  }

  NSMutableArray<NSNumber*>* doomed_uids = [NSMutableArray arrayWithArray:[objects_.get() allKeys]];
  if (root)
    VisitObjectsRecursivelyAndRemove(root, doomed_uids);
  [objects_ removeObjectsForKeys:doomed_uids];

  layoutChanged = layoutChanged || [doomed_uids count] > 0;

  if (layoutChanged) {
    // TODO(goderbauer): figure out which node to focus next.
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  }
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid, blink::SemanticsAction action) {
  std::vector<uint8_t> args;
  platform_view_->DispatchSemanticsAction(uid, action, args);
}

SemanticsObject* AccessibilityBridge::GetOrCreateObject(int32_t uid) {
  SemanticsObject* object = objects_.get()[@(uid)];
  if (!object) {
    object = [[[SemanticsObject alloc] initWithBridge:this uid:uid] autorelease];
    objects_.get()[@(uid)] = object;
  }
  return object;
}

void AccessibilityBridge::VisitObjectsRecursivelyAndRemove(SemanticsObject* object,
                                                           NSMutableArray<NSNumber*>* doomed_uids) {
  [doomed_uids removeObject:@(object.uid)];
  for (SemanticsObject* child : *[object children])
    VisitObjectsRecursivelyAndRemove(child, doomed_uids);
}

void AccessibilityBridge::HandleEvent(NSDictionary<NSString*, id>* annotatedEvent) {
  NSString* type = annotatedEvent[@"type"];
  if ([type isEqualToString:@"scroll"]) {
    // TODO(tvolkert): provide meaningful string (e.g. "page 2 of 5")
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, @"");
  } else if ([type isEqualToString:@"announce"]) {
    NSString* message = annotatedEvent[@"data"][@"message"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message);
  } else {
    NSCAssert(NO, @"Invalid event type %@", type);
  }
}

}  // namespace shell
