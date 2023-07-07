// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db.properties_test;

import 'dart:typed_data';

import 'package:gcloud/datastore.dart' as datastore;
import 'package:gcloud/db.dart';
import 'package:test/test.dart';

void main() {
  group('properties', () {
    var datastoreKey = datastore.Key([datastore.KeyElement('MyKind', 42)],
        partition: datastore.Partition('foonamespace'));
    var dbKey = KeyMock(datastoreKey);
    var modelDBMock = ModelDBMock(datastoreKey, dbKey);

    test('bool_property', () {
      var prop = const BoolProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const BoolProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, true), isTrue);
      expect(prop.validate(modelDBMock, false), isTrue);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, true), equals(true));
      expect(prop.encodeValue(modelDBMock, false), equals(false));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, true), equals(true));
      expect(prop.decodePrimitiveValue(modelDBMock, false), equals(false));
    });

    test('int_property', () {
      var prop = const IntProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const IntProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, 33), isTrue);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, 42), equals(42));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, 99), equals(99));
    });

    test('double_property', () {
      var prop = const DoubleProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const DoubleProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, 33.0), isTrue);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, 42.3), equals(42.3));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, 99.1), equals(99.1));
    });

    test('string_property', () {
      var prop = const StringProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const StringProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, 'foobar'), isTrue);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, 'foo'), equals('foo'));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, 'bar'), equals('bar'));
    });

    test('blob_property', () {
      var prop = const BlobProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const BlobProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, [1, 2]), isTrue);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(
          (prop.encodeValue(modelDBMock, <int>[]) as datastore.BlobValue).bytes,
          equals([]));
      expect(
          (prop.encodeValue(modelDBMock, [1, 2]) as datastore.BlobValue).bytes,
          equals([1, 2]));
      expect(
          (prop.encodeValue(modelDBMock, Uint8List.fromList([1, 2]))
                  as datastore.BlobValue)
              .bytes,
          equals([1, 2]));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, datastore.BlobValue([])),
          equals([]));
      expect(
          prop.decodePrimitiveValue(modelDBMock, datastore.BlobValue([5, 6])),
          equals([5, 6]));
      expect(
          prop.decodePrimitiveValue(
              modelDBMock, datastore.BlobValue(Uint8List.fromList([5, 6]))),
          equals([5, 6]));
    });

    test('datetime_property', () {
      var utc99 = DateTime.fromMillisecondsSinceEpoch(99, isUtc: true);

      var prop = const DateTimeProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const DateTimeProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, utc99), isTrue);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, utc99), equals(utc99));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, 99 * 1000), equals(utc99));
      expect(
          prop.decodePrimitiveValue(modelDBMock, 99 * 1000 + 1), equals(utc99));
      expect(prop.decodePrimitiveValue(modelDBMock, utc99), equals(utc99));
    });

    test('list_property', () {
      var prop = const ListProperty(BoolProperty());

      expect(prop.validate(modelDBMock, null), isFalse);
      expect(prop.validate(modelDBMock, []), isTrue);
      expect(prop.validate(modelDBMock, [true]), isTrue);
      expect(prop.validate(modelDBMock, [true, false]), isTrue);
      expect(prop.validate(modelDBMock, [true, false, 1]), isFalse);
      expect(prop.encodeValue(modelDBMock, []), equals(null));
      expect(prop.encodeValue(modelDBMock, [true]), equals(true));
      expect(
          prop.encodeValue(modelDBMock, [true, false]), equals([true, false]));
      expect(prop.encodeValue(modelDBMock, true, forComparison: true),
          equals(true));
      expect(prop.encodeValue(modelDBMock, false, forComparison: true),
          equals(false));
      expect(prop.encodeValue(modelDBMock, null, forComparison: true),
          equals(null));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals([]));
      expect(prop.decodePrimitiveValue(modelDBMock, []), equals([]));
      expect(prop.decodePrimitiveValue(modelDBMock, true), equals([true]));
      expect(prop.decodePrimitiveValue(modelDBMock, [true, false]),
          equals([true, false]));
    });

    test('composed_list_property', () {
      var prop = const ListProperty(CustomProperty());

      var c1 = Custom()..customValue = 'c1';
      var c2 = Custom()..customValue = 'c2';

      expect(prop.validate(modelDBMock, null), isFalse);
      expect(prop.validate(modelDBMock, []), isTrue);
      expect(prop.validate(modelDBMock, [c1]), isTrue);
      expect(prop.validate(modelDBMock, [c1, c2]), isTrue);
      expect(prop.validate(modelDBMock, [c1, c2, 1]), isFalse);
      expect(prop.encodeValue(modelDBMock, []), equals(null));
      expect(prop.encodeValue(modelDBMock, [c1]), equals(c1.customValue));
      expect(prop.encodeValue(modelDBMock, [c1, c2]),
          equals([c1.customValue, c2.customValue]));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals([]));
      expect(prop.decodePrimitiveValue(modelDBMock, []), equals([]));
      expect(
          prop.decodePrimitiveValue(modelDBMock, c1.customValue), equals([c1]));
      expect(
          prop.decodePrimitiveValue(
              modelDBMock, [c1.customValue, c2.customValue]),
          equals([c1, c2]));
    });

    test('modelkey_property', () {
      var prop = const ModelKeyProperty(required: true);
      expect(prop.validate(modelDBMock, null), isFalse);

      prop = const ModelKeyProperty(required: false);
      expect(prop.validate(modelDBMock, null), isTrue);
      expect(prop.validate(modelDBMock, dbKey), isTrue);
      expect(prop.validate(modelDBMock, datastoreKey), isFalse);
      expect(prop.encodeValue(modelDBMock, null), equals(null));
      expect(prop.encodeValue(modelDBMock, dbKey), equals(datastoreKey));
      expect(prop.decodePrimitiveValue(modelDBMock, null), equals(null));
      expect(
          prop.decodePrimitiveValue(modelDBMock, datastoreKey), equals(dbKey));
    });
  });
}

class Custom {
  String? customValue;

  @override
  int get hashCode => customValue.hashCode;

  @override
  bool operator ==(other) {
    return other is Custom && other.customValue == customValue;
  }
}

class CustomProperty extends StringProperty {
  const CustomProperty(
      {String? propertyName, bool required = false, bool indexed = true});

  @override
  bool validate(ModelDB db, Object? value) {
    if (required && value == null) return false;
    return value == null || value is Custom;
  }

  @override
  Object? decodePrimitiveValue(ModelDB db, Object? value) {
    if (value == null) return null;
    return Custom()..customValue = value as String;
  }

  @override
  Object? encodeValue(ModelDB db, Object? value, {bool forComparison = false}) {
    if (value == null) return null;
    return (value as Custom).customValue;
  }
}

class KeyMock implements Key {
  final datastore.Key _datastoreKey;

  KeyMock(this._datastoreKey);

  @override
  Object id = 1;
  @override
  Type? type;
  @override
  Key get parent => this;
  @override
  bool get isEmpty => false;
  @override
  Partition get partition => throw UnimplementedError('not mocked');
  datastore.Key get datastoreKey => _datastoreKey;
  @override
  Key<T> append<T>(Type modelType, {T? id}) =>
      throw UnimplementedError('not mocked');
  @override
  Key<U> cast<U>() => Key<U>(parent, type, id as U);
  @override
  // ignore: hash_and_equals
  int get hashCode => 1;
}

class ModelDBMock implements ModelDB {
  final datastore.Key _datastoreKey;
  final Key _dbKey;
  ModelDBMock(this._datastoreKey, this._dbKey);

  @override
  Key fromDatastoreKey(datastore.Key datastoreKey) {
    if (!identical(_datastoreKey, datastoreKey)) {
      throw 'Broken test';
    }
    return _dbKey;
  }

  @override
  datastore.Key toDatastoreKey(Key key) {
    if (!identical(_dbKey, key)) {
      throw 'Broken test';
    }
    return _datastoreKey;
  }

  Map<String, Property>? propertiesForModel(modelDescription) => null;
  @override
  T? fromDatastoreEntity<T extends Model>(datastore.Entity? entity) => null;
  @override
  datastore.Entity toDatastoreEntity(Model model) =>
      throw UnimplementedError('not mocked');
  @override
  String? fieldNameToPropertyName(String kind, String fieldName) => null;
  @override
  String kindName(Type type) => throw UnimplementedError('not mocked');
  @override
  Object? toDatastoreValue(String kind, String fieldName, Object? value,
          {bool forComparison = false}) =>
      null;
}
