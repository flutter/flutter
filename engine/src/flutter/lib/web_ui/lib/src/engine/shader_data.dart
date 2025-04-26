// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

class ShaderData {
  ShaderData({
    required this.source,
    required this.uniforms,
    required this.floatCount,
    required this.textureCount,
  });

  factory ShaderData.fromBytes(Uint8List data) {
    final String contents = utf8.decode(data);
    final Object? rawShaderData = json.decode(contents);
    if (rawShaderData is! Map<String, Object?>) {
      throw const FormatException('Invalid Shader Data');
    }
    final Object? root = rawShaderData['sksl'];
    if (root is! Map<String, Object?>) {
      throw const FormatException('Invalid Shader Data');
    }

    final Object? source = root['shader'];
    final Object? rawUniforms = root['uniforms'];
    if (source is! String || rawUniforms is! List<Object?>) {
      throw const FormatException('Invalid Shader Data');
    }

    final List<UniformData> uniforms = List<UniformData>.filled(
      rawUniforms.length,
      UniformData.empty,
    );

    int textureCount = 0;
    int floatCount = 0;
    for (int i = 0; i < rawUniforms.length; i += 1) {
      final Object? rawUniformData = rawUniforms[i];
      if (rawUniformData is! Map<String, Object?>) {
        throw const FormatException('Invalid Shader Data');
      }
      final Object? name = rawUniformData['name'];
      final Object? location = rawUniformData['location'];
      final Object? rawType = rawUniformData['type'];
      if (name is! String || location is! int || rawType is! int) {
        throw const FormatException('Invalid Shader Data');
      }
      final UniformType? type = uniformTypeFromJson(rawType);
      if (type == null) {
        throw const FormatException('Invalid Shader Data');
      }
      if (type == UniformType.SampledImage) {
        textureCount += 1;
      } else {
        final Object? bitWidth = rawUniformData['bit_width'];

        final Object? arrayElements = rawUniformData['array_elements'];
        final Object? rows = rawUniformData['rows'];
        final Object? columns = rawUniformData['columns'];

        if (bitWidth is! int || rows is! int || arrayElements is! int || columns is! int) {
          throw const FormatException('Invalid Shader Data');
        }

        final int units = rows * columns;

        int value = (bitWidth ~/ 32) * units;

        if (arrayElements > 1) {
          value *= arrayElements;
        }

        floatCount += value;
      }
      uniforms[i] = UniformData(name: name, location: location, type: type);
    }
    return ShaderData(
      source: source,
      uniforms: uniforms,
      floatCount: floatCount,
      textureCount: textureCount,
    );
  }

  String source;
  List<UniformData> uniforms;
  int floatCount;
  int textureCount;
}

class UniformData {
  const UniformData({required this.name, required this.location, required this.type});

  final String name;
  final UniformType type;
  final int location;

  static const UniformData empty = UniformData(name: '', location: -1, type: UniformType.Float);
}

enum UniformType {
  Boolean,
  SByte,
  UByte,
  Short,
  UShort,
  Int,
  Uint,
  Int64,
  Uint64,
  Half,
  Float,
  Double,
  SampledImage,
}

UniformType? uniformTypeFromJson(int value) {
  switch (value) {
    case 0:
      return UniformType.Boolean;
    case 1:
      return UniformType.SByte;
    case 2:
      return UniformType.UByte;
    case 3:
      return UniformType.Short;
    case 4:
      return UniformType.UShort;
    case 5:
      return UniformType.Int;
    case 6:
      return UniformType.Uint;
    case 7:
      return UniformType.Int64;
    case 8:
      return UniformType.Uint64;
    case 9:
      return UniformType.Half;
    case 10:
      return UniformType.Float;
    case 11:
      return UniformType.Double;
    case 12:
      return UniformType.SampledImage;
  }
  return null;
}
