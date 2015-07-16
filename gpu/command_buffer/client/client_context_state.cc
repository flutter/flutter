// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/client_context_state.h"

#include "base/logging.h"

namespace gpu {
namespace gles2 {

ClientContextState::ClientContextState() {
}

ClientContextState::~ClientContextState() {
}

// Include the auto-generated part of this file. We split this because it means
// we can easily edit the non-auto generated parts right here in this file
// instead of having to edit some template or the code generator.
#include "gpu/command_buffer/client/client_context_state_impl_autogen.h"

}  // namespace gles2
}  // namespace gpu


