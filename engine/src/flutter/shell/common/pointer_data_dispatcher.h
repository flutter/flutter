// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_COMMON_POINTER_DATA_DISPATCHER_H_
#define FLUTTER_SHELL_COMMON_POINTER_DATA_DISPATCHER_H_

#include "flutter/runtime/runtime_controller.h"
#include "flutter/shell/common/animator.h"

namespace flutter {

class PointerDataDispatcher;

//------------------------------------------------------------------------------
/// The `Engine` pointer data dispatcher that forwards the packet received from
/// `PlatformView::DispatchPointerDataPacket` on the platform thread, to
/// `Window::DispatchPointerDataPacket` on the UI thread.
///
/// This object will be owned by the engine because it relies on the engine's
/// `Animator` (which owns `VsyncWaiter`) and `RuntimeController` to do the
/// filtering. This object is currently designed to be only called from the UI
/// thread (no thread safety is guaranteed).
///
/// The `PlatformView` decides which subclass of `PointerDataDispatcher` is
/// constructed by sending a `PointerDataDispatcherMaker` to the engine's
/// constructor in `Shell::CreateShellOnPlatformThread`. This is needed because:
///   (1) Different platforms (e.g., Android, iOS) have different dispatchers
///       so the decision has to be made per `PlatformView`.
///   (2) The `PlatformView` can only be accessed from the PlatformThread while
///       this class (as owned by engine) can only be accessed in the UI thread.
///       Hence `PlatformView` creates a `PointerDataDispatchMaker` on the
///       platform thread, and sends it to the UI thread for the final
///       construction of the `PointerDataDispatcher`.
class PointerDataDispatcher {
 public:
  /// The interface for Engine to implement.
  class Delegate {
   public:
    /// Actually dispatch the packet using Engine's `animator_` and
    /// `runtime_controller_`.
    virtual void DoDispatchPacket(std::unique_ptr<PointerDataPacket> packet,
                                  uint64_t trace_flow_id) = 0;
  };

  //----------------------------------------------------------------------------
  /// @brief      Signal that `PlatformView` has a packet to be dispatched.
  ///
  /// @param[in]  packet             The `PointerDataPacket` to be dispatched.
  /// @param[in]  trace_flow_id      The id for `Animator::EnqueueTraceFlowId`.
  virtual void DispatchPacket(std::unique_ptr<PointerDataPacket> packet,
                              uint64_t trace_flow_id) = 0;

  //----------------------------------------------------------------------------
  /// @brief      Default destructor.
  virtual ~PointerDataDispatcher();
};

//------------------------------------------------------------------------------
/// The default dispatcher that forwards the packet without any modification.
///
class DefaultPointerDataDispatcher : public PointerDataDispatcher {
 public:
  explicit DefaultPointerDataDispatcher(Delegate& delegate)
      : delegate_(delegate) {}

  // |PointerDataDispatcer|
  void DispatchPacket(std::unique_ptr<PointerDataPacket> packet,
                      uint64_t trace_flow_id) override;

  virtual ~DefaultPointerDataDispatcher();

 protected:
  Delegate& delegate_;

  FML_DISALLOW_COPY_AND_ASSIGN(DefaultPointerDataDispatcher);
};

//--------------------------------------------------------------------------
/// @brief      Signature for constructing PointerDataDispatcher.
///
/// @param[in]  delegate      the `Flutter::Engine`
///
using PointerDataDispatcherMaker =
    std::function<std::unique_ptr<PointerDataDispatcher>(
        PointerDataDispatcher::Delegate&)>;

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_POINTER_DATA_DISPATCHER_H_
