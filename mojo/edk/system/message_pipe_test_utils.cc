// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_pipe_test_utils.h"

#include <utility>

#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/waiter.h"

using mojo::platform::ScopedPlatformHandle;
using mojo::platform::ThreadSleep;
using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace test {

MojoResult WaitIfNecessary(MessagePipe* mp,
                           MojoHandleSignals signals,
                           HandleSignalsState* signals_state) {
  Waiter waiter;
  waiter.Init();

  MojoResult add_result =
      mp->AddAwakable(0, &waiter, 0, false, signals, signals_state);
  if (add_result != MOJO_RESULT_OK) {
    return (add_result == MOJO_RESULT_ALREADY_EXISTS) ? MOJO_RESULT_OK
                                                      : add_result;
  }

  MojoResult wait_result =
      waiter.Wait(MOJO_DEADLINE_INDEFINITE, nullptr, nullptr);
  mp->RemoveAwakable(0, false, &waiter, 0, signals_state);
  return wait_result;
}

ChannelThread::ChannelThread(embedder::PlatformSupport* platform_support)
    : platform_support_(platform_support),
      test_io_thread_(TestIOThread::StartMode::MANUAL) {}

ChannelThread::~ChannelThread() {
  Stop();
}

void ChannelThread::Start(ScopedPlatformHandle platform_handle,
                          RefPtr<ChannelEndpoint>&& channel_endpoint) {
  test_io_thread_.Start();
  // TODO(vtl): With C++11 lambda captures, we'll be able to move
  // |platform_handle| (and |channel_endpoint|) instead.
  auto raw_platform_handle = platform_handle.release();
  test_io_thread_.PostTaskAndWait(
      [this, raw_platform_handle, channel_endpoint]() mutable {
        InitChannelOnIOThread(ScopedPlatformHandle(raw_platform_handle),
                              std::move(channel_endpoint));
      });
}

void ChannelThread::Stop() {
  if (channel_) {
    // Hack to flush write buffers before quitting.
    // TODO(vtl): Remove this once |Channel| has a
    // |FlushWriteBufferAndShutdown()| (or whatever).
    while (!channel_->IsWriteBufferEmpty())
      ThreadSleep(test::EpsilonTimeout());

    test_io_thread_.PostTaskAndWait([this] {
      channel_->Shutdown();
      channel_ = nullptr;
    });
  }
  test_io_thread_.Stop();
}

void ChannelThread::InitChannelOnIOThread(
    ScopedPlatformHandle platform_handle,
    RefPtr<ChannelEndpoint>&& channel_endpoint) {
  CHECK(test_io_thread_.IsCurrentAndRunning());
  CHECK(platform_handle.is_valid());

  // Create and initialize |Channel|.
  channel_ = MakeRefCounted<Channel>(platform_support_);
  channel_->Init(test_io_thread_.task_runner().Clone(),
                 test_io_thread_.platform_handle_watcher(),
                 RawChannel::Create(platform_handle.Pass()));

  // Start the bootstrap endpoint.
  // Note: On the "server" (parent process) side, we need not attach/run the
  // endpoint immediately. However, on the "client" (child process) side, this
  // *must* be done here -- otherwise, the |Channel| may receive/process
  // messages (which it can do as soon as it's hooked up to the IO thread
  // message loop, and that message loop runs) before the endpoint is attached.
  channel_->SetBootstrapEndpoint(std::move(channel_endpoint));
}

#if !defined(OS_IOS)
MultiprocessMessagePipeTestBase::MultiprocessMessagePipeTestBase()
    : platform_support_(embedder::CreateSimplePlatformSupport()),
      channel_thread_(platform_support_.get()) {}

MultiprocessMessagePipeTestBase::~MultiprocessMessagePipeTestBase() {
}

void MultiprocessMessagePipeTestBase::Init(RefPtr<ChannelEndpoint>&& ep) {
  channel_thread_.Start(helper_.server_platform_handle.Pass(), std::move(ep));
}
#endif  // !defined(OS_IOS)

}  // namespace test
}  // namespace system
}  // namespace mojo
