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

import 'package:googleapis/spanner/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed1882() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1882(core.List<core.String> o) {
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

core.int buildCounterBackup = 0;
api.Backup buildBackup() {
  var o = api.Backup();
  buildCounterBackup++;
  if (buildCounterBackup < 3) {
    o.createTime = 'foo';
    o.database = 'foo';
    o.encryptionInfo = buildEncryptionInfo();
    o.expireTime = 'foo';
    o.name = 'foo';
    o.referencingDatabases = buildUnnamed1882();
    o.sizeBytes = 'foo';
    o.state = 'foo';
    o.versionTime = 'foo';
  }
  buildCounterBackup--;
  return o;
}

void checkBackup(api.Backup o) {
  buildCounterBackup++;
  if (buildCounterBackup < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.database!,
      unittest.equals('foo'),
    );
    checkEncryptionInfo(o.encryptionInfo! as api.EncryptionInfo);
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1882(o.referencingDatabases!);
    unittest.expect(
      o.sizeBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterBackup--;
}

core.int buildCounterBackupInfo = 0;
api.BackupInfo buildBackupInfo() {
  var o = api.BackupInfo();
  buildCounterBackupInfo++;
  if (buildCounterBackupInfo < 3) {
    o.backup = 'foo';
    o.createTime = 'foo';
    o.sourceDatabase = 'foo';
    o.versionTime = 'foo';
  }
  buildCounterBackupInfo--;
  return o;
}

void checkBackupInfo(api.BackupInfo o) {
  buildCounterBackupInfo++;
  if (buildCounterBackupInfo < 3) {
    unittest.expect(
      o.backup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceDatabase!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterBackupInfo--;
}

core.int buildCounterBatchCreateSessionsRequest = 0;
api.BatchCreateSessionsRequest buildBatchCreateSessionsRequest() {
  var o = api.BatchCreateSessionsRequest();
  buildCounterBatchCreateSessionsRequest++;
  if (buildCounterBatchCreateSessionsRequest < 3) {
    o.sessionCount = 42;
    o.sessionTemplate = buildSession();
  }
  buildCounterBatchCreateSessionsRequest--;
  return o;
}

void checkBatchCreateSessionsRequest(api.BatchCreateSessionsRequest o) {
  buildCounterBatchCreateSessionsRequest++;
  if (buildCounterBatchCreateSessionsRequest < 3) {
    unittest.expect(
      o.sessionCount!,
      unittest.equals(42),
    );
    checkSession(o.sessionTemplate! as api.Session);
  }
  buildCounterBatchCreateSessionsRequest--;
}

core.List<api.Session> buildUnnamed1883() {
  var o = <api.Session>[];
  o.add(buildSession());
  o.add(buildSession());
  return o;
}

void checkUnnamed1883(core.List<api.Session> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSession(o[0] as api.Session);
  checkSession(o[1] as api.Session);
}

core.int buildCounterBatchCreateSessionsResponse = 0;
api.BatchCreateSessionsResponse buildBatchCreateSessionsResponse() {
  var o = api.BatchCreateSessionsResponse();
  buildCounterBatchCreateSessionsResponse++;
  if (buildCounterBatchCreateSessionsResponse < 3) {
    o.session = buildUnnamed1883();
  }
  buildCounterBatchCreateSessionsResponse--;
  return o;
}

void checkBatchCreateSessionsResponse(api.BatchCreateSessionsResponse o) {
  buildCounterBatchCreateSessionsResponse++;
  if (buildCounterBatchCreateSessionsResponse < 3) {
    checkUnnamed1883(o.session!);
  }
  buildCounterBatchCreateSessionsResponse--;
}

core.int buildCounterBeginTransactionRequest = 0;
api.BeginTransactionRequest buildBeginTransactionRequest() {
  var o = api.BeginTransactionRequest();
  buildCounterBeginTransactionRequest++;
  if (buildCounterBeginTransactionRequest < 3) {
    o.options = buildTransactionOptions();
    o.requestOptions = buildRequestOptions();
  }
  buildCounterBeginTransactionRequest--;
  return o;
}

void checkBeginTransactionRequest(api.BeginTransactionRequest o) {
  buildCounterBeginTransactionRequest++;
  if (buildCounterBeginTransactionRequest < 3) {
    checkTransactionOptions(o.options! as api.TransactionOptions);
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
  }
  buildCounterBeginTransactionRequest--;
}

core.List<core.String> buildUnnamed1884() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1884(core.List<core.String> o) {
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

core.int buildCounterBinding = 0;
api.Binding buildBinding() {
  var o = api.Binding();
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    o.condition = buildExpr();
    o.members = buildUnnamed1884();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed1884(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterChildLink = 0;
api.ChildLink buildChildLink() {
  var o = api.ChildLink();
  buildCounterChildLink++;
  if (buildCounterChildLink < 3) {
    o.childIndex = 42;
    o.type = 'foo';
    o.variable = 'foo';
  }
  buildCounterChildLink--;
  return o;
}

void checkChildLink(api.ChildLink o) {
  buildCounterChildLink++;
  if (buildCounterChildLink < 3) {
    unittest.expect(
      o.childIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.variable!,
      unittest.equals('foo'),
    );
  }
  buildCounterChildLink--;
}

core.List<api.Mutation> buildUnnamed1885() {
  var o = <api.Mutation>[];
  o.add(buildMutation());
  o.add(buildMutation());
  return o;
}

void checkUnnamed1885(core.List<api.Mutation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMutation(o[0] as api.Mutation);
  checkMutation(o[1] as api.Mutation);
}

core.int buildCounterCommitRequest = 0;
api.CommitRequest buildCommitRequest() {
  var o = api.CommitRequest();
  buildCounterCommitRequest++;
  if (buildCounterCommitRequest < 3) {
    o.mutations = buildUnnamed1885();
    o.requestOptions = buildRequestOptions();
    o.returnCommitStats = true;
    o.singleUseTransaction = buildTransactionOptions();
    o.transactionId = 'foo';
  }
  buildCounterCommitRequest--;
  return o;
}

void checkCommitRequest(api.CommitRequest o) {
  buildCounterCommitRequest++;
  if (buildCounterCommitRequest < 3) {
    checkUnnamed1885(o.mutations!);
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
    unittest.expect(o.returnCommitStats!, unittest.isTrue);
    checkTransactionOptions(o.singleUseTransaction! as api.TransactionOptions);
    unittest.expect(
      o.transactionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommitRequest--;
}

core.int buildCounterCommitResponse = 0;
api.CommitResponse buildCommitResponse() {
  var o = api.CommitResponse();
  buildCounterCommitResponse++;
  if (buildCounterCommitResponse < 3) {
    o.commitStats = buildCommitStats();
    o.commitTimestamp = 'foo';
  }
  buildCounterCommitResponse--;
  return o;
}

void checkCommitResponse(api.CommitResponse o) {
  buildCounterCommitResponse++;
  if (buildCounterCommitResponse < 3) {
    checkCommitStats(o.commitStats! as api.CommitStats);
    unittest.expect(
      o.commitTimestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommitResponse--;
}

core.int buildCounterCommitStats = 0;
api.CommitStats buildCommitStats() {
  var o = api.CommitStats();
  buildCounterCommitStats++;
  if (buildCounterCommitStats < 3) {
    o.mutationCount = 'foo';
  }
  buildCounterCommitStats--;
  return o;
}

void checkCommitStats(api.CommitStats o) {
  buildCounterCommitStats++;
  if (buildCounterCommitStats < 3) {
    unittest.expect(
      o.mutationCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommitStats--;
}

core.int buildCounterCreateBackupMetadata = 0;
api.CreateBackupMetadata buildCreateBackupMetadata() {
  var o = api.CreateBackupMetadata();
  buildCounterCreateBackupMetadata++;
  if (buildCounterCreateBackupMetadata < 3) {
    o.cancelTime = 'foo';
    o.database = 'foo';
    o.name = 'foo';
    o.progress = buildOperationProgress();
  }
  buildCounterCreateBackupMetadata--;
  return o;
}

void checkCreateBackupMetadata(api.CreateBackupMetadata o) {
  buildCounterCreateBackupMetadata++;
  if (buildCounterCreateBackupMetadata < 3) {
    unittest.expect(
      o.cancelTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.database!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOperationProgress(o.progress! as api.OperationProgress);
  }
  buildCounterCreateBackupMetadata--;
}

core.int buildCounterCreateDatabaseMetadata = 0;
api.CreateDatabaseMetadata buildCreateDatabaseMetadata() {
  var o = api.CreateDatabaseMetadata();
  buildCounterCreateDatabaseMetadata++;
  if (buildCounterCreateDatabaseMetadata < 3) {
    o.database = 'foo';
  }
  buildCounterCreateDatabaseMetadata--;
  return o;
}

void checkCreateDatabaseMetadata(api.CreateDatabaseMetadata o) {
  buildCounterCreateDatabaseMetadata++;
  if (buildCounterCreateDatabaseMetadata < 3) {
    unittest.expect(
      o.database!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateDatabaseMetadata--;
}

core.List<core.String> buildUnnamed1886() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1886(core.List<core.String> o) {
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

core.int buildCounterCreateDatabaseRequest = 0;
api.CreateDatabaseRequest buildCreateDatabaseRequest() {
  var o = api.CreateDatabaseRequest();
  buildCounterCreateDatabaseRequest++;
  if (buildCounterCreateDatabaseRequest < 3) {
    o.createStatement = 'foo';
    o.encryptionConfig = buildEncryptionConfig();
    o.extraStatements = buildUnnamed1886();
  }
  buildCounterCreateDatabaseRequest--;
  return o;
}

void checkCreateDatabaseRequest(api.CreateDatabaseRequest o) {
  buildCounterCreateDatabaseRequest++;
  if (buildCounterCreateDatabaseRequest < 3) {
    unittest.expect(
      o.createStatement!,
      unittest.equals('foo'),
    );
    checkEncryptionConfig(o.encryptionConfig! as api.EncryptionConfig);
    checkUnnamed1886(o.extraStatements!);
  }
  buildCounterCreateDatabaseRequest--;
}

core.int buildCounterCreateInstanceMetadata = 0;
api.CreateInstanceMetadata buildCreateInstanceMetadata() {
  var o = api.CreateInstanceMetadata();
  buildCounterCreateInstanceMetadata++;
  if (buildCounterCreateInstanceMetadata < 3) {
    o.cancelTime = 'foo';
    o.endTime = 'foo';
    o.instance = buildInstance();
    o.startTime = 'foo';
  }
  buildCounterCreateInstanceMetadata--;
  return o;
}

void checkCreateInstanceMetadata(api.CreateInstanceMetadata o) {
  buildCounterCreateInstanceMetadata++;
  if (buildCounterCreateInstanceMetadata < 3) {
    unittest.expect(
      o.cancelTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkInstance(o.instance! as api.Instance);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateInstanceMetadata--;
}

core.int buildCounterCreateInstanceRequest = 0;
api.CreateInstanceRequest buildCreateInstanceRequest() {
  var o = api.CreateInstanceRequest();
  buildCounterCreateInstanceRequest++;
  if (buildCounterCreateInstanceRequest < 3) {
    o.instance = buildInstance();
    o.instanceId = 'foo';
  }
  buildCounterCreateInstanceRequest--;
  return o;
}

void checkCreateInstanceRequest(api.CreateInstanceRequest o) {
  buildCounterCreateInstanceRequest++;
  if (buildCounterCreateInstanceRequest < 3) {
    checkInstance(o.instance! as api.Instance);
    unittest.expect(
      o.instanceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateInstanceRequest--;
}

core.int buildCounterCreateSessionRequest = 0;
api.CreateSessionRequest buildCreateSessionRequest() {
  var o = api.CreateSessionRequest();
  buildCounterCreateSessionRequest++;
  if (buildCounterCreateSessionRequest < 3) {
    o.session = buildSession();
  }
  buildCounterCreateSessionRequest--;
  return o;
}

void checkCreateSessionRequest(api.CreateSessionRequest o) {
  buildCounterCreateSessionRequest++;
  if (buildCounterCreateSessionRequest < 3) {
    checkSession(o.session! as api.Session);
  }
  buildCounterCreateSessionRequest--;
}

core.List<api.EncryptionInfo> buildUnnamed1887() {
  var o = <api.EncryptionInfo>[];
  o.add(buildEncryptionInfo());
  o.add(buildEncryptionInfo());
  return o;
}

void checkUnnamed1887(core.List<api.EncryptionInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEncryptionInfo(o[0] as api.EncryptionInfo);
  checkEncryptionInfo(o[1] as api.EncryptionInfo);
}

core.int buildCounterDatabase = 0;
api.Database buildDatabase() {
  var o = api.Database();
  buildCounterDatabase++;
  if (buildCounterDatabase < 3) {
    o.createTime = 'foo';
    o.earliestVersionTime = 'foo';
    o.encryptionConfig = buildEncryptionConfig();
    o.encryptionInfo = buildUnnamed1887();
    o.name = 'foo';
    o.restoreInfo = buildRestoreInfo();
    o.state = 'foo';
    o.versionRetentionPeriod = 'foo';
  }
  buildCounterDatabase--;
  return o;
}

void checkDatabase(api.Database o) {
  buildCounterDatabase++;
  if (buildCounterDatabase < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.earliestVersionTime!,
      unittest.equals('foo'),
    );
    checkEncryptionConfig(o.encryptionConfig! as api.EncryptionConfig);
    checkUnnamed1887(o.encryptionInfo!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkRestoreInfo(o.restoreInfo! as api.RestoreInfo);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.versionRetentionPeriod!,
      unittest.equals('foo'),
    );
  }
  buildCounterDatabase--;
}

core.int buildCounterDelete = 0;
api.Delete buildDelete() {
  var o = api.Delete();
  buildCounterDelete++;
  if (buildCounterDelete < 3) {
    o.keySet = buildKeySet();
    o.table = 'foo';
  }
  buildCounterDelete--;
  return o;
}

void checkDelete(api.Delete o) {
  buildCounterDelete++;
  if (buildCounterDelete < 3) {
    checkKeySet(o.keySet! as api.KeySet);
    unittest.expect(
      o.table!,
      unittest.equals('foo'),
    );
  }
  buildCounterDelete--;
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

core.int buildCounterEncryptionConfig = 0;
api.EncryptionConfig buildEncryptionConfig() {
  var o = api.EncryptionConfig();
  buildCounterEncryptionConfig++;
  if (buildCounterEncryptionConfig < 3) {
    o.kmsKeyName = 'foo';
  }
  buildCounterEncryptionConfig--;
  return o;
}

void checkEncryptionConfig(api.EncryptionConfig o) {
  buildCounterEncryptionConfig++;
  if (buildCounterEncryptionConfig < 3) {
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
  }
  buildCounterEncryptionConfig--;
}

core.int buildCounterEncryptionInfo = 0;
api.EncryptionInfo buildEncryptionInfo() {
  var o = api.EncryptionInfo();
  buildCounterEncryptionInfo++;
  if (buildCounterEncryptionInfo < 3) {
    o.encryptionStatus = buildStatus();
    o.encryptionType = 'foo';
    o.kmsKeyVersion = 'foo';
  }
  buildCounterEncryptionInfo--;
  return o;
}

void checkEncryptionInfo(api.EncryptionInfo o) {
  buildCounterEncryptionInfo++;
  if (buildCounterEncryptionInfo < 3) {
    checkStatus(o.encryptionStatus! as api.Status);
    unittest.expect(
      o.encryptionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kmsKeyVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterEncryptionInfo--;
}

core.List<api.Statement> buildUnnamed1888() {
  var o = <api.Statement>[];
  o.add(buildStatement());
  o.add(buildStatement());
  return o;
}

void checkUnnamed1888(core.List<api.Statement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStatement(o[0] as api.Statement);
  checkStatement(o[1] as api.Statement);
}

core.int buildCounterExecuteBatchDmlRequest = 0;
api.ExecuteBatchDmlRequest buildExecuteBatchDmlRequest() {
  var o = api.ExecuteBatchDmlRequest();
  buildCounterExecuteBatchDmlRequest++;
  if (buildCounterExecuteBatchDmlRequest < 3) {
    o.requestOptions = buildRequestOptions();
    o.seqno = 'foo';
    o.statements = buildUnnamed1888();
    o.transaction = buildTransactionSelector();
  }
  buildCounterExecuteBatchDmlRequest--;
  return o;
}

void checkExecuteBatchDmlRequest(api.ExecuteBatchDmlRequest o) {
  buildCounterExecuteBatchDmlRequest++;
  if (buildCounterExecuteBatchDmlRequest < 3) {
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
    unittest.expect(
      o.seqno!,
      unittest.equals('foo'),
    );
    checkUnnamed1888(o.statements!);
    checkTransactionSelector(o.transaction! as api.TransactionSelector);
  }
  buildCounterExecuteBatchDmlRequest--;
}

core.List<api.ResultSet> buildUnnamed1889() {
  var o = <api.ResultSet>[];
  o.add(buildResultSet());
  o.add(buildResultSet());
  return o;
}

void checkUnnamed1889(core.List<api.ResultSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResultSet(o[0] as api.ResultSet);
  checkResultSet(o[1] as api.ResultSet);
}

core.int buildCounterExecuteBatchDmlResponse = 0;
api.ExecuteBatchDmlResponse buildExecuteBatchDmlResponse() {
  var o = api.ExecuteBatchDmlResponse();
  buildCounterExecuteBatchDmlResponse++;
  if (buildCounterExecuteBatchDmlResponse < 3) {
    o.resultSets = buildUnnamed1889();
    o.status = buildStatus();
  }
  buildCounterExecuteBatchDmlResponse--;
  return o;
}

void checkExecuteBatchDmlResponse(api.ExecuteBatchDmlResponse o) {
  buildCounterExecuteBatchDmlResponse++;
  if (buildCounterExecuteBatchDmlResponse < 3) {
    checkUnnamed1889(o.resultSets!);
    checkStatus(o.status! as api.Status);
  }
  buildCounterExecuteBatchDmlResponse--;
}

core.Map<core.String, api.Type> buildUnnamed1890() {
  var o = <core.String, api.Type>{};
  o['x'] = buildType();
  o['y'] = buildType();
  return o;
}

void checkUnnamed1890(core.Map<core.String, api.Type> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkType(o['x']! as api.Type);
  checkType(o['y']! as api.Type);
}

core.Map<core.String, core.Object> buildUnnamed1891() {
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

void checkUnnamed1891(core.Map<core.String, core.Object> o) {
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

core.int buildCounterExecuteSqlRequest = 0;
api.ExecuteSqlRequest buildExecuteSqlRequest() {
  var o = api.ExecuteSqlRequest();
  buildCounterExecuteSqlRequest++;
  if (buildCounterExecuteSqlRequest < 3) {
    o.paramTypes = buildUnnamed1890();
    o.params = buildUnnamed1891();
    o.partitionToken = 'foo';
    o.queryMode = 'foo';
    o.queryOptions = buildQueryOptions();
    o.requestOptions = buildRequestOptions();
    o.resumeToken = 'foo';
    o.seqno = 'foo';
    o.sql = 'foo';
    o.transaction = buildTransactionSelector();
  }
  buildCounterExecuteSqlRequest--;
  return o;
}

void checkExecuteSqlRequest(api.ExecuteSqlRequest o) {
  buildCounterExecuteSqlRequest++;
  if (buildCounterExecuteSqlRequest < 3) {
    checkUnnamed1890(o.paramTypes!);
    checkUnnamed1891(o.params!);
    unittest.expect(
      o.partitionToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queryMode!,
      unittest.equals('foo'),
    );
    checkQueryOptions(o.queryOptions! as api.QueryOptions);
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
    unittest.expect(
      o.resumeToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.seqno!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sql!,
      unittest.equals('foo'),
    );
    checkTransactionSelector(o.transaction! as api.TransactionSelector);
  }
  buildCounterExecuteSqlRequest--;
}

core.int buildCounterExpr = 0;
api.Expr buildExpr() {
  var o = api.Expr();
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    o.description = 'foo';
    o.expression = 'foo';
    o.location = 'foo';
    o.title = 'foo';
  }
  buildCounterExpr--;
  return o;
}

void checkExpr(api.Expr o) {
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterExpr--;
}

core.int buildCounterField = 0;
api.Field buildField() {
  var o = api.Field();
  buildCounterField++;
  if (buildCounterField < 3) {
    o.name = 'foo';
    o.type = buildType();
  }
  buildCounterField--;
  return o;
}

void checkField(api.Field o) {
  buildCounterField++;
  if (buildCounterField < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkType(o.type! as api.Type);
  }
  buildCounterField--;
}

core.List<core.String> buildUnnamed1892() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1892(core.List<core.String> o) {
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

core.int buildCounterGetDatabaseDdlResponse = 0;
api.GetDatabaseDdlResponse buildGetDatabaseDdlResponse() {
  var o = api.GetDatabaseDdlResponse();
  buildCounterGetDatabaseDdlResponse++;
  if (buildCounterGetDatabaseDdlResponse < 3) {
    o.statements = buildUnnamed1892();
  }
  buildCounterGetDatabaseDdlResponse--;
  return o;
}

void checkGetDatabaseDdlResponse(api.GetDatabaseDdlResponse o) {
  buildCounterGetDatabaseDdlResponse++;
  if (buildCounterGetDatabaseDdlResponse < 3) {
    checkUnnamed1892(o.statements!);
  }
  buildCounterGetDatabaseDdlResponse--;
}

core.int buildCounterGetIamPolicyRequest = 0;
api.GetIamPolicyRequest buildGetIamPolicyRequest() {
  var o = api.GetIamPolicyRequest();
  buildCounterGetIamPolicyRequest++;
  if (buildCounterGetIamPolicyRequest < 3) {
    o.options = buildGetPolicyOptions();
  }
  buildCounterGetIamPolicyRequest--;
  return o;
}

void checkGetIamPolicyRequest(api.GetIamPolicyRequest o) {
  buildCounterGetIamPolicyRequest++;
  if (buildCounterGetIamPolicyRequest < 3) {
    checkGetPolicyOptions(o.options! as api.GetPolicyOptions);
  }
  buildCounterGetIamPolicyRequest--;
}

core.int buildCounterGetPolicyOptions = 0;
api.GetPolicyOptions buildGetPolicyOptions() {
  var o = api.GetPolicyOptions();
  buildCounterGetPolicyOptions++;
  if (buildCounterGetPolicyOptions < 3) {
    o.requestedPolicyVersion = 42;
  }
  buildCounterGetPolicyOptions--;
  return o;
}

void checkGetPolicyOptions(api.GetPolicyOptions o) {
  buildCounterGetPolicyOptions++;
  if (buildCounterGetPolicyOptions < 3) {
    unittest.expect(
      o.requestedPolicyVersion!,
      unittest.equals(42),
    );
  }
  buildCounterGetPolicyOptions--;
}

core.List<core.String> buildUnnamed1893() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1893(core.List<core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed1894() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1894(core.Map<core.String, core.String> o) {
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

core.int buildCounterInstance = 0;
api.Instance buildInstance() {
  var o = api.Instance();
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    o.config = 'foo';
    o.displayName = 'foo';
    o.endpointUris = buildUnnamed1893();
    o.labels = buildUnnamed1894();
    o.name = 'foo';
    o.nodeCount = 42;
    o.state = 'foo';
  }
  buildCounterInstance--;
  return o;
}

void checkInstance(api.Instance o) {
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    unittest.expect(
      o.config!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed1893(o.endpointUris!);
    checkUnnamed1894(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nodeCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterInstance--;
}

core.List<api.ReplicaInfo> buildUnnamed1895() {
  var o = <api.ReplicaInfo>[];
  o.add(buildReplicaInfo());
  o.add(buildReplicaInfo());
  return o;
}

void checkUnnamed1895(core.List<api.ReplicaInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReplicaInfo(o[0] as api.ReplicaInfo);
  checkReplicaInfo(o[1] as api.ReplicaInfo);
}

core.int buildCounterInstanceConfig = 0;
api.InstanceConfig buildInstanceConfig() {
  var o = api.InstanceConfig();
  buildCounterInstanceConfig++;
  if (buildCounterInstanceConfig < 3) {
    o.displayName = 'foo';
    o.name = 'foo';
    o.replicas = buildUnnamed1895();
  }
  buildCounterInstanceConfig--;
  return o;
}

void checkInstanceConfig(api.InstanceConfig o) {
  buildCounterInstanceConfig++;
  if (buildCounterInstanceConfig < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1895(o.replicas!);
  }
  buildCounterInstanceConfig--;
}

core.List<core.Object> buildUnnamed1896() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1896(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o[0]) as core.Map;
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
  var casted4 = (o[1]) as core.Map;
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

core.List<core.Object> buildUnnamed1897() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1897(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted5 = (o[0]) as core.Map;
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
  var casted6 = (o[1]) as core.Map;
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

core.List<core.Object> buildUnnamed1898() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1898(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o[0]) as core.Map;
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
  var casted8 = (o[1]) as core.Map;
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

core.List<core.Object> buildUnnamed1899() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1899(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted9 = (o[0]) as core.Map;
  unittest.expect(casted9, unittest.hasLength(3));
  unittest.expect(
    casted9['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted9['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted9['string'],
    unittest.equals('foo'),
  );
  var casted10 = (o[1]) as core.Map;
  unittest.expect(casted10, unittest.hasLength(3));
  unittest.expect(
    casted10['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted10['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted10['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterKeyRange = 0;
api.KeyRange buildKeyRange() {
  var o = api.KeyRange();
  buildCounterKeyRange++;
  if (buildCounterKeyRange < 3) {
    o.endClosed = buildUnnamed1896();
    o.endOpen = buildUnnamed1897();
    o.startClosed = buildUnnamed1898();
    o.startOpen = buildUnnamed1899();
  }
  buildCounterKeyRange--;
  return o;
}

void checkKeyRange(api.KeyRange o) {
  buildCounterKeyRange++;
  if (buildCounterKeyRange < 3) {
    checkUnnamed1896(o.endClosed!);
    checkUnnamed1897(o.endOpen!);
    checkUnnamed1898(o.startClosed!);
    checkUnnamed1899(o.startOpen!);
  }
  buildCounterKeyRange--;
}

core.List<core.Object> buildUnnamed1900() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1900(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted11 = (o[0]) as core.Map;
  unittest.expect(casted11, unittest.hasLength(3));
  unittest.expect(
    casted11['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted11['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted11['string'],
    unittest.equals('foo'),
  );
  var casted12 = (o[1]) as core.Map;
  unittest.expect(casted12, unittest.hasLength(3));
  unittest.expect(
    casted12['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted12['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted12['string'],
    unittest.equals('foo'),
  );
}

core.List<core.List<core.Object>> buildUnnamed1901() {
  var o = <core.List<core.Object>>[];
  o.add(buildUnnamed1900());
  o.add(buildUnnamed1900());
  return o;
}

void checkUnnamed1901(core.List<core.List<core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1900(o[0]);
  checkUnnamed1900(o[1]);
}

core.List<api.KeyRange> buildUnnamed1902() {
  var o = <api.KeyRange>[];
  o.add(buildKeyRange());
  o.add(buildKeyRange());
  return o;
}

void checkUnnamed1902(core.List<api.KeyRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkKeyRange(o[0] as api.KeyRange);
  checkKeyRange(o[1] as api.KeyRange);
}

core.int buildCounterKeySet = 0;
api.KeySet buildKeySet() {
  var o = api.KeySet();
  buildCounterKeySet++;
  if (buildCounterKeySet < 3) {
    o.all = true;
    o.keys = buildUnnamed1901();
    o.ranges = buildUnnamed1902();
  }
  buildCounterKeySet--;
  return o;
}

void checkKeySet(api.KeySet o) {
  buildCounterKeySet++;
  if (buildCounterKeySet < 3) {
    unittest.expect(o.all!, unittest.isTrue);
    checkUnnamed1901(o.keys!);
    checkUnnamed1902(o.ranges!);
  }
  buildCounterKeySet--;
}

core.List<api.Operation> buildUnnamed1903() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed1903(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterListBackupOperationsResponse = 0;
api.ListBackupOperationsResponse buildListBackupOperationsResponse() {
  var o = api.ListBackupOperationsResponse();
  buildCounterListBackupOperationsResponse++;
  if (buildCounterListBackupOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed1903();
  }
  buildCounterListBackupOperationsResponse--;
  return o;
}

void checkListBackupOperationsResponse(api.ListBackupOperationsResponse o) {
  buildCounterListBackupOperationsResponse++;
  if (buildCounterListBackupOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1903(o.operations!);
  }
  buildCounterListBackupOperationsResponse--;
}

core.List<api.Backup> buildUnnamed1904() {
  var o = <api.Backup>[];
  o.add(buildBackup());
  o.add(buildBackup());
  return o;
}

void checkUnnamed1904(core.List<api.Backup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBackup(o[0] as api.Backup);
  checkBackup(o[1] as api.Backup);
}

core.int buildCounterListBackupsResponse = 0;
api.ListBackupsResponse buildListBackupsResponse() {
  var o = api.ListBackupsResponse();
  buildCounterListBackupsResponse++;
  if (buildCounterListBackupsResponse < 3) {
    o.backups = buildUnnamed1904();
    o.nextPageToken = 'foo';
  }
  buildCounterListBackupsResponse--;
  return o;
}

void checkListBackupsResponse(api.ListBackupsResponse o) {
  buildCounterListBackupsResponse++;
  if (buildCounterListBackupsResponse < 3) {
    checkUnnamed1904(o.backups!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListBackupsResponse--;
}

core.List<api.Operation> buildUnnamed1905() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed1905(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterListDatabaseOperationsResponse = 0;
api.ListDatabaseOperationsResponse buildListDatabaseOperationsResponse() {
  var o = api.ListDatabaseOperationsResponse();
  buildCounterListDatabaseOperationsResponse++;
  if (buildCounterListDatabaseOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed1905();
  }
  buildCounterListDatabaseOperationsResponse--;
  return o;
}

void checkListDatabaseOperationsResponse(api.ListDatabaseOperationsResponse o) {
  buildCounterListDatabaseOperationsResponse++;
  if (buildCounterListDatabaseOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1905(o.operations!);
  }
  buildCounterListDatabaseOperationsResponse--;
}

core.List<api.Database> buildUnnamed1906() {
  var o = <api.Database>[];
  o.add(buildDatabase());
  o.add(buildDatabase());
  return o;
}

void checkUnnamed1906(core.List<api.Database> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDatabase(o[0] as api.Database);
  checkDatabase(o[1] as api.Database);
}

core.int buildCounterListDatabasesResponse = 0;
api.ListDatabasesResponse buildListDatabasesResponse() {
  var o = api.ListDatabasesResponse();
  buildCounterListDatabasesResponse++;
  if (buildCounterListDatabasesResponse < 3) {
    o.databases = buildUnnamed1906();
    o.nextPageToken = 'foo';
  }
  buildCounterListDatabasesResponse--;
  return o;
}

void checkListDatabasesResponse(api.ListDatabasesResponse o) {
  buildCounterListDatabasesResponse++;
  if (buildCounterListDatabasesResponse < 3) {
    checkUnnamed1906(o.databases!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDatabasesResponse--;
}

core.List<api.InstanceConfig> buildUnnamed1907() {
  var o = <api.InstanceConfig>[];
  o.add(buildInstanceConfig());
  o.add(buildInstanceConfig());
  return o;
}

void checkUnnamed1907(core.List<api.InstanceConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInstanceConfig(o[0] as api.InstanceConfig);
  checkInstanceConfig(o[1] as api.InstanceConfig);
}

core.int buildCounterListInstanceConfigsResponse = 0;
api.ListInstanceConfigsResponse buildListInstanceConfigsResponse() {
  var o = api.ListInstanceConfigsResponse();
  buildCounterListInstanceConfigsResponse++;
  if (buildCounterListInstanceConfigsResponse < 3) {
    o.instanceConfigs = buildUnnamed1907();
    o.nextPageToken = 'foo';
  }
  buildCounterListInstanceConfigsResponse--;
  return o;
}

void checkListInstanceConfigsResponse(api.ListInstanceConfigsResponse o) {
  buildCounterListInstanceConfigsResponse++;
  if (buildCounterListInstanceConfigsResponse < 3) {
    checkUnnamed1907(o.instanceConfigs!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInstanceConfigsResponse--;
}

core.List<api.Instance> buildUnnamed1908() {
  var o = <api.Instance>[];
  o.add(buildInstance());
  o.add(buildInstance());
  return o;
}

void checkUnnamed1908(core.List<api.Instance> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInstance(o[0] as api.Instance);
  checkInstance(o[1] as api.Instance);
}

core.List<core.String> buildUnnamed1909() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1909(core.List<core.String> o) {
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

core.int buildCounterListInstancesResponse = 0;
api.ListInstancesResponse buildListInstancesResponse() {
  var o = api.ListInstancesResponse();
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    o.instances = buildUnnamed1908();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed1909();
  }
  buildCounterListInstancesResponse--;
  return o;
}

void checkListInstancesResponse(api.ListInstancesResponse o) {
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    checkUnnamed1908(o.instances!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1909(o.unreachable!);
  }
  buildCounterListInstancesResponse--;
}

core.List<api.Operation> buildUnnamed1910() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed1910(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterListOperationsResponse = 0;
api.ListOperationsResponse buildListOperationsResponse() {
  var o = api.ListOperationsResponse();
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed1910();
  }
  buildCounterListOperationsResponse--;
  return o;
}

void checkListOperationsResponse(api.ListOperationsResponse o) {
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1910(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.Session> buildUnnamed1911() {
  var o = <api.Session>[];
  o.add(buildSession());
  o.add(buildSession());
  return o;
}

void checkUnnamed1911(core.List<api.Session> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSession(o[0] as api.Session);
  checkSession(o[1] as api.Session);
}

core.int buildCounterListSessionsResponse = 0;
api.ListSessionsResponse buildListSessionsResponse() {
  var o = api.ListSessionsResponse();
  buildCounterListSessionsResponse++;
  if (buildCounterListSessionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.sessions = buildUnnamed1911();
  }
  buildCounterListSessionsResponse--;
  return o;
}

void checkListSessionsResponse(api.ListSessionsResponse o) {
  buildCounterListSessionsResponse++;
  if (buildCounterListSessionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1911(o.sessions!);
  }
  buildCounterListSessionsResponse--;
}

core.int buildCounterMutation = 0;
api.Mutation buildMutation() {
  var o = api.Mutation();
  buildCounterMutation++;
  if (buildCounterMutation < 3) {
    o.delete = buildDelete();
    o.insert = buildWrite();
    o.insertOrUpdate = buildWrite();
    o.replace = buildWrite();
    o.update = buildWrite();
  }
  buildCounterMutation--;
  return o;
}

void checkMutation(api.Mutation o) {
  buildCounterMutation++;
  if (buildCounterMutation < 3) {
    checkDelete(o.delete! as api.Delete);
    checkWrite(o.insert! as api.Write);
    checkWrite(o.insertOrUpdate! as api.Write);
    checkWrite(o.replace! as api.Write);
    checkWrite(o.update! as api.Write);
  }
  buildCounterMutation--;
}

core.Map<core.String, core.Object> buildUnnamed1912() {
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

void checkUnnamed1912(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted13 = (o['x']!) as core.Map;
  unittest.expect(casted13, unittest.hasLength(3));
  unittest.expect(
    casted13['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted13['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted13['string'],
    unittest.equals('foo'),
  );
  var casted14 = (o['y']!) as core.Map;
  unittest.expect(casted14, unittest.hasLength(3));
  unittest.expect(
    casted14['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted14['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted14['string'],
    unittest.equals('foo'),
  );
}

core.Map<core.String, core.Object> buildUnnamed1913() {
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

void checkUnnamed1913(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted15 = (o['x']!) as core.Map;
  unittest.expect(casted15, unittest.hasLength(3));
  unittest.expect(
    casted15['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted15['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted15['string'],
    unittest.equals('foo'),
  );
  var casted16 = (o['y']!) as core.Map;
  unittest.expect(casted16, unittest.hasLength(3));
  unittest.expect(
    casted16['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted16['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted16['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed1912();
    o.name = 'foo';
    o.response = buildUnnamed1913();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed1912(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1913(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationProgress = 0;
api.OperationProgress buildOperationProgress() {
  var o = api.OperationProgress();
  buildCounterOperationProgress++;
  if (buildCounterOperationProgress < 3) {
    o.endTime = 'foo';
    o.progressPercent = 42;
    o.startTime = 'foo';
  }
  buildCounterOperationProgress--;
  return o;
}

void checkOperationProgress(api.OperationProgress o) {
  buildCounterOperationProgress++;
  if (buildCounterOperationProgress < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationProgress--;
}

core.int buildCounterOptimizeRestoredDatabaseMetadata = 0;
api.OptimizeRestoredDatabaseMetadata buildOptimizeRestoredDatabaseMetadata() {
  var o = api.OptimizeRestoredDatabaseMetadata();
  buildCounterOptimizeRestoredDatabaseMetadata++;
  if (buildCounterOptimizeRestoredDatabaseMetadata < 3) {
    o.name = 'foo';
    o.progress = buildOperationProgress();
  }
  buildCounterOptimizeRestoredDatabaseMetadata--;
  return o;
}

void checkOptimizeRestoredDatabaseMetadata(
    api.OptimizeRestoredDatabaseMetadata o) {
  buildCounterOptimizeRestoredDatabaseMetadata++;
  if (buildCounterOptimizeRestoredDatabaseMetadata < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkOperationProgress(o.progress! as api.OperationProgress);
  }
  buildCounterOptimizeRestoredDatabaseMetadata--;
}

core.List<core.Object> buildUnnamed1914() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1914(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted17 = (o[0]) as core.Map;
  unittest.expect(casted17, unittest.hasLength(3));
  unittest.expect(
    casted17['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted17['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted17['string'],
    unittest.equals('foo'),
  );
  var casted18 = (o[1]) as core.Map;
  unittest.expect(casted18, unittest.hasLength(3));
  unittest.expect(
    casted18['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted18['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted18['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterPartialResultSet = 0;
api.PartialResultSet buildPartialResultSet() {
  var o = api.PartialResultSet();
  buildCounterPartialResultSet++;
  if (buildCounterPartialResultSet < 3) {
    o.chunkedValue = true;
    o.metadata = buildResultSetMetadata();
    o.resumeToken = 'foo';
    o.stats = buildResultSetStats();
    o.values = buildUnnamed1914();
  }
  buildCounterPartialResultSet--;
  return o;
}

void checkPartialResultSet(api.PartialResultSet o) {
  buildCounterPartialResultSet++;
  if (buildCounterPartialResultSet < 3) {
    unittest.expect(o.chunkedValue!, unittest.isTrue);
    checkResultSetMetadata(o.metadata! as api.ResultSetMetadata);
    unittest.expect(
      o.resumeToken!,
      unittest.equals('foo'),
    );
    checkResultSetStats(o.stats! as api.ResultSetStats);
    checkUnnamed1914(o.values!);
  }
  buildCounterPartialResultSet--;
}

core.int buildCounterPartition = 0;
api.Partition buildPartition() {
  var o = api.Partition();
  buildCounterPartition++;
  if (buildCounterPartition < 3) {
    o.partitionToken = 'foo';
  }
  buildCounterPartition--;
  return o;
}

void checkPartition(api.Partition o) {
  buildCounterPartition++;
  if (buildCounterPartition < 3) {
    unittest.expect(
      o.partitionToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartition--;
}

core.int buildCounterPartitionOptions = 0;
api.PartitionOptions buildPartitionOptions() {
  var o = api.PartitionOptions();
  buildCounterPartitionOptions++;
  if (buildCounterPartitionOptions < 3) {
    o.maxPartitions = 'foo';
    o.partitionSizeBytes = 'foo';
  }
  buildCounterPartitionOptions--;
  return o;
}

void checkPartitionOptions(api.PartitionOptions o) {
  buildCounterPartitionOptions++;
  if (buildCounterPartitionOptions < 3) {
    unittest.expect(
      o.maxPartitions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partitionSizeBytes!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartitionOptions--;
}

core.Map<core.String, api.Type> buildUnnamed1915() {
  var o = <core.String, api.Type>{};
  o['x'] = buildType();
  o['y'] = buildType();
  return o;
}

void checkUnnamed1915(core.Map<core.String, api.Type> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkType(o['x']! as api.Type);
  checkType(o['y']! as api.Type);
}

core.Map<core.String, core.Object> buildUnnamed1916() {
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

void checkUnnamed1916(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted19 = (o['x']!) as core.Map;
  unittest.expect(casted19, unittest.hasLength(3));
  unittest.expect(
    casted19['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted19['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted19['string'],
    unittest.equals('foo'),
  );
  var casted20 = (o['y']!) as core.Map;
  unittest.expect(casted20, unittest.hasLength(3));
  unittest.expect(
    casted20['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted20['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted20['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterPartitionQueryRequest = 0;
api.PartitionQueryRequest buildPartitionQueryRequest() {
  var o = api.PartitionQueryRequest();
  buildCounterPartitionQueryRequest++;
  if (buildCounterPartitionQueryRequest < 3) {
    o.paramTypes = buildUnnamed1915();
    o.params = buildUnnamed1916();
    o.partitionOptions = buildPartitionOptions();
    o.sql = 'foo';
    o.transaction = buildTransactionSelector();
  }
  buildCounterPartitionQueryRequest--;
  return o;
}

void checkPartitionQueryRequest(api.PartitionQueryRequest o) {
  buildCounterPartitionQueryRequest++;
  if (buildCounterPartitionQueryRequest < 3) {
    checkUnnamed1915(o.paramTypes!);
    checkUnnamed1916(o.params!);
    checkPartitionOptions(o.partitionOptions! as api.PartitionOptions);
    unittest.expect(
      o.sql!,
      unittest.equals('foo'),
    );
    checkTransactionSelector(o.transaction! as api.TransactionSelector);
  }
  buildCounterPartitionQueryRequest--;
}

core.List<core.String> buildUnnamed1917() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1917(core.List<core.String> o) {
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

core.int buildCounterPartitionReadRequest = 0;
api.PartitionReadRequest buildPartitionReadRequest() {
  var o = api.PartitionReadRequest();
  buildCounterPartitionReadRequest++;
  if (buildCounterPartitionReadRequest < 3) {
    o.columns = buildUnnamed1917();
    o.index = 'foo';
    o.keySet = buildKeySet();
    o.partitionOptions = buildPartitionOptions();
    o.table = 'foo';
    o.transaction = buildTransactionSelector();
  }
  buildCounterPartitionReadRequest--;
  return o;
}

void checkPartitionReadRequest(api.PartitionReadRequest o) {
  buildCounterPartitionReadRequest++;
  if (buildCounterPartitionReadRequest < 3) {
    checkUnnamed1917(o.columns!);
    unittest.expect(
      o.index!,
      unittest.equals('foo'),
    );
    checkKeySet(o.keySet! as api.KeySet);
    checkPartitionOptions(o.partitionOptions! as api.PartitionOptions);
    unittest.expect(
      o.table!,
      unittest.equals('foo'),
    );
    checkTransactionSelector(o.transaction! as api.TransactionSelector);
  }
  buildCounterPartitionReadRequest--;
}

core.List<api.Partition> buildUnnamed1918() {
  var o = <api.Partition>[];
  o.add(buildPartition());
  o.add(buildPartition());
  return o;
}

void checkUnnamed1918(core.List<api.Partition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPartition(o[0] as api.Partition);
  checkPartition(o[1] as api.Partition);
}

core.int buildCounterPartitionResponse = 0;
api.PartitionResponse buildPartitionResponse() {
  var o = api.PartitionResponse();
  buildCounterPartitionResponse++;
  if (buildCounterPartitionResponse < 3) {
    o.partitions = buildUnnamed1918();
    o.transaction = buildTransaction();
  }
  buildCounterPartitionResponse--;
  return o;
}

void checkPartitionResponse(api.PartitionResponse o) {
  buildCounterPartitionResponse++;
  if (buildCounterPartitionResponse < 3) {
    checkUnnamed1918(o.partitions!);
    checkTransaction(o.transaction! as api.Transaction);
  }
  buildCounterPartitionResponse--;
}

core.int buildCounterPartitionedDml = 0;
api.PartitionedDml buildPartitionedDml() {
  var o = api.PartitionedDml();
  buildCounterPartitionedDml++;
  if (buildCounterPartitionedDml < 3) {}
  buildCounterPartitionedDml--;
  return o;
}

void checkPartitionedDml(api.PartitionedDml o) {
  buildCounterPartitionedDml++;
  if (buildCounterPartitionedDml < 3) {}
  buildCounterPartitionedDml--;
}

core.List<api.ChildLink> buildUnnamed1919() {
  var o = <api.ChildLink>[];
  o.add(buildChildLink());
  o.add(buildChildLink());
  return o;
}

void checkUnnamed1919(core.List<api.ChildLink> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChildLink(o[0] as api.ChildLink);
  checkChildLink(o[1] as api.ChildLink);
}

core.Map<core.String, core.Object> buildUnnamed1920() {
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

void checkUnnamed1920(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted21 = (o['x']!) as core.Map;
  unittest.expect(casted21, unittest.hasLength(3));
  unittest.expect(
    casted21['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted21['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted21['string'],
    unittest.equals('foo'),
  );
  var casted22 = (o['y']!) as core.Map;
  unittest.expect(casted22, unittest.hasLength(3));
  unittest.expect(
    casted22['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted22['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted22['string'],
    unittest.equals('foo'),
  );
}

core.Map<core.String, core.Object> buildUnnamed1921() {
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

void checkUnnamed1921(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted23 = (o['x']!) as core.Map;
  unittest.expect(casted23, unittest.hasLength(3));
  unittest.expect(
    casted23['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted23['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted23['string'],
    unittest.equals('foo'),
  );
  var casted24 = (o['y']!) as core.Map;
  unittest.expect(casted24, unittest.hasLength(3));
  unittest.expect(
    casted24['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted24['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted24['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterPlanNode = 0;
api.PlanNode buildPlanNode() {
  var o = api.PlanNode();
  buildCounterPlanNode++;
  if (buildCounterPlanNode < 3) {
    o.childLinks = buildUnnamed1919();
    o.displayName = 'foo';
    o.executionStats = buildUnnamed1920();
    o.index = 42;
    o.kind = 'foo';
    o.metadata = buildUnnamed1921();
    o.shortRepresentation = buildShortRepresentation();
  }
  buildCounterPlanNode--;
  return o;
}

void checkPlanNode(api.PlanNode o) {
  buildCounterPlanNode++;
  if (buildCounterPlanNode < 3) {
    checkUnnamed1919(o.childLinks!);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed1920(o.executionStats!);
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1921(o.metadata!);
    checkShortRepresentation(o.shortRepresentation! as api.ShortRepresentation);
  }
  buildCounterPlanNode--;
}

core.List<api.Binding> buildUnnamed1922() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed1922(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.bindings = buildUnnamed1922();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed1922(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterPolicy--;
}

core.int buildCounterQueryOptions = 0;
api.QueryOptions buildQueryOptions() {
  var o = api.QueryOptions();
  buildCounterQueryOptions++;
  if (buildCounterQueryOptions < 3) {
    o.optimizerStatisticsPackage = 'foo';
    o.optimizerVersion = 'foo';
  }
  buildCounterQueryOptions--;
  return o;
}

void checkQueryOptions(api.QueryOptions o) {
  buildCounterQueryOptions++;
  if (buildCounterQueryOptions < 3) {
    unittest.expect(
      o.optimizerStatisticsPackage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.optimizerVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryOptions--;
}

core.List<api.PlanNode> buildUnnamed1923() {
  var o = <api.PlanNode>[];
  o.add(buildPlanNode());
  o.add(buildPlanNode());
  return o;
}

void checkUnnamed1923(core.List<api.PlanNode> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlanNode(o[0] as api.PlanNode);
  checkPlanNode(o[1] as api.PlanNode);
}

core.int buildCounterQueryPlan = 0;
api.QueryPlan buildQueryPlan() {
  var o = api.QueryPlan();
  buildCounterQueryPlan++;
  if (buildCounterQueryPlan < 3) {
    o.planNodes = buildUnnamed1923();
  }
  buildCounterQueryPlan--;
  return o;
}

void checkQueryPlan(api.QueryPlan o) {
  buildCounterQueryPlan++;
  if (buildCounterQueryPlan < 3) {
    checkUnnamed1923(o.planNodes!);
  }
  buildCounterQueryPlan--;
}

core.int buildCounterReadOnly = 0;
api.ReadOnly buildReadOnly() {
  var o = api.ReadOnly();
  buildCounterReadOnly++;
  if (buildCounterReadOnly < 3) {
    o.exactStaleness = 'foo';
    o.maxStaleness = 'foo';
    o.minReadTimestamp = 'foo';
    o.readTimestamp = 'foo';
    o.returnReadTimestamp = true;
    o.strong = true;
  }
  buildCounterReadOnly--;
  return o;
}

void checkReadOnly(api.ReadOnly o) {
  buildCounterReadOnly++;
  if (buildCounterReadOnly < 3) {
    unittest.expect(
      o.exactStaleness!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxStaleness!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minReadTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(o.returnReadTimestamp!, unittest.isTrue);
    unittest.expect(o.strong!, unittest.isTrue);
  }
  buildCounterReadOnly--;
}

core.List<core.String> buildUnnamed1924() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1924(core.List<core.String> o) {
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

core.int buildCounterReadRequest = 0;
api.ReadRequest buildReadRequest() {
  var o = api.ReadRequest();
  buildCounterReadRequest++;
  if (buildCounterReadRequest < 3) {
    o.columns = buildUnnamed1924();
    o.index = 'foo';
    o.keySet = buildKeySet();
    o.limit = 'foo';
    o.partitionToken = 'foo';
    o.requestOptions = buildRequestOptions();
    o.resumeToken = 'foo';
    o.table = 'foo';
    o.transaction = buildTransactionSelector();
  }
  buildCounterReadRequest--;
  return o;
}

void checkReadRequest(api.ReadRequest o) {
  buildCounterReadRequest++;
  if (buildCounterReadRequest < 3) {
    checkUnnamed1924(o.columns!);
    unittest.expect(
      o.index!,
      unittest.equals('foo'),
    );
    checkKeySet(o.keySet! as api.KeySet);
    unittest.expect(
      o.limit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partitionToken!,
      unittest.equals('foo'),
    );
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
    unittest.expect(
      o.resumeToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.table!,
      unittest.equals('foo'),
    );
    checkTransactionSelector(o.transaction! as api.TransactionSelector);
  }
  buildCounterReadRequest--;
}

core.int buildCounterReadWrite = 0;
api.ReadWrite buildReadWrite() {
  var o = api.ReadWrite();
  buildCounterReadWrite++;
  if (buildCounterReadWrite < 3) {}
  buildCounterReadWrite--;
  return o;
}

void checkReadWrite(api.ReadWrite o) {
  buildCounterReadWrite++;
  if (buildCounterReadWrite < 3) {}
  buildCounterReadWrite--;
}

core.int buildCounterReplicaInfo = 0;
api.ReplicaInfo buildReplicaInfo() {
  var o = api.ReplicaInfo();
  buildCounterReplicaInfo++;
  if (buildCounterReplicaInfo < 3) {
    o.defaultLeaderLocation = true;
    o.location = 'foo';
    o.type = 'foo';
  }
  buildCounterReplicaInfo--;
  return o;
}

void checkReplicaInfo(api.ReplicaInfo o) {
  buildCounterReplicaInfo++;
  if (buildCounterReplicaInfo < 3) {
    unittest.expect(o.defaultLeaderLocation!, unittest.isTrue);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplicaInfo--;
}

core.int buildCounterRequestOptions = 0;
api.RequestOptions buildRequestOptions() {
  var o = api.RequestOptions();
  buildCounterRequestOptions++;
  if (buildCounterRequestOptions < 3) {
    o.priority = 'foo';
    o.requestTag = 'foo';
    o.transactionTag = 'foo';
  }
  buildCounterRequestOptions--;
  return o;
}

void checkRequestOptions(api.RequestOptions o) {
  buildCounterRequestOptions++;
  if (buildCounterRequestOptions < 3) {
    unittest.expect(
      o.priority!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transactionTag!,
      unittest.equals('foo'),
    );
  }
  buildCounterRequestOptions--;
}

core.int buildCounterRestoreDatabaseEncryptionConfig = 0;
api.RestoreDatabaseEncryptionConfig buildRestoreDatabaseEncryptionConfig() {
  var o = api.RestoreDatabaseEncryptionConfig();
  buildCounterRestoreDatabaseEncryptionConfig++;
  if (buildCounterRestoreDatabaseEncryptionConfig < 3) {
    o.encryptionType = 'foo';
    o.kmsKeyName = 'foo';
  }
  buildCounterRestoreDatabaseEncryptionConfig--;
  return o;
}

void checkRestoreDatabaseEncryptionConfig(
    api.RestoreDatabaseEncryptionConfig o) {
  buildCounterRestoreDatabaseEncryptionConfig++;
  if (buildCounterRestoreDatabaseEncryptionConfig < 3) {
    unittest.expect(
      o.encryptionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
  }
  buildCounterRestoreDatabaseEncryptionConfig--;
}

core.int buildCounterRestoreDatabaseMetadata = 0;
api.RestoreDatabaseMetadata buildRestoreDatabaseMetadata() {
  var o = api.RestoreDatabaseMetadata();
  buildCounterRestoreDatabaseMetadata++;
  if (buildCounterRestoreDatabaseMetadata < 3) {
    o.backupInfo = buildBackupInfo();
    o.cancelTime = 'foo';
    o.name = 'foo';
    o.optimizeDatabaseOperationName = 'foo';
    o.progress = buildOperationProgress();
    o.sourceType = 'foo';
  }
  buildCounterRestoreDatabaseMetadata--;
  return o;
}

void checkRestoreDatabaseMetadata(api.RestoreDatabaseMetadata o) {
  buildCounterRestoreDatabaseMetadata++;
  if (buildCounterRestoreDatabaseMetadata < 3) {
    checkBackupInfo(o.backupInfo! as api.BackupInfo);
    unittest.expect(
      o.cancelTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.optimizeDatabaseOperationName!,
      unittest.equals('foo'),
    );
    checkOperationProgress(o.progress! as api.OperationProgress);
    unittest.expect(
      o.sourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRestoreDatabaseMetadata--;
}

core.int buildCounterRestoreDatabaseRequest = 0;
api.RestoreDatabaseRequest buildRestoreDatabaseRequest() {
  var o = api.RestoreDatabaseRequest();
  buildCounterRestoreDatabaseRequest++;
  if (buildCounterRestoreDatabaseRequest < 3) {
    o.backup = 'foo';
    o.databaseId = 'foo';
    o.encryptionConfig = buildRestoreDatabaseEncryptionConfig();
  }
  buildCounterRestoreDatabaseRequest--;
  return o;
}

void checkRestoreDatabaseRequest(api.RestoreDatabaseRequest o) {
  buildCounterRestoreDatabaseRequest++;
  if (buildCounterRestoreDatabaseRequest < 3) {
    unittest.expect(
      o.backup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.databaseId!,
      unittest.equals('foo'),
    );
    checkRestoreDatabaseEncryptionConfig(
        o.encryptionConfig! as api.RestoreDatabaseEncryptionConfig);
  }
  buildCounterRestoreDatabaseRequest--;
}

core.int buildCounterRestoreInfo = 0;
api.RestoreInfo buildRestoreInfo() {
  var o = api.RestoreInfo();
  buildCounterRestoreInfo++;
  if (buildCounterRestoreInfo < 3) {
    o.backupInfo = buildBackupInfo();
    o.sourceType = 'foo';
  }
  buildCounterRestoreInfo--;
  return o;
}

void checkRestoreInfo(api.RestoreInfo o) {
  buildCounterRestoreInfo++;
  if (buildCounterRestoreInfo < 3) {
    checkBackupInfo(o.backupInfo! as api.BackupInfo);
    unittest.expect(
      o.sourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRestoreInfo--;
}

core.List<core.Object> buildUnnamed1925() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1925(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted25 = (o[0]) as core.Map;
  unittest.expect(casted25, unittest.hasLength(3));
  unittest.expect(
    casted25['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted25['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted25['string'],
    unittest.equals('foo'),
  );
  var casted26 = (o[1]) as core.Map;
  unittest.expect(casted26, unittest.hasLength(3));
  unittest.expect(
    casted26['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted26['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted26['string'],
    unittest.equals('foo'),
  );
}

core.List<core.List<core.Object>> buildUnnamed1926() {
  var o = <core.List<core.Object>>[];
  o.add(buildUnnamed1925());
  o.add(buildUnnamed1925());
  return o;
}

void checkUnnamed1926(core.List<core.List<core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1925(o[0]);
  checkUnnamed1925(o[1]);
}

core.int buildCounterResultSet = 0;
api.ResultSet buildResultSet() {
  var o = api.ResultSet();
  buildCounterResultSet++;
  if (buildCounterResultSet < 3) {
    o.metadata = buildResultSetMetadata();
    o.rows = buildUnnamed1926();
    o.stats = buildResultSetStats();
  }
  buildCounterResultSet--;
  return o;
}

void checkResultSet(api.ResultSet o) {
  buildCounterResultSet++;
  if (buildCounterResultSet < 3) {
    checkResultSetMetadata(o.metadata! as api.ResultSetMetadata);
    checkUnnamed1926(o.rows!);
    checkResultSetStats(o.stats! as api.ResultSetStats);
  }
  buildCounterResultSet--;
}

core.int buildCounterResultSetMetadata = 0;
api.ResultSetMetadata buildResultSetMetadata() {
  var o = api.ResultSetMetadata();
  buildCounterResultSetMetadata++;
  if (buildCounterResultSetMetadata < 3) {
    o.rowType = buildStructType();
    o.transaction = buildTransaction();
  }
  buildCounterResultSetMetadata--;
  return o;
}

void checkResultSetMetadata(api.ResultSetMetadata o) {
  buildCounterResultSetMetadata++;
  if (buildCounterResultSetMetadata < 3) {
    checkStructType(o.rowType! as api.StructType);
    checkTransaction(o.transaction! as api.Transaction);
  }
  buildCounterResultSetMetadata--;
}

core.Map<core.String, core.Object> buildUnnamed1927() {
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

void checkUnnamed1927(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted27 = (o['x']!) as core.Map;
  unittest.expect(casted27, unittest.hasLength(3));
  unittest.expect(
    casted27['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted27['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted27['string'],
    unittest.equals('foo'),
  );
  var casted28 = (o['y']!) as core.Map;
  unittest.expect(casted28, unittest.hasLength(3));
  unittest.expect(
    casted28['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted28['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted28['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterResultSetStats = 0;
api.ResultSetStats buildResultSetStats() {
  var o = api.ResultSetStats();
  buildCounterResultSetStats++;
  if (buildCounterResultSetStats < 3) {
    o.queryPlan = buildQueryPlan();
    o.queryStats = buildUnnamed1927();
    o.rowCountExact = 'foo';
    o.rowCountLowerBound = 'foo';
  }
  buildCounterResultSetStats--;
  return o;
}

void checkResultSetStats(api.ResultSetStats o) {
  buildCounterResultSetStats++;
  if (buildCounterResultSetStats < 3) {
    checkQueryPlan(o.queryPlan! as api.QueryPlan);
    checkUnnamed1927(o.queryStats!);
    unittest.expect(
      o.rowCountExact!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rowCountLowerBound!,
      unittest.equals('foo'),
    );
  }
  buildCounterResultSetStats--;
}

core.int buildCounterRollbackRequest = 0;
api.RollbackRequest buildRollbackRequest() {
  var o = api.RollbackRequest();
  buildCounterRollbackRequest++;
  if (buildCounterRollbackRequest < 3) {
    o.transactionId = 'foo';
  }
  buildCounterRollbackRequest--;
  return o;
}

void checkRollbackRequest(api.RollbackRequest o) {
  buildCounterRollbackRequest++;
  if (buildCounterRollbackRequest < 3) {
    unittest.expect(
      o.transactionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRollbackRequest--;
}

core.Map<core.String, core.String> buildUnnamed1928() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1928(core.Map<core.String, core.String> o) {
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

core.int buildCounterSession = 0;
api.Session buildSession() {
  var o = api.Session();
  buildCounterSession++;
  if (buildCounterSession < 3) {
    o.approximateLastUseTime = 'foo';
    o.createTime = 'foo';
    o.labels = buildUnnamed1928();
    o.name = 'foo';
  }
  buildCounterSession--;
  return o;
}

void checkSession(api.Session o) {
  buildCounterSession++;
  if (buildCounterSession < 3) {
    unittest.expect(
      o.approximateLastUseTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUnnamed1928(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSession--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildPolicy();
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkPolicy(o.policy! as api.Policy);
  }
  buildCounterSetIamPolicyRequest--;
}

core.Map<core.String, core.int> buildUnnamed1929() {
  var o = <core.String, core.int>{};
  o['x'] = 42;
  o['y'] = 42;
  return o;
}

void checkUnnamed1929(core.Map<core.String, core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals(42),
  );
  unittest.expect(
    o['y']!,
    unittest.equals(42),
  );
}

core.int buildCounterShortRepresentation = 0;
api.ShortRepresentation buildShortRepresentation() {
  var o = api.ShortRepresentation();
  buildCounterShortRepresentation++;
  if (buildCounterShortRepresentation < 3) {
    o.description = 'foo';
    o.subqueries = buildUnnamed1929();
  }
  buildCounterShortRepresentation--;
  return o;
}

void checkShortRepresentation(api.ShortRepresentation o) {
  buildCounterShortRepresentation++;
  if (buildCounterShortRepresentation < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed1929(o.subqueries!);
  }
  buildCounterShortRepresentation--;
}

core.Map<core.String, api.Type> buildUnnamed1930() {
  var o = <core.String, api.Type>{};
  o['x'] = buildType();
  o['y'] = buildType();
  return o;
}

void checkUnnamed1930(core.Map<core.String, api.Type> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkType(o['x']! as api.Type);
  checkType(o['y']! as api.Type);
}

core.Map<core.String, core.Object> buildUnnamed1931() {
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

void checkUnnamed1931(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted29 = (o['x']!) as core.Map;
  unittest.expect(casted29, unittest.hasLength(3));
  unittest.expect(
    casted29['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted29['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted29['string'],
    unittest.equals('foo'),
  );
  var casted30 = (o['y']!) as core.Map;
  unittest.expect(casted30, unittest.hasLength(3));
  unittest.expect(
    casted30['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted30['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted30['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterStatement = 0;
api.Statement buildStatement() {
  var o = api.Statement();
  buildCounterStatement++;
  if (buildCounterStatement < 3) {
    o.paramTypes = buildUnnamed1930();
    o.params = buildUnnamed1931();
    o.sql = 'foo';
  }
  buildCounterStatement--;
  return o;
}

void checkStatement(api.Statement o) {
  buildCounterStatement++;
  if (buildCounterStatement < 3) {
    checkUnnamed1930(o.paramTypes!);
    checkUnnamed1931(o.params!);
    unittest.expect(
      o.sql!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatement--;
}

core.Map<core.String, core.Object> buildUnnamed1932() {
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

void checkUnnamed1932(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted31 = (o['x']!) as core.Map;
  unittest.expect(casted31, unittest.hasLength(3));
  unittest.expect(
    casted31['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted31['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted31['string'],
    unittest.equals('foo'),
  );
  var casted32 = (o['y']!) as core.Map;
  unittest.expect(casted32, unittest.hasLength(3));
  unittest.expect(
    casted32['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted32['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted32['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed1933() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed1932());
  o.add(buildUnnamed1932());
  return o;
}

void checkUnnamed1933(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1932(o[0]);
  checkUnnamed1932(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed1933();
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
    checkUnnamed1933(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<api.Field> buildUnnamed1934() {
  var o = <api.Field>[];
  o.add(buildField());
  o.add(buildField());
  return o;
}

void checkUnnamed1934(core.List<api.Field> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkField(o[0] as api.Field);
  checkField(o[1] as api.Field);
}

core.int buildCounterStructType = 0;
api.StructType buildStructType() {
  var o = api.StructType();
  buildCounterStructType++;
  if (buildCounterStructType < 3) {
    o.fields = buildUnnamed1934();
  }
  buildCounterStructType--;
  return o;
}

void checkStructType(api.StructType o) {
  buildCounterStructType++;
  if (buildCounterStructType < 3) {
    checkUnnamed1934(o.fields!);
  }
  buildCounterStructType--;
}

core.List<core.String> buildUnnamed1935() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1935(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsRequest = 0;
api.TestIamPermissionsRequest buildTestIamPermissionsRequest() {
  var o = api.TestIamPermissionsRequest();
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    o.permissions = buildUnnamed1935();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed1935(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed1936() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1936(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsResponse = 0;
api.TestIamPermissionsResponse buildTestIamPermissionsResponse() {
  var o = api.TestIamPermissionsResponse();
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    o.permissions = buildUnnamed1936();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed1936(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterTransaction = 0;
api.Transaction buildTransaction() {
  var o = api.Transaction();
  buildCounterTransaction++;
  if (buildCounterTransaction < 3) {
    o.id = 'foo';
    o.readTimestamp = 'foo';
  }
  buildCounterTransaction--;
  return o;
}

void checkTransaction(api.Transaction o) {
  buildCounterTransaction++;
  if (buildCounterTransaction < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTimestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterTransaction--;
}

core.int buildCounterTransactionOptions = 0;
api.TransactionOptions buildTransactionOptions() {
  var o = api.TransactionOptions();
  buildCounterTransactionOptions++;
  if (buildCounterTransactionOptions < 3) {
    o.partitionedDml = buildPartitionedDml();
    o.readOnly = buildReadOnly();
    o.readWrite = buildReadWrite();
  }
  buildCounterTransactionOptions--;
  return o;
}

void checkTransactionOptions(api.TransactionOptions o) {
  buildCounterTransactionOptions++;
  if (buildCounterTransactionOptions < 3) {
    checkPartitionedDml(o.partitionedDml! as api.PartitionedDml);
    checkReadOnly(o.readOnly! as api.ReadOnly);
    checkReadWrite(o.readWrite! as api.ReadWrite);
  }
  buildCounterTransactionOptions--;
}

core.int buildCounterTransactionSelector = 0;
api.TransactionSelector buildTransactionSelector() {
  var o = api.TransactionSelector();
  buildCounterTransactionSelector++;
  if (buildCounterTransactionSelector < 3) {
    o.begin = buildTransactionOptions();
    o.id = 'foo';
    o.singleUse = buildTransactionOptions();
  }
  buildCounterTransactionSelector--;
  return o;
}

void checkTransactionSelector(api.TransactionSelector o) {
  buildCounterTransactionSelector++;
  if (buildCounterTransactionSelector < 3) {
    checkTransactionOptions(o.begin! as api.TransactionOptions);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkTransactionOptions(o.singleUse! as api.TransactionOptions);
  }
  buildCounterTransactionSelector--;
}

core.int buildCounterType = 0;
api.Type buildType() {
  var o = api.Type();
  buildCounterType++;
  if (buildCounterType < 3) {
    o.arrayElementType = buildType();
    o.code = 'foo';
    o.structType = buildStructType();
  }
  buildCounterType--;
  return o;
}

void checkType(api.Type o) {
  buildCounterType++;
  if (buildCounterType < 3) {
    checkType(o.arrayElementType! as api.Type);
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkStructType(o.structType! as api.StructType);
  }
  buildCounterType--;
}

core.List<core.String> buildUnnamed1937() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1937(core.List<core.String> o) {
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

core.List<api.OperationProgress> buildUnnamed1938() {
  var o = <api.OperationProgress>[];
  o.add(buildOperationProgress());
  o.add(buildOperationProgress());
  return o;
}

void checkUnnamed1938(core.List<api.OperationProgress> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperationProgress(o[0] as api.OperationProgress);
  checkOperationProgress(o[1] as api.OperationProgress);
}

core.List<core.String> buildUnnamed1939() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1939(core.List<core.String> o) {
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

core.int buildCounterUpdateDatabaseDdlMetadata = 0;
api.UpdateDatabaseDdlMetadata buildUpdateDatabaseDdlMetadata() {
  var o = api.UpdateDatabaseDdlMetadata();
  buildCounterUpdateDatabaseDdlMetadata++;
  if (buildCounterUpdateDatabaseDdlMetadata < 3) {
    o.commitTimestamps = buildUnnamed1937();
    o.database = 'foo';
    o.progress = buildUnnamed1938();
    o.statements = buildUnnamed1939();
    o.throttled = true;
  }
  buildCounterUpdateDatabaseDdlMetadata--;
  return o;
}

void checkUpdateDatabaseDdlMetadata(api.UpdateDatabaseDdlMetadata o) {
  buildCounterUpdateDatabaseDdlMetadata++;
  if (buildCounterUpdateDatabaseDdlMetadata < 3) {
    checkUnnamed1937(o.commitTimestamps!);
    unittest.expect(
      o.database!,
      unittest.equals('foo'),
    );
    checkUnnamed1938(o.progress!);
    checkUnnamed1939(o.statements!);
    unittest.expect(o.throttled!, unittest.isTrue);
  }
  buildCounterUpdateDatabaseDdlMetadata--;
}

core.List<core.String> buildUnnamed1940() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1940(core.List<core.String> o) {
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

core.int buildCounterUpdateDatabaseDdlRequest = 0;
api.UpdateDatabaseDdlRequest buildUpdateDatabaseDdlRequest() {
  var o = api.UpdateDatabaseDdlRequest();
  buildCounterUpdateDatabaseDdlRequest++;
  if (buildCounterUpdateDatabaseDdlRequest < 3) {
    o.operationId = 'foo';
    o.statements = buildUnnamed1940();
  }
  buildCounterUpdateDatabaseDdlRequest--;
  return o;
}

void checkUpdateDatabaseDdlRequest(api.UpdateDatabaseDdlRequest o) {
  buildCounterUpdateDatabaseDdlRequest++;
  if (buildCounterUpdateDatabaseDdlRequest < 3) {
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
    checkUnnamed1940(o.statements!);
  }
  buildCounterUpdateDatabaseDdlRequest--;
}

core.int buildCounterUpdateInstanceMetadata = 0;
api.UpdateInstanceMetadata buildUpdateInstanceMetadata() {
  var o = api.UpdateInstanceMetadata();
  buildCounterUpdateInstanceMetadata++;
  if (buildCounterUpdateInstanceMetadata < 3) {
    o.cancelTime = 'foo';
    o.endTime = 'foo';
    o.instance = buildInstance();
    o.startTime = 'foo';
  }
  buildCounterUpdateInstanceMetadata--;
  return o;
}

void checkUpdateInstanceMetadata(api.UpdateInstanceMetadata o) {
  buildCounterUpdateInstanceMetadata++;
  if (buildCounterUpdateInstanceMetadata < 3) {
    unittest.expect(
      o.cancelTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkInstance(o.instance! as api.Instance);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateInstanceMetadata--;
}

core.int buildCounterUpdateInstanceRequest = 0;
api.UpdateInstanceRequest buildUpdateInstanceRequest() {
  var o = api.UpdateInstanceRequest();
  buildCounterUpdateInstanceRequest++;
  if (buildCounterUpdateInstanceRequest < 3) {
    o.fieldMask = 'foo';
    o.instance = buildInstance();
  }
  buildCounterUpdateInstanceRequest--;
  return o;
}

void checkUpdateInstanceRequest(api.UpdateInstanceRequest o) {
  buildCounterUpdateInstanceRequest++;
  if (buildCounterUpdateInstanceRequest < 3) {
    unittest.expect(
      o.fieldMask!,
      unittest.equals('foo'),
    );
    checkInstance(o.instance! as api.Instance);
  }
  buildCounterUpdateInstanceRequest--;
}

core.List<core.String> buildUnnamed1941() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1941(core.List<core.String> o) {
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

core.List<core.Object> buildUnnamed1942() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1942(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted33 = (o[0]) as core.Map;
  unittest.expect(casted33, unittest.hasLength(3));
  unittest.expect(
    casted33['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted33['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted33['string'],
    unittest.equals('foo'),
  );
  var casted34 = (o[1]) as core.Map;
  unittest.expect(casted34, unittest.hasLength(3));
  unittest.expect(
    casted34['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted34['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted34['string'],
    unittest.equals('foo'),
  );
}

core.List<core.List<core.Object>> buildUnnamed1943() {
  var o = <core.List<core.Object>>[];
  o.add(buildUnnamed1942());
  o.add(buildUnnamed1942());
  return o;
}

void checkUnnamed1943(core.List<core.List<core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1942(o[0]);
  checkUnnamed1942(o[1]);
}

core.int buildCounterWrite = 0;
api.Write buildWrite() {
  var o = api.Write();
  buildCounterWrite++;
  if (buildCounterWrite < 3) {
    o.columns = buildUnnamed1941();
    o.table = 'foo';
    o.values = buildUnnamed1943();
  }
  buildCounterWrite--;
  return o;
}

void checkWrite(api.Write o) {
  buildCounterWrite++;
  if (buildCounterWrite < 3) {
    checkUnnamed1941(o.columns!);
    unittest.expect(
      o.table!,
      unittest.equals('foo'),
    );
    checkUnnamed1943(o.values!);
  }
  buildCounterWrite--;
}

void main() {
  unittest.group('obj-schema-Backup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBackup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Backup.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBackup(od as api.Backup);
    });
  });

  unittest.group('obj-schema-BackupInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBackupInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.BackupInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBackupInfo(od as api.BackupInfo);
    });
  });

  unittest.group('obj-schema-BatchCreateSessionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchCreateSessionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchCreateSessionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchCreateSessionsRequest(od as api.BatchCreateSessionsRequest);
    });
  });

  unittest.group('obj-schema-BatchCreateSessionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchCreateSessionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchCreateSessionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchCreateSessionsResponse(od as api.BatchCreateSessionsResponse);
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

  unittest.group('obj-schema-Binding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Binding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBinding(od as api.Binding);
    });
  });

  unittest.group('obj-schema-ChildLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ChildLink.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChildLink(od as api.ChildLink);
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

  unittest.group('obj-schema-CommitStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommitStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommitStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommitStats(od as api.CommitStats);
    });
  });

  unittest.group('obj-schema-CreateBackupMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateBackupMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateBackupMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateBackupMetadata(od as api.CreateBackupMetadata);
    });
  });

  unittest.group('obj-schema-CreateDatabaseMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateDatabaseMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateDatabaseMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateDatabaseMetadata(od as api.CreateDatabaseMetadata);
    });
  });

  unittest.group('obj-schema-CreateDatabaseRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateDatabaseRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateDatabaseRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateDatabaseRequest(od as api.CreateDatabaseRequest);
    });
  });

  unittest.group('obj-schema-CreateInstanceMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateInstanceMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateInstanceMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateInstanceMetadata(od as api.CreateInstanceMetadata);
    });
  });

  unittest.group('obj-schema-CreateInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateInstanceRequest(od as api.CreateInstanceRequest);
    });
  });

  unittest.group('obj-schema-CreateSessionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSessionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSessionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSessionRequest(od as api.CreateSessionRequest);
    });
  });

  unittest.group('obj-schema-Database', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatabase();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Database.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDatabase(od as api.Database);
    });
  });

  unittest.group('obj-schema-Delete', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDelete();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Delete.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDelete(od as api.Delete);
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

  unittest.group('obj-schema-EncryptionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEncryptionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EncryptionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEncryptionConfig(od as api.EncryptionConfig);
    });
  });

  unittest.group('obj-schema-EncryptionInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEncryptionInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EncryptionInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEncryptionInfo(od as api.EncryptionInfo);
    });
  });

  unittest.group('obj-schema-ExecuteBatchDmlRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecuteBatchDmlRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecuteBatchDmlRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecuteBatchDmlRequest(od as api.ExecuteBatchDmlRequest);
    });
  });

  unittest.group('obj-schema-ExecuteBatchDmlResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecuteBatchDmlResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecuteBatchDmlResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecuteBatchDmlResponse(od as api.ExecuteBatchDmlResponse);
    });
  });

  unittest.group('obj-schema-ExecuteSqlRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExecuteSqlRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExecuteSqlRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExecuteSqlRequest(od as api.ExecuteSqlRequest);
    });
  });

  unittest.group('obj-schema-Expr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Expr.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExpr(od as api.Expr);
    });
  });

  unittest.group('obj-schema-Field', () {
    unittest.test('to-json--from-json', () async {
      var o = buildField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Field.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkField(od as api.Field);
    });
  });

  unittest.group('obj-schema-GetDatabaseDdlResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetDatabaseDdlResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetDatabaseDdlResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetDatabaseDdlResponse(od as api.GetDatabaseDdlResponse);
    });
  });

  unittest.group('obj-schema-GetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIamPolicyRequest(od as api.GetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-GetPolicyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetPolicyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetPolicyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetPolicyOptions(od as api.GetPolicyOptions);
    });
  });

  unittest.group('obj-schema-Instance', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstance();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Instance.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInstance(od as api.Instance);
    });
  });

  unittest.group('obj-schema-InstanceConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstanceConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InstanceConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInstanceConfig(od as api.InstanceConfig);
    });
  });

  unittest.group('obj-schema-KeyRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeyRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.KeyRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKeyRange(od as api.KeyRange);
    });
  });

  unittest.group('obj-schema-KeySet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeySet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.KeySet.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKeySet(od as api.KeySet);
    });
  });

  unittest.group('obj-schema-ListBackupOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBackupOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBackupOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBackupOperationsResponse(od as api.ListBackupOperationsResponse);
    });
  });

  unittest.group('obj-schema-ListBackupsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBackupsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBackupsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBackupsResponse(od as api.ListBackupsResponse);
    });
  });

  unittest.group('obj-schema-ListDatabaseOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDatabaseOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDatabaseOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDatabaseOperationsResponse(
          od as api.ListDatabaseOperationsResponse);
    });
  });

  unittest.group('obj-schema-ListDatabasesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDatabasesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDatabasesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDatabasesResponse(od as api.ListDatabasesResponse);
    });
  });

  unittest.group('obj-schema-ListInstanceConfigsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInstanceConfigsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInstanceConfigsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInstanceConfigsResponse(od as api.ListInstanceConfigsResponse);
    });
  });

  unittest.group('obj-schema-ListInstancesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInstancesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInstancesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInstancesResponse(od as api.ListInstancesResponse);
    });
  });

  unittest.group('obj-schema-ListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOperationsResponse(od as api.ListOperationsResponse);
    });
  });

  unittest.group('obj-schema-ListSessionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSessionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSessionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSessionsResponse(od as api.ListSessionsResponse);
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

  unittest.group('obj-schema-Operation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Operation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOperation(od as api.Operation);
    });
  });

  unittest.group('obj-schema-OperationProgress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationProgress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationProgress(od as api.OperationProgress);
    });
  });

  unittest.group('obj-schema-OptimizeRestoredDatabaseMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOptimizeRestoredDatabaseMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OptimizeRestoredDatabaseMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOptimizeRestoredDatabaseMetadata(
          od as api.OptimizeRestoredDatabaseMetadata);
    });
  });

  unittest.group('obj-schema-PartialResultSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartialResultSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartialResultSet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartialResultSet(od as api.PartialResultSet);
    });
  });

  unittest.group('obj-schema-Partition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Partition.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPartition(od as api.Partition);
    });
  });

  unittest.group('obj-schema-PartitionOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionOptions(od as api.PartitionOptions);
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

  unittest.group('obj-schema-PartitionReadRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionReadRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionReadRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionReadRequest(od as api.PartitionReadRequest);
    });
  });

  unittest.group('obj-schema-PartitionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionResponse(od as api.PartitionResponse);
    });
  });

  unittest.group('obj-schema-PartitionedDml', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionedDml();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionedDml.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionedDml(od as api.PartitionedDml);
    });
  });

  unittest.group('obj-schema-PlanNode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlanNode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PlanNode.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPlanNode(od as api.PlanNode);
    });
  });

  unittest.group('obj-schema-Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicy(od as api.Policy);
    });
  });

  unittest.group('obj-schema-QueryOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryOptions(od as api.QueryOptions);
    });
  });

  unittest.group('obj-schema-QueryPlan', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryPlan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.QueryPlan.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQueryPlan(od as api.QueryPlan);
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

  unittest.group('obj-schema-ReadRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReadRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReadRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReadRequest(od as api.ReadRequest);
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

  unittest.group('obj-schema-ReplicaInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplicaInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplicaInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplicaInfo(od as api.ReplicaInfo);
    });
  });

  unittest.group('obj-schema-RequestOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequestOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RequestOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRequestOptions(od as api.RequestOptions);
    });
  });

  unittest.group('obj-schema-RestoreDatabaseEncryptionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestoreDatabaseEncryptionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestoreDatabaseEncryptionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestoreDatabaseEncryptionConfig(
          od as api.RestoreDatabaseEncryptionConfig);
    });
  });

  unittest.group('obj-schema-RestoreDatabaseMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestoreDatabaseMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestoreDatabaseMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestoreDatabaseMetadata(od as api.RestoreDatabaseMetadata);
    });
  });

  unittest.group('obj-schema-RestoreDatabaseRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestoreDatabaseRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestoreDatabaseRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestoreDatabaseRequest(od as api.RestoreDatabaseRequest);
    });
  });

  unittest.group('obj-schema-RestoreInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestoreInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestoreInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestoreInfo(od as api.RestoreInfo);
    });
  });

  unittest.group('obj-schema-ResultSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ResultSet.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResultSet(od as api.ResultSet);
    });
  });

  unittest.group('obj-schema-ResultSetMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultSetMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultSetMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultSetMetadata(od as api.ResultSetMetadata);
    });
  });

  unittest.group('obj-schema-ResultSetStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultSetStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultSetStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultSetStats(od as api.ResultSetStats);
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

  unittest.group('obj-schema-Session', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSession();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Session.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSession(od as api.Session);
    });
  });

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-ShortRepresentation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildShortRepresentation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ShortRepresentation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkShortRepresentation(od as api.ShortRepresentation);
    });
  });

  unittest.group('obj-schema-Statement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Statement.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatement(od as api.Statement);
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

  unittest.group('obj-schema-StructType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStructType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StructType.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStructType(od as api.StructType);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsRequest(od as api.TestIamPermissionsRequest);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsResponse(od as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('obj-schema-Transaction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransaction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Transaction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransaction(od as api.Transaction);
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

  unittest.group('obj-schema-TransactionSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransactionSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TransactionSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransactionSelector(od as api.TransactionSelector);
    });
  });

  unittest.group('obj-schema-Type', () {
    unittest.test('to-json--from-json', () async {
      var o = buildType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Type.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkType(od as api.Type);
    });
  });

  unittest.group('obj-schema-UpdateDatabaseDdlMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDatabaseDdlMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDatabaseDdlMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDatabaseDdlMetadata(od as api.UpdateDatabaseDdlMetadata);
    });
  });

  unittest.group('obj-schema-UpdateDatabaseDdlRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDatabaseDdlRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDatabaseDdlRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDatabaseDdlRequest(od as api.UpdateDatabaseDdlRequest);
    });
  });

  unittest.group('obj-schema-UpdateInstanceMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateInstanceMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateInstanceMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateInstanceMetadata(od as api.UpdateInstanceMetadata);
    });
  });

  unittest.group('obj-schema-UpdateInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateInstanceRequest(od as api.UpdateInstanceRequest);
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

  unittest.group('resource-ProjectsInstanceConfigsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instanceConfigs;
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
        var resp = convert.json.encode(buildInstanceConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkInstanceConfig(response as api.InstanceConfig);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instanceConfigs;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListInstanceConfigsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInstanceConfigsResponse(
          response as api.ListInstanceConfigsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
      var arg_request = buildCreateInstanceRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateInstanceRequest(obj as api.CreateInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
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
      var res = api.SpannerApi(mock).projects.instances;
      var arg_name = 'foo';
      var arg_fieldMask = 'foo';
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
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInstance());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          fieldMask: arg_fieldMask, $fields: arg_$fields);
      checkInstance(response as api.Instance);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_instanceDeadline = 'foo';
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
          queryMap["instanceDeadline"]!.first,
          unittest.equals(arg_instanceDeadline),
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
        var resp = convert.json.encode(buildListInstancesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          instanceDeadline: arg_instanceDeadline,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInstancesResponse(response as api.ListInstancesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
      var arg_request = buildUpdateInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateInstanceRequest(obj as api.UpdateInstanceRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesBackupOperationsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backupOperations;
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
        var resp = convert.json.encode(buildListBackupOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListBackupOperationsResponse(
          response as api.ListBackupOperationsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesBackupsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
      var arg_request = buildBackup();
      var arg_parent = 'foo';
      var arg_backupId = 'foo';
      var arg_encryptionConfig_encryptionType = 'foo';
      var arg_encryptionConfig_kmsKeyName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Backup.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBackup(obj as api.Backup);

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
          queryMap["backupId"]!.first,
          unittest.equals(arg_backupId),
        );
        unittest.expect(
          queryMap["encryptionConfig.encryptionType"]!.first,
          unittest.equals(arg_encryptionConfig_encryptionType),
        );
        unittest.expect(
          queryMap["encryptionConfig.kmsKeyName"]!.first,
          unittest.equals(arg_encryptionConfig_kmsKeyName),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          backupId: arg_backupId,
          encryptionConfig_encryptionType: arg_encryptionConfig_encryptionType,
          encryptionConfig_kmsKeyName: arg_encryptionConfig_kmsKeyName,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
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
      var res = api.SpannerApi(mock).projects.instances.backups;
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
        var resp = convert.json.encode(buildBackup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkBackup(response as api.Backup);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
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
        var resp = convert.json.encode(buildListBackupsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListBackupsResponse(response as api.ListBackupsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
      var arg_request = buildBackup();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Backup.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBackup(obj as api.Backup);

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
        var resp = convert.json.encode(buildBackup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkBackup(response as api.Backup);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesBackupsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups.operations;
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
      var res = api.SpannerApi(mock).projects.instances.backups.operations;
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
      var res = api.SpannerApi(mock).projects.instances.backups.operations;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.backups.operations;
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
        var resp = convert.json.encode(buildListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesDatabaseOperationsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databaseOperations;
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
        var resp = convert.json.encode(buildListDatabaseOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDatabaseOperationsResponse(
          response as api.ListDatabaseOperationsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesDatabasesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_request = buildCreateDatabaseRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateDatabaseRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateDatabaseRequest(obj as api.CreateDatabaseRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--dropDatabase', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_database = 'foo';
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
      final response =
          await res.dropDatabase(arg_database, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
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
        var resp = convert.json.encode(buildDatabase());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkDatabase(response as api.Database);
    });

    unittest.test('method--getDdl', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_database = 'foo';
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
        var resp = convert.json.encode(buildGetDatabaseDdlResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getDdl(arg_database, $fields: arg_$fields);
      checkGetDatabaseDdlResponse(response as api.GetDatabaseDdlResponse);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListDatabasesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDatabasesResponse(response as api.ListDatabasesResponse);
    });

    unittest.test('method--restore', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_request = buildRestoreDatabaseRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RestoreDatabaseRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRestoreDatabaseRequest(obj as api.RestoreDatabaseRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.restore(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });

    unittest.test('method--updateDdl', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases;
      var arg_request = buildUpdateDatabaseDdlRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateDatabaseDdlRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateDatabaseDdlRequest(obj as api.UpdateDatabaseDdlRequest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.updateDdl(arg_request, arg_database, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsInstancesDatabasesOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.operations;
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
      var res = api.SpannerApi(mock).projects.instances.databases.operations;
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
      var res = api.SpannerApi(mock).projects.instances.databases.operations;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.operations;
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
        var resp = convert.json.encode(buildListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });

  unittest.group('resource-ProjectsInstancesDatabasesSessionsResource', () {
    unittest.test('method--batchCreate', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildBatchCreateSessionsRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchCreateSessionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchCreateSessionsRequest(obj as api.BatchCreateSessionsRequest);

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
        var resp = convert.json.encode(buildBatchCreateSessionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchCreate(arg_request, arg_database,
          $fields: arg_$fields);
      checkBatchCreateSessionsResponse(
          response as api.BatchCreateSessionsResponse);
    });

    unittest.test('method--beginTransaction', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildBeginTransactionRequest();
      var arg_session = 'foo';
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
        var resp = convert.json.encode(buildTransaction());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.beginTransaction(arg_request, arg_session,
          $fields: arg_$fields);
      checkTransaction(response as api.Transaction);
    });

    unittest.test('method--commit', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildCommitRequest();
      var arg_session = 'foo';
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
          await res.commit(arg_request, arg_session, $fields: arg_$fields);
      checkCommitResponse(response as api.CommitResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildCreateSessionRequest();
      var arg_database = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateSessionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateSessionRequest(obj as api.CreateSessionRequest);

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
        var resp = convert.json.encode(buildSession());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_database, $fields: arg_$fields);
      checkSession(response as api.Session);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
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

    unittest.test('method--executeBatchDml', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildExecuteBatchDmlRequest();
      var arg_session = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExecuteBatchDmlRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExecuteBatchDmlRequest(obj as api.ExecuteBatchDmlRequest);

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
        var resp = convert.json.encode(buildExecuteBatchDmlResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.executeBatchDml(arg_request, arg_session,
          $fields: arg_$fields);
      checkExecuteBatchDmlResponse(response as api.ExecuteBatchDmlResponse);
    });

    unittest.test('method--executeSql', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildExecuteSqlRequest();
      var arg_session = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExecuteSqlRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExecuteSqlRequest(obj as api.ExecuteSqlRequest);

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
        var resp = convert.json.encode(buildResultSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.executeSql(arg_request, arg_session, $fields: arg_$fields);
      checkResultSet(response as api.ResultSet);
    });

    unittest.test('method--executeStreamingSql', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildExecuteSqlRequest();
      var arg_session = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExecuteSqlRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExecuteSqlRequest(obj as api.ExecuteSqlRequest);

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
        var resp = convert.json.encode(buildPartialResultSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.executeStreamingSql(arg_request, arg_session,
          $fields: arg_$fields);
      checkPartialResultSet(response as api.PartialResultSet);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
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
        var resp = convert.json.encode(buildSession());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSession(response as api.Session);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_database = 'foo';
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
        var resp = convert.json.encode(buildListSessionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_database,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSessionsResponse(response as api.ListSessionsResponse);
    });

    unittest.test('method--partitionQuery', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildPartitionQueryRequest();
      var arg_session = 'foo';
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
        var resp = convert.json.encode(buildPartitionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.partitionQuery(arg_request, arg_session,
          $fields: arg_$fields);
      checkPartitionResponse(response as api.PartitionResponse);
    });

    unittest.test('method--partitionRead', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildPartitionReadRequest();
      var arg_session = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PartitionReadRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPartitionReadRequest(obj as api.PartitionReadRequest);

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
        var resp = convert.json.encode(buildPartitionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.partitionRead(arg_request, arg_session,
          $fields: arg_$fields);
      checkPartitionResponse(response as api.PartitionResponse);
    });

    unittest.test('method--read', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildReadRequest();
      var arg_session = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReadRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReadRequest(obj as api.ReadRequest);

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
        var resp = convert.json.encode(buildResultSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.read(arg_request, arg_session, $fields: arg_$fields);
      checkResultSet(response as api.ResultSet);
    });

    unittest.test('method--rollback', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildRollbackRequest();
      var arg_session = 'foo';
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
          await res.rollback(arg_request, arg_session, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--streamingRead', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.databases.sessions;
      var arg_request = buildReadRequest();
      var arg_session = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReadRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReadRequest(obj as api.ReadRequest);

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
        var resp = convert.json.encode(buildPartialResultSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.streamingRead(arg_request, arg_session,
          $fields: arg_$fields);
      checkPartialResultSet(response as api.PartialResultSet);
    });
  });

  unittest.group('resource-ProjectsInstancesOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.operations;
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
      var res = api.SpannerApi(mock).projects.instances.operations;
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
      var res = api.SpannerApi(mock).projects.instances.operations;
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SpannerApi(mock).projects.instances.operations;
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
        var resp = convert.json.encode(buildListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });
}
