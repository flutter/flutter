// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/api.dart';

class _TypeAnnotationStringBuilder {
  final StringSink _sink;

  _TypeAnnotationStringBuilder(this._sink);

  void write(TypeAnnotation type) {
    if (type is FunctionTypeAnnotation) {
      _writeFunctionTypeAnnotation(type);
    } else if (type is NamedTypeAnnotation) {
      _writeNamedTypeAnnotation(type);
    } else if (type is OmittedTypeAnnotation) {
      _sink.write('OmittedType');
    } else {
      throw UnimplementedError('(${type.runtimeType}) $type');
    }
    if (type.isNullable) {
      _sink.write('?');
    }
  }

  void _writeFormalParameter(FunctionTypeParameter node) {
    final String closeSeparator;
    if (node.isNamed) {
      _sink.write('{');
      closeSeparator = '}';
      if (node.isRequired) {
        _sink.write('required ');
      }
    } else if (!node.isRequired) {
      _sink.write('[');
      closeSeparator = ']';
    } else {
      closeSeparator = '';
    }

    write(node.type);
    if (node.name != null) {
      _sink.write(' ');
      _sink.write(node.name);
    }

    _sink.write(closeSeparator);
  }

  void _writeFunctionTypeAnnotation(FunctionTypeAnnotation type) {
    write(type.returnType);
    _sink.write(' Function');

    _sink.writeList(
      elements: type.typeParameters,
      write: _writeTypeParameter,
      separator: ', ',
      open: '<',
      close: '>',
    );

    _sink.write('(');
    var hasFormalParameter = false;
    for (final formalParameter in type.positionalParameters) {
      if (hasFormalParameter) {
        _sink.write(', ');
      }
      _writeFormalParameter(formalParameter);
      hasFormalParameter = true;
    }
    for (final formalParameter in type.namedParameters) {
      if (hasFormalParameter) {
        _sink.write(', ');
      }
      _writeFormalParameter(formalParameter);
      hasFormalParameter = true;
    }
    _sink.write(')');
  }

  void _writeNamedTypeAnnotation(NamedTypeAnnotation type) {
    _sink.write(type.identifier.name);
    _sink.writeList(
      elements: type.typeArguments,
      write: write,
      separator: ', ',
      open: '<',
      close: '>',
    );
  }

  void _writeTypeParameter(TypeParameterDeclaration node) {
    _sink.write(node.identifier.name);

    final bound = node.bound;
    if (bound != null) {
      _sink.write(' extends ');
      write(bound);
    }
  }
}

extension on StringSink {
  void writeList<T>({
    required Iterable<T> elements,
    required void Function(T element) write,
    required String separator,
    String? open,
    String? close,
  }) {
    elements = elements.toList();
    if (elements.isEmpty) {
      return;
    }

    if (open != null) {
      this.write(open);
    }
    var isFirst = true;
    for (var element in elements) {
      if (isFirst) {
        isFirst = false;
      } else {
        this.write(separator);
      }
      write(element);
    }
    if (close != null) {
      this.write(close);
    }
  }
}

extension E on TypeAnnotation {
  String get asString {
    final buffer = StringBuffer();
    _TypeAnnotationStringBuilder(buffer).write(this);
    return buffer.toString();
  }
}
