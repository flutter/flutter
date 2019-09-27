// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_RUNNER_BUILTIN_LIBRARIES_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_RUNNER_BUILTIN_LIBRARIES_H_

#include <memory>
#include <string>

#include <lib/fdio/namespace.h>

#include <fuchsia/sys/cpp/fidl.h>

namespace dart_runner {

void InitBuiltinLibrariesForIsolate(
    const std::string& script_uri,
    fdio_ns_t* namespc,
    int stdoutfd,
    int stderrfd,
    fidl::InterfaceHandle<fuchsia::sys::Environment> environment,
    zx::channel directory_request,
    bool service_isolate);

}  // namespace dart_runner

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_RUNNER_BUILTIN_LIBRARIES_H_
