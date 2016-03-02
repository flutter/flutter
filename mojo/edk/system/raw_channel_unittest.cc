// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/raw_channel.h"

#include <stdint.h>
#include <stdio.h>

#include <memory>
#include <thread>
#include <utility>
#include <vector>

#include "base/logging.h"
#include "mojo/edk/platform/platform_handle.h"
#include "mojo/edk/platform/platform_handle_utils_posix.h"
#include "mojo/edk/platform/platform_pipe.h"
#include "mojo/edk/platform/scoped_platform_handle.h"
#include "mojo/edk/platform/thread_utils.h"
#include "mojo/edk/system/message_in_transit.h"
#include "mojo/edk/system/test/random.h"
#include "mojo/edk/system/test/scoped_test_dir.h"
#include "mojo/edk/system/test/test_io_thread.h"
#include "mojo/edk/system/test/timeouts.h"
#include "mojo/edk/system/transport_data.h"
#include "mojo/edk/test/test_utils.h"
#include "mojo/edk/util/make_unique.h"
#include "mojo/edk/util/mutex.h"
#include "mojo/edk/util/scoped_file.h"
#include "mojo/edk/util/waitable_event.h"
#include "mojo/public/cpp/system/macros.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::FILEFromPlatformHandle;
using mojo::platform::PlatformHandle;
using mojo::platform::PlatformHandleFromFILE;
using mojo::platform::PlatformPipe;
using mojo::platform::ScopedPlatformHandle;
using mojo::platform::ThreadSleep;
using mojo::util::AutoResetWaitableEvent;
using mojo::util::MakeUnique;
using mojo::util::Mutex;
using mojo::util::MutexLocker;

namespace mojo {
namespace system {
namespace {

std::unique_ptr<MessageInTransit> MakeTestMessage(uint32_t num_bytes) {
  std::vector<unsigned char> bytes(num_bytes, 0);
  for (size_t i = 0; i < num_bytes; i++)
    bytes[i] = static_cast<unsigned char>(i + num_bytes);
  return MakeUnique<MessageInTransit>(
      MessageInTransit::Type::ENDPOINT_CLIENT,
      MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA, num_bytes,
      bytes.empty() ? nullptr : &bytes[0]);
}

bool CheckMessageData(const void* bytes, uint32_t num_bytes) {
  const unsigned char* b = static_cast<const unsigned char*>(bytes);
  for (uint32_t i = 0; i < num_bytes; i++) {
    if (b[i] != static_cast<unsigned char>(i + num_bytes))
      return false;
  }
  return true;
}

bool WriteTestMessageToHandle(const PlatformHandle& handle,
                              uint32_t num_bytes) {
  std::unique_ptr<MessageInTransit> message(MakeTestMessage(num_bytes));

  size_t write_size = 0;
  mojo::test::BlockingWrite(handle, message->main_buffer(),
                            message->main_buffer_size(), &write_size);
  return write_size == message->main_buffer_size();
}

// -----------------------------------------------------------------------------

class RawChannelTest : public testing::Test {
 public:
  RawChannelTest() : io_thread_(test::TestIOThread::StartMode::MANUAL) {}
  ~RawChannelTest() override {}

  void SetUp() override {
    PlatformPipe channel_pair;
    handles[0] = channel_pair.handle0.Pass();
    handles[1] = channel_pair.handle1.Pass();
    io_thread_.Start();
  }

  void TearDown() override {
    io_thread_.Stop();
    handles[0].reset();
    handles[1].reset();
  }

 protected:
  test::TestIOThread* io_thread() { return &io_thread_; }

  ScopedPlatformHandle handles[2];

 private:
  test::TestIOThread io_thread_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(RawChannelTest);
};

// RawChannelTest.WriteMessage -------------------------------------------------

class WriteOnlyRawChannelDelegate : public RawChannel::Delegate {
 public:
  WriteOnlyRawChannelDelegate() {}
  ~WriteOnlyRawChannelDelegate() override {}

  // |RawChannel::Delegate| implementation:
  void OnReadMessage(const MessageInTransit::View& /*message_view*/,
                     std::unique_ptr<std::vector<ScopedPlatformHandle>>
                     /*platform_handles*/) override {
    CHECK(false);  // Should not get called.
  }
  void OnError(Error error) override {
    // We'll get a read (shutdown) error when the connection is closed.
    CHECK_EQ(error, ERROR_READ_SHUTDOWN);
  }

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(WriteOnlyRawChannelDelegate);
};

static const unsigned kMessageReaderSleepMs = 1;
static const size_t kMessageReaderMaxPollIterations = 3000;

class TestMessageReaderAndChecker {
 public:
  explicit TestMessageReaderAndChecker(PlatformHandle handle)
      : handle_(handle) {}
  ~TestMessageReaderAndChecker() { CHECK(bytes_.empty()); }

  bool ReadAndCheckNextMessage(uint32_t expected_size) {
    unsigned char buffer[4096];

    for (size_t i = 0; i < kMessageReaderMaxPollIterations;) {
      size_t read_size = 0;
      CHECK(mojo::test::NonBlockingRead(handle_, buffer, sizeof(buffer),
                                        &read_size));

      // Append newly-read data to |bytes_|.
      bytes_.insert(bytes_.end(), buffer, buffer + read_size);

      // If we have the header....
      size_t message_size;
      if (MessageInTransit::GetNextMessageSize(
              bytes_.empty() ? nullptr : &bytes_[0], bytes_.size(),
              &message_size)) {
        // If we've read the whole message....
        if (bytes_.size() >= message_size) {
          bool rv = true;
          MessageInTransit::View message_view(message_size, &bytes_[0]);
          CHECK_EQ(message_view.main_buffer_size(), message_size);

          if (message_view.num_bytes() != expected_size) {
            LOG(ERROR) << "Wrong size: " << message_size << " instead of "
                       << expected_size << " bytes.";
            rv = false;
          } else if (!CheckMessageData(message_view.bytes(),
                                       message_view.num_bytes())) {
            LOG(ERROR) << "Incorrect message bytes.";
            rv = false;
          }

          // Erase message data.
          bytes_.erase(bytes_.begin(),
                       bytes_.begin() + message_view.main_buffer_size());
          return rv;
        }
      }

      if (static_cast<size_t>(read_size) < sizeof(buffer)) {
        i++;
        ThreadSleep(test::DeadlineFromMilliseconds(kMessageReaderSleepMs));
      }
    }

    LOG(ERROR) << "Too many iterations.";
    return false;
  }

 private:
  const PlatformHandle handle_;

  // The start of the received data should always be on a message boundary.
  std::vector<unsigned char> bytes_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(TestMessageReaderAndChecker);
};

// Tests writing (and verifies reading using our own custom reader).
TEST_F(RawChannelTest, WriteMessage) {
  WriteOnlyRawChannelDelegate delegate;
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  TestMessageReaderAndChecker checker(handles[1].get());
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Write and read, for a variety of sizes.
  for (uint32_t size = 1; size < 5 * 1000 * 1000; size += size / 2 + 1) {
    EXPECT_TRUE(rc->WriteMessage(MakeTestMessage(size)));
    EXPECT_TRUE(checker.ReadAndCheckNextMessage(size)) << size;
  }

  // Write/queue and read afterwards, for a variety of sizes.
  for (uint32_t size = 1; size < 5 * 1000 * 1000; size += size / 2 + 1)
    EXPECT_TRUE(rc->WriteMessage(MakeTestMessage(size)));
  for (uint32_t size = 1; size < 5 * 1000 * 1000; size += size / 2 + 1)
    EXPECT_TRUE(checker.ReadAndCheckNextMessage(size)) << size;

  io_thread()->PostTaskAndWait([&rc]() { rc->Shutdown(); });
}

// RawChannelTest.OnReadMessage ------------------------------------------------

class ReadCheckerRawChannelDelegate : public RawChannel::Delegate {
 public:
  ReadCheckerRawChannelDelegate() : position_(0) {}
  ~ReadCheckerRawChannelDelegate() override {}

  // |RawChannel::Delegate| implementation (called on the I/O thread):
  void OnReadMessage(const MessageInTransit::View& message_view,
                     std::unique_ptr<std::vector<ScopedPlatformHandle>>
                         platform_handles) override {
    EXPECT_FALSE(platform_handles);

    size_t position;
    size_t expected_size;
    bool should_signal = false;
    {
      MutexLocker locker(&mutex_);
      CHECK_LT(position_, expected_sizes_.size());
      position = position_;
      expected_size = expected_sizes_[position];
      position_++;
      if (position_ >= expected_sizes_.size())
        should_signal = true;
    }

    EXPECT_EQ(expected_size, message_view.num_bytes()) << position;
    if (message_view.num_bytes() == expected_size) {
      EXPECT_TRUE(
          CheckMessageData(message_view.bytes(), message_view.num_bytes()))
          << position;
    }

    if (should_signal)
      done_event_.Signal();
  }
  void OnError(Error error) override {
    // We'll get a read (shutdown) error when the connection is closed.
    CHECK_EQ(error, ERROR_READ_SHUTDOWN);
  }

  // Waits for all the messages (of sizes |expected_sizes_|) to be seen.
  void Wait() { done_event_.Wait(); }

  void SetExpectedSizes(const std::vector<uint32_t>& expected_sizes) {
    MutexLocker locker(&mutex_);
    CHECK_EQ(position_, expected_sizes_.size());
    expected_sizes_ = expected_sizes;
    position_ = 0;
  }

 private:
  AutoResetWaitableEvent done_event_;

  Mutex mutex_;
  std::vector<uint32_t> expected_sizes_ MOJO_GUARDED_BY(mutex_);
  size_t position_ MOJO_GUARDED_BY(mutex_);

  MOJO_DISALLOW_COPY_AND_ASSIGN(ReadCheckerRawChannelDelegate);
};

// Tests reading (writing using our own custom writer).
TEST_F(RawChannelTest, OnReadMessage) {
  ReadCheckerRawChannelDelegate delegate;
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Write and read, for a variety of sizes.
  for (uint32_t size = 1; size < 5 * 1000 * 1000; size += size / 2 + 1) {
    delegate.SetExpectedSizes(std::vector<uint32_t>(1, size));

    EXPECT_TRUE(WriteTestMessageToHandle(handles[1].get(), size));

    delegate.Wait();
  }

  // Set up reader and write as fast as we can.
  // Write/queue and read afterwards, for a variety of sizes.
  std::vector<uint32_t> expected_sizes;
  for (uint32_t size = 1; size < 5 * 1000 * 1000; size += size / 2 + 1)
    expected_sizes.push_back(size);
  delegate.SetExpectedSizes(expected_sizes);
  for (uint32_t size = 1; size < 5 * 1000 * 1000; size += size / 2 + 1)
    EXPECT_TRUE(WriteTestMessageToHandle(handles[1].get(), size));
  delegate.Wait();

  io_thread()->PostTaskAndWait([&rc]() { rc->Shutdown(); });
}

// RawChannelTest.WriteMessageAndOnReadMessage ---------------------------------

class ReadCountdownRawChannelDelegate : public RawChannel::Delegate {
 public:
  explicit ReadCountdownRawChannelDelegate(size_t expected_count)
      : expected_count_(expected_count), count_(0) {}
  ~ReadCountdownRawChannelDelegate() override {}

  // |RawChannel::Delegate| implementation (called on the I/O thread):
  void OnReadMessage(const MessageInTransit::View& message_view,
                     std::unique_ptr<std::vector<ScopedPlatformHandle>>
                         platform_handles) override {
    EXPECT_FALSE(platform_handles);

    EXPECT_LT(count_, expected_count_);
    count_++;

    EXPECT_TRUE(
        CheckMessageData(message_view.bytes(), message_view.num_bytes()));

    if (count_ >= expected_count_)
      done_event_.Signal();
  }
  void OnError(Error error) override {
    // We'll get a read (shutdown) error when the connection is closed.
    CHECK_EQ(error, ERROR_READ_SHUTDOWN);
  }

  // Waits for all the messages to have been seen.
  void Wait() { done_event_.Wait(); }

 private:
  AutoResetWaitableEvent done_event_;
  size_t expected_count_;
  size_t count_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ReadCountdownRawChannelDelegate);
};

void WriteMessageAndOnReadMessageHelper(RawChannel* raw_channel,
                                        size_t write_count) {
  static const int kMaxRandomMessageSize = 25000;
  while (write_count-- > 0) {
    EXPECT_TRUE(raw_channel->WriteMessage(MakeTestMessage(
        static_cast<uint32_t>(test::RandomInt(1, kMaxRandomMessageSize)))));
  }
}

TEST_F(RawChannelTest, WriteMessageAndOnReadMessage) {
  static const size_t kNumWriterThreads = 10;
  static const size_t kNumWriteMessagesPerThread = 4000;

  WriteOnlyRawChannelDelegate writer_delegate;
  std::unique_ptr<RawChannel> writer_rc(RawChannel::Create(handles[0].Pass()));
  io_thread()->PostTaskAndWait([this, &writer_rc, &writer_delegate]() {
    writer_rc->Init(io_thread()->task_runner().Clone(),
                    io_thread()->platform_handle_watcher(), &writer_delegate);
  });

  ReadCountdownRawChannelDelegate reader_delegate(kNumWriterThreads *
                                                  kNumWriteMessagesPerThread);
  std::unique_ptr<RawChannel> reader_rc(RawChannel::Create(handles[1].Pass()));
  io_thread()->PostTaskAndWait([this, &reader_rc, &reader_delegate]() {
    reader_rc->Init(io_thread()->task_runner().Clone(),
                    io_thread()->platform_handle_watcher(), &reader_delegate);
  });

  std::vector<std::thread> writer_threads;
  // Create/start the the writer threads.
  for (size_t i = 0; i < kNumWriterThreads; i++) {
    writer_threads.push_back(std::thread(&WriteMessageAndOnReadMessageHelper,
                                         writer_rc.get(),
                                         kNumWriteMessagesPerThread));
  }
  for (auto& writer_thread : writer_threads)
    writer_thread.join();

  // Sleep a bit, to let any extraneous reads be processed. (There shouldn't be
  // any, but we want to know about them.)
  ThreadSleep(test::DeadlineFromMilliseconds(100u));

  // Wait for reading to finish.
  reader_delegate.Wait();

  io_thread()->PostTaskAndWait([&reader_rc]() { reader_rc->Shutdown(); });

  io_thread()->PostTaskAndWait([&writer_rc]() { writer_rc->Shutdown(); });
}

// RawChannelTest.OnError ------------------------------------------------------

class ErrorRecordingRawChannelDelegate
    : public ReadCountdownRawChannelDelegate {
 public:
  ErrorRecordingRawChannelDelegate(size_t expected_read_count,
                                   bool expect_read_error,
                                   bool expect_write_error)
      : ReadCountdownRawChannelDelegate(expected_read_count),
        expecting_read_error_(expect_read_error),
        expecting_write_error_(expect_write_error) {}

  ~ErrorRecordingRawChannelDelegate() override {}

  void OnError(Error error) override {
    switch (error) {
      case ERROR_READ_SHUTDOWN:
        ASSERT_TRUE(expecting_read_error_);
        expecting_read_error_ = false;
        got_read_error_event_.Signal();
        break;
      case ERROR_READ_BROKEN:
        // TODO(vtl): Test broken connections.
        CHECK(false);
        break;
      case ERROR_READ_BAD_MESSAGE:
        // TODO(vtl): Test reception/detection of bad messages.
        CHECK(false);
        break;
      case ERROR_READ_UNKNOWN:
        // TODO(vtl): Test however it is we might get here.
        CHECK(false);
        break;
      case ERROR_WRITE:
        ASSERT_TRUE(expecting_write_error_);
        expecting_write_error_ = false;
        got_write_error_event_.Signal();
        break;
    }
  }

  void WaitForReadError() { got_read_error_event_.Wait(); }
  void WaitForWriteError() { got_write_error_event_.Wait(); }

 private:
  AutoResetWaitableEvent got_read_error_event_;
  AutoResetWaitableEvent got_write_error_event_;

  bool expecting_read_error_;
  bool expecting_write_error_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ErrorRecordingRawChannelDelegate);
};

// Tests (fatal) errors.
TEST_F(RawChannelTest, OnError) {
  ErrorRecordingRawChannelDelegate delegate(0, true, true);
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Close the handle of the other end, which should make writing fail.
  handles[1].reset();

  EXPECT_FALSE(rc->WriteMessage(MakeTestMessage(1)));

  // We should get a write error.
  delegate.WaitForWriteError();

  // We should also get a read error.
  delegate.WaitForReadError();

  EXPECT_FALSE(rc->WriteMessage(MakeTestMessage(2)));

  // Sleep a bit, to make sure we don't get another |OnError()|
  // notification. (If we actually get another one, |OnError()| crashes.)
  ThreadSleep(test::DeadlineFromMilliseconds(20u));

  io_thread()->PostTaskAndWait([&rc]() { rc->Shutdown(); });
}

// RawChannelTest.ReadUnaffectedByWriteError -----------------------------------

TEST_F(RawChannelTest, ReadUnaffectedByWriteError) {
  const size_t kMessageCount = 5;

  // Write a few messages into the other end.
  uint32_t message_size = 1;
  for (size_t i = 0; i < kMessageCount;
       i++, message_size += message_size / 2 + 1)
    EXPECT_TRUE(WriteTestMessageToHandle(handles[1].get(), message_size));

  // Close the other end, which should make writing fail.
  handles[1].reset();

  // Only start up reading here. The system buffer should still contain the
  // messages that were written.
  ErrorRecordingRawChannelDelegate delegate(kMessageCount, true, true);
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  EXPECT_FALSE(rc->WriteMessage(MakeTestMessage(1)));

  // We should definitely get a write error.
  delegate.WaitForWriteError();

  // Wait for reading to finish. A writing failure shouldn't affect reading.
  delegate.Wait();

  // And then we should get a read error.
  delegate.WaitForReadError();

  io_thread()->PostTaskAndWait([&rc]() { rc->Shutdown(); });
}

// RawChannelTest.WriteMessageAfterShutdown ------------------------------------

// Makes sure that calling |WriteMessage()| after |Shutdown()| behaves
// correctly.
TEST_F(RawChannelTest, WriteMessageAfterShutdown) {
  WriteOnlyRawChannelDelegate delegate;
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });
  io_thread()->PostTaskAndWait([&rc]() { rc->Shutdown(); });

  EXPECT_FALSE(rc->WriteMessage(MakeTestMessage(1)));
}

// RawChannelTest.{Shutdown, ShutdownAndDestroy}OnReadMessage ------------------

class ShutdownOnReadMessageRawChannelDelegate : public RawChannel::Delegate {
 public:
  explicit ShutdownOnReadMessageRawChannelDelegate(RawChannel* raw_channel,
                                                   bool should_destroy)
      : raw_channel_(raw_channel),
        should_destroy_(should_destroy),
        did_shutdown_(false) {}
  ~ShutdownOnReadMessageRawChannelDelegate() override {}

  // |RawChannel::Delegate| implementation (called on the I/O thread):
  void OnReadMessage(const MessageInTransit::View& message_view,
                     std::unique_ptr<std::vector<ScopedPlatformHandle>>
                         platform_handles) override {
    EXPECT_FALSE(platform_handles);
    EXPECT_FALSE(did_shutdown_);
    EXPECT_TRUE(
        CheckMessageData(message_view.bytes(), message_view.num_bytes()));
    raw_channel_->Shutdown();
    if (should_destroy_)
      delete raw_channel_;
    did_shutdown_ = true;
    done_event_.Signal();
  }
  void OnError(Error /*error*/) override {
    CHECK(false);  // Should not get called.
  }

  // Waits for shutdown.
  void Wait() {
    done_event_.Wait();
    EXPECT_TRUE(did_shutdown_);
  }

 private:
  RawChannel* const raw_channel_;
  const bool should_destroy_;
  AutoResetWaitableEvent done_event_;
  bool did_shutdown_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ShutdownOnReadMessageRawChannelDelegate);
};

TEST_F(RawChannelTest, ShutdownOnReadMessage) {
  // Write a few messages into the other end.
  for (size_t count = 0; count < 5; count++)
    EXPECT_TRUE(WriteTestMessageToHandle(handles[1].get(), 10));

  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  ShutdownOnReadMessageRawChannelDelegate delegate(rc.get(), false);
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Wait for the delegate, which will shut the |RawChannel| down.
  delegate.Wait();
}

TEST_F(RawChannelTest, ShutdownAndDestroyOnReadMessage) {
  // Write a message into the other end.
  EXPECT_TRUE(WriteTestMessageToHandle(handles[1].get(), 10));

  // The delegate will destroy |rc|.
  RawChannel* rc = RawChannel::Create(handles[0].Pass()).release();
  ShutdownOnReadMessageRawChannelDelegate delegate(rc, true);
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Wait for the delegate, which will shut the |RawChannel| down.
  delegate.Wait();
}

// RawChannelTest.{Shutdown, ShutdownAndDestroy}OnError{Read, Write} -----------

class ShutdownOnErrorRawChannelDelegate : public RawChannel::Delegate {
 public:
  ShutdownOnErrorRawChannelDelegate(RawChannel* raw_channel,
                                    bool should_destroy,
                                    Error shutdown_on_error_type)
      : raw_channel_(raw_channel),
        should_destroy_(should_destroy),
        shutdown_on_error_type_(shutdown_on_error_type),
        did_shutdown_(false) {}
  ~ShutdownOnErrorRawChannelDelegate() override {}

  // |RawChannel::Delegate| implementation (called on the I/O thread):
  void OnReadMessage(
      const MessageInTransit::View& /*message_view*/,
      std::unique_ptr<std::vector<ScopedPlatformHandle>> /*platform_handles*/)
      override {
    CHECK(false);  // Should not get called.
  }
  void OnError(Error error) override {
    EXPECT_FALSE(did_shutdown_);
    if (error != shutdown_on_error_type_)
      return;
    raw_channel_->Shutdown();
    if (should_destroy_)
      delete raw_channel_;
    did_shutdown_ = true;
    done_event_.Signal();
  }

  // Waits for shutdown.
  void Wait() {
    done_event_.Wait();
    EXPECT_TRUE(did_shutdown_);
  }

 private:
  RawChannel* const raw_channel_;
  const bool should_destroy_;
  const Error shutdown_on_error_type_;
  AutoResetWaitableEvent done_event_;
  bool did_shutdown_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ShutdownOnErrorRawChannelDelegate);
};

TEST_F(RawChannelTest, ShutdownOnErrorRead) {
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  ShutdownOnErrorRawChannelDelegate delegate(
      rc.get(), false, RawChannel::Delegate::ERROR_READ_SHUTDOWN);
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Close the handle of the other end, which should stuff fail.
  handles[1].reset();

  // Wait for the delegate, which will shut the |RawChannel| down.
  delegate.Wait();
}

TEST_F(RawChannelTest, ShutdownAndDestroyOnErrorRead) {
  RawChannel* rc = RawChannel::Create(handles[0].Pass()).release();
  ShutdownOnErrorRawChannelDelegate delegate(
      rc, true, RawChannel::Delegate::ERROR_READ_SHUTDOWN);
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Close the handle of the other end, which should stuff fail.
  handles[1].reset();

  // Wait for the delegate, which will shut the |RawChannel| down.
  delegate.Wait();
}

TEST_F(RawChannelTest, ShutdownOnErrorWrite) {
  std::unique_ptr<RawChannel> rc(RawChannel::Create(handles[0].Pass()));
  ShutdownOnErrorRawChannelDelegate delegate(rc.get(), false,
                                             RawChannel::Delegate::ERROR_WRITE);
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Close the handle of the other end, which should stuff fail.
  handles[1].reset();

  EXPECT_FALSE(rc->WriteMessage(MakeTestMessage(1)));

  // Wait for the delegate, which will shut the |RawChannel| down.
  delegate.Wait();
}

TEST_F(RawChannelTest, ShutdownAndDestroyOnErrorWrite) {
  RawChannel* rc = RawChannel::Create(handles[0].Pass()).release();
  ShutdownOnErrorRawChannelDelegate delegate(rc, true,
                                             RawChannel::Delegate::ERROR_WRITE);
  io_thread()->PostTaskAndWait([this, &rc, &delegate]() {
    rc->Init(io_thread()->task_runner().Clone(),
             io_thread()->platform_handle_watcher(), &delegate);
  });

  // Close the handle of the other end, which should stuff fail.
  handles[1].reset();

  EXPECT_FALSE(rc->WriteMessage(MakeTestMessage(1)));

  // Wait for the delegate, which will shut the |RawChannel| down.
  delegate.Wait();
}

// RawChannelTest.ReadWritePlatformHandles -------------------------------------

class ReadPlatformHandlesCheckerRawChannelDelegate
    : public RawChannel::Delegate {
 public:
  ReadPlatformHandlesCheckerRawChannelDelegate() {}
  ~ReadPlatformHandlesCheckerRawChannelDelegate() override {}

  // |RawChannel::Delegate| implementation (called on the I/O thread):
  void OnReadMessage(const MessageInTransit::View& message_view,
                     std::unique_ptr<std::vector<ScopedPlatformHandle>>
                         platform_handles) override {
    const char kHello[] = "hello";

    EXPECT_EQ(sizeof(kHello), message_view.num_bytes());
    EXPECT_STREQ(kHello, static_cast<const char*>(message_view.bytes()));

    ASSERT_TRUE(platform_handles);
    ASSERT_EQ(2u, platform_handles->size());
    ScopedPlatformHandle h1(std::move(platform_handles->at(0)));
    EXPECT_TRUE(h1.is_valid());
    ScopedPlatformHandle h2(std::move(platform_handles->at(1)));
    EXPECT_TRUE(h2.is_valid());
    platform_handles->clear();

    {
      char buffer[100] = {};

      util::ScopedFILE fp(FILEFromPlatformHandle(h1.Pass(), "rb"));
      EXPECT_TRUE(fp);
      rewind(fp.get());
      EXPECT_EQ(1u, fread(buffer, 1, sizeof(buffer), fp.get()));
      EXPECT_EQ('1', buffer[0]);
    }

    {
      char buffer[100] = {};
      util::ScopedFILE fp(FILEFromPlatformHandle(h2.Pass(), "rb"));
      EXPECT_TRUE(fp);
      rewind(fp.get());
      EXPECT_EQ(1u, fread(buffer, 1, sizeof(buffer), fp.get()));
      EXPECT_EQ('2', buffer[0]);
    }

    done_event_.Signal();
  }
  void OnError(Error error) override {
    // We'll get a read (shutdown) error when the connection is closed.
    CHECK_EQ(error, ERROR_READ_SHUTDOWN);
  }

  void Wait() { done_event_.Wait(); }

 private:
  AutoResetWaitableEvent done_event_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(ReadPlatformHandlesCheckerRawChannelDelegate);
};

TEST_F(RawChannelTest, ReadWritePlatformHandles) {
  test::ScopedTestDir test_dir;

  WriteOnlyRawChannelDelegate write_delegate;
  std::unique_ptr<RawChannel> rc_write(RawChannel::Create(handles[0].Pass()));
  io_thread()->PostTaskAndWait([this, &rc_write, &write_delegate]() {
    rc_write->Init(io_thread()->task_runner().Clone(),
                   io_thread()->platform_handle_watcher(), &write_delegate);
  });

  ReadPlatformHandlesCheckerRawChannelDelegate read_delegate;
  std::unique_ptr<RawChannel> rc_read(RawChannel::Create(handles[1].Pass()));
  io_thread()->PostTaskAndWait([this, &rc_read, &read_delegate]() {
    rc_read->Init(io_thread()->task_runner().Clone(),
                  io_thread()->platform_handle_watcher(), &read_delegate);
  });

  util::ScopedFILE fp1(test_dir.CreateFile());
  EXPECT_EQ(1u, fwrite("1", 1, 1, fp1.get()));
  util::ScopedFILE fp2(test_dir.CreateFile());
  EXPECT_EQ(1u, fwrite("2", 1, 1, fp2.get()));

  {
    const char kHello[] = "hello";
    auto platform_handles = MakeUnique<std::vector<ScopedPlatformHandle>>();
    platform_handles->push_back(PlatformHandleFromFILE(std::move(fp1)));
    platform_handles->push_back(PlatformHandleFromFILE(std::move(fp2)));

    std::unique_ptr<MessageInTransit> message(
        new MessageInTransit(MessageInTransit::Type::ENDPOINT_CLIENT,
                             MessageInTransit::Subtype::ENDPOINT_CLIENT_DATA,
                             sizeof(kHello), kHello));
    message->SetTransportData(
        MakeUnique<TransportData>(std::move(platform_handles),
                                  rc_write->GetSerializedPlatformHandleSize()));
    EXPECT_TRUE(rc_write->WriteMessage(std::move(message)));
  }

  read_delegate.Wait();

  io_thread()->PostTaskAndWait([&rc_read]() { rc_read->Shutdown(); });
  io_thread()->PostTaskAndWait([&rc_write]() { rc_write->Shutdown(); });
}

}  // namespace
}  // namespace system
}  // namespace mojo
