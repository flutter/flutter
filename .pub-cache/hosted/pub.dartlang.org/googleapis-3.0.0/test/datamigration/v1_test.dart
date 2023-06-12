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

import 'package:googleapis/datamigration/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.AuditLogConfig> buildUnnamed2301() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed2301(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed2301();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed2301(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed2302() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2302(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed2302();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed2302(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.List<core.String> buildUnnamed2303() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2303(core.List<core.String> o) {
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
    o.members = buildUnnamed2303();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed2303(o.members!);
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

core.int buildCounterCloudSqlConnectionProfile = 0;
api.CloudSqlConnectionProfile buildCloudSqlConnectionProfile() {
  var o = api.CloudSqlConnectionProfile();
  buildCounterCloudSqlConnectionProfile++;
  if (buildCounterCloudSqlConnectionProfile < 3) {
    o.cloudSqlId = 'foo';
    o.privateIp = 'foo';
    o.publicIp = 'foo';
    o.settings = buildCloudSqlSettings();
  }
  buildCounterCloudSqlConnectionProfile--;
  return o;
}

void checkCloudSqlConnectionProfile(api.CloudSqlConnectionProfile o) {
  buildCounterCloudSqlConnectionProfile++;
  if (buildCounterCloudSqlConnectionProfile < 3) {
    unittest.expect(
      o.cloudSqlId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privateIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicIp!,
      unittest.equals('foo'),
    );
    checkCloudSqlSettings(o.settings! as api.CloudSqlSettings);
  }
  buildCounterCloudSqlConnectionProfile--;
}

core.Map<core.String, core.String> buildUnnamed2304() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2304(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed2305() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2305(core.Map<core.String, core.String> o) {
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

core.int buildCounterCloudSqlSettings = 0;
api.CloudSqlSettings buildCloudSqlSettings() {
  var o = api.CloudSqlSettings();
  buildCounterCloudSqlSettings++;
  if (buildCounterCloudSqlSettings < 3) {
    o.activationPolicy = 'foo';
    o.autoStorageIncrease = true;
    o.collation = 'foo';
    o.dataDiskSizeGb = 'foo';
    o.dataDiskType = 'foo';
    o.databaseFlags = buildUnnamed2304();
    o.databaseVersion = 'foo';
    o.ipConfig = buildSqlIpConfig();
    o.rootPassword = 'foo';
    o.rootPasswordSet = true;
    o.sourceId = 'foo';
    o.storageAutoResizeLimit = 'foo';
    o.tier = 'foo';
    o.userLabels = buildUnnamed2305();
    o.zone = 'foo';
  }
  buildCounterCloudSqlSettings--;
  return o;
}

void checkCloudSqlSettings(api.CloudSqlSettings o) {
  buildCounterCloudSqlSettings++;
  if (buildCounterCloudSqlSettings < 3) {
    unittest.expect(
      o.activationPolicy!,
      unittest.equals('foo'),
    );
    unittest.expect(o.autoStorageIncrease!, unittest.isTrue);
    unittest.expect(
      o.collation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataDiskSizeGb!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataDiskType!,
      unittest.equals('foo'),
    );
    checkUnnamed2304(o.databaseFlags!);
    unittest.expect(
      o.databaseVersion!,
      unittest.equals('foo'),
    );
    checkSqlIpConfig(o.ipConfig! as api.SqlIpConfig);
    unittest.expect(
      o.rootPassword!,
      unittest.equals('foo'),
    );
    unittest.expect(o.rootPasswordSet!, unittest.isTrue);
    unittest.expect(
      o.sourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.storageAutoResizeLimit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tier!,
      unittest.equals('foo'),
    );
    checkUnnamed2305(o.userLabels!);
    unittest.expect(
      o.zone!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudSqlSettings--;
}

core.Map<core.String, core.String> buildUnnamed2306() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2306(core.Map<core.String, core.String> o) {
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

core.int buildCounterConnectionProfile = 0;
api.ConnectionProfile buildConnectionProfile() {
  var o = api.ConnectionProfile();
  buildCounterConnectionProfile++;
  if (buildCounterConnectionProfile < 3) {
    o.cloudsql = buildCloudSqlConnectionProfile();
    o.createTime = 'foo';
    o.displayName = 'foo';
    o.error = buildStatus();
    o.labels = buildUnnamed2306();
    o.mysql = buildMySqlConnectionProfile();
    o.name = 'foo';
    o.postgresql = buildPostgreSqlConnectionProfile();
    o.provider = 'foo';
    o.state = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterConnectionProfile--;
  return o;
}

void checkConnectionProfile(api.ConnectionProfile o) {
  buildCounterConnectionProfile++;
  if (buildCounterConnectionProfile < 3) {
    checkCloudSqlConnectionProfile(
        o.cloudsql! as api.CloudSqlConnectionProfile);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkStatus(o.error! as api.Status);
    checkUnnamed2306(o.labels!);
    checkMySqlConnectionProfile(o.mysql! as api.MySqlConnectionProfile);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPostgreSqlConnectionProfile(
        o.postgresql! as api.PostgreSqlConnectionProfile);
    unittest.expect(
      o.provider!,
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
  buildCounterConnectionProfile--;
}

core.int buildCounterDatabaseType = 0;
api.DatabaseType buildDatabaseType() {
  var o = api.DatabaseType();
  buildCounterDatabaseType++;
  if (buildCounterDatabaseType < 3) {
    o.engine = 'foo';
    o.provider = 'foo';
  }
  buildCounterDatabaseType--;
  return o;
}

void checkDatabaseType(api.DatabaseType o) {
  buildCounterDatabaseType++;
  if (buildCounterDatabaseType < 3) {
    unittest.expect(
      o.engine!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.provider!,
      unittest.equals('foo'),
    );
  }
  buildCounterDatabaseType--;
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

core.int buildCounterGenerateSshScriptRequest = 0;
api.GenerateSshScriptRequest buildGenerateSshScriptRequest() {
  var o = api.GenerateSshScriptRequest();
  buildCounterGenerateSshScriptRequest++;
  if (buildCounterGenerateSshScriptRequest < 3) {
    o.vm = 'foo';
    o.vmCreationConfig = buildVmCreationConfig();
    o.vmPort = 42;
    o.vmSelectionConfig = buildVmSelectionConfig();
  }
  buildCounterGenerateSshScriptRequest--;
  return o;
}

void checkGenerateSshScriptRequest(api.GenerateSshScriptRequest o) {
  buildCounterGenerateSshScriptRequest++;
  if (buildCounterGenerateSshScriptRequest < 3) {
    unittest.expect(
      o.vm!,
      unittest.equals('foo'),
    );
    checkVmCreationConfig(o.vmCreationConfig! as api.VmCreationConfig);
    unittest.expect(
      o.vmPort!,
      unittest.equals(42),
    );
    checkVmSelectionConfig(o.vmSelectionConfig! as api.VmSelectionConfig);
  }
  buildCounterGenerateSshScriptRequest--;
}

core.int buildCounterGoogleCloudClouddmsV1OperationMetadata = 0;
api.GoogleCloudClouddmsV1OperationMetadata
    buildGoogleCloudClouddmsV1OperationMetadata() {
  var o = api.GoogleCloudClouddmsV1OperationMetadata();
  buildCounterGoogleCloudClouddmsV1OperationMetadata++;
  if (buildCounterGoogleCloudClouddmsV1OperationMetadata < 3) {
    o.apiVersion = 'foo';
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.requestedCancellation = true;
    o.statusMessage = 'foo';
    o.target = 'foo';
    o.verb = 'foo';
  }
  buildCounterGoogleCloudClouddmsV1OperationMetadata--;
  return o;
}

void checkGoogleCloudClouddmsV1OperationMetadata(
    api.GoogleCloudClouddmsV1OperationMetadata o) {
  buildCounterGoogleCloudClouddmsV1OperationMetadata++;
  if (buildCounterGoogleCloudClouddmsV1OperationMetadata < 3) {
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
    unittest.expect(o.requestedCancellation!, unittest.isTrue);
    unittest.expect(
      o.statusMessage!,
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
  buildCounterGoogleCloudClouddmsV1OperationMetadata--;
}

core.List<api.ConnectionProfile> buildUnnamed2307() {
  var o = <api.ConnectionProfile>[];
  o.add(buildConnectionProfile());
  o.add(buildConnectionProfile());
  return o;
}

void checkUnnamed2307(core.List<api.ConnectionProfile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConnectionProfile(o[0] as api.ConnectionProfile);
  checkConnectionProfile(o[1] as api.ConnectionProfile);
}

core.List<core.String> buildUnnamed2308() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2308(core.List<core.String> o) {
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

core.int buildCounterListConnectionProfilesResponse = 0;
api.ListConnectionProfilesResponse buildListConnectionProfilesResponse() {
  var o = api.ListConnectionProfilesResponse();
  buildCounterListConnectionProfilesResponse++;
  if (buildCounterListConnectionProfilesResponse < 3) {
    o.connectionProfiles = buildUnnamed2307();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed2308();
  }
  buildCounterListConnectionProfilesResponse--;
  return o;
}

void checkListConnectionProfilesResponse(api.ListConnectionProfilesResponse o) {
  buildCounterListConnectionProfilesResponse++;
  if (buildCounterListConnectionProfilesResponse < 3) {
    checkUnnamed2307(o.connectionProfiles!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2308(o.unreachable!);
  }
  buildCounterListConnectionProfilesResponse--;
}

core.List<api.Location> buildUnnamed2309() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed2309(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed2309();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed2309(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.MigrationJob> buildUnnamed2310() {
  var o = <api.MigrationJob>[];
  o.add(buildMigrationJob());
  o.add(buildMigrationJob());
  return o;
}

void checkUnnamed2310(core.List<api.MigrationJob> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMigrationJob(o[0] as api.MigrationJob);
  checkMigrationJob(o[1] as api.MigrationJob);
}

core.List<core.String> buildUnnamed2311() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2311(core.List<core.String> o) {
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

core.int buildCounterListMigrationJobsResponse = 0;
api.ListMigrationJobsResponse buildListMigrationJobsResponse() {
  var o = api.ListMigrationJobsResponse();
  buildCounterListMigrationJobsResponse++;
  if (buildCounterListMigrationJobsResponse < 3) {
    o.migrationJobs = buildUnnamed2310();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed2311();
  }
  buildCounterListMigrationJobsResponse--;
  return o;
}

void checkListMigrationJobsResponse(api.ListMigrationJobsResponse o) {
  buildCounterListMigrationJobsResponse++;
  if (buildCounterListMigrationJobsResponse < 3) {
    checkUnnamed2310(o.migrationJobs!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2311(o.unreachable!);
  }
  buildCounterListMigrationJobsResponse--;
}

core.List<api.Operation> buildUnnamed2312() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed2312(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed2312();
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
    checkUnnamed2312(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.Map<core.String, core.String> buildUnnamed2313() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2313(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed2314() {
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

void checkUnnamed2314(core.Map<core.String, core.Object> o) {
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
    o.labels = buildUnnamed2313();
    o.locationId = 'foo';
    o.metadata = buildUnnamed2314();
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
    checkUnnamed2313(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed2314(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.Map<core.String, core.String> buildUnnamed2315() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2315(core.Map<core.String, core.String> o) {
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

core.int buildCounterMigrationJob = 0;
api.MigrationJob buildMigrationJob() {
  var o = api.MigrationJob();
  buildCounterMigrationJob++;
  if (buildCounterMigrationJob < 3) {
    o.createTime = 'foo';
    o.destination = 'foo';
    o.destinationDatabase = buildDatabaseType();
    o.displayName = 'foo';
    o.dumpPath = 'foo';
    o.duration = 'foo';
    o.endTime = 'foo';
    o.error = buildStatus();
    o.labels = buildUnnamed2315();
    o.name = 'foo';
    o.phase = 'foo';
    o.reverseSshConnectivity = buildReverseSshConnectivity();
    o.source = 'foo';
    o.sourceDatabase = buildDatabaseType();
    o.state = 'foo';
    o.staticIpConnectivity = buildStaticIpConnectivity();
    o.type = 'foo';
    o.updateTime = 'foo';
    o.vpcPeeringConnectivity = buildVpcPeeringConnectivity();
  }
  buildCounterMigrationJob--;
  return o;
}

void checkMigrationJob(api.MigrationJob o) {
  buildCounterMigrationJob++;
  if (buildCounterMigrationJob < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destination!,
      unittest.equals('foo'),
    );
    checkDatabaseType(o.destinationDatabase! as api.DatabaseType);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dumpPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkStatus(o.error! as api.Status);
    checkUnnamed2315(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phase!,
      unittest.equals('foo'),
    );
    checkReverseSshConnectivity(
        o.reverseSshConnectivity! as api.ReverseSshConnectivity);
    unittest.expect(
      o.source!,
      unittest.equals('foo'),
    );
    checkDatabaseType(o.sourceDatabase! as api.DatabaseType);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkStaticIpConnectivity(
        o.staticIpConnectivity! as api.StaticIpConnectivity);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    checkVpcPeeringConnectivity(
        o.vpcPeeringConnectivity! as api.VpcPeeringConnectivity);
  }
  buildCounterMigrationJob--;
}

core.int buildCounterMigrationJobVerificationError = 0;
api.MigrationJobVerificationError buildMigrationJobVerificationError() {
  var o = api.MigrationJobVerificationError();
  buildCounterMigrationJobVerificationError++;
  if (buildCounterMigrationJobVerificationError < 3) {
    o.errorCode = 'foo';
    o.errorDetailMessage = 'foo';
    o.errorMessage = 'foo';
  }
  buildCounterMigrationJobVerificationError--;
  return o;
}

void checkMigrationJobVerificationError(api.MigrationJobVerificationError o) {
  buildCounterMigrationJobVerificationError++;
  if (buildCounterMigrationJobVerificationError < 3) {
    unittest.expect(
      o.errorCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorDetailMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
  }
  buildCounterMigrationJobVerificationError--;
}

core.int buildCounterMySqlConnectionProfile = 0;
api.MySqlConnectionProfile buildMySqlConnectionProfile() {
  var o = api.MySqlConnectionProfile();
  buildCounterMySqlConnectionProfile++;
  if (buildCounterMySqlConnectionProfile < 3) {
    o.cloudSqlId = 'foo';
    o.host = 'foo';
    o.password = 'foo';
    o.passwordSet = true;
    o.port = 42;
    o.ssl = buildSslConfig();
    o.username = 'foo';
  }
  buildCounterMySqlConnectionProfile--;
  return o;
}

void checkMySqlConnectionProfile(api.MySqlConnectionProfile o) {
  buildCounterMySqlConnectionProfile++;
  if (buildCounterMySqlConnectionProfile < 3) {
    unittest.expect(
      o.cloudSqlId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(o.passwordSet!, unittest.isTrue);
    unittest.expect(
      o.port!,
      unittest.equals(42),
    );
    checkSslConfig(o.ssl! as api.SslConfig);
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterMySqlConnectionProfile--;
}

core.Map<core.String, core.Object> buildUnnamed2316() {
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

void checkUnnamed2316(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2317() {
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

void checkUnnamed2317(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed2316();
    o.name = 'foo';
    o.response = buildUnnamed2317();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed2316(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2317(o.response!);
  }
  buildCounterOperation--;
}

core.List<api.AuditConfig> buildUnnamed2318() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed2318(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed2319() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed2319(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed2318();
    o.bindings = buildUnnamed2319();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed2318(o.auditConfigs!);
    checkUnnamed2319(o.bindings!);
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

core.int buildCounterPostgreSqlConnectionProfile = 0;
api.PostgreSqlConnectionProfile buildPostgreSqlConnectionProfile() {
  var o = api.PostgreSqlConnectionProfile();
  buildCounterPostgreSqlConnectionProfile++;
  if (buildCounterPostgreSqlConnectionProfile < 3) {
    o.cloudSqlId = 'foo';
    o.host = 'foo';
    o.password = 'foo';
    o.passwordSet = true;
    o.port = 42;
    o.ssl = buildSslConfig();
    o.username = 'foo';
  }
  buildCounterPostgreSqlConnectionProfile--;
  return o;
}

void checkPostgreSqlConnectionProfile(api.PostgreSqlConnectionProfile o) {
  buildCounterPostgreSqlConnectionProfile++;
  if (buildCounterPostgreSqlConnectionProfile < 3) {
    unittest.expect(
      o.cloudSqlId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(o.passwordSet!, unittest.isTrue);
    unittest.expect(
      o.port!,
      unittest.equals(42),
    );
    checkSslConfig(o.ssl! as api.SslConfig);
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterPostgreSqlConnectionProfile--;
}

core.int buildCounterPromoteMigrationJobRequest = 0;
api.PromoteMigrationJobRequest buildPromoteMigrationJobRequest() {
  var o = api.PromoteMigrationJobRequest();
  buildCounterPromoteMigrationJobRequest++;
  if (buildCounterPromoteMigrationJobRequest < 3) {}
  buildCounterPromoteMigrationJobRequest--;
  return o;
}

void checkPromoteMigrationJobRequest(api.PromoteMigrationJobRequest o) {
  buildCounterPromoteMigrationJobRequest++;
  if (buildCounterPromoteMigrationJobRequest < 3) {}
  buildCounterPromoteMigrationJobRequest--;
}

core.int buildCounterRestartMigrationJobRequest = 0;
api.RestartMigrationJobRequest buildRestartMigrationJobRequest() {
  var o = api.RestartMigrationJobRequest();
  buildCounterRestartMigrationJobRequest++;
  if (buildCounterRestartMigrationJobRequest < 3) {}
  buildCounterRestartMigrationJobRequest--;
  return o;
}

void checkRestartMigrationJobRequest(api.RestartMigrationJobRequest o) {
  buildCounterRestartMigrationJobRequest++;
  if (buildCounterRestartMigrationJobRequest < 3) {}
  buildCounterRestartMigrationJobRequest--;
}

core.int buildCounterResumeMigrationJobRequest = 0;
api.ResumeMigrationJobRequest buildResumeMigrationJobRequest() {
  var o = api.ResumeMigrationJobRequest();
  buildCounterResumeMigrationJobRequest++;
  if (buildCounterResumeMigrationJobRequest < 3) {}
  buildCounterResumeMigrationJobRequest--;
  return o;
}

void checkResumeMigrationJobRequest(api.ResumeMigrationJobRequest o) {
  buildCounterResumeMigrationJobRequest++;
  if (buildCounterResumeMigrationJobRequest < 3) {}
  buildCounterResumeMigrationJobRequest--;
}

core.int buildCounterReverseSshConnectivity = 0;
api.ReverseSshConnectivity buildReverseSshConnectivity() {
  var o = api.ReverseSshConnectivity();
  buildCounterReverseSshConnectivity++;
  if (buildCounterReverseSshConnectivity < 3) {
    o.vm = 'foo';
    o.vmIp = 'foo';
    o.vmPort = 42;
    o.vpc = 'foo';
  }
  buildCounterReverseSshConnectivity--;
  return o;
}

void checkReverseSshConnectivity(api.ReverseSshConnectivity o) {
  buildCounterReverseSshConnectivity++;
  if (buildCounterReverseSshConnectivity < 3) {
    unittest.expect(
      o.vm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmPort!,
      unittest.equals(42),
    );
    unittest.expect(
      o.vpc!,
      unittest.equals('foo'),
    );
  }
  buildCounterReverseSshConnectivity--;
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

core.int buildCounterSqlAclEntry = 0;
api.SqlAclEntry buildSqlAclEntry() {
  var o = api.SqlAclEntry();
  buildCounterSqlAclEntry++;
  if (buildCounterSqlAclEntry < 3) {
    o.expireTime = 'foo';
    o.label = 'foo';
    o.ttl = 'foo';
    o.value = 'foo';
  }
  buildCounterSqlAclEntry--;
  return o;
}

void checkSqlAclEntry(api.SqlAclEntry o) {
  buildCounterSqlAclEntry++;
  if (buildCounterSqlAclEntry < 3) {
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ttl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterSqlAclEntry--;
}

core.List<api.SqlAclEntry> buildUnnamed2320() {
  var o = <api.SqlAclEntry>[];
  o.add(buildSqlAclEntry());
  o.add(buildSqlAclEntry());
  return o;
}

void checkUnnamed2320(core.List<api.SqlAclEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSqlAclEntry(o[0] as api.SqlAclEntry);
  checkSqlAclEntry(o[1] as api.SqlAclEntry);
}

core.int buildCounterSqlIpConfig = 0;
api.SqlIpConfig buildSqlIpConfig() {
  var o = api.SqlIpConfig();
  buildCounterSqlIpConfig++;
  if (buildCounterSqlIpConfig < 3) {
    o.authorizedNetworks = buildUnnamed2320();
    o.enableIpv4 = true;
    o.privateNetwork = 'foo';
    o.requireSsl = true;
  }
  buildCounterSqlIpConfig--;
  return o;
}

void checkSqlIpConfig(api.SqlIpConfig o) {
  buildCounterSqlIpConfig++;
  if (buildCounterSqlIpConfig < 3) {
    checkUnnamed2320(o.authorizedNetworks!);
    unittest.expect(o.enableIpv4!, unittest.isTrue);
    unittest.expect(
      o.privateNetwork!,
      unittest.equals('foo'),
    );
    unittest.expect(o.requireSsl!, unittest.isTrue);
  }
  buildCounterSqlIpConfig--;
}

core.int buildCounterSshScript = 0;
api.SshScript buildSshScript() {
  var o = api.SshScript();
  buildCounterSshScript++;
  if (buildCounterSshScript < 3) {
    o.script = 'foo';
  }
  buildCounterSshScript--;
  return o;
}

void checkSshScript(api.SshScript o) {
  buildCounterSshScript++;
  if (buildCounterSshScript < 3) {
    unittest.expect(
      o.script!,
      unittest.equals('foo'),
    );
  }
  buildCounterSshScript--;
}

core.int buildCounterSslConfig = 0;
api.SslConfig buildSslConfig() {
  var o = api.SslConfig();
  buildCounterSslConfig++;
  if (buildCounterSslConfig < 3) {
    o.caCertificate = 'foo';
    o.clientCertificate = 'foo';
    o.clientKey = 'foo';
    o.type = 'foo';
  }
  buildCounterSslConfig--;
  return o;
}

void checkSslConfig(api.SslConfig o) {
  buildCounterSslConfig++;
  if (buildCounterSslConfig < 3) {
    unittest.expect(
      o.caCertificate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clientCertificate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clientKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterSslConfig--;
}

core.int buildCounterStartMigrationJobRequest = 0;
api.StartMigrationJobRequest buildStartMigrationJobRequest() {
  var o = api.StartMigrationJobRequest();
  buildCounterStartMigrationJobRequest++;
  if (buildCounterStartMigrationJobRequest < 3) {}
  buildCounterStartMigrationJobRequest--;
  return o;
}

void checkStartMigrationJobRequest(api.StartMigrationJobRequest o) {
  buildCounterStartMigrationJobRequest++;
  if (buildCounterStartMigrationJobRequest < 3) {}
  buildCounterStartMigrationJobRequest--;
}

core.int buildCounterStaticIpConnectivity = 0;
api.StaticIpConnectivity buildStaticIpConnectivity() {
  var o = api.StaticIpConnectivity();
  buildCounterStaticIpConnectivity++;
  if (buildCounterStaticIpConnectivity < 3) {}
  buildCounterStaticIpConnectivity--;
  return o;
}

void checkStaticIpConnectivity(api.StaticIpConnectivity o) {
  buildCounterStaticIpConnectivity++;
  if (buildCounterStaticIpConnectivity < 3) {}
  buildCounterStaticIpConnectivity--;
}

core.Map<core.String, core.Object> buildUnnamed2321() {
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

void checkUnnamed2321(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2322() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2321());
  o.add(buildUnnamed2321());
  return o;
}

void checkUnnamed2322(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2321(o[0]);
  checkUnnamed2321(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2322();
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
    checkUnnamed2322(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterStopMigrationJobRequest = 0;
api.StopMigrationJobRequest buildStopMigrationJobRequest() {
  var o = api.StopMigrationJobRequest();
  buildCounterStopMigrationJobRequest++;
  if (buildCounterStopMigrationJobRequest < 3) {}
  buildCounterStopMigrationJobRequest--;
  return o;
}

void checkStopMigrationJobRequest(api.StopMigrationJobRequest o) {
  buildCounterStopMigrationJobRequest++;
  if (buildCounterStopMigrationJobRequest < 3) {}
  buildCounterStopMigrationJobRequest--;
}

core.List<core.String> buildUnnamed2323() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2323(core.List<core.String> o) {
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
    o.permissions = buildUnnamed2323();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed2323(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed2324() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2324(core.List<core.String> o) {
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
    o.permissions = buildUnnamed2324();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed2324(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterVerifyMigrationJobRequest = 0;
api.VerifyMigrationJobRequest buildVerifyMigrationJobRequest() {
  var o = api.VerifyMigrationJobRequest();
  buildCounterVerifyMigrationJobRequest++;
  if (buildCounterVerifyMigrationJobRequest < 3) {}
  buildCounterVerifyMigrationJobRequest--;
  return o;
}

void checkVerifyMigrationJobRequest(api.VerifyMigrationJobRequest o) {
  buildCounterVerifyMigrationJobRequest++;
  if (buildCounterVerifyMigrationJobRequest < 3) {}
  buildCounterVerifyMigrationJobRequest--;
}

core.int buildCounterVmCreationConfig = 0;
api.VmCreationConfig buildVmCreationConfig() {
  var o = api.VmCreationConfig();
  buildCounterVmCreationConfig++;
  if (buildCounterVmCreationConfig < 3) {
    o.subnet = 'foo';
    o.vmMachineType = 'foo';
    o.vmZone = 'foo';
  }
  buildCounterVmCreationConfig--;
  return o;
}

void checkVmCreationConfig(api.VmCreationConfig o) {
  buildCounterVmCreationConfig++;
  if (buildCounterVmCreationConfig < 3) {
    unittest.expect(
      o.subnet!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmMachineType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterVmCreationConfig--;
}

core.int buildCounterVmSelectionConfig = 0;
api.VmSelectionConfig buildVmSelectionConfig() {
  var o = api.VmSelectionConfig();
  buildCounterVmSelectionConfig++;
  if (buildCounterVmSelectionConfig < 3) {
    o.vmZone = 'foo';
  }
  buildCounterVmSelectionConfig--;
  return o;
}

void checkVmSelectionConfig(api.VmSelectionConfig o) {
  buildCounterVmSelectionConfig++;
  if (buildCounterVmSelectionConfig < 3) {
    unittest.expect(
      o.vmZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterVmSelectionConfig--;
}

core.int buildCounterVpcPeeringConnectivity = 0;
api.VpcPeeringConnectivity buildVpcPeeringConnectivity() {
  var o = api.VpcPeeringConnectivity();
  buildCounterVpcPeeringConnectivity++;
  if (buildCounterVpcPeeringConnectivity < 3) {
    o.vpc = 'foo';
  }
  buildCounterVpcPeeringConnectivity--;
  return o;
}

void checkVpcPeeringConnectivity(api.VpcPeeringConnectivity o) {
  buildCounterVpcPeeringConnectivity++;
  if (buildCounterVpcPeeringConnectivity < 3) {
    unittest.expect(
      o.vpc!,
      unittest.equals('foo'),
    );
  }
  buildCounterVpcPeeringConnectivity--;
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

  unittest.group('obj-schema-CloudSqlConnectionProfile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudSqlConnectionProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudSqlConnectionProfile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudSqlConnectionProfile(od as api.CloudSqlConnectionProfile);
    });
  });

  unittest.group('obj-schema-CloudSqlSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudSqlSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudSqlSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudSqlSettings(od as api.CloudSqlSettings);
    });
  });

  unittest.group('obj-schema-ConnectionProfile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConnectionProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConnectionProfile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConnectionProfile(od as api.ConnectionProfile);
    });
  });

  unittest.group('obj-schema-DatabaseType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatabaseType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatabaseType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatabaseType(od as api.DatabaseType);
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

  unittest.group('obj-schema-GenerateSshScriptRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenerateSshScriptRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenerateSshScriptRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenerateSshScriptRequest(od as api.GenerateSshScriptRequest);
    });
  });

  unittest.group('obj-schema-GoogleCloudClouddmsV1OperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudClouddmsV1OperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudClouddmsV1OperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudClouddmsV1OperationMetadata(
          od as api.GoogleCloudClouddmsV1OperationMetadata);
    });
  });

  unittest.group('obj-schema-ListConnectionProfilesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConnectionProfilesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConnectionProfilesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConnectionProfilesResponse(
          od as api.ListConnectionProfilesResponse);
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

  unittest.group('obj-schema-ListMigrationJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListMigrationJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListMigrationJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListMigrationJobsResponse(od as api.ListMigrationJobsResponse);
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

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
    });
  });

  unittest.group('obj-schema-MigrationJob', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMigrationJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MigrationJob.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMigrationJob(od as api.MigrationJob);
    });
  });

  unittest.group('obj-schema-MigrationJobVerificationError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMigrationJobVerificationError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MigrationJobVerificationError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMigrationJobVerificationError(
          od as api.MigrationJobVerificationError);
    });
  });

  unittest.group('obj-schema-MySqlConnectionProfile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMySqlConnectionProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MySqlConnectionProfile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMySqlConnectionProfile(od as api.MySqlConnectionProfile);
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

  unittest.group('obj-schema-Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicy(od as api.Policy);
    });
  });

  unittest.group('obj-schema-PostgreSqlConnectionProfile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPostgreSqlConnectionProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PostgreSqlConnectionProfile.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPostgreSqlConnectionProfile(od as api.PostgreSqlConnectionProfile);
    });
  });

  unittest.group('obj-schema-PromoteMigrationJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPromoteMigrationJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PromoteMigrationJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPromoteMigrationJobRequest(od as api.PromoteMigrationJobRequest);
    });
  });

  unittest.group('obj-schema-RestartMigrationJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestartMigrationJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestartMigrationJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestartMigrationJobRequest(od as api.RestartMigrationJobRequest);
    });
  });

  unittest.group('obj-schema-ResumeMigrationJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResumeMigrationJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResumeMigrationJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResumeMigrationJobRequest(od as api.ResumeMigrationJobRequest);
    });
  });

  unittest.group('obj-schema-ReverseSshConnectivity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReverseSshConnectivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReverseSshConnectivity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReverseSshConnectivity(od as api.ReverseSshConnectivity);
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

  unittest.group('obj-schema-SqlAclEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSqlAclEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SqlAclEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSqlAclEntry(od as api.SqlAclEntry);
    });
  });

  unittest.group('obj-schema-SqlIpConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSqlIpConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SqlIpConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSqlIpConfig(od as api.SqlIpConfig);
    });
  });

  unittest.group('obj-schema-SshScript', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSshScript();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SshScript.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSshScript(od as api.SshScript);
    });
  });

  unittest.group('obj-schema-SslConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSslConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SslConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSslConfig(od as api.SslConfig);
    });
  });

  unittest.group('obj-schema-StartMigrationJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStartMigrationJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StartMigrationJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStartMigrationJobRequest(od as api.StartMigrationJobRequest);
    });
  });

  unittest.group('obj-schema-StaticIpConnectivity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStaticIpConnectivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StaticIpConnectivity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStaticIpConnectivity(od as api.StaticIpConnectivity);
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

  unittest.group('obj-schema-StopMigrationJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStopMigrationJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StopMigrationJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStopMigrationJobRequest(od as api.StopMigrationJobRequest);
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

  unittest.group('obj-schema-VerifyMigrationJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerifyMigrationJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerifyMigrationJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerifyMigrationJobRequest(od as api.VerifyMigrationJobRequest);
    });
  });

  unittest.group('obj-schema-VmCreationConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVmCreationConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VmCreationConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVmCreationConfig(od as api.VmCreationConfig);
    });
  });

  unittest.group('obj-schema-VmSelectionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVmSelectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VmSelectionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVmSelectionConfig(od as api.VmSelectionConfig);
    });
  });

  unittest.group('obj-schema-VpcPeeringConnectivity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVpcPeeringConnectivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VpcPeeringConnectivity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVpcPeeringConnectivity(od as api.VpcPeeringConnectivity);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock).projects.locations;
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
      var res = api.DatabaseMigrationServiceApi(mock).projects.locations;
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

  unittest.group('resource-ProjectsLocationsConnectionProfilesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
      var arg_request = buildConnectionProfile();
      var arg_parent = 'foo';
      var arg_connectionProfileId = 'foo';
      var arg_requestId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConnectionProfile.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConnectionProfile(obj as api.ConnectionProfile);

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
          queryMap["connectionProfileId"]!.first,
          unittest.equals(arg_connectionProfileId),
        );
        unittest.expect(
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
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
          connectionProfileId: arg_connectionProfileId,
          requestId: arg_requestId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
      var arg_name = 'foo';
      var arg_force = true;
      var arg_requestId = 'foo';
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
          queryMap["force"]!.first,
          unittest.equals("$arg_force"),
        );
        unittest.expect(
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
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
      final response = await res.delete(arg_name,
          force: arg_force, requestId: arg_requestId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
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
        var resp = convert.json.encode(buildConnectionProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkConnectionProfile(response as api.ConnectionProfile);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
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
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
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
        var resp = convert.json.encode(buildListConnectionProfilesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListConnectionProfilesResponse(
          response as api.ListConnectionProfilesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
      var arg_request = buildConnectionProfile();
      var arg_name = 'foo';
      var arg_requestId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ConnectionProfile.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConnectionProfile(obj as api.ConnectionProfile);

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
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          requestId: arg_requestId,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
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
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .connectionProfiles;
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

  unittest.group('resource-ProjectsLocationsMigrationJobsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildMigrationJob();
      var arg_parent = 'foo';
      var arg_migrationJobId = 'foo';
      var arg_requestId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.MigrationJob.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkMigrationJob(obj as api.MigrationJob);

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
          queryMap["migrationJobId"]!.first,
          unittest.equals(arg_migrationJobId),
        );
        unittest.expect(
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
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
          migrationJobId: arg_migrationJobId,
          requestId: arg_requestId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_name = 'foo';
      var arg_force = true;
      var arg_requestId = 'foo';
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
          queryMap["force"]!.first,
          unittest.equals("$arg_force"),
        );
        unittest.expect(
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
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
      final response = await res.delete(arg_name,
          force: arg_force, requestId: arg_requestId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--generateSshScript', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildGenerateSshScriptRequest();
      var arg_migrationJob = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GenerateSshScriptRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGenerateSshScriptRequest(obj as api.GenerateSshScriptRequest);

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
        var resp = convert.json.encode(buildSshScript());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generateSshScript(
          arg_request, arg_migrationJob,
          $fields: arg_$fields);
      checkSshScript(response as api.SshScript);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
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
        var resp = convert.json.encode(buildMigrationJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkMigrationJob(response as api.MigrationJob);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
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
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
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
        var resp = convert.json.encode(buildListMigrationJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListMigrationJobsResponse(response as api.ListMigrationJobsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildMigrationJob();
      var arg_name = 'foo';
      var arg_requestId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.MigrationJob.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkMigrationJob(obj as api.MigrationJob);

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
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          requestId: arg_requestId,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--promote', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildPromoteMigrationJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PromoteMigrationJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPromoteMigrationJobRequest(obj as api.PromoteMigrationJobRequest);

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
          await res.promote(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--restart', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildRestartMigrationJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RestartMigrationJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRestartMigrationJobRequest(obj as api.RestartMigrationJobRequest);

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
          await res.restart(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--resume', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildResumeMigrationJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResumeMigrationJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResumeMigrationJobRequest(obj as api.ResumeMigrationJobRequest);

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
          await res.resume(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
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

    unittest.test('method--start', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildStartMigrationJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StartMigrationJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStartMigrationJobRequest(obj as api.StartMigrationJobRequest);

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
          await res.start(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildStopMigrationJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StopMigrationJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStopMigrationJobRequest(obj as api.StopMigrationJobRequest);

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
          await res.stop(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
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

    unittest.test('method--verify', () async {
      var mock = HttpServerMock();
      var res = api.DatabaseMigrationServiceApi(mock)
          .projects
          .locations
          .migrationJobs;
      var arg_request = buildVerifyMigrationJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.VerifyMigrationJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkVerifyMigrationJobRequest(obj as api.VerifyMigrationJobRequest);

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
          await res.verify(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res =
          api.DatabaseMigrationServiceApi(mock).projects.locations.operations;
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
          api.DatabaseMigrationServiceApi(mock).projects.locations.operations;
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
          api.DatabaseMigrationServiceApi(mock).projects.locations.operations;
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
          api.DatabaseMigrationServiceApi(mock).projects.locations.operations;
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
