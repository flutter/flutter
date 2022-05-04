// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/reactor_gles.h"

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"

namespace impeller {

ReactorGLES::ReactorGLES(std::unique_ptr<ProcTableGLES> gl)
    : proc_table_(std::move(gl)) {
  if (!proc_table_ || !proc_table_->IsValid()) {
    VALIDATION_LOG << "Proc table was invalid.";
    return;
  }

  is_valid_ = true;
}

ReactorGLES::~ReactorGLES() = default;

bool ReactorGLES::IsValid() const {
  return is_valid_;
}

bool ReactorGLES::HasPendingOperations() const {
  return !pending_operations_.empty() || !gl_handles_to_collect_.empty();
}

const ProcTableGLES& ReactorGLES::GetProcTable() const {
  FML_DCHECK(IsValid());
  return *proc_table_;
}

std::optional<GLuint> ReactorGLES::GetGLHandle(const GLESHandle& handle) const {
  auto found = live_gl_handles_.find(handle);
  if (found != live_gl_handles_.end()) {
    return found->second;
  }
  return std::nullopt;
}

bool ReactorGLES::AddOperation(Operation operation) {
  if (!operation) {
    return false;
  }
  pending_operations_.emplace_back(std::move(operation));
  return React();
}

static std::optional<GLuint> CreateGLHandle(const ProcTableGLES& gl,
                                            HandleType type) {
  GLuint handle = GL_NONE;
  switch (type) {
    case HandleType::kUnknown:
      return std::nullopt;
    case HandleType::kTexture:
      gl.GenTextures(1u, &handle);
      return handle;
    case HandleType::kBuffer:
      gl.GenBuffers(1u, &handle);
      return handle;
    case HandleType::kProgram:
      return gl.CreateProgram();
  }
  return std::nullopt;
}

static bool CollectGLHandle(const ProcTableGLES& gl,
                            HandleType type,
                            GLuint handle) {
  switch (type) {
    case HandleType::kUnknown:
      return false;
    case HandleType::kTexture:
      gl.DeleteTextures(1u, &handle);
      return true;
    case HandleType::kBuffer:
      gl.DeleteBuffers(1u, &handle);
      return true;
    case HandleType::kProgram:
      gl.DeleteProgram(handle);
      return true;
  }
  return false;
}

GLESHandle ReactorGLES::CreateHandle(HandleType type) {
  if (type == HandleType::kUnknown) {
    return GLESHandle::DeadHandle();
  }
  auto new_handle = GLESHandle::Create(type);
  if (new_handle.IsDead()) {
    return GLESHandle::DeadHandle();
  }
  live_gl_handles_[new_handle] =
      in_reaction_ ? CreateGLHandle(GetProcTable(), type) : std::nullopt;
  return new_handle;
}

void ReactorGLES::CollectHandle(GLESHandle handle) {
  auto live_handle = live_gl_handles_.find(handle);
  if (live_handle == live_gl_handles_.end()) {
    return;
  }
  if (live_handle->second.has_value()) {
    gl_handles_to_collect_[live_handle->first] = live_handle->second.value();
  }
  live_gl_handles_.erase(live_handle);
}

bool ReactorGLES::React() {
  TRACE_EVENT0("impeller", "ReactorGLES::React");
  in_reaction_ = true;
  fml::ScopedCleanupClosure reset_in_reaction([&]() { in_reaction_ = false; });
  while (HasPendingOperations()) {
    if (!ReactOnce()) {
      return false;
    }
  }
  return true;
}

bool ReactorGLES::ReactOnce() {
  if (!IsValid()) {
    return false;
  }

  //----------------------------------------------------------------------------
  /// Collect all the handles for whom there is a GL handle sibling.
  ///
  for (const auto& handle_to_collect : gl_handles_to_collect_) {
    if (!CollectGLHandle(GetProcTable(),                // proc table
                         handle_to_collect.first.type,  // handle type
                         handle_to_collect.second       // GL handle name
                         )) {
      VALIDATION_LOG << "Could not collect GL handle.";
      return false;
    }
  }
  gl_handles_to_collect_.clear();

  //----------------------------------------------------------------------------
  /// Make sure all pending handles have a GL handle sibling.
  ///
  for (auto& live_handle : live_gl_handles_) {
    if (live_handle.second.has_value()) {
      // Already a realized GL handle.
      continue;
    }
    auto gl_handle = CreateGLHandle(GetProcTable(), live_handle.first.type);
    if (!gl_handle.has_value()) {
      VALIDATION_LOG << "Could not create GL handle.";
      return false;
    }
    live_handle.second = gl_handle;
  }

  //----------------------------------------------------------------------------
  /// Flush all pending operations in order.
  ///
  auto operations = std::move(pending_operations_);
  for (const auto& operation : operations) {
    operation(*this);
  }
  pending_operations_.clear();

  return true;
}

}  // namespace impeller
