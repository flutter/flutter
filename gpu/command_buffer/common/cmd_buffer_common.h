// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file contains the common parts of command buffer formats.

#ifndef GPU_COMMAND_BUFFER_COMMON_CMD_BUFFER_COMMON_H_
#define GPU_COMMAND_BUFFER_COMMON_CMD_BUFFER_COMMON_H_

#include <stddef.h>
#include <stdint.h>

#include "base/logging.h"
#include "base/macros.h"
#include "gpu/command_buffer/common/bitfield_helpers.h"
#include "gpu/gpu_export.h"

namespace gpu {

namespace cmd {
  enum ArgFlags {
    kFixed = 0x0,
    kAtLeastN = 0x1
  };
}  // namespace cmd

// Pack & unpack Command cmd_flags
#define CMD_FLAG_SET_TRACE_LEVEL(level)     ((level & 3) << 0)
#define CMD_FLAG_GET_TRACE_LEVEL(cmd_flags) ((cmd_flags >> 0) & 3)

// Computes the number of command buffer entries needed for a certain size. In
// other words it rounds up to a multiple of entries.
inline uint32_t ComputeNumEntries(size_t size_in_bytes) {
  return static_cast<uint32_t>(
      (size_in_bytes + sizeof(uint32_t) - 1) / sizeof(uint32_t));  // NOLINT
}

// Rounds up to a multiple of entries in bytes.
inline size_t RoundSizeToMultipleOfEntries(size_t size_in_bytes) {
  return ComputeNumEntries(size_in_bytes) * sizeof(uint32_t);  // NOLINT
}

// Struct that defines the command header in the command buffer.
struct CommandHeader {
  uint32_t size:21;
  uint32_t command:11;

  GPU_EXPORT static const int32_t kMaxSize = (1 << 21) - 1;

  void Init(uint32_t _command, int32_t _size) {
    DCHECK_LE(_size, kMaxSize);
    command = _command;
    size = _size;
  }

  // Sets the header based on the passed in command. Can not be used for
  // variable sized commands like immediate commands or Noop.
  template <typename T>
  void SetCmd() {
    static_assert(T::kArgFlags == cmd::kFixed,
                  "T::kArgFlags should equal cmd::kFixed");
    Init(T::kCmdId, ComputeNumEntries(sizeof(T)));  // NOLINT
  }

  // Sets the header by a size in bytes of the immediate data after the command.
  template <typename T>
  void SetCmdBySize(uint32_t size_of_data_in_bytes) {
    static_assert(T::kArgFlags == cmd::kAtLeastN,
                  "T::kArgFlags should equal cmd::kAtLeastN");
    Init(T::kCmdId,
         ComputeNumEntries(sizeof(T) + size_of_data_in_bytes));  // NOLINT
  }

  // Sets the header by a size in bytes.
  template <typename T>
  void SetCmdByTotalSize(uint32_t size_in_bytes) {
    static_assert(T::kArgFlags == cmd::kAtLeastN,
                  "T::kArgFlags should equal cmd::kAtLeastN");
    DCHECK_GE(size_in_bytes, sizeof(T));  // NOLINT
    Init(T::kCmdId, ComputeNumEntries(size_in_bytes));
  }
};

static_assert(sizeof(CommandHeader) == 4,
              "size of CommandHeader should equal 4");

// Union that defines possible command buffer entries.
union CommandBufferEntry {
  CommandHeader value_header;
  uint32_t value_uint32;
  int32_t value_int32;
  float value_float;
};

#define GPU_COMMAND_BUFFER_ENTRY_ALIGNMENT 4
const size_t kCommandBufferEntrySize = GPU_COMMAND_BUFFER_ENTRY_ALIGNMENT;

static_assert(sizeof(CommandBufferEntry) == kCommandBufferEntrySize,
              "size of CommandBufferEntry should equal "
              "kCommandBufferEntrySize");

// Command buffer is GPU_COMMAND_BUFFER_ENTRY_ALIGNMENT byte aligned.
#pragma pack(push, GPU_COMMAND_BUFFER_ENTRY_ALIGNMENT)

// Gets the address of memory just after a structure in a typesafe way. This is
// used for IMMEDIATE commands to get the address of the place to put the data.
// Immediate command put their data direclty in the command buffer.
// Parameters:
//   cmd: Address of command.
template <typename T>
void* ImmediateDataAddress(T* cmd) {
  static_assert(T::kArgFlags == cmd::kAtLeastN,
                "T::kArgFlags should equal cmd::kAtLeastN");
  return reinterpret_cast<char*>(cmd) + sizeof(*cmd);
}

// Gets the address of the place to put the next command in a typesafe way.
// This can only be used for fixed sized commands.
template <typename T>
// Parameters:
//   cmd: Address of command.
void* NextCmdAddress(void* cmd) {
  static_assert(T::kArgFlags == cmd::kFixed,
                "T::kArgFlags should equal cmd::kFixed");
  return reinterpret_cast<char*>(cmd) + sizeof(T);
}

// Gets the address of the place to put the next command in a typesafe way.
// This can only be used for variable sized command like IMMEDIATE commands.
// Parameters:
//   cmd: Address of command.
//   size_of_data_in_bytes: Size of the data for the command.
template <typename T>
void* NextImmediateCmdAddress(void* cmd, uint32_t size_of_data_in_bytes) {
  static_assert(T::kArgFlags == cmd::kAtLeastN,
                "T::kArgFlags should equal cmd::kAtLeastN");
  return reinterpret_cast<char*>(cmd) + sizeof(T) +   // NOLINT
      RoundSizeToMultipleOfEntries(size_of_data_in_bytes);
}

// Gets the address of the place to put the next command in a typesafe way.
// This can only be used for variable sized command like IMMEDIATE commands.
// Parameters:
//   cmd: Address of command.
//   size_of_cmd_in_bytes: Size of the cmd and data.
template <typename T>
void* NextImmediateCmdAddressTotalSize(void* cmd,
                                       uint32_t total_size_in_bytes) {
  static_assert(T::kArgFlags == cmd::kAtLeastN,
                "T::kArgFlags should equal cmd::kAtLeastN");
  DCHECK_GE(total_size_in_bytes, sizeof(T));  // NOLINT
  return reinterpret_cast<char*>(cmd) +
      RoundSizeToMultipleOfEntries(total_size_in_bytes);
}

namespace cmd {

// This macro is used to safely and convienently expand the list of commnad
// buffer commands in to various lists and never have them get out of sync. To
// add a new command, add it this list, create the corresponding structure below
// and then add a function in gapi_decoder.cc called Handle_COMMAND_NAME where
// COMMAND_NAME is the name of your command structure.
//
// NOTE: THE ORDER OF THESE MUST NOT CHANGE (their id is derived by order)
#define COMMON_COMMAND_BUFFER_CMDS(OP) \
  OP(Noop)                          /*  0 */ \
  OP(SetToken)                      /*  1 */ \
  OP(SetBucketSize)                 /*  2 */ \
  OP(SetBucketData)                 /*  3 */ \
  OP(SetBucketDataImmediate)        /*  4 */ \
  OP(GetBucketStart)                /*  5 */ \
  OP(GetBucketData)                 /*  6 */ \

// Common commands.
enum CommandId {
  #define COMMON_COMMAND_BUFFER_CMD_OP(name) k ## name,

  COMMON_COMMAND_BUFFER_CMDS(COMMON_COMMAND_BUFFER_CMD_OP)

  #undef COMMON_COMMAND_BUFFER_CMD_OP

  kNumCommands,
  kLastCommonId = 255  // reserve 256 spaces for common commands.
};

static_assert(kNumCommands - 1 <= kLastCommonId, "too many commands");

const char* GetCommandName(CommandId id);

// A Noop command.
struct Noop {
  typedef Noop ValueType;
  static const CommandId kCmdId = kNoop;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  void SetHeader(uint32_t skip_count) {
    DCHECK_GT(skip_count, 0u);
    header.Init(kCmdId, skip_count);
  }

  void Init(uint32_t skip_count) {
    SetHeader(skip_count);
  }

  static void* Set(void* cmd, uint32_t skip_count) {
    static_cast<ValueType*>(cmd)->Init(skip_count);
    return NextImmediateCmdAddress<ValueType>(
        cmd, skip_count * sizeof(CommandBufferEntry));  // NOLINT
  }

  CommandHeader header;
};

static_assert(sizeof(Noop) == 4, "size of Noop should equal 4");
static_assert(offsetof(Noop, header) == 0,
              "offset of Noop.header should equal 0");

// The SetToken command puts a token in the command stream that you can
// use to check if that token has been passed in the command stream.
struct SetToken {
  typedef SetToken ValueType;
  static const CommandId kCmdId = kSetToken;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  void SetHeader() {
    header.SetCmd<ValueType>();
  }

  void Init(uint32_t _token) {
    SetHeader();
    token = _token;
  }
  static void* Set(void* cmd, uint32_t token) {
    static_cast<ValueType*>(cmd)->Init(token);
    return NextCmdAddress<ValueType>(cmd);
  }

  CommandHeader header;
  uint32_t token;
};

static_assert(sizeof(SetToken) == 8, "size of SetToken should equal 8");
static_assert(offsetof(SetToken, header) == 0,
              "offset of SetToken.header should equal 0");
static_assert(offsetof(SetToken, token) == 4,
              "offset of SetToken.token should equal 4");

// Sets the size of a bucket for collecting data on the service side.
// This is a utility for gathering data on the service side so it can be used
// all at once when some service side API is called. It removes the need to add
// special commands just to support a particular API. For example, any API
// command that needs a string needs a way to send that string to the API over
// the command buffers. While you can require that the command buffer or
// transfer buffer be large enough to hold the largest string you can send,
// using this command removes that restriction by letting you send smaller
// pieces over and build up the data on the service side.
//
// You can clear a bucket on the service side and thereby free memory by sending
// a size of 0.
struct SetBucketSize {
  typedef SetBucketSize ValueType;
  static const CommandId kCmdId = kSetBucketSize;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  void SetHeader() {
    header.SetCmd<ValueType>();
  }

  void Init(uint32_t _bucket_id, uint32_t _size) {
    SetHeader();
    bucket_id = _bucket_id;
    size = _size;
  }
  static void* Set(void* cmd, uint32_t _bucket_id, uint32_t _size) {
    static_cast<ValueType*>(cmd)->Init(_bucket_id, _size);
    return NextCmdAddress<ValueType>(cmd);
  }

  CommandHeader header;
  uint32_t bucket_id;
  uint32_t size;
};

static_assert(sizeof(SetBucketSize) == 12,
              "size of SetBucketSize should equal 12");
static_assert(offsetof(SetBucketSize, header) == 0,
              "offset of SetBucketSize.header should equal 0");
static_assert(offsetof(SetBucketSize, bucket_id) == 4,
              "offset of SetBucketSize.bucket_id should equal 4");
static_assert(offsetof(SetBucketSize, size) == 8,
              "offset of SetBucketSize.size should equal 8");

// Sets the contents of a portion of a bucket on the service side from data in
// shared memory.
// See SetBucketSize.
struct SetBucketData {
  typedef SetBucketData ValueType;
  static const CommandId kCmdId = kSetBucketData;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  void SetHeader() {
    header.SetCmd<ValueType>();
  }

  void Init(uint32_t _bucket_id,
            uint32_t _offset,
            uint32_t _size,
            uint32_t _shared_memory_id,
            uint32_t _shared_memory_offset) {
    SetHeader();
    bucket_id = _bucket_id;
    offset = _offset;
    size = _size;
    shared_memory_id = _shared_memory_id;
    shared_memory_offset = _shared_memory_offset;
  }
  static void* Set(void* cmd,
                   uint32_t _bucket_id,
                   uint32_t _offset,
                   uint32_t _size,
                   uint32_t _shared_memory_id,
                   uint32_t _shared_memory_offset) {
    static_cast<ValueType*>(cmd)->Init(
        _bucket_id,
        _offset,
        _size,
        _shared_memory_id,
        _shared_memory_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  CommandHeader header;
  uint32_t bucket_id;
  uint32_t offset;
  uint32_t size;
  uint32_t shared_memory_id;
  uint32_t shared_memory_offset;
};

static_assert(sizeof(SetBucketData) == 24,
              "size of SetBucketData should be 24");
static_assert(offsetof(SetBucketData, header) == 0,
              "offset of SetBucketData.header should be 0");
static_assert(offsetof(SetBucketData, bucket_id) == 4,
              "offset of SetBucketData.bucket_id should be 4");
static_assert(offsetof(SetBucketData, offset) == 8,
              "offset of SetBucketData.offset should be 8");
static_assert(offsetof(SetBucketData, size) == 12,
              "offset of SetBucketData.size should be 12");
static_assert(offsetof(SetBucketData, shared_memory_id) == 16,
              "offset of SetBucketData.shared_memory_id should be 16");
static_assert(offsetof(SetBucketData, shared_memory_offset) == 20,
              "offset of SetBucketData.shared_memory_offset should be 20");

// Sets the contents of a portion of a bucket on the service side from data in
// the command buffer.
// See SetBucketSize.
struct SetBucketDataImmediate {
  typedef SetBucketDataImmediate ValueType;
  static const CommandId kCmdId = kSetBucketDataImmediate;
  static const cmd::ArgFlags kArgFlags = cmd::kAtLeastN;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  void SetHeader(uint32_t size) {
    header.SetCmdBySize<ValueType>(size);
  }

  void Init(uint32_t _bucket_id,
            uint32_t _offset,
            uint32_t _size) {
    SetHeader(_size);
    bucket_id = _bucket_id;
    offset = _offset;
    size = _size;
  }
  static void* Set(void* cmd,
                   uint32_t _bucket_id,
                   uint32_t _offset,
                   uint32_t _size) {
    static_cast<ValueType*>(cmd)->Init(
        _bucket_id,
        _offset,
        _size);
    return NextImmediateCmdAddress<ValueType>(cmd, _size);
  }

  CommandHeader header;
  uint32_t bucket_id;
  uint32_t offset;
  uint32_t size;
};

static_assert(sizeof(SetBucketDataImmediate) == 16,
              "size of SetBucketDataImmediate should be 16");
static_assert(offsetof(SetBucketDataImmediate, header) == 0,
              "offset of SetBucketDataImmediate.header should be 0");
static_assert(offsetof(SetBucketDataImmediate, bucket_id) == 4,
              "offset of SetBucketDataImmediate.bucket_id should be 4");
static_assert(offsetof(SetBucketDataImmediate, offset) == 8,
              "offset of SetBucketDataImmediate.offset should be 8");
static_assert(offsetof(SetBucketDataImmediate, size) == 12,
              "offset of SetBucketDataImmediate.size should be 12");

// Gets the start of a bucket the service has available. Sending a variable size
// result back to the client and the portion of that result that fits in the
// supplied shared memory. If the size of the result is larger than the supplied
// shared memory the rest of the bucket's contents can be retrieved with
// GetBucketData.
//
// This is used for example for any API that returns a string. The problem is
// the largest thing you can send back in 1 command is the size of your shared
// memory. This command along with GetBucketData implements a way to get a
// result a piece at a time to help solve that problem in a generic way.
struct GetBucketStart {
  typedef GetBucketStart ValueType;
  static const CommandId kCmdId = kGetBucketStart;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  typedef uint32_t Result;

  void SetHeader() {
    header.SetCmd<ValueType>();
  }

  void Init(uint32_t _bucket_id,
            uint32_t _result_memory_id,
            uint32_t _result_memory_offset,
            uint32_t _data_memory_size,
            uint32_t _data_memory_id,
            uint32_t _data_memory_offset) {
    SetHeader();
    bucket_id = _bucket_id;
    result_memory_id = _result_memory_id;
    result_memory_offset = _result_memory_offset;
    data_memory_size = _data_memory_size;
    data_memory_id = _data_memory_id;
    data_memory_offset = _data_memory_offset;
  }
  static void* Set(void* cmd,
                   uint32_t _bucket_id,
                   uint32_t _result_memory_id,
                   uint32_t _result_memory_offset,
                   uint32_t _data_memory_size,
                   uint32_t _data_memory_id,
                   uint32_t _data_memory_offset) {
    static_cast<ValueType*>(cmd)->Init(
        _bucket_id,
        _result_memory_id,
        _result_memory_offset,
        _data_memory_size,
        _data_memory_id,
        _data_memory_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  CommandHeader header;
  uint32_t bucket_id;
  uint32_t result_memory_id;
  uint32_t result_memory_offset;
  uint32_t data_memory_size;
  uint32_t data_memory_id;
  uint32_t data_memory_offset;
};

static_assert(sizeof(GetBucketStart) == 28,
              "size of GetBucketStart should be 28");
static_assert(offsetof(GetBucketStart, header) == 0,
              "offset of GetBucketStart.header should be 0");
static_assert(offsetof(GetBucketStart, bucket_id) == 4,
              "offset of GetBucketStart.bucket_id should be 4");
static_assert(offsetof(GetBucketStart, result_memory_id) == 8,
              "offset of GetBucketStart.result_memory_id should be 8");
static_assert(offsetof(GetBucketStart, result_memory_offset) == 12,
              "offset of GetBucketStart.result_memory_offset should be 12");
static_assert(offsetof(GetBucketStart, data_memory_size) == 16,
              "offset of GetBucketStart.data_memory_size should be 16");
static_assert(offsetof(GetBucketStart, data_memory_id) == 20,
              "offset of GetBucketStart.data_memory_id should be 20");
static_assert(offsetof(GetBucketStart, data_memory_offset) == 24,
              "offset of GetBucketStart.data_memory_offset should be 24");

// Gets a piece of a result the service as available.
// See GetBucketSize.
struct GetBucketData {
  typedef GetBucketData ValueType;
  static const CommandId kCmdId = kGetBucketData;
  static const cmd::ArgFlags kArgFlags = cmd::kFixed;
  static const uint8_t cmd_flags = CMD_FLAG_SET_TRACE_LEVEL(3);

  void SetHeader() {
    header.SetCmd<ValueType>();
  }

  void Init(uint32_t _bucket_id,
            uint32_t _offset,
            uint32_t _size,
            uint32_t _shared_memory_id,
            uint32_t _shared_memory_offset) {
    SetHeader();
    bucket_id = _bucket_id;
    offset = _offset;
    size = _size;
    shared_memory_id = _shared_memory_id;
    shared_memory_offset = _shared_memory_offset;
  }
  static void* Set(void* cmd,
                   uint32_t _bucket_id,
                   uint32_t _offset,
                   uint32_t _size,
                   uint32_t _shared_memory_id,
                   uint32_t _shared_memory_offset) {
    static_cast<ValueType*>(cmd)->Init(
        _bucket_id,
        _offset,
        _size,
        _shared_memory_id,
        _shared_memory_offset);
    return NextCmdAddress<ValueType>(cmd);
  }

  CommandHeader header;
  uint32_t bucket_id;
  uint32_t offset;
  uint32_t size;
  uint32_t shared_memory_id;
  uint32_t shared_memory_offset;
};

static_assert(sizeof(GetBucketData) == 24,
              "size of GetBucketData should be 24");
static_assert(offsetof(GetBucketData, header) == 0,
              "offset of GetBucketData.header should be 0");
static_assert(offsetof(GetBucketData, bucket_id) == 4,
              "offset of GetBucketData.bucket_id should be 4");
static_assert(offsetof(GetBucketData, offset) == 8,
              "offset of GetBucketData.offset should be 8");
static_assert(offsetof(GetBucketData, size) == 12,
              "offset of GetBucketData.size should be 12");
static_assert(offsetof(GetBucketData, shared_memory_id) == 16,
              "offset of GetBucketData.shared_memory_id should be 16");
static_assert(offsetof(GetBucketData, shared_memory_offset) == 20,
              "offset of GetBucketData.shared_memory_offset should be 20");

}  // namespace cmd

#pragma pack(pop)

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_COMMON_CMD_BUFFER_COMMON_H_

