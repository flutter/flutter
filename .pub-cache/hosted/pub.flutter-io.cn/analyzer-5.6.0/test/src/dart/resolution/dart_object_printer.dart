// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/constant/value.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:collection/collection.dart';

/// Prints [DartObjectImpl] as a tree, with values and fields.
class DartObjectPrinter {
  final StringBuffer sink;
  final String selfUriStr;

  String indent = '';

  DartObjectPrinter({
    required this.sink,
    required this.selfUriStr,
  });

  void write(DartObjectImpl? object) {
    if (object != null) {
      final type = object.type;
      final state = object.state;
      if (object.isUnknown) {
        sink.write(
          type.getDisplayString(
            withNullability: true,
          ),
        );
        sink.writeln(' <unknown>');
      } else if (type.isDartCoreBool) {
        sink.write('bool ');
        sink.writeln(object.toBoolValue());
      } else if (type.isDartCoreDouble) {
        sink.write('double ');
        sink.writeln(object.toDoubleValue());
      } else if (type.isDartCoreInt) {
        sink.write('int ');
        sink.writeln(object.toIntValue());
      } else if (type.isDartCoreNull) {
        sink.writeln('Null null');
      } else if (type.isDartCoreString) {
        sink.write('String ');
        sink.writeln(object.toStringValue());
      } else if (type.isDartCoreList) {
        type as InterfaceType;
        sink.writeln('List');
        _withIndent(() {
          _writelnWithIndent('elementType: ${type.typeArguments[0]}');
          final elements = object.toListValue()!;
          if (elements.isNotEmpty) {
            _writelnWithIndent('elements');
            _withIndent(() {
              for (final element in elements) {
                sink.write(indent);
                write(element);
              }
            });
          }
        });
      } else if (object.isUserDefinedObject) {
        final typeStr = type.getDisplayString(withNullability: true);
        sink.writeln(typeStr);
        _withIndent(() {
          final fields = object.fields;
          if (fields != null) {
            final sortedFields = fields.entries.sortedBy((e) => e.key);
            for (final entry in sortedFields) {
              sink.write(indent);
              sink.write('${entry.key}: ');
              write(entry.value);
            }
          }
        });
      } else if (state is RecordState) {
        _writeRecord(state);
      } else {
        throw UnimplementedError();
      }
      _writeVariable(object);
    } else {
      sink.writeln('<null>');
    }
  }

  String _referenceToString(Reference reference) {
    final parent = reference.parent!;
    if (parent.parent == null) {
      final libraryUriStr = reference.name;
      if (libraryUriStr == selfUriStr) {
        return 'self';
      }
      return libraryUriStr;
    }

    // Ignore the unit, skip to the library.
    if (parent.name == '@unit') {
      return _referenceToString(parent.parent!);
    }

    var name = reference.name;
    if (name.isEmpty) {
      name = '•';
    }
    return '${_referenceToString(parent)}::$name';
  }

  void _withIndent(void Function() f) {
    var savedIndent = indent;
    indent = '$savedIndent  ';
    f();
    indent = savedIndent;
  }

  void _writelnWithIndent(String line) {
    sink.write(indent);
    sink.writeln(line);
  }

  void _writeRecord(RecordState state) {
    sink.writeln('Record');
    _withIndent(() {
      final positionalFields = state.positionalFields;
      if (positionalFields.isNotEmpty) {
        _writelnWithIndent('positionalFields');
        _withIndent(() {
          positionalFields.forEachIndexed((index, field) {
            sink.write(indent);
            sink.write('\$${index + 1}: ');
            write(field);
          });
        });
      }

      final namedFields = state.namedFields;
      if (namedFields.isNotEmpty) {
        _writelnWithIndent('namedFields');
        _withIndent(() {
          final entries = namedFields.entries.sortedBy((entry) => entry.key);
          for (final entry in entries) {
            sink.write(indent);
            sink.write('${entry.key}: ');
            write(entry.value);
          }
        });
      }
    });
  }

  void _writeVariable(DartObjectImpl object) {
    final variable = object.variable;
    if (variable is VariableElementImpl) {
      _withIndent(() {
        final reference = variable.reference!;
        final referenceStr = _referenceToString(reference);
        _writelnWithIndent('variable: $referenceStr');
      });
    }
  }
}
