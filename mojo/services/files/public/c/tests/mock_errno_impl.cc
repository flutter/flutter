// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "files/public/c/tests/mock_errno_impl.h"

namespace mojio {
namespace test {

int MockErrnoImpl::Get() const {
  return last_error_;
}

void MockErrnoImpl::Set(int error) {
  last_error_ = error;
  was_set_ = true;
}

}  // namespace test
}  // namespace mojio
