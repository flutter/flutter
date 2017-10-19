// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_RUNTIME_RUNTIME_DELEGATE_H_
#define FLUTTER_RUNTIME_RUNTIME_DELEGATE_H_

#include <memory>
#include <vector>

#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/semantics/semantics_node.h"
#include "flutter/lib/ui/window/platform_message.h"
#include "third_party/dart/runtime/include/dart_api.h"

namespace blink {

class RuntimeDelegate {
 public:
  virtual std::string DefaultRouteName() = 0;
  virtual void ScheduleFrame() = 0;
  virtual void Render(std::unique_ptr<flow::LayerTree> layer_tree) = 0;
  virtual void UpdateSemantics(std::vector<SemanticsNode> update) = 0;
  virtual void HandlePlatformMessage(fxl::RefPtr<PlatformMessage> message) = 0;

  virtual void DidCreateMainIsolate(Dart_Isolate isolate);
  virtual void DidCreateSecondaryIsolate(Dart_Isolate isolate);

 protected:
  virtual ~RuntimeDelegate();
};

}  // namespace blink

#endif  // FLUTTER_RUNTIME_RUNTIME_DELEGATE_H_
