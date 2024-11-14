// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_ENTITY_CONTENTS_TEST_CONTENTS_TEST_HELPERS_H_
#define FLUTTER_IMPELLER_ENTITY_CONTENTS_TEST_CONTENTS_TEST_HELPERS_H_

#include "impeller/renderer/command.h"

namespace impeller::testing {

/// @brief Retrieve the [VertInfo] struct data from the provided [command].
template <typename T>
typename T::VertInfo* GetVertInfo(const Command& command) {
  auto resource = std::find_if(command.vertex_bindings.buffers.begin(),
                               command.vertex_bindings.buffers.end(),
                               [](const BufferAndUniformSlot& data) {
                                 return data.slot.ext_res_0 == 0u;
                               });
  if (resource == command.vertex_bindings.buffers.end()) {
    return nullptr;
  }

  auto data = (resource->view.resource.buffer->OnGetContents() +
               resource->view.resource.range.offset);
  return reinterpret_cast<typename T::VertInfo*>(data);
}

/// @brief Retrieve the [FragInfo] struct data from the provided [command].
template <typename T>
typename T::FragInfo* GetFragInfo(const Command& command) {
  auto resource = std::find_if(command.fragment_bindings.buffers.begin(),
                               command.fragment_bindings.buffers.end(),
                               [](const BufferAndUniformSlot& data) {
                                 return data.slot.ext_res_0 == 0u ||
                                        data.slot.binding == 64;
                               });
  if (resource == command.fragment_bindings.buffers.end()) {
    return nullptr;
  }

  auto data = (resource->view.resource.buffer->OnGetContents() +
               resource->view.resource.range.offset);
  return reinterpret_cast<typename T::FragInfo*>(data);
}

}  // namespace impeller::testing

#endif  // FLUTTER_IMPELLER_ENTITY_CONTENTS_TEST_CONTENTS_TEST_HELPERS_H_
