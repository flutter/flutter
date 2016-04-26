// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SKY_SHELL_PLATFORM_IOS_ACCESSIBILITY_BRIDGE_H_
#define SKY_SHELL_PLATFORM_IOS_ACCESSIBILITY_BRIDGE_H_

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
#include "sky/shell/platform/ios/FlutterView.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/utils/SkMatrix44.h"

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

  base::WeakPtr<AccessibilityBridge> AsWeakPtr();

 private:
  class Node;

  scoped_refptr<Node> UpdateNode(const semantics::SemanticsNodePtr& node);
  void RemoveNode(scoped_refptr<Node> node);

  NSArray* CreateAccessibleElements() const NS_RETURNS_RETAINED;

  // See class docs above about ownership relationship
  FlutterView* view_;
  semantics::SemanticsServerPtr semantics_server_;
  std::map<long, scoped_refptr<Node>> nodes_;

  mojo::StrongBinding<semantics::SemanticsListener> binding_;

  base::WeakPtrFactory<AccessibilityBridge> weak_factory_;

  DISALLOW_COPY_AND_ASSIGN(AccessibilityBridge);
};

}  // namespace shell
}  // namespace sky

#endif  // SKY_SHELL_PLATFORM_IOS_ACCESSIBILITY_BRIDGE_H_
