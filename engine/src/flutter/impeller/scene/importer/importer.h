// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <array>
#include <memory>

#include "flutter/fml/mapping.h"
#include "impeller/scene/importer/scene_flatbuffers.h"

namespace impeller {
namespace scene {
namespace importer {

bool ParseGLTF(const fml::Mapping& source_mapping, fb::SceneT& out_scene);

}
}  // namespace scene
}  // namespace impeller
