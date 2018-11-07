// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/flow/layers/clip_path_layer.h"

#if defined(OS_FUCHSIA)

#include "lib/ui/scenic/fidl_helpers.h"  // nogncheck

#endif  // defined(OS_FUCHSIA)

namespace flow {

ClipPathLayer::ClipPathLayer(Clip clip_behavior)
    : clip_behavior_(clip_behavior) {}

ClipPathLayer::~ClipPathLayer() = default;

void ClipPathLayer::Preroll(PrerollContext* context, const SkMatrix& matrix) {
  SkRect child_paint_bounds = SkRect::MakeEmpty();
  PrerollChildren(context, matrix, &child_paint_bounds);

  if (child_paint_bounds.intersect(clip_path_.getBounds())) {
    set_paint_bounds(child_paint_bounds);
  }
}

#if defined(OS_FUCHSIA)

void ClipPathLayer::UpdateScene(SceneUpdateContext& context) {
  FML_DCHECK(needs_system_composite());

  // TODO(MZ-140): Must be able to specify paths as shapes to nodes.
  //               Treating the shape as a rectangle for now.
  auto bounds = clip_path_.getBounds();
  scenic::Rectangle shape(context.session(),  // session
                          bounds.width(),     //  width
                          bounds.height()     //  height
  );

  // TODO(liyuqian): respect clip_behavior_
  SceneUpdateContext::Clip clip(context, shape, bounds);
  UpdateSceneChildren(context);
}

#endif  // defined(OS_FUCHSIA)

void ClipPathLayer::Paint(PaintContext& context) const {
  TRACE_EVENT0("flutter", "ClipPathLayer::Paint");
  FML_DCHECK(needs_painting());

  SkAutoCanvasRestore save(context.canvas, true);
  context.canvas->clipPath(clip_path_, clip_behavior_ != Clip::hardEdge);
  if (clip_behavior_ == Clip::antiAliasWithSaveLayer) {
    context.canvas->saveLayer(paint_bounds(), nullptr);
  }
  PaintChildren(context);
  if (clip_behavior_ == Clip::antiAliasWithSaveLayer) {
    context.canvas->restore();
  }
}

}  // namespace flow
