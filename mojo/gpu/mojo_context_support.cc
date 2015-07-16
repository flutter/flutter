// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/gpu/mojo_context_support.h"

#include "base/callback.h"
#include "base/logging.h"

namespace mojo {
namespace {

void RunAndDeleteCallback(void* context) {
  base::Closure* callback = reinterpret_cast<base::Closure*>(context);
  callback->Run();
  delete callback;
}
}

MojoContextSupport::MojoContextSupport(MojoGLES2Context context)
    : context_(context) {
}

MojoContextSupport::~MojoContextSupport() {
}

void MojoContextSupport::SignalSyncPoint(uint32 sync_point,
                                         const base::Closure& callback) {
  MojoGLES2SignalSyncPoint(context_, sync_point, &RunAndDeleteCallback,
                           new base::Closure(callback));
}

void MojoContextSupport::SignalQuery(uint32 query,
                                     const base::Closure& callback) {
  NOTIMPLEMENTED();
}

void MojoContextSupport::SetSurfaceVisible(bool visible) {
  NOTIMPLEMENTED();
}

void MojoContextSupport::Swap() {
  MojoGLES2MakeCurrent(context_);
  MojoGLES2SwapBuffers();
}

void MojoContextSupport::PartialSwapBuffers(const gfx::Rect& sub_buffer) {
  Swap();
}

void MojoContextSupport::ScheduleOverlayPlane(
    int plane_z_order,
    gfx::OverlayTransform plane_transform,
    unsigned overlay_texture_id,
    const gfx::Rect& display_bounds,
    const gfx::RectF& uv_rect) {
  NOTIMPLEMENTED();
}

uint32 MojoContextSupport::InsertFutureSyncPointCHROMIUM() {
  NOTIMPLEMENTED();
  return 0u;
}

void MojoContextSupport::RetireSyncPointCHROMIUM(uint32 sync_point) {
  NOTIMPLEMENTED();
}

}  // namespace mojo
