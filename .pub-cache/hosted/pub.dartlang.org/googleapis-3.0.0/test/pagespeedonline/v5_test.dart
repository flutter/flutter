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

import 'package:googleapis/pagespeedonline/v5.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAuditRefs = 0;
api.AuditRefs buildAuditRefs() {
  var o = api.AuditRefs();
  buildCounterAuditRefs++;
  if (buildCounterAuditRefs < 3) {
    o.group = 'foo';
    o.id = 'foo';
    o.weight = 42.0;
  }
  buildCounterAuditRefs--;
  return o;
}

void checkAuditRefs(api.AuditRefs o) {
  buildCounterAuditRefs++;
  if (buildCounterAuditRefs < 3) {
    unittest.expect(
      o.group!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.weight!,
      unittest.equals(42.0),
    );
  }
  buildCounterAuditRefs--;
}

core.int buildCounterBucket = 0;
api.Bucket buildBucket() {
  var o = api.Bucket();
  buildCounterBucket++;
  if (buildCounterBucket < 3) {
    o.max = 42;
    o.min = 42;
    o.proportion = 42.0;
  }
  buildCounterBucket--;
  return o;
}

void checkBucket(api.Bucket o) {
  buildCounterBucket++;
  if (buildCounterBucket < 3) {
    unittest.expect(
      o.max!,
      unittest.equals(42),
    );
    unittest.expect(
      o.min!,
      unittest.equals(42),
    );
    unittest.expect(
      o.proportion!,
      unittest.equals(42.0),
    );
  }
  buildCounterBucket--;
}

core.int buildCounterCategories = 0;
api.Categories buildCategories() {
  var o = api.Categories();
  buildCounterCategories++;
  if (buildCounterCategories < 3) {
    o.accessibility = buildLighthouseCategoryV5();
    o.bestPractices = buildLighthouseCategoryV5();
    o.performance = buildLighthouseCategoryV5();
    o.pwa = buildLighthouseCategoryV5();
    o.seo = buildLighthouseCategoryV5();
  }
  buildCounterCategories--;
  return o;
}

void checkCategories(api.Categories o) {
  buildCounterCategories++;
  if (buildCounterCategories < 3) {
    checkLighthouseCategoryV5(o.accessibility! as api.LighthouseCategoryV5);
    checkLighthouseCategoryV5(o.bestPractices! as api.LighthouseCategoryV5);
    checkLighthouseCategoryV5(o.performance! as api.LighthouseCategoryV5);
    checkLighthouseCategoryV5(o.pwa! as api.LighthouseCategoryV5);
    checkLighthouseCategoryV5(o.seo! as api.LighthouseCategoryV5);
  }
  buildCounterCategories--;
}

core.int buildCounterCategoryGroupV5 = 0;
api.CategoryGroupV5 buildCategoryGroupV5() {
  var o = api.CategoryGroupV5();
  buildCounterCategoryGroupV5++;
  if (buildCounterCategoryGroupV5 < 3) {
    o.description = 'foo';
    o.title = 'foo';
  }
  buildCounterCategoryGroupV5--;
  return o;
}

void checkCategoryGroupV5(api.CategoryGroupV5 o) {
  buildCounterCategoryGroupV5++;
  if (buildCounterCategoryGroupV5 < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategoryGroupV5--;
}

core.int buildCounterConfigSettings = 0;
api.ConfigSettings buildConfigSettings() {
  var o = api.ConfigSettings();
  buildCounterConfigSettings++;
  if (buildCounterConfigSettings < 3) {
    o.channel = 'foo';
    o.emulatedFormFactor = 'foo';
    o.formFactor = 'foo';
    o.locale = 'foo';
    o.onlyCategories = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterConfigSettings--;
  return o;
}

void checkConfigSettings(api.ConfigSettings o) {
  buildCounterConfigSettings++;
  if (buildCounterConfigSettings < 3) {
    unittest.expect(
      o.channel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.emulatedFormFactor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formFactor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    var casted1 = (o.onlyCategories!) as core.Map;
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
  }
  buildCounterConfigSettings--;
}

core.int buildCounterEnvironment = 0;
api.Environment buildEnvironment() {
  var o = api.Environment();
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    o.benchmarkIndex = 42.0;
    o.hostUserAgent = 'foo';
    o.networkUserAgent = 'foo';
  }
  buildCounterEnvironment--;
  return o;
}

void checkEnvironment(api.Environment o) {
  buildCounterEnvironment++;
  if (buildCounterEnvironment < 3) {
    unittest.expect(
      o.benchmarkIndex!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.hostUserAgent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.networkUserAgent!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnvironment--;
}

core.int buildCounterI18n = 0;
api.I18n buildI18n() {
  var o = api.I18n();
  buildCounterI18n++;
  if (buildCounterI18n < 3) {
    o.rendererFormattedStrings = buildRendererFormattedStrings();
  }
  buildCounterI18n--;
  return o;
}

void checkI18n(api.I18n o) {
  buildCounterI18n++;
  if (buildCounterI18n < 3) {
    checkRendererFormattedStrings(
        o.rendererFormattedStrings! as api.RendererFormattedStrings);
  }
  buildCounterI18n--;
}

core.Map<core.String, core.Object> buildUnnamed3105() {
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

void checkUnnamed3105(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted2 = (o['x']!) as core.Map;
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
  var casted3 = (o['y']!) as core.Map;
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
}

core.int buildCounterLighthouseAuditResultV5 = 0;
api.LighthouseAuditResultV5 buildLighthouseAuditResultV5() {
  var o = api.LighthouseAuditResultV5();
  buildCounterLighthouseAuditResultV5++;
  if (buildCounterLighthouseAuditResultV5 < 3) {
    o.description = 'foo';
    o.details = buildUnnamed3105();
    o.displayValue = 'foo';
    o.errorMessage = 'foo';
    o.explanation = 'foo';
    o.id = 'foo';
    o.numericValue = 42.0;
    o.score = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.scoreDisplayMode = 'foo';
    o.title = 'foo';
    o.warnings = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterLighthouseAuditResultV5--;
  return o;
}

void checkLighthouseAuditResultV5(api.LighthouseAuditResultV5 o) {
  buildCounterLighthouseAuditResultV5++;
  if (buildCounterLighthouseAuditResultV5 < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed3105(o.details!);
    unittest.expect(
      o.displayValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.explanation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numericValue!,
      unittest.equals(42.0),
    );
    var casted4 = (o.score!) as core.Map;
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
    unittest.expect(
      o.scoreDisplayMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    var casted5 = (o.warnings!) as core.Map;
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
  }
  buildCounterLighthouseAuditResultV5--;
}

core.List<api.AuditRefs> buildUnnamed3106() {
  var o = <api.AuditRefs>[];
  o.add(buildAuditRefs());
  o.add(buildAuditRefs());
  return o;
}

void checkUnnamed3106(core.List<api.AuditRefs> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditRefs(o[0] as api.AuditRefs);
  checkAuditRefs(o[1] as api.AuditRefs);
}

core.int buildCounterLighthouseCategoryV5 = 0;
api.LighthouseCategoryV5 buildLighthouseCategoryV5() {
  var o = api.LighthouseCategoryV5();
  buildCounterLighthouseCategoryV5++;
  if (buildCounterLighthouseCategoryV5 < 3) {
    o.auditRefs = buildUnnamed3106();
    o.description = 'foo';
    o.id = 'foo';
    o.manualDescription = 'foo';
    o.score = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.title = 'foo';
  }
  buildCounterLighthouseCategoryV5--;
  return o;
}

void checkLighthouseCategoryV5(api.LighthouseCategoryV5 o) {
  buildCounterLighthouseCategoryV5++;
  if (buildCounterLighthouseCategoryV5 < 3) {
    checkUnnamed3106(o.auditRefs!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manualDescription!,
      unittest.equals('foo'),
    );
    var casted6 = (o.score!) as core.Map;
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
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterLighthouseCategoryV5--;
}

core.Map<core.String, api.LighthouseAuditResultV5> buildUnnamed3107() {
  var o = <core.String, api.LighthouseAuditResultV5>{};
  o['x'] = buildLighthouseAuditResultV5();
  o['y'] = buildLighthouseAuditResultV5();
  return o;
}

void checkUnnamed3107(core.Map<core.String, api.LighthouseAuditResultV5> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLighthouseAuditResultV5(o['x']! as api.LighthouseAuditResultV5);
  checkLighthouseAuditResultV5(o['y']! as api.LighthouseAuditResultV5);
}

core.Map<core.String, api.CategoryGroupV5> buildUnnamed3108() {
  var o = <core.String, api.CategoryGroupV5>{};
  o['x'] = buildCategoryGroupV5();
  o['y'] = buildCategoryGroupV5();
  return o;
}

void checkUnnamed3108(core.Map<core.String, api.CategoryGroupV5> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCategoryGroupV5(o['x']! as api.CategoryGroupV5);
  checkCategoryGroupV5(o['y']! as api.CategoryGroupV5);
}

core.List<core.Object> buildUnnamed3109() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed3109(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o[0]) as core.Map;
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
  var casted8 = (o[1]) as core.Map;
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

core.List<api.StackPack> buildUnnamed3110() {
  var o = <api.StackPack>[];
  o.add(buildStackPack());
  o.add(buildStackPack());
  return o;
}

void checkUnnamed3110(core.List<api.StackPack> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStackPack(o[0] as api.StackPack);
  checkStackPack(o[1] as api.StackPack);
}

core.int buildCounterLighthouseResultV5 = 0;
api.LighthouseResultV5 buildLighthouseResultV5() {
  var o = api.LighthouseResultV5();
  buildCounterLighthouseResultV5++;
  if (buildCounterLighthouseResultV5 < 3) {
    o.audits = buildUnnamed3107();
    o.categories = buildCategories();
    o.categoryGroups = buildUnnamed3108();
    o.configSettings = buildConfigSettings();
    o.environment = buildEnvironment();
    o.fetchTime = 'foo';
    o.finalUrl = 'foo';
    o.i18n = buildI18n();
    o.lighthouseVersion = 'foo';
    o.requestedUrl = 'foo';
    o.runWarnings = buildUnnamed3109();
    o.runtimeError = buildRuntimeError();
    o.stackPacks = buildUnnamed3110();
    o.timing = buildTiming();
    o.userAgent = 'foo';
  }
  buildCounterLighthouseResultV5--;
  return o;
}

void checkLighthouseResultV5(api.LighthouseResultV5 o) {
  buildCounterLighthouseResultV5++;
  if (buildCounterLighthouseResultV5 < 3) {
    checkUnnamed3107(o.audits!);
    checkCategories(o.categories! as api.Categories);
    checkUnnamed3108(o.categoryGroups!);
    checkConfigSettings(o.configSettings! as api.ConfigSettings);
    checkEnvironment(o.environment! as api.Environment);
    unittest.expect(
      o.fetchTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.finalUrl!,
      unittest.equals('foo'),
    );
    checkI18n(o.i18n! as api.I18n);
    unittest.expect(
      o.lighthouseVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestedUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed3109(o.runWarnings!);
    checkRuntimeError(o.runtimeError! as api.RuntimeError);
    checkUnnamed3110(o.stackPacks!);
    checkTiming(o.timing! as api.Timing);
    unittest.expect(
      o.userAgent!,
      unittest.equals('foo'),
    );
  }
  buildCounterLighthouseResultV5--;
}

core.Map<core.String, api.UserPageLoadMetricV5> buildUnnamed3111() {
  var o = <core.String, api.UserPageLoadMetricV5>{};
  o['x'] = buildUserPageLoadMetricV5();
  o['y'] = buildUserPageLoadMetricV5();
  return o;
}

void checkUnnamed3111(core.Map<core.String, api.UserPageLoadMetricV5> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserPageLoadMetricV5(o['x']! as api.UserPageLoadMetricV5);
  checkUserPageLoadMetricV5(o['y']! as api.UserPageLoadMetricV5);
}

core.int buildCounterPagespeedApiLoadingExperienceV5 = 0;
api.PagespeedApiLoadingExperienceV5 buildPagespeedApiLoadingExperienceV5() {
  var o = api.PagespeedApiLoadingExperienceV5();
  buildCounterPagespeedApiLoadingExperienceV5++;
  if (buildCounterPagespeedApiLoadingExperienceV5 < 3) {
    o.id = 'foo';
    o.initialUrl = 'foo';
    o.metrics = buildUnnamed3111();
    o.originFallback = true;
    o.overallCategory = 'foo';
  }
  buildCounterPagespeedApiLoadingExperienceV5--;
  return o;
}

void checkPagespeedApiLoadingExperienceV5(
    api.PagespeedApiLoadingExperienceV5 o) {
  buildCounterPagespeedApiLoadingExperienceV5++;
  if (buildCounterPagespeedApiLoadingExperienceV5 < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.initialUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed3111(o.metrics!);
    unittest.expect(o.originFallback!, unittest.isTrue);
    unittest.expect(
      o.overallCategory!,
      unittest.equals('foo'),
    );
  }
  buildCounterPagespeedApiLoadingExperienceV5--;
}

core.int buildCounterPagespeedApiPagespeedResponseV5 = 0;
api.PagespeedApiPagespeedResponseV5 buildPagespeedApiPagespeedResponseV5() {
  var o = api.PagespeedApiPagespeedResponseV5();
  buildCounterPagespeedApiPagespeedResponseV5++;
  if (buildCounterPagespeedApiPagespeedResponseV5 < 3) {
    o.analysisUTCTimestamp = 'foo';
    o.captchaResult = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.lighthouseResult = buildLighthouseResultV5();
    o.loadingExperience = buildPagespeedApiLoadingExperienceV5();
    o.originLoadingExperience = buildPagespeedApiLoadingExperienceV5();
    o.version = buildPagespeedVersion();
  }
  buildCounterPagespeedApiPagespeedResponseV5--;
  return o;
}

void checkPagespeedApiPagespeedResponseV5(
    api.PagespeedApiPagespeedResponseV5 o) {
  buildCounterPagespeedApiPagespeedResponseV5++;
  if (buildCounterPagespeedApiPagespeedResponseV5 < 3) {
    unittest.expect(
      o.analysisUTCTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.captchaResult!,
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
    checkLighthouseResultV5(o.lighthouseResult! as api.LighthouseResultV5);
    checkPagespeedApiLoadingExperienceV5(
        o.loadingExperience! as api.PagespeedApiLoadingExperienceV5);
    checkPagespeedApiLoadingExperienceV5(
        o.originLoadingExperience! as api.PagespeedApiLoadingExperienceV5);
    checkPagespeedVersion(o.version! as api.PagespeedVersion);
  }
  buildCounterPagespeedApiPagespeedResponseV5--;
}

core.int buildCounterPagespeedVersion = 0;
api.PagespeedVersion buildPagespeedVersion() {
  var o = api.PagespeedVersion();
  buildCounterPagespeedVersion++;
  if (buildCounterPagespeedVersion < 3) {
    o.major = 'foo';
    o.minor = 'foo';
  }
  buildCounterPagespeedVersion--;
  return o;
}

void checkPagespeedVersion(api.PagespeedVersion o) {
  buildCounterPagespeedVersion++;
  if (buildCounterPagespeedVersion < 3) {
    unittest.expect(
      o.major!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minor!,
      unittest.equals('foo'),
    );
  }
  buildCounterPagespeedVersion--;
}

core.int buildCounterRendererFormattedStrings = 0;
api.RendererFormattedStrings buildRendererFormattedStrings() {
  var o = api.RendererFormattedStrings();
  buildCounterRendererFormattedStrings++;
  if (buildCounterRendererFormattedStrings < 3) {
    o.auditGroupExpandTooltip = 'foo';
    o.crcInitialNavigation = 'foo';
    o.crcLongestDurationLabel = 'foo';
    o.errorLabel = 'foo';
    o.errorMissingAuditInfo = 'foo';
    o.labDataTitle = 'foo';
    o.lsPerformanceCategoryDescription = 'foo';
    o.manualAuditsGroupTitle = 'foo';
    o.notApplicableAuditsGroupTitle = 'foo';
    o.opportunityResourceColumnLabel = 'foo';
    o.opportunitySavingsColumnLabel = 'foo';
    o.passedAuditsGroupTitle = 'foo';
    o.scorescaleLabel = 'foo';
    o.toplevelWarningsMessage = 'foo';
    o.varianceDisclaimer = 'foo';
    o.warningHeader = 'foo';
  }
  buildCounterRendererFormattedStrings--;
  return o;
}

void checkRendererFormattedStrings(api.RendererFormattedStrings o) {
  buildCounterRendererFormattedStrings++;
  if (buildCounterRendererFormattedStrings < 3) {
    unittest.expect(
      o.auditGroupExpandTooltip!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.crcInitialNavigation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.crcLongestDurationLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMissingAuditInfo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.labDataTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lsPerformanceCategoryDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manualAuditsGroupTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notApplicableAuditsGroupTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.opportunityResourceColumnLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.opportunitySavingsColumnLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.passedAuditsGroupTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scorescaleLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.toplevelWarningsMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.varianceDisclaimer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.warningHeader!,
      unittest.equals('foo'),
    );
  }
  buildCounterRendererFormattedStrings--;
}

core.int buildCounterRuntimeError = 0;
api.RuntimeError buildRuntimeError() {
  var o = api.RuntimeError();
  buildCounterRuntimeError++;
  if (buildCounterRuntimeError < 3) {
    o.code = 'foo';
    o.message = 'foo';
  }
  buildCounterRuntimeError--;
  return o;
}

void checkRuntimeError(api.RuntimeError o) {
  buildCounterRuntimeError++;
  if (buildCounterRuntimeError < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterRuntimeError--;
}

core.Map<core.String, core.String> buildUnnamed3112() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3112(core.Map<core.String, core.String> o) {
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

core.int buildCounterStackPack = 0;
api.StackPack buildStackPack() {
  var o = api.StackPack();
  buildCounterStackPack++;
  if (buildCounterStackPack < 3) {
    o.descriptions = buildUnnamed3112();
    o.iconDataURL = 'foo';
    o.id = 'foo';
    o.title = 'foo';
  }
  buildCounterStackPack--;
  return o;
}

void checkStackPack(api.StackPack o) {
  buildCounterStackPack++;
  if (buildCounterStackPack < 3) {
    checkUnnamed3112(o.descriptions!);
    unittest.expect(
      o.iconDataURL!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterStackPack--;
}

core.int buildCounterTiming = 0;
api.Timing buildTiming() {
  var o = api.Timing();
  buildCounterTiming++;
  if (buildCounterTiming < 3) {
    o.total = 42.0;
  }
  buildCounterTiming--;
  return o;
}

void checkTiming(api.Timing o) {
  buildCounterTiming++;
  if (buildCounterTiming < 3) {
    unittest.expect(
      o.total!,
      unittest.equals(42.0),
    );
  }
  buildCounterTiming--;
}

core.List<api.Bucket> buildUnnamed3113() {
  var o = <api.Bucket>[];
  o.add(buildBucket());
  o.add(buildBucket());
  return o;
}

void checkUnnamed3113(core.List<api.Bucket> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBucket(o[0] as api.Bucket);
  checkBucket(o[1] as api.Bucket);
}

core.int buildCounterUserPageLoadMetricV5 = 0;
api.UserPageLoadMetricV5 buildUserPageLoadMetricV5() {
  var o = api.UserPageLoadMetricV5();
  buildCounterUserPageLoadMetricV5++;
  if (buildCounterUserPageLoadMetricV5 < 3) {
    o.category = 'foo';
    o.distributions = buildUnnamed3113();
    o.formFactor = 'foo';
    o.median = 42;
    o.metricId = 'foo';
    o.percentile = 42;
  }
  buildCounterUserPageLoadMetricV5--;
  return o;
}

void checkUserPageLoadMetricV5(api.UserPageLoadMetricV5 o) {
  buildCounterUserPageLoadMetricV5++;
  if (buildCounterUserPageLoadMetricV5 < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    checkUnnamed3113(o.distributions!);
    unittest.expect(
      o.formFactor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.median!,
      unittest.equals(42),
    );
    unittest.expect(
      o.metricId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.percentile!,
      unittest.equals(42),
    );
  }
  buildCounterUserPageLoadMetricV5--;
}

core.List<core.String> buildUnnamed3114() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3114(core.List<core.String> o) {
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

void main() {
  unittest.group('obj-schema-AuditRefs', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditRefs();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AuditRefs.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAuditRefs(od as api.AuditRefs);
    });
  });

  unittest.group('obj-schema-Bucket', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucket();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Bucket.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBucket(od as api.Bucket);
    });
  });

  unittest.group('obj-schema-Categories', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategories();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Categories.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCategories(od as api.Categories);
    });
  });

  unittest.group('obj-schema-CategoryGroupV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategoryGroupV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CategoryGroupV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCategoryGroupV5(od as api.CategoryGroupV5);
    });
  });

  unittest.group('obj-schema-ConfigSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConfigSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConfigSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConfigSettings(od as api.ConfigSettings);
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

  unittest.group('obj-schema-I18n', () {
    unittest.test('to-json--from-json', () async {
      var o = buildI18n();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.I18n.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkI18n(od as api.I18n);
    });
  });

  unittest.group('obj-schema-LighthouseAuditResultV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLighthouseAuditResultV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LighthouseAuditResultV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLighthouseAuditResultV5(od as api.LighthouseAuditResultV5);
    });
  });

  unittest.group('obj-schema-LighthouseCategoryV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLighthouseCategoryV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LighthouseCategoryV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLighthouseCategoryV5(od as api.LighthouseCategoryV5);
    });
  });

  unittest.group('obj-schema-LighthouseResultV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLighthouseResultV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LighthouseResultV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLighthouseResultV5(od as api.LighthouseResultV5);
    });
  });

  unittest.group('obj-schema-PagespeedApiLoadingExperienceV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPagespeedApiLoadingExperienceV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PagespeedApiLoadingExperienceV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPagespeedApiLoadingExperienceV5(
          od as api.PagespeedApiLoadingExperienceV5);
    });
  });

  unittest.group('obj-schema-PagespeedApiPagespeedResponseV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPagespeedApiPagespeedResponseV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PagespeedApiPagespeedResponseV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPagespeedApiPagespeedResponseV5(
          od as api.PagespeedApiPagespeedResponseV5);
    });
  });

  unittest.group('obj-schema-PagespeedVersion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPagespeedVersion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PagespeedVersion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPagespeedVersion(od as api.PagespeedVersion);
    });
  });

  unittest.group('obj-schema-RendererFormattedStrings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRendererFormattedStrings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RendererFormattedStrings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRendererFormattedStrings(od as api.RendererFormattedStrings);
    });
  });

  unittest.group('obj-schema-RuntimeError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRuntimeError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RuntimeError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRuntimeError(od as api.RuntimeError);
    });
  });

  unittest.group('obj-schema-StackPack', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackPack();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StackPack.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStackPack(od as api.StackPack);
    });
  });

  unittest.group('obj-schema-Timing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTiming();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Timing.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTiming(od as api.Timing);
    });
  });

  unittest.group('obj-schema-UserPageLoadMetricV5', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserPageLoadMetricV5();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserPageLoadMetricV5.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserPageLoadMetricV5(od as api.UserPageLoadMetricV5);
    });
  });

  unittest.group('resource-PagespeedapiResource', () {
    unittest.test('method--runpagespeed', () async {
      var mock = HttpServerMock();
      var res = api.PagespeedInsightsApi(mock).pagespeedapi;
      var arg_url = 'foo';
      var arg_captchaToken = 'foo';
      var arg_category = buildUnnamed3114();
      var arg_locale = 'foo';
      var arg_strategy = 'foo';
      var arg_utmCampaign = 'foo';
      var arg_utmSource = 'foo';
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
          path.substring(pathOffset, pathOffset + 31),
          unittest.equals("pagespeedonline/v5/runPagespeed"),
        );
        pathOffset += 31;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["url"]!.first,
          unittest.equals(arg_url),
        );
        unittest.expect(
          queryMap["captchaToken"]!.first,
          unittest.equals(arg_captchaToken),
        );
        unittest.expect(
          queryMap["category"]!,
          unittest.equals(arg_category),
        );
        unittest.expect(
          queryMap["locale"]!.first,
          unittest.equals(arg_locale),
        );
        unittest.expect(
          queryMap["strategy"]!.first,
          unittest.equals(arg_strategy),
        );
        unittest.expect(
          queryMap["utm_campaign"]!.first,
          unittest.equals(arg_utmCampaign),
        );
        unittest.expect(
          queryMap["utm_source"]!.first,
          unittest.equals(arg_utmSource),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPagespeedApiPagespeedResponseV5());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.runpagespeed(arg_url,
          captchaToken: arg_captchaToken,
          category: arg_category,
          locale: arg_locale,
          strategy: arg_strategy,
          utmCampaign: arg_utmCampaign,
          utmSource: arg_utmSource,
          $fields: arg_$fields);
      checkPagespeedApiPagespeedResponseV5(
          response as api.PagespeedApiPagespeedResponseV5);
    });
  });
}
