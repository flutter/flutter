// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_HANDLE_H_
#define MOJO_EDK_SYSTEM_HANDLE_H_

#include <vector>

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

  // Returns a new |Handle| with the same contents as this object. Useful when a
  // function takes a |Handle&&| argument and the caller wants to retain its
  // copy (rather than moving it).
  Handle Clone() const { return *this; }

  // A |Handle| tests as true if it actually has a dispatcher.
  explicit operator bool() const { return !!dispatcher; }

  bool operator==(const Handle& rhs) const {
    return dispatcher == rhs.dispatcher && rights == rhs.rights;
  }

  bool operator!=(const Handle& rhs) const { return !operator==(rhs); }

  void reset() { *this = Handle(); }

  bool has_all_rights(MojoHandleRights required_rights) const {
    return (rights & required_rights) == required_rights;
  }

  // Note: |dispatcher| is guaranteed to be null if default-constructed or
  // moved-from, but we make no guarantees about the value of |rights| in either
  // case.
  util::RefPtr<Dispatcher> dispatcher;
  MojoHandleRights rights;
};

using HandleVector = std::vector<Handle>;

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_HANDLE_H_
