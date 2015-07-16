// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the binary format definition of the command buffer and
// command buffer commands.

#include "gpu/command_buffer/common/cmd_buffer_common.h"

#include "gpu/command_buffer/common/command_buffer.h"

namespace gpu {
#if !defined(_WIN32)
// gcc needs this to link, but MSVC requires it not be present
const int32 CommandHeader::kMaxSize;
#endif
namespace cmd {

const char* GetCommandName(CommandId command_id) {
  static const char* const names[] = {
  #define COMMON_COMMAND_BUFFER_CMD_OP(name) # name,

  COMMON_COMMAND_BUFFER_CMDS(COMMON_COMMAND_BUFFER_CMD_OP)

  #undef COMMON_COMMAND_BUFFER_CMD_OP
  };

  int id = static_cast<int>(command_id);
  return (id >= 0 && id < kNumCommands) ? names[id] : "*unknown-command*";
}

}  // namespace cmd

#if !defined(NACL_WIN64)
// TODO(apatrick): this is a temporary optimization while skia is calling
// RendererGLContext::MakeCurrent prior to every GL call. It saves returning 6
// ints redundantly when only the error is needed for the CommandBufferProxy
// implementation.
error::Error CommandBuffer::GetLastError() {
  return GetLastState().error;
}
#endif

}  // namespace gpu


