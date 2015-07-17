// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/thread.h"

#include "base/bind.h"
#include "base/lazy_instance.h"
#include "base/location.h"
#include "base/synchronization/waitable_event.h"
#include "base/third_party/dynamic_annotations/dynamic_annotations.h"
#include "base/threading/thread_id_name_manager.h"
#include "base/threading/thread_local.h"
#include "base/threading/thread_restrictions.h"

#if defined(OS_WIN)
#include "base/win/scoped_com_initializer.h"
#endif

namespace base {

namespace {

// We use this thread-local variable to record whether or not a thread exited
// because its Stop method was called.  This allows us to catch cases where
// MessageLoop::QuitWhenIdle() is called directly, which is unexpected when
// using a Thread to setup and run a MessageLoop.
base::LazyInstance<base::ThreadLocalBoolean> lazy_tls_bool =
    LAZY_INSTANCE_INITIALIZER;

}  // namespace

// This is used to trigger the message loop to exit.
void ThreadQuitHelper() {
  MessageLoop::current()->QuitWhenIdle();
  Thread::SetThreadWasQuitProperly(true);
}

Thread::Options::Options()
    : message_loop_type(MessageLoop::TYPE_DEFAULT),
      timer_slack(TIMER_SLACK_NONE),
      stack_size(0),
      priority(ThreadPriority::NORMAL) {
}

Thread::Options::Options(MessageLoop::Type type,
                         size_t size)
    : message_loop_type(type),
      timer_slack(TIMER_SLACK_NONE),
      stack_size(size),
      priority(ThreadPriority::NORMAL) {
}

Thread::Options::~Options() {
}

Thread::Thread(const std::string& name)
    :
#if defined(OS_WIN)
      com_status_(NONE),
#endif
      stopping_(false),
      running_(false),
      thread_(0),
      message_loop_(nullptr),
      message_loop_timer_slack_(TIMER_SLACK_NONE),
      name_(name) {
}

Thread::~Thread() {
  Stop();
}

bool Thread::Start() {
  Options options;
#if defined(OS_WIN)
  if (com_status_ == STA)
    options.message_loop_type = MessageLoop::TYPE_UI;
#endif
  return StartWithOptions(options);
}

bool Thread::StartWithOptions(const Options& options) {
  DCHECK(!message_loop_);
#if defined(OS_WIN)
  DCHECK((com_status_ != STA) ||
      (options.message_loop_type == MessageLoop::TYPE_UI));
#endif

  SetThreadWasQuitProperly(false);

  MessageLoop::Type type = options.message_loop_type;
  if (!options.message_pump_factory.is_null())
    type = MessageLoop::TYPE_CUSTOM;

  message_loop_timer_slack_ = options.timer_slack;
  scoped_ptr<MessageLoop> message_loop = MessageLoop::CreateUnbound(
      type, options.message_pump_factory);
  message_loop_ = message_loop.get();
  start_event_.reset(new WaitableEvent(false, false));

  // Hold the thread_lock_ while starting a new thread, so that we can make sure
  // that thread_ is populated before the newly created thread accesses it.
  {
    AutoLock lock(thread_lock_);
    bool created;
    if (options.priority == ThreadPriority::NORMAL) {
      created = PlatformThread::Create(options.stack_size, this, &thread_);
    } else {
      created = PlatformThread::CreateWithPriority(options.stack_size, this,
                                                   &thread_, options.priority);
    }
    if (!created) {
      DLOG(ERROR) << "failed to create thread";
      message_loop_ = nullptr;
      start_event_.reset();
      return false;
    }
  }

  // The ownership of message_loop is managemed by the newly created thread
  // within the ThreadMain.
  ignore_result(message_loop.release());

  DCHECK(message_loop_);
  return true;
}

bool Thread::StartAndWaitForTesting() {
  bool result = Start();
  if (!result)
    return false;
  WaitUntilThreadStarted();
  return true;
}

bool Thread::WaitUntilThreadStarted() {
  if (!start_event_)
    return false;
  base::ThreadRestrictions::ScopedAllowWait allow_wait;
  start_event_->Wait();
  return true;
}

void Thread::Stop() {
  if (!start_event_)
    return;

  StopSoon();

  // Wait for the thread to exit.
  //
  // TODO(darin): Unfortunately, we need to keep message_loop_ around until
  // the thread exits.  Some consumers are abusing the API.  Make them stop.
  //
  PlatformThread::Join(thread_);

  // The thread should NULL message_loop_ on exit.
  DCHECK(!message_loop_);

  // The thread no longer needs to be joined.
  start_event_.reset();

  stopping_ = false;
}

void Thread::StopSoon() {
  // We should only be called on the same thread that started us.

  DCHECK_NE(thread_id(), PlatformThread::CurrentId());

  if (stopping_ || !message_loop_)
    return;

  stopping_ = true;
  task_runner()->PostTask(FROM_HERE, base::Bind(&ThreadQuitHelper));
}

PlatformThreadId Thread::thread_id() const {
  AutoLock lock(thread_lock_);
  return thread_.id();
}

bool Thread::IsRunning() const {
  // If the thread's already started (i.e. message_loop_ is non-null) and
  // not yet requested to stop (i.e. stopping_ is false) we can just return
  // true. (Note that stopping_ is touched only on the same thread that
  // starts / started the new thread so we need no locking here.)
  if (message_loop_ && !stopping_)
    return true;
  // Otherwise check the running_ flag, which is set to true by the new thread
  // only while it is inside Run().
  AutoLock lock(running_lock_);
  return running_;
}

void Thread::Run(MessageLoop* message_loop) {
  message_loop->Run();
}

void Thread::SetThreadWasQuitProperly(bool flag) {
  lazy_tls_bool.Pointer()->Set(flag);
}

bool Thread::GetThreadWasQuitProperly() {
  bool quit_properly = true;
#ifndef NDEBUG
  quit_properly = lazy_tls_bool.Pointer()->Get();
#endif
  return quit_properly;
}

void Thread::ThreadMain() {
  // Complete the initialization of our Thread object.
  PlatformThread::SetName(name_.c_str());
  ANNOTATE_THREAD_NAME(name_.c_str());  // Tell the name to race detector.

  // Lazily initialize the message_loop so that it can run on this thread.
  DCHECK(message_loop_);
  scoped_ptr<MessageLoop> message_loop(message_loop_);
  message_loop_->BindToCurrentThread();
  message_loop_->set_thread_name(name_);
  message_loop_->SetTimerSlack(message_loop_timer_slack_);

#if defined(OS_WIN)
  scoped_ptr<win::ScopedCOMInitializer> com_initializer;
  if (com_status_ != NONE) {
    com_initializer.reset((com_status_ == STA) ?
        new win::ScopedCOMInitializer() :
        new win::ScopedCOMInitializer(win::ScopedCOMInitializer::kMTA));
  }
#endif

  // Make sure the thread_id() returns current thread.
  // (This internally acquires lock against PlatformThread::Create)
  DCHECK_EQ(thread_id(), PlatformThread::CurrentId());

  // Let the thread do extra initialization.
  Init();

  {
    AutoLock lock(running_lock_);
    running_ = true;
  }

  start_event_->Signal();

  Run(message_loop_);

  {
    AutoLock lock(running_lock_);
    running_ = false;
  }

  // Let the thread do extra cleanup.
  CleanUp();

#if defined(OS_WIN)
  com_initializer.reset();
#endif

  // Assert that MessageLoop::Quit was called by ThreadQuitHelper.
  DCHECK(GetThreadWasQuitProperly());

  // We can't receive messages anymore.
  // (The message loop is destructed at the end of this block)
  message_loop_ = NULL;
}

}  // namespace base
