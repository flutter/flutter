// Copyright 2018 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "fdio/namespace.h"
#include "lib/fxl/logging.h"
#include "lib/fxl/memory/unique_object.h"

namespace flutter {

struct UniqueFDIONSTraits {
  static fdio_ns_t* InvalidValue() { return nullptr; }

  static bool IsValid(fdio_ns_t* ns) { return ns != InvalidValue(); }

  static void Free(fdio_ns_t* ns) {
    auto status = fdio_ns_destroy(ns);
    FXL_DCHECK(status == ZX_OK);
  }
};

using UniqueFDIONS = fxl::UniqueObject<fdio_ns_t*, UniqueFDIONSTraits>;

inline UniqueFDIONS UniqueFDIONSCreate() {
  fdio_ns_t* ns = nullptr;
  if (fdio_ns_create(&ns) == ZX_OK) {
    return UniqueFDIONS{ns};
  }
  return UniqueFDIONS{nullptr};
}

}  // namespace flutter
