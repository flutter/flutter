// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_PIPE_TEST_UTILS_H_
#define MOJO_EDK_SYSTEM_MESSAGE_PIPE_TEST_UTILS_H_

#include <memory>

#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/test/test_io_thread.h"
#include "mojo/edk/test/multiprocess_test_helper.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
}

namespace system {

class Channel;
class ChannelEndpoint;
class MessagePipe;

namespace test {

MojoResult WaitIfNecessary(MessagePipe* mp,
                           MojoHandleSignals signals,
                           HandleSignalsState* signals_state);

class ChannelThread {
 public:
  explicit ChannelThread(embedder::PlatformSupport* platform_support);
  ~ChannelThread();

  void Start(platform::ScopedPlatformHandle platform_handle,
             util::RefPtr<ChannelEndpoint>&& channel_endpoint);
  void Stop();

 private:
  void InitChannelOnIOThread(platform::ScopedPlatformHandle platform_handle,
                             util::RefPtr<ChannelEndpoint>&& channel_endpoint);

  embedder::PlatformSupport* const platform_support_;
  TestIOThread test_io_thread_;
  util::RefPtr<Channel> channel_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelThread);
};

#if !defined(OS_IOS)
class MultiprocessMessagePipeTestBase : public testing::Test {
 public:
  MultiprocessMessagePipeTestBase();
  ~MultiprocessMessagePipeTestBase() override;

 protected:
  void Init(util::RefPtr<ChannelEndpoint>&& ep);

  embedder::PlatformSupport* platform_support() {
    return platform_support_.get();
  }
  mojo::test::MultiprocessTestHelper* helper() { return &helper_; }

 private:
  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  ChannelThread channel_thread_;
  mojo::test::MultiprocessTestHelper helper_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MultiprocessMessagePipeTestBase);
};
#endif

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_PIPE_TEST_UTILS_H_
