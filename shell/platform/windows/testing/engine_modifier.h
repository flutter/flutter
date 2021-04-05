// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

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

  // Explicitly releases the SurfaceManager being used by the
  // FlutterWindowsEngine instance. This should be used if SetSurfaceManager is
  // used to explicitly set to a non-null value (but not a valid object) to test
  // a successful ANGLE initialization.
  //
  // Modifications are to the engine, and will last for the lifetime of the
  // engine unless overwritten again.
  void ReleaseSurfaceManager() { engine_->surface_manager_.release(); }

 private:
  FlutterWindowsEngine* engine_;
};

}  // namespace flutter
