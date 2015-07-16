// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "ui/gl/gl_image_ref_counted_memory.h"

#include "base/logging.h"
#include "base/memory/ref_counted_memory.h"

namespace gfx {

GLImageRefCountedMemory::GLImageRefCountedMemory(const gfx::Size& size,
                                                 unsigned internalformat)
    : GLImageMemory(size, internalformat) {
}

GLImageRefCountedMemory::~GLImageRefCountedMemory() {
  DCHECK(!ref_counted_memory_.get());
}

bool GLImageRefCountedMemory::Initialize(
    base::RefCountedMemory* ref_counted_memory,
    gfx::GpuMemoryBuffer::Format format) {
  if (!GLImageMemory::Initialize(ref_counted_memory->front(), format))
    return false;

  DCHECK(!ref_counted_memory_.get());
  ref_counted_memory_ = ref_counted_memory;
  return true;
}

void GLImageRefCountedMemory::Destroy(bool have_context) {
  GLImageMemory::Destroy(have_context);
  ref_counted_memory_ = NULL;
}

}  // namespace gfx
