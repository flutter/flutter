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
  _Transpiler(this.spirv, this.target);

  final Uint32List spirv;
  final TargetLanguage target;

  /// The resulting source code of the target language is written to src.
  final StringBuffer src = StringBuffer();

  /// Uniform declarations.
  final Map<int, String> uniformDeclarations = <int, String>{};

  /// Declarations for sampler sizes in SkSL.
  ///
  /// This is because the SkSL eval function uses texel coordinates when
  /// sampling an ImageShader, and SkSL does not support the textureSize
  /// function. These uniforms allow adding support for normalized
  /// coordinates for [opImageSampleImplicitLod].
  final Map<int, String> samplerSizeDeclarations = <int, String>{};

  /// ID mapped to numerical types.
  final Map<int, _Type> types = <int, _Type>{};

  /// ID mapped to function types.
  final Map<int, _FunctionType> functionTypes = <int, _FunctionType>{};

  /// ID mapped to function definition.
  final Map<int, _Function> functions = <int, _Function>{};

  /// ID mapped to location decorator.
  /// See [opDecorate] for more information.
  final Map<int, int> locations = <int, int>{};

  /// ID mapped to ID. Used by [OpLoad].
  final Map<int, int> alias = <int, int>{};

  /// ID mapped to a string to use instead of a generated name.
  final Map<int, String> nameOverloads = <int, String>{};

  /// ID mapped to expression result
  final Map<int, _Instruction> results = <int, _Instruction>{};

  /// The ID for a constant true value.
  /// See [opConstantTrue].
  int constantTrue = 0;

  /// The ID for a constant false value.
  /// See [opConstantFalse].
  int constantFalse = 0;

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

  /// The ID of a 32-bit int type.
  /// See [opTypeInt].
  int intType = 0;

  /// The ID of a 32-bit float type.
  /// See [opTypeFloat].
  int floatType = 0;

  /// The ID of the image type.
  /// See [opTypeImage].
  int imageType = 0;

  /// The ID of the sampledImage type.
  /// See [opTypeSampledImage].
  int sampledImageType = 0;

  /// The function that is currently being defined.
  /// Set by [opFunction] and unset by [opFunctionEnd].
  _Function? currentFunction;

  /// Count of parameters declared so far for the [currentFunction].
  int declaredParams = 0;

  /// The block currently being defined. Set by [opLabel] and unset by
  /// [opFunctionEnd].
  _Block? currentBlock;

  /// The ID for the color output variable.
  /// Set by [opVariable].
  int colorOutput = 0;

  /// The ID for the fragment coordinate builtin.
  /// Set by [opDecorate].
  int fragCoord = 0;

  /// The number of floats used by uniforms.
  int uniformFloatCount = 0;

  /// The number of samplers used by uniforms.
  int samplerCount = 0;

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

    // Add uniform declarations to header.
    if (uniformDeclarations.isNotEmpty) {
      src.writeln();
      final List<int> locations = uniformDeclarations.keys.toList();
      locations.sort((int a, int b) => a - b);
      for (final int location in locations) {
        src.writeln(uniformDeclarations[location]);
      }
    }

    // Add SkSL sampler size declarations to header.
    if (samplerSizeDeclarations.isNotEmpty) {
      src.writeln();
      final List<int> locations = samplerSizeDeclarations.keys.toList();
      locations.sort((int a, int b) => a - b);
      for (final int location in locations) {
        src.writeln(samplerSizeDeclarations[location]);
      }
    }

    src.writeln();

    // TODO(antrob): Investigate if `List<bool>.filled(maxFunctionId, false)` can be used here instead.
    final Set<int> visited = <int>{};
    writeFunctionAndDeps(visited, entryPoint);
  }

  TranspileException failure(String why) =>
      TranspileException._(currentOp, why);

  void collectDeps(Set<int> collectedDeps, int id) {
    if (alias.containsKey(id)) {
      id = alias[id]!;
      collectedDeps.add(id);
    }
    final _Instruction? result = results[id];
    if (result == null) {
      return;
    }
    for (final int i in result.deps) {
      if (!collectedDeps.contains(i)) {
        collectedDeps.add(i);
        collectDeps(collectedDeps, i);
      }
    }
  }

  void writeFunctionAndDeps(Set<int> visited, int function) {
    if (visited.contains(function)) {
      return;
    }
    visited.add(function);
    final _Function f = functions[function]!;
    for (final int dep in f.deps) {
      writeFunctionAndDeps(visited, dep);
    }
    f.write(src);
  }

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

  int resolveId(int id) {
    if (alias.containsKey(id)) {
      return alias[id]!;
    }
    return id;
  }

  String resolveName(int id) {
    if (alias.containsKey(id)) {
      return resolveName(alias[id]!);
    }
    if (nameOverloads.containsKey(id)) {
      return nameOverloads[id]!;
    } else if (constantTrue > 0 && id == constantTrue) {
      return 'true';
    } else if (constantFalse > 0 && id == constantFalse) {
      return 'false';
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

  String resolveResult(int name) {
    if (alias.containsKey(name)) {
      return resolveResult(alias[name]!);
    }
    final _Instruction? res = results[name];
    if (res != null && res.refCount <= 1) {
      final StringBuffer buf = StringBuffer();
      buf.write('(');
      res.write(this, buf);
      buf.write(')');
      return buf.toString();
    }
    return resolveName(name);
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

  /// Increase the refcount of a result with name `id`.
  void ref(int id) {
    final int? a = alias[id];
    if (a != null) {
      ref(a);
      return;
    }
    results[id]?.refCount++;
  }

  void addToCurrentBlock(_Instruction inst) {
    if (inst.isResult) {
      results[inst.id] = inst;
    }
    currentBlock!._add(inst);
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
      case _opConvertSToF:
        typeCast();
        break;
      case _opTypeVoid:
        opTypeVoid();
        break;
      case _opTypeBool:
        opTypeBool();
        break;
      case _opTypeInt:
        opTypeInt();
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
      case _opTypeImage:
        opTypeImage();
        break;
      case _opTypeSampledImage:
        opTypeSampledImage();
        break;
      case _opTypePointer:
        opTypePointer();
        break;
      case _opTypeFunction:
        opTypeFunction();
        break;
      case _opConstantTrue:
        opConstantTrue();
        break;
      case _opConstantFalse:
        opConstantFalse();
        break;
      case _opConstant:
        opConstant();
        break;
      case _opConstantComposite:
        opConstantComposite();
        break;
      case _opConvertFToS:
        typeCast();
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
      case _opSelect:
        opSelect();
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
      case _opImageSampleImplicitLod:
        opImageSampleImplicitLod();
        break;
      case _opFNegate:
        parseUnaryOperator(_Operator.subtraction);
        break;
      case _opFAdd:
        parseOperatorInst(_Operator.addition);
        break;
      case _opFSub:
        parseOperatorInst(_Operator.negation);
        break;
      case _opFMul:
        parseOperatorInst(_Operator.multiplication);
        break;
      case _opFDiv:
        parseOperatorInst(_Operator.division);
        break;
      case _opFMod:
        parseBuiltinFunction('mod');
        break;
      case _opVectorTimesScalar:
      case _opMatrixTimesScalar:
      case _opVectorTimesMatrix:
      case _opMatrixTimesVector:
      case _opMatrixTimesMatrix:
        parseOperatorInst(_Operator.multiplication);
        break;
      case _opDot:
        parseBuiltinFunction('dot');
        break;
      case _opFOrdEqual:
        parseOperatorInst(_Operator.equality);
        break;
      case _opFUnordNotEqual:
        parseOperatorInst(_Operator.inequality);
        break;
      case _opFOrdLessThan:
        parseOperatorInst(_Operator.lessThan);
        break;
      case _opFOrdGreaterThan:
        parseOperatorInst(_Operator.greaterThan);
        break;
      case _opFOrdLessThanEqual:
        parseOperatorInst(_Operator.lessThanEqual);
        break;
      case _opFOrdGreaterThanEqual:
        parseOperatorInst(_Operator.greaterThanEqual);
        break;
      case _opLogicalEqual:
        parseOperatorInst(_Operator.equality);
        break;
      case _opLogicalNotEqual:
        parseOperatorInst(_Operator.inequality);
        break;
      case _opLogicalOr:
        parseOperatorInst(_Operator.or);
        break;
      case _opLogicalAnd:
        parseOperatorInst(_Operator.and);
        break;
      case _opLogicalNot:
        parseUnaryOperator(_Operator.not);
        break;
      case _opLabel:
        opLabel();
        break;
      case _opBranch:
        opBranch();
        break;
      case _opBranchConditional:
        opBranchConditional();
        break;
      case _opLoopMerge:
        opLoopMerge();
        break;
      case _opSelectionMerge:
        opSelectionMerge();
        break;
      case _opReturn:
        opReturn();
        break;
      case _opReturnValue:
        opReturnValue();
        break;
      // Unsupported ops with no semantic meaning.
      case _opSource:
      case _opSourceExtension:
      case _opName:
      case _opMemberName:
      case _opString:
      case _opLine:
        break;
      default:
        throw failure('Not a supported op.');
    }
    position = nextPosition;
  }

  void typeCast() {
    final int type = readWord();
    final int name = readWord();
    final int value = readWord();
    ref(value);
    addToCurrentBlock(_TypeCast(type, name, value));
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

  void opTypeInt() {
    final int id = readWord();
    types[id] = _Type._int;
    intType = id;
    final int width = readWord();
    if (width != 32) {
      throw failure('int width must be 32');
    }
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

  void opTypeImage() {
    if (imageType != 0) {
      throw failure('Image type was previously declared.');
    }
    final int id = readWord();
    final int sampledType = readWord();
    if (types[sampledType] != _Type.float) {
      throw failure('Sampled type must be float.');
    }
    final int dimensionality = readWord();
    if (dimensionality != _dim2D) {
      throw failure('Dimensionality must be 2D.');
    }
    final int depth = readWord();
    if (depth != 0) {
      throw failure('Depth must be 0.');
    }
    final int arrayed = readWord();
    if (arrayed != 0) {
      throw failure('Arrayed must be 0.');
    }
    final int multisampled = readWord();
    if (multisampled != 0) {
      throw failure('Multisampled must be 0.');
    }
    final int sampled = readWord();
    if (sampled != 1) {
      throw failure('Sampled must be 1.');
    }
    imageType = id;
  }

  void opTypeSampledImage() {
    if (sampledImageType != 0) {
      throw failure('imageSampledType was previously declared.');
    }
    if (imageType == 0) {
      throw failure('imageType has not yet been declared.');
    }
    final int id = readWord();
    final int imgType = readWord();
    if (imgType != imageType) {
      throw failure('Invalid image type.');
    }
    sampledImageType = id;
    types[id] = _Type.sampledImage;
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

  void opConstantTrue() {
    position++; // Skip type operand.
    constantTrue = readWord();
  }

  void opConstantFalse() {
    position++; // Skip type operand.
    constantFalse = readWord();
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
    final int returnType = readWord();
    final int id = readWord();

    // ignore function control
    position++;

    final int typeIndex = readWord();
    final _FunctionType? functionType = functionTypes[typeIndex];
    if (functionType == null) {
      throw failure('$typeIndex is not a registered function type');
    }
    if (returnType != functionType.returnType) {
      throw failure('function $id has return type mismatch');
    }

    final _Function f = _Function(this, functionType, id);
    functions[id] = f;
    currentFunction = f;
  }

  void opFunctionParameter() {
    final int type = readWord();
    final int id = readWord();
    final _Function f = currentFunction!;
    f.declareParam(id, type);
  }

  void opFunctionEnd() {
    currentFunction = null;
    currentBlock = null;
  }

  void opFunctionCall() {
    final int type = readWord();
    final int name = readWord();
    final int functionId = readWord();
    final String functionName = resolveName(functionId);

    // Make the current function depend on this function.
    currentFunction!.deps.add(functionId);

    final List<int> args = List<int>.filled(nextPosition - position, 0);
    for (int i = 0; i < args.length; i++) {
      final int id = readWord();
      ref(id);
      args[i] = id;
    }
    addToCurrentBlock(_FunctionCall(type, name, functionName, args));
  }

  void opVariable() {
    final int typeId = readWord();
    final String type = resolveType(typeId);
    final int id = readWord();
    final String name = resolveName(id);
    final int storageClass = readWord();

    switch (storageClass) {
      case _storageClassUniformConstant:
        final int? location = locations[id];
        if (location == null) {
          throw failure('$id had no location specified');
        }
        String prefix = '';
        if (target == TargetLanguage.glslES300) {
          prefix = 'layout ( location = $location ) ';
        }
        uniformDeclarations[location] = '${prefix}uniform $type $name;';
        final _Type? t = types[typeId];
        if (t == null) {
          throw failure('$typeId is not a defined type');
        }
        if (t == _Type.sampledImage) {
          samplerCount++;
          if (target == TargetLanguage.sksl) {
            samplerSizeDeclarations[location] = 'uniform half2 ${name}_size;';
          }
        } else {
          uniformFloatCount += _typeFloatCounts[t]!;
        }
        return;
      case _storageClassInput:
        return;
      case _storageClassOutput:
        if (locations[id] == 0) {
          colorOutput = id;
        }
        return;
      case _storageClassFunction:
        // function variables are declared the first time a value is
        // stored to them.
        currentFunction!.declareVariable(id, typeId);
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

  void opSelect() {
    final int type = readWord();
    final int name = readWord();
    final int condition = readWord();
    final int a = readWord();
    final int b = readWord();
    ref(condition);
    ref(a);
    ref(b);
    addToCurrentBlock(_Select(type, name, condition, a, b));
  }

  void opStore() {
    final int pointer = readWord();
    final int object = readWord();
    ref(object);

    // Variables belonging to the current function need to be declared if they
    // haven't been already.
    final _Variable? v = currentFunction!.variable(pointer);
    if (v != null && !v.initialized) {
      addToCurrentBlock(_Store(
        pointer,
        object,
        shouldDeclare: true,
        declarationType: v.type,
      ));
      v.initialized = true;
      return;
    }

    // Is this a compound assignment operation? (x += y)
    final _Instruction? objInstruction = results[object];
    if (objInstruction is _BinaryOperator &&
        resolveId(objInstruction.a) == pointer &&
        _isCompoundAssignment(objInstruction.op)) {
      addToCurrentBlock(
          _CompoundAssignment(pointer, objInstruction.op, objInstruction.b));
      return;
    }

    addToCurrentBlock(_Store(pointer, object));
  }

  void opAccessChain() {
    final int type = readWord();
    final int id = readWord();
    final int base = readWord();
    ref(base);

    // opAccessChain currently only supports indexed access.
    // Once struct support is added, this will need to be updated.
    // Currently, structs will be caught before this method is called,
    // since using the instruction to define a struct type will throw
    // an exception.
    final List<int> indices = List<int>.filled(nextPosition - position, 0);
    for (int i = 0; i < indices.length; i++) {
      final int id = readWord();
      ref(id);
      indices[i] = id;
    }
    addToCurrentBlock(_AccessChain(type, id, base, indices));
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
    final int type = readWord();
    final int name = readWord();
    final int vector = readWord();
    // ignore second vector
    position++;
    final List<int> indices = List<int>.filled(nextPosition - position, 0);
    for (int i = 0; i < indices.length; i++) {
      ref(vector); // each index references the vector
      final int id = readWord();
      indices[i] = id;
    }
    addToCurrentBlock(_VectorShuffle(type, name, vector, indices));
  }

  void opCompositeConstruct() {
    final int type = readWord();
    final int name = readWord();
    final List<int> components = List<int>.filled(nextPosition - position, 0);
    for (int i = 0; i < components.length; i++) {
      final int id = readWord();
      ref(id);
      components[i] = id;
    }
    addToCurrentBlock(_CompositeConstruct(type, name, components));
  }

  void opCompositeExtract() {
    final int type = readWord();
    final int name = readWord();
    final int src = readWord();
    ref(src);
    final List<int> indices = List<int>.filled(nextPosition - position, 0);
    for (int i = 0; i < indices.length; i++) {
      final int index = readWord();
      indices[i] = index;
    }
    addToCurrentBlock(_CompositeExtract(type, name, src, indices));
  }

  void opImageSampleImplicitLod() {
    final int type = readWord();
    final int name = readWord();
    final int sampledImage = readWord();
    final int coordinate = readWord();
    ref(coordinate);
    addToCurrentBlock(
        _ImageSampleImplicitLod(type, name, sampledImage, coordinate));
  }

  void opLabel() {
    final int id = readWord();
    currentBlock = currentFunction!.addBlock(id);
  }

  void opBranch() {
    currentBlock!.branch = readWord();
    currentBlock = null;
  }

  void opBranchConditional() {
    final _Block b = currentBlock!;
    b.condition = readWord();
    b.truthyBlock = readWord();
    b.falseyBlock = readWord();
  }

  void opLoopMerge() {
    final _Block b = currentBlock!;
    b.mergeBlock = readWord();
    b.continueBlock = readWord();
  }

  void opSelectionMerge() {
    currentBlock!.mergeBlock = readWord();
  }

  void opReturn() {
    if (currentFunction!.name == entryPoint) {
      return;
    } else {
      addToCurrentBlock(_Return());
    }
  }

  void opReturnValue() {
    final int value = readWord();
    ref(value);
    addToCurrentBlock(_ReturnValue(value));
  }

  void parseUnaryOperator(_Operator op) {
    final int type = readWord();
    final int name = readWord();
    final int operand = readWord();
    ref(operand);
    addToCurrentBlock(_UnaryOperator(type, name, op, operand));
  }

  void parseOperatorInst(_Operator op) {
    final int type = readWord();
    final int name = readWord();
    final int a = readWord();
    final int b = readWord();
    ref(a);
    ref(b);
    addToCurrentBlock(_BinaryOperator(type, name, op, a, b));
  }

  void parseBuiltinFunction(String functionName) {
    final int type = readWord();
    final int name = readWord();
    final List<int> args = List<int>.filled(nextPosition - position, 0);
    for (int i = 0; i < args.length; i++) {
      final int id = readWord();
      ref(id);
      args[i] = id;
    }
    addToCurrentBlock(_BuiltinFunction(type, name, functionName, args));
  }

  void parseGLSLInst(int id, int type) {
    int inst = readWord();
    if (inst == _glslStd450Atan2 && target == TargetLanguage.sksl) {
      inst = _glslStd450Atan;
    }
    final String? opName = _glslStd450OpNames[inst];
    if (opName == null) {
      throw failure('$id is not a supported GLSL instruction.');
    }
    final int argc = _glslStd450OpArgc[inst]!;
    final List<int> args = List<int>.filled(argc, 0);
    for (int i = 0; i < argc; i++) {
      final int id = readWord();
      ref(id);
      args[i] = id;
    }
    addToCurrentBlock(_BuiltinFunction(type, id, opName, args));
  }
}
