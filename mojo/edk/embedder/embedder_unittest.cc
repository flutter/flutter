// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/embedder/embedder.h"

#include <string.h>

#include "base/bind.h"
#include "base/command_line.h"
#include "base/location.h"
#include "base/logging.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/waitable_event.h"
#include "base/test/test_io_thread.h"
#include "base/test/test_timeouts.h"
#include "mojo/edk/embedder/platform_channel_pair.h"
#include "mojo/edk/embedder/test_embedder.h"
#include "mojo/edk/system/mutex.h"
#include "mojo/edk/system/test_utils.h"
#include "mojo/edk/test/multiprocess_test_helper.h"
#include "mojo/edk/test/scoped_ipc_support.h"
#include "mojo/public/c/system/core.h"
#include "mojo/public/cpp/system/handle.h"
#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/system/message_pipe.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace embedder {
namespace {

const MojoHandleSignals kSignalReadadableWritable =
    MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE;

const MojoHandleSignals kSignalAll = MOJO_HANDLE_SIGNAL_READABLE |
                                     MOJO_HANDLE_SIGNAL_WRITABLE |
                                     MOJO_HANDLE_SIGNAL_PEER_CLOSED;

const char kConnectionIdFlag[] = "test-connection-id";

class ScopedTestChannel {
 public:
  // Creates a channel, which lives on the I/O thread given to
  // |InitIPCSupport()|. After construction, |bootstrap_message_pipe()| gives
  // the Mojo handle for the bootstrap message pipe on this channel; it is up to
  // the caller to close this handle. Note: The I/O thread must outlive this
  // object (and its message loop must continue pumping messages while this
  // object is alive).
  explicit ScopedTestChannel(ScopedPlatformHandle platform_handle)
      : bootstrap_message_pipe_(MOJO_HANDLE_INVALID),
        event_(true, false),  // Manual reset.
        channel_info_(nullptr) {
    bootstrap_message_pipe_ =
        CreateChannel(platform_handle.Pass(),
                      base::Bind(&ScopedTestChannel::DidCreateChannel,
                                 base::Unretained(this)),
                      nullptr)
            .release()
            .value();
    CHECK_NE(bootstrap_message_pipe_, MOJO_HANDLE_INVALID);
  }

  // Destructor: Shuts down the channel. (As noted above, for this to happen,
  // the I/O thread must be alive and pumping messages.)
  ~ScopedTestChannel() {
    // |WaitForChannelCreationCompletion()| must be called before destruction.
    CHECK(event_.IsSignaled());
    event_.Reset();
    DestroyChannel(channel_info_,
                   base::Bind(&ScopedTestChannel::DidDestroyChannel,
                              base::Unretained(this)),
                   nullptr);
    event_.Wait();
  }

  // Waits for channel creation to be completed.
  void WaitForChannelCreationCompletion() { event_.Wait(); }

  MojoHandle bootstrap_message_pipe() const { return bootstrap_message_pipe_; }

  // Call only after |WaitForChannelCreationCompletion()|. Use only to check
  // that it's not null.
  const ChannelInfo* channel_info() const { return channel_info_; }

 private:
  void DidCreateChannel(ChannelInfo* channel_info) {
    CHECK(channel_info);
    CHECK(!channel_info_);
    channel_info_ = channel_info;
    event_.Signal();
  }

  void DidDestroyChannel() { event_.Signal(); }

  // Valid from creation until whenever it gets closed (by the "owner" of this
  // object).
  // Note: We don't want use the C++ wrappers here, since we want to test the
  // API at the lowest level.
  MojoHandle bootstrap_message_pipe_;

  // Set after channel creation has been completed (i.e., the callback to
  // |CreateChannel()| has been called). Also used in the destructor to wait for
  // |DestroyChannel()| completion.
  base::WaitableEvent event_;

  // Valid after channel creation completion until destruction.
  ChannelInfo* channel_info_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ScopedTestChannel);
};

class EmbedderTest : public testing::Test {
 public:
  EmbedderTest() : test_io_thread_(base::TestIOThread::kAutoStart) {}
  ~EmbedderTest() override {}

 protected:
  base::TestIOThread& test_io_thread() { return test_io_thread_; }
  scoped_refptr<base::TaskRunner> test_io_task_runner() {
    return test_io_thread_.task_runner();
  }

 private:
  void SetUp() override { test::InitWithSimplePlatformSupport(); }

  void TearDown() override { EXPECT_TRUE(test::Shutdown()); }

  base::TestIOThread test_io_thread_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(EmbedderTest);
};

TEST_F(EmbedderTest, ChannelsBasic) {
  mojo::test::ScopedIPCSupport ipc_support(test_io_task_runner());

  PlatformChannelPair channel_pair;
  ScopedTestChannel server_channel(channel_pair.PassServerHandle());
  MojoHandle server_mp = server_channel.bootstrap_message_pipe();
  EXPECT_NE(server_mp, MOJO_HANDLE_INVALID);
  ScopedTestChannel client_channel(channel_pair.PassClientHandle());
  MojoHandle client_mp = client_channel.bootstrap_message_pipe();
  EXPECT_NE(client_mp, MOJO_HANDLE_INVALID);

  // We can write to a message pipe handle immediately.
  const char kHello[] = "hello";
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoWriteMessage(server_mp, kHello, static_cast<uint32_t>(sizeof(kHello)),
                       nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Now wait for the other side to become readable.
  MojoHandleSignalsState state;
  EXPECT_EQ(MOJO_RESULT_OK, MojoWait(client_mp, MOJO_HANDLE_SIGNAL_READABLE,
                                     MOJO_DEADLINE_INDEFINITE, &state));
  EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  char buffer[1000] = {};
  uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoReadMessage(client_mp, buffer, &num_bytes, nullptr, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), num_bytes);
  EXPECT_STREQ(kHello, buffer);

  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(server_mp));
  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(client_mp));

  // By this point, these waits should basically be no-ops (since we've waited
  // for the client message pipe to become readable, which implies that both
  // the server and client channels were completely created).
  server_channel.WaitForChannelCreationCompletion();
  client_channel.WaitForChannelCreationCompletion();
  EXPECT_TRUE(server_channel.channel_info());
  EXPECT_TRUE(client_channel.channel_info());
}

class TestAsyncWaiter {
 public:
  TestAsyncWaiter() : event_(true, false), wait_result_(MOJO_RESULT_UNKNOWN) {}

  void Awake(MojoResult result) {
    system::MutexLocker l(&wait_result_mutex_);
    wait_result_ = result;
    event_.Signal();
  }

  bool TryWait() { return event_.TimedWait(TestTimeouts::action_timeout()); }

  MojoResult wait_result() const {
    system::MutexLocker l(&wait_result_mutex_);
    return wait_result_;
  }

 private:
  base::WaitableEvent event_;

  mutable system::Mutex wait_result_mutex_;
  MojoResult wait_result_ MOJO_GUARDED_BY(wait_result_mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestAsyncWaiter);
};

void WriteHello(MessagePipeHandle pipe) {
  static const char kHello[] = "hello";
  CHECK_EQ(MOJO_RESULT_OK,
           WriteMessageRaw(pipe, kHello, static_cast<uint32_t>(sizeof(kHello)),
                           nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));
}

void CloseScopedHandle(ScopedMessagePipeHandle handle) {
  // Do nothing and the destructor will close it.
}

TEST_F(EmbedderTest, AsyncWait) {
  ScopedMessagePipeHandle client_mp;
  ScopedMessagePipeHandle server_mp;
  EXPECT_EQ(MOJO_RESULT_OK, CreateMessagePipe(nullptr, &client_mp, &server_mp));

  TestAsyncWaiter waiter;
  EXPECT_EQ(MOJO_RESULT_OK,
            AsyncWait(client_mp.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                      base::Bind(&TestAsyncWaiter::Awake,
                                 base::Unretained(&waiter))));

  test_io_task_runner()->PostTask(FROM_HERE,
                                  base::Bind(&WriteHello, server_mp.get()));
  EXPECT_TRUE(waiter.TryWait());
  EXPECT_EQ(MOJO_RESULT_OK, waiter.wait_result());

  // If message is in the queue, it does't allow us to wait.
  TestAsyncWaiter waiter_that_doesnt_wait;
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            AsyncWait(client_mp.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                      base::Bind(&TestAsyncWaiter::Awake,
                                 base::Unretained(&waiter_that_doesnt_wait))));

  char buffer[1000];
  uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
  CHECK_EQ(MOJO_RESULT_OK,
           ReadMessageRaw(client_mp.get(), buffer, &num_bytes, nullptr, nullptr,
                          MOJO_READ_MESSAGE_FLAG_NONE));

  TestAsyncWaiter unsatisfiable_waiter;
  EXPECT_EQ(MOJO_RESULT_OK,
            AsyncWait(client_mp.get().value(), MOJO_HANDLE_SIGNAL_READABLE,
                      base::Bind(&TestAsyncWaiter::Awake,
                                 base::Unretained(&unsatisfiable_waiter))));

  test_io_task_runner()->PostTask(
      FROM_HERE,
      base::Bind(&CloseScopedHandle, base::Passed(server_mp.Pass())));

  EXPECT_TRUE(unsatisfiable_waiter.TryWait());
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            unsatisfiable_waiter.wait_result());
}

TEST_F(EmbedderTest, ChannelsHandlePassing) {
  mojo::test::ScopedIPCSupport ipc_support(test_io_task_runner());

  PlatformChannelPair channel_pair;
  ScopedTestChannel server_channel(channel_pair.PassServerHandle());
  MojoHandle server_mp = server_channel.bootstrap_message_pipe();
  EXPECT_NE(server_mp, MOJO_HANDLE_INVALID);
  ScopedTestChannel client_channel(channel_pair.PassClientHandle());
  MojoHandle client_mp = client_channel.bootstrap_message_pipe();
  EXPECT_NE(client_mp, MOJO_HANDLE_INVALID);

  MojoHandle h0, h1;
  EXPECT_EQ(MOJO_RESULT_OK, MojoCreateMessagePipe(nullptr, &h0, &h1));

  // Write a message to |h0| (attaching nothing).
  const char kHello[] = "hello";
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoWriteMessage(h0, kHello, static_cast<uint32_t>(sizeof(kHello)),
                             nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Write one message to |server_mp|, attaching |h1|.
  const char kWorld[] = "world!!!";
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoWriteMessage(server_mp, kWorld, static_cast<uint32_t>(sizeof(kWorld)),
                       &h1, 1, MOJO_WRITE_MESSAGE_FLAG_NONE));
  h1 = MOJO_HANDLE_INVALID;

  // Write another message to |h0|.
  const char kFoo[] = "foo";
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoWriteMessage(h0, kFoo, static_cast<uint32_t>(sizeof(kFoo)),
                             nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait for |client_mp| to become readable.
  MojoHandleSignalsState state;
  EXPECT_EQ(MOJO_RESULT_OK, MojoWait(client_mp, MOJO_HANDLE_SIGNAL_READABLE,
                                     MOJO_DEADLINE_INDEFINITE, &state));
  EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Read a message from |client_mp|.
  char buffer[1000] = {};
  uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
  MojoHandle handles[10] = {};
  uint32_t num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoReadMessage(client_mp, buffer, &num_bytes, handles,
                            &num_handles, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kWorld), num_bytes);
  EXPECT_STREQ(kWorld, buffer);
  EXPECT_EQ(1u, num_handles);
  EXPECT_NE(handles[0], MOJO_HANDLE_INVALID);
  h1 = handles[0];

  // Wait for |h1| to become readable.
  EXPECT_EQ(MOJO_RESULT_OK, MojoWait(h1, MOJO_HANDLE_SIGNAL_READABLE,
                                     MOJO_DEADLINE_INDEFINITE, &state));
  EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Read a message from |h1|.
  memset(buffer, 0, sizeof(buffer));
  num_bytes = static_cast<uint32_t>(sizeof(buffer));
  memset(handles, 0, sizeof(handles));
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoReadMessage(h1, buffer, &num_bytes, handles, &num_handles,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kHello), num_bytes);
  EXPECT_STREQ(kHello, buffer);
  EXPECT_EQ(0u, num_handles);

  // Wait for |h1| to become readable (again).
  EXPECT_EQ(MOJO_RESULT_OK, MojoWait(h1, MOJO_HANDLE_SIGNAL_READABLE,
                                     MOJO_DEADLINE_INDEFINITE, &state));
  EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Read the second message from |h1|.
  memset(buffer, 0, sizeof(buffer));
  num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoReadMessage(h1, buffer, &num_bytes, nullptr, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kFoo), num_bytes);
  EXPECT_STREQ(kFoo, buffer);

  // Write a message to |h1|.
  const char kBarBaz[] = "barbaz";
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoWriteMessage(h1, kBarBaz, static_cast<uint32_t>(sizeof(kBarBaz)),
                       nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait for |h0| to become readable.
  EXPECT_EQ(MOJO_RESULT_OK, MojoWait(h0, MOJO_HANDLE_SIGNAL_READABLE,
                                     MOJO_DEADLINE_INDEFINITE, &state));
  EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Read a message from |h0|.
  memset(buffer, 0, sizeof(buffer));
  num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoReadMessage(h0, buffer, &num_bytes, nullptr, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(sizeof(kBarBaz), num_bytes);
  EXPECT_STREQ(kBarBaz, buffer);

  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(server_mp));
  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(client_mp));
  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(h0));
  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(h1));

  server_channel.WaitForChannelCreationCompletion();
  client_channel.WaitForChannelCreationCompletion();
  EXPECT_TRUE(server_channel.channel_info());
  EXPECT_TRUE(client_channel.channel_info());
}

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
// TODO(vtl): I'm guessing this is true of this test too?
#define MAYBE_MultiprocessMasterSlave DISABLED_MultiprocessMasterSlave
#else
#define MAYBE_MultiprocessMasterSlave MultiprocessMasterSlave
#endif  // defined(OS_ANDROID)
TEST_F(EmbedderTest, MAYBE_MultiprocessMasterSlave) {
  mojo::test::ScopedMasterIPCSupport ipc_support(test_io_task_runner());

  mojo::test::MultiprocessTestHelper multiprocess_test_helper;
  std::string connection_id;
  base::WaitableEvent event(true, false);
  ChannelInfo* channel_info = nullptr;
  ScopedMessagePipeHandle mp = ConnectToSlave(
      nullptr, multiprocess_test_helper.server_platform_handle.Pass(),
      base::Bind(&base::WaitableEvent::Signal, base::Unretained(&event)),
      nullptr, &connection_id, &channel_info);
  ASSERT_TRUE(mp.is_valid());
  EXPECT_TRUE(channel_info);
  ASSERT_FALSE(connection_id.empty());

  multiprocess_test_helper.StartChildWithExtraSwitch(
      "MultiprocessMasterSlave", kConnectionIdFlag, connection_id);

  // Send a message saying "hello".
  EXPECT_EQ(MOJO_RESULT_OK, WriteMessageRaw(mp.get(), "hello", 5, nullptr, 0,
                                            MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Wait for a response.
  EXPECT_EQ(MOJO_RESULT_OK,
            Wait(mp.get(), MOJO_HANDLE_SIGNAL_READABLE,
                 mojo::system::test::ActionDeadline(), nullptr));

  // The response message should say "world".
  char buffer[100];
  uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            ReadMessageRaw(mp.get(), buffer, &num_bytes, nullptr, nullptr,
                           MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(5u, num_bytes);
  EXPECT_EQ(0, memcmp(buffer, "world", 5));

  mp.reset();

  EXPECT_TRUE(multiprocess_test_helper.WaitForChildTestShutdown());

  EXPECT_TRUE(event.TimedWait(TestTimeouts::action_timeout()));
  test_io_thread().PostTaskAndWait(
      FROM_HERE,
      base::Bind(&DestroyChannelOnIOThread, base::Unretained(channel_info)));
}

MOJO_MULTIPROCESS_TEST_CHILD_TEST(MultiprocessMasterSlave) {
  ScopedPlatformHandle client_platform_handle =
      mojo::test::MultiprocessTestHelper::client_platform_handle.Pass();
  EXPECT_TRUE(client_platform_handle.is_valid());

  base::TestIOThread test_io_thread(base::TestIOThread::kAutoStart);
  test::InitWithSimplePlatformSupport();

  {
    mojo::test::ScopedSlaveIPCSupport ipc_support(
        test_io_thread.task_runner(), client_platform_handle.Pass());

    const base::CommandLine& command_line =
        *base::CommandLine::ForCurrentProcess();
    ASSERT_TRUE(command_line.HasSwitch(kConnectionIdFlag));
    std::string connection_id =
        command_line.GetSwitchValueASCII(kConnectionIdFlag);
    ASSERT_FALSE(connection_id.empty());
    base::WaitableEvent event(true, false);
    ChannelInfo* channel_info = nullptr;
    ScopedMessagePipeHandle mp = ConnectToMaster(
        connection_id,
        base::Bind(&base::WaitableEvent::Signal, base::Unretained(&event)),
        nullptr, &channel_info);
    ASSERT_TRUE(mp.is_valid());
    EXPECT_TRUE(channel_info);

    // Wait for the master to send us a message.
    EXPECT_EQ(MOJO_RESULT_OK,
              Wait(mp.get(), MOJO_HANDLE_SIGNAL_READABLE,
                   mojo::system::test::ActionDeadline(), nullptr));

    // It should say "hello".
    char buffer[100];
    uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
    EXPECT_EQ(MOJO_RESULT_OK,
              ReadMessageRaw(mp.get(), buffer, &num_bytes, nullptr, nullptr,
                             MOJO_READ_MESSAGE_FLAG_NONE));
    EXPECT_EQ(5u, num_bytes);
    EXPECT_EQ(0, memcmp(buffer, "hello", 5));

    // In response send a message saying "world".
    EXPECT_EQ(MOJO_RESULT_OK, WriteMessageRaw(mp.get(), "world", 5, nullptr, 0,
                                              MOJO_WRITE_MESSAGE_FLAG_NONE));

    mp.reset();

    EXPECT_TRUE(event.TimedWait(TestTimeouts::action_timeout()));
    test_io_thread.PostTaskAndWait(
        FROM_HERE,
        base::Bind(&DestroyChannelOnIOThread, base::Unretained(channel_info)));
  }

  EXPECT_TRUE(test::Shutdown());
}

// The sequence of messages sent is:
//       server_mp   client_mp   mp0         mp1         mp2         mp3
//   1.  "hello"
//   2.              "world!"
//   3.                          "FOO"
//   4.  "Bar"+mp1
//   5.  (close)
//   6.              (close)
//   7.                                                              "baz"
//   8.                                                              (closed)
//   9.                                      "quux"+mp2
//  10.                          (close)
//  11.                                      (wait/cl.)
//  12.                                                  (wait/cl.)

#if defined(OS_ANDROID)
// Android multi-process tests are not executing the new process. This is flaky.
#define MAYBE_MultiprocessChannels DISABLED_MultiprocessChannels
#else
#define MAYBE_MultiprocessChannels MultiprocessChannels
#endif  // defined(OS_ANDROID)
TEST_F(EmbedderTest, MAYBE_MultiprocessChannels) {
  // TODO(vtl): This should eventually initialize a master process instead,
  // probably.
  mojo::test::ScopedIPCSupport ipc_support(test_io_task_runner());

  mojo::test::MultiprocessTestHelper multiprocess_test_helper;
  multiprocess_test_helper.StartChild("MultiprocessChannelsClient");

  {
    ScopedTestChannel server_channel(
        multiprocess_test_helper.server_platform_handle.Pass());
    MojoHandle server_mp = server_channel.bootstrap_message_pipe();
    EXPECT_NE(server_mp, MOJO_HANDLE_INVALID);
    server_channel.WaitForChannelCreationCompletion();
    EXPECT_TRUE(server_channel.channel_info());

    // 1. Write a message to |server_mp| (attaching nothing).
    const char kHello[] = "hello";
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoWriteMessage(server_mp, kHello,
                               static_cast<uint32_t>(sizeof(kHello)), nullptr,
                               0, MOJO_WRITE_MESSAGE_FLAG_NONE));

    // TODO(vtl): If the scope were ended immediately here (maybe after closing
    // |server_mp|), we die with a fatal error in |Channel::HandleLocalError()|.

    // 2. Read a message from |server_mp|.
    MojoHandleSignalsState state;
    EXPECT_EQ(MOJO_RESULT_OK, MojoWait(server_mp, MOJO_HANDLE_SIGNAL_READABLE,
                                       MOJO_DEADLINE_INDEFINITE, &state));
    EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
    EXPECT_EQ(kSignalAll, state.satisfiable_signals);

    char buffer[1000] = {};
    uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoReadMessage(server_mp, buffer, &num_bytes, nullptr, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    const char kWorld[] = "world!";
    EXPECT_EQ(sizeof(kWorld), num_bytes);
    EXPECT_STREQ(kWorld, buffer);

    // Create a new message pipe (endpoints |mp0| and |mp1|).
    MojoHandle mp0, mp1;
    EXPECT_EQ(MOJO_RESULT_OK, MojoCreateMessagePipe(nullptr, &mp0, &mp1));

    // 3. Write something to |mp0|.
    const char kFoo[] = "FOO";
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoWriteMessage(mp0, kFoo, static_cast<uint32_t>(sizeof(kFoo)),
                               nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

    // 4. Write a message to |server_mp|, attaching |mp1|.
    const char kBar[] = "Bar";
    EXPECT_EQ(
        MOJO_RESULT_OK,
        MojoWriteMessage(server_mp, kBar, static_cast<uint32_t>(sizeof(kBar)),
                         &mp1, 1, MOJO_WRITE_MESSAGE_FLAG_NONE));
    mp1 = MOJO_HANDLE_INVALID;

    // 5. Close |server_mp|.
    EXPECT_EQ(MOJO_RESULT_OK, MojoClose(server_mp));

    // 9. Read a message from |mp0|, which should have |mp2| attached.
    EXPECT_EQ(MOJO_RESULT_OK, MojoWait(mp0, MOJO_HANDLE_SIGNAL_READABLE,
                                       MOJO_DEADLINE_INDEFINITE, &state));
    EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
    EXPECT_EQ(kSignalAll, state.satisfiable_signals);

    memset(buffer, 0, sizeof(buffer));
    num_bytes = static_cast<uint32_t>(sizeof(buffer));
    MojoHandle mp2 = MOJO_HANDLE_INVALID;
    uint32_t num_handles = 1;
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoReadMessage(mp0, buffer, &num_bytes, &mp2, &num_handles,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    const char kQuux[] = "quux";
    EXPECT_EQ(sizeof(kQuux), num_bytes);
    EXPECT_STREQ(kQuux, buffer);
    EXPECT_EQ(1u, num_handles);
    EXPECT_NE(mp2, MOJO_HANDLE_INVALID);

    // 7. Read a message from |mp2|.
    EXPECT_EQ(MOJO_RESULT_OK, MojoWait(mp2, MOJO_HANDLE_SIGNAL_READABLE,
                                       MOJO_DEADLINE_INDEFINITE, &state));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              state.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              state.satisfiable_signals);

    memset(buffer, 0, sizeof(buffer));
    num_bytes = static_cast<uint32_t>(sizeof(buffer));
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoReadMessage(mp2, buffer, &num_bytes, nullptr, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    const char kBaz[] = "baz";
    EXPECT_EQ(sizeof(kBaz), num_bytes);
    EXPECT_STREQ(kBaz, buffer);

    // 10. Close |mp0|.
    EXPECT_EQ(MOJO_RESULT_OK, MojoClose(mp0));

// 12. Wait on |mp2| (which should eventually fail) and then close it.
// TODO(vtl): crbug.com/351768
#if 0
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              MojoWait(mp2, MOJO_HANDLE_SIGNAL_READABLE,
                       MOJO_DEADLINE_INDEFINITE,
                       &state));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_NONE, state.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_NONE, state.satisfiable_signals);
#endif
    EXPECT_EQ(MOJO_RESULT_OK, MojoClose(mp2));
  }

  EXPECT_TRUE(multiprocess_test_helper.WaitForChildTestShutdown());
}

MOJO_MULTIPROCESS_TEST_CHILD_TEST(MultiprocessChannelsClient) {
  ScopedPlatformHandle client_platform_handle =
      mojo::test::MultiprocessTestHelper::client_platform_handle.Pass();
  EXPECT_TRUE(client_platform_handle.is_valid());

  base::TestIOThread test_io_thread(base::TestIOThread::kAutoStart);
  test::InitWithSimplePlatformSupport();

  {
    // TODO(vtl): This should eventually initialize a slave process instead,
    // probably.
    mojo::test::ScopedIPCSupport ipc_support(test_io_thread.task_runner());

    ScopedTestChannel client_channel(client_platform_handle.Pass());
    MojoHandle client_mp = client_channel.bootstrap_message_pipe();
    EXPECT_NE(client_mp, MOJO_HANDLE_INVALID);
    client_channel.WaitForChannelCreationCompletion();
    CHECK(client_channel.channel_info() != nullptr);

    // 1. Read the first message from |client_mp|.
    MojoHandleSignalsState state;
    EXPECT_EQ(MOJO_RESULT_OK, MojoWait(client_mp, MOJO_HANDLE_SIGNAL_READABLE,
                                       MOJO_DEADLINE_INDEFINITE, &state));
    EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
    EXPECT_EQ(kSignalAll, state.satisfiable_signals);

    char buffer[1000] = {};
    uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoReadMessage(client_mp, buffer, &num_bytes, nullptr, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    const char kHello[] = "hello";
    EXPECT_EQ(sizeof(kHello), num_bytes);
    EXPECT_STREQ(kHello, buffer);

    // 2. Write a message to |client_mp| (attaching nothing).
    const char kWorld[] = "world!";
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoWriteMessage(client_mp, kWorld,
                               static_cast<uint32_t>(sizeof(kWorld)), nullptr,
                               0, MOJO_WRITE_MESSAGE_FLAG_NONE));

    // 4. Read a message from |client_mp|, which should have |mp1| attached.
    EXPECT_EQ(MOJO_RESULT_OK, MojoWait(client_mp, MOJO_HANDLE_SIGNAL_READABLE,
                                       MOJO_DEADLINE_INDEFINITE, &state));
    // The other end of the handle may or may not be closed at this point, so we
    // can't test MOJO_HANDLE_SIGNAL_WRITABLE or MOJO_HANDLE_SIGNAL_PEER_CLOSED.
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE,
              state.satisfied_signals & MOJO_HANDLE_SIGNAL_READABLE);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE,
              state.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE);
    // TODO(vtl): If the scope were to end here (and |client_mp| closed), we'd
    // die (again due to |Channel::HandleLocalError()|).
    memset(buffer, 0, sizeof(buffer));
    num_bytes = static_cast<uint32_t>(sizeof(buffer));
    MojoHandle mp1 = MOJO_HANDLE_INVALID;
    uint32_t num_handles = 1;
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoReadMessage(client_mp, buffer, &num_bytes, &mp1, &num_handles,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    const char kBar[] = "Bar";
    EXPECT_EQ(sizeof(kBar), num_bytes);
    EXPECT_STREQ(kBar, buffer);
    EXPECT_EQ(1u, num_handles);
    EXPECT_NE(mp1, MOJO_HANDLE_INVALID);
    // TODO(vtl): If the scope were to end here (and the two handles closed),
    // we'd die due to |Channel::RunRemoteMessagePipeEndpoint()| not handling
    // write errors (assuming the parent had closed the pipe).

    // 6. Close |client_mp|.
    EXPECT_EQ(MOJO_RESULT_OK, MojoClose(client_mp));

    // Create a new message pipe (endpoints |mp2| and |mp3|).
    MojoHandle mp2, mp3;
    EXPECT_EQ(MOJO_RESULT_OK, MojoCreateMessagePipe(nullptr, &mp2, &mp3));

    // 7. Write a message to |mp3|.
    const char kBaz[] = "baz";
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoWriteMessage(mp3, kBaz, static_cast<uint32_t>(sizeof(kBaz)),
                               nullptr, 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

    // 8. Close |mp3|.
    EXPECT_EQ(MOJO_RESULT_OK, MojoClose(mp3));

    // 9. Write a message to |mp1|, attaching |mp2|.
    const char kQuux[] = "quux";
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoWriteMessage(mp1, kQuux, static_cast<uint32_t>(sizeof(kQuux)),
                               &mp2, 1, MOJO_WRITE_MESSAGE_FLAG_NONE));
    mp2 = MOJO_HANDLE_INVALID;

    // 3. Read a message from |mp1|.
    EXPECT_EQ(MOJO_RESULT_OK, MojoWait(mp1, MOJO_HANDLE_SIGNAL_READABLE,
                                       MOJO_DEADLINE_INDEFINITE, &state));
    EXPECT_EQ(kSignalReadadableWritable, state.satisfied_signals);
    EXPECT_EQ(kSignalAll, state.satisfiable_signals);

    memset(buffer, 0, sizeof(buffer));
    num_bytes = static_cast<uint32_t>(sizeof(buffer));
    EXPECT_EQ(MOJO_RESULT_OK,
              MojoReadMessage(mp1, buffer, &num_bytes, nullptr, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    const char kFoo[] = "FOO";
    EXPECT_EQ(sizeof(kFoo), num_bytes);
    EXPECT_STREQ(kFoo, buffer);

    // 11. Wait on |mp1| (which should eventually fail) and then close it.
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              MojoWait(mp1, MOJO_HANDLE_SIGNAL_READABLE,
                       MOJO_DEADLINE_INDEFINITE, &state));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, state.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, state.satisfiable_signals);
    EXPECT_EQ(MOJO_RESULT_OK, MojoClose(mp1));
  }

  EXPECT_TRUE(test::Shutdown());
}

// TODO(vtl): Test immediate write & close.
// TODO(vtl): Test broken-connection cases.

}  // namespace
}  // namespace embedder
}  // namespace mojo
