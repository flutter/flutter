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

namespace internal {

// TODO(vtl): https://github.com/domokit/mojo/issues/311 applies here as well.
template <typename Interface>
class WeakBinding {
 public:
  WeakBinding(Interface* impl, InterfaceRequest<Interface> request)
      : binding_(impl, request.Pass()), weak_ptr_factory_(this) {
    binding_.set_connection_error_handler([this]() { OnConnectionError(); });
  }

  ~WeakBinding() {}

  void set_connection_error_handler(const Closure& error_handler) {
    error_handler_ = error_handler;
  }

  base::WeakPtr<WeakBinding> GetWeakPtr() {
    return weak_ptr_factory_.GetWeakPtr();
  }

  void Close() { binding_.Close(); }

 private:
  void OnConnectionError() {
    Closure error_handler = error_handler_;
    delete this;
    error_handler.Run();
  }

  mojo::Binding<Interface> binding_;
  Closure error_handler_;
  base::WeakPtrFactory<WeakBinding> weak_ptr_factory_;

  DISALLOW_COPY_AND_ASSIGN(WeakBinding);
};

}  // namespace internal

// Use this class to manage a set of weak pointers to bindings each of which is
// owned by the pipe they are bound to.
template <typename Interface>
class WeakBindingSet {
 public:
  WeakBindingSet() {}
  ~WeakBindingSet() { CloseAllBindings(); }

  void AddBinding(Interface* impl, InterfaceRequest<Interface> request) {
    auto binding = new internal::WeakBinding<Interface>(impl, request.Pass());
    binding->set_connection_error_handler([this]() { OnConnectionError(); });
    bindings_.push_back(binding->GetWeakPtr());
  }

  void CloseAllBindings() {
    for (const auto& it : bindings_) {
      if (it)
        it->Close();
    }
    bindings_.clear();
  }

 private:
  void OnConnectionError() {
    // Clear any deleted bindings.
    bindings_.erase(
        std::remove_if(
            bindings_.begin(), bindings_.end(),
            [](const base::WeakPtr<internal::WeakBinding<Interface>>& p) {
              return p.get() == nullptr;
            }),
        bindings_.end());
  }

  std::vector<base::WeakPtr<internal::WeakBinding<Interface>>> bindings_;

  DISALLOW_COPY_AND_ASSIGN(WeakBindingSet);
};

}  // namespace mojo

#endif  // MOJO_COMMON_WEAK_BINDING_SET_H_
