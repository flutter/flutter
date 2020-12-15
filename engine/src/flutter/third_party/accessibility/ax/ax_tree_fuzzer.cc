// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/accessibility/ax_tree.h"
#include "ui/accessibility/ax_tree_observer.h"

class EmptyAXTreeObserver : public ui::AXTreeObserver {
 public:
  EmptyAXTreeObserver() {}
  ~EmptyAXTreeObserver() override {}
};

// Entry point for LibFuzzer.
extern "C" int LLVMFuzzerTestOneInput(const unsigned char* data, size_t size) {
  ui::AXTreeUpdate initial_state;
  size_t i = 0;
  while (i < size) {
    ui::AXNodeData node;
    node.id = data[i++];
    if (i < size) {
      size_t child_count = data[i++];
      for (size_t j = 0; j < child_count && i < size; j++)
        node.child_ids.push_back(data[i++]);
    }
    initial_state.nodes.push_back(node);
  }

  // Don't test absurdly large trees, it might time out.
#if defined(NDEBUG)
  constexpr size_t kMaxNodes = 500000;
#else
  constexpr size_t kMaxNodes = 50000;
#endif
  if (initial_state.nodes.size() > kMaxNodes) {
    LOG(WARNING) << "Skipping input because it's too large";
    return 0;
  }

  // Run with --v=1 to aid in debugging a specific crash.
  VLOG(1) << "Input accessibility tree:\n" << initial_state.ToString();

  EmptyAXTreeObserver observer;
  ui::AXTree tree;
  tree.AddObserver(&observer);
  tree.Unserialize(initial_state);
  tree.RemoveObserver(&observer);

  return 0;
}
