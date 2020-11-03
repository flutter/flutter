// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/windows/flutter_windows_engine.h"

namespace flutter {

// A test utility class providing the ability to access and alter the embedder
// API proc table for an engine instance.
//
// This simply provides a way to access the normally-private embedder proc
// table, so the lifetime of any changes made to the proc table is that of the
// engine object, not this helper.
class EngineEmbedderApiModifier {
 public:
  explicit EngineEmbedderApiModifier(FlutterWindowsEngine* engine)
      : engine_(engine) {}

  // Returns the engine's embedder API proc table, allowing for modification.
  //
  // Modifications are to the engine, and will last for the lifetime of the
  // engine unless overwritten again.
  FlutterEngineProcTable& embedder_api() { return engine_->embedder_api_; }

 private:
  FlutterWindowsEngine* engine_;
};

}  // namespace flutter
