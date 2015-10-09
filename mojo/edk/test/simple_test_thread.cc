// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/test/simple_test_thread.h"

#include "base/logging.h"

namespace mojo {
namespace test {

SimpleTestThread::SimpleTestThread() : thread_(this, "SimpleTestThread") {}

SimpleTestThread::~SimpleTestThread() {}

void SimpleTestThread::Start() {
  thread_.Start();
}

void SimpleTestThread::Join() {
  thread_.Join();
}

}  // namespace test
}  // namespace mojo
