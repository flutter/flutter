// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the implementation of the command parser.

#include "gpu/command_buffer/service/cmd_parser.h"

#include "base/logging.h"
#include "base/trace_event/trace_event.h"

namespace gpu {

CommandParser::CommandParser(AsyncAPIInterface* handler)
    : get_(0),
      put_(0),
      buffer_(NULL),
      entry_count_(0),
      handler_(handler) {
}

void CommandParser::SetBuffer(
    void* shm_address,
    size_t shm_size,
    ptrdiff_t offset,
    size_t size) {
  // check proper alignments.
  DCHECK_EQ(0, (reinterpret_cast<intptr_t>(shm_address)) % 4);
  DCHECK_EQ(0, offset % 4);
  DCHECK_EQ(0u, size % 4);
  // check that the command buffer fits into the memory buffer.
  DCHECK_GE(shm_size, offset + size);
  get_ = 0;
  put_ = 0;
  char* buffer_begin = static_cast<char*>(shm_address) + offset;
  buffer_ = reinterpret_cast<CommandBufferEntry*>(buffer_begin);
  entry_count_ = size / 4;
}

// Process one command, reading the header from the command buffer, and
// forwarding the command index and the arguments to the handler.
// Note that:
// - validation needs to happen on a copy of the data (to avoid race
// conditions). This function only validates the header, leaving the arguments
// validation to the handler, so it can pass a reference to them.
// - get_ is modified *after* the command has been executed.
error::Error CommandParser::ProcessCommands(int num_commands) {
  int num_entries = put_ < get_ ? entry_count_ - get_ : put_ - get_;
  int entries_processed = 0;

  error::Error result = handler_->DoCommands(
      num_commands, buffer_ + get_, num_entries, &entries_processed);

  get_ += entries_processed;
  if (get_ == entry_count_)
    get_ = 0;

  return result;
}

// Processes all the commands, while the buffer is not empty. Stop if an error
// is encountered.
error::Error CommandParser::ProcessAllCommands() {
  while (!IsEmpty()) {
    error::Error error = ProcessCommands(kParseCommandsSlice);
    if (error)
      return error;
  }
  return error::kNoError;
}

// Decode multiple commands, and call the corresponding GL functions.
// NOTE: buffer is a pointer to the command buffer. As such, it could be
// changed by a (malicious) client at any time, so if validation has to happen,
// it should operate on a copy of them.
error::Error AsyncAPIInterface::DoCommands(unsigned int num_commands,
                                           const void* buffer,
                                           int num_entries,
                                           int* entries_processed) {
  int commands_to_process = num_commands;
  error::Error result = error::kNoError;
  const CommandBufferEntry* cmd_data =
      static_cast<const CommandBufferEntry*>(buffer);
  int process_pos = 0;

  while (process_pos < num_entries && result == error::kNoError &&
         commands_to_process--) {
    CommandHeader header = cmd_data->value_header;
    if (header.size == 0) {
      DVLOG(1) << "Error: zero sized command in command buffer";
      return error::kInvalidSize;
    }

    if (static_cast<int>(header.size) + process_pos > num_entries) {
      DVLOG(1) << "Error: get offset out of bounds";
      return error::kOutOfBounds;
    }

    const unsigned int command = header.command;
    const unsigned int arg_count = header.size - 1;

    result = DoCommand(command, arg_count, cmd_data);

    if (result != error::kDeferCommandUntilLater) {
      process_pos += header.size;
      cmd_data += header.size;
    }
  }

  if (entries_processed)
    *entries_processed = process_pos;

  return result;
}

}  // namespace gpu
