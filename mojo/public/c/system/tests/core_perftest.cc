// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This tests the performance of the C API.

#include "mojo/public/c/system/core.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>

#include "mojo/public/cpp/system/macros.h"
#include "mojo/public/cpp/test_support/test_support.h"
#include "mojo/public/cpp/test_support/test_utils.h"
#include "testing/gtest/include/gtest/gtest.h"

// TODO(vtl): (here and below) crbug.com/342893
#if !defined(WIN32)
#include <time.h>
#include "mojo/public/cpp/utility/thread.h"
#endif  // !defined(WIN32)

namespace {

#if !defined(WIN32)
class MessagePipeWriterThread : public mojo::Thread {
 public:
  MessagePipeWriterThread(MojoHandle handle, uint32_t num_bytes)
      : handle_(handle), num_bytes_(num_bytes), num_writes_(0) {}
  ~MessagePipeWriterThread() override {}

  void Run() override {
    char buffer[10000];
    assert(num_bytes_ <= sizeof(buffer));

    // TODO(vtl): Should I throttle somehow?
    for (;;) {
      MojoResult result = MojoWriteMessage(handle_, buffer, num_bytes_, nullptr,
                                           0, MOJO_WRITE_MESSAGE_FLAG_NONE);
      if (result == MOJO_RESULT_OK) {
        num_writes_++;
        continue;
      }

      // We failed to write.
      // Either |handle_| or its peer was closed.
      assert(result == MOJO_RESULT_INVALID_ARGUMENT ||
             result == MOJO_RESULT_FAILED_PRECONDITION);
      break;
    }
  }

  // Use only after joining the thread.
  int64_t num_writes() const { return num_writes_; }

 private:
  const MojoHandle handle_;
  const uint32_t num_bytes_;
  int64_t num_writes_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessagePipeWriterThread);
};

class MessagePipeReaderThread : public mojo::Thread {
 public:
  explicit MessagePipeReaderThread(MojoHandle handle)
      : handle_(handle), num_reads_(0) {}
  ~MessagePipeReaderThread() override {}

  void Run() override {
    char buffer[10000];

    for (;;) {
      uint32_t num_bytes = static_cast<uint32_t>(sizeof(buffer));
      MojoResult result = MojoReadMessage(handle_, buffer, &num_bytes, nullptr,
                                          nullptr, MOJO_READ_MESSAGE_FLAG_NONE);
      if (result == MOJO_RESULT_OK) {
        num_reads_++;
        continue;
      }

      if (result == MOJO_RESULT_SHOULD_WAIT) {
        result = MojoWait(handle_, MOJO_HANDLE_SIGNAL_READABLE,
                          MOJO_DEADLINE_INDEFINITE, nullptr);
        if (result == MOJO_RESULT_OK) {
          // Go to the top of the loop to read again.
          continue;
        }
      }

      // We failed to read and possibly failed to wait.
      // Either |handle_| or its peer was closed.
      assert(result == MOJO_RESULT_INVALID_ARGUMENT ||
             result == MOJO_RESULT_FAILED_PRECONDITION);
      break;
    }
  }

  // Use only after joining the thread.
  int64_t num_reads() const { return num_reads_; }

 private:
  const MojoHandle handle_;
  int64_t num_reads_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MessagePipeReaderThread);
};
#endif  // !defined(WIN32)

class CorePerftest : public testing::Test {
 public:
  CorePerftest() : buffer_(nullptr), num_bytes_(0) {}
  ~CorePerftest() override {}

  static void NoOp(void* /*closure*/) {}

  static void MessagePipe_CreateAndClose(void* closure) {
    CorePerftest* self = static_cast<CorePerftest*>(closure);
    MojoResult result = MojoCreateMessagePipe(nullptr, &self->h0_, &self->h1_);
    MOJO_ALLOW_UNUSED_LOCAL(result);
    assert(result == MOJO_RESULT_OK);
    result = MojoClose(self->h0_);
    assert(result == MOJO_RESULT_OK);
    result = MojoClose(self->h1_);
    assert(result == MOJO_RESULT_OK);
  }

  static void MessagePipe_WriteAndRead(void* closure) {
    CorePerftest* self = static_cast<CorePerftest*>(closure);
    MojoResult result =
        MojoWriteMessage(self->h0_, self->buffer_, self->num_bytes_, nullptr, 0,
                         MOJO_WRITE_MESSAGE_FLAG_NONE);
    MOJO_ALLOW_UNUSED_LOCAL(result);
    assert(result == MOJO_RESULT_OK);
    uint32_t read_bytes = self->num_bytes_;
    result = MojoReadMessage(self->h1_, self->buffer_, &read_bytes, nullptr,
                             nullptr, MOJO_READ_MESSAGE_FLAG_NONE);
    assert(result == MOJO_RESULT_OK);
  }

  static void MessagePipe_EmptyRead(void* closure) {
    CorePerftest* self = static_cast<CorePerftest*>(closure);
    MojoResult result =
        MojoReadMessage(self->h0_, nullptr, nullptr, nullptr, nullptr,
                        MOJO_READ_MESSAGE_FLAG_MAY_DISCARD);
    MOJO_ALLOW_UNUSED_LOCAL(result);
    assert(result == MOJO_RESULT_SHOULD_WAIT);
  }

 protected:
#if !defined(WIN32)
  void DoMessagePipeThreadedTest(unsigned num_writers,
                                 unsigned num_readers,
                                 uint32_t num_bytes) {
    static const int64_t kPerftestTimeMicroseconds = 3 * 1000000;

    assert(num_writers > 0);
    assert(num_readers > 0);

    MojoResult result = MojoCreateMessagePipe(nullptr, &h0_, &h1_);
    MOJO_ALLOW_UNUSED_LOCAL(result);
    assert(result == MOJO_RESULT_OK);

    std::vector<MessagePipeWriterThread*> writers;
    for (unsigned i = 0; i < num_writers; i++)
      writers.push_back(new MessagePipeWriterThread(h0_, num_bytes));

    std::vector<MessagePipeReaderThread*> readers;
    for (unsigned i = 0; i < num_readers; i++)
      readers.push_back(new MessagePipeReaderThread(h1_));

    // Start time here, just before we fire off the threads.
    const MojoTimeTicks start_time = MojoGetTimeTicksNow();

    // Interleave the starts.
    for (unsigned i = 0; i < num_writers || i < num_readers; i++) {
      if (i < num_writers)
        writers[i]->Start();
      if (i < num_readers)
        readers[i]->Start();
    }

    Sleep(kPerftestTimeMicroseconds);

    // Close both handles to make writers and readers stop immediately.
    result = MojoClose(h0_);
    assert(result == MOJO_RESULT_OK);
    result = MojoClose(h1_);
    assert(result == MOJO_RESULT_OK);

    // Join everything.
    for (unsigned i = 0; i < num_writers; i++)
      writers[i]->Join();
    for (unsigned i = 0; i < num_readers; i++)
      readers[i]->Join();

    // Stop time here.
    MojoTimeTicks end_time = MojoGetTimeTicksNow();

    // Add up write and read counts, and destroy the threads.
    int64_t num_writes = 0;
    for (unsigned i = 0; i < num_writers; i++) {
      num_writes += writers[i]->num_writes();
      delete writers[i];
    }
    writers.clear();
    int64_t num_reads = 0;
    for (unsigned i = 0; i < num_readers; i++) {
      num_reads += readers[i]->num_reads();
      delete readers[i];
    }
    readers.clear();

    char sub_test_name[200];
    sprintf(sub_test_name, "%uw_%ur_%ubytes", num_writers, num_readers,
            static_cast<unsigned>(num_bytes));
    mojo::test::LogPerfResult(
        "MessagePipe_Threaded_Writes", sub_test_name,
        1000000.0 * static_cast<double>(num_writes) / (end_time - start_time),
        "writes/second");
    mojo::test::LogPerfResult(
        "MessagePipe_Threaded_Reads", sub_test_name,
        1000000.0 * static_cast<double>(num_reads) / (end_time - start_time),
        "reads/second");
  }
#endif  // !defined(WIN32)

  MojoHandle h0_;
  MojoHandle h1_;

  void* buffer_;
  uint32_t num_bytes_;

 private:
#if !defined(WIN32)
  void Sleep(int64_t microseconds) {
    struct timespec req = {
        static_cast<time_t>(microseconds / 1000000),       // Seconds.
        static_cast<long>(microseconds % 1000000) * 1000L  // Nanoseconds.
    };
    int rv = nanosleep(&req, nullptr);
    MOJO_ALLOW_UNUSED_LOCAL(rv);
    assert(rv == 0);
  }
#endif  // !defined(WIN32)

  MOJO_DISALLOW_COPY_AND_ASSIGN(CorePerftest);
};

// A no-op test so we can compare performance.
TEST_F(CorePerftest, NoOp) {
  mojo::test::IterateAndReportPerf("Iterate_NoOp", nullptr, &CorePerftest::NoOp,
                                   this);
}

TEST_F(CorePerftest, MessagePipe_CreateAndClose) {
  mojo::test::IterateAndReportPerf("MessagePipe_CreateAndClose", nullptr,
                                   &CorePerftest::MessagePipe_CreateAndClose,
                                   this);
}

TEST_F(CorePerftest, MessagePipe_WriteAndRead) {
  MojoResult result = MojoCreateMessagePipe(nullptr, &h0_, &h1_);
  MOJO_ALLOW_UNUSED_LOCAL(result);
  assert(result == MOJO_RESULT_OK);
  char buffer[10000] = {0};
  buffer_ = buffer;
  num_bytes_ = 10u;
  mojo::test::IterateAndReportPerf("MessagePipe_WriteAndRead", "10bytes",
                                   &CorePerftest::MessagePipe_WriteAndRead,
                                   this);
  num_bytes_ = 100u;
  mojo::test::IterateAndReportPerf("MessagePipe_WriteAndRead", "100bytes",
                                   &CorePerftest::MessagePipe_WriteAndRead,
                                   this);
  num_bytes_ = 1000u;
  mojo::test::IterateAndReportPerf("MessagePipe_WriteAndRead", "1000bytes",
                                   &CorePerftest::MessagePipe_WriteAndRead,
                                   this);
  num_bytes_ = 10000u;
  mojo::test::IterateAndReportPerf("MessagePipe_WriteAndRead", "10000bytes",
                                   &CorePerftest::MessagePipe_WriteAndRead,
                                   this);
  result = MojoClose(h0_);
  assert(result == MOJO_RESULT_OK);
  result = MojoClose(h1_);
  assert(result == MOJO_RESULT_OK);
}

TEST_F(CorePerftest, MessagePipe_EmptyRead) {
  MojoResult result = MojoCreateMessagePipe(nullptr, &h0_, &h1_);
  MOJO_ALLOW_UNUSED_LOCAL(result);
  assert(result == MOJO_RESULT_OK);
  mojo::test::IterateAndReportPerf("MessagePipe_EmptyRead", nullptr,
                                   &CorePerftest::MessagePipe_EmptyRead, this);
  result = MojoClose(h0_);
  assert(result == MOJO_RESULT_OK);
  result = MojoClose(h1_);
  assert(result == MOJO_RESULT_OK);
}

#if !defined(WIN32)
TEST_F(CorePerftest, MessagePipe_Threaded) {
  DoMessagePipeThreadedTest(1u, 1u, 100u);
  DoMessagePipeThreadedTest(2u, 2u, 100u);
  DoMessagePipeThreadedTest(3u, 3u, 100u);
  DoMessagePipeThreadedTest(10u, 10u, 100u);
  DoMessagePipeThreadedTest(10u, 1u, 100u);
  DoMessagePipeThreadedTest(1u, 10u, 100u);

  // For comparison of overhead:
  DoMessagePipeThreadedTest(1u, 1u, 10u);
  // 100 was done above.
  DoMessagePipeThreadedTest(1u, 1u, 1000u);
  DoMessagePipeThreadedTest(1u, 1u, 10000u);

  DoMessagePipeThreadedTest(3u, 3u, 10u);
  // 100 was done above.
  DoMessagePipeThreadedTest(3u, 3u, 1000u);
  DoMessagePipeThreadedTest(3u, 3u, 10000u);
}
#endif  // !defined(WIN32)

}  // namespace
