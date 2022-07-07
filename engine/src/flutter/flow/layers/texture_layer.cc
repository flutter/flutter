// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/texture_layer.h"

#include "flutter/common/graphics/texture.h"

namespace flutter {

TextureLayer::TextureLayer(const SkPoint& offset,
                           const SkSize& size,
                           int64_t texture_id,
                           bool freeze,
                           DlImageSampling sampling)
    : offset_(offset),
      size_(size),
      texture_id_(texture_id),
      freeze_(freeze),
      sampling_(sampling) {}

void TextureLayer::Diff(DiffContext* context, const Layer* old_layer) {
  DiffContext::AutoSubtreeRestore subtree(context);
  if (!context->IsSubtreeDirty()) {
    FML_DCHECK(old_layer);
    auto prev = old_layer->as_texture_layer();
    // TODO(knopp) It would be nice to be able to determine that a texture is
    // dirty
    context->MarkSubtreeDirty(context->GetOldLayerPaintRegion(prev));
  }

  // Make sure DiffContext knows there is a TextureLayer in this subtree.
  // This prevents ContainerLayer from skipping TextureLayer diffing when
  // TextureLayer is inside retained layer.
  // See ContainerLayer::DiffChildren
  // https://github.com/flutter/flutter/issues/92925
  context->MarkSubtreeHasTextureLayer();
  context->AddLayerBounds(SkRect::MakeXYWH(offset_.x(), offset_.y(),
                                           size_.width(), size_.height()));
  context->SetLayerPaintRegion(this, context->CurrentSubtreeRegion());
}

void TextureLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  TRACE_EVENT0("flutter", "TextureLayer::Preroll");

  set_paint_bounds(SkRect::MakeXYWH(offset_.x(), offset_.y(), size_.width(),
                                    size_.height()));
  context->has_texture_layer = true;
  context->subtree_can_inherit_opacity = true;
}

void TextureLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "TextureLayer::Paint");
  FML_DCHECK(needs_painting(context));

  std::shared_ptr<Texture> texture =
      context.texture_registry.GetTexture(texture_id_);
  if (!texture) {
    TRACE_EVENT_INSTANT0("flutter", "null texture");
    return;
  }
  AutoCachePaint cache_paint(context);
  texture->Paint(*context.leaf_nodes_canvas, paint_bounds(), freeze_,
                 context.gr_context, ToSk(sampling_), cache_paint.sk_paint());
}

}  // namespace flutter
