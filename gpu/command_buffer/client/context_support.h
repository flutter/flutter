// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_CONTEXT_SUPPORT_H_
#define GPU_COMMAND_BUFFER_CLIENT_CONTEXT_SUPPORT_H_

#include "base/callback.h"
#include "ui/gfx/geometry/rect.h"
#include "ui/gfx/overlay_transform.h"

namespace gpu {

class ContextSupport {
 public:
  // Runs |callback| when a sync point is reached.
  virtual void SignalSyncPoint(uint32 sync_point,
                               const base::Closure& callback) = 0;

  // Runs |callback| when a query created via glCreateQueryEXT() has cleared
  // passed the glEndQueryEXT() point.
  virtual void SignalQuery(uint32 query, const base::Closure& callback) = 0;

  // For onscreen contexts, indicates that the surface visibility has changed.
  // Clients aren't expected to draw to an invisible surface.
  virtual void SetSurfaceVisible(bool visible) = 0;

  virtual void Swap() = 0;
  virtual void PartialSwapBuffers(const gfx::Rect& sub_buffer) = 0;

  // Schedule a texture to be presented as an overlay synchronously with the
  // primary surface during the next buffer swap.
  // This method is not stateful and needs to be re-scheduled every frame.
  virtual void ScheduleOverlayPlane(int plane_z_order,
                                    gfx::OverlayTransform plane_transform,
                                    unsigned overlay_texture_id,
                                    const gfx::Rect& display_bounds,
                                    const gfx::RectF& uv_rect) = 0;

  virtual uint32 InsertFutureSyncPointCHROMIUM() = 0;
  virtual void RetireSyncPointCHROMIUM(uint32 sync_point) = 0;

 protected:
  ContextSupport() {}
  virtual ~ContextSupport() {}
};

}

#endif  // GPU_COMMAND_BUFFER_CLIENT_CONTEXT_SUPPORT_H_
