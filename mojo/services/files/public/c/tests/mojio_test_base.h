// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef SERVICES_FILES_C_TESTS_MOJIO_TEST_BASE_H_
#define SERVICES_FILES_C_TESTS_MOJIO_TEST_BASE_H_

#include "files/public/c/tests/mojio_impl_test_base.h"

namespace mojio {
namespace test {

// This is a base class for tests that test the exposed functions (etc.), and
// which probably use the singletons.
class MojioTestBase : public MojioImplTestBase {
 public:
  MojioTestBase() {}
  ~MojioTestBase() override {}

  void SetUp() override;
  void TearDown() override;

 private:
  MOJO_DISALLOW_COPY_AND_ASSIGN(MojioTestBase);
};

}  // namespace test
}  // namespace mojio

#endif  // SERVICES_FILES_C_TESTS_MOJIO_TEST_BASE_H_
