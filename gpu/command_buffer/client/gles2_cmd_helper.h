// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_CLIENT_GLES2_CMD_HELPER_H_
#define GPU_COMMAND_BUFFER_CLIENT_GLES2_CMD_HELPER_H_

#include "gpu/command_buffer/client/cmd_buffer_helper.h"
#include "gpu/command_buffer/common/gles2_cmd_format.h"
#include "gpu/gpu_export.h"

namespace gpu {
namespace gles2 {

// A class that helps write GL command buffers.
class GPU_EXPORT GLES2CmdHelper : public CommandBufferHelper {
 public:
  explicit GLES2CmdHelper(CommandBuffer* command_buffer);
  ~GLES2CmdHelper() override;

  // Include the auto-generated part of this class. We split this because it
  // means we can easily edit the non-auto generated parts right here in this
  // file instead of having to edit some template or the code generator.
  #include "gpu/command_buffer/client/gles2_cmd_helper_autogen.h"

  // Helpers that could not be auto-generated.
  // TODO(gman): Auto generate these.
  void CreateAndConsumeTextureCHROMIUMImmediate(GLenum target,
                                                uint32_t client_id,
                                                const GLbyte* _mailbox) {
    const uint32_t size =
        gles2::cmds::CreateAndConsumeTextureCHROMIUMImmediate::ComputeSize();
    gles2::cmds::CreateAndConsumeTextureCHROMIUMImmediate* c =
        GetImmediateCmdSpaceTotalSize<
            gles2::cmds::CreateAndConsumeTextureCHROMIUMImmediate>(size);
    if (c) {
      c->Init(target, client_id, _mailbox);
    }
  }

 private:
  DISALLOW_COPY_AND_ASSIGN(GLES2CmdHelper);
};

}  // namespace gles2
}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_CLIENT_GLES2_CMD_HELPER_H_

