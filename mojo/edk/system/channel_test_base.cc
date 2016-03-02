// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/channel_test_base.h"

#include <utility>

#include "base/logging.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/system/raw_channel.h"

using mojo::platform::PlatformPipe;
using mojo::util::MakeRefCounted;

namespace mojo {
namespace system {
namespace test {

ChannelTestBase::ChannelTestBase()
    : platform_support_(embedder::CreateSimplePlatformSupport()),
      io_thread_(TestIOThread::StartMode::AUTO) {}

ChannelTestBase::~ChannelTestBase() {}

void ChannelTestBase::SetUp() {
  io_thread_.PostTaskAndWait([this]() { SetUpOnIOThread(); });
}

void ChannelTestBase::CreateChannelOnIOThread(unsigned i) {
  CHECK(io_thread()->IsCurrentAndRunning());

  CHECK(!channels_[i]);
  channels_[i] = MakeRefCounted<Channel>(platform_support_.get());
}

void ChannelTestBase::InitChannelOnIOThread(unsigned i) {
  CHECK(io_thread()->IsCurrentAndRunning());

  CHECK(raw_channels_[i]);
  CHECK(channels_[i]);
  channels_[i]->Init(io_thread()->task_runner().Clone(),
                     io_thread()->platform_handle_watcher(),
                     std::move(raw_channels_[i]));
}

void ChannelTestBase::CreateAndInitChannelOnIOThread(unsigned i) {
  CreateChannelOnIOThread(i);
  InitChannelOnIOThread(i);
}

void ChannelTestBase::ShutdownChannelOnIOThread(unsigned i) {
  CHECK(io_thread()->IsCurrentAndRunning());

  CHECK(channels_[i]);
  channels_[i]->Shutdown();
}

void ChannelTestBase::ShutdownAndReleaseChannelOnIOThread(unsigned i) {
  ShutdownChannelOnIOThread(i);
  channels_[i] = nullptr;
}

void ChannelTestBase::SetUpOnIOThread() {
  CHECK(io_thread()->IsCurrentAndRunning());

  PlatformPipe channel_pair;
  raw_channels_[0] = RawChannel::Create(channel_pair.handle0.Pass());
  raw_channels_[1] = RawChannel::Create(channel_pair.handle1.Pass());
}

}  // namespace test
}  // namespace system
}  // namespace mojo
