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

import 'package:googleapis/composer/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAllowedIpRange = 0;
api.AllowedIpRange buildAllowedIpRange() {
  var o = api.AllowedIpRange();
  buildCounterAllowedIpRange++;
  if (buildCounterAllowedIpRange < 3) {
    o.description = 'foo';
    o.value = 'foo';
  }
  buildCounterAllowedIpRange--;
  return o;
}

void checkAllowedIpRange(api.AllowedIpRange o) {
  buildCounterAllowedIpRange++;
  if (buildCounterAllowedIpRange < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterAllowedIpRange--;
}

core.int buildCounterDatabaseConfig = 0;
api.DatabaseConfig buildDatabaseConfig() {
  var o = api.DatabaseConfig();
  buildCounterDatabaseConfig++;
  if (buildCounterDatabaseConfig < 3) {
    o.machineType = 'foo';
  }
  buildCounterDatabaseConfig--;
  return o;
}

void checkDatabaseConfig(api.DatabaseConfig o) {
  buildCounterDatabaseConfig++;
  if (buildCounterDatabaseConfig < 3) {
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDatabaseConfig--;
}

core.int buildCounterDate = 0;
api.Date buildDate() {
  var o = api.Date();
  buildCounterDate++;
  if (buildCounterDate < 3) {
    o.day = 42;
    o.month = 42;
    o.year = 42;
  }
  buildCounterDate--;
  return o;
}

void checkDate(api.Date o) {
  buildCounterDate++;
  if (buildCounterDate < 3) {
    unittest.expect(
      o.day!,
      unittest.equals(42),
    );
    unittest.expect(
      o.month!,
      unittest.equals(42),
    );
    unittest.expect(
      o.year!,
      unittest.equals(42),
    );
  }
  buildCounterDate--;
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

core.Map<core.String, core.String> buildUnnamed2370() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2370(core.Map<core.String, core.String> o) {
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

core.int buildCounterEnvironment = 0;
api.Environment buildEnvironment() {
  var o = api.Environment();
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    o.config = buildEnvironmentConfig();
    o.createTime = 'foo';
    o.labels = buildUnnamed2370();
    o.name = 'foo';
    o.state = 'foo';
    o.updateTime = 'foo';
    o.uuid = 'foo';
  }
  buildCounterEnvironment--;
  return o;
}

void checkEnvironment(api.Environment o) {
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    checkEnvironmentConfig(o.config! as api.EnvironmentConfig);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUnnamed2370(o.labels!);
    unittest.expect(
      o.name!,
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
    unittest.expect(
      o.uuid!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnvironment--;
}

core.int buildCounterEnvironmentConfig = 0;
api.EnvironmentConfig buildEnvironmentConfig() {
  var o = api.EnvironmentConfig();
  buildCounterEnvironmentConfig++;
  if (buildCounterEnvironmentConfig < 3) {
    o.airflowUri = 'foo';
    o.dagGcsPrefix = 'foo';
    o.databaseConfig = buildDatabaseConfig();
    o.encryptionConfig = buildEncryptionConfig();
    o.gkeCluster = 'foo';
    o.nodeConfig = buildNodeConfig();
    o.nodeCount = 42;
    o.privateEnvironmentConfig = buildPrivateEnvironmentConfig();
    o.softwareConfig = buildSoftwareConfig();
    o.webServerConfig = buildWebServerConfig();
    o.webServerNetworkAccessControl = buildWebServerNetworkAccessControl();
  }
  buildCounterEnvironmentConfig--;
  return o;
}

void checkEnvironmentConfig(api.EnvironmentConfig o) {
  buildCounterEnvironmentConfig++;
  if (buildCounterEnvironmentConfig < 3) {
    unittest.expect(
      o.airflowUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dagGcsPrefix!,
      unittest.equals('foo'),
    );
    checkDatabaseConfig(o.databaseConfig! as api.DatabaseConfig);
    checkEncryptionConfig(o.encryptionConfig! as api.EncryptionConfig);
    unittest.expect(
      o.gkeCluster!,
      unittest.equals('foo'),
    );
    checkNodeConfig(o.nodeConfig! as api.NodeConfig);
    unittest.expect(
      o.nodeCount!,
      unittest.equals(42),
    );
    checkPrivateEnvironmentConfig(
        o.privateEnvironmentConfig! as api.PrivateEnvironmentConfig);
    checkSoftwareConfig(o.softwareConfig! as api.SoftwareConfig);
    checkWebServerConfig(o.webServerConfig! as api.WebServerConfig);
    checkWebServerNetworkAccessControl(
        o.webServerNetworkAccessControl! as api.WebServerNetworkAccessControl);
  }
  buildCounterEnvironmentConfig--;
}

core.int buildCounterIPAllocationPolicy = 0;
api.IPAllocationPolicy buildIPAllocationPolicy() {
  var o = api.IPAllocationPolicy();
  buildCounterIPAllocationPolicy++;
  if (buildCounterIPAllocationPolicy < 3) {
    o.clusterIpv4CidrBlock = 'foo';
    o.clusterSecondaryRangeName = 'foo';
    o.servicesIpv4CidrBlock = 'foo';
    o.servicesSecondaryRangeName = 'foo';
    o.useIpAliases = true;
  }
  buildCounterIPAllocationPolicy--;
  return o;
}

void checkIPAllocationPolicy(api.IPAllocationPolicy o) {
  buildCounterIPAllocationPolicy++;
  if (buildCounterIPAllocationPolicy < 3) {
    unittest.expect(
      o.clusterIpv4CidrBlock!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clusterSecondaryRangeName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.servicesIpv4CidrBlock!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.servicesSecondaryRangeName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.useIpAliases!, unittest.isTrue);
  }
  buildCounterIPAllocationPolicy--;
}

core.List<core.String> buildUnnamed2371() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2371(core.List<core.String> o) {
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

core.int buildCounterImageVersion = 0;
api.ImageVersion buildImageVersion() {
  var o = api.ImageVersion();
  buildCounterImageVersion++;
  if (buildCounterImageVersion < 3) {
    o.creationDisabled = true;
    o.imageVersionId = 'foo';
    o.isDefault = true;
    o.releaseDate = buildDate();
    o.supportedPythonVersions = buildUnnamed2371();
    o.upgradeDisabled = true;
  }
  buildCounterImageVersion--;
  return o;
}

void checkImageVersion(api.ImageVersion o) {
  buildCounterImageVersion++;
  if (buildCounterImageVersion < 3) {
    unittest.expect(o.creationDisabled!, unittest.isTrue);
    unittest.expect(
      o.imageVersionId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDefault!, unittest.isTrue);
    checkDate(o.releaseDate! as api.Date);
    checkUnnamed2371(o.supportedPythonVersions!);
    unittest.expect(o.upgradeDisabled!, unittest.isTrue);
  }
  buildCounterImageVersion--;
}

core.List<api.Environment> buildUnnamed2372() {
  var o = <api.Environment>[];
  o.add(buildEnvironment());
  o.add(buildEnvironment());
  return o;
}

void checkUnnamed2372(core.List<api.Environment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnvironment(o[0] as api.Environment);
  checkEnvironment(o[1] as api.Environment);
}

core.int buildCounterListEnvironmentsResponse = 0;
api.ListEnvironmentsResponse buildListEnvironmentsResponse() {
  var o = api.ListEnvironmentsResponse();
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    o.environments = buildUnnamed2372();
    o.nextPageToken = 'foo';
  }
  buildCounterListEnvironmentsResponse--;
  return o;
}

void checkListEnvironmentsResponse(api.ListEnvironmentsResponse o) {
  buildCounterListEnvironmentsResponse++;
  if (buildCounterListEnvironmentsResponse < 3) {
    checkUnnamed2372(o.environments!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListEnvironmentsResponse--;
}

core.List<api.ImageVersion> buildUnnamed2373() {
  var o = <api.ImageVersion>[];
  o.add(buildImageVersion());
  o.add(buildImageVersion());
  return o;
}

void checkUnnamed2373(core.List<api.ImageVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImageVersion(o[0] as api.ImageVersion);
  checkImageVersion(o[1] as api.ImageVersion);
}

core.int buildCounterListImageVersionsResponse = 0;
api.ListImageVersionsResponse buildListImageVersionsResponse() {
  var o = api.ListImageVersionsResponse();
  buildCounterListImageVersionsResponse++;
  if (buildCounterListImageVersionsResponse < 3) {
    o.imageVersions = buildUnnamed2373();
    o.nextPageToken = 'foo';
  }
  buildCounterListImageVersionsResponse--;
  return o;
}

void checkListImageVersionsResponse(api.ListImageVersionsResponse o) {
  buildCounterListImageVersionsResponse++;
  if (buildCounterListImageVersionsResponse < 3) {
    checkUnnamed2373(o.imageVersions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListImageVersionsResponse--;
}

core.List<api.Operation> buildUnnamed2374() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed2374(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed2374();
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
    checkUnnamed2374(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<core.String> buildUnnamed2375() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2375(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2376() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2376(core.List<core.String> o) {
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

core.int buildCounterNodeConfig = 0;
api.NodeConfig buildNodeConfig() {
  var o = api.NodeConfig();
  buildCounterNodeConfig++;
  if (buildCounterNodeConfig < 3) {
    o.diskSizeGb = 42;
    o.ipAllocationPolicy = buildIPAllocationPolicy();
    o.location = 'foo';
    o.machineType = 'foo';
    o.network = 'foo';
    o.oauthScopes = buildUnnamed2375();
    o.serviceAccount = 'foo';
    o.subnetwork = 'foo';
    o.tags = buildUnnamed2376();
  }
  buildCounterNodeConfig--;
  return o;
}

void checkNodeConfig(api.NodeConfig o) {
  buildCounterNodeConfig++;
  if (buildCounterNodeConfig < 3) {
    unittest.expect(
      o.diskSizeGb!,
      unittest.equals(42),
    );
    checkIPAllocationPolicy(o.ipAllocationPolicy! as api.IPAllocationPolicy);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.network!,
      unittest.equals('foo'),
    );
    checkUnnamed2375(o.oauthScopes!);
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subnetwork!,
      unittest.equals('foo'),
    );
    checkUnnamed2376(o.tags!);
  }
  buildCounterNodeConfig--;
}

core.Map<core.String, core.Object> buildUnnamed2377() {
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

void checkUnnamed2377(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2378() {
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

void checkUnnamed2378(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed2377();
    o.name = 'foo';
    o.response = buildUnnamed2378();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed2377(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2378(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationMetadata = 0;
api.OperationMetadata buildOperationMetadata() {
  var o = api.OperationMetadata();
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.operationType = 'foo';
    o.resource = 'foo';
    o.resourceUuid = 'foo';
    o.state = 'foo';
  }
  buildCounterOperationMetadata--;
  return o;
}

void checkOperationMetadata(api.OperationMetadata o) {
  buildCounterOperationMetadata++;
  if (buildCounterOperationMetadata < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUuid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperationMetadata--;
}

core.int buildCounterPrivateClusterConfig = 0;
api.PrivateClusterConfig buildPrivateClusterConfig() {
  var o = api.PrivateClusterConfig();
  buildCounterPrivateClusterConfig++;
  if (buildCounterPrivateClusterConfig < 3) {
    o.enablePrivateEndpoint = true;
    o.masterIpv4CidrBlock = 'foo';
    o.masterIpv4ReservedRange = 'foo';
  }
  buildCounterPrivateClusterConfig--;
  return o;
}

void checkPrivateClusterConfig(api.PrivateClusterConfig o) {
  buildCounterPrivateClusterConfig++;
  if (buildCounterPrivateClusterConfig < 3) {
    unittest.expect(o.enablePrivateEndpoint!, unittest.isTrue);
    unittest.expect(
      o.masterIpv4CidrBlock!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.masterIpv4ReservedRange!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrivateClusterConfig--;
}

core.int buildCounterPrivateEnvironmentConfig = 0;
api.PrivateEnvironmentConfig buildPrivateEnvironmentConfig() {
  var o = api.PrivateEnvironmentConfig();
  buildCounterPrivateEnvironmentConfig++;
  if (buildCounterPrivateEnvironmentConfig < 3) {
    o.cloudSqlIpv4CidrBlock = 'foo';
    o.enablePrivateEnvironment = true;
    o.privateClusterConfig = buildPrivateClusterConfig();
    o.webServerIpv4CidrBlock = 'foo';
    o.webServerIpv4ReservedRange = 'foo';
  }
  buildCounterPrivateEnvironmentConfig--;
  return o;
}

void checkPrivateEnvironmentConfig(api.PrivateEnvironmentConfig o) {
  buildCounterPrivateEnvironmentConfig++;
  if (buildCounterPrivateEnvironmentConfig < 3) {
    unittest.expect(
      o.cloudSqlIpv4CidrBlock!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enablePrivateEnvironment!, unittest.isTrue);
    checkPrivateClusterConfig(
        o.privateClusterConfig! as api.PrivateClusterConfig);
    unittest.expect(
      o.webServerIpv4CidrBlock!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webServerIpv4ReservedRange!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrivateEnvironmentConfig--;
}

core.Map<core.String, core.String> buildUnnamed2379() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2379(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed2380() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2380(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed2381() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2381(core.Map<core.String, core.String> o) {
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

core.int buildCounterSoftwareConfig = 0;
api.SoftwareConfig buildSoftwareConfig() {
  var o = api.SoftwareConfig();
  buildCounterSoftwareConfig++;
  if (buildCounterSoftwareConfig < 3) {
    o.airflowConfigOverrides = buildUnnamed2379();
    o.envVariables = buildUnnamed2380();
    o.imageVersion = 'foo';
    o.pypiPackages = buildUnnamed2381();
    o.pythonVersion = 'foo';
  }
  buildCounterSoftwareConfig--;
  return o;
}

void checkSoftwareConfig(api.SoftwareConfig o) {
  buildCounterSoftwareConfig++;
  if (buildCounterSoftwareConfig < 3) {
    checkUnnamed2379(o.airflowConfigOverrides!);
    checkUnnamed2380(o.envVariables!);
    unittest.expect(
      o.imageVersion!,
      unittest.equals('foo'),
    );
    checkUnnamed2381(o.pypiPackages!);
    unittest.expect(
      o.pythonVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterSoftwareConfig--;
}

core.Map<core.String, core.Object> buildUnnamed2382() {
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

void checkUnnamed2382(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2383() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2382());
  o.add(buildUnnamed2382());
  return o;
}

void checkUnnamed2383(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2382(o[0]);
  checkUnnamed2382(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2383();
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
    checkUnnamed2383(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterWebServerConfig = 0;
api.WebServerConfig buildWebServerConfig() {
  var o = api.WebServerConfig();
  buildCounterWebServerConfig++;
  if (buildCounterWebServerConfig < 3) {
    o.machineType = 'foo';
  }
  buildCounterWebServerConfig--;
  return o;
}

void checkWebServerConfig(api.WebServerConfig o) {
  buildCounterWebServerConfig++;
  if (buildCounterWebServerConfig < 3) {
    unittest.expect(
      o.machineType!,
      unittest.equals('foo'),
    );
  }
  buildCounterWebServerConfig--;
}

core.List<api.AllowedIpRange> buildUnnamed2384() {
  var o = <api.AllowedIpRange>[];
  o.add(buildAllowedIpRange());
  o.add(buildAllowedIpRange());
  return o;
}

void checkUnnamed2384(core.List<api.AllowedIpRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAllowedIpRange(o[0] as api.AllowedIpRange);
  checkAllowedIpRange(o[1] as api.AllowedIpRange);
}

core.int buildCounterWebServerNetworkAccessControl = 0;
api.WebServerNetworkAccessControl buildWebServerNetworkAccessControl() {
  var o = api.WebServerNetworkAccessControl();
  buildCounterWebServerNetworkAccessControl++;
  if (buildCounterWebServerNetworkAccessControl < 3) {
    o.allowedIpRanges = buildUnnamed2384();
  }
  buildCounterWebServerNetworkAccessControl--;
  return o;
}

void checkWebServerNetworkAccessControl(api.WebServerNetworkAccessControl o) {
  buildCounterWebServerNetworkAccessControl++;
  if (buildCounterWebServerNetworkAccessControl < 3) {
    checkUnnamed2384(o.allowedIpRanges!);
  }
  buildCounterWebServerNetworkAccessControl--;
}

void main() {
  unittest.group('obj-schema-AllowedIpRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAllowedIpRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AllowedIpRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAllowedIpRange(od as api.AllowedIpRange);
    });
  });

  unittest.group('obj-schema-DatabaseConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatabaseConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatabaseConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatabaseConfig(od as api.DatabaseConfig);
    });
  });

  unittest.group('obj-schema-Date', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Date.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDate(od as api.Date);
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

  unittest.group('obj-schema-Environment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Environment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironment(od as api.Environment);
    });
  });

  unittest.group('obj-schema-EnvironmentConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironmentConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnvironmentConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironmentConfig(od as api.EnvironmentConfig);
    });
  });

  unittest.group('obj-schema-IPAllocationPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIPAllocationPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IPAllocationPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIPAllocationPolicy(od as api.IPAllocationPolicy);
    });
  });

  unittest.group('obj-schema-ImageVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageVersion(od as api.ImageVersion);
    });
  });

  unittest.group('obj-schema-ListEnvironmentsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListEnvironmentsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListEnvironmentsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListEnvironmentsResponse(od as api.ListEnvironmentsResponse);
    });
  });

  unittest.group('obj-schema-ListImageVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListImageVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListImageVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListImageVersionsResponse(od as api.ListImageVersionsResponse);
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

  unittest.group('obj-schema-NodeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNodeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.NodeConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNodeConfig(od as api.NodeConfig);
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

  unittest.group('obj-schema-PrivateClusterConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrivateClusterConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PrivateClusterConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrivateClusterConfig(od as api.PrivateClusterConfig);
    });
  });

  unittest.group('obj-schema-PrivateEnvironmentConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrivateEnvironmentConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PrivateEnvironmentConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrivateEnvironmentConfig(od as api.PrivateEnvironmentConfig);
    });
  });

  unittest.group('obj-schema-SoftwareConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSoftwareConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SoftwareConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSoftwareConfig(od as api.SoftwareConfig);
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

  unittest.group('obj-schema-WebServerConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebServerConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebServerConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebServerConfig(od as api.WebServerConfig);
    });
  });

  unittest.group('obj-schema-WebServerNetworkAccessControl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebServerNetworkAccessControl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebServerNetworkAccessControl.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebServerNetworkAccessControl(
          od as api.WebServerNetworkAccessControl);
    });
  });

  unittest.group('resource-ProjectsLocationsEnvironmentsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudComposerApi(mock).projects.locations.environments;
      var arg_request = buildEnvironment();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Environment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEnvironment(obj as api.Environment);

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
      var res = api.CloudComposerApi(mock).projects.locations.environments;
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
      var res = api.CloudComposerApi(mock).projects.locations.environments;
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
        var resp = convert.json.encode(buildEnvironment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkEnvironment(response as api.Environment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudComposerApi(mock).projects.locations.environments;
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
        var resp = convert.json.encode(buildListEnvironmentsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListEnvironmentsResponse(response as api.ListEnvironmentsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudComposerApi(mock).projects.locations.environments;
      var arg_request = buildEnvironment();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Environment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEnvironment(obj as api.Environment);

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
  });

  unittest.group('resource-ProjectsLocationsImageVersionsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudComposerApi(mock).projects.locations.imageVersions;
      var arg_parent = 'foo';
      var arg_includePastReleases = true;
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
          queryMap["includePastReleases"]!.first,
          unittest.equals("$arg_includePastReleases"),
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
        var resp = convert.json.encode(buildListImageVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          includePastReleases: arg_includePastReleases,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListImageVersionsResponse(response as api.ListImageVersionsResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudComposerApi(mock).projects.locations.operations;
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
      var res = api.CloudComposerApi(mock).projects.locations.operations;
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
      var res = api.CloudComposerApi(mock).projects.locations.operations;
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
