// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_SCENE_SCENE_NODE_H_
#define FLUTTER_LIB_UI_PAINTING_SCENE_SCENE_NODE_H_

#include <memory>
#include <string>
#include <vector>

#include "flutter/fml/memory/ref_ptr.h"
#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/shader.h"

#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

class SceneShader;

/// @brief  A scene node, which may be a deserialized ipscene asset. This node
///         can be safely added as a child to multiple scene nodes, whether
///         they're in the same scene or a different scene. The deserialized
///         node itself is treated as immutable on the IO thread.
///
///         Internally, nodes may have an animation player, which is controlled
///         via the mutation log in the `DlSceneColorSource`, which is built by
///         `SceneShader`.
class SceneNode : public RefCountedDartWrappable<SceneNode> {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneShader);

 public:
  SceneNode();
  ~SceneNode() override;

  static void Create(Dart_Handle wrapper);

  std::string initFromAsset(const std::string& asset_name,
                            Dart_Handle completion_callback_handle);

  void initFromTransform(const tonic::Float64List& matrix4);

  void AddChild(Dart_Handle scene_node_handle);

  void SetTransform(const tonic::Float64List& matrix4);

  void SetAnimationState(const std::string& animation_name,
                         bool playing,
                         bool loop,
                         double weight,
                         double time_scale);

  void SeekAnimation(const std::string& animation_name, double time);

  fml::RefPtr<SceneNode> node(Dart_Handle shader);

 private:
  std::shared_ptr<impeller::scene::Node> node_;
  std::vector<fml::RefPtr<SceneNode>> children_;

  friend SceneShader;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_SCENE_SCENE_NODE_H_
