// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include <cmath>
#include <memory>
#include <vector>

#include "flutter/fml/mapping.h"
#include "flutter/testing/testing.h"
#include "impeller/core/formats.h"
#include "impeller/geometry/color.h"
#include "impeller/geometry/constants.h"
#include "impeller/geometry/matrix.h"
#include "impeller/geometry/quaternion.h"
#include "impeller/geometry/vector.h"
#include "impeller/image/decompressed_image.h"
#include "impeller/playground/playground.h"
#include "impeller/playground/playground_test.h"
#include "impeller/scene/animation/animation_clip.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/geometry.h"
#include "impeller/scene/importer/scene_flatbuffers.h"
#include "impeller/scene/material.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/scene.h"
#include "third_party/flatbuffers/include/flatbuffers/verifier.h"
#include "third_party/imgui/imgui.h"

namespace impeller {
namespace scene {
namespace testing {

using SceneTest = PlaygroundTest;
INSTANTIATE_PLAYGROUND_SUITE(SceneTest);

TEST_P(SceneTest, CuboidUnlit) {
  auto scene_context = std::make_shared<SceneContext>(GetContext());

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    auto allocator = GetContext()->GetResourceAllocator();
    auto scene = Scene(scene_context);

    {
      Mesh mesh;

      auto material = Material::MakeUnlit();
      material->SetColor(Color::Red());

      Vector3 size(1, 1, 0);
      mesh.AddPrimitive({Geometry::MakeCuboid(size), std::move(material)});

      Node& root = scene.GetRoot();
      root.SetLocalTransform(Matrix::MakeTranslation(-size / 2));
      root.SetMesh(std::move(mesh));
    }

    // Face towards the +Z direction (+X right, +Y up).
    auto camera = Camera::MakePerspective(
                      /* fov */ Radians(kPiOver4),
                      /* position */ {2, 2, -5})
                      .LookAt(
                          /* target */ Vector3(),
                          /* up */ {0, 1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

TEST_P(SceneTest, FlutterLogo) {
  auto allocator = GetContext()->GetResourceAllocator();

  auto mapping =
      flutter::testing::OpenFixtureAsMapping("flutter_logo_baked.glb.ipscene");
  ASSERT_NE(mapping, nullptr);

  flatbuffers::Verifier verifier(mapping->GetMapping(), mapping->GetSize());
  ASSERT_TRUE(fb::VerifySceneBuffer(verifier));

  std::shared_ptr<Node> gltf_scene =
      Node::MakeFromFlatbuffer(*mapping, *allocator);
  ASSERT_NE(gltf_scene, nullptr);
  ASSERT_EQ(gltf_scene->GetChildren().size(), 1u);
  ASSERT_EQ(gltf_scene->GetChildren()[0]->GetMesh().GetPrimitives().size(), 1u);

  auto scene_context = std::make_shared<SceneContext>(GetContext());
  auto scene = Scene(scene_context);
  scene.GetRoot().AddChild(std::move(gltf_scene));
  scene.GetRoot().SetLocalTransform(Matrix::MakeScale({3, 3, 3}));

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    Quaternion rotation({0, 1, 0}, -GetSecondsElapsed() * 0.5);
    Vector3 start_position(-1, -1.5, -5);

    // Face towards the +Z direction (+X right, +Y up).
    auto camera = Camera::MakePerspective(
                      /* fov */ Degrees(60),
                      /* position */ rotation * start_position)
                      .LookAt(
                          /* target */ Vector3(),
                          /* up */ {0, 1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

TEST_P(SceneTest, TwoTriangles) {
  if (GetBackend() == PlaygroundBackend::kVulkan) {
    GTEST_SKIP_("Temporarily disabled.");
  }
  auto allocator = GetContext()->GetResourceAllocator();

  auto mapping =
      flutter::testing::OpenFixtureAsMapping("two_triangles.glb.ipscene");
  ASSERT_NE(mapping, nullptr);

  std::shared_ptr<Node> gltf_scene =
      Node::MakeFromFlatbuffer(*mapping, *allocator);
  ASSERT_NE(gltf_scene, nullptr);

  auto animation = gltf_scene->FindAnimationByName("Metronome");
  ASSERT_NE(animation, nullptr);

  AnimationClip* metronome_clip = gltf_scene->AddAnimation(animation);
  ASSERT_NE(metronome_clip, nullptr);
  metronome_clip->SetLoop(true);
  metronome_clip->Play();

  auto scene_context = std::make_shared<SceneContext>(GetContext());
  auto scene = Scene(scene_context);
  scene.GetRoot().AddChild(std::move(gltf_scene));

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      static Scalar playback_time_scale = 1;
      static Scalar weight = 1;
      static bool loop = true;

      ImGui::SliderFloat("Playback time scale", &playback_time_scale, -5, 5);
      ImGui::SliderFloat("Weight", &weight, -2, 2);
      ImGui::Checkbox("Loop", &loop);
      if (ImGui::Button("Play")) {
        metronome_clip->Play();
      }
      if (ImGui::Button("Pause")) {
        metronome_clip->Pause();
      }
      if (ImGui::Button("Stop")) {
        metronome_clip->Stop();
      }

      metronome_clip->SetPlaybackTimeScale(playback_time_scale);
      metronome_clip->SetWeight(weight);
      metronome_clip->SetLoop(loop);
    }

    ImGui::End();
    Node& node = *scene.GetRoot().GetChildren()[0];
    node.SetLocalTransform(node.GetLocalTransform() *
                           Matrix::MakeRotation(0.02, {0, 1, 0, 0}));

    static ImVec2 mouse_pos_prev = ImGui::GetMousePos();
    ImVec2 mouse_pos = ImGui::GetMousePos();
    Vector2 mouse_diff =
        Vector2(mouse_pos.x - mouse_pos_prev.x, mouse_pos.y - mouse_pos_prev.y);

    static Vector3 position(0, 1, -5);
    static Vector3 cam_position = position;
    auto strafe =
        Vector3(ImGui::IsKeyDown(ImGuiKey_D) - ImGui::IsKeyDown(ImGuiKey_A),
                ImGui::IsKeyDown(ImGuiKey_E) - ImGui::IsKeyDown(ImGuiKey_Q),
                ImGui::IsKeyDown(ImGuiKey_W) - ImGui::IsKeyDown(ImGuiKey_S));
    position += strafe * 0.5;
    cam_position = cam_position.Lerp(position, 0.02);

    // Face towards the +Z direction (+X right, +Y up).
    auto camera = Camera::MakePerspective(
                      /* fov */ Degrees(60),
                      /* position */ cam_position)
                      .LookAt(
                          /* target */ cam_position + Vector3(0, 0, 1),
                          /* up */ {0, 1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

TEST_P(SceneTest, Dash) {
  auto allocator = GetContext()->GetResourceAllocator();

  auto mapping = flutter::testing::OpenFixtureAsMapping("dash.glb.ipscene");
  if (!mapping) {
    // TODO(bdero): Just skip this playground is the dash asset isn't found. I
    //              haven't checked it in because it's way too big right now,
    //              but this is still useful to keep around for debugging
    //              purposes.
    return;
  }
  ASSERT_NE(mapping, nullptr);

  std::shared_ptr<Node> gltf_scene =
      Node::MakeFromFlatbuffer(*mapping, *allocator);
  ASSERT_NE(gltf_scene, nullptr);

  auto walk_anim = gltf_scene->FindAnimationByName("Walk");
  ASSERT_NE(walk_anim, nullptr);

  AnimationClip* walk_clip = gltf_scene->AddAnimation(walk_anim);
  ASSERT_NE(walk_clip, nullptr);
  walk_clip->SetLoop(true);
  walk_clip->Play();

  auto run_anim = gltf_scene->FindAnimationByName("Run");
  ASSERT_NE(walk_anim, nullptr);

  AnimationClip* run_clip = gltf_scene->AddAnimation(run_anim);
  ASSERT_NE(run_clip, nullptr);
  run_clip->SetLoop(true);
  run_clip->Play();

  auto scene_context = std::make_shared<SceneContext>(GetContext());
  auto scene = Scene(scene_context);
  scene.GetRoot().AddChild(std::move(gltf_scene));

  Renderer::RenderCallback callback = [&](RenderTarget& render_target) {
    ImGui::Begin("Controls", nullptr, ImGuiWindowFlags_AlwaysAutoResize);
    {
      static Scalar playback_time_scale = 1;
      static Scalar walk = 0.5;
      static Scalar run = 0.5;
      static bool loop = true;

      ImGui::SliderFloat("Playback time scale", &playback_time_scale, -5, 5);
      ImGui::SliderFloat("Walk weight", &walk, 0, 1);
      ImGui::SliderFloat("Run weight", &run, 0, 1);
      ImGui::Checkbox("Loop", &loop);
      if (ImGui::Button("Play")) {
        walk_clip->Play();
        run_clip->Play();
      }
      if (ImGui::Button("Pause")) {
        walk_clip->Pause();
        run_clip->Pause();
      }
      if (ImGui::Button("Stop")) {
        walk_clip->Stop();
        run_clip->Stop();
      }

      walk_clip->SetPlaybackTimeScale(playback_time_scale);
      walk_clip->SetWeight(walk);
      walk_clip->SetLoop(loop);

      run_clip->SetPlaybackTimeScale(playback_time_scale);
      run_clip->SetWeight(run);
      run_clip->SetLoop(loop);
    }

    ImGui::End();
    Node& node = *scene.GetRoot().GetChildren()[0];
    node.SetLocalTransform(node.GetLocalTransform() *
                           Matrix::MakeRotation(0.02, {0, 1, 0, 0}));

    static ImVec2 mouse_pos_prev = ImGui::GetMousePos();
    ImVec2 mouse_pos = ImGui::GetMousePos();
    Vector2 mouse_diff =
        Vector2(mouse_pos.x - mouse_pos_prev.x, mouse_pos.y - mouse_pos_prev.y);

    static Vector3 position(0, 1, -5);
    static Vector3 cam_position = position;
    auto strafe =
        Vector3(ImGui::IsKeyDown(ImGuiKey_D) - ImGui::IsKeyDown(ImGuiKey_A),
                ImGui::IsKeyDown(ImGuiKey_E) - ImGui::IsKeyDown(ImGuiKey_Q),
                ImGui::IsKeyDown(ImGuiKey_W) - ImGui::IsKeyDown(ImGuiKey_S));
    position += strafe * 0.5;
    cam_position = cam_position.Lerp(position, 0.02);

    // Face towards the +Z direction (+X right, +Y up).
    auto camera = Camera::MakePerspective(
                      /* fov */ Degrees(60),
                      /* position */ cam_position)
                      .LookAt(
                          /* target */ cam_position + Vector3(0, 0, 1),
                          /* up */ {0, 1, 0});

    scene.Render(render_target, camera);
    return true;
  };

  OpenPlaygroundHere(callback);
}

}  // namespace testing
}  // namespace scene
}  // namespace impeller
