// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_WEAK_INTERFACE_PTR_SET_H_
#define MOJO_COMMON_WEAK_INTERFACE_PTR_SET_H_

#include <vector>

#include "base/logging.h"
#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/interface_ptr.h"

namespace mojo {

namespace internal {

// TODO(vtl): This name of this class is a little odd -- it's not a "weak
// pointer", but a wrapper around InterfacePtr that owns itself and can vend
// weak pointers to itself. Probably, with connection error callbacks instead of
// ErrorHandlers, this class is unneeded, and WeakInterfacePtrSet can simply
// own/remove interface pointers as connection errors occur.
// https://github.com/domokit/mojo/issues/311
template <typename Interface>
class WeakInterfacePtr {
 public:
  explicit WeakInterfacePtr(InterfacePtr<Interface> ptr)
      : ptr_(ptr.Pass()), weak_ptr_factory_(this) {
    ptr_.set_connection_error_handler([this]() { delete this; });
  }
  ~WeakInterfacePtr() {}

  void Close() { ptr_.reset(); }

  Interface* get() { return ptr_.get(); }

  base::WeakPtr<WeakInterfacePtr> GetWeakPtr() {
    return weak_ptr_factory_.GetWeakPtr();
  }

 private:
  InterfacePtr<Interface> ptr_;
  base::WeakPtrFactory<WeakInterfacePtr> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(WeakInterfacePtr);
};

}  // namespace internal

// A WeakInterfacePtrSet contains a collection of InterfacePtrs
// that are automatically removed from the collection and destroyed
// when their associated MessagePipe experiences a connection error.
// When the set is destroyed all of the MessagePipes will be closed.
// TODO(rudominer) Rename this class since the ownership of the elements
// is not "weak" from the point of view of the client.
template <typename Interface>
class WeakInterfacePtrSet {
 public:
  WeakInterfacePtrSet() {}
  ~WeakInterfacePtrSet() { CloseAll(); }

  // |ptr| must be bound to a message pipe.
  void AddInterfacePtr(InterfacePtr<Interface> ptr) {
    DCHECK(ptr.is_bound());
    auto weak_interface_ptr =
        new internal::WeakInterfacePtr<Interface>(ptr.Pass());
    ptrs_.push_back(weak_interface_ptr->GetWeakPtr());
    ClearNullInterfacePtrs();
  }

  // Applies |function| to each of the InterfacePtrs in the set.
  template <typename FunctionType>
  void ForAllPtrs(FunctionType function) {
    for (const auto& it : ptrs_) {
      if (it)
        function(it->get());
    }
    ClearNullInterfacePtrs();
  }

  // Closes the MessagePipe associated with each of the InterfacePtrs in
  // this set and clears the set.
  void CloseAll() {
    for (const auto& it : ptrs_) {
      if (it)
        it->Close();
    }
    ptrs_.clear();
  }

  // TODO(rudominer) After reworking this class and eliminating the method
  // ClearNullInterfacePtrs, this method should become const.
  size_t size() {
    ClearNullInterfacePtrs();
    return ptrs_.size();
  }

 private:
  using WPWIPI = base::WeakPtr<internal::WeakInterfacePtr<Interface>>;

  void ClearNullInterfacePtrs() {
    ptrs_.erase(std::remove_if(ptrs_.begin(), ptrs_.end(), [](const WPWIPI& p) {
      return p.get() == nullptr;
    }), ptrs_.end());
  }

  std::vector<WPWIPI> ptrs_;
};

}  // namespace mojo

#endif  // MOJO_COMMON_WEAK_INTERFACE_PTR_SET_H_
