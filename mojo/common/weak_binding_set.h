// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_COMMON_WEAK_BINDING_SET_H_
#define MOJO_COMMON_WEAK_BINDING_SET_H_

#include <algorithm>
#include <vector>

#include "base/memory/weak_ptr.h"
#include "mojo/public/cpp/bindings/binding.h"

namespace mojo {

// Use this class to manage a set of bindings each of which is
// owned by the pipe it is bound to.
template <typename Interface>
class WeakBindingSet {
 public:
  WeakBindingSet() {}
  ~WeakBindingSet() { CloseAllBindings(); }

  void AddBinding(Interface* impl, InterfaceRequest<Interface> request) {
    bindings_.emplace_back(new Binding<Interface>(impl, request.Pass()));
    auto* binding = bindings_.back().get();
    // Set the connection error handler for the newly added Binding to be a
    // function that will erase it from the vector.
    binding->set_connection_error_handler([this, binding]() {
      auto it =
          std::find_if(bindings_.begin(), bindings_.end(),
                       [binding](const std::unique_ptr<Binding<Interface>>& b) {
                         return (b.get() == binding);
                       });
      DCHECK(it != bindings_.end());
      bindings_.erase(it);
    });
  }

  void CloseAllBindings() {
    bindings_.clear();
  }

  size_t size() const { return bindings_.size(); }

 private:
  std::vector<std::unique_ptr<Binding<Interface>>> bindings_;

  DISALLOW_COPY_AND_ASSIGN(WeakBindingSet);
};

}  // namespace mojo

#endif  // MOJO_COMMON_WEAK_BINDING_SET_H_
