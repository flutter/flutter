// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/data_pipe_utils/data_pipe_utils.h"

#include <stdio.h>

#include "base/message_loop/message_loop.h"
#include "base/task_runner_util.h"
#include "base/threading/platform_thread.h"
#include "base/trace_event/trace_event.h"
#include "mojo/data_pipe_utils/data_pipe_utils_internal.h"

namespace mojo {
namespace common {

bool BlockingCopyHelper(
    ScopedDataPipeConsumerHandle source,
    const base::Callback<size_t(const void*, uint32_t)>& write_bytes) {
  for (;;) {
    const void* buffer = nullptr;
    uint32_t num_bytes = 0;
    MojoResult result = BeginReadDataRaw(source.get(), &buffer, &num_bytes,
                                         MOJO_READ_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      size_t bytes_written = write_bytes.Run(buffer, num_bytes);
      if (bytes_written < num_bytes) {
        LOG(ERROR) << "write_bytes callback wrote fewer bytes ("
                   << bytes_written << ") written than expected (" << num_bytes
                   << ") in BlockingCopyHelper (pipe closed? out of disk "
                      "space?)";
        // No need to call EndReadDataRaw(), since |source| will be closed.
        return false;
      }
      result = EndReadDataRaw(source.get(), num_bytes);
      if (result != MOJO_RESULT_OK) {
        LOG(ERROR) << "EndReadDataRaw error (" << result
                   << ") in BlockingCopyHelper";
        return false;
      }
    } else if (result == MOJO_RESULT_SHOULD_WAIT) {
      result = Wait(source.get(), MOJO_HANDLE_SIGNAL_READABLE,
                    MOJO_DEADLINE_INDEFINITE, nullptr);
      if (result != MOJO_RESULT_OK) {
        // If the producer handle was closed, then treat as EOF.
        return result == MOJO_RESULT_FAILED_PRECONDITION;
      }
    } else if (result == MOJO_RESULT_FAILED_PRECONDITION) {
      // If the producer handle was closed, then treat as EOF.
      return true;
    } else {
      LOG(ERROR) << "Unhandled error " << result << " in BlockingCopyHelper";
      // Some other error occurred.
      return false;
    }
  }
}

namespace {

size_t CopyToStringHelper(std::string* result,
                          const void* buffer,
                          uint32_t num_bytes) {
  result->append(static_cast<const char*>(buffer), num_bytes);
  return num_bytes;
}

}  // namespace

// TODO(hansmuller): Add a max_size parameter.
bool BlockingCopyToString(ScopedDataPipeConsumerHandle source,
                          std::string* result) {
  TRACE_EVENT0("data_pipe_utils", "BlockingCopyToString");
  CHECK(result);
  result->clear();
  return BlockingCopyHelper(source.Pass(),
                            base::Bind(&CopyToStringHelper, result));
}

bool BlockingCopyFromString(const std::string& source,
                            const ScopedDataPipeProducerHandle& destination) {
  TRACE_EVENT0("data_pipe_utils", "BlockingCopyFromString");
  auto it = source.begin();
  for (;;) {
    void* buffer = nullptr;
    uint32_t buffer_num_bytes = 0;
    MojoResult result =
        BeginWriteDataRaw(destination.get(), &buffer, &buffer_num_bytes,
                          MOJO_WRITE_DATA_FLAG_NONE);
    if (result == MOJO_RESULT_OK) {
      char* char_buffer = static_cast<char*>(buffer);
      uint32_t byte_index = 0;
      while (it != source.end() && byte_index < buffer_num_bytes) {
        char_buffer[byte_index++] = *it++;
      }
      EndWriteDataRaw(destination.get(), byte_index);
      if (it == source.end())
        return true;
    } else if (result == MOJO_RESULT_SHOULD_WAIT) {
      result = Wait(destination.get(), MOJO_HANDLE_SIGNAL_WRITABLE,
                    MOJO_DEADLINE_INDEFINITE, nullptr);
      if (result != MOJO_RESULT_OK) {
        // If the consumer handle was closed, then treat as EOF.
        return result == MOJO_RESULT_FAILED_PRECONDITION;
      }
    } else {
      // If the consumer handle was closed, then treat as EOF.
      return result == MOJO_RESULT_FAILED_PRECONDITION;
    }
  }
}

}  // namespace common
}  // namespace mojo
