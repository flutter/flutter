// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/gles2_interface_stub.h"

namespace gpu {
namespace gles2 {

GLES2InterfaceStub::GLES2InterfaceStub() {
}

GLES2InterfaceStub::~GLES2InterfaceStub() {
}

// Include the auto-generated part of this class. We split this because
// it means we can easily edit the non-auto generated parts right here in
// this file instead of having to edit some template or the code generator.
#include "gpu/command_buffer/client/gles2_interface_stub_impl_autogen.h"

}  // namespace gles2
}  // namespace gpu


