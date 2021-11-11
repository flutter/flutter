// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spirv;

enum _Type {
  _void,
  _bool,
  _int,
  float,
  float2,
  float3,
  float4,
  float2x2,
  float3x3,
  float4x4,
  sampledImage,
}

class _FunctionType {
  /// Result-id of the return type.
  final int returnType;

  /// Type-id for each parameter.
  final List<int> params;

  _FunctionType(this.returnType, this.params);
}

String _typeName(_Type t, TargetLanguage target) {
  switch (target) {
    case TargetLanguage.sksl:
      return _skslTypeNames[t]!;
    default:
      return _glslTypeNames[t]!;
  }
}

const Map<_Type, String> _skslTypeNames = <_Type, String>{
  _Type._void: 'void',
  _Type._bool: 'bool',
  _Type._int: 'int',
  _Type.float: 'float',
  _Type.float2: 'float2',
  _Type.float3: 'float3',
  _Type.float4: 'float4',
  _Type.float2x2: 'float2x2',
  _Type.float3x3: 'float3x3',
  _Type.float4x4: 'float4x4',
  _Type.sampledImage: 'shader',
};

const Map<_Type, String> _glslTypeNames = <_Type, String>{
  _Type._void: 'void',
  _Type._bool: 'bool',
  _Type._int: 'int',
  _Type.float: 'float',
  _Type.float2: 'vec2',
  _Type.float3: 'vec3 ',
  _Type.float4: 'vec4',
  _Type.float2x2: 'mat2',
  _Type.float3x3: 'mat3',
  _Type.float4x4: 'mat4',
  _Type.sampledImage: 'sampler2D',
};

const Map<_Type, int> _typeFloatCounts = <_Type, int>{
  _Type.float: 1,
  _Type.float2: 2,
  _Type.float3: 3,
  _Type.float4: 4,
  _Type.float2x2: 4,
  _Type.float3x3: 9,
  _Type.float4x4: 16,
};
