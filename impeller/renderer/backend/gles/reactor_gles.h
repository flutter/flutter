// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/closure.h"
#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

class ReactorGLES {
 public:
  using WorkerID = UniqueID;

  class Worker {
   public:
    virtual ~Worker() = default;

    virtual bool CanReactorReactOnCurrentThreadNow(
        const ReactorGLES& reactor) const = 0;
  };

  using Ref = std::shared_ptr<ReactorGLES>;

  ReactorGLES(std::unique_ptr<ProcTableGLES> gl);

  ~ReactorGLES();

  bool IsValid() const;

  WorkerID AddWorker(std::weak_ptr<Worker> worker);

  bool RemoveWorker(WorkerID);

  const ProcTableGLES& GetProcTable() const;

  std::optional<GLuint> GetGLHandle(const HandleGLES& handle) const;

  HandleGLES CreateHandle(HandleType type);

  void CollectHandle(HandleGLES handle);

  void SetDebugLabel(const HandleGLES& handle, std::string label);

  using Operation = std::function<void(const ReactorGLES& reactor)>;
  [[nodiscard]] bool AddOperation(Operation operation);

  [[nodiscard]] bool React();

 private:
  std::unique_ptr<ProcTableGLES> proc_table_;

  mutable Mutex ops_mutex_;
  std::vector<Operation> pending_operations_ IPLR_GUARDED_BY(ops_mutex_);
  GLESHandleMap<GLuint> gl_handles_to_collect_ IPLR_GUARDED_BY(ops_mutex_);

  mutable RWMutex handles_mutex_;
  GLESHandleMap<std::optional<GLuint>> live_gl_handles_
      IPLR_GUARDED_BY(handles_mutex_);
  GLESHandleMap<std::string> pending_debug_labels_
      IPLR_GUARDED_BY(handles_mutex_);

  mutable Mutex workers_mutex_;
  mutable std::map<WorkerID, std::weak_ptr<Worker>> workers_
      IPLR_GUARDED_BY(workers_mutex_);

  // TODO(csg): Make this thread safe.
  bool in_reaction_ = false;
  bool can_set_debug_labels_ = false;

  bool is_valid_ = false;

  bool ReactOnce();

  bool HasPendingOperations() const;

  bool CanReactOnCurrentThread() const;

  FML_DISALLOW_COPY_AND_ASSIGN(ReactorGLES);
};

}  // namespace impeller
