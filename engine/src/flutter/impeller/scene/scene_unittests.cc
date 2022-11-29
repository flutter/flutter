// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/testing/testing.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/vector.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/playground_test.h"

#include "impeller/scene/camera.h"
#include "impeller/scene/geometry.h"
#include "impeller/scene/material.h"
#include "impeller/scene/scene.h"
#include "impeller/scene/static_mesh_entity.h"

// #include "third_party/tinygltf/tiny_gltf.h"

namespace impeller {
namespace scene {
namespace testing {

using SceneTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(SceneTest);

TEST_P(SceneTest, CuboidUnlit) {
  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    auto allocator = GetContext()->GetResourceAllocator();
    auto scene = Scene(GetContext());

    {
      auto mesh = SceneEntity::MakeStaticMesh();

      auto material = Material::MakeUnlit();
      material->SetColor(Color::Red());
      mesh->SetMaterial(std::move(material));

      Vector3 size(1, 2, 3);
      mesh->SetGeometry(Geometry::MakeCuboid(size));

      mesh->SetLocalTransform(Matrix::MakeTranslation(size / 2));

      scene.Add(mesh);
    }

    auto camera = Camera::MakePerspective(
                      /* fov */ kPiOver4,
                      /* position */ {50, -30, 50})
                      .LookAt(
                          /* target */ Vector3(),
                          /* up */ {0, -1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace scene
}  // namespace impeller
