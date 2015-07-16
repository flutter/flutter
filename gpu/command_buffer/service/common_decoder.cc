// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "gpu/command_buffer/service/common_decoder.h"

#include "base/numerics/safe_math.h"
#include "gpu/command_buffer/service/cmd_buffer_engine.h"

namespace gpu {

const CommonDecoder::CommandInfo CommonDecoder::command_info[] = {
#define COMMON_COMMAND_BUFFER_CMD_OP(name)                       \
  {                                                              \
    &CommonDecoder::Handle##name, cmd::name::kArgFlags,          \
        cmd::name::cmd_flags,                                    \
        sizeof(cmd::name) / sizeof(CommandBufferEntry) - 1,      \
  }                                                              \
  ,  /* NOLINT */
  COMMON_COMMAND_BUFFER_CMDS(COMMON_COMMAND_BUFFER_CMD_OP)
  #undef COMMON_COMMAND_BUFFER_CMD_OP
};


CommonDecoder::Bucket::Bucket() : size_(0) {}

CommonDecoder::Bucket::~Bucket() {}

void* CommonDecoder::Bucket::GetData(size_t offset, size_t size) const {
  if (OffsetSizeValid(offset, size)) {
    return data_.get() + offset;
  }
  return NULL;
}

void CommonDecoder::Bucket::SetSize(size_t size) {
  if (size != size_) {
    data_.reset(size ? new int8[size] : NULL);
    size_ = size;
    memset(data_.get(), 0, size);
  }
}

bool CommonDecoder::Bucket::SetData(
    const void* src, size_t offset, size_t size) {
  if (OffsetSizeValid(offset, size)) {
    memcpy(data_.get() + offset, src, size);
    return true;
  }
  return false;
}

void CommonDecoder::Bucket::SetFromString(const char* str) {
  // Strings are passed NULL terminated to distinguish between empty string
  // and no string.
  if (!str) {
    SetSize(0);
  } else {
    size_t size = strlen(str) + 1;
    SetSize(size);
    SetData(str, 0, size);
  }
}

bool CommonDecoder::Bucket::GetAsString(std::string* str) {
  DCHECK(str);
  if (size_ == 0) {
    return false;
  }
  str->assign(GetDataAs<const char*>(0, size_ - 1), size_ - 1);
  return true;
}

bool CommonDecoder::Bucket::GetAsStrings(
    GLsizei* _count, std::vector<char*>* _string, std::vector<GLint>* _length) {
  const size_t kMinBucketSize = sizeof(GLint);
  // Each string has at least |length| in the header and a NUL character.
  const size_t kMinStringSize = sizeof(GLint) + 1;
  const size_t bucket_size = this->size();
  if (bucket_size < kMinBucketSize) {
    return false;
  }
  char* bucket_data = this->GetDataAs<char*>(0, bucket_size);
  GLint* header = reinterpret_cast<GLint*>(bucket_data);
  GLsizei count = static_cast<GLsizei>(header[0]);
  if (count < 0) {
    return false;
  }
  const size_t max_count = (bucket_size - kMinBucketSize) / kMinStringSize;
  if (max_count < static_cast<size_t>(count)) {
    return false;
  }
  GLint* length = header + 1;
  std::vector<char*> strs(count);
  base::CheckedNumeric<size_t> total_size = sizeof(GLint);
  total_size *= count + 1;  // Header size.
  if (!total_size.IsValid())
    return false;
  for (GLsizei ii = 0; ii < count; ++ii) {
    strs[ii] = bucket_data + total_size.ValueOrDefault(0);
    total_size += length[ii];
    total_size += 1;  // NUL char at the end of each char array.
    if (!total_size.IsValid() || total_size.ValueOrDefault(0) > bucket_size ||
        strs[ii][length[ii]] != 0) {
      return false;
    }
  }
  if (total_size.ValueOrDefault(0) != bucket_size) {
    return false;
  }
  DCHECK(_count && _string && _length);
  *_count = count;
  *_string = strs;
  _length->resize(count);
  for (GLsizei ii = 0; ii < count; ++ii) {
    (*_length)[ii] = length[ii];
  }
  return true;
}

CommonDecoder::CommonDecoder() : engine_(NULL) {}

CommonDecoder::~CommonDecoder() {}

void* CommonDecoder::GetAddressAndCheckSize(unsigned int shm_id,
                                            unsigned int data_offset,
                                            unsigned int data_size) {
  CHECK(engine_);
  scoped_refptr<gpu::Buffer> buffer = engine_->GetSharedMemoryBuffer(shm_id);
  if (!buffer.get())
    return NULL;
  return buffer->GetDataAddress(data_offset, data_size);
}

scoped_refptr<gpu::Buffer> CommonDecoder::GetSharedMemoryBuffer(
    unsigned int shm_id) {
  return engine_->GetSharedMemoryBuffer(shm_id);
}

const char* CommonDecoder::GetCommonCommandName(
    cmd::CommandId command_id) const {
  return cmd::GetCommandName(command_id);
}

CommonDecoder::Bucket* CommonDecoder::GetBucket(uint32 bucket_id) const {
  BucketMap::const_iterator iter(buckets_.find(bucket_id));
  return iter != buckets_.end() ? &(*iter->second) : NULL;
}

CommonDecoder::Bucket* CommonDecoder::CreateBucket(uint32 bucket_id) {
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket) {
    bucket = new Bucket();
    buckets_[bucket_id] = linked_ptr<Bucket>(bucket);
  }
  return bucket;
}

namespace {

// Returns the address of the first byte after a struct.
template <typename T>
const void* AddressAfterStruct(const T& pod) {
  return reinterpret_cast<const uint8*>(&pod) + sizeof(pod);
}

// Returns the address of the frst byte after the struct.
template <typename RETURN_TYPE, typename COMMAND_TYPE>
RETURN_TYPE GetImmediateDataAs(const COMMAND_TYPE& pod) {
  return static_cast<RETURN_TYPE>(const_cast<void*>(AddressAfterStruct(pod)));
}

}  // anonymous namespace.

// Decode command with its arguments, and call the corresponding method.
// Note: args is a pointer to the command buffer. As such, it could be changed
// by a (malicious) client at any time, so if validation has to happen, it
// should operate on a copy of them.
error::Error CommonDecoder::DoCommonCommand(
    unsigned int command,
    unsigned int arg_count,
    const void* cmd_data) {
  if (command < arraysize(command_info)) {
    const CommandInfo& info = command_info[command];
    unsigned int info_arg_count = static_cast<unsigned int>(info.arg_count);
    if ((info.arg_flags == cmd::kFixed && arg_count == info_arg_count) ||
        (info.arg_flags == cmd::kAtLeastN && arg_count >= info_arg_count)) {
      uint32 immediate_data_size =
          (arg_count - info_arg_count) * sizeof(CommandBufferEntry);  // NOLINT
      return (this->*info.cmd_handler)(immediate_data_size, cmd_data);
    } else {
      return error::kInvalidArguments;
    }
  }
  return error::kUnknownCommand;
}

error::Error CommonDecoder::HandleNoop(
    uint32 immediate_data_size,
    const void* cmd_data) {
  return error::kNoError;
}

error::Error CommonDecoder::HandleSetToken(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const cmd::SetToken& args = *static_cast<const cmd::SetToken*>(cmd_data);
  engine_->set_token(args.token);
  return error::kNoError;
}

error::Error CommonDecoder::HandleSetBucketSize(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const cmd::SetBucketSize& args =
      *static_cast<const cmd::SetBucketSize*>(cmd_data);
  uint32 bucket_id = args.bucket_id;
  uint32 size = args.size;

  Bucket* bucket = CreateBucket(bucket_id);
  bucket->SetSize(size);
  return error::kNoError;
}

error::Error CommonDecoder::HandleSetBucketData(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const cmd::SetBucketData& args =
      *static_cast<const cmd::SetBucketData*>(cmd_data);
  uint32 bucket_id = args.bucket_id;
  uint32 offset = args.offset;
  uint32 size = args.size;
  const void* data = GetSharedMemoryAs<const void*>(
      args.shared_memory_id, args.shared_memory_offset, size);
  if (!data) {
    return error::kInvalidArguments;
  }
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  if (!bucket->SetData(data, offset, size)) {
    return error::kInvalidArguments;
  }

  return error::kNoError;
}

error::Error CommonDecoder::HandleSetBucketDataImmediate(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const cmd::SetBucketDataImmediate& args =
      *static_cast<const cmd::SetBucketDataImmediate*>(cmd_data);
  const void* data = GetImmediateDataAs<const void*>(args);
  uint32 bucket_id = args.bucket_id;
  uint32 offset = args.offset;
  uint32 size = args.size;
  if (size > immediate_data_size) {
    return error::kInvalidArguments;
  }
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  if (!bucket->SetData(data, offset, size)) {
    return error::kInvalidArguments;
  }
  return error::kNoError;
}

error::Error CommonDecoder::HandleGetBucketStart(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const cmd::GetBucketStart& args =
      *static_cast<const cmd::GetBucketStart*>(cmd_data);
  uint32 bucket_id = args.bucket_id;
  uint32* result = GetSharedMemoryAs<uint32*>(
      args.result_memory_id, args.result_memory_offset, sizeof(*result));
  int32 data_memory_id = args.data_memory_id;
  uint32 data_memory_offset = args.data_memory_offset;
  uint32 data_memory_size = args.data_memory_size;
  uint8* data = NULL;
  if (data_memory_size != 0 || data_memory_id != 0 || data_memory_offset != 0) {
    data = GetSharedMemoryAs<uint8*>(
        args.data_memory_id, args.data_memory_offset, args.data_memory_size);
    if (!data) {
      return error::kInvalidArguments;
    }
  }
  if (!result) {
    return error::kInvalidArguments;
  }
  // Check that the client initialized the result.
  if (*result != 0) {
    return error::kInvalidArguments;
  }
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  uint32 bucket_size = bucket->size();
  *result = bucket_size;
  if (data) {
    uint32 size = std::min(data_memory_size, bucket_size);
    memcpy(data, bucket->GetData(0, size), size);
  }
  return error::kNoError;
}

error::Error CommonDecoder::HandleGetBucketData(
    uint32 immediate_data_size,
    const void* cmd_data) {
  const cmd::GetBucketData& args =
      *static_cast<const cmd::GetBucketData*>(cmd_data);
  uint32 bucket_id = args.bucket_id;
  uint32 offset = args.offset;
  uint32 size = args.size;
  void* data = GetSharedMemoryAs<void*>(
      args.shared_memory_id, args.shared_memory_offset, size);
  if (!data) {
    return error::kInvalidArguments;
  }
  Bucket* bucket = GetBucket(bucket_id);
  if (!bucket) {
    return error::kInvalidArguments;
  }
  const void* src = bucket->GetData(offset, size);
  if (!src) {
      return error::kInvalidArguments;
  }
  memcpy(data, src, size);
  return error::kNoError;
}

}  // namespace gpu
