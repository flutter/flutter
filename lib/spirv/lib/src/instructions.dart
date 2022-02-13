part of spirv;

class _Block {
  List<_Instruction> instructions = <_Instruction>[];

  void add(_Instruction i) {
    instructions.add(i);
  }

  void writeIndent(StringBuffer out, int indent) {
    for (int i = 0; i < indent; i++) {
      out.write('  ');
    }
  }

  void write(_Transpiler t, StringBuffer out, int indent) {
    for (final _Instruction inst in instructions) {
      if (!inst.isResult) {
        writeIndent(out, indent);
        inst.write(t, out);
        out.writeln(';');
      } else if (inst.refCount > 1) {
        writeIndent(out, indent);
        final String typeString = t.resolveType(inst.type);
        final String nameString = t.resolveName(inst.id);
        out.write('$typeString $nameString = ');
        inst.write(t, out);
        out.writeln(';');
      }
    }
  }
}

abstract class _Instruction {
  int get type => 0;

  int get id => 0;

  bool get isResult => id != 0;

  // How many times this instruction is referenced, a value
  // of 2 or greater means that it will be stored into a variable.
  int refCount = 0;

  void write(_Transpiler t, StringBuffer out);
}

class _FunctionCall extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final String function;
  final List<int> args;

  _FunctionCall(this.type, this.id, this.function, this.args);

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write('$function(');
    for (int i = 0; i < args.length; i++) {
      out.write(t.resolveResult(args[i]));
      if (i < args.length - 1) {
        out.write(', ');
      }
    }
    out.write(')');
  }
}

class _StringInstruction extends _Instruction {
  final String value;

  _StringInstruction(this.value);

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write(value);
  }
}

class _Select extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int condition;
  final int a;
  final int b;

  _Select(this.type, this.id, this.condition, this.a, this.b);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String typeName = t.resolveType(type);
    final String aName = t.resolveResult(a);
    final String bName = t.resolveResult(b);
    final String conditionName = t.resolveResult(condition);
    out.write('mix($bName, $aName, $typeName($conditionName))');
  }
}

class _Store extends _Instruction {
  final int pointer;
  final int object;
  _Store(this.pointer, this.object);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String pointerName = t.resolveResult(pointer);
    final String objectName = t.resolveResult(object);
    out.write('$pointerName = $objectName');
  }
}

class _AccessChain extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int base;
  final List<int> indices;

  _AccessChain(this.type, this.id, this.base, this.indices);

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write(t.resolveResult(base));
    for (int i = 0; i < indices.length; i++) {
      final String indexString = t.resolveResult(indices[i]);
      out.write('[$indexString]');
    }
  }
}

class _VectorShuffle extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int vector;
  final List<int> indices;

  _VectorShuffle(this.type, this.id, this.vector, this.indices);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String typeString = t.resolveType(type);
    final String vectorString = t.resolveName(vector);
    out.write('$typeString(');
    for (int i = 0; i < indices.length; i++) {
      final int index = indices[i];
      out.write('$vectorString[$index]');
      if (i < indices.length - 1) {
        out.write(', ');
      }
    }
    out.write(')');
  }
}

class _CompositeConstruct extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final List<int> components;

  _CompositeConstruct(this.type, this.id, this.components);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String typeString = t.resolveType(type);
    out.write('$typeString(');
    for (int i = 0; i < components.length; i++) {
      out.write(t.resolveResult(components[i]));
      if (i < components.length - 1) {
        out.write(', ');
      }
    }
    out.write(')');
  }
}

class _CompositeExtract extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int src;
  final List<int> indices;

  _CompositeExtract(this.type, this.id, this.src, this.indices);

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write(t.resolveResult(src));
    for (int i = 0; i < indices.length; i++) {
      out.write('[${indices[i]}]');
    }
  }
}

class _ImageSampleImplicitLod extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int sampledImage;
  final int coordinate;

  _ImageSampleImplicitLod(this.type, this.id, this.sampledImage, this.coordinate);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String sampledImageString = t.resolveName(sampledImage);
    final String coordinateString = t.resolveResult(coordinate);
    if (t.target == TargetLanguage.sksl) {
      out.write('$sampledImageString.eval(${sampledImageString}_size * $coordinateString)');
    } else {
      out.write('texture($sampledImageString, $coordinateString)');
    }
  }
}

class _Negate extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int operand;

  _Negate(this.type, this.id, this.operand);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String operandString = t.resolveResult(operand);
    out.write('-$operandString');
  }
}

class _ReturnValue extends _Instruction {
  final int value;

  _ReturnValue(this.value);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String valueString = t.resolveResult(value);
    out.write('return $valueString');
  }
}

class _Operator extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final String op;
  final int a;
  final int b;

  _Operator(this.type, this.id, this.op, this.a, this.b);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String aStr = t.resolveResult(a);
    final String bStr = t.resolveResult(b);
    out.write('$aStr $op $bStr');
  }
}

class _BuiltinFunction extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final String function;
  final List<int> args;

  _BuiltinFunction(this.type, this.id, this.function, this.args);

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write('$function(');
    for (int i = 0; i < args.length; i++) {
      out.write(t.resolveResult(args[i]));
      if (i < args.length - 1) {
        out.write(', ');
      }
    }
    out.write(')');
  }
}

class _TypeCast extends _Instruction {
  @override
  final int type;

  @override
  final int id;

  final int value;

  _TypeCast(this.type, this.id, this.value);

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String typeString = t.resolveType(type);
    final String valueString = t.resolveResult(value);
    out.write('$typeString($valueString)');
  }
}
