// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "root_inspect_node.h"

namespace dart_utils {

std::unique_ptr<sys::ComponentInspector> RootInspectNode::inspector_;
std::mutex RootInspectNode::mutex_;

void RootInspectNode::Initialize(sys::ComponentContext* context) {
  std::lock_guard<std::mutex> lock(mutex_);
  if (!inspector_) {
    inspector_ = std::make_unique<sys::ComponentInspector>(context);
  }
}

inspect::Node RootInspectNode::CreateRootChild(const std::string& name) {
  std::lock_guard<std::mutex> lock(mutex_);
  return inspector_->inspector()->GetRoot().CreateChild(name);
}

inspect::Inspector* RootInspectNode::GetInspector() {
  return inspector_->inspector();
}

}  // namespace dart_utils
