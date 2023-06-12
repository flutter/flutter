// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library db_test;

/// NOTE: In order to run these tests, the following datastore indices must
/// exist:
/// $ cat index.yaml
/// indexes:
/// - kind: User
///   ancestor: no
///   properties:
///   - name: name
///     direction: asc
///   - name: nickname
///     direction: desc
///
/// - kind: User
///   ancestor: no
///   properties:
///   - name: name
///     direction: desc
///   - name: nickname
///     direction: desc
///
/// - kind: User
///   ancestor: no
///   properties:
///   - name: name
///     direction: desc
///   - name: nickname
///     direction: asc
///
/// - kind: User
///   ancestor: no
///   properties:
///   - name: language
///     direction: asc
///   - name: name
///     direction: asc
///
/// $ gcloud datastore create-indexes index.yaml
///
/// Now, wait for indexing done
import 'dart:async';

import 'package:gcloud/db.dart' as db;
import 'package:gcloud/src/datastore_impl.dart' as datastore_impl;
import 'package:http/http.dart';
import 'package:test/test.dart';

import '../../common_e2e.dart';
import '../../datastore/e2e/datastore_test_impl.dart' as datastore_test;

@db.Kind()
class Person extends db.Model {
  @db.StringProperty()
  String? name;

  @db.IntProperty()
  int? age;

  @db.ModelKeyProperty(propertyName: 'mangledWife')
  db.Key? wife;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => sameAs(other);

  bool sameAs(Object other) {
    return other is Person &&
        id == other.id &&
        parentKey == other.parentKey &&
        name == other.name &&
        age == other.age &&
        wife == other.wife;
  }

  @override
  String toString() => 'Person(id: $id, name: $name, age: $age)';
}

@db.Kind(idType: db.IdType.String)
class PersonStringId extends db.Model<String> {
  String? get name => id;

  @db.IntProperty()
  int? age;

  @db.ModelKeyProperty(propertyName: 'mangledWife')
  db.Key? wife;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) => sameAs(other);

  bool sameAs(Object other) {
    return other is PersonStringId &&
        id == other.id &&
        parentKey == other.parentKey &&
        age == other.age &&
        wife == other.wife;
  }

  @override
  String toString() => 'PersonStringId(id/name: $name, age: $age)';
}

@db.Kind()
class User extends Person {
  @db.StringProperty()
  String? nickname;

  @db.StringListProperty(propertyName: 'language')
  List<String>? languages = const [];

  @override
  bool sameAs(Object other) {
    if (!(super.sameAs(other) && other is User && nickname == other.nickname)) {
      return false;
    }

    var user = other;
    if (languages == null) {
      if (user.languages == null) return true;
      return false;
    }
    if (languages!.length != user.languages?.length) {
      return false;
    }

    for (var i = 0; i < languages!.length; i++) {
      if (languages![i] != user.languages![i]) {
        return false;
      }
    }
    return true;
  }

  @override
  String toString() =>
      'User(${super.toString()}, nickname: $nickname, languages: $languages';
}

@db.Kind()
class ExpandoPerson extends db.ExpandoModel {
  @db.StringProperty()
  String? name;

  @db.StringProperty(propertyName: 'NN')
  String? nickname;

  @override
  // ignore: hash_and_equals
  bool operator ==(Object other) {
    if (other is ExpandoPerson && id == other.id && name == other.name) {
      if (additionalProperties.length != other.additionalProperties.length) {
        return false;
      }
      for (var key in additionalProperties.keys) {
        if (additionalProperties[key] != other.additionalProperties[key]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

Future sleep(Duration duration) => Future.delayed(duration);

void runTests(db.DatastoreDB store, String? namespace) {
  var partition = namespace != null
      ? store.newPartition(namespace)
      : store.defaultPartition;

  void compareModels(List<db.Model> expectedModels, List<db.Model?> models,
      {bool anyOrder = false}) {
    expect(models.length, equals(expectedModels.length));
    if (anyOrder) {
      // Do expensive O(n^2) search.
      for (var searchModel in expectedModels) {
        var found = false;
        for (var m in models) {
          if (m == searchModel) {
            found = true;
            break;
          }
        }
        expect(found, isTrue);
      }
    } else {
      for (var i = 0; i < expectedModels.length; i++) {
        expect(models[i], equals(expectedModels[i]));
      }
    }
  }

  Future testInsertLookupDelete(List<db.Model> objects,
      {bool transactional = false}) {
    var keys = objects.map((db.Model obj) => obj.key).toList();

    if (transactional) {
      return store.withTransaction((db.Transaction commitTransaction) {
        commitTransaction.queueMutations(inserts: objects);
        return commitTransaction.commit();
      }).then((_) {
        return store.withTransaction((db.Transaction deleteTransaction) {
          return deleteTransaction.lookup(keys).then((List<db.Model?> models) {
            compareModels(objects, models);
            deleteTransaction.queueMutations(deletes: keys);
            return deleteTransaction.commit();
          });
        });
      });
    } else {
      return store.commit(inserts: objects).then(expectAsync1((_) {
        return store.lookup(keys).then(expectAsync1((List<db.Model?> models) {
          compareModels(objects, models);
          return store.commit(deletes: keys).then(expectAsync1((_) {
            return store
                .lookup(keys)
                .then(expectAsync1((List<db.Model?> models) {
              for (var i = 0; i < models.length; i++) {
                expect(models[i], isNull);
              }
            }));
          }));
        }));
      }));
    }
  }

  group('key', () {
    test('equal_and_hashcode', () {
      var k1 = store.emptyKey.append(User, id: 10).append(Person, id: 12);
      var k2 = store.defaultPartition.emptyKey
          .append(User, id: 10)
          .append(Person, id: 12);
      expect(k1, equals(k2));
      expect(k1.hashCode, equals(k2.hashCode));
    });
  });

  group('e2e_db', () {
    group('insert_lookup_delete', () {
      test('persons', () {
        var root = partition.emptyKey;
        var persons = <Person>[];
        for (var i = 1; i <= 10; i++) {
          persons.add(Person()
            ..id = i
            ..parentKey = root
            ..age = 42 + i
            ..name = 'user$i');
        }
        persons.first.wife = persons.last.key;
        return testInsertLookupDelete(persons);
      });
      test('PersonStringId', () {
        var root = partition.emptyKey;
        var persons = <PersonStringId>[];
        for (var i = 1; i <= 10; i++) {
          persons.add(PersonStringId()
            ..id = 'user$i'
            ..parentKey = root
            ..age = 42 + i);
        }
        persons.first.wife = persons.last.key;
        return testInsertLookupDelete(persons);
      });
      test('users', () {
        var root = partition.emptyKey;
        var users = <User>[];
        for (var i = 1; i <= 10; i++) {
          users.add(User()
            ..id = i
            ..parentKey = root
            ..age = 42 + i
            ..name = 'user$i'
            ..nickname = 'nickname${i % 3}');
        }
        return testInsertLookupDelete(users);
      });
      test('expando_insert', () {
        var root = partition.emptyKey;
        var expandoPersons = <ExpandoPerson>[];
        for (var i = 1; i <= 10; i++) {
          dynamic expandoPerson = ExpandoPerson()
            ..parentKey = root
            ..id = i
            ..name = 'user$i';
          expandoPerson.foo = 'foo$i';
          expandoPerson.bar = i;
          expect(expandoPerson.additionalProperties['foo'], equals('foo$i'));
          expect(expandoPerson.additionalProperties['bar'], equals(i));
          expandoPersons.add(expandoPerson as ExpandoPerson);
        }
        return testInsertLookupDelete(expandoPersons);
      });
      test('transactional_insert', () {
        var root = partition.emptyKey;
        var models = <db.Model>[];

        models.add(Person()
          ..id = 1
          ..parentKey = root
          ..age = 1
          ..name = 'user1');
        models.add(User()
          ..id = 2
          ..parentKey = root
          ..age = 2
          ..name = 'user2'
          ..nickname = 'nickname2');
        dynamic expandoPerson = ExpandoPerson()
          ..parentKey = root
          ..id = 3
          ..name = 'user1';
        expandoPerson.foo = 'foo1';
        expandoPerson.bar = 2;

        return testInsertLookupDelete(models, transactional: true);
      });

      test('parent_key', () {
        var root = partition.emptyKey;
        var users = <db.Model>[];
        for (var i = 333; i <= 334; i++) {
          users.add(User()
            ..id = i
            ..parentKey = root
            ..age = 42 + i
            ..name = 'user$i'
            ..nickname = 'nickname${i % 3}');
        }
        var persons = <db.Model>[];
        for (var i = 335; i <= 336; i++) {
          persons.add(Person()
            ..id = i
            ..parentKey = root
            ..age = 42 + i
            ..name = 'person$i');
        }

        // We test that we can insert + lookup
        // users[0], (persons[0] + users[0] as parent)
        // persons[1], (users[1] + persons[0] as parent)
        persons[0].parentKey = users[0].key;
        users[1].parentKey = persons[1].key;

        return testInsertLookupDelete([...users, ...persons]);
      });

      test('auto_ids', () {
        var root = partition.emptyKey;
        var persons = <Person>[];
        persons.add(Person()
          ..id = 42
          ..parentKey = root
          ..age = 80
          ..name = 'user80');
        // Auto id person with parentKey
        persons.add(Person()
          ..parentKey = root
          ..age = 81
          ..name = 'user81');
        // Auto id person with non-root parentKey
        var fatherKey = persons.first.parentKey;
        persons.add(Person()
          ..parentKey = fatherKey
          ..age = 82
          ..name = 'user82');
        persons.add(Person()
          ..id = 43
          ..parentKey = root
          ..age = 83
          ..name = 'user83');
        return store.commit(inserts: persons).then(expectAsync1((_) {
          // At this point, autoIds are allocated and are reflected in the
          // models (as well as parentKey if it was empty).

          var keys = persons.map((db.Model obj) => obj.key).toList();

          for (var i = 0; i < persons.length; i++) {
            expect(persons[i].age, equals(80 + i));
            expect(persons[i].name, equals('user${80 + i}'));
          }

          expect(persons[0].id, equals(42));
          expect(persons[0].parentKey, equals(root));

          expect(persons[1].id, isNotNull);
          expect(persons[1].id is int, isTrue);
          expect(persons[1].parentKey, equals(root));

          expect(persons[2].id, isNotNull);
          expect(persons[2].id is int, isTrue);
          expect(persons[2].parentKey, equals(fatherKey));

          expect(persons[3].id, equals(43));
          expect(persons[3].parentKey, equals(root));

          expect(persons[1].id != persons[2].id, isTrue);
          // NOTE: We can't make assumptions about the id of persons[3],
          // because an id doesn't need to be globally unique, only under
          // entities with the same parent.

          return store.lookup(keys).then(expectAsync1((List<db.Model?> models) {
            // Since the id/parentKey fields are set after commit and a lookup
            // returns new model instances, we can do full model comparison
            // here.
            compareModels(persons, models);
            return store.commit(deletes: keys).then(expectAsync1((_) {
              return store.lookup(keys).then(expectAsync1((List models) {
                for (var i = 0; i < models.length; i++) {
                  expect(models[i], isNull);
                }
              }));
            }));
          }));
        }));
      });
    });

    test('query', () {
      var root = partition.emptyKey;
      var users = <User>[];
      for (var i = 1; i <= 10; i++) {
        var languages = <String>[];
        if (i == 9) {
          languages = ['foo'];
        } else if (i == 10) {
          languages = ['foo', 'bar'];
        }
        users.add(User()
          ..id = i
          ..parentKey = root
          ..wife = root.append(User, id: 42 + i)
          ..age = 42 + i
          ..name = 'user$i'
          ..nickname = 'nickname${i % 3}'
          ..languages = languages);
      }

      var expandoPersons = <ExpandoPerson>[];
      for (var i = 1; i <= 3; i++) {
        dynamic expandoPerson = ExpandoPerson()
          ..parentKey = root
          ..id = i
          ..name = 'user$i'
          ..nickname = 'nickuser$i';
        expandoPerson.foo = 'foo$i';
        expandoPerson.bar = i;
        expect(expandoPerson.additionalProperties['foo'], equals('foo$i'));
        expect(expandoPerson.additionalProperties['bar'], equals(i));
        expandoPersons.add(expandoPerson as ExpandoPerson);
      }

      var lowerBound = 'user2';

      var usersSortedNameDescNicknameAsc = List<User>.from(users);
      usersSortedNameDescNicknameAsc.sort((User a, User b) {
        var result = b.name!.compareTo(a.name!);
        if (result == 0) return a.nickname!.compareTo(b.nickname!);
        return result;
      });

      var usersSortedNameDescNicknameDesc = List<User>.from(users);
      usersSortedNameDescNicknameDesc.sort((User a, User b) {
        var result = b.name!.compareTo(a.name!);
        if (result == 0) return b.nickname!.compareTo(a.nickname!);
        return result;
      });

      var usersSortedAndFilteredNameDescNicknameAsc =
          usersSortedNameDescNicknameAsc.where((User u) {
        return lowerBound.compareTo(u.name!) <= 0;
      }).toList();

      var usersSortedAndFilteredNameDescNicknameDesc =
          usersSortedNameDescNicknameDesc.where((User u) {
        return lowerBound.compareTo(u.name!) <= 0;
      }).toList();

      var fooUsers =
          users.where((User u) => u.languages!.contains('foo')).toList();
      var barUsers =
          users.where((User u) => u.languages!.contains('bar')).toList();
      var usersWithWife = users
          .where((User u) => u.wife == root.append(User, id: 42 + 3))
          .toList();

      var allInserts = <db.Model>[...users, ...expandoPersons];
      var allKeys = allInserts.map((db.Model model) => model.key).toList();
      return store.commit(inserts: allInserts).then((_) {
        return Future.wait([
          waitUntilEntitiesReady<User>(
              store, users.map((u) => u.key).toList(), partition),
          waitUntilEntitiesReady<ExpandoPerson>(
              store, expandoPersons.map((u) => u.key).toList(), partition),
        ]).then((_) {
          var tests = [
            // Queries for [Person] return no results, we only have [User]
            // objects.
            () {
              return store
                  .query<Person>(partition: partition)
                  .run()
                  .toList()
                  .then((List<db.Model> models) {
                compareModels([], models);
              });
            },

            // All users query
            () {
              return store
                  .query<User>(partition: partition)
                  .run()
                  .toList()
                  .then((List<db.Model> models) {
                compareModels(users, models, anyOrder: true);
              });
            },

            // Sorted query
            () async {
              var query = store.query<User>(partition: partition)
                ..order('-name')
                ..order('nickname');
              var models = await runQueryWithExponentialBackoff(
                  query, usersSortedNameDescNicknameAsc.length);
              compareModels(usersSortedNameDescNicknameAsc, models);
            },
            () async {
              var query = store.query<User>(partition: partition)
                ..order('-name')
                ..order('-nickname')
                ..run();
              var models = await runQueryWithExponentialBackoff(
                  query, usersSortedNameDescNicknameDesc.length);
              compareModels(usersSortedNameDescNicknameDesc, models);
            },

            // Sorted query with filter
            () async {
              var query = store.query<User>(partition: partition)
                ..filter('name >=', lowerBound)
                ..order('-name')
                ..order('nickname');
              var models = await runQueryWithExponentialBackoff(
                  query, usersSortedAndFilteredNameDescNicknameAsc.length);
              compareModels(usersSortedAndFilteredNameDescNicknameAsc, models);
            },
            () async {
              var query = store.query<User>(partition: partition)
                ..filter('name >=', lowerBound)
                ..order('-name')
                ..order('-nickname')
                ..run();
              var models = await runQueryWithExponentialBackoff(
                  query, usersSortedAndFilteredNameDescNicknameDesc.length);
              compareModels(usersSortedAndFilteredNameDescNicknameDesc, models);
            },

            // Filter lists
            () async {
              var query = store.query<User>(partition: partition)
                ..filter('languages =', 'foo')
                ..order('name')
                ..run();
              var models =
                  await runQueryWithExponentialBackoff(query, fooUsers.length);
              compareModels(fooUsers, models, anyOrder: true);
            },
            () async {
              var query = store.query<User>(partition: partition)
                ..filter('languages =', 'bar')
                ..order('name')
                ..run();
              var models =
                  await runQueryWithExponentialBackoff(query, barUsers.length);
              compareModels(barUsers, models, anyOrder: true);
            },

            // Filter equals
            () async {
              var wifeKey = root.append(User, id: usersWithWife.first.wife!.id);
              var query = store.query<User>(partition: partition)
                ..filter('wife =', wifeKey)
                ..run();
              var models = await runQueryWithExponentialBackoff(
                  query, usersWithWife.length);
              compareModels(usersWithWife, models, anyOrder: true);
            },

            // Simple limit/offset test.
            () async {
              var query = store.query<User>(partition: partition)
                ..order('-name')
                ..order('nickname')
                ..offset(3)
                ..limit(4);
              var expectedModels =
                  usersSortedAndFilteredNameDescNicknameAsc.sublist(3, 7);
              var models = await runQueryWithExponentialBackoff(
                  query, expectedModels.length);
              compareModels(expectedModels, models);
            },

            // Expando queries: Filter on normal property.
            () async {
              var query = store.query<ExpandoPerson>(partition: partition)
                ..filter('name =', expandoPersons.last.name)
                ..run();
              var models = await runQueryWithExponentialBackoff(query, 1);
              compareModels([expandoPersons.last], models);
            },
            // Expando queries: Filter on expanded String property
            () async {
              var query = store.query<ExpandoPerson>(partition: partition)
                ..filter('foo =', (expandoPersons.last as dynamic).foo)
                ..run();
              var models = await runQueryWithExponentialBackoff(query, 1);
              compareModels([expandoPersons.last], models);
            },
            // Expando queries: Filter on expanded int property
            () async {
              var query = store.query<ExpandoPerson>(partition: partition)
                ..filter('bar =', (expandoPersons.last as dynamic).bar)
                ..run();
              var models = await runQueryWithExponentialBackoff(query, 1);
              compareModels([expandoPersons.last], models);
            },
            // Expando queries: Filter normal property with different
            // propertyName (datastore name is 'NN').
            () async {
              var query = store.query<ExpandoPerson>(partition: partition)
                ..filter('nickname =', expandoPersons.last.nickname)
                ..run();
              var models = await runQueryWithExponentialBackoff(query, 1);
              compareModels([expandoPersons.last], models);
            },

            // Delete results
            () => store.commit(deletes: allKeys),

            // Wait until the entity deletes are reflected in the indices.
            () => Future.wait([
                  waitUntilEntitiesGone<User>(
                      store, users.map((u) => u.key).toList(), partition),
                  waitUntilEntitiesGone<ExpandoPerson>(store,
                      expandoPersons.map((u) => u.key).toList(), partition),
                ]),

            // Make sure queries don't return results
            () => store.lookup(allKeys).then((List<db.Model?> models) {
                  expect(models.length, equals(allKeys.length));
                  for (var model in models) {
                    expect(model, isNull);
                  }
                }),
          ];
          return Future.forEach(tests, (dynamic f) => f());
        });
      });
    });
  });
}

Future<List<db.Model>> runQueryWithExponentialBackoff(
    db.Query query, int expectedResults) async {
  for (var i = 0; i <= 6; i++) {
    if (i > 0) {
      // Wait for 0.1s, 0.2s, ..., 12.8s
      var duration = Duration(milliseconds: 100 * (2 << i));
      print('Running query did return less results than expected.'
          'Using exponential backoff: Sleeping for $duration.');
      await sleep(duration);
    }

    var models = await query.run().toList();
    if (models.length >= expectedResults) {
      return models;
    }
  }

  throw Exception(
      'Tried running a query with exponential backoff, giving up now.');
}

Future waitUntilEntitiesReady<T extends db.Model>(
    db.DatastoreDB mdb, List<db.Key> keys, db.Partition partition) {
  return waitUntilEntitiesHelper<T>(mdb, keys, true, partition);
}

Future waitUntilEntitiesGone<T extends db.Model>(
    db.DatastoreDB mdb, List<db.Key> keys, db.Partition partition) {
  return waitUntilEntitiesHelper<T>(mdb, keys, false, partition);
}

Future<void> waitUntilEntitiesHelper<T extends db.Model>(
  db.DatastoreDB mdb,
  List<db.Key> keys,
  bool positive,
  db.Partition partition,
) async {
  var done = false;
  while (!done) {
    final models = await mdb.query<T>(partition: partition).run().toList();

    done = true;
    for (var key in keys) {
      var found = false;
      for (var model in models) {
        if (key == model.key) found = true;
      }
      if (positive) {
        if (!found) {
          done = false;
        }
      } else {
        if (found) {
          done = false;
        }
      }
    }
  }
}

Future main() async {
  late db.DatastoreDB store;
  BaseClient? client;

  var scopes = datastore_impl.DatastoreImpl.scopes;
  await withAuthClient(scopes, (String project, httpClient) {
    var datastore = datastore_impl.DatastoreImpl(httpClient, project);
    return datastore_test.cleanupDB(datastore, null).then((_) {
      store = db.DatastoreDB(datastore);
    });
  });

  tearDownAll(() {
    client?.close();
  });

  runTests(store, null);
}
