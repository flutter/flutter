// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_ENGINE_H_
#define FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_ENGINE_H_

#include <memory>

#include "flutter/fml/macros.h"
#include "flutter/shell/common/shell.h"
#include "flutter/shell/common/thread_host.h"
#include "flutter/shell/platform/embedder/embedder.h"

namespace shell {

// The object that is returned to the embedder as an opaque pointer to the
// instance of the Flutter engine.
class EmbedderEngine {
 public:
  EmbedderEngine(ThreadHost thread_host,
                 blink::TaskRunners task_runners,
                 blink::Settings settings,
                 Shell::CreateCallback<PlatformView> on_create_platform_view,
                 Shell::CreateCallback<Rasterizer> on_create_rasterizer);

  ~EmbedderEngine();

  bool NotifyCreated();

  bool NotifyDestroyed();

  bool Run(RunConfiguration run_configuration);

  bool IsValid() const;

  bool SetViewportMetrics(blink::ViewportMetrics metrics);

  bool DispatchPointerDataPacket(
      std::unique_ptr<blink::PointerDataPacket> packet);

  bool SendPlatformMessage(fml::RefPtr<blink::PlatformMessage> message);

 private:
  const ThreadHost thread_host_;
  std::unique_ptr<Shell> shell_;
  bool is_valid_ = false;

  FML_DISALLOW_COPY_AND_ASSIGN(EmbedderEngine);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_PLATFORM_EMBEDDER_EMBEDDER_ENGINE_H_
