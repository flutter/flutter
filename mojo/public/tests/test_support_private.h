// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_PUBLIC_TESTS_TEST_SUPPORT_PRIVATE_H_
#define MOJO_PUBLIC_TESTS_TEST_SUPPORT_PRIVATE_H_

#include <stdio.h>

#include "mojo/public/c/test_support/test_support.h"

namespace mojo {
namespace test {

// Implementors of the test support APIs can use this interface to install their
// implementation into the mojo_test_support dynamic library.
class MOJO_TEST_SUPPORT_EXPORT TestSupport {
 public:
  virtual ~TestSupport();

  static void Init(TestSupport* test_support);
  static TestSupport* Get();
  static void Reset();

  virtual void LogPerfResult(const char* test_name,
                             const char* sub_test_name,
                             double value,
                             const char* units) = 0;
  virtual FILE* OpenSourceRootRelativeFile(const char* relative_path) = 0;
  virtual char** EnumerateSourceRootRelativeDirectory(
      const char* relative_path) = 0;
};

}  // namespace test
}  // namespace mojo

#endif  // MOJO_PUBLIC_TESTS_TEST_SUPPORT_PRIVATE_H_
