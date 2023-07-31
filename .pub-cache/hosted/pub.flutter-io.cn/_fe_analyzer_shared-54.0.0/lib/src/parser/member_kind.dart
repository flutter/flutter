// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library _fe_analyzer_shared.parser.member_kind;

enum MemberKind {
  /// A catch block, not a real member.
  Catch,

  /// A factory
  Factory,

  /// Old-style typedef.
  FunctionTypeAlias,

  /// Old-style function-typed parameter, not a real member.
  FunctionTypedParameter,

  /// A generalized function type, not a real member.
  GeneralizedFunctionType,

  /// A local function.
  Local,

  /// A non-static method in a class (including constructors).
  NonStaticMethod,

  /// A static method in a class.
  StaticMethod,

  /// A top-level method.
  TopLevelMethod,

  /// A non-static method in an extension.
  ExtensionNonStaticMethod,

  /// A static method in an extension.
  ExtensionStaticMethod,

  /// An instance field in a class.
  NonStaticField,

  /// A static field in a class.
  StaticField,

  /// A top-level field.
  TopLevelField,
}
