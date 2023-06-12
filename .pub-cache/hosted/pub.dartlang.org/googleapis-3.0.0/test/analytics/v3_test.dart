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

import 'package:googleapis/analytics/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccountChildLink = 0;
api.AccountChildLink buildAccountChildLink() {
  var o = api.AccountChildLink();
  buildCounterAccountChildLink++;
  if (buildCounterAccountChildLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterAccountChildLink--;
  return o;
}

void checkAccountChildLink(api.AccountChildLink o) {
  buildCounterAccountChildLink++;
  if (buildCounterAccountChildLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccountChildLink--;
}

core.List<core.String> buildUnnamed5309() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5309(core.List<core.String> o) {
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

core.int buildCounterAccountPermissions = 0;
api.AccountPermissions buildAccountPermissions() {
  var o = api.AccountPermissions();
  buildCounterAccountPermissions++;
  if (buildCounterAccountPermissions < 3) {
    o.effective = buildUnnamed5309();
  }
  buildCounterAccountPermissions--;
  return o;
}

void checkAccountPermissions(api.AccountPermissions o) {
  buildCounterAccountPermissions++;
  if (buildCounterAccountPermissions < 3) {
    checkUnnamed5309(o.effective!);
  }
  buildCounterAccountPermissions--;
}

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.childLink = buildAccountChildLink();
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.permissions = buildAccountPermissions();
    o.selfLink = 'foo';
    o.starred = true;
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    checkAccountChildLink(o.childLink! as api.AccountChildLink);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
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
    checkAccountPermissions(o.permissions! as api.AccountPermissions);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(o.starred!, unittest.isTrue);
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterAccount--;
}

core.int buildCounterAccountRef = 0;
api.AccountRef buildAccountRef() {
  var o = api.AccountRef();
  buildCounterAccountRef++;
  if (buildCounterAccountRef < 3) {
    o.href = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterAccountRef--;
  return o;
}

void checkAccountRef(api.AccountRef o) {
  buildCounterAccountRef++;
  if (buildCounterAccountRef < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
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
  }
  buildCounterAccountRef--;
}

core.List<api.AccountSummary> buildUnnamed5310() {
  var o = <api.AccountSummary>[];
  o.add(buildAccountSummary());
  o.add(buildAccountSummary());
  return o;
}

void checkUnnamed5310(core.List<api.AccountSummary> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccountSummary(o[0] as api.AccountSummary);
  checkAccountSummary(o[1] as api.AccountSummary);
}

core.int buildCounterAccountSummaries = 0;
api.AccountSummaries buildAccountSummaries() {
  var o = api.AccountSummaries();
  buildCounterAccountSummaries++;
  if (buildCounterAccountSummaries < 3) {
    o.items = buildUnnamed5310();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterAccountSummaries--;
  return o;
}

void checkAccountSummaries(api.AccountSummaries o) {
  buildCounterAccountSummaries++;
  if (buildCounterAccountSummaries < 3) {
    checkUnnamed5310(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccountSummaries--;
}

core.List<api.WebPropertySummary> buildUnnamed5311() {
  var o = <api.WebPropertySummary>[];
  o.add(buildWebPropertySummary());
  o.add(buildWebPropertySummary());
  return o;
}

void checkUnnamed5311(core.List<api.WebPropertySummary> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWebPropertySummary(o[0] as api.WebPropertySummary);
  checkWebPropertySummary(o[1] as api.WebPropertySummary);
}

core.int buildCounterAccountSummary = 0;
api.AccountSummary buildAccountSummary() {
  var o = api.AccountSummary();
  buildCounterAccountSummary++;
  if (buildCounterAccountSummary < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.starred = true;
    o.webProperties = buildUnnamed5311();
  }
  buildCounterAccountSummary--;
  return o;
}

void checkAccountSummary(api.AccountSummary o) {
  buildCounterAccountSummary++;
  if (buildCounterAccountSummary < 3) {
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
    unittest.expect(o.starred!, unittest.isTrue);
    checkUnnamed5311(o.webProperties!);
  }
  buildCounterAccountSummary--;
}

core.int buildCounterAccountTicket = 0;
api.AccountTicket buildAccountTicket() {
  var o = api.AccountTicket();
  buildCounterAccountTicket++;
  if (buildCounterAccountTicket < 3) {
    o.account = buildAccount();
    o.id = 'foo';
    o.kind = 'foo';
    o.profile = buildProfile();
    o.redirectUri = 'foo';
    o.webproperty = buildWebproperty();
  }
  buildCounterAccountTicket--;
  return o;
}

void checkAccountTicket(api.AccountTicket o) {
  buildCounterAccountTicket++;
  if (buildCounterAccountTicket < 3) {
    checkAccount(o.account! as api.Account);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkProfile(o.profile! as api.Profile);
    unittest.expect(
      o.redirectUri!,
      unittest.equals('foo'),
    );
    checkWebproperty(o.webproperty! as api.Webproperty);
  }
  buildCounterAccountTicket--;
}

core.int buildCounterAccountTreeRequest = 0;
api.AccountTreeRequest buildAccountTreeRequest() {
  var o = api.AccountTreeRequest();
  buildCounterAccountTreeRequest++;
  if (buildCounterAccountTreeRequest < 3) {
    o.accountName = 'foo';
    o.kind = 'foo';
    o.profileName = 'foo';
    o.timezone = 'foo';
    o.webpropertyName = 'foo';
    o.websiteUrl = 'foo';
  }
  buildCounterAccountTreeRequest--;
  return o;
}

void checkAccountTreeRequest(api.AccountTreeRequest o) {
  buildCounterAccountTreeRequest++;
  if (buildCounterAccountTreeRequest < 3) {
    unittest.expect(
      o.accountName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timezone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webpropertyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.websiteUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccountTreeRequest--;
}

core.int buildCounterAccountTreeResponse = 0;
api.AccountTreeResponse buildAccountTreeResponse() {
  var o = api.AccountTreeResponse();
  buildCounterAccountTreeResponse++;
  if (buildCounterAccountTreeResponse < 3) {
    o.account = buildAccount();
    o.kind = 'foo';
    o.profile = buildProfile();
    o.webproperty = buildWebproperty();
  }
  buildCounterAccountTreeResponse--;
  return o;
}

void checkAccountTreeResponse(api.AccountTreeResponse o) {
  buildCounterAccountTreeResponse++;
  if (buildCounterAccountTreeResponse < 3) {
    checkAccount(o.account! as api.Account);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkProfile(o.profile! as api.Profile);
    checkWebproperty(o.webproperty! as api.Webproperty);
  }
  buildCounterAccountTreeResponse--;
}

core.List<api.Account> buildUnnamed5312() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed5312(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterAccounts = 0;
api.Accounts buildAccounts() {
  var o = api.Accounts();
  buildCounterAccounts++;
  if (buildCounterAccounts < 3) {
    o.items = buildUnnamed5312();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterAccounts--;
  return o;
}

void checkAccounts(api.Accounts o) {
  buildCounterAccounts++;
  if (buildCounterAccounts < 3) {
    checkUnnamed5312(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccounts--;
}

core.int buildCounterAdWordsAccount = 0;
api.AdWordsAccount buildAdWordsAccount() {
  var o = api.AdWordsAccount();
  buildCounterAdWordsAccount++;
  if (buildCounterAdWordsAccount < 3) {
    o.autoTaggingEnabled = true;
    o.customerId = 'foo';
    o.kind = 'foo';
  }
  buildCounterAdWordsAccount--;
  return o;
}

void checkAdWordsAccount(api.AdWordsAccount o) {
  buildCounterAdWordsAccount++;
  if (buildCounterAdWordsAccount < 3) {
    unittest.expect(o.autoTaggingEnabled!, unittest.isTrue);
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdWordsAccount--;
}

core.List<core.String> buildUnnamed5313() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5313(core.List<core.String> o) {
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

core.int buildCounterAnalyticsDataimportDeleteUploadDataRequest = 0;
api.AnalyticsDataimportDeleteUploadDataRequest
    buildAnalyticsDataimportDeleteUploadDataRequest() {
  var o = api.AnalyticsDataimportDeleteUploadDataRequest();
  buildCounterAnalyticsDataimportDeleteUploadDataRequest++;
  if (buildCounterAnalyticsDataimportDeleteUploadDataRequest < 3) {
    o.customDataImportUids = buildUnnamed5313();
  }
  buildCounterAnalyticsDataimportDeleteUploadDataRequest--;
  return o;
}

void checkAnalyticsDataimportDeleteUploadDataRequest(
    api.AnalyticsDataimportDeleteUploadDataRequest o) {
  buildCounterAnalyticsDataimportDeleteUploadDataRequest++;
  if (buildCounterAnalyticsDataimportDeleteUploadDataRequest < 3) {
    checkUnnamed5313(o.customDataImportUids!);
  }
  buildCounterAnalyticsDataimportDeleteUploadDataRequest--;
}

core.Map<core.String, core.String> buildUnnamed5314() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5314(core.Map<core.String, core.String> o) {
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

core.int buildCounterColumn = 0;
api.Column buildColumn() {
  var o = api.Column();
  buildCounterColumn++;
  if (buildCounterColumn < 3) {
    o.attributes = buildUnnamed5314();
    o.id = 'foo';
    o.kind = 'foo';
  }
  buildCounterColumn--;
  return o;
}

void checkColumn(api.Column o) {
  buildCounterColumn++;
  if (buildCounterColumn < 3) {
    checkUnnamed5314(o.attributes!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterColumn--;
}

core.List<core.String> buildUnnamed5315() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5315(core.List<core.String> o) {
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

core.List<api.Column> buildUnnamed5316() {
  var o = <api.Column>[];
  o.add(buildColumn());
  o.add(buildColumn());
  return o;
}

void checkUnnamed5316(core.List<api.Column> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkColumn(o[0] as api.Column);
  checkColumn(o[1] as api.Column);
}

core.int buildCounterColumns = 0;
api.Columns buildColumns() {
  var o = api.Columns();
  buildCounterColumns++;
  if (buildCounterColumns < 3) {
    o.attributeNames = buildUnnamed5315();
    o.etag = 'foo';
    o.items = buildUnnamed5316();
    o.kind = 'foo';
    o.totalResults = 42;
  }
  buildCounterColumns--;
  return o;
}

void checkColumns(api.Columns o) {
  buildCounterColumns++;
  if (buildCounterColumns < 3) {
    checkUnnamed5315(o.attributeNames!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed5316(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
  }
  buildCounterColumns--;
}

core.int buildCounterCustomDataSourceChildLink = 0;
api.CustomDataSourceChildLink buildCustomDataSourceChildLink() {
  var o = api.CustomDataSourceChildLink();
  buildCounterCustomDataSourceChildLink++;
  if (buildCounterCustomDataSourceChildLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterCustomDataSourceChildLink--;
  return o;
}

void checkCustomDataSourceChildLink(api.CustomDataSourceChildLink o) {
  buildCounterCustomDataSourceChildLink++;
  if (buildCounterCustomDataSourceChildLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDataSourceChildLink--;
}

core.int buildCounterCustomDataSourceParentLink = 0;
api.CustomDataSourceParentLink buildCustomDataSourceParentLink() {
  var o = api.CustomDataSourceParentLink();
  buildCounterCustomDataSourceParentLink++;
  if (buildCounterCustomDataSourceParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterCustomDataSourceParentLink--;
  return o;
}

void checkCustomDataSourceParentLink(api.CustomDataSourceParentLink o) {
  buildCounterCustomDataSourceParentLink++;
  if (buildCounterCustomDataSourceParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDataSourceParentLink--;
}

core.List<core.String> buildUnnamed5317() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5317(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5318() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5318(core.List<core.String> o) {
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

core.int buildCounterCustomDataSource = 0;
api.CustomDataSource buildCustomDataSource() {
  var o = api.CustomDataSource();
  buildCounterCustomDataSource++;
  if (buildCounterCustomDataSource < 3) {
    o.accountId = 'foo';
    o.childLink = buildCustomDataSourceChildLink();
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.description = 'foo';
    o.id = 'foo';
    o.importBehavior = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.parentLink = buildCustomDataSourceParentLink();
    o.profilesLinked = buildUnnamed5317();
    o.schema = buildUnnamed5318();
    o.selfLink = 'foo';
    o.type = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.uploadType = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterCustomDataSource--;
  return o;
}

void checkCustomDataSource(api.CustomDataSource o) {
  buildCounterCustomDataSource++;
  if (buildCounterCustomDataSource < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkCustomDataSourceChildLink(
        o.childLink! as api.CustomDataSourceChildLink);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.importBehavior!,
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
    checkCustomDataSourceParentLink(
        o.parentLink! as api.CustomDataSourceParentLink);
    checkUnnamed5317(o.profilesLinked!);
    checkUnnamed5318(o.schema!);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.uploadType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDataSource--;
}

core.List<api.CustomDataSource> buildUnnamed5319() {
  var o = <api.CustomDataSource>[];
  o.add(buildCustomDataSource());
  o.add(buildCustomDataSource());
  return o;
}

void checkUnnamed5319(core.List<api.CustomDataSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomDataSource(o[0] as api.CustomDataSource);
  checkCustomDataSource(o[1] as api.CustomDataSource);
}

core.int buildCounterCustomDataSources = 0;
api.CustomDataSources buildCustomDataSources() {
  var o = api.CustomDataSources();
  buildCounterCustomDataSources++;
  if (buildCounterCustomDataSources < 3) {
    o.items = buildUnnamed5319();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterCustomDataSources--;
  return o;
}

void checkCustomDataSources(api.CustomDataSources o) {
  buildCounterCustomDataSources++;
  if (buildCounterCustomDataSources < 3) {
    checkUnnamed5319(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDataSources--;
}

core.int buildCounterCustomDimensionParentLink = 0;
api.CustomDimensionParentLink buildCustomDimensionParentLink() {
  var o = api.CustomDimensionParentLink();
  buildCounterCustomDimensionParentLink++;
  if (buildCounterCustomDimensionParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterCustomDimensionParentLink--;
  return o;
}

void checkCustomDimensionParentLink(api.CustomDimensionParentLink o) {
  buildCounterCustomDimensionParentLink++;
  if (buildCounterCustomDimensionParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDimensionParentLink--;
}

core.int buildCounterCustomDimension = 0;
api.CustomDimension buildCustomDimension() {
  var o = api.CustomDimension();
  buildCounterCustomDimension++;
  if (buildCounterCustomDimension < 3) {
    o.accountId = 'foo';
    o.active = true;
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.id = 'foo';
    o.index = 42;
    o.kind = 'foo';
    o.name = 'foo';
    o.parentLink = buildCustomDimensionParentLink();
    o.scope = 'foo';
    o.selfLink = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.webPropertyId = 'foo';
  }
  buildCounterCustomDimension--;
  return o;
}

void checkCustomDimension(api.CustomDimension o) {
  buildCounterCustomDimension++;
  if (buildCounterCustomDimension < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.active!, unittest.isTrue);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkCustomDimensionParentLink(
        o.parentLink! as api.CustomDimensionParentLink);
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDimension--;
}

core.List<api.CustomDimension> buildUnnamed5320() {
  var o = <api.CustomDimension>[];
  o.add(buildCustomDimension());
  o.add(buildCustomDimension());
  return o;
}

void checkUnnamed5320(core.List<api.CustomDimension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomDimension(o[0] as api.CustomDimension);
  checkCustomDimension(o[1] as api.CustomDimension);
}

core.int buildCounterCustomDimensions = 0;
api.CustomDimensions buildCustomDimensions() {
  var o = api.CustomDimensions();
  buildCounterCustomDimensions++;
  if (buildCounterCustomDimensions < 3) {
    o.items = buildUnnamed5320();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterCustomDimensions--;
  return o;
}

void checkCustomDimensions(api.CustomDimensions o) {
  buildCounterCustomDimensions++;
  if (buildCounterCustomDimensions < 3) {
    checkUnnamed5320(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomDimensions--;
}

core.int buildCounterCustomMetricParentLink = 0;
api.CustomMetricParentLink buildCustomMetricParentLink() {
  var o = api.CustomMetricParentLink();
  buildCounterCustomMetricParentLink++;
  if (buildCounterCustomMetricParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterCustomMetricParentLink--;
  return o;
}

void checkCustomMetricParentLink(api.CustomMetricParentLink o) {
  buildCounterCustomMetricParentLink++;
  if (buildCounterCustomMetricParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomMetricParentLink--;
}

core.int buildCounterCustomMetric = 0;
api.CustomMetric buildCustomMetric() {
  var o = api.CustomMetric();
  buildCounterCustomMetric++;
  if (buildCounterCustomMetric < 3) {
    o.accountId = 'foo';
    o.active = true;
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.id = 'foo';
    o.index = 42;
    o.kind = 'foo';
    o.maxValue = 'foo';
    o.minValue = 'foo';
    o.name = 'foo';
    o.parentLink = buildCustomMetricParentLink();
    o.scope = 'foo';
    o.selfLink = 'foo';
    o.type = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.webPropertyId = 'foo';
  }
  buildCounterCustomMetric--;
  return o;
}

void checkCustomMetric(api.CustomMetric o) {
  buildCounterCustomMetric++;
  if (buildCounterCustomMetric < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.active!, unittest.isTrue);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkCustomMetricParentLink(o.parentLink! as api.CustomMetricParentLink);
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomMetric--;
}

core.List<api.CustomMetric> buildUnnamed5321() {
  var o = <api.CustomMetric>[];
  o.add(buildCustomMetric());
  o.add(buildCustomMetric());
  return o;
}

void checkUnnamed5321(core.List<api.CustomMetric> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomMetric(o[0] as api.CustomMetric);
  checkCustomMetric(o[1] as api.CustomMetric);
}

core.int buildCounterCustomMetrics = 0;
api.CustomMetrics buildCustomMetrics() {
  var o = api.CustomMetrics();
  buildCounterCustomMetrics++;
  if (buildCounterCustomMetrics < 3) {
    o.items = buildUnnamed5321();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterCustomMetrics--;
  return o;
}

void checkCustomMetrics(api.CustomMetrics o) {
  buildCounterCustomMetrics++;
  if (buildCounterCustomMetrics < 3) {
    checkUnnamed5321(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomMetrics--;
}

core.List<api.AdWordsAccount> buildUnnamed5322() {
  var o = <api.AdWordsAccount>[];
  o.add(buildAdWordsAccount());
  o.add(buildAdWordsAccount());
  return o;
}

void checkUnnamed5322(core.List<api.AdWordsAccount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdWordsAccount(o[0] as api.AdWordsAccount);
  checkAdWordsAccount(o[1] as api.AdWordsAccount);
}

core.int buildCounterEntityAdWordsLinkEntity = 0;
api.EntityAdWordsLinkEntity buildEntityAdWordsLinkEntity() {
  var o = api.EntityAdWordsLinkEntity();
  buildCounterEntityAdWordsLinkEntity++;
  if (buildCounterEntityAdWordsLinkEntity < 3) {
    o.webPropertyRef = buildWebPropertyRef();
  }
  buildCounterEntityAdWordsLinkEntity--;
  return o;
}

void checkEntityAdWordsLinkEntity(api.EntityAdWordsLinkEntity o) {
  buildCounterEntityAdWordsLinkEntity++;
  if (buildCounterEntityAdWordsLinkEntity < 3) {
    checkWebPropertyRef(o.webPropertyRef! as api.WebPropertyRef);
  }
  buildCounterEntityAdWordsLinkEntity--;
}

core.List<core.String> buildUnnamed5323() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5323(core.List<core.String> o) {
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

core.int buildCounterEntityAdWordsLink = 0;
api.EntityAdWordsLink buildEntityAdWordsLink() {
  var o = api.EntityAdWordsLink();
  buildCounterEntityAdWordsLink++;
  if (buildCounterEntityAdWordsLink < 3) {
    o.adWordsAccounts = buildUnnamed5322();
    o.entity = buildEntityAdWordsLinkEntity();
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.profileIds = buildUnnamed5323();
    o.selfLink = 'foo';
  }
  buildCounterEntityAdWordsLink--;
  return o;
}

void checkEntityAdWordsLink(api.EntityAdWordsLink o) {
  buildCounterEntityAdWordsLink++;
  if (buildCounterEntityAdWordsLink < 3) {
    checkUnnamed5322(o.adWordsAccounts!);
    checkEntityAdWordsLinkEntity(o.entity! as api.EntityAdWordsLinkEntity);
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
    checkUnnamed5323(o.profileIds!);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntityAdWordsLink--;
}

core.List<api.EntityAdWordsLink> buildUnnamed5324() {
  var o = <api.EntityAdWordsLink>[];
  o.add(buildEntityAdWordsLink());
  o.add(buildEntityAdWordsLink());
  return o;
}

void checkUnnamed5324(core.List<api.EntityAdWordsLink> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntityAdWordsLink(o[0] as api.EntityAdWordsLink);
  checkEntityAdWordsLink(o[1] as api.EntityAdWordsLink);
}

core.int buildCounterEntityAdWordsLinks = 0;
api.EntityAdWordsLinks buildEntityAdWordsLinks() {
  var o = api.EntityAdWordsLinks();
  buildCounterEntityAdWordsLinks++;
  if (buildCounterEntityAdWordsLinks < 3) {
    o.items = buildUnnamed5324();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
  }
  buildCounterEntityAdWordsLinks--;
  return o;
}

void checkEntityAdWordsLinks(api.EntityAdWordsLinks o) {
  buildCounterEntityAdWordsLinks++;
  if (buildCounterEntityAdWordsLinks < 3) {
    checkUnnamed5324(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
  }
  buildCounterEntityAdWordsLinks--;
}

core.int buildCounterEntityUserLinkEntity = 0;
api.EntityUserLinkEntity buildEntityUserLinkEntity() {
  var o = api.EntityUserLinkEntity();
  buildCounterEntityUserLinkEntity++;
  if (buildCounterEntityUserLinkEntity < 3) {
    o.accountRef = buildAccountRef();
    o.profileRef = buildProfileRef();
    o.webPropertyRef = buildWebPropertyRef();
  }
  buildCounterEntityUserLinkEntity--;
  return o;
}

void checkEntityUserLinkEntity(api.EntityUserLinkEntity o) {
  buildCounterEntityUserLinkEntity++;
  if (buildCounterEntityUserLinkEntity < 3) {
    checkAccountRef(o.accountRef! as api.AccountRef);
    checkProfileRef(o.profileRef! as api.ProfileRef);
    checkWebPropertyRef(o.webPropertyRef! as api.WebPropertyRef);
  }
  buildCounterEntityUserLinkEntity--;
}

core.List<core.String> buildUnnamed5325() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5325(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5326() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5326(core.List<core.String> o) {
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

core.int buildCounterEntityUserLinkPermissions = 0;
api.EntityUserLinkPermissions buildEntityUserLinkPermissions() {
  var o = api.EntityUserLinkPermissions();
  buildCounterEntityUserLinkPermissions++;
  if (buildCounterEntityUserLinkPermissions < 3) {
    o.effective = buildUnnamed5325();
    o.local = buildUnnamed5326();
  }
  buildCounterEntityUserLinkPermissions--;
  return o;
}

void checkEntityUserLinkPermissions(api.EntityUserLinkPermissions o) {
  buildCounterEntityUserLinkPermissions++;
  if (buildCounterEntityUserLinkPermissions < 3) {
    checkUnnamed5325(o.effective!);
    checkUnnamed5326(o.local!);
  }
  buildCounterEntityUserLinkPermissions--;
}

core.int buildCounterEntityUserLink = 0;
api.EntityUserLink buildEntityUserLink() {
  var o = api.EntityUserLink();
  buildCounterEntityUserLink++;
  if (buildCounterEntityUserLink < 3) {
    o.entity = buildEntityUserLinkEntity();
    o.id = 'foo';
    o.kind = 'foo';
    o.permissions = buildEntityUserLinkPermissions();
    o.selfLink = 'foo';
    o.userRef = buildUserRef();
  }
  buildCounterEntityUserLink--;
  return o;
}

void checkEntityUserLink(api.EntityUserLink o) {
  buildCounterEntityUserLink++;
  if (buildCounterEntityUserLink < 3) {
    checkEntityUserLinkEntity(o.entity! as api.EntityUserLinkEntity);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkEntityUserLinkPermissions(
        o.permissions! as api.EntityUserLinkPermissions);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    checkUserRef(o.userRef! as api.UserRef);
  }
  buildCounterEntityUserLink--;
}

core.List<api.EntityUserLink> buildUnnamed5327() {
  var o = <api.EntityUserLink>[];
  o.add(buildEntityUserLink());
  o.add(buildEntityUserLink());
  return o;
}

void checkUnnamed5327(core.List<api.EntityUserLink> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntityUserLink(o[0] as api.EntityUserLink);
  checkEntityUserLink(o[1] as api.EntityUserLink);
}

core.int buildCounterEntityUserLinks = 0;
api.EntityUserLinks buildEntityUserLinks() {
  var o = api.EntityUserLinks();
  buildCounterEntityUserLinks++;
  if (buildCounterEntityUserLinks < 3) {
    o.items = buildUnnamed5327();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
  }
  buildCounterEntityUserLinks--;
  return o;
}

void checkEntityUserLinks(api.EntityUserLinks o) {
  buildCounterEntityUserLinks++;
  if (buildCounterEntityUserLinks < 3) {
    checkUnnamed5327(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
  }
  buildCounterEntityUserLinks--;
}

core.int buildCounterExperimentParentLink = 0;
api.ExperimentParentLink buildExperimentParentLink() {
  var o = api.ExperimentParentLink();
  buildCounterExperimentParentLink++;
  if (buildCounterExperimentParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterExperimentParentLink--;
  return o;
}

void checkExperimentParentLink(api.ExperimentParentLink o) {
  buildCounterExperimentParentLink++;
  if (buildCounterExperimentParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterExperimentParentLink--;
}

core.int buildCounterExperimentVariations = 0;
api.ExperimentVariations buildExperimentVariations() {
  var o = api.ExperimentVariations();
  buildCounterExperimentVariations++;
  if (buildCounterExperimentVariations < 3) {
    o.name = 'foo';
    o.status = 'foo';
    o.url = 'foo';
    o.weight = 42.0;
    o.won = true;
  }
  buildCounterExperimentVariations--;
  return o;
}

void checkExperimentVariations(api.ExperimentVariations o) {
  buildCounterExperimentVariations++;
  if (buildCounterExperimentVariations < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.weight!,
      unittest.equals(42.0),
    );
    unittest.expect(o.won!, unittest.isTrue);
  }
  buildCounterExperimentVariations--;
}

core.List<api.ExperimentVariations> buildUnnamed5328() {
  var o = <api.ExperimentVariations>[];
  o.add(buildExperimentVariations());
  o.add(buildExperimentVariations());
  return o;
}

void checkUnnamed5328(core.List<api.ExperimentVariations> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExperimentVariations(o[0] as api.ExperimentVariations);
  checkExperimentVariations(o[1] as api.ExperimentVariations);
}

core.int buildCounterExperiment = 0;
api.Experiment buildExperiment() {
  var o = api.Experiment();
  buildCounterExperiment++;
  if (buildCounterExperiment < 3) {
    o.accountId = 'foo';
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.description = 'foo';
    o.editableInGaUi = true;
    o.endTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.equalWeighting = true;
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.minimumExperimentLengthInDays = 42;
    o.name = 'foo';
    o.objectiveMetric = 'foo';
    o.optimizationType = 'foo';
    o.parentLink = buildExperimentParentLink();
    o.profileId = 'foo';
    o.reasonExperimentEnded = 'foo';
    o.rewriteVariationUrlsAsOriginal = true;
    o.selfLink = 'foo';
    o.servingFramework = 'foo';
    o.snippet = 'foo';
    o.startTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.status = 'foo';
    o.trafficCoverage = 42.0;
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.variations = buildUnnamed5328();
    o.webPropertyId = 'foo';
    o.winnerConfidenceLevel = 42.0;
    o.winnerFound = true;
  }
  buildCounterExperiment--;
  return o;
}

void checkExperiment(api.Experiment o) {
  buildCounterExperiment++;
  if (buildCounterExperiment < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(o.editableInGaUi!, unittest.isTrue);
    unittest.expect(
      o.endTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(o.equalWeighting!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumExperimentLengthInDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectiveMetric!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.optimizationType!,
      unittest.equals('foo'),
    );
    checkExperimentParentLink(o.parentLink! as api.ExperimentParentLink);
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reasonExperimentEnded!,
      unittest.equals('foo'),
    );
    unittest.expect(o.rewriteVariationUrlsAsOriginal!, unittest.isTrue);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.servingFramework!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.snippet!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.trafficCoverage!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed5328(o.variations!);
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.winnerConfidenceLevel!,
      unittest.equals(42.0),
    );
    unittest.expect(o.winnerFound!, unittest.isTrue);
  }
  buildCounterExperiment--;
}

core.List<api.Experiment> buildUnnamed5329() {
  var o = <api.Experiment>[];
  o.add(buildExperiment());
  o.add(buildExperiment());
  return o;
}

void checkUnnamed5329(core.List<api.Experiment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExperiment(o[0] as api.Experiment);
  checkExperiment(o[1] as api.Experiment);
}

core.int buildCounterExperiments = 0;
api.Experiments buildExperiments() {
  var o = api.Experiments();
  buildCounterExperiments++;
  if (buildCounterExperiments < 3) {
    o.items = buildUnnamed5329();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterExperiments--;
  return o;
}

void checkExperiments(api.Experiments o) {
  buildCounterExperiments++;
  if (buildCounterExperiments < 3) {
    checkUnnamed5329(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterExperiments--;
}

core.int buildCounterFilterAdvancedDetails = 0;
api.FilterAdvancedDetails buildFilterAdvancedDetails() {
  var o = api.FilterAdvancedDetails();
  buildCounterFilterAdvancedDetails++;
  if (buildCounterFilterAdvancedDetails < 3) {
    o.caseSensitive = true;
    o.extractA = 'foo';
    o.extractB = 'foo';
    o.fieldA = 'foo';
    o.fieldAIndex = 42;
    o.fieldARequired = true;
    o.fieldB = 'foo';
    o.fieldBIndex = 42;
    o.fieldBRequired = true;
    o.outputConstructor = 'foo';
    o.outputToField = 'foo';
    o.outputToFieldIndex = 42;
    o.overrideOutputField = true;
  }
  buildCounterFilterAdvancedDetails--;
  return o;
}

void checkFilterAdvancedDetails(api.FilterAdvancedDetails o) {
  buildCounterFilterAdvancedDetails++;
  if (buildCounterFilterAdvancedDetails < 3) {
    unittest.expect(o.caseSensitive!, unittest.isTrue);
    unittest.expect(
      o.extractA!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.extractB!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldA!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldAIndex!,
      unittest.equals(42),
    );
    unittest.expect(o.fieldARequired!, unittest.isTrue);
    unittest.expect(
      o.fieldB!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldBIndex!,
      unittest.equals(42),
    );
    unittest.expect(o.fieldBRequired!, unittest.isTrue);
    unittest.expect(
      o.outputConstructor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputToField!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputToFieldIndex!,
      unittest.equals(42),
    );
    unittest.expect(o.overrideOutputField!, unittest.isTrue);
  }
  buildCounterFilterAdvancedDetails--;
}

core.int buildCounterFilterLowercaseDetails = 0;
api.FilterLowercaseDetails buildFilterLowercaseDetails() {
  var o = api.FilterLowercaseDetails();
  buildCounterFilterLowercaseDetails++;
  if (buildCounterFilterLowercaseDetails < 3) {
    o.field = 'foo';
    o.fieldIndex = 42;
  }
  buildCounterFilterLowercaseDetails--;
  return o;
}

void checkFilterLowercaseDetails(api.FilterLowercaseDetails o) {
  buildCounterFilterLowercaseDetails++;
  if (buildCounterFilterLowercaseDetails < 3) {
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldIndex!,
      unittest.equals(42),
    );
  }
  buildCounterFilterLowercaseDetails--;
}

core.int buildCounterFilterParentLink = 0;
api.FilterParentLink buildFilterParentLink() {
  var o = api.FilterParentLink();
  buildCounterFilterParentLink++;
  if (buildCounterFilterParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterFilterParentLink--;
  return o;
}

void checkFilterParentLink(api.FilterParentLink o) {
  buildCounterFilterParentLink++;
  if (buildCounterFilterParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterParentLink--;
}

core.int buildCounterFilterSearchAndReplaceDetails = 0;
api.FilterSearchAndReplaceDetails buildFilterSearchAndReplaceDetails() {
  var o = api.FilterSearchAndReplaceDetails();
  buildCounterFilterSearchAndReplaceDetails++;
  if (buildCounterFilterSearchAndReplaceDetails < 3) {
    o.caseSensitive = true;
    o.field = 'foo';
    o.fieldIndex = 42;
    o.replaceString = 'foo';
    o.searchString = 'foo';
  }
  buildCounterFilterSearchAndReplaceDetails--;
  return o;
}

void checkFilterSearchAndReplaceDetails(api.FilterSearchAndReplaceDetails o) {
  buildCounterFilterSearchAndReplaceDetails++;
  if (buildCounterFilterSearchAndReplaceDetails < 3) {
    unittest.expect(o.caseSensitive!, unittest.isTrue);
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.replaceString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.searchString!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterSearchAndReplaceDetails--;
}

core.int buildCounterFilterUppercaseDetails = 0;
api.FilterUppercaseDetails buildFilterUppercaseDetails() {
  var o = api.FilterUppercaseDetails();
  buildCounterFilterUppercaseDetails++;
  if (buildCounterFilterUppercaseDetails < 3) {
    o.field = 'foo';
    o.fieldIndex = 42;
  }
  buildCounterFilterUppercaseDetails--;
  return o;
}

void checkFilterUppercaseDetails(api.FilterUppercaseDetails o) {
  buildCounterFilterUppercaseDetails++;
  if (buildCounterFilterUppercaseDetails < 3) {
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldIndex!,
      unittest.equals(42),
    );
  }
  buildCounterFilterUppercaseDetails--;
}

core.int buildCounterFilter = 0;
api.Filter buildFilter() {
  var o = api.Filter();
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    o.accountId = 'foo';
    o.advancedDetails = buildFilterAdvancedDetails();
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.excludeDetails = buildFilterExpression();
    o.id = 'foo';
    o.includeDetails = buildFilterExpression();
    o.kind = 'foo';
    o.lowercaseDetails = buildFilterLowercaseDetails();
    o.name = 'foo';
    o.parentLink = buildFilterParentLink();
    o.searchAndReplaceDetails = buildFilterSearchAndReplaceDetails();
    o.selfLink = 'foo';
    o.type = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.uppercaseDetails = buildFilterUppercaseDetails();
  }
  buildCounterFilter--;
  return o;
}

void checkFilter(api.Filter o) {
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkFilterAdvancedDetails(o.advancedDetails! as api.FilterAdvancedDetails);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkFilterExpression(o.excludeDetails! as api.FilterExpression);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkFilterExpression(o.includeDetails! as api.FilterExpression);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkFilterLowercaseDetails(
        o.lowercaseDetails! as api.FilterLowercaseDetails);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkFilterParentLink(o.parentLink! as api.FilterParentLink);
    checkFilterSearchAndReplaceDetails(
        o.searchAndReplaceDetails! as api.FilterSearchAndReplaceDetails);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkFilterUppercaseDetails(
        o.uppercaseDetails! as api.FilterUppercaseDetails);
  }
  buildCounterFilter--;
}

core.int buildCounterFilterExpression = 0;
api.FilterExpression buildFilterExpression() {
  var o = api.FilterExpression();
  buildCounterFilterExpression++;
  if (buildCounterFilterExpression < 3) {
    o.caseSensitive = true;
    o.expressionValue = 'foo';
    o.field = 'foo';
    o.fieldIndex = 42;
    o.kind = 'foo';
    o.matchType = 'foo';
  }
  buildCounterFilterExpression--;
  return o;
}

void checkFilterExpression(api.FilterExpression o) {
  buildCounterFilterExpression++;
  if (buildCounterFilterExpression < 3) {
    unittest.expect(o.caseSensitive!, unittest.isTrue);
    unittest.expect(
      o.expressionValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.matchType!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterExpression--;
}

core.int buildCounterFilterRef = 0;
api.FilterRef buildFilterRef() {
  var o = api.FilterRef();
  buildCounterFilterRef++;
  if (buildCounterFilterRef < 3) {
    o.accountId = 'foo';
    o.href = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterFilterRef--;
  return o;
}

void checkFilterRef(api.FilterRef o) {
  buildCounterFilterRef++;
  if (buildCounterFilterRef < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
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
  }
  buildCounterFilterRef--;
}

core.List<api.Filter> buildUnnamed5330() {
  var o = <api.Filter>[];
  o.add(buildFilter());
  o.add(buildFilter());
  return o;
}

void checkUnnamed5330(core.List<api.Filter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilter(o[0] as api.Filter);
  checkFilter(o[1] as api.Filter);
}

core.int buildCounterFilters = 0;
api.Filters buildFilters() {
  var o = api.Filters();
  buildCounterFilters++;
  if (buildCounterFilters < 3) {
    o.items = buildUnnamed5330();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterFilters--;
  return o;
}

void checkFilters(api.Filters o) {
  buildCounterFilters++;
  if (buildCounterFilters < 3) {
    checkUnnamed5330(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilters--;
}

core.int buildCounterGaDataColumnHeaders = 0;
api.GaDataColumnHeaders buildGaDataColumnHeaders() {
  var o = api.GaDataColumnHeaders();
  buildCounterGaDataColumnHeaders++;
  if (buildCounterGaDataColumnHeaders < 3) {
    o.columnType = 'foo';
    o.dataType = 'foo';
    o.name = 'foo';
  }
  buildCounterGaDataColumnHeaders--;
  return o;
}

void checkGaDataColumnHeaders(api.GaDataColumnHeaders o) {
  buildCounterGaDataColumnHeaders++;
  if (buildCounterGaDataColumnHeaders < 3) {
    unittest.expect(
      o.columnType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGaDataColumnHeaders--;
}

core.List<api.GaDataColumnHeaders> buildUnnamed5331() {
  var o = <api.GaDataColumnHeaders>[];
  o.add(buildGaDataColumnHeaders());
  o.add(buildGaDataColumnHeaders());
  return o;
}

void checkUnnamed5331(core.List<api.GaDataColumnHeaders> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGaDataColumnHeaders(o[0] as api.GaDataColumnHeaders);
  checkGaDataColumnHeaders(o[1] as api.GaDataColumnHeaders);
}

core.int buildCounterGaDataDataTableCols = 0;
api.GaDataDataTableCols buildGaDataDataTableCols() {
  var o = api.GaDataDataTableCols();
  buildCounterGaDataDataTableCols++;
  if (buildCounterGaDataDataTableCols < 3) {
    o.id = 'foo';
    o.label = 'foo';
    o.type = 'foo';
  }
  buildCounterGaDataDataTableCols--;
  return o;
}

void checkGaDataDataTableCols(api.GaDataDataTableCols o) {
  buildCounterGaDataDataTableCols++;
  if (buildCounterGaDataDataTableCols < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterGaDataDataTableCols--;
}

core.List<api.GaDataDataTableCols> buildUnnamed5332() {
  var o = <api.GaDataDataTableCols>[];
  o.add(buildGaDataDataTableCols());
  o.add(buildGaDataDataTableCols());
  return o;
}

void checkUnnamed5332(core.List<api.GaDataDataTableCols> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGaDataDataTableCols(o[0] as api.GaDataDataTableCols);
  checkGaDataDataTableCols(o[1] as api.GaDataDataTableCols);
}

core.int buildCounterGaDataDataTableRowsC = 0;
api.GaDataDataTableRowsC buildGaDataDataTableRowsC() {
  var o = api.GaDataDataTableRowsC();
  buildCounterGaDataDataTableRowsC++;
  if (buildCounterGaDataDataTableRowsC < 3) {
    o.v = 'foo';
  }
  buildCounterGaDataDataTableRowsC--;
  return o;
}

void checkGaDataDataTableRowsC(api.GaDataDataTableRowsC o) {
  buildCounterGaDataDataTableRowsC++;
  if (buildCounterGaDataDataTableRowsC < 3) {
    unittest.expect(
      o.v!,
      unittest.equals('foo'),
    );
  }
  buildCounterGaDataDataTableRowsC--;
}

core.List<api.GaDataDataTableRowsC> buildUnnamed5333() {
  var o = <api.GaDataDataTableRowsC>[];
  o.add(buildGaDataDataTableRowsC());
  o.add(buildGaDataDataTableRowsC());
  return o;
}

void checkUnnamed5333(core.List<api.GaDataDataTableRowsC> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGaDataDataTableRowsC(o[0] as api.GaDataDataTableRowsC);
  checkGaDataDataTableRowsC(o[1] as api.GaDataDataTableRowsC);
}

core.int buildCounterGaDataDataTableRows = 0;
api.GaDataDataTableRows buildGaDataDataTableRows() {
  var o = api.GaDataDataTableRows();
  buildCounterGaDataDataTableRows++;
  if (buildCounterGaDataDataTableRows < 3) {
    o.c = buildUnnamed5333();
  }
  buildCounterGaDataDataTableRows--;
  return o;
}

void checkGaDataDataTableRows(api.GaDataDataTableRows o) {
  buildCounterGaDataDataTableRows++;
  if (buildCounterGaDataDataTableRows < 3) {
    checkUnnamed5333(o.c!);
  }
  buildCounterGaDataDataTableRows--;
}

core.List<api.GaDataDataTableRows> buildUnnamed5334() {
  var o = <api.GaDataDataTableRows>[];
  o.add(buildGaDataDataTableRows());
  o.add(buildGaDataDataTableRows());
  return o;
}

void checkUnnamed5334(core.List<api.GaDataDataTableRows> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGaDataDataTableRows(o[0] as api.GaDataDataTableRows);
  checkGaDataDataTableRows(o[1] as api.GaDataDataTableRows);
}

core.int buildCounterGaDataDataTable = 0;
api.GaDataDataTable buildGaDataDataTable() {
  var o = api.GaDataDataTable();
  buildCounterGaDataDataTable++;
  if (buildCounterGaDataDataTable < 3) {
    o.cols = buildUnnamed5332();
    o.rows = buildUnnamed5334();
  }
  buildCounterGaDataDataTable--;
  return o;
}

void checkGaDataDataTable(api.GaDataDataTable o) {
  buildCounterGaDataDataTable++;
  if (buildCounterGaDataDataTable < 3) {
    checkUnnamed5332(o.cols!);
    checkUnnamed5334(o.rows!);
  }
  buildCounterGaDataDataTable--;
}

core.int buildCounterGaDataProfileInfo = 0;
api.GaDataProfileInfo buildGaDataProfileInfo() {
  var o = api.GaDataProfileInfo();
  buildCounterGaDataProfileInfo++;
  if (buildCounterGaDataProfileInfo < 3) {
    o.accountId = 'foo';
    o.internalWebPropertyId = 'foo';
    o.profileId = 'foo';
    o.profileName = 'foo';
    o.tableId = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterGaDataProfileInfo--;
  return o;
}

void checkGaDataProfileInfo(api.GaDataProfileInfo o) {
  buildCounterGaDataProfileInfo++;
  if (buildCounterGaDataProfileInfo < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGaDataProfileInfo--;
}

core.List<core.String> buildUnnamed5335() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5335(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5336() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5336(core.List<core.String> o) {
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

core.int buildCounterGaDataQuery = 0;
api.GaDataQuery buildGaDataQuery() {
  var o = api.GaDataQuery();
  buildCounterGaDataQuery++;
  if (buildCounterGaDataQuery < 3) {
    o.dimensions = 'foo';
    o.endDate = 'foo';
    o.filters = 'foo';
    o.ids = 'foo';
    o.maxResults = 42;
    o.metrics = buildUnnamed5335();
    o.samplingLevel = 'foo';
    o.segment = 'foo';
    o.sort = buildUnnamed5336();
    o.startDate = 'foo';
    o.startIndex = 42;
  }
  buildCounterGaDataQuery--;
  return o;
}

void checkGaDataQuery(api.GaDataQuery o) {
  buildCounterGaDataQuery++;
  if (buildCounterGaDataQuery < 3) {
    unittest.expect(
      o.dimensions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ids!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxResults!,
      unittest.equals(42),
    );
    checkUnnamed5335(o.metrics!);
    unittest.expect(
      o.samplingLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segment!,
      unittest.equals('foo'),
    );
    checkUnnamed5336(o.sort!);
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
  }
  buildCounterGaDataQuery--;
}

core.List<core.String> buildUnnamed5337() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5337(core.List<core.String> o) {
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

core.List<core.List<core.String>> buildUnnamed5338() {
  var o = <core.List<core.String>>[];
  o.add(buildUnnamed5337());
  o.add(buildUnnamed5337());
  return o;
}

void checkUnnamed5338(core.List<core.List<core.String>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5337(o[0]);
  checkUnnamed5337(o[1]);
}

core.Map<core.String, core.String> buildUnnamed5339() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5339(core.Map<core.String, core.String> o) {
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

core.int buildCounterGaData = 0;
api.GaData buildGaData() {
  var o = api.GaData();
  buildCounterGaData++;
  if (buildCounterGaData < 3) {
    o.columnHeaders = buildUnnamed5331();
    o.containsSampledData = true;
    o.dataLastRefreshed = 'foo';
    o.dataTable = buildGaDataDataTable();
    o.id = 'foo';
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.profileInfo = buildGaDataProfileInfo();
    o.query = buildGaDataQuery();
    o.rows = buildUnnamed5338();
    o.sampleSize = 'foo';
    o.sampleSpace = 'foo';
    o.selfLink = 'foo';
    o.totalResults = 42;
    o.totalsForAllResults = buildUnnamed5339();
  }
  buildCounterGaData--;
  return o;
}

void checkGaData(api.GaData o) {
  buildCounterGaData++;
  if (buildCounterGaData < 3) {
    checkUnnamed5331(o.columnHeaders!);
    unittest.expect(o.containsSampledData!, unittest.isTrue);
    unittest.expect(
      o.dataLastRefreshed!,
      unittest.equals('foo'),
    );
    checkGaDataDataTable(o.dataTable! as api.GaDataDataTable);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    checkGaDataProfileInfo(o.profileInfo! as api.GaDataProfileInfo);
    checkGaDataQuery(o.query! as api.GaDataQuery);
    checkUnnamed5338(o.rows!);
    unittest.expect(
      o.sampleSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sampleSpace!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    checkUnnamed5339(o.totalsForAllResults!);
  }
  buildCounterGaData--;
}

core.int buildCounterGoalEventDetailsEventConditions = 0;
api.GoalEventDetailsEventConditions buildGoalEventDetailsEventConditions() {
  var o = api.GoalEventDetailsEventConditions();
  buildCounterGoalEventDetailsEventConditions++;
  if (buildCounterGoalEventDetailsEventConditions < 3) {
    o.comparisonType = 'foo';
    o.comparisonValue = 'foo';
    o.expression = 'foo';
    o.matchType = 'foo';
    o.type = 'foo';
  }
  buildCounterGoalEventDetailsEventConditions--;
  return o;
}

void checkGoalEventDetailsEventConditions(
    api.GoalEventDetailsEventConditions o) {
  buildCounterGoalEventDetailsEventConditions++;
  if (buildCounterGoalEventDetailsEventConditions < 3) {
    unittest.expect(
      o.comparisonType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.comparisonValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.matchType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoalEventDetailsEventConditions--;
}

core.List<api.GoalEventDetailsEventConditions> buildUnnamed5340() {
  var o = <api.GoalEventDetailsEventConditions>[];
  o.add(buildGoalEventDetailsEventConditions());
  o.add(buildGoalEventDetailsEventConditions());
  return o;
}

void checkUnnamed5340(core.List<api.GoalEventDetailsEventConditions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoalEventDetailsEventConditions(
      o[0] as api.GoalEventDetailsEventConditions);
  checkGoalEventDetailsEventConditions(
      o[1] as api.GoalEventDetailsEventConditions);
}

core.int buildCounterGoalEventDetails = 0;
api.GoalEventDetails buildGoalEventDetails() {
  var o = api.GoalEventDetails();
  buildCounterGoalEventDetails++;
  if (buildCounterGoalEventDetails < 3) {
    o.eventConditions = buildUnnamed5340();
    o.useEventValue = true;
  }
  buildCounterGoalEventDetails--;
  return o;
}

void checkGoalEventDetails(api.GoalEventDetails o) {
  buildCounterGoalEventDetails++;
  if (buildCounterGoalEventDetails < 3) {
    checkUnnamed5340(o.eventConditions!);
    unittest.expect(o.useEventValue!, unittest.isTrue);
  }
  buildCounterGoalEventDetails--;
}

core.int buildCounterGoalParentLink = 0;
api.GoalParentLink buildGoalParentLink() {
  var o = api.GoalParentLink();
  buildCounterGoalParentLink++;
  if (buildCounterGoalParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterGoalParentLink--;
  return o;
}

void checkGoalParentLink(api.GoalParentLink o) {
  buildCounterGoalParentLink++;
  if (buildCounterGoalParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoalParentLink--;
}

core.int buildCounterGoalUrlDestinationDetailsSteps = 0;
api.GoalUrlDestinationDetailsSteps buildGoalUrlDestinationDetailsSteps() {
  var o = api.GoalUrlDestinationDetailsSteps();
  buildCounterGoalUrlDestinationDetailsSteps++;
  if (buildCounterGoalUrlDestinationDetailsSteps < 3) {
    o.name = 'foo';
    o.number = 42;
    o.url = 'foo';
  }
  buildCounterGoalUrlDestinationDetailsSteps--;
  return o;
}

void checkGoalUrlDestinationDetailsSteps(api.GoalUrlDestinationDetailsSteps o) {
  buildCounterGoalUrlDestinationDetailsSteps++;
  if (buildCounterGoalUrlDestinationDetailsSteps < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.number!,
      unittest.equals(42),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoalUrlDestinationDetailsSteps--;
}

core.List<api.GoalUrlDestinationDetailsSteps> buildUnnamed5341() {
  var o = <api.GoalUrlDestinationDetailsSteps>[];
  o.add(buildGoalUrlDestinationDetailsSteps());
  o.add(buildGoalUrlDestinationDetailsSteps());
  return o;
}

void checkUnnamed5341(core.List<api.GoalUrlDestinationDetailsSteps> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoalUrlDestinationDetailsSteps(
      o[0] as api.GoalUrlDestinationDetailsSteps);
  checkGoalUrlDestinationDetailsSteps(
      o[1] as api.GoalUrlDestinationDetailsSteps);
}

core.int buildCounterGoalUrlDestinationDetails = 0;
api.GoalUrlDestinationDetails buildGoalUrlDestinationDetails() {
  var o = api.GoalUrlDestinationDetails();
  buildCounterGoalUrlDestinationDetails++;
  if (buildCounterGoalUrlDestinationDetails < 3) {
    o.caseSensitive = true;
    o.firstStepRequired = true;
    o.matchType = 'foo';
    o.steps = buildUnnamed5341();
    o.url = 'foo';
  }
  buildCounterGoalUrlDestinationDetails--;
  return o;
}

void checkGoalUrlDestinationDetails(api.GoalUrlDestinationDetails o) {
  buildCounterGoalUrlDestinationDetails++;
  if (buildCounterGoalUrlDestinationDetails < 3) {
    unittest.expect(o.caseSensitive!, unittest.isTrue);
    unittest.expect(o.firstStepRequired!, unittest.isTrue);
    unittest.expect(
      o.matchType!,
      unittest.equals('foo'),
    );
    checkUnnamed5341(o.steps!);
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoalUrlDestinationDetails--;
}

core.int buildCounterGoalVisitNumPagesDetails = 0;
api.GoalVisitNumPagesDetails buildGoalVisitNumPagesDetails() {
  var o = api.GoalVisitNumPagesDetails();
  buildCounterGoalVisitNumPagesDetails++;
  if (buildCounterGoalVisitNumPagesDetails < 3) {
    o.comparisonType = 'foo';
    o.comparisonValue = 'foo';
  }
  buildCounterGoalVisitNumPagesDetails--;
  return o;
}

void checkGoalVisitNumPagesDetails(api.GoalVisitNumPagesDetails o) {
  buildCounterGoalVisitNumPagesDetails++;
  if (buildCounterGoalVisitNumPagesDetails < 3) {
    unittest.expect(
      o.comparisonType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.comparisonValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoalVisitNumPagesDetails--;
}

core.int buildCounterGoalVisitTimeOnSiteDetails = 0;
api.GoalVisitTimeOnSiteDetails buildGoalVisitTimeOnSiteDetails() {
  var o = api.GoalVisitTimeOnSiteDetails();
  buildCounterGoalVisitTimeOnSiteDetails++;
  if (buildCounterGoalVisitTimeOnSiteDetails < 3) {
    o.comparisonType = 'foo';
    o.comparisonValue = 'foo';
  }
  buildCounterGoalVisitTimeOnSiteDetails--;
  return o;
}

void checkGoalVisitTimeOnSiteDetails(api.GoalVisitTimeOnSiteDetails o) {
  buildCounterGoalVisitTimeOnSiteDetails++;
  if (buildCounterGoalVisitTimeOnSiteDetails < 3) {
    unittest.expect(
      o.comparisonType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.comparisonValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoalVisitTimeOnSiteDetails--;
}

core.int buildCounterGoal = 0;
api.Goal buildGoal() {
  var o = api.Goal();
  buildCounterGoal++;
  if (buildCounterGoal < 3) {
    o.accountId = 'foo';
    o.active = true;
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.eventDetails = buildGoalEventDetails();
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.parentLink = buildGoalParentLink();
    o.profileId = 'foo';
    o.selfLink = 'foo';
    o.type = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.urlDestinationDetails = buildGoalUrlDestinationDetails();
    o.value = 42.0;
    o.visitNumPagesDetails = buildGoalVisitNumPagesDetails();
    o.visitTimeOnSiteDetails = buildGoalVisitTimeOnSiteDetails();
    o.webPropertyId = 'foo';
  }
  buildCounterGoal--;
  return o;
}

void checkGoal(api.Goal o) {
  buildCounterGoal++;
  if (buildCounterGoal < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.active!, unittest.isTrue);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkGoalEventDetails(o.eventDetails! as api.GoalEventDetails);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
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
    checkGoalParentLink(o.parentLink! as api.GoalParentLink);
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkGoalUrlDestinationDetails(
        o.urlDestinationDetails! as api.GoalUrlDestinationDetails);
    unittest.expect(
      o.value!,
      unittest.equals(42.0),
    );
    checkGoalVisitNumPagesDetails(
        o.visitNumPagesDetails! as api.GoalVisitNumPagesDetails);
    checkGoalVisitTimeOnSiteDetails(
        o.visitTimeOnSiteDetails! as api.GoalVisitTimeOnSiteDetails);
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoal--;
}

core.List<api.Goal> buildUnnamed5342() {
  var o = <api.Goal>[];
  o.add(buildGoal());
  o.add(buildGoal());
  return o;
}

void checkUnnamed5342(core.List<api.Goal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoal(o[0] as api.Goal);
  checkGoal(o[1] as api.Goal);
}

core.int buildCounterGoals = 0;
api.Goals buildGoals() {
  var o = api.Goals();
  buildCounterGoals++;
  if (buildCounterGoals < 3) {
    o.items = buildUnnamed5342();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterGoals--;
  return o;
}

void checkGoals(api.Goals o) {
  buildCounterGoals++;
  if (buildCounterGoals < 3) {
    checkUnnamed5342(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoals--;
}

core.int buildCounterHashClientIdRequest = 0;
api.HashClientIdRequest buildHashClientIdRequest() {
  var o = api.HashClientIdRequest();
  buildCounterHashClientIdRequest++;
  if (buildCounterHashClientIdRequest < 3) {
    o.clientId = 'foo';
    o.kind = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterHashClientIdRequest--;
  return o;
}

void checkHashClientIdRequest(api.HashClientIdRequest o) {
  buildCounterHashClientIdRequest++;
  if (buildCounterHashClientIdRequest < 3) {
    unittest.expect(
      o.clientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterHashClientIdRequest--;
}

core.int buildCounterHashClientIdResponse = 0;
api.HashClientIdResponse buildHashClientIdResponse() {
  var o = api.HashClientIdResponse();
  buildCounterHashClientIdResponse++;
  if (buildCounterHashClientIdResponse < 3) {
    o.clientId = 'foo';
    o.hashedClientId = 'foo';
    o.kind = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterHashClientIdResponse--;
  return o;
}

void checkHashClientIdResponse(api.HashClientIdResponse o) {
  buildCounterHashClientIdResponse++;
  if (buildCounterHashClientIdResponse < 3) {
    unittest.expect(
      o.clientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hashedClientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterHashClientIdResponse--;
}

core.int buildCounterIncludeConditions = 0;
api.IncludeConditions buildIncludeConditions() {
  var o = api.IncludeConditions();
  buildCounterIncludeConditions++;
  if (buildCounterIncludeConditions < 3) {
    o.daysToLookBack = 42;
    o.isSmartList = true;
    o.kind = 'foo';
    o.membershipDurationDays = 42;
    o.segment = 'foo';
  }
  buildCounterIncludeConditions--;
  return o;
}

void checkIncludeConditions(api.IncludeConditions o) {
  buildCounterIncludeConditions++;
  if (buildCounterIncludeConditions < 3) {
    unittest.expect(
      o.daysToLookBack!,
      unittest.equals(42),
    );
    unittest.expect(o.isSmartList!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.membershipDurationDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.segment!,
      unittest.equals('foo'),
    );
  }
  buildCounterIncludeConditions--;
}

core.int buildCounterLinkedForeignAccount = 0;
api.LinkedForeignAccount buildLinkedForeignAccount() {
  var o = api.LinkedForeignAccount();
  buildCounterLinkedForeignAccount++;
  if (buildCounterLinkedForeignAccount < 3) {
    o.accountId = 'foo';
    o.eligibleForSearch = true;
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.linkedAccountId = 'foo';
    o.remarketingAudienceId = 'foo';
    o.status = 'foo';
    o.type = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterLinkedForeignAccount--;
  return o;
}

void checkLinkedForeignAccount(api.LinkedForeignAccount o) {
  buildCounterLinkedForeignAccount++;
  if (buildCounterLinkedForeignAccount < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.eligibleForSearch!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.linkedAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.remarketingAudienceId!,
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
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLinkedForeignAccount--;
}

core.int buildCounterMcfDataColumnHeaders = 0;
api.McfDataColumnHeaders buildMcfDataColumnHeaders() {
  var o = api.McfDataColumnHeaders();
  buildCounterMcfDataColumnHeaders++;
  if (buildCounterMcfDataColumnHeaders < 3) {
    o.columnType = 'foo';
    o.dataType = 'foo';
    o.name = 'foo';
  }
  buildCounterMcfDataColumnHeaders--;
  return o;
}

void checkMcfDataColumnHeaders(api.McfDataColumnHeaders o) {
  buildCounterMcfDataColumnHeaders++;
  if (buildCounterMcfDataColumnHeaders < 3) {
    unittest.expect(
      o.columnType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterMcfDataColumnHeaders--;
}

core.List<api.McfDataColumnHeaders> buildUnnamed5343() {
  var o = <api.McfDataColumnHeaders>[];
  o.add(buildMcfDataColumnHeaders());
  o.add(buildMcfDataColumnHeaders());
  return o;
}

void checkUnnamed5343(core.List<api.McfDataColumnHeaders> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMcfDataColumnHeaders(o[0] as api.McfDataColumnHeaders);
  checkMcfDataColumnHeaders(o[1] as api.McfDataColumnHeaders);
}

core.int buildCounterMcfDataProfileInfo = 0;
api.McfDataProfileInfo buildMcfDataProfileInfo() {
  var o = api.McfDataProfileInfo();
  buildCounterMcfDataProfileInfo++;
  if (buildCounterMcfDataProfileInfo < 3) {
    o.accountId = 'foo';
    o.internalWebPropertyId = 'foo';
    o.profileId = 'foo';
    o.profileName = 'foo';
    o.tableId = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterMcfDataProfileInfo--;
  return o;
}

void checkMcfDataProfileInfo(api.McfDataProfileInfo o) {
  buildCounterMcfDataProfileInfo++;
  if (buildCounterMcfDataProfileInfo < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterMcfDataProfileInfo--;
}

core.List<core.String> buildUnnamed5344() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5344(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5345() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5345(core.List<core.String> o) {
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

core.int buildCounterMcfDataQuery = 0;
api.McfDataQuery buildMcfDataQuery() {
  var o = api.McfDataQuery();
  buildCounterMcfDataQuery++;
  if (buildCounterMcfDataQuery < 3) {
    o.dimensions = 'foo';
    o.endDate = 'foo';
    o.filters = 'foo';
    o.ids = 'foo';
    o.maxResults = 42;
    o.metrics = buildUnnamed5344();
    o.samplingLevel = 'foo';
    o.segment = 'foo';
    o.sort = buildUnnamed5345();
    o.startDate = 'foo';
    o.startIndex = 42;
  }
  buildCounterMcfDataQuery--;
  return o;
}

void checkMcfDataQuery(api.McfDataQuery o) {
  buildCounterMcfDataQuery++;
  if (buildCounterMcfDataQuery < 3) {
    unittest.expect(
      o.dimensions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ids!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxResults!,
      unittest.equals(42),
    );
    checkUnnamed5344(o.metrics!);
    unittest.expect(
      o.samplingLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segment!,
      unittest.equals('foo'),
    );
    checkUnnamed5345(o.sort!);
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
  }
  buildCounterMcfDataQuery--;
}

core.int buildCounterMcfDataRowsConversionPathValue = 0;
api.McfDataRowsConversionPathValue buildMcfDataRowsConversionPathValue() {
  var o = api.McfDataRowsConversionPathValue();
  buildCounterMcfDataRowsConversionPathValue++;
  if (buildCounterMcfDataRowsConversionPathValue < 3) {
    o.interactionType = 'foo';
    o.nodeValue = 'foo';
  }
  buildCounterMcfDataRowsConversionPathValue--;
  return o;
}

void checkMcfDataRowsConversionPathValue(api.McfDataRowsConversionPathValue o) {
  buildCounterMcfDataRowsConversionPathValue++;
  if (buildCounterMcfDataRowsConversionPathValue < 3) {
    unittest.expect(
      o.interactionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nodeValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterMcfDataRowsConversionPathValue--;
}

core.List<api.McfDataRowsConversionPathValue> buildUnnamed5346() {
  var o = <api.McfDataRowsConversionPathValue>[];
  o.add(buildMcfDataRowsConversionPathValue());
  o.add(buildMcfDataRowsConversionPathValue());
  return o;
}

void checkUnnamed5346(core.List<api.McfDataRowsConversionPathValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMcfDataRowsConversionPathValue(
      o[0] as api.McfDataRowsConversionPathValue);
  checkMcfDataRowsConversionPathValue(
      o[1] as api.McfDataRowsConversionPathValue);
}

core.int buildCounterMcfDataRows = 0;
api.McfDataRows buildMcfDataRows() {
  var o = api.McfDataRows();
  buildCounterMcfDataRows++;
  if (buildCounterMcfDataRows < 3) {
    o.conversionPathValue = buildUnnamed5346();
    o.primitiveValue = 'foo';
  }
  buildCounterMcfDataRows--;
  return o;
}

void checkMcfDataRows(api.McfDataRows o) {
  buildCounterMcfDataRows++;
  if (buildCounterMcfDataRows < 3) {
    checkUnnamed5346(o.conversionPathValue!);
    unittest.expect(
      o.primitiveValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterMcfDataRows--;
}

core.List<api.McfDataRows> buildUnnamed5347() {
  var o = <api.McfDataRows>[];
  o.add(buildMcfDataRows());
  o.add(buildMcfDataRows());
  return o;
}

void checkUnnamed5347(core.List<api.McfDataRows> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMcfDataRows(o[0] as api.McfDataRows);
  checkMcfDataRows(o[1] as api.McfDataRows);
}

core.List<core.List<api.McfDataRows>> buildUnnamed5348() {
  var o = <core.List<api.McfDataRows>>[];
  o.add(buildUnnamed5347());
  o.add(buildUnnamed5347());
  return o;
}

void checkUnnamed5348(core.List<core.List<api.McfDataRows>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5347(o[0]);
  checkUnnamed5347(o[1]);
}

core.Map<core.String, core.String> buildUnnamed5349() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5349(core.Map<core.String, core.String> o) {
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

core.int buildCounterMcfData = 0;
api.McfData buildMcfData() {
  var o = api.McfData();
  buildCounterMcfData++;
  if (buildCounterMcfData < 3) {
    o.columnHeaders = buildUnnamed5343();
    o.containsSampledData = true;
    o.id = 'foo';
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.profileInfo = buildMcfDataProfileInfo();
    o.query = buildMcfDataQuery();
    o.rows = buildUnnamed5348();
    o.sampleSize = 'foo';
    o.sampleSpace = 'foo';
    o.selfLink = 'foo';
    o.totalResults = 42;
    o.totalsForAllResults = buildUnnamed5349();
  }
  buildCounterMcfData--;
  return o;
}

void checkMcfData(api.McfData o) {
  buildCounterMcfData++;
  if (buildCounterMcfData < 3) {
    checkUnnamed5343(o.columnHeaders!);
    unittest.expect(o.containsSampledData!, unittest.isTrue);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    checkMcfDataProfileInfo(o.profileInfo! as api.McfDataProfileInfo);
    checkMcfDataQuery(o.query! as api.McfDataQuery);
    checkUnnamed5348(o.rows!);
    unittest.expect(
      o.sampleSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sampleSpace!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    checkUnnamed5349(o.totalsForAllResults!);
  }
  buildCounterMcfData--;
}

core.int buildCounterProfileChildLink = 0;
api.ProfileChildLink buildProfileChildLink() {
  var o = api.ProfileChildLink();
  buildCounterProfileChildLink++;
  if (buildCounterProfileChildLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterProfileChildLink--;
  return o;
}

void checkProfileChildLink(api.ProfileChildLink o) {
  buildCounterProfileChildLink++;
  if (buildCounterProfileChildLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfileChildLink--;
}

core.int buildCounterProfileParentLink = 0;
api.ProfileParentLink buildProfileParentLink() {
  var o = api.ProfileParentLink();
  buildCounterProfileParentLink++;
  if (buildCounterProfileParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterProfileParentLink--;
  return o;
}

void checkProfileParentLink(api.ProfileParentLink o) {
  buildCounterProfileParentLink++;
  if (buildCounterProfileParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfileParentLink--;
}

core.List<core.String> buildUnnamed5350() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5350(core.List<core.String> o) {
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

core.int buildCounterProfilePermissions = 0;
api.ProfilePermissions buildProfilePermissions() {
  var o = api.ProfilePermissions();
  buildCounterProfilePermissions++;
  if (buildCounterProfilePermissions < 3) {
    o.effective = buildUnnamed5350();
  }
  buildCounterProfilePermissions--;
  return o;
}

void checkProfilePermissions(api.ProfilePermissions o) {
  buildCounterProfilePermissions++;
  if (buildCounterProfilePermissions < 3) {
    checkUnnamed5350(o.effective!);
  }
  buildCounterProfilePermissions--;
}

core.int buildCounterProfile = 0;
api.Profile buildProfile() {
  var o = api.Profile();
  buildCounterProfile++;
  if (buildCounterProfile < 3) {
    o.accountId = 'foo';
    o.botFilteringEnabled = true;
    o.childLink = buildProfileChildLink();
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.currency = 'foo';
    o.defaultPage = 'foo';
    o.eCommerceTracking = true;
    o.enhancedECommerceTracking = true;
    o.excludeQueryParameters = 'foo';
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.parentLink = buildProfileParentLink();
    o.permissions = buildProfilePermissions();
    o.selfLink = 'foo';
    o.siteSearchCategoryParameters = 'foo';
    o.siteSearchQueryParameters = 'foo';
    o.starred = true;
    o.stripSiteSearchCategoryParameters = true;
    o.stripSiteSearchQueryParameters = true;
    o.timezone = 'foo';
    o.type = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.webPropertyId = 'foo';
    o.websiteUrl = 'foo';
  }
  buildCounterProfile--;
  return o;
}

void checkProfile(api.Profile o) {
  buildCounterProfile++;
  if (buildCounterProfile < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.botFilteringEnabled!, unittest.isTrue);
    checkProfileChildLink(o.childLink! as api.ProfileChildLink);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.currency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultPage!,
      unittest.equals('foo'),
    );
    unittest.expect(o.eCommerceTracking!, unittest.isTrue);
    unittest.expect(o.enhancedECommerceTracking!, unittest.isTrue);
    unittest.expect(
      o.excludeQueryParameters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
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
    checkProfileParentLink(o.parentLink! as api.ProfileParentLink);
    checkProfilePermissions(o.permissions! as api.ProfilePermissions);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.siteSearchCategoryParameters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.siteSearchQueryParameters!,
      unittest.equals('foo'),
    );
    unittest.expect(o.starred!, unittest.isTrue);
    unittest.expect(o.stripSiteSearchCategoryParameters!, unittest.isTrue);
    unittest.expect(o.stripSiteSearchQueryParameters!, unittest.isTrue);
    unittest.expect(
      o.timezone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.websiteUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfile--;
}

core.int buildCounterProfileFilterLink = 0;
api.ProfileFilterLink buildProfileFilterLink() {
  var o = api.ProfileFilterLink();
  buildCounterProfileFilterLink++;
  if (buildCounterProfileFilterLink < 3) {
    o.filterRef = buildFilterRef();
    o.id = 'foo';
    o.kind = 'foo';
    o.profileRef = buildProfileRef();
    o.rank = 42;
    o.selfLink = 'foo';
  }
  buildCounterProfileFilterLink--;
  return o;
}

void checkProfileFilterLink(api.ProfileFilterLink o) {
  buildCounterProfileFilterLink++;
  if (buildCounterProfileFilterLink < 3) {
    checkFilterRef(o.filterRef! as api.FilterRef);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkProfileRef(o.profileRef! as api.ProfileRef);
    unittest.expect(
      o.rank!,
      unittest.equals(42),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfileFilterLink--;
}

core.List<api.ProfileFilterLink> buildUnnamed5351() {
  var o = <api.ProfileFilterLink>[];
  o.add(buildProfileFilterLink());
  o.add(buildProfileFilterLink());
  return o;
}

void checkUnnamed5351(core.List<api.ProfileFilterLink> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProfileFilterLink(o[0] as api.ProfileFilterLink);
  checkProfileFilterLink(o[1] as api.ProfileFilterLink);
}

core.int buildCounterProfileFilterLinks = 0;
api.ProfileFilterLinks buildProfileFilterLinks() {
  var o = api.ProfileFilterLinks();
  buildCounterProfileFilterLinks++;
  if (buildCounterProfileFilterLinks < 3) {
    o.items = buildUnnamed5351();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterProfileFilterLinks--;
  return o;
}

void checkProfileFilterLinks(api.ProfileFilterLinks o) {
  buildCounterProfileFilterLinks++;
  if (buildCounterProfileFilterLinks < 3) {
    checkUnnamed5351(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfileFilterLinks--;
}

core.int buildCounterProfileRef = 0;
api.ProfileRef buildProfileRef() {
  var o = api.ProfileRef();
  buildCounterProfileRef++;
  if (buildCounterProfileRef < 3) {
    o.accountId = 'foo';
    o.href = 'foo';
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterProfileRef--;
  return o;
}

void checkProfileRef(api.ProfileRef o) {
  buildCounterProfileRef++;
  if (buildCounterProfileRef < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
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
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfileRef--;
}

core.int buildCounterProfileSummary = 0;
api.ProfileSummary buildProfileSummary() {
  var o = api.ProfileSummary();
  buildCounterProfileSummary++;
  if (buildCounterProfileSummary < 3) {
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.starred = true;
    o.type = 'foo';
  }
  buildCounterProfileSummary--;
  return o;
}

void checkProfileSummary(api.ProfileSummary o) {
  buildCounterProfileSummary++;
  if (buildCounterProfileSummary < 3) {
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
    unittest.expect(o.starred!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfileSummary--;
}

core.List<api.Profile> buildUnnamed5352() {
  var o = <api.Profile>[];
  o.add(buildProfile());
  o.add(buildProfile());
  return o;
}

void checkUnnamed5352(core.List<api.Profile> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProfile(o[0] as api.Profile);
  checkProfile(o[1] as api.Profile);
}

core.int buildCounterProfiles = 0;
api.Profiles buildProfiles() {
  var o = api.Profiles();
  buildCounterProfiles++;
  if (buildCounterProfiles < 3) {
    o.items = buildUnnamed5352();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterProfiles--;
  return o;
}

void checkProfiles(api.Profiles o) {
  buildCounterProfiles++;
  if (buildCounterProfiles < 3) {
    checkUnnamed5352(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterProfiles--;
}

core.int buildCounterRealtimeDataColumnHeaders = 0;
api.RealtimeDataColumnHeaders buildRealtimeDataColumnHeaders() {
  var o = api.RealtimeDataColumnHeaders();
  buildCounterRealtimeDataColumnHeaders++;
  if (buildCounterRealtimeDataColumnHeaders < 3) {
    o.columnType = 'foo';
    o.dataType = 'foo';
    o.name = 'foo';
  }
  buildCounterRealtimeDataColumnHeaders--;
  return o;
}

void checkRealtimeDataColumnHeaders(api.RealtimeDataColumnHeaders o) {
  buildCounterRealtimeDataColumnHeaders++;
  if (buildCounterRealtimeDataColumnHeaders < 3) {
    unittest.expect(
      o.columnType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterRealtimeDataColumnHeaders--;
}

core.List<api.RealtimeDataColumnHeaders> buildUnnamed5353() {
  var o = <api.RealtimeDataColumnHeaders>[];
  o.add(buildRealtimeDataColumnHeaders());
  o.add(buildRealtimeDataColumnHeaders());
  return o;
}

void checkUnnamed5353(core.List<api.RealtimeDataColumnHeaders> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRealtimeDataColumnHeaders(o[0] as api.RealtimeDataColumnHeaders);
  checkRealtimeDataColumnHeaders(o[1] as api.RealtimeDataColumnHeaders);
}

core.int buildCounterRealtimeDataProfileInfo = 0;
api.RealtimeDataProfileInfo buildRealtimeDataProfileInfo() {
  var o = api.RealtimeDataProfileInfo();
  buildCounterRealtimeDataProfileInfo++;
  if (buildCounterRealtimeDataProfileInfo < 3) {
    o.accountId = 'foo';
    o.internalWebPropertyId = 'foo';
    o.profileId = 'foo';
    o.profileName = 'foo';
    o.tableId = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterRealtimeDataProfileInfo--;
  return o;
}

void checkRealtimeDataProfileInfo(api.RealtimeDataProfileInfo o) {
  buildCounterRealtimeDataProfileInfo++;
  if (buildCounterRealtimeDataProfileInfo < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRealtimeDataProfileInfo--;
}

core.List<core.String> buildUnnamed5354() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5354(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5355() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5355(core.List<core.String> o) {
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

core.int buildCounterRealtimeDataQuery = 0;
api.RealtimeDataQuery buildRealtimeDataQuery() {
  var o = api.RealtimeDataQuery();
  buildCounterRealtimeDataQuery++;
  if (buildCounterRealtimeDataQuery < 3) {
    o.dimensions = 'foo';
    o.filters = 'foo';
    o.ids = 'foo';
    o.maxResults = 42;
    o.metrics = buildUnnamed5354();
    o.sort = buildUnnamed5355();
  }
  buildCounterRealtimeDataQuery--;
  return o;
}

void checkRealtimeDataQuery(api.RealtimeDataQuery o) {
  buildCounterRealtimeDataQuery++;
  if (buildCounterRealtimeDataQuery < 3) {
    unittest.expect(
      o.dimensions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ids!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxResults!,
      unittest.equals(42),
    );
    checkUnnamed5354(o.metrics!);
    checkUnnamed5355(o.sort!);
  }
  buildCounterRealtimeDataQuery--;
}

core.List<core.String> buildUnnamed5356() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5356(core.List<core.String> o) {
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

core.List<core.List<core.String>> buildUnnamed5357() {
  var o = <core.List<core.String>>[];
  o.add(buildUnnamed5356());
  o.add(buildUnnamed5356());
  return o;
}

void checkUnnamed5357(core.List<core.List<core.String>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5356(o[0]);
  checkUnnamed5356(o[1]);
}

core.Map<core.String, core.String> buildUnnamed5358() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5358(core.Map<core.String, core.String> o) {
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

core.int buildCounterRealtimeData = 0;
api.RealtimeData buildRealtimeData() {
  var o = api.RealtimeData();
  buildCounterRealtimeData++;
  if (buildCounterRealtimeData < 3) {
    o.columnHeaders = buildUnnamed5353();
    o.id = 'foo';
    o.kind = 'foo';
    o.profileInfo = buildRealtimeDataProfileInfo();
    o.query = buildRealtimeDataQuery();
    o.rows = buildUnnamed5357();
    o.selfLink = 'foo';
    o.totalResults = 42;
    o.totalsForAllResults = buildUnnamed5358();
  }
  buildCounterRealtimeData--;
  return o;
}

void checkRealtimeData(api.RealtimeData o) {
  buildCounterRealtimeData++;
  if (buildCounterRealtimeData < 3) {
    checkUnnamed5353(o.columnHeaders!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkRealtimeDataProfileInfo(o.profileInfo! as api.RealtimeDataProfileInfo);
    checkRealtimeDataQuery(o.query! as api.RealtimeDataQuery);
    checkUnnamed5357(o.rows!);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    checkUnnamed5358(o.totalsForAllResults!);
  }
  buildCounterRealtimeData--;
}

core.int buildCounterRemarketingAudienceAudienceDefinition = 0;
api.RemarketingAudienceAudienceDefinition
    buildRemarketingAudienceAudienceDefinition() {
  var o = api.RemarketingAudienceAudienceDefinition();
  buildCounterRemarketingAudienceAudienceDefinition++;
  if (buildCounterRemarketingAudienceAudienceDefinition < 3) {
    o.includeConditions = buildIncludeConditions();
  }
  buildCounterRemarketingAudienceAudienceDefinition--;
  return o;
}

void checkRemarketingAudienceAudienceDefinition(
    api.RemarketingAudienceAudienceDefinition o) {
  buildCounterRemarketingAudienceAudienceDefinition++;
  if (buildCounterRemarketingAudienceAudienceDefinition < 3) {
    checkIncludeConditions(o.includeConditions! as api.IncludeConditions);
  }
  buildCounterRemarketingAudienceAudienceDefinition--;
}

core.List<api.LinkedForeignAccount> buildUnnamed5359() {
  var o = <api.LinkedForeignAccount>[];
  o.add(buildLinkedForeignAccount());
  o.add(buildLinkedForeignAccount());
  return o;
}

void checkUnnamed5359(core.List<api.LinkedForeignAccount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLinkedForeignAccount(o[0] as api.LinkedForeignAccount);
  checkLinkedForeignAccount(o[1] as api.LinkedForeignAccount);
}

core.List<core.String> buildUnnamed5360() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5360(core.List<core.String> o) {
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

core.int
    buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions =
    0;
api.RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions
    buildRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions() {
  var o =
      api.RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions();
  buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions++;
  if (buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions <
      3) {
    o.exclusionDuration = 'foo';
    o.segment = 'foo';
  }
  buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions--;
  return o;
}

void checkRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions(
    api.RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions o) {
  buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions++;
  if (buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions <
      3) {
    unittest.expect(
      o.exclusionDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segment!,
      unittest.equals('foo'),
    );
  }
  buildCounterRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions--;
}

core.int buildCounterRemarketingAudienceStateBasedAudienceDefinition = 0;
api.RemarketingAudienceStateBasedAudienceDefinition
    buildRemarketingAudienceStateBasedAudienceDefinition() {
  var o = api.RemarketingAudienceStateBasedAudienceDefinition();
  buildCounterRemarketingAudienceStateBasedAudienceDefinition++;
  if (buildCounterRemarketingAudienceStateBasedAudienceDefinition < 3) {
    o.excludeConditions =
        buildRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions();
    o.includeConditions = buildIncludeConditions();
  }
  buildCounterRemarketingAudienceStateBasedAudienceDefinition--;
  return o;
}

void checkRemarketingAudienceStateBasedAudienceDefinition(
    api.RemarketingAudienceStateBasedAudienceDefinition o) {
  buildCounterRemarketingAudienceStateBasedAudienceDefinition++;
  if (buildCounterRemarketingAudienceStateBasedAudienceDefinition < 3) {
    checkRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions(
        o.excludeConditions! as api
            .RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions);
    checkIncludeConditions(o.includeConditions! as api.IncludeConditions);
  }
  buildCounterRemarketingAudienceStateBasedAudienceDefinition--;
}

core.int buildCounterRemarketingAudience = 0;
api.RemarketingAudience buildRemarketingAudience() {
  var o = api.RemarketingAudience();
  buildCounterRemarketingAudience++;
  if (buildCounterRemarketingAudience < 3) {
    o.accountId = 'foo';
    o.audienceDefinition = buildRemarketingAudienceAudienceDefinition();
    o.audienceType = 'foo';
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.description = 'foo';
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.linkedAdAccounts = buildUnnamed5359();
    o.linkedViews = buildUnnamed5360();
    o.name = 'foo';
    o.stateBasedAudienceDefinition =
        buildRemarketingAudienceStateBasedAudienceDefinition();
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.webPropertyId = 'foo';
  }
  buildCounterRemarketingAudience--;
  return o;
}

void checkRemarketingAudience(api.RemarketingAudience o) {
  buildCounterRemarketingAudience++;
  if (buildCounterRemarketingAudience < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkRemarketingAudienceAudienceDefinition(
        o.audienceDefinition! as api.RemarketingAudienceAudienceDefinition);
    unittest.expect(
      o.audienceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed5359(o.linkedAdAccounts!);
    checkUnnamed5360(o.linkedViews!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkRemarketingAudienceStateBasedAudienceDefinition(
        o.stateBasedAudienceDefinition!
            as api.RemarketingAudienceStateBasedAudienceDefinition);
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRemarketingAudience--;
}

core.List<api.RemarketingAudience> buildUnnamed5361() {
  var o = <api.RemarketingAudience>[];
  o.add(buildRemarketingAudience());
  o.add(buildRemarketingAudience());
  return o;
}

void checkUnnamed5361(core.List<api.RemarketingAudience> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRemarketingAudience(o[0] as api.RemarketingAudience);
  checkRemarketingAudience(o[1] as api.RemarketingAudience);
}

core.int buildCounterRemarketingAudiences = 0;
api.RemarketingAudiences buildRemarketingAudiences() {
  var o = api.RemarketingAudiences();
  buildCounterRemarketingAudiences++;
  if (buildCounterRemarketingAudiences < 3) {
    o.items = buildUnnamed5361();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterRemarketingAudiences--;
  return o;
}

void checkRemarketingAudiences(api.RemarketingAudiences o) {
  buildCounterRemarketingAudiences++;
  if (buildCounterRemarketingAudiences < 3) {
    checkUnnamed5361(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterRemarketingAudiences--;
}

core.int buildCounterSegment = 0;
api.Segment buildSegment() {
  var o = api.Segment();
  buildCounterSegment++;
  if (buildCounterSegment < 3) {
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.definition = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.segmentId = 'foo';
    o.selfLink = 'foo';
    o.type = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterSegment--;
  return o;
}

void checkSegment(api.Segment o) {
  buildCounterSegment++;
  if (buildCounterSegment < 3) {
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.definition!,
      unittest.equals('foo'),
    );
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
    unittest.expect(
      o.segmentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterSegment--;
}

core.List<api.Segment> buildUnnamed5362() {
  var o = <api.Segment>[];
  o.add(buildSegment());
  o.add(buildSegment());
  return o;
}

void checkUnnamed5362(core.List<api.Segment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSegment(o[0] as api.Segment);
  checkSegment(o[1] as api.Segment);
}

core.int buildCounterSegments = 0;
api.Segments buildSegments() {
  var o = api.Segments();
  buildCounterSegments++;
  if (buildCounterSegments < 3) {
    o.items = buildUnnamed5362();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterSegments--;
  return o;
}

void checkSegments(api.Segments o) {
  buildCounterSegments++;
  if (buildCounterSegments < 3) {
    checkUnnamed5362(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterSegments--;
}

core.int buildCounterUnsampledReportCloudStorageDownloadDetails = 0;
api.UnsampledReportCloudStorageDownloadDetails
    buildUnsampledReportCloudStorageDownloadDetails() {
  var o = api.UnsampledReportCloudStorageDownloadDetails();
  buildCounterUnsampledReportCloudStorageDownloadDetails++;
  if (buildCounterUnsampledReportCloudStorageDownloadDetails < 3) {
    o.bucketId = 'foo';
    o.objectId = 'foo';
  }
  buildCounterUnsampledReportCloudStorageDownloadDetails--;
  return o;
}

void checkUnsampledReportCloudStorageDownloadDetails(
    api.UnsampledReportCloudStorageDownloadDetails o) {
  buildCounterUnsampledReportCloudStorageDownloadDetails++;
  if (buildCounterUnsampledReportCloudStorageDownloadDetails < 3) {
    unittest.expect(
      o.bucketId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnsampledReportCloudStorageDownloadDetails--;
}

core.int buildCounterUnsampledReportDriveDownloadDetails = 0;
api.UnsampledReportDriveDownloadDetails
    buildUnsampledReportDriveDownloadDetails() {
  var o = api.UnsampledReportDriveDownloadDetails();
  buildCounterUnsampledReportDriveDownloadDetails++;
  if (buildCounterUnsampledReportDriveDownloadDetails < 3) {
    o.documentId = 'foo';
  }
  buildCounterUnsampledReportDriveDownloadDetails--;
  return o;
}

void checkUnsampledReportDriveDownloadDetails(
    api.UnsampledReportDriveDownloadDetails o) {
  buildCounterUnsampledReportDriveDownloadDetails++;
  if (buildCounterUnsampledReportDriveDownloadDetails < 3) {
    unittest.expect(
      o.documentId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnsampledReportDriveDownloadDetails--;
}

core.int buildCounterUnsampledReport = 0;
api.UnsampledReport buildUnsampledReport() {
  var o = api.UnsampledReport();
  buildCounterUnsampledReport++;
  if (buildCounterUnsampledReport < 3) {
    o.accountId = 'foo';
    o.cloudStorageDownloadDetails =
        buildUnsampledReportCloudStorageDownloadDetails();
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.dimensions = 'foo';
    o.downloadType = 'foo';
    o.driveDownloadDetails = buildUnsampledReportDriveDownloadDetails();
    o.endDate = 'foo';
    o.filters = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.metrics = 'foo';
    o.profileId = 'foo';
    o.segment = 'foo';
    o.selfLink = 'foo';
    o.startDate = 'foo';
    o.status = 'foo';
    o.title = 'foo';
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.webPropertyId = 'foo';
  }
  buildCounterUnsampledReport--;
  return o;
}

void checkUnsampledReport(api.UnsampledReport o) {
  buildCounterUnsampledReport++;
  if (buildCounterUnsampledReport < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkUnsampledReportCloudStorageDownloadDetails(
        o.cloudStorageDownloadDetails!
            as api.UnsampledReportCloudStorageDownloadDetails);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.dimensions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.downloadType!,
      unittest.equals('foo'),
    );
    checkUnsampledReportDriveDownloadDetails(
        o.driveDownloadDetails! as api.UnsampledReportDriveDownloadDetails);
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.metrics!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.segment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnsampledReport--;
}

core.List<api.UnsampledReport> buildUnnamed5363() {
  var o = <api.UnsampledReport>[];
  o.add(buildUnsampledReport());
  o.add(buildUnsampledReport());
  return o;
}

void checkUnnamed5363(core.List<api.UnsampledReport> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnsampledReport(o[0] as api.UnsampledReport);
  checkUnsampledReport(o[1] as api.UnsampledReport);
}

core.int buildCounterUnsampledReports = 0;
api.UnsampledReports buildUnsampledReports() {
  var o = api.UnsampledReports();
  buildCounterUnsampledReports++;
  if (buildCounterUnsampledReports < 3) {
    o.items = buildUnnamed5363();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterUnsampledReports--;
  return o;
}

void checkUnsampledReports(api.UnsampledReports o) {
  buildCounterUnsampledReports++;
  if (buildCounterUnsampledReports < 3) {
    checkUnnamed5363(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnsampledReports--;
}

core.List<core.String> buildUnnamed5364() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5364(core.List<core.String> o) {
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

core.int buildCounterUpload = 0;
api.Upload buildUpload() {
  var o = api.Upload();
  buildCounterUpload++;
  if (buildCounterUpload < 3) {
    o.accountId = 'foo';
    o.customDataSourceId = 'foo';
    o.errors = buildUnnamed5364();
    o.id = 'foo';
    o.kind = 'foo';
    o.status = 'foo';
    o.uploadTime = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterUpload--;
  return o;
}

void checkUpload(api.Upload o) {
  buildCounterUpload++;
  if (buildCounterUpload < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customDataSourceId!,
      unittest.equals('foo'),
    );
    checkUnnamed5364(o.errors!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uploadTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterUpload--;
}

core.List<api.Upload> buildUnnamed5365() {
  var o = <api.Upload>[];
  o.add(buildUpload());
  o.add(buildUpload());
  return o;
}

void checkUnnamed5365(core.List<api.Upload> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUpload(o[0] as api.Upload);
  checkUpload(o[1] as api.Upload);
}

core.int buildCounterUploads = 0;
api.Uploads buildUploads() {
  var o = api.Uploads();
  buildCounterUploads++;
  if (buildCounterUploads < 3) {
    o.items = buildUnnamed5365();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
  }
  buildCounterUploads--;
  return o;
}

void checkUploads(api.Uploads o) {
  buildCounterUploads++;
  if (buildCounterUploads < 3) {
    checkUnnamed5365(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
  }
  buildCounterUploads--;
}

core.int buildCounterUserDeletionRequestId = 0;
api.UserDeletionRequestId buildUserDeletionRequestId() {
  var o = api.UserDeletionRequestId();
  buildCounterUserDeletionRequestId++;
  if (buildCounterUserDeletionRequestId < 3) {
    o.type = 'foo';
    o.userId = 'foo';
  }
  buildCounterUserDeletionRequestId--;
  return o;
}

void checkUserDeletionRequestId(api.UserDeletionRequestId o) {
  buildCounterUserDeletionRequestId++;
  if (buildCounterUserDeletionRequestId < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserDeletionRequestId--;
}

core.int buildCounterUserDeletionRequest = 0;
api.UserDeletionRequest buildUserDeletionRequest() {
  var o = api.UserDeletionRequest();
  buildCounterUserDeletionRequest++;
  if (buildCounterUserDeletionRequest < 3) {
    o.deletionRequestTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.firebaseProjectId = 'foo';
    o.id = buildUserDeletionRequestId();
    o.kind = 'foo';
    o.propertyId = 'foo';
    o.webPropertyId = 'foo';
  }
  buildCounterUserDeletionRequest--;
  return o;
}

void checkUserDeletionRequest(api.UserDeletionRequest o) {
  buildCounterUserDeletionRequest++;
  if (buildCounterUserDeletionRequest < 3) {
    unittest.expect(
      o.deletionRequestTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.firebaseProjectId!,
      unittest.equals('foo'),
    );
    checkUserDeletionRequestId(o.id! as api.UserDeletionRequestId);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.propertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserDeletionRequest--;
}

core.int buildCounterUserRef = 0;
api.UserRef buildUserRef() {
  var o = api.UserRef();
  buildCounterUserRef++;
  if (buildCounterUserRef < 3) {
    o.email = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
  }
  buildCounterUserRef--;
  return o;
}

void checkUserRef(api.UserRef o) {
  buildCounterUserRef++;
  if (buildCounterUserRef < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserRef--;
}

core.int buildCounterWebPropertyRef = 0;
api.WebPropertyRef buildWebPropertyRef() {
  var o = api.WebPropertyRef();
  buildCounterWebPropertyRef++;
  if (buildCounterWebPropertyRef < 3) {
    o.accountId = 'foo';
    o.href = 'foo';
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterWebPropertyRef--;
  return o;
}

void checkWebPropertyRef(api.WebPropertyRef o) {
  buildCounterWebPropertyRef++;
  if (buildCounterWebPropertyRef < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
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
  }
  buildCounterWebPropertyRef--;
}

core.List<api.ProfileSummary> buildUnnamed5366() {
  var o = <api.ProfileSummary>[];
  o.add(buildProfileSummary());
  o.add(buildProfileSummary());
  return o;
}

void checkUnnamed5366(core.List<api.ProfileSummary> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProfileSummary(o[0] as api.ProfileSummary);
  checkProfileSummary(o[1] as api.ProfileSummary);
}

core.int buildCounterWebPropertySummary = 0;
api.WebPropertySummary buildWebPropertySummary() {
  var o = api.WebPropertySummary();
  buildCounterWebPropertySummary++;
  if (buildCounterWebPropertySummary < 3) {
    o.id = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.level = 'foo';
    o.name = 'foo';
    o.profiles = buildUnnamed5366();
    o.starred = true;
    o.websiteUrl = 'foo';
  }
  buildCounterWebPropertySummary--;
  return o;
}

void checkWebPropertySummary(api.WebPropertySummary o) {
  buildCounterWebPropertySummary++;
  if (buildCounterWebPropertySummary < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.level!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5366(o.profiles!);
    unittest.expect(o.starred!, unittest.isTrue);
    unittest.expect(
      o.websiteUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterWebPropertySummary--;
}

core.List<api.Webproperty> buildUnnamed5367() {
  var o = <api.Webproperty>[];
  o.add(buildWebproperty());
  o.add(buildWebproperty());
  return o;
}

void checkUnnamed5367(core.List<api.Webproperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWebproperty(o[0] as api.Webproperty);
  checkWebproperty(o[1] as api.Webproperty);
}

core.int buildCounterWebproperties = 0;
api.Webproperties buildWebproperties() {
  var o = api.Webproperties();
  buildCounterWebproperties++;
  if (buildCounterWebproperties < 3) {
    o.items = buildUnnamed5367();
    o.itemsPerPage = 42;
    o.kind = 'foo';
    o.nextLink = 'foo';
    o.previousLink = 'foo';
    o.startIndex = 42;
    o.totalResults = 42;
    o.username = 'foo';
  }
  buildCounterWebproperties--;
  return o;
}

void checkWebproperties(api.Webproperties o) {
  buildCounterWebproperties++;
  if (buildCounterWebproperties < 3) {
    checkUnnamed5367(o.items!);
    unittest.expect(
      o.itemsPerPage!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.previousLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startIndex!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterWebproperties--;
}

core.int buildCounterWebpropertyChildLink = 0;
api.WebpropertyChildLink buildWebpropertyChildLink() {
  var o = api.WebpropertyChildLink();
  buildCounterWebpropertyChildLink++;
  if (buildCounterWebpropertyChildLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterWebpropertyChildLink--;
  return o;
}

void checkWebpropertyChildLink(api.WebpropertyChildLink o) {
  buildCounterWebpropertyChildLink++;
  if (buildCounterWebpropertyChildLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterWebpropertyChildLink--;
}

core.int buildCounterWebpropertyParentLink = 0;
api.WebpropertyParentLink buildWebpropertyParentLink() {
  var o = api.WebpropertyParentLink();
  buildCounterWebpropertyParentLink++;
  if (buildCounterWebpropertyParentLink < 3) {
    o.href = 'foo';
    o.type = 'foo';
  }
  buildCounterWebpropertyParentLink--;
  return o;
}

void checkWebpropertyParentLink(api.WebpropertyParentLink o) {
  buildCounterWebpropertyParentLink++;
  if (buildCounterWebpropertyParentLink < 3) {
    unittest.expect(
      o.href!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterWebpropertyParentLink--;
}

core.List<core.String> buildUnnamed5368() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5368(core.List<core.String> o) {
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

core.int buildCounterWebpropertyPermissions = 0;
api.WebpropertyPermissions buildWebpropertyPermissions() {
  var o = api.WebpropertyPermissions();
  buildCounterWebpropertyPermissions++;
  if (buildCounterWebpropertyPermissions < 3) {
    o.effective = buildUnnamed5368();
  }
  buildCounterWebpropertyPermissions--;
  return o;
}

void checkWebpropertyPermissions(api.WebpropertyPermissions o) {
  buildCounterWebpropertyPermissions++;
  if (buildCounterWebpropertyPermissions < 3) {
    checkUnnamed5368(o.effective!);
  }
  buildCounterWebpropertyPermissions--;
}

core.int buildCounterWebproperty = 0;
api.Webproperty buildWebproperty() {
  var o = api.Webproperty();
  buildCounterWebproperty++;
  if (buildCounterWebproperty < 3) {
    o.accountId = 'foo';
    o.childLink = buildWebpropertyChildLink();
    o.created = core.DateTime.parse("2002-02-27T14:01:02");
    o.dataRetentionResetOnNewActivity = true;
    o.dataRetentionTtl = 'foo';
    o.defaultProfileId = 'foo';
    o.id = 'foo';
    o.industryVertical = 'foo';
    o.internalWebPropertyId = 'foo';
    o.kind = 'foo';
    o.level = 'foo';
    o.name = 'foo';
    o.parentLink = buildWebpropertyParentLink();
    o.permissions = buildWebpropertyPermissions();
    o.profileCount = 42;
    o.selfLink = 'foo';
    o.starred = true;
    o.updated = core.DateTime.parse("2002-02-27T14:01:02");
    o.websiteUrl = 'foo';
  }
  buildCounterWebproperty--;
  return o;
}

void checkWebproperty(api.Webproperty o) {
  buildCounterWebproperty++;
  if (buildCounterWebproperty < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    checkWebpropertyChildLink(o.childLink! as api.WebpropertyChildLink);
    unittest.expect(
      o.created!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(o.dataRetentionResetOnNewActivity!, unittest.isTrue);
    unittest.expect(
      o.dataRetentionTtl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultProfileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.industryVertical!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalWebPropertyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.level!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkWebpropertyParentLink(o.parentLink! as api.WebpropertyParentLink);
    checkWebpropertyPermissions(o.permissions! as api.WebpropertyPermissions);
    unittest.expect(
      o.profileCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    unittest.expect(o.starred!, unittest.isTrue);
    unittest.expect(
      o.updated!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.websiteUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterWebproperty--;
}

void main() {
  unittest.group('obj-schema-AccountChildLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountChildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountChildLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountChildLink(od as api.AccountChildLink);
    });
  });

  unittest.group('obj-schema-AccountPermissions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountPermissions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountPermissions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountPermissions(od as api.AccountPermissions);
    });
  });

  unittest.group('obj-schema-Account', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Account.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAccount(od as api.Account);
    });
  });

  unittest.group('obj-schema-AccountRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AccountRef.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAccountRef(od as api.AccountRef);
    });
  });

  unittest.group('obj-schema-AccountSummaries', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountSummaries();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountSummaries.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountSummaries(od as api.AccountSummaries);
    });
  });

  unittest.group('obj-schema-AccountSummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountSummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountSummary(od as api.AccountSummary);
    });
  });

  unittest.group('obj-schema-AccountTicket', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountTicket();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountTicket.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountTicket(od as api.AccountTicket);
    });
  });

  unittest.group('obj-schema-AccountTreeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountTreeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountTreeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountTreeRequest(od as api.AccountTreeRequest);
    });
  });

  unittest.group('obj-schema-AccountTreeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountTreeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountTreeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountTreeResponse(od as api.AccountTreeResponse);
    });
  });

  unittest.group('obj-schema-Accounts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccounts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Accounts.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAccounts(od as api.Accounts);
    });
  });

  unittest.group('obj-schema-AdWordsAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdWordsAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdWordsAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdWordsAccount(od as api.AdWordsAccount);
    });
  });

  unittest.group('obj-schema-AnalyticsDataimportDeleteUploadDataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnalyticsDataimportDeleteUploadDataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AnalyticsDataimportDeleteUploadDataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAnalyticsDataimportDeleteUploadDataRequest(
          od as api.AnalyticsDataimportDeleteUploadDataRequest);
    });
  });

  unittest.group('obj-schema-Column', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColumn();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Column.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkColumn(od as api.Column);
    });
  });

  unittest.group('obj-schema-Columns', () {
    unittest.test('to-json--from-json', () async {
      var o = buildColumns();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Columns.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkColumns(od as api.Columns);
    });
  });

  unittest.group('obj-schema-CustomDataSourceChildLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDataSourceChildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDataSourceChildLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDataSourceChildLink(od as api.CustomDataSourceChildLink);
    });
  });

  unittest.group('obj-schema-CustomDataSourceParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDataSourceParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDataSourceParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDataSourceParentLink(od as api.CustomDataSourceParentLink);
    });
  });

  unittest.group('obj-schema-CustomDataSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDataSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDataSource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDataSource(od as api.CustomDataSource);
    });
  });

  unittest.group('obj-schema-CustomDataSources', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDataSources();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDataSources.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDataSources(od as api.CustomDataSources);
    });
  });

  unittest.group('obj-schema-CustomDimensionParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDimensionParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDimensionParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDimensionParentLink(od as api.CustomDimensionParentLink);
    });
  });

  unittest.group('obj-schema-CustomDimension', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDimension();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDimension.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDimension(od as api.CustomDimension);
    });
  });

  unittest.group('obj-schema-CustomDimensions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomDimensions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomDimensions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomDimensions(od as api.CustomDimensions);
    });
  });

  unittest.group('obj-schema-CustomMetricParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomMetricParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomMetricParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomMetricParentLink(od as api.CustomMetricParentLink);
    });
  });

  unittest.group('obj-schema-CustomMetric', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomMetric();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomMetric.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomMetric(od as api.CustomMetric);
    });
  });

  unittest.group('obj-schema-CustomMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomMetrics(od as api.CustomMetrics);
    });
  });

  unittest.group('obj-schema-EntityAdWordsLinkEntity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityAdWordsLinkEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityAdWordsLinkEntity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityAdWordsLinkEntity(od as api.EntityAdWordsLinkEntity);
    });
  });

  unittest.group('obj-schema-EntityAdWordsLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityAdWordsLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityAdWordsLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityAdWordsLink(od as api.EntityAdWordsLink);
    });
  });

  unittest.group('obj-schema-EntityAdWordsLinks', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityAdWordsLinks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityAdWordsLinks.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityAdWordsLinks(od as api.EntityAdWordsLinks);
    });
  });

  unittest.group('obj-schema-EntityUserLinkEntity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityUserLinkEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityUserLinkEntity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityUserLinkEntity(od as api.EntityUserLinkEntity);
    });
  });

  unittest.group('obj-schema-EntityUserLinkPermissions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityUserLinkPermissions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityUserLinkPermissions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityUserLinkPermissions(od as api.EntityUserLinkPermissions);
    });
  });

  unittest.group('obj-schema-EntityUserLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityUserLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityUserLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityUserLink(od as api.EntityUserLink);
    });
  });

  unittest.group('obj-schema-EntityUserLinks', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntityUserLinks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EntityUserLinks.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEntityUserLinks(od as api.EntityUserLinks);
    });
  });

  unittest.group('obj-schema-ExperimentParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExperimentParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExperimentParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExperimentParentLink(od as api.ExperimentParentLink);
    });
  });

  unittest.group('obj-schema-ExperimentVariations', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExperimentVariations();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExperimentVariations.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExperimentVariations(od as api.ExperimentVariations);
    });
  });

  unittest.group('obj-schema-Experiment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExperiment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Experiment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExperiment(od as api.Experiment);
    });
  });

  unittest.group('obj-schema-Experiments', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExperiments();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Experiments.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExperiments(od as api.Experiments);
    });
  });

  unittest.group('obj-schema-FilterAdvancedDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterAdvancedDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterAdvancedDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterAdvancedDetails(od as api.FilterAdvancedDetails);
    });
  });

  unittest.group('obj-schema-FilterLowercaseDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterLowercaseDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterLowercaseDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterLowercaseDetails(od as api.FilterLowercaseDetails);
    });
  });

  unittest.group('obj-schema-FilterParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterParentLink(od as api.FilterParentLink);
    });
  });

  unittest.group('obj-schema-FilterSearchAndReplaceDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterSearchAndReplaceDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterSearchAndReplaceDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterSearchAndReplaceDetails(
          od as api.FilterSearchAndReplaceDetails);
    });
  });

  unittest.group('obj-schema-FilterUppercaseDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterUppercaseDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterUppercaseDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterUppercaseDetails(od as api.FilterUppercaseDetails);
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

  unittest.group('obj-schema-FilterExpression', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterExpression();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterExpression.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterExpression(od as api.FilterExpression);
    });
  });

  unittest.group('obj-schema-FilterRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FilterRef.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilterRef(od as api.FilterRef);
    });
  });

  unittest.group('obj-schema-Filters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Filters.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilters(od as api.Filters);
    });
  });

  unittest.group('obj-schema-GaDataColumnHeaders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataColumnHeaders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataColumnHeaders.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataColumnHeaders(od as api.GaDataColumnHeaders);
    });
  });

  unittest.group('obj-schema-GaDataDataTableCols', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataDataTableCols();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataDataTableCols.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataDataTableCols(od as api.GaDataDataTableCols);
    });
  });

  unittest.group('obj-schema-GaDataDataTableRowsC', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataDataTableRowsC();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataDataTableRowsC.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataDataTableRowsC(od as api.GaDataDataTableRowsC);
    });
  });

  unittest.group('obj-schema-GaDataDataTableRows', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataDataTableRows();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataDataTableRows.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataDataTableRows(od as api.GaDataDataTableRows);
    });
  });

  unittest.group('obj-schema-GaDataDataTable', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataDataTable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataDataTable.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataDataTable(od as api.GaDataDataTable);
    });
  });

  unittest.group('obj-schema-GaDataProfileInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataProfileInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataProfileInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataProfileInfo(od as api.GaDataProfileInfo);
    });
  });

  unittest.group('obj-schema-GaDataQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaDataQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GaDataQuery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGaDataQuery(od as api.GaDataQuery);
    });
  });

  unittest.group('obj-schema-GaData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGaData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GaData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGaData(od as api.GaData);
    });
  });

  unittest.group('obj-schema-GoalEventDetailsEventConditions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalEventDetailsEventConditions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalEventDetailsEventConditions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalEventDetailsEventConditions(
          od as api.GoalEventDetailsEventConditions);
    });
  });

  unittest.group('obj-schema-GoalEventDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalEventDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalEventDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalEventDetails(od as api.GoalEventDetails);
    });
  });

  unittest.group('obj-schema-GoalParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalParentLink(od as api.GoalParentLink);
    });
  });

  unittest.group('obj-schema-GoalUrlDestinationDetailsSteps', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalUrlDestinationDetailsSteps();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalUrlDestinationDetailsSteps.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalUrlDestinationDetailsSteps(
          od as api.GoalUrlDestinationDetailsSteps);
    });
  });

  unittest.group('obj-schema-GoalUrlDestinationDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalUrlDestinationDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalUrlDestinationDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalUrlDestinationDetails(od as api.GoalUrlDestinationDetails);
    });
  });

  unittest.group('obj-schema-GoalVisitNumPagesDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalVisitNumPagesDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalVisitNumPagesDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalVisitNumPagesDetails(od as api.GoalVisitNumPagesDetails);
    });
  });

  unittest.group('obj-schema-GoalVisitTimeOnSiteDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoalVisitTimeOnSiteDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoalVisitTimeOnSiteDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoalVisitTimeOnSiteDetails(od as api.GoalVisitTimeOnSiteDetails);
    });
  });

  unittest.group('obj-schema-Goal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Goal.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoal(od as api.Goal);
    });
  });

  unittest.group('obj-schema-Goals', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoals();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Goals.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoals(od as api.Goals);
    });
  });

  unittest.group('obj-schema-HashClientIdRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHashClientIdRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HashClientIdRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHashClientIdRequest(od as api.HashClientIdRequest);
    });
  });

  unittest.group('obj-schema-HashClientIdResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHashClientIdResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HashClientIdResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHashClientIdResponse(od as api.HashClientIdResponse);
    });
  });

  unittest.group('obj-schema-IncludeConditions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIncludeConditions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IncludeConditions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIncludeConditions(od as api.IncludeConditions);
    });
  });

  unittest.group('obj-schema-LinkedForeignAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLinkedForeignAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LinkedForeignAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLinkedForeignAccount(od as api.LinkedForeignAccount);
    });
  });

  unittest.group('obj-schema-McfDataColumnHeaders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMcfDataColumnHeaders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.McfDataColumnHeaders.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMcfDataColumnHeaders(od as api.McfDataColumnHeaders);
    });
  });

  unittest.group('obj-schema-McfDataProfileInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMcfDataProfileInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.McfDataProfileInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMcfDataProfileInfo(od as api.McfDataProfileInfo);
    });
  });

  unittest.group('obj-schema-McfDataQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMcfDataQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.McfDataQuery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMcfDataQuery(od as api.McfDataQuery);
    });
  });

  unittest.group('obj-schema-McfDataRowsConversionPathValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMcfDataRowsConversionPathValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.McfDataRowsConversionPathValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMcfDataRowsConversionPathValue(
          od as api.McfDataRowsConversionPathValue);
    });
  });

  unittest.group('obj-schema-McfDataRows', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMcfDataRows();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.McfDataRows.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMcfDataRows(od as api.McfDataRows);
    });
  });

  unittest.group('obj-schema-McfData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMcfData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.McfData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMcfData(od as api.McfData);
    });
  });

  unittest.group('obj-schema-ProfileChildLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileChildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileChildLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileChildLink(od as api.ProfileChildLink);
    });
  });

  unittest.group('obj-schema-ProfileParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileParentLink(od as api.ProfileParentLink);
    });
  });

  unittest.group('obj-schema-ProfilePermissions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfilePermissions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfilePermissions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfilePermissions(od as api.ProfilePermissions);
    });
  });

  unittest.group('obj-schema-Profile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Profile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProfile(od as api.Profile);
    });
  });

  unittest.group('obj-schema-ProfileFilterLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileFilterLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileFilterLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileFilterLink(od as api.ProfileFilterLink);
    });
  });

  unittest.group('obj-schema-ProfileFilterLinks', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileFilterLinks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileFilterLinks.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileFilterLinks(od as api.ProfileFilterLinks);
    });
  });

  unittest.group('obj-schema-ProfileRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ProfileRef.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProfileRef(od as api.ProfileRef);
    });
  });

  unittest.group('obj-schema-ProfileSummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileSummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileSummary(od as api.ProfileSummary);
    });
  });

  unittest.group('obj-schema-Profiles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfiles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Profiles.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProfiles(od as api.Profiles);
    });
  });

  unittest.group('obj-schema-RealtimeDataColumnHeaders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRealtimeDataColumnHeaders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RealtimeDataColumnHeaders.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRealtimeDataColumnHeaders(od as api.RealtimeDataColumnHeaders);
    });
  });

  unittest.group('obj-schema-RealtimeDataProfileInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRealtimeDataProfileInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RealtimeDataProfileInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRealtimeDataProfileInfo(od as api.RealtimeDataProfileInfo);
    });
  });

  unittest.group('obj-schema-RealtimeDataQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRealtimeDataQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RealtimeDataQuery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRealtimeDataQuery(od as api.RealtimeDataQuery);
    });
  });

  unittest.group('obj-schema-RealtimeData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRealtimeData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RealtimeData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRealtimeData(od as api.RealtimeData);
    });
  });

  unittest.group('obj-schema-RemarketingAudienceAudienceDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRemarketingAudienceAudienceDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RemarketingAudienceAudienceDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRemarketingAudienceAudienceDefinition(
          od as api.RemarketingAudienceAudienceDefinition);
    });
  });

  unittest.group(
      'obj-schema-RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRemarketingAudienceStateBasedAudienceDefinitionExcludeConditions(od
          as api
              .RemarketingAudienceStateBasedAudienceDefinitionExcludeConditions);
    });
  });

  unittest.group('obj-schema-RemarketingAudienceStateBasedAudienceDefinition',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildRemarketingAudienceStateBasedAudienceDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RemarketingAudienceStateBasedAudienceDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRemarketingAudienceStateBasedAudienceDefinition(
          od as api.RemarketingAudienceStateBasedAudienceDefinition);
    });
  });

  unittest.group('obj-schema-RemarketingAudience', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRemarketingAudience();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RemarketingAudience.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRemarketingAudience(od as api.RemarketingAudience);
    });
  });

  unittest.group('obj-schema-RemarketingAudiences', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRemarketingAudiences();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RemarketingAudiences.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRemarketingAudiences(od as api.RemarketingAudiences);
    });
  });

  unittest.group('obj-schema-Segment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Segment.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSegment(od as api.Segment);
    });
  });

  unittest.group('obj-schema-Segments', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSegments();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Segments.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSegments(od as api.Segments);
    });
  });

  unittest.group('obj-schema-UnsampledReportCloudStorageDownloadDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnsampledReportCloudStorageDownloadDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnsampledReportCloudStorageDownloadDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnsampledReportCloudStorageDownloadDetails(
          od as api.UnsampledReportCloudStorageDownloadDetails);
    });
  });

  unittest.group('obj-schema-UnsampledReportDriveDownloadDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnsampledReportDriveDownloadDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnsampledReportDriveDownloadDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnsampledReportDriveDownloadDetails(
          od as api.UnsampledReportDriveDownloadDetails);
    });
  });

  unittest.group('obj-schema-UnsampledReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnsampledReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnsampledReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnsampledReport(od as api.UnsampledReport);
    });
  });

  unittest.group('obj-schema-UnsampledReports', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnsampledReports();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnsampledReports.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnsampledReports(od as api.UnsampledReports);
    });
  });

  unittest.group('obj-schema-Upload', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpload();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Upload.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUpload(od as api.Upload);
    });
  });

  unittest.group('obj-schema-Uploads', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUploads();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Uploads.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUploads(od as api.Uploads);
    });
  });

  unittest.group('obj-schema-UserDeletionRequestId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserDeletionRequestId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserDeletionRequestId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserDeletionRequestId(od as api.UserDeletionRequestId);
    });
  });

  unittest.group('obj-schema-UserDeletionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserDeletionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserDeletionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserDeletionRequest(od as api.UserDeletionRequest);
    });
  });

  unittest.group('obj-schema-UserRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserRef.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserRef(od as api.UserRef);
    });
  });

  unittest.group('obj-schema-WebPropertyRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebPropertyRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebPropertyRef.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebPropertyRef(od as api.WebPropertyRef);
    });
  });

  unittest.group('obj-schema-WebPropertySummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebPropertySummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebPropertySummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebPropertySummary(od as api.WebPropertySummary);
    });
  });

  unittest.group('obj-schema-Webproperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebproperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Webproperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebproperties(od as api.Webproperties);
    });
  });

  unittest.group('obj-schema-WebpropertyChildLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebpropertyChildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebpropertyChildLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebpropertyChildLink(od as api.WebpropertyChildLink);
    });
  });

  unittest.group('obj-schema-WebpropertyParentLink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebpropertyParentLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebpropertyParentLink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebpropertyParentLink(od as api.WebpropertyParentLink);
    });
  });

  unittest.group('obj-schema-WebpropertyPermissions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebpropertyPermissions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WebpropertyPermissions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebpropertyPermissions(od as api.WebpropertyPermissions);
    });
  });

  unittest.group('obj-schema-Webproperty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWebproperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Webproperty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWebproperty(od as api.Webproperty);
    });
  });

  unittest.group('resource-DataGaResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).data.ga;
      var arg_ids = 'foo';
      var arg_startDate = 'foo';
      var arg_endDate = 'foo';
      var arg_metrics = 'foo';
      var arg_dimensions = 'foo';
      var arg_filters = 'foo';
      var arg_includeEmptyRows = true;
      var arg_maxResults = 42;
      var arg_output = 'foo';
      var arg_samplingLevel = 'foo';
      var arg_segment = 'foo';
      var arg_sort = 'foo';
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("data/ga"),
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
          queryMap["ids"]!.first,
          unittest.equals(arg_ids),
        );
        unittest.expect(
          queryMap["start-date"]!.first,
          unittest.equals(arg_startDate),
        );
        unittest.expect(
          queryMap["end-date"]!.first,
          unittest.equals(arg_endDate),
        );
        unittest.expect(
          queryMap["metrics"]!.first,
          unittest.equals(arg_metrics),
        );
        unittest.expect(
          queryMap["dimensions"]!.first,
          unittest.equals(arg_dimensions),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          queryMap["include-empty-rows"]!.first,
          unittest.equals("$arg_includeEmptyRows"),
        );
        unittest.expect(
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["output"]!.first,
          unittest.equals(arg_output),
        );
        unittest.expect(
          queryMap["samplingLevel"]!.first,
          unittest.equals(arg_samplingLevel),
        );
        unittest.expect(
          queryMap["segment"]!.first,
          unittest.equals(arg_segment),
        );
        unittest.expect(
          queryMap["sort"]!.first,
          unittest.equals(arg_sort),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGaData());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_ids, arg_startDate, arg_endDate, arg_metrics,
          dimensions: arg_dimensions,
          filters: arg_filters,
          includeEmptyRows: arg_includeEmptyRows,
          maxResults: arg_maxResults,
          output: arg_output,
          samplingLevel: arg_samplingLevel,
          segment: arg_segment,
          sort: arg_sort,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkGaData(response as api.GaData);
    });
  });

  unittest.group('resource-DataMcfResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).data.mcf;
      var arg_ids = 'foo';
      var arg_startDate = 'foo';
      var arg_endDate = 'foo';
      var arg_metrics = 'foo';
      var arg_dimensions = 'foo';
      var arg_filters = 'foo';
      var arg_maxResults = 42;
      var arg_samplingLevel = 'foo';
      var arg_sort = 'foo';
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("data/mcf"),
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
          queryMap["ids"]!.first,
          unittest.equals(arg_ids),
        );
        unittest.expect(
          queryMap["start-date"]!.first,
          unittest.equals(arg_startDate),
        );
        unittest.expect(
          queryMap["end-date"]!.first,
          unittest.equals(arg_endDate),
        );
        unittest.expect(
          queryMap["metrics"]!.first,
          unittest.equals(arg_metrics),
        );
        unittest.expect(
          queryMap["dimensions"]!.first,
          unittest.equals(arg_dimensions),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["samplingLevel"]!.first,
          unittest.equals(arg_samplingLevel),
        );
        unittest.expect(
          queryMap["sort"]!.first,
          unittest.equals(arg_sort),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMcfData());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_ids, arg_startDate, arg_endDate, arg_metrics,
          dimensions: arg_dimensions,
          filters: arg_filters,
          maxResults: arg_maxResults,
          samplingLevel: arg_samplingLevel,
          sort: arg_sort,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkMcfData(response as api.McfData);
    });
  });

  unittest.group('resource-DataRealtimeResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).data.realtime;
      var arg_ids = 'foo';
      var arg_metrics = 'foo';
      var arg_dimensions = 'foo';
      var arg_filters = 'foo';
      var arg_maxResults = 42;
      var arg_sort = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("data/realtime"),
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
          queryMap["ids"]!.first,
          unittest.equals(arg_ids),
        );
        unittest.expect(
          queryMap["metrics"]!.first,
          unittest.equals(arg_metrics),
        );
        unittest.expect(
          queryMap["dimensions"]!.first,
          unittest.equals(arg_dimensions),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["sort"]!.first,
          unittest.equals(arg_sort),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRealtimeData());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_ids, arg_metrics,
          dimensions: arg_dimensions,
          filters: arg_filters,
          maxResults: arg_maxResults,
          sort: arg_sort,
          $fields: arg_$fields);
      checkRealtimeData(response as api.RealtimeData);
    });
  });

  unittest.group('resource-ManagementAccountSummariesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.accountSummaries;
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("management/accountSummaries"),
        );
        pathOffset += 27;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAccountSummaries());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkAccountSummaries(response as api.AccountSummaries);
    });
  });

  unittest.group('resource-ManagementAccountUserLinksResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.accountUserLinks;
      var arg_accountId = 'foo';
      var arg_linkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/entityUserLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/entityUserLinks/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_accountId, arg_linkId, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.accountUserLinks;
      var arg_request = buildEntityUserLink();
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityUserLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityUserLink(obj as api.EntityUserLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/entityUserLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/entityUserLinks"),
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
        var resp = convert.json.encode(buildEntityUserLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_accountId, $fields: arg_$fields);
      checkEntityUserLink(response as api.EntityUserLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.accountUserLinks;
      var arg_accountId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/entityUserLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/entityUserLinks"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEntityUserLinks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkEntityUserLinks(response as api.EntityUserLinks);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.accountUserLinks;
      var arg_request = buildEntityUserLink();
      var arg_accountId = 'foo';
      var arg_linkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityUserLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityUserLink(obj as api.EntityUserLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/entityUserLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/entityUserLinks/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = convert.json.encode(buildEntityUserLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId, arg_linkId,
          $fields: arg_$fields);
      checkEntityUserLink(response as api.EntityUserLink);
    });
  });

  unittest.group('resource-ManagementAccountsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.accounts;
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("management/accounts"),
        );
        pathOffset += 19;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAccounts());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkAccounts(response as api.Accounts);
    });
  });

  unittest.group('resource-ManagementClientIdResource', () {
    unittest.test('method--hashClientId', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.clientId;
      var arg_request = buildHashClientIdRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.HashClientIdRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkHashClientIdRequest(obj as api.HashClientIdRequest);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("management/clientId:hashClientId"),
        );
        pathOffset += 32;

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
        var resp = convert.json.encode(buildHashClientIdResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.hashClientId(arg_request, $fields: arg_$fields);
      checkHashClientIdResponse(response as api.HashClientIdResponse);
    });
  });

  unittest.group('resource-ManagementCustomDataSourcesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customDataSources;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDataSources', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/customDataSources"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomDataSources());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkCustomDataSources(response as api.CustomDataSources);
    });
  });

  unittest.group('resource-ManagementCustomDimensionsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customDimensions;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDimensionId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDimensions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/customDimensions/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDimensionId'),
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
        var resp = convert.json.encode(buildCustomDimension());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_customDimensionId,
          $fields: arg_$fields);
      checkCustomDimension(response as api.CustomDimension);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customDimensions;
      var arg_request = buildCustomDimension();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomDimension.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomDimension(obj as api.CustomDimension);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDimensions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/customDimensions"),
        );
        pathOffset += 17;

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
        var resp = convert.json.encode(buildCustomDimension());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkCustomDimension(response as api.CustomDimension);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customDimensions;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDimensions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/customDimensions"),
        );
        pathOffset += 17;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomDimensions());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkCustomDimensions(response as api.CustomDimensions);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customDimensions;
      var arg_request = buildCustomDimension();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDimensionId = 'foo';
      var arg_ignoreCustomDataSourceLinks = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomDimension.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomDimension(obj as api.CustomDimension);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDimensions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/customDimensions/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDimensionId'),
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
          queryMap["ignoreCustomDataSourceLinks"]!.first,
          unittest.equals("$arg_ignoreCustomDataSourceLinks"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomDimension());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_accountId, arg_webPropertyId, arg_customDimensionId,
          ignoreCustomDataSourceLinks: arg_ignoreCustomDataSourceLinks,
          $fields: arg_$fields);
      checkCustomDimension(response as api.CustomDimension);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customDimensions;
      var arg_request = buildCustomDimension();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDimensionId = 'foo';
      var arg_ignoreCustomDataSourceLinks = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomDimension.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomDimension(obj as api.CustomDimension);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDimensions/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/customDimensions/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDimensionId'),
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
          queryMap["ignoreCustomDataSourceLinks"]!.first,
          unittest.equals("$arg_ignoreCustomDataSourceLinks"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomDimension());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_webPropertyId, arg_customDimensionId,
          ignoreCustomDataSourceLinks: arg_ignoreCustomDataSourceLinks,
          $fields: arg_$fields);
      checkCustomDimension(response as api.CustomDimension);
    });
  });

  unittest.group('resource-ManagementCustomMetricsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customMetrics;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customMetricId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customMetrics/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customMetrics/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customMetricId'),
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
        var resp = convert.json.encode(buildCustomMetric());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_customMetricId,
          $fields: arg_$fields);
      checkCustomMetric(response as api.CustomMetric);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customMetrics;
      var arg_request = buildCustomMetric();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomMetric.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomMetric(obj as api.CustomMetric);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customMetrics', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/customMetrics"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomMetric());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkCustomMetric(response as api.CustomMetric);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customMetrics;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customMetrics', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/customMetrics"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomMetrics());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkCustomMetrics(response as api.CustomMetrics);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customMetrics;
      var arg_request = buildCustomMetric();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customMetricId = 'foo';
      var arg_ignoreCustomDataSourceLinks = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomMetric.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomMetric(obj as api.CustomMetric);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customMetrics/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customMetrics/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customMetricId'),
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
          queryMap["ignoreCustomDataSourceLinks"]!.first,
          unittest.equals("$arg_ignoreCustomDataSourceLinks"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomMetric());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_accountId, arg_webPropertyId, arg_customMetricId,
          ignoreCustomDataSourceLinks: arg_ignoreCustomDataSourceLinks,
          $fields: arg_$fields);
      checkCustomMetric(response as api.CustomMetric);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.customMetrics;
      var arg_request = buildCustomMetric();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customMetricId = 'foo';
      var arg_ignoreCustomDataSourceLinks = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomMetric.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomMetric(obj as api.CustomMetric);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customMetrics/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/customMetrics/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customMetricId'),
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
          queryMap["ignoreCustomDataSourceLinks"]!.first,
          unittest.equals("$arg_ignoreCustomDataSourceLinks"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomMetric());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_webPropertyId, arg_customMetricId,
          ignoreCustomDataSourceLinks: arg_ignoreCustomDataSourceLinks,
          $fields: arg_$fields);
      checkCustomMetric(response as api.CustomMetric);
    });
  });

  unittest.group('resource-ManagementExperimentsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.experiments;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_experimentId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/experiments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/experiments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_experimentId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(
          arg_accountId, arg_webPropertyId, arg_profileId, arg_experimentId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.experiments;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_experimentId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/experiments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/experiments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_experimentId'),
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
        var resp = convert.json.encode(buildExperiment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_profileId, arg_experimentId,
          $fields: arg_$fields);
      checkExperiment(response as api.Experiment);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.experiments;
      var arg_request = buildExperiment();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Experiment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExperiment(obj as api.Experiment);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/experiments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/experiments"),
        );
        pathOffset += 12;

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
        var resp = convert.json.encode(buildExperiment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkExperiment(response as api.Experiment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.experiments;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/experiments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/experiments"),
        );
        pathOffset += 12;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildExperiments());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_webPropertyId, arg_profileId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkExperiments(response as api.Experiments);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.experiments;
      var arg_request = buildExperiment();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_experimentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Experiment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExperiment(obj as api.Experiment);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/experiments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/experiments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_experimentId'),
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
        var resp = convert.json.encode(buildExperiment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_experimentId,
          $fields: arg_$fields);
      checkExperiment(response as api.Experiment);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.experiments;
      var arg_request = buildExperiment();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_experimentId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Experiment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkExperiment(obj as api.Experiment);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/experiments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/experiments/"),
        );
        pathOffset += 13;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_experimentId'),
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
        var resp = convert.json.encode(buildExperiment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_experimentId,
          $fields: arg_$fields);
      checkExperiment(response as api.Experiment);
    });
  });

  unittest.group('resource-ManagementFiltersResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.filters;
      var arg_accountId = 'foo';
      var arg_filterId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/filters/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/filters/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_filterId'),
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
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_accountId, arg_filterId, $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.filters;
      var arg_accountId = 'foo';
      var arg_filterId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/filters/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/filters/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_filterId'),
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
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_accountId, arg_filterId, $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.filters;
      var arg_request = buildFilter();
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Filter.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFilter(obj as api.Filter);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/filters', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/filters"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_accountId, $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.filters;
      var arg_accountId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/filters', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/filters"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFilters());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkFilters(response as api.Filters);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.filters;
      var arg_request = buildFilter();
      var arg_accountId = 'foo';
      var arg_filterId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Filter.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFilter(obj as api.Filter);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/filters/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/filters/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_filterId'),
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
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId, arg_filterId,
          $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.filters;
      var arg_request = buildFilter();
      var arg_accountId = 'foo';
      var arg_filterId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Filter.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFilter(obj as api.Filter);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/filters/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/filters/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_filterId'),
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
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_filterId,
          $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });
  });

  unittest.group('resource-ManagementGoalsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.goals;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_goalId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/goals/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/goals/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_goalId'),
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
        var resp = convert.json.encode(buildGoal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_profileId, arg_goalId,
          $fields: arg_$fields);
      checkGoal(response as api.Goal);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.goals;
      var arg_request = buildGoal();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Goal.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGoal(obj as api.Goal);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/goals', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/goals"),
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
        var resp = convert.json.encode(buildGoal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkGoal(response as api.Goal);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.goals;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/goals', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/goals"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoals());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_webPropertyId, arg_profileId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkGoals(response as api.Goals);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.goals;
      var arg_request = buildGoal();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_goalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Goal.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGoal(obj as api.Goal);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/goals/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/goals/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_goalId'),
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
        var resp = convert.json.encode(buildGoal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_goalId,
          $fields: arg_$fields);
      checkGoal(response as api.Goal);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.goals;
      var arg_request = buildGoal();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_goalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Goal.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGoal(obj as api.Goal);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/goals/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/goals/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_goalId'),
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
        var resp = convert.json.encode(buildGoal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_goalId,
          $fields: arg_$fields);
      checkGoal(response as api.Goal);
    });
  });

  unittest.group('resource-ManagementProfileFilterLinksResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileFilterLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_linkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profileFilterLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/profileFilterLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(
          arg_accountId, arg_webPropertyId, arg_profileId, arg_linkId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileFilterLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_linkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profileFilterLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/profileFilterLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = convert.json.encode(buildProfileFilterLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_profileId, arg_linkId,
          $fields: arg_$fields);
      checkProfileFilterLink(response as api.ProfileFilterLink);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileFilterLinks;
      var arg_request = buildProfileFilterLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ProfileFilterLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkProfileFilterLink(obj as api.ProfileFilterLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profileFilterLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/profileFilterLinks"),
        );
        pathOffset += 19;

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
        var resp = convert.json.encode(buildProfileFilterLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkProfileFilterLink(response as api.ProfileFilterLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileFilterLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profileFilterLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/profileFilterLinks"),
        );
        pathOffset += 19;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildProfileFilterLinks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_webPropertyId, arg_profileId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkProfileFilterLinks(response as api.ProfileFilterLinks);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileFilterLinks;
      var arg_request = buildProfileFilterLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_linkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ProfileFilterLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkProfileFilterLink(obj as api.ProfileFilterLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profileFilterLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/profileFilterLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = convert.json.encode(buildProfileFilterLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_linkId,
          $fields: arg_$fields);
      checkProfileFilterLink(response as api.ProfileFilterLink);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileFilterLinks;
      var arg_request = buildProfileFilterLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_linkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ProfileFilterLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkProfileFilterLink(obj as api.ProfileFilterLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profileFilterLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/profileFilterLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = convert.json.encode(buildProfileFilterLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_linkId,
          $fields: arg_$fields);
      checkProfileFilterLink(response as api.ProfileFilterLink);
    });
  });

  unittest.group('resource-ManagementProfileUserLinksResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileUserLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_linkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/entityUserLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/entityUserLinks/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(
          arg_accountId, arg_webPropertyId, arg_profileId, arg_linkId,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileUserLinks;
      var arg_request = buildEntityUserLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityUserLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityUserLink(obj as api.EntityUserLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/entityUserLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/entityUserLinks"),
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
        var resp = convert.json.encode(buildEntityUserLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkEntityUserLink(response as api.EntityUserLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileUserLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/entityUserLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/entityUserLinks"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEntityUserLinks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_webPropertyId, arg_profileId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkEntityUserLinks(response as api.EntityUserLinks);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profileUserLinks;
      var arg_request = buildEntityUserLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_linkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityUserLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityUserLink(obj as api.EntityUserLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/entityUserLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/entityUserLinks/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = convert.json.encode(buildEntityUserLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId,
          arg_webPropertyId, arg_profileId, arg_linkId,
          $fields: arg_$fields);
      checkEntityUserLink(response as api.EntityUserLink);
    });
  });

  unittest.group('resource-ManagementProfilesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profiles;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profiles;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profiles;
      var arg_request = buildProfile();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Profile.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProfile(obj as api.Profile);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/profiles"),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profiles;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/profiles"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildProfiles());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkProfiles(response as api.Profiles);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profiles;
      var arg_request = buildProfile();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Profile.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProfile(obj as api.Profile);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.profiles;
      var arg_request = buildProfile();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Profile.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProfile(obj as api.Profile);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });
  });

  unittest.group('resource-ManagementRemarketingAudienceResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.remarketingAudience;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_remarketingAudienceId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/remarketingAudiences/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/remarketingAudiences/"),
        );
        pathOffset += 22;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_remarketingAudienceId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(
          arg_accountId, arg_webPropertyId, arg_remarketingAudienceId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.remarketingAudience;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_remarketingAudienceId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/remarketingAudiences/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/remarketingAudiences/"),
        );
        pathOffset += 22;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_remarketingAudienceId'),
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
        var resp = convert.json.encode(buildRemarketingAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_remarketingAudienceId,
          $fields: arg_$fields);
      checkRemarketingAudience(response as api.RemarketingAudience);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.remarketingAudience;
      var arg_request = buildRemarketingAudience();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RemarketingAudience.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRemarketingAudience(obj as api.RemarketingAudience);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/remarketingAudiences', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/remarketingAudiences"),
        );
        pathOffset += 21;

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
        var resp = convert.json.encode(buildRemarketingAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkRemarketingAudience(response as api.RemarketingAudience);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.remarketingAudience;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/remarketingAudiences', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/remarketingAudiences"),
        );
        pathOffset += 21;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
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
        var resp = convert.json.encode(buildRemarketingAudiences());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          type: arg_type,
          $fields: arg_$fields);
      checkRemarketingAudiences(response as api.RemarketingAudiences);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.remarketingAudience;
      var arg_request = buildRemarketingAudience();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_remarketingAudienceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RemarketingAudience.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRemarketingAudience(obj as api.RemarketingAudience);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/remarketingAudiences/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/remarketingAudiences/"),
        );
        pathOffset += 22;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_remarketingAudienceId'),
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
        var resp = convert.json.encode(buildRemarketingAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId,
          arg_webPropertyId, arg_remarketingAudienceId,
          $fields: arg_$fields);
      checkRemarketingAudience(response as api.RemarketingAudience);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.remarketingAudience;
      var arg_request = buildRemarketingAudience();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_remarketingAudienceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RemarketingAudience.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRemarketingAudience(obj as api.RemarketingAudience);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/remarketingAudiences/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/remarketingAudiences/"),
        );
        pathOffset += 22;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_remarketingAudienceId'),
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
        var resp = convert.json.encode(buildRemarketingAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId,
          arg_webPropertyId, arg_remarketingAudienceId,
          $fields: arg_$fields);
      checkRemarketingAudience(response as api.RemarketingAudience);
    });
  });

  unittest.group('resource-ManagementSegmentsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.segments;
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("management/segments"),
        );
        pathOffset += 19;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSegments());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkSegments(response as api.Segments);
    });
  });

  unittest.group('resource-ManagementUnsampledReportsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.unsampledReports;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_unsampledReportId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/unsampledReports/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/unsampledReports/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_unsampledReportId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_accountId, arg_webPropertyId, arg_profileId,
          arg_unsampledReportId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.unsampledReports;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_unsampledReportId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/unsampledReports/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/unsampledReports/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_unsampledReportId'),
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
        var resp = convert.json.encode(buildUnsampledReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, arg_webPropertyId,
          arg_profileId, arg_unsampledReportId,
          $fields: arg_$fields);
      checkUnsampledReport(response as api.UnsampledReport);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.unsampledReports;
      var arg_request = buildUnsampledReport();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UnsampledReport.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUnsampledReport(obj as api.UnsampledReport);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/unsampledReports', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/unsampledReports"),
        );
        pathOffset += 17;

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
        var resp = convert.json.encode(buildUnsampledReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId, arg_profileId,
          $fields: arg_$fields);
      checkUnsampledReport(response as api.UnsampledReport);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.unsampledReports;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_profileId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profiles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/profiles/"),
        );
        pathOffset += 10;
        index = path.indexOf('/unsampledReports', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_profileId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/unsampledReports"),
        );
        pathOffset += 17;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUnsampledReports());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_webPropertyId, arg_profileId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkUnsampledReports(response as api.UnsampledReports);
    });
  });

  unittest.group('resource-ManagementUploadsResource', () {
    unittest.test('method--deleteUploadData', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.uploads;
      var arg_request = buildAnalyticsDataimportDeleteUploadDataRequest();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDataSourceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AnalyticsDataimportDeleteUploadDataRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAnalyticsDataimportDeleteUploadDataRequest(
            obj as api.AnalyticsDataimportDeleteUploadDataRequest);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDataSources/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/customDataSources/"),
        );
        pathOffset += 19;
        index = path.indexOf('/deleteUploadData', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDataSourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/deleteUploadData"),
        );
        pathOffset += 17;

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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.deleteUploadData(
          arg_request, arg_accountId, arg_webPropertyId, arg_customDataSourceId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.uploads;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDataSourceId = 'foo';
      var arg_uploadId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDataSources/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/customDataSources/"),
        );
        pathOffset += 19;
        index = path.indexOf('/uploads/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDataSourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/uploads/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_uploadId'),
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
        var resp = convert.json.encode(buildUpload());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, arg_webPropertyId,
          arg_customDataSourceId, arg_uploadId,
          $fields: arg_$fields);
      checkUpload(response as api.Upload);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.uploads;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDataSourceId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDataSources/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/customDataSources/"),
        );
        pathOffset += 19;
        index = path.indexOf('/uploads', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDataSourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/uploads"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUploads());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_webPropertyId, arg_customDataSourceId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkUploads(response as api.Uploads);
    });

    unittest.test('method--uploadData', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.uploads;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_customDataSourceId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/customDataSources/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/customDataSources/"),
        );
        pathOffset += 19;
        index = path.indexOf('/uploads', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customDataSourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/uploads"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUpload());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.uploadData(
          arg_accountId, arg_webPropertyId, arg_customDataSourceId,
          $fields: arg_$fields);
      checkUpload(response as api.Upload);
    });
  });

  unittest.group('resource-ManagementWebPropertyAdWordsLinksResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webPropertyAdWordsLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_webPropertyAdWordsLinkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityAdWordsLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/entityAdWordsLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyAdWordsLinkId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(
          arg_accountId, arg_webPropertyId, arg_webPropertyAdWordsLinkId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webPropertyAdWordsLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_webPropertyAdWordsLinkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityAdWordsLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/entityAdWordsLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyAdWordsLinkId'),
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
        var resp = convert.json.encode(buildEntityAdWordsLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_accountId, arg_webPropertyId, arg_webPropertyAdWordsLinkId,
          $fields: arg_$fields);
      checkEntityAdWordsLink(response as api.EntityAdWordsLink);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webPropertyAdWordsLinks;
      var arg_request = buildEntityAdWordsLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityAdWordsLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityAdWordsLink(obj as api.EntityAdWordsLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityAdWordsLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/entityAdWordsLinks"),
        );
        pathOffset += 19;

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
        var resp = convert.json.encode(buildEntityAdWordsLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkEntityAdWordsLink(response as api.EntityAdWordsLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webPropertyAdWordsLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityAdWordsLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/entityAdWordsLinks"),
        );
        pathOffset += 19;

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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEntityAdWordsLinks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkEntityAdWordsLinks(response as api.EntityAdWordsLinks);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webPropertyAdWordsLinks;
      var arg_request = buildEntityAdWordsLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_webPropertyAdWordsLinkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityAdWordsLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityAdWordsLink(obj as api.EntityAdWordsLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityAdWordsLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/entityAdWordsLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyAdWordsLinkId'),
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
        var resp = convert.json.encode(buildEntityAdWordsLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId,
          arg_webPropertyId, arg_webPropertyAdWordsLinkId,
          $fields: arg_$fields);
      checkEntityAdWordsLink(response as api.EntityAdWordsLink);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webPropertyAdWordsLinks;
      var arg_request = buildEntityAdWordsLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_webPropertyAdWordsLinkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityAdWordsLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityAdWordsLink(obj as api.EntityAdWordsLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityAdWordsLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/entityAdWordsLinks/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyAdWordsLinkId'),
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
        var resp = convert.json.encode(buildEntityAdWordsLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_accountId,
          arg_webPropertyId, arg_webPropertyAdWordsLinkId,
          $fields: arg_$fields);
      checkEntityAdWordsLink(response as api.EntityAdWordsLink);
    });
  });

  unittest.group('resource-ManagementWebpropertiesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webproperties;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
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
        var resp = convert.json.encode(buildWebproperty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_accountId, arg_webPropertyId, $fields: arg_$fields);
      checkWebproperty(response as api.Webproperty);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webproperties;
      var arg_request = buildWebproperty();
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Webproperty.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWebproperty(obj as api.Webproperty);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/webproperties"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildWebproperty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_accountId, $fields: arg_$fields);
      checkWebproperty(response as api.Webproperty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webproperties;
      var arg_accountId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/webproperties"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildWebproperties());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkWebproperties(response as api.Webproperties);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webproperties;
      var arg_request = buildWebproperty();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Webproperty.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWebproperty(obj as api.Webproperty);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
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
        var resp = convert.json.encode(buildWebproperty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkWebproperty(response as api.Webproperty);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webproperties;
      var arg_request = buildWebproperty();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Webproperty.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWebproperty(obj as api.Webproperty);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
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
        var resp = convert.json.encode(buildWebproperty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkWebproperty(response as api.Webproperty);
    });
  });

  unittest.group('resource-ManagementWebpropertyUserLinksResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webpropertyUserLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_linkId = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityUserLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/entityUserLinks/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_accountId, arg_webPropertyId, arg_linkId,
          $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webpropertyUserLinks;
      var arg_request = buildEntityUserLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityUserLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityUserLink(obj as api.EntityUserLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityUserLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/entityUserLinks"),
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
        var resp = convert.json.encode(buildEntityUserLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_accountId, arg_webPropertyId,
          $fields: arg_$fields);
      checkEntityUserLink(response as api.EntityUserLink);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webpropertyUserLinks;
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_maxResults = 42;
      var arg_startIndex = 42;
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityUserLinks', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/entityUserLinks"),
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
          core.int.parse(queryMap["max-results"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          core.int.parse(queryMap["start-index"]!.first),
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEntityUserLinks());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, arg_webPropertyId,
          maxResults: arg_maxResults,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkEntityUserLinks(response as api.EntityUserLinks);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).management.webpropertyUserLinks;
      var arg_request = buildEntityUserLink();
      var arg_accountId = 'foo';
      var arg_webPropertyId = 'foo';
      var arg_linkId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EntityUserLink.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEntityUserLink(obj as api.EntityUserLink);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("management/accounts/"),
        );
        pathOffset += 20;
        index = path.indexOf('/webproperties/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/webproperties/"),
        );
        pathOffset += 15;
        index = path.indexOf('/entityUserLinks/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_webPropertyId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/entityUserLinks/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_linkId'),
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
        var resp = convert.json.encode(buildEntityUserLink());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_webPropertyId, arg_linkId,
          $fields: arg_$fields);
      checkEntityUserLink(response as api.EntityUserLink);
    });
  });

  unittest.group('resource-MetadataColumnsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).metadata.columns;
      var arg_reportType = 'foo';
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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("metadata/"),
        );
        pathOffset += 9;
        index = path.indexOf('/columns', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reportType'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/columns"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildColumns());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_reportType, $fields: arg_$fields);
      checkColumns(response as api.Columns);
    });
  });

  unittest.group('resource-ProvisioningResource', () {
    unittest.test('method--createAccountTicket', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).provisioning;
      var arg_request = buildAccountTicket();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AccountTicket.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAccountTicket(obj as api.AccountTicket);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("provisioning/createAccountTicket"),
        );
        pathOffset += 32;

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
        var resp = convert.json.encode(buildAccountTicket());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.createAccountTicket(arg_request, $fields: arg_$fields);
      checkAccountTicket(response as api.AccountTicket);
    });

    unittest.test('method--createAccountTree', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).provisioning;
      var arg_request = buildAccountTreeRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AccountTreeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAccountTreeRequest(obj as api.AccountTreeRequest);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("provisioning/createAccountTree"),
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
        var resp = convert.json.encode(buildAccountTreeResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.createAccountTree(arg_request, $fields: arg_$fields);
      checkAccountTreeResponse(response as api.AccountTreeResponse);
    });
  });

  unittest.group('resource-UserDeletionUserDeletionRequestResource', () {
    unittest.test('method--upsert', () async {
      var mock = HttpServerMock();
      var res = api.AnalyticsApi(mock).userDeletion.userDeletionRequest;
      var arg_request = buildUserDeletionRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserDeletionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserDeletionRequest(obj as api.UserDeletionRequest);

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
          unittest.equals("analytics/v3/"),
        );
        pathOffset += 13;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 40),
          unittest.equals("userDeletion/userDeletionRequests:upsert"),
        );
        pathOffset += 40;

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
        var resp = convert.json.encode(buildUserDeletionRequest());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.upsert(arg_request, $fields: arg_$fields);
      checkUserDeletionRequest(response as api.UserDeletionRequest);
    });
  });
}
