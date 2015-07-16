// Copyright (c) 2010 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/threading/simple_thread.h"

#include "base/logging.h"
#include "base/strings/string_number_conversions.h"
#include "base/threading/platform_thread.h"
#include "base/threading/thread_restrictions.h"

namespace base {

SimpleThread::SimpleThread(const std::string& name_prefix)
    : name_prefix_(name_prefix), name_(name_prefix),
      thread_(), event_(true, false), tid_(0), joined_(false) {
}

SimpleThread::SimpleThread(const std::string& name_prefix,
                           const Options& options)
    : name_prefix_(name_prefix), name_(name_prefix), options_(options),
      thread_(), event_(true, false), tid_(0), joined_(false) {
}

SimpleThread::~SimpleThread() {
  DCHECK(HasBeenStarted()) << "SimpleThread was never started.";
  DCHECK(HasBeenJoined()) << "SimpleThread destroyed without being Join()ed.";
}

void SimpleThread::Start() {
  DCHECK(!HasBeenStarted()) << "Tried to Start a thread multiple times.";
  bool success;
  if (options_.priority() == ThreadPriority::NORMAL) {
    success = PlatformThread::Create(options_.stack_size(), this, &thread_);
  } else {
    success = PlatformThread::CreateWithPriority(options_.stack_size(), this,
                                                 &thread_, options_.priority());
  }
  DCHECK(success);
  base::ThreadRestrictions::ScopedAllowWait allow_wait;
  event_.Wait();  // Wait for the thread to complete initialization.
}

void SimpleThread::Join() {
  DCHECK(HasBeenStarted()) << "Tried to Join a never-started thread.";
  DCHECK(!HasBeenJoined()) << "Tried to Join a thread multiple times.";
  PlatformThread::Join(thread_);
  joined_ = true;
}

bool SimpleThread::HasBeenStarted() {
  base::ThreadRestrictions::ScopedAllowWait allow_wait;
  return event_.IsSignaled();
}

void SimpleThread::ThreadMain() {
  tid_ = PlatformThread::CurrentId();
  // Construct our full name of the form "name_prefix_/TID".
  name_.push_back('/');
  name_.append(IntToString(tid_));
  PlatformThread::SetName(name_);

  // We've initialized our new thread, signal that we're done to Start().
  event_.Signal();

  Run();
}

DelegateSimpleThread::DelegateSimpleThread(Delegate* delegate,
                                           const std::string& name_prefix)
    : SimpleThread(name_prefix),
      delegate_(delegate) {
}

DelegateSimpleThread::DelegateSimpleThread(Delegate* delegate,
                                           const std::string& name_prefix,
                                           const Options& options)
    : SimpleThread(name_prefix, options),
      delegate_(delegate) {
}

DelegateSimpleThread::~DelegateSimpleThread() {
}

void DelegateSimpleThread::Run() {
  DCHECK(delegate_) << "Tried to call Run without a delegate (called twice?)";
  delegate_->Run();
  delegate_ = NULL;
}

DelegateSimpleThreadPool::DelegateSimpleThreadPool(
    const std::string& name_prefix,
    int num_threads)
    : name_prefix_(name_prefix),
      num_threads_(num_threads),
      dry_(true, false) {
}

DelegateSimpleThreadPool::~DelegateSimpleThreadPool() {
  DCHECK(threads_.empty());
  DCHECK(delegates_.empty());
  DCHECK(!dry_.IsSignaled());
}

void DelegateSimpleThreadPool::Start() {
  DCHECK(threads_.empty()) << "Start() called with outstanding threads.";
  for (int i = 0; i < num_threads_; ++i) {
    DelegateSimpleThread* thread = new DelegateSimpleThread(this, name_prefix_);
    thread->Start();
    threads_.push_back(thread);
  }
}

void DelegateSimpleThreadPool::JoinAll() {
  DCHECK(!threads_.empty()) << "JoinAll() called with no outstanding threads.";

  // Tell all our threads to quit their worker loop.
  AddWork(NULL, num_threads_);

  // Join and destroy all the worker threads.
  for (int i = 0; i < num_threads_; ++i) {
    threads_[i]->Join();
    delete threads_[i];
  }
  threads_.clear();
  DCHECK(delegates_.empty());
}

void DelegateSimpleThreadPool::AddWork(Delegate* delegate, int repeat_count) {
  AutoLock locked(lock_);
  for (int i = 0; i < repeat_count; ++i)
    delegates_.push(delegate);
  // If we were empty, signal that we have work now.
  if (!dry_.IsSignaled())
    dry_.Signal();
}

void DelegateSimpleThreadPool::Run() {
  Delegate* work = NULL;

  while (true) {
    dry_.Wait();
    {
      AutoLock locked(lock_);
      if (!dry_.IsSignaled())
        continue;

      DCHECK(!delegates_.empty());
      work = delegates_.front();
      delegates_.pop();

      // Signal to any other threads that we're currently out of work.
      if (delegates_.empty())
        dry_.Reset();
    }

    // A NULL delegate pointer signals us to quit.
    if (!work)
      break;

    work->Run();
  }
}

}  // namespace base
