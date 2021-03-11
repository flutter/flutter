// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_LAYER_TREE_HOLDER_H_
#define FLUTTER_SHELL_COMMON_LAYER_TREE_HOLDER_H_

#include <memory>

#include "flow/layers/layer_tree.h"

namespace flutter {

/**
 * @brief Holds the next `flutter::LayerTree` that needs to be rasterized. The
 * accesses to `LayerTreeHolder` are thread safe. This is important as this
 * component is accessed from both the UI and the Raster threads.
 *
 * A typical flow of events through this component would be:
 *  1. `flutter::Animator` pushed a layer tree to be rendered during each
 * `Animator::Render` call.
 *  2. `flutter::Rasterizer::Draw` consumes the pushed layer tree via `Pop`.
 *
 * It is important to note that if a layer tree held by this class is yet to be
 * consumed, it can be overriden by a newer layer tree produced by the
 * `Animator`. The newness of the layer tree is determined by the target time.
 */
class LayerTreeHolder {
 public:
  LayerTreeHolder();

  ~LayerTreeHolder();

  /**
   * @brief Checks if a layer tree is currently held.
   *
   * @return true is no layer tree is held.
   * @return false if there is a layer tree waiting to be consumed.
   */
  bool IsEmpty() const;

  [[nodiscard]] std::unique_ptr<LayerTree> Pop();

  void PushIfNewer(std::unique_ptr<LayerTree> proposed_layer_tree);

 private:
  mutable std::mutex layer_tree_mutex;
  std::unique_ptr<LayerTree> layer_tree_;

  FML_DISALLOW_COPY_AND_ASSIGN(LayerTreeHolder);
};

};  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_LAYER_TREE_HOLDER_H_
