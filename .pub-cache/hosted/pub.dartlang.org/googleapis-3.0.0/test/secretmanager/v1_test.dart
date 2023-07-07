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

import 'package:googleapis/secretmanager/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccessSecretVersionResponse = 0;
api.AccessSecretVersionResponse buildAccessSecretVersionResponse() {
  var o = api.AccessSecretVersionResponse();
  buildCounterAccessSecretVersionResponse++;
  if (buildCounterAccessSecretVersionResponse < 3) {
    o.name = 'foo';
    o.payload = buildSecretPayload();
  }
  buildCounterAccessSecretVersionResponse--;
  return o;
}

void checkAccessSecretVersionResponse(api.AccessSecretVersionResponse o) {
  buildCounterAccessSecretVersionResponse++;
  if (buildCounterAccessSecretVersionResponse < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSecretPayload(o.payload! as api.SecretPayload);
  }
  buildCounterAccessSecretVersionResponse--;
}

core.int buildCounterAddSecretVersionRequest = 0;
api.AddSecretVersionRequest buildAddSecretVersionRequest() {
  var o = api.AddSecretVersionRequest();
  buildCounterAddSecretVersionRequest++;
  if (buildCounterAddSecretVersionRequest < 3) {
    o.payload = buildSecretPayload();
  }
  buildCounterAddSecretVersionRequest--;
  return o;
}

void checkAddSecretVersionRequest(api.AddSecretVersionRequest o) {
  buildCounterAddSecretVersionRequest++;
  if (buildCounterAddSecretVersionRequest < 3) {
    checkSecretPayload(o.payload! as api.SecretPayload);
  }
  buildCounterAddSecretVersionRequest--;
}

core.List<api.AuditLogConfig> buildUnnamed6144() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed6144(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed6144();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed6144(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed6145() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6145(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed6145();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed6145(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.int buildCounterAutomatic = 0;
api.Automatic buildAutomatic() {
  var o = api.Automatic();
  buildCounterAutomatic++;
  if (buildCounterAutomatic < 3) {
    o.customerManagedEncryption = buildCustomerManagedEncryption();
  }
  buildCounterAutomatic--;
  return o;
}

void checkAutomatic(api.Automatic o) {
  buildCounterAutomatic++;
  if (buildCounterAutomatic < 3) {
    checkCustomerManagedEncryption(
        o.customerManagedEncryption! as api.CustomerManagedEncryption);
  }
  buildCounterAutomatic--;
}

core.int buildCounterAutomaticStatus = 0;
api.AutomaticStatus buildAutomaticStatus() {
  var o = api.AutomaticStatus();
  buildCounterAutomaticStatus++;
  if (buildCounterAutomaticStatus < 3) {
    o.customerManagedEncryption = buildCustomerManagedEncryptionStatus();
  }
  buildCounterAutomaticStatus--;
  return o;
}

void checkAutomaticStatus(api.AutomaticStatus o) {
  buildCounterAutomaticStatus++;
  if (buildCounterAutomaticStatus < 3) {
    checkCustomerManagedEncryptionStatus(
        o.customerManagedEncryption! as api.CustomerManagedEncryptionStatus);
  }
  buildCounterAutomaticStatus--;
}

core.List<core.String> buildUnnamed6146() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6146(core.List<core.String> o) {
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
    o.members = buildUnnamed6146();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed6146(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterCustomerManagedEncryption = 0;
api.CustomerManagedEncryption buildCustomerManagedEncryption() {
  var o = api.CustomerManagedEncryption();
  buildCounterCustomerManagedEncryption++;
  if (buildCounterCustomerManagedEncryption < 3) {
    o.kmsKeyName = 'foo';
  }
  buildCounterCustomerManagedEncryption--;
  return o;
}

void checkCustomerManagedEncryption(api.CustomerManagedEncryption o) {
  buildCounterCustomerManagedEncryption++;
  if (buildCounterCustomerManagedEncryption < 3) {
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerManagedEncryption--;
}

core.int buildCounterCustomerManagedEncryptionStatus = 0;
api.CustomerManagedEncryptionStatus buildCustomerManagedEncryptionStatus() {
  var o = api.CustomerManagedEncryptionStatus();
  buildCounterCustomerManagedEncryptionStatus++;
  if (buildCounterCustomerManagedEncryptionStatus < 3) {
    o.kmsKeyVersionName = 'foo';
  }
  buildCounterCustomerManagedEncryptionStatus--;
  return o;
}

void checkCustomerManagedEncryptionStatus(
    api.CustomerManagedEncryptionStatus o) {
  buildCounterCustomerManagedEncryptionStatus++;
  if (buildCounterCustomerManagedEncryptionStatus < 3) {
    unittest.expect(
      o.kmsKeyVersionName!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerManagedEncryptionStatus--;
}

core.int buildCounterDestroySecretVersionRequest = 0;
api.DestroySecretVersionRequest buildDestroySecretVersionRequest() {
  var o = api.DestroySecretVersionRequest();
  buildCounterDestroySecretVersionRequest++;
  if (buildCounterDestroySecretVersionRequest < 3) {
    o.etag = 'foo';
  }
  buildCounterDestroySecretVersionRequest--;
  return o;
}

void checkDestroySecretVersionRequest(api.DestroySecretVersionRequest o) {
  buildCounterDestroySecretVersionRequest++;
  if (buildCounterDestroySecretVersionRequest < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
  }
  buildCounterDestroySecretVersionRequest--;
}

core.int buildCounterDisableSecretVersionRequest = 0;
api.DisableSecretVersionRequest buildDisableSecretVersionRequest() {
  var o = api.DisableSecretVersionRequest();
  buildCounterDisableSecretVersionRequest++;
  if (buildCounterDisableSecretVersionRequest < 3) {
    o.etag = 'foo';
  }
  buildCounterDisableSecretVersionRequest--;
  return o;
}

void checkDisableSecretVersionRequest(api.DisableSecretVersionRequest o) {
  buildCounterDisableSecretVersionRequest++;
  if (buildCounterDisableSecretVersionRequest < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
  }
  buildCounterDisableSecretVersionRequest--;
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

core.int buildCounterEnableSecretVersionRequest = 0;
api.EnableSecretVersionRequest buildEnableSecretVersionRequest() {
  var o = api.EnableSecretVersionRequest();
  buildCounterEnableSecretVersionRequest++;
  if (buildCounterEnableSecretVersionRequest < 3) {
    o.etag = 'foo';
  }
  buildCounterEnableSecretVersionRequest--;
  return o;
}

void checkEnableSecretVersionRequest(api.EnableSecretVersionRequest o) {
  buildCounterEnableSecretVersionRequest++;
  if (buildCounterEnableSecretVersionRequest < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnableSecretVersionRequest--;
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

core.List<api.Location> buildUnnamed6147() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed6147(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed6147();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed6147(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.SecretVersion> buildUnnamed6148() {
  var o = <api.SecretVersion>[];
  o.add(buildSecretVersion());
  o.add(buildSecretVersion());
  return o;
}

void checkUnnamed6148(core.List<api.SecretVersion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSecretVersion(o[0] as api.SecretVersion);
  checkSecretVersion(o[1] as api.SecretVersion);
}

core.int buildCounterListSecretVersionsResponse = 0;
api.ListSecretVersionsResponse buildListSecretVersionsResponse() {
  var o = api.ListSecretVersionsResponse();
  buildCounterListSecretVersionsResponse++;
  if (buildCounterListSecretVersionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.totalSize = 42;
    o.versions = buildUnnamed6148();
  }
  buildCounterListSecretVersionsResponse--;
  return o;
}

void checkListSecretVersionsResponse(api.ListSecretVersionsResponse o) {
  buildCounterListSecretVersionsResponse++;
  if (buildCounterListSecretVersionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
    checkUnnamed6148(o.versions!);
  }
  buildCounterListSecretVersionsResponse--;
}

core.List<api.Secret> buildUnnamed6149() {
  var o = <api.Secret>[];
  o.add(buildSecret());
  o.add(buildSecret());
  return o;
}

void checkUnnamed6149(core.List<api.Secret> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSecret(o[0] as api.Secret);
  checkSecret(o[1] as api.Secret);
}

core.int buildCounterListSecretsResponse = 0;
api.ListSecretsResponse buildListSecretsResponse() {
  var o = api.ListSecretsResponse();
  buildCounterListSecretsResponse++;
  if (buildCounterListSecretsResponse < 3) {
    o.nextPageToken = 'foo';
    o.secrets = buildUnnamed6149();
    o.totalSize = 42;
  }
  buildCounterListSecretsResponse--;
  return o;
}

void checkListSecretsResponse(api.ListSecretsResponse o) {
  buildCounterListSecretsResponse++;
  if (buildCounterListSecretsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed6149(o.secrets!);
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListSecretsResponse--;
}

core.Map<core.String, core.String> buildUnnamed6150() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6150(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed6151() {
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

void checkUnnamed6151(core.Map<core.String, core.Object> o) {
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
    o.labels = buildUnnamed6150();
    o.locationId = 'foo';
    o.metadata = buildUnnamed6151();
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
    checkUnnamed6150(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed6151(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.List<api.AuditConfig> buildUnnamed6152() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed6152(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed6153() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed6153(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed6152();
    o.bindings = buildUnnamed6153();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed6152(o.auditConfigs!);
    checkUnnamed6153(o.bindings!);
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

core.int buildCounterReplica = 0;
api.Replica buildReplica() {
  var o = api.Replica();
  buildCounterReplica++;
  if (buildCounterReplica < 3) {
    o.customerManagedEncryption = buildCustomerManagedEncryption();
    o.location = 'foo';
  }
  buildCounterReplica--;
  return o;
}

void checkReplica(api.Replica o) {
  buildCounterReplica++;
  if (buildCounterReplica < 3) {
    checkCustomerManagedEncryption(
        o.customerManagedEncryption! as api.CustomerManagedEncryption);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplica--;
}

core.int buildCounterReplicaStatus = 0;
api.ReplicaStatus buildReplicaStatus() {
  var o = api.ReplicaStatus();
  buildCounterReplicaStatus++;
  if (buildCounterReplicaStatus < 3) {
    o.customerManagedEncryption = buildCustomerManagedEncryptionStatus();
    o.location = 'foo';
  }
  buildCounterReplicaStatus--;
  return o;
}

void checkReplicaStatus(api.ReplicaStatus o) {
  buildCounterReplicaStatus++;
  if (buildCounterReplicaStatus < 3) {
    checkCustomerManagedEncryptionStatus(
        o.customerManagedEncryption! as api.CustomerManagedEncryptionStatus);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplicaStatus--;
}

core.int buildCounterReplication = 0;
api.Replication buildReplication() {
  var o = api.Replication();
  buildCounterReplication++;
  if (buildCounterReplication < 3) {
    o.automatic = buildAutomatic();
    o.userManaged = buildUserManaged();
  }
  buildCounterReplication--;
  return o;
}

void checkReplication(api.Replication o) {
  buildCounterReplication++;
  if (buildCounterReplication < 3) {
    checkAutomatic(o.automatic! as api.Automatic);
    checkUserManaged(o.userManaged! as api.UserManaged);
  }
  buildCounterReplication--;
}

core.int buildCounterReplicationStatus = 0;
api.ReplicationStatus buildReplicationStatus() {
  var o = api.ReplicationStatus();
  buildCounterReplicationStatus++;
  if (buildCounterReplicationStatus < 3) {
    o.automatic = buildAutomaticStatus();
    o.userManaged = buildUserManagedStatus();
  }
  buildCounterReplicationStatus--;
  return o;
}

void checkReplicationStatus(api.ReplicationStatus o) {
  buildCounterReplicationStatus++;
  if (buildCounterReplicationStatus < 3) {
    checkAutomaticStatus(o.automatic! as api.AutomaticStatus);
    checkUserManagedStatus(o.userManaged! as api.UserManagedStatus);
  }
  buildCounterReplicationStatus--;
}

core.int buildCounterRotation = 0;
api.Rotation buildRotation() {
  var o = api.Rotation();
  buildCounterRotation++;
  if (buildCounterRotation < 3) {
    o.nextRotationTime = 'foo';
    o.rotationPeriod = 'foo';
  }
  buildCounterRotation--;
  return o;
}

void checkRotation(api.Rotation o) {
  buildCounterRotation++;
  if (buildCounterRotation < 3) {
    unittest.expect(
      o.nextRotationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rotationPeriod!,
      unittest.equals('foo'),
    );
  }
  buildCounterRotation--;
}

core.Map<core.String, core.String> buildUnnamed6154() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6154(core.Map<core.String, core.String> o) {
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

core.List<api.Topic> buildUnnamed6155() {
  var o = <api.Topic>[];
  o.add(buildTopic());
  o.add(buildTopic());
  return o;
}

void checkUnnamed6155(core.List<api.Topic> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTopic(o[0] as api.Topic);
  checkTopic(o[1] as api.Topic);
}

core.int buildCounterSecret = 0;
api.Secret buildSecret() {
  var o = api.Secret();
  buildCounterSecret++;
  if (buildCounterSecret < 3) {
    o.createTime = 'foo';
    o.etag = 'foo';
    o.expireTime = 'foo';
    o.labels = buildUnnamed6154();
    o.name = 'foo';
    o.replication = buildReplication();
    o.rotation = buildRotation();
    o.topics = buildUnnamed6155();
    o.ttl = 'foo';
  }
  buildCounterSecret--;
  return o;
}

void checkSecret(api.Secret o) {
  buildCounterSecret++;
  if (buildCounterSecret < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    checkUnnamed6154(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkReplication(o.replication! as api.Replication);
    checkRotation(o.rotation! as api.Rotation);
    checkUnnamed6155(o.topics!);
    unittest.expect(
      o.ttl!,
      unittest.equals('foo'),
    );
  }
  buildCounterSecret--;
}

core.int buildCounterSecretPayload = 0;
api.SecretPayload buildSecretPayload() {
  var o = api.SecretPayload();
  buildCounterSecretPayload++;
  if (buildCounterSecretPayload < 3) {
    o.data = 'foo';
  }
  buildCounterSecretPayload--;
  return o;
}

void checkSecretPayload(api.SecretPayload o) {
  buildCounterSecretPayload++;
  if (buildCounterSecretPayload < 3) {
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
  }
  buildCounterSecretPayload--;
}

core.int buildCounterSecretVersion = 0;
api.SecretVersion buildSecretVersion() {
  var o = api.SecretVersion();
  buildCounterSecretVersion++;
  if (buildCounterSecretVersion < 3) {
    o.createTime = 'foo';
    o.destroyTime = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.replicationStatus = buildReplicationStatus();
    o.state = 'foo';
  }
  buildCounterSecretVersion--;
  return o;
}

void checkSecretVersion(api.SecretVersion o) {
  buildCounterSecretVersion++;
  if (buildCounterSecretVersion < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destroyTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkReplicationStatus(o.replicationStatus! as api.ReplicationStatus);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterSecretVersion--;
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

core.List<core.String> buildUnnamed6156() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6156(core.List<core.String> o) {
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
    o.permissions = buildUnnamed6156();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed6156(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed6157() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6157(core.List<core.String> o) {
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
    o.permissions = buildUnnamed6157();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed6157(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterTopic = 0;
api.Topic buildTopic() {
  var o = api.Topic();
  buildCounterTopic++;
  if (buildCounterTopic < 3) {
    o.name = 'foo';
  }
  buildCounterTopic--;
  return o;
}

void checkTopic(api.Topic o) {
  buildCounterTopic++;
  if (buildCounterTopic < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterTopic--;
}

core.List<api.Replica> buildUnnamed6158() {
  var o = <api.Replica>[];
  o.add(buildReplica());
  o.add(buildReplica());
  return o;
}

void checkUnnamed6158(core.List<api.Replica> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReplica(o[0] as api.Replica);
  checkReplica(o[1] as api.Replica);
}

core.int buildCounterUserManaged = 0;
api.UserManaged buildUserManaged() {
  var o = api.UserManaged();
  buildCounterUserManaged++;
  if (buildCounterUserManaged < 3) {
    o.replicas = buildUnnamed6158();
  }
  buildCounterUserManaged--;
  return o;
}

void checkUserManaged(api.UserManaged o) {
  buildCounterUserManaged++;
  if (buildCounterUserManaged < 3) {
    checkUnnamed6158(o.replicas!);
  }
  buildCounterUserManaged--;
}

core.List<api.ReplicaStatus> buildUnnamed6159() {
  var o = <api.ReplicaStatus>[];
  o.add(buildReplicaStatus());
  o.add(buildReplicaStatus());
  return o;
}

void checkUnnamed6159(core.List<api.ReplicaStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReplicaStatus(o[0] as api.ReplicaStatus);
  checkReplicaStatus(o[1] as api.ReplicaStatus);
}

core.int buildCounterUserManagedStatus = 0;
api.UserManagedStatus buildUserManagedStatus() {
  var o = api.UserManagedStatus();
  buildCounterUserManagedStatus++;
  if (buildCounterUserManagedStatus < 3) {
    o.replicas = buildUnnamed6159();
  }
  buildCounterUserManagedStatus--;
  return o;
}

void checkUserManagedStatus(api.UserManagedStatus o) {
  buildCounterUserManagedStatus++;
  if (buildCounterUserManagedStatus < 3) {
    checkUnnamed6159(o.replicas!);
  }
  buildCounterUserManagedStatus--;
}

void main() {
  unittest.group('obj-schema-AccessSecretVersionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessSecretVersionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccessSecretVersionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessSecretVersionResponse(od as api.AccessSecretVersionResponse);
    });
  });

  unittest.group('obj-schema-AddSecretVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddSecretVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddSecretVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddSecretVersionRequest(od as api.AddSecretVersionRequest);
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

  unittest.group('obj-schema-Automatic', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutomatic();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Automatic.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAutomatic(od as api.Automatic);
    });
  });

  unittest.group('obj-schema-AutomaticStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutomaticStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AutomaticStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAutomaticStatus(od as api.AutomaticStatus);
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

  unittest.group('obj-schema-CustomerManagedEncryption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerManagedEncryption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerManagedEncryption.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerManagedEncryption(od as api.CustomerManagedEncryption);
    });
  });

  unittest.group('obj-schema-CustomerManagedEncryptionStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerManagedEncryptionStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerManagedEncryptionStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerManagedEncryptionStatus(
          od as api.CustomerManagedEncryptionStatus);
    });
  });

  unittest.group('obj-schema-DestroySecretVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDestroySecretVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DestroySecretVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDestroySecretVersionRequest(od as api.DestroySecretVersionRequest);
    });
  });

  unittest.group('obj-schema-DisableSecretVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDisableSecretVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DisableSecretVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDisableSecretVersionRequest(od as api.DisableSecretVersionRequest);
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

  unittest.group('obj-schema-EnableSecretVersionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnableSecretVersionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnableSecretVersionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnableSecretVersionRequest(od as api.EnableSecretVersionRequest);
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

  unittest.group('obj-schema-ListLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationsResponse(od as api.ListLocationsResponse);
    });
  });

  unittest.group('obj-schema-ListSecretVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSecretVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSecretVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSecretVersionsResponse(od as api.ListSecretVersionsResponse);
    });
  });

  unittest.group('obj-schema-ListSecretsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSecretsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSecretsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSecretsResponse(od as api.ListSecretsResponse);
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

  unittest.group('obj-schema-Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicy(od as api.Policy);
    });
  });

  unittest.group('obj-schema-Replica', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplica();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Replica.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReplica(od as api.Replica);
    });
  });

  unittest.group('obj-schema-ReplicaStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplicaStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplicaStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplicaStatus(od as api.ReplicaStatus);
    });
  });

  unittest.group('obj-schema-Replication', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Replication.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplication(od as api.Replication);
    });
  });

  unittest.group('obj-schema-ReplicationStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplicationStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplicationStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplicationStatus(od as api.ReplicationStatus);
    });
  });

  unittest.group('obj-schema-Rotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Rotation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRotation(od as api.Rotation);
    });
  });

  unittest.group('obj-schema-Secret', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecret();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Secret.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSecret(od as api.Secret);
    });
  });

  unittest.group('obj-schema-SecretPayload', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecretPayload();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SecretPayload.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSecretPayload(od as api.SecretPayload);
    });
  });

  unittest.group('obj-schema-SecretVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSecretVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SecretVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSecretVersion(od as api.SecretVersion);
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

  unittest.group('obj-schema-Topic', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTopic();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Topic.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTopic(od as api.Topic);
    });
  });

  unittest.group('obj-schema-UserManaged', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserManaged();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserManaged.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserManaged(od as api.UserManaged);
    });
  });

  unittest.group('obj-schema-UserManagedStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserManagedStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserManagedStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserManagedStatus(od as api.UserManagedStatus);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.locations;
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
      var res = api.SecretManagerApi(mock).projects.locations;
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

  unittest.group('resource-ProjectsSecretsResource', () {
    unittest.test('method--addVersion', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
      var arg_request = buildAddSecretVersionRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AddSecretVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAddSecretVersionRequest(obj as api.AddSecretVersionRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSecretVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.addVersion(arg_request, arg_parent, $fields: arg_$fields);
      checkSecretVersion(response as api.SecretVersion);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
      var arg_request = buildSecret();
      var arg_parent = 'foo';
      var arg_secretId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Secret.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSecret(obj as api.Secret);

        var path = (req.url).path;
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
          queryMap["secretId"]!.first,
          unittest.equals(arg_secretId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSecret());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          secretId: arg_secretId, $fields: arg_$fields);
      checkSecret(response as api.Secret);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
      var arg_name = 'foo';
      var arg_etag = 'foo';
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
          queryMap["etag"]!.first,
          unittest.equals(arg_etag),
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
      final response =
          await res.delete(arg_name, etag: arg_etag, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
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
        var resp = convert.json.encode(buildSecret());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSecret(response as api.Secret);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
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
      var res = api.SecretManagerApi(mock).projects.secrets;
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
        var resp = convert.json.encode(buildListSecretsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSecretsResponse(response as api.ListSecretsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
      var arg_request = buildSecret();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Secret.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSecret(obj as api.Secret);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSecret());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkSecret(response as api.Secret);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets;
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
      var res = api.SecretManagerApi(mock).projects.secrets;
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

  unittest.group('resource-ProjectsSecretsVersionsResource', () {
    unittest.test('method--access', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets.versions;
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
        var resp = convert.json.encode(buildAccessSecretVersionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.access(arg_name, $fields: arg_$fields);
      checkAccessSecretVersionResponse(
          response as api.AccessSecretVersionResponse);
    });

    unittest.test('method--destroy', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets.versions;
      var arg_request = buildDestroySecretVersionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DestroySecretVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDestroySecretVersionRequest(
            obj as api.DestroySecretVersionRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSecretVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.destroy(arg_request, arg_name, $fields: arg_$fields);
      checkSecretVersion(response as api.SecretVersion);
    });

    unittest.test('method--disable', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets.versions;
      var arg_request = buildDisableSecretVersionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DisableSecretVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDisableSecretVersionRequest(
            obj as api.DisableSecretVersionRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSecretVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.disable(arg_request, arg_name, $fields: arg_$fields);
      checkSecretVersion(response as api.SecretVersion);
    });

    unittest.test('method--enable', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets.versions;
      var arg_request = buildEnableSecretVersionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EnableSecretVersionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEnableSecretVersionRequest(obj as api.EnableSecretVersionRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSecretVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.enable(arg_request, arg_name, $fields: arg_$fields);
      checkSecretVersion(response as api.SecretVersion);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets.versions;
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
        var resp = convert.json.encode(buildSecretVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSecretVersion(response as api.SecretVersion);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.SecretManagerApi(mock).projects.secrets.versions;
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
        var resp = convert.json.encode(buildListSecretVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSecretVersionsResponse(
          response as api.ListSecretVersionsResponse);
    });
  });
}
