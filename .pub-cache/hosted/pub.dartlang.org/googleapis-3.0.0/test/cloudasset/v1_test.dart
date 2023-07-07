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

import 'package:googleapis/cloudasset/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed3364() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3364(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3365() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3365(core.List<core.String> o) {
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

core.int buildCounterAccessSelector = 0;
api.AccessSelector buildAccessSelector() {
  var o = api.AccessSelector();
  buildCounterAccessSelector++;
  if (buildCounterAccessSelector < 3) {
    o.permissions = buildUnnamed3364();
    o.roles = buildUnnamed3365();
  }
  buildCounterAccessSelector--;
  return o;
}

void checkAccessSelector(api.AccessSelector o) {
  buildCounterAccessSelector++;
  if (buildCounterAccessSelector < 3) {
    checkUnnamed3364(o.permissions!);
    checkUnnamed3365(o.roles!);
  }
  buildCounterAccessSelector--;
}

core.int buildCounterAnalyzeIamPolicyLongrunningRequest = 0;
api.AnalyzeIamPolicyLongrunningRequest
    buildAnalyzeIamPolicyLongrunningRequest() {
  var o = api.AnalyzeIamPolicyLongrunningRequest();
  buildCounterAnalyzeIamPolicyLongrunningRequest++;
  if (buildCounterAnalyzeIamPolicyLongrunningRequest < 3) {
    o.analysisQuery = buildIamPolicyAnalysisQuery();
    o.outputConfig = buildIamPolicyAnalysisOutputConfig();
  }
  buildCounterAnalyzeIamPolicyLongrunningRequest--;
  return o;
}

void checkAnalyzeIamPolicyLongrunningRequest(
    api.AnalyzeIamPolicyLongrunningRequest o) {
  buildCounterAnalyzeIamPolicyLongrunningRequest++;
  if (buildCounterAnalyzeIamPolicyLongrunningRequest < 3) {
    checkIamPolicyAnalysisQuery(o.analysisQuery! as api.IamPolicyAnalysisQuery);
    checkIamPolicyAnalysisOutputConfig(
        o.outputConfig! as api.IamPolicyAnalysisOutputConfig);
  }
  buildCounterAnalyzeIamPolicyLongrunningRequest--;
}

core.int buildCounterAnalyzeIamPolicyLongrunningResponse = 0;
api.AnalyzeIamPolicyLongrunningResponse
    buildAnalyzeIamPolicyLongrunningResponse() {
  var o = api.AnalyzeIamPolicyLongrunningResponse();
  buildCounterAnalyzeIamPolicyLongrunningResponse++;
  if (buildCounterAnalyzeIamPolicyLongrunningResponse < 3) {}
  buildCounterAnalyzeIamPolicyLongrunningResponse--;
  return o;
}

void checkAnalyzeIamPolicyLongrunningResponse(
    api.AnalyzeIamPolicyLongrunningResponse o) {
  buildCounterAnalyzeIamPolicyLongrunningResponse++;
  if (buildCounterAnalyzeIamPolicyLongrunningResponse < 3) {}
  buildCounterAnalyzeIamPolicyLongrunningResponse--;
}

core.List<api.IamPolicyAnalysis> buildUnnamed3366() {
  var o = <api.IamPolicyAnalysis>[];
  o.add(buildIamPolicyAnalysis());
  o.add(buildIamPolicyAnalysis());
  return o;
}

void checkUnnamed3366(core.List<api.IamPolicyAnalysis> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIamPolicyAnalysis(o[0] as api.IamPolicyAnalysis);
  checkIamPolicyAnalysis(o[1] as api.IamPolicyAnalysis);
}

core.int buildCounterAnalyzeIamPolicyResponse = 0;
api.AnalyzeIamPolicyResponse buildAnalyzeIamPolicyResponse() {
  var o = api.AnalyzeIamPolicyResponse();
  buildCounterAnalyzeIamPolicyResponse++;
  if (buildCounterAnalyzeIamPolicyResponse < 3) {
    o.fullyExplored = true;
    o.mainAnalysis = buildIamPolicyAnalysis();
    o.serviceAccountImpersonationAnalysis = buildUnnamed3366();
  }
  buildCounterAnalyzeIamPolicyResponse--;
  return o;
}

void checkAnalyzeIamPolicyResponse(api.AnalyzeIamPolicyResponse o) {
  buildCounterAnalyzeIamPolicyResponse++;
  if (buildCounterAnalyzeIamPolicyResponse < 3) {
    unittest.expect(o.fullyExplored!, unittest.isTrue);
    checkIamPolicyAnalysis(o.mainAnalysis! as api.IamPolicyAnalysis);
    checkUnnamed3366(o.serviceAccountImpersonationAnalysis!);
  }
  buildCounterAnalyzeIamPolicyResponse--;
}

core.List<api.MoveAnalysis> buildUnnamed3367() {
  var o = <api.MoveAnalysis>[];
  o.add(buildMoveAnalysis());
  o.add(buildMoveAnalysis());
  return o;
}

void checkUnnamed3367(core.List<api.MoveAnalysis> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMoveAnalysis(o[0] as api.MoveAnalysis);
  checkMoveAnalysis(o[1] as api.MoveAnalysis);
}

core.int buildCounterAnalyzeMoveResponse = 0;
api.AnalyzeMoveResponse buildAnalyzeMoveResponse() {
  var o = api.AnalyzeMoveResponse();
  buildCounterAnalyzeMoveResponse++;
  if (buildCounterAnalyzeMoveResponse < 3) {
    o.moveAnalysis = buildUnnamed3367();
  }
  buildCounterAnalyzeMoveResponse--;
  return o;
}

void checkAnalyzeMoveResponse(api.AnalyzeMoveResponse o) {
  buildCounterAnalyzeMoveResponse++;
  if (buildCounterAnalyzeMoveResponse < 3) {
    checkUnnamed3367(o.moveAnalysis!);
  }
  buildCounterAnalyzeMoveResponse--;
}

core.List<core.String> buildUnnamed3368() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3368(core.List<core.String> o) {
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

core.List<api.GoogleCloudOrgpolicyV1Policy> buildUnnamed3369() {
  var o = <api.GoogleCloudOrgpolicyV1Policy>[];
  o.add(buildGoogleCloudOrgpolicyV1Policy());
  o.add(buildGoogleCloudOrgpolicyV1Policy());
  return o;
}

void checkUnnamed3369(core.List<api.GoogleCloudOrgpolicyV1Policy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudOrgpolicyV1Policy(o[0] as api.GoogleCloudOrgpolicyV1Policy);
  checkGoogleCloudOrgpolicyV1Policy(o[1] as api.GoogleCloudOrgpolicyV1Policy);
}

core.int buildCounterAsset = 0;
api.Asset buildAsset() {
  var o = api.Asset();
  buildCounterAsset++;
  if (buildCounterAsset < 3) {
    o.accessLevel = buildGoogleIdentityAccesscontextmanagerV1AccessLevel();
    o.accessPolicy = buildGoogleIdentityAccesscontextmanagerV1AccessPolicy();
    o.ancestors = buildUnnamed3368();
    o.assetType = 'foo';
    o.iamPolicy = buildPolicy();
    o.name = 'foo';
    o.orgPolicy = buildUnnamed3369();
    o.osInventory = buildInventory();
    o.resource = buildResource();
    o.servicePerimeter =
        buildGoogleIdentityAccesscontextmanagerV1ServicePerimeter();
    o.updateTime = 'foo';
  }
  buildCounterAsset--;
  return o;
}

void checkAsset(api.Asset o) {
  buildCounterAsset++;
  if (buildCounterAsset < 3) {
    checkGoogleIdentityAccesscontextmanagerV1AccessLevel(
        o.accessLevel! as api.GoogleIdentityAccesscontextmanagerV1AccessLevel);
    checkGoogleIdentityAccesscontextmanagerV1AccessPolicy(o.accessPolicy!
        as api.GoogleIdentityAccesscontextmanagerV1AccessPolicy);
    checkUnnamed3368(o.ancestors!);
    unittest.expect(
      o.assetType!,
      unittest.equals('foo'),
    );
    checkPolicy(o.iamPolicy! as api.Policy);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3369(o.orgPolicy!);
    checkInventory(o.osInventory! as api.Inventory);
    checkResource(o.resource! as api.Resource);
    checkGoogleIdentityAccesscontextmanagerV1ServicePerimeter(
        o.servicePerimeter!
            as api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsset--;
}

core.List<api.AuditLogConfig> buildUnnamed3370() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed3370(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed3370();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed3370(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed3371() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3371(core.List<core.String> o) {
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

core.int buildCounterAuditLogConfig = 0;
api.AuditLogConfig buildAuditLogConfig() {
  var o = api.AuditLogConfig();
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    o.exemptedMembers = buildUnnamed3371();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed3371(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<api.TemporalAsset> buildUnnamed3372() {
  var o = <api.TemporalAsset>[];
  o.add(buildTemporalAsset());
  o.add(buildTemporalAsset());
  return o;
}

void checkUnnamed3372(core.List<api.TemporalAsset> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTemporalAsset(o[0] as api.TemporalAsset);
  checkTemporalAsset(o[1] as api.TemporalAsset);
}

core.int buildCounterBatchGetAssetsHistoryResponse = 0;
api.BatchGetAssetsHistoryResponse buildBatchGetAssetsHistoryResponse() {
  var o = api.BatchGetAssetsHistoryResponse();
  buildCounterBatchGetAssetsHistoryResponse++;
  if (buildCounterBatchGetAssetsHistoryResponse < 3) {
    o.assets = buildUnnamed3372();
  }
  buildCounterBatchGetAssetsHistoryResponse--;
  return o;
}

void checkBatchGetAssetsHistoryResponse(api.BatchGetAssetsHistoryResponse o) {
  buildCounterBatchGetAssetsHistoryResponse++;
  if (buildCounterBatchGetAssetsHistoryResponse < 3) {
    checkUnnamed3372(o.assets!);
  }
  buildCounterBatchGetAssetsHistoryResponse--;
}

core.int buildCounterBigQueryDestination = 0;
api.BigQueryDestination buildBigQueryDestination() {
  var o = api.BigQueryDestination();
  buildCounterBigQueryDestination++;
  if (buildCounterBigQueryDestination < 3) {
    o.dataset = 'foo';
    o.force = true;
    o.partitionSpec = buildPartitionSpec();
    o.separateTablesPerAssetType = true;
    o.table = 'foo';
  }
  buildCounterBigQueryDestination--;
  return o;
}

void checkBigQueryDestination(api.BigQueryDestination o) {
  buildCounterBigQueryDestination++;
  if (buildCounterBigQueryDestination < 3) {
    unittest.expect(
      o.dataset!,
      unittest.equals('foo'),
    );
    unittest.expect(o.force!, unittest.isTrue);
    checkPartitionSpec(o.partitionSpec! as api.PartitionSpec);
    unittest.expect(o.separateTablesPerAssetType!, unittest.isTrue);
    unittest.expect(
      o.table!,
      unittest.equals('foo'),
    );
  }
  buildCounterBigQueryDestination--;
}

core.List<core.String> buildUnnamed3373() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3373(core.List<core.String> o) {
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
    o.members = buildUnnamed3373();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed3373(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterConditionContext = 0;
api.ConditionContext buildConditionContext() {
  var o = api.ConditionContext();
  buildCounterConditionContext++;
  if (buildCounterConditionContext < 3) {
    o.accessTime = 'foo';
  }
  buildCounterConditionContext--;
  return o;
}

void checkConditionContext(api.ConditionContext o) {
  buildCounterConditionContext++;
  if (buildCounterConditionContext < 3) {
    unittest.expect(
      o.accessTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterConditionContext--;
}

core.int buildCounterConditionEvaluation = 0;
api.ConditionEvaluation buildConditionEvaluation() {
  var o = api.ConditionEvaluation();
  buildCounterConditionEvaluation++;
  if (buildCounterConditionEvaluation < 3) {
    o.evaluationValue = 'foo';
  }
  buildCounterConditionEvaluation--;
  return o;
}

void checkConditionEvaluation(api.ConditionEvaluation o) {
  buildCounterConditionEvaluation++;
  if (buildCounterConditionEvaluation < 3) {
    unittest.expect(
      o.evaluationValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterConditionEvaluation--;
}

core.int buildCounterCreateFeedRequest = 0;
api.CreateFeedRequest buildCreateFeedRequest() {
  var o = api.CreateFeedRequest();
  buildCounterCreateFeedRequest++;
  if (buildCounterCreateFeedRequest < 3) {
    o.feed = buildFeed();
    o.feedId = 'foo';
  }
  buildCounterCreateFeedRequest--;
  return o;
}

void checkCreateFeedRequest(api.CreateFeedRequest o) {
  buildCounterCreateFeedRequest++;
  if (buildCounterCreateFeedRequest < 3) {
    checkFeed(o.feed! as api.Feed);
    unittest.expect(
      o.feedId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateFeedRequest--;
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

core.Map<core.String, api.Permissions> buildUnnamed3374() {
  var o = <core.String, api.Permissions>{};
  o['x'] = buildPermissions();
  o['y'] = buildPermissions();
  return o;
}

void checkUnnamed3374(core.Map<core.String, api.Permissions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPermissions(o['x']! as api.Permissions);
  checkPermissions(o['y']! as api.Permissions);
}

core.int buildCounterExplanation = 0;
api.Explanation buildExplanation() {
  var o = api.Explanation();
  buildCounterExplanation++;
  if (buildCounterExplanation < 3) {
    o.matchedPermissions = buildUnnamed3374();
  }
  buildCounterExplanation--;
  return o;
}

void checkExplanation(api.Explanation o) {
  buildCounterExplanation++;
  if (buildCounterExplanation < 3) {
    checkUnnamed3374(o.matchedPermissions!);
  }
  buildCounterExplanation--;
}

core.List<core.String> buildUnnamed3375() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3375(core.List<core.String> o) {
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

core.int buildCounterExportAssetsRequest = 0;
api.ExportAssetsRequest buildExportAssetsRequest() {
  var o = api.ExportAssetsRequest();
  buildCounterExportAssetsRequest++;
  if (buildCounterExportAssetsRequest < 3) {
    o.assetTypes = buildUnnamed3375();
    o.contentType = 'foo';
    o.outputConfig = buildOutputConfig();
    o.readTime = 'foo';
  }
  buildCounterExportAssetsRequest--;
  return o;
}

void checkExportAssetsRequest(api.ExportAssetsRequest o) {
  buildCounterExportAssetsRequest++;
  if (buildCounterExportAssetsRequest < 3) {
    checkUnnamed3375(o.assetTypes!);
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    checkOutputConfig(o.outputConfig! as api.OutputConfig);
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterExportAssetsRequest--;
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

core.List<core.String> buildUnnamed3376() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3376(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3377() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3377(core.List<core.String> o) {
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

core.int buildCounterFeed = 0;
api.Feed buildFeed() {
  var o = api.Feed();
  buildCounterFeed++;
  if (buildCounterFeed < 3) {
    o.assetNames = buildUnnamed3376();
    o.assetTypes = buildUnnamed3377();
    o.condition = buildExpr();
    o.contentType = 'foo';
    o.feedOutputConfig = buildFeedOutputConfig();
    o.name = 'foo';
  }
  buildCounterFeed--;
  return o;
}

void checkFeed(api.Feed o) {
  buildCounterFeed++;
  if (buildCounterFeed < 3) {
    checkUnnamed3376(o.assetNames!);
    checkUnnamed3377(o.assetTypes!);
    checkExpr(o.condition! as api.Expr);
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    checkFeedOutputConfig(o.feedOutputConfig! as api.FeedOutputConfig);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeed--;
}

core.int buildCounterFeedOutputConfig = 0;
api.FeedOutputConfig buildFeedOutputConfig() {
  var o = api.FeedOutputConfig();
  buildCounterFeedOutputConfig++;
  if (buildCounterFeedOutputConfig < 3) {
    o.pubsubDestination = buildPubsubDestination();
  }
  buildCounterFeedOutputConfig--;
  return o;
}

void checkFeedOutputConfig(api.FeedOutputConfig o) {
  buildCounterFeedOutputConfig++;
  if (buildCounterFeedOutputConfig < 3) {
    checkPubsubDestination(o.pubsubDestination! as api.PubsubDestination);
  }
  buildCounterFeedOutputConfig--;
}

core.int buildCounterGcsDestination = 0;
api.GcsDestination buildGcsDestination() {
  var o = api.GcsDestination();
  buildCounterGcsDestination++;
  if (buildCounterGcsDestination < 3) {
    o.uri = 'foo';
    o.uriPrefix = 'foo';
  }
  buildCounterGcsDestination--;
  return o;
}

void checkGcsDestination(api.GcsDestination o) {
  buildCounterGcsDestination++;
  if (buildCounterGcsDestination < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGcsDestination--;
}

core.int buildCounterGoogleCloudAssetV1Access = 0;
api.GoogleCloudAssetV1Access buildGoogleCloudAssetV1Access() {
  var o = api.GoogleCloudAssetV1Access();
  buildCounterGoogleCloudAssetV1Access++;
  if (buildCounterGoogleCloudAssetV1Access < 3) {
    o.analysisState = buildIamPolicyAnalysisState();
    o.permission = 'foo';
    o.role = 'foo';
  }
  buildCounterGoogleCloudAssetV1Access--;
  return o;
}

void checkGoogleCloudAssetV1Access(api.GoogleCloudAssetV1Access o) {
  buildCounterGoogleCloudAssetV1Access++;
  if (buildCounterGoogleCloudAssetV1Access < 3) {
    checkIamPolicyAnalysisState(o.analysisState! as api.IamPolicyAnalysisState);
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1Access--;
}

core.List<api.GoogleCloudAssetV1Access> buildUnnamed3378() {
  var o = <api.GoogleCloudAssetV1Access>[];
  o.add(buildGoogleCloudAssetV1Access());
  o.add(buildGoogleCloudAssetV1Access());
  return o;
}

void checkUnnamed3378(core.List<api.GoogleCloudAssetV1Access> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1Access(o[0] as api.GoogleCloudAssetV1Access);
  checkGoogleCloudAssetV1Access(o[1] as api.GoogleCloudAssetV1Access);
}

core.List<api.GoogleCloudAssetV1Edge> buildUnnamed3379() {
  var o = <api.GoogleCloudAssetV1Edge>[];
  o.add(buildGoogleCloudAssetV1Edge());
  o.add(buildGoogleCloudAssetV1Edge());
  return o;
}

void checkUnnamed3379(core.List<api.GoogleCloudAssetV1Edge> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1Edge(o[0] as api.GoogleCloudAssetV1Edge);
  checkGoogleCloudAssetV1Edge(o[1] as api.GoogleCloudAssetV1Edge);
}

core.List<api.GoogleCloudAssetV1Resource> buildUnnamed3380() {
  var o = <api.GoogleCloudAssetV1Resource>[];
  o.add(buildGoogleCloudAssetV1Resource());
  o.add(buildGoogleCloudAssetV1Resource());
  return o;
}

void checkUnnamed3380(core.List<api.GoogleCloudAssetV1Resource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1Resource(o[0] as api.GoogleCloudAssetV1Resource);
  checkGoogleCloudAssetV1Resource(o[1] as api.GoogleCloudAssetV1Resource);
}

core.int buildCounterGoogleCloudAssetV1AccessControlList = 0;
api.GoogleCloudAssetV1AccessControlList
    buildGoogleCloudAssetV1AccessControlList() {
  var o = api.GoogleCloudAssetV1AccessControlList();
  buildCounterGoogleCloudAssetV1AccessControlList++;
  if (buildCounterGoogleCloudAssetV1AccessControlList < 3) {
    o.accesses = buildUnnamed3378();
    o.conditionEvaluation = buildConditionEvaluation();
    o.resourceEdges = buildUnnamed3379();
    o.resources = buildUnnamed3380();
  }
  buildCounterGoogleCloudAssetV1AccessControlList--;
  return o;
}

void checkGoogleCloudAssetV1AccessControlList(
    api.GoogleCloudAssetV1AccessControlList o) {
  buildCounterGoogleCloudAssetV1AccessControlList++;
  if (buildCounterGoogleCloudAssetV1AccessControlList < 3) {
    checkUnnamed3378(o.accesses!);
    checkConditionEvaluation(o.conditionEvaluation! as api.ConditionEvaluation);
    checkUnnamed3379(o.resourceEdges!);
    checkUnnamed3380(o.resources!);
  }
  buildCounterGoogleCloudAssetV1AccessControlList--;
}

core.int buildCounterGoogleCloudAssetV1BigQueryDestination = 0;
api.GoogleCloudAssetV1BigQueryDestination
    buildGoogleCloudAssetV1BigQueryDestination() {
  var o = api.GoogleCloudAssetV1BigQueryDestination();
  buildCounterGoogleCloudAssetV1BigQueryDestination++;
  if (buildCounterGoogleCloudAssetV1BigQueryDestination < 3) {
    o.dataset = 'foo';
    o.partitionKey = 'foo';
    o.tablePrefix = 'foo';
    o.writeDisposition = 'foo';
  }
  buildCounterGoogleCloudAssetV1BigQueryDestination--;
  return o;
}

void checkGoogleCloudAssetV1BigQueryDestination(
    api.GoogleCloudAssetV1BigQueryDestination o) {
  buildCounterGoogleCloudAssetV1BigQueryDestination++;
  if (buildCounterGoogleCloudAssetV1BigQueryDestination < 3) {
    unittest.expect(
      o.dataset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partitionKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tablePrefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.writeDisposition!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1BigQueryDestination--;
}

core.int buildCounterGoogleCloudAssetV1Edge = 0;
api.GoogleCloudAssetV1Edge buildGoogleCloudAssetV1Edge() {
  var o = api.GoogleCloudAssetV1Edge();
  buildCounterGoogleCloudAssetV1Edge++;
  if (buildCounterGoogleCloudAssetV1Edge < 3) {
    o.sourceNode = 'foo';
    o.targetNode = 'foo';
  }
  buildCounterGoogleCloudAssetV1Edge--;
  return o;
}

void checkGoogleCloudAssetV1Edge(api.GoogleCloudAssetV1Edge o) {
  buildCounterGoogleCloudAssetV1Edge++;
  if (buildCounterGoogleCloudAssetV1Edge < 3) {
    unittest.expect(
      o.sourceNode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetNode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1Edge--;
}

core.int buildCounterGoogleCloudAssetV1GcsDestination = 0;
api.GoogleCloudAssetV1GcsDestination buildGoogleCloudAssetV1GcsDestination() {
  var o = api.GoogleCloudAssetV1GcsDestination();
  buildCounterGoogleCloudAssetV1GcsDestination++;
  if (buildCounterGoogleCloudAssetV1GcsDestination < 3) {
    o.uri = 'foo';
  }
  buildCounterGoogleCloudAssetV1GcsDestination--;
  return o;
}

void checkGoogleCloudAssetV1GcsDestination(
    api.GoogleCloudAssetV1GcsDestination o) {
  buildCounterGoogleCloudAssetV1GcsDestination++;
  if (buildCounterGoogleCloudAssetV1GcsDestination < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1GcsDestination--;
}

core.int buildCounterGoogleCloudAssetV1Identity = 0;
api.GoogleCloudAssetV1Identity buildGoogleCloudAssetV1Identity() {
  var o = api.GoogleCloudAssetV1Identity();
  buildCounterGoogleCloudAssetV1Identity++;
  if (buildCounterGoogleCloudAssetV1Identity < 3) {
    o.analysisState = buildIamPolicyAnalysisState();
    o.name = 'foo';
  }
  buildCounterGoogleCloudAssetV1Identity--;
  return o;
}

void checkGoogleCloudAssetV1Identity(api.GoogleCloudAssetV1Identity o) {
  buildCounterGoogleCloudAssetV1Identity++;
  if (buildCounterGoogleCloudAssetV1Identity < 3) {
    checkIamPolicyAnalysisState(o.analysisState! as api.IamPolicyAnalysisState);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1Identity--;
}

core.List<api.GoogleCloudAssetV1Edge> buildUnnamed3381() {
  var o = <api.GoogleCloudAssetV1Edge>[];
  o.add(buildGoogleCloudAssetV1Edge());
  o.add(buildGoogleCloudAssetV1Edge());
  return o;
}

void checkUnnamed3381(core.List<api.GoogleCloudAssetV1Edge> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1Edge(o[0] as api.GoogleCloudAssetV1Edge);
  checkGoogleCloudAssetV1Edge(o[1] as api.GoogleCloudAssetV1Edge);
}

core.List<api.GoogleCloudAssetV1Identity> buildUnnamed3382() {
  var o = <api.GoogleCloudAssetV1Identity>[];
  o.add(buildGoogleCloudAssetV1Identity());
  o.add(buildGoogleCloudAssetV1Identity());
  return o;
}

void checkUnnamed3382(core.List<api.GoogleCloudAssetV1Identity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1Identity(o[0] as api.GoogleCloudAssetV1Identity);
  checkGoogleCloudAssetV1Identity(o[1] as api.GoogleCloudAssetV1Identity);
}

core.int buildCounterGoogleCloudAssetV1IdentityList = 0;
api.GoogleCloudAssetV1IdentityList buildGoogleCloudAssetV1IdentityList() {
  var o = api.GoogleCloudAssetV1IdentityList();
  buildCounterGoogleCloudAssetV1IdentityList++;
  if (buildCounterGoogleCloudAssetV1IdentityList < 3) {
    o.groupEdges = buildUnnamed3381();
    o.identities = buildUnnamed3382();
  }
  buildCounterGoogleCloudAssetV1IdentityList--;
  return o;
}

void checkGoogleCloudAssetV1IdentityList(api.GoogleCloudAssetV1IdentityList o) {
  buildCounterGoogleCloudAssetV1IdentityList++;
  if (buildCounterGoogleCloudAssetV1IdentityList < 3) {
    checkUnnamed3381(o.groupEdges!);
    checkUnnamed3382(o.identities!);
  }
  buildCounterGoogleCloudAssetV1IdentityList--;
}

core.int buildCounterGoogleCloudAssetV1Resource = 0;
api.GoogleCloudAssetV1Resource buildGoogleCloudAssetV1Resource() {
  var o = api.GoogleCloudAssetV1Resource();
  buildCounterGoogleCloudAssetV1Resource++;
  if (buildCounterGoogleCloudAssetV1Resource < 3) {
    o.analysisState = buildIamPolicyAnalysisState();
    o.fullResourceName = 'foo';
  }
  buildCounterGoogleCloudAssetV1Resource--;
  return o;
}

void checkGoogleCloudAssetV1Resource(api.GoogleCloudAssetV1Resource o) {
  buildCounterGoogleCloudAssetV1Resource++;
  if (buildCounterGoogleCloudAssetV1Resource < 3) {
    checkIamPolicyAnalysisState(o.analysisState! as api.IamPolicyAnalysisState);
    unittest.expect(
      o.fullResourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1Resource--;
}

core.List<core.String> buildUnnamed3383() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3383(core.List<core.String> o) {
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

core.List<api.GoogleCloudOrgpolicyV1Policy> buildUnnamed3384() {
  var o = <api.GoogleCloudOrgpolicyV1Policy>[];
  o.add(buildGoogleCloudOrgpolicyV1Policy());
  o.add(buildGoogleCloudOrgpolicyV1Policy());
  return o;
}

void checkUnnamed3384(core.List<api.GoogleCloudOrgpolicyV1Policy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudOrgpolicyV1Policy(o[0] as api.GoogleCloudOrgpolicyV1Policy);
  checkGoogleCloudOrgpolicyV1Policy(o[1] as api.GoogleCloudOrgpolicyV1Policy);
}

core.int buildCounterGoogleCloudAssetV1p7beta1Asset = 0;
api.GoogleCloudAssetV1p7beta1Asset buildGoogleCloudAssetV1p7beta1Asset() {
  var o = api.GoogleCloudAssetV1p7beta1Asset();
  buildCounterGoogleCloudAssetV1p7beta1Asset++;
  if (buildCounterGoogleCloudAssetV1p7beta1Asset < 3) {
    o.accessLevel = buildGoogleIdentityAccesscontextmanagerV1AccessLevel();
    o.accessPolicy = buildGoogleIdentityAccesscontextmanagerV1AccessPolicy();
    o.ancestors = buildUnnamed3383();
    o.assetType = 'foo';
    o.iamPolicy = buildPolicy();
    o.name = 'foo';
    o.orgPolicy = buildUnnamed3384();
    o.relatedAssets = buildGoogleCloudAssetV1p7beta1RelatedAssets();
    o.resource = buildGoogleCloudAssetV1p7beta1Resource();
    o.servicePerimeter =
        buildGoogleIdentityAccesscontextmanagerV1ServicePerimeter();
    o.updateTime = 'foo';
  }
  buildCounterGoogleCloudAssetV1p7beta1Asset--;
  return o;
}

void checkGoogleCloudAssetV1p7beta1Asset(api.GoogleCloudAssetV1p7beta1Asset o) {
  buildCounterGoogleCloudAssetV1p7beta1Asset++;
  if (buildCounterGoogleCloudAssetV1p7beta1Asset < 3) {
    checkGoogleIdentityAccesscontextmanagerV1AccessLevel(
        o.accessLevel! as api.GoogleIdentityAccesscontextmanagerV1AccessLevel);
    checkGoogleIdentityAccesscontextmanagerV1AccessPolicy(o.accessPolicy!
        as api.GoogleIdentityAccesscontextmanagerV1AccessPolicy);
    checkUnnamed3383(o.ancestors!);
    unittest.expect(
      o.assetType!,
      unittest.equals('foo'),
    );
    checkPolicy(o.iamPolicy! as api.Policy);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3384(o.orgPolicy!);
    checkGoogleCloudAssetV1p7beta1RelatedAssets(
        o.relatedAssets! as api.GoogleCloudAssetV1p7beta1RelatedAssets);
    checkGoogleCloudAssetV1p7beta1Resource(
        o.resource! as api.GoogleCloudAssetV1p7beta1Resource);
    checkGoogleIdentityAccesscontextmanagerV1ServicePerimeter(
        o.servicePerimeter!
            as api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1p7beta1Asset--;
}

core.List<core.String> buildUnnamed3385() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3385(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudAssetV1p7beta1RelatedAsset = 0;
api.GoogleCloudAssetV1p7beta1RelatedAsset
    buildGoogleCloudAssetV1p7beta1RelatedAsset() {
  var o = api.GoogleCloudAssetV1p7beta1RelatedAsset();
  buildCounterGoogleCloudAssetV1p7beta1RelatedAsset++;
  if (buildCounterGoogleCloudAssetV1p7beta1RelatedAsset < 3) {
    o.ancestors = buildUnnamed3385();
    o.asset = 'foo';
    o.assetType = 'foo';
  }
  buildCounterGoogleCloudAssetV1p7beta1RelatedAsset--;
  return o;
}

void checkGoogleCloudAssetV1p7beta1RelatedAsset(
    api.GoogleCloudAssetV1p7beta1RelatedAsset o) {
  buildCounterGoogleCloudAssetV1p7beta1RelatedAsset++;
  if (buildCounterGoogleCloudAssetV1p7beta1RelatedAsset < 3) {
    checkUnnamed3385(o.ancestors!);
    unittest.expect(
      o.asset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.assetType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1p7beta1RelatedAsset--;
}

core.List<api.GoogleCloudAssetV1p7beta1RelatedAsset> buildUnnamed3386() {
  var o = <api.GoogleCloudAssetV1p7beta1RelatedAsset>[];
  o.add(buildGoogleCloudAssetV1p7beta1RelatedAsset());
  o.add(buildGoogleCloudAssetV1p7beta1RelatedAsset());
  return o;
}

void checkUnnamed3386(core.List<api.GoogleCloudAssetV1p7beta1RelatedAsset> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1p7beta1RelatedAsset(
      o[0] as api.GoogleCloudAssetV1p7beta1RelatedAsset);
  checkGoogleCloudAssetV1p7beta1RelatedAsset(
      o[1] as api.GoogleCloudAssetV1p7beta1RelatedAsset);
}

core.int buildCounterGoogleCloudAssetV1p7beta1RelatedAssets = 0;
api.GoogleCloudAssetV1p7beta1RelatedAssets
    buildGoogleCloudAssetV1p7beta1RelatedAssets() {
  var o = api.GoogleCloudAssetV1p7beta1RelatedAssets();
  buildCounterGoogleCloudAssetV1p7beta1RelatedAssets++;
  if (buildCounterGoogleCloudAssetV1p7beta1RelatedAssets < 3) {
    o.assets = buildUnnamed3386();
    o.relationshipAttributes =
        buildGoogleCloudAssetV1p7beta1RelationshipAttributes();
  }
  buildCounterGoogleCloudAssetV1p7beta1RelatedAssets--;
  return o;
}

void checkGoogleCloudAssetV1p7beta1RelatedAssets(
    api.GoogleCloudAssetV1p7beta1RelatedAssets o) {
  buildCounterGoogleCloudAssetV1p7beta1RelatedAssets++;
  if (buildCounterGoogleCloudAssetV1p7beta1RelatedAssets < 3) {
    checkUnnamed3386(o.assets!);
    checkGoogleCloudAssetV1p7beta1RelationshipAttributes(
        o.relationshipAttributes!
            as api.GoogleCloudAssetV1p7beta1RelationshipAttributes);
  }
  buildCounterGoogleCloudAssetV1p7beta1RelatedAssets--;
}

core.int buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes = 0;
api.GoogleCloudAssetV1p7beta1RelationshipAttributes
    buildGoogleCloudAssetV1p7beta1RelationshipAttributes() {
  var o = api.GoogleCloudAssetV1p7beta1RelationshipAttributes();
  buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes++;
  if (buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes < 3) {
    o.action = 'foo';
    o.sourceResourceType = 'foo';
    o.targetResourceType = 'foo';
    o.type = 'foo';
  }
  buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes--;
  return o;
}

void checkGoogleCloudAssetV1p7beta1RelationshipAttributes(
    api.GoogleCloudAssetV1p7beta1RelationshipAttributes o) {
  buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes++;
  if (buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceResourceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetResourceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1p7beta1RelationshipAttributes--;
}

core.Map<core.String, core.Object> buildUnnamed3387() {
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

void checkUnnamed3387(core.Map<core.String, core.Object> o) {
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

core.int buildCounterGoogleCloudAssetV1p7beta1Resource = 0;
api.GoogleCloudAssetV1p7beta1Resource buildGoogleCloudAssetV1p7beta1Resource() {
  var o = api.GoogleCloudAssetV1p7beta1Resource();
  buildCounterGoogleCloudAssetV1p7beta1Resource++;
  if (buildCounterGoogleCloudAssetV1p7beta1Resource < 3) {
    o.data = buildUnnamed3387();
    o.discoveryDocumentUri = 'foo';
    o.discoveryName = 'foo';
    o.location = 'foo';
    o.parent = 'foo';
    o.resourceUrl = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudAssetV1p7beta1Resource--;
  return o;
}

void checkGoogleCloudAssetV1p7beta1Resource(
    api.GoogleCloudAssetV1p7beta1Resource o) {
  buildCounterGoogleCloudAssetV1p7beta1Resource++;
  if (buildCounterGoogleCloudAssetV1p7beta1Resource < 3) {
    checkUnnamed3387(o.data!);
    unittest.expect(
      o.discoveryDocumentUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.discoveryName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudAssetV1p7beta1Resource--;
}

core.int buildCounterGoogleCloudOrgpolicyV1BooleanPolicy = 0;
api.GoogleCloudOrgpolicyV1BooleanPolicy
    buildGoogleCloudOrgpolicyV1BooleanPolicy() {
  var o = api.GoogleCloudOrgpolicyV1BooleanPolicy();
  buildCounterGoogleCloudOrgpolicyV1BooleanPolicy++;
  if (buildCounterGoogleCloudOrgpolicyV1BooleanPolicy < 3) {
    o.enforced = true;
  }
  buildCounterGoogleCloudOrgpolicyV1BooleanPolicy--;
  return o;
}

void checkGoogleCloudOrgpolicyV1BooleanPolicy(
    api.GoogleCloudOrgpolicyV1BooleanPolicy o) {
  buildCounterGoogleCloudOrgpolicyV1BooleanPolicy++;
  if (buildCounterGoogleCloudOrgpolicyV1BooleanPolicy < 3) {
    unittest.expect(o.enforced!, unittest.isTrue);
  }
  buildCounterGoogleCloudOrgpolicyV1BooleanPolicy--;
}

core.List<core.String> buildUnnamed3388() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3388(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3389() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3389(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudOrgpolicyV1ListPolicy = 0;
api.GoogleCloudOrgpolicyV1ListPolicy buildGoogleCloudOrgpolicyV1ListPolicy() {
  var o = api.GoogleCloudOrgpolicyV1ListPolicy();
  buildCounterGoogleCloudOrgpolicyV1ListPolicy++;
  if (buildCounterGoogleCloudOrgpolicyV1ListPolicy < 3) {
    o.allValues = 'foo';
    o.allowedValues = buildUnnamed3388();
    o.deniedValues = buildUnnamed3389();
    o.inheritFromParent = true;
    o.suggestedValue = 'foo';
  }
  buildCounterGoogleCloudOrgpolicyV1ListPolicy--;
  return o;
}

void checkGoogleCloudOrgpolicyV1ListPolicy(
    api.GoogleCloudOrgpolicyV1ListPolicy o) {
  buildCounterGoogleCloudOrgpolicyV1ListPolicy++;
  if (buildCounterGoogleCloudOrgpolicyV1ListPolicy < 3) {
    unittest.expect(
      o.allValues!,
      unittest.equals('foo'),
    );
    checkUnnamed3388(o.allowedValues!);
    checkUnnamed3389(o.deniedValues!);
    unittest.expect(o.inheritFromParent!, unittest.isTrue);
    unittest.expect(
      o.suggestedValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudOrgpolicyV1ListPolicy--;
}

core.int buildCounterGoogleCloudOrgpolicyV1Policy = 0;
api.GoogleCloudOrgpolicyV1Policy buildGoogleCloudOrgpolicyV1Policy() {
  var o = api.GoogleCloudOrgpolicyV1Policy();
  buildCounterGoogleCloudOrgpolicyV1Policy++;
  if (buildCounterGoogleCloudOrgpolicyV1Policy < 3) {
    o.booleanPolicy = buildGoogleCloudOrgpolicyV1BooleanPolicy();
    o.constraint = 'foo';
    o.etag = 'foo';
    o.listPolicy = buildGoogleCloudOrgpolicyV1ListPolicy();
    o.restoreDefault = buildGoogleCloudOrgpolicyV1RestoreDefault();
    o.updateTime = 'foo';
    o.version = 42;
  }
  buildCounterGoogleCloudOrgpolicyV1Policy--;
  return o;
}

void checkGoogleCloudOrgpolicyV1Policy(api.GoogleCloudOrgpolicyV1Policy o) {
  buildCounterGoogleCloudOrgpolicyV1Policy++;
  if (buildCounterGoogleCloudOrgpolicyV1Policy < 3) {
    checkGoogleCloudOrgpolicyV1BooleanPolicy(
        o.booleanPolicy! as api.GoogleCloudOrgpolicyV1BooleanPolicy);
    unittest.expect(
      o.constraint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkGoogleCloudOrgpolicyV1ListPolicy(
        o.listPolicy! as api.GoogleCloudOrgpolicyV1ListPolicy);
    checkGoogleCloudOrgpolicyV1RestoreDefault(
        o.restoreDefault! as api.GoogleCloudOrgpolicyV1RestoreDefault);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleCloudOrgpolicyV1Policy--;
}

core.int buildCounterGoogleCloudOrgpolicyV1RestoreDefault = 0;
api.GoogleCloudOrgpolicyV1RestoreDefault
    buildGoogleCloudOrgpolicyV1RestoreDefault() {
  var o = api.GoogleCloudOrgpolicyV1RestoreDefault();
  buildCounterGoogleCloudOrgpolicyV1RestoreDefault++;
  if (buildCounterGoogleCloudOrgpolicyV1RestoreDefault < 3) {}
  buildCounterGoogleCloudOrgpolicyV1RestoreDefault--;
  return o;
}

void checkGoogleCloudOrgpolicyV1RestoreDefault(
    api.GoogleCloudOrgpolicyV1RestoreDefault o) {
  buildCounterGoogleCloudOrgpolicyV1RestoreDefault++;
  if (buildCounterGoogleCloudOrgpolicyV1RestoreDefault < 3) {}
  buildCounterGoogleCloudOrgpolicyV1RestoreDefault--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel = 0;
api.GoogleIdentityAccesscontextmanagerV1AccessLevel
    buildGoogleIdentityAccesscontextmanagerV1AccessLevel() {
  var o = api.GoogleIdentityAccesscontextmanagerV1AccessLevel();
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel < 3) {
    o.basic = buildGoogleIdentityAccesscontextmanagerV1BasicLevel();
    o.custom = buildGoogleIdentityAccesscontextmanagerV1CustomLevel();
    o.description = 'foo';
    o.name = 'foo';
    o.title = 'foo';
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1AccessLevel(
    api.GoogleIdentityAccesscontextmanagerV1AccessLevel o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel < 3) {
    checkGoogleIdentityAccesscontextmanagerV1BasicLevel(
        o.basic! as api.GoogleIdentityAccesscontextmanagerV1BasicLevel);
    checkGoogleIdentityAccesscontextmanagerV1CustomLevel(
        o.custom! as api.GoogleIdentityAccesscontextmanagerV1CustomLevel);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessLevel--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy = 0;
api.GoogleIdentityAccesscontextmanagerV1AccessPolicy
    buildGoogleIdentityAccesscontextmanagerV1AccessPolicy() {
  var o = api.GoogleIdentityAccesscontextmanagerV1AccessPolicy();
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy < 3) {
    o.etag = 'foo';
    o.name = 'foo';
    o.parent = 'foo';
    o.title = 'foo';
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1AccessPolicy(
    api.GoogleIdentityAccesscontextmanagerV1AccessPolicy o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1AccessPolicy--;
}

core.List<api.GoogleIdentityAccesscontextmanagerV1MethodSelector>
    buildUnnamed3390() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1MethodSelector>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1MethodSelector());
  o.add(buildGoogleIdentityAccesscontextmanagerV1MethodSelector());
  return o;
}

void checkUnnamed3390(
    core.List<api.GoogleIdentityAccesscontextmanagerV1MethodSelector> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1MethodSelector(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1MethodSelector);
  checkGoogleIdentityAccesscontextmanagerV1MethodSelector(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1MethodSelector);
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation = 0;
api.GoogleIdentityAccesscontextmanagerV1ApiOperation
    buildGoogleIdentityAccesscontextmanagerV1ApiOperation() {
  var o = api.GoogleIdentityAccesscontextmanagerV1ApiOperation();
  buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation < 3) {
    o.methodSelectors = buildUnnamed3390();
    o.serviceName = 'foo';
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1ApiOperation(
    api.GoogleIdentityAccesscontextmanagerV1ApiOperation o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation < 3) {
    checkUnnamed3390(o.methodSelectors!);
    unittest.expect(
      o.serviceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1ApiOperation--;
}

core.List<api.GoogleIdentityAccesscontextmanagerV1Condition>
    buildUnnamed3391() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1Condition>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1Condition());
  o.add(buildGoogleIdentityAccesscontextmanagerV1Condition());
  return o;
}

void checkUnnamed3391(
    core.List<api.GoogleIdentityAccesscontextmanagerV1Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1Condition(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1Condition);
  checkGoogleIdentityAccesscontextmanagerV1Condition(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1Condition);
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel = 0;
api.GoogleIdentityAccesscontextmanagerV1BasicLevel
    buildGoogleIdentityAccesscontextmanagerV1BasicLevel() {
  var o = api.GoogleIdentityAccesscontextmanagerV1BasicLevel();
  buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel < 3) {
    o.combiningFunction = 'foo';
    o.conditions = buildUnnamed3391();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1BasicLevel(
    api.GoogleIdentityAccesscontextmanagerV1BasicLevel o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel < 3) {
    unittest.expect(
      o.combiningFunction!,
      unittest.equals('foo'),
    );
    checkUnnamed3391(o.conditions!);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1BasicLevel--;
}

core.List<core.String> buildUnnamed3392() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3392(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3393() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3393(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3394() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3394(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3395() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3395(core.List<core.String> o) {
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

core.int buildCounterGoogleIdentityAccesscontextmanagerV1Condition = 0;
api.GoogleIdentityAccesscontextmanagerV1Condition
    buildGoogleIdentityAccesscontextmanagerV1Condition() {
  var o = api.GoogleIdentityAccesscontextmanagerV1Condition();
  buildCounterGoogleIdentityAccesscontextmanagerV1Condition++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1Condition < 3) {
    o.devicePolicy = buildGoogleIdentityAccesscontextmanagerV1DevicePolicy();
    o.ipSubnetworks = buildUnnamed3392();
    o.members = buildUnnamed3393();
    o.negate = true;
    o.regions = buildUnnamed3394();
    o.requiredAccessLevels = buildUnnamed3395();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1Condition--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1Condition(
    api.GoogleIdentityAccesscontextmanagerV1Condition o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1Condition++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1Condition < 3) {
    checkGoogleIdentityAccesscontextmanagerV1DevicePolicy(o.devicePolicy!
        as api.GoogleIdentityAccesscontextmanagerV1DevicePolicy);
    checkUnnamed3392(o.ipSubnetworks!);
    checkUnnamed3393(o.members!);
    unittest.expect(o.negate!, unittest.isTrue);
    checkUnnamed3394(o.regions!);
    checkUnnamed3395(o.requiredAccessLevels!);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1Condition--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel = 0;
api.GoogleIdentityAccesscontextmanagerV1CustomLevel
    buildGoogleIdentityAccesscontextmanagerV1CustomLevel() {
  var o = api.GoogleIdentityAccesscontextmanagerV1CustomLevel();
  buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel < 3) {
    o.expr = buildExpr();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1CustomLevel(
    api.GoogleIdentityAccesscontextmanagerV1CustomLevel o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel < 3) {
    checkExpr(o.expr! as api.Expr);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1CustomLevel--;
}

core.List<core.String> buildUnnamed3396() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3396(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3397() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3397(core.List<core.String> o) {
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

core.List<api.GoogleIdentityAccesscontextmanagerV1OsConstraint>
    buildUnnamed3398() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1OsConstraint>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1OsConstraint());
  o.add(buildGoogleIdentityAccesscontextmanagerV1OsConstraint());
  return o;
}

void checkUnnamed3398(
    core.List<api.GoogleIdentityAccesscontextmanagerV1OsConstraint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1OsConstraint(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1OsConstraint);
  checkGoogleIdentityAccesscontextmanagerV1OsConstraint(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1OsConstraint);
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy = 0;
api.GoogleIdentityAccesscontextmanagerV1DevicePolicy
    buildGoogleIdentityAccesscontextmanagerV1DevicePolicy() {
  var o = api.GoogleIdentityAccesscontextmanagerV1DevicePolicy();
  buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy < 3) {
    o.allowedDeviceManagementLevels = buildUnnamed3396();
    o.allowedEncryptionStatuses = buildUnnamed3397();
    o.osConstraints = buildUnnamed3398();
    o.requireAdminApproval = true;
    o.requireCorpOwned = true;
    o.requireScreenlock = true;
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1DevicePolicy(
    api.GoogleIdentityAccesscontextmanagerV1DevicePolicy o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy < 3) {
    checkUnnamed3396(o.allowedDeviceManagementLevels!);
    checkUnnamed3397(o.allowedEncryptionStatuses!);
    checkUnnamed3398(o.osConstraints!);
    unittest.expect(o.requireAdminApproval!, unittest.isTrue);
    unittest.expect(o.requireCorpOwned!, unittest.isTrue);
    unittest.expect(o.requireScreenlock!, unittest.isTrue);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1DevicePolicy--;
}

core.List<core.String> buildUnnamed3399() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3399(core.List<core.String> o) {
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

core.int buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom = 0;
api.GoogleIdentityAccesscontextmanagerV1EgressFrom
    buildGoogleIdentityAccesscontextmanagerV1EgressFrom() {
  var o = api.GoogleIdentityAccesscontextmanagerV1EgressFrom();
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom < 3) {
    o.identities = buildUnnamed3399();
    o.identityType = 'foo';
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1EgressFrom(
    api.GoogleIdentityAccesscontextmanagerV1EgressFrom o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom < 3) {
    checkUnnamed3399(o.identities!);
    unittest.expect(
      o.identityType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressFrom--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy = 0;
api.GoogleIdentityAccesscontextmanagerV1EgressPolicy
    buildGoogleIdentityAccesscontextmanagerV1EgressPolicy() {
  var o = api.GoogleIdentityAccesscontextmanagerV1EgressPolicy();
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy < 3) {
    o.egressFrom = buildGoogleIdentityAccesscontextmanagerV1EgressFrom();
    o.egressTo = buildGoogleIdentityAccesscontextmanagerV1EgressTo();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1EgressPolicy(
    api.GoogleIdentityAccesscontextmanagerV1EgressPolicy o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy < 3) {
    checkGoogleIdentityAccesscontextmanagerV1EgressFrom(
        o.egressFrom! as api.GoogleIdentityAccesscontextmanagerV1EgressFrom);
    checkGoogleIdentityAccesscontextmanagerV1EgressTo(
        o.egressTo! as api.GoogleIdentityAccesscontextmanagerV1EgressTo);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressPolicy--;
}

core.List<api.GoogleIdentityAccesscontextmanagerV1ApiOperation>
    buildUnnamed3400() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1ApiOperation>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1ApiOperation());
  o.add(buildGoogleIdentityAccesscontextmanagerV1ApiOperation());
  return o;
}

void checkUnnamed3400(
    core.List<api.GoogleIdentityAccesscontextmanagerV1ApiOperation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1ApiOperation(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1ApiOperation);
  checkGoogleIdentityAccesscontextmanagerV1ApiOperation(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1ApiOperation);
}

core.List<core.String> buildUnnamed3401() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3401(core.List<core.String> o) {
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

core.int buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo = 0;
api.GoogleIdentityAccesscontextmanagerV1EgressTo
    buildGoogleIdentityAccesscontextmanagerV1EgressTo() {
  var o = api.GoogleIdentityAccesscontextmanagerV1EgressTo();
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo < 3) {
    o.operations = buildUnnamed3400();
    o.resources = buildUnnamed3401();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1EgressTo(
    api.GoogleIdentityAccesscontextmanagerV1EgressTo o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo < 3) {
    checkUnnamed3400(o.operations!);
    checkUnnamed3401(o.resources!);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1EgressTo--;
}

core.List<core.String> buildUnnamed3402() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3402(core.List<core.String> o) {
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

core.List<api.GoogleIdentityAccesscontextmanagerV1IngressSource>
    buildUnnamed3403() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1IngressSource>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1IngressSource());
  o.add(buildGoogleIdentityAccesscontextmanagerV1IngressSource());
  return o;
}

void checkUnnamed3403(
    core.List<api.GoogleIdentityAccesscontextmanagerV1IngressSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1IngressSource(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1IngressSource);
  checkGoogleIdentityAccesscontextmanagerV1IngressSource(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1IngressSource);
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom = 0;
api.GoogleIdentityAccesscontextmanagerV1IngressFrom
    buildGoogleIdentityAccesscontextmanagerV1IngressFrom() {
  var o = api.GoogleIdentityAccesscontextmanagerV1IngressFrom();
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom < 3) {
    o.identities = buildUnnamed3402();
    o.identityType = 'foo';
    o.sources = buildUnnamed3403();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1IngressFrom(
    api.GoogleIdentityAccesscontextmanagerV1IngressFrom o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom < 3) {
    checkUnnamed3402(o.identities!);
    unittest.expect(
      o.identityType!,
      unittest.equals('foo'),
    );
    checkUnnamed3403(o.sources!);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressFrom--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy = 0;
api.GoogleIdentityAccesscontextmanagerV1IngressPolicy
    buildGoogleIdentityAccesscontextmanagerV1IngressPolicy() {
  var o = api.GoogleIdentityAccesscontextmanagerV1IngressPolicy();
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy < 3) {
    o.ingressFrom = buildGoogleIdentityAccesscontextmanagerV1IngressFrom();
    o.ingressTo = buildGoogleIdentityAccesscontextmanagerV1IngressTo();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1IngressPolicy(
    api.GoogleIdentityAccesscontextmanagerV1IngressPolicy o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy < 3) {
    checkGoogleIdentityAccesscontextmanagerV1IngressFrom(
        o.ingressFrom! as api.GoogleIdentityAccesscontextmanagerV1IngressFrom);
    checkGoogleIdentityAccesscontextmanagerV1IngressTo(
        o.ingressTo! as api.GoogleIdentityAccesscontextmanagerV1IngressTo);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressPolicy--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource = 0;
api.GoogleIdentityAccesscontextmanagerV1IngressSource
    buildGoogleIdentityAccesscontextmanagerV1IngressSource() {
  var o = api.GoogleIdentityAccesscontextmanagerV1IngressSource();
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource < 3) {
    o.accessLevel = 'foo';
    o.resource = 'foo';
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1IngressSource(
    api.GoogleIdentityAccesscontextmanagerV1IngressSource o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource < 3) {
    unittest.expect(
      o.accessLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resource!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressSource--;
}

core.List<api.GoogleIdentityAccesscontextmanagerV1ApiOperation>
    buildUnnamed3404() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1ApiOperation>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1ApiOperation());
  o.add(buildGoogleIdentityAccesscontextmanagerV1ApiOperation());
  return o;
}

void checkUnnamed3404(
    core.List<api.GoogleIdentityAccesscontextmanagerV1ApiOperation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1ApiOperation(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1ApiOperation);
  checkGoogleIdentityAccesscontextmanagerV1ApiOperation(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1ApiOperation);
}

core.List<core.String> buildUnnamed3405() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3405(core.List<core.String> o) {
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

core.int buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo = 0;
api.GoogleIdentityAccesscontextmanagerV1IngressTo
    buildGoogleIdentityAccesscontextmanagerV1IngressTo() {
  var o = api.GoogleIdentityAccesscontextmanagerV1IngressTo();
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo < 3) {
    o.operations = buildUnnamed3404();
    o.resources = buildUnnamed3405();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1IngressTo(
    api.GoogleIdentityAccesscontextmanagerV1IngressTo o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo < 3) {
    checkUnnamed3404(o.operations!);
    checkUnnamed3405(o.resources!);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1IngressTo--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector = 0;
api.GoogleIdentityAccesscontextmanagerV1MethodSelector
    buildGoogleIdentityAccesscontextmanagerV1MethodSelector() {
  var o = api.GoogleIdentityAccesscontextmanagerV1MethodSelector();
  buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector < 3) {
    o.method = 'foo';
    o.permission = 'foo';
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1MethodSelector(
    api.GoogleIdentityAccesscontextmanagerV1MethodSelector o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector < 3) {
    unittest.expect(
      o.method!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1MethodSelector--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint = 0;
api.GoogleIdentityAccesscontextmanagerV1OsConstraint
    buildGoogleIdentityAccesscontextmanagerV1OsConstraint() {
  var o = api.GoogleIdentityAccesscontextmanagerV1OsConstraint();
  buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint < 3) {
    o.minimumVersion = 'foo';
    o.osType = 'foo';
    o.requireVerifiedChromeOs = true;
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1OsConstraint(
    api.GoogleIdentityAccesscontextmanagerV1OsConstraint o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint < 3) {
    unittest.expect(
      o.minimumVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.requireVerifiedChromeOs!, unittest.isTrue);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1OsConstraint--;
}

core.int buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter = 0;
api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter
    buildGoogleIdentityAccesscontextmanagerV1ServicePerimeter() {
  var o = api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter();
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter < 3) {
    o.description = 'foo';
    o.name = 'foo';
    o.perimeterType = 'foo';
    o.spec = buildGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig();
    o.status =
        buildGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig();
    o.title = 'foo';
    o.useExplicitDryRunSpec = true;
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1ServicePerimeter(
    api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.perimeterType!,
      unittest.equals('foo'),
    );
    checkGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig(o.spec!
        as api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig);
    checkGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig(o.status!
        as api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(o.useExplicitDryRunSpec!, unittest.isTrue);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeter--;
}

core.List<core.String> buildUnnamed3406() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3406(core.List<core.String> o) {
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

core.List<api.GoogleIdentityAccesscontextmanagerV1EgressPolicy>
    buildUnnamed3407() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1EgressPolicy>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1EgressPolicy());
  o.add(buildGoogleIdentityAccesscontextmanagerV1EgressPolicy());
  return o;
}

void checkUnnamed3407(
    core.List<api.GoogleIdentityAccesscontextmanagerV1EgressPolicy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1EgressPolicy(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1EgressPolicy);
  checkGoogleIdentityAccesscontextmanagerV1EgressPolicy(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1EgressPolicy);
}

core.List<api.GoogleIdentityAccesscontextmanagerV1IngressPolicy>
    buildUnnamed3408() {
  var o = <api.GoogleIdentityAccesscontextmanagerV1IngressPolicy>[];
  o.add(buildGoogleIdentityAccesscontextmanagerV1IngressPolicy());
  o.add(buildGoogleIdentityAccesscontextmanagerV1IngressPolicy());
  return o;
}

void checkUnnamed3408(
    core.List<api.GoogleIdentityAccesscontextmanagerV1IngressPolicy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleIdentityAccesscontextmanagerV1IngressPolicy(
      o[0] as api.GoogleIdentityAccesscontextmanagerV1IngressPolicy);
  checkGoogleIdentityAccesscontextmanagerV1IngressPolicy(
      o[1] as api.GoogleIdentityAccesscontextmanagerV1IngressPolicy);
}

core.List<core.String> buildUnnamed3409() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3409(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3410() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3410(core.List<core.String> o) {
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

core.int
    buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig = 0;
api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig
    buildGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig() {
  var o = api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig();
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig <
      3) {
    o.accessLevels = buildUnnamed3406();
    o.egressPolicies = buildUnnamed3407();
    o.ingressPolicies = buildUnnamed3408();
    o.resources = buildUnnamed3409();
    o.restrictedServices = buildUnnamed3410();
    o.vpcAccessibleServices =
        buildGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices();
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig(
    api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig <
      3) {
    checkUnnamed3406(o.accessLevels!);
    checkUnnamed3407(o.egressPolicies!);
    checkUnnamed3408(o.ingressPolicies!);
    checkUnnamed3409(o.resources!);
    checkUnnamed3410(o.restrictedServices!);
    checkGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices(
        o.vpcAccessibleServices!
            as api.GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig--;
}

core.List<core.String> buildUnnamed3411() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3411(core.List<core.String> o) {
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

core.int buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices =
    0;
api.GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices
    buildGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices() {
  var o = api.GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices();
  buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices <
      3) {
    o.allowedServices = buildUnnamed3411();
    o.enableRestriction = true;
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices--;
  return o;
}

void checkGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices(
    api.GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices o) {
  buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices++;
  if (buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices <
      3) {
    checkUnnamed3411(o.allowedServices!);
    unittest.expect(o.enableRestriction!, unittest.isTrue);
  }
  buildCounterGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices--;
}

core.List<api.IamPolicyAnalysisResult> buildUnnamed3412() {
  var o = <api.IamPolicyAnalysisResult>[];
  o.add(buildIamPolicyAnalysisResult());
  o.add(buildIamPolicyAnalysisResult());
  return o;
}

void checkUnnamed3412(core.List<api.IamPolicyAnalysisResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIamPolicyAnalysisResult(o[0] as api.IamPolicyAnalysisResult);
  checkIamPolicyAnalysisResult(o[1] as api.IamPolicyAnalysisResult);
}

core.List<api.IamPolicyAnalysisState> buildUnnamed3413() {
  var o = <api.IamPolicyAnalysisState>[];
  o.add(buildIamPolicyAnalysisState());
  o.add(buildIamPolicyAnalysisState());
  return o;
}

void checkUnnamed3413(core.List<api.IamPolicyAnalysisState> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIamPolicyAnalysisState(o[0] as api.IamPolicyAnalysisState);
  checkIamPolicyAnalysisState(o[1] as api.IamPolicyAnalysisState);
}

core.int buildCounterIamPolicyAnalysis = 0;
api.IamPolicyAnalysis buildIamPolicyAnalysis() {
  var o = api.IamPolicyAnalysis();
  buildCounterIamPolicyAnalysis++;
  if (buildCounterIamPolicyAnalysis < 3) {
    o.analysisQuery = buildIamPolicyAnalysisQuery();
    o.analysisResults = buildUnnamed3412();
    o.fullyExplored = true;
    o.nonCriticalErrors = buildUnnamed3413();
  }
  buildCounterIamPolicyAnalysis--;
  return o;
}

void checkIamPolicyAnalysis(api.IamPolicyAnalysis o) {
  buildCounterIamPolicyAnalysis++;
  if (buildCounterIamPolicyAnalysis < 3) {
    checkIamPolicyAnalysisQuery(o.analysisQuery! as api.IamPolicyAnalysisQuery);
    checkUnnamed3412(o.analysisResults!);
    unittest.expect(o.fullyExplored!, unittest.isTrue);
    checkUnnamed3413(o.nonCriticalErrors!);
  }
  buildCounterIamPolicyAnalysis--;
}

core.int buildCounterIamPolicyAnalysisOutputConfig = 0;
api.IamPolicyAnalysisOutputConfig buildIamPolicyAnalysisOutputConfig() {
  var o = api.IamPolicyAnalysisOutputConfig();
  buildCounterIamPolicyAnalysisOutputConfig++;
  if (buildCounterIamPolicyAnalysisOutputConfig < 3) {
    o.bigqueryDestination = buildGoogleCloudAssetV1BigQueryDestination();
    o.gcsDestination = buildGoogleCloudAssetV1GcsDestination();
  }
  buildCounterIamPolicyAnalysisOutputConfig--;
  return o;
}

void checkIamPolicyAnalysisOutputConfig(api.IamPolicyAnalysisOutputConfig o) {
  buildCounterIamPolicyAnalysisOutputConfig++;
  if (buildCounterIamPolicyAnalysisOutputConfig < 3) {
    checkGoogleCloudAssetV1BigQueryDestination(
        o.bigqueryDestination! as api.GoogleCloudAssetV1BigQueryDestination);
    checkGoogleCloudAssetV1GcsDestination(
        o.gcsDestination! as api.GoogleCloudAssetV1GcsDestination);
  }
  buildCounterIamPolicyAnalysisOutputConfig--;
}

core.int buildCounterIamPolicyAnalysisQuery = 0;
api.IamPolicyAnalysisQuery buildIamPolicyAnalysisQuery() {
  var o = api.IamPolicyAnalysisQuery();
  buildCounterIamPolicyAnalysisQuery++;
  if (buildCounterIamPolicyAnalysisQuery < 3) {
    o.accessSelector = buildAccessSelector();
    o.conditionContext = buildConditionContext();
    o.identitySelector = buildIdentitySelector();
    o.options = buildOptions();
    o.resourceSelector = buildResourceSelector();
    o.scope = 'foo';
  }
  buildCounterIamPolicyAnalysisQuery--;
  return o;
}

void checkIamPolicyAnalysisQuery(api.IamPolicyAnalysisQuery o) {
  buildCounterIamPolicyAnalysisQuery++;
  if (buildCounterIamPolicyAnalysisQuery < 3) {
    checkAccessSelector(o.accessSelector! as api.AccessSelector);
    checkConditionContext(o.conditionContext! as api.ConditionContext);
    checkIdentitySelector(o.identitySelector! as api.IdentitySelector);
    checkOptions(o.options! as api.Options);
    checkResourceSelector(o.resourceSelector! as api.ResourceSelector);
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
  }
  buildCounterIamPolicyAnalysisQuery--;
}

core.List<api.GoogleCloudAssetV1AccessControlList> buildUnnamed3414() {
  var o = <api.GoogleCloudAssetV1AccessControlList>[];
  o.add(buildGoogleCloudAssetV1AccessControlList());
  o.add(buildGoogleCloudAssetV1AccessControlList());
  return o;
}

void checkUnnamed3414(core.List<api.GoogleCloudAssetV1AccessControlList> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudAssetV1AccessControlList(
      o[0] as api.GoogleCloudAssetV1AccessControlList);
  checkGoogleCloudAssetV1AccessControlList(
      o[1] as api.GoogleCloudAssetV1AccessControlList);
}

core.int buildCounterIamPolicyAnalysisResult = 0;
api.IamPolicyAnalysisResult buildIamPolicyAnalysisResult() {
  var o = api.IamPolicyAnalysisResult();
  buildCounterIamPolicyAnalysisResult++;
  if (buildCounterIamPolicyAnalysisResult < 3) {
    o.accessControlLists = buildUnnamed3414();
    o.attachedResourceFullName = 'foo';
    o.fullyExplored = true;
    o.iamBinding = buildBinding();
    o.identityList = buildGoogleCloudAssetV1IdentityList();
  }
  buildCounterIamPolicyAnalysisResult--;
  return o;
}

void checkIamPolicyAnalysisResult(api.IamPolicyAnalysisResult o) {
  buildCounterIamPolicyAnalysisResult++;
  if (buildCounterIamPolicyAnalysisResult < 3) {
    checkUnnamed3414(o.accessControlLists!);
    unittest.expect(
      o.attachedResourceFullName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.fullyExplored!, unittest.isTrue);
    checkBinding(o.iamBinding! as api.Binding);
    checkGoogleCloudAssetV1IdentityList(
        o.identityList! as api.GoogleCloudAssetV1IdentityList);
  }
  buildCounterIamPolicyAnalysisResult--;
}

core.int buildCounterIamPolicyAnalysisState = 0;
api.IamPolicyAnalysisState buildIamPolicyAnalysisState() {
  var o = api.IamPolicyAnalysisState();
  buildCounterIamPolicyAnalysisState++;
  if (buildCounterIamPolicyAnalysisState < 3) {
    o.cause = 'foo';
    o.code = 'foo';
  }
  buildCounterIamPolicyAnalysisState--;
  return o;
}

void checkIamPolicyAnalysisState(api.IamPolicyAnalysisState o) {
  buildCounterIamPolicyAnalysisState++;
  if (buildCounterIamPolicyAnalysisState < 3) {
    unittest.expect(
      o.cause!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
  }
  buildCounterIamPolicyAnalysisState--;
}

core.int buildCounterIamPolicySearchResult = 0;
api.IamPolicySearchResult buildIamPolicySearchResult() {
  var o = api.IamPolicySearchResult();
  buildCounterIamPolicySearchResult++;
  if (buildCounterIamPolicySearchResult < 3) {
    o.explanation = buildExplanation();
    o.policy = buildPolicy();
    o.project = 'foo';
    o.resource = 'foo';
  }
  buildCounterIamPolicySearchResult--;
  return o;
}

void checkIamPolicySearchResult(api.IamPolicySearchResult o) {
  buildCounterIamPolicySearchResult++;
  if (buildCounterIamPolicySearchResult < 3) {
    checkExplanation(o.explanation! as api.Explanation);
    checkPolicy(o.policy! as api.Policy);
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resource!,
      unittest.equals('foo'),
    );
  }
  buildCounterIamPolicySearchResult--;
}

core.int buildCounterIdentitySelector = 0;
api.IdentitySelector buildIdentitySelector() {
  var o = api.IdentitySelector();
  buildCounterIdentitySelector++;
  if (buildCounterIdentitySelector < 3) {
    o.identity = 'foo';
  }
  buildCounterIdentitySelector--;
  return o;
}

void checkIdentitySelector(api.IdentitySelector o) {
  buildCounterIdentitySelector++;
  if (buildCounterIdentitySelector < 3) {
    unittest.expect(
      o.identity!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentitySelector--;
}

core.Map<core.String, api.Item> buildUnnamed3415() {
  var o = <core.String, api.Item>{};
  o['x'] = buildItem();
  o['y'] = buildItem();
  return o;
}

void checkUnnamed3415(core.Map<core.String, api.Item> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkItem(o['x']! as api.Item);
  checkItem(o['y']! as api.Item);
}

core.int buildCounterInventory = 0;
api.Inventory buildInventory() {
  var o = api.Inventory();
  buildCounterInventory++;
  if (buildCounterInventory < 3) {
    o.items = buildUnnamed3415();
    o.osInfo = buildOsInfo();
  }
  buildCounterInventory--;
  return o;
}

void checkInventory(api.Inventory o) {
  buildCounterInventory++;
  if (buildCounterInventory < 3) {
    checkUnnamed3415(o.items!);
    checkOsInfo(o.osInfo! as api.OsInfo);
  }
  buildCounterInventory--;
}

core.int buildCounterItem = 0;
api.Item buildItem() {
  var o = api.Item();
  buildCounterItem++;
  if (buildCounterItem < 3) {
    o.availablePackage = buildSoftwarePackage();
    o.createTime = 'foo';
    o.id = 'foo';
    o.installedPackage = buildSoftwarePackage();
    o.originType = 'foo';
    o.type = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterItem--;
  return o;
}

void checkItem(api.Item o) {
  buildCounterItem++;
  if (buildCounterItem < 3) {
    checkSoftwarePackage(o.availablePackage! as api.SoftwarePackage);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkSoftwarePackage(o.installedPackage! as api.SoftwarePackage);
    unittest.expect(
      o.originType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterItem--;
}

core.List<api.Asset> buildUnnamed3416() {
  var o = <api.Asset>[];
  o.add(buildAsset());
  o.add(buildAsset());
  return o;
}

void checkUnnamed3416(core.List<api.Asset> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAsset(o[0] as api.Asset);
  checkAsset(o[1] as api.Asset);
}

core.int buildCounterListAssetsResponse = 0;
api.ListAssetsResponse buildListAssetsResponse() {
  var o = api.ListAssetsResponse();
  buildCounterListAssetsResponse++;
  if (buildCounterListAssetsResponse < 3) {
    o.assets = buildUnnamed3416();
    o.nextPageToken = 'foo';
    o.readTime = 'foo';
  }
  buildCounterListAssetsResponse--;
  return o;
}

void checkListAssetsResponse(api.ListAssetsResponse o) {
  buildCounterListAssetsResponse++;
  if (buildCounterListAssetsResponse < 3) {
    checkUnnamed3416(o.assets!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAssetsResponse--;
}

core.List<api.Feed> buildUnnamed3417() {
  var o = <api.Feed>[];
  o.add(buildFeed());
  o.add(buildFeed());
  return o;
}

void checkUnnamed3417(core.List<api.Feed> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFeed(o[0] as api.Feed);
  checkFeed(o[1] as api.Feed);
}

core.int buildCounterListFeedsResponse = 0;
api.ListFeedsResponse buildListFeedsResponse() {
  var o = api.ListFeedsResponse();
  buildCounterListFeedsResponse++;
  if (buildCounterListFeedsResponse < 3) {
    o.feeds = buildUnnamed3417();
  }
  buildCounterListFeedsResponse--;
  return o;
}

void checkListFeedsResponse(api.ListFeedsResponse o) {
  buildCounterListFeedsResponse++;
  if (buildCounterListFeedsResponse < 3) {
    checkUnnamed3417(o.feeds!);
  }
  buildCounterListFeedsResponse--;
}

core.int buildCounterMoveAnalysis = 0;
api.MoveAnalysis buildMoveAnalysis() {
  var o = api.MoveAnalysis();
  buildCounterMoveAnalysis++;
  if (buildCounterMoveAnalysis < 3) {
    o.analysis = buildMoveAnalysisResult();
    o.displayName = 'foo';
    o.error = buildStatus();
  }
  buildCounterMoveAnalysis--;
  return o;
}

void checkMoveAnalysis(api.MoveAnalysis o) {
  buildCounterMoveAnalysis++;
  if (buildCounterMoveAnalysis < 3) {
    checkMoveAnalysisResult(o.analysis! as api.MoveAnalysisResult);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkStatus(o.error! as api.Status);
  }
  buildCounterMoveAnalysis--;
}

core.List<api.MoveImpact> buildUnnamed3418() {
  var o = <api.MoveImpact>[];
  o.add(buildMoveImpact());
  o.add(buildMoveImpact());
  return o;
}

void checkUnnamed3418(core.List<api.MoveImpact> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMoveImpact(o[0] as api.MoveImpact);
  checkMoveImpact(o[1] as api.MoveImpact);
}

core.List<api.MoveImpact> buildUnnamed3419() {
  var o = <api.MoveImpact>[];
  o.add(buildMoveImpact());
  o.add(buildMoveImpact());
  return o;
}

void checkUnnamed3419(core.List<api.MoveImpact> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMoveImpact(o[0] as api.MoveImpact);
  checkMoveImpact(o[1] as api.MoveImpact);
}

core.int buildCounterMoveAnalysisResult = 0;
api.MoveAnalysisResult buildMoveAnalysisResult() {
  var o = api.MoveAnalysisResult();
  buildCounterMoveAnalysisResult++;
  if (buildCounterMoveAnalysisResult < 3) {
    o.blockers = buildUnnamed3418();
    o.warnings = buildUnnamed3419();
  }
  buildCounterMoveAnalysisResult--;
  return o;
}

void checkMoveAnalysisResult(api.MoveAnalysisResult o) {
  buildCounterMoveAnalysisResult++;
  if (buildCounterMoveAnalysisResult < 3) {
    checkUnnamed3418(o.blockers!);
    checkUnnamed3419(o.warnings!);
  }
  buildCounterMoveAnalysisResult--;
}

core.int buildCounterMoveImpact = 0;
api.MoveImpact buildMoveImpact() {
  var o = api.MoveImpact();
  buildCounterMoveImpact++;
  if (buildCounterMoveImpact < 3) {
    o.detail = 'foo';
  }
  buildCounterMoveImpact--;
  return o;
}

void checkMoveImpact(api.MoveImpact o) {
  buildCounterMoveImpact++;
  if (buildCounterMoveImpact < 3) {
    unittest.expect(
      o.detail!,
      unittest.equals('foo'),
    );
  }
  buildCounterMoveImpact--;
}

core.Map<core.String, core.Object> buildUnnamed3420() {
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

void checkUnnamed3420(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed3421() {
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

void checkUnnamed3421(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed3420();
    o.name = 'foo';
    o.response = buildUnnamed3421();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed3420(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3421(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOptions = 0;
api.Options buildOptions() {
  var o = api.Options();
  buildCounterOptions++;
  if (buildCounterOptions < 3) {
    o.analyzeServiceAccountImpersonation = true;
    o.expandGroups = true;
    o.expandResources = true;
    o.expandRoles = true;
    o.outputGroupEdges = true;
    o.outputResourceEdges = true;
  }
  buildCounterOptions--;
  return o;
}

void checkOptions(api.Options o) {
  buildCounterOptions++;
  if (buildCounterOptions < 3) {
    unittest.expect(o.analyzeServiceAccountImpersonation!, unittest.isTrue);
    unittest.expect(o.expandGroups!, unittest.isTrue);
    unittest.expect(o.expandResources!, unittest.isTrue);
    unittest.expect(o.expandRoles!, unittest.isTrue);
    unittest.expect(o.outputGroupEdges!, unittest.isTrue);
    unittest.expect(o.outputResourceEdges!, unittest.isTrue);
  }
  buildCounterOptions--;
}

core.int buildCounterOsInfo = 0;
api.OsInfo buildOsInfo() {
  var o = api.OsInfo();
  buildCounterOsInfo++;
  if (buildCounterOsInfo < 3) {
    o.architecture = 'foo';
    o.hostname = 'foo';
    o.kernelRelease = 'foo';
    o.kernelVersion = 'foo';
    o.longName = 'foo';
    o.osconfigAgentVersion = 'foo';
    o.shortName = 'foo';
    o.version = 'foo';
  }
  buildCounterOsInfo--;
  return o;
}

void checkOsInfo(api.OsInfo o) {
  buildCounterOsInfo++;
  if (buildCounterOsInfo < 3) {
    unittest.expect(
      o.architecture!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hostname!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kernelRelease!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kernelVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.longName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osconfigAgentVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shortName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterOsInfo--;
}

core.int buildCounterOutputConfig = 0;
api.OutputConfig buildOutputConfig() {
  var o = api.OutputConfig();
  buildCounterOutputConfig++;
  if (buildCounterOutputConfig < 3) {
    o.bigqueryDestination = buildBigQueryDestination();
    o.gcsDestination = buildGcsDestination();
  }
  buildCounterOutputConfig--;
  return o;
}

void checkOutputConfig(api.OutputConfig o) {
  buildCounterOutputConfig++;
  if (buildCounterOutputConfig < 3) {
    checkBigQueryDestination(o.bigqueryDestination! as api.BigQueryDestination);
    checkGcsDestination(o.gcsDestination! as api.GcsDestination);
  }
  buildCounterOutputConfig--;
}

core.int buildCounterPartitionSpec = 0;
api.PartitionSpec buildPartitionSpec() {
  var o = api.PartitionSpec();
  buildCounterPartitionSpec++;
  if (buildCounterPartitionSpec < 3) {
    o.partitionKey = 'foo';
  }
  buildCounterPartitionSpec--;
  return o;
}

void checkPartitionSpec(api.PartitionSpec o) {
  buildCounterPartitionSpec++;
  if (buildCounterPartitionSpec < 3) {
    unittest.expect(
      o.partitionKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartitionSpec--;
}

core.List<core.String> buildUnnamed3422() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3422(core.List<core.String> o) {
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

core.int buildCounterPermissions = 0;
api.Permissions buildPermissions() {
  var o = api.Permissions();
  buildCounterPermissions++;
  if (buildCounterPermissions < 3) {
    o.permissions = buildUnnamed3422();
  }
  buildCounterPermissions--;
  return o;
}

void checkPermissions(api.Permissions o) {
  buildCounterPermissions++;
  if (buildCounterPermissions < 3) {
    checkUnnamed3422(o.permissions!);
  }
  buildCounterPermissions--;
}

core.List<api.AuditConfig> buildUnnamed3423() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed3423(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed3424() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed3424(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed3423();
    o.bindings = buildUnnamed3424();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed3423(o.auditConfigs!);
    checkUnnamed3424(o.bindings!);
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

core.int buildCounterPubsubDestination = 0;
api.PubsubDestination buildPubsubDestination() {
  var o = api.PubsubDestination();
  buildCounterPubsubDestination++;
  if (buildCounterPubsubDestination < 3) {
    o.topic = 'foo';
  }
  buildCounterPubsubDestination--;
  return o;
}

void checkPubsubDestination(api.PubsubDestination o) {
  buildCounterPubsubDestination++;
  if (buildCounterPubsubDestination < 3) {
    unittest.expect(
      o.topic!,
      unittest.equals('foo'),
    );
  }
  buildCounterPubsubDestination--;
}

core.Map<core.String, core.Object> buildUnnamed3425() {
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

void checkUnnamed3425(core.Map<core.String, core.Object> o) {
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

core.int buildCounterResource = 0;
api.Resource buildResource() {
  var o = api.Resource();
  buildCounterResource++;
  if (buildCounterResource < 3) {
    o.data = buildUnnamed3425();
    o.discoveryDocumentUri = 'foo';
    o.discoveryName = 'foo';
    o.location = 'foo';
    o.parent = 'foo';
    o.resourceUrl = 'foo';
    o.version = 'foo';
  }
  buildCounterResource--;
  return o;
}

void checkResource(api.Resource o) {
  buildCounterResource++;
  if (buildCounterResource < 3) {
    checkUnnamed3425(o.data!);
    unittest.expect(
      o.discoveryDocumentUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.discoveryName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterResource--;
}

core.Map<core.String, core.Object> buildUnnamed3426() {
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

void checkUnnamed3426(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted9 = (o['x']!) as core.Map;
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
  var casted10 = (o['y']!) as core.Map;
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

core.List<core.String> buildUnnamed3427() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3427(core.List<core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed3428() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3428(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed3429() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3429(core.List<core.String> o) {
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

core.int buildCounterResourceSearchResult = 0;
api.ResourceSearchResult buildResourceSearchResult() {
  var o = api.ResourceSearchResult();
  buildCounterResourceSearchResult++;
  if (buildCounterResourceSearchResult < 3) {
    o.additionalAttributes = buildUnnamed3426();
    o.assetType = 'foo';
    o.createTime = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.folders = buildUnnamed3427();
    o.kmsKey = 'foo';
    o.labels = buildUnnamed3428();
    o.location = 'foo';
    o.name = 'foo';
    o.networkTags = buildUnnamed3429();
    o.organization = 'foo';
    o.parentAssetType = 'foo';
    o.parentFullResourceName = 'foo';
    o.project = 'foo';
    o.state = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterResourceSearchResult--;
  return o;
}

void checkResourceSearchResult(api.ResourceSearchResult o) {
  buildCounterResourceSearchResult++;
  if (buildCounterResourceSearchResult < 3) {
    checkUnnamed3426(o.additionalAttributes!);
    unittest.expect(
      o.assetType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed3427(o.folders!);
    unittest.expect(
      o.kmsKey!,
      unittest.equals('foo'),
    );
    checkUnnamed3428(o.labels!);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed3429(o.networkTags!);
    unittest.expect(
      o.organization!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentAssetType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentFullResourceName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceSearchResult--;
}

core.int buildCounterResourceSelector = 0;
api.ResourceSelector buildResourceSelector() {
  var o = api.ResourceSelector();
  buildCounterResourceSelector++;
  if (buildCounterResourceSelector < 3) {
    o.fullResourceName = 'foo';
  }
  buildCounterResourceSelector--;
  return o;
}

void checkResourceSelector(api.ResourceSelector o) {
  buildCounterResourceSelector++;
  if (buildCounterResourceSelector < 3) {
    unittest.expect(
      o.fullResourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceSelector--;
}

core.List<api.IamPolicySearchResult> buildUnnamed3430() {
  var o = <api.IamPolicySearchResult>[];
  o.add(buildIamPolicySearchResult());
  o.add(buildIamPolicySearchResult());
  return o;
}

void checkUnnamed3430(core.List<api.IamPolicySearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIamPolicySearchResult(o[0] as api.IamPolicySearchResult);
  checkIamPolicySearchResult(o[1] as api.IamPolicySearchResult);
}

core.int buildCounterSearchAllIamPoliciesResponse = 0;
api.SearchAllIamPoliciesResponse buildSearchAllIamPoliciesResponse() {
  var o = api.SearchAllIamPoliciesResponse();
  buildCounterSearchAllIamPoliciesResponse++;
  if (buildCounterSearchAllIamPoliciesResponse < 3) {
    o.nextPageToken = 'foo';
    o.results = buildUnnamed3430();
  }
  buildCounterSearchAllIamPoliciesResponse--;
  return o;
}

void checkSearchAllIamPoliciesResponse(api.SearchAllIamPoliciesResponse o) {
  buildCounterSearchAllIamPoliciesResponse++;
  if (buildCounterSearchAllIamPoliciesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3430(o.results!);
  }
  buildCounterSearchAllIamPoliciesResponse--;
}

core.List<api.ResourceSearchResult> buildUnnamed3431() {
  var o = <api.ResourceSearchResult>[];
  o.add(buildResourceSearchResult());
  o.add(buildResourceSearchResult());
  return o;
}

void checkUnnamed3431(core.List<api.ResourceSearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceSearchResult(o[0] as api.ResourceSearchResult);
  checkResourceSearchResult(o[1] as api.ResourceSearchResult);
}

core.int buildCounterSearchAllResourcesResponse = 0;
api.SearchAllResourcesResponse buildSearchAllResourcesResponse() {
  var o = api.SearchAllResourcesResponse();
  buildCounterSearchAllResourcesResponse++;
  if (buildCounterSearchAllResourcesResponse < 3) {
    o.nextPageToken = 'foo';
    o.results = buildUnnamed3431();
  }
  buildCounterSearchAllResourcesResponse--;
  return o;
}

void checkSearchAllResourcesResponse(api.SearchAllResourcesResponse o) {
  buildCounterSearchAllResourcesResponse++;
  if (buildCounterSearchAllResourcesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed3431(o.results!);
  }
  buildCounterSearchAllResourcesResponse--;
}

core.int buildCounterSoftwarePackage = 0;
api.SoftwarePackage buildSoftwarePackage() {
  var o = api.SoftwarePackage();
  buildCounterSoftwarePackage++;
  if (buildCounterSoftwarePackage < 3) {
    o.aptPackage = buildVersionedPackage();
    o.cosPackage = buildVersionedPackage();
    o.googetPackage = buildVersionedPackage();
    o.qfePackage = buildWindowsQuickFixEngineeringPackage();
    o.wuaPackage = buildWindowsUpdatePackage();
    o.yumPackage = buildVersionedPackage();
    o.zypperPackage = buildVersionedPackage();
    o.zypperPatch = buildZypperPatch();
  }
  buildCounterSoftwarePackage--;
  return o;
}

void checkSoftwarePackage(api.SoftwarePackage o) {
  buildCounterSoftwarePackage++;
  if (buildCounterSoftwarePackage < 3) {
    checkVersionedPackage(o.aptPackage! as api.VersionedPackage);
    checkVersionedPackage(o.cosPackage! as api.VersionedPackage);
    checkVersionedPackage(o.googetPackage! as api.VersionedPackage);
    checkWindowsQuickFixEngineeringPackage(
        o.qfePackage! as api.WindowsQuickFixEngineeringPackage);
    checkWindowsUpdatePackage(o.wuaPackage! as api.WindowsUpdatePackage);
    checkVersionedPackage(o.yumPackage! as api.VersionedPackage);
    checkVersionedPackage(o.zypperPackage! as api.VersionedPackage);
    checkZypperPatch(o.zypperPatch! as api.ZypperPatch);
  }
  buildCounterSoftwarePackage--;
}

core.Map<core.String, core.Object> buildUnnamed3432() {
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

void checkUnnamed3432(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted11 = (o['x']!) as core.Map;
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
  var casted12 = (o['y']!) as core.Map;
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

core.List<core.Map<core.String, core.Object>> buildUnnamed3433() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed3432());
  o.add(buildUnnamed3432());
  return o;
}

void checkUnnamed3433(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed3432(o[0]);
  checkUnnamed3432(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed3433();
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
    checkUnnamed3433(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTemporalAsset = 0;
api.TemporalAsset buildTemporalAsset() {
  var o = api.TemporalAsset();
  buildCounterTemporalAsset++;
  if (buildCounterTemporalAsset < 3) {
    o.asset = buildAsset();
    o.deleted = true;
    o.priorAsset = buildAsset();
    o.priorAssetState = 'foo';
    o.window = buildTimeWindow();
  }
  buildCounterTemporalAsset--;
  return o;
}

void checkTemporalAsset(api.TemporalAsset o) {
  buildCounterTemporalAsset++;
  if (buildCounterTemporalAsset < 3) {
    checkAsset(o.asset! as api.Asset);
    unittest.expect(o.deleted!, unittest.isTrue);
    checkAsset(o.priorAsset! as api.Asset);
    unittest.expect(
      o.priorAssetState!,
      unittest.equals('foo'),
    );
    checkTimeWindow(o.window! as api.TimeWindow);
  }
  buildCounterTemporalAsset--;
}

core.int buildCounterTimeWindow = 0;
api.TimeWindow buildTimeWindow() {
  var o = api.TimeWindow();
  buildCounterTimeWindow++;
  if (buildCounterTimeWindow < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterTimeWindow--;
  return o;
}

void checkTimeWindow(api.TimeWindow o) {
  buildCounterTimeWindow++;
  if (buildCounterTimeWindow < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimeWindow--;
}

core.int buildCounterUpdateFeedRequest = 0;
api.UpdateFeedRequest buildUpdateFeedRequest() {
  var o = api.UpdateFeedRequest();
  buildCounterUpdateFeedRequest++;
  if (buildCounterUpdateFeedRequest < 3) {
    o.feed = buildFeed();
    o.updateMask = 'foo';
  }
  buildCounterUpdateFeedRequest--;
  return o;
}

void checkUpdateFeedRequest(api.UpdateFeedRequest o) {
  buildCounterUpdateFeedRequest++;
  if (buildCounterUpdateFeedRequest < 3) {
    checkFeed(o.feed! as api.Feed);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateFeedRequest--;
}

core.int buildCounterVersionedPackage = 0;
api.VersionedPackage buildVersionedPackage() {
  var o = api.VersionedPackage();
  buildCounterVersionedPackage++;
  if (buildCounterVersionedPackage < 3) {
    o.architecture = 'foo';
    o.packageName = 'foo';
    o.version = 'foo';
  }
  buildCounterVersionedPackage--;
  return o;
}

void checkVersionedPackage(api.VersionedPackage o) {
  buildCounterVersionedPackage++;
  if (buildCounterVersionedPackage < 3) {
    unittest.expect(
      o.architecture!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterVersionedPackage--;
}

core.int buildCounterWindowsQuickFixEngineeringPackage = 0;
api.WindowsQuickFixEngineeringPackage buildWindowsQuickFixEngineeringPackage() {
  var o = api.WindowsQuickFixEngineeringPackage();
  buildCounterWindowsQuickFixEngineeringPackage++;
  if (buildCounterWindowsQuickFixEngineeringPackage < 3) {
    o.caption = 'foo';
    o.description = 'foo';
    o.hotFixId = 'foo';
    o.installTime = 'foo';
  }
  buildCounterWindowsQuickFixEngineeringPackage--;
  return o;
}

void checkWindowsQuickFixEngineeringPackage(
    api.WindowsQuickFixEngineeringPackage o) {
  buildCounterWindowsQuickFixEngineeringPackage++;
  if (buildCounterWindowsQuickFixEngineeringPackage < 3) {
    unittest.expect(
      o.caption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hotFixId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.installTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterWindowsQuickFixEngineeringPackage--;
}

core.int buildCounterWindowsUpdateCategory = 0;
api.WindowsUpdateCategory buildWindowsUpdateCategory() {
  var o = api.WindowsUpdateCategory();
  buildCounterWindowsUpdateCategory++;
  if (buildCounterWindowsUpdateCategory < 3) {
    o.id = 'foo';
    o.name = 'foo';
  }
  buildCounterWindowsUpdateCategory--;
  return o;
}

void checkWindowsUpdateCategory(api.WindowsUpdateCategory o) {
  buildCounterWindowsUpdateCategory++;
  if (buildCounterWindowsUpdateCategory < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterWindowsUpdateCategory--;
}

core.List<api.WindowsUpdateCategory> buildUnnamed3434() {
  var o = <api.WindowsUpdateCategory>[];
  o.add(buildWindowsUpdateCategory());
  o.add(buildWindowsUpdateCategory());
  return o;
}

void checkUnnamed3434(core.List<api.WindowsUpdateCategory> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWindowsUpdateCategory(o[0] as api.WindowsUpdateCategory);
  checkWindowsUpdateCategory(o[1] as api.WindowsUpdateCategory);
}

core.List<core.String> buildUnnamed3435() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3435(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3436() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3436(core.List<core.String> o) {
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

core.int buildCounterWindowsUpdatePackage = 0;
api.WindowsUpdatePackage buildWindowsUpdatePackage() {
  var o = api.WindowsUpdatePackage();
  buildCounterWindowsUpdatePackage++;
  if (buildCounterWindowsUpdatePackage < 3) {
    o.categories = buildUnnamed3434();
    o.description = 'foo';
    o.kbArticleIds = buildUnnamed3435();
    o.lastDeploymentChangeTime = 'foo';
    o.moreInfoUrls = buildUnnamed3436();
    o.revisionNumber = 42;
    o.supportUrl = 'foo';
    o.title = 'foo';
    o.updateId = 'foo';
  }
  buildCounterWindowsUpdatePackage--;
  return o;
}

void checkWindowsUpdatePackage(api.WindowsUpdatePackage o) {
  buildCounterWindowsUpdatePackage++;
  if (buildCounterWindowsUpdatePackage < 3) {
    checkUnnamed3434(o.categories!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed3435(o.kbArticleIds!);
    unittest.expect(
      o.lastDeploymentChangeTime!,
      unittest.equals('foo'),
    );
    checkUnnamed3436(o.moreInfoUrls!);
    unittest.expect(
      o.revisionNumber!,
      unittest.equals(42),
    );
    unittest.expect(
      o.supportUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateId!,
      unittest.equals('foo'),
    );
  }
  buildCounterWindowsUpdatePackage--;
}

core.int buildCounterZypperPatch = 0;
api.ZypperPatch buildZypperPatch() {
  var o = api.ZypperPatch();
  buildCounterZypperPatch++;
  if (buildCounterZypperPatch < 3) {
    o.category = 'foo';
    o.patchName = 'foo';
    o.severity = 'foo';
    o.summary = 'foo';
  }
  buildCounterZypperPatch--;
  return o;
}

void checkZypperPatch(api.ZypperPatch o) {
  buildCounterZypperPatch++;
  if (buildCounterZypperPatch < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.patchName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.summary!,
      unittest.equals('foo'),
    );
  }
  buildCounterZypperPatch--;
}

core.List<core.String> buildUnnamed3437() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3437(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3438() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3438(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3439() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3439(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3440() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3440(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3441() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3441(core.List<core.String> o) {
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
  unittest.group('obj-schema-AccessSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessSelector(od as api.AccessSelector);
    });
  });

  unittest.group('obj-schema-AnalyzeIamPolicyLongrunningRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeIamPolicyLongrunningRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeIamPolicyLongrunningRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeIamPolicyLongrunningRequest(
          od as api.AnalyzeIamPolicyLongrunningRequest);
    });
  });

  unittest.group('obj-schema-AnalyzeIamPolicyLongrunningResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeIamPolicyLongrunningResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeIamPolicyLongrunningResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeIamPolicyLongrunningResponse(
          od as api.AnalyzeIamPolicyLongrunningResponse);
    });
  });

  unittest.group('obj-schema-AnalyzeIamPolicyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeIamPolicyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeIamPolicyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeIamPolicyResponse(od as api.AnalyzeIamPolicyResponse);
    });
  });

  unittest.group('obj-schema-AnalyzeMoveResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyzeMoveResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyzeMoveResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyzeMoveResponse(od as api.AnalyzeMoveResponse);
    });
  });

  unittest.group('obj-schema-Asset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Asset.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAsset(od as api.Asset);
    });
  });

  unittest.group('obj-schema-AuditConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditConfig(od as api.AuditConfig);
    });
  });

  unittest.group('obj-schema-AuditLogConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditLogConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditLogConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditLogConfig(od as api.AuditLogConfig);
    });
  });

  unittest.group('obj-schema-BatchGetAssetsHistoryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetAssetsHistoryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetAssetsHistoryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetAssetsHistoryResponse(
          od as api.BatchGetAssetsHistoryResponse);
    });
  });

  unittest.group('obj-schema-BigQueryDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigQueryDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigQueryDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigQueryDestination(od as api.BigQueryDestination);
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

  unittest.group('obj-schema-ConditionContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConditionContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConditionContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConditionContext(od as api.ConditionContext);
    });
  });

  unittest.group('obj-schema-ConditionEvaluation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConditionEvaluation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConditionEvaluation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConditionEvaluation(od as api.ConditionEvaluation);
    });
  });

  unittest.group('obj-schema-CreateFeedRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateFeedRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateFeedRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateFeedRequest(od as api.CreateFeedRequest);
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

  unittest.group('obj-schema-Explanation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExplanation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Explanation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExplanation(od as api.Explanation);
    });
  });

  unittest.group('obj-schema-ExportAssetsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExportAssetsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExportAssetsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExportAssetsRequest(od as api.ExportAssetsRequest);
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

  unittest.group('obj-schema-Feed', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeed();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Feed.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFeed(od as api.Feed);
    });
  });

  unittest.group('obj-schema-FeedOutputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeedOutputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeedOutputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeedOutputConfig(od as api.FeedOutputConfig);
    });
  });

  unittest.group('obj-schema-GcsDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGcsDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GcsDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGcsDestination(od as api.GcsDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1Access', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1Access();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1Access.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1Access(od as api.GoogleCloudAssetV1Access);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1AccessControlList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1AccessControlList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1AccessControlList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1AccessControlList(
          od as api.GoogleCloudAssetV1AccessControlList);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1BigQueryDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1BigQueryDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1BigQueryDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1BigQueryDestination(
          od as api.GoogleCloudAssetV1BigQueryDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1Edge', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1Edge();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1Edge.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1Edge(od as api.GoogleCloudAssetV1Edge);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1GcsDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1GcsDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1GcsDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1GcsDestination(
          od as api.GoogleCloudAssetV1GcsDestination);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1Identity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1Identity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1Identity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1Identity(od as api.GoogleCloudAssetV1Identity);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1IdentityList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1IdentityList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1IdentityList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1IdentityList(
          od as api.GoogleCloudAssetV1IdentityList);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1Resource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1Resource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1Resource(od as api.GoogleCloudAssetV1Resource);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1p7beta1Asset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1p7beta1Asset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1p7beta1Asset.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1p7beta1Asset(
          od as api.GoogleCloudAssetV1p7beta1Asset);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1p7beta1RelatedAsset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1p7beta1RelatedAsset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1p7beta1RelatedAsset.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1p7beta1RelatedAsset(
          od as api.GoogleCloudAssetV1p7beta1RelatedAsset);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1p7beta1RelatedAssets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1p7beta1RelatedAssets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1p7beta1RelatedAssets.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1p7beta1RelatedAssets(
          od as api.GoogleCloudAssetV1p7beta1RelatedAssets);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1p7beta1RelationshipAttributes',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1p7beta1RelationshipAttributes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1p7beta1RelationshipAttributes.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1p7beta1RelationshipAttributes(
          od as api.GoogleCloudAssetV1p7beta1RelationshipAttributes);
    });
  });

  unittest.group('obj-schema-GoogleCloudAssetV1p7beta1Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudAssetV1p7beta1Resource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudAssetV1p7beta1Resource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudAssetV1p7beta1Resource(
          od as api.GoogleCloudAssetV1p7beta1Resource);
    });
  });

  unittest.group('obj-schema-GoogleCloudOrgpolicyV1BooleanPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudOrgpolicyV1BooleanPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudOrgpolicyV1BooleanPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudOrgpolicyV1BooleanPolicy(
          od as api.GoogleCloudOrgpolicyV1BooleanPolicy);
    });
  });

  unittest.group('obj-schema-GoogleCloudOrgpolicyV1ListPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudOrgpolicyV1ListPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudOrgpolicyV1ListPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudOrgpolicyV1ListPolicy(
          od as api.GoogleCloudOrgpolicyV1ListPolicy);
    });
  });

  unittest.group('obj-schema-GoogleCloudOrgpolicyV1Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudOrgpolicyV1Policy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudOrgpolicyV1Policy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudOrgpolicyV1Policy(od as api.GoogleCloudOrgpolicyV1Policy);
    });
  });

  unittest.group('obj-schema-GoogleCloudOrgpolicyV1RestoreDefault', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudOrgpolicyV1RestoreDefault();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudOrgpolicyV1RestoreDefault.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudOrgpolicyV1RestoreDefault(
          od as api.GoogleCloudOrgpolicyV1RestoreDefault);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1AccessLevel',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1AccessLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1AccessLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1AccessLevel(
          od as api.GoogleIdentityAccesscontextmanagerV1AccessLevel);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1AccessPolicy',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1AccessPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1AccessPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1AccessPolicy(
          od as api.GoogleIdentityAccesscontextmanagerV1AccessPolicy);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1ApiOperation',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1ApiOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1ApiOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1ApiOperation(
          od as api.GoogleIdentityAccesscontextmanagerV1ApiOperation);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1BasicLevel',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1BasicLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1BasicLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1BasicLevel(
          od as api.GoogleIdentityAccesscontextmanagerV1BasicLevel);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1Condition',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1Condition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1Condition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1Condition(
          od as api.GoogleIdentityAccesscontextmanagerV1Condition);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1CustomLevel',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1CustomLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1CustomLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1CustomLevel(
          od as api.GoogleIdentityAccesscontextmanagerV1CustomLevel);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1DevicePolicy',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1DevicePolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1DevicePolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1DevicePolicy(
          od as api.GoogleIdentityAccesscontextmanagerV1DevicePolicy);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1EgressFrom',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1EgressFrom();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1EgressFrom.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1EgressFrom(
          od as api.GoogleIdentityAccesscontextmanagerV1EgressFrom);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1EgressPolicy',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1EgressPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1EgressPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1EgressPolicy(
          od as api.GoogleIdentityAccesscontextmanagerV1EgressPolicy);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1EgressTo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1EgressTo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1EgressTo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1EgressTo(
          od as api.GoogleIdentityAccesscontextmanagerV1EgressTo);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1IngressFrom',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1IngressFrom();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1IngressFrom.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1IngressFrom(
          od as api.GoogleIdentityAccesscontextmanagerV1IngressFrom);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1IngressPolicy',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1IngressPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1IngressPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1IngressPolicy(
          od as api.GoogleIdentityAccesscontextmanagerV1IngressPolicy);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1IngressSource',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1IngressSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1IngressSource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1IngressSource(
          od as api.GoogleIdentityAccesscontextmanagerV1IngressSource);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1IngressTo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1IngressTo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1IngressTo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1IngressTo(
          od as api.GoogleIdentityAccesscontextmanagerV1IngressTo);
    });
  });

  unittest.group(
      'obj-schema-GoogleIdentityAccesscontextmanagerV1MethodSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1MethodSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1MethodSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1MethodSelector(
          od as api.GoogleIdentityAccesscontextmanagerV1MethodSelector);
    });
  });

  unittest.group('obj-schema-GoogleIdentityAccesscontextmanagerV1OsConstraint',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1OsConstraint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1OsConstraint.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1OsConstraint(
          od as api.GoogleIdentityAccesscontextmanagerV1OsConstraint);
    });
  });

  unittest.group(
      'obj-schema-GoogleIdentityAccesscontextmanagerV1ServicePerimeter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1ServicePerimeter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1ServicePerimeter(
          od as api.GoogleIdentityAccesscontextmanagerV1ServicePerimeter);
    });
  });

  unittest.group(
      'obj-schema-GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig(
          od as api.GoogleIdentityAccesscontextmanagerV1ServicePerimeterConfig);
    });
  });

  unittest.group(
      'obj-schema-GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleIdentityAccesscontextmanagerV1VpcAccessibleServices(
          od as api.GoogleIdentityAccesscontextmanagerV1VpcAccessibleServices);
    });
  });

  unittest.group('obj-schema-IamPolicyAnalysis', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicyAnalysis();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IamPolicyAnalysis.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicyAnalysis(od as api.IamPolicyAnalysis);
    });
  });

  unittest.group('obj-schema-IamPolicyAnalysisOutputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicyAnalysisOutputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IamPolicyAnalysisOutputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicyAnalysisOutputConfig(
          od as api.IamPolicyAnalysisOutputConfig);
    });
  });

  unittest.group('obj-schema-IamPolicyAnalysisQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicyAnalysisQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IamPolicyAnalysisQuery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicyAnalysisQuery(od as api.IamPolicyAnalysisQuery);
    });
  });

  unittest.group('obj-schema-IamPolicyAnalysisResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicyAnalysisResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IamPolicyAnalysisResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicyAnalysisResult(od as api.IamPolicyAnalysisResult);
    });
  });

  unittest.group('obj-schema-IamPolicyAnalysisState', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicyAnalysisState();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IamPolicyAnalysisState.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicyAnalysisState(od as api.IamPolicyAnalysisState);
    });
  });

  unittest.group('obj-schema-IamPolicySearchResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicySearchResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IamPolicySearchResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicySearchResult(od as api.IamPolicySearchResult);
    });
  });

  unittest.group('obj-schema-IdentitySelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentitySelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentitySelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentitySelector(od as api.IdentitySelector);
    });
  });

  unittest.group('obj-schema-Inventory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Inventory.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInventory(od as api.Inventory);
    });
  });

  unittest.group('obj-schema-Item', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Item.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkItem(od as api.Item);
    });
  });

  unittest.group('obj-schema-ListAssetsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAssetsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAssetsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAssetsResponse(od as api.ListAssetsResponse);
    });
  });

  unittest.group('obj-schema-ListFeedsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFeedsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFeedsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFeedsResponse(od as api.ListFeedsResponse);
    });
  });

  unittest.group('obj-schema-MoveAnalysis', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveAnalysis();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveAnalysis.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveAnalysis(od as api.MoveAnalysis);
    });
  });

  unittest.group('obj-schema-MoveAnalysisResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveAnalysisResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MoveAnalysisResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMoveAnalysisResult(od as api.MoveAnalysisResult);
    });
  });

  unittest.group('obj-schema-MoveImpact', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoveImpact();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.MoveImpact.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMoveImpact(od as api.MoveImpact);
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

  unittest.group('obj-schema-Options', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Options.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOptions(od as api.Options);
    });
  });

  unittest.group('obj-schema-OsInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOsInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OsInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOsInfo(od as api.OsInfo);
    });
  });

  unittest.group('obj-schema-OutputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOutputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OutputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOutputConfig(od as api.OutputConfig);
    });
  });

  unittest.group('obj-schema-PartitionSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartitionSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartitionSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartitionSpec(od as api.PartitionSpec);
    });
  });

  unittest.group('obj-schema-Permissions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPermissions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Permissions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPermissions(od as api.Permissions);
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

  unittest.group('obj-schema-PubsubDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPubsubDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PubsubDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPubsubDestination(od as api.PubsubDestination);
    });
  });

  unittest.group('obj-schema-Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Resource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResource(od as api.Resource);
    });
  });

  unittest.group('obj-schema-ResourceSearchResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceSearchResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceSearchResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceSearchResult(od as api.ResourceSearchResult);
    });
  });

  unittest.group('obj-schema-ResourceSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceSelector(od as api.ResourceSelector);
    });
  });

  unittest.group('obj-schema-SearchAllIamPoliciesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchAllIamPoliciesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchAllIamPoliciesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchAllIamPoliciesResponse(od as api.SearchAllIamPoliciesResponse);
    });
  });

  unittest.group('obj-schema-SearchAllResourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchAllResourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchAllResourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchAllResourcesResponse(od as api.SearchAllResourcesResponse);
    });
  });

  unittest.group('obj-schema-SoftwarePackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSoftwarePackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SoftwarePackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSoftwarePackage(od as api.SoftwarePackage);
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

  unittest.group('obj-schema-TemporalAsset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTemporalAsset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TemporalAsset.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTemporalAsset(od as api.TemporalAsset);
    });
  });

  unittest.group('obj-schema-TimeWindow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeWindow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeWindow.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeWindow(od as api.TimeWindow);
    });
  });

  unittest.group('obj-schema-UpdateFeedRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateFeedRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateFeedRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateFeedRequest(od as api.UpdateFeedRequest);
    });
  });

  unittest.group('obj-schema-VersionedPackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVersionedPackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VersionedPackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVersionedPackage(od as api.VersionedPackage);
    });
  });

  unittest.group('obj-schema-WindowsQuickFixEngineeringPackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWindowsQuickFixEngineeringPackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WindowsQuickFixEngineeringPackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWindowsQuickFixEngineeringPackage(
          od as api.WindowsQuickFixEngineeringPackage);
    });
  });

  unittest.group('obj-schema-WindowsUpdateCategory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWindowsUpdateCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WindowsUpdateCategory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWindowsUpdateCategory(od as api.WindowsUpdateCategory);
    });
  });

  unittest.group('obj-schema-WindowsUpdatePackage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWindowsUpdatePackage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WindowsUpdatePackage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWindowsUpdatePackage(od as api.WindowsUpdatePackage);
    });
  });

  unittest.group('obj-schema-ZypperPatch', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZypperPatch();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ZypperPatch.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkZypperPatch(od as api.ZypperPatch);
    });
  });

  unittest.group('resource-AssetsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).assets;
      var arg_parent = 'foo';
      var arg_assetTypes = buildUnnamed3437();
      var arg_contentType = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_readTime = 'foo';
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
          queryMap["assetTypes"]!,
          unittest.equals(arg_assetTypes),
        );
        unittest.expect(
          queryMap["contentType"]!.first,
          unittest.equals(arg_contentType),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListAssetsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          assetTypes: arg_assetTypes,
          contentType: arg_contentType,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListAssetsResponse(response as api.ListAssetsResponse);
    });
  });

  unittest.group('resource-FeedsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).feeds;
      var arg_request = buildCreateFeedRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateFeedRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateFeedRequest(obj as api.CreateFeedRequest);

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
        var resp = convert.json.encode(buildFeed());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkFeed(response as api.Feed);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).feeds;
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
      var res = api.CloudAssetApi(mock).feeds;
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
        var resp = convert.json.encode(buildFeed());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkFeed(response as api.Feed);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).feeds;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildListFeedsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkListFeedsResponse(response as api.ListFeedsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).feeds;
      var arg_request = buildUpdateFeedRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateFeedRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateFeedRequest(obj as api.UpdateFeedRequest);

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
        var resp = convert.json.encode(buildFeed());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkFeed(response as api.Feed);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).operations;
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
  });

  unittest.group('resource-V1Resource', () {
    unittest.test('method--analyzeIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_scope = 'foo';
      var arg_analysisQuery_accessSelector_permissions = buildUnnamed3438();
      var arg_analysisQuery_accessSelector_roles = buildUnnamed3439();
      var arg_analysisQuery_conditionContext_accessTime = 'foo';
      var arg_analysisQuery_identitySelector_identity = 'foo';
      var arg_analysisQuery_options_analyzeServiceAccountImpersonation = true;
      var arg_analysisQuery_options_expandGroups = true;
      var arg_analysisQuery_options_expandResources = true;
      var arg_analysisQuery_options_expandRoles = true;
      var arg_analysisQuery_options_outputGroupEdges = true;
      var arg_analysisQuery_options_outputResourceEdges = true;
      var arg_analysisQuery_resourceSelector_fullResourceName = 'foo';
      var arg_executionTimeout = 'foo';
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
          queryMap["analysisQuery.accessSelector.permissions"]!,
          unittest.equals(arg_analysisQuery_accessSelector_permissions),
        );
        unittest.expect(
          queryMap["analysisQuery.accessSelector.roles"]!,
          unittest.equals(arg_analysisQuery_accessSelector_roles),
        );
        unittest.expect(
          queryMap["analysisQuery.conditionContext.accessTime"]!.first,
          unittest.equals(arg_analysisQuery_conditionContext_accessTime),
        );
        unittest.expect(
          queryMap["analysisQuery.identitySelector.identity"]!.first,
          unittest.equals(arg_analysisQuery_identitySelector_identity),
        );
        unittest.expect(
          queryMap["analysisQuery.options.analyzeServiceAccountImpersonation"]!
              .first,
          unittest.equals(
              "$arg_analysisQuery_options_analyzeServiceAccountImpersonation"),
        );
        unittest.expect(
          queryMap["analysisQuery.options.expandGroups"]!.first,
          unittest.equals("$arg_analysisQuery_options_expandGroups"),
        );
        unittest.expect(
          queryMap["analysisQuery.options.expandResources"]!.first,
          unittest.equals("$arg_analysisQuery_options_expandResources"),
        );
        unittest.expect(
          queryMap["analysisQuery.options.expandRoles"]!.first,
          unittest.equals("$arg_analysisQuery_options_expandRoles"),
        );
        unittest.expect(
          queryMap["analysisQuery.options.outputGroupEdges"]!.first,
          unittest.equals("$arg_analysisQuery_options_outputGroupEdges"),
        );
        unittest.expect(
          queryMap["analysisQuery.options.outputResourceEdges"]!.first,
          unittest.equals("$arg_analysisQuery_options_outputResourceEdges"),
        );
        unittest.expect(
          queryMap["analysisQuery.resourceSelector.fullResourceName"]!.first,
          unittest.equals(arg_analysisQuery_resourceSelector_fullResourceName),
        );
        unittest.expect(
          queryMap["executionTimeout"]!.first,
          unittest.equals(arg_executionTimeout),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAnalyzeIamPolicyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.analyzeIamPolicy(arg_scope,
          analysisQuery_accessSelector_permissions:
              arg_analysisQuery_accessSelector_permissions,
          analysisQuery_accessSelector_roles:
              arg_analysisQuery_accessSelector_roles,
          analysisQuery_conditionContext_accessTime:
              arg_analysisQuery_conditionContext_accessTime,
          analysisQuery_identitySelector_identity:
              arg_analysisQuery_identitySelector_identity,
          analysisQuery_options_analyzeServiceAccountImpersonation:
              arg_analysisQuery_options_analyzeServiceAccountImpersonation,
          analysisQuery_options_expandGroups:
              arg_analysisQuery_options_expandGroups,
          analysisQuery_options_expandResources:
              arg_analysisQuery_options_expandResources,
          analysisQuery_options_expandRoles:
              arg_analysisQuery_options_expandRoles,
          analysisQuery_options_outputGroupEdges:
              arg_analysisQuery_options_outputGroupEdges,
          analysisQuery_options_outputResourceEdges:
              arg_analysisQuery_options_outputResourceEdges,
          analysisQuery_resourceSelector_fullResourceName:
              arg_analysisQuery_resourceSelector_fullResourceName,
          executionTimeout: arg_executionTimeout,
          $fields: arg_$fields);
      checkAnalyzeIamPolicyResponse(response as api.AnalyzeIamPolicyResponse);
    });

    unittest.test('method--analyzeIamPolicyLongrunning', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_request = buildAnalyzeIamPolicyLongrunningRequest();
      var arg_scope = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyzeIamPolicyLongrunningRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyzeIamPolicyLongrunningRequest(
            obj as api.AnalyzeIamPolicyLongrunningRequest);

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
      final response = await res.analyzeIamPolicyLongrunning(
          arg_request, arg_scope,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--analyzeMove', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_resource = 'foo';
      var arg_destinationParent = 'foo';
      var arg_view = 'foo';
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
          queryMap["destinationParent"]!.first,
          unittest.equals(arg_destinationParent),
        );
        unittest.expect(
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAnalyzeMoveResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.analyzeMove(arg_resource,
          destinationParent: arg_destinationParent,
          view: arg_view,
          $fields: arg_$fields);
      checkAnalyzeMoveResponse(response as api.AnalyzeMoveResponse);
    });

    unittest.test('method--batchGetAssetsHistory', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_parent = 'foo';
      var arg_assetNames = buildUnnamed3440();
      var arg_contentType = 'foo';
      var arg_readTimeWindow_endTime = 'foo';
      var arg_readTimeWindow_startTime = 'foo';
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
          queryMap["assetNames"]!,
          unittest.equals(arg_assetNames),
        );
        unittest.expect(
          queryMap["contentType"]!.first,
          unittest.equals(arg_contentType),
        );
        unittest.expect(
          queryMap["readTimeWindow.endTime"]!.first,
          unittest.equals(arg_readTimeWindow_endTime),
        );
        unittest.expect(
          queryMap["readTimeWindow.startTime"]!.first,
          unittest.equals(arg_readTimeWindow_startTime),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchGetAssetsHistoryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchGetAssetsHistory(arg_parent,
          assetNames: arg_assetNames,
          contentType: arg_contentType,
          readTimeWindow_endTime: arg_readTimeWindow_endTime,
          readTimeWindow_startTime: arg_readTimeWindow_startTime,
          $fields: arg_$fields);
      checkBatchGetAssetsHistoryResponse(
          response as api.BatchGetAssetsHistoryResponse);
    });

    unittest.test('method--exportAssets', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_request = buildExportAssetsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExportAssetsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExportAssetsRequest(obj as api.ExportAssetsRequest);

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
          await res.exportAssets(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--searchAllIamPolicies', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_scope = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
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
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchAllIamPoliciesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchAllIamPolicies(arg_scope,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          query: arg_query,
          $fields: arg_$fields);
      checkSearchAllIamPoliciesResponse(
          response as api.SearchAllIamPoliciesResponse);
    });

    unittest.test('method--searchAllResources', () async {
      var mock = HttpServerMock();
      var res = api.CloudAssetApi(mock).v1;
      var arg_scope = 'foo';
      var arg_assetTypes = buildUnnamed3441();
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
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
          queryMap["assetTypes"]!,
          unittest.equals(arg_assetTypes),
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
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchAllResourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchAllResources(arg_scope,
          assetTypes: arg_assetTypes,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          query: arg_query,
          $fields: arg_$fields);
      checkSearchAllResourcesResponse(
          response as api.SearchAllResourcesResponse);
    });
  });
}
