// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_GPU_MOJO_CONTEXT_SUPPORT_H_
#define MOJO_GPU_MOJO_CONTEXT_SUPPORT_H_

#include "base/macros.h"
#include "gpu/command_buffer/client/context_support.h"
#include "mojo/public/c/gles2/gles2.h"

namespace mojo {

class MojoContextSupport : public gpu::ContextSupport {
 public:
  explicit MojoContextSupport(MojoGLES2Context context);
  ~MojoContextSupport() override;

  // gpu::ContextSupport implementation.
  void SignalSyncPoint(uint32 sync_point,
                       const base::Closure& callback) override;
  void SignalQuery(uint32 query, const base::Closure& callback) override;
  void SetSurfaceVisible(bool visible) override;
  void Swap() override;
  void PartialSwapBuffers(const gfx::Rect& sub_buffer) override;
  void ScheduleOverlayPlane(int plane_z_order,
                            gfx::OverlayTransform plane_transform,
                            unsigned overlay_texture_id,
                            const gfx::Rect& display_bounds,
                            const gfx::RectF& uv_rect) override;
  uint32 InsertFutureSyncPointCHROMIUM() override;
  void RetireSyncPointCHROMIUM(uint32 sync_point) override;

 private:
  MojoGLES2Context context_;
  DISALLOW_COPY_AND_ASSIGN(MojoContextSupport);
};
}

#endif  // MOJO_GPU_MOJO_CONTEXT_SUPPORT_H_
