// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifdef __cplusplus
#error "This file should be compiled as C, not C++."
#endif

#include <stddef.h>
#include <string.h>

// Include all the header files that are meant to be compilable as C. Start with
// core.h, since it's the most important one.
#include "mojo/public/c/environment/async_waiter.h"
#include "mojo/public/c/system/core.h"
#include "mojo/public/c/system/macros.h"

// The joys of the C preprocessor....
#define STRINGIFY(x) #x
#define STRINGIFY2(x) STRINGIFY(x)
#define FAILURE(message) \
  __FILE__ "(" STRINGIFY2(__LINE__) "): Failure: " message

// Poor man's gtest.
#define EXPECT_EQ(a, b)                                                  \
  do {                                                                   \
    if ((a) != (b))                                                      \
      return FAILURE(STRINGIFY(a) " != " STRINGIFY(b) " (expected ==)"); \
  } while (0)
#define EXPECT_NE(a, b)                                                  \
  do {                                                                   \
    if ((a) == (b))                                                      \
      return FAILURE(STRINGIFY(a) " == " STRINGIFY(b) " (expected !=)"); \
  } while (0)

// This function exists mainly to be compiled and linked. We do some cursory
// checks and call it from a unit test, to make sure that link problems aren't
// missed due to deadstripping. Returns null on success and a string on failure
// (describing the failure).
const char* MinimalCTest(void) {
  // MSVS before 2013 *really* only supports C90: All variables must be declared
  // at the top. (MSVS 2013 is more reasonable.)
  MojoTimeTicks ticks;
  MojoHandle handle0, handle1;
  MojoHandleSignals signals;
  const char kHello[] = "hello";
  char buffer[200] = {0};
  uint32_t num_bytes;

  ticks = MojoGetTimeTicksNow();
  EXPECT_NE(ticks, 0);

  handle0 = MOJO_HANDLE_INVALID;
  EXPECT_NE(MOJO_RESULT_OK, MojoClose(handle0));

  EXPECT_EQ(MOJO_RESULT_INVALID_ARGUMENT,
            MojoWait(handle0, ~MOJO_HANDLE_SIGNAL_NONE,
                     MOJO_DEADLINE_INDEFINITE, NULL));

  handle1 = MOJO_HANDLE_INVALID;
  EXPECT_EQ(MOJO_RESULT_OK, MojoCreateMessagePipe(NULL, &handle0, &handle1));

  signals = MOJO_HANDLE_SIGNAL_READABLE;
  uint32_t result_index = 123;
  struct MojoHandleSignalsState states[1];
  EXPECT_EQ(MOJO_RESULT_DEADLINE_EXCEEDED,
            MojoWaitMany(&handle0, &signals, 1, 1, &result_index, states));

  // "Deadline exceeded" doesn't apply to a single handle, so this should leave
  // |result_index| untouched.
  EXPECT_EQ(123u, result_index);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_WRITABLE, states[0].satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            states[0].satisfiable_signals);

  EXPECT_EQ(MOJO_RESULT_OK,
            MojoWriteMessage(handle0, kHello, (uint32_t)sizeof(kHello), NULL,
                             0u, MOJO_WRITE_DATA_FLAG_NONE));

  struct MojoHandleSignalsState state;
  EXPECT_EQ(MOJO_RESULT_OK, MojoWait(handle1, MOJO_HANDLE_SIGNAL_READABLE,
                                     MOJO_DEADLINE_INDEFINITE, &state));

  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE,
            state.satisfied_signals);
  EXPECT_EQ(MOJO_HANDLE_SIGNAL_READABLE | MOJO_HANDLE_SIGNAL_WRITABLE |
                MOJO_HANDLE_SIGNAL_PEER_CLOSED,
            state.satisfiable_signals);

  num_bytes = (uint32_t)sizeof(buffer);
  EXPECT_EQ(MOJO_RESULT_OK, MojoReadMessage(handle1, buffer, &num_bytes, NULL,
                                            NULL, MOJO_READ_MESSAGE_FLAG_NONE));
  EXPECT_EQ((uint32_t)sizeof(kHello), num_bytes);
  EXPECT_EQ(0, memcmp(buffer, kHello, sizeof(kHello)));

  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(handle0));
  EXPECT_EQ(MOJO_RESULT_OK, MojoClose(handle1));

  // TODO(vtl): data pipe

  return NULL;
}
