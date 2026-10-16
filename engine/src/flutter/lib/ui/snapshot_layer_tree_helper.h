// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_SNAPSHOT_LAYER_TREE_HELPER_H_
#define FLUTTER_LIB_UI_SNAPSHOT_LAYER_TREE_HELPER_H_

#include <memory>

#include "flutter/common/graphics/texture.h"
#include "flutter/flow/layers/layer_tree.h"
#include "flutter/lib/ui/snapshot_delegate.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Makes a snapshot provider that flattens |layer_tree| to a
///             display list the size of its frame.
///
///             The layer tree is only flattened once the snapshot controller
///             has made a rendering context current, and with the AiksContext
///             that renders the snapshot. Constructing an AiksContext up
///             front, with no context current, breaks the OpenGL ES backend.
///             https://github.com/flutter/flutter/issues/192365
///
SnapshotDelegate::SnapshotDisplayListProvider MakeLayerTreeSnapshotProvider(
    std::unique_ptr<LayerTree> layer_tree,
    std::shared_ptr<TextureRegistry> texture_registry);

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_SNAPSHOT_LAYER_TREE_HELPER_H_
