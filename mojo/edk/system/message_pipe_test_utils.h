// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_MESSAGE_PIPE_TEST_UTILS_H_
#define MOJO_EDK_SYSTEM_MESSAGE_PIPE_TEST_UTILS_H_

#include "base/test/test_io_thread.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/edk/test/multiprocess_test_helper.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace system {

class Channel;
class ChannelEndpoint;
class MessagePipe;

namespace test {

MojoResult WaitIfNecessary(scoped_refptr<MessagePipe> mp,
                           MojoHandleSignals signals,
                           HandleSignalsState* signals_state);

class ChannelThread {
 public:
  explicit ChannelThread(embedder::PlatformSupport* platform_support);
  ~ChannelThread();

  void Start(embedder::ScopedPlatformHandle platform_handle,
             scoped_refptr<ChannelEndpoint> channel_endpoint);
  void Stop();

 private:
  void InitChannelOnIOThread(embedder::ScopedPlatformHandle platform_handle,
                             scoped_refptr<ChannelEndpoint> channel_endpoint);
  void ShutdownChannelOnIOThread();

  embedder::PlatformSupport* const platform_support_;
  base::TestIOThread test_io_thread_;
  scoped_refptr<Channel> channel_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelThread);
};

#if !defined(OS_IOS)
class MultiprocessMessagePipeTestBase : public testing::Test {
 public:
  MultiprocessMessagePipeTestBase();
  ~MultiprocessMessagePipeTestBase() override;

 protected:
  void Init(scoped_refptr<ChannelEndpoint> ep);

  embedder::PlatformSupport* platform_support() { return &platform_support_; }
  mojo::test::MultiprocessTestHelper* helper() { return &helper_; }

 private:
  embedder::SimplePlatformSupport platform_support_;
  ChannelThread channel_thread_;
  mojo::test::MultiprocessTestHelper helper_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MultiprocessMessagePipeTestBase);
};
#endif

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_MESSAGE_PIPE_TEST_UTILS_H_
