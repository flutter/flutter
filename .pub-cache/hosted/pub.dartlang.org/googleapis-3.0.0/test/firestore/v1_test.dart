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

import 'package:googleapis/firestore/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Value> buildUnnamed4050() {
  var o = <api.Value>[];
  o.add(buildValue());
  o.add(buildValue());
  return o;
}

void checkUnnamed4050(core.List<api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o[0] as api.Value);
  checkValue(o[1] as api.Value);
}

core.int buildCounterArrayValue = 0;
api.ArrayValue buildArrayValue() {
  var o = api.ArrayValue();
  buildCounterArrayValue++;
  if (buildCounterArrayValue < 3) {
    o.values = buildUnnamed4050();
  }
  buildCounterArrayValue--;
  return o;
}

void checkArrayValue(api.ArrayValue o) {
  buildCounterArrayValue++;
  if (buildCounterArrayValue < 3) {
    checkUnnamed4050(o.values!);
  }
  buildCounterArrayValue--;
}

core.List<core.String> buildUnnamed4051() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4051(core.List<core.String> o) {
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

core.int buildCounterBatchGetDocumentsRequest = 0;
api.BatchGetDocumentsRequest buildBatchGetDocumentsRequest() {
  var o = api.BatchGetDocumentsRequest();
  buildCounterBatchGetDocumentsRequest++;
  if (buildCounterBatchGetDocumentsRequest < 3) {
    o.documents = buildUnnamed4051();
    o.mask = buildDocumentMask();
    o.newTransaction = buildTransactionOptions();
    o.readTime = 'foo';
    o.transaction = 'foo';
  }
  buildCounterBatchGetDocumentsRequest--;
  return o;
}

void checkBatchGetDocumentsRequest(api.BatchGetDocumentsRequest o) {
  buildCounterBatchGetDocumentsRequest++;
  if (buildCounterBatchGetDocumentsRequest < 3) {
    checkUnnamed4051(o.documents!);
    checkDocumentMask(o.mask! as api.DocumentMask);
    checkTransactionOptions(o.newTransaction! as api.TransactionOptions);
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchGetDocumentsRequest--;
}

core.int buildCounterBatchGetDocumentsResponse = 0;
api.BatchGetDocumentsResponse buildBatchGetDocumentsResponse() {
  var o = api.BatchGetDocumentsResponse();
  buildCounterBatchGetDocumentsResponse++;
  if (buildCounterBatchGetDocumentsResponse < 3) {
    o.found = buildDocument();
    o.missing = 'foo';
    o.readTime = 'foo';
    o.transaction = 'foo';
  }
  buildCounterBatchGetDocumentsResponse--;
  return o;
}

void checkBatchGetDocumentsResponse(api.BatchGetDocumentsResponse o) {
  buildCounterBatchGetDocumentsResponse++;
  if (buildCounterBatchGetDocumentsResponse < 3) {
    checkDocument(o.found! as api.Document);
    unittest.expect(
      o.missing!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchGetDocumentsResponse--;
}

core.Map<core.String, core.String> buildUnnamed4052() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4052(core.Map<core.String, core.String> o) {
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

core.List<api.Write> buildUnnamed4053() {
  var o = <api.Write>[];
  o.add(buildWrite());
  o.add(buildWrite());
  return o;
}

void checkUnnamed4053(core.List<api.Write> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWrite(o[0] as api.Write);
  checkWrite(o[1] as api.Write);
}

core.int buildCounterBatchWriteRequest = 0;
api.BatchWriteRequest buildBatchWriteRequest() {
  var o = api.BatchWriteRequest();
  buildCounterBatchWriteRequest++;
  if (buildCounterBatchWriteRequest < 3) {
    o.labels = buildUnnamed4052();
    o.writes = buildUnnamed4053();
  }
  buildCounterBatchWriteRequest--;
  return o;
}

void checkBatchWriteRequest(api.BatchWriteRequest o) {
  buildCounterBatchWriteRequest++;
  if (buildCounterBatchWriteRequest < 3) {
    checkUnnamed4052(o.labels!);
    checkUnnamed4053(o.writes!);
  }
  buildCounterBatchWriteRequest--;
}

core.List<api.Status> buildUnnamed4054() {
  var o = <api.Status>[];
  o.add(buildStatus());
  o.add(buildStatus());
  return o;
}

void checkUnnamed4054(core.List<api.Status> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStatus(o[0] as api.Status);
  checkStatus(o[1] as api.Status);
}

core.List<api.WriteResult> buildUnnamed4055() {
  var o = <api.WriteResult>[];
  o.add(buildWriteResult());
  o.add(buildWriteResult());
  return o;
}

void checkUnnamed4055(core.List<api.WriteResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWriteResult(o[0] as api.WriteResult);
  checkWriteResult(o[1] as api.WriteResult);
}

core.int buildCounterBatchWriteResponse = 0;
api.BatchWriteResponse buildBatchWriteResponse() {
  var o = api.BatchWriteResponse();
  buildCounterBatchWriteResponse++;
  if (buildCounterBatchWriteResponse < 3) {
    o.status = buildUnnamed4054();
    o.writeResults = buildUnnamed4055();
  }
  buildCounterBatchWriteResponse--;
  return o;
}

void checkBatchWriteResponse(api.BatchWriteResponse o) {
  buildCounterBatchWriteResponse++;
  if (buildCounterBatchWriteResponse < 3) {
    checkUnnamed4054(o.status!);
    checkUnnamed4055(o.writeResults!);
  }
  buildCounterBatchWriteResponse--;
}

core.int buildCounterBeginTransactionRequest = 0;
api.BeginTransactionRequest buildBeginTransactionRequest() {
  var o = api.BeginTransactionRequest();
  buildCounterBeginTransactionRequest++;
  if (buildCounterBeginTransactionRequest < 3) {
    o.options = buildTransactionOptions();
  }
  buildCounterBeginTransactionRequest--;
  return o;
}

void checkBeginTransactionRequest(api.BeginTransactionRequest o) {
  buildCounterBeginTransactionRequest++;
  if (buildCounterBeginTransactionRequest < 3) {
    checkTransactionOptions(o.options! as api.TransactionOptions);
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

core.int buildCounterCollectionSelector = 0;
api.CollectionSelector buildCollectionSelector() {
  var o = api.CollectionSelector();
  buildCounterCollectionSelector++;
  if (buildCounterCollectionSelector < 3) {
    o.allDescendants = true;
    o.collectionId = 'foo';
  }
  buildCounterCollectionSelector--;
  return o;
}

void checkCollectionSelector(api.CollectionSelector o) {
  buildCounterCollectionSelector++;
  if (buildCounterCollectionSelector < 3) {
    unittest.expect(o.allDescendants!, unittest.isTrue);
    unittest.expect(
      o.collectionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCollectionSelector--;
}

core.List<api.Write> buildUnnamed4056() {
  var o = <api.Write>[];
  o.add(buildWrite());
  o.add(buildWrite());
  return o;
}

void checkUnnamed4056(core.List<api.Write> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWrite(o[0] as api.Write);
  checkWrite(o[1] as api.Write);
}

core.int buildCounterCommitRequest = 0;
api.CommitRequest buildCommitRequest() {
  var o = api.CommitRequest();
  buildCounterCommitRequest++;
  if (buildCounterCommitRequest < 3) {
    o.transaction = 'foo';
    o.writes = buildUnnamed4056();
  }
  buildCounterCommitRequest--;
  return o;
}

void checkCommitRequest(api.CommitRequest o) {
  buildCounterCommitRequest++;
  if (buildCounterCommitRequest < 3) {
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
    checkUnnamed4056(o.writes!);
  }
  buildCounterCommitRequest--;
}

core.List<api.WriteResult> buildUnnamed4057() {
  var o = <api.WriteResult>[];
  o.add(buildWriteResult());
  o.add(buildWriteResult());
  return o;
}

void checkUnnamed4057(core.List<api.WriteResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWriteResult(o[0] as api.WriteResult);
  checkWriteResult(o[1] as api.WriteResult);
}

core.int buildCounterCommitResponse = 0;
api.CommitResponse buildCommitResponse() {
  var o = api.CommitResponse();
  buildCounterCommitResponse++;
  if (buildCounterCommitResponse < 3) {
    o.commitTime = 'foo';
    o.writeResults = buildUnnamed4057();
  }
  buildCounterCommitResponse--;
  return o;
}

void checkCommitResponse(api.CommitResponse o) {
  buildCounterCommitResponse++;
  if (buildCounterCommitResponse < 3) {
    unittest.expect(
      o.commitTime!,
      unittest.equals('foo'),
    );
    checkUnnamed4057(o.writeResults!);
  }
  buildCounterCommitResponse--;
}

core.List<api.Filter> buildUnnamed4058() {
  var o = <api.Filter>[];
  o.add(buildFilter());
  o.add(buildFilter());
  return o;
}

void checkUnnamed4058(core.List<api.Filter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilter(o[0] as api.Filter);
  checkFilter(o[1] as api.Filter);
}

core.int buildCounterCompositeFilter = 0;
api.CompositeFilter buildCompositeFilter() {
  var o = api.CompositeFilter();
  buildCounterCompositeFilter++;
  if (buildCounterCompositeFilter < 3) {
    o.filters = buildUnnamed4058();
    o.op = 'foo';
  }
  buildCounterCompositeFilter--;
  return o;
}

void checkCompositeFilter(api.CompositeFilter o) {
  buildCounterCompositeFilter++;
  if (buildCounterCompositeFilter < 3) {
    checkUnnamed4058(o.filters!);
    unittest.expect(
      o.op!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompositeFilter--;
}

core.List<api.Value> buildUnnamed4059() {
  var o = <api.Value>[];
  o.add(buildValue());
  o.add(buildValue());
  return o;
}

void checkUnnamed4059(core.List<api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o[0] as api.Value);
  checkValue(o[1] as api.Value);
}

core.int buildCounterCursor = 0;
api.Cursor buildCursor() {
  var o = api.Cursor();
  buildCounterCursor++;
  if (buildCounterCursor < 3) {
    o.before = true;
    o.values = buildUnnamed4059();
  }
  buildCounterCursor--;
  return o;
}

void checkCursor(api.Cursor o) {
  buildCounterCursor++;
  if (buildCounterCursor < 3) {
    unittest.expect(o.before!, unittest.isTrue);
    checkUnnamed4059(o.values!);
  }
  buildCounterCursor--;
}

core.Map<core.String, api.Value> buildUnnamed4060() {
  var o = <core.String, api.Value>{};
  o['x'] = buildValue();
  o['y'] = buildValue();
  return o;
}

void checkUnnamed4060(core.Map<core.String, api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o['x']! as api.Value);
  checkValue(o['y']! as api.Value);
}

core.int buildCounterDocument = 0;
api.Document buildDocument() {
  var o = api.Document();
  buildCounterDocument++;
  if (buildCounterDocument < 3) {
    o.createTime = 'foo';
    o.fields = buildUnnamed4060();
    o.name = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterDocument--;
  return o;
}

void checkDocument(api.Document o) {
  buildCounterDocument++;
  if (buildCounterDocument < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUnnamed4060(o.fields!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterDocument--;
}

core.List<core.int> buildUnnamed4061() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed4061(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.int> buildUnnamed4062() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed4062(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterDocumentChange = 0;
api.DocumentChange buildDocumentChange() {
  var o = api.DocumentChange();
  buildCounterDocumentChange++;
  if (buildCounterDocumentChange < 3) {
    o.document = buildDocument();
    o.removedTargetIds = buildUnnamed4061();
    o.targetIds = buildUnnamed4062();
  }
  buildCounterDocumentChange--;
  return o;
}

void checkDocumentChange(api.DocumentChange o) {
  buildCounterDocumentChange++;
  if (buildCounterDocumentChange < 3) {
    checkDocument(o.document! as api.Document);
    checkUnnamed4061(o.removedTargetIds!);
    checkUnnamed4062(o.targetIds!);
  }
  buildCounterDocumentChange--;
}

core.List<core.int> buildUnnamed4063() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed4063(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterDocumentDelete = 0;
api.DocumentDelete buildDocumentDelete() {
  var o = api.DocumentDelete();
  buildCounterDocumentDelete++;
  if (buildCounterDocumentDelete < 3) {
    o.document = 'foo';
    o.readTime = 'foo';
    o.removedTargetIds = buildUnnamed4063();
  }
  buildCounterDocumentDelete--;
  return o;
}

void checkDocumentDelete(api.DocumentDelete o) {
  buildCounterDocumentDelete++;
  if (buildCounterDocumentDelete < 3) {
    unittest.expect(
      o.document!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    checkUnnamed4063(o.removedTargetIds!);
  }
  buildCounterDocumentDelete--;
}

core.List<core.String> buildUnnamed4064() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4064(core.List<core.String> o) {
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

core.int buildCounterDocumentMask = 0;
api.DocumentMask buildDocumentMask() {
  var o = api.DocumentMask();
  buildCounterDocumentMask++;
  if (buildCounterDocumentMask < 3) {
    o.fieldPaths = buildUnnamed4064();
  }
  buildCounterDocumentMask--;
  return o;
}

void checkDocumentMask(api.DocumentMask o) {
  buildCounterDocumentMask++;
  if (buildCounterDocumentMask < 3) {
    checkUnnamed4064(o.fieldPaths!);
  }
  buildCounterDocumentMask--;
}

core.List<core.int> buildUnnamed4065() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed4065(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterDocumentRemove = 0;
api.DocumentRemove buildDocumentRemove() {
  var o = api.DocumentRemove();
  buildCounterDocumentRemove++;
  if (buildCounterDocumentRemove < 3) {
    o.document = 'foo';
    o.readTime = 'foo';
    o.removedTargetIds = buildUnnamed4065();
  }
  buildCounterDocumentRemove--;
  return o;
}

void checkDocumentRemove(api.DocumentRemove o) {
  buildCounterDocumentRemove++;
  if (buildCounterDocumentRemove < 3) {
    unittest.expect(
      o.document!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    checkUnnamed4065(o.removedTargetIds!);
  }
  buildCounterDocumentRemove--;
}

core.List<api.FieldTransform> buildUnnamed4066() {
  var o = <api.FieldTransform>[];
  o.add(buildFieldTransform());
  o.add(buildFieldTransform());
  return o;
}

void checkUnnamed4066(core.List<api.FieldTransform> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFieldTransform(o[0] as api.FieldTransform);
  checkFieldTransform(o[1] as api.FieldTransform);
}

core.int buildCounterDocumentTransform = 0;
api.DocumentTransform buildDocumentTransform() {
  var o = api.DocumentTransform();
  buildCounterDocumentTransform++;
  if (buildCounterDocumentTransform < 3) {
    o.document = 'foo';
    o.fieldTransforms = buildUnnamed4066();
  }
  buildCounterDocumentTransform--;
  return o;
}

void checkDocumentTransform(api.DocumentTransform o) {
  buildCounterDocumentTransform++;
  if (buildCounterDocumentTransform < 3) {
    unittest.expect(
      o.document!,
      unittest.equals('foo'),
    );
    checkUnnamed4066(o.fieldTransforms!);
  }
  buildCounterDocumentTransform--;
}

core.List<core.String> buildUnnamed4067() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4067(core.List<core.String> o) {
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

core.int buildCounterDocumentsTarget = 0;
api.DocumentsTarget buildDocumentsTarget() {
  var o = api.DocumentsTarget();
  buildCounterDocumentsTarget++;
  if (buildCounterDocumentsTarget < 3) {
    o.documents = buildUnnamed4067();
  }
  buildCounterDocumentsTarget--;
  return o;
}

void checkDocumentsTarget(api.DocumentsTarget o) {
  buildCounterDocumentsTarget++;
  if (buildCounterDocumentsTarget < 3) {
    checkUnnamed4067(o.documents!);
  }
  buildCounterDocumentsTarget--;
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

core.int buildCounterExistenceFilter = 0;
api.ExistenceFilter buildExistenceFilter() {
  var o = api.ExistenceFilter();
  buildCounterExistenceFilter++;
  if (buildCounterExistenceFilter < 3) {
    o.count = 42;
    o.targetId = 42;
  }
  buildCounterExistenceFilter--;
  return o;
}

void checkExistenceFilter(api.ExistenceFilter o) {
  buildCounterExistenceFilter++;
  if (buildCounterExistenceFilter < 3) {
    unittest.expect(
      o.count!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetId!,
      unittest.equals(42),
    );
  }
  buildCounterExistenceFilter--;
}

core.int buildCounterFieldFilter = 0;
api.FieldFilter buildFieldFilter() {
  var o = api.FieldFilter();
  buildCounterFieldFilter++;
  if (buildCounterFieldFilter < 3) {
    o.field = buildFieldReference();
    o.op = 'foo';
    o.value = buildValue();
  }
  buildCounterFieldFilter--;
  return o;
}

void checkFieldFilter(api.FieldFilter o) {
  buildCounterFieldFilter++;
  if (buildCounterFieldFilter < 3) {
    checkFieldReference(o.field! as api.FieldReference);
    unittest.expect(
      o.op!,
      unittest.equals('foo'),
    );
    checkValue(o.value! as api.Value);
  }
  buildCounterFieldFilter--;
}

core.int buildCounterFieldReference = 0;
api.FieldReference buildFieldReference() {
  var o = api.FieldReference();
  buildCounterFieldReference++;
  if (buildCounterFieldReference < 3) {
    o.fieldPath = 'foo';
  }
  buildCounterFieldReference--;
  return o;
}

void checkFieldReference(api.FieldReference o) {
  buildCounterFieldReference++;
  if (buildCounterFieldReference < 3) {
    unittest.expect(
      o.fieldPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterFieldReference--;
}

core.int buildCounterFieldTransform = 0;
api.FieldTransform buildFieldTransform() {
  var o = api.FieldTransform();
  buildCounterFieldTransform++;
  if (buildCounterFieldTransform < 3) {
    o.appendMissingElements = buildArrayValue();
    o.fieldPath = 'foo';
    o.increment = buildValue();
    o.maximum = buildValue();
    o.minimum = buildValue();
    o.removeAllFromArray = buildArrayValue();
    o.setToServerValue = 'foo';
  }
  buildCounterFieldTransform--;
  return o;
}

void checkFieldTransform(api.FieldTransform o) {
  buildCounterFieldTransform++;
  if (buildCounterFieldTransform < 3) {
    checkArrayValue(o.appendMissingElements! as api.ArrayValue);
    unittest.expect(
      o.fieldPath!,
      unittest.equals('foo'),
    );
    checkValue(o.increment! as api.Value);
    checkValue(o.maximum! as api.Value);
    checkValue(o.minimum! as api.Value);
    checkArrayValue(o.removeAllFromArray! as api.ArrayValue);
    unittest.expect(
      o.setToServerValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterFieldTransform--;
}

core.int buildCounterFilter = 0;
api.Filter buildFilter() {
  var o = api.Filter();
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    o.compositeFilter = buildCompositeFilter();
    o.fieldFilter = buildFieldFilter();
    o.unaryFilter = buildUnaryFilter();
  }
  buildCounterFilter--;
  return o;
}

void checkFilter(api.Filter o) {
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    checkCompositeFilter(o.compositeFilter! as api.CompositeFilter);
    checkFieldFilter(o.fieldFilter! as api.FieldFilter);
    checkUnaryFilter(o.unaryFilter! as api.UnaryFilter);
  }
  buildCounterFilter--;
}

core.List<core.String> buildUnnamed4068() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4068(core.List<core.String> o) {
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

core.int buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata = 0;
api.GoogleFirestoreAdminV1ExportDocumentsMetadata
    buildGoogleFirestoreAdminV1ExportDocumentsMetadata() {
  var o = api.GoogleFirestoreAdminV1ExportDocumentsMetadata();
  buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata++;
  if (buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata < 3) {
    o.collectionIds = buildUnnamed4068();
    o.endTime = 'foo';
    o.operationState = 'foo';
    o.outputUriPrefix = 'foo';
    o.progressBytes = buildGoogleFirestoreAdminV1Progress();
    o.progressDocuments = buildGoogleFirestoreAdminV1Progress();
    o.startTime = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata--;
  return o;
}

void checkGoogleFirestoreAdminV1ExportDocumentsMetadata(
    api.GoogleFirestoreAdminV1ExportDocumentsMetadata o) {
  buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata++;
  if (buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata < 3) {
    checkUnnamed4068(o.collectionIds!);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputUriPrefix!,
      unittest.equals('foo'),
    );
    checkGoogleFirestoreAdminV1Progress(
        o.progressBytes! as api.GoogleFirestoreAdminV1Progress);
    checkGoogleFirestoreAdminV1Progress(
        o.progressDocuments! as api.GoogleFirestoreAdminV1Progress);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ExportDocumentsMetadata--;
}

core.List<core.String> buildUnnamed4069() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4069(core.List<core.String> o) {
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

core.int buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest = 0;
api.GoogleFirestoreAdminV1ExportDocumentsRequest
    buildGoogleFirestoreAdminV1ExportDocumentsRequest() {
  var o = api.GoogleFirestoreAdminV1ExportDocumentsRequest();
  buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest++;
  if (buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest < 3) {
    o.collectionIds = buildUnnamed4069();
    o.outputUriPrefix = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest--;
  return o;
}

void checkGoogleFirestoreAdminV1ExportDocumentsRequest(
    api.GoogleFirestoreAdminV1ExportDocumentsRequest o) {
  buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest++;
  if (buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest < 3) {
    checkUnnamed4069(o.collectionIds!);
    unittest.expect(
      o.outputUriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ExportDocumentsRequest--;
}

core.int buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse = 0;
api.GoogleFirestoreAdminV1ExportDocumentsResponse
    buildGoogleFirestoreAdminV1ExportDocumentsResponse() {
  var o = api.GoogleFirestoreAdminV1ExportDocumentsResponse();
  buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse++;
  if (buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse < 3) {
    o.outputUriPrefix = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse--;
  return o;
}

void checkGoogleFirestoreAdminV1ExportDocumentsResponse(
    api.GoogleFirestoreAdminV1ExportDocumentsResponse o) {
  buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse++;
  if (buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse < 3) {
    unittest.expect(
      o.outputUriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ExportDocumentsResponse--;
}

core.int buildCounterGoogleFirestoreAdminV1Field = 0;
api.GoogleFirestoreAdminV1Field buildGoogleFirestoreAdminV1Field() {
  var o = api.GoogleFirestoreAdminV1Field();
  buildCounterGoogleFirestoreAdminV1Field++;
  if (buildCounterGoogleFirestoreAdminV1Field < 3) {
    o.indexConfig = buildGoogleFirestoreAdminV1IndexConfig();
    o.name = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1Field--;
  return o;
}

void checkGoogleFirestoreAdminV1Field(api.GoogleFirestoreAdminV1Field o) {
  buildCounterGoogleFirestoreAdminV1Field++;
  if (buildCounterGoogleFirestoreAdminV1Field < 3) {
    checkGoogleFirestoreAdminV1IndexConfig(
        o.indexConfig! as api.GoogleFirestoreAdminV1IndexConfig);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1Field--;
}

core.List<api.GoogleFirestoreAdminV1IndexConfigDelta> buildUnnamed4070() {
  var o = <api.GoogleFirestoreAdminV1IndexConfigDelta>[];
  o.add(buildGoogleFirestoreAdminV1IndexConfigDelta());
  o.add(buildGoogleFirestoreAdminV1IndexConfigDelta());
  return o;
}

void checkUnnamed4070(core.List<api.GoogleFirestoreAdminV1IndexConfigDelta> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleFirestoreAdminV1IndexConfigDelta(
      o[0] as api.GoogleFirestoreAdminV1IndexConfigDelta);
  checkGoogleFirestoreAdminV1IndexConfigDelta(
      o[1] as api.GoogleFirestoreAdminV1IndexConfigDelta);
}

core.int buildCounterGoogleFirestoreAdminV1FieldOperationMetadata = 0;
api.GoogleFirestoreAdminV1FieldOperationMetadata
    buildGoogleFirestoreAdminV1FieldOperationMetadata() {
  var o = api.GoogleFirestoreAdminV1FieldOperationMetadata();
  buildCounterGoogleFirestoreAdminV1FieldOperationMetadata++;
  if (buildCounterGoogleFirestoreAdminV1FieldOperationMetadata < 3) {
    o.endTime = 'foo';
    o.field = 'foo';
    o.indexConfigDeltas = buildUnnamed4070();
    o.progressBytes = buildGoogleFirestoreAdminV1Progress();
    o.progressDocuments = buildGoogleFirestoreAdminV1Progress();
    o.startTime = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1FieldOperationMetadata--;
  return o;
}

void checkGoogleFirestoreAdminV1FieldOperationMetadata(
    api.GoogleFirestoreAdminV1FieldOperationMetadata o) {
  buildCounterGoogleFirestoreAdminV1FieldOperationMetadata++;
  if (buildCounterGoogleFirestoreAdminV1FieldOperationMetadata < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    checkUnnamed4070(o.indexConfigDeltas!);
    checkGoogleFirestoreAdminV1Progress(
        o.progressBytes! as api.GoogleFirestoreAdminV1Progress);
    checkGoogleFirestoreAdminV1Progress(
        o.progressDocuments! as api.GoogleFirestoreAdminV1Progress);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1FieldOperationMetadata--;
}

core.List<core.String> buildUnnamed4071() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4071(core.List<core.String> o) {
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

core.int buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata = 0;
api.GoogleFirestoreAdminV1ImportDocumentsMetadata
    buildGoogleFirestoreAdminV1ImportDocumentsMetadata() {
  var o = api.GoogleFirestoreAdminV1ImportDocumentsMetadata();
  buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata++;
  if (buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata < 3) {
    o.collectionIds = buildUnnamed4071();
    o.endTime = 'foo';
    o.inputUriPrefix = 'foo';
    o.operationState = 'foo';
    o.progressBytes = buildGoogleFirestoreAdminV1Progress();
    o.progressDocuments = buildGoogleFirestoreAdminV1Progress();
    o.startTime = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata--;
  return o;
}

void checkGoogleFirestoreAdminV1ImportDocumentsMetadata(
    api.GoogleFirestoreAdminV1ImportDocumentsMetadata o) {
  buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata++;
  if (buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata < 3) {
    checkUnnamed4071(o.collectionIds!);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUriPrefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationState!,
      unittest.equals('foo'),
    );
    checkGoogleFirestoreAdminV1Progress(
        o.progressBytes! as api.GoogleFirestoreAdminV1Progress);
    checkGoogleFirestoreAdminV1Progress(
        o.progressDocuments! as api.GoogleFirestoreAdminV1Progress);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ImportDocumentsMetadata--;
}

core.List<core.String> buildUnnamed4072() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4072(core.List<core.String> o) {
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

core.int buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest = 0;
api.GoogleFirestoreAdminV1ImportDocumentsRequest
    buildGoogleFirestoreAdminV1ImportDocumentsRequest() {
  var o = api.GoogleFirestoreAdminV1ImportDocumentsRequest();
  buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest++;
  if (buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest < 3) {
    o.collectionIds = buildUnnamed4072();
    o.inputUriPrefix = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest--;
  return o;
}

void checkGoogleFirestoreAdminV1ImportDocumentsRequest(
    api.GoogleFirestoreAdminV1ImportDocumentsRequest o) {
  buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest++;
  if (buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest < 3) {
    checkUnnamed4072(o.collectionIds!);
    unittest.expect(
      o.inputUriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ImportDocumentsRequest--;
}

core.List<api.GoogleFirestoreAdminV1IndexField> buildUnnamed4073() {
  var o = <api.GoogleFirestoreAdminV1IndexField>[];
  o.add(buildGoogleFirestoreAdminV1IndexField());
  o.add(buildGoogleFirestoreAdminV1IndexField());
  return o;
}

void checkUnnamed4073(core.List<api.GoogleFirestoreAdminV1IndexField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleFirestoreAdminV1IndexField(
      o[0] as api.GoogleFirestoreAdminV1IndexField);
  checkGoogleFirestoreAdminV1IndexField(
      o[1] as api.GoogleFirestoreAdminV1IndexField);
}

core.int buildCounterGoogleFirestoreAdminV1Index = 0;
api.GoogleFirestoreAdminV1Index buildGoogleFirestoreAdminV1Index() {
  var o = api.GoogleFirestoreAdminV1Index();
  buildCounterGoogleFirestoreAdminV1Index++;
  if (buildCounterGoogleFirestoreAdminV1Index < 3) {
    o.fields = buildUnnamed4073();
    o.name = 'foo';
    o.queryScope = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1Index--;
  return o;
}

void checkGoogleFirestoreAdminV1Index(api.GoogleFirestoreAdminV1Index o) {
  buildCounterGoogleFirestoreAdminV1Index++;
  if (buildCounterGoogleFirestoreAdminV1Index < 3) {
    checkUnnamed4073(o.fields!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queryScope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1Index--;
}

core.List<api.GoogleFirestoreAdminV1Index> buildUnnamed4074() {
  var o = <api.GoogleFirestoreAdminV1Index>[];
  o.add(buildGoogleFirestoreAdminV1Index());
  o.add(buildGoogleFirestoreAdminV1Index());
  return o;
}

void checkUnnamed4074(core.List<api.GoogleFirestoreAdminV1Index> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleFirestoreAdminV1Index(o[0] as api.GoogleFirestoreAdminV1Index);
  checkGoogleFirestoreAdminV1Index(o[1] as api.GoogleFirestoreAdminV1Index);
}

core.int buildCounterGoogleFirestoreAdminV1IndexConfig = 0;
api.GoogleFirestoreAdminV1IndexConfig buildGoogleFirestoreAdminV1IndexConfig() {
  var o = api.GoogleFirestoreAdminV1IndexConfig();
  buildCounterGoogleFirestoreAdminV1IndexConfig++;
  if (buildCounterGoogleFirestoreAdminV1IndexConfig < 3) {
    o.ancestorField = 'foo';
    o.indexes = buildUnnamed4074();
    o.reverting = true;
    o.usesAncestorConfig = true;
  }
  buildCounterGoogleFirestoreAdminV1IndexConfig--;
  return o;
}

void checkGoogleFirestoreAdminV1IndexConfig(
    api.GoogleFirestoreAdminV1IndexConfig o) {
  buildCounterGoogleFirestoreAdminV1IndexConfig++;
  if (buildCounterGoogleFirestoreAdminV1IndexConfig < 3) {
    unittest.expect(
      o.ancestorField!,
      unittest.equals('foo'),
    );
    checkUnnamed4074(o.indexes!);
    unittest.expect(o.reverting!, unittest.isTrue);
    unittest.expect(o.usesAncestorConfig!, unittest.isTrue);
  }
  buildCounterGoogleFirestoreAdminV1IndexConfig--;
}

core.int buildCounterGoogleFirestoreAdminV1IndexConfigDelta = 0;
api.GoogleFirestoreAdminV1IndexConfigDelta
    buildGoogleFirestoreAdminV1IndexConfigDelta() {
  var o = api.GoogleFirestoreAdminV1IndexConfigDelta();
  buildCounterGoogleFirestoreAdminV1IndexConfigDelta++;
  if (buildCounterGoogleFirestoreAdminV1IndexConfigDelta < 3) {
    o.changeType = 'foo';
    o.index = buildGoogleFirestoreAdminV1Index();
  }
  buildCounterGoogleFirestoreAdminV1IndexConfigDelta--;
  return o;
}

void checkGoogleFirestoreAdminV1IndexConfigDelta(
    api.GoogleFirestoreAdminV1IndexConfigDelta o) {
  buildCounterGoogleFirestoreAdminV1IndexConfigDelta++;
  if (buildCounterGoogleFirestoreAdminV1IndexConfigDelta < 3) {
    unittest.expect(
      o.changeType!,
      unittest.equals('foo'),
    );
    checkGoogleFirestoreAdminV1Index(
        o.index! as api.GoogleFirestoreAdminV1Index);
  }
  buildCounterGoogleFirestoreAdminV1IndexConfigDelta--;
}

core.int buildCounterGoogleFirestoreAdminV1IndexField = 0;
api.GoogleFirestoreAdminV1IndexField buildGoogleFirestoreAdminV1IndexField() {
  var o = api.GoogleFirestoreAdminV1IndexField();
  buildCounterGoogleFirestoreAdminV1IndexField++;
  if (buildCounterGoogleFirestoreAdminV1IndexField < 3) {
    o.arrayConfig = 'foo';
    o.fieldPath = 'foo';
    o.order = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1IndexField--;
  return o;
}

void checkGoogleFirestoreAdminV1IndexField(
    api.GoogleFirestoreAdminV1IndexField o) {
  buildCounterGoogleFirestoreAdminV1IndexField++;
  if (buildCounterGoogleFirestoreAdminV1IndexField < 3) {
    unittest.expect(
      o.arrayConfig!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.order!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1IndexField--;
}

core.int buildCounterGoogleFirestoreAdminV1IndexOperationMetadata = 0;
api.GoogleFirestoreAdminV1IndexOperationMetadata
    buildGoogleFirestoreAdminV1IndexOperationMetadata() {
  var o = api.GoogleFirestoreAdminV1IndexOperationMetadata();
  buildCounterGoogleFirestoreAdminV1IndexOperationMetadata++;
  if (buildCounterGoogleFirestoreAdminV1IndexOperationMetadata < 3) {
    o.endTime = 'foo';
    o.index = 'foo';
    o.progressBytes = buildGoogleFirestoreAdminV1Progress();
    o.progressDocuments = buildGoogleFirestoreAdminV1Progress();
    o.startTime = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1IndexOperationMetadata--;
  return o;
}

void checkGoogleFirestoreAdminV1IndexOperationMetadata(
    api.GoogleFirestoreAdminV1IndexOperationMetadata o) {
  buildCounterGoogleFirestoreAdminV1IndexOperationMetadata++;
  if (buildCounterGoogleFirestoreAdminV1IndexOperationMetadata < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.index!,
      unittest.equals('foo'),
    );
    checkGoogleFirestoreAdminV1Progress(
        o.progressBytes! as api.GoogleFirestoreAdminV1Progress);
    checkGoogleFirestoreAdminV1Progress(
        o.progressDocuments! as api.GoogleFirestoreAdminV1Progress);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1IndexOperationMetadata--;
}

core.List<api.GoogleFirestoreAdminV1Field> buildUnnamed4075() {
  var o = <api.GoogleFirestoreAdminV1Field>[];
  o.add(buildGoogleFirestoreAdminV1Field());
  o.add(buildGoogleFirestoreAdminV1Field());
  return o;
}

void checkUnnamed4075(core.List<api.GoogleFirestoreAdminV1Field> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleFirestoreAdminV1Field(o[0] as api.GoogleFirestoreAdminV1Field);
  checkGoogleFirestoreAdminV1Field(o[1] as api.GoogleFirestoreAdminV1Field);
}

core.int buildCounterGoogleFirestoreAdminV1ListFieldsResponse = 0;
api.GoogleFirestoreAdminV1ListFieldsResponse
    buildGoogleFirestoreAdminV1ListFieldsResponse() {
  var o = api.GoogleFirestoreAdminV1ListFieldsResponse();
  buildCounterGoogleFirestoreAdminV1ListFieldsResponse++;
  if (buildCounterGoogleFirestoreAdminV1ListFieldsResponse < 3) {
    o.fields = buildUnnamed4075();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ListFieldsResponse--;
  return o;
}

void checkGoogleFirestoreAdminV1ListFieldsResponse(
    api.GoogleFirestoreAdminV1ListFieldsResponse o) {
  buildCounterGoogleFirestoreAdminV1ListFieldsResponse++;
  if (buildCounterGoogleFirestoreAdminV1ListFieldsResponse < 3) {
    checkUnnamed4075(o.fields!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ListFieldsResponse--;
}

core.List<api.GoogleFirestoreAdminV1Index> buildUnnamed4076() {
  var o = <api.GoogleFirestoreAdminV1Index>[];
  o.add(buildGoogleFirestoreAdminV1Index());
  o.add(buildGoogleFirestoreAdminV1Index());
  return o;
}

void checkUnnamed4076(core.List<api.GoogleFirestoreAdminV1Index> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleFirestoreAdminV1Index(o[0] as api.GoogleFirestoreAdminV1Index);
  checkGoogleFirestoreAdminV1Index(o[1] as api.GoogleFirestoreAdminV1Index);
}

core.int buildCounterGoogleFirestoreAdminV1ListIndexesResponse = 0;
api.GoogleFirestoreAdminV1ListIndexesResponse
    buildGoogleFirestoreAdminV1ListIndexesResponse() {
  var o = api.GoogleFirestoreAdminV1ListIndexesResponse();
  buildCounterGoogleFirestoreAdminV1ListIndexesResponse++;
  if (buildCounterGoogleFirestoreAdminV1ListIndexesResponse < 3) {
    o.indexes = buildUnnamed4076();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1ListIndexesResponse--;
  return o;
}

void checkGoogleFirestoreAdminV1ListIndexesResponse(
    api.GoogleFirestoreAdminV1ListIndexesResponse o) {
  buildCounterGoogleFirestoreAdminV1ListIndexesResponse++;
  if (buildCounterGoogleFirestoreAdminV1ListIndexesResponse < 3) {
    checkUnnamed4076(o.indexes!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1ListIndexesResponse--;
}

core.int buildCounterGoogleFirestoreAdminV1LocationMetadata = 0;
api.GoogleFirestoreAdminV1LocationMetadata
    buildGoogleFirestoreAdminV1LocationMetadata() {
  var o = api.GoogleFirestoreAdminV1LocationMetadata();
  buildCounterGoogleFirestoreAdminV1LocationMetadata++;
  if (buildCounterGoogleFirestoreAdminV1LocationMetadata < 3) {}
  buildCounterGoogleFirestoreAdminV1LocationMetadata--;
  return o;
}

void checkGoogleFirestoreAdminV1LocationMetadata(
    api.GoogleFirestoreAdminV1LocationMetadata o) {
  buildCounterGoogleFirestoreAdminV1LocationMetadata++;
  if (buildCounterGoogleFirestoreAdminV1LocationMetadata < 3) {}
  buildCounterGoogleFirestoreAdminV1LocationMetadata--;
}

core.int buildCounterGoogleFirestoreAdminV1Progress = 0;
api.GoogleFirestoreAdminV1Progress buildGoogleFirestoreAdminV1Progress() {
  var o = api.GoogleFirestoreAdminV1Progress();
  buildCounterGoogleFirestoreAdminV1Progress++;
  if (buildCounterGoogleFirestoreAdminV1Progress < 3) {
    o.completedWork = 'foo';
    o.estimatedWork = 'foo';
  }
  buildCounterGoogleFirestoreAdminV1Progress--;
  return o;
}

void checkGoogleFirestoreAdminV1Progress(api.GoogleFirestoreAdminV1Progress o) {
  buildCounterGoogleFirestoreAdminV1Progress++;
  if (buildCounterGoogleFirestoreAdminV1Progress < 3) {
    unittest.expect(
      o.completedWork!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.estimatedWork!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleFirestoreAdminV1Progress--;
}

core.int buildCounterGoogleLongrunningCancelOperationRequest = 0;
api.GoogleLongrunningCancelOperationRequest
    buildGoogleLongrunningCancelOperationRequest() {
  var o = api.GoogleLongrunningCancelOperationRequest();
  buildCounterGoogleLongrunningCancelOperationRequest++;
  if (buildCounterGoogleLongrunningCancelOperationRequest < 3) {}
  buildCounterGoogleLongrunningCancelOperationRequest--;
  return o;
}

void checkGoogleLongrunningCancelOperationRequest(
    api.GoogleLongrunningCancelOperationRequest o) {
  buildCounterGoogleLongrunningCancelOperationRequest++;
  if (buildCounterGoogleLongrunningCancelOperationRequest < 3) {}
  buildCounterGoogleLongrunningCancelOperationRequest--;
}

core.List<api.GoogleLongrunningOperation> buildUnnamed4077() {
  var o = <api.GoogleLongrunningOperation>[];
  o.add(buildGoogleLongrunningOperation());
  o.add(buildGoogleLongrunningOperation());
  return o;
}

void checkUnnamed4077(core.List<api.GoogleLongrunningOperation> o) {
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
    o.operations = buildUnnamed4077();
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
    checkUnnamed4077(o.operations!);
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed4078() {
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

void checkUnnamed4078(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed4079() {
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

void checkUnnamed4079(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed4078();
    o.name = 'foo';
    o.response = buildUnnamed4079();
  }
  buildCounterGoogleLongrunningOperation--;
  return o;
}

void checkGoogleLongrunningOperation(api.GoogleLongrunningOperation o) {
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed4078(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4079(o.response!);
  }
  buildCounterGoogleLongrunningOperation--;
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

core.int buildCounterListCollectionIdsRequest = 0;
api.ListCollectionIdsRequest buildListCollectionIdsRequest() {
  var o = api.ListCollectionIdsRequest();
  buildCounterListCollectionIdsRequest++;
  if (buildCounterListCollectionIdsRequest < 3) {
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterListCollectionIdsRequest--;
  return o;
}

void checkListCollectionIdsRequest(api.ListCollectionIdsRequest o) {
  buildCounterListCollectionIdsRequest++;
  if (buildCounterListCollectionIdsRequest < 3) {
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCollectionIdsRequest--;
}

core.List<core.String> buildUnnamed4080() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4080(core.List<core.String> o) {
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

core.int buildCounterListCollectionIdsResponse = 0;
api.ListCollectionIdsResponse buildListCollectionIdsResponse() {
  var o = api.ListCollectionIdsResponse();
  buildCounterListCollectionIdsResponse++;
  if (buildCounterListCollectionIdsResponse < 3) {
    o.collectionIds = buildUnnamed4080();
    o.nextPageToken = 'foo';
  }
  buildCounterListCollectionIdsResponse--;
  return o;
}

void checkListCollectionIdsResponse(api.ListCollectionIdsResponse o) {
  buildCounterListCollectionIdsResponse++;
  if (buildCounterListCollectionIdsResponse < 3) {
    checkUnnamed4080(o.collectionIds!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCollectionIdsResponse--;
}

core.List<api.Document> buildUnnamed4081() {
  var o = <api.Document>[];
  o.add(buildDocument());
  o.add(buildDocument());
  return o;
}

void checkUnnamed4081(core.List<api.Document> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDocument(o[0] as api.Document);
  checkDocument(o[1] as api.Document);
}

core.int buildCounterListDocumentsResponse = 0;
api.ListDocumentsResponse buildListDocumentsResponse() {
  var o = api.ListDocumentsResponse();
  buildCounterListDocumentsResponse++;
  if (buildCounterListDocumentsResponse < 3) {
    o.documents = buildUnnamed4081();
    o.nextPageToken = 'foo';
  }
  buildCounterListDocumentsResponse--;
  return o;
}

void checkListDocumentsResponse(api.ListDocumentsResponse o) {
  buildCounterListDocumentsResponse++;
  if (buildCounterListDocumentsResponse < 3) {
    checkUnnamed4081(o.documents!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDocumentsResponse--;
}

core.List<api.Location> buildUnnamed4082() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed4082(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed4082();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed4082(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.Map<core.String, core.String> buildUnnamed4083() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4083(core.Map<core.String, core.String> o) {
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

core.int buildCounterListenRequest = 0;
api.ListenRequest buildListenRequest() {
  var o = api.ListenRequest();
  buildCounterListenRequest++;
  if (buildCounterListenRequest < 3) {
    o.addTarget = buildTarget();
    o.labels = buildUnnamed4083();
    o.removeTarget = 42;
  }
  buildCounterListenRequest--;
  return o;
}

void checkListenRequest(api.ListenRequest o) {
  buildCounterListenRequest++;
  if (buildCounterListenRequest < 3) {
    checkTarget(o.addTarget! as api.Target);
    checkUnnamed4083(o.labels!);
    unittest.expect(
      o.removeTarget!,
      unittest.equals(42),
    );
  }
  buildCounterListenRequest--;
}

core.int buildCounterListenResponse = 0;
api.ListenResponse buildListenResponse() {
  var o = api.ListenResponse();
  buildCounterListenResponse++;
  if (buildCounterListenResponse < 3) {
    o.documentChange = buildDocumentChange();
    o.documentDelete = buildDocumentDelete();
    o.documentRemove = buildDocumentRemove();
    o.filter = buildExistenceFilter();
    o.targetChange = buildTargetChange();
  }
  buildCounterListenResponse--;
  return o;
}

void checkListenResponse(api.ListenResponse o) {
  buildCounterListenResponse++;
  if (buildCounterListenResponse < 3) {
    checkDocumentChange(o.documentChange! as api.DocumentChange);
    checkDocumentDelete(o.documentDelete! as api.DocumentDelete);
    checkDocumentRemove(o.documentRemove! as api.DocumentRemove);
    checkExistenceFilter(o.filter! as api.ExistenceFilter);
    checkTargetChange(o.targetChange! as api.TargetChange);
  }
  buildCounterListenResponse--;
}

core.Map<core.String, core.String> buildUnnamed4084() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4084(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed4085() {
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

void checkUnnamed4085(core.Map<core.String, core.Object> o) {
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

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.displayName = 'foo';
    o.labels = buildUnnamed4084();
    o.locationId = 'foo';
    o.metadata = buildUnnamed4085();
    o.name = 'foo';
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4084(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed4085(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.Map<core.String, api.Value> buildUnnamed4086() {
  var o = <core.String, api.Value>{};
  o['x'] = buildValue();
  o['y'] = buildValue();
  return o;
}

void checkUnnamed4086(core.Map<core.String, api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o['x']! as api.Value);
  checkValue(o['y']! as api.Value);
}

core.int buildCounterMapValue = 0;
api.MapValue buildMapValue() {
  var o = api.MapValue();
  buildCounterMapValue++;
  if (buildCounterMapValue < 3) {
    o.fields = buildUnnamed4086();
  }
  buildCounterMapValue--;
  return o;
}

void checkMapValue(api.MapValue o) {
  buildCounterMapValue++;
  if (buildCounterMapValue < 3) {
    checkUnnamed4086(o.fields!);
  }
  buildCounterMapValue--;
}

core.int buildCounterOrder = 0;
api.Order buildOrder() {
  var o = api.Order();
  buildCounterOrder++;
  if (buildCounterOrder < 3) {
    o.direction = 'foo';
    o.field = buildFieldReference();
  }
  buildCounterOrder--;
  return o;
}

void checkOrder(api.Order o) {
  buildCounterOrder++;
  if (buildCounterOrder < 3) {
    unittest.expect(
      o.direction!,
      unittest.equals('foo'),
    );
    checkFieldReference(o.field! as api.FieldReference);
  }
  buildCounterOrder--;
}

core.int buildCounterPartitionQueryRequest = 0;
api.PartitionQueryRequest buildPartitionQueryRequest() {
  var o = api.PartitionQueryRequest();
  buildCounterPartitionQueryRequest++;
  if (buildCounterPartitionQueryRequest < 3) {
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.partitionCount = 'foo';
    o.structuredQuery = buildStructuredQuery();
  }
  buildCounterPartitionQueryRequest--;
  return o;
}

void checkPartitionQueryRequest(api.PartitionQueryRequest o) {
  buildCounterPartitionQueryRequest++;
  if (buildCounterPartitionQueryRequest < 3) {
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partitionCount!,
      unittest.equals('foo'),
    );
    checkStructuredQuery(o.structuredQuery! as api.StructuredQuery);
  }
  buildCounterPartitionQueryRequest--;
}

core.List<api.Cursor> buildUnnamed4087() {
  var o = <api.Cursor>[];
  o.add(buildCursor());
  o.add(buildCursor());
  return o;
}

void checkUnnamed4087(core.List<api.Cursor> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCursor(o[0] as api.Cursor);
  checkCursor(o[1] as api.Cursor);
}

core.int buildCounterPartitionQueryResponse = 0;
api.PartitionQueryResponse buildPartitionQueryResponse() {
  var o = api.PartitionQueryResponse();
  buildCounterPartitionQueryResponse++;
  if (buildCounterPartitionQueryResponse < 3) {
    o.nextPageToken = 'foo';
    o.partitions = buildUnnamed4087();
  }
  buildCounterPartitionQueryResponse--;
  return o;
}

void checkPartitionQueryResponse(api.PartitionQueryResponse o) {
  buildCounterPartitionQueryResponse++;
  if (buildCounterPartitionQueryResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4087(o.partitions!);
  }
  buildCounterPartitionQueryResponse--;
}

core.int buildCounterPrecondition = 0;
api.Precondition buildPrecondition() {
  var o = api.Precondition();
  buildCounterPrecondition++;
  if (buildCounterPrecondition < 3) {
    o.exists = true;
    o.updateTime = 'foo';
  }
  buildCounterPrecondition--;
  return o;
}

void checkPrecondition(api.Precondition o) {
  buildCounterPrecondition++;
  if (buildCounterPrecondition < 3) {
    unittest.expect(o.exists!, unittest.isTrue);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrecondition--;
}

core.List<api.FieldReference> buildUnnamed4088() {
  var o = <api.FieldReference>[];
  o.add(buildFieldReference());
  o.add(buildFieldReference());
  return o;
}

void checkUnnamed4088(core.List<api.FieldReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFieldReference(o[0] as api.FieldReference);
  checkFieldReference(o[1] as api.FieldReference);
}

core.int buildCounterProjection = 0;
api.Projection buildProjection() {
  var o = api.Projection();
  buildCounterProjection++;
  if (buildCounterProjection < 3) {
    o.fields = buildUnnamed4088();
  }
  buildCounterProjection--;
  return o;
}

void checkProjection(api.Projection o) {
  buildCounterProjection++;
  if (buildCounterProjection < 3) {
    checkUnnamed4088(o.fields!);
  }
  buildCounterProjection--;
}

core.int buildCounterQueryTarget = 0;
api.QueryTarget buildQueryTarget() {
  var o = api.QueryTarget();
  buildCounterQueryTarget++;
  if (buildCounterQueryTarget < 3) {
    o.parent = 'foo';
    o.structuredQuery = buildStructuredQuery();
  }
  buildCounterQueryTarget--;
  return o;
}

void checkQueryTarget(api.QueryTarget o) {
  buildCounterQueryTarget++;
  if (buildCounterQueryTarget < 3) {
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    checkStructuredQuery(o.structuredQuery! as api.StructuredQuery);
  }
  buildCounterQueryTarget--;
}

core.int buildCounterReadOnly = 0;
api.ReadOnly buildReadOnly() {
  var o = api.ReadOnly();
  buildCounterReadOnly++;
  if (buildCounterReadOnly < 3) {
    o.readTime = 'foo';
  }
  buildCounterReadOnly--;
  return o;
}

void checkReadOnly(api.ReadOnly o) {
  buildCounterReadOnly++;
  if (buildCounterReadOnly < 3) {
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterReadOnly--;
}

core.int buildCounterReadWrite = 0;
api.ReadWrite buildReadWrite() {
  var o = api.ReadWrite();
  buildCounterReadWrite++;
  if (buildCounterReadWrite < 3) {
    o.retryTransaction = 'foo';
  }
  buildCounterReadWrite--;
  return o;
}

void checkReadWrite(api.ReadWrite o) {
  buildCounterReadWrite++;
  if (buildCounterReadWrite < 3) {
    unittest.expect(
      o.retryTransaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterReadWrite--;
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

core.int buildCounterRunQueryRequest = 0;
api.RunQueryRequest buildRunQueryRequest() {
  var o = api.RunQueryRequest();
  buildCounterRunQueryRequest++;
  if (buildCounterRunQueryRequest < 3) {
    o.newTransaction = buildTransactionOptions();
    o.readTime = 'foo';
    o.structuredQuery = buildStructuredQuery();
    o.transaction = 'foo';
  }
  buildCounterRunQueryRequest--;
  return o;
}

void checkRunQueryRequest(api.RunQueryRequest o) {
  buildCounterRunQueryRequest++;
  if (buildCounterRunQueryRequest < 3) {
    checkTransactionOptions(o.newTransaction! as api.TransactionOptions);
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    checkStructuredQuery(o.structuredQuery! as api.StructuredQuery);
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterRunQueryRequest--;
}

core.int buildCounterRunQueryResponse = 0;
api.RunQueryResponse buildRunQueryResponse() {
  var o = api.RunQueryResponse();
  buildCounterRunQueryResponse++;
  if (buildCounterRunQueryResponse < 3) {
    o.document = buildDocument();
    o.readTime = 'foo';
    o.skippedResults = 42;
    o.transaction = 'foo';
  }
  buildCounterRunQueryResponse--;
  return o;
}

void checkRunQueryResponse(api.RunQueryResponse o) {
  buildCounterRunQueryResponse++;
  if (buildCounterRunQueryResponse < 3) {
    checkDocument(o.document! as api.Document);
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skippedResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.transaction!,
      unittest.equals('foo'),
    );
  }
  buildCounterRunQueryResponse--;
}

core.Map<core.String, core.Object> buildUnnamed4089() {
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

void checkUnnamed4089(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o['x']!) as core.Map;
  unittest.expect(casted7, unittest.hasLength(3));
  unittest.expect(
    casted7['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted7['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted7['string'],
    unittest.equals('foo'),
  );
  var casted8 = (o['y']!) as core.Map;
  unittest.expect(casted8, unittest.hasLength(3));
  unittest.expect(
    casted8['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted8['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted8['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed4090() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed4089());
  o.add(buildUnnamed4089());
  return o;
}

void checkUnnamed4090(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed4089(o[0]);
  checkUnnamed4089(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed4090();
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
    checkUnnamed4090(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<api.CollectionSelector> buildUnnamed4091() {
  var o = <api.CollectionSelector>[];
  o.add(buildCollectionSelector());
  o.add(buildCollectionSelector());
  return o;
}

void checkUnnamed4091(core.List<api.CollectionSelector> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCollectionSelector(o[0] as api.CollectionSelector);
  checkCollectionSelector(o[1] as api.CollectionSelector);
}

core.List<api.Order> buildUnnamed4092() {
  var o = <api.Order>[];
  o.add(buildOrder());
  o.add(buildOrder());
  return o;
}

void checkUnnamed4092(core.List<api.Order> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrder(o[0] as api.Order);
  checkOrder(o[1] as api.Order);
}

core.int buildCounterStructuredQuery = 0;
api.StructuredQuery buildStructuredQuery() {
  var o = api.StructuredQuery();
  buildCounterStructuredQuery++;
  if (buildCounterStructuredQuery < 3) {
    o.endAt = buildCursor();
    o.from = buildUnnamed4091();
    o.limit = 42;
    o.offset = 42;
    o.orderBy = buildUnnamed4092();
    o.select = buildProjection();
    o.startAt = buildCursor();
    o.where = buildFilter();
  }
  buildCounterStructuredQuery--;
  return o;
}

void checkStructuredQuery(api.StructuredQuery o) {
  buildCounterStructuredQuery++;
  if (buildCounterStructuredQuery < 3) {
    checkCursor(o.endAt! as api.Cursor);
    checkUnnamed4091(o.from!);
    unittest.expect(
      o.limit!,
      unittest.equals(42),
    );
    unittest.expect(
      o.offset!,
      unittest.equals(42),
    );
    checkUnnamed4092(o.orderBy!);
    checkProjection(o.select! as api.Projection);
    checkCursor(o.startAt! as api.Cursor);
    checkFilter(o.where! as api.Filter);
  }
  buildCounterStructuredQuery--;
}

core.int buildCounterTarget = 0;
api.Target buildTarget() {
  var o = api.Target();
  buildCounterTarget++;
  if (buildCounterTarget < 3) {
    o.documents = buildDocumentsTarget();
    o.once = true;
    o.query = buildQueryTarget();
    o.readTime = 'foo';
    o.resumeToken = 'foo';
    o.targetId = 42;
  }
  buildCounterTarget--;
  return o;
}

void checkTarget(api.Target o) {
  buildCounterTarget++;
  if (buildCounterTarget < 3) {
    checkDocumentsTarget(o.documents! as api.DocumentsTarget);
    unittest.expect(o.once!, unittest.isTrue);
    checkQueryTarget(o.query! as api.QueryTarget);
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resumeToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetId!,
      unittest.equals(42),
    );
  }
  buildCounterTarget--;
}

core.List<core.int> buildUnnamed4093() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed4093(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.int buildCounterTargetChange = 0;
api.TargetChange buildTargetChange() {
  var o = api.TargetChange();
  buildCounterTargetChange++;
  if (buildCounterTargetChange < 3) {
    o.cause = buildStatus();
    o.readTime = 'foo';
    o.resumeToken = 'foo';
    o.targetChangeType = 'foo';
    o.targetIds = buildUnnamed4093();
  }
  buildCounterTargetChange--;
  return o;
}

void checkTargetChange(api.TargetChange o) {
  buildCounterTargetChange++;
  if (buildCounterTargetChange < 3) {
    checkStatus(o.cause! as api.Status);
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resumeToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetChangeType!,
      unittest.equals('foo'),
    );
    checkUnnamed4093(o.targetIds!);
  }
  buildCounterTargetChange--;
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

core.int buildCounterUnaryFilter = 0;
api.UnaryFilter buildUnaryFilter() {
  var o = api.UnaryFilter();
  buildCounterUnaryFilter++;
  if (buildCounterUnaryFilter < 3) {
    o.field = buildFieldReference();
    o.op = 'foo';
  }
  buildCounterUnaryFilter--;
  return o;
}

void checkUnaryFilter(api.UnaryFilter o) {
  buildCounterUnaryFilter++;
  if (buildCounterUnaryFilter < 3) {
    checkFieldReference(o.field! as api.FieldReference);
    unittest.expect(
      o.op!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnaryFilter--;
}

core.int buildCounterValue = 0;
api.Value buildValue() {
  var o = api.Value();
  buildCounterValue++;
  if (buildCounterValue < 3) {
    o.arrayValue = buildArrayValue();
    o.booleanValue = true;
    o.bytesValue = 'foo';
    o.doubleValue = 42.0;
    o.geoPointValue = buildLatLng();
    o.integerValue = 'foo';
    o.mapValue = buildMapValue();
    o.nullValue = 'foo';
    o.referenceValue = 'foo';
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
    unittest.expect(o.booleanValue!, unittest.isTrue);
    unittest.expect(
      o.bytesValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.doubleValue!,
      unittest.equals(42.0),
    );
    checkLatLng(o.geoPointValue! as api.LatLng);
    unittest.expect(
      o.integerValue!,
      unittest.equals('foo'),
    );
    checkMapValue(o.mapValue! as api.MapValue);
    unittest.expect(
      o.nullValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referenceValue!,
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

core.List<api.FieldTransform> buildUnnamed4094() {
  var o = <api.FieldTransform>[];
  o.add(buildFieldTransform());
  o.add(buildFieldTransform());
  return o;
}

void checkUnnamed4094(core.List<api.FieldTransform> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFieldTransform(o[0] as api.FieldTransform);
  checkFieldTransform(o[1] as api.FieldTransform);
}

core.int buildCounterWrite = 0;
api.Write buildWrite() {
  var o = api.Write();
  buildCounterWrite++;
  if (buildCounterWrite < 3) {
    o.currentDocument = buildPrecondition();
    o.delete = 'foo';
    o.transform = buildDocumentTransform();
    o.update = buildDocument();
    o.updateMask = buildDocumentMask();
    o.updateTransforms = buildUnnamed4094();
  }
  buildCounterWrite--;
  return o;
}

void checkWrite(api.Write o) {
  buildCounterWrite++;
  if (buildCounterWrite < 3) {
    checkPrecondition(o.currentDocument! as api.Precondition);
    unittest.expect(
      o.delete!,
      unittest.equals('foo'),
    );
    checkDocumentTransform(o.transform! as api.DocumentTransform);
    checkDocument(o.update! as api.Document);
    checkDocumentMask(o.updateMask! as api.DocumentMask);
    checkUnnamed4094(o.updateTransforms!);
  }
  buildCounterWrite--;
}

core.Map<core.String, core.String> buildUnnamed4095() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4095(core.Map<core.String, core.String> o) {
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

core.List<api.Write> buildUnnamed4096() {
  var o = <api.Write>[];
  o.add(buildWrite());
  o.add(buildWrite());
  return o;
}

void checkUnnamed4096(core.List<api.Write> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWrite(o[0] as api.Write);
  checkWrite(o[1] as api.Write);
}

core.int buildCounterWriteRequest = 0;
api.WriteRequest buildWriteRequest() {
  var o = api.WriteRequest();
  buildCounterWriteRequest++;
  if (buildCounterWriteRequest < 3) {
    o.labels = buildUnnamed4095();
    o.streamId = 'foo';
    o.streamToken = 'foo';
    o.writes = buildUnnamed4096();
  }
  buildCounterWriteRequest--;
  return o;
}

void checkWriteRequest(api.WriteRequest o) {
  buildCounterWriteRequest++;
  if (buildCounterWriteRequest < 3) {
    checkUnnamed4095(o.labels!);
    unittest.expect(
      o.streamId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.streamToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4096(o.writes!);
  }
  buildCounterWriteRequest--;
}

core.List<api.WriteResult> buildUnnamed4097() {
  var o = <api.WriteResult>[];
  o.add(buildWriteResult());
  o.add(buildWriteResult());
  return o;
}

void checkUnnamed4097(core.List<api.WriteResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWriteResult(o[0] as api.WriteResult);
  checkWriteResult(o[1] as api.WriteResult);
}

core.int buildCounterWriteResponse = 0;
api.WriteResponse buildWriteResponse() {
  var o = api.WriteResponse();
  buildCounterWriteResponse++;
  if (buildCounterWriteResponse < 3) {
    o.commitTime = 'foo';
    o.streamId = 'foo';
    o.streamToken = 'foo';
    o.writeResults = buildUnnamed4097();
  }
  buildCounterWriteResponse--;
  return o;
}

void checkWriteResponse(api.WriteResponse o) {
  buildCounterWriteResponse++;
  if (buildCounterWriteResponse < 3) {
    unittest.expect(
      o.commitTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.streamId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.streamToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4097(o.writeResults!);
  }
  buildCounterWriteResponse--;
}

core.List<api.Value> buildUnnamed4098() {
  var o = <api.Value>[];
  o.add(buildValue());
  o.add(buildValue());
  return o;
}

void checkUnnamed4098(core.List<api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o[0] as api.Value);
  checkValue(o[1] as api.Value);
}

core.int buildCounterWriteResult = 0;
api.WriteResult buildWriteResult() {
  var o = api.WriteResult();
  buildCounterWriteResult++;
  if (buildCounterWriteResult < 3) {
    o.transformResults = buildUnnamed4098();
    o.updateTime = 'foo';
  }
  buildCounterWriteResult--;
  return o;
}

void checkWriteResult(api.WriteResult o) {
  buildCounterWriteResult++;
  if (buildCounterWriteResult < 3) {
    checkUnnamed4098(o.transformResults!);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterWriteResult--;
}

core.List<core.String> buildUnnamed4099() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4099(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4100() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4100(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4101() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4101(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4102() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4102(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4103() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4103(core.List<core.String> o) {
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

void main() {
  unittest.group('obj-schema-ArrayValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArrayValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ArrayValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArrayValue(od as api.ArrayValue);
    });
  });

  unittest.group('obj-schema-BatchGetDocumentsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetDocumentsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetDocumentsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetDocumentsRequest(od as api.BatchGetDocumentsRequest);
    });
  });

  unittest.group('obj-schema-BatchGetDocumentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetDocumentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetDocumentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetDocumentsResponse(od as api.BatchGetDocumentsResponse);
    });
  });

  unittest.group('obj-schema-BatchWriteRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchWriteRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchWriteRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchWriteRequest(od as api.BatchWriteRequest);
    });
  });

  unittest.group('obj-schema-BatchWriteResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchWriteResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchWriteResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchWriteResponse(od as api.BatchWriteResponse);
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

  unittest.group('obj-schema-CollectionSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCollectionSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CollectionSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCollectionSelector(od as api.CollectionSelector);
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

  unittest.group('obj-schema-Cursor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCursor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Cursor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCursor(od as api.Cursor);
    });
  });

  unittest.group('obj-schema-Document', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocument();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Document.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDocument(od as api.Document);
    });
  });

  unittest.group('obj-schema-DocumentChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocumentChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DocumentChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDocumentChange(od as api.DocumentChange);
    });
  });

  unittest.group('obj-schema-DocumentDelete', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocumentDelete();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DocumentDelete.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDocumentDelete(od as api.DocumentDelete);
    });
  });

  unittest.group('obj-schema-DocumentMask', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocumentMask();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DocumentMask.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDocumentMask(od as api.DocumentMask);
    });
  });

  unittest.group('obj-schema-DocumentRemove', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocumentRemove();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DocumentRemove.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDocumentRemove(od as api.DocumentRemove);
    });
  });

  unittest.group('obj-schema-DocumentTransform', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocumentTransform();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DocumentTransform.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDocumentTransform(od as api.DocumentTransform);
    });
  });

  unittest.group('obj-schema-DocumentsTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDocumentsTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DocumentsTarget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDocumentsTarget(od as api.DocumentsTarget);
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

  unittest.group('obj-schema-ExistenceFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExistenceFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExistenceFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExistenceFilter(od as api.ExistenceFilter);
    });
  });

  unittest.group('obj-schema-FieldFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFieldFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FieldFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFieldFilter(od as api.FieldFilter);
    });
  });

  unittest.group('obj-schema-FieldReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFieldReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FieldReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFieldReference(od as api.FieldReference);
    });
  });

  unittest.group('obj-schema-FieldTransform', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFieldTransform();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FieldTransform.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFieldTransform(od as api.FieldTransform);
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

  unittest.group('obj-schema-GoogleFirestoreAdminV1ExportDocumentsMetadata',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ExportDocumentsMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ExportDocumentsMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ExportDocumentsMetadata(
          od as api.GoogleFirestoreAdminV1ExportDocumentsMetadata);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1ExportDocumentsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ExportDocumentsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ExportDocumentsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ExportDocumentsRequest(
          od as api.GoogleFirestoreAdminV1ExportDocumentsRequest);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1ExportDocumentsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ExportDocumentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ExportDocumentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ExportDocumentsResponse(
          od as api.GoogleFirestoreAdminV1ExportDocumentsResponse);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1Field', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1Field();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1Field.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1Field(od as api.GoogleFirestoreAdminV1Field);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1FieldOperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1FieldOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1FieldOperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1FieldOperationMetadata(
          od as api.GoogleFirestoreAdminV1FieldOperationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1ImportDocumentsMetadata',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ImportDocumentsMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ImportDocumentsMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ImportDocumentsMetadata(
          od as api.GoogleFirestoreAdminV1ImportDocumentsMetadata);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1ImportDocumentsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ImportDocumentsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ImportDocumentsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ImportDocumentsRequest(
          od as api.GoogleFirestoreAdminV1ImportDocumentsRequest);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1Index', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1Index();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1Index.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1Index(od as api.GoogleFirestoreAdminV1Index);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1IndexConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1IndexConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1IndexConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1IndexConfig(
          od as api.GoogleFirestoreAdminV1IndexConfig);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1IndexConfigDelta', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1IndexConfigDelta();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1IndexConfigDelta.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1IndexConfigDelta(
          od as api.GoogleFirestoreAdminV1IndexConfigDelta);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1IndexField', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1IndexField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1IndexField.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1IndexField(
          od as api.GoogleFirestoreAdminV1IndexField);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1IndexOperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1IndexOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1IndexOperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1IndexOperationMetadata(
          od as api.GoogleFirestoreAdminV1IndexOperationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1ListFieldsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ListFieldsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ListFieldsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ListFieldsResponse(
          od as api.GoogleFirestoreAdminV1ListFieldsResponse);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1ListIndexesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1ListIndexesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1ListIndexesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1ListIndexesResponse(
          od as api.GoogleFirestoreAdminV1ListIndexesResponse);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1LocationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1LocationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1LocationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1LocationMetadata(
          od as api.GoogleFirestoreAdminV1LocationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleFirestoreAdminV1Progress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleFirestoreAdminV1Progress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleFirestoreAdminV1Progress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleFirestoreAdminV1Progress(
          od as api.GoogleFirestoreAdminV1Progress);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningCancelOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningCancelOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningCancelOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningCancelOperationRequest(
          od as api.GoogleLongrunningCancelOperationRequest);
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

  unittest.group('obj-schema-LatLng', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLatLng();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LatLng.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLatLng(od as api.LatLng);
    });
  });

  unittest.group('obj-schema-ListCollectionIdsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCollectionIdsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCollectionIdsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCollectionIdsRequest(od as api.ListCollectionIdsRequest);
    });
  });

  unittest.group('obj-schema-ListCollectionIdsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCollectionIdsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCollectionIdsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCollectionIdsResponse(od as api.ListCollectionIdsResponse);
    });
  });

  unittest.group('obj-schema-ListDocumentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDocumentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDocumentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDocumentsResponse(od as api.ListDocumentsResponse);
    });
  });

  unittest.group('obj-schema-ListLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationsResponse(od as api.ListLocationsResponse);
    });
  });

  unittest.group('obj-schema-ListenRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListenRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListenRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListenRequest(od as api.ListenRequest);
    });
  });

  unittest.group('obj-schema-ListenResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListenResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListenResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListenResponse(od as api.ListenResponse);
    });
  });

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
    });
  });

  unittest.group('obj-schema-MapValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMapValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.MapValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMapValue(od as api.MapValue);
    });
  });

  unittest.group('obj-schema-Order', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Order.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOrder(od as api.Order);
    });
  });

  unittest.group('obj-schema-PartitionQueryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionQueryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionQueryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionQueryRequest(od as api.PartitionQueryRequest);
    });
  });

  unittest.group('obj-schema-PartitionQueryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionQueryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionQueryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionQueryResponse(od as api.PartitionQueryResponse);
    });
  });

  unittest.group('obj-schema-Precondition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrecondition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Precondition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrecondition(od as api.Precondition);
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

  unittest.group('obj-schema-QueryTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryTarget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryTarget(od as api.QueryTarget);
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

  unittest.group('obj-schema-ReadWrite', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReadWrite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReadWrite.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReadWrite(od as api.ReadWrite);
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

  unittest.group('obj-schema-StructuredQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStructuredQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StructuredQuery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStructuredQuery(od as api.StructuredQuery);
    });
  });

  unittest.group('obj-schema-Target', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Target.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTarget(od as api.Target);
    });
  });

  unittest.group('obj-schema-TargetChange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetChange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetChange(od as api.TargetChange);
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

  unittest.group('obj-schema-UnaryFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnaryFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnaryFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnaryFilter(od as api.UnaryFilter);
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

  unittest.group('obj-schema-Write', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWrite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Write.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkWrite(od as api.Write);
    });
  });

  unittest.group('obj-schema-WriteRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWriteRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WriteRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWriteRequest(od as api.WriteRequest);
    });
  });

  unittest.group('obj-schema-WriteResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWriteResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WriteResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWriteResponse(od as api.WriteResponse);
    });
  });

  unittest.group('obj-schema-WriteResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWriteResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WriteResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWriteResult(od as api.WriteResult);
    });
  });

  unittest.group('resource-ProjectsDatabasesResource', () {
    unittest.test('method--exportDocuments', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases;
      var arg_request = buildGoogleFirestoreAdminV1ExportDocumentsRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleFirestoreAdminV1ExportDocumentsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleFirestoreAdminV1ExportDocumentsRequest(
            obj as api.GoogleFirestoreAdminV1ExportDocumentsRequest);

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
      final response = await res.exportDocuments(arg_request, arg_name,
          $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--importDocuments', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases;
      var arg_request = buildGoogleFirestoreAdminV1ImportDocumentsRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleFirestoreAdminV1ImportDocumentsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleFirestoreAdminV1ImportDocumentsRequest(
            obj as api.GoogleFirestoreAdminV1ImportDocumentsRequest);

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
      final response = await res.importDocuments(arg_request, arg_name,
          $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });
  });

  unittest.group('resource-ProjectsDatabasesCollectionGroupsFieldsResource',
      () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.fields;
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
        var resp = convert.json.encode(buildGoogleFirestoreAdminV1Field());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleFirestoreAdminV1Field(
          response as api.GoogleFirestoreAdminV1Field);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.fields;
      var arg_parent = 'foo';
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
        var resp = convert.json
            .encode(buildGoogleFirestoreAdminV1ListFieldsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleFirestoreAdminV1ListFieldsResponse(
          response as api.GoogleFirestoreAdminV1ListFieldsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.fields;
      var arg_request = buildGoogleFirestoreAdminV1Field();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleFirestoreAdminV1Field.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleFirestoreAdminV1Field(
            obj as api.GoogleFirestoreAdminV1Field);

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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
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
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });
  });

  unittest.group('resource-ProjectsDatabasesCollectionGroupsIndexesResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.indexes;
      var arg_request = buildGoogleFirestoreAdminV1Index();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleFirestoreAdminV1Index.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleFirestoreAdminV1Index(
            obj as api.GoogleFirestoreAdminV1Index);

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
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.indexes;
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
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.indexes;
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
        var resp = convert.json.encode(buildGoogleFirestoreAdminV1Index());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleFirestoreAdminV1Index(
          response as api.GoogleFirestoreAdminV1Index);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.FirestoreApi(mock).projects.databases.collectionGroups.indexes;
      var arg_parent = 'foo';
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
        var resp = convert.json
            .encode(buildGoogleFirestoreAdminV1ListIndexesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleFirestoreAdminV1ListIndexesResponse(
          response as api.GoogleFirestoreAdminV1ListIndexesResponse);
    });
  });

  unittest.group('resource-ProjectsDatabasesDocumentsResource', () {
    unittest.test('method--batchGet', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildBatchGetDocumentsRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchGetDocumentsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchGetDocumentsRequest(obj as api.BatchGetDocumentsRequest);

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
        var resp = convert.json.encode(buildBatchGetDocumentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.batchGet(arg_request, arg_database, $fields: arg_$fields);
      checkBatchGetDocumentsResponse(response as api.BatchGetDocumentsResponse);
    });

    unittest.test('method--batchWrite', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildBatchWriteRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchWriteRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchWriteRequest(obj as api.BatchWriteRequest);

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
        var resp = convert.json.encode(buildBatchWriteResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.batchWrite(arg_request, arg_database, $fields: arg_$fields);
      checkBatchWriteResponse(response as api.BatchWriteResponse);
    });

    unittest.test('method--beginTransaction', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildBeginTransactionRequest();
      var arg_database = 'foo';
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
        var resp = convert.json.encode(buildBeginTransactionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.beginTransaction(arg_request, arg_database,
          $fields: arg_$fields);
      checkBeginTransactionResponse(response as api.BeginTransactionResponse);
    });

    unittest.test('method--commit', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildCommitRequest();
      var arg_database = 'foo';
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
        var resp = convert.json.encode(buildCommitResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.commit(arg_request, arg_database, $fields: arg_$fields);
      checkCommitResponse(response as api.CommitResponse);
    });

    unittest.test('method--createDocument', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildDocument();
      var arg_parent = 'foo';
      var arg_collectionId = 'foo';
      var arg_documentId = 'foo';
      var arg_mask_fieldPaths = buildUnnamed4099();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Document.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDocument(obj as api.Document);

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
          queryMap["documentId"]!.first,
          unittest.equals(arg_documentId),
        );
        unittest.expect(
          queryMap["mask.fieldPaths"]!,
          unittest.equals(arg_mask_fieldPaths),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDocument());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.createDocument(
          arg_request, arg_parent, arg_collectionId,
          documentId: arg_documentId,
          mask_fieldPaths: arg_mask_fieldPaths,
          $fields: arg_$fields);
      checkDocument(response as api.Document);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_name = 'foo';
      var arg_currentDocument_exists = true;
      var arg_currentDocument_updateTime = 'foo';
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
          queryMap["currentDocument.exists"]!.first,
          unittest.equals("$arg_currentDocument_exists"),
        );
        unittest.expect(
          queryMap["currentDocument.updateTime"]!.first,
          unittest.equals(arg_currentDocument_updateTime),
        );
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
      final response = await res.delete(arg_name,
          currentDocument_exists: arg_currentDocument_exists,
          currentDocument_updateTime: arg_currentDocument_updateTime,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_name = 'foo';
      var arg_mask_fieldPaths = buildUnnamed4100();
      var arg_readTime = 'foo';
      var arg_transaction = 'foo';
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
          queryMap["mask.fieldPaths"]!,
          unittest.equals(arg_mask_fieldPaths),
        );
        unittest.expect(
          queryMap["readTime"]!.first,
          unittest.equals(arg_readTime),
        );
        unittest.expect(
          queryMap["transaction"]!.first,
          unittest.equals(arg_transaction),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDocument());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          mask_fieldPaths: arg_mask_fieldPaths,
          readTime: arg_readTime,
          transaction: arg_transaction,
          $fields: arg_$fields);
      checkDocument(response as api.Document);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_parent = 'foo';
      var arg_collectionId = 'foo';
      var arg_mask_fieldPaths = buildUnnamed4101();
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_readTime = 'foo';
      var arg_showMissing = true;
      var arg_transaction = 'foo';
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
          queryMap["mask.fieldPaths"]!,
          unittest.equals(arg_mask_fieldPaths),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["readTime"]!.first,
          unittest.equals(arg_readTime),
        );
        unittest.expect(
          queryMap["showMissing"]!.first,
          unittest.equals("$arg_showMissing"),
        );
        unittest.expect(
          queryMap["transaction"]!.first,
          unittest.equals(arg_transaction),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListDocumentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, arg_collectionId,
          mask_fieldPaths: arg_mask_fieldPaths,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          showMissing: arg_showMissing,
          transaction: arg_transaction,
          $fields: arg_$fields);
      checkListDocumentsResponse(response as api.ListDocumentsResponse);
    });

    unittest.test('method--listCollectionIds', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildListCollectionIdsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListCollectionIdsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListCollectionIdsRequest(obj as api.ListCollectionIdsRequest);

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
        var resp = convert.json.encode(buildListCollectionIdsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listCollectionIds(arg_request, arg_parent,
          $fields: arg_$fields);
      checkListCollectionIdsResponse(response as api.ListCollectionIdsResponse);
    });

    unittest.test('method--listen', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildListenRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ListenRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkListenRequest(obj as api.ListenRequest);

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
        var resp = convert.json.encode(buildListenResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.listen(arg_request, arg_database, $fields: arg_$fields);
      checkListenResponse(response as api.ListenResponse);
    });

    unittest.test('method--partitionQuery', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildPartitionQueryRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PartitionQueryRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPartitionQueryRequest(obj as api.PartitionQueryRequest);

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
        var resp = convert.json.encode(buildPartitionQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.partitionQuery(arg_request, arg_parent,
          $fields: arg_$fields);
      checkPartitionQueryResponse(response as api.PartitionQueryResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildDocument();
      var arg_name = 'foo';
      var arg_currentDocument_exists = true;
      var arg_currentDocument_updateTime = 'foo';
      var arg_mask_fieldPaths = buildUnnamed4102();
      var arg_updateMask_fieldPaths = buildUnnamed4103();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Document.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDocument(obj as api.Document);

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
          queryMap["currentDocument.exists"]!.first,
          unittest.equals("$arg_currentDocument_exists"),
        );
        unittest.expect(
          queryMap["currentDocument.updateTime"]!.first,
          unittest.equals(arg_currentDocument_updateTime),
        );
        unittest.expect(
          queryMap["mask.fieldPaths"]!,
          unittest.equals(arg_mask_fieldPaths),
        );
        unittest.expect(
          queryMap["updateMask.fieldPaths"]!,
          unittest.equals(arg_updateMask_fieldPaths),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDocument());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          currentDocument_exists: arg_currentDocument_exists,
          currentDocument_updateTime: arg_currentDocument_updateTime,
          mask_fieldPaths: arg_mask_fieldPaths,
          updateMask_fieldPaths: arg_updateMask_fieldPaths,
          $fields: arg_$fields);
      checkDocument(response as api.Document);
    });

    unittest.test('method--rollback', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildRollbackRequest();
      var arg_database = 'foo';
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
      final response =
          await res.rollback(arg_request, arg_database, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--runQuery', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildRunQueryRequest();
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildRunQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.runQuery(arg_request, arg_parent, $fields: arg_$fields);
      checkRunQueryResponse(response as api.RunQueryResponse);
    });

    unittest.test('method--write', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.documents;
      var arg_request = buildWriteRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WriteRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWriteRequest(obj as api.WriteRequest);

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
        var resp = convert.json.encode(buildWriteResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.write(arg_request, arg_database, $fields: arg_$fields);
      checkWriteResponse(response as api.WriteResponse);
    });
  });

  unittest.group('resource-ProjectsDatabasesOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.operations;
      var arg_request = buildGoogleLongrunningCancelOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleLongrunningCancelOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleLongrunningCancelOperationRequest(
            obj as api.GoogleLongrunningCancelOperationRequest);

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
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.databases.operations;
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
      var res = api.FirestoreApi(mock).projects.databases.operations;
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
      var res = api.FirestoreApi(mock).projects.databases.operations;
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

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.locations;
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
        var resp = convert.json.encode(buildLocation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkLocation(response as api.Location);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.FirestoreApi(mock).projects.locations;
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
        var resp = convert.json.encode(buildListLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationsResponse(response as api.ListLocationsResponse);
    });
  });
}
