// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:code_builder/code_builder.dart';
import 'package:dart_style/dart_style.dart';

final _dartfmt = DartFormatter();

void main() {
  print('animalClass():\n${'=' * 40}\n${animalClass()}');
  print('scopedLibrary():\n${'=' * 40}\n${scopedLibrary()}');
  print('jsonEnum():\n${'=' * 40}\n${jsonEnum()}');
}

/// Outputs:
///
/// ```dart
/// class Animal extends Organism {
///   void eat() => print('Yum!');
/// }
/// ```
String animalClass() {
  final animal = Class((b) => b
    ..name = 'Animal'
    ..extend = refer('Organism')
    ..methods.add(Method.returnsVoid((b) => b
      ..name = 'eat'
      ..body = refer('print').call([literalString('Yum!')]).code)));
  return _dartfmt.format('${animal.accept(DartEmitter())}');
}

/// Outputs:
///
/// ```dart
/// import 'package:a/a.dart' as _i1;
/// import 'package:b/b.dart' as _i2;
///
/// _i1.Thing doThing() {}
/// _i2.Other doOther() {}
/// ```
String scopedLibrary() {
  final methods = [
    Method((b) => b
      ..body = const Code('')
      ..name = 'doThing'
      ..returns = refer('Thing', 'package:a/a.dart')),
    Method((b) => b
      ..body = const Code('')
      ..name = 'doOther'
      ..returns = refer('Other', 'package:b/b.dart')),
  ];
  final library = Library((b) => b.body.addAll(methods));
  return _dartfmt.format('${library.accept(DartEmitter.scoped())}');
}

/// Outputs:
///
/// ```dart
/// enum Unit {
///  @JsonKey('m')
///  metric,
///  @JsonKey('i')
///  imperial
/// }
/// ```
String jsonEnum() {
  final values = <EnumValue>[
    EnumValue((b) => b
      ..name = 'metric'
      ..annotations.addAll([
        refer('JsonKey').call([literalString('m')])
      ])),
    EnumValue((b) => b
      ..name = 'imperial'
      ..annotations.addAll([
        refer('JsonKey').call([literalString('i')])
      ])),
  ];
  final e = Enum((b) => b
    ..name = 'Unit'
    ..values.addAll(values));
  return _dartfmt.format('${e.accept(DartEmitter())}');
}
