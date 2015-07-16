// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/gles2_trace_implementation.h"
#include "gpu/command_buffer/common/trace_event.h"

namespace gpu {
namespace gles2 {

GLES2TraceImplementation::GLES2TraceImplementation(GLES2Interface* gl)
    : gl_(gl) {
}

GLES2TraceImplementation::~GLES2TraceImplementation() {
}

// Include the auto-generated part of this file. We split this because it means
// we can easily edit the non-auto generated parts right here in this file
// instead of having to edit some template or the code generator.
#include "gpu/command_buffer/client/gles2_trace_implementation_impl_autogen.h"

}  // namespace gles2
}  // namespace gpu

