// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

/// A very simple macro that augments any declaration it is given, usually
/// adding print statements and inlining values from the declaration object
/// for comparison with expected values in tests.
///
/// When applied to [MethodDeclaration]s there is some extra work that happens
/// to validate the introspection APIs work as expected.
class SimpleMacro
    implements
        ClassTypesMacro,
        ClassDeclarationsMacro,
        ClassDefinitionMacro,
        ConstructorTypesMacro,
        ConstructorDeclarationsMacro,
        ConstructorDefinitionMacro,
        FieldTypesMacro,
        FieldDeclarationsMacro,
        FieldDefinitionMacro,
        FunctionTypesMacro,
        FunctionDeclarationsMacro,
        FunctionDefinitionMacro,
        MethodTypesMacro,
        MethodDeclarationsMacro,
        MethodDefinitionMacro,
        VariableTypesMacro,
        VariableDeclarationsMacro,
        VariableDefinitionMacro {
  final bool? myBool;
  final int? myInt;
  final double? myDouble;
  final Set? mySet;
  final List? myList;
  final Map? myMap;
  final String? myString;

  SimpleMacro([this.myInt])
      : myBool = null,
        myDouble = null,
        mySet = null,
        myList = null,
        myMap = null,
        myString = null;

  SimpleMacro.named(
      {required this.myBool,
      required this.myDouble,
      required this.myInt,
      required this.mySet,
      required this.myList,
      required this.myMap,
      required this.myString});

  @override
  FutureOr<void> buildDeclarationsForClass(IntrospectableClassDeclaration clazz,
      ClassMemberDeclarationBuilder builder) async {
    var fields = await builder.fieldsOf(clazz);
    builder.declareInClass(DeclarationCode.fromParts([
      'static const List<String> fieldNames = [',
      for (var field in fields) "'${field.identifier.name}',",
      '];',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForConstructor(
      ConstructorDeclaration constructor,
      ClassMemberDeclarationBuilder builder) {
    var className = constructor.definingClass.name;
    var constructorName = constructor.identifier.name;
    builder.declareInClass(DeclarationCode.fromString(
        'factory $className.${constructorName}Delegate() => '
        '$className.$constructorName();'));
  }

  @override
  FutureOr<void> buildDeclarationsForFunction(
      FunctionDeclaration function, DeclarationBuilder builder) {
    var functionName = function.identifier.name;
    builder.declareInLibrary(DeclarationCode.fromParts([
      function.returnType.code,
      if (function.isGetter) ' get' else if (function.isSetter) ' set ',
      ' delegate${functionName.capitalize()}',
      if (!function.isGetter) ...[
        '(',
        if (function.isSetter) ...[
          function.positionalParameters.first.type.code,
          ' value',
        ],
        ')',
      ],
      ' => ${functionName}',
      function.isGetter
          ? ''
          : function.isSetter
              ? ' = value'
              : '()',
      ';',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForMethod(
      MethodDeclaration method, ClassMemberDeclarationBuilder builder) {
    if (method.positionalParameters.isNotEmpty ||
        method.namedParameters.isNotEmpty) {
      throw new UnsupportedError('Can only run on method with no parameters!');
    }
    var methodName = method.identifier.name;
    builder.declareInLibrary(DeclarationCode.fromParts([
      method.returnType.code,
      ' delegateMember${methodName.capitalize()}() => $methodName();',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForVariable(
      VariableDeclaration variable, DeclarationBuilder builder) {
    var variableName = variable.identifier.name;
    builder.declareInLibrary(DeclarationCode.fromParts([
      variable.type.code,
      ' get delegate${variableName.capitalize()} => $variableName;',
    ]));
  }

  @override
  FutureOr<void> buildDeclarationsForField(
      FieldDeclaration field, ClassMemberDeclarationBuilder builder) {
    var fieldName = field.identifier.name;
    builder.declareInClass(DeclarationCode.fromParts([
      field.type.code,
      ' get delegate${fieldName.capitalize()} => $fieldName;',
    ]));
  }

  @override
  Future<void> buildDefinitionForClass(IntrospectableClassDeclaration clazz,
      ClassDefinitionBuilder builder) async {
    // Apply ourself to all our members
    var fields = (await builder.fieldsOf(clazz));
    for (var field in fields) {
      await buildDefinitionForField(
          field, await builder.buildField(field.identifier));
    }
    var methods = (await builder.methodsOf(clazz));
    for (var method in methods) {
      await buildDefinitionForMethod(
          method, await builder.buildMethod(method.identifier));
    }
    var constructors = (await builder.constructorsOf(clazz));
    for (var constructor in constructors) {
      await buildDefinitionForConstructor(
          constructor, await builder.buildConstructor(constructor.identifier));
    }
  }

  @override
  Future<void> buildDefinitionForConstructor(ConstructorDeclaration constructor,
      ConstructorDefinitionBuilder builder) async {
    var clazz = await builder.declarationOf(constructor.definingClass)
        as IntrospectableClassDeclaration;
    var fields = (await builder.fieldsOf(clazz));

    builder.augment(
      body: await _buildFunctionAugmentation(constructor, builder),
      initializers: [
        for (var field in fields)
          // TODO: Compare against actual `int` type.
          if (field.isFinal &&
              (field.type as NamedTypeAnnotation).identifier.name == 'int')
            Code.fromParts([field.identifier, ' = ${myInt!}']),
      ],
    );
  }

  @override
  Future<void> buildDefinitionForField(
          FieldDeclaration field, VariableDefinitionBuilder builder) async =>
      buildDefinitionForVariable(field, builder);

  @override
  Future<void> buildDefinitionForFunction(
      FunctionDeclaration function, FunctionDefinitionBuilder builder) async {
    builder.augment(await _buildFunctionAugmentation(function, builder));
  }

  @override
  Future<void> buildDefinitionForMethod(
      MethodDeclaration method, FunctionDefinitionBuilder builder) async {
    await buildDefinitionForFunction(method, builder);

    // Test the type declaration resolver
    var parentClass = await builder.declarationOf(method.definingClass)
        as IntrospectableClassDeclaration;
    // Should be able to find ourself in the methods of the parent class.
    (await builder.methodsOf(parentClass))
        .singleWhere((m) => m.identifier == method.identifier);

    // Test the class introspector
    var superClass =
        (await builder.declarationOf(parentClass.superclass!.identifier));
    var interfaces = await Future.wait(parentClass.interfaces
        .map((interface) => builder.declarationOf(interface.identifier)));
    var mixins = await Future.wait(parentClass.mixins
        .map((mixins) => builder.declarationOf(mixins.identifier)));
    var fields = (await builder.fieldsOf(parentClass));
    var methods = (await builder.methodsOf(parentClass));
    var constructors = (await builder.constructorsOf(parentClass));

    // Test the type resolver and static type interfaces
    var staticReturnType = await builder.resolve(method.returnType.code);
    if (!(await staticReturnType.isExactly(staticReturnType))) {
      throw StateError('The return type should be exactly equal to itself!');
    }
    if (!(await staticReturnType.isSubtypeOf(staticReturnType))) {
      throw StateError('The return type should be a subtype of itself!');
    }

    // TODO: Use `builder.instantiateCode` instead once implemented.
    var classType = await builder.resolve(constructors.first.returnType.code);
    if (await staticReturnType.isExactly(classType)) {
      throw StateError(
          'The return type should not be exactly equal to the class type');
    }
    if (await staticReturnType.isSubtypeOf(classType)) {
      throw StateError(
          'The return type should not be a subtype of the class type!');
    }

    builder.augment(FunctionBodyCode.fromParts([
      '''{
      print('myBool: $myBool');
      print('myDouble: $myDouble');
      print('myInt: $myInt');
      print('myList: $myList');
      print('mySet: $mySet');
      print('myMap: $myMap');
      print('myString: $myString');
      print('parentClass: ${parentClass.identifier.name}');
      print('superClass: ${superClass.identifier.name}');''',
      for (var interface in interfaces)
        "\n      print('interface: ${interface.identifier.name}');",
      for (var mixin in mixins)
        "\n      print('mixin: ${mixin.identifier.name}');",
      for (var field in fields)
        "\n      print('field: ${field.identifier.name}');",
      for (var method in methods)
        "\n      print('method: ${method.identifier.name}');",
      for (var constructor in constructors)
        "\n      print('constructor: ${constructor.identifier.name}');",
      '''
\n      return augment super();
    }''',
    ]));
  }

  @override
  Future<void> buildDefinitionForVariable(
      VariableDeclaration variable, VariableDefinitionBuilder builder) async {
    var definingClass =
        variable is FieldDeclaration ? variable.definingClass.name : '';
    builder.augment(
      getter: DeclarationCode.fromParts([
        variable.type.code,
        ' get ',
        variable.identifier.name,
        ''' {
          print('parentClass: $definingClass');
          print('isExternal: ${variable.isExternal}');
          print('isFinal: ${variable.isFinal}');
          print('isLate: ${variable.isLate}');
          return augment super;
        }''',
      ]),
      setter: DeclarationCode.fromParts([
        'set ',
        variable.identifier.name,
        '(',
        variable.type.code,
        ' value) { augment super = value; }'
      ]),
      initializer:
          ExpressionCode.fromString("'new initial value' + augment super"),
    );
  }

  @override
  FutureOr<void> buildTypesForClass(
      ClassDeclaration clazz, TypeBuilder builder) {
    List<Object> _buildTypeParam(
        TypeParameterDeclaration typeParam, bool isFirst) {
      return [
        if (!isFirst) ', ',
        typeParam.identifier.name,
        if (typeParam.bound != null) ...[
          ' extends ',
          typeParam.bound!.code,
        ]
      ];
    }

    var name = '${clazz.identifier.name}Builder';
    builder.declareType(
        name,
        DeclarationCode.fromParts([
          'class $name',
          if (clazz.typeParameters.isNotEmpty) ...[
            '<',
            ..._buildTypeParam(clazz.typeParameters.first, true),
            for (var typeParam in clazz.typeParameters.skip(1))
              ..._buildTypeParam(typeParam, false),
            '>',
          ],
          ' implements Builder<',
          clazz.identifier,
          if (clazz.typeParameters.isNotEmpty) ...[
            '<',
            clazz.typeParameters.first.identifier.name,
            for (var typeParam in clazz.typeParameters)
              ', ${typeParam.identifier.name}',
            '>',
          ],
          '> {}'
        ]));
  }

  @override
  FutureOr<void> buildTypesForConstructor(
      ConstructorDeclaration constructor, TypeBuilder builder) {
    var name = 'GeneratedBy${constructor.identifier.name.capitalize()}';
    builder.declareType(name, DeclarationCode.fromString('class $name {}'));
  }

  @override
  FutureOr<void> buildTypesForField(
      FieldDeclaration field, TypeBuilder builder) {
    var name = 'GeneratedBy${field.identifier.name.capitalize()}';
    builder.declareType(name, DeclarationCode.fromString('class $name {}'));
  }

  @override
  FutureOr<void> buildTypesForFunction(
      FunctionDeclaration function, TypeBuilder builder) {
    var suffix = function.isGetter
        ? 'Getter'
        : function.isSetter
            ? 'Setter'
            : '';
    var name = 'GeneratedBy${function.identifier.name.capitalize()}$suffix';
    builder.declareType(name, DeclarationCode.fromString('class $name {}'));
  }

  @override
  FutureOr<void> buildTypesForMethod(
      MethodDeclaration method, TypeBuilder builder) {
    var name = 'GeneratedBy${method.identifier.name.capitalize()}';
    builder.declareType(name, DeclarationCode.fromString('class $name {}'));
  }

  @override
  FutureOr<void> buildTypesForVariable(
      VariableDeclaration variable, TypeBuilder builder) {
    var name = 'GeneratedBy${variable.identifier.name.capitalize()}';
    builder.declareType(name, DeclarationCode.fromString('class $name {}'));
  }
}

Future<FunctionBodyCode> _buildFunctionAugmentation(
    FunctionDeclaration function, TypeInferrer inferrer) async {
  Future<List<Object>> typeParts(TypeAnnotation annotation) async {
    if (annotation is OmittedTypeAnnotation) {
      var inferred = await inferrer.inferType(annotation);
      return [inferred.code, ' (inferred)'];
    }
    return [annotation.code];
  }

  return FunctionBodyCode.fromParts([
    '{\n',
    if (function is MethodDeclaration)
      "print('definingClass: ${function.definingClass.name}');\n",
    if (function is ConstructorDeclaration)
      "print('isFactory: ${function.isFactory}');\n",
    '''
      print('isAbstract: ${function.isAbstract}');
      print('isExternal: ${function.isExternal}');
      print('isGetter: ${function.isGetter}');
      print('isSetter: ${function.isSetter}');
      print('returnType: ''',
    function.returnType.code,
    "');\n",
    for (var param in function.positionalParameters) ...[
      "print('positionalParam: ",
      ...await typeParts(param.type),
      ' ${param.identifier.name}',
      "');\n",
    ],
    for (var param in function.namedParameters) ...[
      "print('namedParam: ",
      ...await typeParts(param.type),
      ' ${param.identifier.name}',
      "');\n",
    ],
    for (var param in function.typeParameters) ...[
      "print('typeParam: ${param.identifier.name} ",
      if (param.bound != null) param.bound!.code,
      "');\n",
    ],
    'return augment super',
    if (function.isSetter) ...[
      ' = ',
      function.positionalParameters.first.identifier,
    ],
    if (!function.isGetter && !function.isSetter) '()',
    ''';
    }''',
  ]);
}

extension _ on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';
}
