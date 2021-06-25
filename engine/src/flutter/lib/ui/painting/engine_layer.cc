// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/lib/ui/painting/engine_layer.h"

#include "flutter/lib/ui/ui_dart_state.h"
#include "third_party/tonic/converter/dart_converter.h"
#include "third_party/tonic/dart_args.h"
#include "third_party/tonic/dart_binding_macros.h"
#include "third_party/tonic/dart_library_natives.h"

using tonic::ToDart;

namespace flutter {

IMPLEMENT_WRAPPERTYPEINFO(ui, EngineLayer);

#define FOR_EACH_BINDING(V) V(EngineLayer, dispose)

DART_BIND_ALL(EngineLayer, FOR_EACH_BINDING)

EngineLayer::EngineLayer(std::shared_ptr<flutter::ContainerLayer> layer)
    : layer_(layer) {}

EngineLayer::~EngineLayer() = default;

void EngineLayer::dispose() {
  layer_.reset();
  ClearDartWrapper();
}

}  // namespace flutter
