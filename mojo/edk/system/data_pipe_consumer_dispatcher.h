// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_DATA_PIPE_CONSUMER_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_DATA_PIPE_CONSUMER_DISPATCHER_H_

#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class DataPipe;

// This is the |Dispatcher| implementation for the consumer handle for data
// pipes (created by the Mojo primitive |MojoCreateDataPipe()|). This class is
// thread-safe.
class DataPipeConsumerDispatcher final : public Dispatcher {
 public:
  // The default/standard rights for a data pipe consumer handle.
  static constexpr MojoHandleRights kDefaultHandleRights =
      MOJO_HANDLE_RIGHT_TRANSFER | MOJO_HANDLE_RIGHT_READ |
      MOJO_HANDLE_RIGHT_WRITE;

  static util::RefPtr<DataPipeConsumerDispatcher> Create() {
    return AdoptRef(new DataPipeConsumerDispatcher());
  }

  // Must be called before any other methods.
  void Init(util::RefPtr<DataPipe>&& data_pipe) MOJO_NOT_THREAD_SAFE;

  // |Dispatcher| public methods:
  Type GetType() const override;
  bool SupportsEntrypointClass(EntrypointClass entrypoint_class) const override;

  // The "opposite" of |SerializeAndClose()|. (Typically this is called by
  // |Dispatcher::Deserialize()|.)
  static util::RefPtr<DataPipeConsumerDispatcher>
  Deserialize(Channel* channel, const void* source, size_t size);

  // Get access to the |DataPipe| for testing.
  DataPipe* GetDataPipeForTest();

 private:
  DataPipeConsumerDispatcher();
  ~DataPipeConsumerDispatcher() override;

  // |Dispatcher| protected methods:
  void CancelAllAwakablesNoLock() override;
  void CloseImplNoLock() override;
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* message_pipe,
      unsigned port) override;
  MojoResult SetDataPipeConsumerOptionsImplNoLock(
      UserPointer<const MojoDataPipeConsumerOptions> options) override;
  MojoResult GetDataPipeConsumerOptionsImplNoLock(
      UserPointer<MojoDataPipeConsumerOptions> options,
      uint32_t options_num_bytes) override;
  MojoResult ReadDataImplNoLock(UserPointer<void> elements,
                                UserPointer<uint32_t> num_bytes,
                                MojoReadDataFlags flags) override;
  MojoResult BeginReadDataImplNoLock(UserPointer<const void*> buffer,
                                     UserPointer<uint32_t> buffer_num_bytes,
                                     MojoReadDataFlags flags) override;
  MojoResult EndReadDataImplNoLock(uint32_t num_bytes_read) override;
  HandleSignalsState GetHandleSignalsStateImplNoLock() const override;
  MojoResult AddAwakableImplNoLock(Awakable* awakable,
                                   MojoHandleSignals signals,
                                   uint32_t context,
                                   HandleSignalsState* signals_state) override;
  void RemoveAwakableImplNoLock(Awakable* awakable,
                                HandleSignalsState* signals_state) override;
  void StartSerializeImplNoLock(Channel* channel,
                                size_t* max_size,
                                size_t* max_platform_handles) override
      MOJO_NOT_THREAD_SAFE;
  bool EndSerializeAndCloseImplNoLock(
      Channel* channel,
      void* destination,
      size_t* actual_size,
      std::vector<platform::ScopedPlatformHandle>* platform_handles) override
      MOJO_NOT_THREAD_SAFE;
  bool IsBusyNoLock() const override;

  // This will be null if closed.
  util::RefPtr<DataPipe> data_pipe_ MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(DataPipeConsumerDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_DATA_PIPE_CONSUMER_DISPATCHER_H_
