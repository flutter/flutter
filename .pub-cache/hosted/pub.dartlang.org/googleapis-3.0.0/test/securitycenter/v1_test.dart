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

import 'package:googleapis/securitycenter/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.Map<core.String, core.Object> buildUnnamed1821() {
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

void checkUnnamed1821(core.Map<core.String, core.Object> o) {
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

core.int buildCounterAsset = 0;
api.Asset buildAsset() {
  var o = api.Asset();
  buildCounterAsset++;
  if (buildCounterAsset < 3) {
    o.canonicalName = 'foo';
    o.createTime = 'foo';
    o.iamPolicy = buildIamPolicy();
    o.name = 'foo';
    o.resourceProperties = buildUnnamed1821();
    o.securityCenterProperties = buildSecurityCenterProperties();
    o.securityMarks = buildSecurityMarks();
    o.updateTime = 'foo';
  }
  buildCounterAsset--;
  return o;
}

void checkAsset(api.Asset o) {
  buildCounterAsset++;
  if (buildCounterAsset < 3) {
    unittest.expect(
      o.canonicalName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkIamPolicy(o.iamPolicy! as api.IamPolicy);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1821(o.resourceProperties!);
    checkSecurityCenterProperties(
        o.securityCenterProperties! as api.SecurityCenterProperties);
    checkSecurityMarks(o.securityMarks! as api.SecurityMarks);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsset--;
}

core.List<core.String> buildUnnamed1822() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1822(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1823() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1823(core.List<core.String> o) {
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

core.int buildCounterAssetDiscoveryConfig = 0;
api.AssetDiscoveryConfig buildAssetDiscoveryConfig() {
  var o = api.AssetDiscoveryConfig();
  buildCounterAssetDiscoveryConfig++;
  if (buildCounterAssetDiscoveryConfig < 3) {
    o.folderIds = buildUnnamed1822();
    o.inclusionMode = 'foo';
    o.projectIds = buildUnnamed1823();
  }
  buildCounterAssetDiscoveryConfig--;
  return o;
}

void checkAssetDiscoveryConfig(api.AssetDiscoveryConfig o) {
  buildCounterAssetDiscoveryConfig++;
  if (buildCounterAssetDiscoveryConfig < 3) {
    checkUnnamed1822(o.folderIds!);
    unittest.expect(
      o.inclusionMode!,
      unittest.equals('foo'),
    );
    checkUnnamed1823(o.projectIds!);
  }
  buildCounterAssetDiscoveryConfig--;
}

core.List<api.AuditLogConfig> buildUnnamed1824() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed1824(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed1824();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed1824(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed1825() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1825(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed1825();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed1825(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed1826() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1826(core.List<core.String> o) {
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
    o.members = buildUnnamed1826();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed1826(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
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

core.Map<core.String, core.Object> buildUnnamed1827() {
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

void checkUnnamed1827(core.Map<core.String, core.Object> o) {
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

core.int buildCounterFinding = 0;
api.Finding buildFinding() {
  var o = api.Finding();
  buildCounterFinding++;
  if (buildCounterFinding < 3) {
    o.canonicalName = 'foo';
    o.category = 'foo';
    o.createTime = 'foo';
    o.eventTime = 'foo';
    o.externalUri = 'foo';
    o.name = 'foo';
    o.parent = 'foo';
    o.resourceName = 'foo';
    o.securityMarks = buildSecurityMarks();
    o.severity = 'foo';
    o.sourceProperties = buildUnnamed1827();
    o.state = 'foo';
  }
  buildCounterFinding--;
  return o;
}

void checkFinding(api.Finding o) {
  buildCounterFinding++;
  if (buildCounterFinding < 3) {
    unittest.expect(
      o.canonicalName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalUri!,
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
      o.resourceName!,
      unittest.equals('foo'),
    );
    checkSecurityMarks(o.securityMarks! as api.SecurityMarks);
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    checkUnnamed1827(o.sourceProperties!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterFinding--;
}

core.int buildCounterFolder = 0;
api.Folder buildFolder() {
  var o = api.Folder();
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    o.resourceFolder = 'foo';
    o.resourceFolderDisplayName = 'foo';
  }
  buildCounterFolder--;
  return o;
}

void checkFolder(api.Folder o) {
  buildCounterFolder++;
  if (buildCounterFolder < 3) {
    unittest.expect(
      o.resourceFolder!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceFolderDisplayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterFolder--;
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

core.int buildCounterGoogleCloudSecuritycenterV1NotificationMessage = 0;
api.GoogleCloudSecuritycenterV1NotificationMessage
    buildGoogleCloudSecuritycenterV1NotificationMessage() {
  var o = api.GoogleCloudSecuritycenterV1NotificationMessage();
  buildCounterGoogleCloudSecuritycenterV1NotificationMessage++;
  if (buildCounterGoogleCloudSecuritycenterV1NotificationMessage < 3) {
    o.finding = buildFinding();
    o.notificationConfigName = 'foo';
    o.resource = buildGoogleCloudSecuritycenterV1Resource();
  }
  buildCounterGoogleCloudSecuritycenterV1NotificationMessage--;
  return o;
}

void checkGoogleCloudSecuritycenterV1NotificationMessage(
    api.GoogleCloudSecuritycenterV1NotificationMessage o) {
  buildCounterGoogleCloudSecuritycenterV1NotificationMessage++;
  if (buildCounterGoogleCloudSecuritycenterV1NotificationMessage < 3) {
    checkFinding(o.finding! as api.Finding);
    unittest.expect(
      o.notificationConfigName!,
      unittest.equals('foo'),
    );
    checkGoogleCloudSecuritycenterV1Resource(
        o.resource! as api.GoogleCloudSecuritycenterV1Resource);
  }
  buildCounterGoogleCloudSecuritycenterV1NotificationMessage--;
}

core.List<api.Folder> buildUnnamed1828() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed1828(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterGoogleCloudSecuritycenterV1Resource = 0;
api.GoogleCloudSecuritycenterV1Resource
    buildGoogleCloudSecuritycenterV1Resource() {
  var o = api.GoogleCloudSecuritycenterV1Resource();
  buildCounterGoogleCloudSecuritycenterV1Resource++;
  if (buildCounterGoogleCloudSecuritycenterV1Resource < 3) {
    o.folders = buildUnnamed1828();
    o.name = 'foo';
    o.parent = 'foo';
    o.parentDisplayName = 'foo';
    o.project = 'foo';
    o.projectDisplayName = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1Resource--;
  return o;
}

void checkGoogleCloudSecuritycenterV1Resource(
    api.GoogleCloudSecuritycenterV1Resource o) {
  buildCounterGoogleCloudSecuritycenterV1Resource++;
  if (buildCounterGoogleCloudSecuritycenterV1Resource < 3) {
    checkUnnamed1828(o.folders!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectDisplayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1Resource--;
}

core.int buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse = 0;
api.GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse
    buildGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse() {
  var o = api.GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse();
  buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse++;
  if (buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse < 3) {
    o.duration = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse--;
  return o;
}

void checkGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse(
    api.GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse o) {
  buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse++;
  if (buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse < 3) {
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse--;
}

core.int buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse =
    0;
api.GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse
    buildGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse() {
  var o = api.GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse();
  buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse++;
  if (buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse <
      3) {
    o.duration = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse--;
  return o;
}

void checkGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse(
    api.GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse o) {
  buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse++;
  if (buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse <
      3) {
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse--;
}

core.Map<core.String, core.Object> buildUnnamed1829() {
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

void checkUnnamed1829(core.Map<core.String, core.Object> o) {
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

core.int buildCounterGoogleCloudSecuritycenterV1p1beta1Finding = 0;
api.GoogleCloudSecuritycenterV1p1beta1Finding
    buildGoogleCloudSecuritycenterV1p1beta1Finding() {
  var o = api.GoogleCloudSecuritycenterV1p1beta1Finding();
  buildCounterGoogleCloudSecuritycenterV1p1beta1Finding++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1Finding < 3) {
    o.canonicalName = 'foo';
    o.category = 'foo';
    o.createTime = 'foo';
    o.eventTime = 'foo';
    o.externalUri = 'foo';
    o.name = 'foo';
    o.parent = 'foo';
    o.resourceName = 'foo';
    o.securityMarks = buildGoogleCloudSecuritycenterV1p1beta1SecurityMarks();
    o.severity = 'foo';
    o.sourceProperties = buildUnnamed1829();
    o.state = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1Finding--;
  return o;
}

void checkGoogleCloudSecuritycenterV1p1beta1Finding(
    api.GoogleCloudSecuritycenterV1p1beta1Finding o) {
  buildCounterGoogleCloudSecuritycenterV1p1beta1Finding++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1Finding < 3) {
    unittest.expect(
      o.canonicalName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalUri!,
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
      o.resourceName!,
      unittest.equals('foo'),
    );
    checkGoogleCloudSecuritycenterV1p1beta1SecurityMarks(o.securityMarks!
        as api.GoogleCloudSecuritycenterV1p1beta1SecurityMarks);
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
    checkUnnamed1829(o.sourceProperties!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1Finding--;
}

core.int buildCounterGoogleCloudSecuritycenterV1p1beta1Folder = 0;
api.GoogleCloudSecuritycenterV1p1beta1Folder
    buildGoogleCloudSecuritycenterV1p1beta1Folder() {
  var o = api.GoogleCloudSecuritycenterV1p1beta1Folder();
  buildCounterGoogleCloudSecuritycenterV1p1beta1Folder++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1Folder < 3) {
    o.resourceFolder = 'foo';
    o.resourceFolderDisplayName = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1Folder--;
  return o;
}

void checkGoogleCloudSecuritycenterV1p1beta1Folder(
    api.GoogleCloudSecuritycenterV1p1beta1Folder o) {
  buildCounterGoogleCloudSecuritycenterV1p1beta1Folder++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1Folder < 3) {
    unittest.expect(
      o.resourceFolder!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceFolderDisplayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1Folder--;
}

core.int buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage = 0;
api.GoogleCloudSecuritycenterV1p1beta1NotificationMessage
    buildGoogleCloudSecuritycenterV1p1beta1NotificationMessage() {
  var o = api.GoogleCloudSecuritycenterV1p1beta1NotificationMessage();
  buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage < 3) {
    o.finding = buildGoogleCloudSecuritycenterV1p1beta1Finding();
    o.notificationConfigName = 'foo';
    o.resource = buildGoogleCloudSecuritycenterV1p1beta1Resource();
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage--;
  return o;
}

void checkGoogleCloudSecuritycenterV1p1beta1NotificationMessage(
    api.GoogleCloudSecuritycenterV1p1beta1NotificationMessage o) {
  buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage < 3) {
    checkGoogleCloudSecuritycenterV1p1beta1Finding(
        o.finding! as api.GoogleCloudSecuritycenterV1p1beta1Finding);
    unittest.expect(
      o.notificationConfigName!,
      unittest.equals('foo'),
    );
    checkGoogleCloudSecuritycenterV1p1beta1Resource(
        o.resource! as api.GoogleCloudSecuritycenterV1p1beta1Resource);
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1NotificationMessage--;
}

core.List<api.GoogleCloudSecuritycenterV1p1beta1Folder> buildUnnamed1830() {
  var o = <api.GoogleCloudSecuritycenterV1p1beta1Folder>[];
  o.add(buildGoogleCloudSecuritycenterV1p1beta1Folder());
  o.add(buildGoogleCloudSecuritycenterV1p1beta1Folder());
  return o;
}

void checkUnnamed1830(
    core.List<api.GoogleCloudSecuritycenterV1p1beta1Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudSecuritycenterV1p1beta1Folder(
      o[0] as api.GoogleCloudSecuritycenterV1p1beta1Folder);
  checkGoogleCloudSecuritycenterV1p1beta1Folder(
      o[1] as api.GoogleCloudSecuritycenterV1p1beta1Folder);
}

core.int buildCounterGoogleCloudSecuritycenterV1p1beta1Resource = 0;
api.GoogleCloudSecuritycenterV1p1beta1Resource
    buildGoogleCloudSecuritycenterV1p1beta1Resource() {
  var o = api.GoogleCloudSecuritycenterV1p1beta1Resource();
  buildCounterGoogleCloudSecuritycenterV1p1beta1Resource++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1Resource < 3) {
    o.folders = buildUnnamed1830();
    o.name = 'foo';
    o.parent = 'foo';
    o.parentDisplayName = 'foo';
    o.project = 'foo';
    o.projectDisplayName = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1Resource--;
  return o;
}

void checkGoogleCloudSecuritycenterV1p1beta1Resource(
    api.GoogleCloudSecuritycenterV1p1beta1Resource o) {
  buildCounterGoogleCloudSecuritycenterV1p1beta1Resource++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1Resource < 3) {
    checkUnnamed1830(o.folders!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectDisplayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1Resource--;
}

core.int
    buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse = 0;
api.GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse
    buildGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse() {
  var o = api.GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse();
  buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse <
      3) {
    o.duration = 'foo';
    o.state = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse--;
  return o;
}

void checkGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse(
    api.GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse o) {
  buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse <
      3) {
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse--;
}

core.Map<core.String, core.String> buildUnnamed1831() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1831(core.Map<core.String, core.String> o) {
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

core.int buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks = 0;
api.GoogleCloudSecuritycenterV1p1beta1SecurityMarks
    buildGoogleCloudSecuritycenterV1p1beta1SecurityMarks() {
  var o = api.GoogleCloudSecuritycenterV1p1beta1SecurityMarks();
  buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks < 3) {
    o.canonicalName = 'foo';
    o.marks = buildUnnamed1831();
    o.name = 'foo';
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks--;
  return o;
}

void checkGoogleCloudSecuritycenterV1p1beta1SecurityMarks(
    api.GoogleCloudSecuritycenterV1p1beta1SecurityMarks o) {
  buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks++;
  if (buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks < 3) {
    unittest.expect(
      o.canonicalName!,
      unittest.equals('foo'),
    );
    checkUnnamed1831(o.marks!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudSecuritycenterV1p1beta1SecurityMarks--;
}

core.int buildCounterGroupAssetsRequest = 0;
api.GroupAssetsRequest buildGroupAssetsRequest() {
  var o = api.GroupAssetsRequest();
  buildCounterGroupAssetsRequest++;
  if (buildCounterGroupAssetsRequest < 3) {
    o.compareDuration = 'foo';
    o.filter = 'foo';
    o.groupBy = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.readTime = 'foo';
  }
  buildCounterGroupAssetsRequest--;
  return o;
}

void checkGroupAssetsRequest(api.GroupAssetsRequest o) {
  buildCounterGroupAssetsRequest++;
  if (buildCounterGroupAssetsRequest < 3) {
    unittest.expect(
      o.compareDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.groupBy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroupAssetsRequest--;
}

core.List<api.GroupResult> buildUnnamed1832() {
  var o = <api.GroupResult>[];
  o.add(buildGroupResult());
  o.add(buildGroupResult());
  return o;
}

void checkUnnamed1832(core.List<api.GroupResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGroupResult(o[0] as api.GroupResult);
  checkGroupResult(o[1] as api.GroupResult);
}

core.int buildCounterGroupAssetsResponse = 0;
api.GroupAssetsResponse buildGroupAssetsResponse() {
  var o = api.GroupAssetsResponse();
  buildCounterGroupAssetsResponse++;
  if (buildCounterGroupAssetsResponse < 3) {
    o.groupByResults = buildUnnamed1832();
    o.nextPageToken = 'foo';
    o.readTime = 'foo';
    o.totalSize = 42;
  }
  buildCounterGroupAssetsResponse--;
  return o;
}

void checkGroupAssetsResponse(api.GroupAssetsResponse o) {
  buildCounterGroupAssetsResponse++;
  if (buildCounterGroupAssetsResponse < 3) {
    checkUnnamed1832(o.groupByResults!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterGroupAssetsResponse--;
}

core.int buildCounterGroupFindingsRequest = 0;
api.GroupFindingsRequest buildGroupFindingsRequest() {
  var o = api.GroupFindingsRequest();
  buildCounterGroupFindingsRequest++;
  if (buildCounterGroupFindingsRequest < 3) {
    o.compareDuration = 'foo';
    o.filter = 'foo';
    o.groupBy = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.readTime = 'foo';
  }
  buildCounterGroupFindingsRequest--;
  return o;
}

void checkGroupFindingsRequest(api.GroupFindingsRequest o) {
  buildCounterGroupFindingsRequest++;
  if (buildCounterGroupFindingsRequest < 3) {
    unittest.expect(
      o.compareDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.groupBy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroupFindingsRequest--;
}

core.List<api.GroupResult> buildUnnamed1833() {
  var o = <api.GroupResult>[];
  o.add(buildGroupResult());
  o.add(buildGroupResult());
  return o;
}

void checkUnnamed1833(core.List<api.GroupResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGroupResult(o[0] as api.GroupResult);
  checkGroupResult(o[1] as api.GroupResult);
}

core.int buildCounterGroupFindingsResponse = 0;
api.GroupFindingsResponse buildGroupFindingsResponse() {
  var o = api.GroupFindingsResponse();
  buildCounterGroupFindingsResponse++;
  if (buildCounterGroupFindingsResponse < 3) {
    o.groupByResults = buildUnnamed1833();
    o.nextPageToken = 'foo';
    o.readTime = 'foo';
    o.totalSize = 42;
  }
  buildCounterGroupFindingsResponse--;
  return o;
}

void checkGroupFindingsResponse(api.GroupFindingsResponse o) {
  buildCounterGroupFindingsResponse++;
  if (buildCounterGroupFindingsResponse < 3) {
    checkUnnamed1833(o.groupByResults!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterGroupFindingsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed1834() {
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

void checkUnnamed1834(core.Map<core.String, core.Object> o) {
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

core.int buildCounterGroupResult = 0;
api.GroupResult buildGroupResult() {
  var o = api.GroupResult();
  buildCounterGroupResult++;
  if (buildCounterGroupResult < 3) {
    o.count = 'foo';
    o.properties = buildUnnamed1834();
  }
  buildCounterGroupResult--;
  return o;
}

void checkGroupResult(api.GroupResult o) {
  buildCounterGroupResult++;
  if (buildCounterGroupResult < 3) {
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    checkUnnamed1834(o.properties!);
  }
  buildCounterGroupResult--;
}

core.int buildCounterIamPolicy = 0;
api.IamPolicy buildIamPolicy() {
  var o = api.IamPolicy();
  buildCounterIamPolicy++;
  if (buildCounterIamPolicy < 3) {
    o.policyBlob = 'foo';
  }
  buildCounterIamPolicy--;
  return o;
}

void checkIamPolicy(api.IamPolicy o) {
  buildCounterIamPolicy++;
  if (buildCounterIamPolicy < 3) {
    unittest.expect(
      o.policyBlob!,
      unittest.equals('foo'),
    );
  }
  buildCounterIamPolicy--;
}

core.List<api.ListAssetsResult> buildUnnamed1835() {
  var o = <api.ListAssetsResult>[];
  o.add(buildListAssetsResult());
  o.add(buildListAssetsResult());
  return o;
}

void checkUnnamed1835(core.List<api.ListAssetsResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkListAssetsResult(o[0] as api.ListAssetsResult);
  checkListAssetsResult(o[1] as api.ListAssetsResult);
}

core.int buildCounterListAssetsResponse = 0;
api.ListAssetsResponse buildListAssetsResponse() {
  var o = api.ListAssetsResponse();
  buildCounterListAssetsResponse++;
  if (buildCounterListAssetsResponse < 3) {
    o.listAssetsResults = buildUnnamed1835();
    o.nextPageToken = 'foo';
    o.readTime = 'foo';
    o.totalSize = 42;
  }
  buildCounterListAssetsResponse--;
  return o;
}

void checkListAssetsResponse(api.ListAssetsResponse o) {
  buildCounterListAssetsResponse++;
  if (buildCounterListAssetsResponse < 3) {
    checkUnnamed1835(o.listAssetsResults!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListAssetsResponse--;
}

core.int buildCounterListAssetsResult = 0;
api.ListAssetsResult buildListAssetsResult() {
  var o = api.ListAssetsResult();
  buildCounterListAssetsResult++;
  if (buildCounterListAssetsResult < 3) {
    o.asset = buildAsset();
    o.stateChange = 'foo';
  }
  buildCounterListAssetsResult--;
  return o;
}

void checkListAssetsResult(api.ListAssetsResult o) {
  buildCounterListAssetsResult++;
  if (buildCounterListAssetsResult < 3) {
    checkAsset(o.asset! as api.Asset);
    unittest.expect(
      o.stateChange!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAssetsResult--;
}

core.List<api.ListFindingsResult> buildUnnamed1836() {
  var o = <api.ListFindingsResult>[];
  o.add(buildListFindingsResult());
  o.add(buildListFindingsResult());
  return o;
}

void checkUnnamed1836(core.List<api.ListFindingsResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkListFindingsResult(o[0] as api.ListFindingsResult);
  checkListFindingsResult(o[1] as api.ListFindingsResult);
}

core.int buildCounterListFindingsResponse = 0;
api.ListFindingsResponse buildListFindingsResponse() {
  var o = api.ListFindingsResponse();
  buildCounterListFindingsResponse++;
  if (buildCounterListFindingsResponse < 3) {
    o.listFindingsResults = buildUnnamed1836();
    o.nextPageToken = 'foo';
    o.readTime = 'foo';
    o.totalSize = 42;
  }
  buildCounterListFindingsResponse--;
  return o;
}

void checkListFindingsResponse(api.ListFindingsResponse o) {
  buildCounterListFindingsResponse++;
  if (buildCounterListFindingsResponse < 3) {
    checkUnnamed1836(o.listFindingsResults!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListFindingsResponse--;
}

core.int buildCounterListFindingsResult = 0;
api.ListFindingsResult buildListFindingsResult() {
  var o = api.ListFindingsResult();
  buildCounterListFindingsResult++;
  if (buildCounterListFindingsResult < 3) {
    o.finding = buildFinding();
    o.resource = buildResource();
    o.stateChange = 'foo';
  }
  buildCounterListFindingsResult--;
  return o;
}

void checkListFindingsResult(api.ListFindingsResult o) {
  buildCounterListFindingsResult++;
  if (buildCounterListFindingsResult < 3) {
    checkFinding(o.finding! as api.Finding);
    checkResource(o.resource! as api.Resource);
    unittest.expect(
      o.stateChange!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFindingsResult--;
}

core.List<api.NotificationConfig> buildUnnamed1837() {
  var o = <api.NotificationConfig>[];
  o.add(buildNotificationConfig());
  o.add(buildNotificationConfig());
  return o;
}

void checkUnnamed1837(core.List<api.NotificationConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNotificationConfig(o[0] as api.NotificationConfig);
  checkNotificationConfig(o[1] as api.NotificationConfig);
}

core.int buildCounterListNotificationConfigsResponse = 0;
api.ListNotificationConfigsResponse buildListNotificationConfigsResponse() {
  var o = api.ListNotificationConfigsResponse();
  buildCounterListNotificationConfigsResponse++;
  if (buildCounterListNotificationConfigsResponse < 3) {
    o.nextPageToken = 'foo';
    o.notificationConfigs = buildUnnamed1837();
  }
  buildCounterListNotificationConfigsResponse--;
  return o;
}

void checkListNotificationConfigsResponse(
    api.ListNotificationConfigsResponse o) {
  buildCounterListNotificationConfigsResponse++;
  if (buildCounterListNotificationConfigsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1837(o.notificationConfigs!);
  }
  buildCounterListNotificationConfigsResponse--;
}

core.List<api.Operation> buildUnnamed1838() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed1838(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed1838();
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
    checkUnnamed1838(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.Source> buildUnnamed1839() {
  var o = <api.Source>[];
  o.add(buildSource());
  o.add(buildSource());
  return o;
}

void checkUnnamed1839(core.List<api.Source> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSource(o[0] as api.Source);
  checkSource(o[1] as api.Source);
}

core.int buildCounterListSourcesResponse = 0;
api.ListSourcesResponse buildListSourcesResponse() {
  var o = api.ListSourcesResponse();
  buildCounterListSourcesResponse++;
  if (buildCounterListSourcesResponse < 3) {
    o.nextPageToken = 'foo';
    o.sources = buildUnnamed1839();
  }
  buildCounterListSourcesResponse--;
  return o;
}

void checkListSourcesResponse(api.ListSourcesResponse o) {
  buildCounterListSourcesResponse++;
  if (buildCounterListSourcesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1839(o.sources!);
  }
  buildCounterListSourcesResponse--;
}

core.int buildCounterNotificationConfig = 0;
api.NotificationConfig buildNotificationConfig() {
  var o = api.NotificationConfig();
  buildCounterNotificationConfig++;
  if (buildCounterNotificationConfig < 3) {
    o.description = 'foo';
    o.name = 'foo';
    o.pubsubTopic = 'foo';
    o.serviceAccount = 'foo';
    o.streamingConfig = buildStreamingConfig();
  }
  buildCounterNotificationConfig--;
  return o;
}

void checkNotificationConfig(api.NotificationConfig o) {
  buildCounterNotificationConfig++;
  if (buildCounterNotificationConfig < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pubsubTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
    checkStreamingConfig(o.streamingConfig! as api.StreamingConfig);
  }
  buildCounterNotificationConfig--;
}

core.Map<core.String, core.Object> buildUnnamed1840() {
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

void checkUnnamed1840(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed1841() {
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

void checkUnnamed1841(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed1840();
    o.name = 'foo';
    o.response = buildUnnamed1841();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed1840(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed1841(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOrganizationSettings = 0;
api.OrganizationSettings buildOrganizationSettings() {
  var o = api.OrganizationSettings();
  buildCounterOrganizationSettings++;
  if (buildCounterOrganizationSettings < 3) {
    o.assetDiscoveryConfig = buildAssetDiscoveryConfig();
    o.enableAssetDiscovery = true;
    o.name = 'foo';
  }
  buildCounterOrganizationSettings--;
  return o;
}

void checkOrganizationSettings(api.OrganizationSettings o) {
  buildCounterOrganizationSettings++;
  if (buildCounterOrganizationSettings < 3) {
    checkAssetDiscoveryConfig(
        o.assetDiscoveryConfig! as api.AssetDiscoveryConfig);
    unittest.expect(o.enableAssetDiscovery!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterOrganizationSettings--;
}

core.List<api.AuditConfig> buildUnnamed1842() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed1842(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed1843() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed1843(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed1842();
    o.bindings = buildUnnamed1843();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed1842(o.auditConfigs!);
    checkUnnamed1843(o.bindings!);
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

core.List<api.Folder> buildUnnamed1844() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed1844(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.int buildCounterResource = 0;
api.Resource buildResource() {
  var o = api.Resource();
  buildCounterResource++;
  if (buildCounterResource < 3) {
    o.folders = buildUnnamed1844();
    o.name = 'foo';
    o.parentDisplayName = 'foo';
    o.parentName = 'foo';
    o.projectDisplayName = 'foo';
    o.projectName = 'foo';
  }
  buildCounterResource--;
  return o;
}

void checkResource(api.Resource o) {
  buildCounterResource++;
  if (buildCounterResource < 3) {
    checkUnnamed1844(o.folders!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectName!,
      unittest.equals('foo'),
    );
  }
  buildCounterResource--;
}

core.int buildCounterRunAssetDiscoveryRequest = 0;
api.RunAssetDiscoveryRequest buildRunAssetDiscoveryRequest() {
  var o = api.RunAssetDiscoveryRequest();
  buildCounterRunAssetDiscoveryRequest++;
  if (buildCounterRunAssetDiscoveryRequest < 3) {}
  buildCounterRunAssetDiscoveryRequest--;
  return o;
}

void checkRunAssetDiscoveryRequest(api.RunAssetDiscoveryRequest o) {
  buildCounterRunAssetDiscoveryRequest++;
  if (buildCounterRunAssetDiscoveryRequest < 3) {}
  buildCounterRunAssetDiscoveryRequest--;
}

core.List<api.Folder> buildUnnamed1845() {
  var o = <api.Folder>[];
  o.add(buildFolder());
  o.add(buildFolder());
  return o;
}

void checkUnnamed1845(core.List<api.Folder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFolder(o[0] as api.Folder);
  checkFolder(o[1] as api.Folder);
}

core.List<core.String> buildUnnamed1846() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1846(core.List<core.String> o) {
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

core.int buildCounterSecurityCenterProperties = 0;
api.SecurityCenterProperties buildSecurityCenterProperties() {
  var o = api.SecurityCenterProperties();
  buildCounterSecurityCenterProperties++;
  if (buildCounterSecurityCenterProperties < 3) {
    o.folders = buildUnnamed1845();
    o.resourceDisplayName = 'foo';
    o.resourceName = 'foo';
    o.resourceOwners = buildUnnamed1846();
    o.resourceParent = 'foo';
    o.resourceParentDisplayName = 'foo';
    o.resourceProject = 'foo';
    o.resourceProjectDisplayName = 'foo';
    o.resourceType = 'foo';
  }
  buildCounterSecurityCenterProperties--;
  return o;
}

void checkSecurityCenterProperties(api.SecurityCenterProperties o) {
  buildCounterSecurityCenterProperties++;
  if (buildCounterSecurityCenterProperties < 3) {
    checkUnnamed1845(o.folders!);
    unittest.expect(
      o.resourceDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
    checkUnnamed1846(o.resourceOwners!);
    unittest.expect(
      o.resourceParent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceParentDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceProject!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceProjectDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSecurityCenterProperties--;
}

core.Map<core.String, core.String> buildUnnamed1847() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1847(core.Map<core.String, core.String> o) {
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

core.int buildCounterSecurityMarks = 0;
api.SecurityMarks buildSecurityMarks() {
  var o = api.SecurityMarks();
  buildCounterSecurityMarks++;
  if (buildCounterSecurityMarks < 3) {
    o.canonicalName = 'foo';
    o.marks = buildUnnamed1847();
    o.name = 'foo';
  }
  buildCounterSecurityMarks--;
  return o;
}

void checkSecurityMarks(api.SecurityMarks o) {
  buildCounterSecurityMarks++;
  if (buildCounterSecurityMarks < 3) {
    unittest.expect(
      o.canonicalName!,
      unittest.equals('foo'),
    );
    checkUnnamed1847(o.marks!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSecurityMarks--;
}

core.int buildCounterSetFindingStateRequest = 0;
api.SetFindingStateRequest buildSetFindingStateRequest() {
  var o = api.SetFindingStateRequest();
  buildCounterSetFindingStateRequest++;
  if (buildCounterSetFindingStateRequest < 3) {
    o.startTime = 'foo';
    o.state = 'foo';
  }
  buildCounterSetFindingStateRequest--;
  return o;
}

void checkSetFindingStateRequest(api.SetFindingStateRequest o) {
  buildCounterSetFindingStateRequest++;
  if (buildCounterSetFindingStateRequest < 3) {
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetFindingStateRequest--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildPolicy();
    o.updateMask = 'foo';
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkPolicy(o.policy! as api.Policy);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetIamPolicyRequest--;
}

core.int buildCounterSource = 0;
api.Source buildSource() {
  var o = api.Source();
  buildCounterSource++;
  if (buildCounterSource < 3) {
    o.canonicalName = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
  }
  buildCounterSource--;
  return o;
}

void checkSource(api.Source o) {
  buildCounterSource++;
  if (buildCounterSource < 3) {
    unittest.expect(
      o.canonicalName!,
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
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSource--;
}

core.Map<core.String, core.Object> buildUnnamed1848() {
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

void checkUnnamed1848(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed1849() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed1848());
  o.add(buildUnnamed1848());
  return o;
}

void checkUnnamed1849(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1848(o[0]);
  checkUnnamed1848(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed1849();
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
    checkUnnamed1849(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterStreamingConfig = 0;
api.StreamingConfig buildStreamingConfig() {
  var o = api.StreamingConfig();
  buildCounterStreamingConfig++;
  if (buildCounterStreamingConfig < 3) {
    o.filter = 'foo';
  }
  buildCounterStreamingConfig--;
  return o;
}

void checkStreamingConfig(api.StreamingConfig o) {
  buildCounterStreamingConfig++;
  if (buildCounterStreamingConfig < 3) {
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
  }
  buildCounterStreamingConfig--;
}

core.List<core.String> buildUnnamed1850() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1850(core.List<core.String> o) {
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
    o.permissions = buildUnnamed1850();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed1850(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed1851() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1851(core.List<core.String> o) {
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
    o.permissions = buildUnnamed1851();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed1851(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

void main() {
  unittest.group('obj-schema-Asset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Asset.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAsset(od as api.Asset);
    });
  });

  unittest.group('obj-schema-AssetDiscoveryConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssetDiscoveryConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssetDiscoveryConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssetDiscoveryConfig(od as api.AssetDiscoveryConfig);
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

  unittest.group('obj-schema-Binding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Binding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBinding(od as api.Binding);
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

  unittest.group('obj-schema-Expr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Expr.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExpr(od as api.Expr);
    });
  });

  unittest.group('obj-schema-Finding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Finding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFinding(od as api.Finding);
    });
  });

  unittest.group('obj-schema-Folder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFolder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Folder.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFolder(od as api.Folder);
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

  unittest.group('obj-schema-GoogleCloudSecuritycenterV1NotificationMessage',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1NotificationMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1NotificationMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1NotificationMessage(
          od as api.GoogleCloudSecuritycenterV1NotificationMessage);
    });
  });

  unittest.group('obj-schema-GoogleCloudSecuritycenterV1Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1Resource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1Resource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1Resource(
          od as api.GoogleCloudSecuritycenterV1Resource);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1RunAssetDiscoveryResponse(
          od as api.GoogleCloudSecuritycenterV1RunAssetDiscoveryResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse(
          od as api.GoogleCloudSecuritycenterV1beta1RunAssetDiscoveryResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudSecuritycenterV1p1beta1Finding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1p1beta1Finding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1p1beta1Finding.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1p1beta1Finding(
          od as api.GoogleCloudSecuritycenterV1p1beta1Finding);
    });
  });

  unittest.group('obj-schema-GoogleCloudSecuritycenterV1p1beta1Folder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1p1beta1Folder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1p1beta1Folder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1p1beta1Folder(
          od as api.GoogleCloudSecuritycenterV1p1beta1Folder);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudSecuritycenterV1p1beta1NotificationMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1p1beta1NotificationMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudSecuritycenterV1p1beta1NotificationMessage.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1p1beta1NotificationMessage(
          od as api.GoogleCloudSecuritycenterV1p1beta1NotificationMessage);
    });
  });

  unittest.group('obj-schema-GoogleCloudSecuritycenterV1p1beta1Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1p1beta1Resource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1p1beta1Resource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1p1beta1Resource(
          od as api.GoogleCloudSecuritycenterV1p1beta1Resource);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse(od
          as api.GoogleCloudSecuritycenterV1p1beta1RunAssetDiscoveryResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudSecuritycenterV1p1beta1SecurityMarks',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudSecuritycenterV1p1beta1SecurityMarks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudSecuritycenterV1p1beta1SecurityMarks.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudSecuritycenterV1p1beta1SecurityMarks(
          od as api.GoogleCloudSecuritycenterV1p1beta1SecurityMarks);
    });
  });

  unittest.group('obj-schema-GroupAssetsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupAssetsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupAssetsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupAssetsRequest(od as api.GroupAssetsRequest);
    });
  });

  unittest.group('obj-schema-GroupAssetsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupAssetsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupAssetsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupAssetsResponse(od as api.GroupAssetsResponse);
    });
  });

  unittest.group('obj-schema-GroupFindingsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupFindingsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupFindingsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupFindingsRequest(od as api.GroupFindingsRequest);
    });
  });

  unittest.group('obj-schema-GroupFindingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupFindingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupFindingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupFindingsResponse(od as api.GroupFindingsResponse);
    });
  });

  unittest.group('obj-schema-GroupResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupResult(od as api.GroupResult);
    });
  });

  unittest.group('obj-schema-IamPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIamPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IamPolicy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIamPolicy(od as api.IamPolicy);
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

  unittest.group('obj-schema-ListAssetsResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAssetsResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAssetsResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAssetsResult(od as api.ListAssetsResult);
    });
  });

  unittest.group('obj-schema-ListFindingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFindingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFindingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFindingsResponse(od as api.ListFindingsResponse);
    });
  });

  unittest.group('obj-schema-ListFindingsResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFindingsResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFindingsResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFindingsResult(od as api.ListFindingsResult);
    });
  });

  unittest.group('obj-schema-ListNotificationConfigsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListNotificationConfigsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListNotificationConfigsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListNotificationConfigsResponse(
          od as api.ListNotificationConfigsResponse);
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

  unittest.group('obj-schema-ListSourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSourcesResponse(od as api.ListSourcesResponse);
    });
  });

  unittest.group('obj-schema-NotificationConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNotificationConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NotificationConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNotificationConfig(od as api.NotificationConfig);
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

  unittest.group('obj-schema-OrganizationSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrganizationSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OrganizationSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrganizationSettings(od as api.OrganizationSettings);
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

  unittest.group('obj-schema-Resource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Resource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResource(od as api.Resource);
    });
  });

  unittest.group('obj-schema-RunAssetDiscoveryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRunAssetDiscoveryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RunAssetDiscoveryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRunAssetDiscoveryRequest(od as api.RunAssetDiscoveryRequest);
    });
  });

  unittest.group('obj-schema-SecurityCenterProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecurityCenterProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SecurityCenterProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSecurityCenterProperties(od as api.SecurityCenterProperties);
    });
  });

  unittest.group('obj-schema-SecurityMarks', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecurityMarks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SecurityMarks.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSecurityMarks(od as api.SecurityMarks);
    });
  });

  unittest.group('obj-schema-SetFindingStateRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetFindingStateRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetFindingStateRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetFindingStateRequest(od as api.SetFindingStateRequest);
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

  unittest.group('obj-schema-Source', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Source.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSource(od as api.Source);
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

  unittest.group('obj-schema-StreamingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStreamingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StreamingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStreamingConfig(od as api.StreamingConfig);
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

  unittest.group('resource-FoldersAssetsResource', () {
    unittest.test('method--group', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.assets;
      var arg_request = buildGroupAssetsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GroupAssetsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGroupAssetsRequest(obj as api.GroupAssetsRequest);

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
        var resp = convert.json.encode(buildGroupAssetsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.group(arg_request, arg_parent, $fields: arg_$fields);
      checkGroupAssetsResponse(response as api.GroupAssetsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.assets;
      var arg_parent = 'foo';
      var arg_compareDuration = 'foo';
      var arg_fieldMask = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["compareDuration"]!.first,
          unittest.equals(arg_compareDuration),
        );
        unittest.expect(
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          compareDuration: arg_compareDuration,
          fieldMask: arg_fieldMask,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListAssetsResponse(response as api.ListAssetsResponse);
    });

    unittest.test('method--updateSecurityMarks', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.assets;
      var arg_request = buildSecurityMarks();
      var arg_name = 'foo';
      var arg_startTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SecurityMarks.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSecurityMarks(obj as api.SecurityMarks);

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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
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
        var resp = convert.json.encode(buildSecurityMarks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateSecurityMarks(arg_request, arg_name,
          startTime: arg_startTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkSecurityMarks(response as api.SecurityMarks);
    });
  });

  unittest.group('resource-FoldersSourcesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.sources;
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
        var resp = convert.json.encode(buildListSourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSourcesResponse(response as api.ListSourcesResponse);
    });
  });

  unittest.group('resource-FoldersSourcesFindingsResource', () {
    unittest.test('method--group', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.sources.findings;
      var arg_request = buildGroupFindingsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GroupFindingsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGroupFindingsRequest(obj as api.GroupFindingsRequest);

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
        var resp = convert.json.encode(buildGroupFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.group(arg_request, arg_parent, $fields: arg_$fields);
      checkGroupFindingsResponse(response as api.GroupFindingsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.sources.findings;
      var arg_parent = 'foo';
      var arg_compareDuration = 'foo';
      var arg_fieldMask = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["compareDuration"]!.first,
          unittest.equals(arg_compareDuration),
        );
        unittest.expect(
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          compareDuration: arg_compareDuration,
          fieldMask: arg_fieldMask,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListFindingsResponse(response as api.ListFindingsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.sources.findings;
      var arg_request = buildFinding();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Finding.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFinding(obj as api.Finding);

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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--setState', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.sources.findings;
      var arg_request = buildSetFindingStateRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetFindingStateRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetFindingStateRequest(obj as api.SetFindingStateRequest);

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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setState(arg_request, arg_name, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--updateSecurityMarks', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).folders.sources.findings;
      var arg_request = buildSecurityMarks();
      var arg_name = 'foo';
      var arg_startTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SecurityMarks.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSecurityMarks(obj as api.SecurityMarks);

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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
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
        var resp = convert.json.encode(buildSecurityMarks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateSecurityMarks(arg_request, arg_name,
          startTime: arg_startTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkSecurityMarks(response as api.SecurityMarks);
    });
  });

  unittest.group('resource-OrganizationsResource', () {
    unittest.test('method--getOrganizationSettings', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations;
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
        var resp = convert.json.encode(buildOrganizationSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getOrganizationSettings(arg_name, $fields: arg_$fields);
      checkOrganizationSettings(response as api.OrganizationSettings);
    });

    unittest.test('method--updateOrganizationSettings', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations;
      var arg_request = buildOrganizationSettings();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.OrganizationSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkOrganizationSettings(obj as api.OrganizationSettings);

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
        var resp = convert.json.encode(buildOrganizationSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateOrganizationSettings(
          arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOrganizationSettings(response as api.OrganizationSettings);
    });
  });

  unittest.group('resource-OrganizationsAssetsResource', () {
    unittest.test('method--group', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.assets;
      var arg_request = buildGroupAssetsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GroupAssetsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGroupAssetsRequest(obj as api.GroupAssetsRequest);

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
        var resp = convert.json.encode(buildGroupAssetsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.group(arg_request, arg_parent, $fields: arg_$fields);
      checkGroupAssetsResponse(response as api.GroupAssetsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.assets;
      var arg_parent = 'foo';
      var arg_compareDuration = 'foo';
      var arg_fieldMask = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["compareDuration"]!.first,
          unittest.equals(arg_compareDuration),
        );
        unittest.expect(
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          compareDuration: arg_compareDuration,
          fieldMask: arg_fieldMask,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListAssetsResponse(response as api.ListAssetsResponse);
    });

    unittest.test('method--runDiscovery', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.assets;
      var arg_request = buildRunAssetDiscoveryRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RunAssetDiscoveryRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRunAssetDiscoveryRequest(obj as api.RunAssetDiscoveryRequest);

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
          await res.runDiscovery(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--updateSecurityMarks', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.assets;
      var arg_request = buildSecurityMarks();
      var arg_name = 'foo';
      var arg_startTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SecurityMarks.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSecurityMarks(obj as api.SecurityMarks);

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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
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
        var resp = convert.json.encode(buildSecurityMarks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateSecurityMarks(arg_request, arg_name,
          startTime: arg_startTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkSecurityMarks(response as api.SecurityMarks);
    });
  });

  unittest.group('resource-OrganizationsNotificationConfigsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.notificationConfigs;
      var arg_request = buildNotificationConfig();
      var arg_parent = 'foo';
      var arg_configId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.NotificationConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkNotificationConfig(obj as api.NotificationConfig);

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
          queryMap["configId"]!.first,
          unittest.equals(arg_configId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildNotificationConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          configId: arg_configId, $fields: arg_$fields);
      checkNotificationConfig(response as api.NotificationConfig);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.notificationConfigs;
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
          api.SecurityCommandCenterApi(mock).organizations.notificationConfigs;
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
        var resp = convert.json.encode(buildNotificationConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkNotificationConfig(response as api.NotificationConfig);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.notificationConfigs;
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
        var resp = convert.json.encode(buildListNotificationConfigsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListNotificationConfigsResponse(
          response as api.ListNotificationConfigsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.notificationConfigs;
      var arg_request = buildNotificationConfig();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.NotificationConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkNotificationConfig(obj as api.NotificationConfig);

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
        var resp = convert.json.encode(buildNotificationConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkNotificationConfig(response as api.NotificationConfig);
    });
  });

  unittest.group('resource-OrganizationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.operations;
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
      var res = api.SecurityCommandCenterApi(mock).organizations.operations;
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
      var res = api.SecurityCommandCenterApi(mock).organizations.operations;
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
      var res = api.SecurityCommandCenterApi(mock).organizations.operations;
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

  unittest.group('resource-OrganizationsSourcesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
      var arg_request = buildSource();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Source.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSource(obj as api.Source);

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
        var resp = convert.json.encode(buildSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkSource(response as api.Source);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
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
        var resp = convert.json.encode(buildSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSource(response as api.Source);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
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
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
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
        var resp = convert.json.encode(buildListSourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSourcesResponse(response as api.ListSourcesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
      var arg_request = buildSource();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Source.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSource(obj as api.Source);

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
        var resp = convert.json.encode(buildSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkSource(response as api.Source);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
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
      var res = api.SecurityCommandCenterApi(mock).organizations.sources;
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

  unittest.group('resource-OrganizationsSourcesFindingsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.sources.findings;
      var arg_request = buildFinding();
      var arg_parent = 'foo';
      var arg_findingId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Finding.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFinding(obj as api.Finding);

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
          queryMap["findingId"]!.first,
          unittest.equals(arg_findingId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          findingId: arg_findingId, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--group', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.sources.findings;
      var arg_request = buildGroupFindingsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GroupFindingsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGroupFindingsRequest(obj as api.GroupFindingsRequest);

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
        var resp = convert.json.encode(buildGroupFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.group(arg_request, arg_parent, $fields: arg_$fields);
      checkGroupFindingsResponse(response as api.GroupFindingsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.sources.findings;
      var arg_parent = 'foo';
      var arg_compareDuration = 'foo';
      var arg_fieldMask = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["compareDuration"]!.first,
          unittest.equals(arg_compareDuration),
        );
        unittest.expect(
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          compareDuration: arg_compareDuration,
          fieldMask: arg_fieldMask,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListFindingsResponse(response as api.ListFindingsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.sources.findings;
      var arg_request = buildFinding();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Finding.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFinding(obj as api.Finding);

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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--setState', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.sources.findings;
      var arg_request = buildSetFindingStateRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetFindingStateRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetFindingStateRequest(obj as api.SetFindingStateRequest);

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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setState(arg_request, arg_name, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--updateSecurityMarks', () async {
      var mock = HttpServerMock();
      var res =
          api.SecurityCommandCenterApi(mock).organizations.sources.findings;
      var arg_request = buildSecurityMarks();
      var arg_name = 'foo';
      var arg_startTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SecurityMarks.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSecurityMarks(obj as api.SecurityMarks);

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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
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
        var resp = convert.json.encode(buildSecurityMarks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateSecurityMarks(arg_request, arg_name,
          startTime: arg_startTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkSecurityMarks(response as api.SecurityMarks);
    });
  });

  unittest.group('resource-ProjectsAssetsResource', () {
    unittest.test('method--group', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.assets;
      var arg_request = buildGroupAssetsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GroupAssetsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGroupAssetsRequest(obj as api.GroupAssetsRequest);

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
        var resp = convert.json.encode(buildGroupAssetsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.group(arg_request, arg_parent, $fields: arg_$fields);
      checkGroupAssetsResponse(response as api.GroupAssetsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.assets;
      var arg_parent = 'foo';
      var arg_compareDuration = 'foo';
      var arg_fieldMask = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["compareDuration"]!.first,
          unittest.equals(arg_compareDuration),
        );
        unittest.expect(
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          compareDuration: arg_compareDuration,
          fieldMask: arg_fieldMask,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListAssetsResponse(response as api.ListAssetsResponse);
    });

    unittest.test('method--updateSecurityMarks', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.assets;
      var arg_request = buildSecurityMarks();
      var arg_name = 'foo';
      var arg_startTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SecurityMarks.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSecurityMarks(obj as api.SecurityMarks);

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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
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
        var resp = convert.json.encode(buildSecurityMarks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateSecurityMarks(arg_request, arg_name,
          startTime: arg_startTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkSecurityMarks(response as api.SecurityMarks);
    });
  });

  unittest.group('resource-ProjectsSourcesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.sources;
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
        var resp = convert.json.encode(buildListSourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSourcesResponse(response as api.ListSourcesResponse);
    });
  });

  unittest.group('resource-ProjectsSourcesFindingsResource', () {
    unittest.test('method--group', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.sources.findings;
      var arg_request = buildGroupFindingsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GroupFindingsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGroupFindingsRequest(obj as api.GroupFindingsRequest);

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
        var resp = convert.json.encode(buildGroupFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.group(arg_request, arg_parent, $fields: arg_$fields);
      checkGroupFindingsResponse(response as api.GroupFindingsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.sources.findings;
      var arg_parent = 'foo';
      var arg_compareDuration = 'foo';
      var arg_fieldMask = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["compareDuration"]!.first,
          unittest.equals(arg_compareDuration),
        );
        unittest.expect(
          queryMap["fieldMask"]!.first,
          unittest.equals(arg_fieldMask),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListFindingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          compareDuration: arg_compareDuration,
          fieldMask: arg_fieldMask,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readTime: arg_readTime,
          $fields: arg_$fields);
      checkListFindingsResponse(response as api.ListFindingsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.sources.findings;
      var arg_request = buildFinding();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Finding.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFinding(obj as api.Finding);

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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--setState', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.sources.findings;
      var arg_request = buildSetFindingStateRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetFindingStateRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetFindingStateRequest(obj as api.SetFindingStateRequest);

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
        var resp = convert.json.encode(buildFinding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.setState(arg_request, arg_name, $fields: arg_$fields);
      checkFinding(response as api.Finding);
    });

    unittest.test('method--updateSecurityMarks', () async {
      var mock = HttpServerMock();
      var res = api.SecurityCommandCenterApi(mock).projects.sources.findings;
      var arg_request = buildSecurityMarks();
      var arg_name = 'foo';
      var arg_startTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SecurityMarks.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSecurityMarks(obj as api.SecurityMarks);

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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
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
        var resp = convert.json.encode(buildSecurityMarks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateSecurityMarks(arg_request, arg_name,
          startTime: arg_startTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkSecurityMarks(response as api.SecurityMarks);
    });
  });
}
