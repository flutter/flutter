// Copyright 2009 The RE2 Authors.  All Rights Reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

#include <pthread.h>

#include "util/util.h"
#include "util/thread.h"

Thread::Thread() {
  pid_ = 0;
  running_ = 0;
  joinable_ = 0;
}

Thread::~Thread() {
}

void *startThread(void *v) {
  Thread* t = (Thread*)v;
  t->Run();
  return 0;
}

void Thread::Start() {
  CHECK(!running_);
  pthread_create(&pid_, 0, startThread, this);
  running_ = true;
  if (!joinable_)
    pthread_detach(pid_);
}

void Thread::Join() {
  CHECK(running_);
  CHECK(joinable_);
  void *val;
  pthread_join(pid_, &val);
  running_ = 0;
}

void Thread::SetJoinable(bool j) {
  CHECK(!running_);
  joinable_ = j;
}
