// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/thread.h"

#if defined(FML_OS_MACOSX) || defined(FML_OS_LINUX) || defined(FML_OS_ANDROID)
#define FLUTTER_PTHREAD_SUPPORTED 1
#else
#define FLUTTER_PTHREAD_SUPPORTED 0
#endif

#if FLUTTER_PTHREAD_SUPPORTED
#include <pthread.h>
#else
#endif

#include <memory>
#include "gtest/gtest.h"

TEST(Thread, CanStartAndEnd) {
  fml::Thread thread;
  ASSERT_TRUE(thread.GetTaskRunner());
}

TEST(Thread, CanStartAndEndWithExplicitJoin) {
  fml::Thread thread;
  ASSERT_TRUE(thread.GetTaskRunner());
  thread.Join();
}

TEST(Thread, HasARunningMessageLoop) {
  fml::Thread thread;
  bool done = false;
  thread.GetTaskRunner()->PostTask([&done]() { done = true; });
  thread.Join();
  ASSERT_TRUE(done);
}

#if FLUTTER_PTHREAD_SUPPORTED
TEST(Thread, ThreadNameCreatedWithConfig) {
  const std::string name = "Thread1";
  fml::Thread thread(name);

  bool done = false;
  thread.GetTaskRunner()->PostTask([&done, &name]() {
    done = true;
    char thread_name[8];
    pthread_t current_thread = pthread_self();
    pthread_getname_np(current_thread, thread_name, 8);
    ASSERT_EQ(thread_name, name);
  });
  thread.Join();
  ASSERT_TRUE(done);
}

static void MockThreadConfigSetter(const fml::Thread::ThreadConfig& config) {
  // set thread name
  fml::Thread::SetCurrentThreadName(config);

  pthread_t tid = pthread_self();
  struct sched_param param;
  int policy = SCHED_OTHER;
  switch (config.priority) {
    case fml::Thread::ThreadPriority::kDisplay:
      param.sched_priority = 10;
      break;
    default:
      param.sched_priority = 1;
  }
  pthread_setschedparam(tid, policy, &param);
}

TEST(Thread, ThreadPriorityCreatedWithConfig) {
  const std::string thread1_name = "Thread1";
  const std::string thread2_name = "Thread2";

  fml::Thread thread(MockThreadConfigSetter,
                     fml::Thread::ThreadConfig(
                         thread1_name, fml::Thread::ThreadPriority::kNormal));
  bool done = false;

  struct sched_param param;
  int policy;
  thread.GetTaskRunner()->PostTask([&]() {
    done = true;
    char thread_name[8];
    pthread_t current_thread = pthread_self();
    pthread_getname_np(current_thread, thread_name, 8);
    pthread_getschedparam(current_thread, &policy, &param);
    ASSERT_EQ(thread_name, thread1_name);
    ASSERT_EQ(policy, SCHED_OTHER);
    ASSERT_EQ(param.sched_priority, 1);
  });

  fml::Thread thread2(MockThreadConfigSetter,
                      fml::Thread::ThreadConfig(
                          thread2_name, fml::Thread::ThreadPriority::kDisplay));
  thread2.GetTaskRunner()->PostTask([&]() {
    done = true;
    char thread_name[8];
    pthread_t current_thread = pthread_self();
    pthread_getname_np(current_thread, thread_name, 8);
    pthread_getschedparam(current_thread, &policy, &param);
    ASSERT_EQ(thread_name, thread2_name);
    ASSERT_EQ(policy, SCHED_OTHER);
    ASSERT_EQ(param.sched_priority, 10);
  });
  thread.Join();
  ASSERT_TRUE(done);
}
#endif
