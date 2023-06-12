// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The first test that runs `testBuilder` takes a LOT longer than the rest.
@Timeout.factor(3)
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:source_gen/source_gen.dart';
import 'package:test/test.dart';

void main() {
  group('skips output if per-annotation output is', () {
    for (var entry in {
      '`null`': null,
      'empty string': '',
      'only whitespace': '\n \t',
      'empty list': [],
      'list with null, empty, and whitespace items': [null, '', '\n \t']
    }.entries) {
      test(entry.key, () async {
        final generator = LiteralOutput(entry.value);
        final builder = LibraryBuilder(generator);
        await testBuilder(builder, _inputMap, outputs: {});
      });
    }
  });

  test('Supports and dedupes multiple return values', () async {
    const generator = RepeatingGenerator();
    final builder = LibraryBuilder(generator);
    await testBuilder(builder, _inputMap, outputs: {
      'a|lib/file.g.dart': r'''
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RepeatingGenerator
// **************************************************************************

// There are deprecated values in this library!

// foo

// bar

// baz
'''
    });
  });

  group('handles errors correctly', () {
    for (var entry in {
      'sync errors': const FailingGenerator(),
      'from iterable': const FailingIterableGenerator()
    }.entries) {
      test(entry.key, () async {
        final builder = LibraryBuilder(entry.value);

        await expectLater(
          () => testBuilder(builder, _inputMap),
          throwsA(
            isA<StateError>().having(
              (source) => source.message,
              'message',
              'not supported!',
            ),
          ),
        );
      });
    }
  });
}

class FailingIterableGenerator extends GeneratorForAnnotation<Deprecated> {
  const FailingIterableGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) sync* {
    yield '// There are deprecated values in this library!';
    throw StateError('not supported!');
  }

  @override
  String toString() => 'FailingGenerator';
}

class FailingGenerator extends GeneratorForAnnotation<Deprecated> {
  const FailingGenerator();

  @override
  dynamic generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    throw StateError('not supported!');
  }
}

class RepeatingGenerator extends GeneratorForAnnotation<Deprecated> {
  const RepeatingGenerator();

  @override
  Iterable<String> generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) sync* {
    yield '// There are deprecated values in this library!';

    yield '// ${element.name}';
  }
}

class LiteralOutput<T> extends GeneratorForAnnotation<Deprecated> {
  final T? value;

  const LiteralOutput([this.value]);

  @override
  T? generateForAnnotatedElement(
          Element element, ConstantReader annotation, BuildStep buildStep) =>
      null;
}

const _inputMap = {
  'a|lib/file.dart': '''
     @deprecated
     final foo = 'foo';

     @deprecated
     final bar = 'bar';

     @deprecated
     final baz = 'baz';
     '''
};
