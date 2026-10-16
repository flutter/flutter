// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/snapshot_layer_tree_helper.h"

#include <utility>

#include "flutter/fml/logging.h"
#include "flutter/fml/make_copyable.h"

namespace flutter {

SnapshotDelegate::SnapshotDisplayListProvider MakeLayerTreeSnapshotProvider(
    std::unique_ptr<LayerTree> layer_tree,
    std::shared_ptr<TextureRegistry> texture_registry) {
  FML_DCHECK(layer_tree);
  return fml::MakeCopyable([layer_tree = std::move(layer_tree),
                            texture_registry = std::move(texture_registry)](
                               impeller::AiksContext* aiks_context) mutable {
    const DlISize& size = layer_tree->frame_size();
    return layer_tree->Flatten(DlRect::MakeWH(size.width, size.height),
                               texture_registry,
                               /*gr_context=*/nullptr, aiks_context);
  });
}

}  // namespace flutter
