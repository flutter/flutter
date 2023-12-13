// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_HANDLE_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_HANDLE_GLES_H_

#include <optional>
#include <sstream>
#include <string>
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

std::string HandleTypeToString(HandleType type);

class ReactorGLES;

struct HandleGLES {
  HandleType type = HandleType::kUnknown;
  std::optional<UniqueID> name;

  static HandleGLES DeadHandle() {
    return HandleGLES{HandleType::kUnknown, std::nullopt};
  }

  constexpr bool IsDead() const { return !name.has_value(); }

  struct Hash {
    std::size_t operator()(const HandleGLES& handle) const {
      return fml::HashCombine(
          std::underlying_type_t<decltype(handle.type)>(handle.type),
          handle.name);
    }
  };

  struct Equal {
    bool operator()(const HandleGLES& lhs, const HandleGLES& rhs) const {
      return lhs.type == rhs.type && lhs.name == rhs.name;
    }
  };

 private:
  friend class ReactorGLES;

  HandleGLES(HandleType p_type, UniqueID p_name) : type(p_type), name(p_name) {}

  HandleGLES(HandleType p_type, std::optional<UniqueID> p_name)
      : type(p_type), name(p_name) {}

  static HandleGLES Create(HandleType type) {
    return HandleGLES{type, UniqueID{}};
  }
};

}  // namespace impeller

namespace std {

inline std::ostream& operator<<(std::ostream& out,
                                const impeller::HandleGLES& handle) {
  out << HandleTypeToString(handle.type) << "(";
  if (handle.IsDead()) {
    out << "DEAD";
  } else {
    if (handle.name.has_value()) {
      out << handle.name.value().id;
    } else {
      out << "UNNAMED";
    }
  }
  out << ")";
  return out;
}

}  // namespace std

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_HANDLE_GLES_H_
