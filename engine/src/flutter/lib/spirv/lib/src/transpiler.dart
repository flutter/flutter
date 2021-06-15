// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spirv;

/// The name of the fragment-coordinate parameter when generating SkSL.
const String _fragParamName = 'iFragCoord';

/// The name of a local variable in the main function of an SkSL shader.
/// It will be assigned in place of an output variable at location 0.
/// This will be returned at the end of the main function.
const String _colorVariableName = 'oColor';

/// The name of the color-output variable in GLSL ES 100.
const String _glslESColorName = 'gl_FragColor';

/// The name of the fragment-coordinate value in GLSL.
const String _glslFragCoord = 'gl_FragCoord';

const String _mainFunctionName = 'main';

/// State machine for transpiling SPIR-V to the target language.
///
/// SPIR-V is specified as a sequence of 32-bit values called words.
/// The first words are the header, and the rest are a sequence of
/// instructions. Instructions begin with one word that includes
/// an opcode and the number of words contained by the instruction.
///
/// This transpiler works by maintaining a read position, [position],
/// which is advanced by methods with names beginning in "read", "parse",
/// or "op". State is written to member variables as the read position
/// advances, this will become more complex with a larger supported
/// subset of SPIR-V, and with more optimized output. It is currently
/// designed only for simplicity and speed, as the resuling code
/// will be compiled and optimized before making it to the GPU.
///
/// The main method for the class is [transpile].
///
/// The list of supported SPIR-V operands is specified by the switch
/// statement in [parseInstruction] and the accompanying constants
/// in `src/constants.dart`.
///
/// The methods beginning with `op` correspond to a specific opcode in SPIR-V.
/// The accompanying documentation is at
/// https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html
///
/// For the spec of a specific instruction, navigate to the above url with
/// the capitalized name of the operator appended. For example, for
/// [opConstant] append `#OpConstant`, like the following:
/// https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html#OpConstant
class _Transpiler {
  _Transpiler(this.spirv, this.target) {
    out = src;
  }

  final Uint32List spirv;
  final TargetLanguage target;

  /// The resulting source code of the target language is written to src.
  final StringBuffer src = StringBuffer();

  /// ID mapped to numerical types.
  final Map<int, _Type> types = <int, _Type>{};

  /// ID mapped to function types.
  final Map<int, _FunctionType> functionTypes = <int, _FunctionType>{};

  /// Function ID mapped to source-code definition.
  final Map<int, StringBuffer> functionDefs = <int, StringBuffer>{};

  /// ID mapped to location decorator.
  /// See [opDecorate] for more information.
  final Map<int, int> locations = <int, int>{};

  /// ID mapped to ID. Used by [OpLoad].
  final Map<int, int> alias = <int, int>{};

  /// The current word-index in the SPIR-V buffer.
  int position = 0;

  /// The word-index of the next unread instruction.
  int nextPosition = 0;

  /// The current op code being handled, or 0 if none.
  int currentOp = 0;

  /// The ID of the GLSL.std.450 instruction set.
  /// See [opExtInstImport] for more information.
  int glslExtImport = 0;

  /// The ID of the shader's entry point.
  /// See [opEntryPoint].
  int entryPoint = 0;

  /// The ID of a 32-bit float type.
  /// See [opTypeFloat].
  int floatType = 0;

  /// The ID of the function that is currently being defined.
  /// Set by [opFunction] and unset by [opFunctionEnd].
  int currentFunction = 0;

  /// The type of [currentFunction], or null.
  _FunctionType? currentFunctionType;

  /// Count of parameters declared so far for the [currentFunction].
  int declaredParams = 0;

  /// The ID for the color output variable.
  /// Set by [opVariable].
  int colorOutput = 0;

  /// The ID for the fragment coordinate builtin.
  /// Set by [opDecorate].
  int fragCoord = 0;

  /// The number of floats used by uniforms.
  int uniformFloatCount = 0;

  /// Current indentation to prepend to new lines.
  String indent = '';

  /// Points to the source of the [currentFunction], or to [src] as a fallback.
  /// The source of [currentFunction] is stored in [functionDefs].
  late StringBuffer out;

  /// Scan through all the words and populate [out] with source code,
  /// or throw an exception. Calls to [parseInstruction] will affect
  /// the state of the transpiler, including [position] and [out].
  void transpile() {
    parseHeader();
    writeHeader();
    while (position < spirv.length) {
      final int lastPosition = position;
      parseInstruction();
      // If position is the same or smaller, the while loop may repeat forever.
      assert(position > lastPosition);
    }

    src.writeln();
    for (final StringBuffer def in functionDefs.values) {
      src.write(def.toString());
    }
  }

  TranspileException failure(String why) =>
      TranspileException._(currentOp, why);

  void writeHeader() {
    switch (target) {
      case TargetLanguage.glslES:
        src.writeln('#version 100\n');
        src.writeln('precision mediump float;\n');
        break;
      case TargetLanguage.glslES300:
        src.writeln('#version 300 es\n');
        src.writeln('precision mediump float;\n');
        src.writeln('layout ( location = 0 ) out vec4 $_colorVariableName;\n');
        break;
      default:
        break;
    }
  }

  String resolveName(int id) {
    if (alias.containsKey(id)) {
      return resolveName(alias[id]!);
    }
    if (id == colorOutput) {
      if (target == TargetLanguage.glslES) {
        return _glslESColorName;
      } else {
        return _colorVariableName;
      }
    } else if (id == entryPoint) {
      return _mainFunctionName;
    } else if (id == fragCoord && target != TargetLanguage.sksl) {
      return _glslFragCoord;
    }
    return 'i$id';
  }

  String resolveType(int type) {
    final _Type? t = types[type];
    if (t == null) {
      throw failure('The id "$type" has not been asgined a type');
    }
    return _typeName(t, target);
  }

  int readWord() {
    if (nextPosition != 0 && position > nextPosition) {
      throw failure('Read past the current instruction.');
    }
    final int word = spirv[position];
    position++;
    return word;
  }

  void parseHeader() {
    if (spirv[0] != _magicNumber) {
      throw failure('Magic number not detected in the header');
    }
    // Skip version, generator's magic word, bound, and reserved word.
    position = 5;
  }

  String readStringLiteral() {
    final List<int> literal = <int>[];
    while (position < nextPosition) {
      final int word = readWord();
      for (int i = 0; i < 4; i++) {
        final int octet = (word >> (i * 8)) & 0xFF;
        if (octet == 0) {
          return utf8.decode(literal);
        }
        literal.add(octet);
      }
    }
    // Null terminating character not found.
    throw failure('No null-terminating character found for string literal');
  }

  /// Read an instruction word, and handle the operation.
  ///
  /// SPIR-V instructions contain an op-code as well as a
  /// word-size. This method parses both, calls the appropriate
  /// operation-handler method, and then advances [position]
  /// to the next instruction.
  void parseInstruction() {
    final int word = readWord();
    currentOp = word & 0xFFFF;
    nextPosition = position + (word >> 16) - 1;
    switch (currentOp) {
      case _opExtInstImport:
        opExtInstImport();
        break;
      case _opExtInst:
        opExtInst();
        break;
      case _opMemoryModel:
        opMemoryModel();
        break;
      case _opEntryPoint:
        opEntryPoint();
        break;
      case _opExecutionMode:
        opExecutionMode();
        break;
      case _opCapability:
        opCapability();
        break;
      case _opTypeVoid:
        opTypeVoid();
        break;
      case _opTypeBool:
        opTypeBool();
        break;
      case _opTypeFloat:
        opTypeFloat();
        break;
      case _opTypeVector:
        opTypeVector();
        break;
      case _opTypeMatrix:
        opTypeMatrix();
        break;
      case _opTypePointer:
        opTypePointer();
        break;
      case _opTypeFunction:
        opTypeFunction();
        break;
      case _opConstant:
        opConstant();
        break;
      case _opConstantComposite:
        opConstantComposite();
        break;
      case _opFunction:
        opFunction();
        break;
      case _opFunctionParameter:
        opFunctionParameter();
        break;
      case _opFunctionEnd:
        opFunctionEnd();
        break;
      case _opFunctionCall:
        opFunctionCall();
        break;
      case _opVariable:
        opVariable();
        break;
      case _opLoad:
        opLoad();
        break;
      case _opStore:
        opStore();
        break;
      case _opAccessChain:
        opAccessChain();
        break;
      case _opDecorate:
        opDecorate();
        break;
      case _opVectorShuffle:
        opVectorShuffle();
        break;
      case _opCompositeConstruct:
        opCompositeConstruct();
        break;
      case _opCompositeExtract:
        opCompositeExtract();
        break;
      case _opFNegate:
        opFNegate();
        break;
      case _opFAdd:
        parseOperatorInst('+');
        break;
      case _opFSub:
        parseOperatorInst('-');
        break;
      case _opFMul:
        parseOperatorInst('*');
        break;
      case _opFDiv:
        parseOperatorInst('/');
        break;
      case _opFMod:
        parseBuiltinFunction('mod');
        break;
      case _opVectorTimesScalar:
      case _opMatrixTimesScalar:
      case _opVectorTimesMatrix:
      case _opMatrixTimesVector:
      case _opMatrixTimesMatrix:
        parseOperatorInst('*');
        break;
      case _opDot:
        parseBuiltinFunction('dot');
        break;
      case _opLabel:
        opLabel();
        break;
      case _opReturn:
        opReturn();
        break;
      case _opReturnValue:
        opReturnValue();
        break;
      default:
        throw failure('Not a supported op.');
    }
    position = nextPosition;
  }

  void opExtInstImport() {
    glslExtImport = readWord();
    final String ext = readStringLiteral();
    if (ext != _glslStd450) {
      throw failure('only "$_glslStd450" is supported. Got "$ext".');
    }
  }

  void opExtInst() {
    final int type = readWord();
    final int id = readWord();
    final int set = readWord();
    if (set != glslExtImport) {
      throw failure('only imported glsl instructions are supported');
    }
    parseGLSLInst(id, type);
  }

  void opMemoryModel() {
    // addressing model
    if (readWord() != _addressingModelLogical) {
      throw failure('only the logical addressing model is supported');
    }
    // memory model
    if (readWord() != _memoryModelGLSL450) {
      throw failure('only the GLSL450 memory model is supported');
    }
  }

  void opEntryPoint() {
    // skip execution model
    position++;
    entryPoint = readWord();
  }

  void opExecutionMode() {
    // Skip entry point
    position++;
    final int executionMode = readWord();
    if (executionMode != _originLowerLeft) {
      throw failure('only OriginLowerLeft is supported as an execution mode');
    }
  }

  void opCapability() {
    final int capability = readWord();
    switch (capability) {
      case _capabilityMatrix:
      case _capabilityShader:
        return;
      default:
        throw failure('$capability is not a supported capability');
    }
  }

  void opTypeVoid() {
    types[readWord()] = _Type._void;
  }

  void opTypeBool() {
    types[readWord()] = _Type._bool;
  }

  void opTypeFloat() {
    final int id = readWord();
    types[id] = _Type.float;
    floatType = id;
    final int width = readWord();
    if (width != 32) {
      throw failure('float width must be 32');
    }
  }

  void opTypeVector() {
    final int id = readWord();
    _Type t;
    final int componentType = readWord();
    if (componentType != floatType) {
      throw failure('only float vectors are supported');
    }
    final int componentCount = readWord();
    switch (componentCount) {
      case 2:
        t = _Type.float2;
        break;
      case 3:
        t = _Type.float3;
        break;
      case 4:
        t = _Type.float4;
        break;
      default:
        throw failure('$componentCount not a supported component count.');
    }
    types[id] = t;
  }

  void opTypeMatrix() {
    final int id = readWord();
    _Type t;
    final int columnType = readWord();
    final int columnCount = readWord();
    _Type expected = _Type.float2;
    switch (columnCount) {
      case 2:
        t = _Type.float2x2;
        break;
      case 3:
        t = _Type.float3x3;
        expected = _Type.float3;
        break;
      case 4:
        t = _Type.float4x4;
        expected = _Type.float4;
        break;
      default:
        throw failure('$columnCount is not a supported column count');
    }
    if (types[columnType] != expected) {
      throw failure('Only square matrix dimensions are supported');
    }
    types[id] = t;
  }

  void opTypePointer() {
    final int id = readWord();
    // ignore storage class
    position++;
    final _Type? t = types[readWord()];
    if (t == null) {
      throw failure('$t is not a registered type');
    }
    types[id] = t;
  }

  void opTypeFunction() {
    final int id = readWord();
    final int returnType = readWord();
    final int paramCount = nextPosition - position;
    final List<int> params = List<int>.filled(paramCount, 0);
    for (int i = 0; i < paramCount; i++) {
      params[i] = readWord();
    }
    functionTypes[id] = _FunctionType(returnType, params);
  }

  void opConstant() {
    final int type = readWord();
    final String id = resolveName(readWord());
    final int value = readWord();
    String valueString = '$value';
    if (types[type] == _Type.float) {
      final double v = Int32List.fromList(<int>[value])
          .buffer
          .asByteData()
          .getFloat32(0, Endian.little);
      valueString = '$v';
    }
    final String typeName = resolveType(type);
    src.writeln('const $typeName $id = $valueString;');
  }

  void opConstantComposite() {
    final String type = resolveType(readWord());
    final String id = resolveName(readWord());
    src.write('const $type $id = $type(');
    final int count = nextPosition - position;
    for (int i = 0; i < count; i++) {
      src.write(resolveName(readWord()));
      if (i < count - 1) {
        src.write(', ');
      }
    }
    src.writeln(');');
  }

  void opFunction() {
    String returnType = resolveType(readWord());
    final int id = readWord();

    if (target == TargetLanguage.sksl && id == entryPoint) {
      returnType = 'half4';
    }

    // ignore function control
    position++;

    final String name = resolveName(id);
    final String opening = '$returnType $name(';
    final StringBuffer def = StringBuffer();
    def.write(opening);
    src.write(opening);

    if (target == TargetLanguage.sksl && id == entryPoint) {
      const String fragParam = 'float2 $_fragParamName';
      def.write(fragParam);
      src.write(fragParam);
    }

    final int typeIndex = readWord();
    final _FunctionType? functionType = functionTypes[typeIndex];
    if (functionType == null) {
      throw failure('$typeIndex is not a registered function type');
    }

    if (functionType.params.isEmpty) {
      def.write(') ');
      src.writeln(');');
    }

    currentFunction = id;
    currentFunctionType = functionType;
    declaredParams = 0;
    out = def;
    functionDefs[id] = def;
  }

  void opFunctionParameter() {
    if (declaredParams > 0) {
      out.write(', ');
      src.write(', ');
    }

    final int type = readWord();
    final int id = readWord();
    final String decl = resolveType(type) + ' ' + resolveName(id);
    out.write(decl);
    src.write(decl);
    declaredParams++;

    if (declaredParams == currentFunctionType?.params.length) {
      out.write(') ');
      src.writeln(');');
    }
  }

  void opFunctionEnd() {
    if (target == TargetLanguage.sksl && currentFunction == entryPoint) {
      out.writeln('${indent}return $_colorVariableName;');
    }
    out.writeln('}');
    out.writeln();
    // Remove trailing two space characters, if present.
    indent = indent.substring(0, max(0, indent.length - 2));
    currentFunction = 0;
    out = src;
    currentFunctionType = null;
  }

  void opFunctionCall() {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    final String functionName = resolveName(readWord());
    final List<String> args =
        List<String>.generate(nextPosition - position, (int i) {
      return resolveName(readWord());
    });
    out.write('$indent$type $name = $functionName(');
    for (int i = 0; i < args.length; i++) {
      out.write(args[i]);
      if (i < args.length - 1) {
        out.write(', ');
      }
    }
    out.writeln(');');
  }

  void opVariable() {
    final int typeId = readWord();
    final String type = resolveType(typeId);
    final int id = readWord();
    final String name = resolveName(id);
    final int storageClass = readWord();

    switch (storageClass) {
      case _storageClassUniformConstant:
        if (target == TargetLanguage.glslES300) {
          final String location = locations[id].toString();
          src.write('layout ( location = $location ) ');
        }
        src.writeln('uniform $type $name;');
        final _Type? t = types[typeId];
        if (t == null) {
          throw failure('$typeId is not a defined type');
        }
        uniformFloatCount += _typeFloatCounts[t]!;
        return;
      case _storageClassInput:
        return;
      case _storageClassOutput:
        if (locations[id] == 0) {
          colorOutput = id;
        }
        return;
      case _storageClassFunction:
        out.writeln('$indent$type $name;');
        return;
      default:
        throw failure('$storageClass is an unsupported Storage Class');
    }
  }

  void opLoad() {
    // ignore type
    position++;
    final int id = readWord();
    final int pointer = readWord();
    alias[id] = pointer;
  }

  void opStore() {
    final String pointer = resolveName(readWord());
    final String object = resolveName(readWord());
    out.writeln('$indent$pointer = $object;');
  }

  void opAccessChain() {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    final String base = resolveName(readWord());

    // opAccessChain currently only supports indexed access.
    // Once struct support is added, this will need to be updated.
    // Currently, structs will be caught before this method is called,
    // since using the instruction to define a struct type will throw
    // an exception.
    out.write('$indent$type $name = $base');
    final int count = nextPosition - position;
    for (int i = 0; i < count; i++) {
      final String index = resolveName(readWord());
      out.write('[$index]');
    }
    out.writeln(';');
  }

  void opDecorate() {
    final int target = readWord();
    final int decoration = readWord();
    switch (decoration) {
      case _decorationBuiltIn:
        if (readWord() == _builtinFragCoord) {
          fragCoord = target;
        }
        return;
      case _decorationLocation:
        locations[target] = readWord();
        return;
      default:
        return;
    }
  }

  void opVectorShuffle() {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    final String vector1Name = resolveName(readWord());
    // ignore second vector
    position++;

    out.write('$indent$type $name = $type(');

    final int count = nextPosition - position;
    for (int i = 0; i < count; i++) {
      final int index = readWord();
      out.write('$vector1Name[$index]');
      if (i < count - 1) {
        out.write(', ');
      }
    }
    out.writeln(');');
  }

  void opCompositeConstruct() {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    out.write('$indent$type $name = $type(');
    final int count = nextPosition - position;
    for (int i = 0; i < count; i++) {
      out.write(resolveName(readWord()));
      if (i < count - 1) {
        out.write(', ');
      }
    }
    out.writeln(');');
  }

  void opCompositeExtract() {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    final String src = resolveName(readWord());
    out.write('$indent$type $name = $src');
    final int count = nextPosition - position;
    for (int i = 0; i < count; i++) {
      final int index = readWord();
      out.write('[$index]');
    }
    out.writeln(';');
  }

  void opFNegate() {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    final String operand = resolveName(readWord());
    out.writeln('$indent$type $name = -$operand;');
  }

  void opLabel() {
    out.writeln('{');
    indent = indent + '  ';
    if (target == TargetLanguage.sksl && currentFunction == entryPoint) {
      final String ind = indent;
      if (fragCoord > 0) {
        final String fragName = resolveName(fragCoord);
        out
          ..write(ind)
          ..writeln('float4 $fragName = float4($_fragParamName, 0, 0);');
      }
      out
        ..write(ind)
        ..writeln('float4 $_colorVariableName;');
    }
  }

  void opReturn() {
    if (currentFunction == entryPoint) {
      return;
    }
    out.writeln(indent + 'return;');
  }

  void opReturnValue() {
    final String name = resolveName(readWord());
    out.writeln(indent + 'return $name;');
  }

  void parseOperatorInst(String op) {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    final String a = resolveName(readWord());
    final String b = resolveName(readWord());
    out.writeln('$indent$type $name = $a $op $b;');
  }

  void parseBuiltinFunction(String functionName) {
    final String type = resolveType(readWord());
    final String name = resolveName(readWord());
    out.write('$indent$type $name = $functionName(');
    final int count = nextPosition - position;
    for (int i = 0; i < count; i++) {
      out.write(resolveName(readWord()));
      if (i < count - 1) {
        out.write(', ');
      }
    }
    out.writeln(');');
  }

  void parseGLSLInst(int id, int type) {
    final int inst = readWord();
    final String? opName = _glslStd450OpNames[inst];
    if (opName == null) {
      throw failure('$id is not a supported GLSL instruction.');
    }
    final int argc = _glslStd450OpArgc[inst]!;
    parseGLSLOp(id, type, opName, argc);
  }

  void parseGLSLOp(int id, int type, String name, int argCount) {
    final String resultName = resolveName(id);
    final String typeName = resolveType(type);
    out.write('$indent$typeName $resultName = $name(');
    for (int i = 0; i < argCount; i++) {
      out.write(resolveName(readWord()));
      if (i < argCount - 1) {
        out.write(', ');
      }
    }
    out.writeln(');');
  }
}
