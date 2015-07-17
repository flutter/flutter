// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// WARNING: You should probably be using Thread (thread.h) instead.  Thread is
//          Chrome's message-loop based Thread abstraction, and if you are a
//          thread running in the browser, there will likely be assumptions
//          that your thread will have an associated message loop.
//
// This is a simple thread interface that backs to a native operating system
// thread.  You should use this only when you want a thread that does not have
// an associated MessageLoop.  Unittesting is the best example of this.
//
// The simplest interface to use is DelegateSimpleThread, which will create
// a new thread, and execute the Delegate's virtual Run() in this new thread
// until it has completed, exiting the thread.
//
// NOTE: You *MUST* call Join on the thread to clean up the underlying thread
// resources.  You are also responsible for destructing the SimpleThread object.
// It is invalid to destroy a SimpleThread while it is running, or without
// Start() having been called (and a thread never created).  The Delegate
// object should live as long as a DelegateSimpleThread.
//
// Thread Safety: A SimpleThread is not completely thread safe.  It is safe to
// access it from the creating thread or from the newly created thread.  This
// implies that the creator thread should be the thread that calls Join.
//
// Example:
//   class MyThreadRunner : public DelegateSimpleThread::Delegate { ... };
//   MyThreadRunner runner;
//   DelegateSimpleThread thread(&runner, "good_name_here");
//   thread.Start();
//   // Start will return after the Thread has been successfully started and
//   // initialized.  The newly created thread will invoke runner->Run(), and
//   // run until it returns.
//   thread.Join();  // Wait until the thread has exited.  You *MUST* Join!
//   // The SimpleThread object is still valid, however you may not call Join
//   // or Start again.

#ifndef BASE_THREADING_SIMPLE_THREAD_H_
#define BASE_THREADING_SIMPLE_THREAD_H_

#include <string>
#include <queue>
#include <vector>

#include "base/base_export.h"
#include "base/basictypes.h"
#include "base/compiler_specific.h"
#include "base/threading/platform_thread.h"
#include "base/synchronization/lock.h"
#include "base/synchronization/waitable_event.h"

namespace base {

// This is the base SimpleThread.  You can derive from it and implement the
// virtual Run method, or you can use the DelegateSimpleThread interface.
class BASE_EXPORT SimpleThread : public PlatformThread::Delegate {
 public:
  class BASE_EXPORT Options {
   public:
    Options() : stack_size_(0), priority_(ThreadPriority::NORMAL) {}
    explicit Options(ThreadPriority priority)
        : stack_size_(0), priority_(priority) {}
    ~Options() {}

    // We use the standard compiler-supplied copy constructor.

    // A custom stack size, or 0 for the system default.
    void set_stack_size(size_t size) { stack_size_ = size; }
    size_t stack_size() const { return stack_size_; }

    // A custom thread priority.
    void set_priority(ThreadPriority priority) { priority_ = priority; }
    ThreadPriority priority() const { return priority_; }
   private:
    size_t stack_size_;
    ThreadPriority priority_;
  };

  // Create a SimpleThread.  |options| should be used to manage any specific
  // configuration involving the thread creation and management.
  // Every thread has a name, in the form of |name_prefix|/TID, for example
  // "my_thread/321".  The thread will not be created until Start() is called.
  explicit SimpleThread(const std::string& name_prefix);
  SimpleThread(const std::string& name_prefix, const Options& options);

  ~SimpleThread() override;

  virtual void Start();
  virtual void Join();

  // Subclasses should override the Run method.
  virtual void Run() = 0;

  // Return the thread name prefix, or "unnamed" if none was supplied.
  std::string name_prefix() { return name_prefix_; }

  // Return the completed name including TID, only valid after Start().
  std::string name() { return name_; }

  // Return the thread id, only valid after Start().
  PlatformThreadId tid() { return tid_; }

  // Return True if Start() has ever been called.
  bool HasBeenStarted();

  // Return True if Join() has evern been called.
  bool HasBeenJoined() { return joined_; }

  // Overridden from PlatformThread::Delegate:
  void ThreadMain() override;

 private:
  const std::string name_prefix_;
  std::string name_;
  const Options options_;
  PlatformThreadHandle thread_;  // PlatformThread handle, invalid after Join!
  WaitableEvent event_;          // Signaled if Start() was ever called.
  PlatformThreadId tid_;         // The backing thread's id.
  bool joined_;                  // True if Join has been called.
};

class BASE_EXPORT DelegateSimpleThread : public SimpleThread {
 public:
  class BASE_EXPORT Delegate {
   public:
    Delegate() { }
    virtual ~Delegate() { }
    virtual void Run() = 0;
  };

  DelegateSimpleThread(Delegate* delegate,
                       const std::string& name_prefix);
  DelegateSimpleThread(Delegate* delegate,
                       const std::string& name_prefix,
                       const Options& options);

  ~DelegateSimpleThread() override;
  void Run() override;

 private:
  Delegate* delegate_;
};

// DelegateSimpleThreadPool allows you to start up a fixed number of threads,
// and then add jobs which will be dispatched to the threads.  This is
// convenient when you have a lot of small work that you want done
// multi-threaded, but don't want to spawn a thread for each small bit of work.
//
// You just call AddWork() to add a delegate to the list of work to be done.
// JoinAll() will make sure that all outstanding work is processed, and wait
// for everything to finish.  You can reuse a pool, so you can call Start()
// again after you've called JoinAll().
class BASE_EXPORT DelegateSimpleThreadPool
    : public DelegateSimpleThread::Delegate {
 public:
  typedef DelegateSimpleThread::Delegate Delegate;

  DelegateSimpleThreadPool(const std::string& name_prefix, int num_threads);
  ~DelegateSimpleThreadPool() override;

  // Start up all of the underlying threads, and start processing work if we
  // have any.
  void Start();

  // Make sure all outstanding work is finished, and wait for and destroy all
  // of the underlying threads in the pool.
  void JoinAll();

  // It is safe to AddWork() any time, before or after Start().
  // Delegate* should always be a valid pointer, NULL is reserved internally.
  void AddWork(Delegate* work, int repeat_count);
  void AddWork(Delegate* work) {
    AddWork(work, 1);
  }

  // We implement the Delegate interface, for running our internal threads.
  void Run() override;

 private:
  const std::string name_prefix_;
  int num_threads_;
  std::vector<DelegateSimpleThread*> threads_;
  std::queue<Delegate*> delegates_;
  base::Lock lock_;            // Locks delegates_
  WaitableEvent dry_;    // Not signaled when there is no work to do.
};

}  // namespace base

#endif  // BASE_THREADING_SIMPLE_THREAD_H_
