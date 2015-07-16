// Copyright (c) 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_TRACE_IMPLEMENTATION_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_TRACE_IMPLEMENTATION_H_

#include "base/compiler_specific.h"
#include "gles2_impl_export.h"
#include "gpu/command_buffer/client/gles2_interface.h"

namespace gpu {
namespace gles2 {

// GLES2TraceImplementation is calls TRACE for every GL call.
class GLES2_IMPL_EXPORT GLES2TraceImplementation
    : NON_EXPORTED_BASE(public GLES2Interface) {
 public:
  explicit GLES2TraceImplementation(GLES2Interface* gl);
  ~GLES2TraceImplementation() override;

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gpu/command_buffer/client/gles2_trace_implementation_autogen.h"

 private:
  GLES2Interface* gl_;
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_TRACE_IMPLEMENTATION_H_

