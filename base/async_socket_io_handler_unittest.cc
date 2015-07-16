// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/async_socket_io_handler.h"

#include "base/bind.h"
#include "base/location.h"
#include "base/single_thread_task_runner.h"
#include "base/thread_task_runner_handle.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace {
const char kAsyncSocketIoTestString[] = "Hello, AsyncSocketIoHandler";
const size_t kAsyncSocketIoTestStringLength =
    arraysize(kAsyncSocketIoTestString);

class TestSocketReader {
 public:
  // Set |number_of_reads_before_quit| to >0 when you expect a specific number
  // of Read operations to complete.  Once that number is reached, the current
  // message loop will be Quit().  Set |number_of_reads_before_quit| to -1 if
  // callbacks should not be counted.
  TestSocketReader(base::CancelableSyncSocket* socket,
                   int number_of_reads_before_quit,
                   bool issue_reads_from_callback,
                   bool expect_eof)
      : socket_(socket), buffer_(),
        number_of_reads_before_quit_(number_of_reads_before_quit),
        callbacks_received_(0),
        issue_reads_from_callback_(issue_reads_from_callback),
        expect_eof_(expect_eof) {
    io_handler.Initialize(socket_->handle(),
                          base::Bind(&TestSocketReader::OnRead,
                                     base::Unretained(this)));
  }
  ~TestSocketReader() {}

  bool IssueRead() {
    return io_handler.Read(&buffer_[0], sizeof(buffer_));
  }

  const char* buffer() const { return &buffer_[0]; }

  int callbacks_received() const { return callbacks_received_; }

 private:
  void OnRead(int bytes_read) {
    if (!expect_eof_) {
      EXPECT_GT(bytes_read, 0);
    } else {
      EXPECT_GE(bytes_read, 0);
    }
    ++callbacks_received_;
    if (number_of_reads_before_quit_ == callbacks_received_) {
      base::MessageLoop::current()->Quit();
    } else if (issue_reads_from_callback_) {
      IssueRead();
    }
  }

  base::AsyncSocketIoHandler io_handler;
  base::CancelableSyncSocket* socket_;  // Ownership lies outside the class.
  char buffer_[kAsyncSocketIoTestStringLength];
  int number_of_reads_before_quit_;
  int callbacks_received_;
  bool issue_reads_from_callback_;
  bool expect_eof_;
};

// Workaround to be able to use a base::Closure for sending data.
// Send() returns int but a closure must return void.
void SendData(base::CancelableSyncSocket* socket,
              const void* buffer,
              size_t length) {
  socket->Send(buffer, length);
}

}  // end namespace.

// Tests doing a pending read from a socket and use an IO handler to get
// notified of data.
TEST(AsyncSocketIoHandlerTest, AsynchronousReadWithMessageLoop) {
  base::MessageLoopForIO loop;

  base::CancelableSyncSocket pair[2];
  ASSERT_TRUE(base::CancelableSyncSocket::CreatePair(&pair[0], &pair[1]));

  TestSocketReader reader(&pair[0], 1, false, false);
  EXPECT_TRUE(reader.IssueRead());

  pair[1].Send(kAsyncSocketIoTestString, kAsyncSocketIoTestStringLength);
  base::MessageLoop::current()->Run();
  EXPECT_EQ(strcmp(reader.buffer(), kAsyncSocketIoTestString), 0);
  EXPECT_EQ(1, reader.callbacks_received());
}

// Tests doing a read from a socket when we know that there is data in the
// socket.  Here we want to make sure that any async 'can read' notifications
// won't trip us off and that the synchronous case works as well.
TEST(AsyncSocketIoHandlerTest, SynchronousReadWithMessageLoop) {
  base::MessageLoopForIO loop;

  base::CancelableSyncSocket pair[2];
  ASSERT_TRUE(base::CancelableSyncSocket::CreatePair(&pair[0], &pair[1]));

  TestSocketReader reader(&pair[0], -1, false, false);

  pair[1].Send(kAsyncSocketIoTestString, kAsyncSocketIoTestStringLength);
  base::ThreadTaskRunnerHandle::Get()->PostDelayedTask(
      FROM_HERE, base::MessageLoop::QuitClosure(),
      base::TimeDelta::FromMilliseconds(100));
  base::MessageLoop::current()->Run();

  EXPECT_TRUE(reader.IssueRead());
  EXPECT_EQ(strcmp(reader.buffer(), kAsyncSocketIoTestString), 0);
  // We've now verified that the read happened synchronously, but it's not
  // guaranteed that the callback has been issued since the callback will be
  // called asynchronously even though the read may have been done.
  // So we call RunUntilIdle() to allow any event notifications or APC's on
  // Windows, to execute before checking the count of how many callbacks we've
  // received.
  base::MessageLoop::current()->RunUntilIdle();
  EXPECT_EQ(1, reader.callbacks_received());
}

// Calls Read() from within a callback to test that simple read "loops" work.
TEST(AsyncSocketIoHandlerTest, ReadFromCallback) {
  base::MessageLoopForIO loop;

  base::CancelableSyncSocket pair[2];
  ASSERT_TRUE(base::CancelableSyncSocket::CreatePair(&pair[0], &pair[1]));

  const int kReadOperationCount = 10;
  TestSocketReader reader(&pair[0], kReadOperationCount, true, false);
  EXPECT_TRUE(reader.IssueRead());

  // Issue sends on an interval to satisfy the Read() requirements.
  int64 milliseconds = 0;
  for (int i = 0; i < kReadOperationCount; ++i) {
    base::ThreadTaskRunnerHandle::Get()->PostDelayedTask(
        FROM_HERE, base::Bind(&SendData, &pair[1], kAsyncSocketIoTestString,
                              kAsyncSocketIoTestStringLength),
        base::TimeDelta::FromMilliseconds(milliseconds));
    milliseconds += 10;
  }

  base::ThreadTaskRunnerHandle::Get()->PostDelayedTask(
      FROM_HERE, base::MessageLoop::QuitClosure(),
      base::TimeDelta::FromMilliseconds(100 + milliseconds));

  base::MessageLoop::current()->Run();
  EXPECT_EQ(kReadOperationCount, reader.callbacks_received());
}

// Calls Read() then close other end, check that a correct callback is received.
TEST(AsyncSocketIoHandlerTest, ReadThenClose) {
  base::MessageLoopForIO loop;

  base::CancelableSyncSocket pair[2];
  ASSERT_TRUE(base::CancelableSyncSocket::CreatePair(&pair[0], &pair[1]));

  const int kReadOperationCount = 1;
  TestSocketReader reader(&pair[0], kReadOperationCount, false, true);
  EXPECT_TRUE(reader.IssueRead());

  pair[1].Close();

  base::MessageLoop::current()->Run();
  EXPECT_EQ(kReadOperationCount, reader.callbacks_received());
}
