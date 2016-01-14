// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_EMBEDDER_MULTIPROCESS_EMBEDDER_H_
#define MOJO_EDK_EMBEDDER_MULTIPROCESS_EMBEDDER_H_

#include <functional>
#include <string>

#include "mojo/edk/embedder/channel_info_forward.h"
#include "mojo/edk/embedder/process_type.h"
#include "mojo/edk/embedder/slave_info.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/public/cpp/system/message_pipe.h"

namespace mojo {

namespace platform {
class PlatformHandleWatcher;
}

namespace embedder {

class ProcessDelegate;

// Initialialization/shutdown for interprocess communication (IPC) -------------

// |InitIPCSupport()| sets up the subsystem for interprocess communication,
// making the IPC functions (in the following section) available and functional.
// (This may only be done after |Init()|.)
//
// This subsystem may be shut down, using |ShutdownIPCSupportOnIOThread()| or
// |ShutdownIPCSupport()|. None of the IPC functions may be called while or
// after either of these is called.

// Initializes a process of the given type; to be called after |Init()|.
//   - |process_delegate| must be a process delegate of the appropriate type
//     corresponding to |process_type|; its methods will be called on
//     |delegate_thread_task_runner|.
//   - |delegate_thread_task_runner|, |process_delegate|, |io_task_runner|,
//     and |io_watcher| should live at least until |ShutdownIPCSupport()|'s
//     callback has been run or |ShutdownIPCSupportOnIOThread()| has completed.
//   - For slave processes (i.e., |process_type| is |ProcessType::SLAVE|),
//     |platform_handle| should be connected to the handle passed to
//     |ConnectToSlave()| (in the master process). For other processes,
//     |platform_handle| is ignored (and should not be valid).
void InitIPCSupport(
    ProcessType process_type,
    util::RefPtr<platform::TaskRunner>&& delegate_thread_task_runner,
    ProcessDelegate* process_delegate,
    util::RefPtr<platform::TaskRunner>&& io_task_runner,
    platform::PlatformHandleWatcher* io_watcher,
    platform::ScopedPlatformHandle platform_handle);

// Shuts down the subsystem initialized by |InitIPCSupport()|. This must be
// called on the I/O thread (given to |InitIPCSupport()|). This completes
// synchronously and does not result in a call to the process delegate's
// |OnShutdownComplete()|.
void ShutdownIPCSupportOnIOThread();

// Like |ShutdownIPCSupportOnIOThread()|, but may be called from any thread,
// signaling shutdown completion via the process delegate's
// |OnShutdownComplete()|.
void ShutdownIPCSupport();

// Interprocess communication (IPC) functions ----------------------------------

// Called in the master process to connect to a slave process to the IPC system.
// (This should only be called in a process initialized (using
// |InitIPCSupport()|) with process type |ProcessType::MASTER|.)
//
// This should typically be called *before* the slave process is even created.
// It requires an OS "pipe" to be established between the master and slave
// processes, with |platform_handle| being a handle to the end that remains on
// the master.
//
// This will establish a channel and an initial message pipe (to which it
// returns a handle), an ID string (returned in |*platform_connection_id|) that
// must be passed to the slave (e.g., on the command line), and a
// |ChannelInfo*| (in |*channel_info|) which should eventually be given to
// |DestroyChannel()|/|DestroyChannelOnIOThread()|, but only after
// |did_connect_to_slave_callback| has been run.
//
// |did_connect_to_slave_callback| will be run either using
// |did_connect_to_slave_runner| (if non-null) or on the I/O thread, once the
// |ChannelInfo*| is valid.
//
// TODO(vtl): The API is a little crazy with respect to the |ChannelInfo*|.
ScopedMessagePipeHandle ConnectToSlave(
    SlaveInfo slave_info,
    platform::ScopedPlatformHandle platform_handle,
    std::function<void()>&& did_connect_to_slave_callback,
    util::RefPtr<platform::TaskRunner>&& did_connect_to_slave_runner,
    std::string* platform_connection_id,
    ChannelInfo** channel_info);

// Called in a slave process to connect it to the IPC system. (This should only
// be called in a process initialized (using |InitIPCSupport()|) with process
// type |ProcessType::SLAVE|.) This should be called exactly once in each slave
// process.
//
// See |ConnectToSlave()| for details. (Note that if this fails in any way,
// e.g., if |platform_connection_id| is invalid, this will CHECK-fail and
// terminate the process.) |channel_info|, |did_connect_to_master_callback|, and
// |did_connect_to_master_runner| are analagous to in |ConnectToSlave()|.
//
// TODO(vtl): The API is a little crazy with respect to the |ChannelInfo*|.
ScopedMessagePipeHandle ConnectToMaster(
    const std::string& platform_connection_id,
    std::function<void()>&& did_connect_to_master_callback,
    util::RefPtr<platform::TaskRunner>&& did_connect_to_master_runner,
    ChannelInfo** channel_info);

// A "channel" is a connection on top of an OS "pipe", on top of which Mojo
// message pipes (etc.) can be multiplexed. It must "live" on some I/O thread.
//
// There are two channel creation APIs: |CreateChannelOnIOThread()| creates a
// channel synchronously and must be called from the I/O thread, while
// |CreateChannel()| is asynchronous and may be called from any thread.
// |DestroyChannel()| is used to destroy the channel in either case and may be
// called from any thread, but completes synchronously when called from the I/O
// thread.
//
// Both creation functions have a |platform_handle| argument, which should be an
// OS-dependent handle to one side of a suitable bidirectional OS "pipe" (e.g.,
// a file descriptor to a Unix domain socket); this "pipe" should be connected
// and ready for operation (e.g., to be written to or read from).
//
// Both (synchronously) return a handle to the bootstrap message pipe on the
// channel that was (or is to be) created, or |MOJO_HANDLE_INVALID| on error
// (but note that this will happen only if, e.g., the handle table is full).
// This message pipe may be used immediately, but since channel operation
// actually begins asynchronously, other errors may still occur (e.g., if the
// other end of the "pipe" is closed) and be reported in the usual way to the
// returned handle.
//
// (E.g., a message written immediately to the returned handle will be queued
// and the handle immediately closed, before the channel begins operation. In
// this case, the channel should connect as usual, send the queued message, and
// report that the handle was closed to the other side. The message sent may
// have other handles, so there may still be message pipes "on" this channel.)
//
// Both also produce a |ChannelInfo*| (a pointer to an opaque object) -- the
// first synchronously and second asynchronously.
//
// The destruction functions are similarly synchronous and asynchronous,
// respectively, and take the |ChannelInfo*| produced by the creation functions.

// Creates a channel; must only be called from the I/O thread. |platform_handle|
// should be a handle to a connected OS "pipe". Eventually (even on failure),
// the "out" value |*channel_info| should be passed to |DestoryChannel()| to
// tear down the channel. Returns a handle to the bootstrap message pipe.
ScopedMessagePipeHandle CreateChannelOnIOThread(
    platform::ScopedPlatformHandle platform_handle,
    ChannelInfo** channel_info);

// Creates a channel asynchronously; may be called from any thread.
// |platform_handle| should be a handle to a connected OS "pipe".
// |did_create_channel_callback| should be the callback to call with the
// |ChannelInfo*|, which should eventually be passed to |DestroyChannel()| to
// tear down the channel; the callback will be called using
// |did_create_channel_runner| if that is non-null, or otherwise it will be
// posted to the I/O thread. Returns a handle to the bootstrap message pipe.
//
// Note: This should only be used to establish a channel with a process of type
// |ProcessType::NONE|. This function may be removed in the future.
ScopedMessagePipeHandle CreateChannel(
    platform::ScopedPlatformHandle platform_handle,
    std::function<void(ChannelInfo*)>&& did_create_channel_callback,
    util::RefPtr<platform::TaskRunner>&& did_create_channel_runner);

// Destroys a channel that was created using |ConnectToMaster()|,
// |ConnectToSlave()|, |CreateChannel()|, or |CreateChannelOnIOThread()|; must
// be called from the channel's I'O thread. Completes synchronously (and posts
// no tasks).
void DestroyChannelOnIOThread(ChannelInfo* channel_info);

// Like |DestroyChannelOnIOThread()|, but asynchronous and may be called from
// any thread. The callback will be called using |did_destroy_channel_runner|
// if that is non-null, or otherwise it will be called on the "channel thread".
// The "channel thread" must remain alive and continue to process tasks until
// the callback has been executed.
void DestroyChannel(
    ChannelInfo* channel_info,
    std::function<void()>&& did_destroy_channel_callback,
    util::RefPtr<platform::TaskRunner>&& did_destroy_channel_runner);

// Inform the channel that it will soon be destroyed (doing so is optional).
// This may be called from any thread, but the caller must ensure that this is
// called before |DestroyChannel()|.
void WillDestroyChannelSoon(ChannelInfo* channel_info);

}  // namespace embedder
}  // namespace mojo

#endif  // MOJO_EDK_EMBEDDER_MULTIPROCESS_EMBEDDER_H_
