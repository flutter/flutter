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

import 'package:googleapis/appengine/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterApiConfigHandler = 0;
api.ApiConfigHandler buildApiConfigHandler() {
  var o = api.ApiConfigHandler();
  buildCounterApiConfigHandler++;
  if (buildCounterApiConfigHandler < 3) {
    o.authFailAction = 'foo';
    o.login = 'foo';
    o.script = 'foo';
    o.securityLevel = 'foo';
    o.url = 'foo';
  }
  buildCounterApiConfigHandler--;
  return o;
}

void checkApiConfigHandler(api.ApiConfigHandler o) {
  buildCounterApiConfigHandler++;
  if (buildCounterApiConfigHandler < 3) {
    unittest.expect(
      o.authFailAction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.login!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.script!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.securityLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterApiConfigHandler--;
}

core.int buildCounterApiEndpointHandler = 0;
api.ApiEndpointHandler buildApiEndpointHandler() {
  var o = api.ApiEndpointHandler();
  buildCounterApiEndpointHandler++;
  if (buildCounterApiEndpointHandler < 3) {
    o.scriptPath = 'foo';
  }
  buildCounterApiEndpointHandler--;
  return o;
}

void checkApiEndpointHandler(api.ApiEndpointHandler o) {
  buildCounterApiEndpointHandler++;
  if (buildCounterApiEndpointHandler < 3) {
    unittest.expect(
      o.scriptPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterApiEndpointHandler--;
}

core.List<api.UrlDispatchRule> buildUnnamed35() {
  var o = <api.UrlDispatchRule>[];
  o.add(buildUrlDispatchRule());
  o.add(buildUrlDispatchRule());
  return o;
}

void checkUnnamed35(core.List<api.UrlDispatchRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUrlDispatchRule(o[0] as api.UrlDispatchRule);
  checkUrlDispatchRule(o[1] as api.UrlDispatchRule);
}

core.int buildCounterApplication = 0;
api.Application buildApplication() {
  var o = api.Application();
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    o.authDomain = 'foo';
    o.codeBucket = 'foo';
    o.databaseType = 'foo';
    o.defaultBucket = 'foo';
    o.defaultCookieExpiration = 'foo';
    o.defaultHostname = 'foo';
    o.dispatchRules = buildUnnamed35();
    o.featureSettings = buildFeatureSettings();
    o.gcrDomain = 'foo';
    o.iap = buildIdentityAwareProxy();
    o.id = 'foo';
    o.locationId = 'foo';
    o.name = 'foo';
    o.servingStatus = 'foo';
  }
  buildCounterApplication--;
  return o;
}

void checkApplication(api.Application o) {
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    unittest.expect(
      o.authDomain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.codeBucket!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.databaseType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultBucket!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultCookieExpiration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultHostname!,
      unittest.equals('foo'),
    );
    checkUnnamed35(o.dispatchRules!);
    checkFeatureSettings(o.featureSettings! as api.FeatureSettings);
    unittest.expect(
      o.gcrDomain!,
      unittest.equals('foo'),
    );
    checkIdentityAwareProxy(o.iap! as api.IdentityAwareProxy);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.servingStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplication--;
}

core.List<core.String> buildUnnamed36() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed36(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed37() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed37(core.List<core.String> o) {
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

core.int buildCounterAuthorizedCertificate = 0;
api.AuthorizedCertificate buildAuthorizedCertificate() {
  var o = api.AuthorizedCertificate();
  buildCounterAuthorizedCertificate++;
  if (buildCounterAuthorizedCertificate < 3) {
    o.certificateRawData = buildCertificateRawData();
    o.displayName = 'foo';
    o.domainMappingsCount = 42;
    o.domainNames = buildUnnamed36();
    o.expireTime = 'foo';
    o.id = 'foo';
    o.managedCertificate = buildManagedCertificate();
    o.name = 'foo';
    o.visibleDomainMappings = buildUnnamed37();
  }
  buildCounterAuthorizedCertificate--;
  return o;
}

void checkAuthorizedCertificate(api.AuthorizedCertificate o) {
  buildCounterAuthorizedCertificate++;
  if (buildCounterAuthorizedCertificate < 3) {
    checkCertificateRawData(o.certificateRawData! as api.CertificateRawData);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.domainMappingsCount!,
      unittest.equals(42),
    );
    checkUnnamed36(o.domainNames!);
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkManagedCertificate(o.managedCertificate! as api.ManagedCertificate);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed37(o.visibleDomainMappings!);
  }
  buildCounterAuthorizedCertificate--;
}

core.int buildCounterAuthorizedDomain = 0;
api.AuthorizedDomain buildAuthorizedDomain() {
  var o = api.AuthorizedDomain();
  buildCounterAuthorizedDomain++;
  if (buildCounterAuthorizedDomain < 3) {
    o.id = 'foo';
    o.name = 'foo';
  }
  buildCounterAuthorizedDomain--;
  return o;
}

void checkAuthorizedDomain(api.AuthorizedDomain o) {
  buildCounterAuthorizedDomain++;
  if (buildCounterAuthorizedDomain < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuthorizedDomain--;
}

core.int buildCounterAutomaticScaling = 0;
api.AutomaticScaling buildAutomaticScaling() {
  var o = api.AutomaticScaling();
  buildCounterAutomaticScaling++;
  if (buildCounterAutomaticScaling < 3) {
    o.coolDownPeriod = 'foo';
    o.cpuUtilization = buildCpuUtilization();
    o.diskUtilization = buildDiskUtilization();
    o.maxConcurrentRequests = 42;
    o.maxIdleInstances = 42;
    o.maxPendingLatency = 'foo';
    o.maxTotalInstances = 42;
    o.minIdleInstances = 42;
    o.minPendingLatency = 'foo';
    o.minTotalInstances = 42;
    o.networkUtilization = buildNetworkUtilization();
    o.requestUtilization = buildRequestUtilization();
    o.standardSchedulerSettings = buildStandardSchedulerSettings();
  }
  buildCounterAutomaticScaling--;
  return o;
}

void checkAutomaticScaling(api.AutomaticScaling o) {
  buildCounterAutomaticScaling++;
  if (buildCounterAutomaticScaling < 3) {
    unittest.expect(
      o.coolDownPeriod!,
      unittest.equals('foo'),
    );
    checkCpuUtilization(o.cpuUtilization! as api.CpuUtilization);
    checkDiskUtilization(o.diskUtilization! as api.DiskUtilization);
    unittest.expect(
      o.maxConcurrentRequests!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxIdleInstances!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxPendingLatency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxTotalInstances!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minIdleInstances!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minPendingLatency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minTotalInstances!,
      unittest.equals(42),
    );
    checkNetworkUtilization(o.networkUtilization! as api.NetworkUtilization);
    checkRequestUtilization(o.requestUtilization! as api.RequestUtilization);
    checkStandardSchedulerSettings(
        o.standardSchedulerSettings! as api.StandardSchedulerSettings);
  }
  buildCounterAutomaticScaling--;
}

core.int buildCounterBasicScaling = 0;
api.BasicScaling buildBasicScaling() {
  var o = api.BasicScaling();
  buildCounterBasicScaling++;
  if (buildCounterBasicScaling < 3) {
    o.idleTimeout = 'foo';
    o.maxInstances = 42;
  }
  buildCounterBasicScaling--;
  return o;
}

void checkBasicScaling(api.BasicScaling o) {
  buildCounterBasicScaling++;
  if (buildCounterBasicScaling < 3) {
    unittest.expect(
      o.idleTimeout!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxInstances!,
      unittest.equals(42),
    );
  }
  buildCounterBasicScaling--;
}

core.List<api.FirewallRule> buildUnnamed38() {
  var o = <api.FirewallRule>[];
  o.add(buildFirewallRule());
  o.add(buildFirewallRule());
  return o;
}

void checkUnnamed38(core.List<api.FirewallRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFirewallRule(o[0] as api.FirewallRule);
  checkFirewallRule(o[1] as api.FirewallRule);
}

core.int buildCounterBatchUpdateIngressRulesRequest = 0;
api.BatchUpdateIngressRulesRequest buildBatchUpdateIngressRulesRequest() {
  var o = api.BatchUpdateIngressRulesRequest();
  buildCounterBatchUpdateIngressRulesRequest++;
  if (buildCounterBatchUpdateIngressRulesRequest < 3) {
    o.ingressRules = buildUnnamed38();
  }
  buildCounterBatchUpdateIngressRulesRequest--;
  return o;
}

void checkBatchUpdateIngressRulesRequest(api.BatchUpdateIngressRulesRequest o) {
  buildCounterBatchUpdateIngressRulesRequest++;
  if (buildCounterBatchUpdateIngressRulesRequest < 3) {
    checkUnnamed38(o.ingressRules!);
  }
  buildCounterBatchUpdateIngressRulesRequest--;
}

core.List<api.FirewallRule> buildUnnamed39() {
  var o = <api.FirewallRule>[];
  o.add(buildFirewallRule());
  o.add(buildFirewallRule());
  return o;
}

void checkUnnamed39(core.List<api.FirewallRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFirewallRule(o[0] as api.FirewallRule);
  checkFirewallRule(o[1] as api.FirewallRule);
}

core.int buildCounterBatchUpdateIngressRulesResponse = 0;
api.BatchUpdateIngressRulesResponse buildBatchUpdateIngressRulesResponse() {
  var o = api.BatchUpdateIngressRulesResponse();
  buildCounterBatchUpdateIngressRulesResponse++;
  if (buildCounterBatchUpdateIngressRulesResponse < 3) {
    o.ingressRules = buildUnnamed39();
  }
  buildCounterBatchUpdateIngressRulesResponse--;
  return o;
}

void checkBatchUpdateIngressRulesResponse(
    api.BatchUpdateIngressRulesResponse o) {
  buildCounterBatchUpdateIngressRulesResponse++;
  if (buildCounterBatchUpdateIngressRulesResponse < 3) {
    checkUnnamed39(o.ingressRules!);
  }
  buildCounterBatchUpdateIngressRulesResponse--;
}

core.int buildCounterCertificateRawData = 0;
api.CertificateRawData buildCertificateRawData() {
  var o = api.CertificateRawData();
  buildCounterCertificateRawData++;
  if (buildCounterCertificateRawData < 3) {
    o.privateKey = 'foo';
    o.publicCertificate = 'foo';
  }
  buildCounterCertificateRawData--;
  return o;
}

void checkCertificateRawData(api.CertificateRawData o) {
  buildCounterCertificateRawData++;
  if (buildCounterCertificateRawData < 3) {
    unittest.expect(
      o.privateKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publicCertificate!,
      unittest.equals('foo'),
    );
  }
  buildCounterCertificateRawData--;
}

core.int buildCounterCloudBuildOptions = 0;
api.CloudBuildOptions buildCloudBuildOptions() {
  var o = api.CloudBuildOptions();
  buildCounterCloudBuildOptions++;
  if (buildCounterCloudBuildOptions < 3) {
    o.appYamlPath = 'foo';
    o.cloudBuildTimeout = 'foo';
  }
  buildCounterCloudBuildOptions--;
  return o;
}

void checkCloudBuildOptions(api.CloudBuildOptions o) {
  buildCounterCloudBuildOptions++;
  if (buildCounterCloudBuildOptions < 3) {
    unittest.expect(
      o.appYamlPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cloudBuildTimeout!,
      unittest.equals('foo'),
    );
  }
  buildCounterCloudBuildOptions--;
}

core.int buildCounterContainerInfo = 0;
api.ContainerInfo buildContainerInfo() {
  var o = api.ContainerInfo();
  buildCounterContainerInfo++;
  if (buildCounterContainerInfo < 3) {
    o.image = 'foo';
  }
  buildCounterContainerInfo--;
  return o;
}

void checkContainerInfo(api.ContainerInfo o) {
  buildCounterContainerInfo++;
  if (buildCounterContainerInfo < 3) {
    unittest.expect(
      o.image!,
      unittest.equals('foo'),
    );
  }
  buildCounterContainerInfo--;
}

core.int buildCounterCpuUtilization = 0;
api.CpuUtilization buildCpuUtilization() {
  var o = api.CpuUtilization();
  buildCounterCpuUtilization++;
  if (buildCounterCpuUtilization < 3) {
    o.aggregationWindowLength = 'foo';
    o.targetUtilization = 42.0;
  }
  buildCounterCpuUtilization--;
  return o;
}

void checkCpuUtilization(api.CpuUtilization o) {
  buildCounterCpuUtilization++;
  if (buildCounterCpuUtilization < 3) {
    unittest.expect(
      o.aggregationWindowLength!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetUtilization!,
      unittest.equals(42.0),
    );
  }
  buildCounterCpuUtilization--;
}

core.int buildCounterCreateVersionMetadataV1 = 0;
api.CreateVersionMetadataV1 buildCreateVersionMetadataV1() {
  var o = api.CreateVersionMetadataV1();
  buildCounterCreateVersionMetadataV1++;
  if (buildCounterCreateVersionMetadataV1 < 3) {
    o.cloudBuildId = 'foo';
  }
  buildCounterCreateVersionMetadataV1--;
  return o;
}

void checkCreateVersionMetadataV1(api.CreateVersionMetadataV1 o) {
  buildCounterCreateVersionMetadataV1++;
  if (buildCounterCreateVersionMetadataV1 < 3) {
    unittest.expect(
      o.cloudBuildId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateVersionMetadataV1--;
}

core.int buildCounterCreateVersionMetadataV1Alpha = 0;
api.CreateVersionMetadataV1Alpha buildCreateVersionMetadataV1Alpha() {
  var o = api.CreateVersionMetadataV1Alpha();
  buildCounterCreateVersionMetadataV1Alpha++;
  if (buildCounterCreateVersionMetadataV1Alpha < 3) {
    o.cloudBuildId = 'foo';
  }
  buildCounterCreateVersionMetadataV1Alpha--;
  return o;
}

void checkCreateVersionMetadataV1Alpha(api.CreateVersionMetadataV1Alpha o) {
  buildCounterCreateVersionMetadataV1Alpha++;
  if (buildCounterCreateVersionMetadataV1Alpha < 3) {
    unittest.expect(
      o.cloudBuildId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateVersionMetadataV1Alpha--;
}

core.int buildCounterCreateVersionMetadataV1Beta = 0;
api.CreateVersionMetadataV1Beta buildCreateVersionMetadataV1Beta() {
  var o = api.CreateVersionMetadataV1Beta();
  buildCounterCreateVersionMetadataV1Beta++;
  if (buildCounterCreateVersionMetadataV1Beta < 3) {
    o.cloudBuildId = 'foo';
  }
  buildCounterCreateVersionMetadataV1Beta--;
  return o;
}

void checkCreateVersionMetadataV1Beta(api.CreateVersionMetadataV1Beta o) {
  buildCounterCreateVersionMetadataV1Beta++;
  if (buildCounterCreateVersionMetadataV1Beta < 3) {
    unittest.expect(
      o.cloudBuildId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateVersionMetadataV1Beta--;
}

core.int buildCounterDebugInstanceRequest = 0;
api.DebugInstanceRequest buildDebugInstanceRequest() {
  var o = api.DebugInstanceRequest();
  buildCounterDebugInstanceRequest++;
  if (buildCounterDebugInstanceRequest < 3) {
    o.sshKey = 'foo';
  }
  buildCounterDebugInstanceRequest--;
  return o;
}

void checkDebugInstanceRequest(api.DebugInstanceRequest o) {
  buildCounterDebugInstanceRequest++;
  if (buildCounterDebugInstanceRequest < 3) {
    unittest.expect(
      o.sshKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterDebugInstanceRequest--;
}

core.Map<core.String, api.FileInfo> buildUnnamed40() {
  var o = <core.String, api.FileInfo>{};
  o['x'] = buildFileInfo();
  o['y'] = buildFileInfo();
  return o;
}

void checkUnnamed40(core.Map<core.String, api.FileInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFileInfo(o['x']! as api.FileInfo);
  checkFileInfo(o['y']! as api.FileInfo);
}

core.int buildCounterDeployment = 0;
api.Deployment buildDeployment() {
  var o = api.Deployment();
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    o.cloudBuildOptions = buildCloudBuildOptions();
    o.container = buildContainerInfo();
    o.files = buildUnnamed40();
    o.zip = buildZipInfo();
  }
  buildCounterDeployment--;
  return o;
}

void checkDeployment(api.Deployment o) {
  buildCounterDeployment++;
  if (buildCounterDeployment < 3) {
    checkCloudBuildOptions(o.cloudBuildOptions! as api.CloudBuildOptions);
    checkContainerInfo(o.container! as api.ContainerInfo);
    checkUnnamed40(o.files!);
    checkZipInfo(o.zip! as api.ZipInfo);
  }
  buildCounterDeployment--;
}

core.int buildCounterDiskUtilization = 0;
api.DiskUtilization buildDiskUtilization() {
  var o = api.DiskUtilization();
  buildCounterDiskUtilization++;
  if (buildCounterDiskUtilization < 3) {
    o.targetReadBytesPerSecond = 42;
    o.targetReadOpsPerSecond = 42;
    o.targetWriteBytesPerSecond = 42;
    o.targetWriteOpsPerSecond = 42;
  }
  buildCounterDiskUtilization--;
  return o;
}

void checkDiskUtilization(api.DiskUtilization o) {
  buildCounterDiskUtilization++;
  if (buildCounterDiskUtilization < 3) {
    unittest.expect(
      o.targetReadBytesPerSecond!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetReadOpsPerSecond!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetWriteBytesPerSecond!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetWriteOpsPerSecond!,
      unittest.equals(42),
    );
  }
  buildCounterDiskUtilization--;
}

core.List<api.ResourceRecord> buildUnnamed41() {
  var o = <api.ResourceRecord>[];
  o.add(buildResourceRecord());
  o.add(buildResourceRecord());
  return o;
}

void checkUnnamed41(core.List<api.ResourceRecord> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResourceRecord(o[0] as api.ResourceRecord);
  checkResourceRecord(o[1] as api.ResourceRecord);
}

core.int buildCounterDomainMapping = 0;
api.DomainMapping buildDomainMapping() {
  var o = api.DomainMapping();
  buildCounterDomainMapping++;
  if (buildCounterDomainMapping < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.resourceRecords = buildUnnamed41();
    o.sslSettings = buildSslSettings();
  }
  buildCounterDomainMapping--;
  return o;
}

void checkDomainMapping(api.DomainMapping o) {
  buildCounterDomainMapping++;
  if (buildCounterDomainMapping < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed41(o.resourceRecords!);
    checkSslSettings(o.sslSettings! as api.SslSettings);
  }
  buildCounterDomainMapping--;
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

core.int buildCounterEndpointsApiService = 0;
api.EndpointsApiService buildEndpointsApiService() {
  var o = api.EndpointsApiService();
  buildCounterEndpointsApiService++;
  if (buildCounterEndpointsApiService < 3) {
    o.configId = 'foo';
    o.disableTraceSampling = true;
    o.name = 'foo';
    o.rolloutStrategy = 'foo';
  }
  buildCounterEndpointsApiService--;
  return o;
}

void checkEndpointsApiService(api.EndpointsApiService o) {
  buildCounterEndpointsApiService++;
  if (buildCounterEndpointsApiService < 3) {
    unittest.expect(
      o.configId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disableTraceSampling!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rolloutStrategy!,
      unittest.equals('foo'),
    );
  }
  buildCounterEndpointsApiService--;
}

core.int buildCounterEntrypoint = 0;
api.Entrypoint buildEntrypoint() {
  var o = api.Entrypoint();
  buildCounterEntrypoint++;
  if (buildCounterEntrypoint < 3) {
    o.shell = 'foo';
  }
  buildCounterEntrypoint--;
  return o;
}

void checkEntrypoint(api.Entrypoint o) {
  buildCounterEntrypoint++;
  if (buildCounterEntrypoint < 3) {
    unittest.expect(
      o.shell!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntrypoint--;
}

core.int buildCounterErrorHandler = 0;
api.ErrorHandler buildErrorHandler() {
  var o = api.ErrorHandler();
  buildCounterErrorHandler++;
  if (buildCounterErrorHandler < 3) {
    o.errorCode = 'foo';
    o.mimeType = 'foo';
    o.staticFile = 'foo';
  }
  buildCounterErrorHandler--;
  return o;
}

void checkErrorHandler(api.ErrorHandler o) {
  buildCounterErrorHandler++;
  if (buildCounterErrorHandler < 3) {
    unittest.expect(
      o.errorCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.staticFile!,
      unittest.equals('foo'),
    );
  }
  buildCounterErrorHandler--;
}

core.int buildCounterFeatureSettings = 0;
api.FeatureSettings buildFeatureSettings() {
  var o = api.FeatureSettings();
  buildCounterFeatureSettings++;
  if (buildCounterFeatureSettings < 3) {
    o.splitHealthChecks = true;
    o.useContainerOptimizedOs = true;
  }
  buildCounterFeatureSettings--;
  return o;
}

void checkFeatureSettings(api.FeatureSettings o) {
  buildCounterFeatureSettings++;
  if (buildCounterFeatureSettings < 3) {
    unittest.expect(o.splitHealthChecks!, unittest.isTrue);
    unittest.expect(o.useContainerOptimizedOs!, unittest.isTrue);
  }
  buildCounterFeatureSettings--;
}

core.int buildCounterFileInfo = 0;
api.FileInfo buildFileInfo() {
  var o = api.FileInfo();
  buildCounterFileInfo++;
  if (buildCounterFileInfo < 3) {
    o.mimeType = 'foo';
    o.sha1Sum = 'foo';
    o.sourceUrl = 'foo';
  }
  buildCounterFileInfo--;
  return o;
}

void checkFileInfo(api.FileInfo o) {
  buildCounterFileInfo++;
  if (buildCounterFileInfo < 3) {
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha1Sum!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterFileInfo--;
}

core.int buildCounterFirewallRule = 0;
api.FirewallRule buildFirewallRule() {
  var o = api.FirewallRule();
  buildCounterFirewallRule++;
  if (buildCounterFirewallRule < 3) {
    o.action = 'foo';
    o.description = 'foo';
    o.priority = 42;
    o.sourceRange = 'foo';
  }
  buildCounterFirewallRule--;
  return o;
}

void checkFirewallRule(api.FirewallRule o) {
  buildCounterFirewallRule++;
  if (buildCounterFirewallRule < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.priority!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sourceRange!,
      unittest.equals('foo'),
    );
  }
  buildCounterFirewallRule--;
}

core.int buildCounterGoogleAppengineV1betaLocationMetadata = 0;
api.GoogleAppengineV1betaLocationMetadata
    buildGoogleAppengineV1betaLocationMetadata() {
  var o = api.GoogleAppengineV1betaLocationMetadata();
  buildCounterGoogleAppengineV1betaLocationMetadata++;
  if (buildCounterGoogleAppengineV1betaLocationMetadata < 3) {
    o.flexibleEnvironmentAvailable = true;
    o.searchApiAvailable = true;
    o.standardEnvironmentAvailable = true;
  }
  buildCounterGoogleAppengineV1betaLocationMetadata--;
  return o;
}

void checkGoogleAppengineV1betaLocationMetadata(
    api.GoogleAppengineV1betaLocationMetadata o) {
  buildCounterGoogleAppengineV1betaLocationMetadata++;
  if (buildCounterGoogleAppengineV1betaLocationMetadata < 3) {
    unittest.expect(o.flexibleEnvironmentAvailable!, unittest.isTrue);
    unittest.expect(o.searchApiAvailable!, unittest.isTrue);
    unittest.expect(o.standardEnvironmentAvailable!, unittest.isTrue);
  }
  buildCounterGoogleAppengineV1betaLocationMetadata--;
}

core.int buildCounterHealthCheck = 0;
api.HealthCheck buildHealthCheck() {
  var o = api.HealthCheck();
  buildCounterHealthCheck++;
  if (buildCounterHealthCheck < 3) {
    o.checkInterval = 'foo';
    o.disableHealthCheck = true;
    o.healthyThreshold = 42;
    o.host = 'foo';
    o.restartThreshold = 42;
    o.timeout = 'foo';
    o.unhealthyThreshold = 42;
  }
  buildCounterHealthCheck--;
  return o;
}

void checkHealthCheck(api.HealthCheck o) {
  buildCounterHealthCheck++;
  if (buildCounterHealthCheck < 3) {
    unittest.expect(
      o.checkInterval!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disableHealthCheck!, unittest.isTrue);
    unittest.expect(
      o.healthyThreshold!,
      unittest.equals(42),
    );
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.restartThreshold!,
      unittest.equals(42),
    );
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.unhealthyThreshold!,
      unittest.equals(42),
    );
  }
  buildCounterHealthCheck--;
}

core.int buildCounterIdentityAwareProxy = 0;
api.IdentityAwareProxy buildIdentityAwareProxy() {
  var o = api.IdentityAwareProxy();
  buildCounterIdentityAwareProxy++;
  if (buildCounterIdentityAwareProxy < 3) {
    o.enabled = true;
    o.oauth2ClientId = 'foo';
    o.oauth2ClientSecret = 'foo';
    o.oauth2ClientSecretSha256 = 'foo';
  }
  buildCounterIdentityAwareProxy--;
  return o;
}

void checkIdentityAwareProxy(api.IdentityAwareProxy o) {
  buildCounterIdentityAwareProxy++;
  if (buildCounterIdentityAwareProxy < 3) {
    unittest.expect(o.enabled!, unittest.isTrue);
    unittest.expect(
      o.oauth2ClientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauth2ClientSecret!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oauth2ClientSecretSha256!,
      unittest.equals('foo'),
    );
  }
  buildCounterIdentityAwareProxy--;
}

core.int buildCounterInstance = 0;
api.Instance buildInstance() {
  var o = api.Instance();
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    o.appEngineRelease = 'foo';
    o.availability = 'foo';
    o.averageLatency = 42;
    o.errors = 42;
    o.id = 'foo';
    o.memoryUsage = 'foo';
    o.name = 'foo';
    o.qps = 42.0;
    o.requests = 42;
    o.startTime = 'foo';
    o.vmDebugEnabled = true;
    o.vmId = 'foo';
    o.vmIp = 'foo';
    o.vmLiveness = 'foo';
    o.vmName = 'foo';
    o.vmStatus = 'foo';
    o.vmZoneName = 'foo';
  }
  buildCounterInstance--;
  return o;
}

void checkInstance(api.Instance o) {
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    unittest.expect(
      o.appEngineRelease!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.availability!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.averageLatency!,
      unittest.equals(42),
    );
    unittest.expect(
      o.errors!,
      unittest.equals(42),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memoryUsage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.qps!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.requests!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(o.vmDebugEnabled!, unittest.isTrue);
    unittest.expect(
      o.vmId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmIp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmLiveness!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vmZoneName!,
      unittest.equals('foo'),
    );
  }
  buildCounterInstance--;
}

core.int buildCounterLibrary = 0;
api.Library buildLibrary() {
  var o = api.Library();
  buildCounterLibrary++;
  if (buildCounterLibrary < 3) {
    o.name = 'foo';
    o.version = 'foo';
  }
  buildCounterLibrary--;
  return o;
}

void checkLibrary(api.Library o) {
  buildCounterLibrary++;
  if (buildCounterLibrary < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterLibrary--;
}

core.List<api.AuthorizedCertificate> buildUnnamed42() {
  var o = <api.AuthorizedCertificate>[];
  o.add(buildAuthorizedCertificate());
  o.add(buildAuthorizedCertificate());
  return o;
}

void checkUnnamed42(core.List<api.AuthorizedCertificate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuthorizedCertificate(o[0] as api.AuthorizedCertificate);
  checkAuthorizedCertificate(o[1] as api.AuthorizedCertificate);
}

core.int buildCounterListAuthorizedCertificatesResponse = 0;
api.ListAuthorizedCertificatesResponse
    buildListAuthorizedCertificatesResponse() {
  var o = api.ListAuthorizedCertificatesResponse();
  buildCounterListAuthorizedCertificatesResponse++;
  if (buildCounterListAuthorizedCertificatesResponse < 3) {
    o.certificates = buildUnnamed42();
    o.nextPageToken = 'foo';
  }
  buildCounterListAuthorizedCertificatesResponse--;
  return o;
}

void checkListAuthorizedCertificatesResponse(
    api.ListAuthorizedCertificatesResponse o) {
  buildCounterListAuthorizedCertificatesResponse++;
  if (buildCounterListAuthorizedCertificatesResponse < 3) {
    checkUnnamed42(o.certificates!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAuthorizedCertificatesResponse--;
}

core.List<api.AuthorizedDomain> buildUnnamed43() {
  var o = <api.AuthorizedDomain>[];
  o.add(buildAuthorizedDomain());
  o.add(buildAuthorizedDomain());
  return o;
}

void checkUnnamed43(core.List<api.AuthorizedDomain> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuthorizedDomain(o[0] as api.AuthorizedDomain);
  checkAuthorizedDomain(o[1] as api.AuthorizedDomain);
}

core.int buildCounterListAuthorizedDomainsResponse = 0;
api.ListAuthorizedDomainsResponse buildListAuthorizedDomainsResponse() {
  var o = api.ListAuthorizedDomainsResponse();
  buildCounterListAuthorizedDomainsResponse++;
  if (buildCounterListAuthorizedDomainsResponse < 3) {
    o.domains = buildUnnamed43();
    o.nextPageToken = 'foo';
  }
  buildCounterListAuthorizedDomainsResponse--;
  return o;
}

void checkListAuthorizedDomainsResponse(api.ListAuthorizedDomainsResponse o) {
  buildCounterListAuthorizedDomainsResponse++;
  if (buildCounterListAuthorizedDomainsResponse < 3) {
    checkUnnamed43(o.domains!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAuthorizedDomainsResponse--;
}

core.List<api.DomainMapping> buildUnnamed44() {
  var o = <api.DomainMapping>[];
  o.add(buildDomainMapping());
  o.add(buildDomainMapping());
  return o;
}

void checkUnnamed44(core.List<api.DomainMapping> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDomainMapping(o[0] as api.DomainMapping);
  checkDomainMapping(o[1] as api.DomainMapping);
}

core.int buildCounterListDomainMappingsResponse = 0;
api.ListDomainMappingsResponse buildListDomainMappingsResponse() {
  var o = api.ListDomainMappingsResponse();
  buildCounterListDomainMappingsResponse++;
  if (buildCounterListDomainMappingsResponse < 3) {
    o.domainMappings = buildUnnamed44();
    o.nextPageToken = 'foo';
  }
  buildCounterListDomainMappingsResponse--;
  return o;
}

void checkListDomainMappingsResponse(api.ListDomainMappingsResponse o) {
  buildCounterListDomainMappingsResponse++;
  if (buildCounterListDomainMappingsResponse < 3) {
    checkUnnamed44(o.domainMappings!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDomainMappingsResponse--;
}

core.List<api.FirewallRule> buildUnnamed45() {
  var o = <api.FirewallRule>[];
  o.add(buildFirewallRule());
  o.add(buildFirewallRule());
  return o;
}

void checkUnnamed45(core.List<api.FirewallRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFirewallRule(o[0] as api.FirewallRule);
  checkFirewallRule(o[1] as api.FirewallRule);
}

core.int buildCounterListIngressRulesResponse = 0;
api.ListIngressRulesResponse buildListIngressRulesResponse() {
  var o = api.ListIngressRulesResponse();
  buildCounterListIngressRulesResponse++;
  if (buildCounterListIngressRulesResponse < 3) {
    o.ingressRules = buildUnnamed45();
    o.nextPageToken = 'foo';
  }
  buildCounterListIngressRulesResponse--;
  return o;
}

void checkListIngressRulesResponse(api.ListIngressRulesResponse o) {
  buildCounterListIngressRulesResponse++;
  if (buildCounterListIngressRulesResponse < 3) {
    checkUnnamed45(o.ingressRules!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListIngressRulesResponse--;
}

core.List<api.Instance> buildUnnamed46() {
  var o = <api.Instance>[];
  o.add(buildInstance());
  o.add(buildInstance());
  return o;
}

void checkUnnamed46(core.List<api.Instance> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInstance(o[0] as api.Instance);
  checkInstance(o[1] as api.Instance);
}

core.int buildCounterListInstancesResponse = 0;
api.ListInstancesResponse buildListInstancesResponse() {
  var o = api.ListInstancesResponse();
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    o.instances = buildUnnamed46();
    o.nextPageToken = 'foo';
  }
  buildCounterListInstancesResponse--;
  return o;
}

void checkListInstancesResponse(api.ListInstancesResponse o) {
  buildCounterListInstancesResponse++;
  if (buildCounterListInstancesResponse < 3) {
    checkUnnamed46(o.instances!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInstancesResponse--;
}

core.List<api.Location> buildUnnamed47() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed47(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed47();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed47(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Operation> buildUnnamed48() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed48(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed48();
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
    checkUnnamed48(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.Service> buildUnnamed49() {
  var o = <api.Service>[];
  o.add(buildService());
  o.add(buildService());
  return o;
}

void checkUnnamed49(core.List<api.Service> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkService(o[0] as api.Service);
  checkService(o[1] as api.Service);
}

core.int buildCounterListServicesResponse = 0;
api.ListServicesResponse buildListServicesResponse() {
  var o = api.ListServicesResponse();
  buildCounterListServicesResponse++;
  if (buildCounterListServicesResponse < 3) {
    o.nextPageToken = 'foo';
    o.services = buildUnnamed49();
  }
  buildCounterListServicesResponse--;
  return o;
}

void checkListServicesResponse(api.ListServicesResponse o) {
  buildCounterListServicesResponse++;
  if (buildCounterListServicesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed49(o.services!);
  }
  buildCounterListServicesResponse--;
}

core.List<api.Version> buildUnnamed50() {
  var o = <api.Version>[];
  o.add(buildVersion());
  o.add(buildVersion());
  return o;
}

void checkUnnamed50(core.List<api.Version> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVersion(o[0] as api.Version);
  checkVersion(o[1] as api.Version);
}

core.int buildCounterListVersionsResponse = 0;
api.ListVersionsResponse buildListVersionsResponse() {
  var o = api.ListVersionsResponse();
  buildCounterListVersionsResponse++;
  if (buildCounterListVersionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.versions = buildUnnamed50();
  }
  buildCounterListVersionsResponse--;
  return o;
}

void checkListVersionsResponse(api.ListVersionsResponse o) {
  buildCounterListVersionsResponse++;
  if (buildCounterListVersionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed50(o.versions!);
  }
  buildCounterListVersionsResponse--;
}

core.int buildCounterLivenessCheck = 0;
api.LivenessCheck buildLivenessCheck() {
  var o = api.LivenessCheck();
  buildCounterLivenessCheck++;
  if (buildCounterLivenessCheck < 3) {
    o.checkInterval = 'foo';
    o.failureThreshold = 42;
    o.host = 'foo';
    o.initialDelay = 'foo';
    o.path = 'foo';
    o.successThreshold = 42;
    o.timeout = 'foo';
  }
  buildCounterLivenessCheck--;
  return o;
}

void checkLivenessCheck(api.LivenessCheck o) {
  buildCounterLivenessCheck++;
  if (buildCounterLivenessCheck < 3) {
    unittest.expect(
      o.checkInterval!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.failureThreshold!,
      unittest.equals(42),
    );
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.initialDelay!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.successThreshold!,
      unittest.equals(42),
    );
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
  }
  buildCounterLivenessCheck--;
}

core.Map<core.String, core.String> buildUnnamed51() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed51(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed52() {
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

void checkUnnamed52(core.Map<core.String, core.Object> o) {
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
    o.labels = buildUnnamed51();
    o.locationId = 'foo';
    o.metadata = buildUnnamed52();
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
    checkUnnamed51(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed52(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterLocationMetadata = 0;
api.LocationMetadata buildLocationMetadata() {
  var o = api.LocationMetadata();
  buildCounterLocationMetadata++;
  if (buildCounterLocationMetadata < 3) {
    o.flexibleEnvironmentAvailable = true;
    o.searchApiAvailable = true;
    o.standardEnvironmentAvailable = true;
  }
  buildCounterLocationMetadata--;
  return o;
}

void checkLocationMetadata(api.LocationMetadata o) {
  buildCounterLocationMetadata++;
  if (buildCounterLocationMetadata < 3) {
    unittest.expect(o.flexibleEnvironmentAvailable!, unittest.isTrue);
    unittest.expect(o.searchApiAvailable!, unittest.isTrue);
    unittest.expect(o.standardEnvironmentAvailable!, unittest.isTrue);
  }
  buildCounterLocationMetadata--;
}

core.int buildCounterManagedCertificate = 0;
api.ManagedCertificate buildManagedCertificate() {
  var o = api.ManagedCertificate();
  buildCounterManagedCertificate++;
  if (buildCounterManagedCertificate < 3) {
    o.lastRenewalTime = 'foo';
    o.status = 'foo';
  }
  buildCounterManagedCertificate--;
  return o;
}

void checkManagedCertificate(api.ManagedCertificate o) {
  buildCounterManagedCertificate++;
  if (buildCounterManagedCertificate < 3) {
    unittest.expect(
      o.lastRenewalTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterManagedCertificate--;
}

core.int buildCounterManualScaling = 0;
api.ManualScaling buildManualScaling() {
  var o = api.ManualScaling();
  buildCounterManualScaling++;
  if (buildCounterManualScaling < 3) {
    o.instances = 42;
  }
  buildCounterManualScaling--;
  return o;
}

void checkManualScaling(api.ManualScaling o) {
  buildCounterManualScaling++;
  if (buildCounterManualScaling < 3) {
    unittest.expect(
      o.instances!,
      unittest.equals(42),
    );
  }
  buildCounterManualScaling--;
}

core.List<core.String> buildUnnamed53() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed53(core.List<core.String> o) {
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

core.int buildCounterNetwork = 0;
api.Network buildNetwork() {
  var o = api.Network();
  buildCounterNetwork++;
  if (buildCounterNetwork < 3) {
    o.forwardedPorts = buildUnnamed53();
    o.instanceTag = 'foo';
    o.name = 'foo';
    o.sessionAffinity = true;
    o.subnetworkName = 'foo';
  }
  buildCounterNetwork--;
  return o;
}

void checkNetwork(api.Network o) {
  buildCounterNetwork++;
  if (buildCounterNetwork < 3) {
    checkUnnamed53(o.forwardedPorts!);
    unittest.expect(
      o.instanceTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sessionAffinity!, unittest.isTrue);
    unittest.expect(
      o.subnetworkName!,
      unittest.equals('foo'),
    );
  }
  buildCounterNetwork--;
}

core.int buildCounterNetworkSettings = 0;
api.NetworkSettings buildNetworkSettings() {
  var o = api.NetworkSettings();
  buildCounterNetworkSettings++;
  if (buildCounterNetworkSettings < 3) {
    o.ingressTrafficAllowed = 'foo';
  }
  buildCounterNetworkSettings--;
  return o;
}

void checkNetworkSettings(api.NetworkSettings o) {
  buildCounterNetworkSettings++;
  if (buildCounterNetworkSettings < 3) {
    unittest.expect(
      o.ingressTrafficAllowed!,
      unittest.equals('foo'),
    );
  }
  buildCounterNetworkSettings--;
}

core.int buildCounterNetworkUtilization = 0;
api.NetworkUtilization buildNetworkUtilization() {
  var o = api.NetworkUtilization();
  buildCounterNetworkUtilization++;
  if (buildCounterNetworkUtilization < 3) {
    o.targetReceivedBytesPerSecond = 42;
    o.targetReceivedPacketsPerSecond = 42;
    o.targetSentBytesPerSecond = 42;
    o.targetSentPacketsPerSecond = 42;
  }
  buildCounterNetworkUtilization--;
  return o;
}

void checkNetworkUtilization(api.NetworkUtilization o) {
  buildCounterNetworkUtilization++;
  if (buildCounterNetworkUtilization < 3) {
    unittest.expect(
      o.targetReceivedBytesPerSecond!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetReceivedPacketsPerSecond!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetSentBytesPerSecond!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetSentPacketsPerSecond!,
      unittest.equals(42),
    );
  }
  buildCounterNetworkUtilization--;
}

core.Map<core.String, core.Object> buildUnnamed54() {
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

void checkUnnamed54(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed55() {
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

void checkUnnamed55(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed54();
    o.name = 'foo';
    o.response = buildUnnamed55();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed54(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed55(o.response!);
  }
  buildCounterOperation--;
}

core.List<core.String> buildUnnamed56() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed56(core.List<core.String> o) {
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

core.int buildCounterOperationMetadataV1 = 0;
api.OperationMetadataV1 buildOperationMetadataV1() {
  var o = api.OperationMetadataV1();
  buildCounterOperationMetadataV1++;
  if (buildCounterOperationMetadataV1 < 3) {
    o.createVersionMetadata = buildCreateVersionMetadataV1();
    o.endTime = 'foo';
    o.ephemeralMessage = 'foo';
    o.insertTime = 'foo';
    o.method = 'foo';
    o.target = 'foo';
    o.user = 'foo';
    o.warning = buildUnnamed56();
  }
  buildCounterOperationMetadataV1--;
  return o;
}

void checkOperationMetadataV1(api.OperationMetadataV1 o) {
  buildCounterOperationMetadataV1++;
  if (buildCounterOperationMetadataV1 < 3) {
    checkCreateVersionMetadataV1(
        o.createVersionMetadata! as api.CreateVersionMetadataV1);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ephemeralMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.method!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.user!,
      unittest.equals('foo'),
    );
    checkUnnamed56(o.warning!);
  }
  buildCounterOperationMetadataV1--;
}

core.List<core.String> buildUnnamed57() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed57(core.List<core.String> o) {
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

core.int buildCounterOperationMetadataV1Alpha = 0;
api.OperationMetadataV1Alpha buildOperationMetadataV1Alpha() {
  var o = api.OperationMetadataV1Alpha();
  buildCounterOperationMetadataV1Alpha++;
  if (buildCounterOperationMetadataV1Alpha < 3) {
    o.createVersionMetadata = buildCreateVersionMetadataV1Alpha();
    o.endTime = 'foo';
    o.ephemeralMessage = 'foo';
    o.insertTime = 'foo';
    o.method = 'foo';
    o.target = 'foo';
    o.user = 'foo';
    o.warning = buildUnnamed57();
  }
  buildCounterOperationMetadataV1Alpha--;
  return o;
}

void checkOperationMetadataV1Alpha(api.OperationMetadataV1Alpha o) {
  buildCounterOperationMetadataV1Alpha++;
  if (buildCounterOperationMetadataV1Alpha < 3) {
    checkCreateVersionMetadataV1Alpha(
        o.createVersionMetadata! as api.CreateVersionMetadataV1Alpha);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ephemeralMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.method!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.user!,
      unittest.equals('foo'),
    );
    checkUnnamed57(o.warning!);
  }
  buildCounterOperationMetadataV1Alpha--;
}

core.List<core.String> buildUnnamed58() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed58(core.List<core.String> o) {
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

core.int buildCounterOperationMetadataV1Beta = 0;
api.OperationMetadataV1Beta buildOperationMetadataV1Beta() {
  var o = api.OperationMetadataV1Beta();
  buildCounterOperationMetadataV1Beta++;
  if (buildCounterOperationMetadataV1Beta < 3) {
    o.createVersionMetadata = buildCreateVersionMetadataV1Beta();
    o.endTime = 'foo';
    o.ephemeralMessage = 'foo';
    o.insertTime = 'foo';
    o.method = 'foo';
    o.target = 'foo';
    o.user = 'foo';
    o.warning = buildUnnamed58();
  }
  buildCounterOperationMetadataV1Beta--;
  return o;
}

void checkOperationMetadataV1Beta(api.OperationMetadataV1Beta o) {
  buildCounterOperationMetadataV1Beta++;
  if (buildCounterOperationMetadataV1Beta < 3) {
    checkCreateVersionMetadataV1Beta(
        o.createVersionMetadata! as api.CreateVersionMetadataV1Beta);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ephemeralMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.method!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.target!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.user!,
      unittest.equals('foo'),
    );
    checkUnnamed58(o.warning!);
  }
  buildCounterOperationMetadataV1Beta--;
}

core.int buildCounterReadinessCheck = 0;
api.ReadinessCheck buildReadinessCheck() {
  var o = api.ReadinessCheck();
  buildCounterReadinessCheck++;
  if (buildCounterReadinessCheck < 3) {
    o.appStartTimeout = 'foo';
    o.checkInterval = 'foo';
    o.failureThreshold = 42;
    o.host = 'foo';
    o.path = 'foo';
    o.successThreshold = 42;
    o.timeout = 'foo';
  }
  buildCounterReadinessCheck--;
  return o;
}

void checkReadinessCheck(api.ReadinessCheck o) {
  buildCounterReadinessCheck++;
  if (buildCounterReadinessCheck < 3) {
    unittest.expect(
      o.appStartTimeout!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.checkInterval!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.failureThreshold!,
      unittest.equals(42),
    );
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.successThreshold!,
      unittest.equals(42),
    );
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
  }
  buildCounterReadinessCheck--;
}

core.int buildCounterRepairApplicationRequest = 0;
api.RepairApplicationRequest buildRepairApplicationRequest() {
  var o = api.RepairApplicationRequest();
  buildCounterRepairApplicationRequest++;
  if (buildCounterRepairApplicationRequest < 3) {}
  buildCounterRepairApplicationRequest--;
  return o;
}

void checkRepairApplicationRequest(api.RepairApplicationRequest o) {
  buildCounterRepairApplicationRequest++;
  if (buildCounterRepairApplicationRequest < 3) {}
  buildCounterRepairApplicationRequest--;
}

core.int buildCounterRequestUtilization = 0;
api.RequestUtilization buildRequestUtilization() {
  var o = api.RequestUtilization();
  buildCounterRequestUtilization++;
  if (buildCounterRequestUtilization < 3) {
    o.targetConcurrentRequests = 42;
    o.targetRequestCountPerSecond = 42;
  }
  buildCounterRequestUtilization--;
  return o;
}

void checkRequestUtilization(api.RequestUtilization o) {
  buildCounterRequestUtilization++;
  if (buildCounterRequestUtilization < 3) {
    unittest.expect(
      o.targetConcurrentRequests!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetRequestCountPerSecond!,
      unittest.equals(42),
    );
  }
  buildCounterRequestUtilization--;
}

core.int buildCounterResourceRecord = 0;
api.ResourceRecord buildResourceRecord() {
  var o = api.ResourceRecord();
  buildCounterResourceRecord++;
  if (buildCounterResourceRecord < 3) {
    o.name = 'foo';
    o.rrdata = 'foo';
    o.type = 'foo';
  }
  buildCounterResourceRecord--;
  return o;
}

void checkResourceRecord(api.ResourceRecord o) {
  buildCounterResourceRecord++;
  if (buildCounterResourceRecord < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rrdata!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterResourceRecord--;
}

core.List<api.Volume> buildUnnamed59() {
  var o = <api.Volume>[];
  o.add(buildVolume());
  o.add(buildVolume());
  return o;
}

void checkUnnamed59(core.List<api.Volume> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVolume(o[0] as api.Volume);
  checkVolume(o[1] as api.Volume);
}

core.int buildCounterResources = 0;
api.Resources buildResources() {
  var o = api.Resources();
  buildCounterResources++;
  if (buildCounterResources < 3) {
    o.cpu = 42.0;
    o.diskGb = 42.0;
    o.kmsKeyReference = 'foo';
    o.memoryGb = 42.0;
    o.volumes = buildUnnamed59();
  }
  buildCounterResources--;
  return o;
}

void checkResources(api.Resources o) {
  buildCounterResources++;
  if (buildCounterResources < 3) {
    unittest.expect(
      o.cpu!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.diskGb!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.kmsKeyReference!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memoryGb!,
      unittest.equals(42.0),
    );
    checkUnnamed59(o.volumes!);
  }
  buildCounterResources--;
}

core.int buildCounterScriptHandler = 0;
api.ScriptHandler buildScriptHandler() {
  var o = api.ScriptHandler();
  buildCounterScriptHandler++;
  if (buildCounterScriptHandler < 3) {
    o.scriptPath = 'foo';
  }
  buildCounterScriptHandler--;
  return o;
}

void checkScriptHandler(api.ScriptHandler o) {
  buildCounterScriptHandler++;
  if (buildCounterScriptHandler < 3) {
    unittest.expect(
      o.scriptPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterScriptHandler--;
}

core.int buildCounterService = 0;
api.Service buildService() {
  var o = api.Service();
  buildCounterService++;
  if (buildCounterService < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.networkSettings = buildNetworkSettings();
    o.split = buildTrafficSplit();
  }
  buildCounterService--;
  return o;
}

void checkService(api.Service o) {
  buildCounterService++;
  if (buildCounterService < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkNetworkSettings(o.networkSettings! as api.NetworkSettings);
    checkTrafficSplit(o.split! as api.TrafficSplit);
  }
  buildCounterService--;
}

core.int buildCounterSslSettings = 0;
api.SslSettings buildSslSettings() {
  var o = api.SslSettings();
  buildCounterSslSettings++;
  if (buildCounterSslSettings < 3) {
    o.certificateId = 'foo';
    o.pendingManagedCertificateId = 'foo';
    o.sslManagementType = 'foo';
  }
  buildCounterSslSettings--;
  return o;
}

void checkSslSettings(api.SslSettings o) {
  buildCounterSslSettings++;
  if (buildCounterSslSettings < 3) {
    unittest.expect(
      o.certificateId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pendingManagedCertificateId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sslManagementType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSslSettings--;
}

core.int buildCounterStandardSchedulerSettings = 0;
api.StandardSchedulerSettings buildStandardSchedulerSettings() {
  var o = api.StandardSchedulerSettings();
  buildCounterStandardSchedulerSettings++;
  if (buildCounterStandardSchedulerSettings < 3) {
    o.maxInstances = 42;
    o.minInstances = 42;
    o.targetCpuUtilization = 42.0;
    o.targetThroughputUtilization = 42.0;
  }
  buildCounterStandardSchedulerSettings--;
  return o;
}

void checkStandardSchedulerSettings(api.StandardSchedulerSettings o) {
  buildCounterStandardSchedulerSettings++;
  if (buildCounterStandardSchedulerSettings < 3) {
    unittest.expect(
      o.maxInstances!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minInstances!,
      unittest.equals(42),
    );
    unittest.expect(
      o.targetCpuUtilization!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.targetThroughputUtilization!,
      unittest.equals(42.0),
    );
  }
  buildCounterStandardSchedulerSettings--;
}

core.Map<core.String, core.String> buildUnnamed60() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed60(core.Map<core.String, core.String> o) {
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

core.int buildCounterStaticFilesHandler = 0;
api.StaticFilesHandler buildStaticFilesHandler() {
  var o = api.StaticFilesHandler();
  buildCounterStaticFilesHandler++;
  if (buildCounterStaticFilesHandler < 3) {
    o.applicationReadable = true;
    o.expiration = 'foo';
    o.httpHeaders = buildUnnamed60();
    o.mimeType = 'foo';
    o.path = 'foo';
    o.requireMatchingFile = true;
    o.uploadPathRegex = 'foo';
  }
  buildCounterStaticFilesHandler--;
  return o;
}

void checkStaticFilesHandler(api.StaticFilesHandler o) {
  buildCounterStaticFilesHandler++;
  if (buildCounterStaticFilesHandler < 3) {
    unittest.expect(o.applicationReadable!, unittest.isTrue);
    unittest.expect(
      o.expiration!,
      unittest.equals('foo'),
    );
    checkUnnamed60(o.httpHeaders!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(o.requireMatchingFile!, unittest.isTrue);
    unittest.expect(
      o.uploadPathRegex!,
      unittest.equals('foo'),
    );
  }
  buildCounterStaticFilesHandler--;
}

core.Map<core.String, core.Object> buildUnnamed61() {
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

void checkUnnamed61(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed62() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed61());
  o.add(buildUnnamed61());
  return o;
}

void checkUnnamed62(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed61(o[0]);
  checkUnnamed61(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed62();
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
    checkUnnamed62(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.Map<core.String, core.double> buildUnnamed63() {
  var o = <core.String, core.double>{};
  o['x'] = 42.0;
  o['y'] = 42.0;
  return o;
}

void checkUnnamed63(core.Map<core.String, core.double> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals(42.0),
  );
  unittest.expect(
    o['y']!,
    unittest.equals(42.0),
  );
}

core.int buildCounterTrafficSplit = 0;
api.TrafficSplit buildTrafficSplit() {
  var o = api.TrafficSplit();
  buildCounterTrafficSplit++;
  if (buildCounterTrafficSplit < 3) {
    o.allocations = buildUnnamed63();
    o.shardBy = 'foo';
  }
  buildCounterTrafficSplit--;
  return o;
}

void checkTrafficSplit(api.TrafficSplit o) {
  buildCounterTrafficSplit++;
  if (buildCounterTrafficSplit < 3) {
    checkUnnamed63(o.allocations!);
    unittest.expect(
      o.shardBy!,
      unittest.equals('foo'),
    );
  }
  buildCounterTrafficSplit--;
}

core.int buildCounterUrlDispatchRule = 0;
api.UrlDispatchRule buildUrlDispatchRule() {
  var o = api.UrlDispatchRule();
  buildCounterUrlDispatchRule++;
  if (buildCounterUrlDispatchRule < 3) {
    o.domain = 'foo';
    o.path = 'foo';
    o.service = 'foo';
  }
  buildCounterUrlDispatchRule--;
  return o;
}

void checkUrlDispatchRule(api.UrlDispatchRule o) {
  buildCounterUrlDispatchRule++;
  if (buildCounterUrlDispatchRule < 3) {
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlDispatchRule--;
}

core.int buildCounterUrlMap = 0;
api.UrlMap buildUrlMap() {
  var o = api.UrlMap();
  buildCounterUrlMap++;
  if (buildCounterUrlMap < 3) {
    o.apiEndpoint = buildApiEndpointHandler();
    o.authFailAction = 'foo';
    o.login = 'foo';
    o.redirectHttpResponseCode = 'foo';
    o.script = buildScriptHandler();
    o.securityLevel = 'foo';
    o.staticFiles = buildStaticFilesHandler();
    o.urlRegex = 'foo';
  }
  buildCounterUrlMap--;
  return o;
}

void checkUrlMap(api.UrlMap o) {
  buildCounterUrlMap++;
  if (buildCounterUrlMap < 3) {
    checkApiEndpointHandler(o.apiEndpoint! as api.ApiEndpointHandler);
    unittest.expect(
      o.authFailAction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.login!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.redirectHttpResponseCode!,
      unittest.equals('foo'),
    );
    checkScriptHandler(o.script! as api.ScriptHandler);
    unittest.expect(
      o.securityLevel!,
      unittest.equals('foo'),
    );
    checkStaticFilesHandler(o.staticFiles! as api.StaticFilesHandler);
    unittest.expect(
      o.urlRegex!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlMap--;
}

core.Map<core.String, core.String> buildUnnamed64() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed64(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed65() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed65(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed66() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed66(core.Map<core.String, core.String> o) {
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

core.List<api.ErrorHandler> buildUnnamed67() {
  var o = <api.ErrorHandler>[];
  o.add(buildErrorHandler());
  o.add(buildErrorHandler());
  return o;
}

void checkUnnamed67(core.List<api.ErrorHandler> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkErrorHandler(o[0] as api.ErrorHandler);
  checkErrorHandler(o[1] as api.ErrorHandler);
}

core.List<api.UrlMap> buildUnnamed68() {
  var o = <api.UrlMap>[];
  o.add(buildUrlMap());
  o.add(buildUrlMap());
  return o;
}

void checkUnnamed68(core.List<api.UrlMap> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUrlMap(o[0] as api.UrlMap);
  checkUrlMap(o[1] as api.UrlMap);
}

core.List<core.String> buildUnnamed69() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed69(core.List<core.String> o) {
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

core.List<api.Library> buildUnnamed70() {
  var o = <api.Library>[];
  o.add(buildLibrary());
  o.add(buildLibrary());
  return o;
}

void checkUnnamed70(core.List<api.Library> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLibrary(o[0] as api.Library);
  checkLibrary(o[1] as api.Library);
}

core.List<core.String> buildUnnamed71() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed71(core.List<core.String> o) {
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

core.int buildCounterVersion = 0;
api.Version buildVersion() {
  var o = api.Version();
  buildCounterVersion++;
  if (buildCounterVersion < 3) {
    o.apiConfig = buildApiConfigHandler();
    o.automaticScaling = buildAutomaticScaling();
    o.basicScaling = buildBasicScaling();
    o.betaSettings = buildUnnamed64();
    o.buildEnvVariables = buildUnnamed65();
    o.createTime = 'foo';
    o.createdBy = 'foo';
    o.defaultExpiration = 'foo';
    o.deployment = buildDeployment();
    o.diskUsageBytes = 'foo';
    o.endpointsApiService = buildEndpointsApiService();
    o.entrypoint = buildEntrypoint();
    o.env = 'foo';
    o.envVariables = buildUnnamed66();
    o.errorHandlers = buildUnnamed67();
    o.handlers = buildUnnamed68();
    o.healthCheck = buildHealthCheck();
    o.id = 'foo';
    o.inboundServices = buildUnnamed69();
    o.instanceClass = 'foo';
    o.libraries = buildUnnamed70();
    o.livenessCheck = buildLivenessCheck();
    o.manualScaling = buildManualScaling();
    o.name = 'foo';
    o.network = buildNetwork();
    o.nobuildFilesRegex = 'foo';
    o.readinessCheck = buildReadinessCheck();
    o.resources = buildResources();
    o.runtime = 'foo';
    o.runtimeApiVersion = 'foo';
    o.runtimeChannel = 'foo';
    o.runtimeMainExecutablePath = 'foo';
    o.serviceAccount = 'foo';
    o.servingStatus = 'foo';
    o.threadsafe = true;
    o.versionUrl = 'foo';
    o.vm = true;
    o.vpcAccessConnector = buildVpcAccessConnector();
    o.zones = buildUnnamed71();
  }
  buildCounterVersion--;
  return o;
}

void checkVersion(api.Version o) {
  buildCounterVersion++;
  if (buildCounterVersion < 3) {
    checkApiConfigHandler(o.apiConfig! as api.ApiConfigHandler);
    checkAutomaticScaling(o.automaticScaling! as api.AutomaticScaling);
    checkBasicScaling(o.basicScaling! as api.BasicScaling);
    checkUnnamed64(o.betaSettings!);
    checkUnnamed65(o.buildEnvVariables!);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createdBy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultExpiration!,
      unittest.equals('foo'),
    );
    checkDeployment(o.deployment! as api.Deployment);
    unittest.expect(
      o.diskUsageBytes!,
      unittest.equals('foo'),
    );
    checkEndpointsApiService(o.endpointsApiService! as api.EndpointsApiService);
    checkEntrypoint(o.entrypoint! as api.Entrypoint);
    unittest.expect(
      o.env!,
      unittest.equals('foo'),
    );
    checkUnnamed66(o.envVariables!);
    checkUnnamed67(o.errorHandlers!);
    checkUnnamed68(o.handlers!);
    checkHealthCheck(o.healthCheck! as api.HealthCheck);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed69(o.inboundServices!);
    unittest.expect(
      o.instanceClass!,
      unittest.equals('foo'),
    );
    checkUnnamed70(o.libraries!);
    checkLivenessCheck(o.livenessCheck! as api.LivenessCheck);
    checkManualScaling(o.manualScaling! as api.ManualScaling);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkNetwork(o.network! as api.Network);
    unittest.expect(
      o.nobuildFilesRegex!,
      unittest.equals('foo'),
    );
    checkReadinessCheck(o.readinessCheck! as api.ReadinessCheck);
    checkResources(o.resources! as api.Resources);
    unittest.expect(
      o.runtime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.runtimeApiVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.runtimeChannel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.runtimeMainExecutablePath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.servingStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(o.threadsafe!, unittest.isTrue);
    unittest.expect(
      o.versionUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.vm!, unittest.isTrue);
    checkVpcAccessConnector(o.vpcAccessConnector! as api.VpcAccessConnector);
    checkUnnamed71(o.zones!);
  }
  buildCounterVersion--;
}

core.int buildCounterVolume = 0;
api.Volume buildVolume() {
  var o = api.Volume();
  buildCounterVolume++;
  if (buildCounterVolume < 3) {
    o.name = 'foo';
    o.sizeGb = 42.0;
    o.volumeType = 'foo';
  }
  buildCounterVolume--;
  return o;
}

void checkVolume(api.Volume o) {
  buildCounterVolume++;
  if (buildCounterVolume < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sizeGb!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.volumeType!,
      unittest.equals('foo'),
    );
  }
  buildCounterVolume--;
}

core.int buildCounterVpcAccessConnector = 0;
api.VpcAccessConnector buildVpcAccessConnector() {
  var o = api.VpcAccessConnector();
  buildCounterVpcAccessConnector++;
  if (buildCounterVpcAccessConnector < 3) {
    o.name = 'foo';
  }
  buildCounterVpcAccessConnector--;
  return o;
}

void checkVpcAccessConnector(api.VpcAccessConnector o) {
  buildCounterVpcAccessConnector++;
  if (buildCounterVpcAccessConnector < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterVpcAccessConnector--;
}

core.int buildCounterZipInfo = 0;
api.ZipInfo buildZipInfo() {
  var o = api.ZipInfo();
  buildCounterZipInfo++;
  if (buildCounterZipInfo < 3) {
    o.filesCount = 42;
    o.sourceUrl = 'foo';
  }
  buildCounterZipInfo--;
  return o;
}

void checkZipInfo(api.ZipInfo o) {
  buildCounterZipInfo++;
  if (buildCounterZipInfo < 3) {
    unittest.expect(
      o.filesCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sourceUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterZipInfo--;
}

void main() {
  unittest.group('obj-schema-ApiConfigHandler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApiConfigHandler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApiConfigHandler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApiConfigHandler(od as api.ApiConfigHandler);
    });
  });

  unittest.group('obj-schema-ApiEndpointHandler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApiEndpointHandler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApiEndpointHandler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApiEndpointHandler(od as api.ApiEndpointHandler);
    });
  });

  unittest.group('obj-schema-Application', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Application.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplication(od as api.Application);
    });
  });

  unittest.group('obj-schema-AuthorizedCertificate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthorizedCertificate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuthorizedCertificate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthorizedCertificate(od as api.AuthorizedCertificate);
    });
  });

  unittest.group('obj-schema-AuthorizedDomain', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthorizedDomain();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuthorizedDomain.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthorizedDomain(od as api.AuthorizedDomain);
    });
  });

  unittest.group('obj-schema-AutomaticScaling', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutomaticScaling();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AutomaticScaling.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAutomaticScaling(od as api.AutomaticScaling);
    });
  });

  unittest.group('obj-schema-BasicScaling', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBasicScaling();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BasicScaling.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBasicScaling(od as api.BasicScaling);
    });
  });

  unittest.group('obj-schema-BatchUpdateIngressRulesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateIngressRulesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateIngressRulesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateIngressRulesRequest(
          od as api.BatchUpdateIngressRulesRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdateIngressRulesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateIngressRulesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateIngressRulesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateIngressRulesResponse(
          od as api.BatchUpdateIngressRulesResponse);
    });
  });

  unittest.group('obj-schema-CertificateRawData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCertificateRawData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CertificateRawData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCertificateRawData(od as api.CertificateRawData);
    });
  });

  unittest.group('obj-schema-CloudBuildOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCloudBuildOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CloudBuildOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCloudBuildOptions(od as api.CloudBuildOptions);
    });
  });

  unittest.group('obj-schema-ContainerInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContainerInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContainerInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContainerInfo(od as api.ContainerInfo);
    });
  });

  unittest.group('obj-schema-CpuUtilization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCpuUtilization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CpuUtilization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCpuUtilization(od as api.CpuUtilization);
    });
  });

  unittest.group('obj-schema-CreateVersionMetadataV1', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateVersionMetadataV1();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateVersionMetadataV1.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateVersionMetadataV1(od as api.CreateVersionMetadataV1);
    });
  });

  unittest.group('obj-schema-CreateVersionMetadataV1Alpha', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateVersionMetadataV1Alpha();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateVersionMetadataV1Alpha.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateVersionMetadataV1Alpha(od as api.CreateVersionMetadataV1Alpha);
    });
  });

  unittest.group('obj-schema-CreateVersionMetadataV1Beta', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateVersionMetadataV1Beta();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateVersionMetadataV1Beta.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateVersionMetadataV1Beta(od as api.CreateVersionMetadataV1Beta);
    });
  });

  unittest.group('obj-schema-DebugInstanceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDebugInstanceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DebugInstanceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDebugInstanceRequest(od as api.DebugInstanceRequest);
    });
  });

  unittest.group('obj-schema-Deployment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeployment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Deployment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeployment(od as api.Deployment);
    });
  });

  unittest.group('obj-schema-DiskUtilization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDiskUtilization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DiskUtilization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDiskUtilization(od as api.DiskUtilization);
    });
  });

  unittest.group('obj-schema-DomainMapping', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomainMapping();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DomainMapping.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDomainMapping(od as api.DomainMapping);
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

  unittest.group('obj-schema-EndpointsApiService', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEndpointsApiService();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EndpointsApiService.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEndpointsApiService(od as api.EndpointsApiService);
    });
  });

  unittest.group('obj-schema-Entrypoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntrypoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Entrypoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEntrypoint(od as api.Entrypoint);
    });
  });

  unittest.group('obj-schema-ErrorHandler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildErrorHandler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ErrorHandler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkErrorHandler(od as api.ErrorHandler);
    });
  });

  unittest.group('obj-schema-FeatureSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatureSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeatureSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeatureSettings(od as api.FeatureSettings);
    });
  });

  unittest.group('obj-schema-FileInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFileInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FileInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFileInfo(od as api.FileInfo);
    });
  });

  unittest.group('obj-schema-FirewallRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirewallRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirewallRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirewallRule(od as api.FirewallRule);
    });
  });

  unittest.group('obj-schema-GoogleAppengineV1betaLocationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAppengineV1betaLocationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAppengineV1betaLocationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAppengineV1betaLocationMetadata(
          od as api.GoogleAppengineV1betaLocationMetadata);
    });
  });

  unittest.group('obj-schema-HealthCheck', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHealthCheck();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HealthCheck.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHealthCheck(od as api.HealthCheck);
    });
  });

  unittest.group('obj-schema-IdentityAwareProxy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdentityAwareProxy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IdentityAwareProxy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIdentityAwareProxy(od as api.IdentityAwareProxy);
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

  unittest.group('obj-schema-Library', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLibrary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Library.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLibrary(od as api.Library);
    });
  });

  unittest.group('obj-schema-ListAuthorizedCertificatesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAuthorizedCertificatesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAuthorizedCertificatesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAuthorizedCertificatesResponse(
          od as api.ListAuthorizedCertificatesResponse);
    });
  });

  unittest.group('obj-schema-ListAuthorizedDomainsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAuthorizedDomainsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAuthorizedDomainsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAuthorizedDomainsResponse(
          od as api.ListAuthorizedDomainsResponse);
    });
  });

  unittest.group('obj-schema-ListDomainMappingsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDomainMappingsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDomainMappingsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDomainMappingsResponse(od as api.ListDomainMappingsResponse);
    });
  });

  unittest.group('obj-schema-ListIngressRulesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListIngressRulesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListIngressRulesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListIngressRulesResponse(od as api.ListIngressRulesResponse);
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

  unittest.group('obj-schema-ListServicesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListServicesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListServicesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListServicesResponse(od as api.ListServicesResponse);
    });
  });

  unittest.group('obj-schema-ListVersionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListVersionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListVersionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListVersionsResponse(od as api.ListVersionsResponse);
    });
  });

  unittest.group('obj-schema-LivenessCheck', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivenessCheck();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LivenessCheck.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLivenessCheck(od as api.LivenessCheck);
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

  unittest.group('obj-schema-LocationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocationMetadata(od as api.LocationMetadata);
    });
  });

  unittest.group('obj-schema-ManagedCertificate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManagedCertificate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManagedCertificate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManagedCertificate(od as api.ManagedCertificate);
    });
  });

  unittest.group('obj-schema-ManualScaling', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManualScaling();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManualScaling.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManualScaling(od as api.ManualScaling);
    });
  });

  unittest.group('obj-schema-Network', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetwork();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Network.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNetwork(od as api.Network);
    });
  });

  unittest.group('obj-schema-NetworkSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkSettings(od as api.NetworkSettings);
    });
  });

  unittest.group('obj-schema-NetworkUtilization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNetworkUtilization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NetworkUtilization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNetworkUtilization(od as api.NetworkUtilization);
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

  unittest.group('obj-schema-OperationMetadataV1', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationMetadataV1();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationMetadataV1.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationMetadataV1(od as api.OperationMetadataV1);
    });
  });

  unittest.group('obj-schema-OperationMetadataV1Alpha', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationMetadataV1Alpha();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationMetadataV1Alpha.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationMetadataV1Alpha(od as api.OperationMetadataV1Alpha);
    });
  });

  unittest.group('obj-schema-OperationMetadataV1Beta', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationMetadataV1Beta();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationMetadataV1Beta.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationMetadataV1Beta(od as api.OperationMetadataV1Beta);
    });
  });

  unittest.group('obj-schema-ReadinessCheck', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReadinessCheck();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReadinessCheck.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReadinessCheck(od as api.ReadinessCheck);
    });
  });

  unittest.group('obj-schema-RepairApplicationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepairApplicationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RepairApplicationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRepairApplicationRequest(od as api.RepairApplicationRequest);
    });
  });

  unittest.group('obj-schema-RequestUtilization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequestUtilization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RequestUtilization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRequestUtilization(od as api.RequestUtilization);
    });
  });

  unittest.group('obj-schema-ResourceRecord', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResourceRecord();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResourceRecord.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResourceRecord(od as api.ResourceRecord);
    });
  });

  unittest.group('obj-schema-Resources', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResources();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Resources.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResources(od as api.Resources);
    });
  });

  unittest.group('obj-schema-ScriptHandler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScriptHandler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScriptHandler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScriptHandler(od as api.ScriptHandler);
    });
  });

  unittest.group('obj-schema-Service', () {
    unittest.test('to-json--from-json', () async {
      var o = buildService();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Service.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkService(od as api.Service);
    });
  });

  unittest.group('obj-schema-SslSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSslSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SslSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSslSettings(od as api.SslSettings);
    });
  });

  unittest.group('obj-schema-StandardSchedulerSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStandardSchedulerSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StandardSchedulerSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStandardSchedulerSettings(od as api.StandardSchedulerSettings);
    });
  });

  unittest.group('obj-schema-StaticFilesHandler', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStaticFilesHandler();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StaticFilesHandler.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStaticFilesHandler(od as api.StaticFilesHandler);
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

  unittest.group('obj-schema-TrafficSplit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrafficSplit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrafficSplit.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrafficSplit(od as api.TrafficSplit);
    });
  });

  unittest.group('obj-schema-UrlDispatchRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrlDispatchRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UrlDispatchRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUrlDispatchRule(od as api.UrlDispatchRule);
    });
  });

  unittest.group('obj-schema-UrlMap', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrlMap();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UrlMap.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUrlMap(od as api.UrlMap);
    });
  });

  unittest.group('obj-schema-Version', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Version.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVersion(od as api.Version);
    });
  });

  unittest.group('obj-schema-Volume', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVolume();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Volume.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkVolume(od as api.Volume);
    });
  });

  unittest.group('obj-schema-VpcAccessConnector', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVpcAccessConnector();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VpcAccessConnector.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVpcAccessConnector(od as api.VpcAccessConnector);
    });
  });

  unittest.group('obj-schema-ZipInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildZipInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ZipInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkZipInfo(od as api.ZipInfo);
    });
  });

  unittest.group('resource-AppsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps;
      var arg_request = buildApplication();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Application.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkApplication(obj as api.Application);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("v1/apps"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps;
      var arg_appsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildApplication());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_appsId, $fields: arg_$fields);
      checkApplication(response as api.Application);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps;
      var arg_request = buildApplication();
      var arg_appsId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Application.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkApplication(obj as api.Application);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
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
      final response = await res.patch(arg_request, arg_appsId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--repair', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps;
      var arg_request = buildRepairApplicationRequest();
      var arg_appsId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RepairApplicationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRepairApplicationRequest(obj as api.RepairApplicationRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf(':repair', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals(":repair"),
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
          await res.repair(arg_request, arg_appsId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-AppsAuthorizedCertificatesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.authorizedCertificates;
      var arg_request = buildAuthorizedCertificate();
      var arg_appsId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AuthorizedCertificate.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAuthorizedCertificate(obj as api.AuthorizedCertificate);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/authorizedCertificates', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("/authorizedCertificates"),
        );
        pathOffset += 23;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildAuthorizedCertificate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_appsId, $fields: arg_$fields);
      checkAuthorizedCertificate(response as api.AuthorizedCertificate);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.authorizedCertificates;
      var arg_appsId = 'foo';
      var arg_authorizedCertificatesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/authorizedCertificates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("/authorizedCertificates/"),
        );
        pathOffset += 24;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_authorizedCertificatesId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(
          arg_appsId, arg_authorizedCertificatesId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.authorizedCertificates;
      var arg_appsId = 'foo';
      var arg_authorizedCertificatesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/authorizedCertificates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("/authorizedCertificates/"),
        );
        pathOffset += 24;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_authorizedCertificatesId'),
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
        var resp = convert.json.encode(buildAuthorizedCertificate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_appsId, arg_authorizedCertificatesId,
          view: arg_view, $fields: arg_$fields);
      checkAuthorizedCertificate(response as api.AuthorizedCertificate);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.authorizedCertificates;
      var arg_appsId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/authorizedCertificates', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("/authorizedCertificates"),
        );
        pathOffset += 23;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp =
            convert.json.encode(buildListAuthorizedCertificatesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_appsId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListAuthorizedCertificatesResponse(
          response as api.ListAuthorizedCertificatesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.authorizedCertificates;
      var arg_request = buildAuthorizedCertificate();
      var arg_appsId = 'foo';
      var arg_authorizedCertificatesId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AuthorizedCertificate.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAuthorizedCertificate(obj as api.AuthorizedCertificate);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/authorizedCertificates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("/authorizedCertificates/"),
        );
        pathOffset += 24;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_authorizedCertificatesId'),
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
        var resp = convert.json.encode(buildAuthorizedCertificate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_appsId, arg_authorizedCertificatesId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAuthorizedCertificate(response as api.AuthorizedCertificate);
    });
  });

  unittest.group('resource-AppsAuthorizedDomainsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.authorizedDomains;
      var arg_appsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/authorizedDomains', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/authorizedDomains"),
        );
        pathOffset += 18;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildListAuthorizedDomainsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_appsId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAuthorizedDomainsResponse(
          response as api.ListAuthorizedDomainsResponse);
    });
  });

  unittest.group('resource-AppsDomainMappingsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.domainMappings;
      var arg_request = buildDomainMapping();
      var arg_appsId = 'foo';
      var arg_overrideStrategy = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DomainMapping.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDomainMapping(obj as api.DomainMapping);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/domainMappings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/domainMappings"),
        );
        pathOffset += 15;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["overrideStrategy"]!.first,
          unittest.equals(arg_overrideStrategy),
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
      final response = await res.create(arg_request, arg_appsId,
          overrideStrategy: arg_overrideStrategy, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.domainMappings;
      var arg_appsId = 'foo';
      var arg_domainMappingsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/domainMappings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/domainMappings/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainMappingsId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_appsId, arg_domainMappingsId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.domainMappings;
      var arg_appsId = 'foo';
      var arg_domainMappingsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/domainMappings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/domainMappings/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainMappingsId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDomainMapping());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_appsId, arg_domainMappingsId, $fields: arg_$fields);
      checkDomainMapping(response as api.DomainMapping);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.domainMappings;
      var arg_appsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/domainMappings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/domainMappings"),
        );
        pathOffset += 15;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildListDomainMappingsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_appsId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDomainMappingsResponse(
          response as api.ListDomainMappingsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.domainMappings;
      var arg_request = buildDomainMapping();
      var arg_appsId = 'foo';
      var arg_domainMappingsId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DomainMapping.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDomainMapping(obj as api.DomainMapping);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/domainMappings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/domainMappings/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainMappingsId'),
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
      final response = await res.patch(
          arg_request, arg_appsId, arg_domainMappingsId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-AppsFirewallIngressRulesResource', () {
    unittest.test('method--batchUpdate', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.firewall.ingressRules;
      var arg_request = buildBatchUpdateIngressRulesRequest();
      var arg_appsId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdateIngressRulesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdateIngressRulesRequest(
            obj as api.BatchUpdateIngressRulesRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/firewall/ingressRules:batchUpdate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 34),
          unittest.equals("/firewall/ingressRules:batchUpdate"),
        );
        pathOffset += 34;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildBatchUpdateIngressRulesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.batchUpdate(arg_request, arg_appsId, $fields: arg_$fields);
      checkBatchUpdateIngressRulesResponse(
          response as api.BatchUpdateIngressRulesResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.firewall.ingressRules;
      var arg_request = buildFirewallRule();
      var arg_appsId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FirewallRule.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFirewallRule(obj as api.FirewallRule);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/firewall/ingressRules', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/firewall/ingressRules"),
        );
        pathOffset += 22;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildFirewallRule());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_appsId, $fields: arg_$fields);
      checkFirewallRule(response as api.FirewallRule);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.firewall.ingressRules;
      var arg_appsId = 'foo';
      var arg_ingressRulesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/firewall/ingressRules/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("/firewall/ingressRules/"),
        );
        pathOffset += 23;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_ingressRulesId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_appsId, arg_ingressRulesId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.firewall.ingressRules;
      var arg_appsId = 'foo';
      var arg_ingressRulesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/firewall/ingressRules/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("/firewall/ingressRules/"),
        );
        pathOffset += 23;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_ingressRulesId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFirewallRule());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_appsId, arg_ingressRulesId, $fields: arg_$fields);
      checkFirewallRule(response as api.FirewallRule);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.firewall.ingressRules;
      var arg_appsId = 'foo';
      var arg_matchingAddress = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/firewall/ingressRules', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/firewall/ingressRules"),
        );
        pathOffset += 22;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["matchingAddress"]!.first,
          unittest.equals(arg_matchingAddress),
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
        var resp = convert.json.encode(buildListIngressRulesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_appsId,
          matchingAddress: arg_matchingAddress,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListIngressRulesResponse(response as api.ListIngressRulesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.firewall.ingressRules;
      var arg_request = buildFirewallRule();
      var arg_appsId = 'foo';
      var arg_ingressRulesId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FirewallRule.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFirewallRule(obj as api.FirewallRule);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/firewall/ingressRules/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("/firewall/ingressRules/"),
        );
        pathOffset += 23;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_ingressRulesId'),
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
        var resp = convert.json.encode(buildFirewallRule());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_appsId, arg_ingressRulesId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkFirewallRule(response as api.FirewallRule);
    });
  });

  unittest.group('resource-AppsLocationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.locations;
      var arg_appsId = 'foo';
      var arg_locationsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/locations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/locations/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_locationsId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLocation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_appsId, arg_locationsId, $fields: arg_$fields);
      checkLocation(response as api.Location);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.locations;
      var arg_appsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/locations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/locations"),
        );
        pathOffset += 10;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
      final response = await res.list(arg_appsId,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationsResponse(response as api.ListLocationsResponse);
    });
  });

  unittest.group('resource-AppsOperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.operations;
      var arg_appsId = 'foo';
      var arg_operationsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/operations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
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
          unittest.equals('$arg_operationsId'),
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
          await res.get(arg_appsId, arg_operationsId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.operations;
      var arg_appsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/operations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
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
      final response = await res.list(arg_appsId,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });

  unittest.group('resource-AppsServicesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
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
          await res.delete(arg_appsId, arg_servicesId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildService());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_appsId, arg_servicesId, $fields: arg_$fields);
      checkService(response as api.Service);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services;
      var arg_appsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/services"),
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
        var resp = convert.json.encode(buildListServicesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_appsId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListServicesResponse(response as api.ListServicesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services;
      var arg_request = buildService();
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_migrateTraffic = true;
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Service.fromJson(json as core.Map<core.String, core.dynamic>);
        checkService(obj as api.Service);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
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
          queryMap["migrateTraffic"]!.first,
          unittest.equals("$arg_migrateTraffic"),
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
      final response = await res.patch(arg_request, arg_appsId, arg_servicesId,
          migrateTraffic: arg_migrateTraffic,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-AppsServicesVersionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions;
      var arg_request = buildVersion();
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Version.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVersion(obj as api.Version);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/versions"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_appsId, arg_servicesId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(
          arg_appsId, arg_servicesId, arg_versionsId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
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
        var resp = convert.json.encode(buildVersion());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_appsId, arg_servicesId, arg_versionsId,
          view: arg_view, $fields: arg_$fields);
      checkVersion(response as api.Version);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/versions"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
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
        var resp = convert.json.encode(buildListVersionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_appsId, arg_servicesId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListVersionsResponse(response as api.ListVersionsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions;
      var arg_request = buildVersion();
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Version.fromJson(json as core.Map<core.String, core.dynamic>);
        checkVersion(obj as api.Version);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
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
      final response = await res.patch(
          arg_request, arg_appsId, arg_servicesId, arg_versionsId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-AppsServicesVersionsInstancesResource', () {
    unittest.test('method--debug', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions.instances;
      var arg_request = buildDebugInstanceRequest();
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
      var arg_instancesId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DebugInstanceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDebugInstanceRequest(obj as api.DebugInstanceRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/instances/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/instances/"),
        );
        pathOffset += 11;
        index = path.indexOf(':debug', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_instancesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals(":debug"),
        );
        pathOffset += 6;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
      final response = await res.debug(arg_request, arg_appsId, arg_servicesId,
          arg_versionsId, arg_instancesId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions.instances;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
      var arg_instancesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/instances/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/instances/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_instancesId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(
          arg_appsId, arg_servicesId, arg_versionsId, arg_instancesId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions.instances;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
      var arg_instancesId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/instances/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/instances/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_instancesId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInstance());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_appsId, arg_servicesId, arg_versionsId, arg_instancesId,
          $fields: arg_$fields);
      checkInstance(response as api.Instance);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AppengineApi(mock).apps.services.versions.instances;
      var arg_appsId = 'foo';
      var arg_servicesId = 'foo';
      var arg_versionsId = 'foo';
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/apps/"),
        );
        pathOffset += 8;
        index = path.indexOf('/services/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_appsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/services/"),
        );
        pathOffset += 10;
        index = path.indexOf('/versions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_servicesId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/versions/"),
        );
        pathOffset += 10;
        index = path.indexOf('/instances', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_versionsId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/instances"),
        );
        pathOffset += 10;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
      final response = await res.list(
          arg_appsId, arg_servicesId, arg_versionsId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInstancesResponse(response as api.ListInstancesResponse);
    });
  });
}
