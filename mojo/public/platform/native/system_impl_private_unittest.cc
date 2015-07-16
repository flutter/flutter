// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file tests the C API, but using the explicit MojoSystemImpl parameter.

#include <string.h>

#include "mojo/public/c/system/core.h"
#include "mojo/public/platform/native/system_impl_private.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace mojo {
namespace {

const MojoHandleSignals kSignalReadadableWritable =
    MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE;

const MojoHandleSignals kSignalAll = MOJO_HANDLE_SIGNAL_READABLE |
                                     MOJO_HANDLE_SIGNAL_WRITABLE |
                                     MOJO_HANDLE_SIGNAL_PEER_CLOSED;

TEST(SystemImplTest, GetTimeTicksNow) {
  MojoSystemImpl system = MojoSystemImplCreateImpl();
  const MojoTimeTicks start = MojoSystemImplGetTimeTicksNow(system);
  EXPECT_NE(static_cast<MojoTimeTicks>(0), start)
      << "MojoGetTimeTicksNow should return nonzero value";

  // SystemImpl is leaked...
}

TEST(SystemImplTest, BasicMessagePipe) {
  MojoSystemImpl sys0 = MojoSystemImplCreateImpl();
  MojoSystemImpl sys1 = MojoSystemImplCreateImpl();
  EXPECT_NE(sys0, sys1);

  MojoHandle h0, h1;
  MojoHandleSignals sig;
  char buffer[10] = {0};
  uint32_t buffer_size;

  h0 = MOJO_HANDLE_INVALID;
  h1 = MOJO_HANDLE_INVALID;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplCreateMessagePipe(sys0, nullptr, &h0, &h1));
  EXPECT_NE(h0, MOJO_HANDLE_INVALID);
  EXPECT_NE(h1, MOJO_HANDLE_INVALID);

  // Move the other end of the pipe to a different SystemImpl.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplTransferHandle(sys0, h1, sys1, &h1));
  EXPECT_NE(h1, MOJO_HANDLE_INVALID);

  // Shouldn't be readable, we haven't written anything.
  MojoHandleSignalsState state;
  EXPECT_EQ(
      MOJO_RESULT_DEADLINE_EXCEEDED,
      MojoSystemImplWait(sys0, h0, MOJO_HANDLE_SIGNAL_READABLE, 0, &state));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Should be writable.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoSystemImplWait(sys0, h0, MOJO_HANDLE_SIGNAL_WRITABLE, 0, &state));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Last parameter is optional.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoSystemImplWait(sys0, h0, MOJO_HANDLE_SIGNAL_WRITABLE, 0, nullptr));

  // Try to read.
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            MojoSystemImplReadMessage(sys0, h0, buffer, &buffer_size, nullptr,
                                      nullptr, MOJO_READ_MESSAGE_FLAG_NONE));

  // Write to |h1|.
  static const char kHello[] = "hello";
  buffer_size = static_cast<uint32_t>(sizeof(kHello));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplWriteMessage(sys1, h1, kHello, buffer_size, nullptr,
                                       0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // |h0| should be readable.
  uint32_t result_index = 1;
  MojoHandleSignalsState states[1];
  sig = MOJO_HANDLE_SIGNAL_READABLE;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplWaitMany(sys0, &h0, &sig, 1, MOJO_DEADLINE_INDEFINITE,
                                   &result_index, states));

  EXPECT_EQ(0u, result_index);
  EXPECT_EQ(kSignalReadadableWritable, states[0].satisfied_signals);
  EXPECT_EQ(kSignalAll, states[0].satisfiable_signals);

  // Read from |h0|.
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplReadMessage(sys0, h0, buffer, &buffer_size, nullptr,
                                      nullptr, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(static_cast<uint32_t>(sizeof(kHello)), buffer_size);
  EXPECT_STREQ(kHello, buffer);

  // |h0| should no longer be readable.
  EXPECT_EQ(
      MOJO_RESULT_DEADLINE_EXCEEDED,
      MojoSystemImplWait(sys0, h0, MOJO_HANDLE_SIGNAL_READABLE, 10, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, state.satisfied_signals);
  EXPECT_EQ(kSignalAll, state.satisfiable_signals);

  // Close |h0|.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplClose(sys0, h0));

  // |h1| should no longer be readable or writable.
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            MojoSystemImplWait(sys1, h1, MOJO_HANDLE_SIGNAL_READABLE |
                                             MOJO_HANDLE_SIGNAL_WRITABLE,
                               1000, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, state.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, state.satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplClose(sys1, h1));

  // 2 SystemImpls are leaked...
}

TEST(SystemImplTest, BasicDataPipe) {
  MojoSystemImpl sys0 = MojoSystemImplCreateImpl();
  MojoSystemImpl sys1 = MojoSystemImplCreateImpl();
  EXPECT_NE(sys0, sys1);

  MojoHandle hp, hc;
  MojoHandleSignals sig;
  char buffer[20] = {0};
  uint32_t buffer_size;
  void* write_pointer;
  const void* read_pointer;

  hp = MOJO_HANDLE_INVALID;
  hc = MOJO_HANDLE_INVALID;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplCreateDataPipe(sys0, nullptr, &hp, &hc));
  EXPECT_NE(hp, MOJO_HANDLE_INVALID);
  EXPECT_NE(hc, MOJO_HANDLE_INVALID);

  // Move the other end of the pipe to a different SystemImpl.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplTransferHandle(sys0, hc, sys1, &hc));
  EXPECT_NE(hc, MOJO_HANDLE_INVALID);

  // The consumer |hc| shouldn't be readable.
  MojoHandleSignalsState state;
  EXPECT_EQ(
      MOJO_RESULT_DEADLINE_EXCEEDED,
      MojoSystemImplWait(sys1, hc, MOJO_HANDLE_SIGNAL_READABLE, 0, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_NONE, state.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            state.satisfiable_signals);

  // The producer |hp| should be writable.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoSystemImplWait(sys0, hp, MOJO_HANDLE_SIGNAL_WRITABLE, 0, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, state.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            state.satisfiable_signals);

  // Try to read from |hc|.
  buffer_size = static_cast<uint32_t>(sizeof(buffer));
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            MojoSystemImplReadData(sys1, hc, buffer, &buffer_size,
                                   MOJO_READ_DATA_FLAG_NONE));

  // Try to begin a two-phase read from |hc|.
  read_pointer = nullptr;
  EXPECT_EQ(MOJO_RESULT_SHOULD_WAIT,
            MojoSystemImplBeginReadData(sys1, hc, &read_pointer, &buffer_size,
                                        MOJO_READ_DATA_FLAG_NONE));

  // Write to |hp|.
  static const char kHello[] = "hello ";
  // Don't include terminating null.
  buffer_size = static_cast<uint32_t>(strlen(kHello));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplWriteData(sys0, hp, kHello, &buffer_size,
                                    MOJO_WRITE_MESSAGE_FLAG_NONE));

  // |hc| should be(come) readable.
  uint32_t result_index = 1;
  MojoHandleSignalsState states[1];
  sig = MOJO_HANDLE_SIGNAL_READABLE;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplWaitMany(sys1, &hc, &sig, 1, MOJO_DEADLINE_INDEFINITE,
                                   &result_index, states));

  EXPECT_EQ(0u, result_index);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, states[0].satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            states[0].satisfiable_signals);

  // Do a two-phase write to |hp|.
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplBeginWriteData(sys0, hp, &write_pointer, &buffer_size,
                                         MOJO_WRITE_DATA_FLAG_NONE));
  static const char kWorld[] = "world";
  ASSERT_GE(buffer_size, sizeof(kWorld));
  // Include the terminating null.
  memcpy(write_pointer, kWorld, sizeof(kWorld));
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplEndWriteData(sys0, hp,
                                       static_cast<uint32_t>(sizeof(kWorld))));

  // Read one character from |hc|.
  memset(buffer, 0, sizeof(buffer));
  buffer_size = 1;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplReadData(sys1, hc, buffer, &buffer_size,
                                   MOJO_READ_DATA_FLAG_NONE));

  // Close |hp|.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplClose(sys0, hp));

  // |hc| should still be readable.
  EXPECT_EQ(
      MOJO_RESULT_OK,
      MojoSystemImplWait(sys1, hc, MOJO_HANDLE_SIGNAL_READABLE, 0, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            state.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            state.satisfiable_signals);

  // Do a two-phase read from |hc|.
  read_pointer = nullptr;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplBeginReadData(sys1, hc, &read_pointer, &buffer_size,
                                        MOJO_READ_DATA_FLAG_NONE));
  ASSERT_LE(buffer_size, sizeof(buffer) - 1);
  memcpy(&buffer[1], read_pointer, buffer_size);
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplEndReadData(sys1, hc, buffer_size));
  EXPECT_STREQ("hello world", buffer);

  // |hc| should no longer be readable.
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      MojoSystemImplWait(sys1, hc, MOJO_HANDLE_SIGNAL_READABLE, 1000, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, state.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, state.satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplClose(sys1, hc));

  // TODO(vtl): Test the other way around -- closing the consumer should make
  // the producer never-writable?

  // 2 SystemImpls are leaked...
}

TEST(SystemImplTest, BasicSharedBuffer) {
  MojoSystemImpl sys0 = MojoSystemImplCreateImpl();
  MojoSystemImpl sys1 = MojoSystemImplCreateImpl();
  EXPECT_NE(sys0, sys1);

  MojoHandle h0, h1;
  void* pointer;

  // Create a shared buffer (|h0|).
  h0 = MOJO_HANDLE_INVALID;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplCreateSharedBuffer(sys0, nullptr, 100, &h0));
  EXPECT_NE(h0, MOJO_HANDLE_INVALID);

  // Map everything.
  pointer = nullptr;
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplMapBuffer(sys0, h0, 0, 100, &pointer,
                                                    MOJO_MAP_BUFFER_FLAG_NONE));
  ASSERT_TRUE(pointer);
  static_cast<char*>(pointer)[50] = 'x';

  // Duplicate |h0| to |h1|.
  h1 = MOJO_HANDLE_INVALID;
  EXPECT_EQ(MOJO_RESULT_OK,
            MojoSystemImplDuplicateBufferHandle(sys0, h0, nullptr, &h1));
  EXPECT_NE(h1, MOJO_HANDLE_INVALID);

  // Move the other end of the pipe to a different SystemImpl.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplTransferHandle(sys0, h1, sys1, &h1));
  EXPECT_NE(h1, MOJO_HANDLE_INVALID);

  // Close |h0|.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplClose(sys0, h0));

  // The mapping should still be good.
  static_cast<char*>(pointer)[51] = 'y';

  // Unmap it.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplUnmapBuffer(sys0, pointer));

  // Map half of |h1|.
  pointer = nullptr;
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplMapBuffer(sys1, h1, 50, 50, &pointer,
                                                    MOJO_MAP_BUFFER_FLAG_NONE));
  ASSERT_TRUE(pointer);

  // It should have what we wrote.
  EXPECT_EQ('x', static_cast<char*>(pointer)[0]);
  EXPECT_EQ('y', static_cast<char*>(pointer)[1]);

  // Unmap it.
  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplUnmapBuffer(sys1, pointer));

  EXPECT_EQ(MOJO_RESULT_OK, MojoSystemImplClose(sys1, h1));

  // 2 SystemImpls are leaked...
}

}  // namespace
}  // namespace mojo
