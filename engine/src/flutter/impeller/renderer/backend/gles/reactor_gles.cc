// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/renderer/backend/gles/reactor_gles.h"

#include <algorithm>

#include "flutter/fml/trace_event.h"
#include "impeller/base/validation.h"

namespace impeller {

ReactorGLES::ReactorGLES(std::unique_ptr<ProcTableGLES> gl)
    : proc_table_(std::move(gl)) {
  if (!proc_table_ || !proc_table_->IsValid()) {
    VALIDATION_LOG << "Proc table was invalid.";
    return;
  }
  can_set_debug_labels_ = proc_table_->GetDescription()->HasDebugExtension();
  is_valid_ = true;
}

ReactorGLES::~ReactorGLES() = default;

bool ReactorGLES::IsValid() const {
  return is_valid_;
}

ReactorGLES::WorkerID ReactorGLES::AddWorker(std::weak_ptr<Worker> worker) {
  Lock lock(workers_mutex_);
  auto id = WorkerID{};
  workers_[id] = std::move(worker);
  return id;
}

bool ReactorGLES::RemoveWorker(WorkerID worker) {
  Lock lock(workers_mutex_);
  return workers_.erase(worker) == 1;
}

bool ReactorGLES::HasPendingOperations() const {
  Lock ops_lock(ops_mutex_);
  return !pending_operations_.empty() || !gl_handles_to_collect_.empty();
}

const ProcTableGLES& ReactorGLES::GetProcTable() const {
  FML_DCHECK(IsValid());
  return *proc_table_;
}

std::optional<GLuint> ReactorGLES::GetGLHandle(const HandleGLES& handle) const {
  ReaderLock handles_lock(handles_mutex_);
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
  {
    Lock ops_lock(ops_mutex_);
    pending_operations_.emplace_back(std::move(operation));
  }
  // Attempt a reaction if able but it is not an error if this isn't possible.
  [[maybe_unused]] auto result = React();
  return true;
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
    case HandleType::kRenderBuffer:
      gl.GenRenderbuffers(1u, &handle);
      return handle;
    case HandleType::kFrameBuffer:
      gl.GenFramebuffers(1u, &handle);
      return handle;
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
    case HandleType::kRenderBuffer:
      gl.DeleteRenderbuffers(1u, &handle);
      return true;
    case HandleType::kFrameBuffer:
      gl.DeleteFramebuffers(1u, &handle);
      return true;
  }
  return false;
}

HandleGLES ReactorGLES::CreateHandle(HandleType type) {
  if (type == HandleType::kUnknown) {
    return HandleGLES::DeadHandle();
  }
  auto new_handle = HandleGLES::Create(type);
  if (new_handle.IsDead()) {
    return HandleGLES::DeadHandle();
  }
  WriterLock handles_lock(handles_mutex_);
  live_gl_handles_[new_handle] =
      in_reaction_ ? CreateGLHandle(GetProcTable(), type) : std::nullopt;
  return new_handle;
}

void ReactorGLES::CollectHandle(HandleGLES handle) {
  WriterLock handles_lock(handles_mutex_);
  auto live_handle = live_gl_handles_.find(handle);
  if (live_handle == live_gl_handles_.end()) {
    return;
  }
  if (live_handle->second.has_value()) {
    Lock ops_lock(ops_mutex_);
    gl_handles_to_collect_[live_handle->first] = live_handle->second.value();
  }
  live_gl_handles_.erase(live_handle);
}

bool ReactorGLES::React() {
  TRACE_EVENT0("impeller", "ReactorGLES::React");
  if (!CanReactOnCurrentThread()) {
    return false;
  }
  in_reaction_ = true;
  fml::ScopedCleanupClosure reset_in_reaction([&]() { in_reaction_ = false; });
  while (HasPendingOperations()) {
    if (!ReactOnce()) {
      return false;
    }
  }
  return true;
}

static DebugResourceType ToDebugResourceType(HandleType type) {
  switch (type) {
    case HandleType::kUnknown:
      FML_UNREACHABLE();
    case HandleType::kTexture:
      return DebugResourceType::kTexture;
    case HandleType::kBuffer:
      return DebugResourceType::kBuffer;
    case HandleType::kProgram:
      return DebugResourceType::kProgram;
    case HandleType::kRenderBuffer:
      return DebugResourceType::kRenderBuffer;
    case HandleType::kFrameBuffer:
      return DebugResourceType::kFrameBuffer;
  }
  FML_UNREACHABLE();
}

bool ReactorGLES::ReactOnce() {
  if (!IsValid()) {
    return false;
  }

  const auto& gl = GetProcTable();

  //----------------------------------------------------------------------------
  /// Collect all the handles for whom there is a GL handle sibling.
  ///
  decltype(gl_handles_to_collect_) gl_handles_to_collect;
  {
    Lock ops_lock(ops_mutex_);
    std::swap(gl_handles_to_collect_, gl_handles_to_collect);
    FML_DCHECK(gl_handles_to_collect_.empty());
  }
  for (const auto& handle_to_collect : gl_handles_to_collect) {
    if (!CollectGLHandle(gl,                            // proc table
                         handle_to_collect.first.type,  // handle type
                         handle_to_collect.second       // GL handle name
                         )) {
      VALIDATION_LOG << "Could not collect GL handle.";
      return false;
    }
  }

  //----------------------------------------------------------------------------
  /// Make sure all pending handles have a GL handle sibling.
  ///
  {
    WriterLock handles_lock(handles_mutex_);
    for (auto& live_handle : live_gl_handles_) {
      if (live_handle.second.has_value()) {
        // Already a realized GL handle.
        continue;
      }
      auto gl_handle = CreateGLHandle(gl, live_handle.first.type);
      if (!gl_handle.has_value()) {
        VALIDATION_LOG << "Could not create GL handle.";
        return false;
      }
      live_handle.second = gl_handle;
    }
  }

  //----------------------------------------------------------------------------
  /// Flush all pending operations in order.
  ///
  decltype(pending_operations_) pending_operations;
  {
    Lock ops_lock(ops_mutex_);
    std::swap(pending_operations_, pending_operations);
    FML_DCHECK(pending_operations_.empty());
  }
  for (const auto& operation : pending_operations) {
    TRACE_EVENT0("impeller", "ReactorGLES::Operation");
    operation(*this);
  }

  //----------------------------------------------------------------------------
  /// Make sure all pending debug labels have been flushed.
  ///
  decltype(pending_debug_labels_) pending_debug_labels;
  {
    WriterLock handles_lock(handles_mutex_);
    std::swap(pending_debug_labels_, pending_debug_labels);
    FML_DCHECK(pending_debug_labels_.empty());
  }
  if (!pending_debug_labels.empty()) {
    ReaderLock handles_lock(handles_mutex_);
    for (const auto& label : pending_debug_labels) {
      auto live_handle = live_gl_handles_.find(label.first);
      if (live_handle == live_gl_handles_.end() ||
          !live_handle->second.has_value()) {
        continue;
      }
      gl.SetDebugLabel(ToDebugResourceType(label.first.type),  // type
                       live_handle->second.value(),            // name
                       label.second                            // label
      );
    }
  }

  return true;
}

void ReactorGLES::SetDebugLabel(const HandleGLES& handle, std::string label) {
  if (!can_set_debug_labels_) {
    return;
  }
  if (label.empty()) {
    return;
  }
  if (handle.IsDead()) {
    return;
  }
  WriterLock handles_lock(handles_mutex_);
  pending_debug_labels_[handle] = std::move(label);
}

bool ReactorGLES::CanReactOnCurrentThread() const {
  std::vector<WorkerID> dead_workers;
  Lock lock(workers_mutex_);
  for (const auto& worker : workers_) {
    auto worker_ptr = worker.second.lock();
    if (!worker_ptr) {
      dead_workers.push_back(worker.first);
      continue;
    }
    if (worker_ptr->CanReactorReactOnCurrentThreadNow(*this)) {
      return true;
    }
  }
  for (const auto& worker_id : dead_workers) {
    workers_.erase(worker_id);
  }
  return false;
}

}  // namespace impeller
