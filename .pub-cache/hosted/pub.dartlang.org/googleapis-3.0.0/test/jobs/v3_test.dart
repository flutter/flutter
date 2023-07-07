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

import 'package:googleapis/jobs/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed3557() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3557(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3558() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3558(core.List<core.String> o) {
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

core.int buildCounterApplicationInfo = 0;
api.ApplicationInfo buildApplicationInfo() {
  var o = api.ApplicationInfo();
  buildCounterApplicationInfo++;
  if (buildCounterApplicationInfo < 3) {
    o.emails = buildUnnamed3557();
    o.instruction = 'foo';
    o.uris = buildUnnamed3558();
  }
  buildCounterApplicationInfo--;
  return o;
}

void checkApplicationInfo(api.ApplicationInfo o) {
  buildCounterApplicationInfo++;
  if (buildCounterApplicationInfo < 3) {
    checkUnnamed3557(o.emails!);
    unittest.expect(
      o.instruction!,
      unittest.equals('foo'),
    );
    checkUnnamed3558(o.uris!);
  }
  buildCounterApplicationInfo--;
}

core.int buildCounterBatchDeleteJobsRequest = 0;
api.BatchDeleteJobsRequest buildBatchDeleteJobsRequest() {
  var o = api.BatchDeleteJobsRequest();
  buildCounterBatchDeleteJobsRequest++;
  if (buildCounterBatchDeleteJobsRequest < 3) {
    o.filter = 'foo';
  }
  buildCounterBatchDeleteJobsRequest--;
  return o;
}

void checkBatchDeleteJobsRequest(api.BatchDeleteJobsRequest o) {
  buildCounterBatchDeleteJobsRequest++;
  if (buildCounterBatchDeleteJobsRequest < 3) {
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchDeleteJobsRequest--;
}

core.int buildCounterBucketRange = 0;
api.BucketRange buildBucketRange() {
  var o = api.BucketRange();
  buildCounterBucketRange++;
  if (buildCounterBucketRange < 3) {
    o.from = 42.0;
    o.to = 42.0;
  }
  buildCounterBucketRange--;
  return o;
}

void checkBucketRange(api.BucketRange o) {
  buildCounterBucketRange++;
  if (buildCounterBucketRange < 3) {
    unittest.expect(
      o.from!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.to!,
      unittest.equals(42.0),
    );
  }
  buildCounterBucketRange--;
}

core.int buildCounterBucketizedCount = 0;
api.BucketizedCount buildBucketizedCount() {
  var o = api.BucketizedCount();
  buildCounterBucketizedCount++;
  if (buildCounterBucketizedCount < 3) {
    o.count = 42;
    o.range = buildBucketRange();
  }
  buildCounterBucketizedCount--;
  return o;
}

void checkBucketizedCount(api.BucketizedCount o) {
  buildCounterBucketizedCount++;
  if (buildCounterBucketizedCount < 3) {
    unittest.expect(
      o.count!,
      unittest.equals(42),
    );
    checkBucketRange(o.range! as api.BucketRange);
  }
  buildCounterBucketizedCount--;
}

core.Map<core.String, core.String> buildUnnamed3559() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3559(core.Map<core.String, core.String> o) {
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

core.int buildCounterClientEvent = 0;
api.ClientEvent buildClientEvent() {
  var o = api.ClientEvent();
  buildCounterClientEvent++;
  if (buildCounterClientEvent < 3) {
    o.createTime = 'foo';
    o.eventId = 'foo';
    o.extraInfo = buildUnnamed3559();
    o.jobEvent = buildJobEvent();
    o.parentEventId = 'foo';
    o.requestId = 'foo';
  }
  buildCounterClientEvent--;
  return o;
}

void checkClientEvent(api.ClientEvent o) {
  buildCounterClientEvent++;
  if (buildCounterClientEvent < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    checkUnnamed3559(o.extraInfo!);
    checkJobEvent(o.jobEvent! as api.JobEvent);
    unittest.expect(
      o.parentEventId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
  }
  buildCounterClientEvent--;
}

core.int buildCounterCommuteFilter = 0;
api.CommuteFilter buildCommuteFilter() {
  var o = api.CommuteFilter();
  buildCounterCommuteFilter++;
  if (buildCounterCommuteFilter < 3) {
    o.allowImpreciseAddresses = true;
    o.commuteMethod = 'foo';
    o.departureTime = buildTimeOfDay();
    o.roadTraffic = 'foo';
    o.startCoordinates = buildLatLng();
    o.travelDuration = 'foo';
  }
  buildCounterCommuteFilter--;
  return o;
}

void checkCommuteFilter(api.CommuteFilter o) {
  buildCounterCommuteFilter++;
  if (buildCounterCommuteFilter < 3) {
    unittest.expect(o.allowImpreciseAddresses!, unittest.isTrue);
    unittest.expect(
      o.commuteMethod!,
      unittest.equals('foo'),
    );
    checkTimeOfDay(o.departureTime! as api.TimeOfDay);
    unittest.expect(
      o.roadTraffic!,
      unittest.equals('foo'),
    );
    checkLatLng(o.startCoordinates! as api.LatLng);
    unittest.expect(
      o.travelDuration!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommuteFilter--;
}

core.int buildCounterCommuteInfo = 0;
api.CommuteInfo buildCommuteInfo() {
  var o = api.CommuteInfo();
  buildCounterCommuteInfo++;
  if (buildCounterCommuteInfo < 3) {
    o.jobLocation = buildLocation();
    o.travelDuration = 'foo';
  }
  buildCounterCommuteInfo--;
  return o;
}

void checkCommuteInfo(api.CommuteInfo o) {
  buildCounterCommuteInfo++;
  if (buildCounterCommuteInfo < 3) {
    checkLocation(o.jobLocation! as api.Location);
    unittest.expect(
      o.travelDuration!,
      unittest.equals('foo'),
    );
  }
  buildCounterCommuteInfo--;
}

core.List<core.String> buildUnnamed3560() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3560(core.List<core.String> o) {
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

core.int buildCounterCompany = 0;
api.Company buildCompany() {
  var o = api.Company();
  buildCounterCompany++;
  if (buildCounterCompany < 3) {
    o.careerSiteUri = 'foo';
    o.derivedInfo = buildCompanyDerivedInfo();
    o.displayName = 'foo';
    o.eeoText = 'foo';
    o.externalId = 'foo';
    o.headquartersAddress = 'foo';
    o.hiringAgency = true;
    o.imageUri = 'foo';
    o.keywordSearchableJobCustomAttributes = buildUnnamed3560();
    o.name = 'foo';
    o.size = 'foo';
    o.suspended = true;
    o.websiteUri = 'foo';
  }
  buildCounterCompany--;
  return o;
}

void checkCompany(api.Company o) {
  buildCounterCompany++;
  if (buildCounterCompany < 3) {
    unittest.expect(
      o.careerSiteUri!,
      unittest.equals('foo'),
    );
    checkCompanyDerivedInfo(o.derivedInfo! as api.CompanyDerivedInfo);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.eeoText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.headquartersAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hiringAgency!, unittest.isTrue);
    unittest.expect(
      o.imageUri!,
      unittest.equals('foo'),
    );
    checkUnnamed3560(o.keywordSearchableJobCustomAttributes!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals('foo'),
    );
    unittest.expect(o.suspended!, unittest.isTrue);
    unittest.expect(
      o.websiteUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompany--;
}

core.int buildCounterCompanyDerivedInfo = 0;
api.CompanyDerivedInfo buildCompanyDerivedInfo() {
  var o = api.CompanyDerivedInfo();
  buildCounterCompanyDerivedInfo++;
  if (buildCounterCompanyDerivedInfo < 3) {
    o.headquartersLocation = buildLocation();
  }
  buildCounterCompanyDerivedInfo--;
  return o;
}

void checkCompanyDerivedInfo(api.CompanyDerivedInfo o) {
  buildCounterCompanyDerivedInfo++;
  if (buildCounterCompanyDerivedInfo < 3) {
    checkLocation(o.headquartersLocation! as api.Location);
  }
  buildCounterCompanyDerivedInfo--;
}

core.int buildCounterCompensationEntry = 0;
api.CompensationEntry buildCompensationEntry() {
  var o = api.CompensationEntry();
  buildCounterCompensationEntry++;
  if (buildCounterCompensationEntry < 3) {
    o.amount = buildMoney();
    o.description = 'foo';
    o.expectedUnitsPerYear = 42.0;
    o.range = buildCompensationRange();
    o.type = 'foo';
    o.unit = 'foo';
  }
  buildCounterCompensationEntry--;
  return o;
}

void checkCompensationEntry(api.CompensationEntry o) {
  buildCounterCompensationEntry++;
  if (buildCounterCompensationEntry < 3) {
    checkMoney(o.amount! as api.Money);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expectedUnitsPerYear!,
      unittest.equals(42.0),
    );
    checkCompensationRange(o.range! as api.CompensationRange);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.unit!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompensationEntry--;
}

core.List<core.String> buildUnnamed3561() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3561(core.List<core.String> o) {
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

core.int buildCounterCompensationFilter = 0;
api.CompensationFilter buildCompensationFilter() {
  var o = api.CompensationFilter();
  buildCounterCompensationFilter++;
  if (buildCounterCompensationFilter < 3) {
    o.includeJobsWithUnspecifiedCompensationRange = true;
    o.range = buildCompensationRange();
    o.type = 'foo';
    o.units = buildUnnamed3561();
  }
  buildCounterCompensationFilter--;
  return o;
}

void checkCompensationFilter(api.CompensationFilter o) {
  buildCounterCompensationFilter++;
  if (buildCounterCompensationFilter < 3) {
    unittest.expect(
        o.includeJobsWithUnspecifiedCompensationRange!, unittest.isTrue);
    checkCompensationRange(o.range! as api.CompensationRange);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkUnnamed3561(o.units!);
  }
  buildCounterCompensationFilter--;
}

core.int buildCounterCompensationHistogramRequest = 0;
api.CompensationHistogramRequest buildCompensationHistogramRequest() {
  var o = api.CompensationHistogramRequest();
  buildCounterCompensationHistogramRequest++;
  if (buildCounterCompensationHistogramRequest < 3) {
    o.bucketingOption = buildNumericBucketingOption();
    o.type = 'foo';
  }
  buildCounterCompensationHistogramRequest--;
  return o;
}

void checkCompensationHistogramRequest(api.CompensationHistogramRequest o) {
  buildCounterCompensationHistogramRequest++;
  if (buildCounterCompensationHistogramRequest < 3) {
    checkNumericBucketingOption(
        o.bucketingOption! as api.NumericBucketingOption);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompensationHistogramRequest--;
}

core.int buildCounterCompensationHistogramResult = 0;
api.CompensationHistogramResult buildCompensationHistogramResult() {
  var o = api.CompensationHistogramResult();
  buildCounterCompensationHistogramResult++;
  if (buildCounterCompensationHistogramResult < 3) {
    o.result = buildNumericBucketingResult();
    o.type = 'foo';
  }
  buildCounterCompensationHistogramResult--;
  return o;
}

void checkCompensationHistogramResult(api.CompensationHistogramResult o) {
  buildCounterCompensationHistogramResult++;
  if (buildCounterCompensationHistogramResult < 3) {
    checkNumericBucketingResult(o.result! as api.NumericBucketingResult);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompensationHistogramResult--;
}

core.List<api.CompensationEntry> buildUnnamed3562() {
  var o = <api.CompensationEntry>[];
  o.add(buildCompensationEntry());
  o.add(buildCompensationEntry());
  return o;
}

void checkUnnamed3562(core.List<api.CompensationEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompensationEntry(o[0] as api.CompensationEntry);
  checkCompensationEntry(o[1] as api.CompensationEntry);
}

core.int buildCounterCompensationInfo = 0;
api.CompensationInfo buildCompensationInfo() {
  var o = api.CompensationInfo();
  buildCounterCompensationInfo++;
  if (buildCounterCompensationInfo < 3) {
    o.annualizedBaseCompensationRange = buildCompensationRange();
    o.annualizedTotalCompensationRange = buildCompensationRange();
    o.entries = buildUnnamed3562();
  }
  buildCounterCompensationInfo--;
  return o;
}

void checkCompensationInfo(api.CompensationInfo o) {
  buildCounterCompensationInfo++;
  if (buildCounterCompensationInfo < 3) {
    checkCompensationRange(
        o.annualizedBaseCompensationRange! as api.CompensationRange);
    checkCompensationRange(
        o.annualizedTotalCompensationRange! as api.CompensationRange);
    checkUnnamed3562(o.entries!);
  }
  buildCounterCompensationInfo--;
}

core.int buildCounterCompensationRange = 0;
api.CompensationRange buildCompensationRange() {
  var o = api.CompensationRange();
  buildCounterCompensationRange++;
  if (buildCounterCompensationRange < 3) {
    o.maxCompensation = buildMoney();
    o.minCompensation = buildMoney();
  }
  buildCounterCompensationRange--;
  return o;
}

void checkCompensationRange(api.CompensationRange o) {
  buildCounterCompensationRange++;
  if (buildCounterCompensationRange < 3) {
    checkMoney(o.maxCompensation! as api.Money);
    checkMoney(o.minCompensation! as api.Money);
  }
  buildCounterCompensationRange--;
}

core.List<api.CompletionResult> buildUnnamed3563() {
  var o = <api.CompletionResult>[];
  o.add(buildCompletionResult());
  o.add(buildCompletionResult());
  return o;
}

void checkUnnamed3563(core.List<api.CompletionResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompletionResult(o[0] as api.CompletionResult);
  checkCompletionResult(o[1] as api.CompletionResult);
}

core.int buildCounterCompleteQueryResponse = 0;
api.CompleteQueryResponse buildCompleteQueryResponse() {
  var o = api.CompleteQueryResponse();
  buildCounterCompleteQueryResponse++;
  if (buildCounterCompleteQueryResponse < 3) {
    o.completionResults = buildUnnamed3563();
    o.metadata = buildResponseMetadata();
  }
  buildCounterCompleteQueryResponse--;
  return o;
}

void checkCompleteQueryResponse(api.CompleteQueryResponse o) {
  buildCounterCompleteQueryResponse++;
  if (buildCounterCompleteQueryResponse < 3) {
    checkUnnamed3563(o.completionResults!);
    checkResponseMetadata(o.metadata! as api.ResponseMetadata);
  }
  buildCounterCompleteQueryResponse--;
}

core.int buildCounterCompletionResult = 0;
api.CompletionResult buildCompletionResult() {
  var o = api.CompletionResult();
  buildCounterCompletionResult++;
  if (buildCounterCompletionResult < 3) {
    o.imageUri = 'foo';
    o.suggestion = 'foo';
    o.type = 'foo';
  }
  buildCounterCompletionResult--;
  return o;
}

void checkCompletionResult(api.CompletionResult o) {
  buildCounterCompletionResult++;
  if (buildCounterCompletionResult < 3) {
    unittest.expect(
      o.imageUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.suggestion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompletionResult--;
}

core.int buildCounterCreateClientEventRequest = 0;
api.CreateClientEventRequest buildCreateClientEventRequest() {
  var o = api.CreateClientEventRequest();
  buildCounterCreateClientEventRequest++;
  if (buildCounterCreateClientEventRequest < 3) {
    o.clientEvent = buildClientEvent();
  }
  buildCounterCreateClientEventRequest--;
  return o;
}

void checkCreateClientEventRequest(api.CreateClientEventRequest o) {
  buildCounterCreateClientEventRequest++;
  if (buildCounterCreateClientEventRequest < 3) {
    checkClientEvent(o.clientEvent! as api.ClientEvent);
  }
  buildCounterCreateClientEventRequest--;
}

core.int buildCounterCreateCompanyRequest = 0;
api.CreateCompanyRequest buildCreateCompanyRequest() {
  var o = api.CreateCompanyRequest();
  buildCounterCreateCompanyRequest++;
  if (buildCounterCreateCompanyRequest < 3) {
    o.company = buildCompany();
  }
  buildCounterCreateCompanyRequest--;
  return o;
}

void checkCreateCompanyRequest(api.CreateCompanyRequest o) {
  buildCounterCreateCompanyRequest++;
  if (buildCounterCreateCompanyRequest < 3) {
    checkCompany(o.company! as api.Company);
  }
  buildCounterCreateCompanyRequest--;
}

core.int buildCounterCreateJobRequest = 0;
api.CreateJobRequest buildCreateJobRequest() {
  var o = api.CreateJobRequest();
  buildCounterCreateJobRequest++;
  if (buildCounterCreateJobRequest < 3) {
    o.job = buildJob();
  }
  buildCounterCreateJobRequest--;
  return o;
}

void checkCreateJobRequest(api.CreateJobRequest o) {
  buildCounterCreateJobRequest++;
  if (buildCounterCreateJobRequest < 3) {
    checkJob(o.job! as api.Job);
  }
  buildCounterCreateJobRequest--;
}

core.List<core.String> buildUnnamed3564() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3564(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3565() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3565(core.List<core.String> o) {
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

core.int buildCounterCustomAttribute = 0;
api.CustomAttribute buildCustomAttribute() {
  var o = api.CustomAttribute();
  buildCounterCustomAttribute++;
  if (buildCounterCustomAttribute < 3) {
    o.filterable = true;
    o.longValues = buildUnnamed3564();
    o.stringValues = buildUnnamed3565();
  }
  buildCounterCustomAttribute--;
  return o;
}

void checkCustomAttribute(api.CustomAttribute o) {
  buildCounterCustomAttribute++;
  if (buildCounterCustomAttribute < 3) {
    unittest.expect(o.filterable!, unittest.isTrue);
    checkUnnamed3564(o.longValues!);
    checkUnnamed3565(o.stringValues!);
  }
  buildCounterCustomAttribute--;
}

core.int buildCounterCustomAttributeHistogramRequest = 0;
api.CustomAttributeHistogramRequest buildCustomAttributeHistogramRequest() {
  var o = api.CustomAttributeHistogramRequest();
  buildCounterCustomAttributeHistogramRequest++;
  if (buildCounterCustomAttributeHistogramRequest < 3) {
    o.key = 'foo';
    o.longValueHistogramBucketingOption = buildNumericBucketingOption();
    o.stringValueHistogram = true;
  }
  buildCounterCustomAttributeHistogramRequest--;
  return o;
}

void checkCustomAttributeHistogramRequest(
    api.CustomAttributeHistogramRequest o) {
  buildCounterCustomAttributeHistogramRequest++;
  if (buildCounterCustomAttributeHistogramRequest < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkNumericBucketingOption(
        o.longValueHistogramBucketingOption! as api.NumericBucketingOption);
    unittest.expect(o.stringValueHistogram!, unittest.isTrue);
  }
  buildCounterCustomAttributeHistogramRequest--;
}

core.Map<core.String, core.int> buildUnnamed3566() {
  var o = <core.String, core.int>{};
  o['x'] = 42;
  o['y'] = 42;
  return o;
}

void checkUnnamed3566(core.Map<core.String, core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals(42),
  );
  unittest.expect(
    o['y']!,
    unittest.equals(42),
  );
}

core.int buildCounterCustomAttributeHistogramResult = 0;
api.CustomAttributeHistogramResult buildCustomAttributeHistogramResult() {
  var o = api.CustomAttributeHistogramResult();
  buildCounterCustomAttributeHistogramResult++;
  if (buildCounterCustomAttributeHistogramResult < 3) {
    o.key = 'foo';
    o.longValueHistogramResult = buildNumericBucketingResult();
    o.stringValueHistogramResult = buildUnnamed3566();
  }
  buildCounterCustomAttributeHistogramResult--;
  return o;
}

void checkCustomAttributeHistogramResult(api.CustomAttributeHistogramResult o) {
  buildCounterCustomAttributeHistogramResult++;
  if (buildCounterCustomAttributeHistogramResult < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkNumericBucketingResult(
        o.longValueHistogramResult! as api.NumericBucketingResult);
    checkUnnamed3566(o.stringValueHistogramResult!);
  }
  buildCounterCustomAttributeHistogramResult--;
}

core.int buildCounterDeviceInfo = 0;
api.DeviceInfo buildDeviceInfo() {
  var o = api.DeviceInfo();
  buildCounterDeviceInfo++;
  if (buildCounterDeviceInfo < 3) {
    o.deviceType = 'foo';
    o.id = 'foo';
  }
  buildCounterDeviceInfo--;
  return o;
}

void checkDeviceInfo(api.DeviceInfo o) {
  buildCounterDeviceInfo++;
  if (buildCounterDeviceInfo < 3) {
    unittest.expect(
      o.deviceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceInfo--;
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

core.List<api.CompensationHistogramRequest> buildUnnamed3567() {
  var o = <api.CompensationHistogramRequest>[];
  o.add(buildCompensationHistogramRequest());
  o.add(buildCompensationHistogramRequest());
  return o;
}

void checkUnnamed3567(core.List<api.CompensationHistogramRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompensationHistogramRequest(o[0] as api.CompensationHistogramRequest);
  checkCompensationHistogramRequest(o[1] as api.CompensationHistogramRequest);
}

core.List<api.CustomAttributeHistogramRequest> buildUnnamed3568() {
  var o = <api.CustomAttributeHistogramRequest>[];
  o.add(buildCustomAttributeHistogramRequest());
  o.add(buildCustomAttributeHistogramRequest());
  return o;
}

void checkUnnamed3568(core.List<api.CustomAttributeHistogramRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomAttributeHistogramRequest(
      o[0] as api.CustomAttributeHistogramRequest);
  checkCustomAttributeHistogramRequest(
      o[1] as api.CustomAttributeHistogramRequest);
}

core.List<core.String> buildUnnamed3569() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3569(core.List<core.String> o) {
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

core.int buildCounterHistogramFacets = 0;
api.HistogramFacets buildHistogramFacets() {
  var o = api.HistogramFacets();
  buildCounterHistogramFacets++;
  if (buildCounterHistogramFacets < 3) {
    o.compensationHistogramFacets = buildUnnamed3567();
    o.customAttributeHistogramFacets = buildUnnamed3568();
    o.simpleHistogramFacets = buildUnnamed3569();
  }
  buildCounterHistogramFacets--;
  return o;
}

void checkHistogramFacets(api.HistogramFacets o) {
  buildCounterHistogramFacets++;
  if (buildCounterHistogramFacets < 3) {
    checkUnnamed3567(o.compensationHistogramFacets!);
    checkUnnamed3568(o.customAttributeHistogramFacets!);
    checkUnnamed3569(o.simpleHistogramFacets!);
  }
  buildCounterHistogramFacets--;
}

core.Map<core.String, core.int> buildUnnamed3570() {
  var o = <core.String, core.int>{};
  o['x'] = 42;
  o['y'] = 42;
  return o;
}

void checkUnnamed3570(core.Map<core.String, core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals(42),
  );
  unittest.expect(
    o['y']!,
    unittest.equals(42),
  );
}

core.int buildCounterHistogramResult = 0;
api.HistogramResult buildHistogramResult() {
  var o = api.HistogramResult();
  buildCounterHistogramResult++;
  if (buildCounterHistogramResult < 3) {
    o.searchType = 'foo';
    o.values = buildUnnamed3570();
  }
  buildCounterHistogramResult--;
  return o;
}

void checkHistogramResult(api.HistogramResult o) {
  buildCounterHistogramResult++;
  if (buildCounterHistogramResult < 3) {
    unittest.expect(
      o.searchType!,
      unittest.equals('foo'),
    );
    checkUnnamed3570(o.values!);
  }
  buildCounterHistogramResult--;
}

core.List<api.CompensationHistogramResult> buildUnnamed3571() {
  var o = <api.CompensationHistogramResult>[];
  o.add(buildCompensationHistogramResult());
  o.add(buildCompensationHistogramResult());
  return o;
}

void checkUnnamed3571(core.List<api.CompensationHistogramResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompensationHistogramResult(o[0] as api.CompensationHistogramResult);
  checkCompensationHistogramResult(o[1] as api.CompensationHistogramResult);
}

core.List<api.CustomAttributeHistogramResult> buildUnnamed3572() {
  var o = <api.CustomAttributeHistogramResult>[];
  o.add(buildCustomAttributeHistogramResult());
  o.add(buildCustomAttributeHistogramResult());
  return o;
}

void checkUnnamed3572(core.List<api.CustomAttributeHistogramResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomAttributeHistogramResult(
      o[0] as api.CustomAttributeHistogramResult);
  checkCustomAttributeHistogramResult(
      o[1] as api.CustomAttributeHistogramResult);
}

core.List<api.HistogramResult> buildUnnamed3573() {
  var o = <api.HistogramResult>[];
  o.add(buildHistogramResult());
  o.add(buildHistogramResult());
  return o;
}

void checkUnnamed3573(core.List<api.HistogramResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistogramResult(o[0] as api.HistogramResult);
  checkHistogramResult(o[1] as api.HistogramResult);
}

core.int buildCounterHistogramResults = 0;
api.HistogramResults buildHistogramResults() {
  var o = api.HistogramResults();
  buildCounterHistogramResults++;
  if (buildCounterHistogramResults < 3) {
    o.compensationHistogramResults = buildUnnamed3571();
    o.customAttributeHistogramResults = buildUnnamed3572();
    o.simpleHistogramResults = buildUnnamed3573();
  }
  buildCounterHistogramResults--;
  return o;
}

void checkHistogramResults(api.HistogramResults o) {
  buildCounterHistogramResults++;
  if (buildCounterHistogramResults < 3) {
    checkUnnamed3571(o.compensationHistogramResults!);
    checkUnnamed3572(o.customAttributeHistogramResults!);
    checkUnnamed3573(o.simpleHistogramResults!);
  }
  buildCounterHistogramResults--;
}

core.List<core.String> buildUnnamed3574() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3574(core.List<core.String> o) {
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

core.Map<core.String, api.CustomAttribute> buildUnnamed3575() {
  var o = <core.String, api.CustomAttribute>{};
  o['x'] = buildCustomAttribute();
  o['y'] = buildCustomAttribute();
  return o;
}

void checkUnnamed3575(core.Map<core.String, api.CustomAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomAttribute(o['x']! as api.CustomAttribute);
  checkCustomAttribute(o['y']! as api.CustomAttribute);
}

core.List<core.String> buildUnnamed3576() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3576(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3577() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3577(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3578() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3578(core.List<core.String> o) {
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

core.int buildCounterJob = 0;
api.Job buildJob() {
  var o = api.Job();
  buildCounterJob++;
  if (buildCounterJob < 3) {
    o.addresses = buildUnnamed3574();
    o.applicationInfo = buildApplicationInfo();
    o.companyDisplayName = 'foo';
    o.companyName = 'foo';
    o.compensationInfo = buildCompensationInfo();
    o.customAttributes = buildUnnamed3575();
    o.degreeTypes = buildUnnamed3576();
    o.department = 'foo';
    o.derivedInfo = buildJobDerivedInfo();
    o.description = 'foo';
    o.employmentTypes = buildUnnamed3577();
    o.incentives = 'foo';
    o.jobBenefits = buildUnnamed3578();
    o.jobEndTime = 'foo';
    o.jobLevel = 'foo';
    o.jobStartTime = 'foo';
    o.languageCode = 'foo';
    o.name = 'foo';
    o.postingCreateTime = 'foo';
    o.postingExpireTime = 'foo';
    o.postingPublishTime = 'foo';
    o.postingRegion = 'foo';
    o.postingUpdateTime = 'foo';
    o.processingOptions = buildProcessingOptions();
    o.promotionValue = 42;
    o.qualifications = 'foo';
    o.requisitionId = 'foo';
    o.responsibilities = 'foo';
    o.title = 'foo';
    o.visibility = 'foo';
  }
  buildCounterJob--;
  return o;
}

void checkJob(api.Job o) {
  buildCounterJob++;
  if (buildCounterJob < 3) {
    checkUnnamed3574(o.addresses!);
    checkApplicationInfo(o.applicationInfo! as api.ApplicationInfo);
    unittest.expect(
      o.companyDisplayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.companyName!,
      unittest.equals('foo'),
    );
    checkCompensationInfo(o.compensationInfo! as api.CompensationInfo);
    checkUnnamed3575(o.customAttributes!);
    checkUnnamed3576(o.degreeTypes!);
    unittest.expect(
      o.department!,
      unittest.equals('foo'),
    );
    checkJobDerivedInfo(o.derivedInfo! as api.JobDerivedInfo);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed3577(o.employmentTypes!);
    unittest.expect(
      o.incentives!,
      unittest.equals('foo'),
    );
    checkUnnamed3578(o.jobBenefits!);
    unittest.expect(
      o.jobEndTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobStartTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postingCreateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postingExpireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postingPublishTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postingRegion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postingUpdateTime!,
      unittest.equals('foo'),
    );
    checkProcessingOptions(o.processingOptions! as api.ProcessingOptions);
    unittest.expect(
      o.promotionValue!,
      unittest.equals(42),
    );
    unittest.expect(
      o.qualifications!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requisitionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responsibilities!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visibility!,
      unittest.equals('foo'),
    );
  }
  buildCounterJob--;
}

core.List<core.String> buildUnnamed3579() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3579(core.List<core.String> o) {
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

core.List<api.Location> buildUnnamed3580() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed3580(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterJobDerivedInfo = 0;
api.JobDerivedInfo buildJobDerivedInfo() {
  var o = api.JobDerivedInfo();
  buildCounterJobDerivedInfo++;
  if (buildCounterJobDerivedInfo < 3) {
    o.jobCategories = buildUnnamed3579();
    o.locations = buildUnnamed3580();
  }
  buildCounterJobDerivedInfo--;
  return o;
}

void checkJobDerivedInfo(api.JobDerivedInfo o) {
  buildCounterJobDerivedInfo++;
  if (buildCounterJobDerivedInfo < 3) {
    checkUnnamed3579(o.jobCategories!);
    checkUnnamed3580(o.locations!);
  }
  buildCounterJobDerivedInfo--;
}

core.List<core.String> buildUnnamed3581() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3581(core.List<core.String> o) {
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

core.int buildCounterJobEvent = 0;
api.JobEvent buildJobEvent() {
  var o = api.JobEvent();
  buildCounterJobEvent++;
  if (buildCounterJobEvent < 3) {
    o.jobs = buildUnnamed3581();
    o.type = 'foo';
  }
  buildCounterJobEvent--;
  return o;
}

void checkJobEvent(api.JobEvent o) {
  buildCounterJobEvent++;
  if (buildCounterJobEvent < 3) {
    checkUnnamed3581(o.jobs!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobEvent--;
}

core.List<core.String> buildUnnamed3582() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3582(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3583() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3583(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3584() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3584(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3585() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3585(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3586() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3586(core.List<core.String> o) {
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

core.List<api.LocationFilter> buildUnnamed3587() {
  var o = <api.LocationFilter>[];
  o.add(buildLocationFilter());
  o.add(buildLocationFilter());
  return o;
}

void checkUnnamed3587(core.List<api.LocationFilter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocationFilter(o[0] as api.LocationFilter);
  checkLocationFilter(o[1] as api.LocationFilter);
}

core.int buildCounterJobQuery = 0;
api.JobQuery buildJobQuery() {
  var o = api.JobQuery();
  buildCounterJobQuery++;
  if (buildCounterJobQuery < 3) {
    o.commuteFilter = buildCommuteFilter();
    o.companyDisplayNames = buildUnnamed3582();
    o.companyNames = buildUnnamed3583();
    o.compensationFilter = buildCompensationFilter();
    o.customAttributeFilter = 'foo';
    o.disableSpellCheck = true;
    o.employmentTypes = buildUnnamed3584();
    o.jobCategories = buildUnnamed3585();
    o.languageCodes = buildUnnamed3586();
    o.locationFilters = buildUnnamed3587();
    o.publishTimeRange = buildTimestampRange();
    o.query = 'foo';
    o.queryLanguageCode = 'foo';
  }
  buildCounterJobQuery--;
  return o;
}

void checkJobQuery(api.JobQuery o) {
  buildCounterJobQuery++;
  if (buildCounterJobQuery < 3) {
    checkCommuteFilter(o.commuteFilter! as api.CommuteFilter);
    checkUnnamed3582(o.companyDisplayNames!);
    checkUnnamed3583(o.companyNames!);
    checkCompensationFilter(o.compensationFilter! as api.CompensationFilter);
    unittest.expect(
      o.customAttributeFilter!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disableSpellCheck!, unittest.isTrue);
    checkUnnamed3584(o.employmentTypes!);
    checkUnnamed3585(o.jobCategories!);
    checkUnnamed3586(o.languageCodes!);
    checkUnnamed3587(o.locationFilters!);
    checkTimestampRange(o.publishTimeRange! as api.TimestampRange);
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queryLanguageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobQuery--;
}

core.int buildCounterLatLng = 0;
api.LatLng buildLatLng() {
  var o = api.LatLng();
  buildCounterLatLng++;
  if (buildCounterLatLng < 3) {
    o.latitude = 42.0;
    o.longitude = 42.0;
  }
  buildCounterLatLng--;
  return o;
}

void checkLatLng(api.LatLng o) {
  buildCounterLatLng++;
  if (buildCounterLatLng < 3) {
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
  }
  buildCounterLatLng--;
}

core.List<api.Company> buildUnnamed3588() {
  var o = <api.Company>[];
  o.add(buildCompany());
  o.add(buildCompany());
  return o;
}

void checkUnnamed3588(core.List<api.Company> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompany(o[0] as api.Company);
  checkCompany(o[1] as api.Company);
}

core.int buildCounterListCompaniesResponse = 0;
api.ListCompaniesResponse buildListCompaniesResponse() {
  var o = api.ListCompaniesResponse();
  buildCounterListCompaniesResponse++;
  if (buildCounterListCompaniesResponse < 3) {
    o.companies = buildUnnamed3588();
    o.metadata = buildResponseMetadata();
    o.nextPageToken = 'foo';
  }
  buildCounterListCompaniesResponse--;
  return o;
}

void checkListCompaniesResponse(api.ListCompaniesResponse o) {
  buildCounterListCompaniesResponse++;
  if (buildCounterListCompaniesResponse < 3) {
    checkUnnamed3588(o.companies!);
    checkResponseMetadata(o.metadata! as api.ResponseMetadata);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCompaniesResponse--;
}

core.List<api.Job> buildUnnamed3589() {
  var o = <api.Job>[];
  o.add(buildJob());
  o.add(buildJob());
  return o;
}

void checkUnnamed3589(core.List<api.Job> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJob(o[0] as api.Job);
  checkJob(o[1] as api.Job);
}

core.int buildCounterListJobsResponse = 0;
api.ListJobsResponse buildListJobsResponse() {
  var o = api.ListJobsResponse();
  buildCounterListJobsResponse++;
  if (buildCounterListJobsResponse < 3) {
    o.jobs = buildUnnamed3589();
    o.metadata = buildResponseMetadata();
    o.nextPageToken = 'foo';
  }
  buildCounterListJobsResponse--;
  return o;
}

void checkListJobsResponse(api.ListJobsResponse o) {
  buildCounterListJobsResponse++;
  if (buildCounterListJobsResponse < 3) {
    checkUnnamed3589(o.jobs!);
    checkResponseMetadata(o.metadata! as api.ResponseMetadata);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListJobsResponse--;
}

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.latLng = buildLatLng();
    o.locationType = 'foo';
    o.postalAddress = buildPostalAddress();
    o.radiusInMiles = 42.0;
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    checkLatLng(o.latLng! as api.LatLng);
    unittest.expect(
      o.locationType!,
      unittest.equals('foo'),
    );
    checkPostalAddress(o.postalAddress! as api.PostalAddress);
    unittest.expect(
      o.radiusInMiles!,
      unittest.equals(42.0),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterLocationFilter = 0;
api.LocationFilter buildLocationFilter() {
  var o = api.LocationFilter();
  buildCounterLocationFilter++;
  if (buildCounterLocationFilter < 3) {
    o.address = 'foo';
    o.distanceInMiles = 42.0;
    o.latLng = buildLatLng();
    o.regionCode = 'foo';
    o.telecommutePreference = 'foo';
  }
  buildCounterLocationFilter--;
  return o;
}

void checkLocationFilter(api.LocationFilter o) {
  buildCounterLocationFilter++;
  if (buildCounterLocationFilter < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.distanceInMiles!,
      unittest.equals(42.0),
    );
    checkLatLng(o.latLng! as api.LatLng);
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.telecommutePreference!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocationFilter--;
}

core.int buildCounterMatchingJob = 0;
api.MatchingJob buildMatchingJob() {
  var o = api.MatchingJob();
  buildCounterMatchingJob++;
  if (buildCounterMatchingJob < 3) {
    o.commuteInfo = buildCommuteInfo();
    o.job = buildJob();
    o.jobSummary = 'foo';
    o.jobTitleSnippet = 'foo';
    o.searchTextSnippet = 'foo';
  }
  buildCounterMatchingJob--;
  return o;
}

void checkMatchingJob(api.MatchingJob o) {
  buildCounterMatchingJob++;
  if (buildCounterMatchingJob < 3) {
    checkCommuteInfo(o.commuteInfo! as api.CommuteInfo);
    checkJob(o.job! as api.Job);
    unittest.expect(
      o.jobSummary!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobTitleSnippet!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.searchTextSnippet!,
      unittest.equals('foo'),
    );
  }
  buildCounterMatchingJob--;
}

core.Map<core.String, api.NamespacedDebugInput> buildUnnamed3590() {
  var o = <core.String, api.NamespacedDebugInput>{};
  o['x'] = buildNamespacedDebugInput();
  o['y'] = buildNamespacedDebugInput();
  return o;
}

void checkUnnamed3590(core.Map<core.String, api.NamespacedDebugInput> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNamespacedDebugInput(o['x']! as api.NamespacedDebugInput);
  checkNamespacedDebugInput(o['y']! as api.NamespacedDebugInput);
}

core.int buildCounterMendelDebugInput = 0;
api.MendelDebugInput buildMendelDebugInput() {
  var o = api.MendelDebugInput();
  buildCounterMendelDebugInput++;
  if (buildCounterMendelDebugInput < 3) {
    o.namespacedDebugInput = buildUnnamed3590();
  }
  buildCounterMendelDebugInput--;
  return o;
}

void checkMendelDebugInput(api.MendelDebugInput o) {
  buildCounterMendelDebugInput++;
  if (buildCounterMendelDebugInput < 3) {
    checkUnnamed3590(o.namespacedDebugInput!);
  }
  buildCounterMendelDebugInput--;
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

core.List<core.String> buildUnnamed3591() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3591(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3592() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3592(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed3593() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed3593(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.String> buildUnnamed3594() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3594(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3595() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3595(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed3596() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed3596(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<core.String> buildUnnamed3597() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3597(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3598() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3598(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed3599() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed3599(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.Map<core.String, core.String> buildUnnamed3600() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed3600(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.bool> buildUnnamed3601() {
  var o = <core.String, core.bool>{};
  o['x'] = true;
  o['y'] = true;
  return o;
}

void checkUnnamed3601(core.Map<core.String, core.bool> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(o['x']!, unittest.isTrue);
  unittest.expect(o['y']!, unittest.isTrue);
}

core.int buildCounterNamespacedDebugInput = 0;
api.NamespacedDebugInput buildNamespacedDebugInput() {
  var o = api.NamespacedDebugInput();
  buildCounterNamespacedDebugInput++;
  if (buildCounterNamespacedDebugInput < 3) {
    o.absolutelyForcedExpNames = buildUnnamed3591();
    o.absolutelyForcedExpTags = buildUnnamed3592();
    o.absolutelyForcedExps = buildUnnamed3593();
    o.conditionallyForcedExpNames = buildUnnamed3594();
    o.conditionallyForcedExpTags = buildUnnamed3595();
    o.conditionallyForcedExps = buildUnnamed3596();
    o.disableAutomaticEnrollmentSelection = true;
    o.disableExpNames = buildUnnamed3597();
    o.disableExpTags = buildUnnamed3598();
    o.disableExps = buildUnnamed3599();
    o.disableManualEnrollmentSelection = true;
    o.disableOrganicSelection = true;
    o.forcedFlags = buildUnnamed3600();
    o.forcedRollouts = buildUnnamed3601();
  }
  buildCounterNamespacedDebugInput--;
  return o;
}

void checkNamespacedDebugInput(api.NamespacedDebugInput o) {
  buildCounterNamespacedDebugInput++;
  if (buildCounterNamespacedDebugInput < 3) {
    checkUnnamed3591(o.absolutelyForcedExpNames!);
    checkUnnamed3592(o.absolutelyForcedExpTags!);
    checkUnnamed3593(o.absolutelyForcedExps!);
    checkUnnamed3594(o.conditionallyForcedExpNames!);
    checkUnnamed3595(o.conditionallyForcedExpTags!);
    checkUnnamed3596(o.conditionallyForcedExps!);
    unittest.expect(o.disableAutomaticEnrollmentSelection!, unittest.isTrue);
    checkUnnamed3597(o.disableExpNames!);
    checkUnnamed3598(o.disableExpTags!);
    checkUnnamed3599(o.disableExps!);
    unittest.expect(o.disableManualEnrollmentSelection!, unittest.isTrue);
    unittest.expect(o.disableOrganicSelection!, unittest.isTrue);
    checkUnnamed3600(o.forcedFlags!);
    checkUnnamed3601(o.forcedRollouts!);
  }
  buildCounterNamespacedDebugInput--;
}

core.List<core.double> buildUnnamed3602() {
  var o = <core.double>[];
  o.add(42.0);
  o.add(42.0);
  return o;
}

void checkUnnamed3602(core.List<core.double> o) {
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

core.int buildCounterNumericBucketingOption = 0;
api.NumericBucketingOption buildNumericBucketingOption() {
  var o = api.NumericBucketingOption();
  buildCounterNumericBucketingOption++;
  if (buildCounterNumericBucketingOption < 3) {
    o.bucketBounds = buildUnnamed3602();
    o.requiresMinMax = true;
  }
  buildCounterNumericBucketingOption--;
  return o;
}

void checkNumericBucketingOption(api.NumericBucketingOption o) {
  buildCounterNumericBucketingOption++;
  if (buildCounterNumericBucketingOption < 3) {
    checkUnnamed3602(o.bucketBounds!);
    unittest.expect(o.requiresMinMax!, unittest.isTrue);
  }
  buildCounterNumericBucketingOption--;
}

core.List<api.BucketizedCount> buildUnnamed3603() {
  var o = <api.BucketizedCount>[];
  o.add(buildBucketizedCount());
  o.add(buildBucketizedCount());
  return o;
}

void checkUnnamed3603(core.List<api.BucketizedCount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBucketizedCount(o[0] as api.BucketizedCount);
  checkBucketizedCount(o[1] as api.BucketizedCount);
}

core.int buildCounterNumericBucketingResult = 0;
api.NumericBucketingResult buildNumericBucketingResult() {
  var o = api.NumericBucketingResult();
  buildCounterNumericBucketingResult++;
  if (buildCounterNumericBucketingResult < 3) {
    o.counts = buildUnnamed3603();
    o.maxValue = 42.0;
    o.minValue = 42.0;
  }
  buildCounterNumericBucketingResult--;
  return o;
}

void checkNumericBucketingResult(api.NumericBucketingResult o) {
  buildCounterNumericBucketingResult++;
  if (buildCounterNumericBucketingResult < 3) {
    checkUnnamed3603(o.counts!);
    unittest.expect(
      o.maxValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.minValue!,
      unittest.equals(42.0),
    );
  }
  buildCounterNumericBucketingResult--;
}

core.List<core.String> buildUnnamed3604() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3604(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3605() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3605(core.List<core.String> o) {
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

core.int buildCounterPostalAddress = 0;
api.PostalAddress buildPostalAddress() {
  var o = api.PostalAddress();
  buildCounterPostalAddress++;
  if (buildCounterPostalAddress < 3) {
    o.addressLines = buildUnnamed3604();
    o.administrativeArea = 'foo';
    o.languageCode = 'foo';
    o.locality = 'foo';
    o.organization = 'foo';
    o.postalCode = 'foo';
    o.recipients = buildUnnamed3605();
    o.regionCode = 'foo';
    o.revision = 42;
    o.sortingCode = 'foo';
    o.sublocality = 'foo';
  }
  buildCounterPostalAddress--;
  return o;
}

void checkPostalAddress(api.PostalAddress o) {
  buildCounterPostalAddress++;
  if (buildCounterPostalAddress < 3) {
    checkUnnamed3604(o.addressLines!);
    unittest.expect(
      o.administrativeArea!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locality!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.organization!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postalCode!,
      unittest.equals('foo'),
    );
    checkUnnamed3605(o.recipients!);
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revision!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sortingCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sublocality!,
      unittest.equals('foo'),
    );
  }
  buildCounterPostalAddress--;
}

core.int buildCounterProcessingOptions = 0;
api.ProcessingOptions buildProcessingOptions() {
  var o = api.ProcessingOptions();
  buildCounterProcessingOptions++;
  if (buildCounterProcessingOptions < 3) {
    o.disableStreetAddressResolution = true;
    o.htmlSanitization = 'foo';
  }
  buildCounterProcessingOptions--;
  return o;
}

void checkProcessingOptions(api.ProcessingOptions o) {
  buildCounterProcessingOptions++;
  if (buildCounterProcessingOptions < 3) {
    unittest.expect(o.disableStreetAddressResolution!, unittest.isTrue);
    unittest.expect(
      o.htmlSanitization!,
      unittest.equals('foo'),
    );
  }
  buildCounterProcessingOptions--;
}

core.int buildCounterRequestMetadata = 0;
api.RequestMetadata buildRequestMetadata() {
  var o = api.RequestMetadata();
  buildCounterRequestMetadata++;
  if (buildCounterRequestMetadata < 3) {
    o.deviceInfo = buildDeviceInfo();
    o.domain = 'foo';
    o.sessionId = 'foo';
    o.userId = 'foo';
  }
  buildCounterRequestMetadata--;
  return o;
}

void checkRequestMetadata(api.RequestMetadata o) {
  buildCounterRequestMetadata++;
  if (buildCounterRequestMetadata < 3) {
    checkDeviceInfo(o.deviceInfo! as api.DeviceInfo);
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sessionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRequestMetadata--;
}

core.int buildCounterResponseMetadata = 0;
api.ResponseMetadata buildResponseMetadata() {
  var o = api.ResponseMetadata();
  buildCounterResponseMetadata++;
  if (buildCounterResponseMetadata < 3) {
    o.requestId = 'foo';
  }
  buildCounterResponseMetadata--;
  return o;
}

void checkResponseMetadata(api.ResponseMetadata o) {
  buildCounterResponseMetadata++;
  if (buildCounterResponseMetadata < 3) {
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
  }
  buildCounterResponseMetadata--;
}

core.int buildCounterSearchJobsRequest = 0;
api.SearchJobsRequest buildSearchJobsRequest() {
  var o = api.SearchJobsRequest();
  buildCounterSearchJobsRequest++;
  if (buildCounterSearchJobsRequest < 3) {
    o.disableKeywordMatch = true;
    o.diversificationLevel = 'foo';
    o.enableBroadening = true;
    o.histogramFacets = buildHistogramFacets();
    o.jobQuery = buildJobQuery();
    o.jobView = 'foo';
    o.offset = 42;
    o.orderBy = 'foo';
    o.pageSize = 42;
    o.pageToken = 'foo';
    o.requestMetadata = buildRequestMetadata();
    o.requirePreciseResultSize = true;
    o.searchMode = 'foo';
  }
  buildCounterSearchJobsRequest--;
  return o;
}

void checkSearchJobsRequest(api.SearchJobsRequest o) {
  buildCounterSearchJobsRequest++;
  if (buildCounterSearchJobsRequest < 3) {
    unittest.expect(o.disableKeywordMatch!, unittest.isTrue);
    unittest.expect(
      o.diversificationLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enableBroadening!, unittest.isTrue);
    checkHistogramFacets(o.histogramFacets! as api.HistogramFacets);
    checkJobQuery(o.jobQuery! as api.JobQuery);
    unittest.expect(
      o.jobView!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.offset!,
      unittest.equals(42),
    );
    unittest.expect(
      o.orderBy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkRequestMetadata(o.requestMetadata! as api.RequestMetadata);
    unittest.expect(o.requirePreciseResultSize!, unittest.isTrue);
    unittest.expect(
      o.searchMode!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchJobsRequest--;
}

core.List<api.Location> buildUnnamed3606() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed3606(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.List<api.MatchingJob> buildUnnamed3607() {
  var o = <api.MatchingJob>[];
  o.add(buildMatchingJob());
  o.add(buildMatchingJob());
  return o;
}

void checkUnnamed3607(core.List<api.MatchingJob> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMatchingJob(o[0] as api.MatchingJob);
  checkMatchingJob(o[1] as api.MatchingJob);
}

core.int buildCounterSearchJobsResponse = 0;
api.SearchJobsResponse buildSearchJobsResponse() {
  var o = api.SearchJobsResponse();
  buildCounterSearchJobsResponse++;
  if (buildCounterSearchJobsResponse < 3) {
    o.broadenedQueryJobsCount = 42;
    o.estimatedTotalSize = 42;
    o.histogramResults = buildHistogramResults();
    o.locationFilters = buildUnnamed3606();
    o.matchingJobs = buildUnnamed3607();
    o.metadata = buildResponseMetadata();
    o.nextPageToken = 'foo';
    o.spellCorrection = buildSpellingCorrection();
    o.totalSize = 42;
  }
  buildCounterSearchJobsResponse--;
  return o;
}

void checkSearchJobsResponse(api.SearchJobsResponse o) {
  buildCounterSearchJobsResponse++;
  if (buildCounterSearchJobsResponse < 3) {
    unittest.expect(
      o.broadenedQueryJobsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.estimatedTotalSize!,
      unittest.equals(42),
    );
    checkHistogramResults(o.histogramResults! as api.HistogramResults);
    checkUnnamed3606(o.locationFilters!);
    checkUnnamed3607(o.matchingJobs!);
    checkResponseMetadata(o.metadata! as api.ResponseMetadata);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkSpellingCorrection(o.spellCorrection! as api.SpellingCorrection);
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterSearchJobsResponse--;
}

core.int buildCounterSpellingCorrection = 0;
api.SpellingCorrection buildSpellingCorrection() {
  var o = api.SpellingCorrection();
  buildCounterSpellingCorrection++;
  if (buildCounterSpellingCorrection < 3) {
    o.corrected = true;
    o.correctedText = 'foo';
  }
  buildCounterSpellingCorrection--;
  return o;
}

void checkSpellingCorrection(api.SpellingCorrection o) {
  buildCounterSpellingCorrection++;
  if (buildCounterSpellingCorrection < 3) {
    unittest.expect(o.corrected!, unittest.isTrue);
    unittest.expect(
      o.correctedText!,
      unittest.equals('foo'),
    );
  }
  buildCounterSpellingCorrection--;
}

core.int buildCounterTimeOfDay = 0;
api.TimeOfDay buildTimeOfDay() {
  var o = api.TimeOfDay();
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    o.hours = 42;
    o.minutes = 42;
    o.nanos = 42;
    o.seconds = 42;
  }
  buildCounterTimeOfDay--;
  return o;
}

void checkTimeOfDay(api.TimeOfDay o) {
  buildCounterTimeOfDay++;
  if (buildCounterTimeOfDay < 3) {
    unittest.expect(
      o.hours!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minutes!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.seconds!,
      unittest.equals(42),
    );
  }
  buildCounterTimeOfDay--;
}

core.int buildCounterTimestampRange = 0;
api.TimestampRange buildTimestampRange() {
  var o = api.TimestampRange();
  buildCounterTimestampRange++;
  if (buildCounterTimestampRange < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterTimestampRange--;
  return o;
}

void checkTimestampRange(api.TimestampRange o) {
  buildCounterTimestampRange++;
  if (buildCounterTimestampRange < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimestampRange--;
}

core.int buildCounterUpdateCompanyRequest = 0;
api.UpdateCompanyRequest buildUpdateCompanyRequest() {
  var o = api.UpdateCompanyRequest();
  buildCounterUpdateCompanyRequest++;
  if (buildCounterUpdateCompanyRequest < 3) {
    o.company = buildCompany();
    o.updateMask = 'foo';
  }
  buildCounterUpdateCompanyRequest--;
  return o;
}

void checkUpdateCompanyRequest(api.UpdateCompanyRequest o) {
  buildCounterUpdateCompanyRequest++;
  if (buildCounterUpdateCompanyRequest < 3) {
    checkCompany(o.company! as api.Company);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateCompanyRequest--;
}

core.int buildCounterUpdateJobRequest = 0;
api.UpdateJobRequest buildUpdateJobRequest() {
  var o = api.UpdateJobRequest();
  buildCounterUpdateJobRequest++;
  if (buildCounterUpdateJobRequest < 3) {
    o.job = buildJob();
    o.updateMask = 'foo';
  }
  buildCounterUpdateJobRequest--;
  return o;
}

void checkUpdateJobRequest(api.UpdateJobRequest o) {
  buildCounterUpdateJobRequest++;
  if (buildCounterUpdateJobRequest < 3) {
    checkJob(o.job! as api.Job);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateJobRequest--;
}

core.List<core.String> buildUnnamed3608() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3608(core.List<core.String> o) {
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
  unittest.group('obj-schema-ApplicationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationInfo(od as api.ApplicationInfo);
    });
  });

  unittest.group('obj-schema-BatchDeleteJobsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeleteJobsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeleteJobsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeleteJobsRequest(od as api.BatchDeleteJobsRequest);
    });
  });

  unittest.group('obj-schema-BucketRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucketRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BucketRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBucketRange(od as api.BucketRange);
    });
  });

  unittest.group('obj-schema-BucketizedCount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucketizedCount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BucketizedCount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBucketizedCount(od as api.BucketizedCount);
    });
  });

  unittest.group('obj-schema-ClientEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClientEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClientEvent(od as api.ClientEvent);
    });
  });

  unittest.group('obj-schema-CommuteFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommuteFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommuteFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommuteFilter(od as api.CommuteFilter);
    });
  });

  unittest.group('obj-schema-CommuteInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCommuteInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CommuteInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCommuteInfo(od as api.CommuteInfo);
    });
  });

  unittest.group('obj-schema-Company', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompany();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Company.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCompany(od as api.Company);
    });
  });

  unittest.group('obj-schema-CompanyDerivedInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompanyDerivedInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompanyDerivedInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompanyDerivedInfo(od as api.CompanyDerivedInfo);
    });
  });

  unittest.group('obj-schema-CompensationEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompensationEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompensationEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompensationEntry(od as api.CompensationEntry);
    });
  });

  unittest.group('obj-schema-CompensationFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompensationFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompensationFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompensationFilter(od as api.CompensationFilter);
    });
  });

  unittest.group('obj-schema-CompensationHistogramRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompensationHistogramRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompensationHistogramRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompensationHistogramRequest(od as api.CompensationHistogramRequest);
    });
  });

  unittest.group('obj-schema-CompensationHistogramResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompensationHistogramResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompensationHistogramResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompensationHistogramResult(od as api.CompensationHistogramResult);
    });
  });

  unittest.group('obj-schema-CompensationInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompensationInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompensationInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompensationInfo(od as api.CompensationInfo);
    });
  });

  unittest.group('obj-schema-CompensationRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompensationRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompensationRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompensationRange(od as api.CompensationRange);
    });
  });

  unittest.group('obj-schema-CompleteQueryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompleteQueryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompleteQueryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompleteQueryResponse(od as api.CompleteQueryResponse);
    });
  });

  unittest.group('obj-schema-CompletionResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCompletionResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CompletionResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCompletionResult(od as api.CompletionResult);
    });
  });

  unittest.group('obj-schema-CreateClientEventRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateClientEventRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateClientEventRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateClientEventRequest(od as api.CreateClientEventRequest);
    });
  });

  unittest.group('obj-schema-CreateCompanyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateCompanyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateCompanyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateCompanyRequest(od as api.CreateCompanyRequest);
    });
  });

  unittest.group('obj-schema-CreateJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateJobRequest(od as api.CreateJobRequest);
    });
  });

  unittest.group('obj-schema-CustomAttribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomAttribute.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomAttribute(od as api.CustomAttribute);
    });
  });

  unittest.group('obj-schema-CustomAttributeHistogramRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomAttributeHistogramRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomAttributeHistogramRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomAttributeHistogramRequest(
          od as api.CustomAttributeHistogramRequest);
    });
  });

  unittest.group('obj-schema-CustomAttributeHistogramResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomAttributeHistogramResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomAttributeHistogramResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomAttributeHistogramResult(
          od as api.CustomAttributeHistogramResult);
    });
  });

  unittest.group('obj-schema-DeviceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DeviceInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDeviceInfo(od as api.DeviceInfo);
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

  unittest.group('obj-schema-HistogramFacets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistogramFacets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistogramFacets.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistogramFacets(od as api.HistogramFacets);
    });
  });

  unittest.group('obj-schema-HistogramResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistogramResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistogramResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistogramResult(od as api.HistogramResult);
    });
  });

  unittest.group('obj-schema-HistogramResults', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistogramResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistogramResults.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistogramResults(od as api.HistogramResults);
    });
  });

  unittest.group('obj-schema-Job', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Job.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJob(od as api.Job);
    });
  });

  unittest.group('obj-schema-JobDerivedInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobDerivedInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobDerivedInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobDerivedInfo(od as api.JobDerivedInfo);
    });
  });

  unittest.group('obj-schema-JobEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.JobEvent.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJobEvent(od as api.JobEvent);
    });
  });

  unittest.group('obj-schema-JobQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.JobQuery.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJobQuery(od as api.JobQuery);
    });
  });

  unittest.group('obj-schema-LatLng', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLatLng();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LatLng.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLatLng(od as api.LatLng);
    });
  });

  unittest.group('obj-schema-ListCompaniesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCompaniesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCompaniesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCompaniesResponse(od as api.ListCompaniesResponse);
    });
  });

  unittest.group('obj-schema-ListJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListJobsResponse(od as api.ListJobsResponse);
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

  unittest.group('obj-schema-LocationFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocationFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocationFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocationFilter(od as api.LocationFilter);
    });
  });

  unittest.group('obj-schema-MatchingJob', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMatchingJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MatchingJob.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMatchingJob(od as api.MatchingJob);
    });
  });

  unittest.group('obj-schema-MendelDebugInput', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMendelDebugInput();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MendelDebugInput.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMendelDebugInput(od as api.MendelDebugInput);
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

  unittest.group('obj-schema-NamespacedDebugInput', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNamespacedDebugInput();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NamespacedDebugInput.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNamespacedDebugInput(od as api.NamespacedDebugInput);
    });
  });

  unittest.group('obj-schema-NumericBucketingOption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNumericBucketingOption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NumericBucketingOption.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNumericBucketingOption(od as api.NumericBucketingOption);
    });
  });

  unittest.group('obj-schema-NumericBucketingResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNumericBucketingResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NumericBucketingResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNumericBucketingResult(od as api.NumericBucketingResult);
    });
  });

  unittest.group('obj-schema-PostalAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPostalAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PostalAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPostalAddress(od as api.PostalAddress);
    });
  });

  unittest.group('obj-schema-ProcessingOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProcessingOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProcessingOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProcessingOptions(od as api.ProcessingOptions);
    });
  });

  unittest.group('obj-schema-RequestMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRequestMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RequestMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRequestMetadata(od as api.RequestMetadata);
    });
  });

  unittest.group('obj-schema-ResponseMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResponseMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResponseMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResponseMetadata(od as api.ResponseMetadata);
    });
  });

  unittest.group('obj-schema-SearchJobsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchJobsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchJobsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchJobsRequest(od as api.SearchJobsRequest);
    });
  });

  unittest.group('obj-schema-SearchJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchJobsResponse(od as api.SearchJobsResponse);
    });
  });

  unittest.group('obj-schema-SpellingCorrection', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpellingCorrection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpellingCorrection.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpellingCorrection(od as api.SpellingCorrection);
    });
  });

  unittest.group('obj-schema-TimeOfDay', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeOfDay();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeOfDay.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeOfDay(od as api.TimeOfDay);
    });
  });

  unittest.group('obj-schema-TimestampRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimestampRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TimestampRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTimestampRange(od as api.TimestampRange);
    });
  });

  unittest.group('obj-schema-UpdateCompanyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateCompanyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateCompanyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateCompanyRequest(od as api.UpdateCompanyRequest);
    });
  });

  unittest.group('obj-schema-UpdateJobRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateJobRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateJobRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateJobRequest(od as api.UpdateJobRequest);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--complete', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects;
      var arg_name = 'foo';
      var arg_companyName = 'foo';
      var arg_languageCode = 'foo';
      var arg_languageCodes = buildUnnamed3608();
      var arg_pageSize = 42;
      var arg_query = 'foo';
      var arg_scope = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v3/"),
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
          queryMap["companyName"]!.first,
          unittest.equals(arg_companyName),
        );
        unittest.expect(
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["languageCodes"]!,
          unittest.equals(arg_languageCodes),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["scope"]!.first,
          unittest.equals(arg_scope),
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
        var resp = convert.json.encode(buildCompleteQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.complete(arg_name,
          companyName: arg_companyName,
          languageCode: arg_languageCode,
          languageCodes: arg_languageCodes,
          pageSize: arg_pageSize,
          query: arg_query,
          scope: arg_scope,
          type: arg_type,
          $fields: arg_$fields);
      checkCompleteQueryResponse(response as api.CompleteQueryResponse);
    });
  });

  unittest.group('resource-ProjectsClientEventsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.clientEvents;
      var arg_request = buildCreateClientEventRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateClientEventRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateClientEventRequest(obj as api.CreateClientEventRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildClientEvent());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkClientEvent(response as api.ClientEvent);
    });
  });

  unittest.group('resource-ProjectsCompaniesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.companies;
      var arg_request = buildCreateCompanyRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateCompanyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateCompanyRequest(obj as api.CreateCompanyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildCompany());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkCompany(response as api.Company);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.companies;
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
          unittest.equals("v3/"),
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
      var res = api.CloudTalentSolutionApi(mock).projects.companies;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildCompany());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkCompany(response as api.Company);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.companies;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_requireOpenJobs = true;
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
          unittest.equals("v3/"),
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
          queryMap["requireOpenJobs"]!.first,
          unittest.equals("$arg_requireOpenJobs"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCompaniesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          requireOpenJobs: arg_requireOpenJobs,
          $fields: arg_$fields);
      checkListCompaniesResponse(response as api.ListCompaniesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.companies;
      var arg_request = buildUpdateCompanyRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateCompanyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateCompanyRequest(obj as api.UpdateCompanyRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildCompany());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkCompany(response as api.Company);
    });
  });

  unittest.group('resource-ProjectsJobsResource', () {
    unittest.test('method--batchDelete', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
      var arg_request = buildBatchDeleteJobsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchDeleteJobsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchDeleteJobsRequest(obj as api.BatchDeleteJobsRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
          await res.batchDelete(arg_request, arg_parent, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
      var arg_request = buildCreateJobRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateJobRequest(obj as api.CreateJobRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
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
          unittest.equals("v3/"),
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
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_jobView = 'foo';
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
          unittest.equals("v3/"),
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
          queryMap["jobView"]!.first,
          unittest.equals(arg_jobView),
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
        var resp = convert.json.encode(buildListJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          jobView: arg_jobView,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListJobsResponse(response as api.ListJobsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
      var arg_request = buildUpdateJobRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateJobRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateJobRequest(obj as api.UpdateJobRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
      var arg_request = buildSearchJobsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchJobsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchJobsRequest(obj as api.SearchJobsRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildSearchJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.search(arg_request, arg_parent, $fields: arg_$fields);
      checkSearchJobsResponse(response as api.SearchJobsResponse);
    });

    unittest.test('method--searchForAlert', () async {
      var mock = HttpServerMock();
      var res = api.CloudTalentSolutionApi(mock).projects.jobs;
      var arg_request = buildSearchJobsRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchJobsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchJobsRequest(obj as api.SearchJobsRequest);

        var path = (req.url).path;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildSearchJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchForAlert(arg_request, arg_parent,
          $fields: arg_$fields);
      checkSearchJobsResponse(response as api.SearchJobsResponse);
    });
  });
}
