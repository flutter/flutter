// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file defines the CommandBufferEngine class, providing the main loop for
// the service, exposing the RPC API, managing the command parser.

#ifndef GPU_COMMAND_BUFFER_SERVICE_CMD_BUFFER_ENGINE_H_
#define GPU_COMMAND_BUFFER_SERVICE_CMD_BUFFER_ENGINE_H_

#include "base/basictypes.h"
#include "gpu/command_buffer/common/buffer.h"

namespace gpu {

class CommandBufferEngine {
 public:
  CommandBufferEngine() {
  }

  virtual ~CommandBufferEngine() {
  }

  // Gets the base address and size of a registered shared memory buffer.
  // Parameters:
  //   shm_id: the identifier for the shared memory buffer.
  virtual scoped_refptr<gpu::Buffer> GetSharedMemoryBuffer(int32 shm_id) = 0;

  // Sets the token value.
  virtual void set_token(int32 token) = 0;

  // Sets the shared memory buffer used for commands.
  virtual bool SetGetBuffer(int32 transfer_buffer_id) = 0;

  // Sets the "get" pointer. Return false if offset is out of range.
  virtual bool SetGetOffset(int32 offset) = 0;

  // Gets the "get" pointer.
  virtual int32 GetGetOffset() = 0;

 private:
  DISALLOW_COPY_AND_ASSIGN(CommandBufferEngine);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_CMD_BUFFER_ENGINE_H_
