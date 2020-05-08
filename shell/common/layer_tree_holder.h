// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_LAYER_TREE_HOLDER_H_
#define FLUTTER_SHELL_COMMON_LAYER_TREE_HOLDER_H_

#include <memory>

#include "flow/layers/layer_tree.h"

namespace flutter {

class LayerTreeHolder {
 public:
  LayerTreeHolder() = default;

  ~LayerTreeHolder() = default;

  bool IsEmpty() const;

  std::unique_ptr<LayerTree> Get();

  void ReplaceIfNewer(std::unique_ptr<LayerTree> proposed_layer_tree);

 private:
  mutable std::mutex layer_tree_mutex;
  std::unique_ptr<LayerTree> layer_tree_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTreeHolder);
};

};  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_LAYER_TREE_HOLDER_H_
