#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import '../out/protos/foo.pb.dart';
import '../out/protos/google/protobuf/unittest.pb.dart';

void main() {
  group('frozen and tobuilder', () {
    var original = Outer()
      ..inner = (Inner()..value = 'foo')
      ..inners.add(Inner()..value = 'repeatedInner')
      ..setExtension(FooExt.inner, Inner()..value = 'extension')
      ..getExtension(FooExt.inners).add(Inner()..value = 'repeatedExtension')
      ..freeze();
    test('can read extensions', () {
      expect(original.getExtension(FooExt.inner).value, 'extension');
      expect(
          original.getExtension(FooExt.inners)[0].value, 'repeatedExtension');
    });

    test('frozen message cannot be modified', () {
      expect(() => original.inner = (Inner()..value = 'bar'),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => original.inner..value = 'bar',
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => original.inners.add(Inner()..value = 'bar'),
          throwsA(TypeMatcher<UnsupportedError>()));
    });

    test('extensions cannot be modified', () {
      expect(() => original.setExtension(FooExt.inner, Inner()..value = 'bar'),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => original.getExtension(FooExt.inner).value = 'bar',
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(
          () =>
              original.getExtension(FooExt.inners).add(Inner()..value = 'bar'),
          throwsA(TypeMatcher<UnsupportedError>()));
    });

    final builder = original.toBuilder() as Outer;
    test('builder is a shallow copy', () {
      expect(builder.inner, same(original.inner));
    });
    test('builder extensions are also copied shallowly', () {
      expect(builder.getExtension(FooExt.inner),
          same(original.getExtension(FooExt.inner)));
    });

    test('repeated fields are cloned', () {
      expect(builder.inners, isNot(same(original.inners)));
      expect(builder.inners[0], same(original.inners[0]));
    });

    test('repeated extensions are cloned', () {
      expect(builder.getExtension(FooExt.inners),
          isNot(same(original.getExtension(FooExt.inners))));
      expect(builder.getExtension(FooExt.inners)[0],
          same(original.getExtension(FooExt.inners)[0]));
    });

    test(
        'the builder is only a shallow copy, the nested message is still frozen.',
        () {
      expect(() => builder.inner.value = 'bar',
          throwsA(TypeMatcher<UnsupportedError>()));
    });
    test('the builder is mutable', () {
      builder.inner = (Inner()..value = 'zop');
      expect(builder.inner.value, 'zop');
      builder.inners.add(Inner()..value = 'bob');
      expect(builder.inners.length, 2);
      builder.setExtension(FooExt.inner, Inner()..value = 'nob');
      expect(builder.getExtension(FooExt.inner).value, 'nob');
      builder.getExtension(FooExt.inners).add(Inner()..value = 'rob');
      expect(builder.getExtension(FooExt.inners).length, 2);
    });
    test('newly created `Inner` is mutable', () {
      builder.inner.value = 'bar';
      expect(builder.inner.value, 'bar');
    });
  });

  group('map properties behave correctly', () {
    late OuterWithMap original;
    late OuterWithMap outerBuilder;
    setUp(() {
      original = OuterWithMap()
        ..innerMap[1] = (Inner()..value = 'mapInner')
        ..freeze();
      outerBuilder = original.toBuilder() as OuterWithMap;
    });
    test('map fields are cloned', () {
      expect(outerBuilder.innerMap, isNot(same(original.innerMap)));
      expect(outerBuilder.innerMap[1], same(original.innerMap[1]));
    });
    test('the builder is mutable', () {
      outerBuilder.innerMap[1] = (Inner()..value = 'mob');
      expect(outerBuilder.innerMap[1]!.value, 'mob');
    });
  });

  group('frozen unknown fields', () {
    late Inner inner;
    late TestEmptyMessage emptyMessage;
    late int tagNumber;
    late UnknownFieldSet unknownFieldSet;
    late UnknownFieldSetField field;

    setUp(() {
      inner = Inner()..value = 'bob';
      emptyMessage = TestEmptyMessage.fromBuffer(inner.writeToBuffer());
      tagNumber = inner.getTagNumber('value')!;
      unknownFieldSet = emptyMessage.unknownFields;
      field = unknownFieldSet.getField(tagNumber)!;
    });

    test('can read from a frozen unknown fieldset', () {
      expect(unknownFieldSet.hasField(tagNumber), isTrue);
      expect(field.lengthDelimited[0], utf8.encode(inner.value));

      emptyMessage.freeze();
      unknownFieldSet = emptyMessage.unknownFields;
      field = unknownFieldSet.getField(tagNumber)!;

      expect(unknownFieldSet.hasField(tagNumber), isTrue);
      expect(field.lengthDelimited[0], utf8.encode(inner.value));
    });

    test('can add fields to a builder with unknown fields', () {
      emptyMessage.freeze();
      var builder = emptyMessage.toBuilder() as TestEmptyMessage;

      builder.unknownFields
          .addField(2, UnknownFieldSetField()..fixed32s.add(42));
      expect(builder.unknownFields.getField(2)!.fixed32s[0], 42);
    });

    test('cannot mutate already added UnknownFieldSetField on builder', () {
      emptyMessage.freeze();
      var builder = emptyMessage.toBuilder() as TestEmptyMessage;

      expect(
          () => builder.unknownFields.getField(1)!.lengthDelimited[0] =
              utf8.encode('alice'),
          throwsA(TypeMatcher<UnsupportedError>()));
    });

    test('cannot add to a frozen UnknownFieldSetField', () {
      emptyMessage.freeze();

      expect(
          () => field.addFixed32(1), throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.fixed32s.add(1),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.addFixed64(Int64(1)),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.fixed64s.add(Int64(1)),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.addLengthDelimited([1]),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.lengthDelimited.add([1]),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.addGroup(unknownFieldSet.clone()),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.groups.add(unknownFieldSet.clone()),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.addVarint(Int64(1)),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => field.varints.add(Int64(1)),
          throwsA(TypeMatcher<UnsupportedError>()));
    });

    test('cannot add or merge field to a frozen UnknownFieldSet', () {
      emptyMessage.freeze();

      expect(() => unknownFieldSet.addField(2, field),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => unknownFieldSet.mergeField(2, field),
          throwsA(TypeMatcher<UnsupportedError>()));
    });

    test('cannot merge message into a frozen UnknownFieldSet', () {
      emptyMessage.freeze();
      var other = emptyMessage.deepCopy();

      expect(() => emptyMessage.mergeFromBuffer(other.writeToBuffer()),
          throwsA(TypeMatcher<UnsupportedError>()));
      expect(() => emptyMessage.mergeFromMessage(other),
          throwsA(TypeMatcher<UnsupportedError>()));
    });

    test('cannot add a field to a frozen UnknownFieldSet', () {
      emptyMessage.freeze();

      expect(() => unknownFieldSet.addField(tagNumber, field),
          throwsA(TypeMatcher<UnsupportedError>()));
    });
  });
}
