// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_INTERFACE_STUB_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_INTERFACE_STUB_H_

#include "gpu/command_buffer/client/gles2_interface.h"

namespace gpu {
namespace gles2 {

// This class a stub to help with mocks for the GLES2Interface class.
class GLES2InterfaceStub : public GLES2Interface {
 public:
  GLES2InterfaceStub();
  ~GLES2InterfaceStub() override;

  // Include the auto-generated part of this class. We split this because
  // it means we can easily edit the non-auto generated parts right here in
  // this file instead of having to edit some template or the code generator.
  #include "gpu/command_buffer/client/gles2_interface_stub_autogen.h"
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_INTERFACE_STUB_H_
