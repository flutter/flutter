// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#ifndef FLUTTER_LIB_UI_PAINTING_SCENE_SCENE_SHADER_H_
#define FLUTTER_LIB_UI_PAINTING_SCENE_SCENE_SHADER_H_

#include <string>
#include <vector>

#include "flutter/lib/ui/dart_wrapper.h"
#include "flutter/lib/ui/painting/scene/scene_node.h"
#include "flutter/lib/ui/painting/shader.h"
#include "impeller/geometry/matrix.h"

#include "third_party/tonic/dart_library_natives.h"

namespace flutter {

class SceneShader : public Shader {
  DEFINE_WRAPPERTYPEINFO();
  FML_FRIEND_MAKE_REF_COUNTED(SceneShader);

 public:
  ~SceneShader() override;

  static void Create(Dart_Handle wrapper, Dart_Handle scene_node_handle);

  void SetCameraTransform(const tonic::Float64List& matrix4);

  void Dispose();

  // |Shader|
  std::shared_ptr<DlColorSource> shader(DlImageSampling) override;

 private:
  explicit SceneShader(fml::RefPtr<SceneNode> scene_node);

  impeller::Matrix camera_transform_;
  fml::RefPtr<SceneNode> scene_node_;
};

}  // namespace flutter

#endif  // FLUTTER_LIB_UI_PAINTING_SCENE_SCENE_SHADER_H_
