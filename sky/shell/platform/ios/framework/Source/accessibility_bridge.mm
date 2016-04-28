// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "sky/shell/platform/ios/framework/Source/accessibility_bridge.h"

#include <UIKit/UIKit.h>

#include "mojo/public/cpp/application/connect.h"

namespace sky {
namespace shell {

namespace {

// Contains better abstractions than the raw Mojo data structure
struct Geometry {
  Geometry& operator=(const semantics::SemanticGeometryPtr& other) {
    if (!other->transform.is_null()) {
      transform.setColMajorf(other->transform.data());
    }
    rect.setXYWH(other->left, other->top, other->width, other->height);
    return *this;
  }

  SkMatrix44 transform;
  SkRect rect;
};

}  // anonymous namespace

// Class that holds information about accessibility nodes, which are used
// to construct iOS accessibility elements
class AccessibilityBridge::Node final
    : public base::RefCounted<AccessibilityBridge::Node> {
 public:
  static const uint32_t kUninitializedNodeId = -1;

  Node(AccessibilityBridge*, const semantics::SemanticsNodePtr&);

  void Update(const semantics::SemanticsNodePtr& node);
  void PopulateAccessibleElements(NSMutableArray* accessibleElements);

  uint32_t id_ = kUninitializedNodeId;
  std::vector<scoped_refptr<Node>> children_;
  Node* parent_ = nullptr;

 private:
  friend class base::RefCounted<Node>;

  ~Node();

  void ValidateGlobalRect();
  void ValidateGlobalTransform();

  AccessibilityBridge* bridge_;

  semantics::SemanticFlagsPtr flags_;
  semantics::SemanticStringsPtr strings_;
  Geometry geometry_;

  std::unique_ptr<SkMatrix44> global_transform_;
  std::unique_ptr<SkRect> global_rect_;

  DISALLOW_COPY_AND_ASSIGN(Node);
};

AccessibilityBridge::Node::Node(AccessibilityBridge* bridge,
                                const semantics::SemanticsNodePtr& node)
    : bridge_(bridge) {
  Update(node);
}

void AccessibilityBridge::Node::Update(
    const semantics::SemanticsNodePtr& node) {
  if (id_ == kUninitializedNodeId) {
    id_ = node->id;
  }
  DCHECK(id_ == node->id);

  if (!node->flags.is_null()) {
    flags_ = node->flags.Pass();
  }

  if (!node->strings.is_null()) {
    strings_ = node->strings.Pass();
  }

  if (!node->geometry.is_null()) {
    geometry_ = node->geometry.Pass();
  }

  if (!node->children.is_null()) {
    // Mark children for removal
    for (scoped_refptr<Node> child : children_) {
      DCHECK(child->parent_ != nullptr);
      child->parent_ = nullptr;
    }

    // Set the new list of children
    std::vector<scoped_refptr<Node>> children;
    for (const semantics::SemanticsNodePtr& childNode : node->children) {
      scoped_refptr<Node> child = bridge_->UpdateNode(childNode);
      child->parent_ = this;
      children.push_back(child);
    }
    children.swap(children_);

    // Remove those children that are still marked for removal
    for (scoped_refptr<Node> child : children) {
      if (child->parent_ == nullptr) {
        bridge_->RemoveNode(child);
      }
    }
  }

  global_transform_.release();
  global_rect_.release();
}

void AccessibilityBridge::Node::ValidateGlobalTransform() {
  if (global_transform_ != nullptr) {
    return;
  }

  if (parent_ == nullptr) {
    global_transform_.reset(new SkMatrix44(geometry_.transform));
  } else {
    parent_->ValidateGlobalTransform();
    global_transform_.reset(
        new SkMatrix44(geometry_.transform * *(parent_->global_transform_)));
  }
}

void AccessibilityBridge::Node::ValidateGlobalRect() {
  if (global_rect_ != nullptr) {
    return;
  }

  ValidateGlobalTransform();

  SkPoint quad[4];
  geometry_.rect.toQuad(quad);
  for (auto& point : quad) {
    SkScalar vector[4] = {point.x(), point.y(), 0, 1};
    global_transform_->mapScalars(vector);
    point.set(vector[0], vector[1]);
  }

  global_rect_.reset(new SkRect());
  global_rect_.get()->set(quad, 4);
}

void AccessibilityBridge::Node::PopulateAccessibleElements(
    NSMutableArray* accessibleElements) {
  if (!geometry_.rect.isEmpty()) {
    UIAccessibilityElement* element = [[UIAccessibilityElement alloc]
        initWithAccessibilityContainer:bridge_->view_];
    element.isAccessibilityElement = YES;
    ValidateGlobalRect();
    element.accessibilityFrame =
        CGRectMake(global_rect_->x(), global_rect_->y(), global_rect_->width(),
                   global_rect_->height());
    if (flags_->canBeTapped) {
      // TODO(tvolkert): What about links? We need semantic info in the mojom
      // definition
      element.accessibilityTraits = UIAccessibilityTraitButton;
    }
    if (!strings_->label.get().empty()) {
      element.accessibilityLabel =
          [NSString stringWithUTF8String:strings_->label.data()];
    }
    [accessibleElements insertObject:element atIndex:0];
    [element release];
  }

  for (scoped_refptr<Node> child : children_) {
    child->PopulateAccessibleElements(accessibleElements);
  }
}

AccessibilityBridge::Node::~Node() {}

AccessibilityBridge::AccessibilityBridge(FlutterView* view,
                                         mojo::ServiceProvider* serviceProvider)
    : view_(view), binding_(this), weak_factory_(this) {
  mojo::ConnectToService(serviceProvider, &semantics_server_);
  mojo::InterfaceHandle<semantics::SemanticsListener> listener;
  binding_.Bind(&listener);
  semantics_server_->AddSemanticsListener(listener.Pass());
}

void AccessibilityBridge::UpdateSemanticsTree(
    mojo::Array<semantics::SemanticsNodePtr> nodes) {
  for (const semantics::SemanticsNodePtr& node : nodes) {
    UpdateNode(node);
  }

  NSArray* accessibleElements = CreateAccessibleElements();
  view_.accessibilityElements = accessibleElements;
  [accessibleElements release];

  UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification,
                                  nil);
}

base::WeakPtr<AccessibilityBridge> AccessibilityBridge::AsWeakPtr() {
  return weak_factory_.GetWeakPtr();
}

scoped_refptr<AccessibilityBridge::Node> AccessibilityBridge::UpdateNode(
    const semantics::SemanticsNodePtr& node) {
  scoped_refptr<Node> persistentNode;
  const auto& iter = nodes_.find(node->id);
  if (iter == nodes_.end()) {
    persistentNode = new Node(this, node);
    nodes_[node->id] = persistentNode;
  } else {
    persistentNode = iter->second;
    persistentNode->Update(node);
  }
  DCHECK(persistentNode != nullptr);
  return persistentNode;
}

void AccessibilityBridge::RemoveNode(scoped_refptr<Node> node) {
  DCHECK(nodes_.find(node->id_) != nodes_.end());
  DCHECK(nodes_.at(node->id_)->parent_ == nullptr);
  nodes_.erase(node->id_);
  for (scoped_refptr<Node>& child : node->children_) {
    child->parent_ = nullptr;
    RemoveNode(child);
  }
}

NSArray* AccessibilityBridge::CreateAccessibleElements() const
    NS_RETURNS_RETAINED {
  NSMutableArray* accessibleElements = [[NSMutableArray alloc] init];
  for (const auto& iter : nodes_) {
    // TODO(tvolkert): There should only ever be 1 root. Keep a reference
    // to it so we don't have to look for it here.
    if (iter.second->parent_ == nullptr) {
      iter.second->PopulateAccessibleElements(accessibleElements);
    }
  }
  return accessibleElements;
}

AccessibilityBridge::~AccessibilityBridge() {}

}  // namespace shell
}  // namespace sky
