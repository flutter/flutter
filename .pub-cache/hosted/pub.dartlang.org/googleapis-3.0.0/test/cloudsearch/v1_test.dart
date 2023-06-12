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

import 'package:googleapis/cloudsearch/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAuditLoggingSettings = 0;
api.AuditLoggingSettings buildAuditLoggingSettings() {
  var o = api.AuditLoggingSettings();
  buildCounterAuditLoggingSettings++;
  if (buildCounterAuditLoggingSettings < 3) {
    o.logAdminReadActions = true;
    o.logDataReadActions = true;
    o.logDataWriteActions = true;
    o.project = 'foo';
  }
  buildCounterAuditLoggingSettings--;
  return o;
}

void checkAuditLoggingSettings(api.AuditLoggingSettings o) {
  buildCounterAuditLoggingSettings++;
  if (buildCounterAuditLoggingSettings < 3) {
    unittest.expect(o.logAdminReadActions!, unittest.isTrue);
    unittest.expect(o.logDataReadActions!, unittest.isTrue);
    unittest.expect(o.logDataWriteActions!, unittest.isTrue);
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLoggingSettings--;
}

core.int buildCounterBooleanOperatorOptions = 0;
api.BooleanOperatorOptions buildBooleanOperatorOptions() {
  var o = api.BooleanOperatorOptions();
  buildCounterBooleanOperatorOptions++;
  if (buildCounterBooleanOperatorOptions < 3) {
    o.operatorName = 'foo';
  }
  buildCounterBooleanOperatorOptions--;
  return o;
}

void checkBooleanOperatorOptions(api.BooleanOperatorOptions o) {
  buildCounterBooleanOperatorOptions++;
  if (buildCounterBooleanOperatorOptions < 3) {
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterBooleanOperatorOptions--;
}

core.int buildCounterBooleanPropertyOptions = 0;
api.BooleanPropertyOptions buildBooleanPropertyOptions() {
  var o = api.BooleanPropertyOptions();
  buildCounterBooleanPropertyOptions++;
  if (buildCounterBooleanPropertyOptions < 3) {
    o.operatorOptions = buildBooleanOperatorOptions();
  }
  buildCounterBooleanPropertyOptions--;
  return o;
}

void checkBooleanPropertyOptions(api.BooleanPropertyOptions o) {
  buildCounterBooleanPropertyOptions++;
  if (buildCounterBooleanPropertyOptions < 3) {
    checkBooleanOperatorOptions(
        o.operatorOptions! as api.BooleanOperatorOptions);
  }
  buildCounterBooleanPropertyOptions--;
}

core.int buildCounterCheckAccessResponse = 0;
api.CheckAccessResponse buildCheckAccessResponse() {
  var o = api.CheckAccessResponse();
  buildCounterCheckAccessResponse++;
  if (buildCounterCheckAccessResponse < 3) {
    o.hasAccess = true;
  }
  buildCounterCheckAccessResponse--;
  return o;
}

void checkCheckAccessResponse(api.CheckAccessResponse o) {
  buildCounterCheckAccessResponse++;
  if (buildCounterCheckAccessResponse < 3) {
    unittest.expect(o.hasAccess!, unittest.isTrue);
  }
  buildCounterCheckAccessResponse--;
}

core.List<api.Filter> buildUnnamed4128() {
  var o = <api.Filter>[];
  o.add(buildFilter());
  o.add(buildFilter());
  return o;
}

void checkUnnamed4128(core.List<api.Filter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilter(o[0] as api.Filter);
  checkFilter(o[1] as api.Filter);
}

core.int buildCounterCompositeFilter = 0;
api.CompositeFilter buildCompositeFilter() {
  var o = api.CompositeFilter();
  buildCounterCompositeFilter++;
  if (buildCounterCompositeFilter < 3) {
    o.logicOperator = 'foo';
    o.subFilters = buildUnnamed4128();
  }
  buildCounterCompositeFilter--;
  return o;
}

void checkCompositeFilter(api.CompositeFilter o) {
  buildCounterCompositeFilter++;
  if (buildCounterCompositeFilter < 3) {
    unittest.expect(
      o.logicOperator!,
      unittest.equals('foo'),
    );
    checkUnnamed4128(o.subFilters!);
  }
  buildCounterCompositeFilter--;
}

core.List<core.String> buildUnnamed4129() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4129(core.List<core.String> o) {
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

core.int buildCounterContextAttribute = 0;
api.ContextAttribute buildContextAttribute() {
  var o = api.ContextAttribute();
  buildCounterContextAttribute++;
  if (buildCounterContextAttribute < 3) {
    o.name = 'foo';
    o.values = buildUnnamed4129();
  }
  buildCounterContextAttribute--;
  return o;
}

void checkContextAttribute(api.ContextAttribute o) {
  buildCounterContextAttribute++;
  if (buildCounterContextAttribute < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4129(o.values!);
  }
  buildCounterContextAttribute--;
}

core.List<api.ItemCountByStatus> buildUnnamed4130() {
  var o = <api.ItemCountByStatus>[];
  o.add(buildItemCountByStatus());
  o.add(buildItemCountByStatus());
  return o;
}

void checkUnnamed4130(core.List<api.ItemCountByStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkItemCountByStatus(o[0] as api.ItemCountByStatus);
  checkItemCountByStatus(o[1] as api.ItemCountByStatus);
}

core.int buildCounterCustomerIndexStats = 0;
api.CustomerIndexStats buildCustomerIndexStats() {
  var o = api.CustomerIndexStats();
  buildCounterCustomerIndexStats++;
  if (buildCounterCustomerIndexStats < 3) {
    o.date = buildDate();
    o.itemCountByStatus = buildUnnamed4130();
  }
  buildCounterCustomerIndexStats--;
  return o;
}

void checkCustomerIndexStats(api.CustomerIndexStats o) {
  buildCounterCustomerIndexStats++;
  if (buildCounterCustomerIndexStats < 3) {
    checkDate(o.date! as api.Date);
    checkUnnamed4130(o.itemCountByStatus!);
  }
  buildCounterCustomerIndexStats--;
}

core.List<api.QueryCountByStatus> buildUnnamed4131() {
  var o = <api.QueryCountByStatus>[];
  o.add(buildQueryCountByStatus());
  o.add(buildQueryCountByStatus());
  return o;
}

void checkUnnamed4131(core.List<api.QueryCountByStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryCountByStatus(o[0] as api.QueryCountByStatus);
  checkQueryCountByStatus(o[1] as api.QueryCountByStatus);
}

core.int buildCounterCustomerQueryStats = 0;
api.CustomerQueryStats buildCustomerQueryStats() {
  var o = api.CustomerQueryStats();
  buildCounterCustomerQueryStats++;
  if (buildCounterCustomerQueryStats < 3) {
    o.date = buildDate();
    o.queryCountByStatus = buildUnnamed4131();
  }
  buildCounterCustomerQueryStats--;
  return o;
}

void checkCustomerQueryStats(api.CustomerQueryStats o) {
  buildCounterCustomerQueryStats++;
  if (buildCounterCustomerQueryStats < 3) {
    checkDate(o.date! as api.Date);
    checkUnnamed4131(o.queryCountByStatus!);
  }
  buildCounterCustomerQueryStats--;
}

core.int buildCounterCustomerSessionStats = 0;
api.CustomerSessionStats buildCustomerSessionStats() {
  var o = api.CustomerSessionStats();
  buildCounterCustomerSessionStats++;
  if (buildCounterCustomerSessionStats < 3) {
    o.date = buildDate();
    o.searchSessionsCount = 'foo';
  }
  buildCounterCustomerSessionStats--;
  return o;
}

void checkCustomerSessionStats(api.CustomerSessionStats o) {
  buildCounterCustomerSessionStats++;
  if (buildCounterCustomerSessionStats < 3) {
    checkDate(o.date! as api.Date);
    unittest.expect(
      o.searchSessionsCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerSessionStats--;
}

core.int buildCounterCustomerSettings = 0;
api.CustomerSettings buildCustomerSettings() {
  var o = api.CustomerSettings();
  buildCounterCustomerSettings++;
  if (buildCounterCustomerSettings < 3) {
    o.auditLoggingSettings = buildAuditLoggingSettings();
    o.vpcSettings = buildVPCSettings();
  }
  buildCounterCustomerSettings--;
  return o;
}

void checkCustomerSettings(api.CustomerSettings o) {
  buildCounterCustomerSettings++;
  if (buildCounterCustomerSettings < 3) {
    checkAuditLoggingSettings(
        o.auditLoggingSettings! as api.AuditLoggingSettings);
    checkVPCSettings(o.vpcSettings! as api.VPCSettings);
  }
  buildCounterCustomerSettings--;
}

core.int buildCounterCustomerUserStats = 0;
api.CustomerUserStats buildCustomerUserStats() {
  var o = api.CustomerUserStats();
  buildCounterCustomerUserStats++;
  if (buildCounterCustomerUserStats < 3) {
    o.date = buildDate();
    o.oneDayActiveUsersCount = 'foo';
    o.sevenDaysActiveUsersCount = 'foo';
    o.thirtyDaysActiveUsersCount = 'foo';
  }
  buildCounterCustomerUserStats--;
  return o;
}

void checkCustomerUserStats(api.CustomerUserStats o) {
  buildCounterCustomerUserStats++;
  if (buildCounterCustomerUserStats < 3) {
    checkDate(o.date! as api.Date);
    unittest.expect(
      o.oneDayActiveUsersCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sevenDaysActiveUsersCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thirtyDaysActiveUsersCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerUserStats--;
}

core.List<core.String> buildUnnamed4132() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4132(core.List<core.String> o) {
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

core.List<api.GSuitePrincipal> buildUnnamed4133() {
  var o = <api.GSuitePrincipal>[];
  o.add(buildGSuitePrincipal());
  o.add(buildGSuitePrincipal());
  return o;
}

void checkUnnamed4133(core.List<api.GSuitePrincipal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGSuitePrincipal(o[0] as api.GSuitePrincipal);
  checkGSuitePrincipal(o[1] as api.GSuitePrincipal);
}

core.List<core.String> buildUnnamed4134() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4134(core.List<core.String> o) {
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

core.int buildCounterDataSource = 0;
api.DataSource buildDataSource() {
  var o = api.DataSource();
  buildCounterDataSource++;
  if (buildCounterDataSource < 3) {
    o.disableModifications = true;
    o.disableServing = true;
    o.displayName = 'foo';
    o.indexingServiceAccounts = buildUnnamed4132();
    o.itemsVisibility = buildUnnamed4133();
    o.name = 'foo';
    o.operationIds = buildUnnamed4134();
    o.shortName = 'foo';
  }
  buildCounterDataSource--;
  return o;
}

void checkDataSource(api.DataSource o) {
  buildCounterDataSource++;
  if (buildCounterDataSource < 3) {
    unittest.expect(o.disableModifications!, unittest.isTrue);
    unittest.expect(o.disableServing!, unittest.isTrue);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4132(o.indexingServiceAccounts!);
    checkUnnamed4133(o.itemsVisibility!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4134(o.operationIds!);
    unittest.expect(
      o.shortName!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSource--;
}

core.List<api.ItemCountByStatus> buildUnnamed4135() {
  var o = <api.ItemCountByStatus>[];
  o.add(buildItemCountByStatus());
  o.add(buildItemCountByStatus());
  return o;
}

void checkUnnamed4135(core.List<api.ItemCountByStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkItemCountByStatus(o[0] as api.ItemCountByStatus);
  checkItemCountByStatus(o[1] as api.ItemCountByStatus);
}

core.int buildCounterDataSourceIndexStats = 0;
api.DataSourceIndexStats buildDataSourceIndexStats() {
  var o = api.DataSourceIndexStats();
  buildCounterDataSourceIndexStats++;
  if (buildCounterDataSourceIndexStats < 3) {
    o.date = buildDate();
    o.itemCountByStatus = buildUnnamed4135();
  }
  buildCounterDataSourceIndexStats--;
  return o;
}

void checkDataSourceIndexStats(api.DataSourceIndexStats o) {
  buildCounterDataSourceIndexStats++;
  if (buildCounterDataSourceIndexStats < 3) {
    checkDate(o.date! as api.Date);
    checkUnnamed4135(o.itemCountByStatus!);
  }
  buildCounterDataSourceIndexStats--;
}

core.List<api.FilterOptions> buildUnnamed4136() {
  var o = <api.FilterOptions>[];
  o.add(buildFilterOptions());
  o.add(buildFilterOptions());
  return o;
}

void checkUnnamed4136(core.List<api.FilterOptions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilterOptions(o[0] as api.FilterOptions);
  checkFilterOptions(o[1] as api.FilterOptions);
}

core.int buildCounterDataSourceRestriction = 0;
api.DataSourceRestriction buildDataSourceRestriction() {
  var o = api.DataSourceRestriction();
  buildCounterDataSourceRestriction++;
  if (buildCounterDataSourceRestriction < 3) {
    o.filterOptions = buildUnnamed4136();
    o.source = buildSource();
  }
  buildCounterDataSourceRestriction--;
  return o;
}

void checkDataSourceRestriction(api.DataSourceRestriction o) {
  buildCounterDataSourceRestriction++;
  if (buildCounterDataSourceRestriction < 3) {
    checkUnnamed4136(o.filterOptions!);
    checkSource(o.source! as api.Source);
  }
  buildCounterDataSourceRestriction--;
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

core.int buildCounterDateOperatorOptions = 0;
api.DateOperatorOptions buildDateOperatorOptions() {
  var o = api.DateOperatorOptions();
  buildCounterDateOperatorOptions++;
  if (buildCounterDateOperatorOptions < 3) {
    o.greaterThanOperatorName = 'foo';
    o.lessThanOperatorName = 'foo';
    o.operatorName = 'foo';
  }
  buildCounterDateOperatorOptions--;
  return o;
}

void checkDateOperatorOptions(api.DateOperatorOptions o) {
  buildCounterDateOperatorOptions++;
  if (buildCounterDateOperatorOptions < 3) {
    unittest.expect(
      o.greaterThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lessThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterDateOperatorOptions--;
}

core.int buildCounterDatePropertyOptions = 0;
api.DatePropertyOptions buildDatePropertyOptions() {
  var o = api.DatePropertyOptions();
  buildCounterDatePropertyOptions++;
  if (buildCounterDatePropertyOptions < 3) {
    o.operatorOptions = buildDateOperatorOptions();
  }
  buildCounterDatePropertyOptions--;
  return o;
}

void checkDatePropertyOptions(api.DatePropertyOptions o) {
  buildCounterDatePropertyOptions++;
  if (buildCounterDatePropertyOptions < 3) {
    checkDateOperatorOptions(o.operatorOptions! as api.DateOperatorOptions);
  }
  buildCounterDatePropertyOptions--;
}

core.List<api.Date> buildUnnamed4137() {
  var o = <api.Date>[];
  o.add(buildDate());
  o.add(buildDate());
  return o;
}

void checkUnnamed4137(core.List<api.Date> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDate(o[0] as api.Date);
  checkDate(o[1] as api.Date);
}

core.int buildCounterDateValues = 0;
api.DateValues buildDateValues() {
  var o = api.DateValues();
  buildCounterDateValues++;
  if (buildCounterDateValues < 3) {
    o.values = buildUnnamed4137();
  }
  buildCounterDateValues--;
  return o;
}

void checkDateValues(api.DateValues o) {
  buildCounterDateValues++;
  if (buildCounterDateValues < 3) {
    checkUnnamed4137(o.values!);
  }
  buildCounterDateValues--;
}

core.int buildCounterDebugOptions = 0;
api.DebugOptions buildDebugOptions() {
  var o = api.DebugOptions();
  buildCounterDebugOptions++;
  if (buildCounterDebugOptions < 3) {
    o.enableDebugging = true;
  }
  buildCounterDebugOptions--;
  return o;
}

void checkDebugOptions(api.DebugOptions o) {
  buildCounterDebugOptions++;
  if (buildCounterDebugOptions < 3) {
    unittest.expect(o.enableDebugging!, unittest.isTrue);
  }
  buildCounterDebugOptions--;
}

core.int buildCounterDeleteQueueItemsRequest = 0;
api.DeleteQueueItemsRequest buildDeleteQueueItemsRequest() {
  var o = api.DeleteQueueItemsRequest();
  buildCounterDeleteQueueItemsRequest++;
  if (buildCounterDeleteQueueItemsRequest < 3) {
    o.connectorName = 'foo';
    o.debugOptions = buildDebugOptions();
    o.queue = 'foo';
  }
  buildCounterDeleteQueueItemsRequest--;
  return o;
}

void checkDeleteQueueItemsRequest(api.DeleteQueueItemsRequest o) {
  buildCounterDeleteQueueItemsRequest++;
  if (buildCounterDeleteQueueItemsRequest < 3) {
    unittest.expect(
      o.connectorName!,
      unittest.equals('foo'),
    );
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    unittest.expect(
      o.queue!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteQueueItemsRequest--;
}

core.int buildCounterDisplayedProperty = 0;
api.DisplayedProperty buildDisplayedProperty() {
  var o = api.DisplayedProperty();
  buildCounterDisplayedProperty++;
  if (buildCounterDisplayedProperty < 3) {
    o.propertyName = 'foo';
  }
  buildCounterDisplayedProperty--;
  return o;
}

void checkDisplayedProperty(api.DisplayedProperty o) {
  buildCounterDisplayedProperty++;
  if (buildCounterDisplayedProperty < 3) {
    unittest.expect(
      o.propertyName!,
      unittest.equals('foo'),
    );
  }
  buildCounterDisplayedProperty--;
}

core.int buildCounterDoubleOperatorOptions = 0;
api.DoubleOperatorOptions buildDoubleOperatorOptions() {
  var o = api.DoubleOperatorOptions();
  buildCounterDoubleOperatorOptions++;
  if (buildCounterDoubleOperatorOptions < 3) {
    o.operatorName = 'foo';
  }
  buildCounterDoubleOperatorOptions--;
  return o;
}

void checkDoubleOperatorOptions(api.DoubleOperatorOptions o) {
  buildCounterDoubleOperatorOptions++;
  if (buildCounterDoubleOperatorOptions < 3) {
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterDoubleOperatorOptions--;
}

core.int buildCounterDoublePropertyOptions = 0;
api.DoublePropertyOptions buildDoublePropertyOptions() {
  var o = api.DoublePropertyOptions();
  buildCounterDoublePropertyOptions++;
  if (buildCounterDoublePropertyOptions < 3) {
    o.operatorOptions = buildDoubleOperatorOptions();
  }
  buildCounterDoublePropertyOptions--;
  return o;
}

void checkDoublePropertyOptions(api.DoublePropertyOptions o) {
  buildCounterDoublePropertyOptions++;
  if (buildCounterDoublePropertyOptions < 3) {
    checkDoubleOperatorOptions(o.operatorOptions! as api.DoubleOperatorOptions);
  }
  buildCounterDoublePropertyOptions--;
}

core.List<core.double> buildUnnamed4138() {
  var o = <core.double>[];
  o.add(42.0);
  o.add(42.0);
  return o;
}

void checkUnnamed4138(core.List<core.double> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42.0),
  );
  unittest.expect(
    o[1],
    unittest.equals(42.0),
  );
}

core.int buildCounterDoubleValues = 0;
api.DoubleValues buildDoubleValues() {
  var o = api.DoubleValues();
  buildCounterDoubleValues++;
  if (buildCounterDoubleValues < 3) {
    o.values = buildUnnamed4138();
  }
  buildCounterDoubleValues--;
  return o;
}

void checkDoubleValues(api.DoubleValues o) {
  buildCounterDoubleValues++;
  if (buildCounterDoubleValues < 3) {
    checkUnnamed4138(o.values!);
  }
  buildCounterDoubleValues--;
}

core.int buildCounterDriveFollowUpRestrict = 0;
api.DriveFollowUpRestrict buildDriveFollowUpRestrict() {
  var o = api.DriveFollowUpRestrict();
  buildCounterDriveFollowUpRestrict++;
  if (buildCounterDriveFollowUpRestrict < 3) {
    o.type = 'foo';
  }
  buildCounterDriveFollowUpRestrict--;
  return o;
}

void checkDriveFollowUpRestrict(api.DriveFollowUpRestrict o) {
  buildCounterDriveFollowUpRestrict++;
  if (buildCounterDriveFollowUpRestrict < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveFollowUpRestrict--;
}

core.int buildCounterDriveLocationRestrict = 0;
api.DriveLocationRestrict buildDriveLocationRestrict() {
  var o = api.DriveLocationRestrict();
  buildCounterDriveLocationRestrict++;
  if (buildCounterDriveLocationRestrict < 3) {
    o.type = 'foo';
  }
  buildCounterDriveLocationRestrict--;
  return o;
}

void checkDriveLocationRestrict(api.DriveLocationRestrict o) {
  buildCounterDriveLocationRestrict++;
  if (buildCounterDriveLocationRestrict < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveLocationRestrict--;
}

core.int buildCounterDriveMimeTypeRestrict = 0;
api.DriveMimeTypeRestrict buildDriveMimeTypeRestrict() {
  var o = api.DriveMimeTypeRestrict();
  buildCounterDriveMimeTypeRestrict++;
  if (buildCounterDriveMimeTypeRestrict < 3) {
    o.type = 'foo';
  }
  buildCounterDriveMimeTypeRestrict--;
  return o;
}

void checkDriveMimeTypeRestrict(api.DriveMimeTypeRestrict o) {
  buildCounterDriveMimeTypeRestrict++;
  if (buildCounterDriveMimeTypeRestrict < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveMimeTypeRestrict--;
}

core.int buildCounterDriveTimeSpanRestrict = 0;
api.DriveTimeSpanRestrict buildDriveTimeSpanRestrict() {
  var o = api.DriveTimeSpanRestrict();
  buildCounterDriveTimeSpanRestrict++;
  if (buildCounterDriveTimeSpanRestrict < 3) {
    o.type = 'foo';
  }
  buildCounterDriveTimeSpanRestrict--;
  return o;
}

void checkDriveTimeSpanRestrict(api.DriveTimeSpanRestrict o) {
  buildCounterDriveTimeSpanRestrict++;
  if (buildCounterDriveTimeSpanRestrict < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDriveTimeSpanRestrict--;
}

core.int buildCounterEmailAddress = 0;
api.EmailAddress buildEmailAddress() {
  var o = api.EmailAddress();
  buildCounterEmailAddress++;
  if (buildCounterEmailAddress < 3) {
    o.emailAddress = 'foo';
  }
  buildCounterEmailAddress--;
  return o;
}

void checkEmailAddress(api.EmailAddress o) {
  buildCounterEmailAddress++;
  if (buildCounterEmailAddress < 3) {
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
  }
  buildCounterEmailAddress--;
}

core.int buildCounterEnumOperatorOptions = 0;
api.EnumOperatorOptions buildEnumOperatorOptions() {
  var o = api.EnumOperatorOptions();
  buildCounterEnumOperatorOptions++;
  if (buildCounterEnumOperatorOptions < 3) {
    o.operatorName = 'foo';
  }
  buildCounterEnumOperatorOptions--;
  return o;
}

void checkEnumOperatorOptions(api.EnumOperatorOptions o) {
  buildCounterEnumOperatorOptions++;
  if (buildCounterEnumOperatorOptions < 3) {
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnumOperatorOptions--;
}

core.List<api.EnumValuePair> buildUnnamed4139() {
  var o = <api.EnumValuePair>[];
  o.add(buildEnumValuePair());
  o.add(buildEnumValuePair());
  return o;
}

void checkUnnamed4139(core.List<api.EnumValuePair> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEnumValuePair(o[0] as api.EnumValuePair);
  checkEnumValuePair(o[1] as api.EnumValuePair);
}

core.int buildCounterEnumPropertyOptions = 0;
api.EnumPropertyOptions buildEnumPropertyOptions() {
  var o = api.EnumPropertyOptions();
  buildCounterEnumPropertyOptions++;
  if (buildCounterEnumPropertyOptions < 3) {
    o.operatorOptions = buildEnumOperatorOptions();
    o.orderedRanking = 'foo';
    o.possibleValues = buildUnnamed4139();
  }
  buildCounterEnumPropertyOptions--;
  return o;
}

void checkEnumPropertyOptions(api.EnumPropertyOptions o) {
  buildCounterEnumPropertyOptions++;
  if (buildCounterEnumPropertyOptions < 3) {
    checkEnumOperatorOptions(o.operatorOptions! as api.EnumOperatorOptions);
    unittest.expect(
      o.orderedRanking!,
      unittest.equals('foo'),
    );
    checkUnnamed4139(o.possibleValues!);
  }
  buildCounterEnumPropertyOptions--;
}

core.int buildCounterEnumValuePair = 0;
api.EnumValuePair buildEnumValuePair() {
  var o = api.EnumValuePair();
  buildCounterEnumValuePair++;
  if (buildCounterEnumValuePair < 3) {
    o.integerValue = 42;
    o.stringValue = 'foo';
  }
  buildCounterEnumValuePair--;
  return o;
}

void checkEnumValuePair(api.EnumValuePair o) {
  buildCounterEnumValuePair++;
  if (buildCounterEnumValuePair < 3) {
    unittest.expect(
      o.integerValue!,
      unittest.equals(42),
    );
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnumValuePair--;
}

core.List<core.String> buildUnnamed4140() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4140(core.List<core.String> o) {
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

core.int buildCounterEnumValues = 0;
api.EnumValues buildEnumValues() {
  var o = api.EnumValues();
  buildCounterEnumValues++;
  if (buildCounterEnumValues < 3) {
    o.values = buildUnnamed4140();
  }
  buildCounterEnumValues--;
  return o;
}

void checkEnumValues(api.EnumValues o) {
  buildCounterEnumValues++;
  if (buildCounterEnumValues < 3) {
    checkUnnamed4140(o.values!);
  }
  buildCounterEnumValues--;
}

core.List<api.ErrorMessage> buildUnnamed4141() {
  var o = <api.ErrorMessage>[];
  o.add(buildErrorMessage());
  o.add(buildErrorMessage());
  return o;
}

void checkUnnamed4141(core.List<api.ErrorMessage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkErrorMessage(o[0] as api.ErrorMessage);
  checkErrorMessage(o[1] as api.ErrorMessage);
}

core.int buildCounterErrorInfo = 0;
api.ErrorInfo buildErrorInfo() {
  var o = api.ErrorInfo();
  buildCounterErrorInfo++;
  if (buildCounterErrorInfo < 3) {
    o.errorMessages = buildUnnamed4141();
  }
  buildCounterErrorInfo--;
  return o;
}

void checkErrorInfo(api.ErrorInfo o) {
  buildCounterErrorInfo++;
  if (buildCounterErrorInfo < 3) {
    checkUnnamed4141(o.errorMessages!);
  }
  buildCounterErrorInfo--;
}

core.int buildCounterErrorMessage = 0;
api.ErrorMessage buildErrorMessage() {
  var o = api.ErrorMessage();
  buildCounterErrorMessage++;
  if (buildCounterErrorMessage < 3) {
    o.errorMessage = 'foo';
    o.source = buildSource();
  }
  buildCounterErrorMessage--;
  return o;
}

void checkErrorMessage(api.ErrorMessage o) {
  buildCounterErrorMessage++;
  if (buildCounterErrorMessage < 3) {
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    checkSource(o.source! as api.Source);
  }
  buildCounterErrorMessage--;
}

core.int buildCounterFacetBucket = 0;
api.FacetBucket buildFacetBucket() {
  var o = api.FacetBucket();
  buildCounterFacetBucket++;
  if (buildCounterFacetBucket < 3) {
    o.count = 42;
    o.percentage = 42;
    o.value = buildValue();
  }
  buildCounterFacetBucket--;
  return o;
}

void checkFacetBucket(api.FacetBucket o) {
  buildCounterFacetBucket++;
  if (buildCounterFacetBucket < 3) {
    unittest.expect(
      o.count!,
      unittest.equals(42),
    );
    unittest.expect(
      o.percentage!,
      unittest.equals(42),
    );
    checkValue(o.value! as api.Value);
  }
  buildCounterFacetBucket--;
}

core.int buildCounterFacetOptions = 0;
api.FacetOptions buildFacetOptions() {
  var o = api.FacetOptions();
  buildCounterFacetOptions++;
  if (buildCounterFacetOptions < 3) {
    o.numFacetBuckets = 42;
    o.objectType = 'foo';
    o.operatorName = 'foo';
    o.sourceName = 'foo';
  }
  buildCounterFacetOptions--;
  return o;
}

void checkFacetOptions(api.FacetOptions o) {
  buildCounterFacetOptions++;
  if (buildCounterFacetOptions < 3) {
    unittest.expect(
      o.numFacetBuckets!,
      unittest.equals(42),
    );
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterFacetOptions--;
}

core.List<api.FacetBucket> buildUnnamed4142() {
  var o = <api.FacetBucket>[];
  o.add(buildFacetBucket());
  o.add(buildFacetBucket());
  return o;
}

void checkUnnamed4142(core.List<api.FacetBucket> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFacetBucket(o[0] as api.FacetBucket);
  checkFacetBucket(o[1] as api.FacetBucket);
}

core.int buildCounterFacetResult = 0;
api.FacetResult buildFacetResult() {
  var o = api.FacetResult();
  buildCounterFacetResult++;
  if (buildCounterFacetResult < 3) {
    o.buckets = buildUnnamed4142();
    o.objectType = 'foo';
    o.operatorName = 'foo';
    o.sourceName = 'foo';
  }
  buildCounterFacetResult--;
  return o;
}

void checkFacetResult(api.FacetResult o) {
  buildCounterFacetResult++;
  if (buildCounterFacetResult < 3) {
    checkUnnamed4142(o.buckets!);
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterFacetResult--;
}

core.int buildCounterFieldViolation = 0;
api.FieldViolation buildFieldViolation() {
  var o = api.FieldViolation();
  buildCounterFieldViolation++;
  if (buildCounterFieldViolation < 3) {
    o.description = 'foo';
    o.field = 'foo';
  }
  buildCounterFieldViolation--;
  return o;
}

void checkFieldViolation(api.FieldViolation o) {
  buildCounterFieldViolation++;
  if (buildCounterFieldViolation < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
  }
  buildCounterFieldViolation--;
}

core.int buildCounterFilter = 0;
api.Filter buildFilter() {
  var o = api.Filter();
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    o.compositeFilter = buildCompositeFilter();
    o.valueFilter = buildValueFilter();
  }
  buildCounterFilter--;
  return o;
}

void checkFilter(api.Filter o) {
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    checkCompositeFilter(o.compositeFilter! as api.CompositeFilter);
    checkValueFilter(o.valueFilter! as api.ValueFilter);
  }
  buildCounterFilter--;
}

core.int buildCounterFilterOptions = 0;
api.FilterOptions buildFilterOptions() {
  var o = api.FilterOptions();
  buildCounterFilterOptions++;
  if (buildCounterFilterOptions < 3) {
    o.filter = buildFilter();
    o.objectType = 'foo';
  }
  buildCounterFilterOptions--;
  return o;
}

void checkFilterOptions(api.FilterOptions o) {
  buildCounterFilterOptions++;
  if (buildCounterFilterOptions < 3) {
    checkFilter(o.filter! as api.Filter);
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterOptions--;
}

core.int buildCounterFreshnessOptions = 0;
api.FreshnessOptions buildFreshnessOptions() {
  var o = api.FreshnessOptions();
  buildCounterFreshnessOptions++;
  if (buildCounterFreshnessOptions < 3) {
    o.freshnessDuration = 'foo';
    o.freshnessProperty = 'foo';
  }
  buildCounterFreshnessOptions--;
  return o;
}

void checkFreshnessOptions(api.FreshnessOptions o) {
  buildCounterFreshnessOptions++;
  if (buildCounterFreshnessOptions < 3) {
    unittest.expect(
      o.freshnessDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.freshnessProperty!,
      unittest.equals('foo'),
    );
  }
  buildCounterFreshnessOptions--;
}

core.int buildCounterGSuitePrincipal = 0;
api.GSuitePrincipal buildGSuitePrincipal() {
  var o = api.GSuitePrincipal();
  buildCounterGSuitePrincipal++;
  if (buildCounterGSuitePrincipal < 3) {
    o.gsuiteDomain = true;
    o.gsuiteGroupEmail = 'foo';
    o.gsuiteUserEmail = 'foo';
  }
  buildCounterGSuitePrincipal--;
  return o;
}

void checkGSuitePrincipal(api.GSuitePrincipal o) {
  buildCounterGSuitePrincipal++;
  if (buildCounterGSuitePrincipal < 3) {
    unittest.expect(o.gsuiteDomain!, unittest.isTrue);
    unittest.expect(
      o.gsuiteGroupEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gsuiteUserEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterGSuitePrincipal--;
}

core.List<api.CustomerIndexStats> buildUnnamed4143() {
  var o = <api.CustomerIndexStats>[];
  o.add(buildCustomerIndexStats());
  o.add(buildCustomerIndexStats());
  return o;
}

void checkUnnamed4143(core.List<api.CustomerIndexStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomerIndexStats(o[0] as api.CustomerIndexStats);
  checkCustomerIndexStats(o[1] as api.CustomerIndexStats);
}

core.int buildCounterGetCustomerIndexStatsResponse = 0;
api.GetCustomerIndexStatsResponse buildGetCustomerIndexStatsResponse() {
  var o = api.GetCustomerIndexStatsResponse();
  buildCounterGetCustomerIndexStatsResponse++;
  if (buildCounterGetCustomerIndexStatsResponse < 3) {
    o.stats = buildUnnamed4143();
  }
  buildCounterGetCustomerIndexStatsResponse--;
  return o;
}

void checkGetCustomerIndexStatsResponse(api.GetCustomerIndexStatsResponse o) {
  buildCounterGetCustomerIndexStatsResponse++;
  if (buildCounterGetCustomerIndexStatsResponse < 3) {
    checkUnnamed4143(o.stats!);
  }
  buildCounterGetCustomerIndexStatsResponse--;
}

core.List<api.CustomerQueryStats> buildUnnamed4144() {
  var o = <api.CustomerQueryStats>[];
  o.add(buildCustomerQueryStats());
  o.add(buildCustomerQueryStats());
  return o;
}

void checkUnnamed4144(core.List<api.CustomerQueryStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomerQueryStats(o[0] as api.CustomerQueryStats);
  checkCustomerQueryStats(o[1] as api.CustomerQueryStats);
}

core.int buildCounterGetCustomerQueryStatsResponse = 0;
api.GetCustomerQueryStatsResponse buildGetCustomerQueryStatsResponse() {
  var o = api.GetCustomerQueryStatsResponse();
  buildCounterGetCustomerQueryStatsResponse++;
  if (buildCounterGetCustomerQueryStatsResponse < 3) {
    o.stats = buildUnnamed4144();
  }
  buildCounterGetCustomerQueryStatsResponse--;
  return o;
}

void checkGetCustomerQueryStatsResponse(api.GetCustomerQueryStatsResponse o) {
  buildCounterGetCustomerQueryStatsResponse++;
  if (buildCounterGetCustomerQueryStatsResponse < 3) {
    checkUnnamed4144(o.stats!);
  }
  buildCounterGetCustomerQueryStatsResponse--;
}

core.List<api.CustomerSessionStats> buildUnnamed4145() {
  var o = <api.CustomerSessionStats>[];
  o.add(buildCustomerSessionStats());
  o.add(buildCustomerSessionStats());
  return o;
}

void checkUnnamed4145(core.List<api.CustomerSessionStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomerSessionStats(o[0] as api.CustomerSessionStats);
  checkCustomerSessionStats(o[1] as api.CustomerSessionStats);
}

core.int buildCounterGetCustomerSessionStatsResponse = 0;
api.GetCustomerSessionStatsResponse buildGetCustomerSessionStatsResponse() {
  var o = api.GetCustomerSessionStatsResponse();
  buildCounterGetCustomerSessionStatsResponse++;
  if (buildCounterGetCustomerSessionStatsResponse < 3) {
    o.stats = buildUnnamed4145();
  }
  buildCounterGetCustomerSessionStatsResponse--;
  return o;
}

void checkGetCustomerSessionStatsResponse(
    api.GetCustomerSessionStatsResponse o) {
  buildCounterGetCustomerSessionStatsResponse++;
  if (buildCounterGetCustomerSessionStatsResponse < 3) {
    checkUnnamed4145(o.stats!);
  }
  buildCounterGetCustomerSessionStatsResponse--;
}

core.List<api.CustomerUserStats> buildUnnamed4146() {
  var o = <api.CustomerUserStats>[];
  o.add(buildCustomerUserStats());
  o.add(buildCustomerUserStats());
  return o;
}

void checkUnnamed4146(core.List<api.CustomerUserStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomerUserStats(o[0] as api.CustomerUserStats);
  checkCustomerUserStats(o[1] as api.CustomerUserStats);
}

core.int buildCounterGetCustomerUserStatsResponse = 0;
api.GetCustomerUserStatsResponse buildGetCustomerUserStatsResponse() {
  var o = api.GetCustomerUserStatsResponse();
  buildCounterGetCustomerUserStatsResponse++;
  if (buildCounterGetCustomerUserStatsResponse < 3) {
    o.stats = buildUnnamed4146();
  }
  buildCounterGetCustomerUserStatsResponse--;
  return o;
}

void checkGetCustomerUserStatsResponse(api.GetCustomerUserStatsResponse o) {
  buildCounterGetCustomerUserStatsResponse++;
  if (buildCounterGetCustomerUserStatsResponse < 3) {
    checkUnnamed4146(o.stats!);
  }
  buildCounterGetCustomerUserStatsResponse--;
}

core.List<api.DataSourceIndexStats> buildUnnamed4147() {
  var o = <api.DataSourceIndexStats>[];
  o.add(buildDataSourceIndexStats());
  o.add(buildDataSourceIndexStats());
  return o;
}

void checkUnnamed4147(core.List<api.DataSourceIndexStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceIndexStats(o[0] as api.DataSourceIndexStats);
  checkDataSourceIndexStats(o[1] as api.DataSourceIndexStats);
}

core.int buildCounterGetDataSourceIndexStatsResponse = 0;
api.GetDataSourceIndexStatsResponse buildGetDataSourceIndexStatsResponse() {
  var o = api.GetDataSourceIndexStatsResponse();
  buildCounterGetDataSourceIndexStatsResponse++;
  if (buildCounterGetDataSourceIndexStatsResponse < 3) {
    o.stats = buildUnnamed4147();
  }
  buildCounterGetDataSourceIndexStatsResponse--;
  return o;
}

void checkGetDataSourceIndexStatsResponse(
    api.GetDataSourceIndexStatsResponse o) {
  buildCounterGetDataSourceIndexStatsResponse++;
  if (buildCounterGetDataSourceIndexStatsResponse < 3) {
    checkUnnamed4147(o.stats!);
  }
  buildCounterGetDataSourceIndexStatsResponse--;
}

core.List<api.SearchApplicationQueryStats> buildUnnamed4148() {
  var o = <api.SearchApplicationQueryStats>[];
  o.add(buildSearchApplicationQueryStats());
  o.add(buildSearchApplicationQueryStats());
  return o;
}

void checkUnnamed4148(core.List<api.SearchApplicationQueryStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchApplicationQueryStats(o[0] as api.SearchApplicationQueryStats);
  checkSearchApplicationQueryStats(o[1] as api.SearchApplicationQueryStats);
}

core.int buildCounterGetSearchApplicationQueryStatsResponse = 0;
api.GetSearchApplicationQueryStatsResponse
    buildGetSearchApplicationQueryStatsResponse() {
  var o = api.GetSearchApplicationQueryStatsResponse();
  buildCounterGetSearchApplicationQueryStatsResponse++;
  if (buildCounterGetSearchApplicationQueryStatsResponse < 3) {
    o.stats = buildUnnamed4148();
  }
  buildCounterGetSearchApplicationQueryStatsResponse--;
  return o;
}

void checkGetSearchApplicationQueryStatsResponse(
    api.GetSearchApplicationQueryStatsResponse o) {
  buildCounterGetSearchApplicationQueryStatsResponse++;
  if (buildCounterGetSearchApplicationQueryStatsResponse < 3) {
    checkUnnamed4148(o.stats!);
  }
  buildCounterGetSearchApplicationQueryStatsResponse--;
}

core.List<api.SearchApplicationSessionStats> buildUnnamed4149() {
  var o = <api.SearchApplicationSessionStats>[];
  o.add(buildSearchApplicationSessionStats());
  o.add(buildSearchApplicationSessionStats());
  return o;
}

void checkUnnamed4149(core.List<api.SearchApplicationSessionStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchApplicationSessionStats(o[0] as api.SearchApplicationSessionStats);
  checkSearchApplicationSessionStats(o[1] as api.SearchApplicationSessionStats);
}

core.int buildCounterGetSearchApplicationSessionStatsResponse = 0;
api.GetSearchApplicationSessionStatsResponse
    buildGetSearchApplicationSessionStatsResponse() {
  var o = api.GetSearchApplicationSessionStatsResponse();
  buildCounterGetSearchApplicationSessionStatsResponse++;
  if (buildCounterGetSearchApplicationSessionStatsResponse < 3) {
    o.stats = buildUnnamed4149();
  }
  buildCounterGetSearchApplicationSessionStatsResponse--;
  return o;
}

void checkGetSearchApplicationSessionStatsResponse(
    api.GetSearchApplicationSessionStatsResponse o) {
  buildCounterGetSearchApplicationSessionStatsResponse++;
  if (buildCounterGetSearchApplicationSessionStatsResponse < 3) {
    checkUnnamed4149(o.stats!);
  }
  buildCounterGetSearchApplicationSessionStatsResponse--;
}

core.List<api.SearchApplicationUserStats> buildUnnamed4150() {
  var o = <api.SearchApplicationUserStats>[];
  o.add(buildSearchApplicationUserStats());
  o.add(buildSearchApplicationUserStats());
  return o;
}

void checkUnnamed4150(core.List<api.SearchApplicationUserStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchApplicationUserStats(o[0] as api.SearchApplicationUserStats);
  checkSearchApplicationUserStats(o[1] as api.SearchApplicationUserStats);
}

core.int buildCounterGetSearchApplicationUserStatsResponse = 0;
api.GetSearchApplicationUserStatsResponse
    buildGetSearchApplicationUserStatsResponse() {
  var o = api.GetSearchApplicationUserStatsResponse();
  buildCounterGetSearchApplicationUserStatsResponse++;
  if (buildCounterGetSearchApplicationUserStatsResponse < 3) {
    o.stats = buildUnnamed4150();
  }
  buildCounterGetSearchApplicationUserStatsResponse--;
  return o;
}

void checkGetSearchApplicationUserStatsResponse(
    api.GetSearchApplicationUserStatsResponse o) {
  buildCounterGetSearchApplicationUserStatsResponse++;
  if (buildCounterGetSearchApplicationUserStatsResponse < 3) {
    checkUnnamed4150(o.stats!);
  }
  buildCounterGetSearchApplicationUserStatsResponse--;
}

core.int buildCounterHtmlOperatorOptions = 0;
api.HtmlOperatorOptions buildHtmlOperatorOptions() {
  var o = api.HtmlOperatorOptions();
  buildCounterHtmlOperatorOptions++;
  if (buildCounterHtmlOperatorOptions < 3) {
    o.operatorName = 'foo';
  }
  buildCounterHtmlOperatorOptions--;
  return o;
}

void checkHtmlOperatorOptions(api.HtmlOperatorOptions o) {
  buildCounterHtmlOperatorOptions++;
  if (buildCounterHtmlOperatorOptions < 3) {
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterHtmlOperatorOptions--;
}

core.int buildCounterHtmlPropertyOptions = 0;
api.HtmlPropertyOptions buildHtmlPropertyOptions() {
  var o = api.HtmlPropertyOptions();
  buildCounterHtmlPropertyOptions++;
  if (buildCounterHtmlPropertyOptions < 3) {
    o.operatorOptions = buildHtmlOperatorOptions();
    o.retrievalImportance = buildRetrievalImportance();
  }
  buildCounterHtmlPropertyOptions--;
  return o;
}

void checkHtmlPropertyOptions(api.HtmlPropertyOptions o) {
  buildCounterHtmlPropertyOptions++;
  if (buildCounterHtmlPropertyOptions < 3) {
    checkHtmlOperatorOptions(o.operatorOptions! as api.HtmlOperatorOptions);
    checkRetrievalImportance(o.retrievalImportance! as api.RetrievalImportance);
  }
  buildCounterHtmlPropertyOptions--;
}

core.List<core.String> buildUnnamed4151() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4151(core.List<core.String> o) {
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

core.int buildCounterHtmlValues = 0;
api.HtmlValues buildHtmlValues() {
  var o = api.HtmlValues();
  buildCounterHtmlValues++;
  if (buildCounterHtmlValues < 3) {
    o.values = buildUnnamed4151();
  }
  buildCounterHtmlValues--;
  return o;
}

void checkHtmlValues(api.HtmlValues o) {
  buildCounterHtmlValues++;
  if (buildCounterHtmlValues < 3) {
    checkUnnamed4151(o.values!);
  }
  buildCounterHtmlValues--;
}

core.int buildCounterIndexItemOptions = 0;
api.IndexItemOptions buildIndexItemOptions() {
  var o = api.IndexItemOptions();
  buildCounterIndexItemOptions++;
  if (buildCounterIndexItemOptions < 3) {
    o.allowUnknownGsuitePrincipals = true;
  }
  buildCounterIndexItemOptions--;
  return o;
}

void checkIndexItemOptions(api.IndexItemOptions o) {
  buildCounterIndexItemOptions++;
  if (buildCounterIndexItemOptions < 3) {
    unittest.expect(o.allowUnknownGsuitePrincipals!, unittest.isTrue);
  }
  buildCounterIndexItemOptions--;
}

core.int buildCounterIndexItemRequest = 0;
api.IndexItemRequest buildIndexItemRequest() {
  var o = api.IndexItemRequest();
  buildCounterIndexItemRequest++;
  if (buildCounterIndexItemRequest < 3) {
    o.connectorName = 'foo';
    o.debugOptions = buildDebugOptions();
    o.indexItemOptions = buildIndexItemOptions();
    o.item = buildItem();
    o.mode = 'foo';
  }
  buildCounterIndexItemRequest--;
  return o;
}

void checkIndexItemRequest(api.IndexItemRequest o) {
  buildCounterIndexItemRequest++;
  if (buildCounterIndexItemRequest < 3) {
    unittest.expect(
      o.connectorName!,
      unittest.equals('foo'),
    );
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    checkIndexItemOptions(o.indexItemOptions! as api.IndexItemOptions);
    checkItem(o.item! as api.Item);
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
  }
  buildCounterIndexItemRequest--;
}

core.int buildCounterIntegerOperatorOptions = 0;
api.IntegerOperatorOptions buildIntegerOperatorOptions() {
  var o = api.IntegerOperatorOptions();
  buildCounterIntegerOperatorOptions++;
  if (buildCounterIntegerOperatorOptions < 3) {
    o.greaterThanOperatorName = 'foo';
    o.lessThanOperatorName = 'foo';
    o.operatorName = 'foo';
  }
  buildCounterIntegerOperatorOptions--;
  return o;
}

void checkIntegerOperatorOptions(api.IntegerOperatorOptions o) {
  buildCounterIntegerOperatorOptions++;
  if (buildCounterIntegerOperatorOptions < 3) {
    unittest.expect(
      o.greaterThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lessThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterIntegerOperatorOptions--;
}

core.int buildCounterIntegerPropertyOptions = 0;
api.IntegerPropertyOptions buildIntegerPropertyOptions() {
  var o = api.IntegerPropertyOptions();
  buildCounterIntegerPropertyOptions++;
  if (buildCounterIntegerPropertyOptions < 3) {
    o.maximumValue = 'foo';
    o.minimumValue = 'foo';
    o.operatorOptions = buildIntegerOperatorOptions();
    o.orderedRanking = 'foo';
  }
  buildCounterIntegerPropertyOptions--;
  return o;
}

void checkIntegerPropertyOptions(api.IntegerPropertyOptions o) {
  buildCounterIntegerPropertyOptions++;
  if (buildCounterIntegerPropertyOptions < 3) {
    unittest.expect(
      o.maximumValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumValue!,
      unittest.equals('foo'),
    );
    checkIntegerOperatorOptions(
        o.operatorOptions! as api.IntegerOperatorOptions);
    unittest.expect(
      o.orderedRanking!,
      unittest.equals('foo'),
    );
  }
  buildCounterIntegerPropertyOptions--;
}

core.List<core.String> buildUnnamed4152() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4152(core.List<core.String> o) {
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

core.int buildCounterIntegerValues = 0;
api.IntegerValues buildIntegerValues() {
  var o = api.IntegerValues();
  buildCounterIntegerValues++;
  if (buildCounterIntegerValues < 3) {
    o.values = buildUnnamed4152();
  }
  buildCounterIntegerValues--;
  return o;
}

void checkIntegerValues(api.IntegerValues o) {
  buildCounterIntegerValues++;
  if (buildCounterIntegerValues < 3) {
    checkUnnamed4152(o.values!);
  }
  buildCounterIntegerValues--;
}

core.int buildCounterInteraction = 0;
api.Interaction buildInteraction() {
  var o = api.Interaction();
  buildCounterInteraction++;
  if (buildCounterInteraction < 3) {
    o.interactionTime = 'foo';
    o.principal = buildPrincipal();
    o.type = 'foo';
  }
  buildCounterInteraction--;
  return o;
}

void checkInteraction(api.Interaction o) {
  buildCounterInteraction++;
  if (buildCounterInteraction < 3) {
    unittest.expect(
      o.interactionTime!,
      unittest.equals('foo'),
    );
    checkPrincipal(o.principal! as api.Principal);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterInteraction--;
}

core.int buildCounterItem = 0;
api.Item buildItem() {
  var o = api.Item();
  buildCounterItem++;
  if (buildCounterItem < 3) {
    o.acl = buildItemAcl();
    o.content = buildItemContent();
    o.itemType = 'foo';
    o.metadata = buildItemMetadata();
    o.name = 'foo';
    o.payload = 'foo';
    o.queue = 'foo';
    o.status = buildItemStatus();
    o.structuredData = buildItemStructuredData();
    o.version = 'foo';
  }
  buildCounterItem--;
  return o;
}

void checkItem(api.Item o) {
  buildCounterItem++;
  if (buildCounterItem < 3) {
    checkItemAcl(o.acl! as api.ItemAcl);
    checkItemContent(o.content! as api.ItemContent);
    unittest.expect(
      o.itemType!,
      unittest.equals('foo'),
    );
    checkItemMetadata(o.metadata! as api.ItemMetadata);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.payload!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queue!,
      unittest.equals('foo'),
    );
    checkItemStatus(o.status! as api.ItemStatus);
    checkItemStructuredData(o.structuredData! as api.ItemStructuredData);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterItem--;
}

core.List<api.Principal> buildUnnamed4153() {
  var o = <api.Principal>[];
  o.add(buildPrincipal());
  o.add(buildPrincipal());
  return o;
}

void checkUnnamed4153(core.List<api.Principal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrincipal(o[0] as api.Principal);
  checkPrincipal(o[1] as api.Principal);
}

core.List<api.Principal> buildUnnamed4154() {
  var o = <api.Principal>[];
  o.add(buildPrincipal());
  o.add(buildPrincipal());
  return o;
}

void checkUnnamed4154(core.List<api.Principal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrincipal(o[0] as api.Principal);
  checkPrincipal(o[1] as api.Principal);
}

core.List<api.Principal> buildUnnamed4155() {
  var o = <api.Principal>[];
  o.add(buildPrincipal());
  o.add(buildPrincipal());
  return o;
}

void checkUnnamed4155(core.List<api.Principal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrincipal(o[0] as api.Principal);
  checkPrincipal(o[1] as api.Principal);
}

core.int buildCounterItemAcl = 0;
api.ItemAcl buildItemAcl() {
  var o = api.ItemAcl();
  buildCounterItemAcl++;
  if (buildCounterItemAcl < 3) {
    o.aclInheritanceType = 'foo';
    o.deniedReaders = buildUnnamed4153();
    o.inheritAclFrom = 'foo';
    o.owners = buildUnnamed4154();
    o.readers = buildUnnamed4155();
  }
  buildCounterItemAcl--;
  return o;
}

void checkItemAcl(api.ItemAcl o) {
  buildCounterItemAcl++;
  if (buildCounterItemAcl < 3) {
    unittest.expect(
      o.aclInheritanceType!,
      unittest.equals('foo'),
    );
    checkUnnamed4153(o.deniedReaders!);
    unittest.expect(
      o.inheritAclFrom!,
      unittest.equals('foo'),
    );
    checkUnnamed4154(o.owners!);
    checkUnnamed4155(o.readers!);
  }
  buildCounterItemAcl--;
}

core.int buildCounterItemContent = 0;
api.ItemContent buildItemContent() {
  var o = api.ItemContent();
  buildCounterItemContent++;
  if (buildCounterItemContent < 3) {
    o.contentDataRef = buildUploadItemRef();
    o.contentFormat = 'foo';
    o.hash = 'foo';
    o.inlineContent = 'foo';
  }
  buildCounterItemContent--;
  return o;
}

void checkItemContent(api.ItemContent o) {
  buildCounterItemContent++;
  if (buildCounterItemContent < 3) {
    checkUploadItemRef(o.contentDataRef! as api.UploadItemRef);
    unittest.expect(
      o.contentFormat!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inlineContent!,
      unittest.equals('foo'),
    );
  }
  buildCounterItemContent--;
}

core.int buildCounterItemCountByStatus = 0;
api.ItemCountByStatus buildItemCountByStatus() {
  var o = api.ItemCountByStatus();
  buildCounterItemCountByStatus++;
  if (buildCounterItemCountByStatus < 3) {
    o.count = 'foo';
    o.statusCode = 'foo';
  }
  buildCounterItemCountByStatus--;
  return o;
}

void checkItemCountByStatus(api.ItemCountByStatus o) {
  buildCounterItemCountByStatus++;
  if (buildCounterItemCountByStatus < 3) {
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statusCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterItemCountByStatus--;
}

core.List<api.ContextAttribute> buildUnnamed4156() {
  var o = <api.ContextAttribute>[];
  o.add(buildContextAttribute());
  o.add(buildContextAttribute());
  return o;
}

void checkUnnamed4156(core.List<api.ContextAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContextAttribute(o[0] as api.ContextAttribute);
  checkContextAttribute(o[1] as api.ContextAttribute);
}

core.List<api.Interaction> buildUnnamed4157() {
  var o = <api.Interaction>[];
  o.add(buildInteraction());
  o.add(buildInteraction());
  return o;
}

void checkUnnamed4157(core.List<api.Interaction> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInteraction(o[0] as api.Interaction);
  checkInteraction(o[1] as api.Interaction);
}

core.List<core.String> buildUnnamed4158() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4158(core.List<core.String> o) {
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

core.int buildCounterItemMetadata = 0;
api.ItemMetadata buildItemMetadata() {
  var o = api.ItemMetadata();
  buildCounterItemMetadata++;
  if (buildCounterItemMetadata < 3) {
    o.containerName = 'foo';
    o.contentLanguage = 'foo';
    o.contextAttributes = buildUnnamed4156();
    o.createTime = 'foo';
    o.hash = 'foo';
    o.interactions = buildUnnamed4157();
    o.keywords = buildUnnamed4158();
    o.mimeType = 'foo';
    o.objectType = 'foo';
    o.searchQualityMetadata = buildSearchQualityMetadata();
    o.sourceRepositoryUrl = 'foo';
    o.title = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterItemMetadata--;
  return o;
}

void checkItemMetadata(api.ItemMetadata o) {
  buildCounterItemMetadata++;
  if (buildCounterItemMetadata < 3) {
    unittest.expect(
      o.containerName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contentLanguage!,
      unittest.equals('foo'),
    );
    checkUnnamed4156(o.contextAttributes!);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hash!,
      unittest.equals('foo'),
    );
    checkUnnamed4157(o.interactions!);
    checkUnnamed4158(o.keywords!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    checkSearchQualityMetadata(
        o.searchQualityMetadata! as api.SearchQualityMetadata);
    unittest.expect(
      o.sourceRepositoryUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterItemMetadata--;
}

core.List<api.ProcessingError> buildUnnamed4159() {
  var o = <api.ProcessingError>[];
  o.add(buildProcessingError());
  o.add(buildProcessingError());
  return o;
}

void checkUnnamed4159(core.List<api.ProcessingError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProcessingError(o[0] as api.ProcessingError);
  checkProcessingError(o[1] as api.ProcessingError);
}

core.List<api.RepositoryError> buildUnnamed4160() {
  var o = <api.RepositoryError>[];
  o.add(buildRepositoryError());
  o.add(buildRepositoryError());
  return o;
}

void checkUnnamed4160(core.List<api.RepositoryError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRepositoryError(o[0] as api.RepositoryError);
  checkRepositoryError(o[1] as api.RepositoryError);
}

core.int buildCounterItemStatus = 0;
api.ItemStatus buildItemStatus() {
  var o = api.ItemStatus();
  buildCounterItemStatus++;
  if (buildCounterItemStatus < 3) {
    o.code = 'foo';
    o.processingErrors = buildUnnamed4159();
    o.repositoryErrors = buildUnnamed4160();
  }
  buildCounterItemStatus--;
  return o;
}

void checkItemStatus(api.ItemStatus o) {
  buildCounterItemStatus++;
  if (buildCounterItemStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkUnnamed4159(o.processingErrors!);
    checkUnnamed4160(o.repositoryErrors!);
  }
  buildCounterItemStatus--;
}

core.int buildCounterItemStructuredData = 0;
api.ItemStructuredData buildItemStructuredData() {
  var o = api.ItemStructuredData();
  buildCounterItemStructuredData++;
  if (buildCounterItemStructuredData < 3) {
    o.hash = 'foo';
    o.object = buildStructuredDataObject();
  }
  buildCounterItemStructuredData--;
  return o;
}

void checkItemStructuredData(api.ItemStructuredData o) {
  buildCounterItemStructuredData++;
  if (buildCounterItemStructuredData < 3) {
    unittest.expect(
      o.hash!,
      unittest.equals('foo'),
    );
    checkStructuredDataObject(o.object! as api.StructuredDataObject);
  }
  buildCounterItemStructuredData--;
}

core.List<api.DataSource> buildUnnamed4161() {
  var o = <api.DataSource>[];
  o.add(buildDataSource());
  o.add(buildDataSource());
  return o;
}

void checkUnnamed4161(core.List<api.DataSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSource(o[0] as api.DataSource);
  checkDataSource(o[1] as api.DataSource);
}

core.int buildCounterListDataSourceResponse = 0;
api.ListDataSourceResponse buildListDataSourceResponse() {
  var o = api.ListDataSourceResponse();
  buildCounterListDataSourceResponse++;
  if (buildCounterListDataSourceResponse < 3) {
    o.nextPageToken = 'foo';
    o.sources = buildUnnamed4161();
  }
  buildCounterListDataSourceResponse--;
  return o;
}

void checkListDataSourceResponse(api.ListDataSourceResponse o) {
  buildCounterListDataSourceResponse++;
  if (buildCounterListDataSourceResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4161(o.sources!);
  }
  buildCounterListDataSourceResponse--;
}

core.List<core.String> buildUnnamed4162() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4162(core.List<core.String> o) {
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

core.int buildCounterListItemNamesForUnmappedIdentityResponse = 0;
api.ListItemNamesForUnmappedIdentityResponse
    buildListItemNamesForUnmappedIdentityResponse() {
  var o = api.ListItemNamesForUnmappedIdentityResponse();
  buildCounterListItemNamesForUnmappedIdentityResponse++;
  if (buildCounterListItemNamesForUnmappedIdentityResponse < 3) {
    o.itemNames = buildUnnamed4162();
    o.nextPageToken = 'foo';
  }
  buildCounterListItemNamesForUnmappedIdentityResponse--;
  return o;
}

void checkListItemNamesForUnmappedIdentityResponse(
    api.ListItemNamesForUnmappedIdentityResponse o) {
  buildCounterListItemNamesForUnmappedIdentityResponse++;
  if (buildCounterListItemNamesForUnmappedIdentityResponse < 3) {
    checkUnnamed4162(o.itemNames!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListItemNamesForUnmappedIdentityResponse--;
}

core.List<api.Item> buildUnnamed4163() {
  var o = <api.Item>[];
  o.add(buildItem());
  o.add(buildItem());
  return o;
}

void checkUnnamed4163(core.List<api.Item> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkItem(o[0] as api.Item);
  checkItem(o[1] as api.Item);
}

core.int buildCounterListItemsResponse = 0;
api.ListItemsResponse buildListItemsResponse() {
  var o = api.ListItemsResponse();
  buildCounterListItemsResponse++;
  if (buildCounterListItemsResponse < 3) {
    o.items = buildUnnamed4163();
    o.nextPageToken = 'foo';
  }
  buildCounterListItemsResponse--;
  return o;
}

void checkListItemsResponse(api.ListItemsResponse o) {
  buildCounterListItemsResponse++;
  if (buildCounterListItemsResponse < 3) {
    checkUnnamed4163(o.items!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListItemsResponse--;
}

core.List<api.Operation> buildUnnamed4164() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed4164(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed4164();
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
    checkUnnamed4164(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.List<api.QuerySource> buildUnnamed4165() {
  var o = <api.QuerySource>[];
  o.add(buildQuerySource());
  o.add(buildQuerySource());
  return o;
}

void checkUnnamed4165(core.List<api.QuerySource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQuerySource(o[0] as api.QuerySource);
  checkQuerySource(o[1] as api.QuerySource);
}

core.int buildCounterListQuerySourcesResponse = 0;
api.ListQuerySourcesResponse buildListQuerySourcesResponse() {
  var o = api.ListQuerySourcesResponse();
  buildCounterListQuerySourcesResponse++;
  if (buildCounterListQuerySourcesResponse < 3) {
    o.nextPageToken = 'foo';
    o.sources = buildUnnamed4165();
  }
  buildCounterListQuerySourcesResponse--;
  return o;
}

void checkListQuerySourcesResponse(api.ListQuerySourcesResponse o) {
  buildCounterListQuerySourcesResponse++;
  if (buildCounterListQuerySourcesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4165(o.sources!);
  }
  buildCounterListQuerySourcesResponse--;
}

core.List<api.SearchApplication> buildUnnamed4166() {
  var o = <api.SearchApplication>[];
  o.add(buildSearchApplication());
  o.add(buildSearchApplication());
  return o;
}

void checkUnnamed4166(core.List<api.SearchApplication> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchApplication(o[0] as api.SearchApplication);
  checkSearchApplication(o[1] as api.SearchApplication);
}

core.int buildCounterListSearchApplicationsResponse = 0;
api.ListSearchApplicationsResponse buildListSearchApplicationsResponse() {
  var o = api.ListSearchApplicationsResponse();
  buildCounterListSearchApplicationsResponse++;
  if (buildCounterListSearchApplicationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.searchApplications = buildUnnamed4166();
  }
  buildCounterListSearchApplicationsResponse--;
  return o;
}

void checkListSearchApplicationsResponse(api.ListSearchApplicationsResponse o) {
  buildCounterListSearchApplicationsResponse++;
  if (buildCounterListSearchApplicationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4166(o.searchApplications!);
  }
  buildCounterListSearchApplicationsResponse--;
}

core.List<api.UnmappedIdentity> buildUnnamed4167() {
  var o = <api.UnmappedIdentity>[];
  o.add(buildUnmappedIdentity());
  o.add(buildUnmappedIdentity());
  return o;
}

void checkUnnamed4167(core.List<api.UnmappedIdentity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnmappedIdentity(o[0] as api.UnmappedIdentity);
  checkUnmappedIdentity(o[1] as api.UnmappedIdentity);
}

core.int buildCounterListUnmappedIdentitiesResponse = 0;
api.ListUnmappedIdentitiesResponse buildListUnmappedIdentitiesResponse() {
  var o = api.ListUnmappedIdentitiesResponse();
  buildCounterListUnmappedIdentitiesResponse++;
  if (buildCounterListUnmappedIdentitiesResponse < 3) {
    o.nextPageToken = 'foo';
    o.unmappedIdentities = buildUnnamed4167();
  }
  buildCounterListUnmappedIdentitiesResponse--;
  return o;
}

void checkListUnmappedIdentitiesResponse(api.ListUnmappedIdentitiesResponse o) {
  buildCounterListUnmappedIdentitiesResponse++;
  if (buildCounterListUnmappedIdentitiesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4167(o.unmappedIdentities!);
  }
  buildCounterListUnmappedIdentitiesResponse--;
}

core.int buildCounterMatchRange = 0;
api.MatchRange buildMatchRange() {
  var o = api.MatchRange();
  buildCounterMatchRange++;
  if (buildCounterMatchRange < 3) {
    o.end = 42;
    o.start = 42;
  }
  buildCounterMatchRange--;
  return o;
}

void checkMatchRange(api.MatchRange o) {
  buildCounterMatchRange++;
  if (buildCounterMatchRange < 3) {
    unittest.expect(
      o.end!,
      unittest.equals(42),
    );
    unittest.expect(
      o.start!,
      unittest.equals(42),
    );
  }
  buildCounterMatchRange--;
}

core.int buildCounterMedia = 0;
api.Media buildMedia() {
  var o = api.Media();
  buildCounterMedia++;
  if (buildCounterMedia < 3) {
    o.resourceName = 'foo';
  }
  buildCounterMedia--;
  return o;
}

void checkMedia(api.Media o) {
  buildCounterMedia++;
  if (buildCounterMedia < 3) {
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterMedia--;
}

core.List<api.NamedProperty> buildUnnamed4168() {
  var o = <api.NamedProperty>[];
  o.add(buildNamedProperty());
  o.add(buildNamedProperty());
  return o;
}

void checkUnnamed4168(core.List<api.NamedProperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNamedProperty(o[0] as api.NamedProperty);
  checkNamedProperty(o[1] as api.NamedProperty);
}

core.int buildCounterMetadata = 0;
api.Metadata buildMetadata() {
  var o = api.Metadata();
  buildCounterMetadata++;
  if (buildCounterMetadata < 3) {
    o.createTime = 'foo';
    o.displayOptions = buildResultDisplayMetadata();
    o.fields = buildUnnamed4168();
    o.mimeType = 'foo';
    o.objectType = 'foo';
    o.owner = buildPerson();
    o.source = buildSource();
    o.updateTime = 'foo';
  }
  buildCounterMetadata--;
  return o;
}

void checkMetadata(api.Metadata o) {
  buildCounterMetadata++;
  if (buildCounterMetadata < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkResultDisplayMetadata(o.displayOptions! as api.ResultDisplayMetadata);
    checkUnnamed4168(o.fields!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    checkPerson(o.owner! as api.Person);
    checkSource(o.source! as api.Source);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterMetadata--;
}

core.List<api.DisplayedProperty> buildUnnamed4169() {
  var o = <api.DisplayedProperty>[];
  o.add(buildDisplayedProperty());
  o.add(buildDisplayedProperty());
  return o;
}

void checkUnnamed4169(core.List<api.DisplayedProperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDisplayedProperty(o[0] as api.DisplayedProperty);
  checkDisplayedProperty(o[1] as api.DisplayedProperty);
}

core.int buildCounterMetaline = 0;
api.Metaline buildMetaline() {
  var o = api.Metaline();
  buildCounterMetaline++;
  if (buildCounterMetaline < 3) {
    o.properties = buildUnnamed4169();
  }
  buildCounterMetaline--;
  return o;
}

void checkMetaline(api.Metaline o) {
  buildCounterMetaline++;
  if (buildCounterMetaline < 3) {
    checkUnnamed4169(o.properties!);
  }
  buildCounterMetaline--;
}

core.int buildCounterName = 0;
api.Name buildName() {
  var o = api.Name();
  buildCounterName++;
  if (buildCounterName < 3) {
    o.displayName = 'foo';
  }
  buildCounterName--;
  return o;
}

void checkName(api.Name o) {
  buildCounterName++;
  if (buildCounterName < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterName--;
}

core.int buildCounterNamedProperty = 0;
api.NamedProperty buildNamedProperty() {
  var o = api.NamedProperty();
  buildCounterNamedProperty++;
  if (buildCounterNamedProperty < 3) {
    o.booleanValue = true;
    o.dateValues = buildDateValues();
    o.doubleValues = buildDoubleValues();
    o.enumValues = buildEnumValues();
    o.htmlValues = buildHtmlValues();
    o.integerValues = buildIntegerValues();
    o.name = 'foo';
    o.objectValues = buildObjectValues();
    o.textValues = buildTextValues();
    o.timestampValues = buildTimestampValues();
  }
  buildCounterNamedProperty--;
  return o;
}

void checkNamedProperty(api.NamedProperty o) {
  buildCounterNamedProperty++;
  if (buildCounterNamedProperty < 3) {
    unittest.expect(o.booleanValue!, unittest.isTrue);
    checkDateValues(o.dateValues! as api.DateValues);
    checkDoubleValues(o.doubleValues! as api.DoubleValues);
    checkEnumValues(o.enumValues! as api.EnumValues);
    checkHtmlValues(o.htmlValues! as api.HtmlValues);
    checkIntegerValues(o.integerValues! as api.IntegerValues);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkObjectValues(o.objectValues! as api.ObjectValues);
    checkTextValues(o.textValues! as api.TextValues);
    checkTimestampValues(o.timestampValues! as api.TimestampValues);
  }
  buildCounterNamedProperty--;
}

core.List<api.PropertyDefinition> buildUnnamed4170() {
  var o = <api.PropertyDefinition>[];
  o.add(buildPropertyDefinition());
  o.add(buildPropertyDefinition());
  return o;
}

void checkUnnamed4170(core.List<api.PropertyDefinition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPropertyDefinition(o[0] as api.PropertyDefinition);
  checkPropertyDefinition(o[1] as api.PropertyDefinition);
}

core.int buildCounterObjectDefinition = 0;
api.ObjectDefinition buildObjectDefinition() {
  var o = api.ObjectDefinition();
  buildCounterObjectDefinition++;
  if (buildCounterObjectDefinition < 3) {
    o.name = 'foo';
    o.options = buildObjectOptions();
    o.propertyDefinitions = buildUnnamed4170();
  }
  buildCounterObjectDefinition--;
  return o;
}

void checkObjectDefinition(api.ObjectDefinition o) {
  buildCounterObjectDefinition++;
  if (buildCounterObjectDefinition < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkObjectOptions(o.options! as api.ObjectOptions);
    checkUnnamed4170(o.propertyDefinitions!);
  }
  buildCounterObjectDefinition--;
}

core.List<api.Metaline> buildUnnamed4171() {
  var o = <api.Metaline>[];
  o.add(buildMetaline());
  o.add(buildMetaline());
  return o;
}

void checkUnnamed4171(core.List<api.Metaline> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetaline(o[0] as api.Metaline);
  checkMetaline(o[1] as api.Metaline);
}

core.int buildCounterObjectDisplayOptions = 0;
api.ObjectDisplayOptions buildObjectDisplayOptions() {
  var o = api.ObjectDisplayOptions();
  buildCounterObjectDisplayOptions++;
  if (buildCounterObjectDisplayOptions < 3) {
    o.metalines = buildUnnamed4171();
    o.objectDisplayLabel = 'foo';
  }
  buildCounterObjectDisplayOptions--;
  return o;
}

void checkObjectDisplayOptions(api.ObjectDisplayOptions o) {
  buildCounterObjectDisplayOptions++;
  if (buildCounterObjectDisplayOptions < 3) {
    checkUnnamed4171(o.metalines!);
    unittest.expect(
      o.objectDisplayLabel!,
      unittest.equals('foo'),
    );
  }
  buildCounterObjectDisplayOptions--;
}

core.int buildCounterObjectOptions = 0;
api.ObjectOptions buildObjectOptions() {
  var o = api.ObjectOptions();
  buildCounterObjectOptions++;
  if (buildCounterObjectOptions < 3) {
    o.displayOptions = buildObjectDisplayOptions();
    o.freshnessOptions = buildFreshnessOptions();
  }
  buildCounterObjectOptions--;
  return o;
}

void checkObjectOptions(api.ObjectOptions o) {
  buildCounterObjectOptions++;
  if (buildCounterObjectOptions < 3) {
    checkObjectDisplayOptions(o.displayOptions! as api.ObjectDisplayOptions);
    checkFreshnessOptions(o.freshnessOptions! as api.FreshnessOptions);
  }
  buildCounterObjectOptions--;
}

core.List<api.PropertyDefinition> buildUnnamed4172() {
  var o = <api.PropertyDefinition>[];
  o.add(buildPropertyDefinition());
  o.add(buildPropertyDefinition());
  return o;
}

void checkUnnamed4172(core.List<api.PropertyDefinition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPropertyDefinition(o[0] as api.PropertyDefinition);
  checkPropertyDefinition(o[1] as api.PropertyDefinition);
}

core.int buildCounterObjectPropertyOptions = 0;
api.ObjectPropertyOptions buildObjectPropertyOptions() {
  var o = api.ObjectPropertyOptions();
  buildCounterObjectPropertyOptions++;
  if (buildCounterObjectPropertyOptions < 3) {
    o.subobjectProperties = buildUnnamed4172();
  }
  buildCounterObjectPropertyOptions--;
  return o;
}

void checkObjectPropertyOptions(api.ObjectPropertyOptions o) {
  buildCounterObjectPropertyOptions++;
  if (buildCounterObjectPropertyOptions < 3) {
    checkUnnamed4172(o.subobjectProperties!);
  }
  buildCounterObjectPropertyOptions--;
}

core.List<api.StructuredDataObject> buildUnnamed4173() {
  var o = <api.StructuredDataObject>[];
  o.add(buildStructuredDataObject());
  o.add(buildStructuredDataObject());
  return o;
}

void checkUnnamed4173(core.List<api.StructuredDataObject> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStructuredDataObject(o[0] as api.StructuredDataObject);
  checkStructuredDataObject(o[1] as api.StructuredDataObject);
}

core.int buildCounterObjectValues = 0;
api.ObjectValues buildObjectValues() {
  var o = api.ObjectValues();
  buildCounterObjectValues++;
  if (buildCounterObjectValues < 3) {
    o.values = buildUnnamed4173();
  }
  buildCounterObjectValues--;
  return o;
}

void checkObjectValues(api.ObjectValues o) {
  buildCounterObjectValues++;
  if (buildCounterObjectValues < 3) {
    checkUnnamed4173(o.values!);
  }
  buildCounterObjectValues--;
}

core.Map<core.String, core.Object> buildUnnamed4174() {
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

void checkUnnamed4174(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed4175() {
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

void checkUnnamed4175(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed4174();
    o.name = 'foo';
    o.response = buildUnnamed4175();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed4174(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4175(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterPeopleSuggestion = 0;
api.PeopleSuggestion buildPeopleSuggestion() {
  var o = api.PeopleSuggestion();
  buildCounterPeopleSuggestion++;
  if (buildCounterPeopleSuggestion < 3) {
    o.person = buildPerson();
  }
  buildCounterPeopleSuggestion--;
  return o;
}

void checkPeopleSuggestion(api.PeopleSuggestion o) {
  buildCounterPeopleSuggestion++;
  if (buildCounterPeopleSuggestion < 3) {
    checkPerson(o.person! as api.Person);
  }
  buildCounterPeopleSuggestion--;
}

core.List<api.EmailAddress> buildUnnamed4176() {
  var o = <api.EmailAddress>[];
  o.add(buildEmailAddress());
  o.add(buildEmailAddress());
  return o;
}

void checkUnnamed4176(core.List<api.EmailAddress> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEmailAddress(o[0] as api.EmailAddress);
  checkEmailAddress(o[1] as api.EmailAddress);
}

core.List<api.Name> buildUnnamed4177() {
  var o = <api.Name>[];
  o.add(buildName());
  o.add(buildName());
  return o;
}

void checkUnnamed4177(core.List<api.Name> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkName(o[0] as api.Name);
  checkName(o[1] as api.Name);
}

core.List<api.Photo> buildUnnamed4178() {
  var o = <api.Photo>[];
  o.add(buildPhoto());
  o.add(buildPhoto());
  return o;
}

void checkUnnamed4178(core.List<api.Photo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPhoto(o[0] as api.Photo);
  checkPhoto(o[1] as api.Photo);
}

core.int buildCounterPerson = 0;
api.Person buildPerson() {
  var o = api.Person();
  buildCounterPerson++;
  if (buildCounterPerson < 3) {
    o.emailAddresses = buildUnnamed4176();
    o.name = 'foo';
    o.obfuscatedId = 'foo';
    o.personNames = buildUnnamed4177();
    o.photos = buildUnnamed4178();
  }
  buildCounterPerson--;
  return o;
}

void checkPerson(api.Person o) {
  buildCounterPerson++;
  if (buildCounterPerson < 3) {
    checkUnnamed4176(o.emailAddresses!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.obfuscatedId!,
      unittest.equals('foo'),
    );
    checkUnnamed4177(o.personNames!);
    checkUnnamed4178(o.photos!);
  }
  buildCounterPerson--;
}

core.int buildCounterPhoto = 0;
api.Photo buildPhoto() {
  var o = api.Photo();
  buildCounterPhoto++;
  if (buildCounterPhoto < 3) {
    o.url = 'foo';
  }
  buildCounterPhoto--;
  return o;
}

void checkPhoto(api.Photo o) {
  buildCounterPhoto++;
  if (buildCounterPhoto < 3) {
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterPhoto--;
}

core.List<core.String> buildUnnamed4179() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4179(core.List<core.String> o) {
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

core.int buildCounterPollItemsRequest = 0;
api.PollItemsRequest buildPollItemsRequest() {
  var o = api.PollItemsRequest();
  buildCounterPollItemsRequest++;
  if (buildCounterPollItemsRequest < 3) {
    o.connectorName = 'foo';
    o.debugOptions = buildDebugOptions();
    o.limit = 42;
    o.queue = 'foo';
    o.statusCodes = buildUnnamed4179();
  }
  buildCounterPollItemsRequest--;
  return o;
}

void checkPollItemsRequest(api.PollItemsRequest o) {
  buildCounterPollItemsRequest++;
  if (buildCounterPollItemsRequest < 3) {
    unittest.expect(
      o.connectorName!,
      unittest.equals('foo'),
    );
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    unittest.expect(
      o.limit!,
      unittest.equals(42),
    );
    unittest.expect(
      o.queue!,
      unittest.equals('foo'),
    );
    checkUnnamed4179(o.statusCodes!);
  }
  buildCounterPollItemsRequest--;
}

core.List<api.Item> buildUnnamed4180() {
  var o = <api.Item>[];
  o.add(buildItem());
  o.add(buildItem());
  return o;
}

void checkUnnamed4180(core.List<api.Item> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkItem(o[0] as api.Item);
  checkItem(o[1] as api.Item);
}

core.int buildCounterPollItemsResponse = 0;
api.PollItemsResponse buildPollItemsResponse() {
  var o = api.PollItemsResponse();
  buildCounterPollItemsResponse++;
  if (buildCounterPollItemsResponse < 3) {
    o.items = buildUnnamed4180();
  }
  buildCounterPollItemsResponse--;
  return o;
}

void checkPollItemsResponse(api.PollItemsResponse o) {
  buildCounterPollItemsResponse++;
  if (buildCounterPollItemsResponse < 3) {
    checkUnnamed4180(o.items!);
  }
  buildCounterPollItemsResponse--;
}

core.int buildCounterPrincipal = 0;
api.Principal buildPrincipal() {
  var o = api.Principal();
  buildCounterPrincipal++;
  if (buildCounterPrincipal < 3) {
    o.groupResourceName = 'foo';
    o.gsuitePrincipal = buildGSuitePrincipal();
    o.userResourceName = 'foo';
  }
  buildCounterPrincipal--;
  return o;
}

void checkPrincipal(api.Principal o) {
  buildCounterPrincipal++;
  if (buildCounterPrincipal < 3) {
    unittest.expect(
      o.groupResourceName!,
      unittest.equals('foo'),
    );
    checkGSuitePrincipal(o.gsuitePrincipal! as api.GSuitePrincipal);
    unittest.expect(
      o.userResourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrincipal--;
}

core.List<api.FieldViolation> buildUnnamed4181() {
  var o = <api.FieldViolation>[];
  o.add(buildFieldViolation());
  o.add(buildFieldViolation());
  return o;
}

void checkUnnamed4181(core.List<api.FieldViolation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFieldViolation(o[0] as api.FieldViolation);
  checkFieldViolation(o[1] as api.FieldViolation);
}

core.int buildCounterProcessingError = 0;
api.ProcessingError buildProcessingError() {
  var o = api.ProcessingError();
  buildCounterProcessingError++;
  if (buildCounterProcessingError < 3) {
    o.code = 'foo';
    o.errorMessage = 'foo';
    o.fieldViolations = buildUnnamed4181();
  }
  buildCounterProcessingError--;
  return o;
}

void checkProcessingError(api.ProcessingError o) {
  buildCounterProcessingError++;
  if (buildCounterProcessingError < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    checkUnnamed4181(o.fieldViolations!);
  }
  buildCounterProcessingError--;
}

core.int buildCounterPropertyDefinition = 0;
api.PropertyDefinition buildPropertyDefinition() {
  var o = api.PropertyDefinition();
  buildCounterPropertyDefinition++;
  if (buildCounterPropertyDefinition < 3) {
    o.booleanPropertyOptions = buildBooleanPropertyOptions();
    o.datePropertyOptions = buildDatePropertyOptions();
    o.displayOptions = buildPropertyDisplayOptions();
    o.doublePropertyOptions = buildDoublePropertyOptions();
    o.enumPropertyOptions = buildEnumPropertyOptions();
    o.htmlPropertyOptions = buildHtmlPropertyOptions();
    o.integerPropertyOptions = buildIntegerPropertyOptions();
    o.isFacetable = true;
    o.isRepeatable = true;
    o.isReturnable = true;
    o.isSortable = true;
    o.isSuggestable = true;
    o.isWildcardSearchable = true;
    o.name = 'foo';
    o.objectPropertyOptions = buildObjectPropertyOptions();
    o.textPropertyOptions = buildTextPropertyOptions();
    o.timestampPropertyOptions = buildTimestampPropertyOptions();
  }
  buildCounterPropertyDefinition--;
  return o;
}

void checkPropertyDefinition(api.PropertyDefinition o) {
  buildCounterPropertyDefinition++;
  if (buildCounterPropertyDefinition < 3) {
    checkBooleanPropertyOptions(
        o.booleanPropertyOptions! as api.BooleanPropertyOptions);
    checkDatePropertyOptions(o.datePropertyOptions! as api.DatePropertyOptions);
    checkPropertyDisplayOptions(
        o.displayOptions! as api.PropertyDisplayOptions);
    checkDoublePropertyOptions(
        o.doublePropertyOptions! as api.DoublePropertyOptions);
    checkEnumPropertyOptions(o.enumPropertyOptions! as api.EnumPropertyOptions);
    checkHtmlPropertyOptions(o.htmlPropertyOptions! as api.HtmlPropertyOptions);
    checkIntegerPropertyOptions(
        o.integerPropertyOptions! as api.IntegerPropertyOptions);
    unittest.expect(o.isFacetable!, unittest.isTrue);
    unittest.expect(o.isRepeatable!, unittest.isTrue);
    unittest.expect(o.isReturnable!, unittest.isTrue);
    unittest.expect(o.isSortable!, unittest.isTrue);
    unittest.expect(o.isSuggestable!, unittest.isTrue);
    unittest.expect(o.isWildcardSearchable!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkObjectPropertyOptions(
        o.objectPropertyOptions! as api.ObjectPropertyOptions);
    checkTextPropertyOptions(o.textPropertyOptions! as api.TextPropertyOptions);
    checkTimestampPropertyOptions(
        o.timestampPropertyOptions! as api.TimestampPropertyOptions);
  }
  buildCounterPropertyDefinition--;
}

core.int buildCounterPropertyDisplayOptions = 0;
api.PropertyDisplayOptions buildPropertyDisplayOptions() {
  var o = api.PropertyDisplayOptions();
  buildCounterPropertyDisplayOptions++;
  if (buildCounterPropertyDisplayOptions < 3) {
    o.displayLabel = 'foo';
  }
  buildCounterPropertyDisplayOptions--;
  return o;
}

void checkPropertyDisplayOptions(api.PropertyDisplayOptions o) {
  buildCounterPropertyDisplayOptions++;
  if (buildCounterPropertyDisplayOptions < 3) {
    unittest.expect(
      o.displayLabel!,
      unittest.equals('foo'),
    );
  }
  buildCounterPropertyDisplayOptions--;
}

core.int buildCounterPushItem = 0;
api.PushItem buildPushItem() {
  var o = api.PushItem();
  buildCounterPushItem++;
  if (buildCounterPushItem < 3) {
    o.contentHash = 'foo';
    o.metadataHash = 'foo';
    o.payload = 'foo';
    o.queue = 'foo';
    o.repositoryError = buildRepositoryError();
    o.structuredDataHash = 'foo';
    o.type = 'foo';
  }
  buildCounterPushItem--;
  return o;
}

void checkPushItem(api.PushItem o) {
  buildCounterPushItem++;
  if (buildCounterPushItem < 3) {
    unittest.expect(
      o.contentHash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metadataHash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.payload!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queue!,
      unittest.equals('foo'),
    );
    checkRepositoryError(o.repositoryError! as api.RepositoryError);
    unittest.expect(
      o.structuredDataHash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterPushItem--;
}

core.int buildCounterPushItemRequest = 0;
api.PushItemRequest buildPushItemRequest() {
  var o = api.PushItemRequest();
  buildCounterPushItemRequest++;
  if (buildCounterPushItemRequest < 3) {
    o.connectorName = 'foo';
    o.debugOptions = buildDebugOptions();
    o.item = buildPushItem();
  }
  buildCounterPushItemRequest--;
  return o;
}

void checkPushItemRequest(api.PushItemRequest o) {
  buildCounterPushItemRequest++;
  if (buildCounterPushItemRequest < 3) {
    unittest.expect(
      o.connectorName!,
      unittest.equals('foo'),
    );
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    checkPushItem(o.item! as api.PushItem);
  }
  buildCounterPushItemRequest--;
}

core.int buildCounterQueryCountByStatus = 0;
api.QueryCountByStatus buildQueryCountByStatus() {
  var o = api.QueryCountByStatus();
  buildCounterQueryCountByStatus++;
  if (buildCounterQueryCountByStatus < 3) {
    o.count = 'foo';
    o.statusCode = 42;
  }
  buildCounterQueryCountByStatus--;
  return o;
}

void checkQueryCountByStatus(api.QueryCountByStatus o) {
  buildCounterQueryCountByStatus++;
  if (buildCounterQueryCountByStatus < 3) {
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.statusCode!,
      unittest.equals(42),
    );
  }
  buildCounterQueryCountByStatus--;
}

core.int buildCounterQueryInterpretation = 0;
api.QueryInterpretation buildQueryInterpretation() {
  var o = api.QueryInterpretation();
  buildCounterQueryInterpretation++;
  if (buildCounterQueryInterpretation < 3) {
    o.interpretationType = 'foo';
    o.interpretedQuery = 'foo';
    o.reason = 'foo';
  }
  buildCounterQueryInterpretation--;
  return o;
}

void checkQueryInterpretation(api.QueryInterpretation o) {
  buildCounterQueryInterpretation++;
  if (buildCounterQueryInterpretation < 3) {
    unittest.expect(
      o.interpretationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.interpretedQuery!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryInterpretation--;
}

core.int buildCounterQueryInterpretationOptions = 0;
api.QueryInterpretationOptions buildQueryInterpretationOptions() {
  var o = api.QueryInterpretationOptions();
  buildCounterQueryInterpretationOptions++;
  if (buildCounterQueryInterpretationOptions < 3) {
    o.disableNlInterpretation = true;
    o.enableVerbatimMode = true;
  }
  buildCounterQueryInterpretationOptions--;
  return o;
}

void checkQueryInterpretationOptions(api.QueryInterpretationOptions o) {
  buildCounterQueryInterpretationOptions++;
  if (buildCounterQueryInterpretationOptions < 3) {
    unittest.expect(o.disableNlInterpretation!, unittest.isTrue);
    unittest.expect(o.enableVerbatimMode!, unittest.isTrue);
  }
  buildCounterQueryInterpretationOptions--;
}

core.int buildCounterQueryItem = 0;
api.QueryItem buildQueryItem() {
  var o = api.QueryItem();
  buildCounterQueryItem++;
  if (buildCounterQueryItem < 3) {
    o.isSynthetic = true;
  }
  buildCounterQueryItem--;
  return o;
}

void checkQueryItem(api.QueryItem o) {
  buildCounterQueryItem++;
  if (buildCounterQueryItem < 3) {
    unittest.expect(o.isSynthetic!, unittest.isTrue);
  }
  buildCounterQueryItem--;
}

core.List<core.String> buildUnnamed4182() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4182(core.List<core.String> o) {
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

core.int buildCounterQueryOperator = 0;
api.QueryOperator buildQueryOperator() {
  var o = api.QueryOperator();
  buildCounterQueryOperator++;
  if (buildCounterQueryOperator < 3) {
    o.displayName = 'foo';
    o.enumValues = buildUnnamed4182();
    o.greaterThanOperatorName = 'foo';
    o.isFacetable = true;
    o.isRepeatable = true;
    o.isReturnable = true;
    o.isSortable = true;
    o.isSuggestable = true;
    o.lessThanOperatorName = 'foo';
    o.objectType = 'foo';
    o.operatorName = 'foo';
    o.type = 'foo';
  }
  buildCounterQueryOperator--;
  return o;
}

void checkQueryOperator(api.QueryOperator o) {
  buildCounterQueryOperator++;
  if (buildCounterQueryOperator < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4182(o.enumValues!);
    unittest.expect(
      o.greaterThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isFacetable!, unittest.isTrue);
    unittest.expect(o.isRepeatable!, unittest.isTrue);
    unittest.expect(o.isReturnable!, unittest.isTrue);
    unittest.expect(o.isSortable!, unittest.isTrue);
    unittest.expect(o.isSuggestable!, unittest.isTrue);
    unittest.expect(
      o.lessThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryOperator--;
}

core.List<api.QueryOperator> buildUnnamed4183() {
  var o = <api.QueryOperator>[];
  o.add(buildQueryOperator());
  o.add(buildQueryOperator());
  return o;
}

void checkUnnamed4183(core.List<api.QueryOperator> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryOperator(o[0] as api.QueryOperator);
  checkQueryOperator(o[1] as api.QueryOperator);
}

core.int buildCounterQuerySource = 0;
api.QuerySource buildQuerySource() {
  var o = api.QuerySource();
  buildCounterQuerySource++;
  if (buildCounterQuerySource < 3) {
    o.displayName = 'foo';
    o.operators = buildUnnamed4183();
    o.shortName = 'foo';
    o.source = buildSource();
  }
  buildCounterQuerySource--;
  return o;
}

void checkQuerySource(api.QuerySource o) {
  buildCounterQuerySource++;
  if (buildCounterQuerySource < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed4183(o.operators!);
    unittest.expect(
      o.shortName!,
      unittest.equals('foo'),
    );
    checkSource(o.source! as api.Source);
  }
  buildCounterQuerySource--;
}

core.int buildCounterQuerySuggestion = 0;
api.QuerySuggestion buildQuerySuggestion() {
  var o = api.QuerySuggestion();
  buildCounterQuerySuggestion++;
  if (buildCounterQuerySuggestion < 3) {}
  buildCounterQuerySuggestion--;
  return o;
}

void checkQuerySuggestion(api.QuerySuggestion o) {
  buildCounterQuerySuggestion++;
  if (buildCounterQuerySuggestion < 3) {}
  buildCounterQuerySuggestion--;
}

core.int buildCounterRepositoryError = 0;
api.RepositoryError buildRepositoryError() {
  var o = api.RepositoryError();
  buildCounterRepositoryError++;
  if (buildCounterRepositoryError < 3) {
    o.errorMessage = 'foo';
    o.httpStatusCode = 42;
    o.type = 'foo';
  }
  buildCounterRepositoryError--;
  return o;
}

void checkRepositoryError(api.RepositoryError o) {
  buildCounterRepositoryError++;
  if (buildCounterRepositoryError < 3) {
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.httpStatusCode!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterRepositoryError--;
}

core.int buildCounterRequestOptions = 0;
api.RequestOptions buildRequestOptions() {
  var o = api.RequestOptions();
  buildCounterRequestOptions++;
  if (buildCounterRequestOptions < 3) {
    o.debugOptions = buildDebugOptions();
    o.languageCode = 'foo';
    o.searchApplicationId = 'foo';
    o.timeZone = 'foo';
  }
  buildCounterRequestOptions--;
  return o;
}

void checkRequestOptions(api.RequestOptions o) {
  buildCounterRequestOptions++;
  if (buildCounterRequestOptions < 3) {
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.searchApplicationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterRequestOptions--;
}

core.int buildCounterResetSearchApplicationRequest = 0;
api.ResetSearchApplicationRequest buildResetSearchApplicationRequest() {
  var o = api.ResetSearchApplicationRequest();
  buildCounterResetSearchApplicationRequest++;
  if (buildCounterResetSearchApplicationRequest < 3) {
    o.debugOptions = buildDebugOptions();
  }
  buildCounterResetSearchApplicationRequest--;
  return o;
}

void checkResetSearchApplicationRequest(api.ResetSearchApplicationRequest o) {
  buildCounterResetSearchApplicationRequest++;
  if (buildCounterResetSearchApplicationRequest < 3) {
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
  }
  buildCounterResetSearchApplicationRequest--;
}

core.int buildCounterResponseDebugInfo = 0;
api.ResponseDebugInfo buildResponseDebugInfo() {
  var o = api.ResponseDebugInfo();
  buildCounterResponseDebugInfo++;
  if (buildCounterResponseDebugInfo < 3) {
    o.formattedDebugInfo = 'foo';
  }
  buildCounterResponseDebugInfo--;
  return o;
}

void checkResponseDebugInfo(api.ResponseDebugInfo o) {
  buildCounterResponseDebugInfo++;
  if (buildCounterResponseDebugInfo < 3) {
    unittest.expect(
      o.formattedDebugInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterResponseDebugInfo--;
}

core.int buildCounterRestrictItem = 0;
api.RestrictItem buildRestrictItem() {
  var o = api.RestrictItem();
  buildCounterRestrictItem++;
  if (buildCounterRestrictItem < 3) {
    o.driveFollowUpRestrict = buildDriveFollowUpRestrict();
    o.driveLocationRestrict = buildDriveLocationRestrict();
    o.driveMimeTypeRestrict = buildDriveMimeTypeRestrict();
    o.driveTimeSpanRestrict = buildDriveTimeSpanRestrict();
    o.searchOperator = 'foo';
  }
  buildCounterRestrictItem--;
  return o;
}

void checkRestrictItem(api.RestrictItem o) {
  buildCounterRestrictItem++;
  if (buildCounterRestrictItem < 3) {
    checkDriveFollowUpRestrict(
        o.driveFollowUpRestrict! as api.DriveFollowUpRestrict);
    checkDriveLocationRestrict(
        o.driveLocationRestrict! as api.DriveLocationRestrict);
    checkDriveMimeTypeRestrict(
        o.driveMimeTypeRestrict! as api.DriveMimeTypeRestrict);
    checkDriveTimeSpanRestrict(
        o.driveTimeSpanRestrict! as api.DriveTimeSpanRestrict);
    unittest.expect(
      o.searchOperator!,
      unittest.equals('foo'),
    );
  }
  buildCounterRestrictItem--;
}

core.List<api.SourceResultCount> buildUnnamed4184() {
  var o = <api.SourceResultCount>[];
  o.add(buildSourceResultCount());
  o.add(buildSourceResultCount());
  return o;
}

void checkUnnamed4184(core.List<api.SourceResultCount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSourceResultCount(o[0] as api.SourceResultCount);
  checkSourceResultCount(o[1] as api.SourceResultCount);
}

core.int buildCounterResultCounts = 0;
api.ResultCounts buildResultCounts() {
  var o = api.ResultCounts();
  buildCounterResultCounts++;
  if (buildCounterResultCounts < 3) {
    o.sourceResultCounts = buildUnnamed4184();
  }
  buildCounterResultCounts--;
  return o;
}

void checkResultCounts(api.ResultCounts o) {
  buildCounterResultCounts++;
  if (buildCounterResultCounts < 3) {
    checkUnnamed4184(o.sourceResultCounts!);
  }
  buildCounterResultCounts--;
}

core.int buildCounterResultDebugInfo = 0;
api.ResultDebugInfo buildResultDebugInfo() {
  var o = api.ResultDebugInfo();
  buildCounterResultDebugInfo++;
  if (buildCounterResultDebugInfo < 3) {
    o.formattedDebugInfo = 'foo';
  }
  buildCounterResultDebugInfo--;
  return o;
}

void checkResultDebugInfo(api.ResultDebugInfo o) {
  buildCounterResultDebugInfo++;
  if (buildCounterResultDebugInfo < 3) {
    unittest.expect(
      o.formattedDebugInfo!,
      unittest.equals('foo'),
    );
  }
  buildCounterResultDebugInfo--;
}

core.int buildCounterResultDisplayField = 0;
api.ResultDisplayField buildResultDisplayField() {
  var o = api.ResultDisplayField();
  buildCounterResultDisplayField++;
  if (buildCounterResultDisplayField < 3) {
    o.label = 'foo';
    o.operatorName = 'foo';
    o.property = buildNamedProperty();
  }
  buildCounterResultDisplayField--;
  return o;
}

void checkResultDisplayField(api.ResultDisplayField o) {
  buildCounterResultDisplayField++;
  if (buildCounterResultDisplayField < 3) {
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
    checkNamedProperty(o.property! as api.NamedProperty);
  }
  buildCounterResultDisplayField--;
}

core.List<api.ResultDisplayField> buildUnnamed4185() {
  var o = <api.ResultDisplayField>[];
  o.add(buildResultDisplayField());
  o.add(buildResultDisplayField());
  return o;
}

void checkUnnamed4185(core.List<api.ResultDisplayField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResultDisplayField(o[0] as api.ResultDisplayField);
  checkResultDisplayField(o[1] as api.ResultDisplayField);
}

core.int buildCounterResultDisplayLine = 0;
api.ResultDisplayLine buildResultDisplayLine() {
  var o = api.ResultDisplayLine();
  buildCounterResultDisplayLine++;
  if (buildCounterResultDisplayLine < 3) {
    o.fields = buildUnnamed4185();
  }
  buildCounterResultDisplayLine--;
  return o;
}

void checkResultDisplayLine(api.ResultDisplayLine o) {
  buildCounterResultDisplayLine++;
  if (buildCounterResultDisplayLine < 3) {
    checkUnnamed4185(o.fields!);
  }
  buildCounterResultDisplayLine--;
}

core.List<api.ResultDisplayLine> buildUnnamed4186() {
  var o = <api.ResultDisplayLine>[];
  o.add(buildResultDisplayLine());
  o.add(buildResultDisplayLine());
  return o;
}

void checkUnnamed4186(core.List<api.ResultDisplayLine> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResultDisplayLine(o[0] as api.ResultDisplayLine);
  checkResultDisplayLine(o[1] as api.ResultDisplayLine);
}

core.int buildCounterResultDisplayMetadata = 0;
api.ResultDisplayMetadata buildResultDisplayMetadata() {
  var o = api.ResultDisplayMetadata();
  buildCounterResultDisplayMetadata++;
  if (buildCounterResultDisplayMetadata < 3) {
    o.metalines = buildUnnamed4186();
    o.objectTypeLabel = 'foo';
  }
  buildCounterResultDisplayMetadata--;
  return o;
}

void checkResultDisplayMetadata(api.ResultDisplayMetadata o) {
  buildCounterResultDisplayMetadata++;
  if (buildCounterResultDisplayMetadata < 3) {
    checkUnnamed4186(o.metalines!);
    unittest.expect(
      o.objectTypeLabel!,
      unittest.equals('foo'),
    );
  }
  buildCounterResultDisplayMetadata--;
}

core.int buildCounterRetrievalImportance = 0;
api.RetrievalImportance buildRetrievalImportance() {
  var o = api.RetrievalImportance();
  buildCounterRetrievalImportance++;
  if (buildCounterRetrievalImportance < 3) {
    o.importance = 'foo';
  }
  buildCounterRetrievalImportance--;
  return o;
}

void checkRetrievalImportance(api.RetrievalImportance o) {
  buildCounterRetrievalImportance++;
  if (buildCounterRetrievalImportance < 3) {
    unittest.expect(
      o.importance!,
      unittest.equals('foo'),
    );
  }
  buildCounterRetrievalImportance--;
}

core.List<api.ObjectDefinition> buildUnnamed4187() {
  var o = <api.ObjectDefinition>[];
  o.add(buildObjectDefinition());
  o.add(buildObjectDefinition());
  return o;
}

void checkUnnamed4187(core.List<api.ObjectDefinition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkObjectDefinition(o[0] as api.ObjectDefinition);
  checkObjectDefinition(o[1] as api.ObjectDefinition);
}

core.List<core.String> buildUnnamed4188() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4188(core.List<core.String> o) {
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

core.int buildCounterSchema = 0;
api.Schema buildSchema() {
  var o = api.Schema();
  buildCounterSchema++;
  if (buildCounterSchema < 3) {
    o.objectDefinitions = buildUnnamed4187();
    o.operationIds = buildUnnamed4188();
  }
  buildCounterSchema--;
  return o;
}

void checkSchema(api.Schema o) {
  buildCounterSchema++;
  if (buildCounterSchema < 3) {
    checkUnnamed4187(o.objectDefinitions!);
    checkUnnamed4188(o.operationIds!);
  }
  buildCounterSchema--;
}

core.int buildCounterScoringConfig = 0;
api.ScoringConfig buildScoringConfig() {
  var o = api.ScoringConfig();
  buildCounterScoringConfig++;
  if (buildCounterScoringConfig < 3) {
    o.disableFreshness = true;
    o.disablePersonalization = true;
  }
  buildCounterScoringConfig--;
  return o;
}

void checkScoringConfig(api.ScoringConfig o) {
  buildCounterScoringConfig++;
  if (buildCounterScoringConfig < 3) {
    unittest.expect(o.disableFreshness!, unittest.isTrue);
    unittest.expect(o.disablePersonalization!, unittest.isTrue);
  }
  buildCounterScoringConfig--;
}

core.List<api.DataSourceRestriction> buildUnnamed4189() {
  var o = <api.DataSourceRestriction>[];
  o.add(buildDataSourceRestriction());
  o.add(buildDataSourceRestriction());
  return o;
}

void checkUnnamed4189(core.List<api.DataSourceRestriction> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceRestriction(o[0] as api.DataSourceRestriction);
  checkDataSourceRestriction(o[1] as api.DataSourceRestriction);
}

core.List<api.FacetOptions> buildUnnamed4190() {
  var o = <api.FacetOptions>[];
  o.add(buildFacetOptions());
  o.add(buildFacetOptions());
  return o;
}

void checkUnnamed4190(core.List<api.FacetOptions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFacetOptions(o[0] as api.FacetOptions);
  checkFacetOptions(o[1] as api.FacetOptions);
}

core.List<core.String> buildUnnamed4191() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4191(core.List<core.String> o) {
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

core.List<api.SourceConfig> buildUnnamed4192() {
  var o = <api.SourceConfig>[];
  o.add(buildSourceConfig());
  o.add(buildSourceConfig());
  return o;
}

void checkUnnamed4192(core.List<api.SourceConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSourceConfig(o[0] as api.SourceConfig);
  checkSourceConfig(o[1] as api.SourceConfig);
}

core.int buildCounterSearchApplication = 0;
api.SearchApplication buildSearchApplication() {
  var o = api.SearchApplication();
  buildCounterSearchApplication++;
  if (buildCounterSearchApplication < 3) {
    o.dataSourceRestrictions = buildUnnamed4189();
    o.defaultFacetOptions = buildUnnamed4190();
    o.defaultSortOptions = buildSortOptions();
    o.displayName = 'foo';
    o.enableAuditLog = true;
    o.name = 'foo';
    o.operationIds = buildUnnamed4191();
    o.scoringConfig = buildScoringConfig();
    o.sourceConfig = buildUnnamed4192();
  }
  buildCounterSearchApplication--;
  return o;
}

void checkSearchApplication(api.SearchApplication o) {
  buildCounterSearchApplication++;
  if (buildCounterSearchApplication < 3) {
    checkUnnamed4189(o.dataSourceRestrictions!);
    checkUnnamed4190(o.defaultFacetOptions!);
    checkSortOptions(o.defaultSortOptions! as api.SortOptions);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableAuditLog!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4191(o.operationIds!);
    checkScoringConfig(o.scoringConfig! as api.ScoringConfig);
    checkUnnamed4192(o.sourceConfig!);
  }
  buildCounterSearchApplication--;
}

core.List<api.QueryCountByStatus> buildUnnamed4193() {
  var o = <api.QueryCountByStatus>[];
  o.add(buildQueryCountByStatus());
  o.add(buildQueryCountByStatus());
  return o;
}

void checkUnnamed4193(core.List<api.QueryCountByStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryCountByStatus(o[0] as api.QueryCountByStatus);
  checkQueryCountByStatus(o[1] as api.QueryCountByStatus);
}

core.int buildCounterSearchApplicationQueryStats = 0;
api.SearchApplicationQueryStats buildSearchApplicationQueryStats() {
  var o = api.SearchApplicationQueryStats();
  buildCounterSearchApplicationQueryStats++;
  if (buildCounterSearchApplicationQueryStats < 3) {
    o.date = buildDate();
    o.queryCountByStatus = buildUnnamed4193();
  }
  buildCounterSearchApplicationQueryStats--;
  return o;
}

void checkSearchApplicationQueryStats(api.SearchApplicationQueryStats o) {
  buildCounterSearchApplicationQueryStats++;
  if (buildCounterSearchApplicationQueryStats < 3) {
    checkDate(o.date! as api.Date);
    checkUnnamed4193(o.queryCountByStatus!);
  }
  buildCounterSearchApplicationQueryStats--;
}

core.int buildCounterSearchApplicationSessionStats = 0;
api.SearchApplicationSessionStats buildSearchApplicationSessionStats() {
  var o = api.SearchApplicationSessionStats();
  buildCounterSearchApplicationSessionStats++;
  if (buildCounterSearchApplicationSessionStats < 3) {
    o.date = buildDate();
    o.searchSessionsCount = 'foo';
  }
  buildCounterSearchApplicationSessionStats--;
  return o;
}

void checkSearchApplicationSessionStats(api.SearchApplicationSessionStats o) {
  buildCounterSearchApplicationSessionStats++;
  if (buildCounterSearchApplicationSessionStats < 3) {
    checkDate(o.date! as api.Date);
    unittest.expect(
      o.searchSessionsCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchApplicationSessionStats--;
}

core.int buildCounterSearchApplicationUserStats = 0;
api.SearchApplicationUserStats buildSearchApplicationUserStats() {
  var o = api.SearchApplicationUserStats();
  buildCounterSearchApplicationUserStats++;
  if (buildCounterSearchApplicationUserStats < 3) {
    o.date = buildDate();
    o.oneDayActiveUsersCount = 'foo';
    o.sevenDaysActiveUsersCount = 'foo';
    o.thirtyDaysActiveUsersCount = 'foo';
  }
  buildCounterSearchApplicationUserStats--;
  return o;
}

void checkSearchApplicationUserStats(api.SearchApplicationUserStats o) {
  buildCounterSearchApplicationUserStats++;
  if (buildCounterSearchApplicationUserStats < 3) {
    checkDate(o.date! as api.Date);
    unittest.expect(
      o.oneDayActiveUsersCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sevenDaysActiveUsersCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thirtyDaysActiveUsersCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchApplicationUserStats--;
}

core.int buildCounterSearchItemsByViewUrlRequest = 0;
api.SearchItemsByViewUrlRequest buildSearchItemsByViewUrlRequest() {
  var o = api.SearchItemsByViewUrlRequest();
  buildCounterSearchItemsByViewUrlRequest++;
  if (buildCounterSearchItemsByViewUrlRequest < 3) {
    o.debugOptions = buildDebugOptions();
    o.pageToken = 'foo';
    o.viewUrl = 'foo';
  }
  buildCounterSearchItemsByViewUrlRequest--;
  return o;
}

void checkSearchItemsByViewUrlRequest(api.SearchItemsByViewUrlRequest o) {
  buildCounterSearchItemsByViewUrlRequest++;
  if (buildCounterSearchItemsByViewUrlRequest < 3) {
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchItemsByViewUrlRequest--;
}

core.List<api.Item> buildUnnamed4194() {
  var o = <api.Item>[];
  o.add(buildItem());
  o.add(buildItem());
  return o;
}

void checkUnnamed4194(core.List<api.Item> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkItem(o[0] as api.Item);
  checkItem(o[1] as api.Item);
}

core.int buildCounterSearchItemsByViewUrlResponse = 0;
api.SearchItemsByViewUrlResponse buildSearchItemsByViewUrlResponse() {
  var o = api.SearchItemsByViewUrlResponse();
  buildCounterSearchItemsByViewUrlResponse++;
  if (buildCounterSearchItemsByViewUrlResponse < 3) {
    o.items = buildUnnamed4194();
    o.nextPageToken = 'foo';
  }
  buildCounterSearchItemsByViewUrlResponse--;
  return o;
}

void checkSearchItemsByViewUrlResponse(api.SearchItemsByViewUrlResponse o) {
  buildCounterSearchItemsByViewUrlResponse++;
  if (buildCounterSearchItemsByViewUrlResponse < 3) {
    checkUnnamed4194(o.items!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchItemsByViewUrlResponse--;
}

core.int buildCounterSearchQualityMetadata = 0;
api.SearchQualityMetadata buildSearchQualityMetadata() {
  var o = api.SearchQualityMetadata();
  buildCounterSearchQualityMetadata++;
  if (buildCounterSearchQualityMetadata < 3) {
    o.quality = 42.0;
  }
  buildCounterSearchQualityMetadata--;
  return o;
}

void checkSearchQualityMetadata(api.SearchQualityMetadata o) {
  buildCounterSearchQualityMetadata++;
  if (buildCounterSearchQualityMetadata < 3) {
    unittest.expect(
      o.quality!,
      unittest.equals(42.0),
    );
  }
  buildCounterSearchQualityMetadata--;
}

core.List<api.ContextAttribute> buildUnnamed4195() {
  var o = <api.ContextAttribute>[];
  o.add(buildContextAttribute());
  o.add(buildContextAttribute());
  return o;
}

void checkUnnamed4195(core.List<api.ContextAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContextAttribute(o[0] as api.ContextAttribute);
  checkContextAttribute(o[1] as api.ContextAttribute);
}

core.List<api.DataSourceRestriction> buildUnnamed4196() {
  var o = <api.DataSourceRestriction>[];
  o.add(buildDataSourceRestriction());
  o.add(buildDataSourceRestriction());
  return o;
}

void checkUnnamed4196(core.List<api.DataSourceRestriction> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceRestriction(o[0] as api.DataSourceRestriction);
  checkDataSourceRestriction(o[1] as api.DataSourceRestriction);
}

core.List<api.FacetOptions> buildUnnamed4197() {
  var o = <api.FacetOptions>[];
  o.add(buildFacetOptions());
  o.add(buildFacetOptions());
  return o;
}

void checkUnnamed4197(core.List<api.FacetOptions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFacetOptions(o[0] as api.FacetOptions);
  checkFacetOptions(o[1] as api.FacetOptions);
}

core.int buildCounterSearchRequest = 0;
api.SearchRequest buildSearchRequest() {
  var o = api.SearchRequest();
  buildCounterSearchRequest++;
  if (buildCounterSearchRequest < 3) {
    o.contextAttributes = buildUnnamed4195();
    o.dataSourceRestrictions = buildUnnamed4196();
    o.facetOptions = buildUnnamed4197();
    o.pageSize = 42;
    o.query = 'foo';
    o.queryInterpretationOptions = buildQueryInterpretationOptions();
    o.requestOptions = buildRequestOptions();
    o.sortOptions = buildSortOptions();
    o.start = 42;
  }
  buildCounterSearchRequest--;
  return o;
}

void checkSearchRequest(api.SearchRequest o) {
  buildCounterSearchRequest++;
  if (buildCounterSearchRequest < 3) {
    checkUnnamed4195(o.contextAttributes!);
    checkUnnamed4196(o.dataSourceRestrictions!);
    checkUnnamed4197(o.facetOptions!);
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    checkQueryInterpretationOptions(
        o.queryInterpretationOptions! as api.QueryInterpretationOptions);
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
    checkSortOptions(o.sortOptions! as api.SortOptions);
    unittest.expect(
      o.start!,
      unittest.equals(42),
    );
  }
  buildCounterSearchRequest--;
}

core.List<api.FacetResult> buildUnnamed4198() {
  var o = <api.FacetResult>[];
  o.add(buildFacetResult());
  o.add(buildFacetResult());
  return o;
}

void checkUnnamed4198(core.List<api.FacetResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFacetResult(o[0] as api.FacetResult);
  checkFacetResult(o[1] as api.FacetResult);
}

core.List<api.SearchResult> buildUnnamed4199() {
  var o = <api.SearchResult>[];
  o.add(buildSearchResult());
  o.add(buildSearchResult());
  return o;
}

void checkUnnamed4199(core.List<api.SearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchResult(o[0] as api.SearchResult);
  checkSearchResult(o[1] as api.SearchResult);
}

core.List<api.SpellResult> buildUnnamed4200() {
  var o = <api.SpellResult>[];
  o.add(buildSpellResult());
  o.add(buildSpellResult());
  return o;
}

void checkUnnamed4200(core.List<api.SpellResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpellResult(o[0] as api.SpellResult);
  checkSpellResult(o[1] as api.SpellResult);
}

core.List<api.StructuredResult> buildUnnamed4201() {
  var o = <api.StructuredResult>[];
  o.add(buildStructuredResult());
  o.add(buildStructuredResult());
  return o;
}

void checkUnnamed4201(core.List<api.StructuredResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStructuredResult(o[0] as api.StructuredResult);
  checkStructuredResult(o[1] as api.StructuredResult);
}

core.int buildCounterSearchResponse = 0;
api.SearchResponse buildSearchResponse() {
  var o = api.SearchResponse();
  buildCounterSearchResponse++;
  if (buildCounterSearchResponse < 3) {
    o.debugInfo = buildResponseDebugInfo();
    o.errorInfo = buildErrorInfo();
    o.facetResults = buildUnnamed4198();
    o.hasMoreResults = true;
    o.queryInterpretation = buildQueryInterpretation();
    o.resultCountEstimate = 'foo';
    o.resultCountExact = 'foo';
    o.resultCounts = buildResultCounts();
    o.results = buildUnnamed4199();
    o.spellResults = buildUnnamed4200();
    o.structuredResults = buildUnnamed4201();
  }
  buildCounterSearchResponse--;
  return o;
}

void checkSearchResponse(api.SearchResponse o) {
  buildCounterSearchResponse++;
  if (buildCounterSearchResponse < 3) {
    checkResponseDebugInfo(o.debugInfo! as api.ResponseDebugInfo);
    checkErrorInfo(o.errorInfo! as api.ErrorInfo);
    checkUnnamed4198(o.facetResults!);
    unittest.expect(o.hasMoreResults!, unittest.isTrue);
    checkQueryInterpretation(o.queryInterpretation! as api.QueryInterpretation);
    unittest.expect(
      o.resultCountEstimate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resultCountExact!,
      unittest.equals('foo'),
    );
    checkResultCounts(o.resultCounts! as api.ResultCounts);
    checkUnnamed4199(o.results!);
    checkUnnamed4200(o.spellResults!);
    checkUnnamed4201(o.structuredResults!);
  }
  buildCounterSearchResponse--;
}

core.List<api.SearchResult> buildUnnamed4202() {
  var o = <api.SearchResult>[];
  o.add(buildSearchResult());
  o.add(buildSearchResult());
  return o;
}

void checkUnnamed4202(core.List<api.SearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchResult(o[0] as api.SearchResult);
  checkSearchResult(o[1] as api.SearchResult);
}

core.int buildCounterSearchResult = 0;
api.SearchResult buildSearchResult() {
  var o = api.SearchResult();
  buildCounterSearchResult++;
  if (buildCounterSearchResult < 3) {
    o.clusteredResults = buildUnnamed4202();
    o.debugInfo = buildResultDebugInfo();
    o.metadata = buildMetadata();
    o.snippet = buildSnippet();
    o.title = 'foo';
    o.url = 'foo';
  }
  buildCounterSearchResult--;
  return o;
}

void checkSearchResult(api.SearchResult o) {
  buildCounterSearchResult++;
  if (buildCounterSearchResult < 3) {
    checkUnnamed4202(o.clusteredResults!);
    checkResultDebugInfo(o.debugInfo! as api.ResultDebugInfo);
    checkMetadata(o.metadata! as api.Metadata);
    checkSnippet(o.snippet! as api.Snippet);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchResult--;
}

core.List<api.MatchRange> buildUnnamed4203() {
  var o = <api.MatchRange>[];
  o.add(buildMatchRange());
  o.add(buildMatchRange());
  return o;
}

void checkUnnamed4203(core.List<api.MatchRange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMatchRange(o[0] as api.MatchRange);
  checkMatchRange(o[1] as api.MatchRange);
}

core.int buildCounterSnippet = 0;
api.Snippet buildSnippet() {
  var o = api.Snippet();
  buildCounterSnippet++;
  if (buildCounterSnippet < 3) {
    o.matchRanges = buildUnnamed4203();
    o.snippet = 'foo';
  }
  buildCounterSnippet--;
  return o;
}

void checkSnippet(api.Snippet o) {
  buildCounterSnippet++;
  if (buildCounterSnippet < 3) {
    checkUnnamed4203(o.matchRanges!);
    unittest.expect(
      o.snippet!,
      unittest.equals('foo'),
    );
  }
  buildCounterSnippet--;
}

core.int buildCounterSortOptions = 0;
api.SortOptions buildSortOptions() {
  var o = api.SortOptions();
  buildCounterSortOptions++;
  if (buildCounterSortOptions < 3) {
    o.operatorName = 'foo';
    o.sortOrder = 'foo';
  }
  buildCounterSortOptions--;
  return o;
}

void checkSortOptions(api.SortOptions o) {
  buildCounterSortOptions++;
  if (buildCounterSortOptions < 3) {
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sortOrder!,
      unittest.equals('foo'),
    );
  }
  buildCounterSortOptions--;
}

core.int buildCounterSource = 0;
api.Source buildSource() {
  var o = api.Source();
  buildCounterSource++;
  if (buildCounterSource < 3) {
    o.name = 'foo';
    o.predefinedSource = 'foo';
  }
  buildCounterSource--;
  return o;
}

void checkSource(api.Source o) {
  buildCounterSource++;
  if (buildCounterSource < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.predefinedSource!,
      unittest.equals('foo'),
    );
  }
  buildCounterSource--;
}

core.int buildCounterSourceConfig = 0;
api.SourceConfig buildSourceConfig() {
  var o = api.SourceConfig();
  buildCounterSourceConfig++;
  if (buildCounterSourceConfig < 3) {
    o.crowdingConfig = buildSourceCrowdingConfig();
    o.scoringConfig = buildSourceScoringConfig();
    o.source = buildSource();
  }
  buildCounterSourceConfig--;
  return o;
}

void checkSourceConfig(api.SourceConfig o) {
  buildCounterSourceConfig++;
  if (buildCounterSourceConfig < 3) {
    checkSourceCrowdingConfig(o.crowdingConfig! as api.SourceCrowdingConfig);
    checkSourceScoringConfig(o.scoringConfig! as api.SourceScoringConfig);
    checkSource(o.source! as api.Source);
  }
  buildCounterSourceConfig--;
}

core.int buildCounterSourceCrowdingConfig = 0;
api.SourceCrowdingConfig buildSourceCrowdingConfig() {
  var o = api.SourceCrowdingConfig();
  buildCounterSourceCrowdingConfig++;
  if (buildCounterSourceCrowdingConfig < 3) {
    o.numResults = 42;
    o.numSuggestions = 42;
  }
  buildCounterSourceCrowdingConfig--;
  return o;
}

void checkSourceCrowdingConfig(api.SourceCrowdingConfig o) {
  buildCounterSourceCrowdingConfig++;
  if (buildCounterSourceCrowdingConfig < 3) {
    unittest.expect(
      o.numResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numSuggestions!,
      unittest.equals(42),
    );
  }
  buildCounterSourceCrowdingConfig--;
}

core.int buildCounterSourceResultCount = 0;
api.SourceResultCount buildSourceResultCount() {
  var o = api.SourceResultCount();
  buildCounterSourceResultCount++;
  if (buildCounterSourceResultCount < 3) {
    o.hasMoreResults = true;
    o.resultCountEstimate = 'foo';
    o.resultCountExact = 'foo';
    o.source = buildSource();
  }
  buildCounterSourceResultCount--;
  return o;
}

void checkSourceResultCount(api.SourceResultCount o) {
  buildCounterSourceResultCount++;
  if (buildCounterSourceResultCount < 3) {
    unittest.expect(o.hasMoreResults!, unittest.isTrue);
    unittest.expect(
      o.resultCountEstimate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resultCountExact!,
      unittest.equals('foo'),
    );
    checkSource(o.source! as api.Source);
  }
  buildCounterSourceResultCount--;
}

core.int buildCounterSourceScoringConfig = 0;
api.SourceScoringConfig buildSourceScoringConfig() {
  var o = api.SourceScoringConfig();
  buildCounterSourceScoringConfig++;
  if (buildCounterSourceScoringConfig < 3) {
    o.sourceImportance = 'foo';
  }
  buildCounterSourceScoringConfig--;
  return o;
}

void checkSourceScoringConfig(api.SourceScoringConfig o) {
  buildCounterSourceScoringConfig++;
  if (buildCounterSourceScoringConfig < 3) {
    unittest.expect(
      o.sourceImportance!,
      unittest.equals('foo'),
    );
  }
  buildCounterSourceScoringConfig--;
}

core.int buildCounterSpellResult = 0;
api.SpellResult buildSpellResult() {
  var o = api.SpellResult();
  buildCounterSpellResult++;
  if (buildCounterSpellResult < 3) {
    o.suggestedQuery = 'foo';
  }
  buildCounterSpellResult--;
  return o;
}

void checkSpellResult(api.SpellResult o) {
  buildCounterSpellResult++;
  if (buildCounterSpellResult < 3) {
    unittest.expect(
      o.suggestedQuery!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpellResult--;
}

core.int buildCounterStartUploadItemRequest = 0;
api.StartUploadItemRequest buildStartUploadItemRequest() {
  var o = api.StartUploadItemRequest();
  buildCounterStartUploadItemRequest++;
  if (buildCounterStartUploadItemRequest < 3) {
    o.connectorName = 'foo';
    o.debugOptions = buildDebugOptions();
  }
  buildCounterStartUploadItemRequest--;
  return o;
}

void checkStartUploadItemRequest(api.StartUploadItemRequest o) {
  buildCounterStartUploadItemRequest++;
  if (buildCounterStartUploadItemRequest < 3) {
    unittest.expect(
      o.connectorName!,
      unittest.equals('foo'),
    );
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
  }
  buildCounterStartUploadItemRequest--;
}

core.Map<core.String, core.Object> buildUnnamed4204() {
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

void checkUnnamed4204(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed4205() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed4204());
  o.add(buildUnnamed4204());
  return o;
}

void checkUnnamed4205(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed4204(o[0]);
  checkUnnamed4204(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed4205();
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
    checkUnnamed4205(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.List<api.NamedProperty> buildUnnamed4206() {
  var o = <api.NamedProperty>[];
  o.add(buildNamedProperty());
  o.add(buildNamedProperty());
  return o;
}

void checkUnnamed4206(core.List<api.NamedProperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNamedProperty(o[0] as api.NamedProperty);
  checkNamedProperty(o[1] as api.NamedProperty);
}

core.int buildCounterStructuredDataObject = 0;
api.StructuredDataObject buildStructuredDataObject() {
  var o = api.StructuredDataObject();
  buildCounterStructuredDataObject++;
  if (buildCounterStructuredDataObject < 3) {
    o.properties = buildUnnamed4206();
  }
  buildCounterStructuredDataObject--;
  return o;
}

void checkStructuredDataObject(api.StructuredDataObject o) {
  buildCounterStructuredDataObject++;
  if (buildCounterStructuredDataObject < 3) {
    checkUnnamed4206(o.properties!);
  }
  buildCounterStructuredDataObject--;
}

core.int buildCounterStructuredResult = 0;
api.StructuredResult buildStructuredResult() {
  var o = api.StructuredResult();
  buildCounterStructuredResult++;
  if (buildCounterStructuredResult < 3) {
    o.person = buildPerson();
  }
  buildCounterStructuredResult--;
  return o;
}

void checkStructuredResult(api.StructuredResult o) {
  buildCounterStructuredResult++;
  if (buildCounterStructuredResult < 3) {
    checkPerson(o.person! as api.Person);
  }
  buildCounterStructuredResult--;
}

core.List<api.DataSourceRestriction> buildUnnamed4207() {
  var o = <api.DataSourceRestriction>[];
  o.add(buildDataSourceRestriction());
  o.add(buildDataSourceRestriction());
  return o;
}

void checkUnnamed4207(core.List<api.DataSourceRestriction> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSourceRestriction(o[0] as api.DataSourceRestriction);
  checkDataSourceRestriction(o[1] as api.DataSourceRestriction);
}

core.int buildCounterSuggestRequest = 0;
api.SuggestRequest buildSuggestRequest() {
  var o = api.SuggestRequest();
  buildCounterSuggestRequest++;
  if (buildCounterSuggestRequest < 3) {
    o.dataSourceRestrictions = buildUnnamed4207();
    o.query = 'foo';
    o.requestOptions = buildRequestOptions();
  }
  buildCounterSuggestRequest--;
  return o;
}

void checkSuggestRequest(api.SuggestRequest o) {
  buildCounterSuggestRequest++;
  if (buildCounterSuggestRequest < 3) {
    checkUnnamed4207(o.dataSourceRestrictions!);
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    checkRequestOptions(o.requestOptions! as api.RequestOptions);
  }
  buildCounterSuggestRequest--;
}

core.List<api.SuggestResult> buildUnnamed4208() {
  var o = <api.SuggestResult>[];
  o.add(buildSuggestResult());
  o.add(buildSuggestResult());
  return o;
}

void checkUnnamed4208(core.List<api.SuggestResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSuggestResult(o[0] as api.SuggestResult);
  checkSuggestResult(o[1] as api.SuggestResult);
}

core.int buildCounterSuggestResponse = 0;
api.SuggestResponse buildSuggestResponse() {
  var o = api.SuggestResponse();
  buildCounterSuggestResponse++;
  if (buildCounterSuggestResponse < 3) {
    o.suggestResults = buildUnnamed4208();
  }
  buildCounterSuggestResponse--;
  return o;
}

void checkSuggestResponse(api.SuggestResponse o) {
  buildCounterSuggestResponse++;
  if (buildCounterSuggestResponse < 3) {
    checkUnnamed4208(o.suggestResults!);
  }
  buildCounterSuggestResponse--;
}

core.int buildCounterSuggestResult = 0;
api.SuggestResult buildSuggestResult() {
  var o = api.SuggestResult();
  buildCounterSuggestResult++;
  if (buildCounterSuggestResult < 3) {
    o.peopleSuggestion = buildPeopleSuggestion();
    o.querySuggestion = buildQuerySuggestion();
    o.source = buildSource();
    o.suggestedQuery = 'foo';
  }
  buildCounterSuggestResult--;
  return o;
}

void checkSuggestResult(api.SuggestResult o) {
  buildCounterSuggestResult++;
  if (buildCounterSuggestResult < 3) {
    checkPeopleSuggestion(o.peopleSuggestion! as api.PeopleSuggestion);
    checkQuerySuggestion(o.querySuggestion! as api.QuerySuggestion);
    checkSource(o.source! as api.Source);
    unittest.expect(
      o.suggestedQuery!,
      unittest.equals('foo'),
    );
  }
  buildCounterSuggestResult--;
}

core.int buildCounterTextOperatorOptions = 0;
api.TextOperatorOptions buildTextOperatorOptions() {
  var o = api.TextOperatorOptions();
  buildCounterTextOperatorOptions++;
  if (buildCounterTextOperatorOptions < 3) {
    o.exactMatchWithOperator = true;
    o.operatorName = 'foo';
  }
  buildCounterTextOperatorOptions--;
  return o;
}

void checkTextOperatorOptions(api.TextOperatorOptions o) {
  buildCounterTextOperatorOptions++;
  if (buildCounterTextOperatorOptions < 3) {
    unittest.expect(o.exactMatchWithOperator!, unittest.isTrue);
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterTextOperatorOptions--;
}

core.int buildCounterTextPropertyOptions = 0;
api.TextPropertyOptions buildTextPropertyOptions() {
  var o = api.TextPropertyOptions();
  buildCounterTextPropertyOptions++;
  if (buildCounterTextPropertyOptions < 3) {
    o.operatorOptions = buildTextOperatorOptions();
    o.retrievalImportance = buildRetrievalImportance();
  }
  buildCounterTextPropertyOptions--;
  return o;
}

void checkTextPropertyOptions(api.TextPropertyOptions o) {
  buildCounterTextPropertyOptions++;
  if (buildCounterTextPropertyOptions < 3) {
    checkTextOperatorOptions(o.operatorOptions! as api.TextOperatorOptions);
    checkRetrievalImportance(o.retrievalImportance! as api.RetrievalImportance);
  }
  buildCounterTextPropertyOptions--;
}

core.List<core.String> buildUnnamed4209() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4209(core.List<core.String> o) {
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

core.int buildCounterTextValues = 0;
api.TextValues buildTextValues() {
  var o = api.TextValues();
  buildCounterTextValues++;
  if (buildCounterTextValues < 3) {
    o.values = buildUnnamed4209();
  }
  buildCounterTextValues--;
  return o;
}

void checkTextValues(api.TextValues o) {
  buildCounterTextValues++;
  if (buildCounterTextValues < 3) {
    checkUnnamed4209(o.values!);
  }
  buildCounterTextValues--;
}

core.int buildCounterTimestampOperatorOptions = 0;
api.TimestampOperatorOptions buildTimestampOperatorOptions() {
  var o = api.TimestampOperatorOptions();
  buildCounterTimestampOperatorOptions++;
  if (buildCounterTimestampOperatorOptions < 3) {
    o.greaterThanOperatorName = 'foo';
    o.lessThanOperatorName = 'foo';
    o.operatorName = 'foo';
  }
  buildCounterTimestampOperatorOptions--;
  return o;
}

void checkTimestampOperatorOptions(api.TimestampOperatorOptions o) {
  buildCounterTimestampOperatorOptions++;
  if (buildCounterTimestampOperatorOptions < 3) {
    unittest.expect(
      o.greaterThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lessThanOperatorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimestampOperatorOptions--;
}

core.int buildCounterTimestampPropertyOptions = 0;
api.TimestampPropertyOptions buildTimestampPropertyOptions() {
  var o = api.TimestampPropertyOptions();
  buildCounterTimestampPropertyOptions++;
  if (buildCounterTimestampPropertyOptions < 3) {
    o.operatorOptions = buildTimestampOperatorOptions();
  }
  buildCounterTimestampPropertyOptions--;
  return o;
}

void checkTimestampPropertyOptions(api.TimestampPropertyOptions o) {
  buildCounterTimestampPropertyOptions++;
  if (buildCounterTimestampPropertyOptions < 3) {
    checkTimestampOperatorOptions(
        o.operatorOptions! as api.TimestampOperatorOptions);
  }
  buildCounterTimestampPropertyOptions--;
}

core.List<core.String> buildUnnamed4210() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4210(core.List<core.String> o) {
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

core.int buildCounterTimestampValues = 0;
api.TimestampValues buildTimestampValues() {
  var o = api.TimestampValues();
  buildCounterTimestampValues++;
  if (buildCounterTimestampValues < 3) {
    o.values = buildUnnamed4210();
  }
  buildCounterTimestampValues--;
  return o;
}

void checkTimestampValues(api.TimestampValues o) {
  buildCounterTimestampValues++;
  if (buildCounterTimestampValues < 3) {
    checkUnnamed4210(o.values!);
  }
  buildCounterTimestampValues--;
}

core.int buildCounterUnmappedIdentity = 0;
api.UnmappedIdentity buildUnmappedIdentity() {
  var o = api.UnmappedIdentity();
  buildCounterUnmappedIdentity++;
  if (buildCounterUnmappedIdentity < 3) {
    o.externalIdentity = buildPrincipal();
    o.resolutionStatusCode = 'foo';
  }
  buildCounterUnmappedIdentity--;
  return o;
}

void checkUnmappedIdentity(api.UnmappedIdentity o) {
  buildCounterUnmappedIdentity++;
  if (buildCounterUnmappedIdentity < 3) {
    checkPrincipal(o.externalIdentity! as api.Principal);
    unittest.expect(
      o.resolutionStatusCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnmappedIdentity--;
}

core.int buildCounterUnreserveItemsRequest = 0;
api.UnreserveItemsRequest buildUnreserveItemsRequest() {
  var o = api.UnreserveItemsRequest();
  buildCounterUnreserveItemsRequest++;
  if (buildCounterUnreserveItemsRequest < 3) {
    o.connectorName = 'foo';
    o.debugOptions = buildDebugOptions();
    o.queue = 'foo';
  }
  buildCounterUnreserveItemsRequest--;
  return o;
}

void checkUnreserveItemsRequest(api.UnreserveItemsRequest o) {
  buildCounterUnreserveItemsRequest++;
  if (buildCounterUnreserveItemsRequest < 3) {
    unittest.expect(
      o.connectorName!,
      unittest.equals('foo'),
    );
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    unittest.expect(
      o.queue!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnreserveItemsRequest--;
}

core.int buildCounterUpdateDataSourceRequest = 0;
api.UpdateDataSourceRequest buildUpdateDataSourceRequest() {
  var o = api.UpdateDataSourceRequest();
  buildCounterUpdateDataSourceRequest++;
  if (buildCounterUpdateDataSourceRequest < 3) {
    o.debugOptions = buildDebugOptions();
    o.source = buildDataSource();
  }
  buildCounterUpdateDataSourceRequest--;
  return o;
}

void checkUpdateDataSourceRequest(api.UpdateDataSourceRequest o) {
  buildCounterUpdateDataSourceRequest++;
  if (buildCounterUpdateDataSourceRequest < 3) {
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    checkDataSource(o.source! as api.DataSource);
  }
  buildCounterUpdateDataSourceRequest--;
}

core.int buildCounterUpdateSchemaRequest = 0;
api.UpdateSchemaRequest buildUpdateSchemaRequest() {
  var o = api.UpdateSchemaRequest();
  buildCounterUpdateSchemaRequest++;
  if (buildCounterUpdateSchemaRequest < 3) {
    o.debugOptions = buildDebugOptions();
    o.schema = buildSchema();
    o.validateOnly = true;
  }
  buildCounterUpdateSchemaRequest--;
  return o;
}

void checkUpdateSchemaRequest(api.UpdateSchemaRequest o) {
  buildCounterUpdateSchemaRequest++;
  if (buildCounterUpdateSchemaRequest < 3) {
    checkDebugOptions(o.debugOptions! as api.DebugOptions);
    checkSchema(o.schema! as api.Schema);
    unittest.expect(o.validateOnly!, unittest.isTrue);
  }
  buildCounterUpdateSchemaRequest--;
}

core.int buildCounterUploadItemRef = 0;
api.UploadItemRef buildUploadItemRef() {
  var o = api.UploadItemRef();
  buildCounterUploadItemRef++;
  if (buildCounterUploadItemRef < 3) {
    o.name = 'foo';
  }
  buildCounterUploadItemRef--;
  return o;
}

void checkUploadItemRef(api.UploadItemRef o) {
  buildCounterUploadItemRef++;
  if (buildCounterUploadItemRef < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterUploadItemRef--;
}

core.int buildCounterVPCSettings = 0;
api.VPCSettings buildVPCSettings() {
  var o = api.VPCSettings();
  buildCounterVPCSettings++;
  if (buildCounterVPCSettings < 3) {
    o.project = 'foo';
  }
  buildCounterVPCSettings--;
  return o;
}

void checkVPCSettings(api.VPCSettings o) {
  buildCounterVPCSettings++;
  if (buildCounterVPCSettings < 3) {
    unittest.expect(
      o.project!,
      unittest.equals('foo'),
    );
  }
  buildCounterVPCSettings--;
}

core.int buildCounterValue = 0;
api.Value buildValue() {
  var o = api.Value();
  buildCounterValue++;
  if (buildCounterValue < 3) {
    o.booleanValue = true;
    o.dateValue = buildDate();
    o.doubleValue = 42.0;
    o.integerValue = 'foo';
    o.stringValue = 'foo';
    o.timestampValue = 'foo';
  }
  buildCounterValue--;
  return o;
}

void checkValue(api.Value o) {
  buildCounterValue++;
  if (buildCounterValue < 3) {
    unittest.expect(o.booleanValue!, unittest.isTrue);
    checkDate(o.dateValue! as api.Date);
    unittest.expect(
      o.doubleValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.integerValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timestampValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterValue--;
}

core.int buildCounterValueFilter = 0;
api.ValueFilter buildValueFilter() {
  var o = api.ValueFilter();
  buildCounterValueFilter++;
  if (buildCounterValueFilter < 3) {
    o.operatorName = 'foo';
    o.value = buildValue();
  }
  buildCounterValueFilter--;
  return o;
}

void checkValueFilter(api.ValueFilter o) {
  buildCounterValueFilter++;
  if (buildCounterValueFilter < 3) {
    unittest.expect(
      o.operatorName!,
      unittest.equals('foo'),
    );
    checkValue(o.value! as api.Value);
  }
  buildCounterValueFilter--;
}

void main() {
  unittest.group('obj-schema-AuditLoggingSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditLoggingSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditLoggingSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditLoggingSettings(od as api.AuditLoggingSettings);
    });
  });

  unittest.group('obj-schema-BooleanOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBooleanOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BooleanOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBooleanOperatorOptions(od as api.BooleanOperatorOptions);
    });
  });

  unittest.group('obj-schema-BooleanPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBooleanPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BooleanPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBooleanPropertyOptions(od as api.BooleanPropertyOptions);
    });
  });

  unittest.group('obj-schema-CheckAccessResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCheckAccessResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CheckAccessResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCheckAccessResponse(od as api.CheckAccessResponse);
    });
  });

  unittest.group('obj-schema-CompositeFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompositeFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompositeFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompositeFilter(od as api.CompositeFilter);
    });
  });

  unittest.group('obj-schema-ContextAttribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContextAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContextAttribute.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContextAttribute(od as api.ContextAttribute);
    });
  });

  unittest.group('obj-schema-CustomerIndexStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerIndexStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerIndexStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerIndexStats(od as api.CustomerIndexStats);
    });
  });

  unittest.group('obj-schema-CustomerQueryStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerQueryStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerQueryStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerQueryStats(od as api.CustomerQueryStats);
    });
  });

  unittest.group('obj-schema-CustomerSessionStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerSessionStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerSessionStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerSessionStats(od as api.CustomerSessionStats);
    });
  });

  unittest.group('obj-schema-CustomerSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerSettings(od as api.CustomerSettings);
    });
  });

  unittest.group('obj-schema-CustomerUserStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerUserStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerUserStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerUserStats(od as api.CustomerUserStats);
    });
  });

  unittest.group('obj-schema-DataSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataSource(od as api.DataSource);
    });
  });

  unittest.group('obj-schema-DataSourceIndexStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceIndexStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceIndexStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceIndexStats(od as api.DataSourceIndexStats);
    });
  });

  unittest.group('obj-schema-DataSourceRestriction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSourceRestriction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSourceRestriction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSourceRestriction(od as api.DataSourceRestriction);
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

  unittest.group('obj-schema-DateOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DateOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDateOperatorOptions(od as api.DateOperatorOptions);
    });
  });

  unittest.group('obj-schema-DatePropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatePropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatePropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatePropertyOptions(od as api.DatePropertyOptions);
    });
  });

  unittest.group('obj-schema-DateValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DateValues.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDateValues(od as api.DateValues);
    });
  });

  unittest.group('obj-schema-DebugOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDebugOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DebugOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDebugOptions(od as api.DebugOptions);
    });
  });

  unittest.group('obj-schema-DeleteQueueItemsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteQueueItemsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteQueueItemsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteQueueItemsRequest(od as api.DeleteQueueItemsRequest);
    });
  });

  unittest.group('obj-schema-DisplayedProperty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDisplayedProperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DisplayedProperty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDisplayedProperty(od as api.DisplayedProperty);
    });
  });

  unittest.group('obj-schema-DoubleOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleOperatorOptions(od as api.DoubleOperatorOptions);
    });
  });

  unittest.group('obj-schema-DoublePropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoublePropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoublePropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoublePropertyOptions(od as api.DoublePropertyOptions);
    });
  });

  unittest.group('obj-schema-DoubleValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleValues.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleValues(od as api.DoubleValues);
    });
  });

  unittest.group('obj-schema-DriveFollowUpRestrict', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveFollowUpRestrict();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveFollowUpRestrict.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveFollowUpRestrict(od as api.DriveFollowUpRestrict);
    });
  });

  unittest.group('obj-schema-DriveLocationRestrict', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveLocationRestrict();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveLocationRestrict.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveLocationRestrict(od as api.DriveLocationRestrict);
    });
  });

  unittest.group('obj-schema-DriveMimeTypeRestrict', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveMimeTypeRestrict();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveMimeTypeRestrict.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveMimeTypeRestrict(od as api.DriveMimeTypeRestrict);
    });
  });

  unittest.group('obj-schema-DriveTimeSpanRestrict', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDriveTimeSpanRestrict();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DriveTimeSpanRestrict.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDriveTimeSpanRestrict(od as api.DriveTimeSpanRestrict);
    });
  });

  unittest.group('obj-schema-EmailAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmailAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EmailAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEmailAddress(od as api.EmailAddress);
    });
  });

  unittest.group('obj-schema-EnumOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnumOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnumOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnumOperatorOptions(od as api.EnumOperatorOptions);
    });
  });

  unittest.group('obj-schema-EnumPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnumPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnumPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnumPropertyOptions(od as api.EnumPropertyOptions);
    });
  });

  unittest.group('obj-schema-EnumValuePair', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnumValuePair();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnumValuePair.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnumValuePair(od as api.EnumValuePair);
    });
  });

  unittest.group('obj-schema-EnumValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnumValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.EnumValues.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEnumValues(od as api.EnumValues);
    });
  });

  unittest.group('obj-schema-ErrorInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildErrorInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ErrorInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkErrorInfo(od as api.ErrorInfo);
    });
  });

  unittest.group('obj-schema-ErrorMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildErrorMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ErrorMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkErrorMessage(od as api.ErrorMessage);
    });
  });

  unittest.group('obj-schema-FacetBucket', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFacetBucket();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FacetBucket.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFacetBucket(od as api.FacetBucket);
    });
  });

  unittest.group('obj-schema-FacetOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFacetOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FacetOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFacetOptions(od as api.FacetOptions);
    });
  });

  unittest.group('obj-schema-FacetResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFacetResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FacetResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFacetResult(od as api.FacetResult);
    });
  });

  unittest.group('obj-schema-FieldViolation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFieldViolation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FieldViolation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFieldViolation(od as api.FieldViolation);
    });
  });

  unittest.group('obj-schema-Filter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Filter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilter(od as api.Filter);
    });
  });

  unittest.group('obj-schema-FilterOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterOptions(od as api.FilterOptions);
    });
  });

  unittest.group('obj-schema-FreshnessOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFreshnessOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FreshnessOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFreshnessOptions(od as api.FreshnessOptions);
    });
  });

  unittest.group('obj-schema-GSuitePrincipal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGSuitePrincipal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GSuitePrincipal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGSuitePrincipal(od as api.GSuitePrincipal);
    });
  });

  unittest.group('obj-schema-GetCustomerIndexStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetCustomerIndexStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetCustomerIndexStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetCustomerIndexStatsResponse(
          od as api.GetCustomerIndexStatsResponse);
    });
  });

  unittest.group('obj-schema-GetCustomerQueryStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetCustomerQueryStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetCustomerQueryStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetCustomerQueryStatsResponse(
          od as api.GetCustomerQueryStatsResponse);
    });
  });

  unittest.group('obj-schema-GetCustomerSessionStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetCustomerSessionStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetCustomerSessionStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetCustomerSessionStatsResponse(
          od as api.GetCustomerSessionStatsResponse);
    });
  });

  unittest.group('obj-schema-GetCustomerUserStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetCustomerUserStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetCustomerUserStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetCustomerUserStatsResponse(od as api.GetCustomerUserStatsResponse);
    });
  });

  unittest.group('obj-schema-GetDataSourceIndexStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetDataSourceIndexStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetDataSourceIndexStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetDataSourceIndexStatsResponse(
          od as api.GetDataSourceIndexStatsResponse);
    });
  });

  unittest.group('obj-schema-GetSearchApplicationQueryStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetSearchApplicationQueryStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetSearchApplicationQueryStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetSearchApplicationQueryStatsResponse(
          od as api.GetSearchApplicationQueryStatsResponse);
    });
  });

  unittest.group('obj-schema-GetSearchApplicationSessionStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetSearchApplicationSessionStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetSearchApplicationSessionStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetSearchApplicationSessionStatsResponse(
          od as api.GetSearchApplicationSessionStatsResponse);
    });
  });

  unittest.group('obj-schema-GetSearchApplicationUserStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetSearchApplicationUserStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetSearchApplicationUserStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetSearchApplicationUserStatsResponse(
          od as api.GetSearchApplicationUserStatsResponse);
    });
  });

  unittest.group('obj-schema-HtmlOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHtmlOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HtmlOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHtmlOperatorOptions(od as api.HtmlOperatorOptions);
    });
  });

  unittest.group('obj-schema-HtmlPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHtmlPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HtmlPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHtmlPropertyOptions(od as api.HtmlPropertyOptions);
    });
  });

  unittest.group('obj-schema-HtmlValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHtmlValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.HtmlValues.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHtmlValues(od as api.HtmlValues);
    });
  });

  unittest.group('obj-schema-IndexItemOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIndexItemOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IndexItemOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIndexItemOptions(od as api.IndexItemOptions);
    });
  });

  unittest.group('obj-schema-IndexItemRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIndexItemRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IndexItemRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIndexItemRequest(od as api.IndexItemRequest);
    });
  });

  unittest.group('obj-schema-IntegerOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntegerOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntegerOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntegerOperatorOptions(od as api.IntegerOperatorOptions);
    });
  });

  unittest.group('obj-schema-IntegerPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntegerPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntegerPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntegerPropertyOptions(od as api.IntegerPropertyOptions);
    });
  });

  unittest.group('obj-schema-IntegerValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntegerValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntegerValues.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntegerValues(od as api.IntegerValues);
    });
  });

  unittest.group('obj-schema-Interaction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInteraction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Interaction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInteraction(od as api.Interaction);
    });
  });

  unittest.group('obj-schema-Item', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Item.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkItem(od as api.Item);
    });
  });

  unittest.group('obj-schema-ItemAcl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItemAcl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ItemAcl.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkItemAcl(od as api.ItemAcl);
    });
  });

  unittest.group('obj-schema-ItemContent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItemContent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ItemContent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkItemContent(od as api.ItemContent);
    });
  });

  unittest.group('obj-schema-ItemCountByStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItemCountByStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ItemCountByStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkItemCountByStatus(od as api.ItemCountByStatus);
    });
  });

  unittest.group('obj-schema-ItemMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItemMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ItemMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkItemMetadata(od as api.ItemMetadata);
    });
  });

  unittest.group('obj-schema-ItemStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItemStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ItemStatus.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkItemStatus(od as api.ItemStatus);
    });
  });

  unittest.group('obj-schema-ItemStructuredData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildItemStructuredData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ItemStructuredData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkItemStructuredData(od as api.ItemStructuredData);
    });
  });

  unittest.group('obj-schema-ListDataSourceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDataSourceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDataSourceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDataSourceResponse(od as api.ListDataSourceResponse);
    });
  });

  unittest.group('obj-schema-ListItemNamesForUnmappedIdentityResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListItemNamesForUnmappedIdentityResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListItemNamesForUnmappedIdentityResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListItemNamesForUnmappedIdentityResponse(
          od as api.ListItemNamesForUnmappedIdentityResponse);
    });
  });

  unittest.group('obj-schema-ListItemsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListItemsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListItemsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListItemsResponse(od as api.ListItemsResponse);
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

  unittest.group('obj-schema-ListQuerySourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListQuerySourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListQuerySourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListQuerySourcesResponse(od as api.ListQuerySourcesResponse);
    });
  });

  unittest.group('obj-schema-ListSearchApplicationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSearchApplicationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSearchApplicationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSearchApplicationsResponse(
          od as api.ListSearchApplicationsResponse);
    });
  });

  unittest.group('obj-schema-ListUnmappedIdentitiesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListUnmappedIdentitiesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListUnmappedIdentitiesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListUnmappedIdentitiesResponse(
          od as api.ListUnmappedIdentitiesResponse);
    });
  });

  unittest.group('obj-schema-MatchRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMatchRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.MatchRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMatchRange(od as api.MatchRange);
    });
  });

  unittest.group('obj-schema-Media', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMedia();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Media.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMedia(od as api.Media);
    });
  });

  unittest.group('obj-schema-Metadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Metadata.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMetadata(od as api.Metadata);
    });
  });

  unittest.group('obj-schema-Metaline', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetaline();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Metaline.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMetaline(od as api.Metaline);
    });
  });

  unittest.group('obj-schema-Name', () {
    unittest.test('to-json--from-json', () async {
      var o = buildName();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Name.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkName(od as api.Name);
    });
  });

  unittest.group('obj-schema-NamedProperty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNamedProperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NamedProperty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNamedProperty(od as api.NamedProperty);
    });
  });

  unittest.group('obj-schema-ObjectDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObjectDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ObjectDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkObjectDefinition(od as api.ObjectDefinition);
    });
  });

  unittest.group('obj-schema-ObjectDisplayOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObjectDisplayOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ObjectDisplayOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkObjectDisplayOptions(od as api.ObjectDisplayOptions);
    });
  });

  unittest.group('obj-schema-ObjectOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObjectOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ObjectOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkObjectOptions(od as api.ObjectOptions);
    });
  });

  unittest.group('obj-schema-ObjectPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObjectPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ObjectPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkObjectPropertyOptions(od as api.ObjectPropertyOptions);
    });
  });

  unittest.group('obj-schema-ObjectValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObjectValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ObjectValues.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkObjectValues(od as api.ObjectValues);
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

  unittest.group('obj-schema-PeopleSuggestion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPeopleSuggestion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PeopleSuggestion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPeopleSuggestion(od as api.PeopleSuggestion);
    });
  });

  unittest.group('obj-schema-Person', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerson();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Person.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPerson(od as api.Person);
    });
  });

  unittest.group('obj-schema-Photo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPhoto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Photo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPhoto(od as api.Photo);
    });
  });

  unittest.group('obj-schema-PollItemsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPollItemsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PollItemsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPollItemsRequest(od as api.PollItemsRequest);
    });
  });

  unittest.group('obj-schema-PollItemsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPollItemsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PollItemsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPollItemsResponse(od as api.PollItemsResponse);
    });
  });

  unittest.group('obj-schema-Principal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrincipal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Principal.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrincipal(od as api.Principal);
    });
  });

  unittest.group('obj-schema-ProcessingError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProcessingError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProcessingError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProcessingError(od as api.ProcessingError);
    });
  });

  unittest.group('obj-schema-PropertyDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPropertyDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PropertyDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPropertyDefinition(od as api.PropertyDefinition);
    });
  });

  unittest.group('obj-schema-PropertyDisplayOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPropertyDisplayOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PropertyDisplayOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPropertyDisplayOptions(od as api.PropertyDisplayOptions);
    });
  });

  unittest.group('obj-schema-PushItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPushItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PushItem.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPushItem(od as api.PushItem);
    });
  });

  unittest.group('obj-schema-PushItemRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPushItemRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PushItemRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPushItemRequest(od as api.PushItemRequest);
    });
  });

  unittest.group('obj-schema-QueryCountByStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryCountByStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryCountByStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryCountByStatus(od as api.QueryCountByStatus);
    });
  });

  unittest.group('obj-schema-QueryInterpretation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryInterpretation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryInterpretation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryInterpretation(od as api.QueryInterpretation);
    });
  });

  unittest.group('obj-schema-QueryInterpretationOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryInterpretationOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryInterpretationOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryInterpretationOptions(od as api.QueryInterpretationOptions);
    });
  });

  unittest.group('obj-schema-QueryItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.QueryItem.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkQueryItem(od as api.QueryItem);
    });
  });

  unittest.group('obj-schema-QueryOperator', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryOperator();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryOperator.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryOperator(od as api.QueryOperator);
    });
  });

  unittest.group('obj-schema-QuerySource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuerySource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QuerySource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQuerySource(od as api.QuerySource);
    });
  });

  unittest.group('obj-schema-QuerySuggestion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQuerySuggestion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QuerySuggestion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQuerySuggestion(od as api.QuerySuggestion);
    });
  });

  unittest.group('obj-schema-RepositoryError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepositoryError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RepositoryError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRepositoryError(od as api.RepositoryError);
    });
  });

  unittest.group('obj-schema-RequestOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequestOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RequestOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRequestOptions(od as api.RequestOptions);
    });
  });

  unittest.group('obj-schema-ResetSearchApplicationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResetSearchApplicationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResetSearchApplicationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResetSearchApplicationRequest(
          od as api.ResetSearchApplicationRequest);
    });
  });

  unittest.group('obj-schema-ResponseDebugInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResponseDebugInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResponseDebugInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResponseDebugInfo(od as api.ResponseDebugInfo);
    });
  });

  unittest.group('obj-schema-RestrictItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRestrictItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RestrictItem.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRestrictItem(od as api.RestrictItem);
    });
  });

  unittest.group('obj-schema-ResultCounts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultCounts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultCounts.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultCounts(od as api.ResultCounts);
    });
  });

  unittest.group('obj-schema-ResultDebugInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultDebugInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultDebugInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultDebugInfo(od as api.ResultDebugInfo);
    });
  });

  unittest.group('obj-schema-ResultDisplayField', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultDisplayField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultDisplayField.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultDisplayField(od as api.ResultDisplayField);
    });
  });

  unittest.group('obj-schema-ResultDisplayLine', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultDisplayLine();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultDisplayLine.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultDisplayLine(od as api.ResultDisplayLine);
    });
  });

  unittest.group('obj-schema-ResultDisplayMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResultDisplayMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResultDisplayMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResultDisplayMetadata(od as api.ResultDisplayMetadata);
    });
  });

  unittest.group('obj-schema-RetrievalImportance', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRetrievalImportance();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RetrievalImportance.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRetrievalImportance(od as api.RetrievalImportance);
    });
  });

  unittest.group('obj-schema-Schema', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchema();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Schema.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSchema(od as api.Schema);
    });
  });

  unittest.group('obj-schema-ScoringConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScoringConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScoringConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScoringConfig(od as api.ScoringConfig);
    });
  });

  unittest.group('obj-schema-SearchApplication', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchApplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchApplication.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchApplication(od as api.SearchApplication);
    });
  });

  unittest.group('obj-schema-SearchApplicationQueryStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchApplicationQueryStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchApplicationQueryStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchApplicationQueryStats(od as api.SearchApplicationQueryStats);
    });
  });

  unittest.group('obj-schema-SearchApplicationSessionStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchApplicationSessionStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchApplicationSessionStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchApplicationSessionStats(
          od as api.SearchApplicationSessionStats);
    });
  });

  unittest.group('obj-schema-SearchApplicationUserStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchApplicationUserStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchApplicationUserStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchApplicationUserStats(od as api.SearchApplicationUserStats);
    });
  });

  unittest.group('obj-schema-SearchItemsByViewUrlRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchItemsByViewUrlRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchItemsByViewUrlRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchItemsByViewUrlRequest(od as api.SearchItemsByViewUrlRequest);
    });
  });

  unittest.group('obj-schema-SearchItemsByViewUrlResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchItemsByViewUrlResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchItemsByViewUrlResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchItemsByViewUrlResponse(od as api.SearchItemsByViewUrlResponse);
    });
  });

  unittest.group('obj-schema-SearchQualityMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchQualityMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchQualityMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchQualityMetadata(od as api.SearchQualityMetadata);
    });
  });

  unittest.group('obj-schema-SearchRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchRequest(od as api.SearchRequest);
    });
  });

  unittest.group('obj-schema-SearchResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchResponse(od as api.SearchResponse);
    });
  });

  unittest.group('obj-schema-SearchResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchResult(od as api.SearchResult);
    });
  });

  unittest.group('obj-schema-Snippet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSnippet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Snippet.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSnippet(od as api.Snippet);
    });
  });

  unittest.group('obj-schema-SortOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSortOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SortOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSortOptions(od as api.SortOptions);
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

  unittest.group('obj-schema-SourceConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceConfig(od as api.SourceConfig);
    });
  });

  unittest.group('obj-schema-SourceCrowdingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceCrowdingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceCrowdingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceCrowdingConfig(od as api.SourceCrowdingConfig);
    });
  });

  unittest.group('obj-schema-SourceResultCount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceResultCount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceResultCount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceResultCount(od as api.SourceResultCount);
    });
  });

  unittest.group('obj-schema-SourceScoringConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSourceScoringConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SourceScoringConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSourceScoringConfig(od as api.SourceScoringConfig);
    });
  });

  unittest.group('obj-schema-SpellResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpellResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpellResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpellResult(od as api.SpellResult);
    });
  });

  unittest.group('obj-schema-StartUploadItemRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStartUploadItemRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StartUploadItemRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStartUploadItemRequest(od as api.StartUploadItemRequest);
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

  unittest.group('obj-schema-StructuredDataObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStructuredDataObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StructuredDataObject.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStructuredDataObject(od as api.StructuredDataObject);
    });
  });

  unittest.group('obj-schema-StructuredResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStructuredResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StructuredResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStructuredResult(od as api.StructuredResult);
    });
  });

  unittest.group('obj-schema-SuggestRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuggestRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuggestRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuggestRequest(od as api.SuggestRequest);
    });
  });

  unittest.group('obj-schema-SuggestResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuggestResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuggestResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuggestResponse(od as api.SuggestResponse);
    });
  });

  unittest.group('obj-schema-SuggestResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSuggestResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SuggestResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSuggestResult(od as api.SuggestResult);
    });
  });

  unittest.group('obj-schema-TextOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextOperatorOptions(od as api.TextOperatorOptions);
    });
  });

  unittest.group('obj-schema-TextPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TextPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTextPropertyOptions(od as api.TextPropertyOptions);
    });
  });

  unittest.group('obj-schema-TextValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTextValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TextValues.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTextValues(od as api.TextValues);
    });
  });

  unittest.group('obj-schema-TimestampOperatorOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimestampOperatorOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TimestampOperatorOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTimestampOperatorOptions(od as api.TimestampOperatorOptions);
    });
  });

  unittest.group('obj-schema-TimestampPropertyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimestampPropertyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TimestampPropertyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTimestampPropertyOptions(od as api.TimestampPropertyOptions);
    });
  });

  unittest.group('obj-schema-TimestampValues', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimestampValues();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TimestampValues.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTimestampValues(od as api.TimestampValues);
    });
  });

  unittest.group('obj-schema-UnmappedIdentity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnmappedIdentity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnmappedIdentity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnmappedIdentity(od as api.UnmappedIdentity);
    });
  });

  unittest.group('obj-schema-UnreserveItemsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnreserveItemsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnreserveItemsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnreserveItemsRequest(od as api.UnreserveItemsRequest);
    });
  });

  unittest.group('obj-schema-UpdateDataSourceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDataSourceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDataSourceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDataSourceRequest(od as api.UpdateDataSourceRequest);
    });
  });

  unittest.group('obj-schema-UpdateSchemaRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSchemaRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSchemaRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSchemaRequest(od as api.UpdateSchemaRequest);
    });
  });

  unittest.group('obj-schema-UploadItemRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUploadItemRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UploadItemRef.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUploadItemRef(od as api.UploadItemRef);
    });
  });

  unittest.group('obj-schema-VPCSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVPCSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VPCSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVPCSettings(od as api.VPCSettings);
    });
  });

  unittest.group('obj-schema-Value', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Value.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkValue(od as api.Value);
    });
  });

  unittest.group('obj-schema-ValueFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValueFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValueFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValueFilter(od as api.ValueFilter);
    });
  });

  unittest.group('resource-DebugDatasourcesItemsResource', () {
    unittest.test('method--checkAccess', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).debug.datasources.items;
      var arg_request = buildPrincipal();
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Principal.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPrincipal(obj as api.Principal);

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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/debug/"),
        );
        pathOffset += 9;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCheckAccessResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.checkAccess(arg_request, arg_name,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkCheckAccessResponse(response as api.CheckAccessResponse);
    });

    unittest.test('method--searchByViewUrl', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).debug.datasources.items;
      var arg_request = buildSearchItemsByViewUrlRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchItemsByViewUrlRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchItemsByViewUrlRequest(
            obj as api.SearchItemsByViewUrlRequest);

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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/debug/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildSearchItemsByViewUrlResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchByViewUrl(arg_request, arg_name,
          $fields: arg_$fields);
      checkSearchItemsByViewUrlResponse(
          response as api.SearchItemsByViewUrlResponse);
    });
  });

  unittest.group('resource-DebugDatasourcesItemsUnmappedidsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).debug.datasources.items.unmappedids;
      var arg_parent = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/debug/"),
        );
        pathOffset += 9;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
        var resp = convert.json.encode(buildListUnmappedIdentitiesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListUnmappedIdentitiesResponse(
          response as api.ListUnmappedIdentitiesResponse);
    });
  });

  unittest.group('resource-DebugIdentitysourcesItemsResource', () {
    unittest.test('method--listForunmappedidentity', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).debug.identitysources.items;
      var arg_parent = 'foo';
      var arg_debugOptions_enableDebugging = true;
      var arg_groupResourceName = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_userResourceName = 'foo';
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/debug/"),
        );
        pathOffset += 9;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["groupResourceName"]!.first,
          unittest.equals(arg_groupResourceName),
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
          queryMap["userResourceName"]!.first,
          unittest.equals(arg_userResourceName),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildListItemNamesForUnmappedIdentityResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listForunmappedidentity(arg_parent,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          groupResourceName: arg_groupResourceName,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          userResourceName: arg_userResourceName,
          $fields: arg_$fields);
      checkListItemNamesForUnmappedIdentityResponse(
          response as api.ListItemNamesForUnmappedIdentityResponse);
    });
  });

  unittest.group('resource-DebugIdentitysourcesUnmappedidsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).debug.identitysources.unmappedids;
      var arg_parent = 'foo';
      var arg_debugOptions_enableDebugging = true;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_resolutionStatusCode = 'foo';
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/debug/"),
        );
        pathOffset += 9;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
          queryMap["resolutionStatusCode"]!.first,
          unittest.equals(arg_resolutionStatusCode),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListUnmappedIdentitiesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          resolutionStatusCode: arg_resolutionStatusCode,
          $fields: arg_$fields);
      checkListUnmappedIdentitiesResponse(
          response as api.ListUnmappedIdentitiesResponse);
    });
  });

  unittest.group('resource-IndexingDatasourcesResource', () {
    unittest.test('method--deleteSchema', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources;
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
      final response = await res.deleteSchema(arg_name,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--getSchema', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources;
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSchema());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getSchema(arg_name,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });

    unittest.test('method--updateSchema', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources;
      var arg_request = buildUpdateSchemaRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateSchemaRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateSchemaRequest(obj as api.UpdateSchemaRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          await res.updateSchema(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-IndexingDatasourcesItemsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_name = 'foo';
      var arg_connectorName = 'foo';
      var arg_debugOptions_enableDebugging = true;
      var arg_mode = 'foo';
      var arg_version = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          queryMap["connectorName"]!.first,
          unittest.equals(arg_connectorName),
        );
        unittest.expect(
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["mode"]!.first,
          unittest.equals(arg_mode),
        );
        unittest.expect(
          queryMap["version"]!.first,
          unittest.equals(arg_version),
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
          connectorName: arg_connectorName,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          mode: arg_mode,
          version: arg_version,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--deleteQueueItems', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_request = buildDeleteQueueItemsRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeleteQueueItemsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeleteQueueItemsRequest(obj as api.DeleteQueueItemsRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
      final response = await res.deleteQueueItems(arg_request, arg_name,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_name = 'foo';
      var arg_connectorName = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          queryMap["connectorName"]!.first,
          unittest.equals(arg_connectorName),
        );
        unittest.expect(
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          connectorName: arg_connectorName,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkItem(response as api.Item);
    });

    unittest.test('method--index', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_request = buildIndexItemRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.IndexItemRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkIndexItemRequest(obj as api.IndexItemRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          await res.index(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_name = 'foo';
      var arg_brief = true;
      var arg_connectorName = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          queryMap["brief"]!.first,
          unittest.equals("$arg_brief"),
        );
        unittest.expect(
          queryMap["connectorName"]!.first,
          unittest.equals(arg_connectorName),
        );
        unittest.expect(
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
        var resp = convert.json.encode(buildListItemsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          brief: arg_brief,
          connectorName: arg_connectorName,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListItemsResponse(response as api.ListItemsResponse);
    });

    unittest.test('method--poll', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_request = buildPollItemsRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PollItemsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPollItemsRequest(obj as api.PollItemsRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
        var resp = convert.json.encode(buildPollItemsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.poll(arg_request, arg_name, $fields: arg_$fields);
      checkPollItemsResponse(response as api.PollItemsResponse);
    });

    unittest.test('method--push', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_request = buildPushItemRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PushItemRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPushItemRequest(obj as api.PushItemRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
        var resp = convert.json.encode(buildItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.push(arg_request, arg_name, $fields: arg_$fields);
      checkItem(response as api.Item);
    });

    unittest.test('method--unreserve', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_request = buildUnreserveItemsRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UnreserveItemsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUnreserveItemsRequest(obj as api.UnreserveItemsRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
          await res.unreserve(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--upload', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).indexing.datasources.items;
      var arg_request = buildStartUploadItemRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.StartUploadItemRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkStartUploadItemRequest(obj as api.StartUploadItemRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/indexing/"),
        );
        pathOffset += 12;
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
        var resp = convert.json.encode(buildUploadItemRef());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upload(arg_request, arg_name, $fields: arg_$fields);
      checkUploadItemRef(response as api.UploadItemRef);
    });
  });

  unittest.group('resource-MediaResource', () {
    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).media;
      var arg_request = buildMedia();
      var arg_resourceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Media.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMedia(obj as api.Media);

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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/media/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildMedia());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upload(arg_request, arg_resourceName, $fields: arg_$fields);
      checkMedia(response as api.Media);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).operations;
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
  });

  unittest.group('resource-OperationsLroResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).operations.lro;
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

  unittest.group('resource-QueryResource', () {
    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).query;
      var arg_request = buildSearchRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchRequest(obj as api.SearchRequest);

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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/query/search"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(arg_request, $fields: arg_$fields);
      checkSearchResponse(response as api.SearchResponse);
    });

    unittest.test('method--suggest', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).query;
      var arg_request = buildSuggestRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SuggestRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSuggestRequest(obj as api.SuggestRequest);

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
          unittest.equals("v1/query/suggest"),
        );
        pathOffset += 16;

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
        var resp = convert.json.encode(buildSuggestResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.suggest(arg_request, $fields: arg_$fields);
      checkSuggestResponse(response as api.SuggestResponse);
    });
  });

  unittest.group('resource-QuerySourcesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).query.sources;
      var arg_pageToken = 'foo';
      var arg_requestOptions_debugOptions_enableDebugging = true;
      var arg_requestOptions_languageCode = 'foo';
      var arg_requestOptions_searchApplicationId = 'foo';
      var arg_requestOptions_timeZone = 'foo';
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
          unittest.equals("v1/query/sources"),
        );
        pathOffset += 16;

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
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["requestOptions.debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_requestOptions_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["requestOptions.languageCode"]!.first,
          unittest.equals(arg_requestOptions_languageCode),
        );
        unittest.expect(
          queryMap["requestOptions.searchApplicationId"]!.first,
          unittest.equals(arg_requestOptions_searchApplicationId),
        );
        unittest.expect(
          queryMap["requestOptions.timeZone"]!.first,
          unittest.equals(arg_requestOptions_timeZone),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListQuerySourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageToken: arg_pageToken,
          requestOptions_debugOptions_enableDebugging:
              arg_requestOptions_debugOptions_enableDebugging,
          requestOptions_languageCode: arg_requestOptions_languageCode,
          requestOptions_searchApplicationId:
              arg_requestOptions_searchApplicationId,
          requestOptions_timeZone: arg_requestOptions_timeZone,
          $fields: arg_$fields);
      checkListQuerySourcesResponse(response as api.ListQuerySourcesResponse);
    });
  });

  unittest.group('resource-SettingsResource', () {
    unittest.test('method--getCustomer', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings;
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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("v1/settings/customer"),
        );
        pathOffset += 20;

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
        var resp = convert.json.encode(buildCustomerSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getCustomer($fields: arg_$fields);
      checkCustomerSettings(response as api.CustomerSettings);
    });

    unittest.test('method--updateCustomer', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings;
      var arg_request = buildCustomerSettings();
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomerSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomerSettings(obj as api.CustomerSettings);

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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("v1/settings/customer"),
        );
        pathOffset += 20;

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
      final response = await res.updateCustomer(arg_request,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-SettingsDatasourcesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.datasources;
      var arg_request = buildDataSource();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DataSource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDataSource(obj as api.DataSource);

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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("v1/settings/datasources"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.datasources;
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.datasources;
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDataSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkDataSource(response as api.DataSource);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.datasources;
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("v1/settings/datasources"),
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
        var resp = convert.json.encode(buildListDataSourceResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDataSourceResponse(response as api.ListDataSourceResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.datasources;
      var arg_request = buildUpdateDataSourceRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateDataSourceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateDataSourceRequest(obj as api.UpdateDataSourceRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          await res.update(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-SettingsSearchapplicationsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.searchapplications;
      var arg_request = buildSearchApplication();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchApplication.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchApplication(obj as api.SearchApplication);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("v1/settings/searchapplications"),
        );
        pathOffset += 30;

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

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.searchapplications;
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.searchapplications;
      var arg_name = 'foo';
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchApplication());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          $fields: arg_$fields);
      checkSearchApplication(response as api.SearchApplication);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.searchapplications;
      var arg_debugOptions_enableDebugging = true;
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("v1/settings/searchapplications"),
        );
        pathOffset += 30;

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
          queryMap["debugOptions.enableDebugging"]!.first,
          unittest.equals("$arg_debugOptions_enableDebugging"),
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
        var resp = convert.json.encode(buildListSearchApplicationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          debugOptions_enableDebugging: arg_debugOptions_enableDebugging,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSearchApplicationsResponse(
          response as api.ListSearchApplicationsResponse);
    });

    unittest.test('method--reset', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.searchapplications;
      var arg_request = buildResetSearchApplicationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ResetSearchApplicationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkResetSearchApplicationRequest(
            obj as api.ResetSearchApplicationRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          await res.reset(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).settings.searchapplications;
      var arg_request = buildSearchApplication();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchApplication.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchApplication(obj as api.SearchApplication);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("v1/settings/"),
        );
        pathOffset += 12;
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
          await res.update(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-StatsResource', () {
    unittest.test('method--getIndex', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats;
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/stats/index"),
        );
        pathOffset += 14;

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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetCustomerIndexStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIndex(
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetCustomerIndexStatsResponse(
          response as api.GetCustomerIndexStatsResponse);
    });

    unittest.test('method--getQuery', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats;
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/stats/query"),
        );
        pathOffset += 14;

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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetCustomerQueryStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getQuery(
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetCustomerQueryStatsResponse(
          response as api.GetCustomerQueryStatsResponse);
    });

    unittest.test('method--getSession', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats;
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          unittest.equals("v1/stats/session"),
        );
        pathOffset += 16;

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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetCustomerSessionStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getSession(
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetCustomerSessionStatsResponse(
          response as api.GetCustomerSessionStatsResponse);
    });

    unittest.test('method--getUser', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats;
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("v1/stats/user"),
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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetCustomerUserStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getUser(
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetCustomerUserStatsResponse(
          response as api.GetCustomerUserStatsResponse);
    });
  });

  unittest.group('resource-StatsIndexDatasourcesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats.index.datasources;
      var arg_name = 'foo';
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/stats/index/"),
        );
        pathOffset += 15;
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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetDataSourceIndexStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetDataSourceIndexStatsResponse(
          response as api.GetDataSourceIndexStatsResponse);
    });
  });

  unittest.group('resource-StatsQuerySearchapplicationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats.query.searchapplications;
      var arg_name = 'foo';
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/stats/query/"),
        );
        pathOffset += 15;
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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildGetSearchApplicationQueryStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetSearchApplicationQueryStatsResponse(
          response as api.GetSearchApplicationQueryStatsResponse);
    });
  });

  unittest.group('resource-StatsSessionSearchapplicationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats.session.searchapplications;
      var arg_name = 'foo';
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v1/stats/session/"),
        );
        pathOffset += 17;
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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildGetSearchApplicationSessionStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetSearchApplicationSessionStatsResponse(
          response as api.GetSearchApplicationSessionStatsResponse);
    });
  });

  unittest.group('resource-StatsUserSearchapplicationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudSearchApi(mock).stats.user.searchapplications;
      var arg_name = 'foo';
      var arg_fromDate_day = 42;
      var arg_fromDate_month = 42;
      var arg_fromDate_year = 42;
      var arg_toDate_day = 42;
      var arg_toDate_month = 42;
      var arg_toDate_year = 42;
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/stats/user/"),
        );
        pathOffset += 14;
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
          core.int.parse(queryMap["fromDate.day"]!.first),
          unittest.equals(arg_fromDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.month"]!.first),
          unittest.equals(arg_fromDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["fromDate.year"]!.first),
          unittest.equals(arg_fromDate_year),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.day"]!.first),
          unittest.equals(arg_toDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.month"]!.first),
          unittest.equals(arg_toDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["toDate.year"]!.first),
          unittest.equals(arg_toDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildGetSearchApplicationUserStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name,
          fromDate_day: arg_fromDate_day,
          fromDate_month: arg_fromDate_month,
          fromDate_year: arg_fromDate_year,
          toDate_day: arg_toDate_day,
          toDate_month: arg_toDate_month,
          toDate_year: arg_toDate_year,
          $fields: arg_$fields);
      checkGetSearchApplicationUserStatsResponse(
          response as api.GetSearchApplicationUserStatsResponse);
    });
  });
}
