// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_REACTOR_GLES_H_
#define FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_REACTOR_GLES_H_

#include <functional>
#include <memory>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/renderer/backend/gles/handle_gles.h"
#include "impeller/renderer/backend/gles/proc_table_gles.h"

namespace impeller {

//------------------------------------------------------------------------------
/// @brief      The reactor attempts to make thread-safe usage of OpenGL ES
///             easier to reason about.
///
///             In the other Impeller backends (like Metal and Vulkan),
///             resources can be created, used, and deleted on any thread with
///             relatively few restrictions. However, OpenGL resources can only
///             be created, used, and deleted on a thread on which an OpenGL
///             context (or one in the same sharegroup) is current.
///
///             There aren't too many OpenGL contexts to go around and making
///             the caller reason about the timing and threading requirement
///             only when the OpenGL backend is in use is tedious. To work
///             around this tedium, there is an abstraction between the
///             resources and their handles in OpenGL. The reactor is this
///             abstraction.
///
///             The reactor is thread-safe and can created, used, and collected
///             on any thread.
///
///             Reactor handles `HandleGLES` can be created, used, and collected
///             on any thread. These handles can be to textures, buffers, etc..
///
///             Operations added to the reactor are guaranteed to run on a
///             worker within a finite amount of time unless the reactor itself
///             is torn down or there are no workers. These operations may run
///             on the calling thread immediately if a worker is active on the
///             current thread and can perform reactions. The operations are
///             guaranteed to run with an OpenGL context current and all reactor
///             handles having live OpenGL handle counterparts.
///
///             Creating a handle in the reactor doesn't mean an OpenGL handle
///             is created immediately. OpenGL handles become live before the
///             next reaction. Similarly, dropping the last reference to a
///             reactor handle means that the OpenGL handle will be deleted at
///             some point in the near future.
///
class ReactorGLES {
 public:
  using WorkerID = UniqueID;

  //----------------------------------------------------------------------------
  /// @brief      A delegate implemented by a thread on which an OpenGL context
  ///             is current. There may be multiple workers for the reactor to
  ///             perform reactions on. In that case, it is the workers
  ///             responsibility to ensure that all of them use either the same
  ///             OpenGL context or multiple OpenGL contexts in the same
  ///             sharegroup.
  ///
  class Worker {
   public:
    virtual ~Worker() = default;

    //--------------------------------------------------------------------------
    /// @brief      Determines the ability of the worker to service a reaction
    ///             on the current thread. The OpenGL context must be current on
    ///             the thread if the worker says it is able to service a
    ///             reaction.
    ///
    /// @param[in]  reactor  The reactor
    ///
    /// @return     If the worker is able to service a reaction. The reactor
    ///             assumes the context is already current if true.
    ///
    virtual bool CanReactorReactOnCurrentThreadNow(
        const ReactorGLES& reactor) const = 0;
  };

  using Ref = std::shared_ptr<ReactorGLES>;

  //----------------------------------------------------------------------------
  /// @brief      Create a new reactor. There are expensive and only one per
  ///             application instance is necessary.
  ///
  /// @param[in]  gl    The proc table for GL access. This is necessary for the
  ///                   reactor to be able to create and collect OpenGL handles.
  ///
  explicit ReactorGLES(std::unique_ptr<ProcTableGLES> gl);

  //----------------------------------------------------------------------------
  /// @brief      Destroy a reactor.
  ///
  ~ReactorGLES();

  //----------------------------------------------------------------------------
  /// @brief      If this is a valid reactor. Invalid reactors must be discarded
  ///             immediately.
  ///
  /// @return     If this reactor is valid.
  ///
  bool IsValid() const;

  //----------------------------------------------------------------------------
  /// @brief      Adds a worker to the reactor. Each new worker must ensure that
  ///             the context it manages is the same as the other workers in the
  ///             reactor or in the same sharegroup.
  ///
  /// @param[in]  worker  The worker
  ///
  /// @return     The worker identifier. This identifier can be used to remove
  ///             the worker from the reactor later.
  ///
  WorkerID AddWorker(std::weak_ptr<Worker> worker);

  //----------------------------------------------------------------------------
  /// @brief      Remove a previously added worker from the reactor. If the
  ///             reactor has no workers, pending added operations will never
  ///             run.
  ///
  /// @param[in]  id  The worker identifier previously returned by `AddWorker`.
  ///
  /// @return     If a worker with the given identifer was successfully removed
  ///             from the reactor.
  ///
  bool RemoveWorker(WorkerID id);

  //----------------------------------------------------------------------------
  /// @brief      Get the OpenGL proc. table the reactor uses to manage handles.
  ///
  /// @return     The proc table.
  ///
  const ProcTableGLES& GetProcTable() const;

  //----------------------------------------------------------------------------
  /// @brief      Returns the OpenGL handle for a reactor handle if one is
  ///             available. This is typically only safe to call within a
  ///             reaction. That is, within a `ReactorGLES::Operation`.
  ///
  ///             Asking for the OpenGL handle before the reactor has a chance
  ///             to reactor will return `std::nullopt`.
  ///
  ///             This can be called on any thread but is typically useless
  ///             outside of a reaction since the handle is useless outside of a
  ///             reactor operation.
  ///
  /// @param[in]  handle  The reactor handle.
  ///
  /// @return     The OpenGL handle if the reactor has had a chance to react.
  ///             `std::nullopt` otherwise.
  ///
  std::optional<GLuint> GetGLHandle(const HandleGLES& handle) const;

  //----------------------------------------------------------------------------
  /// @brief      Create a reactor handle.
  ///
  ///             This can be called on any thread. Even one that doesn't have
  ///             an OpenGL context.
  ///
  /// @param[in]  type  The type of handle to create.
  ///
  /// @return     The reactor handle.
  ///
  HandleGLES CreateHandle(HandleType type);

  //----------------------------------------------------------------------------
  /// @brief      Collect a reactor handle.
  ///
  ///             This can be called on any thread. Even one that doesn't have
  ///             an OpenGL context.
  ///
  /// @param[in]  handle  The reactor handle handle
  ///
  void CollectHandle(HandleGLES handle);

  //----------------------------------------------------------------------------
  /// @brief      Set the debug label on a reactor handle.
  ///
  ///             This call ensures that the OpenGL debug label is propagated to
  ///             even the OpenGL handle hasn't been created at the time the
  ///             caller sets the label.
  ///
  /// @param[in]  handle  The handle
  /// @param[in]  label   The label
  ///
  void SetDebugLabel(const HandleGLES& handle, std::string label);

  using Operation = std::function<void(const ReactorGLES& reactor)>;

  //----------------------------------------------------------------------------
  /// @brief      Adds an operation that the reactor runs on a worker that
  ///             ensures that an OpenGL context is current.
  ///
  ///             This operation is not guaranteed to run immediately. It will
  ///             complete in a finite amount of time on any thread as long as
  ///             there is a reactor worker and the reactor itself is not being
  ///             torn down.
  ///
  /// @param[in]  operation  The operation
  ///
  /// @return     If the operation was successfully queued for completion.
  ///
  [[nodiscard]] bool AddOperation(Operation operation);

  //----------------------------------------------------------------------------
  /// @brief      Perform a reaction on the current thread if able.
  ///
  ///             It is safe to call this simultaneously from multiple threads
  ///             at the same time.
  ///
  /// @return     If a reaction was performed on the calling thread.
  ///
  [[nodiscard]] bool React();

 private:
  struct LiveHandle {
    std::optional<GLuint> name;
    std::optional<std::string> pending_debug_label;
    bool pending_collection = false;

    LiveHandle() = default;

    explicit LiveHandle(std::optional<GLuint> p_name) : name(p_name) {}

    constexpr bool IsLive() const { return name.has_value(); }
  };

  std::unique_ptr<ProcTableGLES> proc_table_;

  Mutex ops_execution_mutex_;
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
  mutable std::map<WorkerID, std::weak_ptr<Worker>> workers_ IPLR_GUARDED_BY(
      workers_mutex_);

  bool can_set_debug_labels_ = false;
  bool is_valid_ = false;

  bool ReactOnce() IPLR_REQUIRES(ops_execution_mutex_);

  bool HasPendingOperations() const;

  bool CanReactOnCurrentThread() const;

  bool ConsolidateHandles();

  bool FlushOps();

  void SetupDebugGroups();

  ReactorGLES(const ReactorGLES&) = delete;

  ReactorGLES& operator=(const ReactorGLES&) = delete;
};

}  // namespace impeller

#endif  // FLUTTER_IMPELLER_RENDERER_BACKEND_GLES_REACTOR_GLES_H_
