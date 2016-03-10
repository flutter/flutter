// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/core.h"

#include <stdint.h>

#include <limits>

#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/awakable.h"
#include "mojo/edk/system/core_test_base.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/public/cpp/system/macros.h"

using mojo::platform::ThreadSleep;

namespace mojo {
namespace system {
namespace {

const MojoHandleSignalsState kEmptyMojoHandleSignalsState = {0u, 0u};
const MojoHandleSignalsState kFullMojoHandleSignalsState = {~0u, ~0u};
const MojoHandleSignals kAllSignals = MOJO_HANDLE_SIGNAL_READABLE |
                                      MOJO_HANDLE_SIGNAL_WRITABLE |
                                      MOJO_HANDLE_SIGNAL_PEER_CLOSED;

using CoreTest = test::CoreTestBase;

TEST_F(CoreTest, GetTimeTicksNow) {
  const MojoTimeTicks start = core()->GetTimeTicksNow();
  EXPECT_NE(static_cast<MojoTimeTicks>(0), start)
      << "GetTimeTicksNow should return nonzero value";
  ThreadSleep(test::DeadlineFromMilliseconds(15u));
  const MojoTimeTicks finish = core()->GetTimeTicksNow();
  // Allow for some fuzz in sleep.
  EXPECT_GE((finish - start), static_cast<MojoTimeTicks>(8000))
      << "Sleeping should result in increasing time ticks";
}

TEST_F(CoreTest, Basic) {
  MockHandleInfo info;

  EXPECT_EQ(0u, info.GetCtorCallCount());
  MojoHandle h = CreateMockHandle(&info);
  EXPECT_EQ(1u, info.GetCtorCallCount());
  EXPECT_NE(h, MOJO_HANDLE_INVALID);

  EXPECT_EQ(0u, info.GetWriteMessageCallCount());
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h, NullUserPointer(), 0, NullUserPointer(), 0,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(1u, info.GetWriteMessageCallCount());

  EXPECT_EQ(0u, info.GetReadMessageCallCount());
  uint32_t num_bytes = 0;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      core()->ReadMessage(h, NullUserPointer(), MakeUserPointer(&num_bytes),
                          NullUserPointer(), NullUserPointer(),
                          MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(1u, info.GetReadMessageCallCount());
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(h, NullUserPointer(), NullUserPointer(),
                                NullUserPointer(), NullUserPointer(),
                                MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(2u, info.GetReadMessageCallCount());

  EXPECT_EQ(0u, info.GetWriteDataCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
            core()->WriteData(h, NullUserPointer(), NullUserPointer(),
                              MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(1u, info.GetWriteDataCallCount());

  EXPECT_EQ(0u, info.GetBeginWriteDataCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
            core()->BeginWriteData(h, NullUserPointer(), NullUserPointer(),
                                   MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(1u, info.GetBeginWriteDataCallCount());

  EXPECT_EQ(0u, info.GetEndWriteDataCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED, core()->EndWriteData(h, 0));
  EXPECT_EQ(1u, info.GetEndWriteDataCallCount());

  EXPECT_EQ(0u, info.GetReadDataCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
            core()->ReadData(h, NullUserPointer(), NullUserPointer(),
                             MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(1u, info.GetReadDataCallCount());

  EXPECT_EQ(0u, info.GetBeginReadDataCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
            core()->BeginReadData(h, NullUserPointer(), NullUserPointer(),
                                  MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(1u, info.GetBeginReadDataCallCount());

  EXPECT_EQ(0u, info.GetEndReadDataCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED, core()->EndReadData(h, 0));
  EXPECT_EQ(1u, info.GetEndReadDataCallCount());

  EXPECT_EQ(0u, info.GetDuplicateBufferHandleCallCount());
  EXPECT_EQ(
      MOJO_RESULT_UNIMPLEMENTED,
      core()->DuplicateBufferHandle(h, NullUserPointer(), NullUserPointer()));
  EXPECT_EQ(1u, info.GetDuplicateBufferHandleCallCount());

  EXPECT_EQ(0u, info.GetGetBufferInformationCallCount());
  EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
            core()->GetBufferInformation(h, NullUserPointer(), 0));
  EXPECT_EQ(1u, info.GetGetBufferInformationCallCount());

  EXPECT_EQ(0u, info.GetMapBufferCallCount());
  EXPECT_EQ(
      MOJO_RESULT_UNIMPLEMENTED,
      core()->MapBuffer(h, 0, 0, NullUserPointer(), MOJO_MAP_BUFFER_FLAG_NONE));
  EXPECT_EQ(1u, info.GetMapBufferCallCount());

  EXPECT_EQ(0u, info.GetAddAwakableCallCount());
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->Wait(h, ~MOJO_HANDLE_SIGNAL_NONE, MOJO_DEADLINE_INDEFINITE,
                         NullUserPointer()));
  EXPECT_EQ(1u, info.GetAddAwakableCallCount());
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->Wait(h, ~MOJO_HANDLE_SIGNAL_NONE, 0, NullUserPointer()));
  EXPECT_EQ(2u, info.GetAddAwakableCallCount());
  MojoHandleSignalsState hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->Wait(h, ~MOJO_HANDLE_SIGNAL_NONE, MOJO_DEADLINE_INDEFINITE,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(3u, info.GetAddAwakableCallCount());
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->Wait(h, ~MOJO_HANDLE_SIGNAL_NONE, 10 * 1000, NullUserPointer()));
  EXPECT_EQ(4u, info.GetAddAwakableCallCount());
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->Wait(h, ~MOJO_HANDLE_SIGNAL_NONE, 10 * 1000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(5u, info.GetAddAwakableCallCount());
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);

  MojoHandleSignals handle_signals = ~MOJO_HANDLE_SIGNAL_NONE;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->WaitMany(MakeUserPointer(&h), MakeUserPointer(&handle_signals), 1,
                       MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                       NullUserPointer()));
  EXPECT_EQ(6u, info.GetAddAwakableCallCount());
  uint32_t result_index = static_cast<uint32_t>(-1);
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->WaitMany(MakeUserPointer(&h), MakeUserPointer(&handle_signals), 1,
                       MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                       NullUserPointer()));
  EXPECT_EQ(7u, info.GetAddAwakableCallCount());
  EXPECT_EQ(0u, result_index);
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->WaitMany(MakeUserPointer(&h), MakeUserPointer(&handle_signals), 1,
                       MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                       MakeUserPointer(&hss)));
  EXPECT_EQ(8u, info.GetAddAwakableCallCount());
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);
  result_index = static_cast<uint32_t>(-1);
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->WaitMany(MakeUserPointer(&h), MakeUserPointer(&handle_signals), 1,
                       MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                       MakeUserPointer(&hss)));
  EXPECT_EQ(9u, info.GetAddAwakableCallCount());
  EXPECT_EQ(0u, result_index);
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(0u, hss.satisfiable_signals);

  EXPECT_EQ(0u, info.GetDtorCallCount());
  EXPECT_EQ(0u, info.GetCloseCallCount());
  EXPECT_EQ(0u, info.GetCancelAllAwakablesCallCount());
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
  EXPECT_EQ(1u, info.GetCancelAllAwakablesCallCount());
  EXPECT_EQ(1u, info.GetCloseCallCount());
  EXPECT_EQ(1u, info.GetDtorCallCount());

  // No awakables should ever have ever been added.
  EXPECT_EQ(0u, info.GetRemoveAwakableCallCount());
}

TEST_F(CoreTest, InvalidArguments) {
  // |Close()|:
  {
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(MOJO_HANDLE_INVALID));
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(10));
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(1000000000));

    // Test a double-close.
    MockHandleInfo info;
    MojoHandle h = CreateMockHandle(&info);
    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
    EXPECT_EQ(1u, info.GetCloseCallCount());
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(h));
    EXPECT_EQ(1u, info.GetCloseCallCount());
  }

  // |Wait()|:
  {
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->Wait(MOJO_HANDLE_INVALID, ~MOJO_HANDLE_SIGNAL_NONE,
                           MOJO_DEADLINE_INDEFINITE, NullUserPointer()));
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->Wait(10, ~MOJO_HANDLE_SIGNAL_NONE,
                           MOJO_DEADLINE_INDEFINITE, NullUserPointer()));

    MojoHandleSignalsState hss = kFullMojoHandleSignalsState;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->Wait(MOJO_HANDLE_INVALID, ~MOJO_HANDLE_SIGNAL_NONE,
                           MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&hss)));
    // On invalid argument, it shouldn't modify the handle signals state.
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfied_signals,
              hss.satisfied_signals);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfiable_signals,
              hss.satisfiable_signals);
    hss = kFullMojoHandleSignalsState;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->Wait(10, ~MOJO_HANDLE_SIGNAL_NONE,
                           MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&hss)));
    // On invalid argument, it shouldn't modify the handle signals state.
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfied_signals,
              hss.satisfied_signals);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfiable_signals,
              hss.satisfiable_signals);
  }

  // |WaitMany()|:
  {
    MojoHandle handles[2] = {MOJO_HANDLE_INVALID, MOJO_HANDLE_INVALID};
    MojoHandleSignals signals[2] = {~MOJO_HANDLE_SIGNAL_NONE,
                                    ~MOJO_HANDLE_SIGNAL_NONE};
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->WaitMany(MakeUserPointer(handles), MakeUserPointer(signals), 0,
                         MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                         NullUserPointer()));
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->WaitMany(NullUserPointer(), MakeUserPointer(signals), 0,
                               MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                               NullUserPointer()));
    // If |num_handles| is invalid, it should leave |result_index| and
    // |signals_states| alone.
    // (We use -1 internally; make sure that doesn't leak.)
    uint32_t result_index = 123;
    MojoHandleSignalsState hss = kFullMojoHandleSignalsState;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->WaitMany(NullUserPointer(), MakeUserPointer(signals), 0,
                               MOJO_DEADLINE_INDEFINITE,
                               MakeUserPointer(&result_index),
                               MakeUserPointer(&hss)));
    EXPECT_EQ(123u, result_index);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfied_signals,
              hss.satisfied_signals);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfiable_signals,
              hss.satisfiable_signals);

    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->WaitMany(MakeUserPointer(handles), NullUserPointer(), 0,
                               MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                               NullUserPointer()));
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->WaitMany(MakeUserPointer(handles), MakeUserPointer(signals), 1,
                         MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                         NullUserPointer()));
    // But if a handle is bad, then it should set |result_index| but still leave
    // |signals_states| alone.
    result_index = static_cast<uint32_t>(-1);
    hss = kFullMojoHandleSignalsState;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->WaitMany(
                  MakeUserPointer(handles), MakeUserPointer(signals), 1,
                  MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                  MakeUserPointer(&hss)));
    EXPECT_EQ(0u, result_index);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfied_signals,
              hss.satisfied_signals);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfiable_signals,
              hss.satisfiable_signals);

    MockHandleInfo info[2];
    handles[0] = CreateMockHandle(&info[0]);

    result_index = static_cast<uint32_t>(-1);
    hss = kFullMojoHandleSignalsState;
    EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
              core()->WaitMany(
                  MakeUserPointer(handles), MakeUserPointer(signals), 1,
                  MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                  MakeUserPointer(&hss)));
    EXPECT_EQ(0u, result_index);
    EXPECT_EQ(0u, hss.satisfied_signals);
    EXPECT_EQ(0u, hss.satisfiable_signals);

    // On invalid argument, it'll leave |signals_states| alone.
    result_index = static_cast<uint32_t>(-1);
    hss = kFullMojoHandleSignalsState;
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->WaitMany(
                  MakeUserPointer(handles), MakeUserPointer(signals), 2,
                  MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                  MakeUserPointer(&hss)));
    EXPECT_EQ(1u, result_index);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfied_signals,
              hss.satisfied_signals);
    EXPECT_EQ(kFullMojoHandleSignalsState.satisfiable_signals,
              hss.satisfiable_signals);
    handles[1] = handles[0] + 1;  // Invalid handle.
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->WaitMany(MakeUserPointer(handles), MakeUserPointer(signals), 2,
                         MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                         NullUserPointer()));
    handles[1] = CreateMockHandle(&info[1]);
    EXPECT_EQ(
        MOJO_RESULT_FAILED_PRECONDITION,
        core()->WaitMany(MakeUserPointer(handles), MakeUserPointer(signals), 2,
                         MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                         NullUserPointer()));

    // TODO(vtl): Test one where we get "failed precondition" only for the
    // second handle (and the first one is valid to wait on).

    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(handles[0]));
    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(handles[1]));
  }

  // |CreateMessagePipe()|:
  {
    // Invalid options: unknown flag.
    const MojoCreateMessagePipeOptions kOptions = {
        static_cast<uint32_t>(sizeof(MojoCreateMessagePipeOptions)),
        ~MOJO_CREATE_MESSAGE_PIPE_OPTIONS_FLAG_NONE};
    MojoHandle handles[2] = {MOJO_HANDLE_INVALID, MOJO_HANDLE_INVALID};
    EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
              core()->CreateMessagePipe(MakeUserPointer(&kOptions),
                                        MakeUserPointer(&handles[0]),
                                        MakeUserPointer(&handles[1])));
    EXPECT_EQ(MOJO_HANDLE_INVALID, handles[0]);
    EXPECT_EQ(MOJO_HANDLE_INVALID, handles[1]);
  }

  // |WriteMessage()|:
  // Only check arguments checked by |Core|, namely |handle|, |handles|, and
  // |num_handles|.
  {
    EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
              core()->WriteMessage(MOJO_HANDLE_INVALID, NullUserPointer(), 0,
                                   NullUserPointer(), 0,
                                   MOJO_WRITE_MESSAGE_FLAG_NONE));

    MockHandleInfo info;
    MojoHandle h = CreateMockHandle(&info);
    MojoHandle handles[2] = {MOJO_HANDLE_INVALID, MOJO_HANDLE_INVALID};

    // Huge handle count (implausibly big on some systems -- more than can be
    // stored in a 32-bit address space).
    // Note: This may return either |MOJO_RESULT_INVALID_ARGUMENT| or
    // |MOJO_RESULT_RESOURCE_EXHAUSTED|, depending on whether it's plausible or
    // not.
    EXPECT_NE(
        MOJO_RESULT_OK,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             std::numeric_limits<uint32_t>::max(),
                             MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(0u, info.GetWriteMessageCallCount());

    // Huge handle count (plausibly big).
    EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
              core()->WriteMessage(
                  h, NullUserPointer(), 0, MakeUserPointer(handles),
                  std::numeric_limits<uint32_t>::max() / sizeof(handles[0]),
                  MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(0u, info.GetWriteMessageCallCount());

    // Invalid handle in |handles|.
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             1, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(0u, info.GetWriteMessageCallCount());

    // Two invalid handles in |handles|.
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             2, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(0u, info.GetWriteMessageCallCount());

    // Can't send a handle over itself.
    handles[0] = h;
    EXPECT_EQ(
        MOJO_RESULT_BUSY,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             1, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(0u, info.GetWriteMessageCallCount());

    MockHandleInfo info2;
    MojoHandle h2 = CreateMockHandle(&info2);

    // This is "okay", but |MockDispatcher| doesn't implement it.
    handles[0] = h2;
    EXPECT_EQ(
        MOJO_RESULT_UNIMPLEMENTED,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             1, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(1u, info.GetWriteMessageCallCount());

    // One of the |handles| is still invalid.
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             2, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(1u, info.GetWriteMessageCallCount());

    // One of the |handles| is the same as |handle|.
    handles[1] = h;
    EXPECT_EQ(
        MOJO_RESULT_BUSY,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             2, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(1u, info.GetWriteMessageCallCount());

    // Can't send a handle twice in the same message.
    handles[1] = h2;
    EXPECT_EQ(
        MOJO_RESULT_BUSY,
        core()->WriteMessage(h, NullUserPointer(), 0, MakeUserPointer(handles),
                             2, MOJO_WRITE_MESSAGE_FLAG_NONE));
    EXPECT_EQ(1u, info.GetWriteMessageCallCount());

    // Note: Since we never successfully sent anything with it, |h2| should
    // still be valid.
    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h2));

    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
  }

  // |ReadMessage()|:
  // Only check arguments checked by |Core|, namely |handle|, |handles|, and
  // |num_handles|.
  {
    EXPECT_EQ(
        MOJO_RESULT_INVALID_ARGUMENT,
        core()->ReadMessage(MOJO_HANDLE_INVALID, NullUserPointer(),
                            NullUserPointer(), NullUserPointer(),
                            NullUserPointer(), MOJO_READ_MESSAGE_FLAG_NONE));

    MockHandleInfo info;
    MojoHandle h = CreateMockHandle(&info);

    // Okay.
    uint32_t handle_count = 0;
    EXPECT_EQ(MOJO_RESULT_OK,
              core()->ReadMessage(
                  h, NullUserPointer(), NullUserPointer(), NullUserPointer(),
                  MakeUserPointer(&handle_count), MOJO_READ_MESSAGE_FLAG_NONE));
    // Checked by |Core|, shouldn't go through to the dispatcher.
    EXPECT_EQ(1u, info.GetReadMessageCallCount());

    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
  }

  // |CreateDataPipe()|:
  {
    // Invalid options: unknown flag.
    const MojoCreateDataPipeOptions kOptions = {
        static_cast<uint32_t>(sizeof(MojoCreateDataPipeOptions)),
        ~MOJO_CREATE_DATA_PIPE_OPTIONS_FLAG_NONE, 1u, 0u};
    MojoHandle handles[2] = {MOJO_HANDLE_INVALID, MOJO_HANDLE_INVALID};
    EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
              core()->CreateDataPipe(MakeUserPointer(&kOptions),
                                     MakeUserPointer(&handles[0]),
                                     MakeUserPointer(&handles[1])));
    EXPECT_EQ(MOJO_HANDLE_INVALID, handles[0]);
    EXPECT_EQ(MOJO_HANDLE_INVALID, handles[1]);
  }

  // |WriteData()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->WriteData(MOJO_HANDLE_INVALID, NullUserPointer(),
                              NullUserPointer(), MOJO_WRITE_DATA_FLAG_NONE));

  // |BeginWriteData()|:
  EXPECT_EQ(
      MOJO_RESULT_INVALID_ARGUMENT,
      core()->BeginWriteData(MOJO_HANDLE_INVALID, NullUserPointer(),
                             NullUserPointer(), MOJO_WRITE_DATA_FLAG_NONE));

  // |EndWriteData()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->EndWriteData(MOJO_HANDLE_INVALID, 0u));

  // |ReadData()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->ReadData(MOJO_HANDLE_INVALID, NullUserPointer(),
                             NullUserPointer(), MOJO_READ_DATA_FLAG_NONE));

  // |BeginReadData()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->BeginReadData(MOJO_HANDLE_INVALID, NullUserPointer(),
                                  NullUserPointer(), MOJO_READ_DATA_FLAG_NONE));

  // |EndReadData()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->EndReadData(MOJO_HANDLE_INVALID, 0u));

  // |CreateSharedBuffer()|:
  {
    // Invalid options: unknown flag.
    const MojoCreateSharedBufferOptions kOptions = {
        static_cast<uint32_t>(sizeof(MojoCreateSharedBufferOptions)),
        ~MOJO_CREATE_SHARED_BUFFER_OPTIONS_FLAG_NONE};
    MojoHandle handle = MOJO_HANDLE_INVALID;
    EXPECT_EQ(MOJO_RESULT_UNIMPLEMENTED,
              core()->CreateSharedBuffer(MakeUserPointer(&kOptions), 4096u,
                                         MakeUserPointer(&handle)));
    EXPECT_EQ(MOJO_HANDLE_INVALID, handle);
  }

  // |DuplicateBufferHandle()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->DuplicateBufferHandle(
                MOJO_HANDLE_INVALID, NullUserPointer(), NullUserPointer()));

  // |GetBufferInformation()|:
  EXPECT_EQ(
      MOJO_RESULT_INVALID_ARGUMENT,
      core()->GetBufferInformation(MOJO_HANDLE_INVALID, NullUserPointer(), 0u));

  // |MapBuffer()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->MapBuffer(MOJO_HANDLE_INVALID, 0u, 0u, NullUserPointer(),
                              MOJO_MAP_BUFFER_FLAG_NONE));

  // |UnmapBuffer()|:
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->UnmapBuffer(NullUserPointer()));
}

// These test invalid arguments that should cause death if we're being paranoid
// about checking arguments (which we would want to do if, e.g., we were in a
// true "kernel" situation, but we might not want to do otherwise for
// performance reasons). Probably blatant errors like passing in null pointers
// (for required pointer arguments) will still cause death, but perhaps not
// predictably.
TEST_F(CoreTest, InvalidArgumentsDeath) {
  const char kMemoryCheckFailedRegex[] = "Check failed";

  // |WaitMany()|:
  {
    MojoHandle handle = MOJO_HANDLE_INVALID;
    MojoHandleSignals signals = ~MOJO_HANDLE_SIGNAL_NONE;
    EXPECT_DEATH_IF_SUPPORTED(
        core()->WaitMany(NullUserPointer(), MakeUserPointer(&signals), 1,
                         MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                         NullUserPointer()),
        kMemoryCheckFailedRegex);
    EXPECT_DEATH_IF_SUPPORTED(
        core()->WaitMany(MakeUserPointer(&handle), NullUserPointer(), 1,
                         MOJO_DEADLINE_INDEFINITE, NullUserPointer(),
                         NullUserPointer()),
        kMemoryCheckFailedRegex);
    // TODO(vtl): |result_index| and |signals_states| are optional. Test them
    // with non-null invalid pointers?
  }

  // |CreateMessagePipe()|:
  {
    MojoHandle h;
    EXPECT_DEATH_IF_SUPPORTED(
        core()->CreateMessagePipe(NullUserPointer(), NullUserPointer(),
                                  NullUserPointer()),
        kMemoryCheckFailedRegex);
    EXPECT_DEATH_IF_SUPPORTED(
        core()->CreateMessagePipe(NullUserPointer(), MakeUserPointer(&h),
                                  NullUserPointer()),
        kMemoryCheckFailedRegex);
    EXPECT_DEATH_IF_SUPPORTED(
        core()->CreateMessagePipe(NullUserPointer(), NullUserPointer(),
                                  MakeUserPointer(&h)),
        kMemoryCheckFailedRegex);
  }

  // |WriteMessage()|:
  // Only check arguments checked by |Core|, namely |handle|, |handles|, and
  // |num_handles|.
  {
    MockHandleInfo info;
    MojoHandle h = CreateMockHandle(&info);

    // Null |handles| with nonzero |num_handles|.
    EXPECT_DEATH_IF_SUPPORTED(
        core()->WriteMessage(h, NullUserPointer(), 0, NullUserPointer(), 1,
                             MOJO_WRITE_MESSAGE_FLAG_NONE),
        kMemoryCheckFailedRegex);

    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
  }

  // |ReadMessage()|:
  // Only check arguments checked by |Core|, namely |handle|, |handles|, and
  // |num_handles|.
  {
    MockHandleInfo info;
    MojoHandle h = CreateMockHandle(&info);

    uint32_t handle_count = 1;
    EXPECT_DEATH_IF_SUPPORTED(
        core()->ReadMessage(h, NullUserPointer(), NullUserPointer(),
                            NullUserPointer(), MakeUserPointer(&handle_count),
                            MOJO_READ_MESSAGE_FLAG_NONE),
        kMemoryCheckFailedRegex);

    EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
  }

  // TODO(vtl): Missing a bunch here.
}

// TODO(vtl): test |Wait()| and |WaitMany()| properly
//  - including |WaitMany()| with the same handle more than once (with
//    same/different signals)

TEST_F(CoreTest, MessagePipe) {
  MojoHandle h[2];
  MojoHandleSignalsState hss[2];
  uint32_t result_index;

  EXPECT_EQ(MOJO_RESULT_OK,
            core()->CreateMessagePipe(NullUserPointer(), MakeUserPointer(&h[0]),
                                      MakeUserPointer(&h[1])));
  // Should get two distinct, valid handles.
  EXPECT_NE(h[0], MOJO_HANDLE_INVALID);
  EXPECT_NE(h[1], MOJO_HANDLE_INVALID);
  EXPECT_NE(h[0], h[1]);

  // Neither should be readable.
  MojoHandleSignals signals[2] = {MOJO_HANDLE_SIGNAL_READABLE,
                                  MOJO_HANDLE_SIGNAL_READABLE};
  result_index = static_cast<uint32_t>(-1);
  hss[0] = kEmptyMojoHandleSignalsState;
  hss[1] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_DEADLINE_EXCEEDED,
      core()->WaitMany(MakeUserPointer(h), MakeUserPointer(signals), 2, 0,
                       MakeUserPointer(&result_index), MakeUserPointer(hss)));
  EXPECT_EQ(static_cast<uint32_t>(-1), result_index);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[0].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[0].satisfiable_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[1].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[1].satisfiable_signals);

  // Try to read anyway.
  char buffer[1] = {'a'};
  uint32_t buffer_size = 1;
  EXPECT_EQ(
      MOJO_RESULT_SHOULD_WAIT,
      core()->ReadMessage(h[0], UserPointer<void>(buffer),
                          MakeUserPointer(&buffer_size), NullUserPointer(),
                          NullUserPointer(), MOJO_READ_MESSAGE_FLAG_NONE));
  // Check that it left its inputs alone.
  EXPECT_EQ('a', buffer[0]);
  EXPECT_EQ(1u, buffer_size);

  // Both should be writable.
  hss[0] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK, core()->Wait(h[0], MOJO_HANDLE_SIGNAL_WRITABLE,
                                         1000000000, MakeUserPointer(&hss[0])));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[0].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[0].satisfiable_signals);
  hss[0] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK, core()->Wait(h[1], MOJO_HANDLE_SIGNAL_WRITABLE,
                                         1000000000, MakeUserPointer(&hss[0])));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[0].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[0].satisfiable_signals);

  // Also check that |h[1]| is writable using |WaitMany()|.
  signals[0] = MOJO_HANDLE_SIGNAL_READABLE;
  signals[1] = MOJO_HANDLE_SIGNAL_WRITABLE;
  result_index = static_cast<uint32_t>(-1);
  hss[0] = kEmptyMojoHandleSignalsState;
  hss[1] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      core()->WaitMany(MakeUserPointer(h), MakeUserPointer(signals), 2,
                       MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                       MakeUserPointer(hss)));
  EXPECT_EQ(1u, result_index);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[0].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[0].satisfiable_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[1].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[1].satisfiable_signals);

  // Write to |h[1]|.
  buffer[0] = 'b';
  EXPECT_EQ(
      MOJO_RESULT_OK,
      core()->WriteMessage(h[1], UserPointer<const void>(buffer), 1,
                           NullUserPointer(), 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Check that |h[0]| is now readable.
  signals[0] = MOJO_HANDLE_SIGNAL_READABLE;
  signals[1] = MOJO_HANDLE_SIGNAL_READABLE;
  result_index = static_cast<uint32_t>(-1);
  hss[0] = kEmptyMojoHandleSignalsState;
  hss[1] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      core()->WaitMany(MakeUserPointer(h), MakeUserPointer(signals), 2,
                       MOJO_DEADLINE_INDEFINITE, MakeUserPointer(&result_index),
                       MakeUserPointer(hss)));
  EXPECT_EQ(0u, result_index);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss[0].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[0].satisfiable_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[1].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[1].satisfiable_signals);

  // Read from |h[0]|.
  // First, get only the size.
  buffer_size = 0;
  EXPECT_EQ(
      MOJO_RESULT_RESOURCE_EXHAUSTED,
      core()->ReadMessage(h[0], NullUserPointer(),
                          MakeUserPointer(&buffer_size), NullUserPointer(),
                          NullUserPointer(), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(1u, buffer_size);
  // Then actually read it.
  buffer[0] = 'c';
  buffer_size = 1;
  EXPECT_EQ(
      MOJO_RESULT_OK,
      core()->ReadMessage(h[0], UserPointer<void>(buffer),
                          MakeUserPointer(&buffer_size), NullUserPointer(),
                          NullUserPointer(), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ('b', buffer[0]);
  EXPECT_EQ(1u, buffer_size);

  // |h[0]| should no longer be readable.
  hss[0] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
            core()->Wait(h[0], MOJO_HANDLE_SIGNAL_READABLE, 0,
                         MakeUserPointer(&hss[0])));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss[0].satisfied_signals);
  EXPECT_EQ(kAllSignals, hss[0].satisfiable_signals);

  // Write to |h[0]|.
  buffer[0] = 'd';
  EXPECT_EQ(
      MOJO_RESULT_OK,
      core()->WriteMessage(h[0], UserPointer<const void>(buffer), 1,
                           NullUserPointer(), 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  // Close |h[0]|.
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h[0]));

  // Check that |h[1]| is no longer writable (and will never be).
  hss[0] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->Wait(h[1], MOJO_HANDLE_SIGNAL_WRITABLE, 1000000000,
                         MakeUserPointer(&hss[0])));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss[0].satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss[0].satisfiable_signals);

  // Check that |h[1]| is still readable (for the moment).
  hss[0] = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK, core()->Wait(h[1], MOJO_HANDLE_SIGNAL_READABLE,
                                         1000000000, MakeUserPointer(&hss[0])));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss[0].satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss[0].satisfiable_signals);

  // Discard a message from |h[1]|.
  EXPECT_EQ(MOJO_RESULT_RESOURCE_EXHAUSTED,
            core()->ReadMessage(h[1], NullUserPointer(), NullUserPointer(),
                                NullUserPointer(), NullUserPointer(),
                                MOJO_READ_MESSAGE_FLAG_MAY_DISCARD));

  // |h[1]| is no longer readable (and will never be).
  hss[0] = kFullMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->Wait(h[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss[0])));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss[0].satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss[0].satisfiable_signals);

  // Try writing to |h[1]|.
  buffer[0] = 'e';
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->WriteMessage(h[1], UserPointer<const void>(buffer), 1,
                           NullUserPointer(), 0, MOJO_WRITE_MESSAGE_FLAG_NONE));

  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h[1]));
}

// Tests passing a message pipe handle.
TEST_F(CoreTest, MessagePipeBasicLocalHandlePassing1) {
  const char kHello[] = "hello";
  const uint32_t kHelloSize = static_cast<uint32_t>(sizeof(kHello));
  const char kWorld[] = "world!!!";
  const uint32_t kWorldSize = static_cast<uint32_t>(sizeof(kWorld));
  char buffer[100];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t num_bytes;
  MojoHandle handles[10];
  uint32_t num_handles;
  MojoHandleSignalsState hss;
  MojoHandle h_received;

  MojoHandle h_passing[2];
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->CreateMessagePipe(NullUserPointer(),
                                      MakeUserPointer(&h_passing[0]),
                                      MakeUserPointer(&h_passing[1])));

  // Make sure that |h_passing[]| work properly.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, NullUserPointer(), 0,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passing[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passing[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kHelloSize, num_bytes);
  EXPECT_STREQ(kHello, buffer);
  EXPECT_EQ(0u, num_handles);

  // Make sure that you can't pass either of the message pipe's handles over
  // itself.
  EXPECT_EQ(MOJO_RESULT_BUSY,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, MakeUserPointer(&h_passing[0]), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, MakeUserPointer(&h_passing[1]), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));

  MojoHandle h_passed[2];
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->CreateMessagePipe(NullUserPointer(),
                                      MakeUserPointer(&h_passed[0]),
                                      MakeUserPointer(&h_passed[1])));

  // Make sure that |h_passed[]| work properly.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passed[0], UserPointer<const void>(kHello),
                                 kHelloSize, NullUserPointer(), 0,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passed[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passed[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kHelloSize, num_bytes);
  EXPECT_STREQ(kHello, buffer);
  EXPECT_EQ(0u, num_handles);

  // Send |h_passed[1]| from |h_passing[0]| to |h_passing[1]|.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kWorld),
                                 kWorldSize, MakeUserPointer(&h_passed[1]), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passing[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passing[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kWorldSize, num_bytes);
  EXPECT_STREQ(kWorld, buffer);
  EXPECT_EQ(1u, num_handles);
  h_received = handles[0];
  EXPECT_NE(h_received, MOJO_HANDLE_INVALID);
  EXPECT_NE(h_received, h_passing[0]);
  EXPECT_NE(h_received, h_passing[1]);
  EXPECT_NE(h_received, h_passed[0]);

  // Note: We rely on the Mojo system not re-using handle values very often.
  EXPECT_NE(h_received, h_passed[1]);

  // |h_passed[1]| should no longer be valid; check that trying to close it
  // fails. See above note.
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(h_passed[1]));

  // Write to |h_passed[0]|. Should receive on |h_received|.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passed[0], UserPointer<const void>(kHello),
                                 kHelloSize, NullUserPointer(), 0,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_received, MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_received, UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kHelloSize, num_bytes);
  EXPECT_STREQ(kHello, buffer);
  EXPECT_EQ(0u, num_handles);

  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h_passing[0]));
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h_passing[1]));
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h_passed[0]));
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h_received));
}

TEST_F(CoreTest, DataPipe) {
  MojoHandle ph, ch;  // p is for producer and c is for consumer.
  MojoHandleSignalsState hss;

  EXPECT_EQ(MOJO_RESULT_OK,
            core()->CreateDataPipe(NullUserPointer(), MakeUserPointer(&ph),
                                   MakeUserPointer(&ch)));
  // Should get two distinct, valid handles.
  EXPECT_NE(ph, MOJO_HANDLE_INVALID);
  EXPECT_NE(ch, MOJO_HANDLE_INVALID);
  EXPECT_NE(ph, ch);

  // Producer should be never-readable, but already writable.
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->Wait(ph, MOJO_HANDLE_SIGNAL_READABLE, 0, MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK, core()->Wait(ph, MOJO_HANDLE_SIGNAL_WRITABLE, 0,
                                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Consumer should be never-writable, and not yet readable.
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->Wait(ch, MOJO_HANDLE_SIGNAL_WRITABLE, 0, MakeUserPointer(&hss)));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_DEADLINE_EXCEEDED,
      core()->Wait(ch, MOJO_HANDLE_SIGNAL_READABLE, 0, MakeUserPointer(&hss)));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Write.
  signed char elements[2] = {'A', 'B'};
  uint32_t num_bytes = 2u;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteData(ph, UserPointer<const void>(elements),
                              MakeUserPointer(&num_bytes),
                              MOJO_WRITE_DATA_FLAG_NONE));
  EXPECT_EQ(2u, num_bytes);

  // Consumer should now be readable.
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK, core()->Wait(ch, MOJO_HANDLE_SIGNAL_READABLE, 0,
                                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Peek one character.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = 1u;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadData(
                ch, UserPointer<void>(elements), MakeUserPointer(&num_bytes),
                MOJO_READ_DATA_FLAG_NONE | MOJO_READ_DATA_FLAG_PEEK));
  EXPECT_EQ('A', elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Read one character.
  elements[0] = -1;
  elements[1] = -1;
  num_bytes = 1u;
  EXPECT_EQ(MOJO_RESULT_OK, core()->ReadData(ch, UserPointer<void>(elements),
                                             MakeUserPointer(&num_bytes),
                                             MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ('A', elements[0]);
  EXPECT_EQ(-1, elements[1]);

  // Two-phase write.
  void* write_ptr = nullptr;
  num_bytes = 0u;
  ASSERT_EQ(MOJO_RESULT_OK,
            core()->BeginWriteData(ph, MakeUserPointer(&write_ptr),
                                   MakeUserPointer(&num_bytes),
                                   MOJO_WRITE_DATA_FLAG_NONE));
  // We count on the default options providing a decent buffer size.
  ASSERT_GE(num_bytes, 3u);

  // Trying to do a normal write during a two-phase write should fail.
  elements[0] = 'X';
  num_bytes = 1u;
  EXPECT_EQ(MOJO_RESULT_BUSY,
            core()->WriteData(ph, UserPointer<const void>(elements),
                              MakeUserPointer(&num_bytes),
                              MOJO_WRITE_DATA_FLAG_NONE));

  // Actually write the data, and complete it now.
  static_cast<char*>(write_ptr)[0] = 'C';
  static_cast<char*>(write_ptr)[1] = 'D';
  static_cast<char*>(write_ptr)[2] = 'E';
  EXPECT_EQ(MOJO_RESULT_OK, core()->EndWriteData(ph, 3u));

  // Query how much data we have.
  num_bytes = 0;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadData(ch, NullUserPointer(), MakeUserPointer(&num_bytes),
                             MOJO_READ_DATA_FLAG_QUERY));
  EXPECT_EQ(4u, num_bytes);

  // Try to query with peek. Should fail.
  num_bytes = 0;
  EXPECT_EQ(
      MOJO_RESULT_INVALID_ARGUMENT,
      core()->ReadData(ch, NullUserPointer(), MakeUserPointer(&num_bytes),
                       MOJO_READ_DATA_FLAG_QUERY | MOJO_READ_DATA_FLAG_PEEK));
  EXPECT_EQ(0u, num_bytes);

  // Try to discard ten characters, in all-or-none mode. Should fail.
  num_bytes = 10;
  EXPECT_EQ(MOJO_RESULT_OUT_OF_RANGE,
            core()->ReadData(
                ch, NullUserPointer(), MakeUserPointer(&num_bytes),
                MOJO_READ_DATA_FLAG_DISCARD | MOJO_READ_DATA_FLAG_ALL_OR_NONE));

  // Try to discard two characters, in peek mode. Should fail.
  num_bytes = 2;
  EXPECT_EQ(
      MOJO_RESULT_INVALID_ARGUMENT,
      core()->ReadData(ch, NullUserPointer(), MakeUserPointer(&num_bytes),
                       MOJO_READ_DATA_FLAG_DISCARD | MOJO_READ_DATA_FLAG_PEEK));

  // Discard two characters.
  num_bytes = 2;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadData(
                ch, NullUserPointer(), MakeUserPointer(&num_bytes),
                MOJO_READ_DATA_FLAG_DISCARD | MOJO_READ_DATA_FLAG_ALL_OR_NONE));

  // Try a two-phase read of the remaining two bytes with peek. Should fail.
  const void* read_ptr = nullptr;
  num_bytes = 2;
  ASSERT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            core()->BeginReadData(ch, MakeUserPointer(&read_ptr),
                                  MakeUserPointer(&num_bytes),
                                  MOJO_READ_DATA_FLAG_PEEK));

  // Read the remaining two characters, in two-phase mode.
  num_bytes = 2;
  ASSERT_EQ(MOJO_RESULT_OK,
            core()->BeginReadData(ch, MakeUserPointer(&read_ptr),
                                  MakeUserPointer(&num_bytes),
                                  MOJO_READ_DATA_FLAG_NONE));
  // Note: Count on still being able to do the contiguous read here.
  ASSERT_EQ(2u, num_bytes);

  // Discarding right now should fail.
  num_bytes = 1;
  EXPECT_EQ(MOJO_RESULT_BUSY,
            core()->ReadData(ch, NullUserPointer(), MakeUserPointer(&num_bytes),
                             MOJO_READ_DATA_FLAG_DISCARD));

  // Actually check our data and end the two-phase read.
  EXPECT_EQ('D', static_cast<const char*>(read_ptr)[0]);
  EXPECT_EQ('E', static_cast<const char*>(read_ptr)[1]);
  EXPECT_EQ(MOJO_RESULT_OK, core()->EndReadData(ch, 2u));

  // Consumer should now be no longer readable.
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_DEADLINE_EXCEEDED,
      core()->Wait(ch, MOJO_HANDLE_SIGNAL_READABLE, 0, MakeUserPointer(&hss)));
  EXPECT_EQ(0u, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // TODO(vtl): More.

  // Close the producer.
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(ph));

  // The consumer should now be never-readable.
  hss = kFullMojoHandleSignalsState;
  EXPECT_EQ(
      MOJO_RESULT_FAILED_PRECONDITION,
      core()->Wait(ch, MOJO_HANDLE_SIGNAL_READABLE, 0, MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_PEER_CLOSED, hss.satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(ch));
}

// Tests passing data pipe producer and consumer handles.
TEST_F(CoreTest, MessagePipeBasicLocalHandlePassing2) {
  const char kHello[] = "hello";
  const uint32_t kHelloSize = static_cast<uint32_t>(sizeof(kHello));
  const char kWorld[] = "world!!!";
  const uint32_t kWorldSize = static_cast<uint32_t>(sizeof(kWorld));
  char buffer[100];
  const uint32_t kBufferSize = static_cast<uint32_t>(sizeof(buffer));
  uint32_t num_bytes;
  MojoHandle handles[10];
  uint32_t num_handles;
  MojoHandleSignalsState hss;

  MojoHandle h_passing[2];
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->CreateMessagePipe(NullUserPointer(),
                                      MakeUserPointer(&h_passing[0]),
                                      MakeUserPointer(&h_passing[1])));

  MojoHandle ph, ch;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->CreateDataPipe(NullUserPointer(), MakeUserPointer(&ph),
                                   MakeUserPointer(&ch)));

  // Send |ch| from |h_passing[0]| to |h_passing[1]|.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, MakeUserPointer(&ch), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passing[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passing[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kHelloSize, num_bytes);
  EXPECT_STREQ(kHello, buffer);
  EXPECT_EQ(1u, num_handles);
  MojoHandle ch_received = handles[0];
  EXPECT_NE(ch_received, MOJO_HANDLE_INVALID);
  EXPECT_NE(ch_received, h_passing[0]);
  EXPECT_NE(ch_received, h_passing[1]);
  EXPECT_NE(ch_received, ph);

  // Note: We rely on the Mojo system not re-using handle values very often.
  EXPECT_NE(ch_received, ch);

  // |ch| should no longer be valid; check that trying to close it fails. See
  // above note.
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(ch));

  // Write to |ph|. Should receive on |ch_received|.
  num_bytes = kWorldSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteData(ph, UserPointer<const void>(kWorld),
                              MakeUserPointer(&num_bytes),
                              MOJO_WRITE_DATA_FLAG_ALL_OR_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(ch_received, MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);
  num_bytes = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadData(ch_received, UserPointer<void>(buffer),
                             MakeUserPointer(&num_bytes),
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kWorldSize, num_bytes);
  EXPECT_STREQ(kWorld, buffer);

  // Now pass |ph| in the same direction.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kWorld),
                                 kWorldSize, MakeUserPointer(&ph), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passing[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passing[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kWorldSize, num_bytes);
  EXPECT_STREQ(kWorld, buffer);
  EXPECT_EQ(1u, num_handles);
  MojoHandle ph_received = handles[0];
  EXPECT_NE(ph_received, MOJO_HANDLE_INVALID);
  EXPECT_NE(ph_received, h_passing[0]);
  EXPECT_NE(ph_received, h_passing[1]);
  EXPECT_NE(ph_received, ch_received);

  // Again, rely on the Mojo system not re-using handle values very often.
  EXPECT_NE(ph_received, ph);

  // |ph| should no longer be valid; check that trying to close it fails. See
  // above note.
  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT, core()->Close(ph));

  // Write to |ph_received|. Should receive on |ch_received|.
  num_bytes = kHelloSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteData(ph_received, UserPointer<const void>(kHello),
                              MakeUserPointer(&num_bytes),
                              MOJO_WRITE_DATA_FLAG_ALL_OR_NONE));
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(ch_received, MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);
  num_bytes = kBufferSize;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadData(ch_received, UserPointer<void>(buffer),
                             MakeUserPointer(&num_bytes),
                             MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kHelloSize, num_bytes);
  EXPECT_STREQ(kHello, buffer);

  ph = ph_received;
  ph_received = MOJO_HANDLE_INVALID;
  ch = ch_received;
  ch_received = MOJO_HANDLE_INVALID;

  // Make sure that |ph| can't be sent if it's in a two-phase write.
  void* write_ptr = nullptr;
  num_bytes = 0;
  ASSERT_EQ(MOJO_RESULT_OK,
            core()->BeginWriteData(ph, MakeUserPointer(&write_ptr),
                                   MakeUserPointer(&num_bytes),
                                   MOJO_WRITE_DATA_FLAG_NONE));
  ASSERT_GE(num_bytes, 1u);
  EXPECT_EQ(MOJO_RESULT_BUSY,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, MakeUserPointer(&ph), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));

  // But |ch| can, even if |ph| is in a two-phase write.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, MakeUserPointer(&ch), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  ch = MOJO_HANDLE_INVALID;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passing[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         NullUserPointer()));
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passing[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kHelloSize, num_bytes);
  EXPECT_STREQ(kHello, buffer);
  EXPECT_EQ(1u, num_handles);
  ch = handles[0];
  EXPECT_NE(ch, MOJO_HANDLE_INVALID);

  // Complete the two-phase write.
  static_cast<char*>(write_ptr)[0] = 'x';
  EXPECT_EQ(MOJO_RESULT_OK, core()->EndWriteData(ph, 1));

  // Wait for |ch| to be readable.
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK, core()->Wait(ch, MOJO_HANDLE_SIGNAL_READABLE,
                                         1000000000, MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE, hss.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            hss.satisfiable_signals);

  // Make sure that |ch| can't be sent if it's in a two-phase read.
  const void* read_ptr = nullptr;
  num_bytes = 1;
  ASSERT_EQ(MOJO_RESULT_OK,
            core()->BeginReadData(ch, MakeUserPointer(&read_ptr),
                                  MakeUserPointer(&num_bytes),
                                  MOJO_READ_DATA_FLAG_NONE));
  EXPECT_EQ(MOJO_RESULT_BUSY,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kHello),
                                 kHelloSize, MakeUserPointer(&ch), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));

  // But |ph| can, even if |ch| is in a two-phase read.
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->WriteMessage(h_passing[0], UserPointer<const void>(kWorld),
                                 kWorldSize, MakeUserPointer(&ph), 1,
                                 MOJO_WRITE_MESSAGE_FLAG_NONE));
  ph = MOJO_HANDLE_INVALID;
  hss = kEmptyMojoHandleSignalsState;
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->Wait(h_passing[1], MOJO_HANDLE_SIGNAL_READABLE, 1000000000,
                         MakeUserPointer(&hss)));
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            hss.satisfied_signals);
  EXPECT_EQ(kAllSignals, hss.satisfiable_signals);
  num_bytes = kBufferSize;
  num_handles = MOJO_ARRAYSIZE(handles);
  EXPECT_EQ(MOJO_RESULT_OK,
            core()->ReadMessage(
                h_passing[1], UserPointer<void>(buffer),
                MakeUserPointer(&num_bytes), MakeUserPointer(handles),
                MakeUserPointer(&num_handles), MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ(kWorldSize, num_bytes);
  EXPECT_STREQ(kWorld, buffer);
  EXPECT_EQ(1u, num_handles);
  ph = handles[0];
  EXPECT_NE(ph, MOJO_HANDLE_INVALID);

  // Complete the two-phase read.
  EXPECT_EQ('x', static_cast<const char*>(read_ptr)[0]);
  EXPECT_EQ(MOJO_RESULT_OK, core()->EndReadData(ch, 1));

  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h_passing[0]));
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h_passing[1]));
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(ph));
  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(ch));
}

struct TestAsyncWaiter {
  TestAsyncWaiter() : result(MOJO_RESULT_UNKNOWN) {}

  void Awake(MojoResult r) { result = r; }

  MojoResult result;
};

TEST_F(CoreTest, AsyncWait) {
  TestAsyncWaiter waiter;
  MockHandleInfo info;
  MojoHandle h = CreateMockHandle(&info);

  EXPECT_EQ(MOJO_RESULT_FAILED_PRECONDITION,
            core()->AsyncWait(
                h, MOJO_HANDLE_SIGNAL_READABLE,
                [&waiter](MojoResult result) { waiter.Awake(result); }));
  EXPECT_EQ(0u, info.GetAddedAwakableSize());

  info.AllowAddAwakable(true);
  EXPECT_EQ(MOJO_RESULT_OK, core()->AsyncWait(h, MOJO_HANDLE_SIGNAL_READABLE,
                                              [&waiter](MojoResult result) {
                                                waiter.Awake(result);
                                              }));
  EXPECT_EQ(1u, info.GetAddedAwakableSize());

  EXPECT_FALSE(info.GetAddedAwakableAt(0)->Awake(MOJO_RESULT_BUSY, 0));
  EXPECT_EQ(MOJO_RESULT_BUSY, waiter.result);

  EXPECT_EQ(MOJO_RESULT_OK, core()->Close(h));
}

// TODO(vtl): Test |DuplicateBufferHandle()| and |MapBuffer()|.

}  // namespace
}  // namespace system
}  // namespace mojo
