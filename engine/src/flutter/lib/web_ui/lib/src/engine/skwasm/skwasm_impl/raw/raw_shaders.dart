// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

@DefaultAsset('skwasm')
library skwasm_impl;

import 'dart:ffi';

import 'package:ui/src/engine/skwasm/skwasm_impl.dart';

final class RawShader extends Opaque {}
typedef ShaderHandle = Pointer<RawShader>;

final class RawSkString extends Opaque {}
typedef SkStringHandle = Pointer<RawSkString>;

final class RawSkData extends Opaque {}
typedef SkDataHandle = Pointer<RawSkData>;

final class RawRuntimeEffect extends Opaque {}
typedef RuntimeEffectHandle = Pointer<RawRuntimeEffect>;

@Native<ShaderHandle Function(
  RawPointArray,
  RawColorArray,
  Pointer<Float>,
  Int,
  Int,
  RawMatrix33,
)>(symbol: 'shader_createLinearGradient', isLeaf: true)
external ShaderHandle shaderCreateLinearGradient(
  RawPointArray endPoints, // two points
  RawColorArray colors,
  Pointer<Float> stops, // Can be nullptr
  int count, // Number of stops/colors
  int tileMode,
  RawMatrix33 matrix, // Can be nullptr
);

@Native<ShaderHandle Function(
  Float,
  Float,
  Float,
  RawColorArray,
  Pointer<Float>,
  Int,
  Int,
  RawMatrix33,
)>(symbol: 'shader_createRadialGradient', isLeaf: true)
external ShaderHandle shaderCreateRadialGradient(
  double centerX,
  double centerY,
  double radius,
  RawColorArray colors,
  Pointer<Float> stops,
  int count,
  int tileMode,
  RawMatrix33 localMatrix,
);

@Native<ShaderHandle Function(
  RawPointArray,
  Float,
  Float,
  RawColorArray,
  Pointer<Float>,
  Int,
  Int,
  RawMatrix33,
)>(symbol: 'shader_createConicalGradient', isLeaf: true)
external ShaderHandle shaderCreateConicalGradient(
  RawPointArray endPoints, // Two points,
  double startRadius,
  double endRadius,
  RawColorArray colors,
  Pointer<Float> stops,
  int count,
  int tileMode,
  RawMatrix33 localMatrix,
);

@Native<ShaderHandle Function(
  Float,
  Float,
  RawColorArray,
  Pointer<Float>,
  Int,
  Int,
  Float,
  Float,
  RawMatrix33,
)>(symbol: 'shader_createSweepGradient', isLeaf: true)
external ShaderHandle shaderCreateSweepGradient(
  double centerX,
  double centerY,
  RawColorArray colors,
  Pointer<Float> stops,
  int count,
  int tileMode,
  double startAngle,
  double endAngle,
  RawMatrix33 localMatrix
);

@Native<Void Function(ShaderHandle)>(symbol: 'shader_dispose', isLeaf: true)
external void shaderDispose(ShaderHandle handle);

@Native<SkStringHandle Function(Size)>(symbol: 'shaderSource_allocate', isLeaf: true)
external SkStringHandle shaderSourceAllocate(int size);

@Native<Pointer<Int8> Function(SkStringHandle)>(symbol: 'shaderSource_getData', isLeaf: true)
external Pointer<Int8> shaderSourceGetData(SkStringHandle handle);

@Native<Void Function(SkStringHandle)>(symbol: 'shaderSource_free', isLeaf: true)
external void shaderSourceFree(SkStringHandle handle);

@Native<RuntimeEffectHandle Function(SkStringHandle)>(symbol: 'runtimeEffect_create', isLeaf: true)
external RuntimeEffectHandle runtimeEffectCreate(SkStringHandle source);

@Native<Void Function(RuntimeEffectHandle)>(symbol: 'runtimeEffect_dispose', isLeaf: true)
external void runtimeEffectDispose(RuntimeEffectHandle handle);

@Native<Size Function(RuntimeEffectHandle)>(symbol: 'runtimeEffect_getUniformSize', isLeaf: true)
external int runtimeEffectGetUniformSize(RuntimeEffectHandle handle);

@Native<SkDataHandle Function(Size)>(symbol: 'data_create', isLeaf: true)
external SkDataHandle dataCreate(int size);

@Native<Pointer<Void> Function(SkDataHandle)>(symbol: 'data_getPointer', isLeaf: true)
external Pointer<Void> dataGetPointer(SkDataHandle handle);

@Native<Void Function(SkDataHandle)>(symbol: 'data_dispose', isLeaf: true)
external void dataDispose(SkDataHandle handle);

@Native<ShaderHandle Function(
  RuntimeEffectHandle,
  SkDataHandle,
  Pointer<ShaderHandle>,
  Size
)>(symbol: 'shader_createRuntimeEffectShader', isLeaf: true)
external ShaderHandle shaderCreateRuntimeEffectShader(
  RuntimeEffectHandle runtimeEffect,
  SkDataHandle uniforms,
  Pointer<ShaderHandle> childShaders,
  int childCount
);
