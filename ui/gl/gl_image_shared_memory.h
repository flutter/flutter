// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef UI_GL_GL_IMAGE_SHARED_MEMORY_H_
#define UI_GL_GL_IMAGE_SHARED_MEMORY_H_

#include "base/memory/scoped_ptr.h"
#include "ui/gfx/gpu_memory_buffer.h"
#include "ui/gl/gl_image_memory.h"

namespace gfx {

class GL_EXPORT GLImageSharedMemory : public GLImageMemory {
 public:
  GLImageSharedMemory(const gfx::Size& size, unsigned internalformat);

  bool Initialize(const gfx::GpuMemoryBufferHandle& handle,
                  gfx::GpuMemoryBuffer::Format format);

  // Overridden from GLImage:
  void Destroy(bool have_context) override;

 protected:
  ~GLImageSharedMemory() override;

 private:
  scoped_ptr<base::SharedMemory> shared_memory_;

  DISALLOW_COPY_AND_ASSIGN(GLImageSharedMemory);
};

}  // namespace gfx

#endif  // UI_GL_GL_IMAGE_SHARED_MEMORY_H_
