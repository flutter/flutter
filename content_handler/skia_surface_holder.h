// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_CONTENT_HANDLER_SKIA_SURFACE_HOLDER_H_
#define FLUTTER_CONTENT_HANDLER_SKIA_SURFACE_HOLDER_H_

#include "apps/mozart/services/composition/interfaces/image.mojom.h"
#include "lib/ftl/macros.h"
#include "mojo/services/geometry/interfaces/geometry.mojom.h"
#include "third_party/skia/include/core/SkSize.h"
#include "third_party/skia/include/core/SkSurface.h"

namespace flutter_content_handler {

// Provides an |SkSurface| backed by a shared memory buffer for software
// rendering which can then be passed to the Mozart compositor in the form
// of an |Image|.
class SkiaSurfaceHolder {
 public:
  SkiaSurfaceHolder(const SkISize& size);
  ~SkiaSurfaceHolder();

  // Gets the |SkSurface| backed by this buffer.
  const sk_sp<SkSurface>& surface() const { return surface_; }

  // Gets an |Image| backed by this buffer, transferring ownership of the
  // underlying shared memory buffer to the image.  The image can then be
  // sent to the Mozart compositor as an |ImageResource|.
  // This method must be called at most once.
  //
  // Note: The underlying shared memory buffer remains mapped in this process
  // (and the |SkSurface| remains usable) until the |SkiaSurfaceHolder|
  // itself is destroyed.
  mozart::ImagePtr TakeImage();

 private:
  mojo::ScopedSharedBufferHandle buffer_handle_;
  void* buffer_;
  sk_sp<SkSurface> surface_;

  FTL_DISALLOW_COPY_AND_ASSIGN(SkiaSurfaceHolder);
};

}  // namespace flutter_content_handler

#endif  // FLUTTER_CONTENT_HANDLER_SKIA_SURFACE_HOLDER_H_
