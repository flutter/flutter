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
  struct LiveHandle {
    std::optional<GLuint> name;
    std::optional<std::string> pending_debug_label;
    bool pending_collection = false;

    LiveHandle() = default;

    explicit LiveHandle(std::optional<GLuint> p_name)
        : name(std::move(p_name)) {}

    constexpr bool IsLive() const { return name.has_value(); }
  };

  std::unique_ptr<ProcTableGLES> proc_table_;

  mutable Mutex ops_mutex_;
  std::vector<Operation> ops_ IPLR_GUARDED_BY(ops_mutex_);

  // Make sure the container is one where erasing items during iteration doesn't
  // invalidate other iterators.
  using LiveHandles = std::unordered_map<HandleGLES,
                                         LiveHandle,
                                         HandleGLES::Hash,
                                         HandleGLES::Equal>;
  mutable RWMutex handles_mutex_;
  LiveHandles handles_ IPLR_GUARDED_BY(handles_mutex_);

  mutable Mutex workers_mutex_;
  mutable std::map<WorkerID, std::weak_ptr<Worker>> workers_
      IPLR_GUARDED_BY(workers_mutex_);

  bool can_set_debug_labels_ = false;
  bool is_valid_ = false;

  bool ReactOnce();

  bool HasPendingOperations() const;

  bool CanReactOnCurrentThread() const;

  bool ConsolidateHandles();

  bool FlushOps();

  FML_DISALLOW_COPY_AND_ASSIGN(ReactorGLES);
};

}  // namespace impeller
