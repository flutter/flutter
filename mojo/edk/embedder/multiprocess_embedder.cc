// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/multiprocess_embedder.h"

#include <atomic>
#include <utility>

#include "base/logging.h"
#include "mojo/edk/embedder/embedder_internal.h"
#include "mojo/edk/embedder/master_process_delegate.h"
#include "mojo/edk/embedder/process_delegate.h"
#include "mojo/edk/embedder/slave_process_delegate.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_manager.h"
#include "mojo/edk/system/core.h"
#include "mojo/edk/system/ipc_support.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/util/ref_ptr.h"

using mojo::platform::PlatformHandleWatcher;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::TaskRunner;
using mojo::util::RefPtr;

namespace mojo {
namespace embedder {

namespace internal {

// Declared in embedder_internal.h.
system::IPCSupport* g_ipc_support = nullptr;

}  // namespace internal

namespace {

std::atomic<unsigned>* g_make_channel_id_counter = nullptr;

// TODO(vtl): For now, we need this to be thread-safe (since theoretically we
// currently support multiple channel creation threads -- possibly one per
// channel). Eventually, we won't need it to be thread-safe (we'll require a
// single I/O thread), and eventually we won't need it at all. Remember to
// remove the base/atomicops.h include.
system::ChannelId MakeChannelId() {
  DCHECK(g_make_channel_id_counter);
  unsigned new_counter_value = g_make_channel_id_counter->fetch_add(1u) + 1u;
  // Don't allow the counter to wrap.
  CHECK_GT(new_counter_value, 0u);
  // Use "negative" values for these IDs, so that we'll also be able to use
  // "positive" "process identifiers" (see connection_manager.h) as IDs (and
  // they won't conflict). (|system::ChannelId| is a |uint64_t|, so assuming
  // that |unsigned| is 32-bit, we won't run into the process identifiers.)
  return -static_cast<system::ChannelId>(new_counter_value);
}

}  // namespace

void InitIPCSupport(ProcessType process_type,
                    RefPtr<TaskRunner>&& delegate_thread_task_runner,
                    ProcessDelegate* process_delegate,
                    RefPtr<TaskRunner>&& io_task_runner,
                    PlatformHandleWatcher* io_watcher,
                    ScopedPlatformHandle platform_handle) {
  // |Init()| must have already been called.
  DCHECK(internal::g_core);
  // And not |InitIPCSupport()| (without |ShutdownIPCSupport()|).
  DCHECK(!internal::g_ipc_support);
  DCHECK(!g_make_channel_id_counter);

  internal::g_ipc_support = new system::IPCSupport(
      internal::g_platform_support, process_type,
      std::move(delegate_thread_task_runner), process_delegate,
      std::move(io_task_runner), io_watcher, platform_handle.Pass());

  g_make_channel_id_counter = new std::atomic<unsigned>();
}

void ShutdownIPCSupportOnIOThread() {
  DCHECK(internal::g_ipc_support);
  DCHECK(g_make_channel_id_counter);

  internal::g_ipc_support->ShutdownOnIOThread();
  delete internal::g_ipc_support;
  internal::g_ipc_support = nullptr;
  delete g_make_channel_id_counter;
  g_make_channel_id_counter = nullptr;
}

void ShutdownIPCSupport() {
  DCHECK(internal::g_ipc_support);

  internal::g_ipc_support->io_task_runner()->PostTask([]() {
    // Save these before they get nuked by |ShutdownChannelOnIOThread()|.
    RefPtr<TaskRunner> delegate_thread_task_runner(
        internal::g_ipc_support->delegate_thread_task_runner());
    ProcessDelegate* process_delegate =
        internal::g_ipc_support->process_delegate();

    ShutdownIPCSupportOnIOThread();

    delegate_thread_task_runner->PostTask(
        [process_delegate]() { process_delegate->OnShutdownComplete(); });
  });
}

ScopedMessagePipeHandle ConnectToSlave(
    SlaveInfo slave_info,
    ScopedPlatformHandle platform_handle,
    std::function<void()>&& did_connect_to_slave_callback,
    RefPtr<TaskRunner>&& did_connect_to_slave_runner,
    std::string* platform_connection_id,
    ChannelInfo** channel_info) {
  DCHECK(platform_connection_id);
  DCHECK(channel_info);
  DCHECK(internal::g_ipc_support);

  system::ConnectionIdentifier connection_id =
      internal::g_ipc_support->GenerateConnectionIdentifier();
  *platform_connection_id = connection_id.ToString();
  system::ChannelId channel_id = system::kInvalidChannelId;
  RefPtr<system::MessagePipeDispatcher> dispatcher =
      internal::g_ipc_support->ConnectToSlave(
          connection_id, slave_info, platform_handle.Pass(),
          std::move(did_connect_to_slave_callback),
          std::move(did_connect_to_slave_runner), &channel_id);
  *channel_info = new ChannelInfo(channel_id);

  ScopedMessagePipeHandle rv(
      MessagePipeHandle(internal::g_core->AddDispatcher(dispatcher.get())));
  CHECK(rv.is_valid());
  return rv;
}

ScopedMessagePipeHandle ConnectToMaster(
    const std::string& platform_connection_id,
    std::function<void()>&& did_connect_to_master_callback,
    RefPtr<TaskRunner>&& did_connect_to_master_runner,
    ChannelInfo** channel_info) {
  DCHECK(channel_info);
  DCHECK(internal::g_ipc_support);

  bool ok = false;
  system::ConnectionIdentifier connection_id =
      system::ConnectionIdentifier::FromString(platform_connection_id, &ok);
  CHECK(ok);

  system::ChannelId channel_id = system::kInvalidChannelId;
  RefPtr<system::MessagePipeDispatcher> dispatcher =
      internal::g_ipc_support->ConnectToMaster(
          connection_id, std::move(did_connect_to_master_callback),
          std::move(did_connect_to_master_runner), &channel_id);
  *channel_info = new ChannelInfo(channel_id);

  ScopedMessagePipeHandle rv(
      MessagePipeHandle(internal::g_core->AddDispatcher(dispatcher.get())));
  CHECK(rv.is_valid());
  return rv;
}

// TODO(vtl): Write tests for this.
ScopedMessagePipeHandle CreateChannelOnIOThread(
    ScopedPlatformHandle platform_handle,
    ChannelInfo** channel_info) {
  DCHECK(platform_handle.is_valid());
  DCHECK(channel_info);
  DCHECK(internal::g_ipc_support);

  system::ChannelManager* channel_manager =
      internal::g_ipc_support->channel_manager();

  *channel_info = new ChannelInfo(MakeChannelId());
  RefPtr<system::MessagePipeDispatcher> dispatcher =
      channel_manager->CreateChannelOnIOThread((*channel_info)->channel_id,
                                               platform_handle.Pass());

  ScopedMessagePipeHandle rv(
      MessagePipeHandle(internal::g_core->AddDispatcher(dispatcher.get())));
  CHECK(rv.is_valid());
  return rv;
}

ScopedMessagePipeHandle CreateChannel(
    ScopedPlatformHandle platform_handle,
    std::function<void(ChannelInfo*)>&& did_create_channel_callback,
    RefPtr<TaskRunner>&& did_create_channel_runner) {
  DCHECK(platform_handle.is_valid());
  DCHECK(did_create_channel_callback);
  DCHECK(internal::g_ipc_support);

  system::ChannelManager* channel_manager =
      internal::g_ipc_support->channel_manager();

  system::ChannelId channel_id = MakeChannelId();
  // Ownership gets passed back to the caller via |did_create_channel_callback|.
  ChannelInfo* channel_info = new ChannelInfo(channel_id);
  RefPtr<system::MessagePipeDispatcher> dispatcher =
      channel_manager->CreateChannel(
          channel_id, platform_handle.Pass(),
          [did_create_channel_callback, channel_info]() {
            did_create_channel_callback(channel_info);
          },
          std::move(did_create_channel_runner));

  ScopedMessagePipeHandle rv(
      MessagePipeHandle(internal::g_core->AddDispatcher(dispatcher.get())));
  CHECK(rv.is_valid());
  return rv;
}

// TODO(vtl): Write tests for this.
void DestroyChannelOnIOThread(ChannelInfo* channel_info) {
  DCHECK(channel_info);
  DCHECK(channel_info->channel_id);
  DCHECK(internal::g_ipc_support);

  system::ChannelManager* channel_manager =
      internal::g_ipc_support->channel_manager();
  channel_manager->ShutdownChannelOnIOThread(channel_info->channel_id);
  delete channel_info;
}

// TODO(vtl): Write tests for this.
void DestroyChannel(ChannelInfo* channel_info,
                    std::function<void()>&& did_destroy_channel_callback,
                    RefPtr<TaskRunner>&& did_destroy_channel_runner) {
  DCHECK(channel_info);
  DCHECK(channel_info->channel_id);
  DCHECK(did_destroy_channel_callback);
  DCHECK(internal::g_ipc_support);

  system::ChannelManager* channel_manager =
      internal::g_ipc_support->channel_manager();
  channel_manager->ShutdownChannel(channel_info->channel_id,
                                   std::move(did_destroy_channel_callback),
                                   std::move(did_destroy_channel_runner));
  delete channel_info;
}

void WillDestroyChannelSoon(ChannelInfo* channel_info) {
  DCHECK(channel_info);
  DCHECK(internal::g_ipc_support);

  system::ChannelManager* channel_manager =
      internal::g_ipc_support->channel_manager();
  channel_manager->WillShutdownChannel(channel_info->channel_id);
}

}  // namespace embedder
}  // namespace mojo
