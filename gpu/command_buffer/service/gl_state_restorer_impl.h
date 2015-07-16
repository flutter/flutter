// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the GLStateRestorerImpl class.

#ifndef GPU_COMMAND_BUFFER_SERVICE_GL_STATE_RESTORER_IMPL_H_
#define GPU_COMMAND_BUFFER_SERVICE_GL_STATE_RESTORER_IMPL_H_

#include "base/compiler_specific.h"
#include "base/memory/weak_ptr.h"
#include "gpu/gpu_export.h"
#include "ui/gl/gl_state_restorer.h"

namespace gpu {
namespace gles2 {
class GLES2Decoder;
struct ContextState;
}

// This class implements a GLStateRestorer that forwards to a GLES2Decoder.
class GPU_EXPORT GLStateRestorerImpl : public gfx::GLStateRestorer {
 public:
   explicit GLStateRestorerImpl(base::WeakPtr<gles2::GLES2Decoder> decoder);
   ~GLStateRestorerImpl() override;

   bool IsInitialized() override;
   void RestoreState(const gfx::GLStateRestorer* prev_state) override;
   void RestoreAllTextureUnitBindings() override;
   void RestoreActiveTextureUnitBinding(unsigned int target) override;
   void RestoreFramebufferBindings() override;

 private:
   const gles2::ContextState* GetContextState() const;
   base::WeakPtr<gles2::GLES2Decoder> decoder_;

   DISALLOW_COPY_AND_ASSIGN(GLStateRestorerImpl);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_GL_STATE_RESTORER_IMPL_H_
