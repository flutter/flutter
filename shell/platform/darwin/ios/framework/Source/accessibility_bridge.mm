// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"

#include <utility>
#include <vector>

#import <UIKit/UIKit.h>

#include "flutter/shell/platform/darwin/ios/platform_view_ios.h"
#include "lib/ftl/logging.h"

namespace {

constexpr int32_t kRootNodeId = 0;

blink::SemanticsAction GetSemanticsActionForScrollDirection(
    UIAccessibilityScrollDirection direction) {
  // To describe scroll direction, UIAccessibilityScrollDirection uses the direction the scroll bar
  // moves in and SemanticsAction uses the direction the finger moves in. Both move in opposite
  // directions, which is why the following maps left to right and vice versa.
  switch (direction) {
    case UIAccessibilityScrollDirectionRight:
    case UIAccessibilityScrollDirectionPrevious:  // TODO(abarth): Support RTL.
      return blink::SemanticsAction::kScrollLeft;
    case UIAccessibilityScrollDirectionLeft:
    case UIAccessibilityScrollDirectionNext:  // TODO(abarth): Support RTL.
      return blink::SemanticsAction::kScrollRight;
    case UIAccessibilityScrollDirectionUp:
      return blink::SemanticsAction::kScrollDown;
    case UIAccessibilityScrollDirectionDown:
      return blink::SemanticsAction::kScrollUp;
  }
  FTL_DCHECK(false);  // Unreachable
  return blink::SemanticsAction::kScrollUp;
}

}  // namespace

@implementation SemanticsObject {
  shell::AccessibilityBridge* _bridge;
  blink::SemanticsNode _node;
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
  FTL_DCHECK(bridge != nil) << "bridge must be set";
  FTL_DCHECK(uid >= kRootNodeId);
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

- (std::vector<SemanticsObject*>*)children {
  return &_children;
}

- (void)neuter {
  _bridge = nullptr;
  _children.clear();
  self.parent = nil;
}

#pragma mark - UIAccessibility overrides

- (BOOL)isAccessibilityElement {
  // Note: hit detection will only apply to elements that report
  // -isAccessibilityElement of YES. The framework will continue scanning the
  // entire element tree looking for such a hit.
  return _node.HasAction(blink::SemanticsAction::kTap) || _children.empty();
}

- (NSString*)accessibilityLabel {
  if (_node.label.empty()) {
    NSMutableString *label = [NSMutableString string];
    for (auto& child : _children) {
      [label appendString: [child accessibilityLabel]];
      [label appendString: @"\n"];
    }
    return label;
  }
  return @(_node.label.data());
}

- (UIAccessibilityTraits)accessibilityTraits {
  UIAccessibilityTraits traits = UIAccessibilityTraitNone;
  if (_node.HasAction(blink::SemanticsAction::kTap)) {
    traits |= UIAccessibilityTraitButton;
  }
  if (_node.HasAction(blink::SemanticsAction::kIncrease) ||
      _node.HasAction(blink::SemanticsAction::kDecrease)) {
    traits |= UIAccessibilityTraitAdjustable;
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
  return (_uid == kRootNodeId) ? _bridge->view() : _parent;
}

#pragma mark - UIAccessibilityContainer overrides

- (NSInteger)accessibilityElementCount {
  return (NSInteger)_children.size();
}

- (nullable id)accessibilityElementAtIndex:(NSInteger)index {
  if (index < 0 || index >= (NSInteger)_children.size()) {
    return nil;
  }
  return _children[index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
  auto it = std::find(_children.begin(), _children.end(), element);
  if (it == _children.end()) {
    return NSNotFound;
  }
  return it - _children.begin();
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
    _bridge->DispatchSemanticsAction(_uid, blink::SemanticsAction::kIncrease);
  }
}

- (void)accessibilityDecrement {
  if (_node.HasAction(blink::SemanticsAction::kDecrease)) {
    _bridge->DispatchSemanticsAction(_uid, blink::SemanticsAction::kDecrease);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  blink::SemanticsAction action = GetSemanticsActionForScrollDirection(direction);
  if (!_node.HasAction(action))
    return NO;
  _bridge->DispatchSemanticsAction(_uid, action);
  // TODO(tvolkert): provide meaningful string (e.g. "page 2 of 5")
  UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, nil);
  return YES;
}

- (BOOL)accessibilityPerformEscape {
  // TODO(tvolkert): Implement
  return NO;
}

- (BOOL)accessibilityPerformMagicTap {
  // TODO(tvolkert): Implement
  return NO;
}

@end

#pragma mark - AccessibilityBridge impl

namespace shell {

AccessibilityBridge::AccessibilityBridge(UIView* view, PlatformViewIOS* platform_view)
    : view_(view), platform_view_(platform_view) {}

AccessibilityBridge::~AccessibilityBridge() {
  ReleaseObjects(objects_);
  objects_.clear();
}

void AccessibilityBridge::UpdateSemantics(std::vector<blink::SemanticsNode> nodes) {
  for (const blink::SemanticsNode& node : nodes) {
    SemanticsObject* object = GetOrCreateObject(node.id);
    [object setSemanticsNode:&node];
    const size_t childrenCount = node.children.size();
    auto& children = *[object children];
    children.resize(childrenCount);
    for (size_t i = 0; i < childrenCount; ++i) {
      SemanticsObject* child = GetOrCreateObject(node.children[i]);
      child.parent = object;
      children[i] = child;
    }
  }

  SemanticsObject* root = objects_[kRootNodeId];

  if (root) {
    if (!view_.accessibilityElements) {
      view_.accessibilityElements = @[ root ];
    }
  } else {
    view_.accessibilityElements = nil;
  }

  std::unordered_set<int> visited_objects;
  if (root)
    VisitObjectsRecursively(root, &visited_objects);

  std::unordered_map<int, SemanticsObject*> doomed_objects;
  doomed_objects.swap(objects_);
  for (int uid : visited_objects) {
    auto it = doomed_objects.find(uid);
    objects_.insert(*it);
    doomed_objects.erase(it);
    // TODO(abarth): Use extract once we're at C++17.
  }

  SemanticsObject* doomed_focused_object = nil;
  for (const auto& entry : doomed_objects) {
    SemanticsObject* object = entry.second;
    if ([object accessibilityElementIsFocused]) {
      doomed_focused_object = object;
      break;
    }
  }

  if (doomed_focused_object != nil) {
    // Previously focused element is no longer in the tree.
    // Passing `nil` as argument to let iOS figure out what to focus next.
    // TODO(goderbauer): Figure out which element should be focused next and post
    //     UIAccessibilityLayoutChangedNotification with that element instead.
    UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, nil);
  } else {
    // Passing `nil` as argument to keep focus where it is.
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
  }

  ReleaseObjects(doomed_objects);
}

void AccessibilityBridge::DispatchSemanticsAction(int32_t uid, blink::SemanticsAction action) {
  platform_view_->DispatchSemanticsAction(uid, action);
}

SemanticsObject* AccessibilityBridge::GetOrCreateObject(int32_t uid) {
  SemanticsObject* object = objects_[uid];
  if (!object) {
    object = [[SemanticsObject alloc] initWithBridge:this uid:uid];
    objects_[uid] = object;
  }
  return object;
}

void AccessibilityBridge::VisitObjectsRecursively(SemanticsObject* object,
                                                  std::unordered_set<int>* visited_objects) {
  visited_objects->insert(object.uid);
  for (SemanticsObject* child : *[object children])
    VisitObjectsRecursively(child, visited_objects);
}

void AccessibilityBridge::ReleaseObjects(std::unordered_map<int, SemanticsObject*>& objects) {
  for (const auto& entry : objects) {
    SemanticsObject* object = entry.second;
    [object neuter];
    [object release];
  }
  objects.clear();
}

}  // namespace shell
