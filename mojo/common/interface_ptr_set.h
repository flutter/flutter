// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_INTERFACE_PTR_SET_H_
#define MOJO_COMMON_INTERFACE_PTR_SET_H_

#include <vector>

#include "base/logging.h"
#include "mojo/public/cpp/bindings/interface_ptr.h"

namespace mojo {

// An InterfacePtrSet contains a collection of InterfacePtrs
// that are automatically removed from the collection and destroyed
// when their associated MessagePipe experiences a connection error.
// When the set is destroyed all of the MessagePipes will be closed.
template <typename Interface>
class InterfacePtrSet {
 public:
  InterfacePtrSet() {}
  ~InterfacePtrSet() { CloseAll(); }

  // |ptr| must be bound to a message pipe.
  void AddInterfacePtr(InterfacePtr<Interface> ptr) {
    DCHECK(ptr.is_bound());
    ptrs_.emplace_back(ptr.Pass());
    InterfacePtr<Interface>& intrfc_ptr = ptrs_.back();
    Interface* pointer = intrfc_ptr.get();
    // Set the connection error handler for the newly added InterfacePtr to be a
    // function that will erase it from the vector.
    intrfc_ptr.set_connection_error_handler([pointer, this]() {
      // Since InterfacePtr itself is a movable type, the thing that uniquely
      // identifies the InterfacePtr we wish to erase is its Interface*.
      auto it = std::find_if(ptrs_.begin(), ptrs_.end(),
                             [pointer](const InterfacePtr<Interface>& p) {
                               return (p.get() == pointer);
                             });
      DCHECK(it != ptrs_.end());
      ptrs_.erase(it);
    });
  }

  // Applies |function| to each of the InterfacePtrs in the set.
  template <typename FunctionType>
  void ForAllPtrs(FunctionType function) {
    for (const auto& it : ptrs_) {
      if (it)
        function(it.get());
    }
  }

  // Closes the MessagePipe associated with each of the InterfacePtrs in
  // this set and clears the set.
  void CloseAll() {
    for (auto& it : ptrs_) {
      if (it)
        it.reset();
    }
    ptrs_.clear();
  }

  size_t size() const { return ptrs_.size(); }

 private:
  std::vector<InterfacePtr<Interface>> ptrs_;
};

}  // namespace mojo

#endif  // MOJO_COMMON_INTERFACE_PTR_SET_H_
