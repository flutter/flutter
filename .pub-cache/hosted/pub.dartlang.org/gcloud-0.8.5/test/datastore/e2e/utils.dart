// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library raw_datastore_test_utils;

import 'package:gcloud/datastore.dart';

const _testKind = 'TestKind';
const testPropertyKeyPrefix = 'test_property';
const testListProperty = 'listproperty';
const testListValue = 'listvalue';
const testPropertyValuePrefix = 'test_property';

const testIndexedProperty = 'indexedProp';
const testIndexedPropertyValuePrefix = 'indexedValue';
const testUnindexedProperty = 'unindexedProp';
const testBlobIndexedProperty = 'blobPropertyIndexed';
final testBlobIndexedValue = BlobValue([0xaa, 0xaa, 0xff, 0xff]);

Key buildKey(
  int i, {
  Object Function(int)? idFunction,
  String kind = _testKind,
  Partition? p,
}) {
  var path = [KeyElement(kind, idFunction == null ? null : idFunction(i))];
  return Key(path, partition: p ?? Partition.DEFAULT);
}

Map<String, Object> buildProperties(int i) {
  var listValues = [
    'foo',
    '$testListValue$i',
  ];

  return {
    testPropertyKeyPrefix: '$testPropertyValuePrefix$i',
    testListProperty: listValues,
    testIndexedProperty: '$testIndexedPropertyValuePrefix$i',
    testUnindexedProperty: '$testIndexedPropertyValuePrefix$i',
    testBlobIndexedProperty: testBlobIndexedValue,
  };
}

List<Key> buildKeys(
  int from,
  int to, {
  Object Function(int)? idFunction,
  String kind = _testKind,
  Partition? partition,
}) {
  var keys = <Key>[];
  for (var i = from; i < to; i++) {
    keys.add(buildKey(i, idFunction: idFunction, kind: kind, p: partition));
  }
  return keys;
}

List<Entity> buildEntities(
  int from,
  int to, {
  Object Function(int)? idFunction,
  String kind = _testKind,
  Partition? partition,
}) {
  var entities = <Entity>[];
  var unIndexedProperties = <String>{};
  for (var i = from; i < to; i++) {
    var key = buildKey(i, idFunction: idFunction, kind: kind, p: partition);
    var properties = buildProperties(i);
    unIndexedProperties.add(testUnindexedProperty);
    entities
        .add(Entity(key, properties, unIndexedProperties: unIndexedProperties));
  }
  return entities;
}

List<Entity> buildEntityWithAllProperties(int from, int to,
    {String kind = _testKind, Partition? partition}) {
  var us42 = const Duration(microseconds: 42);
  var unIndexed = <String>{'blobProperty'};

  Map<String, dynamic> buildProperties(int i) {
    return {
      'nullValue': null,
      'boolProperty': true,
      'intProperty': 42,
      'doubleProperty': 4.2,
      'stringProperty': 'foobar',
      'blobProperty': BlobValue([0xff, 0xff, 0xaa, 0xaa]),
      'blobPropertyIndexed': BlobValue([0xaa, 0xaa, 0xff, 0xff]),
      'dateProperty':
          DateTime.fromMillisecondsSinceEpoch(1, isUtc: true).add(us42),
      'keyProperty': buildKey(1, idFunction: (i) => 's$i', kind: kind),
      'listProperty': [
        42,
        4.2,
        'foobar',
        buildKey(1, idFunction: (i) => 's$i', kind: 'TestKind'),
      ],
    };
  }

  var entities = <Entity>[];
  for (var i = from; i < to; i++) {
    var key =
        buildKey(i, idFunction: (i) => 'allprop$i', kind: kind, p: partition);
    var properties = buildProperties(i);
    entities.add(Entity(key, properties, unIndexedProperties: unIndexed));
  }
  return entities;
}
