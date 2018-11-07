// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_IO_MANAGER_H_
#define FLUTTER_SHELL_COMMON_IO_MANAGER_H_

#include <memory>

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/macros.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace shell {

class IOManager {
 public:
  // Convenience methods for platforms to create a GrContext used to supply to
  // the IOManager. The platforms may create the context themselves if they so
  // desire.
  static sk_sp<GrContext> CreateCompatibleResourceLoadingContext(
      GrBackend backend);

  IOManager(sk_sp<GrContext> resource_context,
            fml::RefPtr<fml::TaskRunner> unref_queue_task_runner);

  ~IOManager();

  fml::WeakPtr<GrContext> GetResourceContext() const;

  fml::RefPtr<flow::SkiaUnrefQueue> GetSkiaUnrefQueue() const;

 private:
  // Resource context management.
  sk_sp<GrContext> resource_context_;
  std::unique_ptr<fml::WeakPtrFactory<GrContext>>
      resource_context_weak_factory_;

  // Unref queue management.
  fml::RefPtr<flow::SkiaUnrefQueue> unref_queue_;

  fml::WeakPtrFactory<IOManager> weak_factory_;

  FML_DISALLOW_COPY_AND_ASSIGN(IOManager);
};

}  // namespace shell

#endif  // FLUTTER_SHELL_COMMON_IO_MANAGER_H_
