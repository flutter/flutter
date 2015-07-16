// Copyright (c) 2009 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines the GLES2 command buffer commands.

#ifndef GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_IDS_H_
#define GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_IDS_H_

#include "gpu/command_buffer/common/cmd_buffer_common.h"

namespace gpu {
namespace gles2 {

#include "gpu/command_buffer/common/gles2_cmd_ids_autogen.h"

const char* GetCommandName(CommandId command_id);

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_GLES2_CMD_IDS_H_

