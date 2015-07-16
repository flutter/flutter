// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_image_stub.h"

namespace gfx {

GLImageStub::GLImageStub() {}

GLImageStub::~GLImageStub() {}

gfx::Size GLImageStub::GetSize() { return gfx::Size(1, 1); }

bool GLImageStub::BindTexImage(unsigned target) { return true; }

bool GLImageStub::CopyTexImage(unsigned target) { return true; }

bool GLImageStub::ScheduleOverlayPlane(gfx::AcceleratedWidget widget,
                                       int z_order,
                                       OverlayTransform transform,
                                       const Rect& bounds_rect,
                                       const RectF& crop_rect) {
  return false;
}

}  // namespace gfx
