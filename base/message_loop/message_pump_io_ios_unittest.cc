// Copyright 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_io_ios.h"

#include <unistd.h>

#include "base/message_loop/message_loop.h"
#include "base/posix/eintr_wrapper.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class MessagePumpIOSForIOTest : public testing::Test {
 protected:
  MessagePumpIOSForIOTest()
      : ui_loop_(MessageLoop::TYPE_UI),
        io_thread_("MessagePumpIOSForIOTestIOThread") {}
  ~MessagePumpIOSForIOTest() override {}

  void SetUp() override {
    Thread::Options options(MessageLoop::TYPE_IO, 0);
    ASSERT_TRUE(io_thread_.StartWithOptions(options));
    ASSERT_EQ(MessageLoop::TYPE_IO, io_thread_.message_loop()->type());
    int ret = pipe(pipefds_);
    ASSERT_EQ(0, ret);
    ret = pipe(alternate_pipefds_);
    ASSERT_EQ(0, ret);
  }

  void TearDown() override {
    if (IGNORE_EINTR(close(pipefds_[0])) < 0)
      PLOG(ERROR) << "close";
    if (IGNORE_EINTR(close(pipefds_[1])) < 0)
      PLOG(ERROR) << "close";
  }

  MessageLoop* ui_loop() { return &ui_loop_; }
  MessageLoopForIO* io_loop() const {
    return static_cast<MessageLoopForIO*>(io_thread_.message_loop());
  }

  void HandleFdIOEvent(MessageLoopForIO::FileDescriptorWatcher* watcher) {
    MessagePumpIOSForIO::HandleFdIOEvent(watcher->fdref_,
        kCFFileDescriptorReadCallBack | kCFFileDescriptorWriteCallBack,
        watcher);
  }

  int pipefds_[2];
  int alternate_pipefds_[2];

 private:
  MessageLoop ui_loop_;
  Thread io_thread_;

  DISALLOW_COPY_AND_ASSIGN(MessagePumpIOSForIOTest);
};

namespace {

// Concrete implementation of MessagePumpIOSForIO::Watcher that does
// nothing useful.
class StupidWatcher : public MessagePumpIOSForIO::Watcher {
 public:
  ~StupidWatcher() override {}

  // base:MessagePumpIOSForIO::Watcher interface
  void OnFileCanReadWithoutBlocking(int fd) override {}
  void OnFileCanWriteWithoutBlocking(int fd) override {}
};

#if GTEST_HAS_DEATH_TEST && !defined(NDEBUG)

// Test to make sure that we catch calling WatchFileDescriptor off of the
//  wrong thread.
TEST_F(MessagePumpIOSForIOTest, TestWatchingFromBadThread) {
  MessagePumpIOSForIO::FileDescriptorWatcher watcher;
  StupidWatcher delegate;

  ASSERT_DEBUG_DEATH(io_loop()->WatchFileDescriptor(
      STDOUT_FILENO, false, MessageLoopForIO::WATCH_READ, &watcher, &delegate),
      "Check failed: "
      "watch_file_descriptor_caller_checker_.CalledOnValidThread\\(\\)");
}

#endif  // GTEST_HAS_DEATH_TEST && !defined(NDEBUG)

class BaseWatcher : public MessagePumpIOSForIO::Watcher {
 public:
  BaseWatcher(MessagePumpIOSForIO::FileDescriptorWatcher* controller)
      : controller_(controller) {
    DCHECK(controller_);
  }
  ~BaseWatcher() override {}

  // MessagePumpIOSForIO::Watcher interface
  void OnFileCanReadWithoutBlocking(int /* fd */) override { NOTREACHED(); }

  void OnFileCanWriteWithoutBlocking(int /* fd */) override { NOTREACHED(); }

 protected:
  MessagePumpIOSForIO::FileDescriptorWatcher* controller_;
};

class DeleteWatcher : public BaseWatcher {
 public:
  explicit DeleteWatcher(
      MessagePumpIOSForIO::FileDescriptorWatcher* controller)
      : BaseWatcher(controller) {}

  ~DeleteWatcher() override { DCHECK(!controller_); }

  void OnFileCanWriteWithoutBlocking(int /* fd */) override {
    DCHECK(controller_);
    delete controller_;
    controller_ = NULL;
  }
};

TEST_F(MessagePumpIOSForIOTest, DeleteWatcher) {
  scoped_ptr<MessagePumpIOSForIO> pump(new MessagePumpIOSForIO);
  MessagePumpIOSForIO::FileDescriptorWatcher* watcher =
      new MessagePumpIOSForIO::FileDescriptorWatcher;
  DeleteWatcher delegate(watcher);
  pump->WatchFileDescriptor(pipefds_[1],
      false, MessagePumpIOSForIO::WATCH_READ_WRITE, watcher, &delegate);

  // Spoof a callback.
  HandleFdIOEvent(watcher);
}

class StopWatcher : public BaseWatcher {
 public:
  StopWatcher(MessagePumpIOSForIO::FileDescriptorWatcher* controller,
              MessagePumpIOSForIO* pump,
              int fd_to_start_watching = -1)
      : BaseWatcher(controller),
        pump_(pump),
        fd_to_start_watching_(fd_to_start_watching) {}

  ~StopWatcher() override {}

  void OnFileCanWriteWithoutBlocking(int /* fd */) override {
    controller_->StopWatchingFileDescriptor();
    if (fd_to_start_watching_ >= 0) {
      pump_->WatchFileDescriptor(fd_to_start_watching_,
          false, MessagePumpIOSForIO::WATCH_READ_WRITE, controller_, this);
    }
  }

 private:
  MessagePumpIOSForIO* pump_;
  int fd_to_start_watching_;
};

TEST_F(MessagePumpIOSForIOTest, StopWatcher) {
  scoped_ptr<MessagePumpIOSForIO> pump(new MessagePumpIOSForIO);
  MessagePumpIOSForIO::FileDescriptorWatcher watcher;
  StopWatcher delegate(&watcher, pump.get());
  pump->WatchFileDescriptor(pipefds_[1],
      false, MessagePumpIOSForIO::WATCH_READ_WRITE, &watcher, &delegate);

  // Spoof a callback.
  HandleFdIOEvent(&watcher);
}

TEST_F(MessagePumpIOSForIOTest, StopWatcherAndWatchSomethingElse) {
  scoped_ptr<MessagePumpIOSForIO> pump(new MessagePumpIOSForIO);
  MessagePumpIOSForIO::FileDescriptorWatcher watcher;
  StopWatcher delegate(&watcher, pump.get(), alternate_pipefds_[1]);
  pump->WatchFileDescriptor(pipefds_[1],
      false, MessagePumpIOSForIO::WATCH_READ_WRITE, &watcher, &delegate);

  // Spoof a callback.
  HandleFdIOEvent(&watcher);
}

}  // namespace

}  // namespace base
