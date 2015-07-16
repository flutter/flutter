// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_ENVIRONMENT_ENVIRONMENT_H_
#define MOJO_PUBLIC_CPP_ENVIRONMENT_ENVIRONMENT_H_

#include "mojo/public/cpp/system/macros.h"

struct MojoAsyncWaiter;
struct MojoLogger;

namespace mojo {

struct TaskTracker;

// Other parts of the Mojo C++ APIs use the *static* methods of this class.
//
// The "standalone" implementation of this class requires that this class (in
// the lib/ subdirectory) be instantiated (and remain so) while using the Mojo
// C++ APIs. I.e., the static methods depend on things set up by the constructor
// and torn down by the destructor.
//
// Other implementations may not have this requirement.
class Environment {
 public:
  Environment();
  // This constructor allows the standard implementations to be overridden (set
  // a parameter to null to get the standard implementation).
  Environment(const MojoAsyncWaiter* default_async_waiter,
              const MojoLogger* default_logger,
              const TaskTracker* default_task_tracker);
  ~Environment();

  static const MojoAsyncWaiter* GetDefaultAsyncWaiter();
  static const MojoLogger* GetDefaultLogger();
  static const TaskTracker* GetDefaultTaskTracker();

  // These instantiate and destroy an environment-specific run loop for the
  // current thread, allowing |GetDefaultAsyncWaiter()| to be used. (The run
  // loop itself should be accessible via thread-local storage, using methods
  // specific to the run loop implementation.) Creating and destroying nested
  // run loops is not supported.
  static void InstantiateDefaultRunLoop();
  static void DestroyDefaultRunLoop();

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(Environment);
};

}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_ENVIRONMENT_ENVIRONMENT_H_
