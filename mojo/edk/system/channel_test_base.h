// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CHANNEL_TEST_BASE_H_
#define MOJO_EDK_SYSTEM_CHANNEL_TEST_BASE_H_

#include <memory>

#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/test/test_io_thread.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {

namespace embedder {
class PlatformSupport;
}

namespace system {

class RawChannel;

namespace test {

// A base class for tests that need a |Channel| set up in a simple way.
class ChannelTestBase : public testing::Test {
 public:
  ChannelTestBase();
  ~ChannelTestBase() override;

  void SetUp() override;

  // These should only be called from |io_thread()|:
  void CreateChannelOnIOThread(unsigned i);
  void InitChannelOnIOThread(unsigned i);
  void CreateAndInitChannelOnIOThread(unsigned i);
  void ShutdownChannelOnIOThread(unsigned i);
  void ShutdownAndReleaseChannelOnIOThread(unsigned i);

  TestIOThread* io_thread() { return &io_thread_; }
  Channel* channel(unsigned i) { return channels_[i].get(); }
  util::RefPtr<Channel>* mutable_channel(unsigned i) { return &channels_[i]; }

 private:
  void SetUpOnIOThread();

  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  TestIOThread io_thread_;
  std::unique_ptr<RawChannel> raw_channels_[2];
  util::RefPtr<Channel> channels_[2];

  MOJO_DISALLOW_COPY_AND_ASSIGN(ChannelTestBase);
};

}  // namespace test
}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CHANNEL_TEST_BASE_H_
