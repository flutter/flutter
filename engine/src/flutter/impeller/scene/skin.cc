// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "impeller/scene/skin.h"

#include <cmath>
#include <memory>
#include <vector>

#include "flutter/fml/logging.h"
#include "impeller/base/allocation.h"
#include "impeller/core/allocator.h"
#include "impeller/scene/importer/conversions.h"

namespace impeller {
namespace scene {

std::unique_ptr<Skin> Skin::MakeFromFlatbuffer(
    const fb::Skin& skin,
    const std::vector<std::shared_ptr<Node>>& scene_nodes) {
  if (!skin.joints() || !skin.inverse_bind_matrices() ||
      skin.joints()->size() != skin.inverse_bind_matrices()->size()) {
    VALIDATION_LOG << "Skin data is missing joints or bind matrices.";
    return nullptr;
  }

  Skin result;

  result.joints_.reserve(skin.joints()->size());
  for (auto joint : *skin.joints()) {
    if (joint < 0 || static_cast<size_t>(joint) > scene_nodes.size()) {
      VALIDATION_LOG << "Skin joint index out of range.";
      result.joints_.push_back(nullptr);
      continue;
    }
    if (scene_nodes[joint]) {
      scene_nodes[joint]->SetIsJoint(true);
    }
    result.joints_.push_back(scene_nodes[joint]);
  }

  result.inverse_bind_matrices_.reserve(skin.inverse_bind_matrices()->size());
  for (size_t matrix_i = 0; matrix_i < skin.inverse_bind_matrices()->size();
       matrix_i++) {
    const auto* ip_matrix = skin.inverse_bind_matrices()->Get(matrix_i);
    Matrix matrix = ip_matrix ? importer::ToMatrix(*ip_matrix) : Matrix();

    result.inverse_bind_matrices_.push_back(matrix);
    // Overwrite the joint transforms with the inverse bind pose.
    result.joints_[matrix_i]->SetGlobalTransform(matrix.Invert());
  }

  return std::make_unique<Skin>(std::move(result));
}

Skin::Skin() = default;

Skin::~Skin() = default;

Skin::Skin(Skin&&) = default;

Skin& Skin::operator=(Skin&&) = default;

std::shared_ptr<Texture> Skin::GetJointsTexture(Allocator& allocator) {
  // Each joint has a matrix. 1 matrix = 16 floats. 1 pixel = 4 floats.
  // Therefore, each joint needs 4 pixels.
  auto required_pixels = joints_.size() * 4;
  auto dimension_size = std::max(
      2u,
      Allocation::NextPowerOfTwoSize(std::ceil(std::sqrt(required_pixels))));

  impeller::TextureDescriptor texture_descriptor;
  texture_descriptor.storage_mode = impeller::StorageMode::kHostVisible;
  texture_descriptor.format = PixelFormat::kR32G32B32A32Float;
  texture_descriptor.size = {dimension_size, dimension_size};
  texture_descriptor.mip_count = 1u;

  auto result = allocator.CreateTexture(texture_descriptor);
  result->SetLabel("Joints Texture");
  if (!result) {
    FML_LOG(ERROR) << "Could not create joint texture.";
    return nullptr;
  }

  std::vector<Matrix> joints;
  joints.resize(result->GetSize().Area() / 4, Matrix());
  FML_DCHECK(joints.size() >= joints_.size());
  for (size_t joint_i = 0; joint_i < joints_.size(); joint_i++) {
    const Node* joint = joints_[joint_i].get();
    if (!joint) {
      // When a joint is missing, just let it remain as an identity matrix.
      continue;
    }

    // Compute a model space matrix for the joint by walking up the bones to the
    // skeleton root.
    while (joint && joint->IsJoint()) {
      joints[joint_i] = joint->GetLocalTransform() * joints[joint_i];
      joint = joint->GetParent();
    }

    // Get the joint transform relative to the default pose of the bone by
    // incorporating the joint's inverse bind matrix. The inverse bind matrix
    // transforms from model space to the default pose space of the joint. The
    // result is a model space matrix that only captures the difference between
    // the joint's default pose and the joint's current pose in the scene. This
    // is necessary because the skinned model's vertex positions (which _define_
    // the default pose) are all in model space.
    joints[joint_i] = joints[joint_i] * inverse_bind_matrices_[joint_i];
  }

  if (!result->SetContents(reinterpret_cast<uint8_t*>(joints.data()),
                           joints.size() * sizeof(Matrix))) {
    FML_LOG(ERROR) << "Could not set contents of joint texture.";
    return nullptr;
  }

  return result;
}

}  // namespace scene
}  // namespace impeller
