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

import 'package:googleapis/dns/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.ResourceRecordSet> buildUnnamed2159() {
  var o = <api.ResourceRecordSet>[];
  o.add(buildResourceRecordSet());
  o.add(buildResourceRecordSet());
  return o;
}

void checkUnnamed2159(core.List<api.ResourceRecordSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceRecordSet(o[0] as api.ResourceRecordSet);
  checkResourceRecordSet(o[1] as api.ResourceRecordSet);
}

core.List<api.ResourceRecordSet> buildUnnamed2160() {
  var o = <api.ResourceRecordSet>[];
  o.add(buildResourceRecordSet());
  o.add(buildResourceRecordSet());
  return o;
}

void checkUnnamed2160(core.List<api.ResourceRecordSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceRecordSet(o[0] as api.ResourceRecordSet);
  checkResourceRecordSet(o[1] as api.ResourceRecordSet);
}

core.int buildCounterChange = 0;
api.Change buildChange() {
  var o = api.Change();
  buildCounterChange++;
  if (buildCounterChange < 3) {
    o.additions = buildUnnamed2159();
    o.deletions = buildUnnamed2160();
    o.id = 'foo';
    o.isServing = true;
    o.kind = 'foo';
    o.startTime = 'foo';
    o.status = 'foo';
  }
  buildCounterChange--;
  return o;
}

void checkChange(api.Change o) {
  buildCounterChange++;
  if (buildCounterChange < 3) {
    checkUnnamed2159(o.additions!);
    checkUnnamed2160(o.deletions!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isServing!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterChange--;
}

core.List<api.Change> buildUnnamed2161() {
  var o = <api.Change>[];
  o.add(buildChange());
  o.add(buildChange());
  return o;
}

void checkUnnamed2161(core.List<api.Change> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChange(o[0] as api.Change);
  checkChange(o[1] as api.Change);
}

core.int buildCounterChangesListResponse = 0;
api.ChangesListResponse buildChangesListResponse() {
  var o = api.ChangesListResponse();
  buildCounterChangesListResponse++;
  if (buildCounterChangesListResponse < 3) {
    o.changes = buildUnnamed2161();
    o.header = buildResponseHeader();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterChangesListResponse--;
  return o;
}

void checkChangesListResponse(api.ChangesListResponse o) {
  buildCounterChangesListResponse++;
  if (buildCounterChangesListResponse < 3) {
    checkUnnamed2161(o.changes!);
    checkResponseHeader(o.header! as api.ResponseHeader);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterChangesListResponse--;
}

core.List<api.DnsKeyDigest> buildUnnamed2162() {
  var o = <api.DnsKeyDigest>[];
  o.add(buildDnsKeyDigest());
  o.add(buildDnsKeyDigest());
  return o;
}

void checkUnnamed2162(core.List<api.DnsKeyDigest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDnsKeyDigest(o[0] as api.DnsKeyDigest);
  checkDnsKeyDigest(o[1] as api.DnsKeyDigest);
}

core.int buildCounterDnsKey = 0;
api.DnsKey buildDnsKey() {
  var o = api.DnsKey();
  buildCounterDnsKey++;
  if (buildCounterDnsKey < 3) {
    o.algorithm = 'foo';
    o.creationTime = 'foo';
    o.description = 'foo';
    o.digests = buildUnnamed2162();
    o.id = 'foo';
    o.isActive = true;
    o.keyLength = 42;
    o.keyTag = 42;
    o.kind = 'foo';
    o.publicKey = 'foo';
    o.type = 'foo';
  }
  buildCounterDnsKey--;
  return o;
}

void checkDnsKey(api.DnsKey o) {
  buildCounterDnsKey++;
  if (buildCounterDnsKey < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed2162(o.digests!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isActive!, unittest.isTrue);
    unittest.expect(
      o.keyLength!,
      unittest.equals(42),
    );
    unittest.expect(
      o.keyTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDnsKey--;
}

core.int buildCounterDnsKeyDigest = 0;
api.DnsKeyDigest buildDnsKeyDigest() {
  var o = api.DnsKeyDigest();
  buildCounterDnsKeyDigest++;
  if (buildCounterDnsKeyDigest < 3) {
    o.digest = 'foo';
    o.type = 'foo';
  }
  buildCounterDnsKeyDigest--;
  return o;
}

void checkDnsKeyDigest(api.DnsKeyDigest o) {
  buildCounterDnsKeyDigest++;
  if (buildCounterDnsKeyDigest < 3) {
    unittest.expect(
      o.digest!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDnsKeyDigest--;
}

core.int buildCounterDnsKeySpec = 0;
api.DnsKeySpec buildDnsKeySpec() {
  var o = api.DnsKeySpec();
  buildCounterDnsKeySpec++;
  if (buildCounterDnsKeySpec < 3) {
    o.algorithm = 'foo';
    o.keyLength = 42;
    o.keyType = 'foo';
    o.kind = 'foo';
  }
  buildCounterDnsKeySpec--;
  return o;
}

void checkDnsKeySpec(api.DnsKeySpec o) {
  buildCounterDnsKeySpec++;
  if (buildCounterDnsKeySpec < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.keyLength!,
      unittest.equals(42),
    );
    unittest.expect(
      o.keyType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterDnsKeySpec--;
}

core.List<api.DnsKey> buildUnnamed2163() {
  var o = <api.DnsKey>[];
  o.add(buildDnsKey());
  o.add(buildDnsKey());
  return o;
}

void checkUnnamed2163(core.List<api.DnsKey> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDnsKey(o[0] as api.DnsKey);
  checkDnsKey(o[1] as api.DnsKey);
}

core.int buildCounterDnsKeysListResponse = 0;
api.DnsKeysListResponse buildDnsKeysListResponse() {
  var o = api.DnsKeysListResponse();
  buildCounterDnsKeysListResponse++;
  if (buildCounterDnsKeysListResponse < 3) {
    o.dnsKeys = buildUnnamed2163();
    o.header = buildResponseHeader();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterDnsKeysListResponse--;
  return o;
}

void checkDnsKeysListResponse(api.DnsKeysListResponse o) {
  buildCounterDnsKeysListResponse++;
  if (buildCounterDnsKeysListResponse < 3) {
    checkUnnamed2163(o.dnsKeys!);
    checkResponseHeader(o.header! as api.ResponseHeader);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterDnsKeysListResponse--;
}

core.Map<core.String, core.String> buildUnnamed2164() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed2164(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed2165() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2165(core.List<core.String> o) {
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

core.int buildCounterManagedZone = 0;
api.ManagedZone buildManagedZone() {
  var o = api.ManagedZone();
  buildCounterManagedZone++;
  if (buildCounterManagedZone < 3) {
    o.creationTime = 'foo';
    o.description = 'foo';
    o.dnsName = 'foo';
    o.dnssecConfig = buildManagedZoneDnsSecConfig();
    o.forwardingConfig = buildManagedZoneForwardingConfig();
    o.id = 'foo';
    o.kind = 'foo';
    o.labels = buildUnnamed2164();
    o.name = 'foo';
    o.nameServerSet = 'foo';
    o.nameServers = buildUnnamed2165();
    o.peeringConfig = buildManagedZonePeeringConfig();
    o.privateVisibilityConfig = buildManagedZonePrivateVisibilityConfig();
    o.reverseLookupConfig = buildManagedZoneReverseLookupConfig();
    o.serviceDirectoryConfig = buildManagedZoneServiceDirectoryConfig();
    o.visibility = 'foo';
  }
  buildCounterManagedZone--;
  return o;
}

void checkManagedZone(api.ManagedZone o) {
  buildCounterManagedZone++;
  if (buildCounterManagedZone < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dnsName!,
      unittest.equals('foo'),
    );
    checkManagedZoneDnsSecConfig(
        o.dnssecConfig! as api.ManagedZoneDnsSecConfig);
    checkManagedZoneForwardingConfig(
        o.forwardingConfig! as api.ManagedZoneForwardingConfig);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2164(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nameServerSet!,
      unittest.equals('foo'),
    );
    checkUnnamed2165(o.nameServers!);
    checkManagedZonePeeringConfig(
        o.peeringConfig! as api.ManagedZonePeeringConfig);
    checkManagedZonePrivateVisibilityConfig(
        o.privateVisibilityConfig! as api.ManagedZonePrivateVisibilityConfig);
    checkManagedZoneReverseLookupConfig(
        o.reverseLookupConfig! as api.ManagedZoneReverseLookupConfig);
    checkManagedZoneServiceDirectoryConfig(
        o.serviceDirectoryConfig! as api.ManagedZoneServiceDirectoryConfig);
    unittest.expect(
      o.visibility!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZone--;
}

core.List<api.DnsKeySpec> buildUnnamed2166() {
  var o = <api.DnsKeySpec>[];
  o.add(buildDnsKeySpec());
  o.add(buildDnsKeySpec());
  return o;
}

void checkUnnamed2166(core.List<api.DnsKeySpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDnsKeySpec(o[0] as api.DnsKeySpec);
  checkDnsKeySpec(o[1] as api.DnsKeySpec);
}

core.int buildCounterManagedZoneDnsSecConfig = 0;
api.ManagedZoneDnsSecConfig buildManagedZoneDnsSecConfig() {
  var o = api.ManagedZoneDnsSecConfig();
  buildCounterManagedZoneDnsSecConfig++;
  if (buildCounterManagedZoneDnsSecConfig < 3) {
    o.defaultKeySpecs = buildUnnamed2166();
    o.kind = 'foo';
    o.nonExistence = 'foo';
    o.state = 'foo';
  }
  buildCounterManagedZoneDnsSecConfig--;
  return o;
}

void checkManagedZoneDnsSecConfig(api.ManagedZoneDnsSecConfig o) {
  buildCounterManagedZoneDnsSecConfig++;
  if (buildCounterManagedZoneDnsSecConfig < 3) {
    checkUnnamed2166(o.defaultKeySpecs!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nonExistence!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZoneDnsSecConfig--;
}

core.List<api.ManagedZoneForwardingConfigNameServerTarget> buildUnnamed2167() {
  var o = <api.ManagedZoneForwardingConfigNameServerTarget>[];
  o.add(buildManagedZoneForwardingConfigNameServerTarget());
  o.add(buildManagedZoneForwardingConfigNameServerTarget());
  return o;
}

void checkUnnamed2167(
    core.List<api.ManagedZoneForwardingConfigNameServerTarget> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkManagedZoneForwardingConfigNameServerTarget(
      o[0] as api.ManagedZoneForwardingConfigNameServerTarget);
  checkManagedZoneForwardingConfigNameServerTarget(
      o[1] as api.ManagedZoneForwardingConfigNameServerTarget);
}

core.int buildCounterManagedZoneForwardingConfig = 0;
api.ManagedZoneForwardingConfig buildManagedZoneForwardingConfig() {
  var o = api.ManagedZoneForwardingConfig();
  buildCounterManagedZoneForwardingConfig++;
  if (buildCounterManagedZoneForwardingConfig < 3) {
    o.kind = 'foo';
    o.targetNameServers = buildUnnamed2167();
  }
  buildCounterManagedZoneForwardingConfig--;
  return o;
}

void checkManagedZoneForwardingConfig(api.ManagedZoneForwardingConfig o) {
  buildCounterManagedZoneForwardingConfig++;
  if (buildCounterManagedZoneForwardingConfig < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2167(o.targetNameServers!);
  }
  buildCounterManagedZoneForwardingConfig--;
}

core.int buildCounterManagedZoneForwardingConfigNameServerTarget = 0;
api.ManagedZoneForwardingConfigNameServerTarget
    buildManagedZoneForwardingConfigNameServerTarget() {
  var o = api.ManagedZoneForwardingConfigNameServerTarget();
  buildCounterManagedZoneForwardingConfigNameServerTarget++;
  if (buildCounterManagedZoneForwardingConfigNameServerTarget < 3) {
    o.forwardingPath = 'foo';
    o.ipv4Address = 'foo';
    o.kind = 'foo';
  }
  buildCounterManagedZoneForwardingConfigNameServerTarget--;
  return o;
}

void checkManagedZoneForwardingConfigNameServerTarget(
    api.ManagedZoneForwardingConfigNameServerTarget o) {
  buildCounterManagedZoneForwardingConfigNameServerTarget++;
  if (buildCounterManagedZoneForwardingConfigNameServerTarget < 3) {
    unittest.expect(
      o.forwardingPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ipv4Address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZoneForwardingConfigNameServerTarget--;
}

core.List<api.Operation> buildUnnamed2168() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed2168(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterManagedZoneOperationsListResponse = 0;
api.ManagedZoneOperationsListResponse buildManagedZoneOperationsListResponse() {
  var o = api.ManagedZoneOperationsListResponse();
  buildCounterManagedZoneOperationsListResponse++;
  if (buildCounterManagedZoneOperationsListResponse < 3) {
    o.header = buildResponseHeader();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed2168();
  }
  buildCounterManagedZoneOperationsListResponse--;
  return o;
}

void checkManagedZoneOperationsListResponse(
    api.ManagedZoneOperationsListResponse o) {
  buildCounterManagedZoneOperationsListResponse++;
  if (buildCounterManagedZoneOperationsListResponse < 3) {
    checkResponseHeader(o.header! as api.ResponseHeader);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2168(o.operations!);
  }
  buildCounterManagedZoneOperationsListResponse--;
}

core.int buildCounterManagedZonePeeringConfig = 0;
api.ManagedZonePeeringConfig buildManagedZonePeeringConfig() {
  var o = api.ManagedZonePeeringConfig();
  buildCounterManagedZonePeeringConfig++;
  if (buildCounterManagedZonePeeringConfig < 3) {
    o.kind = 'foo';
    o.targetNetwork = buildManagedZonePeeringConfigTargetNetwork();
  }
  buildCounterManagedZonePeeringConfig--;
  return o;
}

void checkManagedZonePeeringConfig(api.ManagedZonePeeringConfig o) {
  buildCounterManagedZonePeeringConfig++;
  if (buildCounterManagedZonePeeringConfig < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkManagedZonePeeringConfigTargetNetwork(
        o.targetNetwork! as api.ManagedZonePeeringConfigTargetNetwork);
  }
  buildCounterManagedZonePeeringConfig--;
}

core.int buildCounterManagedZonePeeringConfigTargetNetwork = 0;
api.ManagedZonePeeringConfigTargetNetwork
    buildManagedZonePeeringConfigTargetNetwork() {
  var o = api.ManagedZonePeeringConfigTargetNetwork();
  buildCounterManagedZonePeeringConfigTargetNetwork++;
  if (buildCounterManagedZonePeeringConfigTargetNetwork < 3) {
    o.deactivateTime = 'foo';
    o.kind = 'foo';
    o.networkUrl = 'foo';
  }
  buildCounterManagedZonePeeringConfigTargetNetwork--;
  return o;
}

void checkManagedZonePeeringConfigTargetNetwork(
    api.ManagedZonePeeringConfigTargetNetwork o) {
  buildCounterManagedZonePeeringConfigTargetNetwork++;
  if (buildCounterManagedZonePeeringConfigTargetNetwork < 3) {
    unittest.expect(
      o.deactivateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZonePeeringConfigTargetNetwork--;
}

core.List<api.ManagedZonePrivateVisibilityConfigNetwork> buildUnnamed2169() {
  var o = <api.ManagedZonePrivateVisibilityConfigNetwork>[];
  o.add(buildManagedZonePrivateVisibilityConfigNetwork());
  o.add(buildManagedZonePrivateVisibilityConfigNetwork());
  return o;
}

void checkUnnamed2169(
    core.List<api.ManagedZonePrivateVisibilityConfigNetwork> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkManagedZonePrivateVisibilityConfigNetwork(
      o[0] as api.ManagedZonePrivateVisibilityConfigNetwork);
  checkManagedZonePrivateVisibilityConfigNetwork(
      o[1] as api.ManagedZonePrivateVisibilityConfigNetwork);
}

core.int buildCounterManagedZonePrivateVisibilityConfig = 0;
api.ManagedZonePrivateVisibilityConfig
    buildManagedZonePrivateVisibilityConfig() {
  var o = api.ManagedZonePrivateVisibilityConfig();
  buildCounterManagedZonePrivateVisibilityConfig++;
  if (buildCounterManagedZonePrivateVisibilityConfig < 3) {
    o.kind = 'foo';
    o.networks = buildUnnamed2169();
  }
  buildCounterManagedZonePrivateVisibilityConfig--;
  return o;
}

void checkManagedZonePrivateVisibilityConfig(
    api.ManagedZonePrivateVisibilityConfig o) {
  buildCounterManagedZonePrivateVisibilityConfig++;
  if (buildCounterManagedZonePrivateVisibilityConfig < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2169(o.networks!);
  }
  buildCounterManagedZonePrivateVisibilityConfig--;
}

core.int buildCounterManagedZonePrivateVisibilityConfigNetwork = 0;
api.ManagedZonePrivateVisibilityConfigNetwork
    buildManagedZonePrivateVisibilityConfigNetwork() {
  var o = api.ManagedZonePrivateVisibilityConfigNetwork();
  buildCounterManagedZonePrivateVisibilityConfigNetwork++;
  if (buildCounterManagedZonePrivateVisibilityConfigNetwork < 3) {
    o.kind = 'foo';
    o.networkUrl = 'foo';
  }
  buildCounterManagedZonePrivateVisibilityConfigNetwork--;
  return o;
}

void checkManagedZonePrivateVisibilityConfigNetwork(
    api.ManagedZonePrivateVisibilityConfigNetwork o) {
  buildCounterManagedZonePrivateVisibilityConfigNetwork++;
  if (buildCounterManagedZonePrivateVisibilityConfigNetwork < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZonePrivateVisibilityConfigNetwork--;
}

core.int buildCounterManagedZoneReverseLookupConfig = 0;
api.ManagedZoneReverseLookupConfig buildManagedZoneReverseLookupConfig() {
  var o = api.ManagedZoneReverseLookupConfig();
  buildCounterManagedZoneReverseLookupConfig++;
  if (buildCounterManagedZoneReverseLookupConfig < 3) {
    o.kind = 'foo';
  }
  buildCounterManagedZoneReverseLookupConfig--;
  return o;
}

void checkManagedZoneReverseLookupConfig(api.ManagedZoneReverseLookupConfig o) {
  buildCounterManagedZoneReverseLookupConfig++;
  if (buildCounterManagedZoneReverseLookupConfig < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZoneReverseLookupConfig--;
}

core.int buildCounterManagedZoneServiceDirectoryConfig = 0;
api.ManagedZoneServiceDirectoryConfig buildManagedZoneServiceDirectoryConfig() {
  var o = api.ManagedZoneServiceDirectoryConfig();
  buildCounterManagedZoneServiceDirectoryConfig++;
  if (buildCounterManagedZoneServiceDirectoryConfig < 3) {
    o.kind = 'foo';
    o.namespace = buildManagedZoneServiceDirectoryConfigNamespace();
  }
  buildCounterManagedZoneServiceDirectoryConfig--;
  return o;
}

void checkManagedZoneServiceDirectoryConfig(
    api.ManagedZoneServiceDirectoryConfig o) {
  buildCounterManagedZoneServiceDirectoryConfig++;
  if (buildCounterManagedZoneServiceDirectoryConfig < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkManagedZoneServiceDirectoryConfigNamespace(
        o.namespace! as api.ManagedZoneServiceDirectoryConfigNamespace);
  }
  buildCounterManagedZoneServiceDirectoryConfig--;
}

core.int buildCounterManagedZoneServiceDirectoryConfigNamespace = 0;
api.ManagedZoneServiceDirectoryConfigNamespace
    buildManagedZoneServiceDirectoryConfigNamespace() {
  var o = api.ManagedZoneServiceDirectoryConfigNamespace();
  buildCounterManagedZoneServiceDirectoryConfigNamespace++;
  if (buildCounterManagedZoneServiceDirectoryConfigNamespace < 3) {
    o.deletionTime = 'foo';
    o.kind = 'foo';
    o.namespaceUrl = 'foo';
  }
  buildCounterManagedZoneServiceDirectoryConfigNamespace--;
  return o;
}

void checkManagedZoneServiceDirectoryConfigNamespace(
    api.ManagedZoneServiceDirectoryConfigNamespace o) {
  buildCounterManagedZoneServiceDirectoryConfigNamespace++;
  if (buildCounterManagedZoneServiceDirectoryConfigNamespace < 3) {
    unittest.expect(
      o.deletionTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.namespaceUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZoneServiceDirectoryConfigNamespace--;
}

core.List<api.ManagedZone> buildUnnamed2170() {
  var o = <api.ManagedZone>[];
  o.add(buildManagedZone());
  o.add(buildManagedZone());
  return o;
}

void checkUnnamed2170(core.List<api.ManagedZone> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkManagedZone(o[0] as api.ManagedZone);
  checkManagedZone(o[1] as api.ManagedZone);
}

core.int buildCounterManagedZonesListResponse = 0;
api.ManagedZonesListResponse buildManagedZonesListResponse() {
  var o = api.ManagedZonesListResponse();
  buildCounterManagedZonesListResponse++;
  if (buildCounterManagedZonesListResponse < 3) {
    o.header = buildResponseHeader();
    o.kind = 'foo';
    o.managedZones = buildUnnamed2170();
    o.nextPageToken = 'foo';
  }
  buildCounterManagedZonesListResponse--;
  return o;
}

void checkManagedZonesListResponse(api.ManagedZonesListResponse o) {
  buildCounterManagedZonesListResponse++;
  if (buildCounterManagedZonesListResponse < 3) {
    checkResponseHeader(o.header! as api.ResponseHeader);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2170(o.managedZones!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedZonesListResponse--;
}

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.dnsKeyContext = buildOperationDnsKeyContext();
    o.id = 'foo';
    o.kind = 'foo';
    o.startTime = 'foo';
    o.status = 'foo';
    o.type = 'foo';
    o.user = 'foo';
    o.zoneContext = buildOperationManagedZoneContext();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    checkOperationDnsKeyContext(o.dnsKeyContext! as api.OperationDnsKeyContext);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.user!,
      unittest.equals('foo'),
    );
    checkOperationManagedZoneContext(
        o.zoneContext! as api.OperationManagedZoneContext);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationDnsKeyContext = 0;
api.OperationDnsKeyContext buildOperationDnsKeyContext() {
  var o = api.OperationDnsKeyContext();
  buildCounterOperationDnsKeyContext++;
  if (buildCounterOperationDnsKeyContext < 3) {
    o.newValue = buildDnsKey();
    o.oldValue = buildDnsKey();
  }
  buildCounterOperationDnsKeyContext--;
  return o;
}

void checkOperationDnsKeyContext(api.OperationDnsKeyContext o) {
  buildCounterOperationDnsKeyContext++;
  if (buildCounterOperationDnsKeyContext < 3) {
    checkDnsKey(o.newValue! as api.DnsKey);
    checkDnsKey(o.oldValue! as api.DnsKey);
  }
  buildCounterOperationDnsKeyContext--;
}

core.int buildCounterOperationManagedZoneContext = 0;
api.OperationManagedZoneContext buildOperationManagedZoneContext() {
  var o = api.OperationManagedZoneContext();
  buildCounterOperationManagedZoneContext++;
  if (buildCounterOperationManagedZoneContext < 3) {
    o.newValue = buildManagedZone();
    o.oldValue = buildManagedZone();
  }
  buildCounterOperationManagedZoneContext--;
  return o;
}

void checkOperationManagedZoneContext(api.OperationManagedZoneContext o) {
  buildCounterOperationManagedZoneContext++;
  if (buildCounterOperationManagedZoneContext < 3) {
    checkManagedZone(o.newValue! as api.ManagedZone);
    checkManagedZone(o.oldValue! as api.ManagedZone);
  }
  buildCounterOperationManagedZoneContext--;
}

core.List<api.Policy> buildUnnamed2171() {
  var o = <api.Policy>[];
  o.add(buildPolicy());
  o.add(buildPolicy());
  return o;
}

void checkUnnamed2171(core.List<api.Policy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPolicy(o[0] as api.Policy);
  checkPolicy(o[1] as api.Policy);
}

core.int buildCounterPoliciesListResponse = 0;
api.PoliciesListResponse buildPoliciesListResponse() {
  var o = api.PoliciesListResponse();
  buildCounterPoliciesListResponse++;
  if (buildCounterPoliciesListResponse < 3) {
    o.header = buildResponseHeader();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.policies = buildUnnamed2171();
  }
  buildCounterPoliciesListResponse--;
  return o;
}

void checkPoliciesListResponse(api.PoliciesListResponse o) {
  buildCounterPoliciesListResponse++;
  if (buildCounterPoliciesListResponse < 3) {
    checkResponseHeader(o.header! as api.ResponseHeader);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2171(o.policies!);
  }
  buildCounterPoliciesListResponse--;
}

core.int buildCounterPoliciesPatchResponse = 0;
api.PoliciesPatchResponse buildPoliciesPatchResponse() {
  var o = api.PoliciesPatchResponse();
  buildCounterPoliciesPatchResponse++;
  if (buildCounterPoliciesPatchResponse < 3) {
    o.header = buildResponseHeader();
    o.policy = buildPolicy();
  }
  buildCounterPoliciesPatchResponse--;
  return o;
}

void checkPoliciesPatchResponse(api.PoliciesPatchResponse o) {
  buildCounterPoliciesPatchResponse++;
  if (buildCounterPoliciesPatchResponse < 3) {
    checkResponseHeader(o.header! as api.ResponseHeader);
    checkPolicy(o.policy! as api.Policy);
  }
  buildCounterPoliciesPatchResponse--;
}

core.int buildCounterPoliciesUpdateResponse = 0;
api.PoliciesUpdateResponse buildPoliciesUpdateResponse() {
  var o = api.PoliciesUpdateResponse();
  buildCounterPoliciesUpdateResponse++;
  if (buildCounterPoliciesUpdateResponse < 3) {
    o.header = buildResponseHeader();
    o.policy = buildPolicy();
  }
  buildCounterPoliciesUpdateResponse--;
  return o;
}

void checkPoliciesUpdateResponse(api.PoliciesUpdateResponse o) {
  buildCounterPoliciesUpdateResponse++;
  if (buildCounterPoliciesUpdateResponse < 3) {
    checkResponseHeader(o.header! as api.ResponseHeader);
    checkPolicy(o.policy! as api.Policy);
  }
  buildCounterPoliciesUpdateResponse--;
}

core.List<api.PolicyNetwork> buildUnnamed2172() {
  var o = <api.PolicyNetwork>[];
  o.add(buildPolicyNetwork());
  o.add(buildPolicyNetwork());
  return o;
}

void checkUnnamed2172(core.List<api.PolicyNetwork> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPolicyNetwork(o[0] as api.PolicyNetwork);
  checkPolicyNetwork(o[1] as api.PolicyNetwork);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.alternativeNameServerConfig = buildPolicyAlternativeNameServerConfig();
    o.description = 'foo';
    o.enableInboundForwarding = true;
    o.enableLogging = true;
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.networks = buildUnnamed2172();
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkPolicyAlternativeNameServerConfig(o.alternativeNameServerConfig!
        as api.PolicyAlternativeNameServerConfig);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableInboundForwarding!, unittest.isTrue);
    unittest.expect(o.enableLogging!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2172(o.networks!);
  }
  buildCounterPolicy--;
}

core.List<api.PolicyAlternativeNameServerConfigTargetNameServer>
    buildUnnamed2173() {
  var o = <api.PolicyAlternativeNameServerConfigTargetNameServer>[];
  o.add(buildPolicyAlternativeNameServerConfigTargetNameServer());
  o.add(buildPolicyAlternativeNameServerConfigTargetNameServer());
  return o;
}

void checkUnnamed2173(
    core.List<api.PolicyAlternativeNameServerConfigTargetNameServer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPolicyAlternativeNameServerConfigTargetNameServer(
      o[0] as api.PolicyAlternativeNameServerConfigTargetNameServer);
  checkPolicyAlternativeNameServerConfigTargetNameServer(
      o[1] as api.PolicyAlternativeNameServerConfigTargetNameServer);
}

core.int buildCounterPolicyAlternativeNameServerConfig = 0;
api.PolicyAlternativeNameServerConfig buildPolicyAlternativeNameServerConfig() {
  var o = api.PolicyAlternativeNameServerConfig();
  buildCounterPolicyAlternativeNameServerConfig++;
  if (buildCounterPolicyAlternativeNameServerConfig < 3) {
    o.kind = 'foo';
    o.targetNameServers = buildUnnamed2173();
  }
  buildCounterPolicyAlternativeNameServerConfig--;
  return o;
}

void checkPolicyAlternativeNameServerConfig(
    api.PolicyAlternativeNameServerConfig o) {
  buildCounterPolicyAlternativeNameServerConfig++;
  if (buildCounterPolicyAlternativeNameServerConfig < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2173(o.targetNameServers!);
  }
  buildCounterPolicyAlternativeNameServerConfig--;
}

core.int buildCounterPolicyAlternativeNameServerConfigTargetNameServer = 0;
api.PolicyAlternativeNameServerConfigTargetNameServer
    buildPolicyAlternativeNameServerConfigTargetNameServer() {
  var o = api.PolicyAlternativeNameServerConfigTargetNameServer();
  buildCounterPolicyAlternativeNameServerConfigTargetNameServer++;
  if (buildCounterPolicyAlternativeNameServerConfigTargetNameServer < 3) {
    o.forwardingPath = 'foo';
    o.ipv4Address = 'foo';
    o.kind = 'foo';
  }
  buildCounterPolicyAlternativeNameServerConfigTargetNameServer--;
  return o;
}

void checkPolicyAlternativeNameServerConfigTargetNameServer(
    api.PolicyAlternativeNameServerConfigTargetNameServer o) {
  buildCounterPolicyAlternativeNameServerConfigTargetNameServer++;
  if (buildCounterPolicyAlternativeNameServerConfigTargetNameServer < 3) {
    unittest.expect(
      o.forwardingPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ipv4Address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterPolicyAlternativeNameServerConfigTargetNameServer--;
}

core.int buildCounterPolicyNetwork = 0;
api.PolicyNetwork buildPolicyNetwork() {
  var o = api.PolicyNetwork();
  buildCounterPolicyNetwork++;
  if (buildCounterPolicyNetwork < 3) {
    o.kind = 'foo';
    o.networkUrl = 'foo';
  }
  buildCounterPolicyNetwork--;
  return o;
}

void checkPolicyNetwork(api.PolicyNetwork o) {
  buildCounterPolicyNetwork++;
  if (buildCounterPolicyNetwork < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterPolicyNetwork--;
}

core.int buildCounterProject = 0;
api.Project buildProject() {
  var o = api.Project();
  buildCounterProject++;
  if (buildCounterProject < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.number = 'foo';
    o.quota = buildQuota();
  }
  buildCounterProject--;
  return o;
}

void checkProject(api.Project o) {
  buildCounterProject++;
  if (buildCounterProject < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.number!,
      unittest.equals('foo'),
    );
    checkQuota(o.quota! as api.Quota);
  }
  buildCounterProject--;
}

core.List<api.DnsKeySpec> buildUnnamed2174() {
  var o = <api.DnsKeySpec>[];
  o.add(buildDnsKeySpec());
  o.add(buildDnsKeySpec());
  return o;
}

void checkUnnamed2174(core.List<api.DnsKeySpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDnsKeySpec(o[0] as api.DnsKeySpec);
  checkDnsKeySpec(o[1] as api.DnsKeySpec);
}

core.int buildCounterQuota = 0;
api.Quota buildQuota() {
  var o = api.Quota();
  buildCounterQuota++;
  if (buildCounterQuota < 3) {
    o.dnsKeysPerManagedZone = 42;
    o.kind = 'foo';
    o.managedZones = 42;
    o.managedZonesPerNetwork = 42;
    o.networksPerManagedZone = 42;
    o.networksPerPolicy = 42;
    o.policies = 42;
    o.resourceRecordsPerRrset = 42;
    o.rrsetAdditionsPerChange = 42;
    o.rrsetDeletionsPerChange = 42;
    o.rrsetsPerManagedZone = 42;
    o.targetNameServersPerManagedZone = 42;
    o.targetNameServersPerPolicy = 42;
    o.totalRrdataSizePerChange = 42;
    o.whitelistedKeySpecs = buildUnnamed2174();
  }
  buildCounterQuota--;
  return o;
}

void checkQuota(api.Quota o) {
  buildCounterQuota++;
  if (buildCounterQuota < 3) {
    unittest.expect(
      o.dnsKeysPerManagedZone!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.managedZones!,
      unittest.equals(42),
    );
    unittest.expect(
      o.managedZonesPerNetwork!,
      unittest.equals(42),
    );
    unittest.expect(
      o.networksPerManagedZone!,
      unittest.equals(42),
    );
    unittest.expect(
      o.networksPerPolicy!,
      unittest.equals(42),
    );
    unittest.expect(
      o.policies!,
      unittest.equals(42),
    );
    unittest.expect(
      o.resourceRecordsPerRrset!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rrsetAdditionsPerChange!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rrsetDeletionsPerChange!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rrsetsPerManagedZone!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetNameServersPerManagedZone!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetNameServersPerPolicy!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalRrdataSizePerChange!,
      unittest.equals(42),
    );
    checkUnnamed2174(o.whitelistedKeySpecs!);
  }
  buildCounterQuota--;
}

core.List<core.String> buildUnnamed2175() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2175(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2176() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2176(core.List<core.String> o) {
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

core.int buildCounterResourceRecordSet = 0;
api.ResourceRecordSet buildResourceRecordSet() {
  var o = api.ResourceRecordSet();
  buildCounterResourceRecordSet++;
  if (buildCounterResourceRecordSet < 3) {
    o.kind = 'foo';
    o.name = 'foo';
    o.rrdatas = buildUnnamed2175();
    o.signatureRrdatas = buildUnnamed2176();
    o.ttl = 42;
    o.type = 'foo';
  }
  buildCounterResourceRecordSet--;
  return o;
}

void checkResourceRecordSet(api.ResourceRecordSet o) {
  buildCounterResourceRecordSet++;
  if (buildCounterResourceRecordSet < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2175(o.rrdatas!);
    checkUnnamed2176(o.signatureRrdatas!);
    unittest.expect(
      o.ttl!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceRecordSet--;
}

core.int buildCounterResourceRecordSetsDeleteResponse = 0;
api.ResourceRecordSetsDeleteResponse buildResourceRecordSetsDeleteResponse() {
  var o = api.ResourceRecordSetsDeleteResponse();
  buildCounterResourceRecordSetsDeleteResponse++;
  if (buildCounterResourceRecordSetsDeleteResponse < 3) {}
  buildCounterResourceRecordSetsDeleteResponse--;
  return o;
}

void checkResourceRecordSetsDeleteResponse(
    api.ResourceRecordSetsDeleteResponse o) {
  buildCounterResourceRecordSetsDeleteResponse++;
  if (buildCounterResourceRecordSetsDeleteResponse < 3) {}
  buildCounterResourceRecordSetsDeleteResponse--;
}

core.List<api.ResourceRecordSet> buildUnnamed2177() {
  var o = <api.ResourceRecordSet>[];
  o.add(buildResourceRecordSet());
  o.add(buildResourceRecordSet());
  return o;
}

void checkUnnamed2177(core.List<api.ResourceRecordSet> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceRecordSet(o[0] as api.ResourceRecordSet);
  checkResourceRecordSet(o[1] as api.ResourceRecordSet);
}

core.int buildCounterResourceRecordSetsListResponse = 0;
api.ResourceRecordSetsListResponse buildResourceRecordSetsListResponse() {
  var o = api.ResourceRecordSetsListResponse();
  buildCounterResourceRecordSetsListResponse++;
  if (buildCounterResourceRecordSetsListResponse < 3) {
    o.header = buildResponseHeader();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.rrsets = buildUnnamed2177();
  }
  buildCounterResourceRecordSetsListResponse--;
  return o;
}

void checkResourceRecordSetsListResponse(api.ResourceRecordSetsListResponse o) {
  buildCounterResourceRecordSetsListResponse++;
  if (buildCounterResourceRecordSetsListResponse < 3) {
    checkResponseHeader(o.header! as api.ResponseHeader);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2177(o.rrsets!);
  }
  buildCounterResourceRecordSetsListResponse--;
}

core.int buildCounterResponseHeader = 0;
api.ResponseHeader buildResponseHeader() {
  var o = api.ResponseHeader();
  buildCounterResponseHeader++;
  if (buildCounterResponseHeader < 3) {
    o.operationId = 'foo';
  }
  buildCounterResponseHeader--;
  return o;
}

void checkResponseHeader(api.ResponseHeader o) {
  buildCounterResponseHeader++;
  if (buildCounterResponseHeader < 3) {
    unittest.expect(
      o.operationId!,
      unittest.equals('foo'),
    );
  }
  buildCounterResponseHeader--;
}

void main() {
  unittest.group('obj-schema-Change', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Change.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChange(od as api.Change);
    });
  });

  unittest.group('obj-schema-ChangesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChangesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChangesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChangesListResponse(od as api.ChangesListResponse);
    });
  });

  unittest.group('obj-schema-DnsKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDnsKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DnsKey.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDnsKey(od as api.DnsKey);
    });
  });

  unittest.group('obj-schema-DnsKeyDigest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDnsKeyDigest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DnsKeyDigest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDnsKeyDigest(od as api.DnsKeyDigest);
    });
  });

  unittest.group('obj-schema-DnsKeySpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDnsKeySpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DnsKeySpec.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDnsKeySpec(od as api.DnsKeySpec);
    });
  });

  unittest.group('obj-schema-DnsKeysListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDnsKeysListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DnsKeysListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDnsKeysListResponse(od as api.DnsKeysListResponse);
    });
  });

  unittest.group('obj-schema-ManagedZone', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZone();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZone.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZone(od as api.ManagedZone);
    });
  });

  unittest.group('obj-schema-ManagedZoneDnsSecConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneDnsSecConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneDnsSecConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneDnsSecConfig(od as api.ManagedZoneDnsSecConfig);
    });
  });

  unittest.group('obj-schema-ManagedZoneForwardingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneForwardingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneForwardingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneForwardingConfig(od as api.ManagedZoneForwardingConfig);
    });
  });

  unittest.group('obj-schema-ManagedZoneForwardingConfigNameServerTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneForwardingConfigNameServerTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneForwardingConfigNameServerTarget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneForwardingConfigNameServerTarget(
          od as api.ManagedZoneForwardingConfigNameServerTarget);
    });
  });

  unittest.group('obj-schema-ManagedZoneOperationsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneOperationsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneOperationsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneOperationsListResponse(
          od as api.ManagedZoneOperationsListResponse);
    });
  });

  unittest.group('obj-schema-ManagedZonePeeringConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZonePeeringConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZonePeeringConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZonePeeringConfig(od as api.ManagedZonePeeringConfig);
    });
  });

  unittest.group('obj-schema-ManagedZonePeeringConfigTargetNetwork', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZonePeeringConfigTargetNetwork();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZonePeeringConfigTargetNetwork.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZonePeeringConfigTargetNetwork(
          od as api.ManagedZonePeeringConfigTargetNetwork);
    });
  });

  unittest.group('obj-schema-ManagedZonePrivateVisibilityConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZonePrivateVisibilityConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZonePrivateVisibilityConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZonePrivateVisibilityConfig(
          od as api.ManagedZonePrivateVisibilityConfig);
    });
  });

  unittest.group('obj-schema-ManagedZonePrivateVisibilityConfigNetwork', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZonePrivateVisibilityConfigNetwork();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZonePrivateVisibilityConfigNetwork.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZonePrivateVisibilityConfigNetwork(
          od as api.ManagedZonePrivateVisibilityConfigNetwork);
    });
  });

  unittest.group('obj-schema-ManagedZoneReverseLookupConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneReverseLookupConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneReverseLookupConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneReverseLookupConfig(
          od as api.ManagedZoneReverseLookupConfig);
    });
  });

  unittest.group('obj-schema-ManagedZoneServiceDirectoryConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneServiceDirectoryConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneServiceDirectoryConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneServiceDirectoryConfig(
          od as api.ManagedZoneServiceDirectoryConfig);
    });
  });

  unittest.group('obj-schema-ManagedZoneServiceDirectoryConfigNamespace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZoneServiceDirectoryConfigNamespace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZoneServiceDirectoryConfigNamespace.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZoneServiceDirectoryConfigNamespace(
          od as api.ManagedZoneServiceDirectoryConfigNamespace);
    });
  });

  unittest.group('obj-schema-ManagedZonesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedZonesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedZonesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedZonesListResponse(od as api.ManagedZonesListResponse);
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

  unittest.group('obj-schema-OperationDnsKeyContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationDnsKeyContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationDnsKeyContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationDnsKeyContext(od as api.OperationDnsKeyContext);
    });
  });

  unittest.group('obj-schema-OperationManagedZoneContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationManagedZoneContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationManagedZoneContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationManagedZoneContext(od as api.OperationManagedZoneContext);
    });
  });

  unittest.group('obj-schema-PoliciesListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPoliciesListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PoliciesListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPoliciesListResponse(od as api.PoliciesListResponse);
    });
  });

  unittest.group('obj-schema-PoliciesPatchResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPoliciesPatchResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PoliciesPatchResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPoliciesPatchResponse(od as api.PoliciesPatchResponse);
    });
  });

  unittest.group('obj-schema-PoliciesUpdateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPoliciesUpdateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PoliciesUpdateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPoliciesUpdateResponse(od as api.PoliciesUpdateResponse);
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

  unittest.group('obj-schema-PolicyAlternativeNameServerConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicyAlternativeNameServerConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PolicyAlternativeNameServerConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPolicyAlternativeNameServerConfig(
          od as api.PolicyAlternativeNameServerConfig);
    });
  });

  unittest.group('obj-schema-PolicyAlternativeNameServerConfigTargetNameServer',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicyAlternativeNameServerConfigTargetNameServer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PolicyAlternativeNameServerConfigTargetNameServer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPolicyAlternativeNameServerConfigTargetNameServer(
          od as api.PolicyAlternativeNameServerConfigTargetNameServer);
    });
  });

  unittest.group('obj-schema-PolicyNetwork', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicyNetwork();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PolicyNetwork.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPolicyNetwork(od as api.PolicyNetwork);
    });
  });

  unittest.group('obj-schema-Project', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Project.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProject(od as api.Project);
    });
  });

  unittest.group('obj-schema-Quota', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuota();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Quota.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQuota(od as api.Quota);
    });
  });

  unittest.group('obj-schema-ResourceRecordSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceRecordSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceRecordSet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceRecordSet(od as api.ResourceRecordSet);
    });
  });

  unittest.group('obj-schema-ResourceRecordSetsDeleteResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceRecordSetsDeleteResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceRecordSetsDeleteResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceRecordSetsDeleteResponse(
          od as api.ResourceRecordSetsDeleteResponse);
    });
  });

  unittest.group('obj-schema-ResourceRecordSetsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceRecordSetsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceRecordSetsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceRecordSetsListResponse(
          od as api.ResourceRecordSetsListResponse);
    });
  });

  unittest.group('obj-schema-ResponseHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResponseHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResponseHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResponseHeader(od as api.ResponseHeader);
    });
  });

  unittest.group('resource-ChangesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).changes;
      var arg_request = buildChange();
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Change.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChange(obj as api.Change);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/changes', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/changes"),
        );
        pathOffset += 8;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChange());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_project, arg_managedZone,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkChange(response as api.Change);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).changes;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_changeId = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/changes/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/changes/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_changeId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChange());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_project, arg_managedZone, arg_changeId,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkChange(response as api.Change);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).changes;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_sortBy = 'foo';
      var arg_sortOrder = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/changes', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/changes"),
        );
        pathOffset += 8;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["sortBy"]!.first,
          unittest.equals(arg_sortBy),
        );
        unittest.expect(
          queryMap["sortOrder"]!.first,
          unittest.equals(arg_sortOrder),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChangesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project, arg_managedZone,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          sortBy: arg_sortBy,
          sortOrder: arg_sortOrder,
          $fields: arg_$fields);
      checkChangesListResponse(response as api.ChangesListResponse);
    });
  });

  unittest.group('resource-DnsKeysResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).dnsKeys;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_dnsKeyId = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_digestType = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/dnsKeys/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/dnsKeys/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_dnsKeyId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["digestType"]!.first,
          unittest.equals(arg_digestType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDnsKey());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_project, arg_managedZone, arg_dnsKeyId,
          clientOperationId: arg_clientOperationId,
          digestType: arg_digestType,
          $fields: arg_$fields);
      checkDnsKey(response as api.DnsKey);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).dnsKeys;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_digestType = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/dnsKeys', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/dnsKeys"),
        );
        pathOffset += 8;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["digestType"]!.first,
          unittest.equals(arg_digestType),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildDnsKeysListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project, arg_managedZone,
          digestType: arg_digestType,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkDnsKeysListResponse(response as api.DnsKeysListResponse);
    });
  });

  unittest.group('resource-ManagedZoneOperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZoneOperations;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_operation = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/operations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/operations/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_operation'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
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
      final response = await res.get(
          arg_project, arg_managedZone, arg_operation,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZoneOperations;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_sortBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/operations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/operations"),
        );
        pathOffset += 11;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["sortBy"]!.first,
          unittest.equals(arg_sortBy),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildManagedZoneOperationsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project, arg_managedZone,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          sortBy: arg_sortBy,
          $fields: arg_$fields);
      checkManagedZoneOperationsListResponse(
          response as api.ManagedZoneOperationsListResponse);
    });
  });

  unittest.group('resource-ManagedZonesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZones;
      var arg_request = buildManagedZone();
      var arg_project = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ManagedZone.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkManagedZone(obj as api.ManagedZone);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/managedZones"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildManagedZone());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_project,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkManagedZone(response as api.ManagedZone);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZones;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_project, arg_managedZone,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZones;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildManagedZone());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_project, arg_managedZone,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkManagedZone(response as api.ManagedZone);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZones;
      var arg_project = 'foo';
      var arg_dnsName = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/managedZones"),
        );
        pathOffset += 13;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["dnsName"]!.first,
          unittest.equals(arg_dnsName),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildManagedZonesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          dnsName: arg_dnsName,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkManagedZonesListResponse(response as api.ManagedZonesListResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZones;
      var arg_request = buildManagedZone();
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ManagedZone.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkManagedZone(obj as api.ManagedZone);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
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
      final response = await res.patch(
          arg_request, arg_project, arg_managedZone,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).managedZones;
      var arg_request = buildManagedZone();
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ManagedZone.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkManagedZone(obj as api.ManagedZone);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
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
      final response = await res.update(
          arg_request, arg_project, arg_managedZone,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-PoliciesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).policies;
      var arg_request = buildPolicy();
      var arg_project = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Policy.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPolicy(obj as api.Policy);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/policies', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/policies"),
        );
        pathOffset += 9;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
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
      final response = await res.create(arg_request, arg_project,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).policies;
      var arg_project = 'foo';
      var arg_policy = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/policies/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/policies/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_policy'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_project, arg_policy,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).policies;
      var arg_project = 'foo';
      var arg_policy = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/policies/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/policies/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_policy'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
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
      final response = await res.get(arg_project, arg_policy,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).policies;
      var arg_project = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/policies', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/policies"),
        );
        pathOffset += 9;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
        var resp = convert.json.encode(buildPoliciesListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkPoliciesListResponse(response as api.PoliciesListResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).policies;
      var arg_request = buildPolicy();
      var arg_project = 'foo';
      var arg_policy = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Policy.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPolicy(obj as api.Policy);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/policies/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/policies/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_policy'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPoliciesPatchResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_project, arg_policy,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkPoliciesPatchResponse(response as api.PoliciesPatchResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).policies;
      var arg_request = buildPolicy();
      var arg_project = 'foo';
      var arg_policy = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Policy.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPolicy(obj as api.Policy);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/policies/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/policies/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_policy'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPoliciesUpdateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_project, arg_policy,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkPoliciesUpdateResponse(response as api.PoliciesUpdateResponse);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).projects;
      var arg_project = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildProject());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_project,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkProject(response as api.Project);
    });
  });

  unittest.group('resource-ProjectsManagedZonesRrsetsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).projects.managedZones.rrsets;
      var arg_request = buildResourceRecordSet();
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResourceRecordSet.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResourceRecordSet(obj as api.ResourceRecordSet);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/rrsets', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/rrsets"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResourceRecordSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_project, arg_managedZone,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkResourceRecordSet(response as api.ResourceRecordSet);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).projects.managedZones.rrsets;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_name = 'foo';
      var arg_type = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/rrsets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/rrsets/"),
        );
        pathOffset += 8;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_name'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_type'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResourceRecordSetsDeleteResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(
          arg_project, arg_managedZone, arg_name, arg_type,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkResourceRecordSetsDeleteResponse(
          response as api.ResourceRecordSetsDeleteResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).projects.managedZones.rrsets;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_name = 'foo';
      var arg_type = 'foo';
      var arg_clientOperationId = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/rrsets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/rrsets/"),
        );
        pathOffset += 8;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_name'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_type'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResourceRecordSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_project, arg_managedZone, arg_name, arg_type,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkResourceRecordSet(response as api.ResourceRecordSet);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).projects.managedZones.rrsets;
      var arg_request = buildResourceRecordSet();
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_name = 'foo';
      var arg_type = 'foo';
      var arg_clientOperationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResourceRecordSet.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResourceRecordSet(obj as api.ResourceRecordSet);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/rrsets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/rrsets/"),
        );
        pathOffset += 8;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_name'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_type'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["clientOperationId"]!.first,
          unittest.equals(arg_clientOperationId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResourceRecordSet());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_project, arg_managedZone, arg_name, arg_type,
          clientOperationId: arg_clientOperationId, $fields: arg_$fields);
      checkResourceRecordSet(response as api.ResourceRecordSet);
    });
  });

  unittest.group('resource-ResourceRecordSetsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DnsApi(mock).resourceRecordSets;
      var arg_project = 'foo';
      var arg_managedZone = 'foo';
      var arg_maxResults = 42;
      var arg_name = 'foo';
      var arg_pageToken = 'foo';
      var arg_type = 'foo';
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
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("dns/v1/projects/"),
        );
        pathOffset += 16;
        index = path.indexOf('/managedZones/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_project'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/managedZones/"),
        );
        pathOffset += 14;
        index = path.indexOf('/rrsets', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_managedZone'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/rrsets"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["name"]!.first,
          unittest.equals(arg_name),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["type"]!.first,
          unittest.equals(arg_type),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResourceRecordSetsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project, arg_managedZone,
          maxResults: arg_maxResults,
          name: arg_name,
          pageToken: arg_pageToken,
          type: arg_type,
          $fields: arg_$fields);
      checkResourceRecordSetsListResponse(
          response as api.ResourceRecordSetsListResponse);
    });
  });
}
