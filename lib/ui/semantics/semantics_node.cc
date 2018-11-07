// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/semantics/semantics_node.h"

#include <string.h>

namespace blink {

SemanticsNode::SemanticsNode() = default;

SemanticsNode::~SemanticsNode() = default;

bool SemanticsNode::HasAction(SemanticsAction action) {
  return (actions & static_cast<int32_t>(action)) != 0;
}

bool SemanticsNode::HasFlag(SemanticsFlags flag) {
  return (flags & static_cast<int32_t>(flag)) != 0;
}

}  // namespace blink
