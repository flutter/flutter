// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/client/gles2_cmd_helper.h"

namespace gpu {
namespace gles2 {

GLES2CmdHelper::GLES2CmdHelper(CommandBuffer* command_buffer)
    : CommandBufferHelper(command_buffer) {
}

GLES2CmdHelper::~GLES2CmdHelper() {
}

}  // namespace gles2
}  // namespace gpu



