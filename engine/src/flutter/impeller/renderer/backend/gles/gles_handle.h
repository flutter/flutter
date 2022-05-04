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
};

class ReactorGLES;

struct GLESHandle {
  HandleType type = HandleType::kUnknown;

  static GLESHandle DeadHandle() {
    return GLESHandle{HandleType::kUnknown, std::nullopt};
  }

  constexpr bool IsDead() const { return !name_.has_value(); }

  struct Hash {
    std::size_t operator()(const GLESHandle& handle) const {
      return fml::HashCombine(
          std::underlying_type_t<decltype(handle.type)>(handle.type),
          handle.name_);
    }
  };

  struct Equal {
    bool operator()(const GLESHandle& lhs, const GLESHandle& rhs) const {
      return lhs.type == rhs.type && lhs.name_ == rhs.name_;
    }
  };

 private:
  friend class ReactorGLES;

  std::optional<UniqueID> name_;

  GLESHandle(HandleType p_type, UniqueID p_name)
      : type(p_type), name_(p_name) {}

  GLESHandle(HandleType p_type, std::optional<UniqueID> p_name)
      : type(p_type), name_(p_name) {}

  static GLESHandle Create(HandleType type) {
    return GLESHandle{type, UniqueID{}};
  }
};

using GLESHandleSet =
    std::unordered_set<GLESHandle, GLESHandle::Hash, GLESHandle::Equal>;
template <class T>
using GLESHandleMap =
    std::unordered_map<GLESHandle, T, GLESHandle::Hash, GLESHandle::Equal>;

}  // namespace impeller
