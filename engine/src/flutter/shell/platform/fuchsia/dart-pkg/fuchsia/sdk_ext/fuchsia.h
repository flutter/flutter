// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_PKG_FUCHSIA_SDK_EXT_FUCHSIA_H_
#define FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_PKG_FUCHSIA_SDK_EXT_FUCHSIA_H_

#include <fuchsia/sys/cpp/fidl.h>

namespace fuchsia {
namespace dart {

/// Initializes Dart bindings for the Fuchsia application model.
void Initialize(fidl::InterfaceHandle<fuchsia::sys::Environment> environment,
                zx::channel directory_request,
                std::optional<zx::eventpair> view_ref);

}  // namespace dart
}  // namespace fuchsia

#endif  // FLUTTER_SHELL_PLATFORM_FUCHSIA_DART_PKG_FUCHSIA_SDK_EXT_FUCHSIA_H_
