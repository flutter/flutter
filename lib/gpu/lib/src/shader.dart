// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

part of flutter_gpu;

base class UniformSlot {
  const UniformSlot(this.slotId, this.shaderStage);

  final int slotId;
  final ShaderStage shaderStage;
}

base class Shader extends NativeFieldWrapperClass1 {
  // [Shader] handles are instantiated when interacting with a [ShaderLibrary].
  Shader._();

  UniformSlot? getUniformSlot(String name) {
    int slot = _getUniformSlot(name);
    if (slot < 0) {
      return null;
    }
    return UniformSlot(slot, ShaderStage.values[_getShaderStage()]);
  }

  @Native<Int Function(Pointer<Void>)>(
      symbol: 'InternalFlutterGpu_Shader_GetShaderStage')
  external int _getShaderStage();

  @Native<Int Function(Pointer<Void>, Handle)>(
      symbol: 'InternalFlutterGpu_Shader_GetUniformSlot')
  external int _getUniformSlot(String name);
}
