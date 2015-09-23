// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_AWAKABLE_H_
#define MOJO_EDK_SYSTEM_AWAKABLE_H_

#include <stdint.h>

#include "mojo/public/c/system/types.h"

namespace mojo {
namespace system {

// An interface for things that may be awoken. E.g., |Waiter| is an
// implementation that blocks while waiting to be awoken.
class Awakable {
 public:
  // |Awake()| must satisfy the following contract:
  //   - It must be thread-safe.
  //   - Since it is called with a mutex held, it must not call anything that
  //     takes "non-terminal" locks, i.e., those which are always safe to take.
  //   - It should return false if it must not be called again for the same
  //     reason (e.g., for the same call to |AwakableList::Add()|).
  virtual bool Awake(MojoResult result, uintptr_t context) = 0;

 protected:
  Awakable() {}
  virtual ~Awakable() {}
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_AWAKABLE_H_
