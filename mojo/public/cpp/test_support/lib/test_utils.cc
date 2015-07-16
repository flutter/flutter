// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/test_support/test_utils.h"

#include "mojo/public/cpp/system/core.h"
#include "mojo/public/cpp/test_support/test_support.h"

namespace mojo {
namespace test {

bool WriteTextMessage(const MessagePipeHandle& handle,
                      const std::string& text) {
  MojoResult rv = WriteMessageRaw(handle,
                                  text.data(),
                                  static_cast<uint32_t>(text.size()),
                                  nullptr,
                                  0,
                                  MOJO_WRITE_MESSAGE_FLAG_NONE);
  return rv == MOJO_RESULT_OK;
}

bool ReadTextMessage(const MessagePipeHandle& handle, std::string* text) {
  MojoResult rv;
  bool did_wait = false;

  uint32_t num_bytes = 0, num_handles = 0;
  for (;;) {
    rv = ReadMessageRaw(handle,
                        nullptr,
                        &num_bytes,
                        nullptr,
                        &num_handles,
                        MOJO_READ_MESSAGE_FLAG_NONE);
    if (rv == MOJO_RESULT_SHOULD_WAIT) {
      if (did_wait) {
        assert(false);  // Looping endlessly!?
        return false;
      }
      rv = Wait(handle, MOJO_HANDLE_SIGNAL_READABLE, MOJO_DEADLINE_INDEFINITE,
                nullptr);
      if (rv != MOJO_RESULT_OK)
        return false;
      did_wait = true;
    } else {
      assert(!num_handles);
      break;
    }
  }

  text->resize(num_bytes);
  rv = ReadMessageRaw(handle,
                      &text->at(0),
                      &num_bytes,
                      nullptr,
                      &num_handles,
                      MOJO_READ_MESSAGE_FLAG_NONE);
  return rv == MOJO_RESULT_OK;
}

bool DiscardMessage(const MessagePipeHandle& handle) {
  MojoResult rv = ReadMessageRaw(handle,
                                 nullptr,
                                 nullptr,
                                 nullptr,
                                 nullptr,
                                 MOJO_READ_MESSAGE_FLAG_MAY_DISCARD);
  return rv == MOJO_RESULT_OK;
}

void IterateAndReportPerf(const char* test_name,
                          const char* sub_test_name,
                          PerfTestSingleIteration single_iteration,
                          void* closure) {
  // TODO(vtl): These should be specifiable using command-line flags.
  static const size_t kGranularity = 100;
  static const MojoTimeTicks kPerftestTimeMicroseconds = 3 * 1000000;

  const MojoTimeTicks start_time = GetTimeTicksNow();
  MojoTimeTicks end_time;
  size_t iterations = 0;
  do {
    for (size_t i = 0; i < kGranularity; i++)
      (*single_iteration)(closure);
    iterations += kGranularity;

    end_time = GetTimeTicksNow();
  } while (end_time - start_time < kPerftestTimeMicroseconds);

  MojoTestSupportLogPerfResult(test_name, sub_test_name,
                               1000000.0 * iterations / (end_time - start_time),
                               "iterations/second");
}

}  // namespace test
}  // namespace mojo
