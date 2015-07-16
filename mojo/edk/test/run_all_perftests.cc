// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/perf_test_suite.h"
#include "mojo/edk/embedder/test_embedder.h"
#include "mojo/edk/test/test_support_impl.h"
#include "mojo/public/tests/test_support_private.h"

int main(int argc, char** argv) {
  mojo::embedder::test::InitWithSimplePlatformSupport();
  mojo::test::TestSupport::Init(new mojo::test::TestSupportImpl());
  return base::PerfTestSuite(argc, argv).Run();
}
