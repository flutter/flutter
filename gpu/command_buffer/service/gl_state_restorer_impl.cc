// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/gl_state_restorer_impl.h"

#include "gpu/command_buffer/service/gles2_cmd_decoder.h"

namespace gpu {

GLStateRestorerImpl::GLStateRestorerImpl(
    base::WeakPtr<gles2::GLES2Decoder> decoder)
    : decoder_(decoder) {
}

GLStateRestorerImpl::~GLStateRestorerImpl() {
}

bool GLStateRestorerImpl::IsInitialized() {
  DCHECK(decoder_.get());
  return decoder_->initialized();
}

void GLStateRestorerImpl::RestoreState(const gfx::GLStateRestorer* prev_state) {
  DCHECK(decoder_.get());
  const GLStateRestorerImpl* restorer_impl =
      static_cast<const GLStateRestorerImpl*>(prev_state);
  decoder_->RestoreState(
      restorer_impl ? restorer_impl->GetContextState() : NULL);
}

void GLStateRestorerImpl::RestoreAllTextureUnitBindings() {
  DCHECK(decoder_.get());
  decoder_->RestoreAllTextureUnitBindings(NULL);
}

void GLStateRestorerImpl::RestoreActiveTextureUnitBinding(unsigned int target) {
  DCHECK(decoder_.get());
  decoder_->RestoreActiveTextureUnitBinding(target);
}

void GLStateRestorerImpl::RestoreFramebufferBindings() {
  DCHECK(decoder_.get());
  decoder_->RestoreFramebufferBindings();
}

const gles2::ContextState* GLStateRestorerImpl::GetContextState() const {
  DCHECK(decoder_.get());
  return decoder_->GetContextState();
}

}  // namespace gpu
