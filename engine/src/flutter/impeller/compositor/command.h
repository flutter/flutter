// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <map>
#include <memory>
#include <string>

#include "flutter/fml/macros.h"
#include "impeller/compositor/buffer_view.h"
#include "impeller/compositor/pipeline.h"

namespace impeller {

class Texture;
class Sampler;

struct Bindings {
  std::map<size_t, BufferView> buffers;
  std::map<size_t, std::shared_ptr<Texture>> textures;
  std::map<size_t, std::shared_ptr<Sampler>> samplers;
};

struct Command {
  std::shared_ptr<Pipeline> pipeline;
  Bindings vertex_bindings;
  Bindings fragment_bindings;
  BufferView index_buffer;
  size_t index_count = 0u;
  std::string label;

  constexpr operator bool() const { return pipeline && pipeline->IsValid(); }
};

}  // namespace impeller
