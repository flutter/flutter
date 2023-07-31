// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class AliasedElementTag {
  static const int nothing = 0;
  static const int genericFunctionElement = 1;
}

enum DirectiveUriKind {
  withAugmentation,
  withLibrary,
  withUnit,
  withSource,
  withRelativeUri,
  withRelativeUriString,
  withNothing,
}

enum ImportElementPrefixKind {
  isDeferred,
  isNotDeferred,
  isNull,
}

class Tag {
  static const int Nothing = 0;
  static const int Something = 1;

  static const int AdjacentStrings = 75;
  static const int Annotation = 2;
  static const int ArgumentList = 3;
  static const int AsExpression = 84;
  static const int AssertInitializer = 82;
  static const int AssignmentExpression = 96;
  static const int AwaitExpression = 100;
  static const int BinaryExpression = 52;
  static const int BooleanLiteral = 4;
  static const int CascadeExpression = 95;
  static const int ConditionalExpression = 51;
  static const int ConstructorFieldInitializer = 50;
  static const int ConstructorName = 7;
  static const int ConstructorReference = 101;
  static const int DeclaredIdentifier = 90;
  static const int DefaultFormalParameter = 8;
  static const int DottedName = 47;
  static const int DoubleLiteral = 9;
  static const int ExtensionOverride = 87;
  static const int FieldFormalParameter = 16;
  static const int ForEachPartsWithDeclaration = 89;
  static const int ForElement = 88;
  static const int ForPartsWithDeclarations = 91;
  static const int ForPartsWithExpression = 99;
  static const int FormalParameterList = 17;
  static const int FunctionDeclaration_getter = 57;
  static const int FunctionDeclaration_setter = 58;
  static const int FunctionExpressionStub = 19;
  static const int FunctionExpressionInvocation = 93;
  static const int FunctionReference = 103;
  static const int FunctionTypedFormalParameter = 20;
  static const int GenericFunctionType = 21;
  static const int HideCombinator = 48;
  static const int IfElement = 63;
  static const int ImplicitCallReference = 104;
  static const int IndexExpression = 98;
  static const int InstanceCreationExpression = 25;
  static const int IntegerLiteralNegative = 73;
  static const int IntegerLiteralNegative1 = 71;
  static const int IntegerLiteralNull = 97;
  static const int IntegerLiteralPositive = 72;
  static const int IntegerLiteralPositive1 = 26;
  static const int InterpolationExpression = 77;
  static const int InterpolationString = 78;
  static const int IsExpression = 83;
  static const int ListLiteral = 56;
  static const int MapLiteralEntry = 66;
  static const int MethodDeclaration_getter = 85;
  static const int MethodDeclaration_setter = 86;
  static const int MethodInvocation = 59;
  static const int NamedExpression = 60;
  static const int NamedType = 39;
  static const int NullLiteral = 49;
  static const int ParenthesizedExpression = 53;
  static const int PostfixExpression = 94;
  static const int PrefixExpression = 79;
  static const int PrefixedIdentifier = 32;
  static const int PropertyAccess = 62;
  static const int RecordLiteral = 105;
  static const int RedirectingConstructorInvocation = 54;
  static const int SetOrMapLiteral = 65;
  static const int ShowCombinator = 33;
  static const int SimpleFormalParameter = 34;
  static const int SimpleIdentifier = 35;
  static const int SimpleStringLiteral = 36;
  static const int SpreadElement = 64;
  static const int StringInterpolation = 76;
  static const int SuperConstructorInvocation = 69;
  static const int SuperExpression = 80;
  static const int SymbolLiteral = 74;
  static const int ThisExpression = 70;
  static const int ThrowExpression = 81;
  static const int TypeArgumentList = 38;
  static const int TypeLiteral = 102;
  static const int TypeParameter = 40;
  static const int TypeParameterList = 41;
  static const int VariableDeclaration = 42;
  static const int VariableDeclarationList = 43;

  static const int RawElement = 0;
  static const int MemberLegacyWithoutTypeArguments = 1;
  static const int MemberLegacyWithTypeArguments = 2;
  static const int MemberWithTypeArguments = 3;
  static const int ImportPrefixElement = 4;

  static const int ParameterKindRequiredPositional = 1;
  static const int ParameterKindOptionalPositional = 2;
  static const int ParameterKindRequiredNamed = 3;
  static const int ParameterKindOptionalNamed = 4;

  static const int NullType = 2;
  static const int DynamicType = 3;
  static const int FunctionType = 4;
  static const int NeverType = 5;
  static const int InterfaceType = 6;
  static const int InterfaceType_noTypeArguments_none = 7;
  static const int InterfaceType_noTypeArguments_question = 8;
  static const int InterfaceType_noTypeArguments_star = 9;
  static const int RecordType = 10;
  static const int TypeParameterType = 11;
  static const int VoidType = 12;
}

enum TypeParameterVarianceTag {
  legacy,
  unrelated,
  covariant,
  contravariant,
  invariant,
}
