// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_MOZART_SCENE_UPDATE_CONTEXT_H_
#define FLUTTER_FLOW_MOZART_SCENE_UPDATE_CONTEXT_H_

#include <memory>
#include <vector>

#include "flutter/flow/compositor_context.h"
#include "lib/ftl/build_config.h"
#include "lib/ftl/logging.h"
#include "lib/ftl/macros.h"
#include "third_party/skia/include/core/SkRect.h"
#include "third_party/skia/include/core/SkSurface.h"

#if defined(OS_FUCHSIA)
#include "apps/mozart/services/composition/nodes.fidl.h"
#include "apps/mozart/services/composition/resources.fidl.h"
#include "apps/mozart/services/images/image.fidl.h"
#endif  // defined(OS_FUCHSIA)

namespace mozart {
class BufferProducer;
class Node;
class SceneUpdate;
}  // namespace mozart

namespace flow {
class Layer;
class SceneUpdateContext;

#if defined(OS_FUCHSIA)

class SceneUpdateContext {
 public:
  SceneUpdateContext(mozart::SceneUpdate* update,
                     mozart::BufferProducer* buffer_producer);
  ~SceneUpdateContext();

  mozart::SceneUpdate* update() const { return update_; }

  void AddLayerToCurrentPaintTask(Layer* layer);
  void FinalizeCurrentPaintTaskIfNeeded(mozart::Node* container,
                                        const SkMatrix& ctm);

  uint32_t AddResource(mozart::ResourcePtr resource);
  void AddChildNode(mozart::Node* container, mozart::NodePtr child);

  void ExecutePaintTasks(CompositorContext::ScopedFrame& frame);

 private:
  mozart::NodePtr FinalizeCurrentPaintTask(const SkMatrix& ctm);

  struct CurrentPaintTask {
    CurrentPaintTask();
    void Clear();

    SkRect bounds;
    std::vector<Layer*> layers;
  };

  struct PaintTask {
    sk_sp<SkSurface> surface;
    SkScalar left;
    SkScalar top;
    SkScalar scaleX;
    SkScalar scaleY;
    std::vector<Layer*> layers;
  };

  mozart::SceneUpdate* update_;
  mozart::BufferProducer* buffer_producer_;

  CurrentPaintTask current_paint_task_;
  std::vector<PaintTask> paint_tasks_;

  uint32_t next_resource_id_ = 1;
  uint32_t next_node_id_ = 1;

  FTL_DISALLOW_COPY_AND_ASSIGN(SceneUpdateContext);
};

#endif  // defined(OS_FUCHSIA)

}  // namespace flow

#endif  // FLUTTER_FLOW_MOZART_SCENE_UPDATE_CONTEXT_H_
