// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:_fe_analyzer_shared/src/macros/api.dart';

import 'introspect_shared.dart';

/*macro*/ class DeclarationTextMacro implements ClassTypesMacro {
  const DeclarationTextMacro();

  @override
  FutureOr<void> buildTypesForClass(declaration, builder) {
    final printer = _DeclarationPrinter();
    printer.writeClassDeclaration(declaration);
    final text = printer._sink.toString();

    builder.declareType(
      'x',
      DeclarationCode.fromString(
        'const x = r"""$text""";',
      ),
    );
  }
}

class _DeclarationPrinter {
  final StringBuffer _sink = StringBuffer();
  String _indent = '';

  void writeClassDeclaration(ClassDeclaration e) {
    _writeIf(e.isAbstract, 'abstract ');
    _writeIf(e.isExternal, 'external ');

    _writeln('class ${e.identifier.name}');

    _withIndent(() {
      var superclass = e.superclass;
      if (superclass != null) {
        _writeTypeAnnotation('superclass', superclass);
      }

      _writeTypeParameters(e.typeParameters);
      _writeTypeAnnotations('mixins', e.mixins);
      _writeTypeAnnotations('interfaces', e.interfaces);
    });
  }

  void _withIndent(void Function() f) {
    var savedIndent = _indent;
    _indent = '$savedIndent  ';
    f();
    _indent = savedIndent;
  }

  void _writeElements<T>(
    String name,
    Iterable<T> elements,
    void Function(T) f,
  ) {
    if (elements.isNotEmpty) {
      _writelnWithIndent(name);
      _withIndent(() {
        for (var element in elements) {
          f(element);
        }
      });
    }
  }

  void _writeIf(bool flag, String str) {
    if (flag) {
      _sink.write(str);
    }
  }

  void _writeln(String line) {
    _sink.writeln(line);
  }

  void _writelnWithIndent(String line) {
    _sink.write(_indent);
    _sink.writeln(line);
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

  void _writeTypeAnnotationLine(TypeAnnotation type) {
    _writelnWithIndent(type.asString);
  }

  void _writeTypeAnnotations(String name, Iterable<TypeAnnotation> elements) {
    _writeElements(name, elements, _writeTypeAnnotationLine);
  }

  void _writeTypeParameter(TypeParameterDeclaration e) {
    _writelnWithIndent(e.identifier.name);

    _withIndent(() {
      var bound = e.bound;
      if (bound != null) {
        _writeTypeAnnotation('bound', bound);
      }
    });
  }

  void _writeTypeParameters(Iterable<TypeParameterDeclaration> elements) {
    _writeElements('typeParameters', elements, _writeTypeParameter);
  }
}
