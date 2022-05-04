// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "impeller/renderer/backend/gles/gles_handle.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

class ReactorGLES {
 public:
  using Ref = std::shared_ptr<ReactorGLES>;

  ReactorGLES(std::unique_ptr<ProcTableGLES> gl);

  ~ReactorGLES();

  bool IsValid() const;

  bool HasPendingOperations() const;

  const ProcTableGLES& GetProcTable() const;

  std::optional<GLuint> GetGLHandle(const GLESHandle& handle) const;

  GLESHandle CreateHandle(HandleType type);

  void CollectHandle(GLESHandle handle);

  using Operation = std::function<void(const ReactorGLES& reactor)>;
  [[nodiscard]] bool AddOperation(Operation operation);

  [[nodiscard]] bool React();

 private:
  std::unique_ptr<ProcTableGLES> proc_table_;
  std::vector<Operation> pending_operations_;
  GLESHandleMap<std::optional<GLuint>> live_gl_handles_;
  GLESHandleMap<GLuint> gl_handles_to_collect_;
  bool in_reaction_ = false;

  bool is_valid_ = false;

  bool ReactOnce();

  FML_DISALLOW_COPY_AND_ASSIGN(ReactorGLES);
};

}  // namespace impeller
