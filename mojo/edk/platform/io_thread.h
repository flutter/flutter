// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This file declares a factory function (which must be implemented by the
// embedder) for "I/O threads" -- threads with a message loop that are also
// capable of watching platform handles.

#ifndef MOJO_EDK_PLATFORM_IO_THREAD_H_
#define MOJO_EDK_PLATFORM_IO_THREAD_H_

#include <memory>

#include "mojo/edk/util/ref_ptr.h"

namespace mojo {
namespace platform {

class PlatformHandleWatcher;
class TaskRunner;
class Thread;

// Creates and starts an "I/O thread", which runs a message loop and can watch
// platform handles. The "out" |TaskRunner| is usable immediately upon return;
// the "out" |PlatformHandleWatcher| should only be used on the created thread.
// After the returned |Thread|'s |Stop()| is called, the |TaskRunner| should no
// longer be used.
std::unique_ptr<Thread> CreateAndStartIOThread(
    util::RefPtr<TaskRunner>* task_runner,
    PlatformHandleWatcher** platform_handle_watcher);

}  // namespace platform
}  // namespace mojo

#endif  // MOJO_EDK_PLATFORM_IO_THREAD_H_
