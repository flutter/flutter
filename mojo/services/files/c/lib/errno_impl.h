// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_ERRNO_IMPL_H_
#define SERVICES_FILES_C_LIB_ERRNO_IMPL_H_

#include "mojo/public/cpp/system/macros.h"

namespace mojio {

// |ErrnoImpl| is an interface for getting/setting errno values.
class ErrnoImpl {
 public:
  // When destroyed, this class either preserves the errno value at creation or
  // sets it to an explicit value. (Without this, internal calls may set errno
  // to a value that shouldn't be visible to the caller.)
  class Setter {
   public:
    explicit Setter(ErrnoImpl* errno_impl)
        : errno_impl_(errno_impl), error_(errno_impl_->Get()) {}
    ~Setter() { errno_impl_->Set(error_); }

    // If |error| is 0, this does nothing and returns true. Otherwise, this will
    // arrange for the |ErrnoImpl|'s |Set()| to be called with the value of
    // |error| (which should be a valid errno code) on destruction, and returns
    // false.
    bool Set(int error) {
      if (error == 0)
        return true;
      error_ = error;
      return false;
    }

   private:
    ErrnoImpl* const errno_impl_;
    int error_;

    MOJO_DISALLOW_COPY_AND_ASSIGN(Setter);
  };

  virtual int Get() const = 0;
  virtual void Set(int error) = 0;

 protected:
  ErrnoImpl() {}
  // Important: Destructors should not modify (the "real") errno (or any global
  // state that may affect implementations of |ErrnoImpl|).
  virtual ~ErrnoImpl() {}

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(ErrnoImpl);
};

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_ERRNO_IMPL_H_
