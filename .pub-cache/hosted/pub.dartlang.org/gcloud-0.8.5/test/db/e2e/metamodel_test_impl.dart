// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library metamodel_test;

import 'dart:async';

import 'package:gcloud/datastore.dart';
import 'package:gcloud/db.dart' as db;
import 'package:gcloud/db/metamodel.dart';
import 'package:test/test.dart';

List<Entity> buildEntitiesWithDifferentNamespaces() {
  Key newKey(String? namespace, String kind, int id) {
    var partition = Partition(namespace);
    return Key([KeyElement(kind, id)], partition: partition);
  }

  Entity newEntity(String? namespace, String kind, {int id = 1}) {
    return Entity(newKey(namespace, kind, id), {'ping': 'pong'});
  }

  return [
    newEntity(null, 'NullKind', id: 1),
    newEntity(null, 'NullKind', id: 2),
    newEntity(null, 'NullKind2', id: 1),
    newEntity(null, 'NullKind2', id: 2),
    newEntity('FooNamespace', 'FooKind', id: 1),
    newEntity('FooNamespace', 'FooKind', id: 2),
    newEntity('FooNamespace', 'FooKind2', id: 1),
    newEntity('FooNamespace', 'FooKind2', id: 2),
    newEntity('BarNamespace', 'BarKind', id: 1),
    newEntity('BarNamespace', 'BarKind', id: 2),
    newEntity('BarNamespace', 'BarKind2', id: 1),
    newEntity('BarNamespace', 'BarKind2', id: 2),
  ];
}

Future sleep(Duration duration) {
  var completer = Completer();
  Timer(duration, completer.complete);
  return completer.future;
}

void runTests(datastore, db.DatastoreDB store) {
  // Shorten this name, so we don't have to break lines at 80 chars.
  final cond = predicate;

  group('e2e_db_metamodel', () {
    // NOTE: This test cannot safely be run concurrently, since it's using fixed
    // keys (i.e. fixed partition + fixed Ids).
    test('namespaces__insert_lookup_delete', () {
      var entities = buildEntitiesWithDifferentNamespaces();
      var keys = entities.map((e) => e.key).toList();

      return datastore.commit(inserts: entities).then((_) {
        return sleep(const Duration(seconds: 10)).then((_) {
          var namespaceQuery = store.query<Namespace>();
          return namespaceQuery.run().toList().then((namespaces) {
            expect(namespaces.length, greaterThanOrEqualTo(3));
            expect(namespaces, contains(cond((dynamic ns) => ns.name == null)));
            expect(namespaces,
                contains(cond((dynamic ns) => ns.name == 'FooNamespace')));
            expect(namespaces,
                contains(cond((dynamic ns) => ns.name == 'BarNamespace')));

            var futures = <Future>[];
            for (var namespace in namespaces) {
              if (!(namespace.name == 'FooNamespace' ||
                  namespace.name == 'BarNamespace')) {
                continue;
              }
              var partition = store.newPartition(namespace.name!);
              var kindQuery = store.query<Kind>(partition: partition);
              futures.add(kindQuery.run().toList().then((List<db.Model> kinds) {
                expect(kinds.length, greaterThanOrEqualTo(2));
                if (namespace.name == null) {
                  expect(kinds,
                      contains(cond((dynamic k) => k.name == 'NullKind')));
                  expect(kinds,
                      contains(cond((dynamic k) => k.name == 'NullKind2')));
                } else if (namespace.name == 'FooNamespace') {
                  expect(kinds,
                      contains(cond((dynamic k) => k.name == 'FooKind')));
                  expect(kinds,
                      contains(cond((dynamic k) => k.name == 'FooKind2')));
                } else if (namespace.name == 'BarNamespace') {
                  expect(kinds,
                      contains(cond((dynamic k) => k.name == 'BarKind')));
                  expect(kinds,
                      contains(cond((dynamic k) => k.name == 'BarKind2')));
                }
              }));
            }
            return Future.wait(futures).then((_) {
              expect(datastore.commit(deletes: keys), completes);
            });
          });
        });
      });
    });
  });
}
