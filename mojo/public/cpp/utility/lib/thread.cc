// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/cpp/utility/thread.h"

#include <assert.h>

namespace mojo {

Thread::Thread() : options_(), thread_(), started_(false), joined_(false) {
}

Thread::Thread(const Options& options)
    : options_(options), thread_(), started_(false), joined_(false) {
}

Thread::~Thread() {
  // If it was started, it must have been joined.
  assert(!started_ || joined_);
}

void Thread::Start() {
  assert(!started_);
  assert(!joined_);

  pthread_attr_t attr;
  int rv = pthread_attr_init(&attr);
  MOJO_ALLOW_UNUSED_LOCAL(rv);
  assert(rv == 0);

  // Non-default stack size?
  if (options_.stack_size() != 0) {
    rv = pthread_attr_setstacksize(&attr, options_.stack_size());
    assert(rv == 0);
  }

  started_ = true;
  rv = pthread_create(&thread_, &attr, &ThreadRunTrampoline, this);
  assert(rv == 0);

  rv = pthread_attr_destroy(&attr);
  assert(rv == 0);
}

void Thread::Join() {
  // Must have been started but not yet joined.
  assert(started_);
  assert(!joined_);

  joined_ = true;
  int rv = pthread_join(thread_, nullptr);
  MOJO_ALLOW_UNUSED_LOCAL(rv);
  assert(rv == 0);
}

// static
void* Thread::ThreadRunTrampoline(void* arg) {
  Thread* self = static_cast<Thread*>(arg);
  self->Run();
  return nullptr;
}

}  // namespace mojo
