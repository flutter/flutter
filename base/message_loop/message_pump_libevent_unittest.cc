// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_pump_libevent.h"

#include <unistd.h>

#include "base/bind.h"
#include "base/bind_helpers.h"
#include "base/files/file_util.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/posix/eintr_wrapper.h"
#include "base/run_loop.h"
#include "base/synchronization/waitable_event.h"
#include "base/synchronization/waitable_event_watcher.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"
#include "third_party/libevent/event.h"

namespace base {

class MessagePumpLibeventTest : public testing::Test {
 protected:
  MessagePumpLibeventTest()
      : ui_loop_(new MessageLoop(MessageLoop::TYPE_UI)),
        io_thread_("MessagePumpLibeventTestIOThread") {}
  ~MessagePumpLibeventTest() override {}

  void SetUp() override {
    Thread::Options options(MessageLoop::TYPE_IO, 0);
    ASSERT_TRUE(io_thread_.StartWithOptions(options));
    ASSERT_EQ(MessageLoop::TYPE_IO, io_thread_.message_loop()->type());
    int ret = pipe(pipefds_);
    ASSERT_EQ(0, ret);
  }

  void TearDown() override {
    if (IGNORE_EINTR(close(pipefds_[0])) < 0)
      PLOG(ERROR) << "close";
    if (IGNORE_EINTR(close(pipefds_[1])) < 0)
      PLOG(ERROR) << "close";
  }

  MessageLoopForIO* io_loop() const {
    return static_cast<MessageLoopForIO*>(io_thread_.message_loop());
  }

  void OnLibeventNotification(
      MessagePumpLibevent* pump,
      MessagePumpLibevent::FileDescriptorWatcher* controller) {
    pump->OnLibeventNotification(0, EV_WRITE | EV_READ, controller);
  }

  int pipefds_[2];
  scoped_ptr<MessageLoop> ui_loop_;

 private:
  Thread io_thread_;
};

namespace {

// Concrete implementation of MessagePumpLibevent::Watcher that does
// nothing useful.
class StupidWatcher : public MessagePumpLibevent::Watcher {
 public:
  ~StupidWatcher() override {}

  // base:MessagePumpLibevent::Watcher interface
  void OnFileCanReadWithoutBlocking(int fd) override {}
  void OnFileCanWriteWithoutBlocking(int fd) override {}
};

#if GTEST_HAS_DEATH_TEST && !defined(NDEBUG)

// Test to make sure that we catch calling WatchFileDescriptor off of the
// wrong thread.
#if defined(OS_CHROMEOS) || defined(OS_LINUX)
// Flaky on Chrome OS and Linux: crbug.com/138845.
#define MAYBE_TestWatchingFromBadThread DISABLED_TestWatchingFromBadThread
#else
#define MAYBE_TestWatchingFromBadThread TestWatchingFromBadThread
#endif
TEST_F(MessagePumpLibeventTest, MAYBE_TestWatchingFromBadThread) {
  MessagePumpLibevent::FileDescriptorWatcher watcher;
  StupidWatcher delegate;

  ASSERT_DEATH(io_loop()->WatchFileDescriptor(
      STDOUT_FILENO, false, MessageLoopForIO::WATCH_READ, &watcher, &delegate),
      "Check failed: "
      "watch_file_descriptor_caller_checker_.CalledOnValidThread\\(\\)");
}

TEST_F(MessagePumpLibeventTest, QuitOutsideOfRun) {
  scoped_ptr<MessagePumpLibevent> pump(new MessagePumpLibevent);
  ASSERT_DEATH(pump->Quit(), "Check failed: in_run_. "
                             "Quit was called outside of Run!");
}

#endif  // GTEST_HAS_DEATH_TEST && !defined(NDEBUG)

class BaseWatcher : public MessagePumpLibevent::Watcher {
 public:
  explicit BaseWatcher(MessagePumpLibevent::FileDescriptorWatcher* controller)
      : controller_(controller) {
    DCHECK(controller_);
  }
  ~BaseWatcher() override {}

  // base:MessagePumpLibevent::Watcher interface
  void OnFileCanReadWithoutBlocking(int /* fd */) override { NOTREACHED(); }

  void OnFileCanWriteWithoutBlocking(int /* fd */) override { NOTREACHED(); }

 protected:
  MessagePumpLibevent::FileDescriptorWatcher* controller_;
};

class DeleteWatcher : public BaseWatcher {
 public:
  explicit DeleteWatcher(
      MessagePumpLibevent::FileDescriptorWatcher* controller)
      : BaseWatcher(controller) {}

  ~DeleteWatcher() override { DCHECK(!controller_); }

  void OnFileCanWriteWithoutBlocking(int /* fd */) override {
    DCHECK(controller_);
    delete controller_;
    controller_ = NULL;
  }
};

TEST_F(MessagePumpLibeventTest, DeleteWatcher) {
  scoped_ptr<MessagePumpLibevent> pump(new MessagePumpLibevent);
  MessagePumpLibevent::FileDescriptorWatcher* watcher =
      new MessagePumpLibevent::FileDescriptorWatcher;
  DeleteWatcher delegate(watcher);
  pump->WatchFileDescriptor(pipefds_[1],
      false, MessagePumpLibevent::WATCH_READ_WRITE, watcher, &delegate);

  // Spoof a libevent notification.
  OnLibeventNotification(pump.get(), watcher);
}

class StopWatcher : public BaseWatcher {
 public:
  explicit StopWatcher(
      MessagePumpLibevent::FileDescriptorWatcher* controller)
      : BaseWatcher(controller) {}

  ~StopWatcher() override {}

  void OnFileCanWriteWithoutBlocking(int /* fd */) override {
    controller_->StopWatchingFileDescriptor();
  }
};

TEST_F(MessagePumpLibeventTest, StopWatcher) {
  scoped_ptr<MessagePumpLibevent> pump(new MessagePumpLibevent);
  MessagePumpLibevent::FileDescriptorWatcher watcher;
  StopWatcher delegate(&watcher);
  pump->WatchFileDescriptor(pipefds_[1],
      false, MessagePumpLibevent::WATCH_READ_WRITE, &watcher, &delegate);

  // Spoof a libevent notification.
  OnLibeventNotification(pump.get(), &watcher);
}

void QuitMessageLoopAndStart(const Closure& quit_closure) {
  quit_closure.Run();

  MessageLoop::ScopedNestableTaskAllower allow(MessageLoop::current());
  RunLoop runloop;
  MessageLoop::current()->PostTask(FROM_HERE, runloop.QuitClosure());
  runloop.Run();
}

class NestedPumpWatcher : public MessagePumpLibevent::Watcher {
 public:
  NestedPumpWatcher() {}
  ~NestedPumpWatcher() override {}

  void OnFileCanReadWithoutBlocking(int /* fd */) override {
    RunLoop runloop;
    MessageLoop::current()->PostTask(FROM_HERE, Bind(&QuitMessageLoopAndStart,
                                                     runloop.QuitClosure()));
    runloop.Run();
  }

  void OnFileCanWriteWithoutBlocking(int /* fd */) override {}
};

TEST_F(MessagePumpLibeventTest, NestedPumpWatcher) {
  scoped_ptr<MessagePumpLibevent> pump(new MessagePumpLibevent);
  MessagePumpLibevent::FileDescriptorWatcher watcher;
  NestedPumpWatcher delegate;
  pump->WatchFileDescriptor(pipefds_[1],
      false, MessagePumpLibevent::WATCH_READ, &watcher, &delegate);

  // Spoof a libevent notification.
  OnLibeventNotification(pump.get(), &watcher);
}

void FatalClosure() {
  FAIL() << "Reached fatal closure.";
}

class QuitWatcher : public BaseWatcher {
 public:
  QuitWatcher(MessagePumpLibevent::FileDescriptorWatcher* controller,
              RunLoop* run_loop)
      : BaseWatcher(controller), run_loop_(run_loop) {}
  ~QuitWatcher() override {}

  void OnFileCanReadWithoutBlocking(int /* fd */) override {
    // Post a fatal closure to the MessageLoop before we quit it.
    MessageLoop::current()->PostTask(FROM_HERE, Bind(&FatalClosure));

    // Now quit the MessageLoop.
    run_loop_->Quit();
  }

 private:
  RunLoop* run_loop_;  // weak
};

void WriteFDWrapper(const int fd,
                    const char* buf,
                    int size,
                    WaitableEvent* event) {
  ASSERT_TRUE(WriteFileDescriptor(fd, buf, size));
}

// Tests that MessagePumpLibevent quits immediately when it is quit from
// libevent's event_base_loop().
TEST_F(MessagePumpLibeventTest, QuitWatcher) {
  // Delete the old MessageLoop so that we can manage our own one here.
  ui_loop_.reset();

  MessagePumpLibevent* pump = new MessagePumpLibevent;  // owned by |loop|.
  MessageLoop loop(make_scoped_ptr(pump));
  RunLoop run_loop;
  MessagePumpLibevent::FileDescriptorWatcher controller;
  QuitWatcher delegate(&controller, &run_loop);
  WaitableEvent event(false /* manual_reset */, false /* initially_signaled */);
  scoped_ptr<WaitableEventWatcher> watcher(new WaitableEventWatcher);

  // Tell the pump to watch the pipe.
  pump->WatchFileDescriptor(pipefds_[0], false, MessagePumpLibevent::WATCH_READ,
                            &controller, &delegate);

  // Make the IO thread wait for |event| before writing to pipefds[1].
  const char buf = 0;
  const WaitableEventWatcher::EventCallback write_fd_task =
      Bind(&WriteFDWrapper, pipefds_[1], &buf, 1);
  io_loop()->PostTask(FROM_HERE,
                      Bind(IgnoreResult(&WaitableEventWatcher::StartWatching),
                           Unretained(watcher.get()), &event, write_fd_task));

  // Queue |event| to signal on |loop|.
  loop.PostTask(FROM_HERE, Bind(&WaitableEvent::Signal, Unretained(&event)));

  // Now run the MessageLoop.
  run_loop.Run();

  // StartWatching can move |watcher| to IO thread. Release on IO thread.
  io_loop()->PostTask(FROM_HERE, Bind(&WaitableEventWatcher::StopWatching,
                                      Owned(watcher.release())));
}

}  // namespace

}  // namespace base
