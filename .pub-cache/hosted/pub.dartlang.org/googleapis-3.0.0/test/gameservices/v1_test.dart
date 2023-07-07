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

import 'package:googleapis/gameservices/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.AuditLogConfig> buildUnnamed110() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed110(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.List<core.String> buildUnnamed111() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed111(core.List<core.String> o) {
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

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed110();
    o.exemptedMembers = buildUnnamed111();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed110(o.auditLogConfigs!);
    checkUnnamed111(o.exemptedMembers!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed112() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed112(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed112();
    o.ignoreChildExemptions = true;
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed112(o.exemptedMembers!);
    unittest.expect(o.ignoreChildExemptions!, unittest.isTrue);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.int buildCounterAuthorizationLoggingOptions = 0;
api.AuthorizationLoggingOptions buildAuthorizationLoggingOptions() {
  var o = api.AuthorizationLoggingOptions();
  buildCounterAuthorizationLoggingOptions++;
  if (buildCounterAuthorizationLoggingOptions < 3) {
    o.permissionType = 'foo';
  }
  buildCounterAuthorizationLoggingOptions--;
  return o;
}

void checkAuthorizationLoggingOptions(api.AuthorizationLoggingOptions o) {
  buildCounterAuthorizationLoggingOptions++;
  if (buildCounterAuthorizationLoggingOptions < 3) {
    unittest.expect(
      o.permissionType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuthorizationLoggingOptions--;
}

core.List<core.String> buildUnnamed113() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed113(core.List<core.String> o) {
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
    o.bindingId = 'foo';
    o.condition = buildExpr();
    o.members = buildUnnamed113();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    unittest.expect(
      o.bindingId!,
      unittest.equals('foo'),
    );
    checkExpr(o.condition! as api.Expr);
    checkUnnamed113(o.members!);
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

core.int buildCounterCloudAuditOptions = 0;
api.CloudAuditOptions buildCloudAuditOptions() {
  var o = api.CloudAuditOptions();
  buildCounterCloudAuditOptions++;
  if (buildCounterCloudAuditOptions < 3) {
    o.authorizationLoggingOptions = buildAuthorizationLoggingOptions();
    o.logName = 'foo';
  }
  buildCounterCloudAuditOptions--;
  return o;
}

void checkCloudAuditOptions(api.CloudAuditOptions o) {
  buildCounterCloudAuditOptions++;
  if (buildCounterCloudAuditOptions < 3) {
    checkAuthorizationLoggingOptions(
        o.authorizationLoggingOptions! as api.AuthorizationLoggingOptions);
    unittest.expect(
      o.logName!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudAuditOptions--;
}

core.List<core.String> buildUnnamed114() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed114(core.List<core.String> o) {
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

core.int buildCounterCondition = 0;
api.Condition buildCondition() {
  var o = api.Condition();
  buildCounterCondition++;
  if (buildCounterCondition < 3) {
    o.iam = 'foo';
    o.op = 'foo';
    o.svc = 'foo';
    o.sys = 'foo';
    o.values = buildUnnamed114();
  }
  buildCounterCondition--;
  return o;
}

void checkCondition(api.Condition o) {
  buildCounterCondition++;
  if (buildCounterCondition < 3) {
    unittest.expect(
      o.iam!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.op!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.svc!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sys!,
      unittest.equals('foo'),
    );
    checkUnnamed114(o.values!);
  }
  buildCounterCondition--;
}

core.List<api.CustomField> buildUnnamed115() {
  var o = <api.CustomField>[];
  o.add(buildCustomField());
  o.add(buildCustomField());
  return o;
}

void checkUnnamed115(core.List<api.CustomField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomField(o[0] as api.CustomField);
  checkCustomField(o[1] as api.CustomField);
}

core.int buildCounterCounterOptions = 0;
api.CounterOptions buildCounterOptions() {
  var o = api.CounterOptions();
  buildCounterCounterOptions++;
  if (buildCounterCounterOptions < 3) {
    o.customFields = buildUnnamed115();
    o.field = 'foo';
    o.metric = 'foo';
  }
  buildCounterCounterOptions--;
  return o;
}

void checkCounterOptions(api.CounterOptions o) {
  buildCounterCounterOptions++;
  if (buildCounterCounterOptions < 3) {
    checkUnnamed115(o.customFields!);
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metric!,
      unittest.equals('foo'),
    );
  }
  buildCounterCounterOptions--;
}

core.int buildCounterCustomField = 0;
api.CustomField buildCustomField() {
  var o = api.CustomField();
  buildCounterCustomField++;
  if (buildCounterCustomField < 3) {
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterCustomField--;
  return o;
}

void checkCustomField(api.CustomField o) {
  buildCounterCustomField++;
  if (buildCounterCustomField < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomField--;
}

core.int buildCounterDataAccessOptions = 0;
api.DataAccessOptions buildDataAccessOptions() {
  var o = api.DataAccessOptions();
  buildCounterDataAccessOptions++;
  if (buildCounterDataAccessOptions < 3) {
    o.logMode = 'foo';
  }
  buildCounterDataAccessOptions--;
  return o;
}

void checkDataAccessOptions(api.DataAccessOptions o) {
  buildCounterDataAccessOptions++;
  if (buildCounterDataAccessOptions < 3) {
    unittest.expect(
      o.logMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataAccessOptions--;
}

core.List<api.DeployedFleetDetails> buildUnnamed116() {
  var o = <api.DeployedFleetDetails>[];
  o.add(buildDeployedFleetDetails());
  o.add(buildDeployedFleetDetails());
  return o;
}

void checkUnnamed116(core.List<api.DeployedFleetDetails> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeployedFleetDetails(o[0] as api.DeployedFleetDetails);
  checkDeployedFleetDetails(o[1] as api.DeployedFleetDetails);
}

core.int buildCounterDeployedClusterState = 0;
api.DeployedClusterState buildDeployedClusterState() {
  var o = api.DeployedClusterState();
  buildCounterDeployedClusterState++;
  if (buildCounterDeployedClusterState < 3) {
    o.cluster = 'foo';
    o.fleetDetails = buildUnnamed116();
  }
  buildCounterDeployedClusterState--;
  return o;
}

void checkDeployedClusterState(api.DeployedClusterState o) {
  buildCounterDeployedClusterState++;
  if (buildCounterDeployedClusterState < 3) {
    unittest.expect(
      o.cluster!,
      unittest.equals('foo'),
    );
    checkUnnamed116(o.fleetDetails!);
  }
  buildCounterDeployedClusterState--;
}

core.int buildCounterDeployedFleet = 0;
api.DeployedFleet buildDeployedFleet() {
  var o = api.DeployedFleet();
  buildCounterDeployedFleet++;
  if (buildCounterDeployedFleet < 3) {
    o.fleet = 'foo';
    o.fleetSpec = 'foo';
    o.specSource = buildSpecSource();
    o.status = buildDeployedFleetStatus();
  }
  buildCounterDeployedFleet--;
  return o;
}

void checkDeployedFleet(api.DeployedFleet o) {
  buildCounterDeployedFleet++;
  if (buildCounterDeployedFleet < 3) {
    unittest.expect(
      o.fleet!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fleetSpec!,
      unittest.equals('foo'),
    );
    checkSpecSource(o.specSource! as api.SpecSource);
    checkDeployedFleetStatus(o.status! as api.DeployedFleetStatus);
  }
  buildCounterDeployedFleet--;
}

core.int buildCounterDeployedFleetAutoscaler = 0;
api.DeployedFleetAutoscaler buildDeployedFleetAutoscaler() {
  var o = api.DeployedFleetAutoscaler();
  buildCounterDeployedFleetAutoscaler++;
  if (buildCounterDeployedFleetAutoscaler < 3) {
    o.autoscaler = 'foo';
    o.fleetAutoscalerSpec = 'foo';
    o.specSource = buildSpecSource();
  }
  buildCounterDeployedFleetAutoscaler--;
  return o;
}

void checkDeployedFleetAutoscaler(api.DeployedFleetAutoscaler o) {
  buildCounterDeployedFleetAutoscaler++;
  if (buildCounterDeployedFleetAutoscaler < 3) {
    unittest.expect(
      o.autoscaler!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fleetAutoscalerSpec!,
      unittest.equals('foo'),
    );
    checkSpecSource(o.specSource! as api.SpecSource);
  }
  buildCounterDeployedFleetAutoscaler--;
}

core.int buildCounterDeployedFleetDetails = 0;
api.DeployedFleetDetails buildDeployedFleetDetails() {
  var o = api.DeployedFleetDetails();
  buildCounterDeployedFleetDetails++;
  if (buildCounterDeployedFleetDetails < 3) {
    o.deployedAutoscaler = buildDeployedFleetAutoscaler();
    o.deployedFleet = buildDeployedFleet();
  }
  buildCounterDeployedFleetDetails--;
  return o;
}

void checkDeployedFleetDetails(api.DeployedFleetDetails o) {
  buildCounterDeployedFleetDetails++;
  if (buildCounterDeployedFleetDetails < 3) {
    checkDeployedFleetAutoscaler(
        o.deployedAutoscaler! as api.DeployedFleetAutoscaler);
    checkDeployedFleet(o.deployedFleet! as api.DeployedFleet);
  }
  buildCounterDeployedFleetDetails--;
}

core.int buildCounterDeployedFleetStatus = 0;
api.DeployedFleetStatus buildDeployedFleetStatus() {
  var o = api.DeployedFleetStatus();
  buildCounterDeployedFleetStatus++;
  if (buildCounterDeployedFleetStatus < 3) {
    o.allocatedReplicas = 'foo';
    o.readyReplicas = 'foo';
    o.replicas = 'foo';
    o.reservedReplicas = 'foo';
  }
  buildCounterDeployedFleetStatus--;
  return o;
}

void checkDeployedFleetStatus(api.DeployedFleetStatus o) {
  buildCounterDeployedFleetStatus++;
  if (buildCounterDeployedFleetStatus < 3) {
    unittest.expect(
      o.allocatedReplicas!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readyReplicas!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.replicas!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reservedReplicas!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeployedFleetStatus--;
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

core.int buildCounterFetchDeploymentStateRequest = 0;
api.FetchDeploymentStateRequest buildFetchDeploymentStateRequest() {
  var o = api.FetchDeploymentStateRequest();
  buildCounterFetchDeploymentStateRequest++;
  if (buildCounterFetchDeploymentStateRequest < 3) {}
  buildCounterFetchDeploymentStateRequest--;
  return o;
}

void checkFetchDeploymentStateRequest(api.FetchDeploymentStateRequest o) {
  buildCounterFetchDeploymentStateRequest++;
  if (buildCounterFetchDeploymentStateRequest < 3) {}
  buildCounterFetchDeploymentStateRequest--;
}

core.List<api.DeployedClusterState> buildUnnamed117() {
  var o = <api.DeployedClusterState>[];
  o.add(buildDeployedClusterState());
  o.add(buildDeployedClusterState());
  return o;
}

void checkUnnamed117(core.List<api.DeployedClusterState> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeployedClusterState(o[0] as api.DeployedClusterState);
  checkDeployedClusterState(o[1] as api.DeployedClusterState);
}

core.List<core.String> buildUnnamed118() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed118(core.List<core.String> o) {
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

core.int buildCounterFetchDeploymentStateResponse = 0;
api.FetchDeploymentStateResponse buildFetchDeploymentStateResponse() {
  var o = api.FetchDeploymentStateResponse();
  buildCounterFetchDeploymentStateResponse++;
  if (buildCounterFetchDeploymentStateResponse < 3) {
    o.clusterState = buildUnnamed117();
    o.unavailable = buildUnnamed118();
  }
  buildCounterFetchDeploymentStateResponse--;
  return o;
}

void checkFetchDeploymentStateResponse(api.FetchDeploymentStateResponse o) {
  buildCounterFetchDeploymentStateResponse++;
  if (buildCounterFetchDeploymentStateResponse < 3) {
    checkUnnamed117(o.clusterState!);
    checkUnnamed118(o.unavailable!);
  }
  buildCounterFetchDeploymentStateResponse--;
}

core.int buildCounterFleetConfig = 0;
api.FleetConfig buildFleetConfig() {
  var o = api.FleetConfig();
  buildCounterFleetConfig++;
  if (buildCounterFleetConfig < 3) {
    o.fleetSpec = 'foo';
    o.name = 'foo';
  }
  buildCounterFleetConfig--;
  return o;
}

void checkFleetConfig(api.FleetConfig o) {
  buildCounterFleetConfig++;
  if (buildCounterFleetConfig < 3) {
    unittest.expect(
      o.fleetSpec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterFleetConfig--;
}

core.Map<core.String, core.String> buildUnnamed119() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed119(core.Map<core.String, core.String> o) {
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

core.int buildCounterGameServerCluster = 0;
api.GameServerCluster buildGameServerCluster() {
  var o = api.GameServerCluster();
  buildCounterGameServerCluster++;
  if (buildCounterGameServerCluster < 3) {
    o.connectionInfo = buildGameServerClusterConnectionInfo();
    o.createTime = 'foo';
    o.description = 'foo';
    o.etag = 'foo';
    o.labels = buildUnnamed119();
    o.name = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGameServerCluster--;
  return o;
}

void checkGameServerCluster(api.GameServerCluster o) {
  buildCounterGameServerCluster++;
  if (buildCounterGameServerCluster < 3) {
    checkGameServerClusterConnectionInfo(
        o.connectionInfo! as api.GameServerClusterConnectionInfo);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed119(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGameServerCluster--;
}

core.int buildCounterGameServerClusterConnectionInfo = 0;
api.GameServerClusterConnectionInfo buildGameServerClusterConnectionInfo() {
  var o = api.GameServerClusterConnectionInfo();
  buildCounterGameServerClusterConnectionInfo++;
  if (buildCounterGameServerClusterConnectionInfo < 3) {
    o.gkeClusterReference = buildGkeClusterReference();
    o.namespace = 'foo';
  }
  buildCounterGameServerClusterConnectionInfo--;
  return o;
}

void checkGameServerClusterConnectionInfo(
    api.GameServerClusterConnectionInfo o) {
  buildCounterGameServerClusterConnectionInfo++;
  if (buildCounterGameServerClusterConnectionInfo < 3) {
    checkGkeClusterReference(o.gkeClusterReference! as api.GkeClusterReference);
    unittest.expect(
      o.namespace!,
      unittest.equals('foo'),
    );
  }
  buildCounterGameServerClusterConnectionInfo--;
}

core.List<api.FleetConfig> buildUnnamed120() {
  var o = <api.FleetConfig>[];
  o.add(buildFleetConfig());
  o.add(buildFleetConfig());
  return o;
}

void checkUnnamed120(core.List<api.FleetConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFleetConfig(o[0] as api.FleetConfig);
  checkFleetConfig(o[1] as api.FleetConfig);
}

core.Map<core.String, core.String> buildUnnamed121() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed121(core.Map<core.String, core.String> o) {
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

core.List<api.ScalingConfig> buildUnnamed122() {
  var o = <api.ScalingConfig>[];
  o.add(buildScalingConfig());
  o.add(buildScalingConfig());
  return o;
}

void checkUnnamed122(core.List<api.ScalingConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScalingConfig(o[0] as api.ScalingConfig);
  checkScalingConfig(o[1] as api.ScalingConfig);
}

core.int buildCounterGameServerConfig = 0;
api.GameServerConfig buildGameServerConfig() {
  var o = api.GameServerConfig();
  buildCounterGameServerConfig++;
  if (buildCounterGameServerConfig < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.fleetConfigs = buildUnnamed120();
    o.labels = buildUnnamed121();
    o.name = 'foo';
    o.scalingConfigs = buildUnnamed122();
    o.updateTime = 'foo';
  }
  buildCounterGameServerConfig--;
  return o;
}

void checkGameServerConfig(api.GameServerConfig o) {
  buildCounterGameServerConfig++;
  if (buildCounterGameServerConfig < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed120(o.fleetConfigs!);
    checkUnnamed121(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed122(o.scalingConfigs!);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGameServerConfig--;
}

core.int buildCounterGameServerConfigOverride = 0;
api.GameServerConfigOverride buildGameServerConfigOverride() {
  var o = api.GameServerConfigOverride();
  buildCounterGameServerConfigOverride++;
  if (buildCounterGameServerConfigOverride < 3) {
    o.configVersion = 'foo';
    o.realmsSelector = buildRealmSelector();
  }
  buildCounterGameServerConfigOverride--;
  return o;
}

void checkGameServerConfigOverride(api.GameServerConfigOverride o) {
  buildCounterGameServerConfigOverride++;
  if (buildCounterGameServerConfigOverride < 3) {
    unittest.expect(
      o.configVersion!,
      unittest.equals('foo'),
    );
    checkRealmSelector(o.realmsSelector! as api.RealmSelector);
  }
  buildCounterGameServerConfigOverride--;
}

core.Map<core.String, core.String> buildUnnamed123() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed123(core.Map<core.String, core.String> o) {
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

core.int buildCounterGameServerDeployment = 0;
api.GameServerDeployment buildGameServerDeployment() {
  var o = api.GameServerDeployment();
  buildCounterGameServerDeployment++;
  if (buildCounterGameServerDeployment < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.etag = 'foo';
    o.labels = buildUnnamed123();
    o.name = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGameServerDeployment--;
  return o;
}

void checkGameServerDeployment(api.GameServerDeployment o) {
  buildCounterGameServerDeployment++;
  if (buildCounterGameServerDeployment < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed123(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGameServerDeployment--;
}

core.List<api.GameServerConfigOverride> buildUnnamed124() {
  var o = <api.GameServerConfigOverride>[];
  o.add(buildGameServerConfigOverride());
  o.add(buildGameServerConfigOverride());
  return o;
}

void checkUnnamed124(core.List<api.GameServerConfigOverride> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGameServerConfigOverride(o[0] as api.GameServerConfigOverride);
  checkGameServerConfigOverride(o[1] as api.GameServerConfigOverride);
}

core.int buildCounterGameServerDeploymentRollout = 0;
api.GameServerDeploymentRollout buildGameServerDeploymentRollout() {
  var o = api.GameServerDeploymentRollout();
  buildCounterGameServerDeploymentRollout++;
  if (buildCounterGameServerDeploymentRollout < 3) {
    o.createTime = 'foo';
    o.defaultGameServerConfig = 'foo';
    o.etag = 'foo';
    o.gameServerConfigOverrides = buildUnnamed124();
    o.name = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGameServerDeploymentRollout--;
  return o;
}

void checkGameServerDeploymentRollout(api.GameServerDeploymentRollout o) {
  buildCounterGameServerDeploymentRollout++;
  if (buildCounterGameServerDeploymentRollout < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultGameServerConfig!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed124(o.gameServerConfigOverrides!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGameServerDeploymentRollout--;
}

core.int buildCounterGkeClusterReference = 0;
api.GkeClusterReference buildGkeClusterReference() {
  var o = api.GkeClusterReference();
  buildCounterGkeClusterReference++;
  if (buildCounterGkeClusterReference < 3) {
    o.cluster = 'foo';
  }
  buildCounterGkeClusterReference--;
  return o;
}

void checkGkeClusterReference(api.GkeClusterReference o) {
  buildCounterGkeClusterReference++;
  if (buildCounterGkeClusterReference < 3) {
    unittest.expect(
      o.cluster!,
      unittest.equals('foo'),
    );
  }
  buildCounterGkeClusterReference--;
}

core.Map<core.String, core.String> buildUnnamed125() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed125(core.Map<core.String, core.String> o) {
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

core.int buildCounterLabelSelector = 0;
api.LabelSelector buildLabelSelector() {
  var o = api.LabelSelector();
  buildCounterLabelSelector++;
  if (buildCounterLabelSelector < 3) {
    o.labels = buildUnnamed125();
  }
  buildCounterLabelSelector--;
  return o;
}

void checkLabelSelector(api.LabelSelector o) {
  buildCounterLabelSelector++;
  if (buildCounterLabelSelector < 3) {
    checkUnnamed125(o.labels!);
  }
  buildCounterLabelSelector--;
}

core.List<api.GameServerCluster> buildUnnamed126() {
  var o = <api.GameServerCluster>[];
  o.add(buildGameServerCluster());
  o.add(buildGameServerCluster());
  return o;
}

void checkUnnamed126(core.List<api.GameServerCluster> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGameServerCluster(o[0] as api.GameServerCluster);
  checkGameServerCluster(o[1] as api.GameServerCluster);
}

core.List<core.String> buildUnnamed127() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed127(core.List<core.String> o) {
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

core.int buildCounterListGameServerClustersResponse = 0;
api.ListGameServerClustersResponse buildListGameServerClustersResponse() {
  var o = api.ListGameServerClustersResponse();
  buildCounterListGameServerClustersResponse++;
  if (buildCounterListGameServerClustersResponse < 3) {
    o.gameServerClusters = buildUnnamed126();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed127();
  }
  buildCounterListGameServerClustersResponse--;
  return o;
}

void checkListGameServerClustersResponse(api.ListGameServerClustersResponse o) {
  buildCounterListGameServerClustersResponse++;
  if (buildCounterListGameServerClustersResponse < 3) {
    checkUnnamed126(o.gameServerClusters!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed127(o.unreachable!);
  }
  buildCounterListGameServerClustersResponse--;
}

core.List<api.GameServerConfig> buildUnnamed128() {
  var o = <api.GameServerConfig>[];
  o.add(buildGameServerConfig());
  o.add(buildGameServerConfig());
  return o;
}

void checkUnnamed128(core.List<api.GameServerConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGameServerConfig(o[0] as api.GameServerConfig);
  checkGameServerConfig(o[1] as api.GameServerConfig);
}

core.List<core.String> buildUnnamed129() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed129(core.List<core.String> o) {
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

core.int buildCounterListGameServerConfigsResponse = 0;
api.ListGameServerConfigsResponse buildListGameServerConfigsResponse() {
  var o = api.ListGameServerConfigsResponse();
  buildCounterListGameServerConfigsResponse++;
  if (buildCounterListGameServerConfigsResponse < 3) {
    o.gameServerConfigs = buildUnnamed128();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed129();
  }
  buildCounterListGameServerConfigsResponse--;
  return o;
}

void checkListGameServerConfigsResponse(api.ListGameServerConfigsResponse o) {
  buildCounterListGameServerConfigsResponse++;
  if (buildCounterListGameServerConfigsResponse < 3) {
    checkUnnamed128(o.gameServerConfigs!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed129(o.unreachable!);
  }
  buildCounterListGameServerConfigsResponse--;
}

core.List<api.GameServerDeployment> buildUnnamed130() {
  var o = <api.GameServerDeployment>[];
  o.add(buildGameServerDeployment());
  o.add(buildGameServerDeployment());
  return o;
}

void checkUnnamed130(core.List<api.GameServerDeployment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGameServerDeployment(o[0] as api.GameServerDeployment);
  checkGameServerDeployment(o[1] as api.GameServerDeployment);
}

core.List<core.String> buildUnnamed131() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed131(core.List<core.String> o) {
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

core.int buildCounterListGameServerDeploymentsResponse = 0;
api.ListGameServerDeploymentsResponse buildListGameServerDeploymentsResponse() {
  var o = api.ListGameServerDeploymentsResponse();
  buildCounterListGameServerDeploymentsResponse++;
  if (buildCounterListGameServerDeploymentsResponse < 3) {
    o.gameServerDeployments = buildUnnamed130();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed131();
  }
  buildCounterListGameServerDeploymentsResponse--;
  return o;
}

void checkListGameServerDeploymentsResponse(
    api.ListGameServerDeploymentsResponse o) {
  buildCounterListGameServerDeploymentsResponse++;
  if (buildCounterListGameServerDeploymentsResponse < 3) {
    checkUnnamed130(o.gameServerDeployments!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed131(o.unreachable!);
  }
  buildCounterListGameServerDeploymentsResponse--;
}

core.List<api.Location> buildUnnamed132() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed132(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed132();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed132(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Operation> buildUnnamed133() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed133(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed133();
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
    checkUnnamed133(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.Realm> buildUnnamed134() {
  var o = <api.Realm>[];
  o.add(buildRealm());
  o.add(buildRealm());
  return o;
}

void checkUnnamed134(core.List<api.Realm> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRealm(o[0] as api.Realm);
  checkRealm(o[1] as api.Realm);
}

core.List<core.String> buildUnnamed135() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed135(core.List<core.String> o) {
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

core.int buildCounterListRealmsResponse = 0;
api.ListRealmsResponse buildListRealmsResponse() {
  var o = api.ListRealmsResponse();
  buildCounterListRealmsResponse++;
  if (buildCounterListRealmsResponse < 3) {
    o.nextPageToken = 'foo';
    o.realms = buildUnnamed134();
    o.unreachable = buildUnnamed135();
  }
  buildCounterListRealmsResponse--;
  return o;
}

void checkListRealmsResponse(api.ListRealmsResponse o) {
  buildCounterListRealmsResponse++;
  if (buildCounterListRealmsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed134(o.realms!);
    checkUnnamed135(o.unreachable!);
  }
  buildCounterListRealmsResponse--;
}

core.Map<core.String, core.String> buildUnnamed136() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed136(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed137() {
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

void checkUnnamed137(core.Map<core.String, core.Object> o) {
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
    o.labels = buildUnnamed136();
    o.locationId = 'foo';
    o.metadata = buildUnnamed137();
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
    checkUnnamed136(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed137(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterLogConfig = 0;
api.LogConfig buildLogConfig() {
  var o = api.LogConfig();
  buildCounterLogConfig++;
  if (buildCounterLogConfig < 3) {
    o.cloudAudit = buildCloudAuditOptions();
    o.counter = buildCounterOptions();
    o.dataAccess = buildDataAccessOptions();
  }
  buildCounterLogConfig--;
  return o;
}

void checkLogConfig(api.LogConfig o) {
  buildCounterLogConfig++;
  if (buildCounterLogConfig < 3) {
    checkCloudAuditOptions(o.cloudAudit! as api.CloudAuditOptions);
    checkCounterOptions(o.counter! as api.CounterOptions);
    checkDataAccessOptions(o.dataAccess! as api.DataAccessOptions);
  }
  buildCounterLogConfig--;
}

core.Map<core.String, core.Object> buildUnnamed138() {
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

void checkUnnamed138(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed139() {
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

void checkUnnamed139(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed138();
    o.name = 'foo';
    o.response = buildUnnamed139();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed138(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed139(o.response!);
  }
  buildCounterOperation--;
}

core.Map<core.String, api.OperationStatus> buildUnnamed140() {
  var o = <core.String, api.OperationStatus>{};
  o['x'] = buildOperationStatus();
  o['y'] = buildOperationStatus();
  return o;
}

void checkUnnamed140(core.Map<core.String, api.OperationStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperationStatus(o['x']! as api.OperationStatus);
  checkOperationStatus(o['y']! as api.OperationStatus);
}

core.List<core.String> buildUnnamed141() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed141(core.List<core.String> o) {
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

core.int buildCounterOperationMetadata = 0;
api.OperationMetadata buildOperationMetadata() {
  var o = api.OperationMetadata();
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    o.apiVersion = 'foo';
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.operationStatus = buildUnnamed140();
    o.requestedCancellation = true;
    o.statusMessage = 'foo';
    o.target = 'foo';
    o.unreachable = buildUnnamed141();
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
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkUnnamed140(o.operationStatus!);
    unittest.expect(o.requestedCancellation!, unittest.isTrue);
    unittest.expect(
      o.statusMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    checkUnnamed141(o.unreachable!);
    unittest.expect(
      o.verb!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationMetadata--;
}

core.int buildCounterOperationStatus = 0;
api.OperationStatus buildOperationStatus() {
  var o = api.OperationStatus();
  buildCounterOperationStatus++;
  if (buildCounterOperationStatus < 3) {
    o.done = true;
    o.errorCode = 'foo';
    o.errorMessage = 'foo';
  }
  buildCounterOperationStatus--;
  return o;
}

void checkOperationStatus(api.OperationStatus o) {
  buildCounterOperationStatus++;
  if (buildCounterOperationStatus < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    unittest.expect(
      o.errorCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationStatus--;
}

core.List<api.AuditConfig> buildUnnamed142() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed142(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed143() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed143(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.List<api.Rule> buildUnnamed144() {
  var o = <api.Rule>[];
  o.add(buildRule());
  o.add(buildRule());
  return o;
}

void checkUnnamed144(core.List<api.Rule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRule(o[0] as api.Rule);
  checkRule(o[1] as api.Rule);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed142();
    o.bindings = buildUnnamed143();
    o.etag = 'foo';
    o.iamOwned = true;
    o.rules = buildUnnamed144();
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed142(o.auditConfigs!);
    checkUnnamed143(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(o.iamOwned!, unittest.isTrue);
    checkUnnamed144(o.rules!);
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterPolicy--;
}

core.int buildCounterPreviewCreateGameServerClusterResponse = 0;
api.PreviewCreateGameServerClusterResponse
    buildPreviewCreateGameServerClusterResponse() {
  var o = api.PreviewCreateGameServerClusterResponse();
  buildCounterPreviewCreateGameServerClusterResponse++;
  if (buildCounterPreviewCreateGameServerClusterResponse < 3) {
    o.etag = 'foo';
    o.targetState = buildTargetState();
  }
  buildCounterPreviewCreateGameServerClusterResponse--;
  return o;
}

void checkPreviewCreateGameServerClusterResponse(
    api.PreviewCreateGameServerClusterResponse o) {
  buildCounterPreviewCreateGameServerClusterResponse++;
  if (buildCounterPreviewCreateGameServerClusterResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkTargetState(o.targetState! as api.TargetState);
  }
  buildCounterPreviewCreateGameServerClusterResponse--;
}

core.int buildCounterPreviewDeleteGameServerClusterResponse = 0;
api.PreviewDeleteGameServerClusterResponse
    buildPreviewDeleteGameServerClusterResponse() {
  var o = api.PreviewDeleteGameServerClusterResponse();
  buildCounterPreviewDeleteGameServerClusterResponse++;
  if (buildCounterPreviewDeleteGameServerClusterResponse < 3) {
    o.etag = 'foo';
    o.targetState = buildTargetState();
  }
  buildCounterPreviewDeleteGameServerClusterResponse--;
  return o;
}

void checkPreviewDeleteGameServerClusterResponse(
    api.PreviewDeleteGameServerClusterResponse o) {
  buildCounterPreviewDeleteGameServerClusterResponse++;
  if (buildCounterPreviewDeleteGameServerClusterResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkTargetState(o.targetState! as api.TargetState);
  }
  buildCounterPreviewDeleteGameServerClusterResponse--;
}

core.List<core.String> buildUnnamed145() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed145(core.List<core.String> o) {
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

core.int buildCounterPreviewGameServerDeploymentRolloutResponse = 0;
api.PreviewGameServerDeploymentRolloutResponse
    buildPreviewGameServerDeploymentRolloutResponse() {
  var o = api.PreviewGameServerDeploymentRolloutResponse();
  buildCounterPreviewGameServerDeploymentRolloutResponse++;
  if (buildCounterPreviewGameServerDeploymentRolloutResponse < 3) {
    o.etag = 'foo';
    o.targetState = buildTargetState();
    o.unavailable = buildUnnamed145();
  }
  buildCounterPreviewGameServerDeploymentRolloutResponse--;
  return o;
}

void checkPreviewGameServerDeploymentRolloutResponse(
    api.PreviewGameServerDeploymentRolloutResponse o) {
  buildCounterPreviewGameServerDeploymentRolloutResponse++;
  if (buildCounterPreviewGameServerDeploymentRolloutResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkTargetState(o.targetState! as api.TargetState);
    checkUnnamed145(o.unavailable!);
  }
  buildCounterPreviewGameServerDeploymentRolloutResponse--;
}

core.int buildCounterPreviewRealmUpdateResponse = 0;
api.PreviewRealmUpdateResponse buildPreviewRealmUpdateResponse() {
  var o = api.PreviewRealmUpdateResponse();
  buildCounterPreviewRealmUpdateResponse++;
  if (buildCounterPreviewRealmUpdateResponse < 3) {
    o.etag = 'foo';
    o.targetState = buildTargetState();
  }
  buildCounterPreviewRealmUpdateResponse--;
  return o;
}

void checkPreviewRealmUpdateResponse(api.PreviewRealmUpdateResponse o) {
  buildCounterPreviewRealmUpdateResponse++;
  if (buildCounterPreviewRealmUpdateResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkTargetState(o.targetState! as api.TargetState);
  }
  buildCounterPreviewRealmUpdateResponse--;
}

core.int buildCounterPreviewUpdateGameServerClusterResponse = 0;
api.PreviewUpdateGameServerClusterResponse
    buildPreviewUpdateGameServerClusterResponse() {
  var o = api.PreviewUpdateGameServerClusterResponse();
  buildCounterPreviewUpdateGameServerClusterResponse++;
  if (buildCounterPreviewUpdateGameServerClusterResponse < 3) {
    o.etag = 'foo';
    o.targetState = buildTargetState();
  }
  buildCounterPreviewUpdateGameServerClusterResponse--;
  return o;
}

void checkPreviewUpdateGameServerClusterResponse(
    api.PreviewUpdateGameServerClusterResponse o) {
  buildCounterPreviewUpdateGameServerClusterResponse++;
  if (buildCounterPreviewUpdateGameServerClusterResponse < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkTargetState(o.targetState! as api.TargetState);
  }
  buildCounterPreviewUpdateGameServerClusterResponse--;
}

core.Map<core.String, core.String> buildUnnamed146() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed146(core.Map<core.String, core.String> o) {
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

core.int buildCounterRealm = 0;
api.Realm buildRealm() {
  var o = api.Realm();
  buildCounterRealm++;
  if (buildCounterRealm < 3) {
    o.createTime = 'foo';
    o.description = 'foo';
    o.etag = 'foo';
    o.labels = buildUnnamed146();
    o.name = 'foo';
    o.timeZone = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterRealm--;
  return o;
}

void checkRealm(api.Realm o) {
  buildCounterRealm++;
  if (buildCounterRealm < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed146(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterRealm--;
}

core.List<core.String> buildUnnamed147() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed147(core.List<core.String> o) {
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

core.int buildCounterRealmSelector = 0;
api.RealmSelector buildRealmSelector() {
  var o = api.RealmSelector();
  buildCounterRealmSelector++;
  if (buildCounterRealmSelector < 3) {
    o.realms = buildUnnamed147();
  }
  buildCounterRealmSelector--;
  return o;
}

void checkRealmSelector(api.RealmSelector o) {
  buildCounterRealmSelector++;
  if (buildCounterRealmSelector < 3) {
    checkUnnamed147(o.realms!);
  }
  buildCounterRealmSelector--;
}

core.List<api.Condition> buildUnnamed148() {
  var o = <api.Condition>[];
  o.add(buildCondition());
  o.add(buildCondition());
  return o;
}

void checkUnnamed148(core.List<api.Condition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCondition(o[0] as api.Condition);
  checkCondition(o[1] as api.Condition);
}

core.List<core.String> buildUnnamed149() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed149(core.List<core.String> o) {
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

core.List<api.LogConfig> buildUnnamed150() {
  var o = <api.LogConfig>[];
  o.add(buildLogConfig());
  o.add(buildLogConfig());
  return o;
}

void checkUnnamed150(core.List<api.LogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLogConfig(o[0] as api.LogConfig);
  checkLogConfig(o[1] as api.LogConfig);
}

core.List<core.String> buildUnnamed151() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed151(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed152() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed152(core.List<core.String> o) {
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

core.int buildCounterRule = 0;
api.Rule buildRule() {
  var o = api.Rule();
  buildCounterRule++;
  if (buildCounterRule < 3) {
    o.action = 'foo';
    o.conditions = buildUnnamed148();
    o.description = 'foo';
    o.in_ = buildUnnamed149();
    o.logConfig = buildUnnamed150();
    o.notIn = buildUnnamed151();
    o.permissions = buildUnnamed152();
  }
  buildCounterRule--;
  return o;
}

void checkRule(api.Rule o) {
  buildCounterRule++;
  if (buildCounterRule < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    checkUnnamed148(o.conditions!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed149(o.in_!);
    checkUnnamed150(o.logConfig!);
    checkUnnamed151(o.notIn!);
    checkUnnamed152(o.permissions!);
  }
  buildCounterRule--;
}

core.List<api.Schedule> buildUnnamed153() {
  var o = <api.Schedule>[];
  o.add(buildSchedule());
  o.add(buildSchedule());
  return o;
}

void checkUnnamed153(core.List<api.Schedule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSchedule(o[0] as api.Schedule);
  checkSchedule(o[1] as api.Schedule);
}

core.List<api.LabelSelector> buildUnnamed154() {
  var o = <api.LabelSelector>[];
  o.add(buildLabelSelector());
  o.add(buildLabelSelector());
  return o;
}

void checkUnnamed154(core.List<api.LabelSelector> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLabelSelector(o[0] as api.LabelSelector);
  checkLabelSelector(o[1] as api.LabelSelector);
}

core.int buildCounterScalingConfig = 0;
api.ScalingConfig buildScalingConfig() {
  var o = api.ScalingConfig();
  buildCounterScalingConfig++;
  if (buildCounterScalingConfig < 3) {
    o.fleetAutoscalerSpec = 'foo';
    o.name = 'foo';
    o.schedules = buildUnnamed153();
    o.selectors = buildUnnamed154();
  }
  buildCounterScalingConfig--;
  return o;
}

void checkScalingConfig(api.ScalingConfig o) {
  buildCounterScalingConfig++;
  if (buildCounterScalingConfig < 3) {
    unittest.expect(
      o.fleetAutoscalerSpec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed153(o.schedules!);
    checkUnnamed154(o.selectors!);
  }
  buildCounterScalingConfig--;
}

core.int buildCounterSchedule = 0;
api.Schedule buildSchedule() {
  var o = api.Schedule();
  buildCounterSchedule++;
  if (buildCounterSchedule < 3) {
    o.cronJobDuration = 'foo';
    o.cronSpec = 'foo';
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterSchedule--;
  return o;
}

void checkSchedule(api.Schedule o) {
  buildCounterSchedule++;
  if (buildCounterSchedule < 3) {
    unittest.expect(
      o.cronJobDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cronSpec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchedule--;
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

core.int buildCounterSpecSource = 0;
api.SpecSource buildSpecSource() {
  var o = api.SpecSource();
  buildCounterSpecSource++;
  if (buildCounterSpecSource < 3) {
    o.gameServerConfigName = 'foo';
    o.name = 'foo';
  }
  buildCounterSpecSource--;
  return o;
}

void checkSpecSource(api.SpecSource o) {
  buildCounterSpecSource++;
  if (buildCounterSpecSource < 3) {
    unittest.expect(
      o.gameServerConfigName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpecSource--;
}

core.Map<core.String, core.Object> buildUnnamed155() {
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

void checkUnnamed155(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed156() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed155());
  o.add(buildUnnamed155());
  return o;
}

void checkUnnamed156(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed155(o[0]);
  checkUnnamed155(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed156();
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
    checkUnnamed156(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<api.TargetFleetDetails> buildUnnamed157() {
  var o = <api.TargetFleetDetails>[];
  o.add(buildTargetFleetDetails());
  o.add(buildTargetFleetDetails());
  return o;
}

void checkUnnamed157(core.List<api.TargetFleetDetails> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetFleetDetails(o[0] as api.TargetFleetDetails);
  checkTargetFleetDetails(o[1] as api.TargetFleetDetails);
}

core.int buildCounterTargetDetails = 0;
api.TargetDetails buildTargetDetails() {
  var o = api.TargetDetails();
  buildCounterTargetDetails++;
  if (buildCounterTargetDetails < 3) {
    o.fleetDetails = buildUnnamed157();
    o.gameServerClusterName = 'foo';
    o.gameServerDeploymentName = 'foo';
  }
  buildCounterTargetDetails--;
  return o;
}

void checkTargetDetails(api.TargetDetails o) {
  buildCounterTargetDetails++;
  if (buildCounterTargetDetails < 3) {
    checkUnnamed157(o.fleetDetails!);
    unittest.expect(
      o.gameServerClusterName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gameServerDeploymentName!,
      unittest.equals('foo'),
    );
  }
  buildCounterTargetDetails--;
}

core.int buildCounterTargetFleet = 0;
api.TargetFleet buildTargetFleet() {
  var o = api.TargetFleet();
  buildCounterTargetFleet++;
  if (buildCounterTargetFleet < 3) {
    o.name = 'foo';
    o.specSource = buildSpecSource();
  }
  buildCounterTargetFleet--;
  return o;
}

void checkTargetFleet(api.TargetFleet o) {
  buildCounterTargetFleet++;
  if (buildCounterTargetFleet < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSpecSource(o.specSource! as api.SpecSource);
  }
  buildCounterTargetFleet--;
}

core.int buildCounterTargetFleetAutoscaler = 0;
api.TargetFleetAutoscaler buildTargetFleetAutoscaler() {
  var o = api.TargetFleetAutoscaler();
  buildCounterTargetFleetAutoscaler++;
  if (buildCounterTargetFleetAutoscaler < 3) {
    o.name = 'foo';
    o.specSource = buildSpecSource();
  }
  buildCounterTargetFleetAutoscaler--;
  return o;
}

void checkTargetFleetAutoscaler(api.TargetFleetAutoscaler o) {
  buildCounterTargetFleetAutoscaler++;
  if (buildCounterTargetFleetAutoscaler < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSpecSource(o.specSource! as api.SpecSource);
  }
  buildCounterTargetFleetAutoscaler--;
}

core.int buildCounterTargetFleetDetails = 0;
api.TargetFleetDetails buildTargetFleetDetails() {
  var o = api.TargetFleetDetails();
  buildCounterTargetFleetDetails++;
  if (buildCounterTargetFleetDetails < 3) {
    o.autoscaler = buildTargetFleetAutoscaler();
    o.fleet = buildTargetFleet();
  }
  buildCounterTargetFleetDetails--;
  return o;
}

void checkTargetFleetDetails(api.TargetFleetDetails o) {
  buildCounterTargetFleetDetails++;
  if (buildCounterTargetFleetDetails < 3) {
    checkTargetFleetAutoscaler(o.autoscaler! as api.TargetFleetAutoscaler);
    checkTargetFleet(o.fleet! as api.TargetFleet);
  }
  buildCounterTargetFleetDetails--;
}

core.List<api.TargetDetails> buildUnnamed158() {
  var o = <api.TargetDetails>[];
  o.add(buildTargetDetails());
  o.add(buildTargetDetails());
  return o;
}

void checkUnnamed158(core.List<api.TargetDetails> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetDetails(o[0] as api.TargetDetails);
  checkTargetDetails(o[1] as api.TargetDetails);
}

core.int buildCounterTargetState = 0;
api.TargetState buildTargetState() {
  var o = api.TargetState();
  buildCounterTargetState++;
  if (buildCounterTargetState < 3) {
    o.details = buildUnnamed158();
  }
  buildCounterTargetState--;
  return o;
}

void checkTargetState(api.TargetState o) {
  buildCounterTargetState++;
  if (buildCounterTargetState < 3) {
    checkUnnamed158(o.details!);
  }
  buildCounterTargetState--;
}

core.List<core.String> buildUnnamed159() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed159(core.List<core.String> o) {
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
    o.permissions = buildUnnamed159();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed159(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed160() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed160(core.List<core.String> o) {
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
    o.permissions = buildUnnamed160();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed160(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

void main() {
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

  unittest.group('obj-schema-AuthorizationLoggingOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthorizationLoggingOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuthorizationLoggingOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthorizationLoggingOptions(od as api.AuthorizationLoggingOptions);
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

  unittest.group('obj-schema-CloudAuditOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudAuditOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudAuditOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudAuditOptions(od as api.CloudAuditOptions);
    });
  });

  unittest.group('obj-schema-Condition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCondition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Condition.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCondition(od as api.Condition);
    });
  });

  unittest.group('obj-schema-CounterOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCounterOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CounterOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCounterOptions(od as api.CounterOptions);
    });
  });

  unittest.group('obj-schema-CustomField', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomField.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomField(od as api.CustomField);
    });
  });

  unittest.group('obj-schema-DataAccessOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataAccessOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataAccessOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataAccessOptions(od as api.DataAccessOptions);
    });
  });

  unittest.group('obj-schema-DeployedClusterState', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployedClusterState();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeployedClusterState.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeployedClusterState(od as api.DeployedClusterState);
    });
  });

  unittest.group('obj-schema-DeployedFleet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployedFleet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeployedFleet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeployedFleet(od as api.DeployedFleet);
    });
  });

  unittest.group('obj-schema-DeployedFleetAutoscaler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployedFleetAutoscaler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeployedFleetAutoscaler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeployedFleetAutoscaler(od as api.DeployedFleetAutoscaler);
    });
  });

  unittest.group('obj-schema-DeployedFleetDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployedFleetDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeployedFleetDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeployedFleetDetails(od as api.DeployedFleetDetails);
    });
  });

  unittest.group('obj-schema-DeployedFleetStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployedFleetStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeployedFleetStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeployedFleetStatus(od as api.DeployedFleetStatus);
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

  unittest.group('obj-schema-FetchDeploymentStateRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFetchDeploymentStateRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FetchDeploymentStateRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFetchDeploymentStateRequest(od as api.FetchDeploymentStateRequest);
    });
  });

  unittest.group('obj-schema-FetchDeploymentStateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFetchDeploymentStateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FetchDeploymentStateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFetchDeploymentStateResponse(od as api.FetchDeploymentStateResponse);
    });
  });

  unittest.group('obj-schema-FleetConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFleetConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FleetConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFleetConfig(od as api.FleetConfig);
    });
  });

  unittest.group('obj-schema-GameServerCluster', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGameServerCluster();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GameServerCluster.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGameServerCluster(od as api.GameServerCluster);
    });
  });

  unittest.group('obj-schema-GameServerClusterConnectionInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGameServerClusterConnectionInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GameServerClusterConnectionInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGameServerClusterConnectionInfo(
          od as api.GameServerClusterConnectionInfo);
    });
  });

  unittest.group('obj-schema-GameServerConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGameServerConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GameServerConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGameServerConfig(od as api.GameServerConfig);
    });
  });

  unittest.group('obj-schema-GameServerConfigOverride', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGameServerConfigOverride();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GameServerConfigOverride.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGameServerConfigOverride(od as api.GameServerConfigOverride);
    });
  });

  unittest.group('obj-schema-GameServerDeployment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGameServerDeployment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GameServerDeployment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGameServerDeployment(od as api.GameServerDeployment);
    });
  });

  unittest.group('obj-schema-GameServerDeploymentRollout', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGameServerDeploymentRollout();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GameServerDeploymentRollout.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGameServerDeploymentRollout(od as api.GameServerDeploymentRollout);
    });
  });

  unittest.group('obj-schema-GkeClusterReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGkeClusterReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GkeClusterReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGkeClusterReference(od as api.GkeClusterReference);
    });
  });

  unittest.group('obj-schema-LabelSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLabelSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LabelSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLabelSelector(od as api.LabelSelector);
    });
  });

  unittest.group('obj-schema-ListGameServerClustersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGameServerClustersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGameServerClustersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGameServerClustersResponse(
          od as api.ListGameServerClustersResponse);
    });
  });

  unittest.group('obj-schema-ListGameServerConfigsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGameServerConfigsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGameServerConfigsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGameServerConfigsResponse(
          od as api.ListGameServerConfigsResponse);
    });
  });

  unittest.group('obj-schema-ListGameServerDeploymentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGameServerDeploymentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGameServerDeploymentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGameServerDeploymentsResponse(
          od as api.ListGameServerDeploymentsResponse);
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

  unittest.group('obj-schema-ListRealmsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListRealmsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListRealmsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListRealmsResponse(od as api.ListRealmsResponse);
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

  unittest.group('obj-schema-LogConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLogConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LogConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLogConfig(od as api.LogConfig);
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

  unittest.group('obj-schema-OperationStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationStatus(od as api.OperationStatus);
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

  unittest.group('obj-schema-PreviewCreateGameServerClusterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPreviewCreateGameServerClusterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PreviewCreateGameServerClusterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPreviewCreateGameServerClusterResponse(
          od as api.PreviewCreateGameServerClusterResponse);
    });
  });

  unittest.group('obj-schema-PreviewDeleteGameServerClusterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPreviewDeleteGameServerClusterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PreviewDeleteGameServerClusterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPreviewDeleteGameServerClusterResponse(
          od as api.PreviewDeleteGameServerClusterResponse);
    });
  });

  unittest.group('obj-schema-PreviewGameServerDeploymentRolloutResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPreviewGameServerDeploymentRolloutResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PreviewGameServerDeploymentRolloutResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPreviewGameServerDeploymentRolloutResponse(
          od as api.PreviewGameServerDeploymentRolloutResponse);
    });
  });

  unittest.group('obj-schema-PreviewRealmUpdateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPreviewRealmUpdateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PreviewRealmUpdateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPreviewRealmUpdateResponse(od as api.PreviewRealmUpdateResponse);
    });
  });

  unittest.group('obj-schema-PreviewUpdateGameServerClusterResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPreviewUpdateGameServerClusterResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PreviewUpdateGameServerClusterResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPreviewUpdateGameServerClusterResponse(
          od as api.PreviewUpdateGameServerClusterResponse);
    });
  });

  unittest.group('obj-schema-Realm', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRealm();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Realm.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRealm(od as api.Realm);
    });
  });

  unittest.group('obj-schema-RealmSelector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRealmSelector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RealmSelector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRealmSelector(od as api.RealmSelector);
    });
  });

  unittest.group('obj-schema-Rule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Rule.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRule(od as api.Rule);
    });
  });

  unittest.group('obj-schema-ScalingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScalingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScalingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScalingConfig(od as api.ScalingConfig);
    });
  });

  unittest.group('obj-schema-Schedule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchedule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Schedule.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSchedule(od as api.Schedule);
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

  unittest.group('obj-schema-SpecSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpecSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SpecSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSpecSource(od as api.SpecSource);
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

  unittest.group('obj-schema-TargetDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetDetails(od as api.TargetDetails);
    });
  });

  unittest.group('obj-schema-TargetFleet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetFleet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetFleet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetFleet(od as api.TargetFleet);
    });
  });

  unittest.group('obj-schema-TargetFleetAutoscaler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetFleetAutoscaler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetFleetAutoscaler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetFleetAutoscaler(od as api.TargetFleetAutoscaler);
    });
  });

  unittest.group('obj-schema-TargetFleetDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetFleetDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetFleetDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetFleetDetails(od as api.TargetFleetDetails);
    });
  });

  unittest.group('obj-schema-TargetState', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetState();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetState.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetState(od as api.TargetState);
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

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations;
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
      var res = api.GameServicesApi(mock).projects.locations;
      var arg_name = 'foo';
      var arg_filter = 'foo';
      var arg_includeUnrevealedLocations = true;
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
          queryMap["includeUnrevealedLocations"]!.first,
          unittest.equals("$arg_includeUnrevealedLocations"),
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
          includeUnrevealedLocations: arg_includeUnrevealedLocations,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationsResponse(response as api.ListLocationsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsGameServerDeploymentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
      var arg_request = buildGameServerDeployment();
      var arg_parent = 'foo';
      var arg_deploymentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerDeployment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerDeployment(obj as api.GameServerDeployment);

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
          queryMap["deploymentId"]!.first,
          unittest.equals(arg_deploymentId),
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
          deploymentId: arg_deploymentId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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

    unittest.test('method--fetchDeploymentState', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
      var arg_request = buildFetchDeploymentStateRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FetchDeploymentStateRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFetchDeploymentStateRequest(
            obj as api.FetchDeploymentStateRequest);

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
        var resp = convert.json.encode(buildFetchDeploymentStateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.fetchDeploymentState(arg_request, arg_name,
          $fields: arg_$fields);
      checkFetchDeploymentStateResponse(
          response as api.FetchDeploymentStateResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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
        var resp = convert.json.encode(buildGameServerDeployment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGameServerDeployment(response as api.GameServerDeployment);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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

    unittest.test('method--getRollout', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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
        var resp = convert.json.encode(buildGameServerDeploymentRollout());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getRollout(arg_name, $fields: arg_$fields);
      checkGameServerDeploymentRollout(
          response as api.GameServerDeploymentRollout);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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
        var resp =
            convert.json.encode(buildListGameServerDeploymentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListGameServerDeploymentsResponse(
          response as api.ListGameServerDeploymentsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
      var arg_request = buildGameServerDeployment();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerDeployment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerDeployment(obj as api.GameServerDeployment);

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

    unittest.test('method--previewRollout', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
      var arg_request = buildGameServerDeploymentRollout();
      var arg_name = 'foo';
      var arg_previewTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerDeploymentRollout.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerDeploymentRollout(
            obj as api.GameServerDeploymentRollout);

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
          queryMap["previewTime"]!.first,
          unittest.equals(arg_previewTime),
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
        var resp = convert.json
            .encode(buildPreviewGameServerDeploymentRolloutResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.previewRollout(arg_request, arg_name,
          previewTime: arg_previewTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkPreviewGameServerDeploymentRolloutResponse(
          response as api.PreviewGameServerDeploymentRolloutResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
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

    unittest.test('method--updateRollout', () async {
      var mock = HttpServerMock();
      var res =
          api.GameServicesApi(mock).projects.locations.gameServerDeployments;
      var arg_request = buildGameServerDeploymentRollout();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerDeploymentRollout.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerDeploymentRollout(
            obj as api.GameServerDeploymentRollout);

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
      final response = await res.updateRollout(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group(
      'resource-ProjectsLocationsGameServerDeploymentsConfigsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .gameServerDeployments
          .configs;
      var arg_request = buildGameServerConfig();
      var arg_parent = 'foo';
      var arg_configId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerConfig(obj as api.GameServerConfig);

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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          configId: arg_configId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .gameServerDeployments
          .configs;
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
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .gameServerDeployments
          .configs;
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
        var resp = convert.json.encode(buildGameServerConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGameServerConfig(response as api.GameServerConfig);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .gameServerDeployments
          .configs;
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
        var resp = convert.json.encode(buildListGameServerConfigsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListGameServerConfigsResponse(
          response as api.ListGameServerConfigsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations.operations;
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
      var res = api.GameServicesApi(mock).projects.locations.operations;
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
      var res = api.GameServicesApi(mock).projects.locations.operations;
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
      var res = api.GameServicesApi(mock).projects.locations.operations;
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

  unittest.group('resource-ProjectsLocationsRealmsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations.realms;
      var arg_request = buildRealm();
      var arg_parent = 'foo';
      var arg_realmId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Realm.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRealm(obj as api.Realm);

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
          queryMap["realmId"]!.first,
          unittest.equals(arg_realmId),
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
          realmId: arg_realmId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations.realms;
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
      var res = api.GameServicesApi(mock).projects.locations.realms;
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
        var resp = convert.json.encode(buildRealm());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkRealm(response as api.Realm);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations.realms;
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
        var resp = convert.json.encode(buildListRealmsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListRealmsResponse(response as api.ListRealmsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations.realms;
      var arg_request = buildRealm();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Realm.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRealm(obj as api.Realm);

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

    unittest.test('method--previewUpdate', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock).projects.locations.realms;
      var arg_request = buildRealm();
      var arg_name = 'foo';
      var arg_previewTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Realm.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRealm(obj as api.Realm);

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
          queryMap["previewTime"]!.first,
          unittest.equals(arg_previewTime),
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
        var resp = convert.json.encode(buildPreviewRealmUpdateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.previewUpdate(arg_request, arg_name,
          previewTime: arg_previewTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkPreviewRealmUpdateResponse(
          response as api.PreviewRealmUpdateResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsRealmsGameServerClustersResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
      var arg_request = buildGameServerCluster();
      var arg_parent = 'foo';
      var arg_gameServerClusterId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerCluster.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerCluster(obj as api.GameServerCluster);

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
          queryMap["gameServerClusterId"]!.first,
          unittest.equals(arg_gameServerClusterId),
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
          gameServerClusterId: arg_gameServerClusterId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
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
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
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
        var resp = convert.json.encode(buildGameServerCluster());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGameServerCluster(response as api.GameServerCluster);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
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
        var resp = convert.json.encode(buildListGameServerClustersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListGameServerClustersResponse(
          response as api.ListGameServerClustersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
      var arg_request = buildGameServerCluster();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerCluster.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerCluster(obj as api.GameServerCluster);

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

    unittest.test('method--previewCreate', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
      var arg_request = buildGameServerCluster();
      var arg_parent = 'foo';
      var arg_gameServerClusterId = 'foo';
      var arg_previewTime = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerCluster.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerCluster(obj as api.GameServerCluster);

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
          queryMap["gameServerClusterId"]!.first,
          unittest.equals(arg_gameServerClusterId),
        );
        unittest.expect(
          queryMap["previewTime"]!.first,
          unittest.equals(arg_previewTime),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildPreviewCreateGameServerClusterResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.previewCreate(arg_request, arg_parent,
          gameServerClusterId: arg_gameServerClusterId,
          previewTime: arg_previewTime,
          $fields: arg_$fields);
      checkPreviewCreateGameServerClusterResponse(
          response as api.PreviewCreateGameServerClusterResponse);
    });

    unittest.test('method--previewDelete', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
      var arg_name = 'foo';
      var arg_previewTime = 'foo';
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
          queryMap["previewTime"]!.first,
          unittest.equals(arg_previewTime),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildPreviewDeleteGameServerClusterResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.previewDelete(arg_name,
          previewTime: arg_previewTime, $fields: arg_$fields);
      checkPreviewDeleteGameServerClusterResponse(
          response as api.PreviewDeleteGameServerClusterResponse);
    });

    unittest.test('method--previewUpdate', () async {
      var mock = HttpServerMock();
      var res = api.GameServicesApi(mock)
          .projects
          .locations
          .realms
          .gameServerClusters;
      var arg_request = buildGameServerCluster();
      var arg_name = 'foo';
      var arg_previewTime = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GameServerCluster.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGameServerCluster(obj as api.GameServerCluster);

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
          queryMap["previewTime"]!.first,
          unittest.equals(arg_previewTime),
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
        var resp =
            convert.json.encode(buildPreviewUpdateGameServerClusterResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.previewUpdate(arg_request, arg_name,
          previewTime: arg_previewTime,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkPreviewUpdateGameServerClusterResponse(
          response as api.PreviewUpdateGameServerClusterResponse);
    });
  });
}
