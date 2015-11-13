// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file "provides" abstractions for "task runners" and posting tasks to
// them. The embedder is required to actually declare/define them in
// platform_task_runner_impl.h. See below for details.

#ifndef MOJO_EDK_EMBEDDER_PLATFORM_TASK_RUNNER_H_
#define MOJO_EDK_EMBEDDER_PLATFORM_TASK_RUNNER_H_

// The embedder is required to provide the following:
//
// |mojo::embedder::PlatformTaskRunner|: An opaque class or type in the
// |mojo::embedder| namespace to a "reference counted" object (see below).
//
// |mojo::embedder::PlatformTaskRunnerRefPtr|: A class or type alias in the
// |mojo::embedder| namespace that is:
//   * default constructible;
//   * copy and move constructible and assignable;
//   * implicitly constructible and assignable from |nullptr|;
//   * explicitly (possibly implicitly) constructible from a
//     |PlatformTaskRunner*|;
//   * testable (with the obvious semantics; testing must also be |const| and
//     thread-safe); and
//   * comparable with suitable |operator==|, |operator!=| and |operator<|
//     (satisifying obvious properties).
// It must also have a const |get()| method that returns a
// |PlatformTaskRunner*|. (The various operations must coincide with the
// corresponding operations on pointers returned by |get()|.)
//
// A |PlatformTaskRunnerRefPtr| refers ("points") to something that can
// (sequentially) execute tasks on a single-thread (so it's really more like a
// pointer to Chromium's |base::SingleThreadTaskRunner| than to a
// |base::TaskRunner|).
//
// |mojo::embedder::PlatformPostTask()|: A function in the |mojo::embedder|
// namespace with the signature:
//   void PlatformPostTask(PlatformTaskRunner* task_runner,
//                         const base::Closure& closure);
// where |task_runner| must be non-null. This function has the following
// requirements:
//   * It must be thread-safe.
//   * It will execute |closure| exactly once, on the thread referred to by the
//     task runner.
//   * Given two calls |PlatformPostTask(task_runner1, closure1)| and
//     |PlatformPostTask(task_runner2, closure2)| with |task_runner1 ==
//     task_runner2|, and the first call occurring before the second call in
//     some well-defined way (e.g., they occur on the same thread, or on
//     different threads with synchronization to ensure ordering), then
//     |closure1| will be executed before |closure2|.
//
// TODO(vtl): Remove the |base::Closure| dependency.

// The embedder should define the above in the following file.
#include "mojo/edk/embedder/platform_task_runner_impl.h"

#endif  // MOJO_EDK_EMBEDDER_PLATFORM_TASK_RUNNER_H_
