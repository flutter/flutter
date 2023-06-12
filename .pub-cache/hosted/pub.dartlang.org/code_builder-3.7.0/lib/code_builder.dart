// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

export 'src/allocator.dart' show Allocator;
export 'src/base.dart' show lazySpec, Spec;
export 'src/emitter.dart' show DartEmitter;
export 'src/matchers.dart' show equalsDart, EqualsDart;
export 'src/specs/class.dart' show Class, ClassBuilder;
export 'src/specs/code.dart'
    show lazyCode, Block, BlockBuilder, Code, StaticCode, ScopedCode;
export 'src/specs/constructor.dart' show Constructor, ConstructorBuilder;
export 'src/specs/directive.dart'
    show Directive, DirectiveType, DirectiveBuilder;
export 'src/specs/enum.dart'
    show Enum, EnumBuilder, EnumValue, EnumValueBuilder;
export 'src/specs/expression.dart'
    show
        ToCodeExpression,
        BinaryExpression,
        CodeExpression,
        Expression,
        ExpressionEmitter,
        ExpressionVisitor,
        InvokeExpression,
        InvokeExpressionType,
        LiteralExpression,
        LiteralListExpression,
        literal,
        literalNull,
        literalNum,
        literalBool,
        literalList,
        literalConstList,
        literalSet,
        literalConstSet,
        literalMap,
        literalConstMap,
        literalString,
        literalTrue,
        literalFalse;
export 'src/specs/extension.dart' show Extension, ExtensionBuilder;
export 'src/specs/field.dart' show Field, FieldBuilder, FieldModifier;
export 'src/specs/library.dart' show Library, LibraryBuilder;
export 'src/specs/method.dart'
    show
        Method,
        MethodBuilder,
        MethodModifier,
        MethodType,
        Parameter,
        ParameterBuilder;
export 'src/specs/reference.dart' show refer, Reference;
export 'src/specs/type_function.dart' show FunctionType, FunctionTypeBuilder;
export 'src/specs/type_reference.dart' show TypeReference, TypeReferenceBuilder;
