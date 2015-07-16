// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/callback_internal.h"

#include "base/logging.h"

namespace base {
namespace internal {

void BindStateBase::AddRef() {
  AtomicRefCountInc(&ref_count_);
}

void BindStateBase::Release() {
  if (!AtomicRefCountDec(&ref_count_))
    destructor_(this);
}

CallbackBase::CallbackBase(const CallbackBase& c) = default;
CallbackBase& CallbackBase::operator=(const CallbackBase& c) = default;

void CallbackBase::Reset() {
  polymorphic_invoke_ = NULL;
  // NULL the bind_state_ last, since it may be holding the last ref to whatever
  // object owns us, and we may be deleted after that.
  bind_state_ = NULL;
}

bool CallbackBase::Equals(const CallbackBase& other) const {
  return bind_state_.get() == other.bind_state_.get() &&
         polymorphic_invoke_ == other.polymorphic_invoke_;
}

CallbackBase::CallbackBase(BindStateBase* bind_state)
    : bind_state_(bind_state),
      polymorphic_invoke_(NULL) {
  DCHECK(!bind_state_.get() || bind_state_->ref_count_ == 1);
}

CallbackBase::~CallbackBase() {
}

}  // namespace internal
}  // namespace base
