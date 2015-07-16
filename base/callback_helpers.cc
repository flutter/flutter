// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/callback_helpers.h"

#include "base/callback.h"

namespace base {

ScopedClosureRunner::ScopedClosureRunner() {
}

ScopedClosureRunner::ScopedClosureRunner(const Closure& closure)
    : closure_(closure) {
}

ScopedClosureRunner::~ScopedClosureRunner() {
  if (!closure_.is_null())
    closure_.Run();
}

void ScopedClosureRunner::Reset() {
  Closure old_closure = Release();
  if (!old_closure.is_null())
    old_closure.Run();
}

void ScopedClosureRunner::Reset(const Closure& closure) {
  Closure old_closure = Release();
  closure_ = closure;
  if (!old_closure.is_null())
    old_closure.Run();
}

Closure ScopedClosureRunner::Release() {
  Closure result = closure_;
  closure_.Reset();
  return result;
}

}  // namespace base
