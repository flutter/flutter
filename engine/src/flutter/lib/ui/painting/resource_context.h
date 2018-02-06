// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_RESOURCE_CONTEXT_H_
#define FLUTTER_LIB_UI_PAINTING_RESOURCE_CONTEXT_H_

#include "lib/fxl/macros.h"
#include "third_party/skia/include/gpu/GrContext.h"

namespace blink {

class ResourceContext {
 public:
  /**
   * Globally set the GrContext singleton instance.
   */
  static void Set(sk_sp<GrContext> context);

  /**
   * Acquire a GrContext wrapping ResourceContext that's also an exclusive mutex
   * on GrContext operations.
   *
   * Destructing the ResourceContext frees the mutex.
   */
  static std::unique_ptr<ResourceContext> Acquire();

  /**
   * Synchronously signal a freeze on GrContext operations.
   *
   * ResourceContext instances will return nullptr on GrContext Get until
   * unfrozen.
   */
  static void Freeze();

  /**
   * Synchronously unfreeze GrContext operations.
   *
   * ResourceContext instances will continue to return the global GrContext
   * instance on Get.
   */
  static void Unfreeze();

  ResourceContext();
  ~ResourceContext();

  /**
   * Returns global GrContext instance. May return null when operations are
   * frozen.
   *
   * Happens on iOS when background operations on GrContext are forbidden.
   */
  GrContext* Get();

  FXL_DISALLOW_COPY_AND_ASSIGN(ResourceContext);
};

}  // namespace blink

#endif  // FLUTTER_LIB_UI_PAINTING_RESOURCE_CONTEXT_H_
