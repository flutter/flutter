// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/public/tests/test_support_private.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

static mojo::test::TestSupport* g_test_support = NULL;

extern "C" {

void MojoTestSupportLogPerfResult(const char* test_name,
                                  const char* sub_test_name,
                                  double value,
                                  const char* units) {
  if (g_test_support) {
    g_test_support->LogPerfResult(test_name, sub_test_name, value, units);
  } else {
    if (sub_test_name) {
      printf("[no test runner]\t%s/%s\t%g\t%s\n", test_name, sub_test_name,
             value, units);
    } else {
      printf("[no test runner]\t%s\t%g\t%s\n", test_name, value, units);
    }
  }
}

FILE* MojoTestSupportOpenSourceRootRelativeFile(const char* relative_path) {
  if (g_test_support)
    return g_test_support->OpenSourceRootRelativeFile(relative_path);
  printf("[no test runner]\n");
  return NULL;
}

char** MojoTestSupportEnumerateSourceRootRelativeDirectory(
    const char* relative_path) {
  if (g_test_support)
    return g_test_support->EnumerateSourceRootRelativeDirectory(relative_path);

  printf("[no test runner]\n");

  // Return empty list:
  char** rv = static_cast<char**>(calloc(1, sizeof(char*)));
  rv[0] = NULL;
  return rv;
}

}  // extern "C"

namespace mojo {
namespace test {

TestSupport::~TestSupport() {
}

// static
void TestSupport::Init(TestSupport* test_support) {
  assert(!g_test_support);
  g_test_support = test_support;
}

// static
TestSupport* TestSupport::Get() {
  return g_test_support;
}

// static
void TestSupport::Reset() {
  g_test_support = NULL;
}

}  // namespace test
}  // namespace mojo
