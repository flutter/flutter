// ignore_for_file: avoid_returning_null
// ignore_for_file: camel_case_types
// ignore_for_file: cascade_invocations
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unnecessary_string_interpolations
// ignore_for_file: unused_local_variable

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:googleapis/datastore/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Key> buildUnnamed0() {
  var o = <api.Key>[];
  o.add(buildKey());
  o.add(buildKey());
  return o;
}

void checkUnnamed0(core.List<api.Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKey(o[0] as api.Key);
  checkKey(o[1] as api.Key);
}

core.int buildCounterAllocateIdsRequest = 0;
api.AllocateIdsRequest buildAllocateIdsRequest() {
  var o = api.AllocateIdsRequest();
  buildCounterAllocateIdsRequest++;
  if (buildCounterAllocateIdsRequest < 3) {
    o.keys = buildUnnamed0();
  }
  buildCounterAllocateIdsRequest--;
  return o;
}

void checkAllocateIdsRequest(api.AllocateIdsRequest o) {
  buildCounterAllocateIdsRequest++;
  if (buildCounterAllocateIdsRequest < 3) {
    checkUnnamed0(o.keys!);
  }
  buildCounterAllocateIdsRequest--;
}

core.List<api.Key> buildUnnamed1() {
  var o = <api.Key>[];
  o.add(buildKey());
  o.add(buildKey());
  return o;
}

void checkUnnamed1(core.List<api.Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKey(o[0] as api.Key);
  checkKey(o[1] as api.Key);
}

core.int buildCounterAllocateIdsResponse = 0;
api.AllocateIdsResponse buildAllocateIdsResponse() {
  var o = api.AllocateIdsResponse();
  buildCounterAllocateIdsResponse++;
  if (buildCounterAllocateIdsResponse < 3) {
    o.keys = buildUnnamed1();
  }
  buildCounterAllocateIdsResponse--;
  return o;
}

void checkAllocateIdsResponse(api.AllocateIdsResponse o) {
  buildCounterAllocateIdsResponse++;
  if (buildCounterAllocateIdsResponse < 3) {
    checkUnnamed1(o.keys!);
  }
  buildCounterAllocateIdsResponse--;
}

core.List<api.Value> buildUnnamed2() {
  var o = <api.Value>[];
  o.add(buildValue());
  o.add(buildValue());
  return o;
}

void checkUnnamed2(core.List<api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o[0] as api.Value);
  checkValue(o[1] as api.Value);
}

core.int buildCounterArrayValue = 0;
api.ArrayValue buildArrayValue() {
  var o = api.ArrayValue();
  buildCounterArrayValue++;
  if (buildCounterArrayValue < 3) {
    o.values = buildUnnamed2();
  }
  buildCounterArrayValue--;
  return o;
}

void checkArrayValue(api.ArrayValue o) {
  buildCounterArrayValue++;
  if (buildCounterArrayValue < 3) {
    checkUnnamed2(o.values!);
  }
  buildCounterArrayValue--;
}

core.int buildCounterBeginTransactionRequest = 0;
api.BeginTransactionRequest buildBeginTransactionRequest() {
  var o = api.BeginTransactionRequest();
  buildCounterBeginTransactionRequest++;
  if (buildCounterBeginTransactionRequest < 3) {
    o.transactionOptions = buildTransactionOptions();
  }
  buildCounterBeginTransactionRequest--;
  return o;
}

void checkBeginTransactionRequest(api.BeginTransactionRequest o) {
  buildCounterBeginTransactionRequest++;
  if (buildCounterBeginTransactionRequest < 3) {
    checkTransactionOptions(o.transactionOptions! as api.TransactionOptions);
  }
  buildCounterBeginTransactionRequest--;
}

core.int buildCounterBeginTransactionResponse = 0;
api.BeginTransactionResponse buildBeginTransactionResponse() {
  var o = api.BeginTransactionResponse();
  buildCounterBeginTransactionResponse++;
  if (buildCounterBeginTransactionResponse < 3) {
    o.transaction = 'foo';
  }
  buildCounterBeginTransactionResponse--;
  return o;
}

void checkBeginTransactionResponse(api.BeginTransactionResponse o) {
  buildCounterBeginTransactionResponse++;
  if (buildCounterBeginTransactionResponse < 3) {
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterBeginTransactionResponse--;
}

core.List<api.Mutation> buildUnnamed3() {
  var o = <api.Mutation>[];
  o.add(buildMutation());
  o.add(buildMutation());
  return o;
}

void checkUnnamed3(core.List<api.Mutation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMutation(o[0] as api.Mutation);
  checkMutation(o[1] as api.Mutation);
}

core.int buildCounterCommitRequest = 0;
api.CommitRequest buildCommitRequest() {
  var o = api.CommitRequest();
  buildCounterCommitRequest++;
  if (buildCounterCommitRequest < 3) {
    o.mode = 'foo';
    o.mutations = buildUnnamed3();
    o.transaction = 'foo';
  }
  buildCounterCommitRequest--;
  return o;
}

void checkCommitRequest(api.CommitRequest o) {
  buildCounterCommitRequest++;
  if (buildCounterCommitRequest < 3) {
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
    checkUnnamed3(o.mutations!);
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommitRequest--;
}

core.List<api.MutationResult> buildUnnamed4() {
  var o = <api.MutationResult>[];
  o.add(buildMutationResult());
  o.add(buildMutationResult());
  return o;
}

void checkUnnamed4(core.List<api.MutationResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMutationResult(o[0] as api.MutationResult);
  checkMutationResult(o[1] as api.MutationResult);
}

core.int buildCounterCommitResponse = 0;
api.CommitResponse buildCommitResponse() {
  var o = api.CommitResponse();
  buildCounterCommitResponse++;
  if (buildCounterCommitResponse < 3) {
    o.indexUpdates = 42;
    o.mutationResults = buildUnnamed4();
  }
  buildCounterCommitResponse--;
  return o;
}

void checkCommitResponse(api.CommitResponse o) {
  buildCounterCommitResponse++;
  if (buildCounterCommitResponse < 3) {
    unittest.expect(
      o.indexUpdates!,
      unittest.equals(42),
    );
    checkUnnamed4(o.mutationResults!);
  }
  buildCounterCommitResponse--;
}

core.List<api.Filter> buildUnnamed5() {
  var o = <api.Filter>[];
  o.add(buildFilter());
  o.add(buildFilter());
  return o;
}

void checkUnnamed5(core.List<api.Filter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilter(o[0] as api.Filter);
  checkFilter(o[1] as api.Filter);
}

core.int buildCounterCompositeFilter = 0;
api.CompositeFilter buildCompositeFilter() {
  var o = api.CompositeFilter();
  buildCounterCompositeFilter++;
  if (buildCounterCompositeFilter < 3) {
    o.filters = buildUnnamed5();
    o.op = 'foo';
  }
  buildCounterCompositeFilter--;
  return o;
}

void checkCompositeFilter(api.CompositeFilter o) {
  buildCounterCompositeFilter++;
  if (buildCounterCompositeFilter < 3) {
    checkUnnamed5(o.filters!);
    unittest.expect(
      o.op!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompositeFilter--;
}

core.int buildCounterEmpty = 0;
api.Empty buildEmpty() {
  var o = api.Empty();
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
  return o;
}

void checkEmpty(api.Empty o) {
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
}

core.Map<core.String, api.Value> buildUnnamed6() {
  var o = <core.String, api.Value>{};
  o['x'] = buildValue();
  o['y'] = buildValue();
  return o;
}

void checkUnnamed6(core.Map<core.String, api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o['x']! as api.Value);
  checkValue(o['y']! as api.Value);
}

core.int buildCounterEntity = 0;
api.Entity buildEntity() {
  var o = api.Entity();
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    o.key = buildKey();
    o.properties = buildUnnamed6();
  }
  buildCounterEntity--;
  return o;
}

void checkEntity(api.Entity o) {
  buildCounterEntity++;
  if (buildCounterEntity < 3) {
    checkKey(o.key! as api.Key);
    checkUnnamed6(o.properties!);
  }
  buildCounterEntity--;
}

core.int buildCounterEntityResult = 0;
api.EntityResult buildEntityResult() {
  var o = api.EntityResult();
  buildCounterEntityResult++;
  if (buildCounterEntityResult < 3) {
    o.cursor = 'foo';
    o.entity = buildEntity();
    o.version = 'foo';
  }
  buildCounterEntityResult--;
  return o;
}

void checkEntityResult(api.EntityResult o) {
  buildCounterEntityResult++;
  if (buildCounterEntityResult < 3) {
    unittest.expect(
      o.cursor!,
      unittest.equals('foo'),
    );
    checkEntity(o.entity! as api.Entity);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntityResult--;
}

core.int buildCounterFilter = 0;
api.Filter buildFilter() {
  var o = api.Filter();
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    o.compositeFilter = buildCompositeFilter();
    o.propertyFilter = buildPropertyFilter();
  }
  buildCounterFilter--;
  return o;
}

void checkFilter(api.Filter o) {
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    checkCompositeFilter(o.compositeFilter! as api.CompositeFilter);
    checkPropertyFilter(o.propertyFilter! as api.PropertyFilter);
  }
  buildCounterFilter--;
}

core.Map<core.String, core.String> buildUnnamed7() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed7(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleDatastoreAdminV1CommonMetadata = 0;
api.GoogleDatastoreAdminV1CommonMetadata
    buildGoogleDatastoreAdminV1CommonMetadata() {
  var o = api.GoogleDatastoreAdminV1CommonMetadata();
  buildCounterGoogleDatastoreAdminV1CommonMetadata++;
  if (buildCounterGoogleDatastoreAdminV1CommonMetadata < 3) {
    o.endTime = 'foo';
    o.labels = buildUnnamed7();
    o.operationType = 'foo';
    o.startTime = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1CommonMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1CommonMetadata(
    api.GoogleDatastoreAdminV1CommonMetadata o) {
  buildCounterGoogleDatastoreAdminV1CommonMetadata++;
  if (buildCounterGoogleDatastoreAdminV1CommonMetadata < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkUnnamed7(o.labels!);
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1CommonMetadata--;
}

core.List<core.String> buildUnnamed8() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed8(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed9() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed9(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleDatastoreAdminV1EntityFilter = 0;
api.GoogleDatastoreAdminV1EntityFilter
    buildGoogleDatastoreAdminV1EntityFilter() {
  var o = api.GoogleDatastoreAdminV1EntityFilter();
  buildCounterGoogleDatastoreAdminV1EntityFilter++;
  if (buildCounterGoogleDatastoreAdminV1EntityFilter < 3) {
    o.kinds = buildUnnamed8();
    o.namespaceIds = buildUnnamed9();
  }
  buildCounterGoogleDatastoreAdminV1EntityFilter--;
  return o;
}

void checkGoogleDatastoreAdminV1EntityFilter(
    api.GoogleDatastoreAdminV1EntityFilter o) {
  buildCounterGoogleDatastoreAdminV1EntityFilter++;
  if (buildCounterGoogleDatastoreAdminV1EntityFilter < 3) {
    checkUnnamed8(o.kinds!);
    checkUnnamed9(o.namespaceIds!);
  }
  buildCounterGoogleDatastoreAdminV1EntityFilter--;
}

core.int buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata = 0;
api.GoogleDatastoreAdminV1ExportEntitiesMetadata
    buildGoogleDatastoreAdminV1ExportEntitiesMetadata() {
  var o = api.GoogleDatastoreAdminV1ExportEntitiesMetadata();
  buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata < 3) {
    o.common = buildGoogleDatastoreAdminV1CommonMetadata();
    o.entityFilter = buildGoogleDatastoreAdminV1EntityFilter();
    o.outputUrlPrefix = 'foo';
    o.progressBytes = buildGoogleDatastoreAdminV1Progress();
    o.progressEntities = buildGoogleDatastoreAdminV1Progress();
  }
  buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1ExportEntitiesMetadata(
    api.GoogleDatastoreAdminV1ExportEntitiesMetadata o) {
  buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata < 3) {
    checkGoogleDatastoreAdminV1CommonMetadata(
        o.common! as api.GoogleDatastoreAdminV1CommonMetadata);
    checkGoogleDatastoreAdminV1EntityFilter(
        o.entityFilter! as api.GoogleDatastoreAdminV1EntityFilter);
    unittest.expect(
      o.outputUrlPrefix!,
      unittest.equals('foo'),
    );
    checkGoogleDatastoreAdminV1Progress(
        o.progressBytes! as api.GoogleDatastoreAdminV1Progress);
    checkGoogleDatastoreAdminV1Progress(
        o.progressEntities! as api.GoogleDatastoreAdminV1Progress);
  }
  buildCounterGoogleDatastoreAdminV1ExportEntitiesMetadata--;
}

core.Map<core.String, core.String> buildUnnamed10() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed10(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest = 0;
api.GoogleDatastoreAdminV1ExportEntitiesRequest
    buildGoogleDatastoreAdminV1ExportEntitiesRequest() {
  var o = api.GoogleDatastoreAdminV1ExportEntitiesRequest();
  buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest++;
  if (buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest < 3) {
    o.entityFilter = buildGoogleDatastoreAdminV1EntityFilter();
    o.labels = buildUnnamed10();
    o.outputUrlPrefix = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest--;
  return o;
}

void checkGoogleDatastoreAdminV1ExportEntitiesRequest(
    api.GoogleDatastoreAdminV1ExportEntitiesRequest o) {
  buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest++;
  if (buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest < 3) {
    checkGoogleDatastoreAdminV1EntityFilter(
        o.entityFilter! as api.GoogleDatastoreAdminV1EntityFilter);
    checkUnnamed10(o.labels!);
    unittest.expect(
      o.outputUrlPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1ExportEntitiesRequest--;
}

core.int buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse = 0;
api.GoogleDatastoreAdminV1ExportEntitiesResponse
    buildGoogleDatastoreAdminV1ExportEntitiesResponse() {
  var o = api.GoogleDatastoreAdminV1ExportEntitiesResponse();
  buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse++;
  if (buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse < 3) {
    o.outputUrl = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse--;
  return o;
}

void checkGoogleDatastoreAdminV1ExportEntitiesResponse(
    api.GoogleDatastoreAdminV1ExportEntitiesResponse o) {
  buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse++;
  if (buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse < 3) {
    unittest.expect(
      o.outputUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1ExportEntitiesResponse--;
}

core.int buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata = 0;
api.GoogleDatastoreAdminV1ImportEntitiesMetadata
    buildGoogleDatastoreAdminV1ImportEntitiesMetadata() {
  var o = api.GoogleDatastoreAdminV1ImportEntitiesMetadata();
  buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata < 3) {
    o.common = buildGoogleDatastoreAdminV1CommonMetadata();
    o.entityFilter = buildGoogleDatastoreAdminV1EntityFilter();
    o.inputUrl = 'foo';
    o.progressBytes = buildGoogleDatastoreAdminV1Progress();
    o.progressEntities = buildGoogleDatastoreAdminV1Progress();
  }
  buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1ImportEntitiesMetadata(
    api.GoogleDatastoreAdminV1ImportEntitiesMetadata o) {
  buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata < 3) {
    checkGoogleDatastoreAdminV1CommonMetadata(
        o.common! as api.GoogleDatastoreAdminV1CommonMetadata);
    checkGoogleDatastoreAdminV1EntityFilter(
        o.entityFilter! as api.GoogleDatastoreAdminV1EntityFilter);
    unittest.expect(
      o.inputUrl!,
      unittest.equals('foo'),
    );
    checkGoogleDatastoreAdminV1Progress(
        o.progressBytes! as api.GoogleDatastoreAdminV1Progress);
    checkGoogleDatastoreAdminV1Progress(
        o.progressEntities! as api.GoogleDatastoreAdminV1Progress);
  }
  buildCounterGoogleDatastoreAdminV1ImportEntitiesMetadata--;
}

core.Map<core.String, core.String> buildUnnamed11() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed11(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest = 0;
api.GoogleDatastoreAdminV1ImportEntitiesRequest
    buildGoogleDatastoreAdminV1ImportEntitiesRequest() {
  var o = api.GoogleDatastoreAdminV1ImportEntitiesRequest();
  buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest++;
  if (buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest < 3) {
    o.entityFilter = buildGoogleDatastoreAdminV1EntityFilter();
    o.inputUrl = 'foo';
    o.labels = buildUnnamed11();
  }
  buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest--;
  return o;
}

void checkGoogleDatastoreAdminV1ImportEntitiesRequest(
    api.GoogleDatastoreAdminV1ImportEntitiesRequest o) {
  buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest++;
  if (buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest < 3) {
    checkGoogleDatastoreAdminV1EntityFilter(
        o.entityFilter! as api.GoogleDatastoreAdminV1EntityFilter);
    unittest.expect(
      o.inputUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed11(o.labels!);
  }
  buildCounterGoogleDatastoreAdminV1ImportEntitiesRequest--;
}

core.List<api.GoogleDatastoreAdminV1IndexedProperty> buildUnnamed12() {
  var o = <api.GoogleDatastoreAdminV1IndexedProperty>[];
  o.add(buildGoogleDatastoreAdminV1IndexedProperty());
  o.add(buildGoogleDatastoreAdminV1IndexedProperty());
  return o;
}

void checkUnnamed12(core.List<api.GoogleDatastoreAdminV1IndexedProperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleDatastoreAdminV1IndexedProperty(
      o[0] as api.GoogleDatastoreAdminV1IndexedProperty);
  checkGoogleDatastoreAdminV1IndexedProperty(
      o[1] as api.GoogleDatastoreAdminV1IndexedProperty);
}

core.int buildCounterGoogleDatastoreAdminV1Index = 0;
api.GoogleDatastoreAdminV1Index buildGoogleDatastoreAdminV1Index() {
  var o = api.GoogleDatastoreAdminV1Index();
  buildCounterGoogleDatastoreAdminV1Index++;
  if (buildCounterGoogleDatastoreAdminV1Index < 3) {
    o.ancestor = 'foo';
    o.indexId = 'foo';
    o.kind = 'foo';
    o.projectId = 'foo';
    o.properties = buildUnnamed12();
    o.state = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1Index--;
  return o;
}

void checkGoogleDatastoreAdminV1Index(api.GoogleDatastoreAdminV1Index o) {
  buildCounterGoogleDatastoreAdminV1Index++;
  if (buildCounterGoogleDatastoreAdminV1Index < 3) {
    unittest.expect(
      o.ancestor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.indexId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkUnnamed12(o.properties!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1Index--;
}

core.int buildCounterGoogleDatastoreAdminV1IndexOperationMetadata = 0;
api.GoogleDatastoreAdminV1IndexOperationMetadata
    buildGoogleDatastoreAdminV1IndexOperationMetadata() {
  var o = api.GoogleDatastoreAdminV1IndexOperationMetadata();
  buildCounterGoogleDatastoreAdminV1IndexOperationMetadata++;
  if (buildCounterGoogleDatastoreAdminV1IndexOperationMetadata < 3) {
    o.common = buildGoogleDatastoreAdminV1CommonMetadata();
    o.indexId = 'foo';
    o.progressEntities = buildGoogleDatastoreAdminV1Progress();
  }
  buildCounterGoogleDatastoreAdminV1IndexOperationMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1IndexOperationMetadata(
    api.GoogleDatastoreAdminV1IndexOperationMetadata o) {
  buildCounterGoogleDatastoreAdminV1IndexOperationMetadata++;
  if (buildCounterGoogleDatastoreAdminV1IndexOperationMetadata < 3) {
    checkGoogleDatastoreAdminV1CommonMetadata(
        o.common! as api.GoogleDatastoreAdminV1CommonMetadata);
    unittest.expect(
      o.indexId!,
      unittest.equals('foo'),
    );
    checkGoogleDatastoreAdminV1Progress(
        o.progressEntities! as api.GoogleDatastoreAdminV1Progress);
  }
  buildCounterGoogleDatastoreAdminV1IndexOperationMetadata--;
}

core.int buildCounterGoogleDatastoreAdminV1IndexedProperty = 0;
api.GoogleDatastoreAdminV1IndexedProperty
    buildGoogleDatastoreAdminV1IndexedProperty() {
  var o = api.GoogleDatastoreAdminV1IndexedProperty();
  buildCounterGoogleDatastoreAdminV1IndexedProperty++;
  if (buildCounterGoogleDatastoreAdminV1IndexedProperty < 3) {
    o.direction = 'foo';
    o.name = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1IndexedProperty--;
  return o;
}

void checkGoogleDatastoreAdminV1IndexedProperty(
    api.GoogleDatastoreAdminV1IndexedProperty o) {
  buildCounterGoogleDatastoreAdminV1IndexedProperty++;
  if (buildCounterGoogleDatastoreAdminV1IndexedProperty < 3) {
    unittest.expect(
      o.direction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1IndexedProperty--;
}

core.List<api.GoogleDatastoreAdminV1Index> buildUnnamed13() {
  var o = <api.GoogleDatastoreAdminV1Index>[];
  o.add(buildGoogleDatastoreAdminV1Index());
  o.add(buildGoogleDatastoreAdminV1Index());
  return o;
}

void checkUnnamed13(core.List<api.GoogleDatastoreAdminV1Index> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleDatastoreAdminV1Index(o[0] as api.GoogleDatastoreAdminV1Index);
  checkGoogleDatastoreAdminV1Index(o[1] as api.GoogleDatastoreAdminV1Index);
}

core.int buildCounterGoogleDatastoreAdminV1ListIndexesResponse = 0;
api.GoogleDatastoreAdminV1ListIndexesResponse
    buildGoogleDatastoreAdminV1ListIndexesResponse() {
  var o = api.GoogleDatastoreAdminV1ListIndexesResponse();
  buildCounterGoogleDatastoreAdminV1ListIndexesResponse++;
  if (buildCounterGoogleDatastoreAdminV1ListIndexesResponse < 3) {
    o.indexes = buildUnnamed13();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1ListIndexesResponse--;
  return o;
}

void checkGoogleDatastoreAdminV1ListIndexesResponse(
    api.GoogleDatastoreAdminV1ListIndexesResponse o) {
  buildCounterGoogleDatastoreAdminV1ListIndexesResponse++;
  if (buildCounterGoogleDatastoreAdminV1ListIndexesResponse < 3) {
    checkUnnamed13(o.indexes!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1ListIndexesResponse--;
}

core.int buildCounterGoogleDatastoreAdminV1Progress = 0;
api.GoogleDatastoreAdminV1Progress buildGoogleDatastoreAdminV1Progress() {
  var o = api.GoogleDatastoreAdminV1Progress();
  buildCounterGoogleDatastoreAdminV1Progress++;
  if (buildCounterGoogleDatastoreAdminV1Progress < 3) {
    o.workCompleted = 'foo';
    o.workEstimated = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1Progress--;
  return o;
}

void checkGoogleDatastoreAdminV1Progress(api.GoogleDatastoreAdminV1Progress o) {
  buildCounterGoogleDatastoreAdminV1Progress++;
  if (buildCounterGoogleDatastoreAdminV1Progress < 3) {
    unittest.expect(
      o.workCompleted!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workEstimated!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1Progress--;
}

core.Map<core.String, core.String> buildUnnamed14() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed14(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleDatastoreAdminV1beta1CommonMetadata = 0;
api.GoogleDatastoreAdminV1beta1CommonMetadata
    buildGoogleDatastoreAdminV1beta1CommonMetadata() {
  var o = api.GoogleDatastoreAdminV1beta1CommonMetadata();
  buildCounterGoogleDatastoreAdminV1beta1CommonMetadata++;
  if (buildCounterGoogleDatastoreAdminV1beta1CommonMetadata < 3) {
    o.endTime = 'foo';
    o.labels = buildUnnamed14();
    o.operationType = 'foo';
    o.startTime = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1beta1CommonMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1beta1CommonMetadata(
    api.GoogleDatastoreAdminV1beta1CommonMetadata o) {
  buildCounterGoogleDatastoreAdminV1beta1CommonMetadata++;
  if (buildCounterGoogleDatastoreAdminV1beta1CommonMetadata < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkUnnamed14(o.labels!);
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1beta1CommonMetadata--;
}

core.List<core.String> buildUnnamed15() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed15(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.List<core.String> buildUnnamed16() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed16(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleDatastoreAdminV1beta1EntityFilter = 0;
api.GoogleDatastoreAdminV1beta1EntityFilter
    buildGoogleDatastoreAdminV1beta1EntityFilter() {
  var o = api.GoogleDatastoreAdminV1beta1EntityFilter();
  buildCounterGoogleDatastoreAdminV1beta1EntityFilter++;
  if (buildCounterGoogleDatastoreAdminV1beta1EntityFilter < 3) {
    o.kinds = buildUnnamed15();
    o.namespaceIds = buildUnnamed16();
  }
  buildCounterGoogleDatastoreAdminV1beta1EntityFilter--;
  return o;
}

void checkGoogleDatastoreAdminV1beta1EntityFilter(
    api.GoogleDatastoreAdminV1beta1EntityFilter o) {
  buildCounterGoogleDatastoreAdminV1beta1EntityFilter++;
  if (buildCounterGoogleDatastoreAdminV1beta1EntityFilter < 3) {
    checkUnnamed15(o.kinds!);
    checkUnnamed16(o.namespaceIds!);
  }
  buildCounterGoogleDatastoreAdminV1beta1EntityFilter--;
}

core.int buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata = 0;
api.GoogleDatastoreAdminV1beta1ExportEntitiesMetadata
    buildGoogleDatastoreAdminV1beta1ExportEntitiesMetadata() {
  var o = api.GoogleDatastoreAdminV1beta1ExportEntitiesMetadata();
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata < 3) {
    o.common = buildGoogleDatastoreAdminV1beta1CommonMetadata();
    o.entityFilter = buildGoogleDatastoreAdminV1beta1EntityFilter();
    o.outputUrlPrefix = 'foo';
    o.progressBytes = buildGoogleDatastoreAdminV1beta1Progress();
    o.progressEntities = buildGoogleDatastoreAdminV1beta1Progress();
  }
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1beta1ExportEntitiesMetadata(
    api.GoogleDatastoreAdminV1beta1ExportEntitiesMetadata o) {
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata < 3) {
    checkGoogleDatastoreAdminV1beta1CommonMetadata(
        o.common! as api.GoogleDatastoreAdminV1beta1CommonMetadata);
    checkGoogleDatastoreAdminV1beta1EntityFilter(
        o.entityFilter! as api.GoogleDatastoreAdminV1beta1EntityFilter);
    unittest.expect(
      o.outputUrlPrefix!,
      unittest.equals('foo'),
    );
    checkGoogleDatastoreAdminV1beta1Progress(
        o.progressBytes! as api.GoogleDatastoreAdminV1beta1Progress);
    checkGoogleDatastoreAdminV1beta1Progress(
        o.progressEntities! as api.GoogleDatastoreAdminV1beta1Progress);
  }
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesMetadata--;
}

core.int buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse = 0;
api.GoogleDatastoreAdminV1beta1ExportEntitiesResponse
    buildGoogleDatastoreAdminV1beta1ExportEntitiesResponse() {
  var o = api.GoogleDatastoreAdminV1beta1ExportEntitiesResponse();
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse++;
  if (buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse < 3) {
    o.outputUrl = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse--;
  return o;
}

void checkGoogleDatastoreAdminV1beta1ExportEntitiesResponse(
    api.GoogleDatastoreAdminV1beta1ExportEntitiesResponse o) {
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse++;
  if (buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse < 3) {
    unittest.expect(
      o.outputUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1beta1ExportEntitiesResponse--;
}

core.int buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata = 0;
api.GoogleDatastoreAdminV1beta1ImportEntitiesMetadata
    buildGoogleDatastoreAdminV1beta1ImportEntitiesMetadata() {
  var o = api.GoogleDatastoreAdminV1beta1ImportEntitiesMetadata();
  buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata < 3) {
    o.common = buildGoogleDatastoreAdminV1beta1CommonMetadata();
    o.entityFilter = buildGoogleDatastoreAdminV1beta1EntityFilter();
    o.inputUrl = 'foo';
    o.progressBytes = buildGoogleDatastoreAdminV1beta1Progress();
    o.progressEntities = buildGoogleDatastoreAdminV1beta1Progress();
  }
  buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata--;
  return o;
}

void checkGoogleDatastoreAdminV1beta1ImportEntitiesMetadata(
    api.GoogleDatastoreAdminV1beta1ImportEntitiesMetadata o) {
  buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata++;
  if (buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata < 3) {
    checkGoogleDatastoreAdminV1beta1CommonMetadata(
        o.common! as api.GoogleDatastoreAdminV1beta1CommonMetadata);
    checkGoogleDatastoreAdminV1beta1EntityFilter(
        o.entityFilter! as api.GoogleDatastoreAdminV1beta1EntityFilter);
    unittest.expect(
      o.inputUrl!,
      unittest.equals('foo'),
    );
    checkGoogleDatastoreAdminV1beta1Progress(
        o.progressBytes! as api.GoogleDatastoreAdminV1beta1Progress);
    checkGoogleDatastoreAdminV1beta1Progress(
        o.progressEntities! as api.GoogleDatastoreAdminV1beta1Progress);
  }
  buildCounterGoogleDatastoreAdminV1beta1ImportEntitiesMetadata--;
}

core.int buildCounterGoogleDatastoreAdminV1beta1Progress = 0;
api.GoogleDatastoreAdminV1beta1Progress
    buildGoogleDatastoreAdminV1beta1Progress() {
  var o = api.GoogleDatastoreAdminV1beta1Progress();
  buildCounterGoogleDatastoreAdminV1beta1Progress++;
  if (buildCounterGoogleDatastoreAdminV1beta1Progress < 3) {
    o.workCompleted = 'foo';
    o.workEstimated = 'foo';
  }
  buildCounterGoogleDatastoreAdminV1beta1Progress--;
  return o;
}

void checkGoogleDatastoreAdminV1beta1Progress(
    api.GoogleDatastoreAdminV1beta1Progress o) {
  buildCounterGoogleDatastoreAdminV1beta1Progress++;
  if (buildCounterGoogleDatastoreAdminV1beta1Progress < 3) {
    unittest.expect(
      o.workCompleted!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.workEstimated!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleDatastoreAdminV1beta1Progress--;
}

core.List<api.GoogleLongrunningOperation> buildUnnamed17() {
  var o = <api.GoogleLongrunningOperation>[];
  o.add(buildGoogleLongrunningOperation());
  o.add(buildGoogleLongrunningOperation());
  return o;
}

void checkUnnamed17(core.List<api.GoogleLongrunningOperation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleLongrunningOperation(o[0] as api.GoogleLongrunningOperation);
  checkGoogleLongrunningOperation(o[1] as api.GoogleLongrunningOperation);
}

core.int buildCounterGoogleLongrunningListOperationsResponse = 0;
api.GoogleLongrunningListOperationsResponse
    buildGoogleLongrunningListOperationsResponse() {
  var o = api.GoogleLongrunningListOperationsResponse();
  buildCounterGoogleLongrunningListOperationsResponse++;
  if (buildCounterGoogleLongrunningListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed17();
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
  return o;
}

void checkGoogleLongrunningListOperationsResponse(
    api.GoogleLongrunningListOperationsResponse o) {
  buildCounterGoogleLongrunningListOperationsResponse++;
  if (buildCounterGoogleLongrunningListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed17(o.operations!);
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed18() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed18(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o['x']!) as core.Map;
  unittest.expect(casted1, unittest.hasLength(3));
  unittest.expect(
    casted1['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted1['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted1['string'],
    unittest.equals('foo'),
  );
  var casted2 = (o['y']!) as core.Map;
  unittest.expect(casted2, unittest.hasLength(3));
  unittest.expect(
    casted2['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted2['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted2['string'],
    unittest.equals('foo'),
  );
}

core.Map<core.String, core.Object> buildUnnamed19() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed19(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o['x']!) as core.Map;
  unittest.expect(casted3, unittest.hasLength(3));
  unittest.expect(
    casted3['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted3['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted3['string'],
    unittest.equals('foo'),
  );
  var casted4 = (o['y']!) as core.Map;
  unittest.expect(casted4, unittest.hasLength(3));
  unittest.expect(
    casted4['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted4['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted4['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleLongrunningOperation = 0;
api.GoogleLongrunningOperation buildGoogleLongrunningOperation() {
  var o = api.GoogleLongrunningOperation();
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed18();
    o.name = 'foo';
    o.response = buildUnnamed19();
  }
  buildCounterGoogleLongrunningOperation--;
  return o;
}

void checkGoogleLongrunningOperation(api.GoogleLongrunningOperation o) {
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed18(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed19(o.response!);
  }
  buildCounterGoogleLongrunningOperation--;
}

core.Map<core.String, api.GqlQueryParameter> buildUnnamed20() {
  var o = <core.String, api.GqlQueryParameter>{};
  o['x'] = buildGqlQueryParameter();
  o['y'] = buildGqlQueryParameter();
  return o;
}

void checkUnnamed20(core.Map<core.String, api.GqlQueryParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGqlQueryParameter(o['x']! as api.GqlQueryParameter);
  checkGqlQueryParameter(o['y']! as api.GqlQueryParameter);
}

core.List<api.GqlQueryParameter> buildUnnamed21() {
  var o = <api.GqlQueryParameter>[];
  o.add(buildGqlQueryParameter());
  o.add(buildGqlQueryParameter());
  return o;
}

void checkUnnamed21(core.List<api.GqlQueryParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGqlQueryParameter(o[0] as api.GqlQueryParameter);
  checkGqlQueryParameter(o[1] as api.GqlQueryParameter);
}

core.int buildCounterGqlQuery = 0;
api.GqlQuery buildGqlQuery() {
  var o = api.GqlQuery();
  buildCounterGqlQuery++;
  if (buildCounterGqlQuery < 3) {
    o.allowLiterals = true;
    o.namedBindings = buildUnnamed20();
    o.positionalBindings = buildUnnamed21();
    o.queryString = 'foo';
  }
  buildCounterGqlQuery--;
  return o;
}

void checkGqlQuery(api.GqlQuery o) {
  buildCounterGqlQuery++;
  if (buildCounterGqlQuery < 3) {
    unittest.expect(o.allowLiterals!, unittest.isTrue);
    checkUnnamed20(o.namedBindings!);
    checkUnnamed21(o.positionalBindings!);
    unittest.expect(
      o.queryString!,
      unittest.equals('foo'),
    );
  }
  buildCounterGqlQuery--;
}

core.int buildCounterGqlQueryParameter = 0;
api.GqlQueryParameter buildGqlQueryParameter() {
  var o = api.GqlQueryParameter();
  buildCounterGqlQueryParameter++;
  if (buildCounterGqlQueryParameter < 3) {
    o.cursor = 'foo';
    o.value = buildValue();
  }
  buildCounterGqlQueryParameter--;
  return o;
}

void checkGqlQueryParameter(api.GqlQueryParameter o) {
  buildCounterGqlQueryParameter++;
  if (buildCounterGqlQueryParameter < 3) {
    unittest.expect(
      o.cursor!,
      unittest.equals('foo'),
    );
    checkValue(o.value! as api.Value);
  }
  buildCounterGqlQueryParameter--;
}

core.List<api.PathElement> buildUnnamed22() {
  var o = <api.PathElement>[];
  o.add(buildPathElement());
  o.add(buildPathElement());
  return o;
}

void checkUnnamed22(core.List<api.PathElement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPathElement(o[0] as api.PathElement);
  checkPathElement(o[1] as api.PathElement);
}

core.int buildCounterKey = 0;
api.Key buildKey() {
  var o = api.Key();
  buildCounterKey++;
  if (buildCounterKey < 3) {
    o.partitionId = buildPartitionId();
    o.path = buildUnnamed22();
  }
  buildCounterKey--;
  return o;
}

void checkKey(api.Key o) {
  buildCounterKey++;
  if (buildCounterKey < 3) {
    checkPartitionId(o.partitionId! as api.PartitionId);
    checkUnnamed22(o.path!);
  }
  buildCounterKey--;
}

core.int buildCounterKindExpression = 0;
api.KindExpression buildKindExpression() {
  var o = api.KindExpression();
  buildCounterKindExpression++;
  if (buildCounterKindExpression < 3) {
    o.name = 'foo';
  }
  buildCounterKindExpression--;
  return o;
}

void checkKindExpression(api.KindExpression o) {
  buildCounterKindExpression++;
  if (buildCounterKindExpression < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterKindExpression--;
}

core.int buildCounterLatLng = 0;
api.LatLng buildLatLng() {
  var o = api.LatLng();
  buildCounterLatLng++;
  if (buildCounterLatLng < 3) {
    o.latitude = 42.0;
    o.longitude = 42.0;
  }
  buildCounterLatLng--;
  return o;
}

void checkLatLng(api.LatLng o) {
  buildCounterLatLng++;
  if (buildCounterLatLng < 3) {
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
  }
  buildCounterLatLng--;
}

core.List<api.Key> buildUnnamed23() {
  var o = <api.Key>[];
  o.add(buildKey());
  o.add(buildKey());
  return o;
}

void checkUnnamed23(core.List<api.Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKey(o[0] as api.Key);
  checkKey(o[1] as api.Key);
}

core.int buildCounterLookupRequest = 0;
api.LookupRequest buildLookupRequest() {
  var o = api.LookupRequest();
  buildCounterLookupRequest++;
  if (buildCounterLookupRequest < 3) {
    o.keys = buildUnnamed23();
    o.readOptions = buildReadOptions();
  }
  buildCounterLookupRequest--;
  return o;
}

void checkLookupRequest(api.LookupRequest o) {
  buildCounterLookupRequest++;
  if (buildCounterLookupRequest < 3) {
    checkUnnamed23(o.keys!);
    checkReadOptions(o.readOptions! as api.ReadOptions);
  }
  buildCounterLookupRequest--;
}

core.List<api.Key> buildUnnamed24() {
  var o = <api.Key>[];
  o.add(buildKey());
  o.add(buildKey());
  return o;
}

void checkUnnamed24(core.List<api.Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKey(o[0] as api.Key);
  checkKey(o[1] as api.Key);
}

core.List<api.EntityResult> buildUnnamed25() {
  var o = <api.EntityResult>[];
  o.add(buildEntityResult());
  o.add(buildEntityResult());
  return o;
}

void checkUnnamed25(core.List<api.EntityResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntityResult(o[0] as api.EntityResult);
  checkEntityResult(o[1] as api.EntityResult);
}

core.List<api.EntityResult> buildUnnamed26() {
  var o = <api.EntityResult>[];
  o.add(buildEntityResult());
  o.add(buildEntityResult());
  return o;
}

void checkUnnamed26(core.List<api.EntityResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntityResult(o[0] as api.EntityResult);
  checkEntityResult(o[1] as api.EntityResult);
}

core.int buildCounterLookupResponse = 0;
api.LookupResponse buildLookupResponse() {
  var o = api.LookupResponse();
  buildCounterLookupResponse++;
  if (buildCounterLookupResponse < 3) {
    o.deferred = buildUnnamed24();
    o.found = buildUnnamed25();
    o.missing = buildUnnamed26();
  }
  buildCounterLookupResponse--;
  return o;
}

void checkLookupResponse(api.LookupResponse o) {
  buildCounterLookupResponse++;
  if (buildCounterLookupResponse < 3) {
    checkUnnamed24(o.deferred!);
    checkUnnamed25(o.found!);
    checkUnnamed26(o.missing!);
  }
  buildCounterLookupResponse--;
}

core.int buildCounterMutation = 0;
api.Mutation buildMutation() {
  var o = api.Mutation();
  buildCounterMutation++;
  if (buildCounterMutation < 3) {
    o.baseVersion = 'foo';
    o.delete = buildKey();
    o.insert = buildEntity();
    o.update = buildEntity();
    o.upsert = buildEntity();
  }
  buildCounterMutation--;
  return o;
}

void checkMutation(api.Mutation o) {
  buildCounterMutation++;
  if (buildCounterMutation < 3) {
    unittest.expect(
      o.baseVersion!,
      unittest.equals('foo'),
    );
    checkKey(o.delete! as api.Key);
    checkEntity(o.insert! as api.Entity);
    checkEntity(o.update! as api.Entity);
    checkEntity(o.upsert! as api.Entity);
  }
  buildCounterMutation--;
}

core.int buildCounterMutationResult = 0;
api.MutationResult buildMutationResult() {
  var o = api.MutationResult();
  buildCounterMutationResult++;
  if (buildCounterMutationResult < 3) {
    o.conflictDetected = true;
    o.key = buildKey();
    o.version = 'foo';
  }
  buildCounterMutationResult--;
  return o;
}

void checkMutationResult(api.MutationResult o) {
  buildCounterMutationResult++;
  if (buildCounterMutationResult < 3) {
    unittest.expect(o.conflictDetected!, unittest.isTrue);
    checkKey(o.key! as api.Key);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterMutationResult--;
}

core.int buildCounterPartitionId = 0;
api.PartitionId buildPartitionId() {
  var o = api.PartitionId();
  buildCounterPartitionId++;
  if (buildCounterPartitionId < 3) {
    o.namespaceId = 'foo';
    o.projectId = 'foo';
  }
  buildCounterPartitionId--;
  return o;
}

void checkPartitionId(api.PartitionId o) {
  buildCounterPartitionId++;
  if (buildCounterPartitionId < 3) {
    unittest.expect(
      o.namespaceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartitionId--;
}

core.int buildCounterPathElement = 0;
api.PathElement buildPathElement() {
  var o = api.PathElement();
  buildCounterPathElement++;
  if (buildCounterPathElement < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterPathElement--;
  return o;
}

void checkPathElement(api.PathElement o) {
  buildCounterPathElement++;
  if (buildCounterPathElement < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterPathElement--;
}

core.int buildCounterProjection = 0;
api.Projection buildProjection() {
  var o = api.Projection();
  buildCounterProjection++;
  if (buildCounterProjection < 3) {
    o.property = buildPropertyReference();
  }
  buildCounterProjection--;
  return o;
}

void checkProjection(api.Projection o) {
  buildCounterProjection++;
  if (buildCounterProjection < 3) {
    checkPropertyReference(o.property! as api.PropertyReference);
  }
  buildCounterProjection--;
}

core.int buildCounterPropertyFilter = 0;
api.PropertyFilter buildPropertyFilter() {
  var o = api.PropertyFilter();
  buildCounterPropertyFilter++;
  if (buildCounterPropertyFilter < 3) {
    o.op = 'foo';
    o.property = buildPropertyReference();
    o.value = buildValue();
  }
  buildCounterPropertyFilter--;
  return o;
}

void checkPropertyFilter(api.PropertyFilter o) {
  buildCounterPropertyFilter++;
  if (buildCounterPropertyFilter < 3) {
    unittest.expect(
      o.op!,
      unittest.equals('foo'),
    );
    checkPropertyReference(o.property! as api.PropertyReference);
    checkValue(o.value! as api.Value);
  }
  buildCounterPropertyFilter--;
}

core.int buildCounterPropertyOrder = 0;
api.PropertyOrder buildPropertyOrder() {
  var o = api.PropertyOrder();
  buildCounterPropertyOrder++;
  if (buildCounterPropertyOrder < 3) {
    o.direction = 'foo';
    o.property = buildPropertyReference();
  }
  buildCounterPropertyOrder--;
  return o;
}

void checkPropertyOrder(api.PropertyOrder o) {
  buildCounterPropertyOrder++;
  if (buildCounterPropertyOrder < 3) {
    unittest.expect(
      o.direction!,
      unittest.equals('foo'),
    );
    checkPropertyReference(o.property! as api.PropertyReference);
  }
  buildCounterPropertyOrder--;
}

core.int buildCounterPropertyReference = 0;
api.PropertyReference buildPropertyReference() {
  var o = api.PropertyReference();
  buildCounterPropertyReference++;
  if (buildCounterPropertyReference < 3) {
    o.name = 'foo';
  }
  buildCounterPropertyReference--;
  return o;
}

void checkPropertyReference(api.PropertyReference o) {
  buildCounterPropertyReference++;
  if (buildCounterPropertyReference < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterPropertyReference--;
}

core.List<api.PropertyReference> buildUnnamed27() {
  var o = <api.PropertyReference>[];
  o.add(buildPropertyReference());
  o.add(buildPropertyReference());
  return o;
}

void checkUnnamed27(core.List<api.PropertyReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPropertyReference(o[0] as api.PropertyReference);
  checkPropertyReference(o[1] as api.PropertyReference);
}

core.List<api.KindExpression> buildUnnamed28() {
  var o = <api.KindExpression>[];
  o.add(buildKindExpression());
  o.add(buildKindExpression());
  return o;
}

void checkUnnamed28(core.List<api.KindExpression> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKindExpression(o[0] as api.KindExpression);
  checkKindExpression(o[1] as api.KindExpression);
}

core.List<api.PropertyOrder> buildUnnamed29() {
  var o = <api.PropertyOrder>[];
  o.add(buildPropertyOrder());
  o.add(buildPropertyOrder());
  return o;
}

void checkUnnamed29(core.List<api.PropertyOrder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPropertyOrder(o[0] as api.PropertyOrder);
  checkPropertyOrder(o[1] as api.PropertyOrder);
}

core.List<api.Projection> buildUnnamed30() {
  var o = <api.Projection>[];
  o.add(buildProjection());
  o.add(buildProjection());
  return o;
}

void checkUnnamed30(core.List<api.Projection> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProjection(o[0] as api.Projection);
  checkProjection(o[1] as api.Projection);
}

core.int buildCounterQuery = 0;
api.Query buildQuery() {
  var o = api.Query();
  buildCounterQuery++;
  if (buildCounterQuery < 3) {
    o.distinctOn = buildUnnamed27();
    o.endCursor = 'foo';
    o.filter = buildFilter();
    o.kind = buildUnnamed28();
    o.limit = 42;
    o.offset = 42;
    o.order = buildUnnamed29();
    o.projection = buildUnnamed30();
    o.startCursor = 'foo';
  }
  buildCounterQuery--;
  return o;
}

void checkQuery(api.Query o) {
  buildCounterQuery++;
  if (buildCounterQuery < 3) {
    checkUnnamed27(o.distinctOn!);
    unittest.expect(
      o.endCursor!,
      unittest.equals('foo'),
    );
    checkFilter(o.filter! as api.Filter);
    checkUnnamed28(o.kind!);
    unittest.expect(
      o.limit!,
      unittest.equals(42),
    );
    unittest.expect(
      o.offset!,
      unittest.equals(42),
    );
    checkUnnamed29(o.order!);
    checkUnnamed30(o.projection!);
    unittest.expect(
      o.startCursor!,
      unittest.equals('foo'),
    );
  }
  buildCounterQuery--;
}

core.List<api.EntityResult> buildUnnamed31() {
  var o = <api.EntityResult>[];
  o.add(buildEntityResult());
  o.add(buildEntityResult());
  return o;
}

void checkUnnamed31(core.List<api.EntityResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntityResult(o[0] as api.EntityResult);
  checkEntityResult(o[1] as api.EntityResult);
}

core.int buildCounterQueryResultBatch = 0;
api.QueryResultBatch buildQueryResultBatch() {
  var o = api.QueryResultBatch();
  buildCounterQueryResultBatch++;
  if (buildCounterQueryResultBatch < 3) {
    o.endCursor = 'foo';
    o.entityResultType = 'foo';
    o.entityResults = buildUnnamed31();
    o.moreResults = 'foo';
    o.skippedCursor = 'foo';
    o.skippedResults = 42;
    o.snapshotVersion = 'foo';
  }
  buildCounterQueryResultBatch--;
  return o;
}

void checkQueryResultBatch(api.QueryResultBatch o) {
  buildCounterQueryResultBatch++;
  if (buildCounterQueryResultBatch < 3) {
    unittest.expect(
      o.endCursor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityResultType!,
      unittest.equals('foo'),
    );
    checkUnnamed31(o.entityResults!);
    unittest.expect(
      o.moreResults!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skippedCursor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skippedResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.snapshotVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryResultBatch--;
}

core.int buildCounterReadOnly = 0;
api.ReadOnly buildReadOnly() {
  var o = api.ReadOnly();
  buildCounterReadOnly++;
  if (buildCounterReadOnly < 3) {}
  buildCounterReadOnly--;
  return o;
}

void checkReadOnly(api.ReadOnly o) {
  buildCounterReadOnly++;
  if (buildCounterReadOnly < 3) {}
  buildCounterReadOnly--;
}

core.int buildCounterReadOptions = 0;
api.ReadOptions buildReadOptions() {
  var o = api.ReadOptions();
  buildCounterReadOptions++;
  if (buildCounterReadOptions < 3) {
    o.readConsistency = 'foo';
    o.transaction = 'foo';
  }
  buildCounterReadOptions--;
  return o;
}

void checkReadOptions(api.ReadOptions o) {
  buildCounterReadOptions++;
  if (buildCounterReadOptions < 3) {
    unittest.expect(
      o.readConsistency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterReadOptions--;
}

core.int buildCounterReadWrite = 0;
api.ReadWrite buildReadWrite() {
  var o = api.ReadWrite();
  buildCounterReadWrite++;
  if (buildCounterReadWrite < 3) {
    o.previousTransaction = 'foo';
  }
  buildCounterReadWrite--;
  return o;
}

void checkReadWrite(api.ReadWrite o) {
  buildCounterReadWrite++;
  if (buildCounterReadWrite < 3) {
    unittest.expect(
      o.previousTransaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterReadWrite--;
}

core.List<api.Key> buildUnnamed32() {
  var o = <api.Key>[];
  o.add(buildKey());
  o.add(buildKey());
  return o;
}

void checkUnnamed32(core.List<api.Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKey(o[0] as api.Key);
  checkKey(o[1] as api.Key);
}

core.int buildCounterReserveIdsRequest = 0;
api.ReserveIdsRequest buildReserveIdsRequest() {
  var o = api.ReserveIdsRequest();
  buildCounterReserveIdsRequest++;
  if (buildCounterReserveIdsRequest < 3) {
    o.databaseId = 'foo';
    o.keys = buildUnnamed32();
  }
  buildCounterReserveIdsRequest--;
  return o;
}

void checkReserveIdsRequest(api.ReserveIdsRequest o) {
  buildCounterReserveIdsRequest++;
  if (buildCounterReserveIdsRequest < 3) {
    unittest.expect(
      o.databaseId!,
      unittest.equals('foo'),
    );
    checkUnnamed32(o.keys!);
  }
  buildCounterReserveIdsRequest--;
}

core.int buildCounterReserveIdsResponse = 0;
api.ReserveIdsResponse buildReserveIdsResponse() {
  var o = api.ReserveIdsResponse();
  buildCounterReserveIdsResponse++;
  if (buildCounterReserveIdsResponse < 3) {}
  buildCounterReserveIdsResponse--;
  return o;
}

void checkReserveIdsResponse(api.ReserveIdsResponse o) {
  buildCounterReserveIdsResponse++;
  if (buildCounterReserveIdsResponse < 3) {}
  buildCounterReserveIdsResponse--;
}

core.int buildCounterRollbackRequest = 0;
api.RollbackRequest buildRollbackRequest() {
  var o = api.RollbackRequest();
  buildCounterRollbackRequest++;
  if (buildCounterRollbackRequest < 3) {
    o.transaction = 'foo';
  }
  buildCounterRollbackRequest--;
  return o;
}

void checkRollbackRequest(api.RollbackRequest o) {
  buildCounterRollbackRequest++;
  if (buildCounterRollbackRequest < 3) {
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterRollbackRequest--;
}

core.int buildCounterRollbackResponse = 0;
api.RollbackResponse buildRollbackResponse() {
  var o = api.RollbackResponse();
  buildCounterRollbackResponse++;
  if (buildCounterRollbackResponse < 3) {}
  buildCounterRollbackResponse--;
  return o;
}

void checkRollbackResponse(api.RollbackResponse o) {
  buildCounterRollbackResponse++;
  if (buildCounterRollbackResponse < 3) {}
  buildCounterRollbackResponse--;
}

core.int buildCounterRunQueryRequest = 0;
api.RunQueryRequest buildRunQueryRequest() {
  var o = api.RunQueryRequest();
  buildCounterRunQueryRequest++;
  if (buildCounterRunQueryRequest < 3) {
    o.gqlQuery = buildGqlQuery();
    o.partitionId = buildPartitionId();
    o.query = buildQuery();
    o.readOptions = buildReadOptions();
  }
  buildCounterRunQueryRequest--;
  return o;
}

void checkRunQueryRequest(api.RunQueryRequest o) {
  buildCounterRunQueryRequest++;
  if (buildCounterRunQueryRequest < 3) {
    checkGqlQuery(o.gqlQuery! as api.GqlQuery);
    checkPartitionId(o.partitionId! as api.PartitionId);
    checkQuery(o.query! as api.Query);
    checkReadOptions(o.readOptions! as api.ReadOptions);
  }
  buildCounterRunQueryRequest--;
}

core.int buildCounterRunQueryResponse = 0;
api.RunQueryResponse buildRunQueryResponse() {
  var o = api.RunQueryResponse();
  buildCounterRunQueryResponse++;
  if (buildCounterRunQueryResponse < 3) {
    o.batch = buildQueryResultBatch();
    o.query = buildQuery();
  }
  buildCounterRunQueryResponse--;
  return o;
}

void checkRunQueryResponse(api.RunQueryResponse o) {
  buildCounterRunQueryResponse++;
  if (buildCounterRunQueryResponse < 3) {
    checkQueryResultBatch(o.batch! as api.QueryResultBatch);
    checkQuery(o.query! as api.Query);
  }
  buildCounterRunQueryResponse--;
}

core.Map<core.String, core.Object> buildUnnamed33() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed33(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted5 = (o['x']!) as core.Map;
  unittest.expect(casted5, unittest.hasLength(3));
  unittest.expect(
    casted5['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted5['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted5['string'],
    unittest.equals('foo'),
  );
  var casted6 = (o['y']!) as core.Map;
  unittest.expect(casted6, unittest.hasLength(3));
  unittest.expect(
    casted6['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted6['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted6['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed34() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed33());
  o.add(buildUnnamed33());
  return o;
}

void checkUnnamed34(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed33(o[0]);
  checkUnnamed33(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed34();
    o.message = 'foo';
  }
  buildCounterStatus--;
  return o;
}

void checkStatus(api.Status o) {
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals(42),
    );
    checkUnnamed34(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTransactionOptions = 0;
api.TransactionOptions buildTransactionOptions() {
  var o = api.TransactionOptions();
  buildCounterTransactionOptions++;
  if (buildCounterTransactionOptions < 3) {
    o.readOnly = buildReadOnly();
    o.readWrite = buildReadWrite();
  }
  buildCounterTransactionOptions--;
  return o;
}

void checkTransactionOptions(api.TransactionOptions o) {
  buildCounterTransactionOptions++;
  if (buildCounterTransactionOptions < 3) {
    checkReadOnly(o.readOnly! as api.ReadOnly);
    checkReadWrite(o.readWrite! as api.ReadWrite);
  }
  buildCounterTransactionOptions--;
}

core.int buildCounterValue = 0;
api.Value buildValue() {
  var o = api.Value();
  buildCounterValue++;
  if (buildCounterValue < 3) {
    o.arrayValue = buildArrayValue();
    o.blobValue = 'foo';
    o.booleanValue = true;
    o.doubleValue = 42.0;
    o.entityValue = buildEntity();
    o.excludeFromIndexes = true;
    o.geoPointValue = buildLatLng();
    o.integerValue = 'foo';
    o.keyValue = buildKey();
    o.meaning = 42;
    o.nullValue = 'foo';
    o.stringValue = 'foo';
    o.timestampValue = 'foo';
  }
  buildCounterValue--;
  return o;
}

void checkValue(api.Value o) {
  buildCounterValue++;
  if (buildCounterValue < 3) {
    checkArrayValue(o.arrayValue! as api.ArrayValue);
    unittest.expect(
      o.blobValue!,
      unittest.equals('foo'),
    );
    unittest.expect(o.booleanValue!, unittest.isTrue);
    unittest.expect(
      o.doubleValue!,
      unittest.equals(42.0),
    );
    checkEntity(o.entityValue! as api.Entity);
    unittest.expect(o.excludeFromIndexes!, unittest.isTrue);
    checkLatLng(o.geoPointValue! as api.LatLng);
    unittest.expect(
      o.integerValue!,
      unittest.equals('foo'),
    );
    checkKey(o.keyValue! as api.Key);
    unittest.expect(
      o.meaning!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nullValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timestampValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterValue--;
}

void main() {
  unittest.group('obj-schema-AllocateIdsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAllocateIdsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AllocateIdsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAllocateIdsRequest(od as api.AllocateIdsRequest);
    });
  });

  unittest.group('obj-schema-AllocateIdsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAllocateIdsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AllocateIdsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAllocateIdsResponse(od as api.AllocateIdsResponse);
    });
  });

  unittest.group('obj-schema-ArrayValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArrayValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ArrayValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArrayValue(od as api.ArrayValue);
    });
  });

  unittest.group('obj-schema-BeginTransactionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBeginTransactionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BeginTransactionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBeginTransactionRequest(od as api.BeginTransactionRequest);
    });
  });

  unittest.group('obj-schema-BeginTransactionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBeginTransactionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BeginTransactionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBeginTransactionResponse(od as api.BeginTransactionResponse);
    });
  });

  unittest.group('obj-schema-CommitRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommitRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommitRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommitRequest(od as api.CommitRequest);
    });
  });

  unittest.group('obj-schema-CommitResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommitResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommitResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommitResponse(od as api.CommitResponse);
    });
  });

  unittest.group('obj-schema-CompositeFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompositeFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompositeFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompositeFilter(od as api.CompositeFilter);
    });
  });

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Entity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEntity(od as api.Entity);
    });
  });

  unittest.group('obj-schema-EntityResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityResult(od as api.EntityResult);
    });
  });

  unittest.group('obj-schema-Filter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Filter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilter(od as api.Filter);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1CommonMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1CommonMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1CommonMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1CommonMetadata(
          od as api.GoogleDatastoreAdminV1CommonMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1EntityFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1EntityFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1EntityFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1EntityFilter(
          od as api.GoogleDatastoreAdminV1EntityFilter);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1ExportEntitiesMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1ExportEntitiesMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1ExportEntitiesMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1ExportEntitiesMetadata(
          od as api.GoogleDatastoreAdminV1ExportEntitiesMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1ExportEntitiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1ExportEntitiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1ExportEntitiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1ExportEntitiesRequest(
          od as api.GoogleDatastoreAdminV1ExportEntitiesRequest);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1ExportEntitiesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1ExportEntitiesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1ExportEntitiesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1ExportEntitiesResponse(
          od as api.GoogleDatastoreAdminV1ExportEntitiesResponse);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1ImportEntitiesMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1ImportEntitiesMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1ImportEntitiesMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1ImportEntitiesMetadata(
          od as api.GoogleDatastoreAdminV1ImportEntitiesMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1ImportEntitiesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1ImportEntitiesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1ImportEntitiesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1ImportEntitiesRequest(
          od as api.GoogleDatastoreAdminV1ImportEntitiesRequest);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1Index', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1Index();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1Index.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1Index(od as api.GoogleDatastoreAdminV1Index);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1IndexOperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1IndexOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1IndexOperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1IndexOperationMetadata(
          od as api.GoogleDatastoreAdminV1IndexOperationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1IndexedProperty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1IndexedProperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1IndexedProperty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1IndexedProperty(
          od as api.GoogleDatastoreAdminV1IndexedProperty);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1ListIndexesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1ListIndexesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1ListIndexesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1ListIndexesResponse(
          od as api.GoogleDatastoreAdminV1ListIndexesResponse);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1Progress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1Progress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1Progress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1Progress(
          od as api.GoogleDatastoreAdminV1Progress);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1beta1CommonMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1beta1CommonMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1beta1CommonMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1beta1CommonMetadata(
          od as api.GoogleDatastoreAdminV1beta1CommonMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1beta1EntityFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1beta1EntityFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1beta1EntityFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1beta1EntityFilter(
          od as api.GoogleDatastoreAdminV1beta1EntityFilter);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1beta1ExportEntitiesMetadata',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1beta1ExportEntitiesMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1beta1ExportEntitiesMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1beta1ExportEntitiesMetadata(
          od as api.GoogleDatastoreAdminV1beta1ExportEntitiesMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1beta1ExportEntitiesResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1beta1ExportEntitiesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1beta1ExportEntitiesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1beta1ExportEntitiesResponse(
          od as api.GoogleDatastoreAdminV1beta1ExportEntitiesResponse);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1beta1ImportEntitiesMetadata',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1beta1ImportEntitiesMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1beta1ImportEntitiesMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1beta1ImportEntitiesMetadata(
          od as api.GoogleDatastoreAdminV1beta1ImportEntitiesMetadata);
    });
  });

  unittest.group('obj-schema-GoogleDatastoreAdminV1beta1Progress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleDatastoreAdminV1beta1Progress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleDatastoreAdminV1beta1Progress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleDatastoreAdminV1beta1Progress(
          od as api.GoogleDatastoreAdminV1beta1Progress);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningListOperationsResponse(
          od as api.GoogleLongrunningListOperationsResponse);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningOperation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningOperation(od as api.GoogleLongrunningOperation);
    });
  });

  unittest.group('obj-schema-GqlQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGqlQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GqlQuery.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGqlQuery(od as api.GqlQuery);
    });
  });

  unittest.group('obj-schema-GqlQueryParameter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGqlQueryParameter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GqlQueryParameter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGqlQueryParameter(od as api.GqlQueryParameter);
    });
  });

  unittest.group('obj-schema-Key', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Key.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKey(od as api.Key);
    });
  });

  unittest.group('obj-schema-KindExpression', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKindExpression();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.KindExpression.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkKindExpression(od as api.KindExpression);
    });
  });

  unittest.group('obj-schema-LatLng', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLatLng();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LatLng.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLatLng(od as api.LatLng);
    });
  });

  unittest.group('obj-schema-LookupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLookupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LookupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLookupRequest(od as api.LookupRequest);
    });
  });

  unittest.group('obj-schema-LookupResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLookupResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LookupResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLookupResponse(od as api.LookupResponse);
    });
  });

  unittest.group('obj-schema-Mutation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMutation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Mutation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMutation(od as api.Mutation);
    });
  });

  unittest.group('obj-schema-MutationResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMutationResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MutationResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMutationResult(od as api.MutationResult);
    });
  });

  unittest.group('obj-schema-PartitionId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionId(od as api.PartitionId);
    });
  });

  unittest.group('obj-schema-PathElement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPathElement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PathElement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPathElement(od as api.PathElement);
    });
  });

  unittest.group('obj-schema-Projection', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Projection.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProjection(od as api.Projection);
    });
  });

  unittest.group('obj-schema-PropertyFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPropertyFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PropertyFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPropertyFilter(od as api.PropertyFilter);
    });
  });

  unittest.group('obj-schema-PropertyOrder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPropertyOrder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PropertyOrder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPropertyOrder(od as api.PropertyOrder);
    });
  });

  unittest.group('obj-schema-PropertyReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPropertyReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PropertyReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPropertyReference(od as api.PropertyReference);
    });
  });

  unittest.group('obj-schema-Query', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Query.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQuery(od as api.Query);
    });
  });

  unittest.group('obj-schema-QueryResultBatch', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryResultBatch();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryResultBatch.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryResultBatch(od as api.QueryResultBatch);
    });
  });

  unittest.group('obj-schema-ReadOnly', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReadOnly();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReadOnly.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReadOnly(od as api.ReadOnly);
    });
  });

  unittest.group('obj-schema-ReadOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReadOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReadOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReadOptions(od as api.ReadOptions);
    });
  });

  unittest.group('obj-schema-ReadWrite', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReadWrite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReadWrite.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReadWrite(od as api.ReadWrite);
    });
  });

  unittest.group('obj-schema-ReserveIdsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReserveIdsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReserveIdsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReserveIdsRequest(od as api.ReserveIdsRequest);
    });
  });

  unittest.group('obj-schema-ReserveIdsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReserveIdsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReserveIdsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReserveIdsResponse(od as api.ReserveIdsResponse);
    });
  });

  unittest.group('obj-schema-RollbackRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRollbackRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RollbackRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRollbackRequest(od as api.RollbackRequest);
    });
  });

  unittest.group('obj-schema-RollbackResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRollbackResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RollbackResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRollbackResponse(od as api.RollbackResponse);
    });
  });

  unittest.group('obj-schema-RunQueryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRunQueryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RunQueryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRunQueryRequest(od as api.RunQueryRequest);
    });
  });

  unittest.group('obj-schema-RunQueryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRunQueryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RunQueryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRunQueryResponse(od as api.RunQueryResponse);
    });
  });

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-TransactionOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransactionOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TransactionOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransactionOptions(od as api.TransactionOptions);
    });
  });

  unittest.group('obj-schema-Value', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Value.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkValue(od as api.Value);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--allocateIds', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildAllocateIdsRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AllocateIdsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAllocateIdsRequest(obj as api.AllocateIdsRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':allocateIds', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals(":allocateIds"),
        );
        pathOffset += 12;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAllocateIdsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.allocateIds(arg_request, arg_projectId,
          $fields: arg_$fields);
      checkAllocateIdsResponse(response as api.AllocateIdsResponse);
    });

    unittest.test('method--beginTransaction', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildBeginTransactionRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BeginTransactionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBeginTransactionRequest(obj as api.BeginTransactionRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':beginTransaction', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals(":beginTransaction"),
        );
        pathOffset += 17;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBeginTransactionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.beginTransaction(arg_request, arg_projectId,
          $fields: arg_$fields);
      checkBeginTransactionResponse(response as api.BeginTransactionResponse);
    });

    unittest.test('method--commit', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildCommitRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CommitRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCommitRequest(obj as api.CommitRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':commit', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":commit"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCommitResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.commit(arg_request, arg_projectId, $fields: arg_$fields);
      checkCommitResponse(response as api.CommitResponse);
    });

    unittest.test('method--export', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildGoogleDatastoreAdminV1ExportEntitiesRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleDatastoreAdminV1ExportEntitiesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleDatastoreAdminV1ExportEntitiesRequest(
            obj as api.GoogleDatastoreAdminV1ExportEntitiesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':export', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":export"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.export(arg_request, arg_projectId, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--import', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildGoogleDatastoreAdminV1ImportEntitiesRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleDatastoreAdminV1ImportEntitiesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleDatastoreAdminV1ImportEntitiesRequest(
            obj as api.GoogleDatastoreAdminV1ImportEntitiesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':import', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":import"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.import(arg_request, arg_projectId, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--lookup', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildLookupRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LookupRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLookupRequest(obj as api.LookupRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':lookup', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":lookup"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLookupResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.lookup(arg_request, arg_projectId, $fields: arg_$fields);
      checkLookupResponse(response as api.LookupResponse);
    });

    unittest.test('method--reserveIds', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildReserveIdsRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReserveIdsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReserveIdsRequest(obj as api.ReserveIdsRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':reserveIds', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals(":reserveIds"),
        );
        pathOffset += 11;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReserveIdsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.reserveIds(arg_request, arg_projectId,
          $fields: arg_$fields);
      checkReserveIdsResponse(response as api.ReserveIdsResponse);
    });

    unittest.test('method--rollback', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildRollbackRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RollbackRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRollbackRequest(obj as api.RollbackRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':rollback', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals(":rollback"),
        );
        pathOffset += 9;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRollbackResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.rollback(arg_request, arg_projectId, $fields: arg_$fields);
      checkRollbackResponse(response as api.RollbackResponse);
    });

    unittest.test('method--runQuery', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects;
      var arg_request = buildRunQueryRequest();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RunQueryRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRunQueryRequest(obj as api.RunQueryRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf(':runQuery', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals(":runQuery"),
        );
        pathOffset += 9;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRunQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.runQuery(arg_request, arg_projectId, $fields: arg_$fields);
      checkRunQueryResponse(response as api.RunQueryResponse);
    });
  });

  unittest.group('resource-ProjectsIndexesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.indexes;
      var arg_request = buildGoogleDatastoreAdminV1Index();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleDatastoreAdminV1Index.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleDatastoreAdminV1Index(
            obj as api.GoogleDatastoreAdminV1Index);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/indexes', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/indexes"),
        );
        pathOffset += 8;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_projectId, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.indexes;
      var arg_projectId = 'foo';
      var arg_indexId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/indexes/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/indexes/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_indexId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_projectId, arg_indexId, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.indexes;
      var arg_projectId = 'foo';
      var arg_indexId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/indexes/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/indexes/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_indexId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleDatastoreAdminV1Index());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_projectId, arg_indexId, $fields: arg_$fields);
      checkGoogleDatastoreAdminV1Index(
          response as api.GoogleDatastoreAdminV1Index);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.indexes;
      var arg_projectId = 'foo';
      var arg_filter = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/projects/"),
        );
        pathOffset += 12;
        index = path.indexOf('/indexes', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/indexes"),
        );
        pathOffset += 8;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildGoogleDatastoreAdminV1ListIndexesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleDatastoreAdminV1ListIndexesResponse(
          response as api.GoogleDatastoreAdminV1ListIndexesResponse);
    });
  });

  unittest.group('resource-ProjectsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.operations;
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.cancel(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.operations;
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.operations;
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DatastoreApi(mock).projects.operations;
      var arg_name = 'foo';
      var arg_filter = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildGoogleLongrunningListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleLongrunningListOperationsResponse(
          response as api.GoogleLongrunningListOperationsResponse);
    });
  });
}
