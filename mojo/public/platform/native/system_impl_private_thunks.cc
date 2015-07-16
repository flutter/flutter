// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/platform/native/system_impl_private_thunks.h"

#include <assert.h>

#include "mojo/public/platform/native/thunk_export.h"

extern "C" {

static MojoSystemImplControlThunksPrivate g_system_impl_control_thunks = {0};
static MojoSystemImplThunksPrivate g_system_impl_thunks = {0};

MojoSystemImpl MojoSystemImplGetDefaultImpl() {
  assert(g_system_impl_control_thunks.GetDefaultSystemImpl);
  return g_system_impl_control_thunks.GetDefaultSystemImpl();
}

MojoSystemImpl MojoSystemImplCreateImpl() {
  assert(g_system_impl_control_thunks.CreateSystemImpl);
  return g_system_impl_control_thunks.CreateSystemImpl();
}

MojoResult MojoSystemImplTransferHandle(MojoSystemImpl from_system,
                                        MojoHandle handle,
                                        MojoSystemImpl to_system,
                                        MojoHandle* result_handle) {
  assert(g_system_impl_control_thunks.TransferHandle);
  return g_system_impl_control_thunks.TransferHandle(from_system, handle,
                                                     to_system, result_handle);
}

MojoTimeTicks MojoSystemImplGetTimeTicksNow(MojoSystemImpl system) {
  assert(g_system_impl_thunks.GetTimeTicksNow);
  return g_system_impl_thunks.GetTimeTicksNow(system);
}

MojoResult MojoSystemImplClose(MojoSystemImpl system, MojoHandle handle) {
  assert(g_system_impl_thunks.Close);
  return g_system_impl_thunks.Close(system, handle);
}

MojoResult MojoSystemImplWait(MojoSystemImpl system,
                              MojoHandle handle,
                              MojoHandleSignals signals,
                              MojoDeadline deadline,
                              struct MojoHandleSignalsState* signals_state) {
  assert(g_system_impl_thunks.Wait);
  return g_system_impl_thunks.Wait(system, handle, signals, deadline,
                                   signals_state);
}

MojoResult MojoSystemImplWaitMany(
    MojoSystemImpl system,
    const MojoHandle* handles,
    const MojoHandleSignals* signals,
    uint32_t num_handles,
    MojoDeadline deadline,
    uint32_t* result_index,
    struct MojoHandleSignalsState* signals_states) {
  assert(g_system_impl_thunks.WaitMany);
  return g_system_impl_thunks.WaitMany(system, handles, signals, num_handles,
                                       deadline, result_index, signals_states);
}

MojoResult MojoSystemImplCreateMessagePipe(
    MojoSystemImpl system,
    const struct MojoCreateMessagePipeOptions* options,
    MojoHandle* message_pipe_handle0,
    MojoHandle* message_pipe_handle1) {
  assert(g_system_impl_thunks.CreateMessagePipe);
  return g_system_impl_thunks.CreateMessagePipe(
      system, options, message_pipe_handle0, message_pipe_handle1);
}

MojoResult MojoSystemImplWriteMessage(MojoSystemImpl system,
                                      MojoHandle message_pipe_handle,
                                      const void* bytes,
                                      uint32_t num_bytes,
                                      const MojoHandle* handles,
                                      uint32_t num_handles,
                                      MojoWriteMessageFlags flags) {
  assert(g_system_impl_thunks.WriteMessage);
  return g_system_impl_thunks.WriteMessage(system, message_pipe_handle, bytes,
                                           num_bytes, handles, num_handles,
                                           flags);
}

MojoResult MojoSystemImplReadMessage(MojoSystemImpl system,
                                     MojoHandle message_pipe_handle,
                                     void* bytes,
                                     uint32_t* num_bytes,
                                     MojoHandle* handles,
                                     uint32_t* num_handles,
                                     MojoReadMessageFlags flags) {
  assert(g_system_impl_thunks.ReadMessage);
  return g_system_impl_thunks.ReadMessage(system, message_pipe_handle, bytes,
                                          num_bytes, handles, num_handles,
                                          flags);
}

MojoResult MojoSystemImplCreateDataPipe(
    MojoSystemImpl system,
    const struct MojoCreateDataPipeOptions* options,
    MojoHandle* data_pipe_producer_handle,
    MojoHandle* data_pipe_consumer_handle) {
  assert(g_system_impl_thunks.CreateDataPipe);
  return g_system_impl_thunks.CreateDataPipe(
      system, options, data_pipe_producer_handle, data_pipe_consumer_handle);
}

MojoResult MojoSystemImplWriteData(MojoSystemImpl system,
                                   MojoHandle data_pipe_producer_handle,
                                   const void* elements,
                                   uint32_t* num_elements,
                                   MojoWriteDataFlags flags) {
  assert(g_system_impl_thunks.WriteData);
  return g_system_impl_thunks.WriteData(system, data_pipe_producer_handle,
                                        elements, num_elements, flags);
}

MojoResult MojoSystemImplBeginWriteData(MojoSystemImpl system,
                                        MojoHandle data_pipe_producer_handle,
                                        void** buffer,
                                        uint32_t* buffer_num_elements,
                                        MojoWriteDataFlags flags) {
  assert(g_system_impl_thunks.BeginWriteData);
  return g_system_impl_thunks.BeginWriteData(
      system, data_pipe_producer_handle, buffer, buffer_num_elements, flags);
}

MojoResult MojoSystemImplEndWriteData(MojoSystemImpl system,
                                      MojoHandle data_pipe_producer_handle,
                                      uint32_t num_elements_written) {
  assert(g_system_impl_thunks.EndWriteData);
  return g_system_impl_thunks.EndWriteData(system, data_pipe_producer_handle,
                                           num_elements_written);
}

MojoResult MojoSystemImplReadData(MojoSystemImpl system,
                                  MojoHandle data_pipe_consumer_handle,
                                  void* elements,
                                  uint32_t* num_elements,
                                  MojoReadDataFlags flags) {
  assert(g_system_impl_thunks.ReadData);
  return g_system_impl_thunks.ReadData(system, data_pipe_consumer_handle,
                                       elements, num_elements, flags);
}

MojoResult MojoSystemImplBeginReadData(MojoSystemImpl system,
                                       MojoHandle data_pipe_consumer_handle,
                                       const void** buffer,
                                       uint32_t* buffer_num_elements,
                                       MojoReadDataFlags flags) {
  assert(g_system_impl_thunks.BeginReadData);
  return g_system_impl_thunks.BeginReadData(system, data_pipe_consumer_handle,
                                            buffer, buffer_num_elements, flags);
}

MojoResult MojoSystemImplEndReadData(MojoSystemImpl system,
                                     MojoHandle data_pipe_consumer_handle,
                                     uint32_t num_elements_read) {
  assert(g_system_impl_thunks.EndReadData);
  return g_system_impl_thunks.EndReadData(system, data_pipe_consumer_handle,
                                          num_elements_read);
}

MojoResult MojoSystemImplCreateSharedBuffer(
    MojoSystemImpl system,
    const struct MojoCreateSharedBufferOptions* options,
    uint64_t num_bytes,
    MojoHandle* shared_buffer_handle) {
  assert(g_system_impl_thunks.CreateSharedBuffer);
  return g_system_impl_thunks.CreateSharedBuffer(system, options, num_bytes,
                                                 shared_buffer_handle);
}

MojoResult MojoSystemImplDuplicateBufferHandle(
    MojoSystemImpl system,
    MojoHandle buffer_handle,
    const struct MojoDuplicateBufferHandleOptions* options,
    MojoHandle* new_buffer_handle) {
  assert(g_system_impl_thunks.DuplicateBufferHandle);
  return g_system_impl_thunks.DuplicateBufferHandle(system, buffer_handle,
                                                    options, new_buffer_handle);
}

MojoResult MojoSystemImplMapBuffer(MojoSystemImpl system,
                                   MojoHandle buffer_handle,
                                   uint64_t offset,
                                   uint64_t num_bytes,
                                   void** buffer,
                                   MojoMapBufferFlags flags) {
  assert(g_system_impl_thunks.MapBuffer);
  return g_system_impl_thunks.MapBuffer(system, buffer_handle, offset,
                                        num_bytes, buffer, flags);
}

MojoResult MojoSystemImplUnmapBuffer(MojoSystemImpl system, void* buffer) {
  assert(g_system_impl_thunks.UnmapBuffer);
  return g_system_impl_thunks.UnmapBuffer(system, buffer);
}

extern "C" THUNK_EXPORT size_t MojoSetSystemImplControlThunksPrivate(
    const MojoSystemImplControlThunksPrivate* system_thunks) {
  if (system_thunks->size >= sizeof(g_system_impl_control_thunks))
    g_system_impl_control_thunks = *system_thunks;
  return sizeof(g_system_impl_control_thunks);
}

extern "C" THUNK_EXPORT size_t MojoSetSystemImplThunksPrivate(
    const MojoSystemImplThunksPrivate* system_thunks) {
  if (system_thunks->size >= sizeof(g_system_impl_thunks))
    g_system_impl_thunks = *system_thunks;
  return sizeof(g_system_impl_thunks);
}

}  // extern "C"
