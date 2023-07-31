#!/usr/bin/env dart
// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:core' hide Duration;

import 'package:fixnum/fixnum.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';

import '../out/protos/enum_name.pb.dart';
import '../out/protos/google/protobuf/any.pb.dart';
import '../out/protos/google/protobuf/duration.pb.dart';
import '../out/protos/google/protobuf/empty.pb.dart';
import '../out/protos/google/protobuf/field_mask.pb.dart';
import '../out/protos/google/protobuf/struct.pb.dart';
import '../out/protos/google/protobuf/timestamp.pb.dart';
import '../out/protos/google/protobuf/unittest.pb.dart';
import '../out/protos/google/protobuf/unittest_nested_any.pb.dart';
import '../out/protos/google/protobuf/unittest_well_known_types.pb.dart';
import '../out/protos/google/protobuf/wrappers.pb.dart';
import '../out/protos/map_field.pb.dart';
import '../out/protos/oneof.pb.dart';
import 'oneof_test.dart';
import 'test_util.dart';

final testAllTypesJson = {
  'optionalInt32': 101,
  'optionalInt64': '102',
  'optionalUint32': 103,
  'optionalUint64': '104',
  'optionalSint32': 105,
  'optionalSint64': '106',
  'optionalFixed32': 107,
  'optionalFixed64': '108',
  'optionalSfixed32': 109,
  'optionalSfixed64': '110',
  'optionalFloat': 111.0,
  'optionalDouble': 112.0,
  'optionalBool': true,
  'optionalString': '115',
  'optionalBytes': 'MTE2',
  'optionalgroup': {'a': 117},
  'optionalNestedMessage': {'bb': 118},
  'optionalForeignMessage': {'c': 119},
  'optionalImportMessage': {'d': 120},
  'optionalNestedEnum': 'BAZ',
  'optionalForeignEnum': 'FOREIGN_BAZ',
  'optionalImportEnum': 'IMPORT_BAZ',
  'optionalStringPiece': '124',
  'optionalCord': '125',
  'repeatedInt32': [201, 301],
  'repeatedInt64': ['202', '302'],
  'repeatedUint32': [203, 303],
  'repeatedUint64': ['204', '304'],
  'repeatedSint32': [205, 305],
  'repeatedSint64': ['206', '306'],
  'repeatedFixed32': [207, 307],
  'repeatedFixed64': ['208', '308'],
  'repeatedSfixed32': [209, 309],
  'repeatedSfixed64': ['210', '310'],
  'repeatedFloat': [211.0, 311.0],
  'repeatedDouble': [212.0, 312.0],
  'repeatedBool': [true, false],
  'repeatedString': ['215', '315'],
  'repeatedBytes': ['MjE2', 'MzE2'],
  'repeatedgroup': [
    {'a': 217},
    {'a': 317}
  ],
  'repeatedNestedMessage': [
    {'bb': 218},
    {'bb': 318}
  ],
  'repeatedForeignMessage': [
    {'c': 219},
    {'c': 319}
  ],
  'repeatedImportMessage': [
    {'d': 220},
    {'d': 320}
  ],
  'repeatedNestedEnum': ['BAR', 'BAZ'],
  'repeatedForeignEnum': ['FOREIGN_BAR', 'FOREIGN_BAZ'],
  'repeatedImportEnum': ['IMPORT_BAR', 'IMPORT_BAZ'],
  'repeatedStringPiece': ['224', '324'],
  'repeatedCord': ['225', '325'],
  'defaultInt32': 401,
  'defaultInt64': '402',
  'defaultUint32': 403,
  'defaultUint64': '404',
  'defaultSint32': 405,
  'defaultSint64': '406',
  'defaultFixed32': 407,
  'defaultFixed64': '408',
  'defaultSfixed32': 409,
  'defaultSfixed64': '410',
  'defaultFloat': 411.0,
  'defaultDouble': 412.0,
  'defaultBool': false,
  'defaultString': '415',
  'defaultBytes': 'NDE2',
  'defaultNestedEnum': 'FOO',
  'defaultForeignEnum': 'FOREIGN_FOO',
  'defaultImportEnum': 'IMPORT_FOO',
  'defaultStringPiece': '424',
  'defaultCord': '425'
};

void main() {
  group('encode', () {
    test('testOutput', () {
      expect(getAllSet().toProto3Json(), testAllTypesJson);
    });

    test('testFrozenOutput', () {
      expect(getAllSet().freeze().toProto3Json(), testAllTypesJson);
    });

    test('testUnsignedOutput', () {
      var message = TestAllTypes();
      // These values are selected because they are large enough to set the sign bit.
      message.optionalUint64 = Int64.parseHex('f0000000ffff0000');
      message.optionalFixed64 = Int64.parseHex('f0000000ffff0001');

      expect(message.toProto3Json(), {
        'optionalUint64': '17293822573397606400',
        'optionalFixed64': '-1152921500311945215'
      });
    });

    test('doubles', () {
      void testValue(double value, Object expected) {
        var message = TestAllTypes()
          ..defaultFloat = value
          ..defaultDouble = value;
        expect(
            (message.toProto3Json() as Map)['defaultDouble'], equals(expected));
      }

      testValue(-0.0, -0.0);
      testValue(0.0, 0);
      testValue(1.0, 1);
      testValue(-1.0, -1);
      testValue(double.nan, 'NaN');
      testValue(double.infinity, 'Infinity');
      testValue(double.negativeInfinity, '-Infinity');
    });

    test('map value', () {
      var message = TestMap()
        ..int32ToInt32Field[32] = 32
        ..int32ToStringField[0] = 'foo'
        ..int32ToStringField[1] = 'bar'
        ..int32ToBytesField[-1] = [1, 2, 3]
        ..int32ToEnumField[1] = TestMap_EnumValue.BAZ
        ..int32ToMessageField[21] = (TestMap_MessageValue()
          ..value = 2
          ..secondValue = 3)
        ..stringToInt32Field['key'] = -1
        ..uint32ToInt32Field[0] = 0
        ..int64ToInt32Field[Int64.ZERO] = 0
        ..int64ToInt32Field[Int64.ONE] = 1
        ..int64ToInt32Field[-Int64.ONE] = -1
        ..int64ToInt32Field[Int64.MIN_VALUE] = -2
        ..int64ToInt32Field[Int64.MAX_VALUE] = 2
        ..uint64ToInt32Field[Int64.MIN_VALUE] = -2;
      expect(message.toProto3Json(), {
        'int32ToInt32Field': {'32': 32},
        'int32ToStringField': {'0': 'foo', '1': 'bar'},
        'int32ToBytesField': {'-1': 'AQID'},
        'int32ToEnumField': {'1': 'BAZ'},
        'int32ToMessageField': {
          '21': {'value': 2, 'secondValue': 3}
        },
        'stringToInt32Field': {'key': -1},
        'uint32ToInt32Field': {'0': 0},
        'int64ToInt32Field': {
          '0': 0,
          '1': 1,
          '-1': -1,
          '-9223372036854775808': -2,
          '9223372036854775807': 2
        },
        'uint64ToInt32Field': {'9223372036854775808': -2},
      });
    });

    test('Timestamp', () {
      expect(
          Timestamp.fromDateTime(DateTime.utc(1969, 7, 20, 20, 17, 40))
              .toProto3Json(),
          '1969-07-20T20:17:40Z');
      expect(Timestamp.fromDateTime(DateTime.utc(9)).toProto3Json(),
          '0009-01-01T00:00:00Z');
      expect(Timestamp.fromDateTime(DateTime.utc(420)).toProto3Json(),
          '0420-01-01T00:00:00Z');
      expect(() => Timestamp.fromDateTime(DateTime.utc(42001)).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
      expect(() => Timestamp.fromDateTime(DateTime.utc(-1)).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
      expect(
          Timestamp.fromDateTime(DateTime.utc(9999, 12, 31, 23, 59, 59))
              .toProto3Json(),
          '9999-12-31T23:59:59Z');

      expect((Timestamp()..nanos = 1).toProto3Json(),
          '1970-01-01T00:00:00.000000001Z');
      expect((Timestamp()..nanos = 8200000).toProto3Json(),
          '1970-01-01T00:00:00.008200Z');
      expect(() => (Timestamp()..nanos = -8200000).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
      expect(() => (Timestamp()..nanos = -8200000).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
      expect(() => (Timestamp()..nanos = 1000000000).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
    });

    test('Duration', () {
      expect(
          (Duration()
                ..seconds = Int64(0)
                ..nanos = 0)
              .toProto3Json(),
          '0s');
      expect(
          (Duration()
                ..seconds = Int64(10)
                ..nanos = 0)
              .toProto3Json(),
          '10s');
      expect(
          (Duration()
                ..seconds = Int64(10)
                ..nanos = 1)
              .toProto3Json(),
          '10.000000001s');
      expect(
          (Duration()
                ..seconds = Int64(10)
                ..nanos = 10)
              .toProto3Json(),
          '10.00000001s');
      expect(
          (Duration()
                ..seconds = -Int64(1)
                ..nanos = -99000)
              .toProto3Json(),
          '-1.000099s');
    });

    test('Any', () {
      expect(
          Any.pack(TestAllTypes()..optionalFixed64 = Int64(100))
              .toProto3Json(typeRegistry: TypeRegistry([TestAllTypes()])),
          {
            '@type': 'type.googleapis.com/protobuf_unittest.TestAllTypes',
            'optionalFixed64': '100'
          });
      expect(
          Any.pack(Timestamp.fromDateTime(DateTime.utc(1969, 7, 20, 20, 17)))
              .toProto3Json(typeRegistry: TypeRegistry([Timestamp()])),
          {
            '@type': 'type.googleapis.com/google.protobuf.Timestamp',
            'value': '1969-07-20T20:17:00Z'
          });
      expect(
          () => Any.pack(Timestamp.fromDateTime(DateTime(1969, 7, 20, 20, 17)))
              .toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
    });

    test('Nested Any', () {
      final packedOne = Any.pack(AnyMessage1()..value = '1');
      final packedTwo = Any.pack(AnyMessage2()
        ..value = '2'
        ..anyField2 = packedOne);
      expect(
          packedTwo.toProto3Json(
              typeRegistry: TypeRegistry([AnyMessage1(), AnyMessage2()])),
          {
            'anyField2': {
              'value': '1',
              '@type':
                  'type.googleapis.com/protobuf_unittest_nested_any.AnyMessage1'
            },
            'value': '2',
            '@type':
                'type.googleapis.com/protobuf_unittest_nested_any.AnyMessage2'
          });
    });

    test('struct', () {
      final s = Struct()
        ..fields['null'] = (Value()..nullValue = NullValue.NULL_VALUE)
        ..fields['number'] = (Value()..numberValue = 22.3)
        ..fields['string'] = (Value()..stringValue = 'foo')
        ..fields['bool'] = (Value()..boolValue = false)
        ..fields['struct'] = (Value()
          ..structValue =
              (Struct()..fields['a'] = (Value()..numberValue = 0.0)))
        ..fields['list'] = (Value()
          ..listValue = (ListValue()
            ..values.addAll([
              Value()..structValue = Struct(),
              Value()..listValue = ListValue(),
              Value()..stringValue = 'why'
            ])));
      expect(s.toProto3Json(), {
        'null': null,
        'number': 22.3,
        'string': 'foo',
        'bool': false,
        'struct': {'a': 0},
        'list': [{}, [], 'why']
      });
      expect(
          () => Value().toProto3Json(), throwsA(TypeMatcher<ArgumentError>()));
    });

    test('empty', () {
      expect(Empty().toProto3Json(), {});
    });

    test('wrapper types', () {
      final t = TestWellKnownTypes()
        ..doubleField = (DoubleValue()..value = 10.01)
        ..floatField = (FloatValue()..value = 3.0)
        ..int64Field = (Int64Value()..value = Int64.MIN_VALUE)
        ..uint64Field = (UInt64Value()..value = Int64.MIN_VALUE)
        ..int32Field = (Int32Value()..value = 101)
        ..uint32Field = (UInt32Value()..value = 102)
        ..boolField = (BoolValue()..value = false)
        ..stringField = (StringValue()..value = 'Pop')
        ..bytesField = (BytesValue()..value = [8, 9, 10]);
      expect(t.toProto3Json(), {
        'doubleField': 10.01,
        'floatField': 3,
        'int64Field': '-9223372036854775808',
        'uint64Field': '9223372036854775808',
        'int32Field': 101,
        'uint32Field': 102,
        'boolField': false,
        'stringField': 'Pop',
        'bytesField': 'CAkK',
      });
    });

    test('field mask', () {
      expect(FieldMask().toProto3Json(), '');
      expect((FieldMask()..paths.addAll(['foo_bar_baz'])).toProto3Json(),
          'fooBarBaz');
      expect((FieldMask()..paths.addAll(['foo_bar', 'zop'])).toProto3Json(),
          'fooBar,zop');
      expect(() => (FieldMask()..paths.add('foo_3_bar')).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
      expect(() => (FieldMask()..paths.add('foo__bar')).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
      expect(() => (FieldMask()..paths.add('fooBar')).toProto3Json(),
          throwsA(TypeMatcher<ArgumentError>()));
    });
  });

  group('decode', () {
    Matcher parseFailure(List<String> expectedPath) => throwsA(predicate((e) {
          if (e is FormatException) {
            final pathExpression =
                RegExp(r'root(\["[^"]*"]*\])*').firstMatch(e.message)![0]!;
            final actualPath = RegExp(r'\["([^"]*)"\]')
                .allMatches(pathExpression)
                .map((match) => match[1])
                .toList();
            if (actualPath.length != expectedPath.length) return false;
            for (var i = 0; i < actualPath.length; i++) {
              if (actualPath[i] != expectedPath[i]) return false;
            }
            return true;
          }
          return false;
        }));

    test('Nulls', () {
      final decoded = TestAllTypes()
        ..mergeFromProto3Json({'defaultString': null});
      expect(decoded, TestAllTypes()..defaultString = 'hello');
    });
    test('decode TestAllTypes', () {
      final decoded = TestAllTypes()..mergeFromProto3Json(testAllTypesJson);
      expect(decoded, getAllSet());
    });
    test('Type expectations', () {
      expect(
          () => TestAllTypes()..mergeFromProto3Json({1: 1}), parseFailure([]));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalBool': 1}),
          parseFailure(['optionalBool']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalBytes': 1}),
          parseFailure(['optionalBytes']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalBytes': '()'}),
          parseFailure(['optionalBytes']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalInt32': '()'}),
          parseFailure(['optionalInt32']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalInt32': 20.4}),
          parseFailure(['optionalInt32']));
      expect(TestAllTypes()..mergeFromProto3Json({'optionalInt32': '28'}),
          TestAllTypes()..optionalInt32 = 28);
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalInt64': '()'}),
          parseFailure(['optionalInt64']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalInt64': 20.4}),
          parseFailure(['optionalInt64']));
      expect(TestAllTypes()..mergeFromProto3Json({'optionalInt64': '28'}),
          TestAllTypes()..optionalInt64 = Int64(28));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalDouble': 'a'}),
          parseFailure(['optionalDouble']));
      expect(TestAllTypes()..mergeFromProto3Json({'optionalDouble': 28}),
          TestAllTypes()..optionalDouble = 28.0);
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalDouble': 'a'}),
          parseFailure(['optionalDouble']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalString': 11}),
          parseFailure(['optionalString']));
      expect(
          () => TestAllTypes()
            ..mergeFromProto3Json({'optionalEnum': 'wrongValue'}),
          parseFailure(['optionalEnum']));
      expect(() => TestAllTypes()..mergeFromProto3Json({'optionalEnum': []}),
          parseFailure(['optionalEnum']));
      expect(
          () =>
              TestAllTypes()..mergeFromProto3Json({'optionalNestedEnum': 100}),
          parseFailure(['optionalNestedEnum']));
      expect(
          TestAllTypes()..mergeFromProto3Json({'optionalNestedEnum': 1}),
          TestAllTypes()
            ..optionalNestedEnum = TestAllTypes_NestedEnum.valueOf(1)!);
      expect(TestAllTypes()..mergeFromProto3Json({'repeatedBool': null}),
          TestAllTypes());
      expect(() => TestAllTypes()..mergeFromProto3Json({'repeatedBool': 100}),
          parseFailure(['repeatedBool']));
      expect(
          () => TestAllTypes()
            ..mergeFromProto3Json({
              'repeatedBool': [true, false, 1]
            }),
          parseFailure(['repeatedBool', '2']));
      expect(() => TestAllTypes()..mergeFromProto3Json(Object()),
          parseFailure([]));
    });

    test('merging behavior', () {
      final t = TestAllTypes()
        ..optionalForeignMessage = ForeignMessage()
        ..repeatedForeignMessage.add(ForeignMessage()..c = 1);
      final f = t.optionalForeignMessage;
      expect(
          t
            ..mergeFromProto3Json({
              'repeatedForeignMessage': [
                {'c': 2}
              ],
              'optionalForeignMessage': {'c': 2}
            }),
          TestAllTypes()
            ..optionalForeignMessage = (ForeignMessage()..c = 2)
            ..repeatedForeignMessage
                .addAll([ForeignMessage()..c = 1, ForeignMessage()..c = 2]));
      expect(f, ForeignMessage()..c = 2);
    });

    test('names_with_underscores', () {
      expect(
          TestAllTypes()
            ..mergeFromProto3Json({
              'optional_foreign_message': {'c': 1}
            }),
          TestAllTypes()..optionalForeignMessage = (ForeignMessage()..c = 1));
      expect(
          () => TestAllTypes()
            ..mergeFromProto3Json({
              'optional_foreign_message': {'c': 1}
            }, supportNamesWithUnderscores: false),
          parseFailure(['optional_foreign_message']));
    });
    test('permissive enums', () {
      final sparseB = SparseEnumMessage()..sparseEnum = TestSparseEnum.SPARSE_B;
      expect(
          SparseEnumMessage()..mergeFromProto3Json({'sparseEnum': 'SPARSE_B'}),
          sparseB);
      expect(
          () => SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'sparse_b'}),
          parseFailure(['sparseEnum']));
      expect(
          () => SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'SPARSE-B'}),
          parseFailure(['sparseEnum']));
      expect(
          () => SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'sPaRsE_b'}),
          parseFailure(['sparseEnum']));
      expect(
          () => SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'sparseB'}),
          parseFailure(['sparseEnum']));
      expect(
          () => SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'spaRSEB'}),
          parseFailure(['sparseEnum']));

      expect(() => AMessage()..mergeFromProto3Json({'a': 'x'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'X'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'x_'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'X_'}),
          parseFailure(['a']));
      expect(
          AMessage()..mergeFromProto3Json({'a': '_x'}), AMessage()..a = A.x_);
      expect(() => AMessage()..mergeFromProto3Json({'a': '_X'}),
          parseFailure(['a']));

      expect(() => AMessage()..mergeFromProto3Json({'a': 'y'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'Y'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'y_'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'Y_'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': '_y'}),
          parseFailure(['a']));
      expect(
          AMessage()..mergeFromProto3Json({'a': '_Y'}), AMessage()..a = A.Y_);

      expect(() => AMessage()..mergeFromProto3Json({'a': 'z'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'Z'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'z_'}),
          parseFailure(['a']));
      expect(
          AMessage()..mergeFromProto3Json({'a': 'Z_'}), AMessage()..a = A.Z_);
      expect(() => AMessage()..mergeFromProto3Json({'a': '_z'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': '_Z'}),
          parseFailure(['a']));

      expect(() => AMessage()..mergeFromProto3Json({'a': 'a_a'}),
          parseFailure(['a']));
      expect(
          AMessage()..mergeFromProto3Json({'a': 'A_A'}), AMessage()..a = A.A_A);
      expect(() => AMessage()..mergeFromProto3Json({'a': 'aA'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'AA'}),
          parseFailure(['a']));

      expect(
          AMessage()..mergeFromProto3Json({'a': 'b_b'}), AMessage()..a = A.b_b);
      expect(() => AMessage()..mergeFromProto3Json({'a': 'B_B'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'bB'}),
          parseFailure(['a']));
      expect(() => AMessage()..mergeFromProto3Json({'a': 'BB'}),
          parseFailure(['a']));

      expect(() => AMessage()..mergeFromProto3Json({'a': 'CAMEL_CASE'}),
          parseFailure(['a']));
      expect(AMessage()..mergeFromProto3Json({'a': 'camelCase'}),
          AMessage()..a = A.camelCase);

      expect(AMessage()..mergeFromProto3Json({'a': 'x'}, permissiveEnums: true),
          AMessage()..a = A.x_);
      expect(AMessage()..mergeFromProto3Json({'a': 'X'}, permissiveEnums: true),
          AMessage()..a = A.x_);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'x_'}, permissiveEnums: true),
          AMessage()..a = A.x_);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'X_'}, permissiveEnums: true),
          AMessage()..a = A.x_);
      expect(
          AMessage()..mergeFromProto3Json({'a': '_x'}, permissiveEnums: true),
          AMessage()..a = A.x_);
      expect(
          AMessage()..mergeFromProto3Json({'a': '_X'}, permissiveEnums: true),
          AMessage()..a = A.x_);

      expect(AMessage()..mergeFromProto3Json({'a': 'y'}, permissiveEnums: true),
          AMessage()..a = A.Y_);
      expect(AMessage()..mergeFromProto3Json({'a': 'Y'}, permissiveEnums: true),
          AMessage()..a = A.Y_);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'y_'}, permissiveEnums: true),
          AMessage()..a = A.Y_);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'Y_'}, permissiveEnums: true),
          AMessage()..a = A.Y_);
      expect(
          AMessage()..mergeFromProto3Json({'a': '_y'}, permissiveEnums: true),
          AMessage()..a = A.Y_);
      expect(
          AMessage()..mergeFromProto3Json({'a': '_Y'}, permissiveEnums: true),
          AMessage()..a = A.Y_);

      expect(AMessage()..mergeFromProto3Json({'a': 'z'}, permissiveEnums: true),
          AMessage()..a = A.Z_);
      expect(AMessage()..mergeFromProto3Json({'a': 'Z'}, permissiveEnums: true),
          AMessage()..a = A.Z_);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'z_'}, permissiveEnums: true),
          AMessage()..a = A.Z_);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'Z_'}, permissiveEnums: true),
          AMessage()..a = A.Z_);
      expect(
          AMessage()..mergeFromProto3Json({'a': '_z'}, permissiveEnums: true),
          AMessage()..a = A.Z_);
      expect(
          AMessage()..mergeFromProto3Json({'a': '_Z'}, permissiveEnums: true),
          AMessage()..a = A.Z_);

      expect(
          AMessage()..mergeFromProto3Json({'a': 'a_a'}, permissiveEnums: true),
          AMessage()..a = A.A_A);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'A_A'}, permissiveEnums: true),
          AMessage()..a = A.A_A);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'aA'}, permissiveEnums: true),
          AMessage()..a = A.A_A);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'AA'}, permissiveEnums: true),
          AMessage()..a = A.A_A);

      expect(
          AMessage()..mergeFromProto3Json({'a': 'b_b'}, permissiveEnums: true),
          AMessage()..a = A.b_b);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'B_B'}, permissiveEnums: true),
          AMessage()..a = A.b_b);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'bB'}, permissiveEnums: true),
          AMessage()..a = A.b_b);
      expect(
          AMessage()..mergeFromProto3Json({'a': 'BB'}, permissiveEnums: true),
          AMessage()..a = A.b_b);

      expect(
          AMessage()
            ..mergeFromProto3Json({'a': 'CAMEL_CASE'}, permissiveEnums: true),
          AMessage()..a = A.camelCase);
      expect(
          AMessage()
            ..mergeFromProto3Json({'a': 'camelCase'}, permissiveEnums: true),
          AMessage()..a = A.camelCase);

      expect(
          SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'sparse_b'},
                permissiveEnums: true),
          sparseB);
      expect(
          SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'SPARSE-B'},
                permissiveEnums: true),
          sparseB);
      expect(
          SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'S-P-A-R-S-E-B'},
                permissiveEnums: true),
          sparseB);
      expect(
          SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'sPaRsE_b'},
                permissiveEnums: true),
          sparseB);
      expect(
          SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'sparseB'},
                permissiveEnums: true),
          sparseB);
      expect(
          SparseEnumMessage()
            ..mergeFromProto3Json({'sparseEnum': 'spaRSEB'},
                permissiveEnums: true),
          sparseB);
      expect(
          () => Any()
            ..mergeFromProto3Json({
              '@type':
                  'type.googleapis.com/protobuf_unittest.SparseEnumMessage',
              'sparseEnum': 'SPARSEB'
            }, typeRegistry: TypeRegistry([SparseEnumMessage()])),
          parseFailure(['sparseEnum']));
      expect(
          Any()
            ..mergeFromProto3Json({
              '@type':
                  'type.googleapis.com/protobuf_unittest.SparseEnumMessage',
              'sparseEnum': 'SPARSEB'
            },
                typeRegistry: TypeRegistry([SparseEnumMessage()]),
                permissiveEnums: true),
          Any.pack(sparseB),
          reason: 'Parsing options are passed through Any messages');
    });

    test('map value', () {
      var expected = TestMap()
        ..int32ToInt32Field[32] = 32
        ..int32ToStringField[0] = 'foo'
        ..int32ToStringField[1] = 'bar'
        ..int32ToBytesField[-1] = [1, 2, 3]
        ..int32ToEnumField[1] = TestMap_EnumValue.BAZ
        ..int32ToMessageField[21] = (TestMap_MessageValue()
          ..value = 2
          ..secondValue = 3)
        ..stringToInt32Field['key'] = -1
        ..uint32ToInt32Field[0] = 0
        ..int64ToInt32Field[Int64.ZERO] = 0
        ..int64ToInt32Field[Int64.ONE] = 1
        ..int64ToInt32Field[-Int64.ONE] = -1
        ..int64ToInt32Field[Int64.MIN_VALUE] = -2
        ..int64ToInt32Field[Int64.MAX_VALUE] = 2
        ..uint64ToInt32Field[Int64.MIN_VALUE] = -2;
      expect(
          TestMap()
            ..mergeFromProto3Json({
              'int32ToInt32Field': {'32': 32},
              'int32ToStringField': {'0': 'foo', '1': 'bar'},
              'int32ToBytesField': {'-1': 'AQID'},
              'int32ToEnumField': {'1': 'BAZ'},
              'int32ToMessageField': {
                '21': {'value': 2, 'secondValue': 3}
              },
              'stringToInt32Field': {'key': -1},
              'uint32ToInt32Field': {'0': 0},
              'int64ToInt32Field': {
                '0': 0,
                '1': 1,
                '-1': -1,
                '-9223372036854775808': -2,
                '9223372036854775807': 2
              },
              'uint64ToInt32Field': {'9223372036854775808': -2},
            }),
          expected);
      expect(() => TestMap()..mergeFromProto3Json([]), parseFailure([]));
      expect(
          () => TestMap()
            ..mergeFromProto3Json({
              'int32ToInt32Field': {'32': 'a'}
            }),
          parseFailure(['int32ToInt32Field', '32']));
      expect(
          () => TestMap()
            ..mergeFromProto3Json({
              'int32ToInt32Field': {'2147483648': 1}
            }),
          parseFailure(['int32ToInt32Field', '2147483648']));
      expect(
          () => TestMap()
            ..mergeFromProto3Json({
              'uint32ToInt32Field': {'-32': 21}
            }),
          parseFailure(['uint32ToInt32Field', '-32']));
      expect(
          () => TestMap()
            ..mergeFromProto3Json({
              'uint32ToInt32Field': {'4294967296': 21}
            }),
          parseFailure(['uint32ToInt32Field', '4294967296']));
      expect(
          TestMap()
            ..mergeFromProto3Json({
              'int32ToInt32Field': <dynamic, dynamic>{'2': 21}
            }),
          TestMap()..int32ToInt32Field[2] = 21);
    });
    test('ints', () {
      expect(
          (TestAllTypes()
                ..mergeFromProto3Json({
                  'optionalUint64': '17293822573397606400',
                }))
              .optionalUint64,
          Int64.parseHex('f0000000ffff0000'));

      // TODO(sigurdm): This should throw.
      expect(
          TestAllTypes()
            ..mergeFromProto3Json({
              'optionalUint64': '-1',
            }),
          TestAllTypes()
            ..optionalUint64 =
                Int64.fromBytes([255, 255, 255, 255, 255, 255, 255, 255]));

      void expectRoundTrip(String typeName, int value) {
        final t = TestAllTypes()
          ..mergeFromProto3Json({
            typeName: value,
          });
        expect(t.getField(t.getTagNumber(typeName)!), value);
        final t2 = TestAllTypes()
          ..mergeFromProto3Json({
            typeName: value.toString(),
          });
        expect(t2.getField(t2.getTagNumber(typeName)!), value);
      }

      void expectFailure(String typeName, int value) {
        expect(
            () => TestAllTypes()..mergeFromProto3Json({typeName: -2147483649}),
            parseFailure([typeName]));
      }

      void expectSigned32(String typeName) {
        expectRoundTrip(typeName, 1);
        expectRoundTrip(typeName, 0);
        expectRoundTrip(typeName, 2147483647);
        expectRoundTrip(typeName, -2147483648);
        expectFailure(typeName, 2147483648);
        expectFailure(typeName, -2147483649);
      }

      void expectUnsigned32(String typeName) {
        expectRoundTrip(typeName, 1);
        expectRoundTrip(typeName, 0);
        expectRoundTrip(typeName, 0xFFFFFFFF);
        expectFailure(typeName, 0xFFFFFFFF + 1);
        expectFailure(typeName, -1);
      }

      expectUnsigned32('optionalFixed32');
      expectUnsigned32('optionalUint32');
      expectSigned32('optionalInt32');
      expectSigned32('optionalSfixed32');
      expectSigned32('optionalSint32');
    });

    test('unknown fields', () {
      expect(
          () => TestAllTypes()
            ..mergeFromProto3Json({
              'myOwnInventedField': 'blahblahblah',
            }),
          throwsA(const TypeMatcher<FormatException>()));
      expect(
          () => TestAllTypes()
            ..mergeFromProto3Json({
              'myOwnInventedField': 'blahblahblah',
            }, ignoreUnknownFields: false),
          throwsA(const TypeMatcher<FormatException>()));
      final t = TestAllTypes()
        ..mergeFromProto3Json({
          'myOwnInventedField': 'blahblahblah',
        }, ignoreUnknownFields: true);
      expect(t, TestAllTypes());
      expect(t.unknownFields.isEmpty, isTrue);
    });

    test('Any', () {
      final m1 = Any()
        ..mergeFromProto3Json({
          '@type': 'type.googleapis.com/protobuf_unittest.TestAllTypes',
          'optionalFixed64': '100'
        }, typeRegistry: TypeRegistry([TestAllTypes()]));

      expect(m1.unpackInto(TestAllTypes()).optionalFixed64, Int64(100));

      final m2 = Any()
        ..mergeFromProto3Json({
          '@type': 'type.googleapis.com/google.protobuf.Timestamp',
          'value': '1969-07-20T19:17:00Z'
        }, typeRegistry: TypeRegistry([Timestamp()]));

      expect(m2.unpackInto(Timestamp()).toDateTime().millisecondsSinceEpoch,
          DateTime.utc(1969, 7, 20, 19, 17).millisecondsSinceEpoch);

      expect(
          () => Any()
            ..mergeFromProto3Json({
              '@type': 'type.googleapis.com/google.protobuf.Timestamp',
              'value': '1969-07-20T19:17:00Z'
            }),
          parseFailure([]));

      expect(
          () => Any()
            ..mergeFromProto3Json(
                {'@type': 11, 'value': '1969-07-20T19:17:00Z'}),
          parseFailure([]));

      final m3 = Any()
        ..mergeFromProto3Json({
          '@type': 'type.googleapis.com/google.protobuf.Any',
          'value': {
            '@type': 'type.googleapis.com/google.protobuf.Timestamp',
            'value': '1969-07-20T19:17:00Z'
          }
        }, typeRegistry: TypeRegistry([Timestamp(), Any()]));

      expect(
          m3
              .unpackInto(Any())
              .unpackInto(Timestamp())
              .toDateTime()
              .millisecondsSinceEpoch,
          DateTime.utc(1969, 7, 20, 19, 17).millisecondsSinceEpoch);

      // TODO(sigurdm): We would ideally like the error path to be
      // ['value', 'value'].
      expect(
          () => Any()
            ..mergeFromProto3Json({
              '@type': 'type.googleapis.com/google.protobuf.Any',
              'value': {
                '@type': 'type.googleapis.com/google.protobuf.Timestamp',
                'value': '1969'
              }
            }, typeRegistry: TypeRegistry([Timestamp(), Any()])),
          parseFailure([]));

      expect(() => Any()..mergeFromProto3Json('@type'), parseFailure([]));

      expect(() => Any()..mergeFromProto3Json(11), parseFailure([]));

      expect(() => Any()..mergeFromProto3Json(['@type']), parseFailure([]));

      expect(
          () => Any()
            ..mergeFromProto3Json({
              '@type': 'type.googleapis.com/google.protobuf.Timestamp',
              'value': '1969-07-20T19:17:00Z'
            }),
          parseFailure([]));
    });

    test('Nested Any', () {
      final m1 = Any()
        ..mergeFromProto3Json({
          'anyField2': {
            'value': '1',
            '@type':
                'type.googleapis.com/protobuf_unittest_nested_any.AnyMessage1'
          },
          'value': '2',
          '@type':
              'type.googleapis.com/protobuf_unittest_nested_any.AnyMessage2'
        }, typeRegistry: TypeRegistry([AnyMessage1(), AnyMessage2()]));

      expect(
          m1
              .unpackInto(AnyMessage2())
              .anyField2
              .unpackInto(AnyMessage1())
              .value,
          '1');
    });

    test('Duration', () {
      expect(
          Duration()..mergeFromProto3Json('0s'),
          Duration()
            ..seconds = Int64(0)
            ..nanos = 0);
      expect(
          Duration()..mergeFromProto3Json('10s'),
          Duration()
            ..seconds = Int64(10)
            ..nanos = 0);
      expect(
          Duration()..mergeFromProto3Json('10.000000001s'),
          Duration()
            ..seconds = Int64(10)
            ..nanos = 1);
      expect(
          Duration()..mergeFromProto3Json('10.00000001s'),
          Duration()
            ..seconds = Int64(10)
            ..nanos = 10);
      expect(
          Duration()..mergeFromProto3Json('-1.000099s'),
          Duration()
            ..seconds = -Int64(1)
            ..nanos = -99000);

      expect(
          Duration()..mergeFromProto3Json('0.s'),
          Duration()
            ..seconds = Int64(0)
            ..nanos = 0);
      expect(
          Duration()..mergeFromProto3Json('.0s'),
          Duration()
            ..seconds = Int64(0)
            ..nanos = 0);
      expect(
          Duration()..mergeFromProto3Json('.5s'),
          Duration()
            ..seconds = Int64(0)
            ..nanos = 500000000);
      expect(
          Duration()..mergeFromProto3Json('5.s'),
          Duration()
            ..seconds = Int64(5)
            ..nanos = 0);
      expect(
          Duration()..mergeFromProto3Json('.s'),
          Duration()
            ..seconds = Int64(0)
            ..nanos = 0);
      expect(() => Duration()..mergeFromProto3Json('0.5'), parseFailure([]));
      expect(() => Duration()..mergeFromProto3Json(100), parseFailure([]));
    });

    test('Timestamp', () {
      expect(Timestamp()..mergeFromProto3Json('1969-07-20T20:17:00Z'),
          Timestamp.fromDateTime(DateTime.utc(1969, 7, 20, 20, 17)));
      expect(
          Timestamp()..mergeFromProto3Json('1970-01-01T00:00:00.000000001Z'),
          Timestamp()
            ..seconds = Int64(0)
            ..nanos = 1);
      expect(Timestamp()..mergeFromProto3Json('1970-01-01T00:00:00.008200Z'),
          Timestamp.fromDateTime(DateTime.utc(1970))..nanos = 8200000);
      expect(
          Timestamp()..mergeFromProto3Json('1970-01-01T18:50:00-04:00'),
          Timestamp()
            ..seconds = Int64(82200)
            ..nanos = 0);
      expect(
          Timestamp()..mergeFromProto3Json('1970-01-01T18:50:00+04:00'),
          Timestamp()
            ..seconds = Int64(53400)
            ..nanos = 0);
      expect(
          Timestamp()..mergeFromProto3Json('1970-01-01T18:50:00.0001+04:00'),
          Timestamp()
            ..seconds = Int64(53400)
            ..nanos = 100000);
      expect(
          () => Timestamp()
            ..mergeFromProto3Json('1970-01-01T00:00:00.0000000001Z'),
          parseFailure([]));
      expect(() => Timestamp()..mergeFromProto3Json(1970), parseFailure([]));
      expect(() => Timestamp()..mergeFromProto3Json('1970-01-01T18:50:00.'),
          parseFailure([]));
    });

    test('wrapper types', () {
      expect(
          TestWellKnownTypes()
            ..mergeFromProto3Json({
              'doubleField': 10.01,
              'floatField': 3,
              'int64Field': '-9223372036854775808',
              'uint64Field': '9223372036854775808',
              'int32Field': 101,
              'uint32Field': 102,
              'boolField': false,
              'stringField': 'Pop',
              'bytesField': 'CAkK',
            }),
          TestWellKnownTypes()
            ..doubleField = (DoubleValue()..value = 10.01)
            ..floatField = (FloatValue()..value = 3.0)
            ..int64Field = (Int64Value()..value = Int64.MIN_VALUE)
            ..uint64Field = (UInt64Value()..value = Int64.MIN_VALUE)
            ..int32Field = (Int32Value()..value = 101)
            ..uint32Field = (UInt32Value()..value = 102)
            ..boolField = (BoolValue()..value = false)
            ..stringField = (StringValue()..value = 'Pop')
            ..bytesField = (BytesValue()..value = [8, 9, 10]));

      expect(
          TestWellKnownTypes()
            ..mergeFromProto3Json({
              'doubleField': '10.01',
              'floatField': '3',
              'int64Field': -854775808,
              'uint64Field': 854775808,
              'int32Field': '101',
              'uint32Field': '102',
              'boolField': false,
            }),
          TestWellKnownTypes()
            ..doubleField = (DoubleValue()..value = 10.01)
            ..floatField = (FloatValue()..value = 3.0)
            ..int64Field = (Int64Value()..value = Int64(-854775808))
            ..uint64Field = (UInt64Value()..value = Int64(854775808))
            ..int32Field = (Int32Value()..value = 101)
            ..uint32Field = (UInt32Value()..value = 102)
            ..boolField = (BoolValue()..value = false),
          reason: 'alternative representations should be accepted');

      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'doubleField': 'a'}),
          parseFailure(['doubleField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'doubleField': {}}),
          parseFailure(['doubleField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'floatField': 'a'}),
          parseFailure(['floatField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'floatField': {}}),
          parseFailure(['floatField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'int64Field': 'a'}),
          parseFailure(['int64Field']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'int64Field': {}}),
          parseFailure(['int64Field']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'int64Field': 10.4}),
          parseFailure(['int64Field']));

      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'uint64Field': 'a'}),
          parseFailure(['uint64Field']));
      expect(
          () =>
              TestWellKnownTypes()..mergeFromProto3Json({'uint64Field': 10.4}),
          parseFailure(['uint64Field']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'int32Field': 'a'}),
          parseFailure(['int32Field']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'int32Field': 10.4}),
          parseFailure(['int32Field']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'uint32Field': 'a'}),
          parseFailure(['uint32Field']));
      expect(
          () =>
              TestWellKnownTypes()..mergeFromProto3Json({'uint32Field': 10.4}),
          parseFailure(['uint32Field']));
      expect(
          () =>
              TestWellKnownTypes()..mergeFromProto3Json({'boolField': 'false'}),
          parseFailure(['boolField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'stringField': 22}),
          parseFailure(['stringField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'bytesField': 22}),
          parseFailure(['bytesField']));
      expect(
          () => TestWellKnownTypes()..mergeFromProto3Json({'bytesField': '()'}),
          parseFailure(['bytesField']));

      expect(
          TestWellKnownTypes()
            ..mergeFromProto3Json({
              'doubleField': null,
              'floatField': null,
              'int64Field': null,
              'uint64Field': null,
              'int32Field': null,
              'uint32Field': null,
              'boolField': null,
              'stringField': null,
              'bytesField': null,
            }),
          TestWellKnownTypes()
            ..doubleField = DoubleValue()
            ..floatField = FloatValue()
            ..int64Field = Int64Value()
            ..uint64Field = UInt64Value()
            ..int32Field = Int32Value()
            ..uint32Field = UInt32Value()
            ..boolField = BoolValue()
            ..stringField = StringValue()
            ..bytesField = BytesValue(),
          reason: 'having fields of wrapper types set to null will return an '
              'empty wrapper (with unset .value field)');
    });

    test('struct', () {
      final f = {
        'null': null,
        'number': 22.3,
        'string': 'foo',
        'bool': false,
        'struct': {'a': 0},
        'list': [{}, [], 'why']
      };

      final s = Struct()
        ..fields['null'] = (Value()..nullValue = NullValue.NULL_VALUE)
        ..fields['number'] = (Value()..numberValue = 22.3)
        ..fields['string'] = (Value()..stringValue = 'foo')
        ..fields['bool'] = (Value()..boolValue = false)
        ..fields['struct'] = (Value()
          ..structValue =
              (Struct()..fields['a'] = (Value()..numberValue = 0.0)))
        ..fields['list'] = (Value()
          ..listValue = (ListValue()
            ..values.addAll([
              Value()..structValue = Struct(),
              Value()..listValue = ListValue(),
              Value()..stringValue = 'why'
            ])));
      expect(Struct()..mergeFromProto3Json(f), s);

      expect(Struct()..mergeFromProto3Json(<dynamic, dynamic>{'a': 12}),
          (Struct()..fields['a'] = (Value()..numberValue = 12.0)),
          reason: 'Allow key type to be `dynamic`');

      expect(() => Struct()..mergeFromProto3Json({1: 2}), parseFailure([]),
          reason: 'Non-string key in JSON object literal');

      expect(() => Struct()..mergeFromProto3Json([]), parseFailure([]),
          reason: 'Non object literal');

      expect(() => Struct()..mergeFromProto3Json([]), parseFailure([]),
          reason: 'Non-string key in JSON object literal');

      expect(() => Value()..mergeFromProto3Json(Object()), parseFailure([]),
          reason: 'Non JSON value');

      expect(() => ListValue()..mergeFromProto3Json({}), parseFailure([]),
          reason: 'Non-list');
    });

    test('field mask', () {
      expect(
          TestWellKnownTypes()
            ..mergeFromProto3Json({'fieldMaskField': 'foo,barBaz'}),
          TestWellKnownTypes()
            ..fieldMaskField = (FieldMask()..paths.addAll(['foo', 'bar_baz'])));
      expect(() => FieldMask()..mergeFromProto3Json('foo,bar_bar'),
          parseFailure([]));

      expect(FieldMask()..mergeFromProto3Json(''), FieldMask());
      expect(() => FieldMask()..mergeFromProto3Json(12), parseFailure([]));
    });
  });

  test('one-of', () {
    expectFirstSet(Foo()..mergeFromProto3Json({'first': 'oneof'}));
    expectSecondSet(Foo()..mergeFromProto3Json({'second': 1}));
    expectOneofNotSet(Foo()..mergeFromProto3Json({}));
  });

  group('Convert Double', () {
    test('With Decimal', () {
      final json = {'optionalDouble': 1.2};
      TestAllTypes proto = TestAllTypes()..optionalDouble = 1.2;
      expect(TestAllTypes()..mergeFromProto3Json(json), proto);
      expect(proto.toProto3Json(), json);
    });

    test('Whole Number', () {
      final json = {'optionalDouble': 5};
      TestAllTypes proto = TestAllTypes()..optionalDouble = 5.0;
      expect(TestAllTypes()..mergeFromProto3Json(json), proto);
      expect(proto.toProto3Json(), json);
    });

    test('Infinity', () {
      final json = {'optionalDouble': 'Infinity'};
      TestAllTypes proto = TestAllTypes()..optionalDouble = double.infinity;
      expect(TestAllTypes()..mergeFromProto3Json(json), proto);
      expect(proto.toProto3Json(), json);
    });

    test('Negative Infinity', () {
      final json = {'optionalDouble': '-Infinity'};
      TestAllTypes proto = TestAllTypes()
        ..optionalDouble = double.negativeInfinity;
      expect(TestAllTypes()..mergeFromProto3Json(json), proto);
      expect(proto.toProto3Json(), json);
    });
  });
}
