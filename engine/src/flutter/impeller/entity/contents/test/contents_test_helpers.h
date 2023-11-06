// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include "impeller/renderer/command.h"

namespace impeller {

/// @brief Retrieve the [VertInfo] struct data from the provided [command].
template <typename T>
typename T::VertInfo* GetVertInfo(const Command& command) {
  auto resource = command.vertex_bindings.buffers.find(0u);
  if (resource == command.vertex_bindings.buffers.end()) {
    return nullptr;
  }

  auto data = (resource->second.view.resource.contents +
               resource->second.view.resource.range.offset);
  return reinterpret_cast<typename T::VertInfo*>(data);
}

/// @brief Retrieve the [FragInfo] struct data from the provided [command].
template <typename T>
typename T::FragInfo* GetFragInfo(const Command& command) {
  auto resource = command.fragment_bindings.buffers.find(0u);
  if (resource == command.fragment_bindings.buffers.end()) {
    return nullptr;
  }

  auto data = (resource->second.view.resource.contents +
               resource->second.view.resource.range.offset);
  return reinterpret_cast<typename T::FragInfo*>(data);
}

}  // namespace impeller
