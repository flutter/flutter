// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/accessibility_bridge.h"

#import <UIKit/UIKit.h>
#include <vector>

#include "base/logging.h"
#include "mojo/public/cpp/application/connect.h"

namespace {

constexpr uint32_t kRootNodeId = 0;

// Contains better abstractions than the raw Mojo data structure
struct Geometry {
  Geometry& operator=(const semantics::SemanticGeometryPtr& other) {
    if (!other->transform.is_null()) {
      transform.setColMajorf(other->transform.data());
    }
    rect.setXYWH(other->left, other->top, other->width, other->height);
    return *this;
  }

  SkMatrix44 transform = SkMatrix44(SkMatrix44::kIdentity_Constructor);
  SkRect rect;
};

}  // namespace

@implementation SemanticObject {
  shell::AccessibilityBridge* _bridge;

  semantics::SemanticFlagsPtr _flags;
  semantics::SemanticStringsPtr _strings;
  Geometry _geometry;
  bool _canBeTapped;
  bool _canBeLongPressed;
  bool _canBeScrolledHorizontally;
  bool _canBeScrolledVertically;
  bool _canBeAdjusted;

  std::vector<SemanticObject*> _children;
}

#pragma mark - Override base class designated initializers

// Method declared as unavailable in the interface
- (instancetype)init {
  [self release];
  [super doesNotRecognizeSelector:_cmd];
  return nil;
}

#pragma mark - Designated initializers

- (instancetype)initWithBridge:(shell::AccessibilityBridge*)bridge
                           uid:(uint32_t)uid {
  DCHECK(bridge != nil) << "bridge must be set";
  DCHECK(uid >= kRootNodeId);
  self = [super init];

  if (self) {
    _bridge = bridge;
    _uid = uid;
  }

  return self;
}

#pragma mark - Semantic object methods

- (void)updateWith:(const semantics::SemanticsNodePtr&)node {
  DCHECK(_uid == node->id);

  if (!node->flags.is_null()) {
    _flags = node->flags.Pass();
  }

  if (!node->strings.is_null()) {
    _strings = node->strings.Pass();
  }

  if (!node->geometry.is_null()) {
    _geometry = node->geometry;
  }

  if (!node->actions.is_null()) {
    _canBeTapped = false;
    _canBeLongPressed = false;
    _canBeScrolledHorizontally = false;
    _canBeScrolledVertically = false;
    for (int action : node->actions) {
      switch (static_cast<semantics::SemanticAction>(action)) {
        case semantics::SemanticAction::TAP:
          _canBeTapped = true;
          break;
        case semantics::SemanticAction::LONG_PRESS:
          _canBeLongPressed = true;
          break;
        case semantics::SemanticAction::SCROLL_LEFT:
        case semantics::SemanticAction::SCROLL_RIGHT:
          _canBeScrolledHorizontally = true;
          break;
        case semantics::SemanticAction::SCROLL_UP:
        case semantics::SemanticAction::SCROLL_DOWN:
          _canBeScrolledVertically = true;
          break;
        case semantics::SemanticAction::INCREASE:
        case semantics::SemanticAction::DECREASE:
          _canBeAdjusted = true;
          break;
      }
    }
  }
}

- (std::vector<SemanticObject*>*)children {
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
  return _canBeTapped || _children.empty();
}

- (NSString*)accessibilityLabel {
  if (_strings.is_null() || _strings->label.get().empty()) {
    return nil;
  }
  return @(_strings->label.data());
}

- (UIAccessibilityTraits)accessibilityTraits {
  UIAccessibilityTraits traits = UIAccessibilityTraitNone;
  if (_canBeTapped) {
    traits |= UIAccessibilityTraitButton;
  }
  if (_canBeAdjusted) {
    traits |= UIAccessibilityTraitAdjustable;
  }
  return traits;
}

- (CGRect)accessibilityFrame {
  SkMatrix44 globalTransform = _geometry.transform;
  for (SemanticObject* parent = _parent; parent; parent = parent.parent) {
    globalTransform = globalTransform * parent->_geometry.transform;
  }

  SkPoint quad[4];
  _geometry.rect.toQuad(quad);
  for (auto& point : quad) {
    SkScalar vector[4] = {point.x(), point.y(), 0, 1};
    globalTransform.mapScalars(vector);
    point.set(vector[0], vector[1]);
  }
  SkRect rect;
  rect.set(quad, 4);

  auto result = CGRectMake(rect.x(), rect.y(), rect.width(), rect.height());
  return UIAccessibilityConvertFrameToScreenCoordinates(result,
                                                        _bridge->view());
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
  // TODO(tvolkert): Implement
  return NO;
}

- (void)accessibilityIncrement {
  if (_canBeAdjusted) {
    _bridge->server()->PerformAction(_uid, semantics::SemanticAction::INCREASE);
  }
}

- (void)accessibilityDecrement {
  if (_canBeAdjusted) {
    _bridge->server()->PerformAction(_uid, semantics::SemanticAction::DECREASE);
  }
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
  BOOL canBeScrolled = NO;
  switch (direction) {
    case UIAccessibilityScrollDirectionRight:
    case UIAccessibilityScrollDirectionLeft:
      canBeScrolled = _canBeScrolledHorizontally;
      break;
    case UIAccessibilityScrollDirectionUp:
    case UIAccessibilityScrollDirectionDown:
      canBeScrolled = _canBeScrolledVertically;
      break;
    default:
      // Note: page turning of reading content is not currently supported
      // (UIAccessibilityScrollDirectionNext,
      //  UIAccessibilityScrollDirectionPrevious)
      canBeScrolled = NO;
      break;
  }

  if (!canBeScrolled) {
    return NO;
  }

  switch (direction) {
    case UIAccessibilityScrollDirectionRight:
      _bridge->server()->PerformAction(_uid,
                                       semantics::SemanticAction::SCROLL_RIGHT);
      break;
    case UIAccessibilityScrollDirectionLeft:
      _bridge->server()->PerformAction(_uid,
                                       semantics::SemanticAction::SCROLL_LEFT);
      break;
    case UIAccessibilityScrollDirectionUp:
      _bridge->server()->PerformAction(_uid,
                                       semantics::SemanticAction::SCROLL_UP);
      break;
    case UIAccessibilityScrollDirectionDown:
      _bridge->server()->PerformAction(_uid,
                                       semantics::SemanticAction::SCROLL_DOWN);
      break;
    default:
      DCHECK(false) << "Unsupported scroll direction: " << direction;
  }

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

AccessibilityBridge::AccessibilityBridge(UIView* view,
                                         mojo::ServiceProvider* serviceProvider)
    : view_(view), binding_(this) {
  mojo::ConnectToService(serviceProvider, mojo::GetProxy(&semantics_server_));
  mojo::InterfaceHandle<semantics::SemanticsListener> listener;
  binding_.Bind(&listener);
  semantics_server_->AddSemanticsListener(listener.Pass());
}

AccessibilityBridge::~AccessibilityBridge() {
  for (const auto& entry : objects_) {
    SemanticObject* object = entry.second;
    [object neuter];
    [object release];
  }
}

void AccessibilityBridge::UpdateSemanticsTree(
    mojo::Array<semantics::SemanticsNodePtr> nodes) {
  std::set<SemanticObject*> updated_objects;
  std::set<SemanticObject*> removed_objects;

  for (const semantics::SemanticsNodePtr& node : nodes) {
    UpdateSemanticObject(node, &updated_objects, &removed_objects);
  }

  for (SemanticObject* object : removed_objects) {
    if (!updated_objects.count(object)) {
      RemoveSemanticObject(object, &updated_objects);
    }
  }

  SemanticObject* root = objects_[kRootNodeId];
  if (root) {
    if (!view_.accessibilityElements) {
      view_.accessibilityElements = @[ root ];
    }
  } else {
    view_.accessibilityElements = nil;
  }
  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
                                  nil);
}

SemanticObject* AccessibilityBridge::UpdateSemanticObject(
    const semantics::SemanticsNodePtr& node,
    std::set<SemanticObject*>* updated_objects,
    std::set<SemanticObject*>* removed_objects) {
  SemanticObject* object = objects_[node->id];
  if (!object) {
    object = [[SemanticObject alloc] initWithBridge:this uid:node->id];
    objects_[node->id] = object;
  }
  [object updateWith:node];
  updated_objects->insert(object);
  if (!node->children.is_null()) {
    std::vector<SemanticObject*>* children = [object children];
    removed_objects->insert(children->begin(), children->end());
    children->clear();
    children->reserve(node->children.size());
    for (const auto& child_node : node->children) {
      SemanticObject* child_object =
          UpdateSemanticObject(child_node, updated_objects, removed_objects);
      child_object.parent = object;
      children->push_back(child_object);
    }
  }
  return object;
}

void AccessibilityBridge::RemoveSemanticObject(
    SemanticObject* object,
    std::set<SemanticObject*>* updated_objects) {
  DCHECK(objects_[object.uid] == object);
  objects_.erase(object.uid);
  for (SemanticObject* child : *[object children]) {
    if (!updated_objects->count(child)) {
      DCHECK(child.parent == object);
      child.parent = nil;
      RemoveSemanticObject(child, updated_objects);
    }
  }
  [object neuter];
  [object release];
}

}  // namespace shell
