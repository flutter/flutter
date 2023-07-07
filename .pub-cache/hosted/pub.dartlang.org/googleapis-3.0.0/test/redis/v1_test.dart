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

import 'package:googleapis/redis/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

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

core.int buildCounterExportInstanceRequest = 0;
api.ExportInstanceRequest buildExportInstanceRequest() {
  var o = api.ExportInstanceRequest();
  buildCounterExportInstanceRequest++;
  if (buildCounterExportInstanceRequest < 3) {
    o.outputConfig = buildOutputConfig();
  }
  buildCounterExportInstanceRequest--;
  return o;
}

void checkExportInstanceRequest(api.ExportInstanceRequest o) {
  buildCounterExportInstanceRequest++;
  if (buildCounterExportInstanceRequest < 3) {
    checkOutputConfig(o.outputConfig! as api.OutputConfig);
  }
  buildCounterExportInstanceRequest--;
}

core.int buildCounterFailoverInstanceRequest = 0;
api.FailoverInstanceRequest buildFailoverInstanceRequest() {
  var o = api.FailoverInstanceRequest();
  buildCounterFailoverInstanceRequest++;
  if (buildCounterFailoverInstanceRequest < 3) {
    o.dataProtectionMode = 'foo';
  }
  buildCounterFailoverInstanceRequest--;
  return o;
}

void checkFailoverInstanceRequest(api.FailoverInstanceRequest o) {
  buildCounterFailoverInstanceRequest++;
  if (buildCounterFailoverInstanceRequest < 3) {
    unittest.expect(
      o.dataProtectionMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterFailoverInstanceRequest--;
}

core.int buildCounterGcsDestination = 0;
api.GcsDestination buildGcsDestination() {
  var o = api.GcsDestination();
  buildCounterGcsDestination++;
  if (buildCounterGcsDestination < 3) {
    o.uri = 'foo';
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
  }
  buildCounterGcsDestination--;
}

core.int buildCounterGcsSource = 0;
api.GcsSource buildGcsSource() {
  var o = api.GcsSource();
  buildCounterGcsSource++;
  if (buildCounterGcsSource < 3) {
    o.uri = 'foo';
  }
  buildCounterGcsSource--;
  return o;
}

void checkGcsSource(api.GcsSource o) {
  buildCounterGcsSource++;
  if (buildCounterGcsSource < 3) {
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterGcsSource--;
}

core.Map<core.String, api.GoogleCloudRedisV1ZoneMetadata> buildUnnamed2898() {
  var o = <core.String, api.GoogleCloudRedisV1ZoneMetadata>{};
  o['x'] = buildGoogleCloudRedisV1ZoneMetadata();
  o['y'] = buildGoogleCloudRedisV1ZoneMetadata();
  return o;
}

void checkUnnamed2898(
    core.Map<core.String, api.GoogleCloudRedisV1ZoneMetadata> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudRedisV1ZoneMetadata(
      o['x']! as api.GoogleCloudRedisV1ZoneMetadata);
  checkGoogleCloudRedisV1ZoneMetadata(
      o['y']! as api.GoogleCloudRedisV1ZoneMetadata);
}

core.int buildCounterGoogleCloudRedisV1LocationMetadata = 0;
api.GoogleCloudRedisV1LocationMetadata
    buildGoogleCloudRedisV1LocationMetadata() {
  var o = api.GoogleCloudRedisV1LocationMetadata();
  buildCounterGoogleCloudRedisV1LocationMetadata++;
  if (buildCounterGoogleCloudRedisV1LocationMetadata < 3) {
    o.availableZones = buildUnnamed2898();
  }
  buildCounterGoogleCloudRedisV1LocationMetadata--;
  return o;
}

void checkGoogleCloudRedisV1LocationMetadata(
    api.GoogleCloudRedisV1LocationMetadata o) {
  buildCounterGoogleCloudRedisV1LocationMetadata++;
  if (buildCounterGoogleCloudRedisV1LocationMetadata < 3) {
    checkUnnamed2898(o.availableZones!);
  }
  buildCounterGoogleCloudRedisV1LocationMetadata--;
}

core.int buildCounterGoogleCloudRedisV1OperationMetadata = 0;
api.GoogleCloudRedisV1OperationMetadata
    buildGoogleCloudRedisV1OperationMetadata() {
  var o = api.GoogleCloudRedisV1OperationMetadata();
  buildCounterGoogleCloudRedisV1OperationMetadata++;
  if (buildCounterGoogleCloudRedisV1OperationMetadata < 3) {
    o.apiVersion = 'foo';
    o.cancelRequested = true;
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.statusDetail = 'foo';
    o.target = 'foo';
    o.verb = 'foo';
  }
  buildCounterGoogleCloudRedisV1OperationMetadata--;
  return o;
}

void checkGoogleCloudRedisV1OperationMetadata(
    api.GoogleCloudRedisV1OperationMetadata o) {
  buildCounterGoogleCloudRedisV1OperationMetadata++;
  if (buildCounterGoogleCloudRedisV1OperationMetadata < 3) {
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
  buildCounterGoogleCloudRedisV1OperationMetadata--;
}

core.int buildCounterGoogleCloudRedisV1ZoneMetadata = 0;
api.GoogleCloudRedisV1ZoneMetadata buildGoogleCloudRedisV1ZoneMetadata() {
  var o = api.GoogleCloudRedisV1ZoneMetadata();
  buildCounterGoogleCloudRedisV1ZoneMetadata++;
  if (buildCounterGoogleCloudRedisV1ZoneMetadata < 3) {}
  buildCounterGoogleCloudRedisV1ZoneMetadata--;
  return o;
}

void checkGoogleCloudRedisV1ZoneMetadata(api.GoogleCloudRedisV1ZoneMetadata o) {
  buildCounterGoogleCloudRedisV1ZoneMetadata++;
  if (buildCounterGoogleCloudRedisV1ZoneMetadata < 3) {}
  buildCounterGoogleCloudRedisV1ZoneMetadata--;
}

core.int buildCounterImportInstanceRequest = 0;
api.ImportInstanceRequest buildImportInstanceRequest() {
  var o = api.ImportInstanceRequest();
  buildCounterImportInstanceRequest++;
  if (buildCounterImportInstanceRequest < 3) {
    o.inputConfig = buildInputConfig();
  }
  buildCounterImportInstanceRequest--;
  return o;
}

void checkImportInstanceRequest(api.ImportInstanceRequest o) {
  buildCounterImportInstanceRequest++;
  if (buildCounterImportInstanceRequest < 3) {
    checkInputConfig(o.inputConfig! as api.InputConfig);
  }
  buildCounterImportInstanceRequest--;
}

core.int buildCounterInputConfig = 0;
api.InputConfig buildInputConfig() {
  var o = api.InputConfig();
  buildCounterInputConfig++;
  if (buildCounterInputConfig < 3) {
    o.gcsSource = buildGcsSource();
  }
  buildCounterInputConfig--;
  return o;
}

void checkInputConfig(api.InputConfig o) {
  buildCounterInputConfig++;
  if (buildCounterInputConfig < 3) {
    checkGcsSource(o.gcsSource! as api.GcsSource);
  }
  buildCounterInputConfig--;
}

core.Map<core.String, core.String> buildUnnamed2899() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2899(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed2900() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2900(core.Map<core.String, core.String> o) {
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

core.List<api.TlsCertificate> buildUnnamed2901() {
  var o = <api.TlsCertificate>[];
  o.add(buildTlsCertificate());
  o.add(buildTlsCertificate());
  return o;
}

void checkUnnamed2901(core.List<api.TlsCertificate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTlsCertificate(o[0] as api.TlsCertificate);
  checkTlsCertificate(o[1] as api.TlsCertificate);
}

core.int buildCounterInstance = 0;
api.Instance buildInstance() {
  var o = api.Instance();
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    o.alternativeLocationId = 'foo';
    o.authEnabled = true;
    o.authorizedNetwork = 'foo';
    o.connectMode = 'foo';
    o.createTime = 'foo';
    o.currentLocationId = 'foo';
    o.displayName = 'foo';
    o.host = 'foo';
    o.labels = buildUnnamed2899();
    o.locationId = 'foo';
    o.memorySizeGb = 42;
    o.name = 'foo';
    o.persistenceIamIdentity = 'foo';
    o.port = 42;
    o.redisConfigs = buildUnnamed2900();
    o.redisVersion = 'foo';
    o.reservedIpRange = 'foo';
    o.serverCaCerts = buildUnnamed2901();
    o.state = 'foo';
    o.statusMessage = 'foo';
    o.tier = 'foo';
    o.transitEncryptionMode = 'foo';
  }
  buildCounterInstance--;
  return o;
}

void checkInstance(api.Instance o) {
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    unittest.expect(
      o.alternativeLocationId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.authEnabled!, unittest.isTrue);
    unittest.expect(
      o.authorizedNetwork!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.connectMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currentLocationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    checkUnnamed2899(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memorySizeGb!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.persistenceIamIdentity!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.port!,
      unittest.equals(42),
    );
    checkUnnamed2900(o.redisConfigs!);
    unittest.expect(
      o.redisVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reservedIpRange!,
      unittest.equals('foo'),
    );
    checkUnnamed2901(o.serverCaCerts!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statusMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transitEncryptionMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterInstance--;
}

core.int buildCounterInstanceAuthString = 0;
api.InstanceAuthString buildInstanceAuthString() {
  var o = api.InstanceAuthString();
  buildCounterInstanceAuthString++;
  if (buildCounterInstanceAuthString < 3) {
    o.authString = 'foo';
  }
  buildCounterInstanceAuthString--;
  return o;
}

void checkInstanceAuthString(api.InstanceAuthString o) {
  buildCounterInstanceAuthString++;
  if (buildCounterInstanceAuthString < 3) {
    unittest.expect(
      o.authString!,
      unittest.equals('foo'),
    );
  }
  buildCounterInstanceAuthString--;
}

core.List<api.Instance> buildUnnamed2902() {
  var o = <api.Instance>[];
  o.add(buildInstance());
  o.add(buildInstance());
  return o;
}

void checkUnnamed2902(core.List<api.Instance> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInstance(o[0] as api.Instance);
  checkInstance(o[1] as api.Instance);
}

core.List<core.String> buildUnnamed2903() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2903(core.List<core.String> o) {
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
    o.instances = buildUnnamed2902();
    o.nextPageToken = 'foo';
    o.unreachable = buildUnnamed2903();
  }
  buildCounterListInstancesResponse--;
  return o;
}

void checkListInstancesResponse(api.ListInstancesResponse o) {
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    checkUnnamed2902(o.instances!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2903(o.unreachable!);
  }
  buildCounterListInstancesResponse--;
}

core.List<api.Location> buildUnnamed2904() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed2904(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed2904();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed2904(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Operation> buildUnnamed2905() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed2905(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed2905();
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
    checkUnnamed2905(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.Map<core.String, core.String> buildUnnamed2906() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2906(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed2907() {
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

void checkUnnamed2907(core.Map<core.String, core.Object> o) {
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
    o.labels = buildUnnamed2906();
    o.locationId = 'foo';
    o.metadata = buildUnnamed2907();
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
    checkUnnamed2906(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed2907(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.Map<core.String, core.Object> buildUnnamed2908() {
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

void checkUnnamed2908(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed2909() {
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

void checkUnnamed2909(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed2908();
    o.name = 'foo';
    o.response = buildUnnamed2909();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed2908(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2909(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOutputConfig = 0;
api.OutputConfig buildOutputConfig() {
  var o = api.OutputConfig();
  buildCounterOutputConfig++;
  if (buildCounterOutputConfig < 3) {
    o.gcsDestination = buildGcsDestination();
  }
  buildCounterOutputConfig--;
  return o;
}

void checkOutputConfig(api.OutputConfig o) {
  buildCounterOutputConfig++;
  if (buildCounterOutputConfig < 3) {
    checkGcsDestination(o.gcsDestination! as api.GcsDestination);
  }
  buildCounterOutputConfig--;
}

core.Map<core.String, core.Object> buildUnnamed2910() {
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

void checkUnnamed2910(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed2911() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed2910());
  o.add(buildUnnamed2910());
  return o;
}

void checkUnnamed2911(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed2910(o[0]);
  checkUnnamed2910(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed2911();
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
    checkUnnamed2911(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTlsCertificate = 0;
api.TlsCertificate buildTlsCertificate() {
  var o = api.TlsCertificate();
  buildCounterTlsCertificate++;
  if (buildCounterTlsCertificate < 3) {
    o.cert = 'foo';
    o.createTime = 'foo';
    o.expireTime = 'foo';
    o.serialNumber = 'foo';
    o.sha1Fingerprint = 'foo';
  }
  buildCounterTlsCertificate--;
  return o;
}

void checkTlsCertificate(api.TlsCertificate o) {
  buildCounterTlsCertificate++;
  if (buildCounterTlsCertificate < 3) {
    unittest.expect(
      o.cert!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serialNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha1Fingerprint!,
      unittest.equals('foo'),
    );
  }
  buildCounterTlsCertificate--;
}

core.int buildCounterUpgradeInstanceRequest = 0;
api.UpgradeInstanceRequest buildUpgradeInstanceRequest() {
  var o = api.UpgradeInstanceRequest();
  buildCounterUpgradeInstanceRequest++;
  if (buildCounterUpgradeInstanceRequest < 3) {
    o.redisVersion = 'foo';
  }
  buildCounterUpgradeInstanceRequest--;
  return o;
}

void checkUpgradeInstanceRequest(api.UpgradeInstanceRequest o) {
  buildCounterUpgradeInstanceRequest++;
  if (buildCounterUpgradeInstanceRequest < 3) {
    unittest.expect(
      o.redisVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpgradeInstanceRequest--;
}

void main() {
  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-ExportInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExportInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExportInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExportInstanceRequest(od as api.ExportInstanceRequest);
    });
  });

  unittest.group('obj-schema-FailoverInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFailoverInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FailoverInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFailoverInstanceRequest(od as api.FailoverInstanceRequest);
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

  unittest.group('obj-schema-GcsSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGcsSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GcsSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGcsSource(od as api.GcsSource);
    });
  });

  unittest.group('obj-schema-GoogleCloudRedisV1LocationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRedisV1LocationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRedisV1LocationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRedisV1LocationMetadata(
          od as api.GoogleCloudRedisV1LocationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleCloudRedisV1OperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRedisV1OperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRedisV1OperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRedisV1OperationMetadata(
          od as api.GoogleCloudRedisV1OperationMetadata);
    });
  });

  unittest.group('obj-schema-GoogleCloudRedisV1ZoneMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudRedisV1ZoneMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudRedisV1ZoneMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudRedisV1ZoneMetadata(
          od as api.GoogleCloudRedisV1ZoneMetadata);
    });
  });

  unittest.group('obj-schema-ImportInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImportInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImportInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImportInstanceRequest(od as api.ImportInstanceRequest);
    });
  });

  unittest.group('obj-schema-InputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInputConfig(od as api.InputConfig);
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

  unittest.group('obj-schema-InstanceAuthString', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstanceAuthString();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InstanceAuthString.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInstanceAuthString(od as api.InstanceAuthString);
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

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
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

  unittest.group('obj-schema-OutputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOutputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OutputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOutputConfig(od as api.OutputConfig);
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

  unittest.group('obj-schema-TlsCertificate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTlsCertificate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TlsCertificate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTlsCertificate(od as api.TlsCertificate);
    });
  });

  unittest.group('obj-schema-UpgradeInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpgradeInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpgradeInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpgradeInstanceRequest(od as api.UpgradeInstanceRequest);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations;
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
      var res = api.CloudRedisApi(mock).projects.locations;
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

  unittest.group('resource-ProjectsLocationsInstancesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
      var arg_request = buildInstance();
      var arg_parent = 'foo';
      var arg_instanceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Instance.fromJson(json as core.Map<core.String, core.dynamic>);
        checkInstance(obj as api.Instance);

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
          queryMap["instanceId"]!.first,
          unittest.equals(arg_instanceId),
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
          instanceId: arg_instanceId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
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

    unittest.test('method--export', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
      var arg_request = buildExportInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ExportInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExportInstanceRequest(obj as api.ExportInstanceRequest);

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
          await res.export(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--failover', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
      var arg_request = buildFailoverInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FailoverInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFailoverInstanceRequest(obj as api.FailoverInstanceRequest);

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
          await res.failover(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildInstance());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkInstance(response as api.Instance);
    });

    unittest.test('method--getAuthString', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildInstanceAuthString());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getAuthString(arg_name, $fields: arg_$fields);
      checkInstanceAuthString(response as api.InstanceAuthString);
    });

    unittest.test('method--import', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
      var arg_request = buildImportInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ImportInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkImportInstanceRequest(obj as api.ImportInstanceRequest);

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
          await res.import(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
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
        var resp = convert.json.encode(buildListInstancesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInstancesResponse(response as api.ListInstancesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
      var arg_request = buildInstance();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Instance.fromJson(json as core.Map<core.String, core.dynamic>);
        checkInstance(obj as api.Instance);

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

    unittest.test('method--upgrade', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.instances;
      var arg_request = buildUpgradeInstanceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpgradeInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpgradeInstanceRequest(obj as api.UpgradeInstanceRequest);

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
          await res.upgrade(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.CloudRedisApi(mock).projects.locations.operations;
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
      var res = api.CloudRedisApi(mock).projects.locations.operations;
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
      var res = api.CloudRedisApi(mock).projects.locations.operations;
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
      var res = api.CloudRedisApi(mock).projects.locations.operations;
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
