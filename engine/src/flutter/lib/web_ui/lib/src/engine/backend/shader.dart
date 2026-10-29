// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:ui/ui.dart' as ui;

/// The base interface for native backend implementations of [ui.Shader].
abstract class BackendShader {
  /// Detaches and eagerly cleans up any native resources.
  void dispose();

  bool get isGradient => false;
}

/// The native backend representation of a [ui.Gradient].
abstract class BackendGradient extends BackendShader {
  @override
  bool get isGradient => true;
}

/// The native backend representation of a [ui.ImageShader].
abstract class BackendImageShader extends BackendShader {}

/// The native backend representation of a [ui.FragmentShader].
abstract class BackendFragmentShader extends BackendShader {
  void setFloat(int index, double value);
  void setImageSampler(int index, BackendImageShader shader, double width, double height);

  // Introspection methods
  ui.UniformFloatSlot getUniformFloat(String name, [int? index]);
  ui.UniformVec2Slot getUniformVec2(String name);
  ui.UniformVec3Slot getUniformVec3(String name);
  ui.UniformVec4Slot getUniformVec4(String name);
  ui.UniformMat2Slot getUniformMat2(String name);
  ui.UniformMat3Slot getUniformMat3(String name);
  ui.UniformMat4Slot getUniformMat4(String name);
  ui.ImageSamplerSlot getImageSampler(String name);
  ui.UniformArray<ui.UniformFloatSlot> getUniformFloatArray(String name);
  ui.UniformArray<ui.UniformVec2Slot> getUniformVec2Array(String name);
  ui.UniformArray<ui.UniformVec3Slot> getUniformVec3Array(String name);
  ui.UniformArray<ui.UniformVec4Slot> getUniformVec4Array(String name);
  ui.UniformArray<ui.UniformMat2Slot> getUniformMat2Array(String name);
  ui.UniformArray<ui.UniformMat3Slot> getUniformMat3Array(String name);
  ui.UniformArray<ui.UniformMat4Slot> getUniformMat4Array(String name);
}
