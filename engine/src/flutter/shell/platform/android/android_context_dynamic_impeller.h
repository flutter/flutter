// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_
#define FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_

#include <atomic>
#include <thread>

#include "flutter/fml/macros.h"
#include "flutter/fml/native_library.h"
#include "flutter/fml/synchronization/waitable_event.h"
#include "flutter/shell/platform/android/android_context_gl_impeller.h"
#include "flutter/shell/platform/android/android_context_vk_impeller.h"
#include "flutter/shell/platform/android/context/android_context.h"

namespace flutter {

/// @brief An Impeller Android context that dynamically creates either an
/// [AndroidContextGLImpeller] or an [AndroidContextVKImpeller].
class AndroidContextDynamicImpeller : public AndroidContext {
 public:
  explicit AndroidContextDynamicImpeller(
      const AndroidContext::ContextSettings& settings,
      std::shared_ptr<fml::BasicTaskRunner> io_task_runner);

  ~AndroidContextDynamicImpeller();

  // |AndroidContext|
  bool IsValid() const override { return true; }

  // |AndroidContext|
  bool IsDynamicSelection() const override { return true; }

  /// @brief Returns the selected rendering backend, blocking if the selection
  ///        is still in flight.
  ///
  ///        The backend is chosen lazily by [SetupImpellerContext] on the
  ///        raster thread, which can take 100+ ms while probing for Vulkan.
  ///        Callers on other threads would otherwise observe
  ///        kImpellerAutoselect during early startup, so this blocks until the
  ///        choice is made. Waiting also publishes the raster thread's writes,
  ///        making it safe to then read [GetImpellerContext], [GetGLContext]
  ///        and [GetVKContext] without further synchronization.
  ///
  ///        Once setup has completed this is just an uncontended mutex
  ///        acquisition, so it is not worth avoiding on non-hot paths.
  ///
  /// @attention  Must never be called from the thread that executes
  ///             [SetupImpellerContext] before that setup has completed, as
  ///             the signal being waited on could then never be delivered.
  ///             In practice that is the raster thread, but note it is not
  ///             always a distinct thread: while a |fml::RasterThreadMerger|
  ///             lease is active, raster tasks run on the platform thread.
  ///
  // |AndroidContext|
  AndroidRenderingAPI RenderingApi() const override;

  /// @brief Retrieve the GL Context if it was created, or nullptr.
  ///
  ///        Does not block. Only meaningful after [RenderingApi] has returned.
  std::shared_ptr<AndroidContextGLImpeller> GetGLContext() const;

  /// @brief Retrieve the VK context if it was created, or nullptr.
  ///
  ///        Does not block. Only meaningful after [RenderingApi] has returned.
  std::shared_ptr<AndroidContextVKImpeller> GetVKContext() const;

  // |AndroidContext|
  void SetupImpellerContext() override;

  /// @brief Retrieve the Impeller context, or nullptr if setup has not run.
  ///
  ///        Does not block. Callers on threads other than the raster thread
  ///        should read [RenderingApi] first, which both waits for setup and
  ///        publishes the writes read here.
  ///
  // |AndroidContext|
  std::shared_ptr<impeller::Context> GetImpellerContext() const override;

 private:
  /// @brief Blocks until [SetupImpellerContext] has completed on the raster
  ///        thread. Returns immediately once it has.
  ///
  ///        Debug builds assert that the caller is not the thread running
  ///        setup, which would deadlock. Note the assert can only fire once
  ///        setup has begun; a thread that waits before setup is ever
  ///        scheduled still hangs undiagnosed.
  void WaitForSetup() const;

  const AndroidContext::ContextSettings settings_;
  // These are written once on the raster thread by |SetupImpellerContext| and
  // only read by other threads after |setup_complete_| has been signalled.
  std::shared_ptr<AndroidContextGLImpeller> gl_context_;
  std::shared_ptr<AndroidContextVKImpeller> vk_context_;
  std::shared_ptr<fml::BasicTaskRunner> io_task_runner_;
  // Signalled by |SetupImpellerContext| once a backend has been chosen.
  // Mutable so the const accessors above can wait on it.
  mutable fml::ManualResetWaitableEvent setup_complete_;
#ifdef FML_DCHECK_IS_ON
  // The thread running |SetupImpellerContext|, recorded so |WaitForSetup| can
  // assert it is not being called from that same thread. Atomic because it is
  // read by waiters concurrently with the setup thread writing it.
  std::atomic<std::thread::id> setup_thread_id_;
#endif

  FML_DISALLOW_COPY_AND_ASSIGN(AndroidContextDynamicImpeller);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_ANDROID_ANDROID_CONTEXT_DYNAMIC_IMPELLER_H_
