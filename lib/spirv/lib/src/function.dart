// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spirv;

class _Variable {
  _Variable(this.id, this.type);

  final int id;
  final int type;

  bool initialized = false;
  int liftToBlock = 0;
}

class _Function {
  _Function(this.transpiler, this.type, this.name)
      : params = List<int>.filled(type.params.length, 0);

  final _Transpiler transpiler;
  final int name;
  final _FunctionType type;
  final List<int> params;

  // entry point for the function
  _Block? entry;

  // The number of parameters declared so far.
  int declaredParams = 0;

  final Map<int, _Block> blocks = <int, _Block>{};
  final List<int> deps = <int>[];
  final Map<int, _Variable> variables = <int, _Variable>{};

  _Block addBlock(int id) {
    final _Block b = _Block(id, this);
    blocks[id] = b;
    entry ??= b;
    return b;
  }

  _Block block(int id) {
    return blocks[id]!;
  }

  void declareVariable(int id, int type) {
    variables[id] = _Variable(id, type);
  }

  _Variable? variable(int id) {
    return variables[id];
  }

  void declareParam(int id, int paramType) {
    final int i = declaredParams;
    if (paramType != type.params[i]) {
      throw TranspileException._(
          _opFunctionParameter, 'type mismatch for param $i of function $name');
    }
    params[i] = id;
    declaredParams++;
  }

  /// Returns deps of result `id` that are variables.
  List<_Variable> variableDeps(int id) {
    final _Instruction? result = transpiler.results[id];
    if (result == null) {
      return <_Variable>[];
    }
    final Set<int> deps = <int>{};
    transpiler.collectDeps(deps, id);
    return deps
        .where(variables.containsKey)
        .map((int id) => variables[id]!)
        .toList();
  }

  void write(StringBuffer out) {
    if (declaredParams != params.length) {
      throw transpiler
          .failure('not all parameters declared for function $name');
    }
    if (entry == null) {
      throw transpiler.failure('function $name has no entry block');
    }
    String returnTypeString = transpiler.resolveType(type.returnType);
    if (transpiler.target == TargetLanguage.sksl &&
        name == transpiler.entryPoint) {
      returnTypeString = 'half4';
    }
    final String nameString = transpiler.resolveName(name);
    out.write('$returnTypeString $nameString(');

    if (transpiler.target == TargetLanguage.sksl &&
        name == transpiler.entryPoint) {
      const String fragParam = 'float2 $_fragParamName';
      out.write(fragParam);
    }

    for (int i = 0; i < params.length; i++) {
      final String typeString = transpiler.resolveType(type.params[i]);
      final String nameString = transpiler.resolveName(params[i]);
      out.write('$typeString $nameString');
      if (i < params.length - 1) {
        out.write(', ');
      }
    }

    out.writeln(') {');

    // SkSL needs to return a value from main, so we maintain a variable
    // that receives the value of gl_FragColor and returns it at the end.
    if (transpiler.target == TargetLanguage.sksl &&
        name == transpiler.entryPoint) {
      if (transpiler.fragCoord > 0) {
        final String fragName = transpiler.resolveName(transpiler.fragCoord);
        out.writeln('  float4 $fragName = float4($_fragParamName, 0, 0);');
      }
      out.writeln('  float4 $_colorVariableName;');
    }

    entry?._preprocess();

    // write the actual function body
    entry?.write(_BlockContext(
      out: out,
      indent: 1,
    ));

    if (transpiler.target == TargetLanguage.sksl &&
        name == transpiler.entryPoint) {
      out.writeln('  return $_colorVariableName;');
    }
    out.writeln('}');
    out.writeln();
  }
}
