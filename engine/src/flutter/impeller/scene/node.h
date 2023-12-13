// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_IMPELLER_SCENE_NODE_H_
#define FLUTTER_IMPELLER_SCENE_NODE_H_

#include <memory>
#include <mutex>
#include <optional>
#include <vector>

#include "flutter/fml/macros.h"
#include "impeller/base/thread.h"
#include "impeller/base/thread_safety.h"
#include "impeller/core/texture.h"
#include "impeller/geometry/matrix.h"
#include "impeller/renderer/render_target.h"
#include "impeller/scene/animation/animation.h"
#include "impeller/scene/animation/animation_clip.h"
#include "impeller/scene/animation/animation_player.h"
#include "impeller/scene/camera.h"
#include "impeller/scene/mesh.h"
#include "impeller/scene/scene_encoder.h"
#include "impeller/scene/skin.h"

namespace impeller {
namespace scene {

class Node final {
 public:
  class MutationLog {
   public:
    struct SetTransformEntry {
      Matrix transform;
    };

    struct SetAnimationStateEntry {
      std::string animation_name;
      bool playing = false;
      bool loop = false;
      Scalar weight = 0;
      Scalar time_scale = 1;
    };

    struct SeekAnimationEntry {
      std::string animation_name;
      float time = 0;
    };

    using Entry = std::
        variant<SetTransformEntry, SetAnimationStateEntry, SeekAnimationEntry>;

    void Append(const Entry& entry);

   private:
    std::optional<std::vector<Entry>> Flush();

    RWMutex write_mutex_;
    bool dirty_ IPLR_GUARDED_BY(write_mutex_) = false;
    std::vector<Entry> entries_ IPLR_GUARDED_BY(write_mutex_);

    friend Node;
  };

  static std::shared_ptr<Node> MakeFromFlatbuffer(
      const fml::Mapping& ipscene_mapping,
      Allocator& allocator);
  static std::shared_ptr<Node> MakeFromFlatbuffer(const fb::Scene& scene,
                                                  Allocator& allocator);

  Node();
  ~Node();

  const std::string& GetName() const;
  void SetName(const std::string& new_name);

  Node* GetParent() const;

  std::shared_ptr<Node> FindChildByName(
      const std::string& name,
      bool exclude_animation_players = false) const;

  std::shared_ptr<Animation> FindAnimationByName(const std::string& name) const;
  AnimationClip* AddAnimation(const std::shared_ptr<Animation>& animation);

  void SetLocalTransform(Matrix transform);
  Matrix GetLocalTransform() const;

  void SetGlobalTransform(Matrix transform);
  Matrix GetGlobalTransform() const;

  bool AddChild(std::shared_ptr<Node> child);
  std::vector<std::shared_ptr<Node>>& GetChildren();

  void SetMesh(Mesh mesh);
  Mesh& GetMesh();

  void SetIsJoint(bool is_joint);
  bool IsJoint() const;

  bool Render(SceneEncoder& encoder,
              Allocator& allocator,
              const Matrix& parent_transform);

  void AddMutation(const MutationLog::Entry& entry);

 private:
  void UnpackFromFlatbuffer(
      const fb::Node& node,
      const std::vector<std::shared_ptr<Node>>& scene_nodes,
      const std::vector<std::shared_ptr<Texture>>& textures,
      Allocator& allocator);

  mutable MutationLog mutation_log_;

  Matrix local_transform_;

  std::string name_;
  bool is_root_ = false;
  bool is_joint_ = false;
  Node* parent_ = nullptr;
  std::vector<std::shared_ptr<Node>> children_;
  Mesh mesh_;

  // For convenience purposes, deserialized nodes hang onto an animation library
  std::vector<std::shared_ptr<Animation>> animations_;
  mutable std::optional<AnimationPlayer> animation_player_;

  std::unique_ptr<Skin> skin_;

  Node(const Node&) = delete;

  Node& operator=(const Node&) = delete;

  friend Scene;
};

}  // namespace scene
}  // namespace impeller

#endif  // FLUTTER_IMPELLER_SCENE_NODE_H_
