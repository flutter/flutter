// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_CPP_BINDINGS_LIB_SHARED_DATA_H_
#define MOJO_PUBLIC_CPP_BINDINGS_LIB_SHARED_DATA_H_

#include "mojo/public/cpp/system/macros.h"

namespace mojo {
namespace internal {

// Used to allocate an instance of T that can be shared via reference counting.
template <typename T>
class SharedData {
 public:
  ~SharedData() { holder_->Release(); }

  SharedData() : holder_(new Holder()) {}

  explicit SharedData(const T& value) : holder_(new Holder(value)) {}

  SharedData(const SharedData<T>& other) : holder_(other.holder_) {
    holder_->Retain();
  }

  SharedData<T>& operator=(const SharedData<T>& other) {
    if (other.holder_ == holder_)
      return *this;
    holder_->Release();
    holder_ = other.holder_;
    holder_->Retain();
    return *this;
  }

  void reset() {
    holder_->Release();
    holder_ = new Holder();
  }

  void reset(const T& value) {
    holder_->Release();
    holder_ = new Holder(value);
  }

  void set_value(const T& value) { holder_->value = value; }
  T* mutable_value() { return &holder_->value; }
  const T& value() const { return holder_->value; }

 private:
  class Holder {
   public:
    Holder() : value(), ref_count_(1) {}
    Holder(const T& value) : value(value), ref_count_(1) {}

    void Retain() { ++ref_count_; }
    void Release() {
      if (--ref_count_ == 0)
        delete this;
    }

    T value;

   private:
    int ref_count_;
    MOJO_DISALLOW_COPY_AND_ASSIGN(Holder);
  };

  Holder* holder_;
};

}  // namespace internal
}  // namespace mojo

#endif  // MOJO_PUBLIC_CPP_BINDINGS_LIB_SHARED_DATA_H_
