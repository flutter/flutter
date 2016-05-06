// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
#define SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_

#include <map>
#include <memory>
#include <string>
#include <vector>

#include "base/macros.h"
#include "base/memory/ref_counted.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/array.h"
#include "mojo/public/cpp/bindings/strong_binding.h"
#include "mojo/public/interfaces/application/service_provider.mojom.h"
#include "sky/engine/platform/geometry/FloatRect.h"
#include "sky/services/semantics/semantics.mojom.h"
#include "sky/shell/platform/ios/framework/Source/FlutterView.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/utils/SkMatrix44.h"

namespace sky {
namespace shell {
class AccessibilityBridge;
}
}

@interface AccessibilityNode : NSObject

/**
 * The globally unique identifier for this node.
 */
@property(nonatomic, readonly) uint32_t uid;

/**
 * The parent of this node in the node tree. Will be nil for the root node and
 * during transient state changes.
 */
@property(nonatomic, readonly) AccessibilityNode* parent;

/**
 * This node's children in the node tree.
 */
@property(nonatomic, readonly) NSArray<AccessibilityNode*>* children;

- (instancetype)init __attribute__((unavailable("Use initWithBridge instead")));
- (instancetype)initWithBridge:(sky::shell::AccessibilityBridge*)bridge
                           uid:(uint32_t)uid NS_DESIGNATED_INITIALIZER;

@end

namespace sky {
namespace shell {

// Class that mediates communication between FlutterView and the Dart layer in
// order to provide accessibility features.
//
// The bridge is owned by the FlutterView that created it. It maintains a raw
// pointer back to the view to enable bidirectional communication with the view
// without introducing a circular reference. Since the strong binding herein may
// destroy the bridge, the view maintains its ownership via a weak reference.
class AccessibilityBridge final : public semantics::SemanticsListener {
 public:
  AccessibilityBridge(FlutterView*, mojo::ServiceProvider*);
  ~AccessibilityBridge() override;

  void UpdateSemanticsTree(mojo::Array<semantics::SemanticsNodePtr>) override;
  AccessibilityNode* UpdateNode(const semantics::SemanticsNodePtr& node);
  void RemoveNode(AccessibilityNode* node);

  base::WeakPtr<AccessibilityBridge> AsWeakPtr();

  FlutterView* getView() { return view_; }

 private:
  // See class docs above about ownership relationship
  FlutterView* view_;
  semantics::SemanticsServerPtr semantics_server_;
  NSMutableDictionary<NSNumber*, AccessibilityNode*>* nodes_;

  mojo::StrongBinding<semantics::SemanticsListener> binding_;

  base::WeakPtrFactory<AccessibilityBridge> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_IOS_FRAMEWORK_SOURCE_ACCESSIBILITY_BRIDGE_H_
