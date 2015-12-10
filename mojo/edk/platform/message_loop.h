// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file provides an interface for "message loops", which are used within
// the EDK itself.

#ifndef MOJO_EDK_PLATFORM_MESSAGE_LOOP_H_
#define MOJO_EDK_PLATFORM_MESSAGE_LOOP_H_

#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace platform {

class TaskRunner;

// Interface for "message loops", which receives and executes tasks. In general,
// a |MessageLoop| need not be thread-safe: except as otherwise noted, its
// methods may only be called on a designated thread, typically the one is was
// created on ((the |MessageLoop| is said to "belong to" that thread).
//
// In general, the result of running a |MessageLoop| "inside" a |MessageLoop|
// (whether the same one -- the classic "nested message loop" case -- or a
// different one) is implementation-defined.
class MessageLoop {
 public:
  virtual ~MessageLoop() {}

  // Runs the message loop until it is told to quit (via |QuitNow() or
  // |QuitWhenIdle()|).
  virtual void Run() = 0;

  // Runs the message loop until there are no more tasks available to execute
  // immediately (i.e., not including delayed tasks).
  virtual void RunUntilIdle() = 0;

  // If running, quits the message loop when there are no more tasks available
  // to execute immediately. (Note that this includes "future" tasks, i.e.,
  // those that are posted as a result of executing other tasks, so this may
  // never quit. However, it does not include delayed tasks.)
  virtual void QuitWhenIdle() = 0;

  // If running, quits the message loop now (i.e., do not process any further
  // tasks until |Run()| or |RunUntilIdle()|) is called again.
  virtual void QuitNow() = 0;

  // Gets the |TaskRunner| for this message loop, which can be used to post
  // tasks to it. For a given |MessageLoop| instance, this will always return a
  // reference to the same |TaskRunner| (and different |MessageLoop| instances
  // have different |TaskRunner|s). This may be called from any thread (and
  // returned |TaskRunner| is also thread-safe).
  //
  // Note: The returned |TaskRunner| should only claim to run tasks on the
  // thread which this message loop belongs to.
  virtual const mojo::util::RefPtr<TaskRunner>& GetTaskRunner() const = 0;

  // Returns true if this message loop belongs to the current thread (i.e., was
  // created on and executes tasks on this thread) *and* if it is currently
  // running (i.e., is called from within a task executed "under" |Run()| or
  // |RunUntilIdle()|). This may be called from any thread.
  //
  // If message loops are nested on the current thread, this must return true
  // for the "innermost" message loop. The result for "outer" message loops is
  // implementation-defined.
  virtual bool IsRunningOnCurrentThread() const = 0;

 protected:
  MessageLoop() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(MessageLoop);
};

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_MESSAGE_LOOP_H_
