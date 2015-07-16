// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_AWAKABLE_H_
#define MOJO_EDK_SYSTEM_AWAKABLE_H_

#include <stdint.h>

#include "mojo/edk/system/system_impl_export.h"
#include "mojo/public/c/system/types.h"

namespace mojo {
namespace system {

// An interface that may be waited on |AwakableList|.
class MOJO_SYSTEM_IMPL_EXPORT Awakable {
 public:
  // |Awake()| must satisfy the following contract:
  // * As this is called from any thread, this must be thread-safe.
  // * As this is called inside a lock, this must not call anything that takes
  //   "non-terminal" locks, i.e., those which are always safe to take.
  // This should return false if this must not be called again for the same
  // reason (e.g., for the same call to |AwakableList::Add()|).
  virtual bool Awake(MojoResult result, uintptr_t context) = 0;

 protected:
  Awakable() {}
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_AWAKABLE_H_
