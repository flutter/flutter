// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "benchmarking.h"

#include "flutter/fml/backtrace.h"
#include "flutter/fml/icu_util.h"

namespace benchmarking {

int Main(int argc, char** argv) {
  fml::InstallCrashHandler();
  benchmark::Initialize(&argc, argv);
  fml::icu::InitializeICU("icudtl.dat");
  ::benchmark::RunSpecifiedBenchmarks();
  return 0;
}

}  // namespace benchmarking

int main(int argc, char** argv) {
  return benchmarking::Main(argc, argv);
}
