// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// This library defines a transpiler for converting SPIR-V into SkSL or GLSL.
library spirv;

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

// These parts only contain private members, all public
// members are in this file (spirv.dart)
part 'src/constants.dart';
part 'src/function.dart';
part 'src/instructions.dart';
part 'src/transpiler.dart';
part 'src/types.dart';

/// The language to transpile to.
enum TargetLanguage {
  /// SkSL, for Skia.
  sksl,

  /// GLSL ES 1.00, for WebGL 1.
  glslES,

  /// GLSL ES 3.00, for WebGL 2.
  glslES300,
}

/// The result of a transpilation.
class TranspileResult {
  /// Source code string in [language].
  final String src;

  /// The shader language in [src].
  final TargetLanguage language;

  /// The number of float uniforms used in this shader.
  final int uniformFloatCount;

  /// The number of samplers (children) used in this shader.
  final int samplerCount;

  TranspileResult._(
    this.src,
    this.uniformFloatCount,
    this.samplerCount,
    this.language,
  );
}

/// Thrown during transpilation due to malformed or unsupported SPIR-V.
class TranspileException implements Exception {
  /// The SPIR-V operator last read, or zero if there was none.
  final int op;

  /// Human readable message explaining the exception.
  final String message;

  @override
  String toString() => '$op: $message';

  TranspileException._(this.op, this.message);
}

/// Transpile the provided SPIR-V buffer into a string of the [target] lang.
/// Throws an instance of [TranspileException] for malformed or unsupported
/// SPIR-V.
TranspileResult transpile(ByteBuffer spirv, TargetLanguage target) {
  final _Transpiler t = _Transpiler(spirv.asUint32List(), target);
  t.transpile();
  return TranspileResult._(
    t.src.toString(),
    t.uniformFloatCount,
    t.samplerCount,
    target,
  );
}
