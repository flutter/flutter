// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides a C++ wrapping around the Mojo C API for message pipes,
// replacing the prefix of "Mojo" with a "mojo" namespace, and using more
// strongly-typed representations of |MojoHandle|s.
//
// Please see "mojo/public/c/system/message_pipe.h" for complete documentation
// of the API.

#ifndef MOJO_PUBLIC_CPP_SYSTEM_MESSAGE_PIPE_H_
#define MOJO_PUBLIC_CPP_SYSTEM_MESSAGE_PIPE_H_

#include <assert.h>

#include "mojo/public/c/system/message_pipe.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

// A strongly-typed representation of a |MojoHandle| to one end of a message
// pipe.
class MessagePipeHandle : public Handle {
 public:
  MessagePipeHandle() {}
  explicit MessagePipeHandle(MojoHandle value) : Handle(value) {}

  // Copying and assignment allowed.
};

static_assert(sizeof(MessagePipeHandle) == sizeof(Handle),
              "Bad size for C++ MessagePipeHandle");

typedef ScopedHandleBase<MessagePipeHandle> ScopedMessagePipeHandle;
static_assert(sizeof(ScopedMessagePipeHandle) == sizeof(MessagePipeHandle),
              "Bad size for C++ ScopedMessagePipeHandle");

// Creates a message pipe. See |MojoCreateMessagePipe()| for complete
// documentation.
inline MojoResult CreateMessagePipe(const MojoCreateMessagePipeOptions* options,
                                    ScopedMessagePipeHandle* message_pipe0,
                                    ScopedMessagePipeHandle* message_pipe1) {
  assert(message_pipe0);
  assert(message_pipe1);
  MessagePipeHandle handle0;
  MessagePipeHandle handle1;
  MojoResult rv = MojoCreateMessagePipe(
      options, handle0.mutable_value(), handle1.mutable_value());
  // Reset even on failure (reduces the chances that a "stale"/incorrect handle
  // will be used).
  message_pipe0->reset(handle0);
  message_pipe1->reset(handle1);
  return rv;
}

// The following "...Raw" versions fully expose the underlying API, and don't
// help with ownership of handles (especially when writing messages). It is
// expected that in most cases these methods will be called through generated
// bindings anyway.
// TODO(vtl): Write friendlier versions of these functions (using scoped
// handles and/or vectors) if there is a demonstrated need for them.

// Writes to a message pipe.  If handles are attached, on success the handles
// will no longer be valid (the receiver will receive equivalent, but logically
// different, handles). See |MojoWriteMessage()| for complete documentation.
inline MojoResult WriteMessageRaw(MessagePipeHandle message_pipe,
                                  const void* bytes,
                                  uint32_t num_bytes,
                                  const MojoHandle* handles,
                                  uint32_t num_handles,
                                  MojoWriteMessageFlags flags) {
  return MojoWriteMessage(
      message_pipe.value(), bytes, num_bytes, handles, num_handles, flags);
}

// Reads from a message pipe. See |MojoReadMessage()| for complete
// documentation.
inline MojoResult ReadMessageRaw(MessagePipeHandle message_pipe,
                                 void* bytes,
                                 uint32_t* num_bytes,
                                 MojoHandle* handles,
                                 uint32_t* num_handles,
                                 MojoReadMessageFlags flags) {
  return MojoReadMessage(
      message_pipe.value(), bytes, num_bytes, handles, num_handles, flags);
}

// A wrapper class that automatically creates a message pipe and owns both
// handles.
class MessagePipe {
 public:
  MessagePipe();
  explicit MessagePipe(const MojoCreateMessagePipeOptions& options);
  ~MessagePipe();

  ScopedMessagePipeHandle handle0;
  ScopedMessagePipeHandle handle1;
};

inline MessagePipe::MessagePipe() {
  MojoResult result = CreateMessagePipe(nullptr, &handle0, &handle1);
  MOJO_ALLOW_UNUSED_LOCAL(result);
  assert(result == MOJO_RESULT_OK);
}

inline MessagePipe::MessagePipe(const MojoCreateMessagePipeOptions& options) {
  MojoResult result = CreateMessagePipe(&options, &handle0, &handle1);
  MOJO_ALLOW_UNUSED_LOCAL(result);
  assert(result == MOJO_RESULT_OK);
}

inline MessagePipe::~MessagePipe() {
}

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_SYSTEM_MESSAGE_PIPE_H_
