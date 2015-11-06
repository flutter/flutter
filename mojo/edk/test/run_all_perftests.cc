// Copyright 2013 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "base/test/perf_test_suite.h"
#include "mojo/edk/embedder/test_embedder.h"

int main(int argc, char** argv) {
  mojo::embedder::test::InitWithSimplePlatformSupport();
  return base::PerfTestSuite(argc, argv).Run();
}
