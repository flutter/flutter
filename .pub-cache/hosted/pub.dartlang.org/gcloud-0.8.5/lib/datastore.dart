// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library provides a low-level API for accessing Google's Cloud
/// Datastore.
///
/// For more information on Cloud Datastore, please refer to the following
/// developers page: https://cloud.google.com/datastore/docs
library gcloud.datastore;

import 'dart:async';

import 'package:http/http.dart' as http;

import 'common.dart' show Page;
import 'service_scope.dart' as ss;
import 'src/datastore_impl.dart' show DatastoreImpl;

const Symbol _datastoreKey = #gcloud.datastore;

/// Access the [Datastore] object available in the current service scope.
///
/// The returned object will be the one which was previously registered with
/// [registerDatastoreService] within the current (or a parent) service scope.
///
/// Accessing this getter outside of a service scope will result in an error.
/// See the `package:gcloud/service_scope.dart` library for more information.
Datastore get datastoreService => ss.lookup(_datastoreKey) as Datastore;

/// Registers the [Datastore] object within the current service scope.
///
/// The provided `datastore` object will be available via the top-level
/// `datastore` getter.
///
/// Calling this function outside of a service scope will result in an error.
/// Calling this function more than once inside the same service scope is not
/// allowed.
void registerDatastoreService(Datastore datastore) {
  ss.register(_datastoreKey, datastore);
}

class ApplicationError implements Exception {
  final String message;
  ApplicationError(this.message);

  @override
  String toString() => 'ApplicationError: $message';
}

class DatastoreError implements Exception {
  final String message;

  DatastoreError([String? message])
      : message = (message ?? 'DatastoreError: An unknown error occured');

  @override
  String toString() => message;
}

class UnknownDatastoreError extends DatastoreError {
  UnknownDatastoreError(error) : super('An unknown error occured ($error).');
}

class TransactionAbortedError extends DatastoreError {
  TransactionAbortedError() : super('The transaction was aborted.');
}

class TimeoutError extends DatastoreError {
  TimeoutError() : super('The operation timed out.');
}

/// Thrown when a query would require an index which was not set.
///
/// An application needs to specify indices in a `index.yaml` file and needs to
/// create indices using the `gcloud preview datastore create-indexes` command.
class NeedIndexError extends DatastoreError {
  NeedIndexError() : super('An index is needed for the query to succeed.');
}

class PermissionDeniedError extends DatastoreError {
  PermissionDeniedError() : super('Permission denied.');
}

class InternalError extends DatastoreError {
  InternalError() : super('Internal service error.');
}

class QuotaExceededError extends DatastoreError {
  QuotaExceededError(error) : super('Quota was exceeded ($error).');
}

/// A datastore Entity
///
/// An entity is identified by a unique `key` and consists of a number of
/// `properties`. If a property should not be indexed, it needs to be included
/// in the `unIndexedProperties` set.
///
/// The `properties` field maps names to values. Values can be of a primitive
/// type or of a composed type.
///
/// The following primitive types are supported:
///   bool, int, double, String, DateTime, BlobValue, Key
///
/// It is possible to have a `List` of values. The values must be primitive.
/// Lists inside lists are not supported.
///
/// Whether a property is indexed or not applies to all values (this is only
/// relevant if the value is a list of primitive values).
class Entity {
  final Key key;
  final Map<String, Object?> properties;
  final Set<String> unIndexedProperties;

  Entity(this.key, this.properties,
      {this.unIndexedProperties = const <String>{}});
}

/// A complete or partial key.
///
/// A key can uniquely identify a datastore `Entity`s. It consists of a
/// partition and path. The path consists of one or more `KeyElement`s.
///
/// A key may be incomplete. This is usesful when inserting `Entity`s which IDs
/// should be automatically allocated.
///
/// Example of a fully populated [Key]:
///
///     var fullKey = new Key([new KeyElement('Person', 1),
///                            new KeyElement('Address', 2)]);
///
/// Example of a partially populated [Key] / an incomplete [Key]:
///
///     var partialKey = new Key([new KeyElement('Person', 1),
///                               new KeyElement('Address', null)]);
class Key {
  /// The partition of this `Key`.
  final Partition partition;

  /// The path of `KeyElement`s.
  final List<KeyElement> elements;

  Key(this.elements, {this.partition = Partition.DEFAULT});

  factory Key.fromParent(String kind, int id, {Key? parent}) {
    var partition = Partition.DEFAULT;
    var elements = <KeyElement>[];
    if (parent != null) {
      partition = parent.partition;
      elements.addAll(parent.elements);
    }
    elements.add(KeyElement(kind, id));
    return Key(elements, partition: partition);
  }

  @override
  int get hashCode =>
      elements.fold(partition.hashCode, (a, b) => a ^ b.hashCode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is Key &&
        partition == other.partition &&
        elements.length == other.elements.length) {
      for (var i = 0; i < elements.length; i++) {
        if (elements[i] != other.elements[i]) return false;
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    var namespaceString =
        partition.namespace == null ? 'null' : "'${partition.namespace}'";
    return "Key(namespace=$namespaceString, path=[${elements.join(', ')}])";
  }
}

/// A datastore partition.
///
/// A partition is used for partitioning a dataset into multiple namespaces.
/// The default namespace is `null`. Using empty Strings as namespaces is
/// invalid.
///
// TODO(Issue #6): Add dataset-id here.
class Partition {
  // ignore: constant_identifier_names
  static const Partition DEFAULT = Partition._default();

  /// The namespace of this partition.
  ///
  /// The default namespace is `null`.
  final String? namespace;

  Partition(this.namespace) {
    if (namespace == '') {
      throw ArgumentError("'namespace' must not be empty");
    }
  }

  const Partition._default() : namespace = null;

  @override
  int get hashCode => namespace.hashCode;

  @override
  bool operator ==(Object other) =>
      other is Partition && namespace == other.namespace;
}

/// An element in a `Key`s path.
class KeyElement {
  /// The kind of this element.
  final String kind;

  /// The ID of this element. It must be either an `int` or a `String.
  ///
  /// This may be `null`, in which case it does not identify an Entity. It is
  /// possible to insert [Entity]s with incomplete keys and let Datastore
  /// automatically select a unused integer ID.
  final dynamic id;

  KeyElement(this.kind, this.id) {
    if (id != null) {
      if (id is! int && id is! String) {
        throw ArgumentError("'id' must be either null, a String or an int");
      }
    }
  }

  @override
  int get hashCode => kind.hashCode ^ id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is KeyElement && kind == other.kind && id == other.id;

  @override
  String toString() => '$kind.$id';
}

/// A relation used in query filters.
class FilterRelation {
  // ignore: constant_identifier_names
  static const FilterRelation LessThan = FilterRelation._('<');
  // ignore: constant_identifier_names
  static const FilterRelation LessThanOrEqual = FilterRelation._('<=');
  // ignore: constant_identifier_names
  static const FilterRelation GreatherThan = FilterRelation._('>');
  // ignore: constant_identifier_names
  static const FilterRelation GreatherThanOrEqual = FilterRelation._('>=');
  // ignore: constant_identifier_names
  static const FilterRelation Equal = FilterRelation._('==');

  final String name;

  const FilterRelation._(this.name);

  @override
  String toString() => name;
}

/// A filter used in queries.
class Filter {
  /// The relation used for comparing `name` with `value`.
  final FilterRelation relation;

  /// The name of the datastore property used in the comparison.
  final String name;

  /// The value used for comparing against the property named by `name`.
  final Object value;

  Filter(this.relation, this.name, this.value);
}

/// The direction of a order.
///
// TODO(Issue #6): Make this class Private and add the two statics to the
/// 'Order' class.
/// [i.e. so one can write Order.Ascending, Order.Descending].
class OrderDirection {
  // ignore: constant_identifier_names
  static const OrderDirection Ascending = OrderDirection._('Ascending');
  // ignore: constant_identifier_names
  static const OrderDirection Decending = OrderDirection._('Decending');

  final String name;

  const OrderDirection._(this.name);
}

/// A order used in queries.
class Order {
  /// The direction of the order.
  final OrderDirection direction;

  /// The name of the property used for the order.
  final String propertyName;

  // TODO(Issue #6): Make [direction] the second argument and make it optional.
  Order(this.direction, this.propertyName);
}

/// A datastore query.
///
/// A query consists of filters (kind, ancestor and property filters), one or
/// more orders and a offset/limit pair.
///
/// All fields may be optional.
///
/// Example of building a [Query]:
///     var person = ....;
///     var query = new Query(ancestorKey: personKey, kind: 'Address')
class Query {
  /// Restrict the result set to entities of this kind.
  final String? kind;

  /// Restrict the result set to entities which have this  ancestorKey / parent.
  final Key? ancestorKey;

  /// Restrict the result set by a list of property [Filter]s.
  final List<Filter>? filters;

  /// Order the matching entities following the given property [Order]s.
  final List<Order>? orders;

  /// Skip the first [offset] entities in the result set.
  final int? offset;

  /// Limit the number of entities returned to [limit].
  final int? limit;

  Query({
    this.ancestorKey,
    this.kind,
    this.filters,
    this.orders,
    this.offset,
    this.limit,
  });
}

/// The result of a commit.
class CommitResult {
  /// If the commit included `autoIdInserts`, this list will be the fully
  /// populated Keys, including the automatically allocated integer IDs.
  final List<Key> autoIdInsertKeys;

  CommitResult(this.autoIdInsertKeys);
}

/// A blob value which can be used as a property value in `Entity`s.
class BlobValue {
  /// The binary data of this blob.
  final List<int> bytes;

  BlobValue(this.bytes);
}

/// An opaque token returned by the `beginTransaction` method of a [Datastore].
///
/// This token can be passed to the `commit` and `lookup` calls if they should
/// operate within this transaction.
abstract class Transaction {}

/// Interface used to talk to the Google Cloud Datastore service.
///
/// It can be used to insert/update/delete [Entity]s, lookup/query [Entity]s
/// and allocate IDs from the auto ID allocation policy.
abstract class Datastore {
  /// List of required OAuth2 scopes for Datastore operation.
  // ignore: constant_identifier_names
  static const Scopes = DatastoreImpl.scopes;

  /// Access Datastore using an authenticated client.
  ///
  /// The [client] is an authenticated HTTP client. This client must
  /// provide access to at least the scopes in `Datastore.Scopes`.
  ///
  /// The [project] is the name of the Google Cloud project.
  ///
  /// Returs an object providing access to Datastore. The passed-in [client]
  /// will not be closed automatically. The caller is responsible for closing
  /// it.
  factory Datastore(http.Client client, String project) {
    return DatastoreImpl(client, project);
  }

  /// Allocate integer IDs for the partially populated [keys] given as argument.
  ///
  /// The returned [Key]s will be fully populated with the allocated IDs.
  Future<List<Key>> allocateIds(List<Key> keys);

  /// Starts a new transaction and returns an opaque value representing it.
  ///
  /// If [crossEntityGroup] is `true`, the transaction can work on up to 5
  /// entity groups. Otherwise the transaction will be limited to only operate
  /// on a single entity group.
  Future<Transaction> beginTransaction({bool crossEntityGroup = false});

  /// Make modifications to the datastore.
  ///
  ///  - `inserts` are [Entity]s which have a fully populated [Key] and should
  ///    be either added to the datastore or updated.
  ///
  ///  - `autoIdInserts` are [Entity]s which do not have a fully populated [Key]
  ///    and should be added to the dataset, automatically assigning integer
  ///    IDs.
  ///    The returned [CommitResult] will contain the fully populated keys.
  ///
  ///  - `deletes` are a list of fully populated [Key]s which uniquely identify
  ///    the [Entity]s which should be deleted.
  ///
  /// If a [transaction] is given, all modifications will be done within that
  /// transaction.
  ///
  /// This method might complete with a [TransactionAbortedError] error.
  /// Users must take care of retrying transactions.
  // TODO(Issue #6): Consider splitting `inserts` into insert/update/upsert.
  Future<CommitResult> commit(
      {List<Entity> inserts,
      List<Entity> autoIdInserts,
      List<Key> deletes,
      Transaction transaction});

  /// Roll a started transaction back.
  Future rollback(Transaction transaction);

  /// Looks up the fully populated [keys] in the datastore and returns either
  /// the [Entity] corresponding to the [Key] or `null`. The order in the
  /// returned [Entity]s is the same as in [keys].
  ///
  /// If a [transaction] is given, the lookup will be within this transaction.
  Future<List<Entity?>> lookup(List<Key> keys, {Transaction transaction});

  /// Runs a query on the dataset and returns a [Page] of matching [Entity]s.
  ///
  /// The [Page] instance returned might not contain all matching [Entity]s -
  /// in which case `isLast` is set to `false`. The page's `next` method can
  /// be used to page through the whole result set.
  /// The maximum number of [Entity]s returned within a single page is
  /// implementation specific.
  ///
  ///  - `query` is used to restrict the number of returned [Entity]s and may
  ///    may specify an order.
  ///
  ///  - `partition` can be used to specify the namespace used for the lookup.
  ///
  /// If a [transaction] is given, the query will be within this transaction.
  /// But note that arbitrary queries within a transaction are not possible.
  /// A transaction is limited to a very small number of entity groups. Usually
  /// queries with transactions are restricted by providing an ancestor filter.
  ///
  /// Outside of transactions, the result set might be stale. Queries are by
  /// default eventually consistent.
  Future<Page<Entity>> query(Query query,
      {Partition partition, Transaction transaction});
}
