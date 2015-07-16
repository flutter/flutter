// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_UNION_ACCESSOR_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_UNION_ACCESSOR_H_

namespace mojo {
namespace internal {

// When serializing and deserializing Unions, it is necessary to access
// the private fields and methods of the Union. This allows us to do that
// without leaking those same fields and methods in the Union interface.
// All Union wrappers are friends of this class allowing such access.
template <typename U>
class UnionAccessor {
 public:
  explicit UnionAccessor(U* u) : u_(u) {}

  typename U::Union_* data() { return &(u_->data_); }

  typename U::Tag* tag() { return &(u_->tag_); }

  void SwitchActive(typename U::Tag new_tag) { u_->SwitchActive(new_tag); }

 private:
  U* u_;
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_UNION_ACCESSOR_H_
