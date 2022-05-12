part of spirv;

class _BlockContext {
  _BlockContext({
    required this.out,
    required this.indent,
    this.merge = 0,
    this.continueBlock = 0,
    this.loopHeader = 0,
    this.loopMerge = 0,
  });

  final StringBuffer out;
  final int indent;

  /// The most local merge block id, or zero.
  final int merge;

  /// The most local continue block id, or zero.
  final int continueBlock;

  /// The most local loop-construct header block id.
  final int loopHeader;

  /// The most local loop-construct merge block id.
  /// This is different from [merge] when the context is inside an if-statement
  /// inside of a for-loop, for example.
  final int loopMerge;

  /// Return a new [_BlockContext] that is a copy of the current [_BlockContext]
  /// with an increased indent and any parameters specified here overwritten.
  _BlockContext child({
    int? merge,
    int? continueBlock,
    int? loopHeader,
    int? loopMerge,
  }) =>
      _BlockContext(
        out: out,
        indent: indent + 1,
        merge: merge ?? this.merge,
        continueBlock: continueBlock ?? this.continueBlock,
        loopHeader: loopHeader ?? this.loopHeader,
        loopMerge: loopMerge ?? this.loopMerge,
      );

  void writeIndent() {
    out.write('  ' * indent);
  }
}

class _Block {
  _Block(this.id, this.function);

  final int id;
  final _Function function;

  List<_Instruction> instructions = <_Instruction>[];

  // control flow
  int branch = 0;
  int mergeBlock = 0;
  int condition = 0;
  int truthyBlock = 0;
  int falseyBlock = 0;

  // structured loop
  _Store? loopInitializer;
  int continueBlock = 0;

  // true if this block has been processed by [liftLoopVariables].
  bool scanned = false;

  _Transpiler get transpiler => function.transpiler;

  bool get hasSelectionStructure => mergeBlock != 0 && continueBlock == 0;
  bool get hasLoopStructure => continueBlock != 0;

  void _add(_Instruction i) {
    instructions.add(i);
  }

  void _writeContinue(_BlockContext ctx) {
    final List<_CompoundAssignment> assignments =
        instructions.whereType<_CompoundAssignment>().toList();
    if (assignments.isEmpty) {
      throw TranspileException._(
          _opLoopMerge, 'loop continue block $id has no compound assignments.');
    }
    if (assignments.length > 1) {
      throw TranspileException._(_opLoopMerge,
          'loop continue block $id has multiple compound assignments.');
    }
    assignments[0].write(transpiler, ctx.out);
  }

  void write(_BlockContext ctx) {
    for (final _Instruction inst in instructions) {
      if (inst is _Store) {
        final _Variable? v = function.variables[inst.pointer];
        if (v != null && inst.shouldDeclare && v.liftToBlock != 0) {
          function.block(v.liftToBlock).loopInitializer = inst;
          continue;
        }
      }

      if (!inst.isResult) {
        ctx.writeIndent();
        inst.write(transpiler, ctx.out);
        ctx.out.writeln(';');
      } else if (inst.refCount > 1) {
        ctx.writeIndent();
        final String typeString = transpiler.resolveType(inst.type);
        final String nameString = transpiler.resolveName(inst.id);
        ctx.out.write('$typeString $nameString = ');
        inst.write(transpiler, ctx.out);
        ctx.out.writeln(';');
      }
    }

    if (hasSelectionStructure) {
      _writeSelectionStructure(ctx);
    } else if (hasLoopStructure) {
      _writeLoopStructure(ctx);
    }

    if (mergeBlock != 0) {
      function.block(mergeBlock).write(ctx);
    } else if (branch != 0) {
      if (branch == ctx.merge) {
        return;
      }
      if (branch == ctx.continueBlock) {
        if (ctx.merge != ctx.loopMerge) {
          ctx.writeIndent();
          ctx.out.writeln('continue;');
        }
        return;
      }
      if (branch == ctx.loopMerge) {
        ctx.writeIndent();
        ctx.out.writeln('break;');
      }
      function.block(branch).write(ctx);
    }
  }

  /// Scans through the entire Control-Flow graph to collecting parts of
  /// for-loop structures.
  void _preprocess() {
    if (scanned) {
      return;
    }
    scanned = true;

    // SkSL has specific needs for for-loops - they must define a single
    // index variable to a constant value, they must compare that value
    // against a constant value, and they must be modified in place with
    // a constant value. SPIR-V represents all these operations in different
    // blocks, so we scan here to collect them so they can be written together.
    if (hasLoopStructure) {
      int conditionId = condition;
      if (condition == 0) {
        final _Block branchBlock = function.block(branch);
        if (!branchBlock._isSimple() || branchBlock.condition == 0) {
          throw TranspileException._(
              _opBranch,
              'block $id has a loop structure but does not immediately '
              'branch to a single-expression conditional block.');
        }
        conditionId = branchBlock.condition;
      }
      final List<_Variable> deps = function.variableDeps(conditionId);
      if (deps.length != 1) {
        throw TranspileException._(
            _opLoopMerge,
            'block $id has a loop structure with a condition '
            'using more or fewer than one local variable.');
      }
      deps[0].liftToBlock = id;
    }

    // Scan all blocks that can be reached from this block.
    if (branch != 0) {
      function.block(branch)._preprocess();
    }
    if (condition != 0) {
      if (truthyBlock != 0) {
        function.block(truthyBlock)._preprocess();
      }
      if (falseyBlock != 0) {
        function.block(falseyBlock)._preprocess();
      }
    }
    if (mergeBlock != 0) {
      function.block(mergeBlock)._preprocess();
    }
  }

  void _writeSelectionStructure(_BlockContext ctx) {
    final _BlockContext childCtx = ctx.child(merge: mergeBlock);
    ctx.writeIndent();
    final String conditionString = transpiler.resolveResult(condition);
    ctx.out.writeln('if ($conditionString) {');
    function.block(truthyBlock).write(childCtx);
    if (falseyBlock != 0 && falseyBlock != mergeBlock) {
      ctx.writeIndent();
      ctx.out.writeln('} else {');
      function.block(falseyBlock).write(childCtx);
    }
    ctx.writeIndent();
    ctx.out.writeln('}');
  }

  void _writeLoopStructure(_BlockContext ctx) {
    final _BlockContext childCtx = ctx.child(
      merge: mergeBlock,
      continueBlock: continueBlock,
      loopHeader: id,
      loopMerge: mergeBlock,
    );

    String conditionString;
    int loopBody = 0;
    if (condition != 0) {
      conditionString = transpiler.resolveResult(condition);
      if (truthyBlock == mergeBlock) {
        conditionString = '!' + conditionString;
        loopBody = falseyBlock;
      } else if (falseyBlock == mergeBlock) {
        loopBody = truthyBlock;
      }
    } else {
      final _Block branchBlock = function.block(branch);
      if (!branchBlock._isSimple() || branchBlock.condition == 0) {
        throw TranspileException._(
            _opBranch,
            'block $id has a loop structure but does not immediately '
            'branch to a single-expression conditional block.');
      }

      conditionString = transpiler.resolveResult(branchBlock.condition);
      if (branchBlock.truthyBlock == mergeBlock) {
        conditionString = '!' + conditionString;
        loopBody = branchBlock.falseyBlock;
      } else if (branchBlock.falseyBlock == mergeBlock) {
        loopBody = branchBlock.truthyBlock;
      }
    }

    if (loopBody == 0) {
      throw TranspileException._(
          _opLoopMerge,
          'block $id does not conditionally branch to its '
          'loop merge block.');
    }

    ctx.writeIndent();
    ctx.out.write('for(');
    loopInitializer!.write(transpiler, ctx.out);
    ctx.out.write('; ');
    ctx.out.write(conditionString);
    ctx.out.write('; ');
    function.block(continueBlock)._writeContinue(ctx);
    ctx.out.writeln(') {');
    function.block(loopBody).write(childCtx);
    ctx.writeIndent();
    ctx.out.writeln('}');
  }

  /// Returns true if this block has no stateful expressions
  /// and can be written as a single expression.
  bool _isSimple() {
    int statements = 0;
    for (final _Instruction inst in instructions) {
      if (!inst.isResult) {
        return false;
      }
      if (inst.refCount > 1) {
        statements++;
      }
    }
    return statements == 0;
  }
}

abstract class _Instruction {
  int get type => 0;

  int get id => 0;

  bool get isResult => id != 0;

  List<int> get deps => <int>[];

  // How many times this instruction is referenced, a value
  // of 2 or greater means that it will be stored into a variable.
  int refCount = 0;

  void write(_Transpiler t, StringBuffer out);
}

class _FunctionCall extends _Instruction {
  _FunctionCall(this.type, this.id, this.function, this.args);

  @override
  final int type;

  @override
  final int id;

  final String function;
  final List<int> args;

  @override
  List<int> get deps => args;

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

class _Return extends _Instruction {
  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write('return');
  }
}

class _Select extends _Instruction {
  _Select(this.type, this.id, this.condition, this.a, this.b);

  @override
  final int type;

  @override
  final int id;

  final int condition;
  final int a;
  final int b;

  @override
  List<int> get deps => <int>[condition, a, b];

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String aName = t.resolveResult(a);
    final String bName = t.resolveResult(b);
    final String conditionName = t.resolveResult(condition);
    out.write('$conditionName ? $aName : $bName');
  }
}

class _CompoundAssignment extends _Instruction {
  _CompoundAssignment(this.pointer, this.op, this.object);

  final int pointer;
  final _Operator op;
  final int object;

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String pointerName = t.resolveResult(pointer);
    final String objectName = t.resolveResult(object);
    final String operatorString = _operatorString(op);
    out.write('$pointerName $operatorString= $objectName');
  }
}

class _Store extends _Instruction {
  _Store(
    this.pointer,
    this.object, {
    this.shouldDeclare = false,
    this.declarationType = 0,
  });

  final int pointer;
  final int object;

  final bool shouldDeclare;
  final int declarationType;

  int selfModifyObject = 0;
  String selfModifyOperator = '';

  @override
  List<int> get deps => <int>[pointer, object];

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String pointerName = t.resolveResult(pointer);
    if (selfModifyObject > 0) {
      final String objectName = t.resolveResult(selfModifyObject);
      out.write('$pointerName $selfModifyOperator $objectName');
    } else {
      final String objectName = t.resolveResult(object);
      if (shouldDeclare) {
        final String typeString = t.resolveType(declarationType);
        out.write('$typeString ');
      }
      out.write('$pointerName = $objectName');
    }
  }
}

class _AccessChain extends _Instruction {
  _AccessChain(this.type, this.id, this.base, this.indices);

  @override
  final int type;

  @override
  final int id;

  final int base;
  final List<int> indices;

  @override
  List<int> get deps => <int>[base, ...indices];

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
  _VectorShuffle(this.type, this.id, this.vector, this.indices);

  @override
  final int type;

  @override
  final int id;

  final int vector;
  final List<int> indices;

  @override
  List<int> get deps => <int>[vector];

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
  _CompositeConstruct(this.type, this.id, this.components);

  @override
  final int type;

  @override
  final int id;

  final List<int> components;

  @override
  List<int> get deps => components;

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
  _CompositeExtract(this.type, this.id, this.src, this.indices);

  @override
  final int type;

  @override
  final int id;

  final int src;
  final List<int> indices;

  @override
  List<int> get deps => <int>[src];

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write(t.resolveResult(src));
    for (int i = 0; i < indices.length; i++) {
      out.write('[${indices[i]}]');
    }
  }
}

class _ImageSampleImplicitLod extends _Instruction {
  _ImageSampleImplicitLod(
      this.type, this.id, this.sampledImage, this.coordinate);

  @override
  final int type;

  @override
  final int id;

  final int sampledImage;
  final int coordinate;

  @override
  List<int> get deps => <int>[coordinate];

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String sampledImageString = t.resolveName(sampledImage);
    final String coordinateString = t.resolveResult(coordinate);
    if (t.target == TargetLanguage.sksl) {
      out.write(
          '$sampledImageString.eval(${sampledImageString}_size * $coordinateString)');
    } else {
      out.write('texture($sampledImageString, $coordinateString)');
    }
  }
}

class _UnaryOperator extends _Instruction {
  _UnaryOperator(this.type, this.id, this.op, this.operand);

  @override
  final int type;

  @override
  final int id;

  final _Operator op;
  final int operand;

  @override
  List<int> get deps => <int>[operand];

  @override
  void write(_Transpiler t, StringBuffer out) {
    out.write(_operatorString(op));
    out.write(t.resolveResult(operand));
  }
}

class _ReturnValue extends _Instruction {
  _ReturnValue(this.value);

  final int value;

  @override
  List<int> get deps => <int>[value];

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String valueString = t.resolveResult(value);
    out.write('return $valueString');
  }
}

class _BinaryOperator extends _Instruction {
  _BinaryOperator(this.type, this.id, this.op, this.a, this.b);

  @override
  final int type;

  @override
  final int id;

  final _Operator op;
  final int a;
  final int b;

  @override
  List<int> get deps => <int>[a, b];

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String aStr = t.resolveResult(a);
    final String bStr = t.resolveResult(b);
    final String opString = _operatorString(op);
    out.write('$aStr $opString $bStr');
  }
}

class _BuiltinFunction extends _Instruction {
  _BuiltinFunction(this.type, this.id, this.function, this.args);

  @override
  final int type;

  @override
  final int id;

  final String function;
  final List<int> args;

  @override
  List<int> get deps => args;

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
  _TypeCast(this.type, this.id, this.value);

  @override
  final int type;

  @override
  final int id;

  final int value;

  @override
  List<int> get deps => <int>[value];

  @override
  void write(_Transpiler t, StringBuffer out) {
    final String typeString = t.resolveType(type);
    final String valueString = t.resolveResult(value);
    out.write('$typeString($valueString)');
  }
}
