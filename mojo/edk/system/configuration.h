// Copyright 2014 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef MOJO_EDK_SYSTEM_CONFIGURATION_H_
#define MOJO_EDK_SYSTEM_CONFIGURATION_H_

#include "mojo/edk/embedder/configuration.h"

namespace mojo {
namespace system {

namespace internal {
extern embedder::Configuration g_configuration;
}  // namespace internal

inline const embedder::Configuration& GetConfiguration() {
  return internal::g_configuration;
}

inline embedder::Configuration* GetMutableConfiguration() {
  return &internal::g_configuration;
}

}  // namespace system
}  // namespace mojo

#endif  // MOJO_EDK_SYSTEM_CONFIGURATION_H_
