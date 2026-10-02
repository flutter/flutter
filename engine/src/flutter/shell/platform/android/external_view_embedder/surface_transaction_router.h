// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_TRANSACTION_ROUTER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_TRANSACTION_ROUTER_H_

#include <atomic>
#include <cstdint>

#include "flutter/fml/macros.h"

namespace flutter {

//------------------------------------------------------------------------------
/// @brief      Decides, per frame, how the SurfaceControl transactions of the
///             HC++ swapchain reach SurfaceFlinger, and remembers which
///             platform-routed frames SurfaceFlinger has not committed yet.
///
///             A swapchain buffer is presented by applying a transaction.
///             There are two ways to do that:
///
///             - |Route::kDirect|: the raster thread owns the transaction and
///               applies it itself as soon as the frame is submitted.
///             - |Route::kPlatform|: the transaction is created by Java
///               (PlatformViewsController2.createTransaction) and merged with
///               the platform view mutations of the same frame on the platform
///               thread, which hands the merged transaction to ViewRootImpl
///               (AttachedSurfaceControl.applyTransactionOnDraw) so that it is
///               applied together with the next View hierarchy draw.
///
///             The two routes apply with different apply tokens, so
///             SurfaceFlinger does not order them with respect to each other.
///             A direct frame could therefore overtake a platform frame that
///             is still waiting for its View draw, and the older buffer would
///             be shown after the newer one. To prevent that, the view
///             embedder keeps routing frames through the platform thread for
///             as long as |HasUncommittedPlatformFrames| is true.
///
///             Only the raster thread selects the route. The uncommitted frame
///             count is modified from the raster thread (submission) and the
///             platform thread (commit), and is therefore atomic.
///
class SurfaceTransactionRouter {
 public:
  enum class Route {
    kDirect,
    kPlatform,
  };

  SurfaceTransactionRouter();

  ~SurfaceTransactionRouter();

  //----------------------------------------------------------------------------
  /// @brief      Selects the route of the frame that is being submitted. The
  ///             route stays in effect until it is set again, so the caller
  ///             must restore |Route::kDirect| when the submission is over.
  ///
  /// @note       Raster thread only.
  ///
  void SetFrameRoute(Route route);

  //----------------------------------------------------------------------------
  /// @brief      The route of the frame that is being submitted. Read by the
  ///             swapchain when it creates the transaction that presents a
  ///             buffer.
  ///
  /// @note       Raster thread only.
  ///
  Route GetFrameRoute() const;

  //----------------------------------------------------------------------------
  /// @brief      Records that a frame was handed to the platform thread.
  ///
  /// @note       Thread safe.
  ///
  void OnPlatformFrameSubmitted();

  //----------------------------------------------------------------------------
  /// @brief      Records that SurfaceFlinger committed a platform-routed
  ///             frame, or that the frame was dropped without ever being
  ///             applied. Calls that are not matched by an earlier
  ///             |OnPlatformFrameSubmitted| are ignored.
  ///
  /// @note       Thread safe.
  ///
  void OnPlatformFrameCommitted();

  //----------------------------------------------------------------------------
  /// @brief      Whether any platform-routed frame is still uncommitted.
  ///
  /// @note       Thread safe.
  ///
  bool HasUncommittedPlatformFrames() const;

 private:
  // Raster thread only.
  Route frame_route_ = Route::kDirect;

  std::atomic<int32_t> uncommitted_platform_frames_{0};

  FML_DISALLOW_COPY_AND_ASSIGN(SurfaceTransactionRouter);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_EXTERNAL_VIEW_EMBEDDER_SURFACE_TRANSACTION_ROUTER_H_
