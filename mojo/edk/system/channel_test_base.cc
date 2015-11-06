// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_test_base.h"

#include <utility>

#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "mojo/edk/embedder/platform_channel_pair.h"
#include "mojo/edk/system/raw_channel.h"

using mojo::util::MakeRefCounted;

namespace mojo {
namespace system {
namespace test {

ChannelTestBase::ChannelTestBase()
    : io_thread_(TestIOThread::StartMode::AUTO) {}

ChannelTestBase::~ChannelTestBase() {
}

void ChannelTestBase::SetUp() {
  PostMethodToIOThreadAndWait(&ChannelTestBase::SetUpOnIOThread);
}

void ChannelTestBase::CreateChannelOnIOThread(unsigned i) {
  CHECK_EQ(base::MessageLoop::current(), io_thread()->message_loop());

  CHECK(!channels_[i]);
  channels_[i] = MakeRefCounted<Channel>(&platform_support_);
}

void ChannelTestBase::InitChannelOnIOThread(unsigned i) {
  CHECK_EQ(base::MessageLoop::current(), io_thread()->message_loop());

  CHECK(raw_channels_[i]);
  CHECK(channels_[i]);
  channels_[i]->Init(std::move(raw_channels_[i]));
}

void ChannelTestBase::CreateAndInitChannelOnIOThread(unsigned i) {
  CreateChannelOnIOThread(i);
  InitChannelOnIOThread(i);
}

void ChannelTestBase::ShutdownChannelOnIOThread(unsigned i) {
  CHECK_EQ(base::MessageLoop::current(), io_thread()->message_loop());

  CHECK(channels_[i]);
  channels_[i]->Shutdown();
}

void ChannelTestBase::ShutdownAndReleaseChannelOnIOThread(unsigned i) {
  ShutdownChannelOnIOThread(i);
  channels_[i] = nullptr;
}

void ChannelTestBase::SetUpOnIOThread() {
  CHECK_EQ(base::MessageLoop::current(), io_thread()->message_loop());

  embedder::PlatformChannelPair channel_pair;
  raw_channels_[0] = RawChannel::Create(channel_pair.PassServerHandle());
  raw_channels_[1] = RawChannel::Create(channel_pair.PassClientHandle());
}

}  // namespace test
}  // namespace system
}  // namespace mojo
