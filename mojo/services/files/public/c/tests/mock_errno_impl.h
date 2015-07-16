// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_TESTS_MOCK_ERRNO_IMPL_H_
#define SERVICES_FILES_C_TESTS_MOCK_ERRNO_IMPL_H_

#include "files/public/c/lib/errno_impl.h"
#include "mojo/public/cpp/system/macros.h"

namespace mojio {
namespace test {

class MockErrnoImpl : public ErrnoImpl {
 public:
  explicit MockErrnoImpl(int error) : last_error_(error), was_set_(false) {}
  ~MockErrnoImpl() override {}

  // |ErrnoImpl| implementation:
  int Get() const override;
  void Set(int error) override;

  // Reset to initial state (with specified value for |last_error_|).
  void Reset(int error) {
    last_error_ = error;
    was_set_ = false;
  }

  bool was_set() const { return was_set_; }

 private:
  int last_error_;
  bool was_set_;

  MOJO_DISALLOW_COPY_AND_ASSIGN(MockErrnoImpl);
};

}  // namespace test
}  // namespace mojio

#endif  // SERVICES_FILES_C_TESTS_MOCK_ERRNO_IMPL_H_
