// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_FLOW_EXPORT_NODE_H_
#define FLUTTER_FLOW_EXPORT_NODE_H_

#include <memory>

#include <mx/eventpair.h>

#include "apps/mozart/lib/scene/client/resources.h"
#include "flutter/flow/scene_update_context.h"
#include "lib/fidl/dart/sdk_ext/src/handle.h"
#include "lib/ftl/build_config.h"
#include "lib/ftl/macros.h"
#include "lib/ftl/memory/ref_counted.h"
#include "lib/ftl/synchronization/mutex.h"
#include "lib/ftl/synchronization/thread_annotations.h"
#include "third_party/skia/include/core/SkPoint.h"

namespace flow {

// Represents a node which is being exported from the session.
// This object is created on the UI thread but the entity node it contains
// must be created and destroyed by the rasterizer thread.
//
// Therefore this object is thread-safe.
class ExportNode : public ftl::RefCountedThreadSafe<ExportNode> {
 public:
  ExportNode(ftl::RefPtr<fidl::dart::Handle> export_token_handle);

  // Binds the export token to the entity node and adds it as a child of
  // the specified container.
  void Bind(SceneUpdateContext& context,
            mozart::client::ContainerNode& container,
            const SkPoint& offset,
            bool hit_testable);

 private:
  ~ExportNode();

  ftl::Mutex mutex_;
  mx::eventpair export_token_ FTL_GUARDED_BY(mutex_);
  std::unique_ptr<mozart::client::EntityNode> node_ FTL_GUARDED_BY(mutex_);

  FRIEND_MAKE_REF_COUNTED(ExportNode);
  FRIEND_REF_COUNTED_THREAD_SAFE(ExportNode);
  FTL_DISALLOW_COPY_AND_ASSIGN(ExportNode);
};

}  // namespace flow

#endif  // FLUTTER_FLOW_EXPORT_NODE_H_
