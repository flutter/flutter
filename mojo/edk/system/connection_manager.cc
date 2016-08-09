// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "mojo/edk/system/connection_manager.h"

namespace mojo {
namespace system {

ConnectionIdentifier ConnectionManager::GenerateConnectionIdentifier() {
  return UniqueIdentifier::Generate(platform_support_);
}

}  // namespace system
}  // namespace mojo
