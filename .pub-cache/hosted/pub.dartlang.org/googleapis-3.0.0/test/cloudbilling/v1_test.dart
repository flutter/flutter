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

import 'package:googleapis/cloudbilling/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAggregationInfo = 0;
api.AggregationInfo buildAggregationInfo() {
  var o = api.AggregationInfo();
  buildCounterAggregationInfo++;
  if (buildCounterAggregationInfo < 3) {
    o.aggregationCount = 42;
    o.aggregationInterval = 'foo';
    o.aggregationLevel = 'foo';
  }
  buildCounterAggregationInfo--;
  return o;
}

void checkAggregationInfo(api.AggregationInfo o) {
  buildCounterAggregationInfo++;
  if (buildCounterAggregationInfo < 3) {
    unittest.expect(
      o.aggregationCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.aggregationInterval!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.aggregationLevel!,
      unittest.equals('foo'),
    );
  }
  buildCounterAggregationInfo--;
}

core.List<api.AuditLogConfig> buildUnnamed2926() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed2926(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed2926();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed2926(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed2927() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2927(core.List<core.String> o) {
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
    o.exemptedMembers = buildUnnamed2927();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed2927(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.int buildCounterBillingAccount = 0;
api.BillingAccount buildBillingAccount() {
  var o = api.BillingAccount();
  buildCounterBillingAccount++;
  if (buildCounterBillingAccount < 3) {
    o.displayName = 'foo';
    o.masterBillingAccount = 'foo';
    o.name = 'foo';
    o.open = true;
  }
  buildCounterBillingAccount--;
  return o;
}

void checkBillingAccount(api.BillingAccount o) {
  buildCounterBillingAccount++;
  if (buildCounterBillingAccount < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.masterBillingAccount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.open!, unittest.isTrue);
  }
  buildCounterBillingAccount--;
}

core.List<core.String> buildUnnamed2928() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2928(core.List<core.String> o) {
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
    o.members = buildUnnamed2928();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed2928(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterCategory = 0;
api.Category buildCategory() {
  var o = api.Category();
  buildCounterCategory++;
  if (buildCounterCategory < 3) {
    o.resourceFamily = 'foo';
    o.resourceGroup = 'foo';
    o.serviceDisplayName = 'foo';
    o.usageType = 'foo';
  }
  buildCounterCategory--;
  return o;
}

void checkCategory(api.Category o) {
  buildCounterCategory++;
  if (buildCounterCategory < 3) {
    unittest.expect(
      o.resourceFamily!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.usageType!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategory--;
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

core.List<core.String> buildUnnamed2929() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2929(core.List<core.String> o) {
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

core.int buildCounterGeoTaxonomy = 0;
api.GeoTaxonomy buildGeoTaxonomy() {
  var o = api.GeoTaxonomy();
  buildCounterGeoTaxonomy++;
  if (buildCounterGeoTaxonomy < 3) {
    o.regions = buildUnnamed2929();
    o.type = 'foo';
  }
  buildCounterGeoTaxonomy--;
  return o;
}

void checkGeoTaxonomy(api.GeoTaxonomy o) {
  buildCounterGeoTaxonomy++;
  if (buildCounterGeoTaxonomy < 3) {
    checkUnnamed2929(o.regions!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterGeoTaxonomy--;
}

core.List<api.BillingAccount> buildUnnamed2930() {
  var o = <api.BillingAccount>[];
  o.add(buildBillingAccount());
  o.add(buildBillingAccount());
  return o;
}

void checkUnnamed2930(core.List<api.BillingAccount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBillingAccount(o[0] as api.BillingAccount);
  checkBillingAccount(o[1] as api.BillingAccount);
}

core.int buildCounterListBillingAccountsResponse = 0;
api.ListBillingAccountsResponse buildListBillingAccountsResponse() {
  var o = api.ListBillingAccountsResponse();
  buildCounterListBillingAccountsResponse++;
  if (buildCounterListBillingAccountsResponse < 3) {
    o.billingAccounts = buildUnnamed2930();
    o.nextPageToken = 'foo';
  }
  buildCounterListBillingAccountsResponse--;
  return o;
}

void checkListBillingAccountsResponse(api.ListBillingAccountsResponse o) {
  buildCounterListBillingAccountsResponse++;
  if (buildCounterListBillingAccountsResponse < 3) {
    checkUnnamed2930(o.billingAccounts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListBillingAccountsResponse--;
}

core.List<api.ProjectBillingInfo> buildUnnamed2931() {
  var o = <api.ProjectBillingInfo>[];
  o.add(buildProjectBillingInfo());
  o.add(buildProjectBillingInfo());
  return o;
}

void checkUnnamed2931(core.List<api.ProjectBillingInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProjectBillingInfo(o[0] as api.ProjectBillingInfo);
  checkProjectBillingInfo(o[1] as api.ProjectBillingInfo);
}

core.int buildCounterListProjectBillingInfoResponse = 0;
api.ListProjectBillingInfoResponse buildListProjectBillingInfoResponse() {
  var o = api.ListProjectBillingInfoResponse();
  buildCounterListProjectBillingInfoResponse++;
  if (buildCounterListProjectBillingInfoResponse < 3) {
    o.nextPageToken = 'foo';
    o.projectBillingInfo = buildUnnamed2931();
  }
  buildCounterListProjectBillingInfoResponse--;
  return o;
}

void checkListProjectBillingInfoResponse(api.ListProjectBillingInfoResponse o) {
  buildCounterListProjectBillingInfoResponse++;
  if (buildCounterListProjectBillingInfoResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2931(o.projectBillingInfo!);
  }
  buildCounterListProjectBillingInfoResponse--;
}

core.List<api.Service> buildUnnamed2932() {
  var o = <api.Service>[];
  o.add(buildService());
  o.add(buildService());
  return o;
}

void checkUnnamed2932(core.List<api.Service> o) {
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
    o.services = buildUnnamed2932();
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
    checkUnnamed2932(o.services!);
  }
  buildCounterListServicesResponse--;
}

core.List<api.Sku> buildUnnamed2933() {
  var o = <api.Sku>[];
  o.add(buildSku());
  o.add(buildSku());
  return o;
}

void checkUnnamed2933(core.List<api.Sku> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSku(o[0] as api.Sku);
  checkSku(o[1] as api.Sku);
}

core.int buildCounterListSkusResponse = 0;
api.ListSkusResponse buildListSkusResponse() {
  var o = api.ListSkusResponse();
  buildCounterListSkusResponse++;
  if (buildCounterListSkusResponse < 3) {
    o.nextPageToken = 'foo';
    o.skus = buildUnnamed2933();
  }
  buildCounterListSkusResponse--;
  return o;
}

void checkListSkusResponse(api.ListSkusResponse o) {
  buildCounterListSkusResponse++;
  if (buildCounterListSkusResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed2933(o.skus!);
  }
  buildCounterListSkusResponse--;
}

core.int buildCounterMoney = 0;
api.Money buildMoney() {
  var o = api.Money();
  buildCounterMoney++;
  if (buildCounterMoney < 3) {
    o.currencyCode = 'foo';
    o.nanos = 42;
    o.units = 'foo';
  }
  buildCounterMoney--;
  return o;
}

void checkMoney(api.Money o) {
  buildCounterMoney++;
  if (buildCounterMoney < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.units!,
      unittest.equals('foo'),
    );
  }
  buildCounterMoney--;
}

core.List<api.AuditConfig> buildUnnamed2934() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed2934(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed2935() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed2935(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed2934();
    o.bindings = buildUnnamed2935();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed2934(o.auditConfigs!);
    checkUnnamed2935(o.bindings!);
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

core.List<api.TierRate> buildUnnamed2936() {
  var o = <api.TierRate>[];
  o.add(buildTierRate());
  o.add(buildTierRate());
  return o;
}

void checkUnnamed2936(core.List<api.TierRate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTierRate(o[0] as api.TierRate);
  checkTierRate(o[1] as api.TierRate);
}

core.int buildCounterPricingExpression = 0;
api.PricingExpression buildPricingExpression() {
  var o = api.PricingExpression();
  buildCounterPricingExpression++;
  if (buildCounterPricingExpression < 3) {
    o.baseUnit = 'foo';
    o.baseUnitConversionFactor = 42.0;
    o.baseUnitDescription = 'foo';
    o.displayQuantity = 42.0;
    o.tieredRates = buildUnnamed2936();
    o.usageUnit = 'foo';
    o.usageUnitDescription = 'foo';
  }
  buildCounterPricingExpression--;
  return o;
}

void checkPricingExpression(api.PricingExpression o) {
  buildCounterPricingExpression++;
  if (buildCounterPricingExpression < 3) {
    unittest.expect(
      o.baseUnit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.baseUnitConversionFactor!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.baseUnitDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayQuantity!,
      unittest.equals(42.0),
    );
    checkUnnamed2936(o.tieredRates!);
    unittest.expect(
      o.usageUnit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.usageUnitDescription!,
      unittest.equals('foo'),
    );
  }
  buildCounterPricingExpression--;
}

core.int buildCounterPricingInfo = 0;
api.PricingInfo buildPricingInfo() {
  var o = api.PricingInfo();
  buildCounterPricingInfo++;
  if (buildCounterPricingInfo < 3) {
    o.aggregationInfo = buildAggregationInfo();
    o.currencyConversionRate = 42.0;
    o.effectiveTime = 'foo';
    o.pricingExpression = buildPricingExpression();
    o.summary = 'foo';
  }
  buildCounterPricingInfo--;
  return o;
}

void checkPricingInfo(api.PricingInfo o) {
  buildCounterPricingInfo++;
  if (buildCounterPricingInfo < 3) {
    checkAggregationInfo(o.aggregationInfo! as api.AggregationInfo);
    unittest.expect(
      o.currencyConversionRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.effectiveTime!,
      unittest.equals('foo'),
    );
    checkPricingExpression(o.pricingExpression! as api.PricingExpression);
    unittest.expect(
      o.summary!,
      unittest.equals('foo'),
    );
  }
  buildCounterPricingInfo--;
}

core.int buildCounterProjectBillingInfo = 0;
api.ProjectBillingInfo buildProjectBillingInfo() {
  var o = api.ProjectBillingInfo();
  buildCounterProjectBillingInfo++;
  if (buildCounterProjectBillingInfo < 3) {
    o.billingAccountName = 'foo';
    o.billingEnabled = true;
    o.name = 'foo';
    o.projectId = 'foo';
  }
  buildCounterProjectBillingInfo--;
  return o;
}

void checkProjectBillingInfo(api.ProjectBillingInfo o) {
  buildCounterProjectBillingInfo++;
  if (buildCounterProjectBillingInfo < 3) {
    unittest.expect(
      o.billingAccountName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.billingEnabled!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterProjectBillingInfo--;
}

core.int buildCounterService = 0;
api.Service buildService() {
  var o = api.Service();
  buildCounterService++;
  if (buildCounterService < 3) {
    o.businessEntityName = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
    o.serviceId = 'foo';
  }
  buildCounterService--;
  return o;
}

void checkService(api.Service o) {
  buildCounterService++;
  if (buildCounterService < 3) {
    unittest.expect(
      o.businessEntityName!,
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
    unittest.expect(
      o.serviceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterService--;
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

core.List<api.PricingInfo> buildUnnamed2937() {
  var o = <api.PricingInfo>[];
  o.add(buildPricingInfo());
  o.add(buildPricingInfo());
  return o;
}

void checkUnnamed2937(core.List<api.PricingInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPricingInfo(o[0] as api.PricingInfo);
  checkPricingInfo(o[1] as api.PricingInfo);
}

core.List<core.String> buildUnnamed2938() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2938(core.List<core.String> o) {
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

core.int buildCounterSku = 0;
api.Sku buildSku() {
  var o = api.Sku();
  buildCounterSku++;
  if (buildCounterSku < 3) {
    o.category = buildCategory();
    o.description = 'foo';
    o.geoTaxonomy = buildGeoTaxonomy();
    o.name = 'foo';
    o.pricingInfo = buildUnnamed2937();
    o.serviceProviderName = 'foo';
    o.serviceRegions = buildUnnamed2938();
    o.skuId = 'foo';
  }
  buildCounterSku--;
  return o;
}

void checkSku(api.Sku o) {
  buildCounterSku++;
  if (buildCounterSku < 3) {
    checkCategory(o.category! as api.Category);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkGeoTaxonomy(o.geoTaxonomy! as api.GeoTaxonomy);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2937(o.pricingInfo!);
    unittest.expect(
      o.serviceProviderName!,
      unittest.equals('foo'),
    );
    checkUnnamed2938(o.serviceRegions!);
    unittest.expect(
      o.skuId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSku--;
}

core.List<core.String> buildUnnamed2939() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2939(core.List<core.String> o) {
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
    o.permissions = buildUnnamed2939();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed2939(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed2940() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2940(core.List<core.String> o) {
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
    o.permissions = buildUnnamed2940();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed2940(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterTierRate = 0;
api.TierRate buildTierRate() {
  var o = api.TierRate();
  buildCounterTierRate++;
  if (buildCounterTierRate < 3) {
    o.startUsageAmount = 42.0;
    o.unitPrice = buildMoney();
  }
  buildCounterTierRate--;
  return o;
}

void checkTierRate(api.TierRate o) {
  buildCounterTierRate++;
  if (buildCounterTierRate < 3) {
    unittest.expect(
      o.startUsageAmount!,
      unittest.equals(42.0),
    );
    checkMoney(o.unitPrice! as api.Money);
  }
  buildCounterTierRate--;
}

void main() {
  unittest.group('obj-schema-AggregationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAggregationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AggregationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAggregationInfo(od as api.AggregationInfo);
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

  unittest.group('obj-schema-BillingAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBillingAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BillingAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBillingAccount(od as api.BillingAccount);
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

  unittest.group('obj-schema-Category', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Category.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCategory(od as api.Category);
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

  unittest.group('obj-schema-GeoTaxonomy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeoTaxonomy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GeoTaxonomy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGeoTaxonomy(od as api.GeoTaxonomy);
    });
  });

  unittest.group('obj-schema-ListBillingAccountsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListBillingAccountsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListBillingAccountsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListBillingAccountsResponse(od as api.ListBillingAccountsResponse);
    });
  });

  unittest.group('obj-schema-ListProjectBillingInfoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListProjectBillingInfoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListProjectBillingInfoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListProjectBillingInfoResponse(
          od as api.ListProjectBillingInfoResponse);
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

  unittest.group('obj-schema-ListSkusResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSkusResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSkusResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSkusResponse(od as api.ListSkusResponse);
    });
  });

  unittest.group('obj-schema-Money', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMoney();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Money.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMoney(od as api.Money);
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

  unittest.group('obj-schema-PricingExpression', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPricingExpression();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PricingExpression.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPricingExpression(od as api.PricingExpression);
    });
  });

  unittest.group('obj-schema-PricingInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPricingInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PricingInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPricingInfo(od as api.PricingInfo);
    });
  });

  unittest.group('obj-schema-ProjectBillingInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectBillingInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectBillingInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectBillingInfo(od as api.ProjectBillingInfo);
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

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-Sku', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSku();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Sku.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSku(od as api.Sku);
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

  unittest.group('obj-schema-TierRate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTierRate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TierRate.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTierRate(od as api.TierRate);
    });
  });

  unittest.group('resource-BillingAccountsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).billingAccounts;
      var arg_request = buildBillingAccount();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BillingAccount.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBillingAccount(obj as api.BillingAccount);

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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("v1/billingAccounts"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBillingAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkBillingAccount(response as api.BillingAccount);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).billingAccounts;
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
        var resp = convert.json.encode(buildBillingAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkBillingAccount(response as api.BillingAccount);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).billingAccounts;
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
      var res = api.CloudbillingApi(mock).billingAccounts;
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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("v1/billingAccounts"),
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
        var resp = convert.json.encode(buildListBillingAccountsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListBillingAccountsResponse(
          response as api.ListBillingAccountsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).billingAccounts;
      var arg_request = buildBillingAccount();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BillingAccount.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBillingAccount(obj as api.BillingAccount);

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
        var resp = convert.json.encode(buildBillingAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkBillingAccount(response as api.BillingAccount);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).billingAccounts;
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
      var res = api.CloudbillingApi(mock).billingAccounts;
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

  unittest.group('resource-BillingAccountsProjectsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).billingAccounts.projects;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildListProjectBillingInfoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListProjectBillingInfoResponse(
          response as api.ListProjectBillingInfoResponse);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--getBillingInfo', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).projects;
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
        var resp = convert.json.encode(buildProjectBillingInfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getBillingInfo(arg_name, $fields: arg_$fields);
      checkProjectBillingInfo(response as api.ProjectBillingInfo);
    });

    unittest.test('method--updateBillingInfo', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).projects;
      var arg_request = buildProjectBillingInfo();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ProjectBillingInfo.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkProjectBillingInfo(obj as api.ProjectBillingInfo);

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
        var resp = convert.json.encode(buildProjectBillingInfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateBillingInfo(arg_request, arg_name,
          $fields: arg_$fields);
      checkProjectBillingInfo(response as api.ProjectBillingInfo);
    });
  });

  unittest.group('resource-ServicesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).services;
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
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("v1/services"),
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
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListServicesResponse(response as api.ListServicesResponse);
    });
  });

  unittest.group('resource-ServicesSkusResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudbillingApi(mock).services.skus;
      var arg_parent = 'foo';
      var arg_currencyCode = 'foo';
      var arg_endTime = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_startTime = 'foo';
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
          queryMap["currencyCode"]!.first,
          unittest.equals(arg_currencyCode),
        );
        unittest.expect(
          queryMap["endTime"]!.first,
          unittest.equals(arg_endTime),
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
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListSkusResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          currencyCode: arg_currencyCode,
          endTime: arg_endTime,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          startTime: arg_startTime,
          $fields: arg_$fields);
      checkListSkusResponse(response as api.ListSkusResponse);
    });
  });
}
