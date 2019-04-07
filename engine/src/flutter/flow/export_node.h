// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_EXPORT_NODE_H_
#define FLUTTER_FLOW_EXPORT_NODE_H_

#include <lib/ui/scenic/cpp/resources.h>
#include <lib/zx/eventpair.h>
#include <third_party/skia/include/core/SkMatrix.h>
#include <third_party/skia/include/core/SkPoint.h>
#include <third_party/skia/include/core/SkSize.h>
#include <zircon/types.h>

#include <memory>

#include "flutter/flow/scene_update_context.h"
#include "flutter/fml/macros.h"

namespace flow {

// Represents a Scenic |ExportNode| resource that exports an |EntityNode| to
// another session.
//
// This object is created and destroyed on the |Rasterizer|'s' thread.
class ExportNode {
 public:
  static void Create(zx_koid_t id, zx::eventpair export_token);
  static void Destroy(zx_koid_t id);
  static ExportNode* FromId(zx_koid_t id);

  // Creates or updates the contained EntityNode resource using the specified
  // |SceneUpdateContext|.
  void UpdateScene(SceneUpdateContext& context,
                   const SkPoint& offset,
                   const SkSize& size,
                   bool hit_testable);

 private:
  ExportNode(zx::eventpair export_token);

  zx::eventpair pending_export_token_;
  std::unique_ptr<scenic::EntityNode> export_node_;

  FML_DISALLOW_COPY_AND_ASSIGN(ExportNode);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_EXPORT_NODE_H_
