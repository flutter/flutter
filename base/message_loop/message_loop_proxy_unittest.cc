// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/message_loop/message_loop_proxy.h"

#include "base/atomic_sequence_num.h"
#include "base/bind.h"
#include "base/debug/leak_annotations.h"
#include "base/memory/ref_counted.h"
#include "base/memory/scoped_ptr.h"
#include "base/message_loop/message_loop.h"
#include "base/synchronization/waitable_event.h"
#include "base/threading/thread.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

namespace {

class MessageLoopProxyTest : public testing::Test {
 public:
  MessageLoopProxyTest()
      : current_loop_(new MessageLoop()),
        task_thread_("task_thread"),
        thread_sync_(true, false) {
  }

  void DeleteCurrentMessageLoop() {
    current_loop_.reset();
  }

 protected:
  void SetUp() override {
    // Use SetUp() instead of the constructor to avoid posting a task to a
    // partialy constructed object.
    task_thread_.Start();

    // Allow us to pause the |task_thread_|'s MessageLoop.
    task_thread_.message_loop()->PostTask(
        FROM_HERE,
        Bind(&MessageLoopProxyTest::BlockTaskThreadHelper, Unretained(this)));
  }

  void TearDown() override {
    // Make sure the |task_thread_| is not blocked, and stop the thread
    // fully before destuction because its tasks may still depend on the
    // |thread_sync_| event.
    thread_sync_.Signal();
    task_thread_.Stop();
    DeleteCurrentMessageLoop();
  }

  // Make LoopRecorder threadsafe so that there is defined behavior even if a
  // threading mistake sneaks into the PostTaskAndReplyRelay implementation.
  class LoopRecorder : public RefCountedThreadSafe<LoopRecorder> {
   public:
    LoopRecorder(MessageLoop** run_on, MessageLoop** deleted_on,
                 int* destruct_order)
        : run_on_(run_on),
          deleted_on_(deleted_on),
          destruct_order_(destruct_order) {
    }

    void RecordRun() {
      *run_on_ = MessageLoop::current();
    }

   private:
    friend class RefCountedThreadSafe<LoopRecorder>;
    ~LoopRecorder() {
      *deleted_on_ = MessageLoop::current();
      *destruct_order_ = g_order.GetNext();
    }

    MessageLoop** run_on_;
    MessageLoop** deleted_on_;
    int* destruct_order_;
  };

  static void RecordLoop(scoped_refptr<LoopRecorder> recorder) {
    recorder->RecordRun();
  }

  static void RecordLoopAndQuit(scoped_refptr<LoopRecorder> recorder) {
    recorder->RecordRun();
    MessageLoop::current()->QuitWhenIdle();
  }

  void UnblockTaskThread() {
    thread_sync_.Signal();
  }

  void BlockTaskThreadHelper() {
    thread_sync_.Wait();
  }

  static StaticAtomicSequenceNumber g_order;

  scoped_ptr<MessageLoop> current_loop_;
  Thread task_thread_;

 private:
  base::WaitableEvent thread_sync_;
};

StaticAtomicSequenceNumber MessageLoopProxyTest::g_order;

TEST_F(MessageLoopProxyTest, PostTaskAndReply_Basic) {
  MessageLoop* task_run_on = NULL;
  MessageLoop* task_deleted_on = NULL;
  int task_delete_order = -1;
  MessageLoop* reply_run_on = NULL;
  MessageLoop* reply_deleted_on = NULL;
  int reply_delete_order = -1;

  scoped_refptr<LoopRecorder> task_recoder =
      new LoopRecorder(&task_run_on, &task_deleted_on, &task_delete_order);
  scoped_refptr<LoopRecorder> reply_recoder =
      new LoopRecorder(&reply_run_on, &reply_deleted_on, &reply_delete_order);

  ASSERT_TRUE(task_thread_.message_loop_proxy()->PostTaskAndReply(
      FROM_HERE,
      Bind(&RecordLoop, task_recoder),
      Bind(&RecordLoopAndQuit, reply_recoder)));

  // Die if base::Bind doesn't retain a reference to the recorders.
  task_recoder = NULL;
  reply_recoder = NULL;
  ASSERT_FALSE(task_deleted_on);
  ASSERT_FALSE(reply_deleted_on);

  UnblockTaskThread();
  current_loop_->Run();

  EXPECT_EQ(task_thread_.message_loop(), task_run_on);
  EXPECT_EQ(current_loop_.get(), task_deleted_on);
  EXPECT_EQ(current_loop_.get(), reply_run_on);
  EXPECT_EQ(current_loop_.get(), reply_deleted_on);
  EXPECT_LT(task_delete_order, reply_delete_order);
}

TEST_F(MessageLoopProxyTest, PostTaskAndReplyOnDeletedThreadDoesNotLeak) {
  MessageLoop* task_run_on = NULL;
  MessageLoop* task_deleted_on = NULL;
  int task_delete_order = -1;
  MessageLoop* reply_run_on = NULL;
  MessageLoop* reply_deleted_on = NULL;
  int reply_delete_order = -1;

  scoped_refptr<LoopRecorder> task_recoder =
      new LoopRecorder(&task_run_on, &task_deleted_on, &task_delete_order);
  scoped_refptr<LoopRecorder> reply_recoder =
      new LoopRecorder(&reply_run_on, &reply_deleted_on, &reply_delete_order);

  // Grab a MessageLoopProxy to a dead MessageLoop.
  scoped_refptr<MessageLoopProxy> task_loop_proxy =
      task_thread_.message_loop_proxy();
  UnblockTaskThread();
  task_thread_.Stop();

  ASSERT_FALSE(task_loop_proxy->PostTaskAndReply(
      FROM_HERE,
      Bind(&RecordLoop, task_recoder),
      Bind(&RecordLoopAndQuit, reply_recoder)));

  // The relay should have properly deleted its resources leaving us as the only
  // reference.
  EXPECT_EQ(task_delete_order, reply_delete_order);
  ASSERT_TRUE(task_recoder->HasOneRef());
  ASSERT_TRUE(reply_recoder->HasOneRef());

  // Nothing should have run though.
  EXPECT_FALSE(task_run_on);
  EXPECT_FALSE(reply_run_on);
}

TEST_F(MessageLoopProxyTest, PostTaskAndReply_SameLoop) {
  MessageLoop* task_run_on = NULL;
  MessageLoop* task_deleted_on = NULL;
  int task_delete_order = -1;
  MessageLoop* reply_run_on = NULL;
  MessageLoop* reply_deleted_on = NULL;
  int reply_delete_order = -1;

  scoped_refptr<LoopRecorder> task_recoder =
      new LoopRecorder(&task_run_on, &task_deleted_on, &task_delete_order);
  scoped_refptr<LoopRecorder> reply_recoder =
      new LoopRecorder(&reply_run_on, &reply_deleted_on, &reply_delete_order);

  // Enqueue the relay.
  ASSERT_TRUE(current_loop_->message_loop_proxy()->PostTaskAndReply(
      FROM_HERE,
      Bind(&RecordLoop, task_recoder),
      Bind(&RecordLoopAndQuit, reply_recoder)));

  // Die if base::Bind doesn't retain a reference to the recorders.
  task_recoder = NULL;
  reply_recoder = NULL;
  ASSERT_FALSE(task_deleted_on);
  ASSERT_FALSE(reply_deleted_on);

  current_loop_->Run();

  EXPECT_EQ(current_loop_.get(), task_run_on);
  EXPECT_EQ(current_loop_.get(), task_deleted_on);
  EXPECT_EQ(current_loop_.get(), reply_run_on);
  EXPECT_EQ(current_loop_.get(), reply_deleted_on);
  EXPECT_LT(task_delete_order, reply_delete_order);
}

TEST_F(MessageLoopProxyTest, PostTaskAndReply_DeadReplyLoopDoesNotDelete) {
  // Annotate the scope as having memory leaks to suppress heapchecker reports.
  ANNOTATE_SCOPED_MEMORY_LEAK;
  MessageLoop* task_run_on = NULL;
  MessageLoop* task_deleted_on = NULL;
  int task_delete_order = -1;
  MessageLoop* reply_run_on = NULL;
  MessageLoop* reply_deleted_on = NULL;
  int reply_delete_order = -1;

  scoped_refptr<LoopRecorder> task_recoder =
      new LoopRecorder(&task_run_on, &task_deleted_on, &task_delete_order);
  scoped_refptr<LoopRecorder> reply_recoder =
      new LoopRecorder(&reply_run_on, &reply_deleted_on, &reply_delete_order);

  // Enqueue the relay.
  task_thread_.message_loop_proxy()->PostTaskAndReply(
      FROM_HERE,
      Bind(&RecordLoop, task_recoder),
      Bind(&RecordLoopAndQuit, reply_recoder));

  // Die if base::Bind doesn't retain a reference to the recorders.
  task_recoder = NULL;
  reply_recoder = NULL;
  ASSERT_FALSE(task_deleted_on);
  ASSERT_FALSE(reply_deleted_on);

  UnblockTaskThread();

  // Mercilessly whack the current loop before |reply| gets to run.
  current_loop_.reset();

  // This should ensure the relay has been run.  We need to record the
  // MessageLoop pointer before stopping the thread because Thread::Stop() will
  // NULL out its own pointer.
  MessageLoop* task_loop = task_thread_.message_loop();
  task_thread_.Stop();

  EXPECT_EQ(task_loop, task_run_on);
  ASSERT_FALSE(task_deleted_on);
  EXPECT_FALSE(reply_run_on);
  ASSERT_FALSE(reply_deleted_on);
  EXPECT_EQ(task_delete_order, reply_delete_order);

  // The PostTaskAndReplyRelay is leaked here.  Even if we had a reference to
  // it, we cannot just delete it because PostTaskAndReplyRelay's destructor
  // checks that MessageLoop::current() is the the same as when the
  // PostTaskAndReplyRelay object was constructed.  However, this loop must have
  // aleady been deleted in order to perform this test.  See
  // http://crbug.com/86301.
}

}  // namespace

}  // namespace base
