// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/util/weak_ptr_internal.h"

#include <assert.h>

namespace mojo {
namespace util {
namespace internal {

WeakPtrFlag::WeakPtrFlag() : is_valid_(true) {}

WeakPtrFlag::~WeakPtrFlag() {
  // Should be invalidated before destruction.
  assert(!is_valid_);
}

void WeakPtrFlag::Invalidate() {
  // Invalidation should happen exactly once.
  assert(is_valid_);
  is_valid_ = false;
}

}  // namespace internal
}  // namespace util
}  // namespace mojo
