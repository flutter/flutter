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

import 'package:googleapis/networkmanagement/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAbortInfo = 0;
api.AbortInfo buildAbortInfo() {
  var o = api.AbortInfo();
  buildCounterAbortInfo++;
  if (buildCounterAbortInfo < 3) {
    o.cause = 'foo';
    o.resourceUri = 'foo';
  }
  buildCounterAbortInfo--;
  return o;
}

void checkAbortInfo(api.AbortInfo o) {
  buildCounterAbortInfo++;
  if (buildCounterAbortInfo < 3) {
    unittest.expect(
      o.cause!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterAbortInfo--;
}

core.List<api.AuditLogConfig> buildUnnamed4440() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed4440(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed4440();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed4440(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed4441() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4441(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed4441();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed4441(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed4442() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4442(core.List<core.String> o) {
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
    o.members = buildUnnamed4442();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed4442(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterCancelOperationRequest = 0;
api.CancelOperationRequest buildCancelOperationRequest() {
  var o = api.CancelOperationRequest();
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
  return o;
}

void checkCancelOperationRequest(api.CancelOperationRequest o) {
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
}

core.int buildCounterCloudSQLInstanceInfo = 0;
api.CloudSQLInstanceInfo buildCloudSQLInstanceInfo() {
  var o = api.CloudSQLInstanceInfo();
  buildCounterCloudSQLInstanceInfo++;
  if (buildCounterCloudSQLInstanceInfo < 3) {
    o.displayName = 'foo';
    o.externalIp = 'foo';
    o.internalIp = 'foo';
    o.networkUri = 'foo';
    o.region = 'foo';
    o.uri = 'foo';
  }
  buildCounterCloudSQLInstanceInfo--;
  return o;
}

void checkCloudSQLInstanceInfo(api.CloudSQLInstanceInfo o) {
  buildCounterCloudSQLInstanceInfo++;
  if (buildCounterCloudSQLInstanceInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudSQLInstanceInfo--;
}

core.Map<core.String, core.String> buildUnnamed4443() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4443(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed4444() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4444(core.List<core.String> o) {
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

core.int buildCounterConnectivityTest = 0;
api.ConnectivityTest buildConnectivityTest() {
  var o = api.ConnectivityTest();
  buildCounterConnectivityTest++;
  if (buildCounterConnectivityTest < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.destination = buildEndpoint();
    o.displayName = 'foo';
    o.labels = buildUnnamed4443();
    o.name = 'foo';
    o.protocol = 'foo';
    o.reachabilityDetails = buildReachabilityDetails();
    o.relatedProjects = buildUnnamed4444();
    o.source = buildEndpoint();
    o.updateTime = 'foo';
  }
  buildCounterConnectivityTest--;
  return o;
}

void checkConnectivityTest(api.ConnectivityTest o) {
  buildCounterConnectivityTest++;
  if (buildCounterConnectivityTest < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkEndpoint(o.destination! as api.Endpoint);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4443(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    checkReachabilityDetails(o.reachabilityDetails! as api.ReachabilityDetails);
    checkUnnamed4444(o.relatedProjects!);
    checkEndpoint(o.source! as api.Endpoint);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterConnectivityTest--;
}

core.int buildCounterDeliverInfo = 0;
api.DeliverInfo buildDeliverInfo() {
  var o = api.DeliverInfo();
  buildCounterDeliverInfo++;
  if (buildCounterDeliverInfo < 3) {
    o.resourceUri = 'foo';
    o.target = 'foo';
  }
  buildCounterDeliverInfo--;
  return o;
}

void checkDeliverInfo(api.DeliverInfo o) {
  buildCounterDeliverInfo++;
  if (buildCounterDeliverInfo < 3) {
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeliverInfo--;
}

core.int buildCounterDropInfo = 0;
api.DropInfo buildDropInfo() {
  var o = api.DropInfo();
  buildCounterDropInfo++;
  if (buildCounterDropInfo < 3) {
    o.cause = 'foo';
    o.resourceUri = 'foo';
  }
  buildCounterDropInfo--;
  return o;
}

void checkDropInfo(api.DropInfo o) {
  buildCounterDropInfo++;
  if (buildCounterDropInfo < 3) {
    unittest.expect(
      o.cause!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterDropInfo--;
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

core.int buildCounterEndpoint = 0;
api.Endpoint buildEndpoint() {
  var o = api.Endpoint();
  buildCounterEndpoint++;
  if (buildCounterEndpoint < 3) {
    o.cloudSqlInstance = 'foo';
    o.gkeMasterCluster = 'foo';
    o.instance = 'foo';
    o.ipAddress = 'foo';
    o.network = 'foo';
    o.networkType = 'foo';
    o.port = 42;
    o.projectId = 'foo';
  }
  buildCounterEndpoint--;
  return o;
}

void checkEndpoint(api.Endpoint o) {
  buildCounterEndpoint++;
  if (buildCounterEndpoint < 3) {
    unittest.expect(
      o.cloudSqlInstance!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gkeMasterCluster!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.instance!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ipAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.network!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.port!,
      unittest.equals(42),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterEndpoint--;
}

core.int buildCounterEndpointInfo = 0;
api.EndpointInfo buildEndpointInfo() {
  var o = api.EndpointInfo();
  buildCounterEndpointInfo++;
  if (buildCounterEndpointInfo < 3) {
    o.destinationIp = 'foo';
    o.destinationNetworkUri = 'foo';
    o.destinationPort = 42;
    o.protocol = 'foo';
    o.sourceIp = 'foo';
    o.sourceNetworkUri = 'foo';
    o.sourcePort = 42;
  }
  buildCounterEndpointInfo--;
  return o;
}

void checkEndpointInfo(api.EndpointInfo o) {
  buildCounterEndpointInfo++;
  if (buildCounterEndpointInfo < 3) {
    unittest.expect(
      o.destinationIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destinationNetworkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destinationPort!,
      unittest.equals(42),
    );
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceNetworkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourcePort!,
      unittest.equals(42),
    );
  }
  buildCounterEndpointInfo--;
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

core.List<core.String> buildUnnamed4445() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4445(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4446() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4446(core.List<core.String> o) {
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

core.int buildCounterFirewallInfo = 0;
api.FirewallInfo buildFirewallInfo() {
  var o = api.FirewallInfo();
  buildCounterFirewallInfo++;
  if (buildCounterFirewallInfo < 3) {
    o.action = 'foo';
    o.direction = 'foo';
    o.displayName = 'foo';
    o.firewallRuleType = 'foo';
    o.networkUri = 'foo';
    o.policy = 'foo';
    o.priority = 42;
    o.targetServiceAccounts = buildUnnamed4445();
    o.targetTags = buildUnnamed4446();
    o.uri = 'foo';
  }
  buildCounterFirewallInfo--;
  return o;
}

void checkFirewallInfo(api.FirewallInfo o) {
  buildCounterFirewallInfo++;
  if (buildCounterFirewallInfo < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.direction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firewallRuleType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.policy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.priority!,
      unittest.equals(42),
    );
    checkUnnamed4445(o.targetServiceAccounts!);
    checkUnnamed4446(o.targetTags!);
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterFirewallInfo--;
}

core.int buildCounterForwardInfo = 0;
api.ForwardInfo buildForwardInfo() {
  var o = api.ForwardInfo();
  buildCounterForwardInfo++;
  if (buildCounterForwardInfo < 3) {
    o.resourceUri = 'foo';
    o.target = 'foo';
  }
  buildCounterForwardInfo--;
  return o;
}

void checkForwardInfo(api.ForwardInfo o) {
  buildCounterForwardInfo++;
  if (buildCounterForwardInfo < 3) {
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
  }
  buildCounterForwardInfo--;
}

core.int buildCounterForwardingRuleInfo = 0;
api.ForwardingRuleInfo buildForwardingRuleInfo() {
  var o = api.ForwardingRuleInfo();
  buildCounterForwardingRuleInfo++;
  if (buildCounterForwardingRuleInfo < 3) {
    o.displayName = 'foo';
    o.matchedPortRange = 'foo';
    o.matchedProtocol = 'foo';
    o.networkUri = 'foo';
    o.target = 'foo';
    o.uri = 'foo';
    o.vip = 'foo';
  }
  buildCounterForwardingRuleInfo--;
  return o;
}

void checkForwardingRuleInfo(api.ForwardingRuleInfo o) {
  buildCounterForwardingRuleInfo++;
  if (buildCounterForwardingRuleInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.matchedPortRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.matchedProtocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vip!,
      unittest.equals('foo'),
    );
  }
  buildCounterForwardingRuleInfo--;
}

core.int buildCounterGKEMasterInfo = 0;
api.GKEMasterInfo buildGKEMasterInfo() {
  var o = api.GKEMasterInfo();
  buildCounterGKEMasterInfo++;
  if (buildCounterGKEMasterInfo < 3) {
    o.clusterNetworkUri = 'foo';
    o.clusterUri = 'foo';
    o.externalIp = 'foo';
    o.internalIp = 'foo';
  }
  buildCounterGKEMasterInfo--;
  return o;
}

void checkGKEMasterInfo(api.GKEMasterInfo o) {
  buildCounterGKEMasterInfo++;
  if (buildCounterGKEMasterInfo < 3) {
    unittest.expect(
      o.clusterNetworkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clusterUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalIp!,
      unittest.equals('foo'),
    );
  }
  buildCounterGKEMasterInfo--;
}

core.List<core.String> buildUnnamed4447() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4447(core.List<core.String> o) {
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

core.int buildCounterInstanceInfo = 0;
api.InstanceInfo buildInstanceInfo() {
  var o = api.InstanceInfo();
  buildCounterInstanceInfo++;
  if (buildCounterInstanceInfo < 3) {
    o.displayName = 'foo';
    o.externalIp = 'foo';
    o.interface = 'foo';
    o.internalIp = 'foo';
    o.networkTags = buildUnnamed4447();
    o.networkUri = 'foo';
    o.serviceAccount = 'foo';
    o.uri = 'foo';
  }
  buildCounterInstanceInfo--;
  return o;
}

void checkInstanceInfo(api.InstanceInfo o) {
  buildCounterInstanceInfo++;
  if (buildCounterInstanceInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.interface!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalIp!,
      unittest.equals('foo'),
    );
    checkUnnamed4447(o.networkTags!);
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterInstanceInfo--;
}

core.List<api.ConnectivityTest> buildUnnamed4448() {
  var o = <api.ConnectivityTest>[];
  o.add(buildConnectivityTest());
  o.add(buildConnectivityTest());
  return o;
}

void checkUnnamed4448(core.List<api.ConnectivityTest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConnectivityTest(o[0] as api.ConnectivityTest);
  checkConnectivityTest(o[1] as api.ConnectivityTest);
}

core.List<core.String> buildUnnamed4449() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4449(core.List<core.String> o) {
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

core.int buildCounterListConnectivityTestsResponse = 0;
api.ListConnectivityTestsResponse buildListConnectivityTestsResponse() {
  var o = api.ListConnectivityTestsResponse();
  buildCounterListConnectivityTestsResponse++;
  if (buildCounterListConnectivityTestsResponse < 3) {
    o.nextPageToken = 'foo';
    o.resources = buildUnnamed4448();
    o.unreachable = buildUnnamed4449();
  }
  buildCounterListConnectivityTestsResponse--;
  return o;
}

void checkListConnectivityTestsResponse(api.ListConnectivityTestsResponse o) {
  buildCounterListConnectivityTestsResponse++;
  if (buildCounterListConnectivityTestsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4448(o.resources!);
    checkUnnamed4449(o.unreachable!);
  }
  buildCounterListConnectivityTestsResponse--;
}

core.List<api.Location> buildUnnamed4450() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed4450(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed4450();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed4450(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Operation> buildUnnamed4451() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed4451(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed4451();
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
    checkUnnamed4451(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<core.String> buildUnnamed4452() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4452(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4453() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4453(core.List<core.String> o) {
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

core.int buildCounterLoadBalancerBackend = 0;
api.LoadBalancerBackend buildLoadBalancerBackend() {
  var o = api.LoadBalancerBackend();
  buildCounterLoadBalancerBackend++;
  if (buildCounterLoadBalancerBackend < 3) {
    o.displayName = 'foo';
    o.healthCheckAllowingFirewallRules = buildUnnamed4452();
    o.healthCheckBlockingFirewallRules = buildUnnamed4453();
    o.healthCheckFirewallState = 'foo';
    o.uri = 'foo';
  }
  buildCounterLoadBalancerBackend--;
  return o;
}

void checkLoadBalancerBackend(api.LoadBalancerBackend o) {
  buildCounterLoadBalancerBackend++;
  if (buildCounterLoadBalancerBackend < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4452(o.healthCheckAllowingFirewallRules!);
    checkUnnamed4453(o.healthCheckBlockingFirewallRules!);
    unittest.expect(
      o.healthCheckFirewallState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterLoadBalancerBackend--;
}

core.List<api.LoadBalancerBackend> buildUnnamed4454() {
  var o = <api.LoadBalancerBackend>[];
  o.add(buildLoadBalancerBackend());
  o.add(buildLoadBalancerBackend());
  return o;
}

void checkUnnamed4454(core.List<api.LoadBalancerBackend> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLoadBalancerBackend(o[0] as api.LoadBalancerBackend);
  checkLoadBalancerBackend(o[1] as api.LoadBalancerBackend);
}

core.int buildCounterLoadBalancerInfo = 0;
api.LoadBalancerInfo buildLoadBalancerInfo() {
  var o = api.LoadBalancerInfo();
  buildCounterLoadBalancerInfo++;
  if (buildCounterLoadBalancerInfo < 3) {
    o.backendType = 'foo';
    o.backendUri = 'foo';
    o.backends = buildUnnamed4454();
    o.healthCheckUri = 'foo';
    o.loadBalancerType = 'foo';
  }
  buildCounterLoadBalancerInfo--;
  return o;
}

void checkLoadBalancerInfo(api.LoadBalancerInfo o) {
  buildCounterLoadBalancerInfo++;
  if (buildCounterLoadBalancerInfo < 3) {
    unittest.expect(
      o.backendType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.backendUri!,
      unittest.equals('foo'),
    );
    checkUnnamed4454(o.backends!);
    unittest.expect(
      o.healthCheckUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.loadBalancerType!,
      unittest.equals('foo'),
    );
  }
  buildCounterLoadBalancerInfo--;
}

core.Map<core.String, core.String> buildUnnamed4455() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4455(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed4456() {
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

void checkUnnamed4456(core.Map<core.String, core.Object> o) {
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

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.displayName = 'foo';
    o.labels = buildUnnamed4455();
    o.locationId = 'foo';
    o.metadata = buildUnnamed4456();
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
    checkUnnamed4455(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed4456(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterNetworkInfo = 0;
api.NetworkInfo buildNetworkInfo() {
  var o = api.NetworkInfo();
  buildCounterNetworkInfo++;
  if (buildCounterNetworkInfo < 3) {
    o.displayName = 'foo';
    o.matchedIpRange = 'foo';
    o.uri = 'foo';
  }
  buildCounterNetworkInfo--;
  return o;
}

void checkNetworkInfo(api.NetworkInfo o) {
  buildCounterNetworkInfo++;
  if (buildCounterNetworkInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.matchedIpRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterNetworkInfo--;
}

core.Map<core.String, core.Object> buildUnnamed4457() {
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

void checkUnnamed4457(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed4458() {
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

void checkUnnamed4458(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed4457();
    o.name = 'foo';
    o.response = buildUnnamed4458();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed4457(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4458(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationMetadata = 0;
api.OperationMetadata buildOperationMetadata() {
  var o = api.OperationMetadata();
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    o.apiVersion = 'foo';
    o.cancelRequested = true;
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.statusDetail = 'foo';
    o.target = 'foo';
    o.verb = 'foo';
  }
  buildCounterOperationMetadata--;
  return o;
}

void checkOperationMetadata(api.OperationMetadata o) {
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    unittest.expect(
      o.apiVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cancelRequested!, unittest.isTrue);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statusDetail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verb!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationMetadata--;
}

core.List<api.AuditConfig> buildUnnamed4459() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed4459(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed4460() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed4460(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed4459();
    o.bindings = buildUnnamed4460();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed4459(o.auditConfigs!);
    checkUnnamed4460(o.bindings!);
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

core.List<api.Trace> buildUnnamed4461() {
  var o = <api.Trace>[];
  o.add(buildTrace());
  o.add(buildTrace());
  return o;
}

void checkUnnamed4461(core.List<api.Trace> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrace(o[0] as api.Trace);
  checkTrace(o[1] as api.Trace);
}

core.int buildCounterReachabilityDetails = 0;
api.ReachabilityDetails buildReachabilityDetails() {
  var o = api.ReachabilityDetails();
  buildCounterReachabilityDetails++;
  if (buildCounterReachabilityDetails < 3) {
    o.error = buildStatus();
    o.result = 'foo';
    o.traces = buildUnnamed4461();
    o.verifyTime = 'foo';
  }
  buildCounterReachabilityDetails--;
  return o;
}

void checkReachabilityDetails(api.ReachabilityDetails o) {
  buildCounterReachabilityDetails++;
  if (buildCounterReachabilityDetails < 3) {
    checkStatus(o.error! as api.Status);
    unittest.expect(
      o.result!,
      unittest.equals('foo'),
    );
    checkUnnamed4461(o.traces!);
    unittest.expect(
      o.verifyTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterReachabilityDetails--;
}

core.int buildCounterRerunConnectivityTestRequest = 0;
api.RerunConnectivityTestRequest buildRerunConnectivityTestRequest() {
  var o = api.RerunConnectivityTestRequest();
  buildCounterRerunConnectivityTestRequest++;
  if (buildCounterRerunConnectivityTestRequest < 3) {}
  buildCounterRerunConnectivityTestRequest--;
  return o;
}

void checkRerunConnectivityTestRequest(api.RerunConnectivityTestRequest o) {
  buildCounterRerunConnectivityTestRequest++;
  if (buildCounterRerunConnectivityTestRequest < 3) {}
  buildCounterRerunConnectivityTestRequest--;
}

core.List<core.String> buildUnnamed4462() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4462(core.List<core.String> o) {
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

core.int buildCounterRouteInfo = 0;
api.RouteInfo buildRouteInfo() {
  var o = api.RouteInfo();
  buildCounterRouteInfo++;
  if (buildCounterRouteInfo < 3) {
    o.destIpRange = 'foo';
    o.displayName = 'foo';
    o.instanceTags = buildUnnamed4462();
    o.networkUri = 'foo';
    o.nextHop = 'foo';
    o.nextHopType = 'foo';
    o.priority = 42;
    o.routeType = 'foo';
    o.uri = 'foo';
  }
  buildCounterRouteInfo--;
  return o;
}

void checkRouteInfo(api.RouteInfo o) {
  buildCounterRouteInfo++;
  if (buildCounterRouteInfo < 3) {
    unittest.expect(
      o.destIpRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4462(o.instanceTags!);
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextHop!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextHopType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.priority!,
      unittest.equals(42),
    );
    unittest.expect(
      o.routeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterRouteInfo--;
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

core.Map<core.String, core.Object> buildUnnamed4463() {
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

void checkUnnamed4463(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed4464() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed4463());
  o.add(buildUnnamed4463());
  return o;
}

void checkUnnamed4464(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed4463(o[0]);
  checkUnnamed4463(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed4464();
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
    checkUnnamed4464(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterStep = 0;
api.Step buildStep() {
  var o = api.Step();
  buildCounterStep++;
  if (buildCounterStep < 3) {
    o.abort = buildAbortInfo();
    o.causesDrop = true;
    o.cloudSqlInstance = buildCloudSQLInstanceInfo();
    o.deliver = buildDeliverInfo();
    o.description = 'foo';
    o.drop = buildDropInfo();
    o.endpoint = buildEndpointInfo();
    o.firewall = buildFirewallInfo();
    o.forward = buildForwardInfo();
    o.forwardingRule = buildForwardingRuleInfo();
    o.gkeMaster = buildGKEMasterInfo();
    o.instance = buildInstanceInfo();
    o.loadBalancer = buildLoadBalancerInfo();
    o.network = buildNetworkInfo();
    o.projectId = 'foo';
    o.route = buildRouteInfo();
    o.state = 'foo';
    o.vpnGateway = buildVpnGatewayInfo();
    o.vpnTunnel = buildVpnTunnelInfo();
  }
  buildCounterStep--;
  return o;
}

void checkStep(api.Step o) {
  buildCounterStep++;
  if (buildCounterStep < 3) {
    checkAbortInfo(o.abort! as api.AbortInfo);
    unittest.expect(o.causesDrop!, unittest.isTrue);
    checkCloudSQLInstanceInfo(o.cloudSqlInstance! as api.CloudSQLInstanceInfo);
    checkDeliverInfo(o.deliver! as api.DeliverInfo);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkDropInfo(o.drop! as api.DropInfo);
    checkEndpointInfo(o.endpoint! as api.EndpointInfo);
    checkFirewallInfo(o.firewall! as api.FirewallInfo);
    checkForwardInfo(o.forward! as api.ForwardInfo);
    checkForwardingRuleInfo(o.forwardingRule! as api.ForwardingRuleInfo);
    checkGKEMasterInfo(o.gkeMaster! as api.GKEMasterInfo);
    checkInstanceInfo(o.instance! as api.InstanceInfo);
    checkLoadBalancerInfo(o.loadBalancer! as api.LoadBalancerInfo);
    checkNetworkInfo(o.network! as api.NetworkInfo);
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    checkRouteInfo(o.route! as api.RouteInfo);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkVpnGatewayInfo(o.vpnGateway! as api.VpnGatewayInfo);
    checkVpnTunnelInfo(o.vpnTunnel! as api.VpnTunnelInfo);
  }
  buildCounterStep--;
}

core.List<core.String> buildUnnamed4465() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4465(core.List<core.String> o) {
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
    o.permissions = buildUnnamed4465();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed4465(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed4466() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4466(core.List<core.String> o) {
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
    o.permissions = buildUnnamed4466();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed4466(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.List<api.Step> buildUnnamed4467() {
  var o = <api.Step>[];
  o.add(buildStep());
  o.add(buildStep());
  return o;
}

void checkUnnamed4467(core.List<api.Step> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStep(o[0] as api.Step);
  checkStep(o[1] as api.Step);
}

core.int buildCounterTrace = 0;
api.Trace buildTrace() {
  var o = api.Trace();
  buildCounterTrace++;
  if (buildCounterTrace < 3) {
    o.endpointInfo = buildEndpointInfo();
    o.steps = buildUnnamed4467();
  }
  buildCounterTrace--;
  return o;
}

void checkTrace(api.Trace o) {
  buildCounterTrace++;
  if (buildCounterTrace < 3) {
    checkEndpointInfo(o.endpointInfo! as api.EndpointInfo);
    checkUnnamed4467(o.steps!);
  }
  buildCounterTrace--;
}

core.int buildCounterVpnGatewayInfo = 0;
api.VpnGatewayInfo buildVpnGatewayInfo() {
  var o = api.VpnGatewayInfo();
  buildCounterVpnGatewayInfo++;
  if (buildCounterVpnGatewayInfo < 3) {
    o.displayName = 'foo';
    o.ipAddress = 'foo';
    o.networkUri = 'foo';
    o.region = 'foo';
    o.uri = 'foo';
    o.vpnTunnelUri = 'foo';
  }
  buildCounterVpnGatewayInfo--;
  return o;
}

void checkVpnGatewayInfo(api.VpnGatewayInfo o) {
  buildCounterVpnGatewayInfo++;
  if (buildCounterVpnGatewayInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ipAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vpnTunnelUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterVpnGatewayInfo--;
}

core.int buildCounterVpnTunnelInfo = 0;
api.VpnTunnelInfo buildVpnTunnelInfo() {
  var o = api.VpnTunnelInfo();
  buildCounterVpnTunnelInfo++;
  if (buildCounterVpnTunnelInfo < 3) {
    o.displayName = 'foo';
    o.networkUri = 'foo';
    o.region = 'foo';
    o.remoteGateway = 'foo';
    o.remoteGatewayIp = 'foo';
    o.routingType = 'foo';
    o.sourceGateway = 'foo';
    o.sourceGatewayIp = 'foo';
    o.uri = 'foo';
  }
  buildCounterVpnTunnelInfo--;
  return o;
}

void checkVpnTunnelInfo(api.VpnTunnelInfo o) {
  buildCounterVpnTunnelInfo++;
  if (buildCounterVpnTunnelInfo < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.remoteGateway!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.remoteGatewayIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.routingType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceGateway!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceGatewayIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterVpnTunnelInfo--;
}

void main() {
  unittest.group('obj-schema-AbortInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAbortInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AbortInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAbortInfo(od as api.AbortInfo);
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

  unittest.group('obj-schema-CancelOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelOperationRequest(od as api.CancelOperationRequest);
    });
  });

  unittest.group('obj-schema-CloudSQLInstanceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudSQLInstanceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudSQLInstanceInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudSQLInstanceInfo(od as api.CloudSQLInstanceInfo);
    });
  });

  unittest.group('obj-schema-ConnectivityTest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConnectivityTest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConnectivityTest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConnectivityTest(od as api.ConnectivityTest);
    });
  });

  unittest.group('obj-schema-DeliverInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeliverInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeliverInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeliverInfo(od as api.DeliverInfo);
    });
  });

  unittest.group('obj-schema-DropInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDropInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DropInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDropInfo(od as api.DropInfo);
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

  unittest.group('obj-schema-Endpoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEndpoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Endpoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEndpoint(od as api.Endpoint);
    });
  });

  unittest.group('obj-schema-EndpointInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEndpointInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EndpointInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEndpointInfo(od as api.EndpointInfo);
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

  unittest.group('obj-schema-FirewallInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirewallInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirewallInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirewallInfo(od as api.FirewallInfo);
    });
  });

  unittest.group('obj-schema-ForwardInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildForwardInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ForwardInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkForwardInfo(od as api.ForwardInfo);
    });
  });

  unittest.group('obj-schema-ForwardingRuleInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildForwardingRuleInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ForwardingRuleInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkForwardingRuleInfo(od as api.ForwardingRuleInfo);
    });
  });

  unittest.group('obj-schema-GKEMasterInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGKEMasterInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GKEMasterInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGKEMasterInfo(od as api.GKEMasterInfo);
    });
  });

  unittest.group('obj-schema-InstanceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstanceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InstanceInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInstanceInfo(od as api.InstanceInfo);
    });
  });

  unittest.group('obj-schema-ListConnectivityTestsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConnectivityTestsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConnectivityTestsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConnectivityTestsResponse(
          od as api.ListConnectivityTestsResponse);
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

  unittest.group('obj-schema-ListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOperationsResponse(od as api.ListOperationsResponse);
    });
  });

  unittest.group('obj-schema-LoadBalancerBackend', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLoadBalancerBackend();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LoadBalancerBackend.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLoadBalancerBackend(od as api.LoadBalancerBackend);
    });
  });

  unittest.group('obj-schema-LoadBalancerInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLoadBalancerInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LoadBalancerInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLoadBalancerInfo(od as api.LoadBalancerInfo);
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

  unittest.group('obj-schema-NetworkInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkInfo(od as api.NetworkInfo);
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

  unittest.group('obj-schema-OperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationMetadata(od as api.OperationMetadata);
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

  unittest.group('obj-schema-ReachabilityDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReachabilityDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReachabilityDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReachabilityDetails(od as api.ReachabilityDetails);
    });
  });

  unittest.group('obj-schema-RerunConnectivityTestRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRerunConnectivityTestRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RerunConnectivityTestRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRerunConnectivityTestRequest(od as api.RerunConnectivityTestRequest);
    });
  });

  unittest.group('obj-schema-RouteInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRouteInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RouteInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRouteInfo(od as api.RouteInfo);
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

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-Step', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStep();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Step.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStep(od as api.Step);
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

  unittest.group('obj-schema-Trace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Trace.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTrace(od as api.Trace);
    });
  });

  unittest.group('obj-schema-VpnGatewayInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVpnGatewayInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VpnGatewayInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVpnGatewayInfo(od as api.VpnGatewayInfo);
    });
  });

  unittest.group('obj-schema-VpnTunnelInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVpnTunnelInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VpnTunnelInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVpnTunnelInfo(od as api.VpnTunnelInfo);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock).projects.locations;
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
      var res = api.NetworkManagementApi(mock).projects.locations;
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

  unittest.group('resource-ProjectsLocationsGlobalConnectivityTestsResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
      var arg_request = buildConnectivityTest();
      var arg_parent = 'foo';
      var arg_testId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConnectivityTest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConnectivityTest(obj as api.ConnectivityTest);

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
          queryMap["testId"]!.first,
          unittest.equals(arg_testId),
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
          testId: arg_testId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
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
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
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
        var resp = convert.json.encode(buildConnectivityTest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkConnectivityTest(response as api.ConnectivityTest);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
      var arg_resource = 'foo';
      var arg_options_requestedPolicyVersion = 42;
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
          core.int.parse(queryMap["options.requestedPolicyVersion"]!.first),
          unittest.equals(arg_options_requestedPolicyVersion),
        );
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
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListConnectivityTestsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListConnectivityTestsResponse(
          response as api.ListConnectivityTestsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
      var arg_request = buildConnectivityTest();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConnectivityTest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConnectivityTest(obj as api.ConnectivityTest);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--rerun', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
      var arg_request = buildRerunConnectivityTestRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RerunConnectivityTestRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRerunConnectivityTestRequest(
            obj as api.RerunConnectivityTestRequest);

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
          await res.rerun(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
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
      var res = api.NetworkManagementApi(mock)
          .projects
          .locations
          .global
          .connectivityTests;
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

  unittest.group('resource-ProjectsLocationsGlobalOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res =
          api.NetworkManagementApi(mock).projects.locations.global.operations;
      var arg_request = buildCancelOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelOperationRequest(obj as api.CancelOperationRequest);

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
      var res =
          api.NetworkManagementApi(mock).projects.locations.global.operations;
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
          api.NetworkManagementApi(mock).projects.locations.global.operations;
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
      var res =
          api.NetworkManagementApi(mock).projects.locations.global.operations;
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
