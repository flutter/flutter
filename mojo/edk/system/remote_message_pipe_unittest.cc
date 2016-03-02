// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <memory>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/platform_handle_utils_posix.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/platform_shared_buffer.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/channel_endpoint.h"
#include "mojo/edk/system/channel_endpoint_id.h"
#include "mojo/edk/system/incoming_endpoint.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/message_pipe_dispatcher.h"
#include "mojo/edk/system/platform_handle_dispatcher.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/shared_buffer_dispatcher.h"
#include "mojo/edk/system/test/scoped_test_dir.h"
#include "mojo/edk/system/test/test_io_thread.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/scoped_file.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::FILEFromPlatformHandle;
using mojo::platform::PlatformHandleFromFILE;
using mojo::platform::PlatformPipe;
using mojo::platform::PlatformSharedBufferMapping;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::ThreadSleep;
using mojo::util::MakeRefCounted;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

const MojoHandleSignals kAllSignals = MOJO_HANDLE_SIGNAL_READABLE |
                                      MOJO_HANDLE_SIGNAL_WRITABLE |
                                      MOJO_HANDLE_SIGNAL_PEER_CLOSED;

class RemoteMessagePipeTest : public testing::Test {
 public:
  RemoteMessagePipeTest()
      : platform_support_(embedder::CreateSimplePlatformSupport()),
        io_thread_(test::TestIOThread::StartMode::AUTO) {}
  ~RemoteMessagePipeTest() override {}

  void SetUp() override {
    io_thread_.PostTaskAndWait([this]() { SetUpOnIOThread(); });
  }

  void TearDown() override {
    io_thread_.PostTaskAndWait([this]() { TearDownOnIOThread(); });
  }

 protected:
  // This connects the two given |ChannelEndpoint|s. It assumes/requires that
  // this is the bootstrap case (i.e., no other message pipes have ever been
  // hosted on the channel).
  void BootstrapChannelEndpoints(RefPtr<ChannelEndpoint>&& ep0,
                                 RefPtr<ChannelEndpoint>&& ep1) {
    io_thread_.PostTaskAndWait([this, &ep0, &ep1]() {
      BootstrapChannelEndpointsOnIOThread(std::move(ep0), std::move(ep1));
    });
  }

  // This bootstraps |ep| on |channels_[channel_index]|. It assumes/requires
  // that this is the bootstrap case (i.e., no message pipes have ever been
  // hosted on the channel). This returns *without* waiting.
  void BootstrapChannelEndpointNoWait(unsigned channel_index,
                                      RefPtr<ChannelEndpoint>&& ep) {
    // Note: We have to copy |ep| here, since we're not waiting for it.
    // TODO(vtl): With C++14 lambda captures, we'll be able to move it.
    io_thread_.PostTask([this, channel_index, ep]() mutable {
      BootstrapChannelEndpointOnIOThread(channel_index, std::move(ep));
    });
  }

  void RestoreInitialState() {
    io_thread_.PostTaskAndWait([this]() { RestoreInitialStateOnIOThread(); });
  }

  embedder::PlatformSupport* platform_support() {
    return platform_support_.get();
  }
  test::TestIOThread* io_thread() { return &io_thread_; }
  // Warning: It's up to the caller to ensure that the returned channel
  // is/remains valid.
  Channel* channels(size_t i) { return channels_[i].get(); }

 private:
  void SetUpOnIOThread() {
    CHECK(io_thread()->IsCurrentAndRunning());

    PlatformPipe channel_pair;
    platform_handles_[0] = channel_pair.handle0.Pass();
    platform_handles_[1] = channel_pair.handle1.Pass();
  }

  void TearDownOnIOThread() {
    CHECK(io_thread()->IsCurrentAndRunning());

    if (channels_[0]) {
      channels_[0]->Shutdown();
      channels_[0] = nullptr;
    }
    if (channels_[1]) {
      channels_[1]->Shutdown();
      channels_[1] = nullptr;
    }
  }

  void CreateAndInitChannel(unsigned channel_index) {
    CHECK(io_thread()->IsCurrentAndRunning());
    CHECK(channel_index == 0 || channel_index == 1);
    CHECK(!channels_[channel_index]);

    channels_[channel_index] = MakeRefCounted<Channel>(platform_support_.get());
    channels_[channel_index]->Init(
        io_thread()->task_runner().Clone(),
        io_thread()->platform_handle_watcher(),
        RawChannel::Create(platform_handles_[channel_index].Pass()));
  }

  void BootstrapChannelEndpointsOnIOThread(RefPtr<ChannelEndpoint>&& ep0,
                                           RefPtr<ChannelEndpoint>&& ep1) {
    CHECK(io_thread()->IsCurrentAndRunning());

    if (!channels_[0])
      CreateAndInitChannel(0);
    if (!channels_[1])
      CreateAndInitChannel(1);

    channels_[0]->SetBootstrapEndpoint(std::move(ep0));
    channels_[1]->SetBootstrapEndpoint(std::move(ep1));
  }

  void BootstrapChannelEndpointOnIOThread(unsigned channel_index,
                                          RefPtr<ChannelEndpoint>&& ep) {
    CHECK(io_thread()->IsCurrentAndRunning());
    CHECK(channel_index == 0 || channel_index == 1);

    CreateAndInitChannel(channel_index);
    channels_[channel_index]->SetBootstrapEndpoint(std::move(ep));
  }

  void RestoreInitialStateOnIOThread() {
    CHECK(io_thread()->IsCurrentAndRunning());

    TearDownOnIOThread();
    SetUpOnIOThread();
  }

  std::unique_ptr<embedder::PlatformSupport> platform_support_;
  test::TestIOThread io_thread_;
  ScopedPlatformHandle platform_handles_[2];
  RefPtr<Channel> channels_[2];

  MOJO_DISALLOW_COPY_AND_ASSIGN(RemoteMessagePipeTest);
};

TEST_F(RemoteMessagePipeTest, Basic) {
  static const char kHello[] = "hello";
  static const char kWorld[] = "world!!!1!!!1!";
  char buffer[100] = {0};
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // Connect message pipes. MP 0, port 1 will be attached to channel 0 and
  // connected to MP 1, port 0, which will be attached to channel 1. This leaves
  // MP 0, port 0 and MP 1, port 1 as the "user-facing" endpoints.

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // Write in one direction: MP 0, port 0 -> ... -> MP 1, port 1.

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Write to MP 0, port 0.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                        nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 1, port 1.
  EXPECT_EQ(MOJO_RESULT_OK,
            mp1->ReadMessage(1, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(buffer_size));
  EXPECT_STREQ(kHello, buffer);

  // Write in the other direction: MP 1, port 1 -> ... -> MP 0, port 0.

  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp0->AddAwakable(0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 456, nullptr));

  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp1->WriteMessage(1, UserPointer<const void>(kWorld), sizeof(kWorld),
                        nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(456u, context);
  hss = HandleSignalsState();
  mp0->RemoveAwakable(0, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            mp0->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kWorld), static_cast<size_t>(buffer_size));
  EXPECT_STREQ(kWorld, buffer);

  // Close MP 0, port 0.
  mp0->Close(0);

  // Try to wait for MP 1, port 1 to become readable. This will eventually fail
  // when it realizes that MP 0, port 0 has been closed. (It may also fail
  // immediately.)
  waiter.Init();
  hss = HandleSignalsState();
  MojoResult result =
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 789, &hss);
  if (result == MOJO_RESULT_OK) {
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
    EXPECT_EQ(789u, context);
    hss = HandleSignalsState();
    mp1->RemoveAwakable(1, &waiter, &hss);
  }
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  // And MP 1, port 1.
  mp1->Close(1);
}

TEST_F(RemoteMessagePipeTest, PeerClosed) {
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // Connect message pipes. MP 0, port 1 will be attached to channel 0 and
  // connected to MP 1, port 0, which will be attached to channel 1. This leaves
  // MP 0, port 0 and MP 1, port 1 as the "user-facing" endpoints.

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // Close MP 0, port 0.
  mp0->Close(0);

  // Try to wait for MP 1, port 1 to be signaled with peer closed.
  waiter.Init();
  hss = HandleSignalsState();
  MojoResult result =
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_PEER_CLOSED, 101, &hss);
  if (result == MOJO_RESULT_OK) {
    EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
    EXPECT_EQ(101u, context);
    hss = HandleSignalsState();
    mp1->RemoveAwakable(1, &waiter, &hss);
  }
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  // And MP 1, port 1.
  mp1->Close(1);
}

TEST_F(RemoteMessagePipeTest, Multiplex) {
  static const char kHello[] = "hello";
  static const char kWorld[] = "world!!!1!!!1!";
  char buffer[100] = {0};
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // Connect message pipes as in the |Basic| test.

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // Now put another message pipe on the channel.

  // Do this by creating a message pipe (for the |channels(0)| side) and
  // attaching and running it, yielding the remote ID. A message is then sent
  // via |ep0| (i.e., sent using |mp0|, port 0) with this remote ID. Upon
  // receiving this message, |PassIncomingMessagePipe()| is used to obtain the
  // message pipe on the other side.
  auto mp2 = MessagePipe::CreateLocalLocal();
  ASSERT_TRUE(channels(0));
  size_t max_endpoint_info_size;
  size_t max_platform_handle_count;
  mp2->StartSerialize(1, channels(0), &max_endpoint_info_size,
                      &max_platform_handle_count);
  EXPECT_GT(max_endpoint_info_size, 0u);
  ASSERT_EQ(0u, max_platform_handle_count);
  std::unique_ptr<char[]> endpoint_info(new char[max_endpoint_info_size]);
  size_t endpoint_info_size;
  mp2->EndSerialize(1, channels(0), endpoint_info.get(), &endpoint_info_size,
                    nullptr);
  EXPECT_EQ(max_endpoint_info_size, endpoint_info_size);

  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  EXPECT_EQ(MOJO_RESULT_OK,
            mp0->WriteMessage(0, UserPointer<const void>(endpoint_info.get()),
                              static_cast<uint32_t>(endpoint_info_size),
                              nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  EXPECT_EQ(endpoint_info_size, channels(1)->GetSerializedEndpointSize());
  std::unique_ptr<char[]> received_endpoint_info(new char[endpoint_info_size]);
  buffer_size = static_cast<uint32_t>(endpoint_info_size);
  EXPECT_EQ(MOJO_RESULT_OK,
            mp1->ReadMessage(1, UserPointer<void>(received_endpoint_info.get()),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(endpoint_info_size, static_cast<size_t>(buffer_size));
  EXPECT_EQ(0, memcmp(received_endpoint_info.get(), endpoint_info.get(),
                      endpoint_info_size));

  // Warning: The local side of mp3 is port 0, not port 1.
  RefPtr<IncomingEndpoint> incoming_endpoint =
      channels(1)->DeserializeEndpoint(received_endpoint_info.get());
  ASSERT_TRUE(incoming_endpoint);
  RefPtr<MessagePipe> mp3 = incoming_endpoint->ConvertToMessagePipe();
  ASSERT_TRUE(mp3);

  // Write: MP 2, port 0 -> MP 3, port 1.

  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp3->AddAwakable(0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 789, nullptr));

  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp2->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                        nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(789u, context);
  hss = HandleSignalsState();
  mp3->RemoveAwakable(0, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Make sure there's nothing on MP 0, port 0 or MP 1, port 1 or MP 2, port 0.
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp0->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp1->ReadMessage(1, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp2->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));

  // Read from MP 3, port 1.
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            mp3->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(buffer_size));
  EXPECT_STREQ(kHello, buffer);

  // Write: MP 0, port 0 -> MP 1, port 1 again.

  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp0->WriteMessage(0, UserPointer<const void>(kWorld), sizeof(kWorld),
                        nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Make sure there's nothing on the other ports.
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp0->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp2->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp3->ReadMessage(0, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));

  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            mp1->ReadMessage(1, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kWorld), static_cast<size_t>(buffer_size));
  EXPECT_STREQ(kWorld, buffer);

  mp0->Close(0);
  mp1->Close(1);
  mp2->Close(0);
  mp3->Close(0);
}

TEST_F(RemoteMessagePipeTest, CloseBeforeAttachAndRun) {
  static const char kHello[] = "hello";
  char buffer[100] = {0};
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // Connect message pipes. MP 0, port 1 will be attached to channel 0 and
  // connected to MP 1, port 0, which will be attached to channel 1. This leaves
  // MP 0, port 0 and MP 1, port 1 as the "user-facing" endpoints.

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);

  // Write to MP 0, port 0.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                        nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Close MP 0, port 0 before it's even been attached to the channel and run.
  mp0->Close(0);

  BootstrapChannelEndpointNoWait(0, std::move(ep0));

  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  BootstrapChannelEndpointNoWait(1, std::move(ep1));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  // Note: MP 1, port 1 should definitely should be readable, but it may or may
  // not appear as writable (there's a race, and it may not have noticed that
  // the other side was closed yet -- e.g., inserting a sleep here would make it
  // much more likely to notice that it's no longer writable).
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
  EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

  // Read from MP 1, port 1.
  EXPECT_EQ(MOJO_RESULT_OK,
            mp1->ReadMessage(1, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(buffer_size));
  EXPECT_STREQ(kHello, buffer);

  // And MP 1, port 1.
  mp1->Close(1);
}

TEST_F(RemoteMessagePipeTest, CloseBeforeConnect) {
  static const char kHello[] = "hello";
  char buffer[100] = {0};
  uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // Connect message pipes. MP 0, port 1 will be attached to channel 0 and
  // connected to MP 1, port 0, which will be attached to channel 1. This leaves
  // MP 0, port 0 and MP 1, port 1 as the "user-facing" endpoints.

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);

  // Write to MP 0, port 0.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                        nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  BootstrapChannelEndpointNoWait(0, std::move(ep0));

  // Close MP 0, port 0 before channel 1 is even connected.
  mp0->Close(0);

  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  BootstrapChannelEndpointNoWait(1, std::move(ep1));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  // Note: MP 1, port 1 should definitely should be readable, but it may or may
  // not appear as writable (there's a race, and it may not have noticed that
  // the other side was closed yet -- e.g., inserting a sleep here would make it
  // much more likely to notice that it's no longer writable).
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
  EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

  // Read from MP 1, port 1.
  EXPECT_EQ(MOJO_RESULT_OK,
            mp1->ReadMessage(1, UserPointer<void>(buffer),
                             MakeUserPointer(&buffer_size), nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(buffer_size));
  EXPECT_STREQ(kHello, buffer);

  // And MP 1, port 1.
  mp1->Close(1);
}

TEST_F(RemoteMessagePipeTest, HandlePassing) {
  static const char kHello[] = "hello";
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // We'll try to pass this dispatcher.
  auto dispatcher = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  auto local_mp = MessagePipe::CreateLocalLocal();
  dispatcher->Init(local_mp.Clone(), 0);

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Write to MP 0, port 0.
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(
        MOJO_RESULT_OK,
        mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                          &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |dispatcher| should have been closed. This is |DCHECK()|ed when the
    // |dispatcher| is destroyed.
    EXPECT_TRUE(dispatcher->HasOneRef());
    dispatcher = nullptr;
  }

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 1, port 1.
  char read_buffer[100] = {0};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  DispatcherVector read_dispatchers;
  uint32_t read_num_dispatchers = 10;  // Maximum to get.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp1->ReadMessage(1, UserPointer<void>(read_buffer),
                       MakeUserPointer(&read_buffer_size), &read_dispatchers,
                       &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::MESSAGE_PIPE, read_dispatchers[0]->GetType());
  dispatcher = RefPtr<MessagePipeDispatcher>(
      static_cast<MessagePipeDispatcher*>(read_dispatchers[0].get()));

  // Add the waiter now, before it becomes readable to avoid a race.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            dispatcher->AddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE, 456,
                                    nullptr));

  // Write to "local_mp", port 1.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      local_mp->WriteMessage(1, UserPointer<const void>(kHello), sizeof(kHello),
                             nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // TODO(vtl): FIXME -- We (racily) crash if I close |dispatcher| immediately
  // here. (We don't crash if I sleep and then close.)

  // Wait for the dispatcher to become readable.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(456u, context);
  hss = HandleSignalsState();
  dispatcher->RemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from the dispatcher.
  memset(read_buffer, 0, sizeof(read_buffer));
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->ReadMessage(UserPointer<void>(read_buffer),
                                    MakeUserPointer(&read_buffer_size), 0,
                                    nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);

  // Prepare to wait on "local_mp", port 1.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            local_mp->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 789,
                                  nullptr));

  // Write to the dispatcher.
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->WriteMessage(
                                UserPointer<const void>(kHello), sizeof(kHello),
                                nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(789u, context);
  hss = HandleSignalsState();
  local_mp->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from "local_mp", port 1.
  memset(read_buffer, 0, sizeof(read_buffer));
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            local_mp->ReadMessage(1, UserPointer<void>(read_buffer),
                                  MakeUserPointer(&read_buffer_size), nullptr,
                                  nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);

  // TODO(vtl): Also test that messages queued up before the handle was sent are
  // delivered properly.

  // Close everything that belongs to us.
  mp0->Close(0);
  mp1->Close(1);
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
  // Note that |local_mp|'s port 0 belong to |dispatcher|, which was closed.
  local_mp->Close(1);
}

TEST_F(RemoteMessagePipeTest, HandlePassingHalfClosed) {
  static const char kHello[] = "hello";
  static const char kWorld[] = "world!";
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  // We'll try to pass this dispatcher.
  auto dispatcher = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  auto local_mp = MessagePipe::CreateLocalLocal();
  dispatcher->Init(local_mp.Clone(), 0);

  hss = local_mp->GetHandleSignalsState(0);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  // Write to the other end (|local_mp|, port 1), and then close it.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      local_mp->WriteMessage(1, UserPointer<const void>(kHello), sizeof(kHello),
                             nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = local_mp->GetHandleSignalsState(0);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  // Then the second message....
  EXPECT_EQ(
      MOJO_RESULT_OK,
      local_mp->WriteMessage(1, UserPointer<const void>(kWorld), sizeof(kWorld),
                             nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = local_mp->GetHandleSignalsState(0);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  // Then close it.
  local_mp->Close(1);

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Write to MP 0, port 0.
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(
        MOJO_RESULT_OK,
        mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                          &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |dispatcher| should have been closed. This is |DCHECK()|ed when the
    // |dispatcher| is destroyed.
    EXPECT_TRUE(dispatcher->HasOneRef());
    dispatcher = nullptr;
  }

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 1, port 1.
  char read_buffer[100] = {0};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  DispatcherVector read_dispatchers;
  uint32_t read_num_dispatchers = 10;  // Maximum to get.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp1->ReadMessage(1, UserPointer<void>(read_buffer),
                       MakeUserPointer(&read_buffer_size), &read_dispatchers,
                       &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::MESSAGE_PIPE, read_dispatchers[0]->GetType());
  dispatcher = RefPtr<MessagePipeDispatcher>(
      static_cast<MessagePipeDispatcher*>(read_dispatchers[0].get()));

  // |dispatcher| should already be readable and not writable.
  hss = dispatcher->GetHandleSignalsState();
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);
  // So read from it.
  memset(read_buffer, 0, sizeof(read_buffer));
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->ReadMessage(UserPointer<void>(read_buffer),
                                    MakeUserPointer(&read_buffer_size), 0,
                                    nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);
  // It should still be readable.
  hss = dispatcher->GetHandleSignalsState();
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);
  // So read from it.
  memset(read_buffer, 0, sizeof(read_buffer));
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->ReadMessage(UserPointer<void>(read_buffer),
                                    MakeUserPointer(&read_buffer_size), 0,
                                    nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kWorld), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kWorld, read_buffer);
  // Now it should no longer be readable.
  hss = dispatcher->GetHandleSignalsState();
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  // Close everything that belongs to us.
  mp0->Close(0);
  mp1->Close(1);
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
}

TEST_F(RemoteMessagePipeTest, SharedBufferPassing) {
  static const char kHello[] = "hello";
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // We'll try to pass this dispatcher.
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 100,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);
  ASSERT_TRUE(dispatcher);

  // Make a mapping.
  std::unique_ptr<PlatformSharedBufferMapping> mapping0;
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->MapBuffer(
                                0, 100, MOJO_MAP_BUFFER_FLAG_NONE, &mapping0));
  ASSERT_TRUE(mapping0);
  ASSERT_TRUE(mapping0->GetBase());
  ASSERT_EQ(100u, mapping0->GetLength());
  static_cast<char*>(mapping0->GetBase())[0] = 'A';
  static_cast<char*>(mapping0->GetBase())[50] = 'B';
  static_cast<char*>(mapping0->GetBase())[99] = 'C';

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Write to MP 0, port 0.
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(
        MOJO_RESULT_OK,
        mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                          &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |dispatcher| should have been closed. This is |DCHECK()|ed when the
    // |dispatcher| is destroyed.
    EXPECT_TRUE(dispatcher->HasOneRef());
    dispatcher = nullptr;
  }

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 1, port 1.
  char read_buffer[100] = {0};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  DispatcherVector read_dispatchers;
  uint32_t read_num_dispatchers = 10;  // Maximum to get.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp1->ReadMessage(1, UserPointer<void>(read_buffer),
                       MakeUserPointer(&read_buffer_size), &read_dispatchers,
                       &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::SHARED_BUFFER, read_dispatchers[0]->GetType());
  dispatcher = RefPtr<SharedBufferDispatcher>(
      static_cast<SharedBufferDispatcher*>(read_dispatchers[0].get()));

  // Make another mapping.
  std::unique_ptr<PlatformSharedBufferMapping> mapping1;
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->MapBuffer(
                                0, 100, MOJO_MAP_BUFFER_FLAG_NONE, &mapping1));
  ASSERT_TRUE(mapping1);
  ASSERT_TRUE(mapping1->GetBase());
  ASSERT_EQ(100u, mapping1->GetLength());
  EXPECT_NE(mapping1->GetBase(), mapping0->GetBase());
  EXPECT_EQ('A', static_cast<char*>(mapping1->GetBase())[0]);
  EXPECT_EQ('B', static_cast<char*>(mapping1->GetBase())[50]);
  EXPECT_EQ('C', static_cast<char*>(mapping1->GetBase())[99]);

  // Write stuff either way.
  static_cast<char*>(mapping1->GetBase())[1] = 'x';
  EXPECT_EQ('x', static_cast<char*>(mapping0->GetBase())[1]);
  static_cast<char*>(mapping0->GetBase())[2] = 'y';
  EXPECT_EQ('y', static_cast<char*>(mapping1->GetBase())[2]);

  // Kill the first mapping; the second should still be valid.
  mapping0.reset();
  EXPECT_EQ('A', static_cast<char*>(mapping1->GetBase())[0]);

  // Close everything that belongs to us.
  mp0->Close(0);
  mp1->Close(1);
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());

  // The second mapping should still be good.
  EXPECT_EQ('x', static_cast<char*>(mapping1->GetBase())[1]);
}

TEST_F(RemoteMessagePipeTest, PlatformHandlePassing) {
  test::ScopedTestDir test_dir;

  static const char kHello[] = "hello";
  static const char kWorld[] = "world";
  Waiter waiter;
  uint32_t context = 0;
  HandleSignalsState hss;

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  util::ScopedFILE fp(test_dir.CreateFile());
  EXPECT_EQ(sizeof(kHello), fwrite(kHello, 1, sizeof(kHello), fp.get()));
  // We'll try to pass this dispatcher, which will cause a |PlatformHandle| to
  // be passed.
  auto dispatcher =
      PlatformHandleDispatcher::Create(PlatformHandleFromFILE(std::move(fp)));

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Write to MP 0, port 0.
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(
        MOJO_RESULT_OK,
        mp0->WriteMessage(0, UserPointer<const void>(kWorld), sizeof(kWorld),
                          &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |dispatcher| should have been closed. This is |DCHECK()|ed when the
    // |dispatcher| is destroyed.
    EXPECT_TRUE(dispatcher->HasOneRef());
    dispatcher = nullptr;
  }

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 1, port 1.
  char read_buffer[100] = {0};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  DispatcherVector read_dispatchers;
  uint32_t read_num_dispatchers = 10;  // Maximum to get.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp1->ReadMessage(1, UserPointer<void>(read_buffer),
                       MakeUserPointer(&read_buffer_size), &read_dispatchers,
                       &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kWorld), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kWorld, read_buffer);
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::PLATFORM_HANDLE, read_dispatchers[0]->GetType());
  dispatcher = RefPtr<PlatformHandleDispatcher>(
      static_cast<PlatformHandleDispatcher*>(read_dispatchers[0].get()));

  ScopedPlatformHandle h = dispatcher->PassPlatformHandle();
  EXPECT_TRUE(h.is_valid());

  fp = FILEFromPlatformHandle(h.Pass(), "rb");
  EXPECT_FALSE(h.is_valid());
  EXPECT_TRUE(fp);

  rewind(fp.get());
  memset(read_buffer, 0, sizeof(read_buffer));
  EXPECT_EQ(sizeof(kHello),
            fread(read_buffer, 1, sizeof(read_buffer), fp.get()));
  EXPECT_STREQ(kHello, read_buffer);

  // Close everything that belongs to us.
  mp0->Close(0);
  mp1->Close(1);
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
}

// Test racing closes (on each end).
// Note: A flaky failure would almost certainly indicate a problem in the code
// itself (not in the test). Also, any logged warnings/errors would also
// probably be indicative of bugs.
TEST_F(RemoteMessagePipeTest, RacingClosesStress) {
  MojoDeadline delay = test::DeadlineFromMilliseconds(5u);

  for (unsigned i = 0; i < 256; i++) {
    DVLOG(2) << "---------------------------------------- " << i;
    RefPtr<ChannelEndpoint> ep0;
    auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
    BootstrapChannelEndpointNoWait(0, std::move(ep0));

    RefPtr<ChannelEndpoint> ep1;
    auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
    BootstrapChannelEndpointNoWait(1, std::move(ep1));

    if (i & 1u) {
      io_thread()->PostTask([delay]() { ThreadSleep(delay); });
    }
    if (i & 2u)
      ThreadSleep(delay);

    mp0->Close(0);

    if (i & 4u) {
      io_thread()->PostTask([delay]() { ThreadSleep(delay); });
    }
    if (i & 8u)
      ThreadSleep(delay);

    mp1->Close(1);

    RestoreInitialState();
  }
}

// Tests passing an end of a message pipe over a remote message pipe, and then
// passing that end back.
// TODO(vtl): Also test passing a message pipe across two remote message pipes.
TEST_F(RemoteMessagePipeTest, PassMessagePipeHandleAcrossAndBack) {
  static const char kHello[] = "hello";
  static const char kWorld[] = "world";
  Waiter waiter;
  HandleSignalsState hss;
  uint32_t context = 0;

  RefPtr<ChannelEndpoint> ep0;
  auto mp0 = MessagePipe::CreateLocalProxy(&ep0);
  RefPtr<ChannelEndpoint> ep1;
  auto mp1 = MessagePipe::CreateProxyLocal(&ep1);
  BootstrapChannelEndpoints(std::move(ep0), std::move(ep1));

  // We'll try to pass this dispatcher.
  auto dispatcher = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  auto local_mp = MessagePipe::CreateLocalLocal();
  dispatcher->Init(local_mp.Clone(), 0);

  // Prepare to wait on MP 1, port 1. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp1->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 123, nullptr));

  // Write to MP 0, port 0.
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(
        MOJO_RESULT_OK,
        mp0->WriteMessage(0, UserPointer<const void>(kHello), sizeof(kHello),
                          &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |dispatcher| should have been closed. This is |DCHECK()|ed when the
    // |dispatcher| is destroyed.
    EXPECT_TRUE(dispatcher->HasOneRef());
    dispatcher = nullptr;
  }

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(123u, context);
  hss = HandleSignalsState();
  mp1->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 1, port 1.
  char read_buffer[100] = {0};
  uint32_t read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  DispatcherVector read_dispatchers;
  uint32_t read_num_dispatchers = 10;  // Maximum to get.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp1->ReadMessage(1, UserPointer<void>(read_buffer),
                       MakeUserPointer(&read_buffer_size), &read_dispatchers,
                       &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::MESSAGE_PIPE, read_dispatchers[0]->GetType());
  dispatcher = RefPtr<MessagePipeDispatcher>(
      static_cast<MessagePipeDispatcher*>(read_dispatchers[0].get()));
  read_dispatchers.clear();

  // Now pass it back.

  // Prepare to wait on MP 0, port 0. (Add the waiter now. Otherwise, if we do
  // it later, it might already be readable.)
  waiter.Init();
  ASSERT_EQ(
      MOJO_RESULT_OK,
      mp0->AddAwakable(0, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 456, nullptr));

  // Write to MP 1, port 1.
  {
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    EXPECT_TRUE(transport.is_valid());

    std::vector<DispatcherTransport> transports;
    transports.push_back(transport);
    EXPECT_EQ(
        MOJO_RESULT_OK,
        mp1->WriteMessage(1, UserPointer<const void>(kWorld), sizeof(kWorld),
                          &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));
    transport.End();

    // |dispatcher| should have been closed. This is |DCHECK()|ed when the
    // |dispatcher| is destroyed.
    EXPECT_TRUE(dispatcher->HasOneRef());
    dispatcher = nullptr;
  }

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(456u, context);
  hss = HandleSignalsState();
  mp0->RemoveAwakable(0, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from MP 0, port 0.
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  read_num_dispatchers = 10;  // Maximum to get.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      mp0->ReadMessage(0, UserPointer<void>(read_buffer),
                       MakeUserPointer(&read_buffer_size), &read_dispatchers,
                       &read_num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kWorld), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kWorld, read_buffer);
  EXPECT_EQ(1u, read_dispatchers.size());
  EXPECT_EQ(1u, read_num_dispatchers);
  ASSERT_TRUE(read_dispatchers[0]);
  EXPECT_TRUE(read_dispatchers[0]->HasOneRef());

  EXPECT_EQ(Dispatcher::Type::MESSAGE_PIPE, read_dispatchers[0]->GetType());
  dispatcher = RefPtr<MessagePipeDispatcher>(
      static_cast<MessagePipeDispatcher*>(read_dispatchers[0].get()));
  read_dispatchers.clear();

  // Add the waiter now, before it becomes readable to avoid a race.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            dispatcher->AddAwakable(&waiter, MOJO_HANDLE_SIGNAL_READABLE, 789,
                                    nullptr));

  // Write to "local_mp", port 1.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      local_mp->WriteMessage(1, UserPointer<const void>(kHello), sizeof(kHello),
                             nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait for the dispatcher to become readable.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(789u, context);
  hss = HandleSignalsState();
  dispatcher->RemoveAwakable(&waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from the dispatcher.
  memset(read_buffer, 0, sizeof(read_buffer));
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->ReadMessage(UserPointer<void>(read_buffer),
                                    MakeUserPointer(&read_buffer_size), 0,
                                    nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);

  // Prepare to wait on "local_mp", port 1.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            local_mp->AddAwakable(1, &waiter, MOJO_HANDLE_SIGNAL_READABLE, 789,
                                  nullptr));

  // Write to the dispatcher.
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->WriteMessage(
                                UserPointer<const void>(kHello), sizeof(kHello),
                                nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait.
  EXPECT_EQ(MOJO_RESULT_OK, waiter.Wait(MOJO_DEADLINE_INDEFINITE, &context));
  EXPECT_EQ(789u, context);
  hss = HandleSignalsState();
  local_mp->RemoveAwakable(1, &waiter, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Read from "local_mp", port 1.
  memset(read_buffer, 0, sizeof(read_buffer));
  read_buffer_size = static_cast<uint32_t>(sizeof(read_buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            local_mp->ReadMessage(1, UserPointer<void>(read_buffer),
                                  MakeUserPointer(&read_buffer_size), nullptr,
                                  nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), static_cast<size_t>(read_buffer_size));
  EXPECT_STREQ(kHello, read_buffer);

  // TODO(vtl): Also test the cases where messages are written and read (at
  // various points) on the message pipe being passed around.

  // Close everything that belongs to us.
  mp0->Close(0);
  mp1->Close(1);
  EXPECT_EQ(MOJO_RESULT_OK, dispatcher->Close());
  // Note that |local_mp|'s port 0 belong to |dispatcher|, which was closed.
  local_mp->Close(1);
}

}  // namespace
}  // namespace system
}  // namespace mojo
