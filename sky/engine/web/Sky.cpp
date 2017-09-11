/*
 * Copyright (C) 2009 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#include "flutter/sky/engine/public/web/Sky.h"

#include "flutter/glue/trace_event.h"
#include "flutter/sky/engine/core/Init.h"
#include "flutter/sky/engine/public/platform/Platform.h"
#include "flutter/sky/engine/wtf/Assertions.h"
#include "flutter/sky/engine/wtf/MainThread.h"
#include "flutter/sky/engine/wtf/WTF.h"
#include "flutter/sky/engine/wtf/text/AtomicString.h"
#include "flutter/sky/engine/wtf/text/TextEncoding.h"
#include "lib/fxl/build_config.h"
#include "lib/tonic/dart_microtask_queue.h"

#if defined(OS_FUCHSIA)

#include "lib/mtl/tasks/message_loop.h"  // nogncheck

#else  // defined(OS_FUCHSIA)

#include "flutter/fml/message_loop.h"  // nogncheck

#endif  // defined(OS_FUCHSIA)

namespace blink {

namespace {

void didProcessTask() {
  tonic::DartMicrotaskQueue::GetForCurrentThread()->RunMicrotasks();
  // FIXME: Report memory usage to dart?
}

#if defined(OS_FUCHSIA)

void addMessageLoopObservers() {
  mtl::MessageLoop::GetCurrent()->SetAfterTaskCallback(didProcessTask);
}

void removeMessageLoopObservers() {
  mtl::MessageLoop::GetCurrent()->ClearAfterTaskCallback();
}

#else  // defined(OS_FUCHSIA)

class RunMicrotasksTaskObserver : public fml::TaskObserver {
 public:
  RunMicrotasksTaskObserver() = default;

  ~RunMicrotasksTaskObserver() override = default;

  void DidProcessTask() override { didProcessTask(); }
};

// FIXME(chinmaygarde): The awkward use of the global here is be cause we cannot
// introduce the fml::TaskObserver subclass in common code because Fuchsia does
// not support the same. Unify the API and remove hack.
static RunMicrotasksTaskObserver* g_run_microtasks_task_observer = nullptr;

void addMessageLoopObservers() {
  g_run_microtasks_task_observer = new RunMicrotasksTaskObserver();
  fml::MessageLoop::GetCurrent().AddTaskObserver(
      g_run_microtasks_task_observer);
}

void removeMessageLoopObservers() {
  fml::MessageLoop::GetCurrent().RemoveTaskObserver(
      g_run_microtasks_task_observer);
  delete g_run_microtasks_task_observer;
  g_run_microtasks_task_observer = nullptr;
}

#endif  // defined(OS_FUCHSIA)

}  // namespace

// Make sure we are not re-initialized in the same address space.
// Doing so may cause hard to reproduce crashes.
static bool s_webKitInitialized = false;

void InitEngine(Platform* platform) {
  TRACE_EVENT0("flutter", "InitEngine");

  ASSERT(!s_webKitInitialized);
  s_webKitInitialized = true;

  ASSERT(platform);
  Platform::initialize(platform);

  WTF::initialize();
  WTF::initializeMainThread();

  DEFINE_STATIC_LOCAL(CoreInitializer, initializer, ());
  initializer.init();

  // There are some code paths (for example, running WebKit in the browser
  // process and calling into LocalStorage before anything else) where the
  // UTF8 string encoding tables are used on a background thread before
  // they're set up.  This is a problem because their set up routines assert
  // they're running on the main WebKitThread.  It might be possible to make
  // the initialization thread-safe, but given that so many code paths use
  // this, initializing this lazily probably doesn't buy us much.
  WTF::UTF8Encoding();

  tonic::DartMicrotaskQueue::StartForCurrentThread();
  addMessageLoopObservers();
}

void ShutdownEngine() {
  removeMessageLoopObservers();
  tonic::DartMicrotaskQueue::GetForCurrentThread()->Destroy();

  // FIXME: Shutdown dart?

  CoreInitializer::shutdown();
  WTF::shutdown();
  Platform::shutdown();
}

}  // namespace blink
