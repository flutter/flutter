// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

const introspectMacro = IntrospectDeclarationsPhaseMacro();

const introspectMacroX = IntrospectDeclarationsPhaseMacro(
  withDetailsFor: {'X'},
);

/*macro*/ class IntrospectDeclarationsPhaseMacro
    implements ClassDeclarationsMacro {
  final Set<Object?> withDetailsFor;

  const IntrospectDeclarationsPhaseMacro({
    this.withDetailsFor = const {},
  });

  @override
  Future<void> buildDeclarationsForClass(
    IntrospectableClassDeclaration declaration,
    ClassMemberDeclarationBuilder builder,
  ) async {
    final printer = _DeclarationPrinter(
      withDetailsFor: withDetailsFor.cast(),
      typeIntrospector: builder,
      identifierResolver: builder,
      typeDeclarationResolver: builder,
      typeResolver: builder,
    );
    await printer.writeClassDeclaration(declaration);
    final text = printer._sink.toString();

    final resultName = 'introspect_${declaration.identifier.name}';
    builder.declareInLibrary(
      DeclarationCode.fromString(
        'const $resultName = r"""$text""";',
      ),
    );
  }
}

class _DeclarationPrinter {
  final Set<String> withDetailsFor;
  final TypeIntrospector typeIntrospector;
  final IdentifierResolver identifierResolver;
  final TypeDeclarationResolver typeDeclarationResolver;
  final TypeResolver typeResolver;

  final StringBuffer _sink = StringBuffer();
  String _indent = '';

  Identifier? _enclosingDeclarationIdentifier;

  _DeclarationPrinter({
    required this.withDetailsFor,
    required this.typeIntrospector,
    required this.identifierResolver,
    required this.typeDeclarationResolver,
    required this.typeResolver,
  });

  Future<void> writeClassDeclaration(IntrospectableClassDeclaration e) async {
    _sink.write(_indent);
    _writeIf(e.isAbstract, 'abstract ');
    _writeIf(e.isExternal, 'external ');

    _writeln('class ${e.identifier.name}');

    if (!_shouldWriteDetailsFor(e)) {
      return;
    }

    await _withIndent(() async {
      final superAnnotation = e.superclass;
      if (superAnnotation != null) {
        final superIdentifier = superAnnotation.identifier;
        _writelnWithIndent('superclass');
        try {
          final superDeclaration = await typeDeclarationResolver
              .declarationOf(superIdentifier) as IntrospectableClassDeclaration;
          await _withIndent(() => writeClassDeclaration(superDeclaration));
        } on ArgumentError {
          await _withIndent(() async {
            _writelnWithIndent('notType ${superIdentifier.name}');
          });
        }
      }

      await _writeTypeParameters(e.typeParameters);
      await _writeTypeAnnotations('mixins', e.mixins);
      await _writeTypeAnnotations('interfaces', e.interfaces);

      _enclosingDeclarationIdentifier = e.identifier;
      await _writeElements<FieldDeclaration>(
        'fields',
        await typeIntrospector.fieldsOf(e),
        _writeField,
      );
    });
  }

  void _assertEnclosingClass(ClassMemberDeclaration e) {
    if (e.definingClass != _enclosingDeclarationIdentifier) {
      throw StateError('Mismatch: definingClass');
    }
  }

  bool _shouldWriteDetailsFor(Declaration declaration) {
    return withDetailsFor.isEmpty ||
        withDetailsFor.contains(declaration.identifier.name);
  }

  Future<void> _withIndent(Future<void> Function() f) async {
    final savedIndent = _indent;
    _indent = '$savedIndent  ';
    await f();
    _indent = savedIndent;
  }

  Future<void> _writeElements<T>(
    String name,
    Iterable<T> elements,
    Future<void> Function(T) f,
  ) async {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      await _withIndent(() async {
        for (final element in elements) {
          await f(element);
        }
      });
    }
  }

  Future<void> _writeField(FieldDeclaration e) async {
    _assertEnclosingClass(e);

    _writeIndentedLine(() {
      _writeIf(e.isStatic, 'static ');
      _writeIf(e.isExternal, 'external ');
      _writeIf(e.isLate, 'late ');
      _writeIf(e.isFinal, 'final ');
      _writeName(e);
    });

    await _withIndent(() async {
      _writeTypeAnnotation('type', e.type);
    });
  }

  void _writeIf(bool flag, String str) {
    if (flag) {
      _sink.write(str);
    }
  }

  void _writeIndentedLine(void Function() f) {
    _sink.write(_indent);
    f();
    _sink.writeln();
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
  }

  void _writeName(Declaration e) {
    _sink.write(e.identifier.name);
  }

  void _writeTypeAnnotation(String name, TypeAnnotation? type) {
    _sink.write(_indent);
    _sink.write('$name: ');

    if (type != null) {
      _writeln(type.asString);
    } else {
      _writeln('null');
    }
  }

  Future<void> _writeTypeAnnotationLine(TypeAnnotation type) async {
    _writelnWithIndent(type.asString);
  }

  Future<void> _writeTypeAnnotations(
    String name,
    Iterable<TypeAnnotation> elements,
  ) async {
    await _writeElements(name, elements, _writeTypeAnnotationLine);
  }

  Future<void> _writeTypeParameter(TypeParameterDeclaration e) async {
    _writelnWithIndent(e.identifier.name);

    await _withIndent(() async {
      final bound = e.bound;
      if (bound != null) {
        _writeTypeAnnotation('bound', bound);
      }
    });
  }

  Future<void> _writeTypeParameters(
    Iterable<TypeParameterDeclaration> elements,
  ) async {
    await _writeElements('typeParameters', elements, _writeTypeParameter);
  }
}
