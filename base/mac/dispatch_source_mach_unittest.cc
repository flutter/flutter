// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/mac/dispatch_source_mach.h"

#include <mach/mach.h>

#include "base/logging.h"
#include "base/mac/scoped_mach_port.h"
#include "base/memory/scoped_ptr.h"
#include "base/test/test_timeouts.h"
#include "testing/gtest/include/gtest/gtest.h"

namespace base {

class DispatchSourceMachTest : public testing::Test {
 public:
  void SetUp() override {
    mach_port_t port = MACH_PORT_NULL;
    ASSERT_EQ(KERN_SUCCESS, mach_port_allocate(mach_task_self(),
        MACH_PORT_RIGHT_RECEIVE, &port));
    receive_right_.reset(port);

    ASSERT_EQ(KERN_SUCCESS, mach_port_insert_right(mach_task_self(), port,
        port, MACH_MSG_TYPE_MAKE_SEND));
    send_right_.reset(port);
  }

  mach_port_t GetPort() { return receive_right_.get(); }

  void WaitForSemaphore(dispatch_semaphore_t semaphore) {
    dispatch_semaphore_wait(semaphore, dispatch_time(
        DISPATCH_TIME_NOW,
        TestTimeouts::action_timeout().InSeconds() * NSEC_PER_SEC));
  }

 private:
  base::mac::ScopedMachReceiveRight receive_right_;
  base::mac::ScopedMachSendRight send_right_;
};

TEST_F(DispatchSourceMachTest, ReceiveAfterResume) {
  dispatch_semaphore_t signal = dispatch_semaphore_create(0);
  mach_port_t port = GetPort();

  bool __block did_receive = false;
  DispatchSourceMach source("org.chromium.base.test.ReceiveAfterResume",
      port, ^{
          mach_msg_empty_rcv_t msg = {{0}};
          msg.header.msgh_size = sizeof(msg);
          msg.header.msgh_local_port = port;
          mach_msg_receive(&msg.header);
          did_receive = true;

          dispatch_semaphore_signal(signal);
      });

  mach_msg_empty_send_t msg = {{0}};
  msg.header.msgh_size = sizeof(msg);
  msg.header.msgh_remote_port = port;
  msg.header.msgh_bits = MACH_MSGH_BITS_REMOTE(MACH_MSG_TYPE_COPY_SEND);
  ASSERT_EQ(KERN_SUCCESS, mach_msg_send(&msg.header));

  EXPECT_FALSE(did_receive);

  source.Resume();

  WaitForSemaphore(signal);
  dispatch_release(signal);

  EXPECT_TRUE(did_receive);
}

TEST_F(DispatchSourceMachTest, NoMessagesAfterDestruction) {
  mach_port_t port = GetPort();

  scoped_ptr<int> count(new int(0));
  int* __block count_ptr = count.get();

  scoped_ptr<DispatchSourceMach> source(new DispatchSourceMach(
      "org.chromium.base.test.NoMessagesAfterDestruction",
      port, ^{
          mach_msg_empty_rcv_t msg = {{0}};
          msg.header.msgh_size = sizeof(msg);
          msg.header.msgh_local_port = port;
          mach_msg_receive(&msg.header);
          LOG(INFO) << "Receieve " << *count_ptr;
          ++(*count_ptr);
      }));
  source->Resume();

  dispatch_queue_t queue =
      dispatch_queue_create("org.chromium.base.test.MessageSend", NULL);
  dispatch_semaphore_t signal = dispatch_semaphore_create(0);
  for (int i = 0; i < 30; ++i) {
    dispatch_async(queue, ^{
        mach_msg_empty_send_t msg = {{0}};
        msg.header.msgh_size = sizeof(msg);
        msg.header.msgh_remote_port = port;
        msg.header.msgh_bits =
            MACH_MSGH_BITS_REMOTE(MACH_MSG_TYPE_COPY_SEND);
        mach_msg_send(&msg.header);
    });

    // After sending five messages, shut down the source and taint the
    // pointer the handler dereferences. The test will crash if |count_ptr|
    // is being used after "free".
    if (i == 5) {
      scoped_ptr<DispatchSourceMach>* source_ptr = &source;
      dispatch_async(queue, ^{
          source_ptr->reset();
          count_ptr = reinterpret_cast<int*>(0xdeaddead);
          dispatch_semaphore_signal(signal);
      });
    }
  }

  WaitForSemaphore(signal);
  dispatch_release(signal);

  dispatch_release(queue);
}

}  // namespace base
