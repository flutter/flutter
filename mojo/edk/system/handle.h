// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_H_
#define MOJO_EDK_SYSTEM_HANDLE_H_

#include "mojo/edk/util/ref_ptr.h"
#include "mojo/public/c/system/handle.h"

namespace mojo {
namespace system {

class Dispatcher;

// Struct that represents what a handle *value* refers to (via the handle
// table) -- a dispatcher and a (bit)set of rights.
struct Handle {
  // Note: We want to allow copy/move construction/assignment, but since the
  // Chromium style checker made us declare a destructor, we have to declare the
  // move versions ourselves. We also do so for the copy versions so we can
  // out-of-line them.
  Handle();
  Handle(const Handle&);
  Handle(Handle&&);
  Handle(util::RefPtr<Dispatcher>&& dispatcher, MojoHandleRights rights);

  ~Handle();

  Handle& operator=(const Handle&);
  Handle& operator=(Handle&&);

  // A |Handle| tests as true if it actually has a dispatcher.
  explicit operator bool() const { return !!dispatcher; }

  // Note: |dispatcher| is guaranteed to be null if default-constructed or
  // moved-from, but we make no guarantees about the value of |rights| in either
  // case.
  util::RefPtr<Dispatcher> dispatcher;
  MojoHandleRights rights;
};

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_H_
