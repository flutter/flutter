// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_PIPE_DISPATCHER_H_
#define MOJO_EDK_SYSTEM_MESSAGE_PIPE_DISPATCHER_H_

#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/memory.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class ChannelEndpoint;
class MessagePipe;

// This is the |Dispatcher| implementation for message pipes (created by the
// Mojo primitive |MojoCreateMessagePipe()|). This class is thread-safe.
class MessagePipeDispatcher final : public Dispatcher {
 public:
  // The default/standard rights for a message pipe handle.
  static constexpr MojoHandleRights kDefaultHandleRights =
      MOJO_HANDLE_RIGHT_TRANSFER | MOJO_HANDLE_RIGHT_READ |
      MOJO_HANDLE_RIGHT_WRITE;

  // The default options to use for |MojoCreateMessagePipe()|. (Real uses
  // should obtain this via |ValidateCreateOptions()| with a null |in_options|;
  // this is exposed directly for testing convenience.)
  static const MojoCreateMessagePipeOptions kDefaultCreateOptions;

  static util::RefPtr<MessagePipeDispatcher> Create(
      const MojoCreateMessagePipeOptions& /*validated_options*/) {
    return AdoptRef(new MessagePipeDispatcher());
  }

  // Validates and/or sets default options for |MojoCreateMessagePipeOptions|.
  // If non-null, |in_options| must point to a struct of at least
  // |in_options->struct_size| bytes. |out_options| must point to a (current)
  // |MojoCreateMessagePipeOptions| and will be entirely overwritten on success
  // (it may be partly overwritten on failure).
  static MojoResult ValidateCreateOptions(
      UserPointer<const MojoCreateMessagePipeOptions> in_options,
      MojoCreateMessagePipeOptions* out_options);

  // Must be called before any other methods. (This method is not thread-safe.)
  void Init(util::RefPtr<MessagePipe>&& message_pipe,
            unsigned port) MOJO_NOT_THREAD_SAFE;

  // |Dispatcher| public methods:
  Type GetType() const override;
  bool SupportsEntrypointClass(EntrypointClass entrypoint_class) const override;

  // Creates a |MessagePipe| with a local endpoint (at port 0) and a proxy
  // endpoint, and creates/initializes a |MessagePipeDispatcher| (attached to
  // the message pipe, port 0).
  // TODO(vtl): This currently uses |kDefaultCreateOptions|, which is okay since
  // there aren't any options, but eventually options should be plumbed through.
  static util::RefPtr<MessagePipeDispatcher> CreateRemoteMessagePipe(
      util::RefPtr<ChannelEndpoint>* channel_endpoint);

  // The "opposite" of |SerializeAndClose()|. (Typically this is called by
  // |Dispatcher::Deserialize()|.)
  static util::RefPtr<MessagePipeDispatcher> Deserialize(Channel* channel,
                                                         const void* source,
                                                         size_t size);

 private:
  MessagePipeDispatcher();
  ~MessagePipeDispatcher() override;

  // Gets a dumb pointer to |message_pipe_|. This must be called under the
  // |Dispatcher| lock (that it's a dumb pointer is okay since it's under lock).
  // This is needed when sending handles across processes, where nontrivial,
  // invasive work needs to be done.
  MessagePipe* GetMessagePipeNoLock() const;
  // Similarly for the port.
  unsigned GetPortNoLock() const;

  // |Dispatcher| protected methods:
  void CancelAllAwakablesNoLock() override;
  void CloseImplNoLock() override;
  util::RefPtr<Dispatcher> CreateEquivalentDispatcherAndCloseImplNoLock(
      MessagePipe* message_pipe,
      unsigned port) override;
  MojoResult WriteMessageImplNoLock(UserPointer<const void> bytes,
                                    uint32_t num_bytes,
                                    std::vector<HandleTransport>* transports,
                                    MojoWriteMessageFlags flags) override;
  MojoResult ReadMessageImplNoLock(UserPointer<void> bytes,
                                   UserPointer<uint32_t> num_bytes,
                                   HandleVector* handles,
                                   uint32_t* num_handles,
                                   MojoReadMessageFlags flags) override;
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

  // This will be null if closed.
  util::RefPtr<MessagePipe> message_pipe_ MOJO_GUARDED_BY(mutex());
  unsigned port_ MOJO_GUARDED_BY(mutex());

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessagePipeDispatcher);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_PIPE_DISPATCHER_H_
