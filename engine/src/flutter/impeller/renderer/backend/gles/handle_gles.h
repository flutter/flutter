// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <optional>
#include <type_traits>
#include <unordered_map>
#include <unordered_set>

#include "flutter/fml/hash_combine.h"
#include "flutter/fml/macros.h"
#include "impeller/base/comparable.h"
#include "impeller/renderer/backend/gles/gles.h"

namespace impeller {

enum class HandleType {
  kUnknown,
  kTexture,
  kBuffer,
  kProgram,
  kRenderBuffer,
  kFrameBuffer,
};

class ReactorGLES;

struct HandleGLES {
  HandleType type = HandleType::kUnknown;

  static HandleGLES DeadHandle() {
    return HandleGLES{HandleType::kUnknown, std::nullopt};
  }

  constexpr bool IsDead() const { return !name_.has_value(); }

  struct Hash {
    std::size_t operator()(const HandleGLES& handle) const {
      return fml::HashCombine(
          std::underlying_type_t<decltype(handle.type)>(handle.type),
          handle.name_);
    }
  };

  struct Equal {
    bool operator()(const HandleGLES& lhs, const HandleGLES& rhs) const {
      return lhs.type == rhs.type && lhs.name_ == rhs.name_;
    }
  };

 private:
  friend class ReactorGLES;

  std::optional<UniqueID> name_;

  HandleGLES(HandleType p_type, UniqueID p_name)
      : type(p_type), name_(p_name) {}

  HandleGLES(HandleType p_type, std::optional<UniqueID> p_name)
      : type(p_type), name_(p_name) {}

  static HandleGLES Create(HandleType type) {
    return HandleGLES{type, UniqueID{}};
  }
};

using GLESHandleSet =
    std::unordered_set<HandleGLES, HandleGLES::Hash, HandleGLES::Equal>;
template <class T>
using GLESHandleMap =
    std::unordered_map<HandleGLES, T, HandleGLES::Hash, HandleGLES::Equal>;

}  // namespace impeller
