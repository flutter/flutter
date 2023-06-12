// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';

/// When this option enabled, when we write AST and resolution, we write
/// into markers into the resolution stream, so when we apply resolution
/// to AST, we can be more confident that we are reading resolution data
/// that is expected to the AST node to which resolution is applied.
///
/// This might help us to track if we have a bug and think that some resolution
/// data can be applied (because its signature is the same), when actually
/// AST changed in ways that should make resolution incompatible (and so
/// the resolution signature should have been different).
bool enableDebugResolutionMarkers = false;

class AstBinaryFlags {
  static final Map<Type, int> _typeBits = {};

  static final _hasAwait = _checkBit(
    0,
    ForElement,
    ForStatement,
  );

  static final _hasConstConstructor = _checkBit(
    0,
    ClassDeclaration,
  );

  static final _hasEqual = _checkBit(
    0,
    Configuration,
  );

  static final _hasInitializer = _checkBit(
    2,
    DefaultFormalParameter,
    VariableDeclaration,
  );

  static final _hasName = _checkBit(
    5,
    ConstructorDeclaration,
    FieldFormalParameter,
    FunctionTypedFormalParameter,
    SimpleFormalParameter,
  );

  static final _hasNot = _checkBit(
    0,
    IsExpression,
  );

  static final _hasPrefix = _checkBit(
    1,
    ImportDirective,
  );

  static final _hasPeriod = _checkBit(
    0,
    IndexExpression,
    MethodInvocation,
    PropertyAccess,
  );

  static final _hasPeriod2 = _checkBit(
    1,
    MethodInvocation,
    PropertyAccess,
  );

  static final _hasQuestion = _checkBit(
    2,
    FieldFormalParameter,
    GenericFunctionType,
    IndexExpression,
    NamedType,
    PropertyAccess,
  );

  static final _hasSeparatorColon = _checkBit(
    0,
    ConstructorDeclaration,
  );

  static final _hasSeparatorEquals = _checkBit(
    2,
    ConstructorDeclaration,
  );

  static final _hasThis = _checkBit(
    0,
    ConstructorFieldInitializer,
    RedirectingConstructorInvocation,
  );

  static final _hasTypeArguments = _checkBit(
    0,
    NamedType,
    TypedLiteral,
  );

  static final _isAbstract = _checkBit(
    1,
    ClassDeclaration,
    ClassTypeAlias,
    ConstructorDeclaration,
    MethodDeclaration,
  );

  static final _isAsync = _checkBit(
    2,
    BlockFunctionBody,
    EmptyFunctionBody,
    FunctionExpression,
    MethodDeclaration,
  );

  static final _isConst = _checkBit(
    3,
    ConstructorDeclaration,
    DeclaredIdentifier,
    InstanceCreationExpression,
    NormalFormalParameter,
    TypedLiteral,
    VariableDeclarationList,
  );

  static final _isCovariant = _checkBit(
    2,
    FieldDeclaration,
    NormalFormalParameter,
  );

  static final _isDeclaration = _checkBit(
    0,
    SimpleIdentifier,
  );

  static final _isDeferred = _checkBit(
    0,
    ImportDirective,
  );

  static final _isDelimiterCurly = _checkBit(
    0,
    FormalParameterList,
  );

  static final _isDelimiterSquare = _checkBit(
    1,
    FormalParameterList,
  );

  static final _isExternal = _checkBit(
    7,
    ConstructorDeclaration,
    FunctionDeclaration,
    MethodDeclaration,
  );

  static final _isFactory = _checkBit(
    4,
    ConstructorDeclaration,
  );

  static final _isFinal = _checkBit(
    4,
    DeclaredIdentifier,
    NormalFormalParameter,
    VariableDeclarationList,
  );

  static final _isGenerator = _checkBit(
    3,
    FunctionExpression,
    MethodDeclaration,
  );

  static final _isGet = _checkBit(
    4,
    FunctionDeclaration,
    MethodDeclaration,
  );

  static final _isLate = _checkBit(
    0,
    VariableDeclarationList,
  );

  static final _isNative = _checkBit(
    8,
    MethodDeclaration,
  );

  static final _isNew = _checkBit(
    0,
    InstanceCreationExpression,
  );

  static final _isOperator = _checkBit(
    0,
    MethodDeclaration,
  );

  static final _isPositional = _checkBit(
    1,
    DefaultFormalParameter,
  );

  static final _isRequired = _checkBit(
    0,
    DefaultFormalParameter,
    NormalFormalParameter,
  );

  static final _isSet = _checkBit(
    5,
    FunctionDeclaration,
    MethodDeclaration,
    TypedLiteral,
  );

  static final _isStar = _checkBit(
    0,
    BlockFunctionBody,
    YieldStatement,
  );

  static final _isStatic = _checkBit(
    6,
    FieldDeclaration,
    MethodDeclaration,
  );

  static final _isStringInterpolationIdentifier = _checkBit(
    0,
    InterpolationExpression,
  );

  static final _isSync = _checkBit(
    3,
    BlockFunctionBody,
    ExpressionFunctionBody,
  );

  static final _isVar = _checkBit(
    1,
    DeclaredIdentifier,
    NormalFormalParameter,
    VariableDeclarationList,
  );

  static int encode({
    bool hasAwait = false,
    bool hasConstConstructor = false,
    bool hasEqual = false,
    bool hasInitializer = false,
    bool hasName = false,
    bool hasNot = false,
    bool hasPeriod = false,
    bool hasPeriod2 = false,
    bool hasPrefix = false,
    bool hasQuestion = false,
    bool hasSeparatorColon = false,
    bool hasSeparatorEquals = false,
    bool hasThis = false,
    bool hasTypeArguments = false,
    bool isAbstract = false,
    bool isAsync = false,
    bool isConst = false,
    bool isCovariant = false,
    bool isDeclaration = false,
    bool isDeferred = false,
    bool isDelimiterCurly = false,
    bool isDelimiterSquare = false,
    bool isExternal = false,
    bool isFactory = false,
    bool isFinal = false,
    bool isGenerator = false,
    bool isGet = false,
    bool isLate = false,
    bool isNative = false,
    bool isNew = false,
    bool isOperator = false,
    bool isPositional = false,
    bool isRequired = false,
    bool isSet = false,
    bool isStar = false,
    bool isStatic = false,
    bool isStringInterpolationIdentifier = false,
    bool isSync = false,
    bool isVar = false,
  }) {
    var result = 0;
    if (hasAwait) {
      result |= _hasAwait;
    }
    if (hasConstConstructor) {
      result |= _hasConstConstructor;
    }
    if (hasEqual) {
      result |= _hasEqual;
    }
    if (hasInitializer) {
      result |= _hasInitializer;
    }
    if (hasName) {
      result |= _hasName;
    }
    if (hasNot) {
      result |= _hasNot;
    }
    if (hasPeriod) {
      result |= _hasPeriod;
    }
    if (hasPeriod2) {
      result |= _hasPeriod2;
    }
    if (hasPrefix) {
      result |= _hasPrefix;
    }
    if (hasQuestion) {
      result |= _hasQuestion;
    }
    if (hasSeparatorColon) {
      result |= _hasSeparatorColon;
    }
    if (hasSeparatorEquals) {
      result |= _hasSeparatorEquals;
    }
    if (hasThis) {
      result |= _hasThis;
    }
    if (hasTypeArguments) {
      result |= _hasTypeArguments;
    }
    if (isAbstract) {
      result |= _isAbstract;
    }
    if (isAsync) {
      result |= _isAsync;
    }
    if (isCovariant) {
      result |= _isCovariant;
    }
    if (isDeclaration) {
      result |= _isDeclaration;
    }
    if (isDeferred) {
      result |= _isDeferred;
    }
    if (isDelimiterCurly) {
      result |= _isDelimiterCurly;
    }
    if (isDelimiterSquare) {
      result |= _isDelimiterSquare;
    }
    if (isConst) {
      result |= _isConst;
    }
    if (isExternal) {
      result |= _isExternal;
    }
    if (isFactory) {
      result |= _isFactory;
    }
    if (isFinal) {
      result |= _isFinal;
    }
    if (isGenerator) {
      result |= _isGenerator;
    }
    if (isGet) {
      result |= _isGet;
    }
    if (isLate) {
      result |= _isLate;
    }
    if (isNative) {
      result |= _isNative;
    }
    if (isNew) {
      result |= _isNew;
    }
    if (isOperator) {
      result |= _isOperator;
    }
    if (isPositional) {
      result |= _isPositional;
    }
    if (isRequired) {
      result |= _isRequired;
    }
    if (isSet) {
      result |= _isSet;
    }
    if (isStar) {
      result |= _isStar;
    }
    if (isStatic) {
      result |= _isStatic;
    }
    if (isStringInterpolationIdentifier) {
      result |= _isStringInterpolationIdentifier;
    }
    if (isSync) {
      result |= _isSync;
    }
    if (isVar) {
      result |= _isVar;
    }
    return result;
  }

  static bool hasAwait(int flags) {
    return (flags & _hasAwait) != 0;
  }

  static bool hasConstConstructor(int flags) {
    return (flags & _hasConstConstructor) != 0;
  }

  static bool hasEqual(int flags) {
    return (flags & _hasEqual) != 0;
  }

  static bool hasInitializer(int flags) {
    return (flags & _hasInitializer) != 0;
  }

  static bool hasName(int flags) {
    return (flags & _hasName) != 0;
  }

  static bool hasNot(int flags) {
    return (flags & _hasNot) != 0;
  }

  static bool hasPeriod(int flags) {
    return (flags & _hasPeriod) != 0;
  }

  static bool hasPeriod2(int flags) {
    return (flags & _hasPeriod2) != 0;
  }

  static bool hasPrefix(int flags) {
    return (flags & _hasPrefix) != 0;
  }

  static bool hasQuestion(int flags) {
    return (flags & _hasQuestion) != 0;
  }

  static bool hasSeparatorColon(int flags) {
    return (flags & _hasSeparatorColon) != 0;
  }

  static bool hasSeparatorEquals(int flags) {
    return (flags & _hasSeparatorEquals) != 0;
  }

  static bool hasThis(int flags) {
    return (flags & _hasThis) != 0;
  }

  static bool hasTypeArguments(int flags) {
    return (flags & _hasTypeArguments) != 0;
  }

  static bool isAbstract(int flags) {
    return (flags & _isAbstract) != 0;
  }

  static bool isAsync(int flags) {
    return (flags & _isAsync) != 0;
  }

  static bool isConst(int flags) {
    return (flags & _isConst) != 0;
  }

  static bool isCovariant(int flags) {
    return (flags & _isCovariant) != 0;
  }

  static bool isDeclaration(int flags) {
    return (flags & _isDeclaration) != 0;
  }

  static bool isDeferred(int flags) {
    return (flags & _isDeferred) != 0;
  }

  static bool isDelimiterCurly(int flags) {
    return (flags & _isDelimiterCurly) != 0;
  }

  static bool isDelimiterSquare(int flags) {
    return (flags & _isDelimiterSquare) != 0;
  }

  static bool isExternal(int flags) {
    return (flags & _isExternal) != 0;
  }

  static bool isFactory(int flags) {
    return (flags & _isFactory) != 0;
  }

  static bool isFinal(int flags) {
    return (flags & _isFinal) != 0;
  }

  static bool isGenerator(int flags) {
    return (flags & _isGenerator) != 0;
  }

  static bool isGet(int flags) {
    return (flags & _isGet) != 0;
  }

  static bool isLate(int flags) {
    return (flags & _isLate) != 0;
  }

  static bool isNative(int flags) {
    return (flags & _isNative) != 0;
  }

  static bool isNew(int flags) {
    return (flags & _isNew) != 0;
  }

  static bool isOperator(int flags) {
    return (flags & _isOperator) != 0;
  }

  static bool isPositional(int flags) {
    return (flags & _isPositional) != 0;
  }

  static bool isRequired(int flags) {
    return (flags & _isRequired) != 0;
  }

  static bool isSet(int flags) {
    return (flags & _isSet) != 0;
  }

  static bool isStar(int flags) {
    return (flags & _isStar) != 0;
  }

  static bool isStatic(int flags) {
    return (flags & _isStatic) != 0;
  }

  static bool isStringInterpolationIdentifier(int flags) {
    return (flags & _isStringInterpolationIdentifier) != 0;
  }

  static bool isSync(int flags) {
    return (flags & _isSync) != 0;
  }

  static bool isVar(int flags) {
    return (flags & _isVar) != 0;
  }

  /// Check the bit for its uniqueness for the given types.
  static int _checkBit(int shift, Type type1,
      [Type? type2, Type? type3, Type? type4, Type? type5, Type? type6]) {
    _checkBit0(shift, type1);
    _checkBit0(shift, type2);
    _checkBit0(shift, type3);
    _checkBit0(shift, type4);
    _checkBit0(shift, type5);
    _checkBit0(shift, type6);
    return 1 << shift;
  }

  /// Check the bit for its uniqueness for the [type].
  static void _checkBit0(int shift, Type? type) {
    if (type != null) {
      var currentBits = _typeBits[type] ?? 0;
      var bit = 1 << shift;
      if ((currentBits & bit) != 0) {
        throw StateError('1 << $shift is already used for $type');
      }
      _typeBits[type] = currentBits | bit;
    }
  }
}
