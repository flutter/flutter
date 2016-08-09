// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/message_pipe.h"

#include "mojo/edk/system/waiter.h"
#include "mojo/edk/system/waiter_test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace system {
namespace {

const MojoHandleSignals kAllSignals = MOJO_HANDLE_SIGNAL_READABLE |
                                      MOJO_HANDLE_SIGNAL_WRITABLE |
                                      MOJO_HANDLE_SIGNAL_PEER_CLOSED;

// Tests:
//  - only default flags
//  - reading messages from a port
//    - when there are no/one/two messages available for that port
//    - with buffer size 0 (and null buffer) -- should get size
//    - with too-small buffer -- should get size
//    - also verify that buffers aren't modified when/where they shouldn't be
//  - writing messages to a port
//    - in the obvious scenarios (as above)
//    - to a port that's been closed
//  - writing a message to a port, closing the other (would be the source) port,
//    and reading it
TEST(MessagePipeTest, Basic) {
  auto mp = MessagePipe::CreateLocalLocal();

  int32_t buffer[2];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;

  // Nothing to read yet on port 0.
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kBufferSize, buffer_size);
  EXPECT_EQ(123, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Ditto for port 1.
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));

  // Write from port 1 (to port 0).
  buffer[0] = 789012345;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(1, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Read from port 0.
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);
  EXPECT_EQ(789012345, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Read again from port 0 -- it should be empty.
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));

  // Write two messages from port 0 (to port 1).
  buffer[0] = 123456789;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));
  buffer[0] = 234567890;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Read from port 1 with buffer size 0 (should get the size of next message).
  // Also test that giving a null buffer is okay when the buffer size is 0.
  buffer_size = 0;
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            mp->ReadMessage(1, NullUserPointer(), MakeUserPointer(&buffer_size),
                            0, nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);

  // Read from port 1 with buffer size 1 (too small; should get the size of next
  // message).
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = 1;
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);
  EXPECT_EQ(123, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Read from port 1.
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);
  EXPECT_EQ(123456789, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Read again from port 1.
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);
  EXPECT_EQ(234567890, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Read again from port 1 -- it should be empty.
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));

  // Write from port 0 (to port 1).
  buffer[0] = 345678901;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Close port 0.
  mp->Close(0);

  // Try to write from port 1 (to port 0).
  buffer[0] = 456789012;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            mp->WriteMessage(1, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Read from port 1; should still get message (even though port 0 was closed).
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);
  EXPECT_EQ(345678901, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Read again from port 1 -- it should be empty (and port 0 is closed).
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));

  mp->Close(1);
}

TEST(MessagePipeTest, CloseWithQueuedIncomingMessages) {
  auto mp = MessagePipe::CreateLocalLocal();

  int32_t buffer[1];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;

  // Write some messages from port 1 (to port 0).
  for (int32_t i = 0; i < 5; i++) {
    buffer[0] = i;
    EXPECT_EQ(MOJO_RESULT_OK,
              mp->WriteMessage(1, UserPointer<const void>(buffer), kBufferSize,
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));
  }

  // Port 0 shouldn't be empty.
  buffer_size = 0;
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            mp->ReadMessage(0, NullUserPointer(), MakeUserPointer(&buffer_size),
                            0, nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kBufferSize, buffer_size);

  // Close port 0 first, which should have outstanding (incoming) messages.
  mp->Close(0);
  mp->Close(1);
}

TEST(MessagePipeTest, DiscardMode) {
  auto mp = MessagePipe::CreateLocalLocal();

  int32_t buffer[2];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;

  // Write from port 1 (to port 0).
  buffer[0] = 789012345;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(1, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Read/discard from port 0 (no buffer); get size.
  buffer_size = 0;
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            mp->ReadMessage(0, NullUserPointer(), MakeUserPointer(&buffer_size),
                            0, nullptr, MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);

  // Read again from port 0 -- it should be empty.
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));

  // Write from port 1 (to port 0).
  buffer[0] = 890123456;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(1, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Read from port 0 (buffer big enough).
  buffer[0] = 123;
  buffer[1] = 456;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);
  EXPECT_EQ(890123456, buffer[0]);
  EXPECT_EQ(456, buffer[1]);

  // Read again from port 0 -- it should be empty.
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));

  // Write from port 1 (to port 0).
  buffer[0] = 901234567;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(1, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Read/discard from port 0 (buffer too small); get size.
  buffer_size = 1;
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(buffer[0])), buffer_size);

  // Read again from port 0 -- it should be empty.
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));

  // Write from port 1 (to port 0).
  buffer[0] = 123456789;
  buffer[1] = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(1, UserPointer<const void>(buffer),
                             static_cast<uint32_t>(sizeof(buffer[0])), nullptr,
                             MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Discard from port 0.
  buffer_size = 1;
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            mp->ReadMessage(0, NullUserPointer(), NullUserPointer(), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));

  // Read again from port 0 -- it should be empty.
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            mp->ReadMessage(0, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));

  mp->Close(0);
  mp->Close(1);
}

TEST(MessagePipeTest, BasicWaiting) {
  auto mp = MessagePipe::CreateLocalLocal();
  Waiter waiter;
  HandleSignalsState hss;

  int32_t buffer[1];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t buffer_size;

  // Always writable (until the other port is closed).
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      mp->AddAwakable(0, &waiter, 0, false, MOJO_HANDLE_SIGNAL_WRITABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      mp->AddAwakable(0, &waiter, 0, false,
                      MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
                      &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Not yet readable.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            mp->AddAwakable(0, &waiter, 1, false, MOJO_HANDLE_SIGNAL_READABLE,
                            nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr, nullptr));
  hss = HandleSignalsState();
  mp->RemoveAwakable(0, false, &waiter, 0, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // The peer is not closed.
  waiter.Init();
  ASSERT_EQ(MOJO_RESULT_OK,
            mp->AddAwakable(0, &waiter, 2, false,
                            MOJO_HANDLE_SIGNAL_PEER_CLOSED, nullptr));
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED, waiter.Wait(0, nullptr, nullptr));
  hss = HandleSignalsState();
  mp->RemoveAwakable(0, false, &waiter, 0, &hss);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Write from port 0 (to port 1), to make port 1 readable.
  buffer[0] = 123456789;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->WriteMessage(0, UserPointer<const void>(buffer), kBufferSize,
                             nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Port 1 should already be readable now.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      mp->AddAwakable(1, &waiter, 3, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      mp->AddAwakable(1, &waiter, 0, false,
                      MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
                      &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  // ... and still writable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      mp->AddAwakable(1, &waiter, 4, false, MOJO_HANDLE_SIGNAL_WRITABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

  // Close port 0.
  mp->Close(0);

  // Port 1 should be signaled with peer closed.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_ALREADY_EXISTS,
            mp->AddAwakable(1, &waiter, 5, false,
                            MOJO_HANDLE_SIGNAL_PEER_CLOSED, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Port 1 should not be writable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      mp->AddAwakable(1, &waiter, 6, false, MOJO_HANDLE_SIGNAL_WRITABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // But it should still be readable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(
      MOJO_RESULT_ALREADY_EXISTS,
      mp->AddAwakable(1, &waiter, 7, false, MOJO_HANDLE_SIGNAL_READABLE, &hss));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Read from port 1.
  buffer[0] = 0;
  buffer_size = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            mp->ReadMessage(1, UserPointer<void>(buffer),
                            MakeUserPointer(&buffer_size), 0, nullptr,
                            MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(123456789, buffer[0]);

  // Now port 1 should no longer be readable.
  waiter.Init();
  hss = HandleSignalsState();
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            mp->AddAwakable(1, &waiter, 8, false, MOJO_HANDLE_SIGNAL_READABLE,
                            nullptr));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);

  mp->Close(1);
}

TEST(MessagePipeTest, ThreadedWaiting) {
  int32_t buffer[1];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));

  MojoResult result;
  uint64_t context;

  // Write to wake up waiter waiting for read.
  {
    auto mp = MessagePipe::CreateLocalLocal();
    test::SimpleWaiterThread thread(&result, &context);

    thread.waiter()->Init();
    ASSERT_EQ(MOJO_RESULT_OK,
              mp->AddAwakable(1, thread.waiter(), 1, false,
                              MOJO_HANDLE_SIGNAL_READABLE, nullptr));
    thread.Start();

    buffer[0] = 123456789;
    // Write from port 0 (to port 1), which should wake up the waiter.
    EXPECT_EQ(MOJO_RESULT_OK,
              mp->WriteMessage(0, UserPointer<const void>(buffer), kBufferSize,
                               nullptr, MOJO_WRITE_MESSAGE_FLAG_NONE));

    HandleSignalsState hss;
    mp->RemoveAwakable(1, false, thread.waiter(), 0, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
              hss.satisfied_signals);
    EXPECT_EQ(kAllSignals, hss.satisfiable_signals);

    mp->Close(0);
    mp->Close(1);
  }  // Joins |thread|.
  // The waiter should have woken up successfully.
  EXPECT_EQ(MOJO_RESULT_OK, result);
  EXPECT_EQ(1u, context);

  // Close to cancel waiter.
  {
    auto mp = MessagePipe::CreateLocalLocal();
    test::SimpleWaiterThread thread(&result, &context);

    thread.waiter()->Init();
    ASSERT_EQ(MOJO_RESULT_OK,
              mp->AddAwakable(1, thread.waiter(), 2, false,
                              MOJO_HANDLE_SIGNAL_READABLE, nullptr));
    thread.Start();

    // Close port 1 first -- this should result in the waiter being cancelled.
    mp->CancelAllState(1);
    mp->Close(1);

    // Port 1 is closed, so |Dispatcher::RemoveAwakable()| wouldn't call into
    // the |MessagePipe| to remove any waiter.

    mp->Close(0);
  }  // Joins |thread|.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
  EXPECT_EQ(2u, context);

  // Close to cancel waiter using peer closed signal.
  {
    auto mp = MessagePipe::CreateLocalLocal();
    test::SimpleWaiterThread thread(&result, &context);

    thread.waiter()->Init();
    ASSERT_EQ(MOJO_RESULT_OK,
              mp->AddAwakable(1, thread.waiter(), 3, false,
                              MOJO_HANDLE_SIGNAL_PEER_CLOSED, nullptr));
    thread.Start();

    // Close port 1 first -- this should result in the waiter being cancelled.
    mp->CancelAllState(1);
    mp->Close(1);

    // Port 1 is closed, so |Dispatcher::RemoveAwakable()| wouldn't call into
    // the |MessagePipe| to remove any waiter.

    mp->Close(0);
  }  // Joins |thread|.
  EXPECT_EQ(MOJO_RESULT_CANCELLED, result);
  EXPECT_EQ(3u, context);

  // Close to make waiter un-wake-up-able.
  {
    auto mp = MessagePipe::CreateLocalLocal();
    test::SimpleWaiterThread thread(&result, &context);

    thread.waiter()->Init();
    ASSERT_EQ(MOJO_RESULT_OK,
              mp->AddAwakable(1, thread.waiter(), 4, false,
                              MOJO_HANDLE_SIGNAL_READABLE, nullptr));
    thread.Start();

    // Close port 0 first -- this should wake the waiter up, since port 1 will
    // never be readable.
    mp->CancelAllState(0);
    mp->Close(0);

    HandleSignalsState hss;
    mp->RemoveAwakable(1, false, thread.waiter(), 0, &hss);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
    EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

    mp->CancelAllState(1);
    mp->Close(1);
  }  // Joins |thread|.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION, result);
  EXPECT_EQ(4u, context);
}

}  // namespace
}  // namespace system
}  // namespace mojo
