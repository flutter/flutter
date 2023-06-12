// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library datastore_test;

/// NOTE: In order to run these tests, the following datastore indices must
/// exist:
/// $ cat index.yaml
/// indexes:
/// - kind: TestQueryKind
///   ancestor: no
///   properties:
///   - name: indexedProp
///     direction: asc
///   - name: blobPropertyIndexed
///     direction: asc
///
/// - kind: TestQueryKind
///   ancestor: no
///   properties:
///   - name: listproperty
///   - name: test_property
///     direction: desc
/// $ gcloud datastore create-indexes index.yaml
///
/// Now, wait for indexing done
import 'dart:async';

import 'package:gcloud/common.dart';
import 'package:gcloud/datastore.dart';
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:http/http.dart';
import 'package:test/test.dart';

import '../../common_e2e.dart';
import '../error_matchers.dart';
import 'utils.dart';

Future sleep(Duration duration) {
  var completer = Completer();
  Timer(duration, completer.complete);
  return completer.future;
}

Future<List<Entity>> consumePages(FirstPageProvider<Entity> provider) {
  return StreamFromPages<Entity>(provider).stream.toList();
}

void runTests(Datastore datastore, String? namespace) {
  final partition = Partition(namespace);

  Future<T> withTransaction<T>(FutureOr<T> Function(Transaction t) f,
      {bool xg = false}) {
    return datastore.beginTransaction(crossEntityGroup: xg).then(f);
  }

  Future<List<Key>> insert(List<Entity> entities, List<Entity> autoIdEntities,
      {bool transactional = true}) {
    if (transactional) {
      return withTransaction((Transaction transaction) {
        return datastore
            .commit(
                inserts: entities,
                autoIdInserts: autoIdEntities,
                transaction: transaction)
            .then((result) {
          if (autoIdEntities.isNotEmpty) {
            expect(
                result.autoIdInsertKeys.length, equals(autoIdEntities.length));
          }
          return result.autoIdInsertKeys;
        });
      }, xg: true);
    } else {
      return datastore
          .commit(inserts: entities, autoIdInserts: autoIdEntities)
          .then((result) {
        if (autoIdEntities.isNotEmpty) {
          expect(result.autoIdInsertKeys.length, equals(autoIdEntities.length));
        }
        return result.autoIdInsertKeys;
      });
    }
  }

  Future delete(List<Key> keys, {bool transactional = true}) {
    if (transactional) {
      return withTransaction((Transaction t) {
        return datastore
            .commit(deletes: keys, transaction: t)
            .then((result) => null);
      }, xg: true);
    } else {
      return datastore.commit(deletes: keys).then((_) => _);
    }
  }

  Future<List<Entity?>> lookup(List<Key> keys, {bool transactional = true}) {
    if (transactional) {
      return withTransaction((Transaction transaction) {
        return datastore.lookup(keys, transaction: transaction);
      }, xg: true);
    } else {
      return datastore.lookup(keys);
    }
  }

  bool isValidKey(Key key, {bool ignoreIds = false}) {
    if (key.elements.isEmpty) return false;

    for (var element in key.elements) {
      if (!ignoreIds) {
        if (element.id == null ||
            (element.id is! String && element.id is! int)) {
          return false;
        }
      }
    }
    return true;
  }

  bool compareKey(Key a, Key b, {bool ignoreIds = false}) {
    if (a.partition != b.partition) return false;
    if (a.elements.length != b.elements.length) return false;
    for (var i = 0; i < a.elements.length; i++) {
      if (a.elements[i].kind != b.elements[i].kind) return false;
      if (!ignoreIds && a.elements[i].id != b.elements[i].id) return false;
    }
    return true;
  }

  bool compareEntity(Entity a, Entity b, {bool ignoreIds = false}) {
    if (!compareKey(a.key, b.key, ignoreIds: ignoreIds)) return false;
    if (a.properties.length != b.properties.length) return false;
    for (var key in a.properties.keys) {
      if (!b.properties.containsKey(key)) return false;
      if (a.properties[key] != null && a.properties[key] is List) {
        var aList = a.properties[key] as List;
        var bList = b.properties[key] as List;
        if (aList.length != bList.length) return false;
        for (var i = 0; i < aList.length; i++) {
          if (aList[i] != bList[i]) return false;
        }
      } else if (a.properties[key] is BlobValue) {
        if (b.properties[key] is BlobValue) {
          var b1 = (a.properties[key] as BlobValue).bytes;
          var b2 = (b.properties[key] as BlobValue).bytes;
          if (b1.length != b2.length) return false;
          for (var i = 0; i < b1.length; i++) {
            if (b1[i] != b2[i]) return false;
          }
          return true;
        }
        return false;
      } else {
        if (a.properties[key] != b.properties[key]) {
          return false;
        }
      }
    }
    return true;
  }

  group('e2e_datastore', () {
    group('insert', () {
      Future<List<Key>> testInsert(List<Entity> entities,
          {bool transactional = false, bool xg = false, bool unnamed = true}) {
        Future<List<Key>> test(Transaction? transaction) {
          return (transaction == null
                  ? datastore.commit(autoIdInserts: entities)
                  : datastore.commit(
                      autoIdInserts: entities, transaction: transaction))
              .then((CommitResult result) {
            expect(result.autoIdInsertKeys.length, equals(entities.length));

            for (var i = 0; i < result.autoIdInsertKeys.length; i++) {
              var key = result.autoIdInsertKeys[i];
              expect(isValidKey(key), isTrue);
              if (unnamed) {
                expect(
                    compareKey(key, entities[i].key, ignoreIds: true), isTrue);
              } else {
                expect(compareKey(key, entities[i].key), isTrue);
              }
            }
            return result.autoIdInsertKeys;
          });
        }

        if (transactional) {
          return withTransaction(test, xg: xg);
        }
        return test(null);
      }

      FutureOr<void> testInsertNegative(List<Entity> entities,
          {bool transactional = false, bool xg = false}) {
        void test(Transaction? transaction) {
          expect(
              transaction == null
                  ? datastore.commit(autoIdInserts: entities)
                  : datastore.commit(
                      autoIdInserts: entities, transaction: transaction),
              throwsA(isApplicationError));
        }

        if (transactional) {
          return withTransaction(test, xg: xg);
        }
        test(null);
      }

      var unnamedEntities1 = buildEntities(42, 43, partition: partition);
      var unnamedEntities5 = buildEntities(1, 6, partition: partition);
      var unnamedEntities26 = buildEntities(6, 32, partition: partition);
      var named20000 = buildEntities(1000, 21001,
          idFunction: (i) => 'named_${i}_of_10000', partition: partition);

      test('insert', () {
        return testInsert(unnamedEntities5, transactional: false).then((keys) {
          return delete(keys).then((_) {
            return lookup(keys).then((List<Entity?> entities) {
              for (var e in entities) {
                expect(e, isNull);
              }
            });
          });
        });
      });

      test('insert_transactional', () {
        return testInsert(unnamedEntities1, transactional: true).then((keys) {
          return delete(keys).then((_) {
            return lookup(keys).then((List<Entity?> entities) {
              for (var e in entities) {
                expect(e, isNull);
              }
            });
          });
        });
      });

      test('insert_transactional_xg', () {
        return testInsert(unnamedEntities5, transactional: true, xg: true)
            .then((keys) {
          return delete(keys).then((_) {
            return lookup(keys).then((List<Entity?> entities) {
              for (var e in entities) {
                expect(e, isNull);
              }
            });
          });
        });
      });

      test('negative_insert__incomplete_path', () {
        expect(() => datastore.commit(inserts: unnamedEntities1),
            throwsA(isApplicationError));
      });

      test('negative_insert_transactional_xg', () {
        return testInsertNegative(unnamedEntities26,
            transactional: true, xg: true);
      },
          skip: 'With Firestore in Datastore mode, transactions are no longer '
              'limited to 25 entity groups');

      test('negative_insert_20000_entities', () async {
        // Maybe it should not be a [DataStoreError] here?
        // FIXME/TODO: This was adapted
        expect(
            datastore.commit(inserts: named20000), throwsA(isSocketException));
      });

      // TODO: test invalid inserts (like entities without key, ...)
    });

    group('allocate_ids', () {
      test('allocate_ids_query', () {
        void compareResult(List<Key> keys, List<Key> completedKeys) {
          expect(completedKeys.length, equals(keys.length));
          for (var i = 0; i < keys.length; i++) {
            var insertedKey = keys[i];
            var completedKey = completedKeys[i];

            expect(completedKey.elements.length,
                equals(insertedKey.elements.length));
            for (var j = 0; j < insertedKey.elements.length - 1; j++) {
              expect(completedKey.elements[j], equals(insertedKey.elements[j]));
            }
            for (var j = insertedKey.elements.length - 1;
                j < insertedKey.elements.length;
                j++) {
              expect(completedKey.elements[j].kind,
                  equals(insertedKey.elements[j].kind));
              expect(completedKey.elements[j].id, isNotNull);
              expect(completedKey.elements[j].id, isInt);
            }
          }
        }

        var keys = buildKeys(1, 4, partition: partition);
        return datastore.allocateIds(keys).then((List<Key> completedKeys) {
          compareResult(keys, completedKeys);
          // TODO: Make sure we can insert these keys
          // FIXME: Insert currently doesn't through if entities already exist!
        });
      });
    });

    group('lookup', () {
      Future testLookup(List<Key> keysToLookup, List<Entity> entitiesToLookup,
          {bool transactional = false,
          bool xg = false,
          bool negative = false,
          bool named = false}) {
        expect(keysToLookup.length, equals(entitiesToLookup.length));
        for (var i = 0; i < keysToLookup.length; i++) {
          expect(
              compareKey(keysToLookup[i], entitiesToLookup[i].key,
                  ignoreIds: !named),
              isTrue);
        }

        Future test(Transaction? transaction) {
          return datastore.lookup(keysToLookup).then((List<Entity?> entities) {
            expect(entities.length, equals(keysToLookup.length));
            if (negative) {
              for (var i = 0; i < entities.length; i++) {
                expect(entities[i], isNull);
              }
            } else {
              for (var i = 0; i < entities.length; i++) {
                expect(compareKey(entities[i]!.key, keysToLookup[i]), isTrue);
                expect(
                    compareEntity(entities[i]!, entitiesToLookup[i],
                        ignoreIds: !named),
                    isTrue);
              }
            }
            if (transaction != null) {
              return datastore
                  .commit(transaction: transaction)
                  .then((_) => null);
            }
            return null;
          });
        }

        if (transactional) {
          return withTransaction(test, xg: xg);
        }
        return test(null);
      }

      var unnamedEntities1 = buildEntities(42, 43, partition: partition);
      var unnamedEntities5 = buildEntities(1, 6, partition: partition);
      var unnamedEntities20 = buildEntities(6, 26, partition: partition);
      var entitiesWithAllPropertyTypes =
          buildEntityWithAllProperties(1, 6, partition: partition);

      test('lookup', () {
        return insert([], unnamedEntities20, transactional: false).then((keys) {
          for (var key in keys) {
            expect(isValidKey(key), isTrue);
          }
          return testLookup(keys, unnamedEntities20).then((_) {
            return delete(keys, transactional: false);
          });
        });
      });

      test('lookup_with_all_properties', () {
        return insert(entitiesWithAllPropertyTypes, [], transactional: false)
            .then((_) {
          var keys = entitiesWithAllPropertyTypes.map((e) => e.key).toList();
          return testLookup(keys, entitiesWithAllPropertyTypes).then((_) {
            return delete(keys, transactional: false);
          });
        });
      });

      test('lookup_transactional', () {
        return insert([], unnamedEntities1).then((keys) {
          for (var key in keys) {
            expect(isValidKey(key), isTrue);
          }
          return testLookup(keys, unnamedEntities1, transactional: true)
              .then((_) => delete(keys));
        });
      });

      test('lookup_transactional_xg', () {
        return insert([], unnamedEntities5).then((keys) {
          for (var key in keys) {
            expect(isValidKey(key), isTrue);
          }
          return testLookup(keys, unnamedEntities5,
                  transactional: true, xg: true)
              .then((_) {
            return delete(keys);
          });
        });
      });

      // TODO: ancestor lookups, string id lookups
    });

    group('delete', () {
      Future testDelete(List<Key> keys,
          {bool transactional = false, bool xg = false}) {
        Future test(Transaction? transaction) {
          return datastore.commit(deletes: keys).then((_) {
            if (transaction != null) {
              return datastore.commit(transaction: transaction);
            }
            return null;
          });
        }

        if (transactional) {
          return withTransaction(test, xg: xg);
        }
        return test(null);
      }

      var unnamedEntities99 = buildEntities(6, 106, partition: partition);

      test('delete', () {
        return insert([], unnamedEntities99, transactional: false).then((keys) {
          for (var key in keys) {
            expect(isValidKey(key), isTrue);
          }
          return lookup(keys, transactional: false).then((entities) {
            for (var e in entities) {
              expect(e, isNotNull);
            }
            return testDelete(keys).then((_) {
              return lookup(keys, transactional: false).then((entities) {
                for (var e in entities) {
                  expect(e, isNull);
                }
              });
            });
          });
        });
      });

      // This should not work with [unamedEntities20], but is working!
      // FIXME TODO FIXME : look into this.
      test('delete_transactional', () {
        return insert([], unnamedEntities99, transactional: false).then((keys) {
          for (var key in keys) {
            expect(isValidKey(key), isTrue);
          }
          return lookup(keys, transactional: false).then((entities) {
            for (var e in entities) {
              expect(e, isNotNull);
            }
            return testDelete(keys, transactional: true).then((_) {
              return lookup(keys, transactional: false).then((entities) {
                for (var e in entities) {
                  expect(e, isNull);
                }
              });
            });
          });
        });
      });

      test('delete_transactional_xg', () {
        return insert([], unnamedEntities99, transactional: false).then((keys) {
          for (var key in keys) {
            expect(isValidKey(key), isTrue);
          }
          return lookup(keys, transactional: false).then((entities) {
            expect(entities.length, equals(unnamedEntities99.length));
            for (var e in entities) {
              expect(e, isNotNull);
            }
            return testDelete(keys, transactional: true, xg: true).then((_) {
              return lookup(keys, transactional: false).then((entities) {
                expect(entities.length, equals(unnamedEntities99.length));
                for (var e in entities) {
                  expect(e, isNull);
                }
              });
            });
          });
        });
      });

      // TODO: ancestor deletes, string id deletes
    });

    group('rollback', () {
      Future testRollback(List<Key> keys, {bool xg = false}) {
        return withTransaction((Transaction transaction) {
          return datastore
              .lookup(keys, transaction: transaction)
              .then((List<Entity?> entities) {
            return datastore.rollback(transaction);
          });
        }, xg: xg);
      }

      var namedEntities1 =
          buildEntities(42, 43, idFunction: (i) => 'i$i', partition: partition);
      var namedEntities5 =
          buildEntities(1, 6, idFunction: (i) => 'i$i', partition: partition);

      var namedEntities1Keys = namedEntities1.map((e) => e.key).toList();
      var namedEntities5Keys = namedEntities5.map((e) => e.key).toList();

      test('rollback', () {
        return testRollback(namedEntities1Keys);
      });

      test('rollback_xg', () {
        return testRollback(namedEntities5Keys, xg: true);
      });
    });

    group('empty_commit', () {
      Future testEmptyCommit(List<Key> keys,
          {bool transactional = false, bool xg = false}) {
        Future test(Transaction? transaction) {
          return (transaction == null
                  ? datastore.lookup(keys)
                  : datastore.lookup(keys, transaction: transaction))
              .then((List<Entity?> entities) {
            if (transaction == null) return datastore.commit();
            return datastore.commit(transaction: transaction);
          });
        }

        if (transactional) {
          return withTransaction(test, xg: xg);
        } else {
          return test(null);
        }
      }

      var namedEntities1 =
          buildEntities(42, 43, idFunction: (i) => 'i$i', partition: partition);
      var namedEntities5 =
          buildEntities(1, 6, idFunction: (i) => 'i$i', partition: partition);
      var namedEntities20 =
          buildEntities(6, 26, idFunction: (i) => 'i$i', partition: partition);

      var namedEntities1Keys = namedEntities1.map((e) => e.key).toList();
      var namedEntities5Keys = namedEntities5.map((e) => e.key).toList();
      var namedEntities20Keys = namedEntities20.map((e) => e.key).toList();

      test('empty_commit', () {
        return testEmptyCommit(namedEntities20Keys);
      });

      test('empty_commit_transactional', () {
        return testEmptyCommit(namedEntities1Keys);
      });

      test('empty_commit_transactional_xg', () {
        return testEmptyCommit(namedEntities5Keys);
      });

      /* Disabled until we validate if the server has started to support
       * more than 5 concurrent commits to different entity groups.
      test('negative_empty_commit_xg', () {
        expect(testEmptyCommit(
               namedEntities20Keys, transactional: true, xg: true),
               throwsA(isApplicationError));
      });
       */
    });

    group('conflicting_transaction', () {
      Future testConflictingTransaction(List<Entity> entities,
          {bool xg = false}) {
        Future test(List<Entity?> entities, Transaction transaction, value) {
          // Change entities:
          var changedEntities = List<Entity?>.filled(entities.length, null);
          for (var i = 0; i < entities.length; i++) {
            var entity = entities[i]!;
            var newProperties = Map<String, Object>.from(entity.properties);
            for (var prop in newProperties.keys) {
              newProperties[prop] = '${newProperties[prop]}conflict$value';
            }
            changedEntities[i] = Entity(entity.key, newProperties);
          }
          return datastore.commit(
              inserts: changedEntities as List<Entity>,
              transaction: transaction);
        }

        // Insert first
        return insert(entities, [], transactional: true).then((_) {
          var keys = entities.map((e) => e.key).toList();

          var numTransactions = 10;

          // Start transactions
          var transactions = <Future<Transaction>>[];
          for (var i = 0; i < numTransactions; i++) {
            transactions.add(datastore.beginTransaction(crossEntityGroup: xg));
          }
          return Future.wait(transactions)
              .then((List<Transaction> transactions) {
            // Do a lookup for the entities in every transaction
            List<Future<List<Entity?>>> lookups = <Future<List<Entity>>>[];
            for (var transaction in transactions) {
              lookups.add(datastore.lookup(keys, transaction: transaction));
            }
            return Future.wait(lookups).then((List<List<Entity?>> results) {
              // Do a conflicting commit in every transaction.
              var commits = <Future>[];
              for (var i = 0; i < transactions.length; i++) {
                var transaction = transactions[i];
                commits.add(test(results[i], transaction, i));
              }
              return Future.wait(commits);
            });
          });
        });
      }

      var namedEntities1 =
          buildEntities(42, 43, idFunction: (i) => 'i$i', partition: partition);
      var namedEntities5 =
          buildEntities(1, 6, idFunction: (i) => 'i$i', partition: partition);

      test('conflicting_transaction', () {
        expect(testConflictingTransaction(namedEntities1),
            throwsA(isTransactionAbortedError));
      });

      test('conflicting_transaction_xg', () {
        expect(testConflictingTransaction(namedEntities5, xg: true),
            throwsA(isTransactionAbortedError));
      });
    });

    group('query', () {
      Future<List<Entity>> testQuery(String kind,
          {List<Filter>? filters,
          List<Order>? orders,
          bool transactional = false,
          bool xg = false,
          int? offset,
          int? limit}) {
        Future<List<Entity>> test(Transaction? transaction) {
          var query = Query(
              kind: kind,
              filters: filters,
              orders: orders,
              offset: offset,
              limit: limit);
          return consumePages(
                  (_) => datastore.query(query, partition: partition))
              .then((List<Entity> entities) {
            if (transaction != null) {
              return datastore
                  .commit(transaction: transaction)
                  .then((_) => entities);
            }
            return entities;
          });
        }

        if (transactional) {
          return withTransaction(test, xg: xg);
        }
        return test(null);
      }

      Future testQueryAndCompare(String kind, List<Entity> expectedEntities,
          {List<Filter>? filters,
          List<Order>? orders,
          bool transactional = false,
          bool xg = false,
          bool correctOrder = true,
          int? offset,
          int? limit}) {
        return testQuery(kind,
                filters: filters,
                orders: orders,
                transactional: transactional,
                xg: xg,
                offset: offset,
                limit: limit)
            .then((List<Entity> entities) {
          expect(entities.length, equals(expectedEntities.length));

          if (correctOrder) {
            for (var i = 0; i < entities.length; i++) {
              expect(compareEntity(entities[i], expectedEntities[i]), isTrue);
            }
          } else {
            for (var i = 0; i < entities.length; i++) {
              var found = false;
              for (var j = 0; j < expectedEntities.length; j++) {
                if (compareEntity(entities[i], expectedEntities[i])) {
                  found = true;
                }
              }
              expect(found, isTrue);
            }
          }
        });
      }

      Future testOffsetLimitQuery(String kind, List<Entity> expectedEntities,
          {List<Order>? orders, bool transactional = false, bool xg = false}) {
        // We query for all subsets of expectedEntities
        // NOTE: This is O(0.5 * n^2) queries, but n is currently only 6.
        var queryTests = <Function>[];
        for (var start = 0; start < expectedEntities.length; start++) {
          for (var end = start; end < expectedEntities.length; end++) {
            var offset = start;
            var limit = end - start;
            var entities = expectedEntities.sublist(offset, offset + limit);
            queryTests.add(() {
              return testQueryAndCompare(kind, entities,
                  transactional: transactional,
                  xg: xg,
                  orders: orders,
                  offset: offset,
                  limit: limit);
            });
          }
        }
        // Query with limit higher than the number of results.
        queryTests.add(() {
          return testQueryAndCompare(kind, expectedEntities,
              transactional: transactional,
              xg: xg,
              orders: orders,
              offset: 0,
              limit: expectedEntities.length * 10);
        });

        return Future.forEach(queryTests, (dynamic f) => f());
      }

      const testQueryKind = 'TestQueryKind';
      var stringNamedEntities = buildEntities(1, 6,
          idFunction: (i) => 'str$i',
          kind: testQueryKind,
          partition: partition);
      var stringNamedKeys = stringNamedEntities.map((e) => e.key).toList();

      var queryKey = testPropertyKeyPrefix;
      var queryUpperbound = '${testPropertyValuePrefix}4';
      var queryLowerBound = '${testPropertyValuePrefix}1';
      var queryListEntry = '${testListValue}2';
      var queryIndexValue = '${testIndexedPropertyValuePrefix}1';

      reverseOrderFunction(Entity a, Entity b) {
        // Reverse the order
        return -1 *
            (a.properties[queryKey] as String)
                .compareTo(b.properties[queryKey].toString());
      }

      filterFunction(Entity entity) {
        var value = entity.properties[queryKey] as String;
        return value.compareTo(queryUpperbound) == -1 &&
            value.compareTo(queryLowerBound) == 1;
      }

      listFilterFunction(Entity entity) {
        var values = entity.properties[testListProperty] as List;
        return values.contains(queryListEntry);
      }

      indexFilterMatches(Entity entity) {
        return entity.properties[testIndexedProperty] == queryIndexValue;
      }

      var sorted = stringNamedEntities.toList()..sort(reverseOrderFunction);
      var filtered = stringNamedEntities.where(filterFunction).toList();
      var sortedAndFiltered = sorted.where(filterFunction).toList();
      var sortedAndListFiltered = sorted.where(listFilterFunction).toList();
      var indexedEntity = sorted.where(indexFilterMatches).toList();
      assert(indexedEntity.length == 1);

      var filters = [
        Filter(FilterRelation.GreatherThan, queryKey, queryLowerBound),
        Filter(FilterRelation.LessThan, queryKey, queryUpperbound),
      ];
      var listFilters = [
        Filter(FilterRelation.Equal, testListProperty, queryListEntry)
      ];
      var indexedPropertyFilter = [
        Filter(FilterRelation.Equal, testIndexedProperty, queryIndexValue),
        Filter(
            FilterRelation.Equal, testBlobIndexedProperty, testBlobIndexedValue)
      ];
      var unIndexedPropertyFilter = [
        Filter(FilterRelation.Equal, testUnindexedProperty, queryIndexValue)
      ];

      var orders = [Order(OrderDirection.Decending, queryKey)];

      test('query', () {
        return insert(stringNamedEntities, <Entity>[]).then((keys) {
          return waitUntilEntitiesReady(datastore, stringNamedKeys, partition)
              .then((_) {
            var tests = [
              // EntityKind query
              () => testQueryAndCompare(testQueryKind, stringNamedEntities,
                  transactional: false, correctOrder: false),
              () => testQueryAndCompare(testQueryKind, stringNamedEntities,
                  transactional: true, correctOrder: false),
              () => testQueryAndCompare(testQueryKind, stringNamedEntities,
                  transactional: true, correctOrder: false, xg: true),

              // EntityKind query with order
              () => testQueryAndCompare(testQueryKind, sorted,
                  transactional: false, orders: orders),
              () => testQueryAndCompare(testQueryKind, sorted,
                  transactional: true, orders: orders),
              () => testQueryAndCompare(testQueryKind, sorted,
                  transactional: false, xg: true, orders: orders),

              // EntityKind query with filter
              () => testQueryAndCompare(testQueryKind, filtered,
                  transactional: false, filters: filters),
              () => testQueryAndCompare(testQueryKind, filtered,
                  transactional: true, filters: filters),
              () => testQueryAndCompare(testQueryKind, filtered,
                  transactional: false, xg: true, filters: filters),

              // EntityKind query with filter + order
              () => testQueryAndCompare(testQueryKind, sortedAndFiltered,
                  transactional: false, filters: filters, orders: orders),
              () => testQueryAndCompare(testQueryKind, sortedAndFiltered,
                  transactional: true, filters: filters, orders: orders),
              () => testQueryAndCompare(testQueryKind, sortedAndFiltered,
                  transactional: false,
                  xg: true,
                  filters: filters,
                  orders: orders),

              // EntityKind query with IN filter + order
              () => testQueryAndCompare(testQueryKind, sortedAndListFiltered,
                  transactional: false, filters: listFilters, orders: orders),
              () => testQueryAndCompare(testQueryKind, sortedAndListFiltered,
                  transactional: true, filters: listFilters, orders: orders),
              () => testQueryAndCompare(testQueryKind, sortedAndListFiltered,
                  transactional: false,
                  xg: true,
                  filters: listFilters,
                  orders: orders),

              // Limit & Offset test
              () => testOffsetLimitQuery(testQueryKind, sorted,
                  transactional: false, orders: orders),
              () => testOffsetLimitQuery(testQueryKind, sorted,
                  transactional: true, orders: orders),
              () => testOffsetLimitQuery(testQueryKind, sorted,
                  transactional: false, xg: true, orders: orders),

              // Query for indexed property
              () => testQueryAndCompare(testQueryKind, indexedEntity,
                  transactional: false, filters: indexedPropertyFilter),
              () => testQueryAndCompare(testQueryKind, indexedEntity,
                  transactional: true, filters: indexedPropertyFilter),
              () => testQueryAndCompare(testQueryKind, indexedEntity,
                  transactional: false,
                  xg: true,
                  filters: indexedPropertyFilter),

              // Query for un-indexed property
              () => testQueryAndCompare(testQueryKind, [],
                  transactional: false, filters: unIndexedPropertyFilter),
              () => testQueryAndCompare(testQueryKind, [],
                  transactional: true, filters: unIndexedPropertyFilter),
              () => testQueryAndCompare(testQueryKind, [],
                  transactional: false,
                  xg: true,
                  filters: unIndexedPropertyFilter),

              // Delete results
              () => delete(stringNamedKeys, transactional: true),

              // Wait until the entity deletes are reflected in the indices.
              () =>
                  waitUntilEntitiesGone(datastore, stringNamedKeys, partition),

              // Make sure queries don't return results
              () =>
                  testQueryAndCompare(testQueryKind, [], transactional: false),
              () => testQueryAndCompare(testQueryKind, [], transactional: true),
              () => testQueryAndCompare(testQueryKind, [],
                  transactional: true, xg: true),
              () => testQueryAndCompare(testQueryKind, [],
                  transactional: false, filters: filters, orders: orders),
            ];
            return Future.forEach(tests, (dynamic f) => f());
          });
        });

        // TODO: query by multiple keys, multiple sort orders, ...
      });

      test('ancestor_query', () {
        /*
         * This test creates an
         * RootKind:1 -- This defines the entity group (no entity with that key)
         *    + SubKind:1  -- This a subpath (no entity with that key)
         *        + SubSubKind:1  -- This is a real entity of kind SubSubKind
         *        + SubSubKind2:1 -- This is a real entity of kind SubSubKind2
         */
        var rootKey = Key([KeyElement('RootKind', 1)], partition: partition);
        var subKey = Key.fromParent('SubKind', 1, parent: rootKey);
        var subSubKey = Key.fromParent('SubSubKind', 1, parent: subKey);
        var subSubKey2 = Key.fromParent('SubSubKind2', 1, parent: subKey);
        var properties = {'foo': 'bar'};

        var entity = Entity(subSubKey, properties);
        var entity2 = Entity(subSubKey2, properties);

        var orders = [Order(OrderDirection.Ascending, '__key__')];

        return datastore.commit(inserts: [entity, entity2]).then((_) {
          var futures = [
            // FIXME/TODO: Ancestor queries should be strongly consistent.
            // We should not need to wait for them.
            () {
              return waitUntilEntitiesReady(
                  datastore, [subSubKey, subSubKey2], partition);
            },
            // Test that lookup only returns inserted entities.
            () {
              return datastore
                  .lookup([rootKey, subKey, subSubKey, subSubKey2]).then(
                      (List<Entity?> entities) {
                expect(entities.length, 4);
                expect(entities[0], isNull);
                expect(entities[1], isNull);
                expect(entities[2], isNotNull);
                expect(entities[3], isNotNull);
                expect(compareEntity(entity, entities[2]!), isTrue);
                expect(compareEntity(entity2, entities[3]!), isTrue);
              });
            },

            // Query by ancestor.
            // - by [rootKey]
            () {
              var ancestorQuery = Query(ancestorKey: rootKey, orders: orders);
              return consumePages((_) =>
                      datastore.query(ancestorQuery, partition: partition))
                  .then((results) {
                expect(results.length, 2);
                expect(compareEntity(entity, results[0]), isTrue);
                expect(compareEntity(entity2, results[1]), isTrue);
              });
            },
            // - by [subKey]
            () {
              var ancestorQuery = Query(ancestorKey: subKey, orders: orders);
              return consumePages((_) =>
                      datastore.query(ancestorQuery, partition: partition))
                  .then((results) {
                expect(results.length, 2);
                expect(compareEntity(entity, results[0]), isTrue);
                expect(compareEntity(entity2, results[1]), isTrue);
              });
            },
            // - by [subSubKey]
            () {
              var ancestorQuery = Query(ancestorKey: subSubKey);
              return consumePages((_) =>
                      datastore.query(ancestorQuery, partition: partition))
                  .then((results) {
                expect(results.length, 1);
                expect(compareEntity(entity, results[0]), isTrue);
              });
            },
            // - by [subSubKey2]
            () {
              var ancestorQuery = Query(ancestorKey: subSubKey2);
              return consumePages((_) =>
                      datastore.query(ancestorQuery, partition: partition))
                  .then((results) {
                expect(results.length, 1);
                expect(compareEntity(entity2, results[0]), isTrue);
              });
            },

            // Query by ancestor and kind.
            // - by [rootKey] + 'SubSubKind'
            () {
              var query = Query(ancestorKey: rootKey, kind: 'SubSubKind');
              return consumePages(
                      (_) => datastore.query(query, partition: partition))
                  .then((List<Entity> results) {
                expect(results.length, 1);
                expect(compareEntity(entity, results[0]), isTrue);
              });
            },
            // - by [rootKey] + 'SubSubKind2'
            () {
              var query = Query(ancestorKey: rootKey, kind: 'SubSubKind2');
              return consumePages(
                      (_) => datastore.query(query, partition: partition))
                  .then((List<Entity> results) {
                expect(results.length, 1);
                expect(compareEntity(entity2, results[0]), isTrue);
              });
            },
            // - by [subSubKey] + 'SubSubKind'
            () {
              var query = Query(ancestorKey: subSubKey, kind: 'SubSubKind');
              return consumePages(
                      (_) => datastore.query(query, partition: partition))
                  .then((List<Entity> results) {
                expect(results.length, 1);
                expect(compareEntity(entity, results[0]), isTrue);
              });
            },
            // - by [subSubKey2] + 'SubSubKind2'
            () {
              var query = Query(ancestorKey: subSubKey2, kind: 'SubSubKind2');
              return consumePages(
                      (_) => datastore.query(query, partition: partition))
                  .then((List<Entity> results) {
                expect(results.length, 1);
                expect(compareEntity(entity2, results[0]), isTrue);
              });
            },
            // - by [subSubKey] + 'SubSubKind2'
            () {
              var query = Query(ancestorKey: subSubKey, kind: 'SubSubKind2');
              return consumePages(
                      (_) => datastore.query(query, partition: partition))
                  .then((List<Entity> results) {
                expect(results.length, 0);
              });
            },
            // - by [subSubKey2] + 'SubSubKind'
            () {
              var query = Query(ancestorKey: subSubKey2, kind: 'SubSubKind');
              return consumePages(
                      (_) => datastore.query(query, partition: partition))
                  .then((List<Entity> results) {
                expect(results.length, 0);
              });
            },

            // Cleanup
            () {
              return datastore.commit(deletes: [subSubKey, subSubKey2]);
            }
          ];
          return Future.forEach(futures, (dynamic f) => f())
              .then(expectAsync1((_) {}));
        });
      });
    });
  });
}

Future cleanupDB(Datastore db, String? namespace) {
  Future<List<String?>> getKinds(String? namespace) {
    var partition = Partition(namespace);
    var q = Query(kind: '__kind__');
    return consumePages((_) => db.query(q, partition: partition))
        .then((List<Entity> entities) {
      return entities
          .map((Entity e) => e.key.elements.last.id as String?)
          .where((String? kind) => !kind!.contains('__'))
          .toList();
    });
  }

  // cleanup() will call itself again as long as the DB is not clean.
  Future<void> cleanup(String? namespace, String? kind) {
    var partition = Partition(namespace);
    var q = Query(kind: kind, limit: 500);
    return consumePages((_) => db.query(q, partition: partition))
        .then((List<Entity> entities) {
      if (entities.isEmpty) return null;

      print('[cleanupDB]: Removing left-over ${entities.length} entities');
      var deletes = entities.map((e) => e.key).toList();
      return db.commit(deletes: deletes).then((_) => cleanup(namespace, kind));
    });
  }

  return getKinds(namespace).then((List<String?> kinds) {
    return Future.forEach(kinds, (String? kind) {
      return cleanup(namespace, kind);
    });
  });
}

Future waitUntilEntitiesReady(Datastore db, List<Key> keys, Partition p) {
  return waitUntilEntitiesHelper(db, keys, true, p);
}

Future waitUntilEntitiesGone(Datastore db, List<Key> keys, Partition p) {
  return waitUntilEntitiesHelper(db, keys, false, p);
}

Future waitUntilEntitiesHelper(
    Datastore db, List<Key> keys, bool positive, Partition p) {
  var keysByKind = <String, List<Key>>{};
  for (var key in keys) {
    keysByKind.putIfAbsent(key.elements.last.kind, () => <Key>[]).add(key);
  }

  Future waitForKeys(String kind, List<Key>? keys) {
    var q = Query(kind: kind);
    return consumePages((_) => db.query(q, partition: p)).then((entities) {
      for (var key in keys!) {
        var found = false;
        for (var entity in entities) {
          if (key == entity.key) found = true;
        }
        if (positive) {
          if (!found) return waitForKeys(kind, keys);
        } else {
          if (found) return waitForKeys(kind, keys);
        }
      }
      return null;
    });
  }

  return Future.forEach(keysByKind.keys.toList(), (String kind) {
    return waitForKeys(kind, keysByKind[kind]);
  });
}

Future main() async {
  late Datastore datastore;
  late Client client;

  var scopes = datastore_impl.DatastoreImpl.scopes;
  await withAuthClient(scopes, (String project, Client httpClient) {
    datastore = datastore_impl.DatastoreImpl(httpClient, project);
    client = httpClient;
    return cleanupDB(datastore, null);
  });

  tearDownAll(() async {
    await cleanupDB(datastore, null);
    client.close();
  });

  runTests(datastore, null);
}
