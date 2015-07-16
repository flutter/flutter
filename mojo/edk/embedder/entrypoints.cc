// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/embedder_internal.h"
#include "mojo/edk/system/core.h"
#include "mojo/public/c/system/buffer.h"
#include "mojo/public/c/system/data_pipe.h"
#include "mojo/public/c/system/functions.h"
#include "mojo/public/c/system/message_pipe.h"

using mojo::embedder::internal::g_core;
using mojo::system::MakeUserPointer;

// Definitions of the system functions.
extern "C" {
MojoTimeTicks MojoGetTimeTicksNow() {
  return g_core->GetTimeTicksNow();
}

MojoResult MojoClose(MojoHandle handle) {
  return g_core->Close(handle);
}

MojoResult MojoWait(MojoHandle handle,
                       MojoHandleSignals signals,
                       MojoDeadline deadline,
                       MojoHandleSignalsState* signals_state) {
  return g_core->Wait(handle, signals, deadline,
                      MakeUserPointer(signals_state));
}

MojoResult MojoWaitMany(const MojoHandle* handles,
                        const MojoHandleSignals* signals,
                        uint32_t num_handles,
                        MojoDeadline deadline,
                        uint32_t* result_index,
                        MojoHandleSignalsState* signals_states) {
  return g_core->WaitMany(MakeUserPointer(handles), MakeUserPointer(signals),
                          num_handles, deadline, MakeUserPointer(result_index),
                          MakeUserPointer(signals_states));
}

MojoResult MojoCreateMessagePipe(const MojoCreateMessagePipeOptions* options,
                                 MojoHandle* message_pipe_handle0,
                                 MojoHandle* message_pipe_handle1) {
  return g_core->CreateMessagePipe(MakeUserPointer(options),
                                   MakeUserPointer(message_pipe_handle0),
                                   MakeUserPointer(message_pipe_handle1));
}

MojoResult MojoWriteMessage(MojoHandle message_pipe_handle,
                            const void* bytes,
                            uint32_t num_bytes,
                            const MojoHandle* handles,
                            uint32_t num_handles,
                            MojoWriteMessageFlags flags) {
  return g_core->WriteMessage(message_pipe_handle, MakeUserPointer(bytes),
                              num_bytes, MakeUserPointer(handles), num_handles,
                              flags);
}

MojoResult MojoReadMessage(MojoHandle message_pipe_handle,
                           void* bytes,
                           uint32_t* num_bytes,
                           MojoHandle* handles,
                           uint32_t* num_handles,
                           MojoReadMessageFlags flags) {
  return g_core->ReadMessage(
      message_pipe_handle, MakeUserPointer(bytes), MakeUserPointer(num_bytes),
      MakeUserPointer(handles), MakeUserPointer(num_handles), flags);
}

MojoResult MojoCreateDataPipe(const MojoCreateDataPipeOptions* options,
                              MojoHandle* data_pipe_producer_handle,
                              MojoHandle* data_pipe_consumer_handle) {
  return g_core->CreateDataPipe(MakeUserPointer(options),
                                MakeUserPointer(data_pipe_producer_handle),
                                MakeUserPointer(data_pipe_consumer_handle));
}

MojoResult MojoWriteData(MojoHandle data_pipe_producer_handle,
                         const void* elements,
                         uint32_t* num_elements,
                         MojoWriteDataFlags flags) {
  return g_core->WriteData(data_pipe_producer_handle, MakeUserPointer(elements),
                           MakeUserPointer(num_elements), flags);
}

MojoResult MojoBeginWriteData(MojoHandle data_pipe_producer_handle,
                              void** buffer,
                              uint32_t* buffer_num_elements,
                              MojoWriteDataFlags flags) {
  return g_core->BeginWriteData(data_pipe_producer_handle,
                                MakeUserPointer(buffer),
                                MakeUserPointer(buffer_num_elements), flags);
}

MojoResult MojoEndWriteData(MojoHandle data_pipe_producer_handle,
                            uint32_t num_elements_written) {
  return g_core->EndWriteData(data_pipe_producer_handle, num_elements_written);
}

MojoResult MojoReadData(MojoHandle data_pipe_consumer_handle,
                        void* elements,
                        uint32_t* num_elements,
                        MojoReadDataFlags flags) {
  return g_core->ReadData(data_pipe_consumer_handle, MakeUserPointer(elements),
                          MakeUserPointer(num_elements), flags);
}

MojoResult MojoBeginReadData(MojoHandle data_pipe_consumer_handle,
                             const void** buffer,
                             uint32_t* buffer_num_elements,
                             MojoReadDataFlags flags) {
  return g_core->BeginReadData(data_pipe_consumer_handle,
                               MakeUserPointer(buffer),
                               MakeUserPointer(buffer_num_elements), flags);
}

MojoResult MojoEndReadData(MojoHandle data_pipe_consumer_handle,
                           uint32_t num_elements_read) {
  return g_core->EndReadData(data_pipe_consumer_handle, num_elements_read);
}

MojoResult MojoCreateSharedBuffer(
    const struct MojoCreateSharedBufferOptions* options,
    uint64_t num_bytes,
    MojoHandle* shared_buffer_handle) {
  return g_core->CreateSharedBuffer(MakeUserPointer(options), num_bytes,
                                    MakeUserPointer(shared_buffer_handle));
}

MojoResult MojoDuplicateBufferHandle(
    MojoHandle buffer_handle,
    const struct MojoDuplicateBufferHandleOptions* options,
    MojoHandle* new_buffer_handle) {
  return g_core->DuplicateBufferHandle(buffer_handle, MakeUserPointer(options),
                                       MakeUserPointer(new_buffer_handle));
}

MojoResult MojoMapBuffer(MojoHandle buffer_handle,
                         uint64_t offset,
                         uint64_t num_bytes,
                         void** buffer,
                         MojoMapBufferFlags flags) {
  return g_core->MapBuffer(buffer_handle, offset, num_bytes,
                           MakeUserPointer(buffer), flags);
}

MojoResult MojoUnmapBuffer(void* buffer) {
  return g_core->UnmapBuffer(MakeUserPointer(buffer));
}

}  // extern "C"
