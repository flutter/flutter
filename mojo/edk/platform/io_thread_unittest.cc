// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/platform/io_thread.h"

#include <memory>
#include <vector>

#include "mojo/edk/platform/platform_handle_watcher.h"
#include "mojo/edk/platform/task_runner.h"
#include "mojo/edk/platform/thread.h"
#include "mojo/edk/util/ref_ptr.h"
#include "mojo/edk/util/waitable_event.h"
#include "testing/gtest/include/gtest/gtest.h"

using mojo::platform::PlatformHandleWatcher;
using mojo::platform::PlatformHandleWatcher;
using mojo::platform::TaskRunner;
using mojo::platform::Thread;
using mojo::util::AutoResetWaitableEvent;
using mojo::util::RefPtr;

namespace {

TEST(IOThreadTest, CreateAndStartIOThread_TaskRunner) {
  RefPtr<TaskRunner> task_runner;
  PlatformHandleWatcher* platform_handle_watcher;
  std::unique_ptr<Thread> thread = mojo::platform::CreateAndStartIOThread(
      &task_runner, &platform_handle_watcher);
  ASSERT_TRUE(task_runner);

  std::vector<int> stuff;
  // Should be able to post tasks immediately.
  AutoResetWaitableEvent event;
  ASSERT_FALSE(event.IsSignaledForTest());
  task_runner->PostTask([&stuff]() { stuff.push_back(1); });
  task_runner->PostTask([&stuff, &event]() {
    stuff.push_back(2);
    event.Signal();
  });
  // The thread was already started, so wait for the task to run.
  event.Wait();

  // Should still be able to post tasks now that we know it's running.
  ASSERT_FALSE(event.IsSignaledForTest());
  task_runner->PostTask([&stuff]() { stuff.push_back(3); });
  task_runner->PostTask([&stuff, &event]() {
    stuff.push_back(4);
    event.Signal();
  });
  event.Wait();

  thread->Stop();

  std::vector<int> expected_stuff = {1, 2, 3, 4};
  EXPECT_EQ(expected_stuff, stuff);
}

TEST(IOThreadTest, CreateAndStartIOThread_Watcher) {
  RefPtr<TaskRunner> task_runner;
  PlatformHandleWatcher* platform_handle_watcher;
  std::unique_ptr<Thread> thread = mojo::platform::CreateAndStartIOThread(
      &task_runner, &platform_handle_watcher);
  ASSERT_TRUE(task_runner);
  ASSERT_TRUE(platform_handle_watcher);

  // TODO(vtl): Test the handle watcher. This is annoying to do, since we can't
  // use |base_edk::test::PlatformHandleWatcherTestHelper()|: it needs to run
  // the message loop, which we can't and shouldn't (since the message loop is
  // owned by the base::Thread) do. :(

  thread->Stop();
}

}  // namespace
