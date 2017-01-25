// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/content_handler/content_handler_thread.h"

#include <unistd.h>

#include "lib/ftl/logging.h"
#include "lib/mtl/tasks/incoming_task_queue.h"
#include "lib/mtl/tasks/message_loop.h"

namespace flutter_runner {

typedef void (*ThreadEntry)(Thread*);

static size_t NextPageSizeMultiple(size_t size) {
  const size_t page_size = sysconf(_SC_PAGE_SIZE);
  FTL_CHECK(page_size != 0);

  size = std::max<size_t>(size, page_size);

  size_t rem = size % page_size;

  if (rem == 0) {
    return size;
  }

  return size + page_size - rem;
}

static bool CreateThread(pthread_t* thread,
                         ThreadEntry main,
                         Thread* argument,
                         size_t stack_size) {
  pthread_attr_t thread_attributes;

  if (pthread_attr_init(&thread_attributes) != 0) {
    return false;
  }

  stack_size = std::max<size_t>(NextPageSizeMultiple(PTHREAD_STACK_MIN),
                                NextPageSizeMultiple(stack_size));

  if (pthread_attr_setstacksize(&thread_attributes, stack_size) != 0) {
    return false;
  }

  auto result =
      pthread_create(thread, &thread_attributes,
                     reinterpret_cast<void* (*)(void*)>(main), argument);

  pthread_attr_destroy(&thread_attributes);

  return result == 0;
}

Thread::Thread()
    : task_runner_(ftl::MakeRefCounted<mtl::internal::IncomingTaskQueue>()) {
  valid_ = CreateThread(&thread_, [](Thread* thread) { thread->Main(); }, this,
                        1 << 20);
}

Thread::~Thread() {
  Join();
}

bool Thread::IsValid() const {
  return valid_;
}

ftl::RefPtr<ftl::TaskRunner> Thread::TaskRunner() const {
  return task_runner_;
}

void Thread::Main() {
  mtl::MessageLoop message_loop(task_runner_);
  message_loop.Run();
}

bool Thread::Join() {
  if (!valid_) {
    return false;
  }

  return pthread_join(thread_, nullptr) == 0;
}

}  // namespace flutter_runner
