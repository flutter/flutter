// Copyright (c) 2012 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This defines helpful methods for dealing with Callbacks.  Because Callbacks
// are implemented using templates, with a class per callback signature, adding
// methods to Callback<> itself is unattractive (lots of extra code gets
// generated).  Instead, consider adding methods here.
//
// ResetAndReturn(&cb) is like cb.Reset() but allows executing a callback (via a
// copy) after the original callback is Reset().  This can be handy if Run()
// reads/writes the variable holding the Callback.

#ifndef BASE_CALLBACK_HELPERS_H_
#define BASE_CALLBACK_HELPERS_H_

#include "base/basictypes.h"
#include "base/callback.h"
#include "base/compiler_specific.h"

namespace base {

template <typename Sig>
base::Callback<Sig> ResetAndReturn(base::Callback<Sig>* cb) {
  base::Callback<Sig> ret(*cb);
  cb->Reset();
  return ret;
}

// ScopedClosureRunner is akin to scoped_ptr for Closures. It ensures that the
// Closure is executed and deleted no matter how the current scope exits.
class BASE_EXPORT ScopedClosureRunner {
 public:
  ScopedClosureRunner();
  explicit ScopedClosureRunner(const Closure& closure);
  ~ScopedClosureRunner();

  void Reset();
  void Reset(const Closure& closure);
  Closure Release() WARN_UNUSED_RESULT;

 private:
  Closure closure_;

  DISALLOW_COPY_AND_ASSIGN(ScopedClosureRunner);
};

}  // namespace base

#endif  // BASE_CALLBACK_HELPERS_H_
