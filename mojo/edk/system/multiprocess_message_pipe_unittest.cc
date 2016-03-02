// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "build/build_config.h"  // TODO(vtl): Remove this.
#include "mojo/edk/embedder/simple_platform_support.h"
#include "mojo/edk/platform/platform_handle_utils_posix.h"
#include "mojo/edk/platform/platform_shared_buffer.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/system/channel.h"
#include "mojo/edk/system/dispatcher.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/message_pipe_test_utils.h"
#include "mojo/edk/system/platform_handle_dispatcher.h"
#include "mojo/edk/system/raw_channel.h"
#include "mojo/edk/system/shared_buffer_dispatcher.h"
#include "mojo/edk/system/test/scoped_test_dir.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/scoped_file.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::FILEFromPlatformHandle;
using mojo::platform::PlatformHandleFromFILE;
using mojo::platform::PlatformSharedBufferMapping;
using mojo::platform::ScopedPlatformHandle;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

class MultiprocessMessagePipeTest
    : public test::MultiprocessMessagePipeTestBase {};

// For each message received, sends a reply message with the same contents
// repeated twice, until the other end is closed or it receives "quitquitquit"
// (which it doesn't reply to). It'll return the number of messages received,
// not including any "quitquitquit" message, modulo 100.
MOJO_MULTIPROCESS_TEST_CHILD_MAIN(EchoEcho) {
  std::unique_ptr<embedder::PlatformSupport> platform_support(
      embedder::CreateSimplePlatformSupport());
  test::ChannelThread channel_thread(platform_support.get());
  ScopedPlatformHandle client_platform_handle =
      mojo::test::MultiprocessTestHelper::client_platform_handle.Pass();
  CHECK(client_platform_handle.is_valid());
  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  channel_thread.Start(client_platform_handle.Pass(), std::move(ep));

  const std::string quitquitquit("quitquitquit");
  int rv = 0;
  for (;; rv = (rv + 1) % 100) {
    // Wait for our end of the message pipe to be readable.
    HandleSignalsState hss;
    MojoResult result =
        test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss);
    if (result != MOJO_RESULT_OK) {
      // It was closed, probably.
      CHECK_EQ(result, MOJO_RESULT_FAILED_PRECONDITION);
      CHECK_EQ(hss.satisfied_signals, MOJO_HANDLE_SIGNAL_PEER_CLOSED);
      CHECK_EQ(hss.satisfiable_signals, MOJO_HANDLE_SIGNAL_PEER_CLOSED);
      break;
    } else {
      CHECK((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
      CHECK((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));
    }

    std::string read_buffer(1000, '\0');
    uint32_t read_buffer_size = static_cast<uint32_t>(read_buffer.size());
    CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                             MakeUserPointer(&read_buffer_size), nullptr,
                             nullptr, MOJO_READ_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
    read_buffer.resize(read_buffer_size);
    VLOG(2) << "Child got: " << read_buffer;

    if (read_buffer == quitquitquit) {
      VLOG(2) << "Child quitting.";
      break;
    }

    std::string write_buffer = read_buffer + read_buffer;
    CHECK_EQ(mp->WriteMessage(0, UserPointer<const void>(write_buffer.data()),
                              static_cast<uint32_t>(write_buffer.size()),
                              nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
  }

  mp->Close(0);
  return rv;
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_Basic DISABLED_Basic
#else
#define MAYBE_Basic Basic
#endif
// Sends "hello" to child, and expects "hellohello" back.
TEST_F(MultiprocessMessagePipeTest, MAYBE_Basic) {
  helper()->StartChild("EchoEcho");

  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  Init(std::move(ep));

  std::string hello("hello");
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(hello.data()),
                             static_cast<uint32_t>(hello.size()), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  HandleSignalsState hss;
  EXPECT_EQ(MOJO_RESULT_OK,
            test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss));
  // The child may or may not have closed its end of the message pipe and died
  // (and we may or may not know it yet), so our end may or may not appear as
  // writable.
  EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
  EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

  std::string read_buffer(1000, '\0');
  uint32_t read_buffer_size = static_cast<uint32_t>(read_buffer.size());
  CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                           MakeUserPointer(&read_buffer_size), nullptr, nullptr,
                           MOJO_READ_MESSAGE_FLAG_NONE),
           MOJO_RESULT_OK);
  read_buffer.resize(read_buffer_size);
  VLOG(2) << "Parent got: " << read_buffer;
  EXPECT_EQ(hello + hello, read_buffer);

  mp->Close(0);

  // We sent one message.
  EXPECT_EQ(1 % 100, helper()->WaitForChildShutdown());
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_QueueMessages DISABLED_QueueMessages
#else
#define MAYBE_QueueMessages QueueMessages
#endif
// Sends a bunch of messages to the child. Expects them "repeated" back. Waits
// for the child to close its end before quitting.
TEST_F(MultiprocessMessagePipeTest, DISABLED_QueueMessages) {
  helper()->StartChild("EchoEcho");

  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  Init(std::move(ep));

  static const size_t kNumMessages = 1001;
  for (size_t i = 0; i < kNumMessages; i++) {
    std::string write_buffer(i, 'A' + (i % 26));
    EXPECT_EQ(MOJO_RESULT_OK,
              mp->WriteMessage(0, UserPointer<const void>(write_buffer.data()),
                               static_cast<uint32_t>(write_buffer.size()),
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
  }

  const std::string quitquitquit("quitquitquit");
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(quitquitquit.data()),
                             static_cast<uint32_t>(quitquitquit.size()),
                             nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  for (size_t i = 0; i < kNumMessages; i++) {
    HandleSignalsState hss;
    EXPECT_EQ(MOJO_RESULT_OK, test::WaitIfNecessary(
                                  mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss));
    // The child may or may not have closed its end of the message pipe and died
    // (and we may or may not know it yet), so our end may or may not appear as
    // writable.
    EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
    EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

    std::string read_buffer(kNumMessages * 2, '\0');
    uint32_t read_buffer_size = static_cast<uint32_t>(read_buffer.size());
    CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                             MakeUserPointer(&read_buffer_size), nullptr,
                             nullptr, MOJO_READ_MESSAGE_FLAG_NONE),
             MOJO_RESULT_OK);
    read_buffer.resize(read_buffer_size);

    EXPECT_EQ(std::string(i * 2, 'A' + (i % 26)), read_buffer);
  }

  // Wait for it to become readable, which should fail (since we sent
  // "quitquitquit").
  HandleSignalsState hss;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  mp->Close(0);

  EXPECT_EQ(static_cast<int>(kNumMessages % 100),
            helper()->WaitForChildShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_MAIN(CheckSharedBuffer) {
  std::unique_ptr<embedder::PlatformSupport> platform_support(
      embedder::CreateSimplePlatformSupport());
  test::ChannelThread channel_thread(platform_support.get());
  ScopedPlatformHandle client_platform_handle =
      mojo::test::MultiprocessTestHelper::client_platform_handle.Pass();
  CHECK(client_platform_handle.is_valid());
  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  channel_thread.Start(client_platform_handle.Pass(), std::move(ep));

  // Wait for the first message from our parent.
  HandleSignalsState hss;
  CHECK_EQ(test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss),
           MOJO_RESULT_OK);
  // In this test, the parent definitely doesn't close its end of the message
  // pipe before we do.
  CHECK_EQ(hss.satisfied_signals,
           MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
  CHECK_EQ(hss.satisfiable_signals, MOJO_HANDLE_SIGNAL_READABLE |
                                        MOJO_HANDLE_SIGNAL_WRITABLE |
                                        MOJO_HANDLE_SIGNAL_PEER_CLOSED);

  // It should have a shared buffer.
  std::string read_buffer(100, '\0');
  uint32_t num_bytes = static_cast<uint32_t>(read_buffer.size());
  DispatcherVector dispatchers;
  uint32_t num_dispatchers = 10;  // Maximum number to receive.
  CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                           MakeUserPointer(&num_bytes), &dispatchers,
                           &num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE),
           MOJO_RESULT_OK);
  read_buffer.resize(num_bytes);
  CHECK_EQ(read_buffer, std::string("go 1"));
  CHECK_EQ(num_dispatchers, 1u);

  CHECK_EQ(dispatchers[0]->GetType(), Dispatcher::Type::SHARED_BUFFER);

  RefPtr<SharedBufferDispatcher> dispatcher(
      static_cast<SharedBufferDispatcher*>(dispatchers[0].get()));

  // Make a mapping.
  std::unique_ptr<PlatformSharedBufferMapping> mapping;
  CHECK_EQ(dispatcher->MapBuffer(0, 100, MOJO_MAP_BUFFER_FLAG_NONE, &mapping),
           MOJO_RESULT_OK);
  CHECK(mapping);
  CHECK(mapping->GetBase());
  CHECK_EQ(mapping->GetLength(), 100u);

  // Write some stuff to the shared buffer.
  static const char kHello[] = "hello";
  memcpy(mapping->GetBase(), kHello, sizeof(kHello));

  // We should be able to close the dispatcher now.
  dispatcher->Close();

  // And send a message to signal that we've written stuff.
  const std::string go2("go 2");
  CHECK_EQ(mp->WriteMessage(0, UserPointer<const void>(&go2[0]),
                            static_cast<uint32_t>(go2.size()), nullptr,
                            MOJO_WRITE_MESSAGE_FLAG_NONE),
           MOJO_RESULT_OK);

  // Now wait for our parent to send us a message.
  hss = HandleSignalsState();
  CHECK_EQ(test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss),
           MOJO_RESULT_OK);
  CHECK_EQ(hss.satisfied_signals,
           MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
  CHECK_EQ(hss.satisfiable_signals, MOJO_HANDLE_SIGNAL_READABLE |
                                        MOJO_HANDLE_SIGNAL_WRITABLE |
                                        MOJO_HANDLE_SIGNAL_PEER_CLOSED);

  read_buffer = std::string(100, '\0');
  num_bytes = static_cast<uint32_t>(read_buffer.size());
  CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                           MakeUserPointer(&num_bytes), nullptr, nullptr,
                           MOJO_READ_MESSAGE_FLAG_NONE),
           MOJO_RESULT_OK);
  read_buffer.resize(num_bytes);
  CHECK_EQ(read_buffer, std::string("go 3"));

  // It should have written something to the shared buffer.
  static const char kWorld[] = "world!!!";
  CHECK_EQ(memcmp(mapping->GetBase(), kWorld, sizeof(kWorld)), 0);

  // And we're done.
  mp->Close(0);

  return 0;
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_SharedBufferPassing DISABLED_SharedBufferPassing
#else
#define MAYBE_SharedBufferPassing SharedBufferPassing
#endif
TEST_F(MultiprocessMessagePipeTest, MAYBE_SharedBufferPassing) {
  helper()->StartChild("CheckSharedBuffer");

  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  Init(std::move(ep));

  // Make a shared buffer.
  MojoResult result = MOJO_RESULT_INTERNAL;
  auto dispatcher = SharedBufferDispatcher::Create(
      platform_support(), SharedBufferDispatcher::kDefaultCreateOptions, 100,
      &result);
  EXPECT_EQ(MOJO_RESULT_OK, result);
  ASSERT_TRUE(dispatcher);

  // Make a mapping.
  std::unique_ptr<PlatformSharedBufferMapping> mapping;
  EXPECT_EQ(MOJO_RESULT_OK,
            dispatcher->MapBuffer(0, 100, MOJO_MAP_BUFFER_FLAG_NONE, &mapping));
  ASSERT_TRUE(mapping);
  ASSERT_TRUE(mapping->GetBase());
  ASSERT_EQ(100u, mapping->GetLength());

  // Send the shared buffer.
  const std::string go1("go 1");
  DispatcherTransport transport(
      test::DispatcherTryStartTransport(dispatcher.get()));
  ASSERT_TRUE(transport.is_valid());

  std::vector<DispatcherTransport> transports;
  transports.push_back(transport);
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(&go1[0]),
                             static_cast<uint32_t>(go1.size()), &transports,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));
  transport.End();

  EXPECT_TRUE(dispatcher->HasOneRef());
  dispatcher = nullptr;

  // Wait for a message from the child.
  HandleSignalsState hss;
  EXPECT_EQ(MOJO_RESULT_OK,
            test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss));
  EXPECT_TRUE((hss.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE));
  EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

  std::string read_buffer(100, '\0');
  uint32_t num_bytes = static_cast<uint32_t>(read_buffer.size());
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                            MakeUserPointer(&num_bytes), nullptr, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  read_buffer.resize(num_bytes);
  EXPECT_EQ(std::string("go 2"), read_buffer);

  // After we get it, the child should have written something to the shared
  // buffer.
  static const char kHello[] = "hello";
  EXPECT_EQ(0, memcmp(mapping->GetBase(), kHello, sizeof(kHello)));

  // Now we'll write some stuff to the shared buffer.
  static const char kWorld[] = "world!!!";
  memcpy(mapping->GetBase(), kWorld, sizeof(kWorld));

  // And send a message to signal that we've written stuff.
  const std::string go3("go 3");
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(&go3[0]),
                             static_cast<uint32_t>(go3.size()), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait for |mp| to become readable, which should fail.
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  mp->Close(0);

  EXPECT_EQ(0, helper()->WaitForChildShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_MAIN(CheckPlatformHandleFile) {
  std::unique_ptr<embedder::PlatformSupport> platform_support(
      embedder::CreateSimplePlatformSupport());
  test::ChannelThread channel_thread(platform_support.get());
  ScopedPlatformHandle client_platform_handle =
      mojo::test::MultiprocessTestHelper::client_platform_handle.Pass();
  CHECK(client_platform_handle.is_valid());
  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  channel_thread.Start(client_platform_handle.Pass(), std::move(ep));

  HandleSignalsState hss;
  CHECK_EQ(test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss),
           MOJO_RESULT_OK);
  CHECK_EQ(hss.satisfied_signals,
           MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE);
  CHECK_EQ(hss.satisfiable_signals, MOJO_HANDLE_SIGNAL_READABLE |
                                        MOJO_HANDLE_SIGNAL_WRITABLE |
                                        MOJO_HANDLE_SIGNAL_PEER_CLOSED);

  std::string read_buffer(100, '\0');
  uint32_t num_bytes = static_cast<uint32_t>(read_buffer.size());
  DispatcherVector dispatchers;
  uint32_t num_dispatchers = 255;  // Maximum number to receive.
  CHECK_EQ(mp->ReadMessage(0, UserPointer<void>(&read_buffer[0]),
                           MakeUserPointer(&num_bytes), &dispatchers,
                           &num_dispatchers, MOJO_READ_MESSAGE_FLAG_NONE),
           MOJO_RESULT_OK);
  mp->Close(0);

  read_buffer.resize(num_bytes);
  char hello[32];
  int num_handles = 0;
  sscanf(read_buffer.c_str(), "%s %d", hello, &num_handles);
  CHECK_EQ(std::string("hello"), std::string(hello));
  CHECK_GT(num_handles, 0);

  for (int i = 0; i < num_handles; ++i) {
    CHECK_EQ(dispatchers[i]->GetType(), Dispatcher::Type::PLATFORM_HANDLE);

    RefPtr<PlatformHandleDispatcher> dispatcher(
        static_cast<PlatformHandleDispatcher*>(dispatchers[i].get()));
    ScopedPlatformHandle h = dispatcher->PassPlatformHandle();
    CHECK(h.is_valid());
    dispatcher->Close();

    util::ScopedFILE fp(FILEFromPlatformHandle(h.Pass(), "r"));
    CHECK(fp);
    std::string fread_buffer(100, '\0');
    size_t bytes_read =
        fread(&fread_buffer[0], 1, fread_buffer.size(), fp.get());
    fread_buffer.resize(bytes_read);
    CHECK_EQ(fread_buffer, "world");
  }

  return 0;
}

class MultiprocessMessagePipeTestWithPipeCount
    : public test::MultiprocessMessagePipeTestBase,
      public testing::WithParamInterface<size_t> {};

TEST_P(MultiprocessMessagePipeTestWithPipeCount, PlatformHandlePassing) {
  test::ScopedTestDir test_dir;

  helper()->StartChild("CheckPlatformHandleFile");

  RefPtr<ChannelEndpoint> ep;
  auto mp = MessagePipe::CreateLocalProxy(&ep);
  Init(std::move(ep));

  std::vector<RefPtr<PlatformHandleDispatcher>> dispatchers;
  std::vector<DispatcherTransport> transports;

  size_t pipe_count = GetParam();
  for (size_t i = 0; i < pipe_count; ++i) {
    util::ScopedFILE fp(test_dir.CreateFile());
    const std::string world("world");
    CHECK_EQ(fwrite(&world[0], 1, world.size(), fp.get()), world.size());
    fflush(fp.get());
    rewind(fp.get());

    auto dispatcher = PlatformHandleDispatcher::Create(
        ScopedPlatformHandle(PlatformHandleFromFILE(std::move(fp))));
    dispatchers.push_back(dispatcher);
    DispatcherTransport transport(
        test::DispatcherTryStartTransport(dispatcher.get()));
    ASSERT_TRUE(transport.is_valid());
    transports.push_back(transport);
  }

  char message[128];
  sprintf(message, "hello %d", static_cast<int>(pipe_count));
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(message),
                             static_cast<uint32_t>(strlen(message)),
                             &transports, MOJO_WRITE_MESSAGE_FLAG_NONE));

  for (size_t i = 0; i < pipe_count; ++i) {
    transports[i].End();
    EXPECT_TRUE(dispatchers[i]->HasOneRef());
  }

  dispatchers.clear();

  // Wait for it to become readable, which should fail.
  HandleSignalsState hss;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            test::WaitIfNecessary(mp.get(), MOJO_HANDLE_SIGNAL_READABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  mp->Close(0);

  EXPECT_EQ(0, helper()->WaitForChildShutdown());
}

// Android multi-process tests are not executing the new process. This is flaky.
#if !defined(OS_ANDROID)
INSTANTIATE_TEST_CASE_P(PipeCount,
                        MultiprocessMessagePipeTestWithPipeCount,
                        testing::Values(1u, 128u, 140u));
#endif

}  // namespace
}  // namespace system
}  // namespace mojo
