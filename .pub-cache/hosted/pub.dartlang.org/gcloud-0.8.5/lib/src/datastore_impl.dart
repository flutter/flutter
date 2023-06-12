// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library gcloud.datastore_impl;

import 'dart:async';

import 'package:googleapis/datastore/v1.dart' as api;
import 'package:http/http.dart' as http;

import '../common.dart' show Page;
import '../datastore.dart' as datastore;
import 'common_utils.dart';

class TransactionImpl implements datastore.Transaction {
  final String data;

  TransactionImpl(this.data);
}

class DatastoreImpl implements datastore.Datastore {
  static const List<String> scopes = <String>[
    api.DatastoreApi.datastoreScope,
    api.DatastoreApi.cloudPlatformScope,
  ];

  final api.DatastoreApi _api;
  final String _project;

  /// The [project] parameter is the name of the cloud project (it should not
  /// start with a `s~`).
  DatastoreImpl(http.Client client, String project)
      : _api = api.DatastoreApi(client),
        _project = project;

  api.Key _convertDatastore2ApiKey(datastore.Key key, {bool enforceId = true}) {
    var apiKey = api.Key();

    apiKey.partitionId = api.PartitionId()
      ..projectId = _project
      ..namespaceId = key.partition.namespace;

    apiKey.path = key.elements.map((datastore.KeyElement element) {
      final part = api.PathElement();
      part.kind = element.kind;
      final id = element.id;
      if (id is int) {
        part.id = '$id';
      } else if (id is String) {
        part.name = id;
      } else if (enforceId) {
        throw datastore.ApplicationError(
            'Error while encoding entity key: Using `null` as the id is not '
            'allowed.');
      }
      return part;
    }).toList();

    return apiKey;
  }

  static datastore.Key _convertApi2DatastoreKey(api.Key key) {
    var elements = key.path!.map((api.PathElement element) {
      if (element.id != null) {
        return datastore.KeyElement(element.kind!, int.parse(element.id!));
      } else if (element.name != null) {
        return datastore.KeyElement(element.kind!, element.name);
      } else {
        throw datastore.DatastoreError(
            'Invalid server response: Expected allocated name/id.');
      }
    }).toList();

    var partition = datastore.Partition.DEFAULT;
    if (key.partitionId != null) {
      partition = datastore.Partition(key.partitionId!.namespaceId);
      // TODO: assert projectId.
    }
    return datastore.Key(elements, partition: partition);
  }

  bool _compareApiKey(api.Key a, api.Key b) {
    if (a.path!.length != b.path!.length) return false;

    // FIXME(Issue #2): Is this comparison working correctly?
    if (a.partitionId != null) {
      if (b.partitionId == null) {
        return false;
      }
      if (a.partitionId!.projectId != b.partitionId!.projectId) {
        return false;
      }
      if (a.partitionId!.namespaceId != b.partitionId!.namespaceId) {
        return false;
      }
    } else if (b.partitionId != null) {
      return false;
    }

    for (var i = 0; i < a.path!.length; i++) {
      if (a.path![i].id != b.path![i].id ||
          a.path![i].name != b.path![i].name ||
          a.path![i].kind != b.path![i].kind) return false;
    }
    return true;
  }

  api.Value _convertDatastore2ApiPropertyValue(value, bool indexed,
      {bool lists = true}) {
    var apiValue = api.Value()..excludeFromIndexes = !indexed;
    if (value == null) {
      return apiValue..nullValue = 'NULL_VALUE';
    } else if (value is bool) {
      return apiValue..booleanValue = value;
    } else if (value is int) {
      return apiValue..integerValue = '$value';
    } else if (value is double) {
      return apiValue..doubleValue = value;
    } else if (value is String) {
      return apiValue..stringValue = value;
    } else if (value is DateTime) {
      return apiValue..timestampValue = value.toIso8601String();
    } else if (value is datastore.BlobValue) {
      return apiValue..blobValueAsBytes = value.bytes;
    } else if (value is datastore.Key) {
      return apiValue
        ..keyValue = _convertDatastore2ApiKey(value, enforceId: false);
    } else if (value is List) {
      if (!lists) {
        // FIXME(Issue #3): Consistently handle exceptions.
        throw Exception('List values are not allowed.');
      }

      api.Value convertItem(i) =>
          _convertDatastore2ApiPropertyValue(i, indexed, lists: false);

      return api.Value()
        ..arrayValue =
            (api.ArrayValue()..values = value.map(convertItem).toList());
    } else {
      throw UnsupportedError(
          'Types ${value.runtimeType} cannot be used for serializing.');
    }
  }

  static dynamic _convertApi2DatastoreProperty(api.Value value) {
    if (value.booleanValue != null) {
      return value.booleanValue;
    } else if (value.integerValue != null) {
      return int.parse(value.integerValue!);
    } else if (value.doubleValue != null) {
      return value.doubleValue;
    } else if (value.stringValue != null) {
      return value.stringValue;
    } else if (value.timestampValue != null) {
      return DateTime.parse(value.timestampValue!);
    } else if (value.blobValue != null) {
      return datastore.BlobValue(value.blobValueAsBytes);
    } else if (value.keyValue != null) {
      return _convertApi2DatastoreKey(value.keyValue!);
    } else if (value.arrayValue != null && value.arrayValue!.values != null) {
      return value.arrayValue!.values!
          .map(_convertApi2DatastoreProperty)
          .toList();
    } else if (value.entityValue != null) {
      throw UnsupportedError('Entity values are not supported.');
    } else if (value.geoPointValue != null) {
      throw UnsupportedError('GeoPoint values are not supported.');
    }
    return null;
  }

  static datastore.Entity _convertApi2DatastoreEntity(api.Entity entity) {
    var unindexedProperties = <String>{};
    var properties = <String, Object?>{};

    if (entity.properties != null) {
      entity.properties!.forEach((String name, api.Value value) {
        properties[name] = _convertApi2DatastoreProperty(value);
        if (value.excludeFromIndexes != null && value.excludeFromIndexes!) {
          unindexedProperties.add(name);
        }
      });
    }
    return datastore.Entity(_convertApi2DatastoreKey(entity.key!), properties,
        unIndexedProperties: unindexedProperties);
  }

  api.Entity _convertDatastore2ApiEntity(datastore.Entity entity,
      {bool enforceId = false}) {
    var apiEntity = api.Entity();

    apiEntity.key = _convertDatastore2ApiKey(entity.key, enforceId: enforceId);
    final properties = apiEntity.properties = {};
    if (entity.properties.isNotEmpty) {
      for (var key in entity.properties.keys) {
        var value = entity.properties[key];
        final indexed = !entity.unIndexedProperties.contains(key);
        properties[key] = _convertDatastore2ApiPropertyValue(value, indexed);
      }
    }
    return apiEntity;
  }

  static Map<datastore.FilterRelation, String> relationMapping = const {
    datastore.FilterRelation.LessThan: 'LESS_THAN',
    datastore.FilterRelation.LessThanOrEqual: 'LESS_THAN_OR_EQUAL',
    datastore.FilterRelation.Equal: 'EQUAL',
    datastore.FilterRelation.GreatherThan: 'GREATER_THAN',
    datastore.FilterRelation.GreatherThanOrEqual: 'GREATER_THAN_OR_EQUAL',
  };

  api.Filter _convertDatastore2ApiFilter(datastore.Filter filter) {
    var pf = api.PropertyFilter();
    var operator = relationMapping[filter.relation];
    if (operator == null) {
      throw ArgumentError('Unknown filter relation: ${filter.relation}.');
    }
    pf.op = operator;
    pf.property = api.PropertyReference()..name = filter.name;
    pf.value =
        _convertDatastore2ApiPropertyValue(filter.value, true, lists: false);
    return api.Filter()..propertyFilter = pf;
  }

  api.Filter _convertDatastoreAncestorKey2ApiFilter(datastore.Key key) {
    var pf = api.PropertyFilter();
    pf.op = 'HAS_ANCESTOR';
    pf.property = api.PropertyReference()..name = '__key__';
    pf.value = api.Value()
      ..keyValue = _convertDatastore2ApiKey(key, enforceId: true);
    return api.Filter()..propertyFilter = pf;
  }

  api.Filter? _convertDatastore2ApiFilters(
    List<datastore.Filter>? filters,
    datastore.Key? ancestorKey,
  ) {
    if ((filters == null || filters.isEmpty) && ancestorKey == null) {
      return null;
    }

    var compFilter = api.CompositeFilter();
    if (filters != null) {
      compFilter.filters = filters.map(_convertDatastore2ApiFilter).toList();
    }
    if (ancestorKey != null) {
      var filter = _convertDatastoreAncestorKey2ApiFilter(ancestorKey);
      if (compFilter.filters == null) {
        compFilter.filters = [filter];
      } else {
        compFilter.filters!.add(filter);
      }
    }
    compFilter.op = 'AND';
    return api.Filter()..compositeFilter = compFilter;
  }

  api.PropertyOrder _convertDatastore2ApiOrder(datastore.Order order) {
    var property = api.PropertyReference()..name = order.propertyName;
    var direction = order.direction == datastore.OrderDirection.Ascending
        ? 'ASCENDING'
        : 'DESCENDING';
    return api.PropertyOrder()
      ..direction = direction
      ..property = property;
  }

  List<api.PropertyOrder>? _convertDatastore2ApiOrders(
      List<datastore.Order>? orders) {
    if (orders == null) return null;

    return orders.map(_convertDatastore2ApiOrder).toList();
  }

  static Future<Never> _handleError(Object error, StackTrace stack) {
    if (error is api.DetailedApiRequestError) {
      if (error.status == 400) {
        return Future.error(
          datastore.ApplicationError(
            error.message ?? 'An unknown error occured',
          ),
          stack,
        );
      } else if (error.status == 409) {
        // NOTE: This is reported as:
        // "too much contention on these datastore entities"
        // TODO:
        return Future.error(datastore.TransactionAbortedError(), stack);
      } else if (error.status == 412) {
        return Future.error(datastore.NeedIndexError(), stack);
      }
    }
    return Future.error(error, stack);
  }

  @override
  Future<List<datastore.Key>> allocateIds(List<datastore.Key> keys) {
    var request = api.AllocateIdsRequest();
    request.keys = keys.map((key) {
      return _convertDatastore2ApiKey(key, enforceId: false);
    }).toList();
    return _api.projects.allocateIds(request, _project).then((response) {
      return (response.keys ?? []).map(_convertApi2DatastoreKey).toList();
    }, onError: _handleError);
  }

  @override
  Future<datastore.Transaction> beginTransaction(
      {bool crossEntityGroup = false}) {
    var request = api.BeginTransactionRequest();
    return _api.projects.beginTransaction(request, _project).then((result) {
      return TransactionImpl(result.transaction!);
    }, onError: _handleError);
  }

  @override
  Future<datastore.CommitResult> commit({
    List<datastore.Entity> inserts = const [],
    List<datastore.Entity> autoIdInserts = const [],
    List<datastore.Key> deletes = const [],
    datastore.Transaction? transaction,
  }) {
    final request = api.CommitRequest();

    if (transaction != null) {
      request.mode = 'TRANSACTIONAL';
      request.transaction = (transaction as TransactionImpl).data;
    } else {
      request.mode = 'NON_TRANSACTIONAL';
    }

    var mutations = request.mutations = <api.Mutation>[];
    if (inserts.isNotEmpty) {
      for (var i = 0; i < inserts.length; i++) {
        mutations.add(api.Mutation()
          ..upsert = _convertDatastore2ApiEntity(inserts[i], enforceId: true));
      }
    }
    var autoIdStartIndex = -1;
    if (autoIdInserts.isNotEmpty) {
      autoIdStartIndex = mutations.length;
      for (var i = 0; i < autoIdInserts.length; i++) {
        mutations.add(api.Mutation()
          ..insert =
              _convertDatastore2ApiEntity(autoIdInserts[i], enforceId: false));
      }
    }
    if (deletes.isNotEmpty) {
      for (var i = 0; i < deletes.length; i++) {
        mutations.add(api.Mutation()
          ..delete = _convertDatastore2ApiKey(deletes[i], enforceId: true));
      }
    }
    return _api.projects.commit(request, _project).then((result) {
      var keys = <datastore.Key>[];
      if (autoIdInserts.isNotEmpty) {
        assert(result.mutationResults != null);
        var mutationResults = result.mutationResults!;
        assert(autoIdStartIndex != -1);
        assert(mutationResults.length >=
            (autoIdStartIndex + autoIdInserts.length));
        keys = mutationResults
            .skip(autoIdStartIndex)
            .take(autoIdInserts.length)
            .map<datastore.Key>((r) => _convertApi2DatastoreKey(r.key!))
            .toList();
      }
      return datastore.CommitResult(keys);
    }, onError: _handleError);
  }

  @override
  Future<List<datastore.Entity?>> lookup(
    List<datastore.Key> keys, {
    datastore.Transaction? transaction,
  }) {
    var apiKeys = keys.map((key) {
      return _convertDatastore2ApiKey(key, enforceId: true);
    }).toList();
    var request = api.LookupRequest();
    request.keys = apiKeys;
    if (transaction != null) {
      // TODO: Make readOptions more configurable.
      request.readOptions = api.ReadOptions()
        ..transaction = (transaction as TransactionImpl).data;
    }
    return _api.projects.lookup(request, _project).then((response) {
      if (response.deferred != null && response.deferred!.isNotEmpty) {
        throw datastore.DatastoreError(
            'Could not successfully look up all keys due to resource '
            'constraints.');
      }

      // NOTE: This is worst-case O(n^2)!
      // Maybe we can optimize this somehow. But the API says:
      //  message LookupResponse {
      //    // The order of results in these fields is undefined and has no relation to
      //    // the order of the keys in the input.
      //
      //    // Entities found as ResultType.FULL entities.
      //    repeated EntityResult found = 1;
      //
      //    // Entities not found as ResultType.KEY_ONLY entities.
      //    repeated EntityResult missing = 2;
      //
      //    // A list of keys that were not looked up due to resource constraints.
      //    repeated Key deferred = 3;
      //  }
      var entities = List<datastore.Entity?>.filled(apiKeys.length, null);
      for (var i = 0; i < apiKeys.length; i++) {
        var apiKey = apiKeys[i];

        var found = false;

        if (response.found != null) {
          for (var result in response.found!) {
            if (_compareApiKey(apiKey, result.entity!.key!)) {
              entities[i] = _convertApi2DatastoreEntity(result.entity!);
              found = true;
              break;
            }
          }
        }

        if (found) continue;

        if (response.missing != null) {
          for (var result in response.missing!) {
            if (_compareApiKey(apiKey, result.entity!.key!)) {
              entities[i] = null;
              found = true;
              break;
            }
          }
        }

        if (!found) {
          throw datastore.DatastoreError('Invalid server response: '
              'Tried to lookup ${apiKey.toJson()} but entity was neither in '
              'missing nor in found.');
        }
      }
      return entities;
    }, onError: _handleError);
  }

  @override
  Future<Page<datastore.Entity>> query(
    datastore.Query query, {
    datastore.Partition partition = datastore.Partition.DEFAULT,
    datastore.Transaction? transaction,
  }) {
    // NOTE: We explicitly do not set 'limit' here, since this is handled by
    // QueryPageImpl.runQuery.
    var apiQuery = api.Query()
      ..filter = _convertDatastore2ApiFilters(query.filters, query.ancestorKey)
      ..order = _convertDatastore2ApiOrders(query.orders)
      ..offset = query.offset;

    if (query.kind != null) {
      apiQuery.kind = [api.KindExpression()..name = query.kind];
    }

    var request = api.RunQueryRequest();
    request.query = apiQuery;
    if (transaction != null) {
      // TODO: Make readOptions more configurable.
      request.readOptions = api.ReadOptions()
        ..transaction = (transaction as TransactionImpl).data;
    }
    if (partition != datastore.Partition.DEFAULT) {
      request.partitionId = api.PartitionId()
        ..namespaceId = partition.namespace;
    }

    return QueryPageImpl.runQuery(_api, _project, request, query.limit)
        .catchError(_handleError);
  }

  @override
  Future rollback(datastore.Transaction transaction) {
    // TODO: Handle [transaction]
    var request = api.RollbackRequest()
      ..transaction = (transaction as TransactionImpl).data;
    return _api.projects.rollback(request, _project).catchError(_handleError);
  }
}

class QueryPageImpl implements Page<datastore.Entity> {
  static const int _maxEntitiesPerResponse = 2000;

  final api.DatastoreApi _api;
  final String _project;
  final api.RunQueryRequest _nextRequest;
  final List<datastore.Entity> _entities;
  final bool _isLast;

  // This might be `null` in which case we request as many as we can get.
  final int? _remainingNumberOfEntities;

  QueryPageImpl(this._api, this._project, this._nextRequest, this._entities,
      this._isLast, this._remainingNumberOfEntities);

  static Future<QueryPageImpl> runQuery(api.DatastoreApi api, String project,
      api.RunQueryRequest request, int? limit,
      {int batchSize = _maxEntitiesPerResponse}) {
    if (limit != null && limit < batchSize) {
      batchSize = limit;
    }

    request.query!.limit = batchSize;

    return api.projects.runQuery(request, project).then((response) {
      var returnedEntities = const <datastore.Entity>[];

      final batch = response.batch!;
      if (batch.entityResults != null) {
        returnedEntities = batch.entityResults!
            .map((result) => result.entity!)
            .map(DatastoreImpl._convertApi2DatastoreEntity)
            .toList();
      }

      // This check is only necessary for the first request/response pair
      // (if offset was supplied).
      if (request.query!.offset != null &&
          request.query!.offset! > 0 &&
          request.query!.offset != batch.skippedResults) {
        throw datastore.DatastoreError(
            'Server did not skip over the specified ${request.query!.offset} '
            'entities.');
      }

      if (limit != null && returnedEntities.length > limit) {
        throw datastore.DatastoreError(
            'Server returned more entities then the limit for the request'
            '(${request.query!.limit}) was.');
      }

      // FIXME: TODO: Big hack!
      // It looks like Apiary/Atlas is currently broken.
      /*
      if (limit != null &&
          returnedEntities.length < batchSize &&
          response.batch.moreResults == 'MORE_RESULTS_AFTER_LIMIT') {
        throw new datastore.DatastoreError(
            'Server returned response with less entities then the limit was, '
            'but signals there are more results after the limit.');
      }
      */

      // In case a limit was specified, we need to subtraction the number of
      // entities we already got.
      // (the checks above guarantee that this subtraction is >= 0).
      int? remainingEntities;
      if (limit != null) {
        remainingEntities = limit - returnedEntities.length;
      }

      // If the server signals there are more entities and we either have no
      // limit or our limit has not been reached, we set `moreBatches` to
      // `true`.
      var moreBatches = (remainingEntities == null || remainingEntities > 0) &&
          batch.moreResults == 'MORE_RESULTS_AFTER_LIMIT';

      var gotAll = limit != null && remainingEntities == 0;
      var noMore = batch.moreResults == 'NO_MORE_RESULTS';
      var isLast = gotAll || noMore;

      // As a sanity check, we assert that `moreBatches XOR isLast`.
      assert(isLast != moreBatches);

      // FIXME: TODO: Big hack!
      // It looks like Apiary/Atlas is currently broken.
      if (moreBatches && returnedEntities.isEmpty) {
        print('Warning: Api to Google Cloud Datastore returned bogus response. '
            'Trying a workaround.');
        isLast = true;
        moreBatches = false;
      }

      if (!isLast && batch.endCursor == null) {
        throw datastore.DatastoreError(
            'Server did not supply an end cursor, even though the query '
            'is not done.');
      }

      if (isLast) {
        return QueryPageImpl(
            api, project, request, returnedEntities, true, null);
      } else {
        // NOTE: We reuse the old RunQueryRequest object here .

        // The offset will be 0 from now on, since the first request will have
        // skipped over the first `offset` results.
        request.query!.offset = 0;

        // Furthermore we set the startCursor to the endCursor of the previous
        // result batch, so we can continue where we left off.
        request.query!.startCursor = batch.endCursor;

        return QueryPageImpl(
            api, project, request, returnedEntities, false, remainingEntities);
      }
    });
  }

  @override
  bool get isLast => _isLast;

  @override
  List<datastore.Entity> get items => _entities;

  @override
  Future<Page<datastore.Entity>> next({int? pageSize}) async {
    // NOTE: We do not respect [pageSize] here, the only mechanism we can
    // really use is `query.limit`, but this is user-specified when making
    // the query.
    throwIfIsLast();

    return QueryPageImpl.runQuery(
            _api, _project, _nextRequest, _remainingNumberOfEntities)
        .catchError(DatastoreImpl._handleError);
  }
}
