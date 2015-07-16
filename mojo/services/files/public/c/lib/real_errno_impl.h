// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_LIB_REAL_ERRNO_IMPL_H_
#define SERVICES_FILES_C_LIB_REAL_ERRNO_IMPL_H_

#include "files/public/c/lib/errno_impl.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojio {

// An implementation of |ErrnoImpl| using the "real" errno.
class RealErrnoImpl : public ErrnoImpl {
 public:
  // Important: The constructor and the destructor must not modify (or result in
  // modifications to) the "real" errno.
  RealErrnoImpl() {}
  ~RealErrnoImpl() override {}

  int Get() const override;
  void Set(int error) override;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(RealErrnoImpl);
};

}  // namespace mojio

#endif  // SERVICES_FILES_C_LIB_REAL_ERRNO_IMPL_H_
