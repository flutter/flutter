// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_SESSION_CONNECTION_H_
#define FLUTTER_CONTENT_HANDLER_SESSION_CONNECTION_H_

#include "lib/ui/scenic/client/resources.h"
#include "lib/ui/scenic/client/session.h"
#include "flutter/common/threads.h"
#include "flutter/content_handler/vulkan_surface_producer.h"
#include "flutter/flow/compositor_context.h"
#include "flutter/flow/scene_update_context.h"
#include "lib/fidl/cpp/bindings/interface_handle.h"
#include "lib/ftl/functional/closure.h"
#include "lib/ftl/macros.h"
#include "magenta/system/ulib/mx/include/mx/eventpair.h"

namespace flutter_runner {

class SessionConnection {
 public:
  SessionConnection(scenic::SceneManagerPtr scene_manager,
                    mx::eventpair import_token);

  ~SessionConnection();

  bool has_metrics() const { return scene_update_context_.has_metrics(); }

  void set_metrics_changed_callback(ftl::Closure callback) {
    metrics_changed_callback_ = std::move(callback);
  }

  flow::SceneUpdateContext& scene_update_context() {
    return scene_update_context_;
  }

  scenic_lib::ImportNode& root_node() {
    ASSERT_IS_GPU_THREAD;
    return root_node_;
  }

  void Present(flow::CompositorContext::ScopedFrame& frame,
               ftl::Closure on_present_callback);

 private:
  scenic_lib::Session session_;
  scenic_lib::ImportNode root_node_;
  scenic_lib::Session::PresentCallback present_callback_;
  ftl::Closure pending_on_present_callback_;
  std::unique_ptr<VulkanSurfaceProducer> surface_producer_;
  flow::SceneUpdateContext scene_update_context_;
  ftl::Closure metrics_changed_callback_;

  void OnSessionError();
  void OnSessionEvents(fidl::Array<scenic::EventPtr> events);

  void EnqueueClearOps();

  void OnPresent(scenic::PresentationInfoPtr info);

  FTL_DISALLOW_COPY_AND_ASSIGN(SessionConnection);
};

}  // namespace flutter_runner

#endif  // FLUTTER_CONTENT_HANDLER_SESSION_CONNECTION_H_
