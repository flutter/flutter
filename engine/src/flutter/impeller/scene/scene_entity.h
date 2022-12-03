// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#pragma once

#include <memory>
#include <vector>

#include "flutter/fml/macros.h"

#include "impeller/geometry/matrix.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/scene_encoder.h"

namespace impeller {
namespace scene {

class StaticMeshEntity;

class SceneEntity {
 public:
  SceneEntity();
  virtual ~SceneEntity();

  static std::shared_ptr<StaticMeshEntity> MakeStaticMesh();

  void SetLocalTransform(Matrix transform);
  Matrix GetLocalTransform() const;

  void SetGlobalTransform(Matrix transform);
  Matrix GetGlobalTransform() const;

  bool Add(const std::shared_ptr<SceneEntity>& child);

  bool Render(SceneEncoder& encoder) const;

 protected:
  Matrix local_transform_;

 private:
  virtual bool OnRender(SceneEncoder& encoder) const;

  SceneEntity* parent_ = nullptr;
  std::vector<std::shared_ptr<SceneEntity>> children_;

  FML_DISALLOW_COPY_AND_ASSIGN(SceneEntity);
};

}  // namespace scene
}  // namespace impeller
