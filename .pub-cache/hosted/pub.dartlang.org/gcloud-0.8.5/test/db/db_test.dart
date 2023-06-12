// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.db_test;

import 'dart:mirrors' show reflectClass;

import 'package:gcloud/datastore.dart' as datastore;
import 'package:gcloud/db.dart';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

@Kind()
class Foobar extends Model {}

class _FakeHttpClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError('FakeHttpClient cannot make requests');
  }
}

void main() {
  group('db', () {
    final ds = datastore.Datastore(_FakeHttpClient(), '');
    test('default-partition', () {
      var db = DatastoreDB(ds);

      // Test defaultPartition
      expect(db.defaultPartition.namespace, isNull);

      // Test emptyKey
      expect(db.emptyKey.partition.namespace, isNull);

      // Test emptyKey.append()
      var key = db.emptyKey.append(Foobar, id: 42);
      expect(key.parent, db.emptyKey);
      expect(key.partition.namespace, isNull);
      expect(key.id, 42);
      expect(key.type, equals(Foobar));
    });

    test('non-default-partition', () {
      var nsDb =
          DatastoreDB(ds, defaultPartition: Partition('foobar-namespace'));

      // Test defaultPartition
      expect(nsDb.defaultPartition.namespace, 'foobar-namespace');

      // Test emptyKey
      expect(nsDb.emptyKey.partition.namespace, 'foobar-namespace');

      // Test emptyKey.append()
      var key = nsDb.emptyKey.append(Foobar, id: 42);
      expect(key.parent, nsDb.emptyKey);
      expect(key.partition.namespace, 'foobar-namespace');
      expect(key.id, 42);
      expect(key.type, equals(Foobar));
    });

    test('hasDefaultConstructor', () {
      expect(hasDefaultConstructor(Empty), isTrue);
      expect(hasDefaultConstructor(OnlyNamedConstructor), isFalse);
      expect(hasDefaultConstructor(DefaultAndNamedConstructor), isTrue);
      expect(hasDefaultConstructor(RequiredArguments), isFalse);
      expect(hasDefaultConstructor(OnlyPositionalArguments), isTrue);
      expect(hasDefaultConstructor(OnlyNamedArguments), isTrue);
      // TODO: Figure out how mirrors can detect 'required' named parameters.
      // expect(hasDefaultConstructor(RequiredNamedArguments), isFalse);
      expect(hasDefaultConstructor(DefaultArgumentValues), isTrue);
    });
  });
}

bool hasDefaultConstructor(Type type) =>
    ModelDBImpl.hasDefaultConstructor(reflectClass(type));

class Empty {
  const Empty();
}

class OnlyNamedConstructor {
  const OnlyNamedConstructor.named();
}

class DefaultAndNamedConstructor {
  const DefaultAndNamedConstructor();
  const DefaultAndNamedConstructor.named();
}

class RequiredArguments {
  const RequiredArguments(int arg);
}

class OnlyPositionalArguments {
  const OnlyPositionalArguments([int? arg, int? arg2]);
}

class OnlyNamedArguments {
  const OnlyNamedArguments({int? arg, int? arg2});
}

class RequiredNamedArguments {
  const RequiredNamedArguments({int? arg1, required int arg2});
}

class DefaultArgumentValues {
  const DefaultArgumentValues([int arg1 = 1, int arg2 = 2]);
}
