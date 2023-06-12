// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNTIME_DART_UTILS_TEMPFS_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNTIME_DART_UTILS_TEMPFS_H_

#include <mutex>

#include <lib/async-loop/cpp/loop.h>
#include <lib/fdio/namespace.h>

namespace dart_utils {

// Sets up /tmp for the dart_runner and flutter_runner.
class RunnerTemp {
 public:
  // Sets up a virtual filesystem bound to /tmp in the process-wide namespace
  // that has the lifetime of this instance.
  RunnerTemp();
  ~RunnerTemp();

  // Take the virtual filesystem mapped into the process-wide namespace for
  // /tmp, and map it to /tmp in the given namespace.
  static void SetupComponent(fdio_ns_t* ns);

 private:
  void Start();

  std::unique_ptr<async::Loop> loop_;

  // Disallow copy and assignment.
  RunnerTemp(const RunnerTemp&) = delete;
  RunnerTemp& operator=(const RunnerTemp&) = delete;
};

}  // namespace dart_utils

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_RUNTIME_DART_UTILS_TEMPFS_H_
