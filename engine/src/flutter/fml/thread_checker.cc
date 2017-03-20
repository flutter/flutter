// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/fml/thread_checker.h"

namespace fml {

ThreadChecker::ThreadChecker() : handle_(std::this_thread::get_id()) {}

ThreadChecker::~ThreadChecker() = default;

bool ThreadChecker::IsCalledOnValidThread() const {
  return handle_ == std::this_thread::get_id();
}

}  // namespace fml
