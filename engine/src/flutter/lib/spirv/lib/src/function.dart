// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spirv;

class _Function {
  final int name;
  final _FunctionType type;
  final List<int> params;

  _Function(this.type, this.name) :
    params = List<int>.filled(type.params.length, 0);

  // entry point for the function
  _Block? entry;

  // The number of parameters declared so far.
  int declaredParams = 0;

  final Map<int, _Block> blocks = <int, _Block>{};
  final List<int> deps = <int>[];

  _Block addBlock(int id) {
    final _Block b = _Block();
    blocks[id] = b;
    entry ??= b;
    return b;
  }

  void declareParam(int id, int paramType) {
    final int i = declaredParams;
    if (paramType != type.params[i]) {
      throw TranspileException._(_opFunctionParameter,
          'type mismatch for param $i of function $name');
    }
    params[i] = id;
    declaredParams++;
  }

  void write(_Transpiler t, StringBuffer out) {
    if (declaredParams != params.length) {
      throw t.failure('not all parameters declared for function $name');
    }
    if (entry == null) {
      throw t.failure('function $name has no entry block');
    }
    String returnTypeString = t.resolveType(type.returnType);
    if (t.target == TargetLanguage.sksl && name == t.entryPoint) {
      returnTypeString = 'half4';
    }
    final String nameString = t.resolveName(name);
    out.write('$returnTypeString $nameString(');

    if (t.target == TargetLanguage.sksl && name == t.entryPoint) {
      const String fragParam = 'float2 $_fragParamName';
      out.write(fragParam);
    }

    for (int i = 0; i < params.length; i++) {
      final String typeString = t.resolveType(type.params[i]);
      final String nameString = t.resolveName(params[i]);
      out.write('$typeString $nameString');
      if (i < params.length - 1) {
        out.write(', ');
      }
    }

    out.writeln(') {');

    // SkSL needs to return a value from main, so we maintain a variable
    // that receives the value of gl_FragColor and returns it at the end.
    if (t.target == TargetLanguage.sksl && name == t.entryPoint) {
      if (t.fragCoord > 0) {
        final String fragName = t.resolveName(t.fragCoord);
        out.writeln('  float4 $fragName = float4($_fragParamName, 0, 0);');
      }
      out.writeln('  float4 $_colorVariableName;');
    }

    // write the actual function body
    entry?.write(t, out, 1);

    if (t.target == TargetLanguage.sksl && name == t.entryPoint) {
      out.writeln('  return $_colorVariableName;');
    }
    out.writeln('}');
    out.writeln();
  }
}

