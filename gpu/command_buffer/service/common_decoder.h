// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef GPU_COMMAND_BUFFER_SERVICE_COMMON_DECODER_H_
#define GPU_COMMAND_BUFFER_SERVICE_COMMON_DECODER_H_

#include <map>
#include <stack>
#include <string>
#include "base/memory/linked_ptr.h"
#include "base/memory/scoped_ptr.h"
#include "gpu/command_buffer/common/buffer.h"
#include "gpu/command_buffer/service/cmd_parser.h"
#include "gpu/gpu_export.h"

// Forwardly declare a few GL types to avoid including GL header files.
typedef int GLsizei;
typedef int GLint;

namespace gpu {

class CommandBufferEngine;

// This class is a helper base class for implementing the common parts of the
// o3d/gl2 command buffer decoder.
class GPU_EXPORT CommonDecoder : NON_EXPORTED_BASE(public AsyncAPIInterface) {
 public:
  typedef error::Error Error;

  static const unsigned int kMaxStackDepth = 32;

  // A bucket is a buffer to help collect memory across a command buffer. When
  // creating a command buffer implementation of an existing API, sometimes that
  // API has functions that take a pointer to data.  A good example is OpenGL's
  // glBufferData. Because the data is separated between client and service,
  // there are 2 ways to get this data across. 1 is to put all the data in
  // shared memory. The problem with this is the data can be arbitarily large
  // and the host OS may not support that much shared memory. Another solution
  // is to shuffle memory across a little bit at a time, collecting it on the
  // service side and when it is all there then call glBufferData. Buckets
  // implement this second solution. Using the common commands, SetBucketSize,
  // SetBucketData, SetBucketDataImmediate the client can fill a bucket. It can
  // then call a command that uses that bucket (like BufferDataBucket in the
  // GLES2 command buffer implementation).
  //
  // If you are designing an API from scratch you can avoid this need for
  // Buckets by making your API always take an offset and a size
  // similar to glBufferSubData.
  //
  // Buckets also help pass strings to/from the service. To return a string of
  // arbitary size, the service puts the string in a bucket. The client can
  // then query the size of a bucket and request sections of the bucket to
  // be passed across shared memory.
  class GPU_EXPORT Bucket {
   public:
    Bucket();
    ~Bucket();

    size_t size() const {
      return size_;
    }

    // Gets a pointer to a section the bucket. Returns NULL if offset or size is
    // out of range.
    void* GetData(size_t offset, size_t size) const;

    template <typename T>
    T GetDataAs(size_t offset, size_t size) const {
      return reinterpret_cast<T>(GetData(offset, size));
    }

    // Sets the size of the bucket.
    void SetSize(size_t size);

    // Sets a part of the bucket.
    // Returns false if offset or size is out of range.
    bool SetData(const void* src, size_t offset, size_t size);

    // Sets the bucket data from a string. Strings are passed NULL terminated to
    // distinguish between empty string and no string.
    void SetFromString(const char* str);

    // Gets the bucket data as a string. Strings are passed NULL terminated to
    // distrinquish between empty string and no string. Returns False if there
    // is no string.
    bool GetAsString(std::string* str);

    // Gets the bucket data as strings.
    // On success, the number of strings are in |_count|, the string data are
    // in |_string|, and string sizes are in |_length|..
    bool GetAsStrings(GLsizei* _count,
                      std::vector<char*>* _string,
                      std::vector<GLint>* _length);

   private:
    bool OffsetSizeValid(size_t offset, size_t size) const {
      size_t temp = offset + size;
      return temp <= size_ && temp >= offset;
    }

    size_t size_;
    ::scoped_ptr<int8[]> data_;

    DISALLOW_COPY_AND_ASSIGN(Bucket);
  };

  CommonDecoder();
  ~CommonDecoder() override;

  // Sets the engine, to get shared memory buffers from, and to set the token
  // to.
  void set_engine(CommandBufferEngine* engine) {
    engine_ = engine;
  }
  CommandBufferEngine* engine() const { return engine_; }

  // Creates a bucket. If the bucket already exists returns that bucket.
  Bucket* CreateBucket(uint32 bucket_id);

  // Gets a bucket. Returns NULL if the bucket does not exist.
  Bucket* GetBucket(uint32 bucket_id) const;

  // Gets the address of shared memory data, given a shared memory ID and an
  // offset. Also checks that the size is consistent with the shared memory
  // size.
  // Parameters:
  //   shm_id: the id of the shared memory buffer.
  //   offset: the offset of the data in the shared memory buffer.
  //   size: the size of the data.
  // Returns:
  //   NULL if shm_id isn't a valid shared memory buffer ID or if the size
  //   check fails. Return a pointer to the data otherwise.
  void* GetAddressAndCheckSize(unsigned int shm_id,
                               unsigned int offset,
                               unsigned int size);

  // Typed version of GetAddressAndCheckSize.
  template <typename T>
  T GetSharedMemoryAs(unsigned int shm_id, unsigned int offset,
                      unsigned int size) {
    return static_cast<T>(GetAddressAndCheckSize(shm_id, offset, size));
  }

  // Get the actual shared memory buffer.
  scoped_refptr<gpu::Buffer> GetSharedMemoryBuffer(unsigned int shm_id);

 protected:
  // Executes a common command.
  // Parameters:
  //    command: the command index.
  //    arg_count: the number of CommandBufferEntry arguments.
  //    cmd_data: the command data.
  // Returns:
  //   error::kNoError if no error was found, one of
  //   error::Error otherwise.
  error::Error DoCommonCommand(
      unsigned int command,
      unsigned int arg_count,
      const void* cmd_data);

  // Gets an name for a common command.
  const char* GetCommonCommandName(cmd::CommandId command_id) const;

 private:
  // Generate a member function prototype for each command in an automated and
  // typesafe way.
  #define COMMON_COMMAND_BUFFER_CMD_OP(name)             \
     error::Error Handle##name(uint32 immediate_data_size, const void* data);

  COMMON_COMMAND_BUFFER_CMDS(COMMON_COMMAND_BUFFER_CMD_OP)

  #undef COMMON_COMMAND_BUFFER_CMD_OP

  CommandBufferEngine* engine_;

  typedef std::map<uint32, linked_ptr<Bucket> > BucketMap;
  BucketMap buckets_;

  typedef Error (CommonDecoder::*CmdHandler)(
      uint32 immediate_data_size,
      const void* data);

  // A struct to hold info about each command.
  struct CommandInfo {
    CmdHandler cmd_handler;
    uint8 arg_flags;   // How to handle the arguments for this command
    uint8 cmd_flags;   // How to handle this command
    uint16 arg_count;  // How many arguments are expected for this command.
  };

  // A table of CommandInfo for all the commands.
  static const CommandInfo command_info[];

};

}  // namespace gpu

#endif  // GPU_COMMAND_BUFFER_SERVICE_COMMON_DECODER_H_

