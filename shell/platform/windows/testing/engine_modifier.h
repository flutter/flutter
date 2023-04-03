// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_ENGINE_MODIFIER_H_
#define FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_ENGINE_MODIFIER_H_

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

#include <chrono>

#include "flutter/fml/macros.h"

namespace flutter {

// A test utility class providing the ability to access and alter various
// private fields in an Engine instance.
//
// This simply provides a way to access the normally-private embedder proc
// table, so the lifetime of any changes made to the proc table is that of the
// engine object, not this helper.
class EngineModifier {
 public:
  explicit EngineModifier(FlutterWindowsEngine* engine) : engine_(engine) {}

  // Returns the engine's embedder API proc table, allowing for modification.
  //
  // Modifications are to the engine, and will last for the lifetime of the
  // engine unless overwritten again.
  FlutterEngineProcTable& embedder_api() { return engine_->embedder_api_; }

  // Explicitly sets the SurfaceManager being used by the FlutterWindowsEngine
  // instance. This allows us to test fallback paths when a SurfaceManager fails
  // to initialize for whatever reason.
  //
  // Modifications are to the engine, and will last for the lifetime of the
  // engine unless overwritten again.
  void SetSurfaceManager(AngleSurfaceManager* surface_manager) {
    engine_->surface_manager_.reset(surface_manager);
  }

  /// Reset the start_time field that is used to align vsync events.
  void SetStartTime(uint64_t start_time_nanos) {
    engine_->start_time_ = std::chrono::nanoseconds(start_time_nanos);
  }

  /// Override the frame interval to the provided nanosecond interval.
  ///
  /// This will prevent the windows engine from delegating to dwm to
  /// discover the true frame interval, which can vary across machines.
  void SetFrameInterval(uint64_t frame_interval_nanos) {
    engine_->frame_interval_override_ =
        std::optional<std::chrono::nanoseconds>(frame_interval_nanos);
  }

  // Explicitly releases the SurfaceManager being used by the
  // FlutterWindowsEngine instance. This should be used if SetSurfaceManager is
  // used to explicitly set to a non-null value (but not a valid object) to test
  // a successful ANGLE initialization.
  //
  // Modifications are to the engine, and will last for the lifetime of the
  // engine unless overwritten again.
  void ReleaseSurfaceManager() { engine_->surface_manager_.release(); }

  // Run the FlutterWindowsEngine's handler that runs right before an engine
  // restart. This resets the keyboard's state if it exists.
  void Restart() { engine_->OnPreEngineRestart(); }

  void SetLifecycleManager(std::unique_ptr<WindowsLifecycleManager>&& handler) {
    engine_->lifecycle_manager_ = std::move(handler);
  }

 private:
  FlutterWindowsEngine* engine_;

  FML_DISALLOW_COPY_AND_ASSIGN(EngineModifier);
};

}  // namespace flutter

#endif  // FLUTTER_SHELL_PLATFORM_WINDOWS_TESTING_ENGINE_MODIFIER_H_
