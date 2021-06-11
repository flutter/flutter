// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "thread.h"

#include <lib/async-loop/cpp/loop.h>
#include <unistd.h>

#include <algorithm>
#include <climits>

#include "flutter/fml/logging.h"
#include "loop.h"

namespace flutter_runner {

typedef void (*ThreadEntry)(Thread*);

namespace {

size_t NextPageSizeMultiple(size_t size) {
  const size_t page_size = sysconf(_SC_PAGE_SIZE);
  FML_CHECK(page_size != 0);

  size = std::max<size_t>(size, page_size);

  size_t rem = size % page_size;

  if (rem == 0) {
    return size;
  }

  return size + page_size - rem;
}

bool CreateThread(pthread_t* thread,
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

}  // anonymous namespace

Thread::Thread() {
  loop_.reset(MakeObservableLoop(false));
  valid_ = CreateThread(
      &thread_, [](Thread* thread) { thread->Main(); }, this, 1 << 20);
}

Thread::~Thread() {
  Join();
}

bool Thread::IsValid() const {
  return valid_;
}

async_dispatcher_t* Thread::dispatcher() const {
  return loop_->dispatcher();
}

void Thread::Main() {
  async_set_default_dispatcher(loop_->dispatcher());
  loop_->Run();
}

void Thread::Quit() {
  loop_->Quit();
}

bool Thread::Join() {
  if (!valid_) {
    return false;
  }

  bool result = pthread_join(thread_, nullptr) == 0;
  valid_ = false;
  return result;
}

}  // namespace flutter_runner
