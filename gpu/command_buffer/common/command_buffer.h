// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_H_
#define GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_H_

#include "gpu/command_buffer/common/buffer.h"
#include "gpu/command_buffer/common/constants.h"
#include "gpu/gpu_export.h"

namespace base {
class SharedMemory;
}

namespace gpu {

// Common interface for CommandBuffer implementations.
class GPU_EXPORT CommandBuffer {
 public:
  struct State {
    State()
        : get_offset(0),
          token(-1),
          error(error::kNoError),
          context_lost_reason(error::kUnknown),
          generation(0) {
    }

    // The offset (in entries) from which the reader is reading.
    int32 get_offset;

    // The current token value. This is used by the writer to defer
    // changes to shared memory objects until the reader has reached a certain
    // point in the command buffer. The reader is responsible for updating the
    // token value, for example in response to an asynchronous set token command
    // embedded in the command buffer. The default token value is zero.
    int32 token;

    // Error status.
    error::Error error;

    // Lost context detail information.
    error::ContextLostReason context_lost_reason;

    // Generation index of this state. The generation index is incremented every
    // time a new state is retrieved from the command processor, so that
    // consistency can be kept even if IPC messages are processed out-of-order.
    uint32 generation;
  };

  struct ConsoleMessage {
    // An user supplied id.
    int32 id;
    // The message.
    std::string message;
  };

  CommandBuffer() {
  }

  virtual ~CommandBuffer() {
  }

  // Check if a value is between a start and end value, inclusive, allowing
  // for wrapping if start > end.
  static bool InRange(int32 start, int32 end, int32 value) {
    if (start <= end)
      return start <= value && value <= end;
    else
      return start <= value || value <= end;
  }

  // Initialize the command buffer with the given size.
  virtual bool Initialize() = 0;

  // Returns the last state without synchronizing with the service.
  virtual State GetLastState() = 0;

  // Returns the last token without synchronizing with the service. Note that
  // while you could just call GetLastState().token, GetLastState needs to be
  // fast as it is called for every command where GetLastToken is only called
  // by code that needs to know the last token so it can be slower but more up
  // to date than GetLastState.
  virtual int32 GetLastToken() = 0;

  // The writer calls this to update its put offset. This ensures the reader
  // sees the latest added commands, and will eventually process them. On the
  // service side, commands are processed up to the given put_offset before
  // subsequent Flushes on the same GpuChannel.
  virtual void Flush(int32 put_offset) = 0;

  // As Flush, ensures that on the service side, commands up to put_offset
  // are processed but before subsequent commands on the same GpuChannel but
  // flushing to the service may be deferred.
  virtual void OrderingBarrier(int32 put_offset) = 0;

  // The writer calls this to wait until the current token is within a
  // specific range, inclusive. Can return early if an error is generated.
  virtual void WaitForTokenInRange(int32 start, int32 end) = 0;

  // The writer calls this to wait until the current get offset is within a
  // specific range, inclusive. Can return early if an error is generated.
  virtual void WaitForGetOffsetInRange(int32 start, int32 end) = 0;

  // Sets the buffer commands are read from.
  // Also resets the get and put offsets to 0.
  virtual void SetGetBuffer(int32 transfer_buffer_id) = 0;

  // Create a transfer buffer of the given size. Returns its ID or -1 on
  // error.
  virtual scoped_refptr<gpu::Buffer> CreateTransferBuffer(size_t size,
                                                          int32* id) = 0;

  // Destroy a transfer buffer. The ID must be positive.
  virtual void DestroyTransferBuffer(int32 id) = 0;

// The NaCl Win64 build only really needs the struct definitions above; having
// GetLastError declared would mean we'd have to also define it, and pull more
// of gpu in to the NaCl Win64 build.
#if !defined(NACL_WIN64)
  // TODO(apatrick): this is a temporary optimization while skia is calling
  // RendererGLContext::MakeCurrent prior to every GL call. It saves returning 6
  // ints redundantly when only the error is needed for the CommandBufferProxy
  // implementation.
  virtual error::Error GetLastError();
#endif

 private:
  DISALLOW_COPY_AND_ASSIGN(CommandBuffer);
};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_COMMAND_BUFFER_H_
