// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of spirv;

// This file contains a subset of SPIR-V constants defined at
// https://www.khronos.org/registry/spir-v/specs/unified1/SPIRV.html

// Header constants
const int _magicNumber = 0x07230203;

// Supported ExecutionModes
const int _originLowerLeft = 8;

// Supported memory models
const int _addressingModelLogical = 0;
const int _memoryModelGLSL450 = 1;

// Supported capabilities
const int _capabilityMatrix = 0;
const int _capabilityShader = 1;

// Supported storage classes
const int _storageClassUniformConstant = 0;
const int _storageClassInput = 1;
const int _storageClassOutput = 3;
const int _storageClassFunction = 7;

// Explicity supported decorations, others are ignored
const int _decorationBuiltIn = 11;
const int _decorationLocation = 30;

// Explicitly supported builtin types
const int _builtinFragCoord = 15;

// Explicitly supported dimensionalities
const int _dim2D = 1;

// Ops that have no semantic meaning in output and can be safely ignored
const int _opSource = 3;
const int _opSourceExtension = 4;
const int _opName = 5;
const int _opMemberName = 6;
const int _opString = 7;
const int _opLine = 8;

// Supported instructions
const int _opExtInstImport = 11;
const int _opExtInst = 12;
const int _opMemoryModel = 14;
const int _opEntryPoint = 15;
const int _opExecutionMode = 16;
const int _opCapability = 17;
const int _opTypeVoid = 19;
const int _opTypeBool = 20;
const int _opTypeInt = 21;
const int _opTypeFloat = 22;
const int _opTypeVector = 23;
const int _opTypeMatrix = 24;
const int _opTypeImage = 25;
const int _opTypeSampledImage = 27;
const int _opTypePointer = 32;
const int _opTypeFunction = 33;
const int _opConstantTrue = 41;
const int _opConstantFalse = 42;
const int _opConstant = 43;
const int _opConstantComposite = 44;
const int _opFunction = 54;
const int _opFunctionParameter = 55;
const int _opFunctionEnd = 56;
const int _opFunctionCall = 57;
const int _opVariable = 59;
const int _opLoad = 61;
const int _opStore = 62;
const int _opAccessChain = 65;
const int _opDecorate = 71;
const int _opVectorShuffle = 79;
const int _opCompositeConstruct = 80;
const int _opCompositeExtract = 81;
const int _opImageSampleImplicitLod = 87;
const int _opImageQuerySize = 104;
const int _opConvertFToS = 110;
const int _opConvertSToF = 111;
const int _opFNegate = 127;
const int _opFAdd = 129;
const int _opFSub = 131;
const int _opFMul = 133;
const int _opFDiv = 136;
const int _opFMod = 141;
const int _opVectorTimesScalar = 142;
const int _opMatrixTimesScalar = 143;
const int _opVectorTimesMatrix = 144;
const int _opMatrixTimesVector = 145;
const int _opMatrixTimesMatrix = 146;
const int _opDot = 148;
const int _opFOrdEqual = 180;
const int _opFUnordNotEqual = 183;
const int _opFOrdLessThan = 184;
const int _opFOrdGreaterThan = 186;
const int _opFOrdLessThanEqual = 188;
const int _opFOrdGreaterThanEqual = 190;
const int _opLogicalEqual = 164;
const int _opLogicalNotEqual = 165;
const int _opLogicalOr = 166;
const int _opLogicalAnd = 167;
const int _opLogicalNot = 168;
const int _opSelect = 169;
const int _opLoopMerge = 246;
const int _opSelectionMerge = 247;
const int _opLabel = 248;
const int _opBranch = 249;
const int _opBranchConditional = 250;
const int _opReturn = 253;
const int _opReturnValue = 254;

// GLSL extension constants defined at
// https://www.khronos.org/registry/spir-v/specs/unified1/GLSL.std.450.html

// Supported GLSL extension name
const String _glslStd450 = 'GLSL.std.450';

// Supported GLSL ops
const int _glslStd450FAbs = 4;
const int _glslStd450FSign = 6;
const int _glslStd450Floor = 8;
const int _glslStd450Ceil = 9;
const int _glslStd450Fract = 10;
const int _glslStd450Radians = 11;
const int _glslStd450Degrees = 12;
const int _glslStd450Sin = 13;
const int _glslStd450Cos = 14;
const int _glslStd450Tan = 15;
const int _glslStd450Asin = 16;
const int _glslStd450Acos = 17;
const int _glslStd450Atan = 18;
const int _glslStd450Atan2 = 25;
const int _glslStd450Pow = 26;
const int _glslStd450Exp = 27;
const int _glslStd450Log = 28;
const int _glslStd450Exp2 = 29;
const int _glslStd450Log2 = 30;
const int _glslStd450Sqrt = 31;
const int _glslStd450InverseSqrt = 32;
const int _glslStd450FMin = 37;
const int _glslStd450FMax = 40;
const int _glslStd450FClamp = 43;
const int _glslStd450FMix = 46;
const int _glslStd450Step = 48;
const int _glslStd450SmoothStep = 49;
const int _glslStd450Length = 66;
const int _glslStd450Distance = 67;
const int _glslStd450Cross = 68;
const int _glslStd450Normalize = 69;
const int _glslStd450FaceForward = 70;
const int _glslStd450Reflect = 71;

const Map<int, String> _glslStd450OpNames = <int, String>{
  _glslStd450FAbs: 'abs',
  _glslStd450FSign: 'sign',
  _glslStd450Floor: 'floor',
  _glslStd450Ceil: 'ceil',
  _glslStd450Fract: 'fract',
  _glslStd450Radians: 'radians',
  _glslStd450Degrees: 'degrees',
  _glslStd450Sin: 'sin',
  _glslStd450Cos: 'cos',
  _glslStd450Tan: 'tan',
  _glslStd450Asin: 'asin',
  _glslStd450Acos: 'acos',
  _glslStd450Atan: 'atan',
  _glslStd450Atan2: 'atan2',
  _glslStd450Pow: 'pow',
  _glslStd450Exp: 'exp',
  _glslStd450Log: 'log',
  _glslStd450Exp2: 'exp2',
  _glslStd450Log2: 'log2',
  _glslStd450Sqrt: 'sqrt',
  _glslStd450InverseSqrt: 'inversesqrt',
  _glslStd450FMin: 'min',
  _glslStd450FMax: 'max',
  _glslStd450FClamp: 'clamp',
  _glslStd450FMix: 'mix',
  _glslStd450Step: 'step',
  _glslStd450SmoothStep: 'smoothstep',
  _glslStd450Length: 'length',
  _glslStd450Distance: 'distance',
  _glslStd450Cross: 'cross',
  _glslStd450Normalize: 'normalize',
  _glslStd450FaceForward: 'faceforward',
  _glslStd450Reflect: 'reflect',
};

const Map<int, int> _glslStd450OpArgc = <int, int>{
  _glslStd450FAbs: 1,
  _glslStd450FSign: 1,
  _glslStd450Floor: 1,
  _glslStd450Ceil: 1,
  _glslStd450Fract: 1,
  _glslStd450Radians: 1,
  _glslStd450Degrees: 1,
  _glslStd450Sin: 1,
  _glslStd450Cos: 1,
  _glslStd450Tan: 1,
  _glslStd450Asin: 1,
  _glslStd450Acos: 1,
  _glslStd450Atan: 1,
  _glslStd450Atan2: 2,
  _glslStd450Pow: 2,
  _glslStd450Exp: 1,
  _glslStd450Log: 1,
  _glslStd450Exp2: 1,
  _glslStd450Log2: 1,
  _glslStd450Sqrt: 1,
  _glslStd450InverseSqrt: 1,
  _glslStd450FMin: 2,
  _glslStd450FMax: 2,
  _glslStd450FClamp: 3,
  _glslStd450FMix: 3,
  _glslStd450Step: 2,
  _glslStd450SmoothStep: 3,
  _glslStd450Length: 1,
  _glslStd450Distance: 2,
  _glslStd450Cross: 2,
  _glslStd450Normalize: 1,
  _glslStd450FaceForward: 3,
  _glslStd450Reflect: 2,
};

enum _Operator {
  addition,
  subtraction,
  division,
  multiplication,
  modulo,
  negation,
  equality,
  inequality,
  and,
  or,
  not,
  lessThan,
  greaterThan,
  lessThanEqual,
  greaterThanEqual,
}

const Set<_Operator> _compoundAssignmentOperators = <_Operator>{
  _Operator.addition,
  _Operator.subtraction,
  _Operator.division,
  _Operator.multiplication,
  _Operator.modulo,
};

const Map<_Operator, String> _operatorStrings = <_Operator, String>{
  _Operator.addition: '+',
  _Operator.subtraction: '-',
  _Operator.division: '/',
  _Operator.multiplication: '*',
  _Operator.modulo: '%',
  _Operator.negation: '-',
  _Operator.equality: '==',
  _Operator.inequality: '!=',
  _Operator.and: '&&',
  _Operator.or: '||',
  _Operator.not: '!',
  _Operator.lessThan: '<',
  _Operator.greaterThan: '>',
  _Operator.lessThanEqual: '<=',
  _Operator.greaterThanEqual: '>=',
};

String _operatorString(_Operator op) {
  return _operatorStrings[op]!;
}

bool _isCompoundAssignment(_Operator op) {
  return _compoundAssignmentOperators.contains(op);
}
