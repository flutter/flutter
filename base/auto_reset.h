// Copyright (c) 2011 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef BASE_AUTO_RESET_H_
#define BASE_AUTO_RESET_H_

#include "base/basictypes.h"

// base::AutoReset<> is useful for setting a variable to a new value only within
// a particular scope. An base::AutoReset<> object resets a variable to its
// original value upon destruction, making it an alternative to writing
// "var = false;" or "var = old_val;" at all of a block's exit points.
//
// This should be obvious, but note that an base::AutoReset<> instance should
// have a shorter lifetime than its scoped_variable, to prevent invalid memory
// writes when the base::AutoReset<> object is destroyed.

namespace base {

template<typename T>
class AutoReset {
 public:
  AutoReset(T* scoped_variable, T new_value)
      : scoped_variable_(scoped_variable),
        original_value_(*scoped_variable) {
    *scoped_variable_ = new_value;
  }

  ~AutoReset() { *scoped_variable_ = original_value_; }

 private:
  T* scoped_variable_;
  T original_value_;

  DISALLOW_COPY_AND_ASSIGN(AutoReset);
};

}  // namespace base

#endif  // BASE_AUTO_RESET_H_
