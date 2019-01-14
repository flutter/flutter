// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_IO_MANAGER_H_
#define FLUTTER_LIB_UI_IO_MANAGER_H_

#include "flutter/flow/skia_gpu_object.h"
#include "flutter/fml/memory/weak_ptr.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace blink {
// Interface for methods that manage access to the resource GrContext and Skia
// unref queue.  Meant to be implemented by the owner of the resource GrContext,
// i.e. the shell's IOManager.
class IOManager {
 public:
  virtual fml::WeakPtr<GrContext> GetResourceContext() const = 0;

  virtual fml::RefPtr<flow::SkiaUnrefQueue> GetSkiaUnrefQueue() const = 0;
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_IO_MANAGER_H_
