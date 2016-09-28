// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// NOTE(vtl): Some of these tests are inherently flaky (e.g., if run on a
// heavily-loaded system). Sorry. |test::EpsilonTimeout()| may be increased to
// increase tolerance and reduce observed flakiness (though doing so reduces the
// meaningfulness of the test).

#include "mojo/edk/system/message_pipe_dispatcher.h"

#include <string.h>

#include <limits>
#include <memory>
#include <utility>
#include <vector>

#include "mojo/edk/platform/test_stopwatch.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/message_pipe.h"
#include "mojo/edk/system/test/random.h"
#include "mojo/edk/system/test/simple_test_thread.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/waiter.h"
#include "mojo/edk/system/waiter_test_utils.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::test::Stopwatch;
using mojo::platform::ThreadSleep;
using mojo::util::MakeUnique;
using mojo::util::RefPtr;

namespace mojo {
namespace system {
namespace {

TEST(MessagePipeDispatcherTest, Basic) {
  Stopwatch stopwatch;
  int32_t buffer[1];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;

  // Run this test both with |d0| as port 0, |d1| as port 1 and vice versa.
  for (unsigned i = 0; i < 2; i++) {
    auto d0 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    EXPECT_EQ(Dispatcher::Type::MESSAGE_PIPE, d0->GetType());
    auto d1 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    {
      auto mp = MessagePipe::CreateLocalLocal();
      d0->Init(mp.Clone(), i);         // 0, 1.
      d1->Init(std::move(mp), i ^ 1);  // 1, 0.
    }
    Waiter w;
    uint64_t context = 0;
    HandleSignalsState hss;

    // Try adding a writable waiter when already writable.
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
              d0->AddAwakable(&w, 0, false, MOJO_HANDLE_SIGNAL_WRITABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);
    // Shouldn't need to remove the waiter (it was not added).

    // Add a readable waiter to |d0|, then make it readable (by writing to
    // |d1|), then wait.
    w.Init();
    ASSERT_EQ(
        MOJO_RESULT_OK,
        d0->AddAwakable(&w, 1, false, MOJO_HANDLE_SIGNAL_READABLE, nullptr));
    buffer[0] = 123456789;
    EXPECT_EQ(MOJO_RESULT_OK,
              d1->WriteMessage(UserPointer<const void>(buffer), kBufferSize,
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
    stopwatch.Start();
    EXPECT_EQ(MOJO_RESULT_OK,
              w.Wait(MOJO_DEADLINE_INDEFINITE, &context, nullptr));
    EXPECT_EQ(1u, context);
    EXPECT_LT(stopwatch.Elapsed(), test::EpsilonTimeout());
    hss = HandleSignalsState();
    d0->RemoveAwakable(false, &w, 0, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Try adding a readable waiter when already readable (from above).
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
              d0->AddAwakable(&w, 2, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);
    // Shouldn't need to remove the waiter (it was not added).

    // Make |d0| no longer readable (by reading from it).
    buffer[0] = 0;
    buffer_size = kBufferSize;
    EXPECT_EQ(MOJO_RESULT_OK,
              d0->ReadMessage(UserPointer<void>(buffer),
                              MakeUserPointer(&buffer_size), 0, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    EXPECT_EQ(kBufferSize, buffer_size);
    EXPECT_EQ(123456789, buffer[0]);

    // Wait for zero time for readability on |d0| (will time out).
    w.Init();
    ASSERT_EQ(
        MOJO_RESULT_OK,
        d0->AddAwakable(&w, 3, false, MOJO_HANDLE_SIGNAL_READABLE, nullptr));
    stopwatch.Start();
    EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, w.Wait(0, nullptr, nullptr));
    EXPECT_LT(stopwatch.Elapsed(), test::EpsilonTimeout());
    hss = HandleSignalsState();
    d0->RemoveAwakable(false, &w, 0, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Wait for non-zero, finite time for readability on |d0| (will time out).
    w.Init();
    ASSERT_EQ(
        MOJO_RESULT_OK,
        d0->AddAwakable(&w, 3, false, MOJO_HANDLE_SIGNAL_READABLE, nullptr));
    stopwatch.Start();
    EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
              w.Wait(2 * test::EpsilonTimeout(), nullptr, nullptr));
    MojoDeadline elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonTimeout());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonTimeout());
    hss = HandleSignalsState();
    d0->RemoveAwakable(false, &w, 0, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Check the peer closed signal.
    w.Init();
    ASSERT_EQ(MOJO_RESULT_OK,
              d0->AddAwakable(&w, 12, false, MOJO_HANDLE_SIGNAL_PEER_CLOSED,
                              nullptr));

    // Close the peer.
    EXPECT_EQ(MOJO_RESULT_OK, d1->Close());

    // It should be signaled.
    EXPECT_EQ(MOJO_RESULT_OK, w.Wait(test::TinyTimeout(), &context, nullptr));
    EXPECT_EQ(12u, context);
    hss = HandleSignalsState();
    d0->RemoveAwakable(false, &w, 0, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

    EXPECT_EQ(MOJO_RESULT_OK, d0->Close());
  }
}

TEST(MessagePipeDispatcherTest, SupportsEntrypointClass) {
  auto d = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  ASSERT_TRUE(d);

  // We need to initialize |d|.
  {
    auto d_peer = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    auto mp = MessagePipe::CreateLocalLocal();
    d->Init(mp.Clone(), 0);
    d_peer->Init(std::move(mp), 1);
    EXPECT_EQ(MOJO_RESULT_OK, d_peer->Close());
  }

  EXPECT_TRUE(d->SupportsEntrypointClass(EntrypointClass::NONE));
  EXPECT_TRUE(d->SupportsEntrypointClass(EntrypointClass::MESSAGE_PIPE));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::DATA_PIPE_PRODUCER));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::DATA_PIPE_CONSUMER));
  EXPECT_FALSE(d->SupportsEntrypointClass(EntrypointClass::BUFFER));

  // TODO(vtl): Check that it actually returns |MOJO_RESULT_INVALID_ARGUMENT|
  // for methods in unsupported entrypoint classes.

  EXPECT_EQ(MOJO_RESULT_OK, d->Close());
}

TEST(MessagePipeDispatcherTest, InvalidParams) {
  char buffer[1];

  auto d0 = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  auto d1 = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  {
    auto mp = MessagePipe::CreateLocalLocal();
    d0->Init(mp.Clone(), 0);
    d1->Init(std::move(mp), 1);
  }

  // |WriteMessage|:
  // Huge buffer size.
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            d0->WriteMessage(UserPointer<const void>(buffer),
                             std::numeric_limits<uint32_t>::max(), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  EXPECT_EQ(MOJO_RESULT_OK, d0->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d1->Close());
}

// These test invalid arguments that should cause death if we're being paranoid
// about checking arguments (which we would want to do if, e.g., we were in a
// true "kernel" situation, but we might not want to do otherwise for
// performance reasons). Probably blatant errors like passing in null pointers
// (for required pointer arguments) will still cause death, but perhaps not
// predictably.
TEST(MessagePipeDispatcherTest, InvalidParamsDeath) {
  const char kMemoryCheckFailedRegex[] = "Check failed";

  auto d0 = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  auto d1 = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  {
    auto mp = MessagePipe::CreateLocalLocal();
    d0->Init(mp.Clone(), 0);
    d1->Init(std::move(mp), 1);
  }

  // |WriteMessage|:
  // Null buffer with nonzero buffer size.
  EXPECT_DEATH_IF_SUPPORTED(d0->WriteMessage(NullUserPointer(), 1, nullptr,
                                             MOJO_WRITE_MESSAGE_FLAG_NONE),
                            kMemoryCheckFailedRegex);

  // |ReadMessage|:
  // Null buffer with nonzero buffer size.
  // First write something so that we actually have something to read.
  EXPECT_EQ(MOJO_RESULT_OK,
            d1->WriteMessage(UserPointer<const void>("x"), 1, nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));
  uint32_t buffer_size = 1;
  EXPECT_DEATH_IF_SUPPORTED(
      d0->ReadMessage(NullUserPointer(), MakeUserPointer(&buffer_size), 0,
                      nullptr, MOJO_READ_MESSAGE_FLAG_NONE),
      kMemoryCheckFailedRegex);

  EXPECT_EQ(MOJO_RESULT_OK, d0->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d1->Close());
}

// Test what happens when one end is closed (single-threaded test).
TEST(MessagePipeDispatcherTest, BasicClosed) {
  int32_t buffer[1];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;

  // Run this test both with |d0| as port 0, |d1| as port 1 and vice versa.
  for (unsigned i = 0; i < 2; i++) {
    auto d0 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    auto d1 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    {
      auto mp = MessagePipe::CreateLocalLocal();
      d0->Init(mp.Clone(), i);         // 0, 1.
      d1->Init(std::move(mp), i ^ 1);  // 1, 0.
    }
    Waiter w;
    HandleSignalsState hss;

    // Write (twice) to |d1|.
    buffer[0] = 123456789;
    EXPECT_EQ(MOJO_RESULT_OK,
              d1->WriteMessage(UserPointer<const void>(buffer), kBufferSize,
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
    buffer[0] = 234567890;
    EXPECT_EQ(MOJO_RESULT_OK,
              d1->WriteMessage(UserPointer<const void>(buffer), kBufferSize,
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

    // Try waiting for readable on |d0|; should fail (already satisfied).
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
              d0->AddAwakable(&w, 0, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Try reading from |d1|; should fail (nothing to read).
    buffer[0] = 0;
    buffer_size = kBufferSize;
    EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
              d1->ReadMessage(UserPointer<void>(buffer),
                              MakeUserPointer(&buffer_size), 0, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));

    // Close |d1|.
    EXPECT_EQ(MOJO_RESULT_OK, d1->Close());

    // Try waiting for readable on |d0|; should fail (already satisfied).
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
              d0->AddAwakable(&w, 1, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Read from |d0|.
    buffer[0] = 0;
    buffer_size = kBufferSize;
    EXPECT_EQ(MOJO_RESULT_OK,
              d0->ReadMessage(UserPointer<void>(buffer),
                              MakeUserPointer(&buffer_size), 0, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    EXPECT_EQ(kBufferSize, buffer_size);
    EXPECT_EQ(123456789, buffer[0]);

    // Try waiting for readable on |d0|; should fail (already satisfied).
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
              d0->AddAwakable(&w, 2, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Read again from |d0|.
    buffer[0] = 0;
    buffer_size = kBufferSize;
    EXPECT_EQ(MOJO_RESULT_OK,
              d0->ReadMessage(UserPointer<void>(buffer),
                              MakeUserPointer(&buffer_size), 0, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    EXPECT_EQ(kBufferSize, buffer_size);
    EXPECT_EQ(234567890, buffer[0]);

    // Try waiting for readable on |d0|; should fail (unsatisfiable).
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              d0->AddAwakable(&w, 3, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

    // Try waiting for writable on |d0|; should fail (unsatisfiable).
    w.Init();
    hss = HandleSignalsState();
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              d0->AddAwakable(&w, 4, false, MOJO_HANDLE_SIGNAL_WRITABLE, &hss));
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

    // Try reading from |d0|; should fail (nothing to read and other end
    // closed).
    buffer[0] = 0;
    buffer_size = kBufferSize;
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              d0->ReadMessage(UserPointer<void>(buffer),
                              MakeUserPointer(&buffer_size), 0, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));

    // Try writing to |d0|; should fail (other end closed).
    buffer[0] = 345678901;
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              d0->WriteMessage(UserPointer<const void>(buffer), kBufferSize,
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

    EXPECT_EQ(MOJO_RESULT_OK, d0->Close());
  }
}

TEST(MessagePipeDispatcherTest, BasicThreaded) {
  Stopwatch stopwatch;
  int32_t buffer[1];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;
  MojoDeadline elapsed;
  bool did_wait;
  MojoResult result;
  uint64_t context;
  HandleSignalsState hss;

  // Run this test both with |d0| as port 0, |d1| as port 1 and vice versa.
  for (unsigned i = 0; i < 2; i++) {
    auto d0 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    auto d1 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    {
      auto mp = MessagePipe::CreateLocalLocal();
      d0->Init(mp.Clone(), i);         // 0, 1.
      d1->Init(std::move(mp), i ^ 1);  // 1, 0.
    }

    // Wait for readable on |d1|, which will become readable after some time.
    {
      test::WaiterThread thread(d1, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 1, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
      ThreadSleep(2 * test::EpsilonTimeout());
      // Wake it up by writing to |d0|.
      buffer[0] = 123456789;
      EXPECT_EQ(MOJO_RESULT_OK,
                d0->WriteMessage(UserPointer<const void>(buffer), kBufferSize,
                                 nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
    }  // Joins the thread.
    elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonTimeout());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonTimeout());
    EXPECT_TRUE(did_wait);
    EXPECT_EQ(MOJO_RESULT_OK, result);
    EXPECT_EQ(1u, context);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Now |d1| is already readable. Try waiting for it again.
    {
      test::WaiterThread thread(d1, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 2, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
    }  // Joins the thread.
    EXPECT_LT(stopwatch.Elapsed(), test::EpsilonTimeout());
    EXPECT_FALSE(did_wait);
    EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS, result);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                  MOJO_HANDLE_SIGNAL_PEER_CLOSED,
              hss.satisfiable_signals);

    // Consume what we wrote to |d0|.
    buffer[0] = 0;
    buffer_size = kBufferSize;
    EXPECT_EQ(MOJO_RESULT_OK,
              d1->ReadMessage(UserPointer<void>(buffer),
                              MakeUserPointer(&buffer_size), 0, nullptr,
                              MOJO_READ_MESSAGE_FLAG_NONE));
    EXPECT_EQ(kBufferSize, buffer_size);
    EXPECT_EQ(123456789, buffer[0]);

    // Wait for readable on |d1| and close |d0| after some time, which should
    // cancel that wait.
    {
      test::WaiterThread thread(d1, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 3, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
      ThreadSleep(2 * test::EpsilonTimeout());
      EXPECT_EQ(MOJO_RESULT_OK, d0->Close());
    }  // Joins the thread.
    elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonTimeout());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonTimeout());
    EXPECT_TRUE(did_wait);
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
    EXPECT_EQ(3u, context);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

    EXPECT_EQ(MOJO_RESULT_OK, d1->Close());
  }

  for (unsigned i = 0; i < 2; i++) {
    auto d0 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    auto d1 = MessagePipeDispatcher::Create(
        MessagePipeDispatcher::kDefaultCreateOptions);
    {
      auto mp = MessagePipe::CreateLocalLocal();
      d0->Init(mp.Clone(), i);         // 0, 1.
      d1->Init(std::move(mp), i ^ 1);  // 1, 0.
    }

    // Wait for readable on |d1| and close |d1| after some time, which should
    // cancel that wait.
    {
      test::WaiterThread thread(d1, MOJO_HANDLE_SIGNAL_READABLE,
                                MOJO_DEADLINE_INDEFINITE, 4, &did_wait, &result,
                                &context, &hss);
      stopwatch.Start();
      thread.Start();
      ThreadSleep(2 * test::EpsilonTimeout());
      EXPECT_EQ(MOJO_RESULT_OK, d1->Close());
    }  // Joins the thread.
    elapsed = stopwatch.Elapsed();
    EXPECT_GT(elapsed, (2 - 1) * test::EpsilonTimeout());
    EXPECT_LT(elapsed, (2 + 1) * test::EpsilonTimeout());
    EXPECT_TRUE(did_wait);
    EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
    EXPECT_EQ(4u, context);
    EXPECT_EQ(0u, hss.satisfied_signals);
    EXPECT_EQ(0u, hss.satisfiable_signals);

    EXPECT_EQ(MOJO_RESULT_OK, d0->Close());
  }
}

// Stress test -----------------------------------------------------------------

const size_t kMaxMessageSize = 2000;

class WriterThread : public test::SimpleTestThread {
 public:
  // |*messages_written| and |*bytes_written| belong to the thread while it's
  // alive.
  WriterThread(RefPtr<Dispatcher> write_dispatcher,
               size_t* messages_written,
               size_t* bytes_written)
      : write_dispatcher_(write_dispatcher),
        messages_written_(messages_written),
        bytes_written_(bytes_written) {
    *messages_written_ = 0;
    *bytes_written_ = 0;
  }

  ~WriterThread() override { Join(); }

 private:
  void Run() override {
    // Make some data to write.
    unsigned char buffer[kMaxMessageSize];
    for (size_t i = 0; i < kMaxMessageSize; i++)
      buffer[i] = static_cast<unsigned char>(i);

    // Number of messages to write.
    *messages_written_ = static_cast<size_t>(test::RandomInt(1000, 6000));

    // Write messages.
    for (size_t i = 0; i < *messages_written_; i++) {
      uint32_t bytes_to_write = static_cast<uint32_t>(
          test::RandomInt(1, static_cast<int>(kMaxMessageSize)));
      EXPECT_EQ(MOJO_RESULT_OK,
                write_dispatcher_->WriteMessage(UserPointer<const void>(buffer),
                                                bytes_to_write, nullptr,
                                                MOJO_WRITE_MESSAGE_FLAG_NONE));
      *bytes_written_ += bytes_to_write;
    }

    // Write one last "quit" message.
    EXPECT_EQ(MOJO_RESULT_OK, write_dispatcher_->WriteMessage(
                                  UserPointer<const void>("quit"), 4, nullptr,
                                  MOJO_WRITE_MESSAGE_FLAG_NONE));
  }

  const RefPtr<Dispatcher> write_dispatcher_;
  size_t* const messages_written_;
  size_t* const bytes_written_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(WriterThread);
};

class ReaderThread : public test::SimpleTestThread {
 public:
  // |*messages_read| and |*bytes_read| belong to the thread while it's alive.
  ReaderThread(RefPtr<Dispatcher> read_dispatcher,
               size_t* messages_read,
               size_t* bytes_read)
      : read_dispatcher_(read_dispatcher),
        messages_read_(messages_read),
        bytes_read_(bytes_read) {
    *messages_read_ = 0;
    *bytes_read_ = 0;
  }

  ~ReaderThread() override { Join(); }

 private:
  void Run() override {
    unsigned char buffer[kMaxMessageSize];
    Waiter w;
    HandleSignalsState hss;
    MojoResult result;

    // Read messages.
    for (;;) {
      // Wait for it to be readable.
      w.Init();
      hss = HandleSignalsState();
      result = read_dispatcher_->AddAwakable(&w, 0, false,
                                             MOJO_HANDLE_SIGNAL_READABLE, &hss);
      EXPECT_TRUE(result == MOJO_RESULT_OK ||
                  result == MOJO_RESULT_ALREADY_EXISTS)
          << "result: " << result;
      if (result == MOJO_RESULT_OK) {
        // Actually need to wait.
        EXPECT_EQ(MOJO_RESULT_OK,
                  w.Wait(MOJO_DEADLINE_INDEFINITE, nullptr, nullptr));
        read_dispatcher_->RemoveAwakable(false, &w, 0, &hss);
      }
      // We may not actually be readable, since we're racing with other threads.
      EXPECT_TRUE((hss.satisfiable_signals & MOJO_HANDLE_SIGNAL_READABLE));

      // Now, try to do the read.
      // Clear the buffer so that we can check the result.
      memset(buffer, 0, sizeof(buffer));
      uint32_t buffer_size = static_cast<uint32_t>(sizeof(buffer));
      result = read_dispatcher_->ReadMessage(
          UserPointer<void>(buffer), MakeUserPointer(&buffer_size), 0, nullptr,
          MOJO_READ_MESSAGE_FLAG_NONE);
      EXPECT_TRUE(result == MOJO_RESULT_OK || result == MOJO_RESULT_SHOULD_WAIT)
          << "result: " << result;
      // We're racing with others to read, so maybe we failed.
      if (result == MOJO_RESULT_SHOULD_WAIT)
        continue;  // In which case, try again.
      // Check for quit.
      if (buffer_size == 4 && memcmp("quit", buffer, 4) == 0)
        return;
      EXPECT_GE(buffer_size, 1u);
      EXPECT_LE(buffer_size, kMaxMessageSize);
      EXPECT_TRUE(IsValidMessage(buffer, buffer_size));

      (*messages_read_)++;
      *bytes_read_ += buffer_size;
    }
  }

  static bool IsValidMessage(const unsigned char* buffer,
                             uint32_t message_size) {
    size_t i;
    for (i = 0; i < message_size; i++) {
      if (buffer[i] != static_cast<unsigned char>(i))
        return false;
    }
    // Check that the remaining bytes weren't stomped on.
    for (; i < kMaxMessageSize; i++) {
      if (buffer[i] != 0)
        return false;
    }
    return true;
  }

  const RefPtr<Dispatcher> read_dispatcher_;
  size_t* const messages_read_;
  size_t* const bytes_read_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ReaderThread);
};

TEST(MessagePipeDispatcherTest, Stress) {
  static const size_t kNumWriters = 30;
  static const size_t kNumReaders = kNumWriters;

  auto d_write = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  auto d_read = MessagePipeDispatcher::Create(
      MessagePipeDispatcher::kDefaultCreateOptions);
  {
    auto mp = MessagePipe::CreateLocalLocal();
    d_write->Init(mp.Clone(), 0);
    d_read->Init(std::move(mp), 1);
  }

  size_t messages_written[kNumWriters];
  size_t bytes_written[kNumWriters];
  size_t messages_read[kNumReaders];
  size_t bytes_read[kNumReaders];
  {
    // Make writers.
    std::vector<std::unique_ptr<WriterThread>> writers;
    for (size_t i = 0; i < kNumWriters; i++) {
      writers.push_back(MakeUnique<WriterThread>(d_write, &messages_written[i],
                                                 &bytes_written[i]));
    }

    // Make readers.
    std::vector<std::unique_ptr<ReaderThread>> readers;
    for (size_t i = 0; i < kNumReaders; i++) {
      readers.push_back(
          MakeUnique<ReaderThread>(d_read, &messages_read[i], &bytes_read[i]));
    }

    // Start writers.
    for (size_t i = 0; i < kNumWriters; i++)
      writers[i]->Start();

    // Start readers.
    for (size_t i = 0; i < kNumReaders; i++)
      readers[i]->Start();

    // TODO(vtl): Maybe I should have an event that triggers all the threads to
    // start doing stuff for real (so that the first ones created/started aren't
    // advantaged).
  }  // Joins all the threads.

  size_t total_messages_written = 0;
  size_t total_bytes_written = 0;
  for (size_t i = 0; i < kNumWriters; i++) {
    total_messages_written += messages_written[i];
    total_bytes_written += bytes_written[i];
  }
  size_t total_messages_read = 0;
  size_t total_bytes_read = 0;
  for (size_t i = 0; i < kNumReaders; i++) {
    total_messages_read += messages_read[i];
    total_bytes_read += bytes_read[i];
    // We'd have to be really unlucky to have read no messages on a thread.
    EXPECT_GT(messages_read[i], 0u) << "reader: " << i;
    EXPECT_GE(bytes_read[i], messages_read[i]) << "reader: " << i;
  }
  EXPECT_EQ(total_messages_written, total_messages_read);
  EXPECT_EQ(total_bytes_written, total_bytes_read);

  EXPECT_EQ(MOJO_RESULT_OK, d_write->Close());
  EXPECT_EQ(MOJO_RESULT_OK, d_read->Close());
}

}  // namespace
}  // namespace system
}  // namespace mojo
