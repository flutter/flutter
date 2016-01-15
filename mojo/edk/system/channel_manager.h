// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_MANAGER_H_
#define MOJO_EDK_SYSTEM_CHANNEL_MANAGER_H_

#include <stdint.h>

#include <functional>
#include <unordered_map>

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/system/channel_id.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/thread_annotations.h"
#include "mojo/public/cpp/system/macros.h"

namespace base {
class TaskRunner;
}

namespace mojo {

namespace embedder {
class PlatformSupport;
}

namespace platform {
class PlatformHandleWatcher;
}

namespace system {

class Channel;
class ChannelEndpoint;
class ConnectionManager;
class MessagePipeDispatcher;

// This class manages and "owns" |Channel|s (which typically connect to other
// processes) for a given process. This class is thread-safe, except as
// specifically noted.
class ChannelManager {
 public:
  // |io_task_runner| and |io_watcher| should be the |TaskRunner| and
  // |PlatformHandleWatcher|, respectively, for the I/O thread, on which this
  // channel manager will create all channels. |connection_manager| is optional
  // and may be null. All arguments (if non-null) must remain alive at least
  // until after shutdown completion.
  ChannelManager(embedder::PlatformSupport* platform_support,
                 util::RefPtr<platform::TaskRunner>&& io_task_runner,
                 platform::PlatformHandleWatcher* io_watcher,
                 ConnectionManager* connection_manager);
  ~ChannelManager();

  // Shuts down the channel manager, including shutting down all channels (as if
  // |ShutdownChannelOnIOThread()| were called for each channel). This must be
  // called from the I/O thread (given to the constructor) and completes
  // synchronously. This, or |Shutdown()|, must be called before destroying this
  // object.
  void ShutdownOnIOThread();

  // Like |ShutdownOnIOThread()|, but may be called from any thread. On
  // completion, will call |callback| ("on" |io_task_runner| if
  // |callback_thread_task_runner| is null else by posted using
  // |callback_thread_task_runner|). Note: This will always post a task to the
  // I/O thread, even it is the current thread.
  // TODO(vtl): Consider if this is really necessary, since it only has one use
  // (in tests).
  void Shutdown(
      std::function<void()>&& callback,
      util::RefPtr<platform::TaskRunner>&& callback_thread_task_runner);

  // Creates a |Channel| and adds it to the set of channels managed by this
  // |ChannelManager|. This must be called from the I/O thread (given to the
  // constructor). |channel_id| should be a valid |ChannelId| (i.e., nonzero)
  // not "assigned" to any other |Channel| being managed by this
  // |ChannelManager|.
  util::RefPtr<MessagePipeDispatcher> CreateChannelOnIOThread(
      ChannelId channel_id,
      platform::ScopedPlatformHandle platform_handle);

  // Like |CreateChannelOnIOThread()|, but doesn't create a bootstrap message
  // pipe. Returns the newly-created |Channel|.
  // TODO(vtl): Maybe get rid of the others (and bootstrap message pipes in
  // general).
  util::RefPtr<Channel> CreateChannelWithoutBootstrapOnIOThread(
      ChannelId channel_id,
      platform::ScopedPlatformHandle platform_handle);

  // Like |CreateChannelOnIOThread()|, but may be called from any thread. On
  // completion, will call |callback| (using |callback_thread_task_runner| if it
  // is non-null, else on the I/O thread). Note: This will always post a task to
  // the I/O thread, even if called from that thread.
  util::RefPtr<MessagePipeDispatcher> CreateChannel(
      ChannelId channel_id,
      platform::ScopedPlatformHandle platform_handle,
      std::function<void()>&& callback,
      util::RefPtr<platform::TaskRunner>&& callback_thread_task_runner);

  // Gets the |Channel| with the given ID (which must exist).
  util::RefPtr<Channel> GetChannel(ChannelId channel_id) const;

  // Informs the channel manager (and thus channel) that it will be shutdown
  // soon (by calling |ShutdownChannel()|). Calling this is optional (and may in
  // fact be called multiple times) but it will suppress certain warnings (e.g.,
  // for the channel being broken) and enable others (if messages are written to
  // the channel).
  void WillShutdownChannel(ChannelId channel_id);

  // Shuts down the channel specified by the given ID. This, or
  // |ShutdownChannel()|, should be called once per channel (created using
  // |CreateChannelOnIOThread()| or |CreateChannel()|). This must be called from
  // the I/O thread.
  void ShutdownChannelOnIOThread(ChannelId channel_id);

  // Like |ShutdownChannelOnIOThread()|, but may be called from any thread. It
  // will always post a task to the I/O thread, and post |callback| to
  // |callback_thread_task_runner| (or execute it directly on the I/O thread if
  // |callback_thread_task_runner| is null) on completion.
  void ShutdownChannel(
      ChannelId channel_id,
      std::function<void()>&& callback,
      util::RefPtr<platform::TaskRunner>&& callback_thread_task_runner);

  ConnectionManager* connection_manager() const { return connection_manager_; }

 private:
  // Used by |CreateChannelOnIOThread()| and |CreateChannel()|. Called on the
  // I/O thread. |bootstrap_channel_endpoint| is optional and may be null.
  // Returns the newly-created |Channel|.
  util::RefPtr<Channel> CreateChannelOnIOThreadHelper(
      ChannelId channel_id,
      platform::ScopedPlatformHandle platform_handle,
      util::RefPtr<ChannelEndpoint>&& bootstrap_channel_endpoint);

  // Note: These must not be used after shutdown.
  embedder::PlatformSupport* const platform_support_;
  const util::RefPtr<platform::TaskRunner> io_task_runner_;
  platform::PlatformHandleWatcher* const io_watcher_;
  ConnectionManager* const connection_manager_;

  // Note: |Channel| methods should not be called under |mutex_|.
  // TODO(vtl): Annotate the above rule using |MOJO_ACQUIRED_{BEFORE,AFTER}()|,
  // once clang actually checks such annotations.
  // https://github.com/domokit/mojo/issues/313
  mutable util::Mutex mutex_;

  using ChannelIdToChannelMap =
      std::unordered_map<ChannelId, util::RefPtr<Channel>>;
  ChannelIdToChannelMap channels_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelManager);
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CHANNEL_MANAGER_H_
