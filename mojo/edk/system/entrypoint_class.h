// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_ENTRYPOINT_CLASS_H_
#define MOJO_EDK_SYSTEM_ENTRYPOINT_CLASS_H_

namespace mojo {
namespace system {

// Classes of "entrypoints"/"syscalls": Each dispatcher should support entire
// classes of methods (and if they don't support a given class, they should
// return |MOJO_RESULT_INVALID_ARGUMENT| for all the methods in that class).
// Warning: A dispatcher method may be called even if the dispatcher's
// |SupportsEntrypointClass()| indicates that the method's class is not
// supported.
enum class EntrypointClass {
  // Not an entrypoint; all implementations of
  // |Dispatcher::SupportsEntrypointClass()| should return true for this:
  NONE,

  // |Dispatcher::ReadMessage()|, |Dispatcher::WriteMessage()|:
  MESSAGE_PIPE,

  // |Dispatcher::SetDataPipeProducerOptions()|,
  // |Dispatcher::GetDataPipeProducerOptions()|,
  // |Dispatcher::WriteData()|, |Dispatcher::BeginWriteData()|,
  // |Dispatcher::EndWriteData()|:
  DATA_PIPE_PRODUCER,

  // |Dispatcher::SetDataPipeConsumerOptions()|,
  // |Dispatcher::GetDataPipeConsumerOptions()|, |Dispatcher::ReadData()|,
  // |Dispatcher::BeginReadData()|, |Dispatcher::EndReadData()|:
  DATA_PIPE_CONSUMER,

  // |Dispatcher::DuplicateBufferHandle()|,
  // |Dispatcher::GetBufferInformation()|, |Dispatcher::MapBuffer()|:
  BUFFER,
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_ENTRYPOINT_CLASS_H_
