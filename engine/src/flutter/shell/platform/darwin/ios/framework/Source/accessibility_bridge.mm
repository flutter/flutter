// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"
#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_text_entry.h"

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
  SemanticsObjectContainer* _container;
  std::vector<SemanticsObject*> _children;
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

- (void)dealloc {
  _bridge = nullptr;
  _children.clear();
  [_parent release];
  [_container release];
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

- (std::vector<SemanticsObject*>*)children {
  return &_children;
}

- (BOOL)hasChildren {
  return _children.size() != 0;
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.
  return [self node].flags != 0 || ![self node].label.empty() || ![self node].value.empty() ||
         ![self node].hint.empty() ||
         ([self node].actions & ~blink::kScrollableSemanticsActions) != 0;
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
  CGFloat scale = [[[self bridge] -> view() window] screen].scale;
  auto result =
      CGRectMake(rect.x() / scale, rect.y() / scale, rect.width() / scale, rect.height() / scale);
  return UIAccessibilityConvertFrameToScreenCoordinates(result, [self bridge] -> view());
}

#pragma mark - UIAccessibilityElement protocol

- (id)accessibilityContainer {
  if ([self hasChildren] || [self uid] == kRootNodeId) {
    if (_container == nil)
      _container =
          [[SemanticsObjectContainer alloc] initWithSemanticsObject:self bridge:[self bridge]];
    return _container;
  }
  NSAssert([self parent] != nil, @"Illegal access to non-existent parent of root semantics node");
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

#pragma mark UIAccessibilityFocus overrides

- (void)accessibilityElementDidBecomeFocused {
  if ([self node].HasAction(blink::SemanticsAction::kDidGainAccessibilityFocus)) {
    [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kDidGainAccessibilityFocus);
  }
}

- (void)accessibilityElementDidLoseFocus {
  if ([self node].HasAction(blink::SemanticsAction::kDidLoseAccessibilityFocus)) {
    [self bridge] -> DispatchSemanticsAction([self uid], blink::SemanticsAction::kDidLoseAccessibilityFocus);
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

- (instancetype)initWithBridge:(shell::AccessibilityBridge*)bridge uid:(int32_t)uid {
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
  if ([self node].HasFlag(blink::SemanticsFlags::kIsSelected) ||
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
  return traits;
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

UIView<UITextInput>* AccessibilityBridge::textInputView() {
  return [platform_view_->text_input_plugin() textInputView];
}

void AccessibilityBridge::UpdateSemantics(blink::SemanticsNodeUpdates nodes) {
  // Children are received in paint order (inverse hit testing order). We need to bring them into
  // traversal order (top left to bottom right, with hit testing order as tie breaker).
  NSMutableSet<SemanticsObject*>* childOrdersToUpdate = [[[NSMutableSet alloc] init] autorelease];
  BOOL layoutChanged = NO;
  BOOL scrollOccured = NO;

  for (const auto& entry : nodes) {
    const blink::SemanticsNode& node = entry.second;
    SemanticsObject* object = GetOrCreateObject(node.id, nodes);
    layoutChanged = layoutChanged || [object nodeWillCauseLayoutChange:&node];
    scrollOccured = scrollOccured || [object nodeWillCauseScroll:&node];
    [object setSemanticsNode:&node];
    const size_t childrenCount = node.children.size();
    auto& children = *[object children];
    children.resize(childrenCount);
    for (size_t i = 0; i < childrenCount; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.children[i], nodes);
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
  if (scrollOccured) {
    // TODO(tvolkert): provide meaningful string (e.g. "page 2 of 5")
    UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, @"");
  }
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid, blink::SemanticsAction action) {
  std::vector<uint8_t> args;
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
      object = [[[TextInputSemanticsObject alloc] initWithBridge:this uid:uid] autorelease];
    } else {
      object = [[[FlutterSemanticsObject alloc] initWithBridge:this uid:uid] autorelease];
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
        auto positionInChildlist =
            std::find(object.parent.children->begin(), object.parent.children->end(), object);
        [objects_ removeObjectForKey:@(node.id)];
        if (isTextField) {
          // Text fields are backed by objects that implement UITextInput.
          object = [[[TextInputSemanticsObject alloc] initWithBridge:this uid:uid] autorelease];
        } else {
          object = [[[FlutterSemanticsObject alloc] initWithBridge:this uid:uid] autorelease];
        }
        *positionInChildlist = object;
        objects_.get()[@(node.id)] = object;
      }
    }
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
  if ([type isEqualToString:@"announce"]) {
    NSString* message = annotatedEvent[@"data"][@"message"];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, message);
  } else {
    NSCAssert(NO, @"Invalid event type %@", type);
  }
}

}  // namespace shell
