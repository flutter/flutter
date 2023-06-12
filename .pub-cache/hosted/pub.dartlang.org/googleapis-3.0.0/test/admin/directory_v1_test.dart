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

import 'package:googleapis/admin/directory_v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAlias = 0;
api.Alias buildAlias() {
  var o = api.Alias();
  buildCounterAlias++;
  if (buildCounterAlias < 3) {
    o.alias = 'foo';
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.primaryEmail = 'foo';
  }
  buildCounterAlias--;
  return o;
}

void checkAlias(api.Alias o) {
  buildCounterAlias++;
  if (buildCounterAlias < 3) {
    unittest.expect(
      o.alias!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
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
      o.primaryEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterAlias--;
}

core.List<core.Object> buildUnnamed1944() {
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

void checkUnnamed1944(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o[0]) as core.Map;
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
  var casted2 = (o[1]) as core.Map;
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

core.int buildCounterAliases = 0;
api.Aliases buildAliases() {
  var o = api.Aliases();
  buildCounterAliases++;
  if (buildCounterAliases < 3) {
    o.aliases = buildUnnamed1944();
    o.etag = 'foo';
    o.kind = 'foo';
  }
  buildCounterAliases--;
  return o;
}

void checkAliases(api.Aliases o) {
  buildCounterAliases++;
  if (buildCounterAliases < 3) {
    checkUnnamed1944(o.aliases!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAliases--;
}

core.int buildCounterAsp = 0;
api.Asp buildAsp() {
  var o = api.Asp();
  buildCounterAsp++;
  if (buildCounterAsp < 3) {
    o.codeId = 42;
    o.creationTime = 'foo';
    o.etag = 'foo';
    o.kind = 'foo';
    o.lastTimeUsed = 'foo';
    o.name = 'foo';
    o.userKey = 'foo';
  }
  buildCounterAsp--;
  return o;
}

void checkAsp(api.Asp o) {
  buildCounterAsp++;
  if (buildCounterAsp < 3) {
    unittest.expect(
      o.codeId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastTimeUsed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsp--;
}

core.List<api.Asp> buildUnnamed1945() {
  var o = <api.Asp>[];
  o.add(buildAsp());
  o.add(buildAsp());
  return o;
}

void checkUnnamed1945(core.List<api.Asp> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAsp(o[0] as api.Asp);
  checkAsp(o[1] as api.Asp);
}

core.int buildCounterAsps = 0;
api.Asps buildAsps() {
  var o = api.Asps();
  buildCounterAsps++;
  if (buildCounterAsps < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed1945();
    o.kind = 'foo';
  }
  buildCounterAsps--;
  return o;
}

void checkAsps(api.Asps o) {
  buildCounterAsps++;
  if (buildCounterAsps < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1945(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsps--;
}

core.int buildCounterAuxiliaryMessage = 0;
api.AuxiliaryMessage buildAuxiliaryMessage() {
  var o = api.AuxiliaryMessage();
  buildCounterAuxiliaryMessage++;
  if (buildCounterAuxiliaryMessage < 3) {
    o.auxiliaryMessage = 'foo';
    o.fieldMask = 'foo';
    o.severity = 'foo';
  }
  buildCounterAuxiliaryMessage--;
  return o;
}

void checkAuxiliaryMessage(api.AuxiliaryMessage o) {
  buildCounterAuxiliaryMessage++;
  if (buildCounterAuxiliaryMessage < 3) {
    unittest.expect(
      o.auxiliaryMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldMask!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.severity!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuxiliaryMessage--;
}

core.List<api.CreatePrinterRequest> buildUnnamed1946() {
  var o = <api.CreatePrinterRequest>[];
  o.add(buildCreatePrinterRequest());
  o.add(buildCreatePrinterRequest());
  return o;
}

void checkUnnamed1946(core.List<api.CreatePrinterRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreatePrinterRequest(o[0] as api.CreatePrinterRequest);
  checkCreatePrinterRequest(o[1] as api.CreatePrinterRequest);
}

core.int buildCounterBatchCreatePrintersRequest = 0;
api.BatchCreatePrintersRequest buildBatchCreatePrintersRequest() {
  var o = api.BatchCreatePrintersRequest();
  buildCounterBatchCreatePrintersRequest++;
  if (buildCounterBatchCreatePrintersRequest < 3) {
    o.requests = buildUnnamed1946();
  }
  buildCounterBatchCreatePrintersRequest--;
  return o;
}

void checkBatchCreatePrintersRequest(api.BatchCreatePrintersRequest o) {
  buildCounterBatchCreatePrintersRequest++;
  if (buildCounterBatchCreatePrintersRequest < 3) {
    checkUnnamed1946(o.requests!);
  }
  buildCounterBatchCreatePrintersRequest--;
}

core.List<api.FailureInfo> buildUnnamed1947() {
  var o = <api.FailureInfo>[];
  o.add(buildFailureInfo());
  o.add(buildFailureInfo());
  return o;
}

void checkUnnamed1947(core.List<api.FailureInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFailureInfo(o[0] as api.FailureInfo);
  checkFailureInfo(o[1] as api.FailureInfo);
}

core.List<api.Printer> buildUnnamed1948() {
  var o = <api.Printer>[];
  o.add(buildPrinter());
  o.add(buildPrinter());
  return o;
}

void checkUnnamed1948(core.List<api.Printer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrinter(o[0] as api.Printer);
  checkPrinter(o[1] as api.Printer);
}

core.int buildCounterBatchCreatePrintersResponse = 0;
api.BatchCreatePrintersResponse buildBatchCreatePrintersResponse() {
  var o = api.BatchCreatePrintersResponse();
  buildCounterBatchCreatePrintersResponse++;
  if (buildCounterBatchCreatePrintersResponse < 3) {
    o.failures = buildUnnamed1947();
    o.printers = buildUnnamed1948();
  }
  buildCounterBatchCreatePrintersResponse--;
  return o;
}

void checkBatchCreatePrintersResponse(api.BatchCreatePrintersResponse o) {
  buildCounterBatchCreatePrintersResponse++;
  if (buildCounterBatchCreatePrintersResponse < 3) {
    checkUnnamed1947(o.failures!);
    checkUnnamed1948(o.printers!);
  }
  buildCounterBatchCreatePrintersResponse--;
}

core.List<core.String> buildUnnamed1949() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1949(core.List<core.String> o) {
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

core.int buildCounterBatchDeletePrintersRequest = 0;
api.BatchDeletePrintersRequest buildBatchDeletePrintersRequest() {
  var o = api.BatchDeletePrintersRequest();
  buildCounterBatchDeletePrintersRequest++;
  if (buildCounterBatchDeletePrintersRequest < 3) {
    o.printerIds = buildUnnamed1949();
  }
  buildCounterBatchDeletePrintersRequest--;
  return o;
}

void checkBatchDeletePrintersRequest(api.BatchDeletePrintersRequest o) {
  buildCounterBatchDeletePrintersRequest++;
  if (buildCounterBatchDeletePrintersRequest < 3) {
    checkUnnamed1949(o.printerIds!);
  }
  buildCounterBatchDeletePrintersRequest--;
}

core.List<api.FailureInfo> buildUnnamed1950() {
  var o = <api.FailureInfo>[];
  o.add(buildFailureInfo());
  o.add(buildFailureInfo());
  return o;
}

void checkUnnamed1950(core.List<api.FailureInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFailureInfo(o[0] as api.FailureInfo);
  checkFailureInfo(o[1] as api.FailureInfo);
}

core.List<core.String> buildUnnamed1951() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1951(core.List<core.String> o) {
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

core.int buildCounterBatchDeletePrintersResponse = 0;
api.BatchDeletePrintersResponse buildBatchDeletePrintersResponse() {
  var o = api.BatchDeletePrintersResponse();
  buildCounterBatchDeletePrintersResponse++;
  if (buildCounterBatchDeletePrintersResponse < 3) {
    o.failedPrinters = buildUnnamed1950();
    o.printerIds = buildUnnamed1951();
  }
  buildCounterBatchDeletePrintersResponse--;
  return o;
}

void checkBatchDeletePrintersResponse(api.BatchDeletePrintersResponse o) {
  buildCounterBatchDeletePrintersResponse++;
  if (buildCounterBatchDeletePrintersResponse < 3) {
    checkUnnamed1950(o.failedPrinters!);
    checkUnnamed1951(o.printerIds!);
  }
  buildCounterBatchDeletePrintersResponse--;
}

core.List<core.String> buildUnnamed1952() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1952(core.List<core.String> o) {
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

core.int buildCounterBuilding = 0;
api.Building buildBuilding() {
  var o = api.Building();
  buildCounterBuilding++;
  if (buildCounterBuilding < 3) {
    o.address = buildBuildingAddress();
    o.buildingId = 'foo';
    o.buildingName = 'foo';
    o.coordinates = buildBuildingCoordinates();
    o.description = 'foo';
    o.etags = 'foo';
    o.floorNames = buildUnnamed1952();
    o.kind = 'foo';
  }
  buildCounterBuilding--;
  return o;
}

void checkBuilding(api.Building o) {
  buildCounterBuilding++;
  if (buildCounterBuilding < 3) {
    checkBuildingAddress(o.address! as api.BuildingAddress);
    unittest.expect(
      o.buildingId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.buildingName!,
      unittest.equals('foo'),
    );
    checkBuildingCoordinates(o.coordinates! as api.BuildingCoordinates);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etags!,
      unittest.equals('foo'),
    );
    checkUnnamed1952(o.floorNames!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuilding--;
}

core.List<core.String> buildUnnamed1953() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1953(core.List<core.String> o) {
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

core.int buildCounterBuildingAddress = 0;
api.BuildingAddress buildBuildingAddress() {
  var o = api.BuildingAddress();
  buildCounterBuildingAddress++;
  if (buildCounterBuildingAddress < 3) {
    o.addressLines = buildUnnamed1953();
    o.administrativeArea = 'foo';
    o.languageCode = 'foo';
    o.locality = 'foo';
    o.postalCode = 'foo';
    o.regionCode = 'foo';
    o.sublocality = 'foo';
  }
  buildCounterBuildingAddress--;
  return o;
}

void checkBuildingAddress(api.BuildingAddress o) {
  buildCounterBuildingAddress++;
  if (buildCounterBuildingAddress < 3) {
    checkUnnamed1953(o.addressLines!);
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
      o.postalCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.regionCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sublocality!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuildingAddress--;
}

core.int buildCounterBuildingCoordinates = 0;
api.BuildingCoordinates buildBuildingCoordinates() {
  var o = api.BuildingCoordinates();
  buildCounterBuildingCoordinates++;
  if (buildCounterBuildingCoordinates < 3) {
    o.latitude = 42.0;
    o.longitude = 42.0;
  }
  buildCounterBuildingCoordinates--;
  return o;
}

void checkBuildingCoordinates(api.BuildingCoordinates o) {
  buildCounterBuildingCoordinates++;
  if (buildCounterBuildingCoordinates < 3) {
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
  }
  buildCounterBuildingCoordinates--;
}

core.List<api.Building> buildUnnamed1954() {
  var o = <api.Building>[];
  o.add(buildBuilding());
  o.add(buildBuilding());
  return o;
}

void checkUnnamed1954(core.List<api.Building> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBuilding(o[0] as api.Building);
  checkBuilding(o[1] as api.Building);
}

core.int buildCounterBuildings = 0;
api.Buildings buildBuildings() {
  var o = api.Buildings();
  buildCounterBuildings++;
  if (buildCounterBuildings < 3) {
    o.buildings = buildUnnamed1954();
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterBuildings--;
  return o;
}

void checkBuildings(api.Buildings o) {
  buildCounterBuildings++;
  if (buildCounterBuildings < 3) {
    checkUnnamed1954(o.buildings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuildings--;
}

core.int buildCounterCalendarResource = 0;
api.CalendarResource buildCalendarResource() {
  var o = api.CalendarResource();
  buildCounterCalendarResource++;
  if (buildCounterCalendarResource < 3) {
    o.buildingId = 'foo';
    o.capacity = 42;
    o.etags = 'foo';
    o.featureInstances = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.floorName = 'foo';
    o.floorSection = 'foo';
    o.generatedResourceName = 'foo';
    o.kind = 'foo';
    o.resourceCategory = 'foo';
    o.resourceDescription = 'foo';
    o.resourceEmail = 'foo';
    o.resourceId = 'foo';
    o.resourceName = 'foo';
    o.resourceType = 'foo';
    o.userVisibleDescription = 'foo';
  }
  buildCounterCalendarResource--;
  return o;
}

void checkCalendarResource(api.CalendarResource o) {
  buildCounterCalendarResource++;
  if (buildCounterCalendarResource < 3) {
    unittest.expect(
      o.buildingId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.capacity!,
      unittest.equals(42),
    );
    unittest.expect(
      o.etags!,
      unittest.equals('foo'),
    );
    var casted3 = (o.featureInstances!) as core.Map;
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
    unittest.expect(
      o.floorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floorSection!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.generatedResourceName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceCategory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userVisibleDescription!,
      unittest.equals('foo'),
    );
  }
  buildCounterCalendarResource--;
}

core.List<api.CalendarResource> buildUnnamed1955() {
  var o = <api.CalendarResource>[];
  o.add(buildCalendarResource());
  o.add(buildCalendarResource());
  return o;
}

void checkUnnamed1955(core.List<api.CalendarResource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCalendarResource(o[0] as api.CalendarResource);
  checkCalendarResource(o[1] as api.CalendarResource);
}

core.int buildCounterCalendarResources = 0;
api.CalendarResources buildCalendarResources() {
  var o = api.CalendarResources();
  buildCounterCalendarResources++;
  if (buildCounterCalendarResources < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed1955();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterCalendarResources--;
  return o;
}

void checkCalendarResources(api.CalendarResources o) {
  buildCounterCalendarResources++;
  if (buildCounterCalendarResources < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1955(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterCalendarResources--;
}

core.Map<core.String, core.String> buildUnnamed1956() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1956(core.Map<core.String, core.String> o) {
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

core.int buildCounterChannel = 0;
api.Channel buildChannel() {
  var o = api.Channel();
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    o.address = 'foo';
    o.expiration = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.params = buildUnnamed1956();
    o.payload = true;
    o.resourceId = 'foo';
    o.resourceUri = 'foo';
    o.token = 'foo';
    o.type = 'foo';
  }
  buildCounterChannel--;
  return o;
}

void checkChannel(api.Channel o) {
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiration!,
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
    checkUnnamed1956(o.params!);
    unittest.expect(o.payload!, unittest.isTrue);
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannel--;
}

core.int buildCounterChromeOsDeviceActiveTimeRanges = 0;
api.ChromeOsDeviceActiveTimeRanges buildChromeOsDeviceActiveTimeRanges() {
  var o = api.ChromeOsDeviceActiveTimeRanges();
  buildCounterChromeOsDeviceActiveTimeRanges++;
  if (buildCounterChromeOsDeviceActiveTimeRanges < 3) {
    o.activeTime = 42;
    o.date = core.DateTime.parse('2002-02-27T14:01:02Z');
  }
  buildCounterChromeOsDeviceActiveTimeRanges--;
  return o;
}

void checkChromeOsDeviceActiveTimeRanges(api.ChromeOsDeviceActiveTimeRanges o) {
  buildCounterChromeOsDeviceActiveTimeRanges++;
  if (buildCounterChromeOsDeviceActiveTimeRanges < 3) {
    unittest.expect(
      o.activeTime!,
      unittest.equals(42),
    );
    unittest.expect(
      o.date!,
      unittest.equals(core.DateTime.parse("2002-02-27T00:00:00")),
    );
  }
  buildCounterChromeOsDeviceActiveTimeRanges--;
}

core.List<api.ChromeOsDeviceActiveTimeRanges> buildUnnamed1957() {
  var o = <api.ChromeOsDeviceActiveTimeRanges>[];
  o.add(buildChromeOsDeviceActiveTimeRanges());
  o.add(buildChromeOsDeviceActiveTimeRanges());
  return o;
}

void checkUnnamed1957(core.List<api.ChromeOsDeviceActiveTimeRanges> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceActiveTimeRanges(
      o[0] as api.ChromeOsDeviceActiveTimeRanges);
  checkChromeOsDeviceActiveTimeRanges(
      o[1] as api.ChromeOsDeviceActiveTimeRanges);
}

core.int buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo = 0;
api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo
    buildChromeOsDeviceCpuStatusReportsCpuTemperatureInfo() {
  var o = api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo();
  buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo++;
  if (buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo < 3) {
    o.label = 'foo';
    o.temperature = 42;
  }
  buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo--;
  return o;
}

void checkChromeOsDeviceCpuStatusReportsCpuTemperatureInfo(
    api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo o) {
  buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo++;
  if (buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo < 3) {
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.temperature!,
      unittest.equals(42),
    );
  }
  buildCounterChromeOsDeviceCpuStatusReportsCpuTemperatureInfo--;
}

core.List<api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo>
    buildUnnamed1958() {
  var o = <api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo>[];
  o.add(buildChromeOsDeviceCpuStatusReportsCpuTemperatureInfo());
  o.add(buildChromeOsDeviceCpuStatusReportsCpuTemperatureInfo());
  return o;
}

void checkUnnamed1958(
    core.List<api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceCpuStatusReportsCpuTemperatureInfo(
      o[0] as api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo);
  checkChromeOsDeviceCpuStatusReportsCpuTemperatureInfo(
      o[1] as api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo);
}

core.List<core.int> buildUnnamed1959() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1959(core.List<core.int> o) {
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

core.int buildCounterChromeOsDeviceCpuStatusReports = 0;
api.ChromeOsDeviceCpuStatusReports buildChromeOsDeviceCpuStatusReports() {
  var o = api.ChromeOsDeviceCpuStatusReports();
  buildCounterChromeOsDeviceCpuStatusReports++;
  if (buildCounterChromeOsDeviceCpuStatusReports < 3) {
    o.cpuTemperatureInfo = buildUnnamed1958();
    o.cpuUtilizationPercentageInfo = buildUnnamed1959();
    o.reportTime = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterChromeOsDeviceCpuStatusReports--;
  return o;
}

void checkChromeOsDeviceCpuStatusReports(api.ChromeOsDeviceCpuStatusReports o) {
  buildCounterChromeOsDeviceCpuStatusReports++;
  if (buildCounterChromeOsDeviceCpuStatusReports < 3) {
    checkUnnamed1958(o.cpuTemperatureInfo!);
    checkUnnamed1959(o.cpuUtilizationPercentageInfo!);
    unittest.expect(
      o.reportTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterChromeOsDeviceCpuStatusReports--;
}

core.List<api.ChromeOsDeviceCpuStatusReports> buildUnnamed1960() {
  var o = <api.ChromeOsDeviceCpuStatusReports>[];
  o.add(buildChromeOsDeviceCpuStatusReports());
  o.add(buildChromeOsDeviceCpuStatusReports());
  return o;
}

void checkUnnamed1960(core.List<api.ChromeOsDeviceCpuStatusReports> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceCpuStatusReports(
      o[0] as api.ChromeOsDeviceCpuStatusReports);
  checkChromeOsDeviceCpuStatusReports(
      o[1] as api.ChromeOsDeviceCpuStatusReports);
}

core.int buildCounterChromeOsDeviceDeviceFiles = 0;
api.ChromeOsDeviceDeviceFiles buildChromeOsDeviceDeviceFiles() {
  var o = api.ChromeOsDeviceDeviceFiles();
  buildCounterChromeOsDeviceDeviceFiles++;
  if (buildCounterChromeOsDeviceDeviceFiles < 3) {
    o.createTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.downloadUrl = 'foo';
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterChromeOsDeviceDeviceFiles--;
  return o;
}

void checkChromeOsDeviceDeviceFiles(api.ChromeOsDeviceDeviceFiles o) {
  buildCounterChromeOsDeviceDeviceFiles++;
  if (buildCounterChromeOsDeviceDeviceFiles < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.downloadUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceDeviceFiles--;
}

core.List<api.ChromeOsDeviceDeviceFiles> buildUnnamed1961() {
  var o = <api.ChromeOsDeviceDeviceFiles>[];
  o.add(buildChromeOsDeviceDeviceFiles());
  o.add(buildChromeOsDeviceDeviceFiles());
  return o;
}

void checkUnnamed1961(core.List<api.ChromeOsDeviceDeviceFiles> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceDeviceFiles(o[0] as api.ChromeOsDeviceDeviceFiles);
  checkChromeOsDeviceDeviceFiles(o[1] as api.ChromeOsDeviceDeviceFiles);
}

core.int buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo = 0;
api.ChromeOsDeviceDiskVolumeReportsVolumeInfo
    buildChromeOsDeviceDiskVolumeReportsVolumeInfo() {
  var o = api.ChromeOsDeviceDiskVolumeReportsVolumeInfo();
  buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo++;
  if (buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo < 3) {
    o.storageFree = 'foo';
    o.storageTotal = 'foo';
    o.volumeId = 'foo';
  }
  buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo--;
  return o;
}

void checkChromeOsDeviceDiskVolumeReportsVolumeInfo(
    api.ChromeOsDeviceDiskVolumeReportsVolumeInfo o) {
  buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo++;
  if (buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo < 3) {
    unittest.expect(
      o.storageFree!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.storageTotal!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.volumeId!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceDiskVolumeReportsVolumeInfo--;
}

core.List<api.ChromeOsDeviceDiskVolumeReportsVolumeInfo> buildUnnamed1962() {
  var o = <api.ChromeOsDeviceDiskVolumeReportsVolumeInfo>[];
  o.add(buildChromeOsDeviceDiskVolumeReportsVolumeInfo());
  o.add(buildChromeOsDeviceDiskVolumeReportsVolumeInfo());
  return o;
}

void checkUnnamed1962(
    core.List<api.ChromeOsDeviceDiskVolumeReportsVolumeInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceDiskVolumeReportsVolumeInfo(
      o[0] as api.ChromeOsDeviceDiskVolumeReportsVolumeInfo);
  checkChromeOsDeviceDiskVolumeReportsVolumeInfo(
      o[1] as api.ChromeOsDeviceDiskVolumeReportsVolumeInfo);
}

core.int buildCounterChromeOsDeviceDiskVolumeReports = 0;
api.ChromeOsDeviceDiskVolumeReports buildChromeOsDeviceDiskVolumeReports() {
  var o = api.ChromeOsDeviceDiskVolumeReports();
  buildCounterChromeOsDeviceDiskVolumeReports++;
  if (buildCounterChromeOsDeviceDiskVolumeReports < 3) {
    o.volumeInfo = buildUnnamed1962();
  }
  buildCounterChromeOsDeviceDiskVolumeReports--;
  return o;
}

void checkChromeOsDeviceDiskVolumeReports(
    api.ChromeOsDeviceDiskVolumeReports o) {
  buildCounterChromeOsDeviceDiskVolumeReports++;
  if (buildCounterChromeOsDeviceDiskVolumeReports < 3) {
    checkUnnamed1962(o.volumeInfo!);
  }
  buildCounterChromeOsDeviceDiskVolumeReports--;
}

core.List<api.ChromeOsDeviceDiskVolumeReports> buildUnnamed1963() {
  var o = <api.ChromeOsDeviceDiskVolumeReports>[];
  o.add(buildChromeOsDeviceDiskVolumeReports());
  o.add(buildChromeOsDeviceDiskVolumeReports());
  return o;
}

void checkUnnamed1963(core.List<api.ChromeOsDeviceDiskVolumeReports> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceDiskVolumeReports(
      o[0] as api.ChromeOsDeviceDiskVolumeReports);
  checkChromeOsDeviceDiskVolumeReports(
      o[1] as api.ChromeOsDeviceDiskVolumeReports);
}

core.int buildCounterChromeOsDeviceLastKnownNetwork = 0;
api.ChromeOsDeviceLastKnownNetwork buildChromeOsDeviceLastKnownNetwork() {
  var o = api.ChromeOsDeviceLastKnownNetwork();
  buildCounterChromeOsDeviceLastKnownNetwork++;
  if (buildCounterChromeOsDeviceLastKnownNetwork < 3) {
    o.ipAddress = 'foo';
    o.wanIpAddress = 'foo';
  }
  buildCounterChromeOsDeviceLastKnownNetwork--;
  return o;
}

void checkChromeOsDeviceLastKnownNetwork(api.ChromeOsDeviceLastKnownNetwork o) {
  buildCounterChromeOsDeviceLastKnownNetwork++;
  if (buildCounterChromeOsDeviceLastKnownNetwork < 3) {
    unittest.expect(
      o.ipAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.wanIpAddress!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceLastKnownNetwork--;
}

core.List<api.ChromeOsDeviceLastKnownNetwork> buildUnnamed1964() {
  var o = <api.ChromeOsDeviceLastKnownNetwork>[];
  o.add(buildChromeOsDeviceLastKnownNetwork());
  o.add(buildChromeOsDeviceLastKnownNetwork());
  return o;
}

void checkUnnamed1964(core.List<api.ChromeOsDeviceLastKnownNetwork> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceLastKnownNetwork(
      o[0] as api.ChromeOsDeviceLastKnownNetwork);
  checkChromeOsDeviceLastKnownNetwork(
      o[1] as api.ChromeOsDeviceLastKnownNetwork);
}

core.int buildCounterChromeOsDeviceRecentUsers = 0;
api.ChromeOsDeviceRecentUsers buildChromeOsDeviceRecentUsers() {
  var o = api.ChromeOsDeviceRecentUsers();
  buildCounterChromeOsDeviceRecentUsers++;
  if (buildCounterChromeOsDeviceRecentUsers < 3) {
    o.email = 'foo';
    o.type = 'foo';
  }
  buildCounterChromeOsDeviceRecentUsers--;
  return o;
}

void checkChromeOsDeviceRecentUsers(api.ChromeOsDeviceRecentUsers o) {
  buildCounterChromeOsDeviceRecentUsers++;
  if (buildCounterChromeOsDeviceRecentUsers < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceRecentUsers--;
}

core.List<api.ChromeOsDeviceRecentUsers> buildUnnamed1965() {
  var o = <api.ChromeOsDeviceRecentUsers>[];
  o.add(buildChromeOsDeviceRecentUsers());
  o.add(buildChromeOsDeviceRecentUsers());
  return o;
}

void checkUnnamed1965(core.List<api.ChromeOsDeviceRecentUsers> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceRecentUsers(o[0] as api.ChromeOsDeviceRecentUsers);
  checkChromeOsDeviceRecentUsers(o[1] as api.ChromeOsDeviceRecentUsers);
}

core.int buildCounterChromeOsDeviceScreenshotFiles = 0;
api.ChromeOsDeviceScreenshotFiles buildChromeOsDeviceScreenshotFiles() {
  var o = api.ChromeOsDeviceScreenshotFiles();
  buildCounterChromeOsDeviceScreenshotFiles++;
  if (buildCounterChromeOsDeviceScreenshotFiles < 3) {
    o.createTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.downloadUrl = 'foo';
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterChromeOsDeviceScreenshotFiles--;
  return o;
}

void checkChromeOsDeviceScreenshotFiles(api.ChromeOsDeviceScreenshotFiles o) {
  buildCounterChromeOsDeviceScreenshotFiles++;
  if (buildCounterChromeOsDeviceScreenshotFiles < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.downloadUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceScreenshotFiles--;
}

core.List<api.ChromeOsDeviceScreenshotFiles> buildUnnamed1966() {
  var o = <api.ChromeOsDeviceScreenshotFiles>[];
  o.add(buildChromeOsDeviceScreenshotFiles());
  o.add(buildChromeOsDeviceScreenshotFiles());
  return o;
}

void checkUnnamed1966(core.List<api.ChromeOsDeviceScreenshotFiles> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceScreenshotFiles(o[0] as api.ChromeOsDeviceScreenshotFiles);
  checkChromeOsDeviceScreenshotFiles(o[1] as api.ChromeOsDeviceScreenshotFiles);
}

core.List<core.String> buildUnnamed1967() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1967(core.List<core.String> o) {
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

core.int buildCounterChromeOsDeviceSystemRamFreeReports = 0;
api.ChromeOsDeviceSystemRamFreeReports
    buildChromeOsDeviceSystemRamFreeReports() {
  var o = api.ChromeOsDeviceSystemRamFreeReports();
  buildCounterChromeOsDeviceSystemRamFreeReports++;
  if (buildCounterChromeOsDeviceSystemRamFreeReports < 3) {
    o.reportTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.systemRamFreeInfo = buildUnnamed1967();
  }
  buildCounterChromeOsDeviceSystemRamFreeReports--;
  return o;
}

void checkChromeOsDeviceSystemRamFreeReports(
    api.ChromeOsDeviceSystemRamFreeReports o) {
  buildCounterChromeOsDeviceSystemRamFreeReports++;
  if (buildCounterChromeOsDeviceSystemRamFreeReports < 3) {
    unittest.expect(
      o.reportTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed1967(o.systemRamFreeInfo!);
  }
  buildCounterChromeOsDeviceSystemRamFreeReports--;
}

core.List<api.ChromeOsDeviceSystemRamFreeReports> buildUnnamed1968() {
  var o = <api.ChromeOsDeviceSystemRamFreeReports>[];
  o.add(buildChromeOsDeviceSystemRamFreeReports());
  o.add(buildChromeOsDeviceSystemRamFreeReports());
  return o;
}

void checkUnnamed1968(core.List<api.ChromeOsDeviceSystemRamFreeReports> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDeviceSystemRamFreeReports(
      o[0] as api.ChromeOsDeviceSystemRamFreeReports);
  checkChromeOsDeviceSystemRamFreeReports(
      o[1] as api.ChromeOsDeviceSystemRamFreeReports);
}

core.int buildCounterChromeOsDeviceTpmVersionInfo = 0;
api.ChromeOsDeviceTpmVersionInfo buildChromeOsDeviceTpmVersionInfo() {
  var o = api.ChromeOsDeviceTpmVersionInfo();
  buildCounterChromeOsDeviceTpmVersionInfo++;
  if (buildCounterChromeOsDeviceTpmVersionInfo < 3) {
    o.family = 'foo';
    o.firmwareVersion = 'foo';
    o.manufacturer = 'foo';
    o.specLevel = 'foo';
    o.tpmModel = 'foo';
    o.vendorSpecific = 'foo';
  }
  buildCounterChromeOsDeviceTpmVersionInfo--;
  return o;
}

void checkChromeOsDeviceTpmVersionInfo(api.ChromeOsDeviceTpmVersionInfo o) {
  buildCounterChromeOsDeviceTpmVersionInfo++;
  if (buildCounterChromeOsDeviceTpmVersionInfo < 3) {
    unittest.expect(
      o.family!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firmwareVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manufacturer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.specLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tpmModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vendorSpecific!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceTpmVersionInfo--;
}

core.int buildCounterChromeOsDevice = 0;
api.ChromeOsDevice buildChromeOsDevice() {
  var o = api.ChromeOsDevice();
  buildCounterChromeOsDevice++;
  if (buildCounterChromeOsDevice < 3) {
    o.activeTimeRanges = buildUnnamed1957();
    o.annotatedAssetId = 'foo';
    o.annotatedLocation = 'foo';
    o.annotatedUser = 'foo';
    o.autoUpdateExpiration = 'foo';
    o.bootMode = 'foo';
    o.cpuStatusReports = buildUnnamed1960();
    o.deviceFiles = buildUnnamed1961();
    o.deviceId = 'foo';
    o.diskVolumeReports = buildUnnamed1963();
    o.dockMacAddress = 'foo';
    o.etag = 'foo';
    o.ethernetMacAddress = 'foo';
    o.ethernetMacAddress0 = 'foo';
    o.firmwareVersion = 'foo';
    o.kind = 'foo';
    o.lastEnrollmentTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.lastKnownNetwork = buildUnnamed1964();
    o.lastSync = core.DateTime.parse("2002-02-27T14:01:02");
    o.macAddress = 'foo';
    o.manufactureDate = 'foo';
    o.meid = 'foo';
    o.model = 'foo';
    o.notes = 'foo';
    o.orderNumber = 'foo';
    o.orgUnitPath = 'foo';
    o.osVersion = 'foo';
    o.platformVersion = 'foo';
    o.recentUsers = buildUnnamed1965();
    o.screenshotFiles = buildUnnamed1966();
    o.serialNumber = 'foo';
    o.status = 'foo';
    o.supportEndDate = core.DateTime.parse("2002-02-27T14:01:02");
    o.systemRamFreeReports = buildUnnamed1968();
    o.systemRamTotal = 'foo';
    o.tpmVersionInfo = buildChromeOsDeviceTpmVersionInfo();
    o.willAutoRenew = true;
  }
  buildCounterChromeOsDevice--;
  return o;
}

void checkChromeOsDevice(api.ChromeOsDevice o) {
  buildCounterChromeOsDevice++;
  if (buildCounterChromeOsDevice < 3) {
    checkUnnamed1957(o.activeTimeRanges!);
    unittest.expect(
      o.annotatedAssetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.annotatedLocation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.annotatedUser!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.autoUpdateExpiration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bootMode!,
      unittest.equals('foo'),
    );
    checkUnnamed1960(o.cpuStatusReports!);
    checkUnnamed1961(o.deviceFiles!);
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    checkUnnamed1963(o.diskVolumeReports!);
    unittest.expect(
      o.dockMacAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ethernetMacAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ethernetMacAddress0!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firmwareVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastEnrollmentTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed1964(o.lastKnownNetwork!);
    unittest.expect(
      o.lastSync!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.macAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manufactureDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.meid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orgUnitPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.osVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platformVersion!,
      unittest.equals('foo'),
    );
    checkUnnamed1965(o.recentUsers!);
    checkUnnamed1966(o.screenshotFiles!);
    unittest.expect(
      o.serialNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.supportEndDate!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed1968(o.systemRamFreeReports!);
    unittest.expect(
      o.systemRamTotal!,
      unittest.equals('foo'),
    );
    checkChromeOsDeviceTpmVersionInfo(
        o.tpmVersionInfo! as api.ChromeOsDeviceTpmVersionInfo);
    unittest.expect(o.willAutoRenew!, unittest.isTrue);
  }
  buildCounterChromeOsDevice--;
}

core.int buildCounterChromeOsDeviceAction = 0;
api.ChromeOsDeviceAction buildChromeOsDeviceAction() {
  var o = api.ChromeOsDeviceAction();
  buildCounterChromeOsDeviceAction++;
  if (buildCounterChromeOsDeviceAction < 3) {
    o.action = 'foo';
    o.deprovisionReason = 'foo';
  }
  buildCounterChromeOsDeviceAction--;
  return o;
}

void checkChromeOsDeviceAction(api.ChromeOsDeviceAction o) {
  buildCounterChromeOsDeviceAction++;
  if (buildCounterChromeOsDeviceAction < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deprovisionReason!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDeviceAction--;
}

core.List<api.ChromeOsDevice> buildUnnamed1969() {
  var o = <api.ChromeOsDevice>[];
  o.add(buildChromeOsDevice());
  o.add(buildChromeOsDevice());
  return o;
}

void checkUnnamed1969(core.List<api.ChromeOsDevice> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChromeOsDevice(o[0] as api.ChromeOsDevice);
  checkChromeOsDevice(o[1] as api.ChromeOsDevice);
}

core.int buildCounterChromeOsDevices = 0;
api.ChromeOsDevices buildChromeOsDevices() {
  var o = api.ChromeOsDevices();
  buildCounterChromeOsDevices++;
  if (buildCounterChromeOsDevices < 3) {
    o.chromeosdevices = buildUnnamed1969();
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterChromeOsDevices--;
  return o;
}

void checkChromeOsDevices(api.ChromeOsDevices o) {
  buildCounterChromeOsDevices++;
  if (buildCounterChromeOsDevices < 3) {
    checkUnnamed1969(o.chromeosdevices!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterChromeOsDevices--;
}

core.List<core.String> buildUnnamed1970() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1970(core.List<core.String> o) {
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

core.int buildCounterChromeOsMoveDevicesToOu = 0;
api.ChromeOsMoveDevicesToOu buildChromeOsMoveDevicesToOu() {
  var o = api.ChromeOsMoveDevicesToOu();
  buildCounterChromeOsMoveDevicesToOu++;
  if (buildCounterChromeOsMoveDevicesToOu < 3) {
    o.deviceIds = buildUnnamed1970();
  }
  buildCounterChromeOsMoveDevicesToOu--;
  return o;
}

void checkChromeOsMoveDevicesToOu(api.ChromeOsMoveDevicesToOu o) {
  buildCounterChromeOsMoveDevicesToOu++;
  if (buildCounterChromeOsMoveDevicesToOu < 3) {
    checkUnnamed1970(o.deviceIds!);
  }
  buildCounterChromeOsMoveDevicesToOu--;
}

core.int buildCounterCreatePrinterRequest = 0;
api.CreatePrinterRequest buildCreatePrinterRequest() {
  var o = api.CreatePrinterRequest();
  buildCounterCreatePrinterRequest++;
  if (buildCounterCreatePrinterRequest < 3) {
    o.parent = 'foo';
    o.printer = buildPrinter();
  }
  buildCounterCreatePrinterRequest--;
  return o;
}

void checkCreatePrinterRequest(api.CreatePrinterRequest o) {
  buildCounterCreatePrinterRequest++;
  if (buildCounterCreatePrinterRequest < 3) {
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
    checkPrinter(o.printer! as api.Printer);
  }
  buildCounterCreatePrinterRequest--;
}

core.int buildCounterCustomer = 0;
api.Customer buildCustomer() {
  var o = api.Customer();
  buildCounterCustomer++;
  if (buildCounterCustomer < 3) {
    o.alternateEmail = 'foo';
    o.customerCreationTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.customerDomain = 'foo';
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.language = 'foo';
    o.phoneNumber = 'foo';
    o.postalAddress = buildCustomerPostalAddress();
  }
  buildCounterCustomer--;
  return o;
}

void checkCustomer(api.Customer o) {
  buildCounterCustomer++;
  if (buildCounterCustomer < 3) {
    unittest.expect(
      o.alternateEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customerCreationTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.customerDomain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
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
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    checkCustomerPostalAddress(o.postalAddress! as api.CustomerPostalAddress);
  }
  buildCounterCustomer--;
}

core.int buildCounterCustomerPostalAddress = 0;
api.CustomerPostalAddress buildCustomerPostalAddress() {
  var o = api.CustomerPostalAddress();
  buildCounterCustomerPostalAddress++;
  if (buildCounterCustomerPostalAddress < 3) {
    o.addressLine1 = 'foo';
    o.addressLine2 = 'foo';
    o.addressLine3 = 'foo';
    o.contactName = 'foo';
    o.countryCode = 'foo';
    o.locality = 'foo';
    o.organizationName = 'foo';
    o.postalCode = 'foo';
    o.region = 'foo';
  }
  buildCounterCustomerPostalAddress--;
  return o;
}

void checkCustomerPostalAddress(api.CustomerPostalAddress o) {
  buildCounterCustomerPostalAddress++;
  if (buildCounterCustomerPostalAddress < 3) {
    unittest.expect(
      o.addressLine1!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.addressLine2!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.addressLine3!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contactName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.countryCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locality!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.organizationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postalCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerPostalAddress--;
}

core.int buildCounterDirectoryChromeosdevicesCommand = 0;
api.DirectoryChromeosdevicesCommand buildDirectoryChromeosdevicesCommand() {
  var o = api.DirectoryChromeosdevicesCommand();
  buildCounterDirectoryChromeosdevicesCommand++;
  if (buildCounterDirectoryChromeosdevicesCommand < 3) {
    o.commandExpireTime = 'foo';
    o.commandId = 'foo';
    o.commandResult = buildDirectoryChromeosdevicesCommandResult();
    o.issueTime = 'foo';
    o.payload = 'foo';
    o.state = 'foo';
    o.type = 'foo';
  }
  buildCounterDirectoryChromeosdevicesCommand--;
  return o;
}

void checkDirectoryChromeosdevicesCommand(
    api.DirectoryChromeosdevicesCommand o) {
  buildCounterDirectoryChromeosdevicesCommand++;
  if (buildCounterDirectoryChromeosdevicesCommand < 3) {
    unittest.expect(
      o.commandExpireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.commandId!,
      unittest.equals('foo'),
    );
    checkDirectoryChromeosdevicesCommandResult(
        o.commandResult! as api.DirectoryChromeosdevicesCommandResult);
    unittest.expect(
      o.issueTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.payload!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDirectoryChromeosdevicesCommand--;
}

core.int buildCounterDirectoryChromeosdevicesCommandResult = 0;
api.DirectoryChromeosdevicesCommandResult
    buildDirectoryChromeosdevicesCommandResult() {
  var o = api.DirectoryChromeosdevicesCommandResult();
  buildCounterDirectoryChromeosdevicesCommandResult++;
  if (buildCounterDirectoryChromeosdevicesCommandResult < 3) {
    o.errorMessage = 'foo';
    o.executeTime = 'foo';
    o.result = 'foo';
  }
  buildCounterDirectoryChromeosdevicesCommandResult--;
  return o;
}

void checkDirectoryChromeosdevicesCommandResult(
    api.DirectoryChromeosdevicesCommandResult o) {
  buildCounterDirectoryChromeosdevicesCommandResult++;
  if (buildCounterDirectoryChromeosdevicesCommandResult < 3) {
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.executeTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.result!,
      unittest.equals('foo'),
    );
  }
  buildCounterDirectoryChromeosdevicesCommandResult--;
}

core.int buildCounterDirectoryChromeosdevicesIssueCommandRequest = 0;
api.DirectoryChromeosdevicesIssueCommandRequest
    buildDirectoryChromeosdevicesIssueCommandRequest() {
  var o = api.DirectoryChromeosdevicesIssueCommandRequest();
  buildCounterDirectoryChromeosdevicesIssueCommandRequest++;
  if (buildCounterDirectoryChromeosdevicesIssueCommandRequest < 3) {
    o.commandType = 'foo';
    o.payload = 'foo';
  }
  buildCounterDirectoryChromeosdevicesIssueCommandRequest--;
  return o;
}

void checkDirectoryChromeosdevicesIssueCommandRequest(
    api.DirectoryChromeosdevicesIssueCommandRequest o) {
  buildCounterDirectoryChromeosdevicesIssueCommandRequest++;
  if (buildCounterDirectoryChromeosdevicesIssueCommandRequest < 3) {
    unittest.expect(
      o.commandType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.payload!,
      unittest.equals('foo'),
    );
  }
  buildCounterDirectoryChromeosdevicesIssueCommandRequest--;
}

core.int buildCounterDirectoryChromeosdevicesIssueCommandResponse = 0;
api.DirectoryChromeosdevicesIssueCommandResponse
    buildDirectoryChromeosdevicesIssueCommandResponse() {
  var o = api.DirectoryChromeosdevicesIssueCommandResponse();
  buildCounterDirectoryChromeosdevicesIssueCommandResponse++;
  if (buildCounterDirectoryChromeosdevicesIssueCommandResponse < 3) {
    o.commandId = 'foo';
  }
  buildCounterDirectoryChromeosdevicesIssueCommandResponse--;
  return o;
}

void checkDirectoryChromeosdevicesIssueCommandResponse(
    api.DirectoryChromeosdevicesIssueCommandResponse o) {
  buildCounterDirectoryChromeosdevicesIssueCommandResponse++;
  if (buildCounterDirectoryChromeosdevicesIssueCommandResponse < 3) {
    unittest.expect(
      o.commandId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDirectoryChromeosdevicesIssueCommandResponse--;
}

core.int buildCounterDomainAlias = 0;
api.DomainAlias buildDomainAlias() {
  var o = api.DomainAlias();
  buildCounterDomainAlias++;
  if (buildCounterDomainAlias < 3) {
    o.creationTime = 'foo';
    o.domainAliasName = 'foo';
    o.etag = 'foo';
    o.kind = 'foo';
    o.parentDomainName = 'foo';
    o.verified = true;
  }
  buildCounterDomainAlias--;
  return o;
}

void checkDomainAlias(api.DomainAlias o) {
  buildCounterDomainAlias++;
  if (buildCounterDomainAlias < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.domainAliasName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentDomainName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verified!, unittest.isTrue);
  }
  buildCounterDomainAlias--;
}

core.List<api.DomainAlias> buildUnnamed1971() {
  var o = <api.DomainAlias>[];
  o.add(buildDomainAlias());
  o.add(buildDomainAlias());
  return o;
}

void checkUnnamed1971(core.List<api.DomainAlias> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDomainAlias(o[0] as api.DomainAlias);
  checkDomainAlias(o[1] as api.DomainAlias);
}

core.int buildCounterDomainAliases = 0;
api.DomainAliases buildDomainAliases() {
  var o = api.DomainAliases();
  buildCounterDomainAliases++;
  if (buildCounterDomainAliases < 3) {
    o.domainAliases = buildUnnamed1971();
    o.etag = 'foo';
    o.kind = 'foo';
  }
  buildCounterDomainAliases--;
  return o;
}

void checkDomainAliases(api.DomainAliases o) {
  buildCounterDomainAliases++;
  if (buildCounterDomainAliases < 3) {
    checkUnnamed1971(o.domainAliases!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterDomainAliases--;
}

core.List<api.DomainAlias> buildUnnamed1972() {
  var o = <api.DomainAlias>[];
  o.add(buildDomainAlias());
  o.add(buildDomainAlias());
  return o;
}

void checkUnnamed1972(core.List<api.DomainAlias> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDomainAlias(o[0] as api.DomainAlias);
  checkDomainAlias(o[1] as api.DomainAlias);
}

core.int buildCounterDomains = 0;
api.Domains buildDomains() {
  var o = api.Domains();
  buildCounterDomains++;
  if (buildCounterDomains < 3) {
    o.creationTime = 'foo';
    o.domainAliases = buildUnnamed1972();
    o.domainName = 'foo';
    o.etag = 'foo';
    o.isPrimary = true;
    o.kind = 'foo';
    o.verified = true;
  }
  buildCounterDomains--;
  return o;
}

void checkDomains(api.Domains o) {
  buildCounterDomains++;
  if (buildCounterDomains < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    checkUnnamed1972(o.domainAliases!);
    unittest.expect(
      o.domainName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isPrimary!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.verified!, unittest.isTrue);
  }
  buildCounterDomains--;
}

core.List<api.Domains> buildUnnamed1973() {
  var o = <api.Domains>[];
  o.add(buildDomains());
  o.add(buildDomains());
  return o;
}

void checkUnnamed1973(core.List<api.Domains> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDomains(o[0] as api.Domains);
  checkDomains(o[1] as api.Domains);
}

core.int buildCounterDomains2 = 0;
api.Domains2 buildDomains2() {
  var o = api.Domains2();
  buildCounterDomains2++;
  if (buildCounterDomains2 < 3) {
    o.domains = buildUnnamed1973();
    o.etag = 'foo';
    o.kind = 'foo';
  }
  buildCounterDomains2--;
  return o;
}

void checkDomains2(api.Domains2 o) {
  buildCounterDomains2++;
  if (buildCounterDomains2 < 3) {
    checkUnnamed1973(o.domains!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterDomains2--;
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

core.int buildCounterFailureInfo = 0;
api.FailureInfo buildFailureInfo() {
  var o = api.FailureInfo();
  buildCounterFailureInfo++;
  if (buildCounterFailureInfo < 3) {
    o.errorCode = 'foo';
    o.errorMessage = 'foo';
    o.printer = buildPrinter();
    o.printerId = 'foo';
  }
  buildCounterFailureInfo--;
  return o;
}

void checkFailureInfo(api.FailureInfo o) {
  buildCounterFailureInfo++;
  if (buildCounterFailureInfo < 3) {
    unittest.expect(
      o.errorCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    checkPrinter(o.printer! as api.Printer);
    unittest.expect(
      o.printerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterFailureInfo--;
}

core.int buildCounterFeature = 0;
api.Feature buildFeature() {
  var o = api.Feature();
  buildCounterFeature++;
  if (buildCounterFeature < 3) {
    o.etags = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
  }
  buildCounterFeature--;
  return o;
}

void checkFeature(api.Feature o) {
  buildCounterFeature++;
  if (buildCounterFeature < 3) {
    unittest.expect(
      o.etags!,
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
  buildCounterFeature--;
}

core.int buildCounterFeatureInstance = 0;
api.FeatureInstance buildFeatureInstance() {
  var o = api.FeatureInstance();
  buildCounterFeatureInstance++;
  if (buildCounterFeatureInstance < 3) {
    o.feature = buildFeature();
  }
  buildCounterFeatureInstance--;
  return o;
}

void checkFeatureInstance(api.FeatureInstance o) {
  buildCounterFeatureInstance++;
  if (buildCounterFeatureInstance < 3) {
    checkFeature(o.feature! as api.Feature);
  }
  buildCounterFeatureInstance--;
}

core.int buildCounterFeatureRename = 0;
api.FeatureRename buildFeatureRename() {
  var o = api.FeatureRename();
  buildCounterFeatureRename++;
  if (buildCounterFeatureRename < 3) {
    o.newName = 'foo';
  }
  buildCounterFeatureRename--;
  return o;
}

void checkFeatureRename(api.FeatureRename o) {
  buildCounterFeatureRename++;
  if (buildCounterFeatureRename < 3) {
    unittest.expect(
      o.newName!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeatureRename--;
}

core.List<api.Feature> buildUnnamed1974() {
  var o = <api.Feature>[];
  o.add(buildFeature());
  o.add(buildFeature());
  return o;
}

void checkUnnamed1974(core.List<api.Feature> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFeature(o[0] as api.Feature);
  checkFeature(o[1] as api.Feature);
}

core.int buildCounterFeatures = 0;
api.Features buildFeatures() {
  var o = api.Features();
  buildCounterFeatures++;
  if (buildCounterFeatures < 3) {
    o.etag = 'foo';
    o.features = buildUnnamed1974();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterFeatures--;
  return o;
}

void checkFeatures(api.Features o) {
  buildCounterFeatures++;
  if (buildCounterFeatures < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1974(o.features!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterFeatures--;
}

core.List<core.String> buildUnnamed1975() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1975(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1976() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1976(core.List<core.String> o) {
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

core.int buildCounterGroup = 0;
api.Group buildGroup() {
  var o = api.Group();
  buildCounterGroup++;
  if (buildCounterGroup < 3) {
    o.adminCreated = true;
    o.aliases = buildUnnamed1975();
    o.description = 'foo';
    o.directMembersCount = 'foo';
    o.email = 'foo';
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.nonEditableAliases = buildUnnamed1976();
  }
  buildCounterGroup--;
  return o;
}

void checkGroup(api.Group o) {
  buildCounterGroup++;
  if (buildCounterGroup < 3) {
    unittest.expect(o.adminCreated!, unittest.isTrue);
    checkUnnamed1975(o.aliases!);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.directMembersCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
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
    checkUnnamed1976(o.nonEditableAliases!);
  }
  buildCounterGroup--;
}

core.List<api.Group> buildUnnamed1977() {
  var o = <api.Group>[];
  o.add(buildGroup());
  o.add(buildGroup());
  return o;
}

void checkUnnamed1977(core.List<api.Group> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGroup(o[0] as api.Group);
  checkGroup(o[1] as api.Group);
}

core.int buildCounterGroups = 0;
api.Groups buildGroups() {
  var o = api.Groups();
  buildCounterGroups++;
  if (buildCounterGroups < 3) {
    o.etag = 'foo';
    o.groups = buildUnnamed1977();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterGroups--;
  return o;
}

void checkGroups(api.Groups o) {
  buildCounterGroups++;
  if (buildCounterGroups < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1977(o.groups!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroups--;
}

core.List<api.PrinterModel> buildUnnamed1978() {
  var o = <api.PrinterModel>[];
  o.add(buildPrinterModel());
  o.add(buildPrinterModel());
  return o;
}

void checkUnnamed1978(core.List<api.PrinterModel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrinterModel(o[0] as api.PrinterModel);
  checkPrinterModel(o[1] as api.PrinterModel);
}

core.int buildCounterListPrinterModelsResponse = 0;
api.ListPrinterModelsResponse buildListPrinterModelsResponse() {
  var o = api.ListPrinterModelsResponse();
  buildCounterListPrinterModelsResponse++;
  if (buildCounterListPrinterModelsResponse < 3) {
    o.nextPageToken = 'foo';
    o.printerModels = buildUnnamed1978();
  }
  buildCounterListPrinterModelsResponse--;
  return o;
}

void checkListPrinterModelsResponse(api.ListPrinterModelsResponse o) {
  buildCounterListPrinterModelsResponse++;
  if (buildCounterListPrinterModelsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1978(o.printerModels!);
  }
  buildCounterListPrinterModelsResponse--;
}

core.List<api.Printer> buildUnnamed1979() {
  var o = <api.Printer>[];
  o.add(buildPrinter());
  o.add(buildPrinter());
  return o;
}

void checkUnnamed1979(core.List<api.Printer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrinter(o[0] as api.Printer);
  checkPrinter(o[1] as api.Printer);
}

core.int buildCounterListPrintersResponse = 0;
api.ListPrintersResponse buildListPrintersResponse() {
  var o = api.ListPrintersResponse();
  buildCounterListPrintersResponse++;
  if (buildCounterListPrintersResponse < 3) {
    o.nextPageToken = 'foo';
    o.printers = buildUnnamed1979();
  }
  buildCounterListPrintersResponse--;
  return o;
}

void checkListPrintersResponse(api.ListPrintersResponse o) {
  buildCounterListPrintersResponse++;
  if (buildCounterListPrintersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1979(o.printers!);
  }
  buildCounterListPrintersResponse--;
}

core.int buildCounterMember = 0;
api.Member buildMember() {
  var o = api.Member();
  buildCounterMember++;
  if (buildCounterMember < 3) {
    o.deliverySettings = 'foo';
    o.email = 'foo';
    o.etag = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.role = 'foo';
    o.status = 'foo';
    o.type = 'foo';
  }
  buildCounterMember--;
  return o;
}

void checkMember(api.Member o) {
  buildCounterMember++;
  if (buildCounterMember < 3) {
    unittest.expect(
      o.deliverySettings!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
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
      o.role!,
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
  }
  buildCounterMember--;
}

core.List<api.Member> buildUnnamed1980() {
  var o = <api.Member>[];
  o.add(buildMember());
  o.add(buildMember());
  return o;
}

void checkUnnamed1980(core.List<api.Member> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMember(o[0] as api.Member);
  checkMember(o[1] as api.Member);
}

core.int buildCounterMembers = 0;
api.Members buildMembers() {
  var o = api.Members();
  buildCounterMembers++;
  if (buildCounterMembers < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.members = buildUnnamed1980();
    o.nextPageToken = 'foo';
  }
  buildCounterMembers--;
  return o;
}

void checkMembers(api.Members o) {
  buildCounterMembers++;
  if (buildCounterMembers < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1980(o.members!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterMembers--;
}

core.int buildCounterMembersHasMember = 0;
api.MembersHasMember buildMembersHasMember() {
  var o = api.MembersHasMember();
  buildCounterMembersHasMember++;
  if (buildCounterMembersHasMember < 3) {
    o.isMember = true;
  }
  buildCounterMembersHasMember--;
  return o;
}

void checkMembersHasMember(api.MembersHasMember o) {
  buildCounterMembersHasMember++;
  if (buildCounterMembersHasMember < 3) {
    unittest.expect(o.isMember!, unittest.isTrue);
  }
  buildCounterMembersHasMember--;
}

core.List<core.String> buildUnnamed1981() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1981(core.List<core.String> o) {
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

core.int buildCounterMobileDeviceApplications = 0;
api.MobileDeviceApplications buildMobileDeviceApplications() {
  var o = api.MobileDeviceApplications();
  buildCounterMobileDeviceApplications++;
  if (buildCounterMobileDeviceApplications < 3) {
    o.displayName = 'foo';
    o.packageName = 'foo';
    o.permission = buildUnnamed1981();
    o.versionCode = 42;
    o.versionName = 'foo';
  }
  buildCounterMobileDeviceApplications--;
  return o;
}

void checkMobileDeviceApplications(api.MobileDeviceApplications o) {
  buildCounterMobileDeviceApplications++;
  if (buildCounterMobileDeviceApplications < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    checkUnnamed1981(o.permission!);
    unittest.expect(
      o.versionCode!,
      unittest.equals(42),
    );
    unittest.expect(
      o.versionName!,
      unittest.equals('foo'),
    );
  }
  buildCounterMobileDeviceApplications--;
}

core.List<api.MobileDeviceApplications> buildUnnamed1982() {
  var o = <api.MobileDeviceApplications>[];
  o.add(buildMobileDeviceApplications());
  o.add(buildMobileDeviceApplications());
  return o;
}

void checkUnnamed1982(core.List<api.MobileDeviceApplications> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMobileDeviceApplications(o[0] as api.MobileDeviceApplications);
  checkMobileDeviceApplications(o[1] as api.MobileDeviceApplications);
}

core.List<core.String> buildUnnamed1983() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1983(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1984() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1984(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1985() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1985(core.List<core.String> o) {
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

core.int buildCounterMobileDevice = 0;
api.MobileDevice buildMobileDevice() {
  var o = api.MobileDevice();
  buildCounterMobileDevice++;
  if (buildCounterMobileDevice < 3) {
    o.adbStatus = true;
    o.applications = buildUnnamed1982();
    o.basebandVersion = 'foo';
    o.bootloaderVersion = 'foo';
    o.brand = 'foo';
    o.buildNumber = 'foo';
    o.defaultLanguage = 'foo';
    o.developerOptionsStatus = true;
    o.deviceCompromisedStatus = 'foo';
    o.deviceId = 'foo';
    o.devicePasswordStatus = 'foo';
    o.email = buildUnnamed1983();
    o.encryptionStatus = 'foo';
    o.etag = 'foo';
    o.firstSync = core.DateTime.parse("2002-02-27T14:01:02");
    o.hardware = 'foo';
    o.hardwareId = 'foo';
    o.imei = 'foo';
    o.kernelVersion = 'foo';
    o.kind = 'foo';
    o.lastSync = core.DateTime.parse("2002-02-27T14:01:02");
    o.managedAccountIsOnOwnerProfile = true;
    o.manufacturer = 'foo';
    o.meid = 'foo';
    o.model = 'foo';
    o.name = buildUnnamed1984();
    o.networkOperator = 'foo';
    o.os = 'foo';
    o.otherAccountsInfo = buildUnnamed1985();
    o.privilege = 'foo';
    o.releaseVersion = 'foo';
    o.resourceId = 'foo';
    o.securityPatchLevel = 'foo';
    o.serialNumber = 'foo';
    o.status = 'foo';
    o.supportsWorkProfile = true;
    o.type = 'foo';
    o.unknownSourcesStatus = true;
    o.userAgent = 'foo';
    o.wifiMacAddress = 'foo';
  }
  buildCounterMobileDevice--;
  return o;
}

void checkMobileDevice(api.MobileDevice o) {
  buildCounterMobileDevice++;
  if (buildCounterMobileDevice < 3) {
    unittest.expect(o.adbStatus!, unittest.isTrue);
    checkUnnamed1982(o.applications!);
    unittest.expect(
      o.basebandVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bootloaderVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.brand!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.buildNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(o.developerOptionsStatus!, unittest.isTrue);
    unittest.expect(
      o.deviceCompromisedStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.devicePasswordStatus!,
      unittest.equals('foo'),
    );
    checkUnnamed1983(o.email!);
    unittest.expect(
      o.encryptionStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firstSync!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.hardware!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hardwareId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.imei!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kernelVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastSync!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(o.managedAccountIsOnOwnerProfile!, unittest.isTrue);
    unittest.expect(
      o.manufacturer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.meid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    checkUnnamed1984(o.name!);
    unittest.expect(
      o.networkOperator!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.os!,
      unittest.equals('foo'),
    );
    checkUnnamed1985(o.otherAccountsInfo!);
    unittest.expect(
      o.privilege!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.releaseVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.securityPatchLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serialNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(o.supportsWorkProfile!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(o.unknownSourcesStatus!, unittest.isTrue);
    unittest.expect(
      o.userAgent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.wifiMacAddress!,
      unittest.equals('foo'),
    );
  }
  buildCounterMobileDevice--;
}

core.int buildCounterMobileDeviceAction = 0;
api.MobileDeviceAction buildMobileDeviceAction() {
  var o = api.MobileDeviceAction();
  buildCounterMobileDeviceAction++;
  if (buildCounterMobileDeviceAction < 3) {
    o.action = 'foo';
  }
  buildCounterMobileDeviceAction--;
  return o;
}

void checkMobileDeviceAction(api.MobileDeviceAction o) {
  buildCounterMobileDeviceAction++;
  if (buildCounterMobileDeviceAction < 3) {
    unittest.expect(
      o.action!,
      unittest.equals('foo'),
    );
  }
  buildCounterMobileDeviceAction--;
}

core.List<api.MobileDevice> buildUnnamed1986() {
  var o = <api.MobileDevice>[];
  o.add(buildMobileDevice());
  o.add(buildMobileDevice());
  return o;
}

void checkUnnamed1986(core.List<api.MobileDevice> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMobileDevice(o[0] as api.MobileDevice);
  checkMobileDevice(o[1] as api.MobileDevice);
}

core.int buildCounterMobileDevices = 0;
api.MobileDevices buildMobileDevices() {
  var o = api.MobileDevices();
  buildCounterMobileDevices++;
  if (buildCounterMobileDevices < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.mobiledevices = buildUnnamed1986();
    o.nextPageToken = 'foo';
  }
  buildCounterMobileDevices--;
  return o;
}

void checkMobileDevices(api.MobileDevices o) {
  buildCounterMobileDevices++;
  if (buildCounterMobileDevices < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1986(o.mobiledevices!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterMobileDevices--;
}

core.int buildCounterOrgUnit = 0;
api.OrgUnit buildOrgUnit() {
  var o = api.OrgUnit();
  buildCounterOrgUnit++;
  if (buildCounterOrgUnit < 3) {
    o.blockInheritance = true;
    o.description = 'foo';
    o.etag = 'foo';
    o.kind = 'foo';
    o.name = 'foo';
    o.orgUnitId = 'foo';
    o.orgUnitPath = 'foo';
    o.parentOrgUnitId = 'foo';
    o.parentOrgUnitPath = 'foo';
  }
  buildCounterOrgUnit--;
  return o;
}

void checkOrgUnit(api.OrgUnit o) {
  buildCounterOrgUnit++;
  if (buildCounterOrgUnit < 3) {
    unittest.expect(o.blockInheritance!, unittest.isTrue);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
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
      o.orgUnitId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orgUnitPath!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentOrgUnitId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentOrgUnitPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterOrgUnit--;
}

core.List<api.OrgUnit> buildUnnamed1987() {
  var o = <api.OrgUnit>[];
  o.add(buildOrgUnit());
  o.add(buildOrgUnit());
  return o;
}

void checkUnnamed1987(core.List<api.OrgUnit> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrgUnit(o[0] as api.OrgUnit);
  checkOrgUnit(o[1] as api.OrgUnit);
}

core.int buildCounterOrgUnits = 0;
api.OrgUnits buildOrgUnits() {
  var o = api.OrgUnits();
  buildCounterOrgUnits++;
  if (buildCounterOrgUnits < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.organizationUnits = buildUnnamed1987();
  }
  buildCounterOrgUnits--;
  return o;
}

void checkOrgUnits(api.OrgUnits o) {
  buildCounterOrgUnits++;
  if (buildCounterOrgUnits < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1987(o.organizationUnits!);
  }
  buildCounterOrgUnits--;
}

core.List<api.AuxiliaryMessage> buildUnnamed1988() {
  var o = <api.AuxiliaryMessage>[];
  o.add(buildAuxiliaryMessage());
  o.add(buildAuxiliaryMessage());
  return o;
}

void checkUnnamed1988(core.List<api.AuxiliaryMessage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuxiliaryMessage(o[0] as api.AuxiliaryMessage);
  checkAuxiliaryMessage(o[1] as api.AuxiliaryMessage);
}

core.int buildCounterPrinter = 0;
api.Printer buildPrinter() {
  var o = api.Printer();
  buildCounterPrinter++;
  if (buildCounterPrinter < 3) {
    o.auxiliaryMessages = buildUnnamed1988();
    o.createTime = 'foo';
    o.description = 'foo';
    o.displayName = 'foo';
    o.id = 'foo';
    o.makeAndModel = 'foo';
    o.name = 'foo';
    o.orgUnitId = 'foo';
    o.uri = 'foo';
    o.useDriverlessConfig = true;
  }
  buildCounterPrinter--;
  return o;
}

void checkPrinter(api.Printer o) {
  buildCounterPrinter++;
  if (buildCounterPrinter < 3) {
    checkUnnamed1988(o.auxiliaryMessages!);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.makeAndModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orgUnitId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
    unittest.expect(o.useDriverlessConfig!, unittest.isTrue);
  }
  buildCounterPrinter--;
}

core.int buildCounterPrinterModel = 0;
api.PrinterModel buildPrinterModel() {
  var o = api.PrinterModel();
  buildCounterPrinterModel++;
  if (buildCounterPrinterModel < 3) {
    o.displayName = 'foo';
    o.makeAndModel = 'foo';
    o.manufacturer = 'foo';
  }
  buildCounterPrinterModel--;
  return o;
}

void checkPrinterModel(api.PrinterModel o) {
  buildCounterPrinterModel++;
  if (buildCounterPrinterModel < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.makeAndModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.manufacturer!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrinterModel--;
}

core.List<api.Privilege> buildUnnamed1989() {
  var o = <api.Privilege>[];
  o.add(buildPrivilege());
  o.add(buildPrivilege());
  return o;
}

void checkUnnamed1989(core.List<api.Privilege> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrivilege(o[0] as api.Privilege);
  checkPrivilege(o[1] as api.Privilege);
}

core.int buildCounterPrivilege = 0;
api.Privilege buildPrivilege() {
  var o = api.Privilege();
  buildCounterPrivilege++;
  if (buildCounterPrivilege < 3) {
    o.childPrivileges = buildUnnamed1989();
    o.etag = 'foo';
    o.isOuScopable = true;
    o.kind = 'foo';
    o.privilegeName = 'foo';
    o.serviceId = 'foo';
    o.serviceName = 'foo';
  }
  buildCounterPrivilege--;
  return o;
}

void checkPrivilege(api.Privilege o) {
  buildCounterPrivilege++;
  if (buildCounterPrivilege < 3) {
    checkUnnamed1989(o.childPrivileges!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isOuScopable!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privilegeName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrivilege--;
}

core.List<api.Privilege> buildUnnamed1990() {
  var o = <api.Privilege>[];
  o.add(buildPrivilege());
  o.add(buildPrivilege());
  return o;
}

void checkUnnamed1990(core.List<api.Privilege> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPrivilege(o[0] as api.Privilege);
  checkPrivilege(o[1] as api.Privilege);
}

core.int buildCounterPrivileges = 0;
api.Privileges buildPrivileges() {
  var o = api.Privileges();
  buildCounterPrivileges++;
  if (buildCounterPrivileges < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed1990();
    o.kind = 'foo';
  }
  buildCounterPrivileges--;
  return o;
}

void checkPrivileges(api.Privileges o) {
  buildCounterPrivileges++;
  if (buildCounterPrivileges < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1990(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrivileges--;
}

core.int buildCounterRoleRolePrivileges = 0;
api.RoleRolePrivileges buildRoleRolePrivileges() {
  var o = api.RoleRolePrivileges();
  buildCounterRoleRolePrivileges++;
  if (buildCounterRoleRolePrivileges < 3) {
    o.privilegeName = 'foo';
    o.serviceId = 'foo';
  }
  buildCounterRoleRolePrivileges--;
  return o;
}

void checkRoleRolePrivileges(api.RoleRolePrivileges o) {
  buildCounterRoleRolePrivileges++;
  if (buildCounterRoleRolePrivileges < 3) {
    unittest.expect(
      o.privilegeName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoleRolePrivileges--;
}

core.List<api.RoleRolePrivileges> buildUnnamed1991() {
  var o = <api.RoleRolePrivileges>[];
  o.add(buildRoleRolePrivileges());
  o.add(buildRoleRolePrivileges());
  return o;
}

void checkUnnamed1991(core.List<api.RoleRolePrivileges> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRoleRolePrivileges(o[0] as api.RoleRolePrivileges);
  checkRoleRolePrivileges(o[1] as api.RoleRolePrivileges);
}

core.int buildCounterRole = 0;
api.Role buildRole() {
  var o = api.Role();
  buildCounterRole++;
  if (buildCounterRole < 3) {
    o.etag = 'foo';
    o.isSuperAdminRole = true;
    o.isSystemRole = true;
    o.kind = 'foo';
    o.roleDescription = 'foo';
    o.roleId = 'foo';
    o.roleName = 'foo';
    o.rolePrivileges = buildUnnamed1991();
  }
  buildCounterRole--;
  return o;
}

void checkRole(api.Role o) {
  buildCounterRole++;
  if (buildCounterRole < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isSuperAdminRole!, unittest.isTrue);
    unittest.expect(o.isSystemRole!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.roleDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.roleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.roleName!,
      unittest.equals('foo'),
    );
    checkUnnamed1991(o.rolePrivileges!);
  }
  buildCounterRole--;
}

core.int buildCounterRoleAssignment = 0;
api.RoleAssignment buildRoleAssignment() {
  var o = api.RoleAssignment();
  buildCounterRoleAssignment++;
  if (buildCounterRoleAssignment < 3) {
    o.assignedTo = 'foo';
    o.etag = 'foo';
    o.kind = 'foo';
    o.orgUnitId = 'foo';
    o.roleAssignmentId = 'foo';
    o.roleId = 'foo';
    o.scopeType = 'foo';
  }
  buildCounterRoleAssignment--;
  return o;
}

void checkRoleAssignment(api.RoleAssignment o) {
  buildCounterRoleAssignment++;
  if (buildCounterRoleAssignment < 3) {
    unittest.expect(
      o.assignedTo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orgUnitId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.roleAssignmentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.roleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scopeType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoleAssignment--;
}

core.List<api.RoleAssignment> buildUnnamed1992() {
  var o = <api.RoleAssignment>[];
  o.add(buildRoleAssignment());
  o.add(buildRoleAssignment());
  return o;
}

void checkUnnamed1992(core.List<api.RoleAssignment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRoleAssignment(o[0] as api.RoleAssignment);
  checkRoleAssignment(o[1] as api.RoleAssignment);
}

core.int buildCounterRoleAssignments = 0;
api.RoleAssignments buildRoleAssignments() {
  var o = api.RoleAssignments();
  buildCounterRoleAssignments++;
  if (buildCounterRoleAssignments < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed1992();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterRoleAssignments--;
  return o;
}

void checkRoleAssignments(api.RoleAssignments o) {
  buildCounterRoleAssignments++;
  if (buildCounterRoleAssignments < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1992(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoleAssignments--;
}

core.List<api.Role> buildUnnamed1993() {
  var o = <api.Role>[];
  o.add(buildRole());
  o.add(buildRole());
  return o;
}

void checkUnnamed1993(core.List<api.Role> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRole(o[0] as api.Role);
  checkRole(o[1] as api.Role);
}

core.int buildCounterRoles = 0;
api.Roles buildRoles() {
  var o = api.Roles();
  buildCounterRoles++;
  if (buildCounterRoles < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed1993();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterRoles--;
  return o;
}

void checkRoles(api.Roles o) {
  buildCounterRoles++;
  if (buildCounterRoles < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1993(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoles--;
}

core.List<api.SchemaFieldSpec> buildUnnamed1994() {
  var o = <api.SchemaFieldSpec>[];
  o.add(buildSchemaFieldSpec());
  o.add(buildSchemaFieldSpec());
  return o;
}

void checkUnnamed1994(core.List<api.SchemaFieldSpec> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSchemaFieldSpec(o[0] as api.SchemaFieldSpec);
  checkSchemaFieldSpec(o[1] as api.SchemaFieldSpec);
}

core.int buildCounterSchema = 0;
api.Schema buildSchema() {
  var o = api.Schema();
  buildCounterSchema++;
  if (buildCounterSchema < 3) {
    o.displayName = 'foo';
    o.etag = 'foo';
    o.fields = buildUnnamed1994();
    o.kind = 'foo';
    o.schemaId = 'foo';
    o.schemaName = 'foo';
  }
  buildCounterSchema--;
  return o;
}

void checkSchema(api.Schema o) {
  buildCounterSchema++;
  if (buildCounterSchema < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1994(o.fields!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.schemaId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.schemaName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchema--;
}

core.int buildCounterSchemaFieldSpecNumericIndexingSpec = 0;
api.SchemaFieldSpecNumericIndexingSpec
    buildSchemaFieldSpecNumericIndexingSpec() {
  var o = api.SchemaFieldSpecNumericIndexingSpec();
  buildCounterSchemaFieldSpecNumericIndexingSpec++;
  if (buildCounterSchemaFieldSpecNumericIndexingSpec < 3) {
    o.maxValue = 42.0;
    o.minValue = 42.0;
  }
  buildCounterSchemaFieldSpecNumericIndexingSpec--;
  return o;
}

void checkSchemaFieldSpecNumericIndexingSpec(
    api.SchemaFieldSpecNumericIndexingSpec o) {
  buildCounterSchemaFieldSpecNumericIndexingSpec++;
  if (buildCounterSchemaFieldSpecNumericIndexingSpec < 3) {
    unittest.expect(
      o.maxValue!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.minValue!,
      unittest.equals(42.0),
    );
  }
  buildCounterSchemaFieldSpecNumericIndexingSpec--;
}

core.int buildCounterSchemaFieldSpec = 0;
api.SchemaFieldSpec buildSchemaFieldSpec() {
  var o = api.SchemaFieldSpec();
  buildCounterSchemaFieldSpec++;
  if (buildCounterSchemaFieldSpec < 3) {
    o.displayName = 'foo';
    o.etag = 'foo';
    o.fieldId = 'foo';
    o.fieldName = 'foo';
    o.fieldType = 'foo';
    o.indexed = true;
    o.kind = 'foo';
    o.multiValued = true;
    o.numericIndexingSpec = buildSchemaFieldSpecNumericIndexingSpec();
    o.readAccessType = 'foo';
  }
  buildCounterSchemaFieldSpec--;
  return o;
}

void checkSchemaFieldSpec(api.SchemaFieldSpec o) {
  buildCounterSchemaFieldSpec++;
  if (buildCounterSchemaFieldSpec < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.indexed!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.multiValued!, unittest.isTrue);
    checkSchemaFieldSpecNumericIndexingSpec(
        o.numericIndexingSpec! as api.SchemaFieldSpecNumericIndexingSpec);
    unittest.expect(
      o.readAccessType!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchemaFieldSpec--;
}

core.List<api.Schema> buildUnnamed1995() {
  var o = <api.Schema>[];
  o.add(buildSchema());
  o.add(buildSchema());
  return o;
}

void checkUnnamed1995(core.List<api.Schema> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSchema(o[0] as api.Schema);
  checkSchema(o[1] as api.Schema);
}

core.int buildCounterSchemas = 0;
api.Schemas buildSchemas() {
  var o = api.Schemas();
  buildCounterSchemas++;
  if (buildCounterSchemas < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.schemas = buildUnnamed1995();
  }
  buildCounterSchemas--;
  return o;
}

void checkSchemas(api.Schemas o) {
  buildCounterSchemas++;
  if (buildCounterSchemas < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1995(o.schemas!);
  }
  buildCounterSchemas--;
}

core.List<core.String> buildUnnamed1996() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1996(core.List<core.String> o) {
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

core.int buildCounterToken = 0;
api.Token buildToken() {
  var o = api.Token();
  buildCounterToken++;
  if (buildCounterToken < 3) {
    o.anonymous = true;
    o.clientId = 'foo';
    o.displayText = 'foo';
    o.etag = 'foo';
    o.kind = 'foo';
    o.nativeApp = true;
    o.scopes = buildUnnamed1996();
    o.userKey = 'foo';
  }
  buildCounterToken--;
  return o;
}

void checkToken(api.Token o) {
  buildCounterToken++;
  if (buildCounterToken < 3) {
    unittest.expect(o.anonymous!, unittest.isTrue);
    unittest.expect(
      o.clientId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.nativeApp!, unittest.isTrue);
    checkUnnamed1996(o.scopes!);
    unittest.expect(
      o.userKey!,
      unittest.equals('foo'),
    );
  }
  buildCounterToken--;
}

core.List<api.Token> buildUnnamed1997() {
  var o = <api.Token>[];
  o.add(buildToken());
  o.add(buildToken());
  return o;
}

void checkUnnamed1997(core.List<api.Token> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkToken(o[0] as api.Token);
  checkToken(o[1] as api.Token);
}

core.int buildCounterTokens = 0;
api.Tokens buildTokens() {
  var o = api.Tokens();
  buildCounterTokens++;
  if (buildCounterTokens < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed1997();
    o.kind = 'foo';
  }
  buildCounterTokens--;
  return o;
}

void checkTokens(api.Tokens o) {
  buildCounterTokens++;
  if (buildCounterTokens < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1997(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterTokens--;
}

core.List<core.String> buildUnnamed1998() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1998(core.List<core.String> o) {
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

core.Map<core.String, api.UserCustomProperties> buildUnnamed1999() {
  var o = <core.String, api.UserCustomProperties>{};
  o['x'] = buildUserCustomProperties();
  o['y'] = buildUserCustomProperties();
  return o;
}

void checkUnnamed1999(core.Map<core.String, api.UserCustomProperties> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserCustomProperties(o['x']! as api.UserCustomProperties);
  checkUserCustomProperties(o['y']! as api.UserCustomProperties);
}

core.List<core.String> buildUnnamed2000() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2000(core.List<core.String> o) {
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

core.int buildCounterUser = 0;
api.User buildUser() {
  var o = api.User();
  buildCounterUser++;
  if (buildCounterUser < 3) {
    o.addresses = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.agreedToTerms = true;
    o.aliases = buildUnnamed1998();
    o.archived = true;
    o.changePasswordAtNextLogin = true;
    o.creationTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.customSchemas = buildUnnamed1999();
    o.customerId = 'foo';
    o.deletionTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.emails = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.etag = 'foo';
    o.externalIds = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.gender = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.hashFunction = 'foo';
    o.id = 'foo';
    o.ims = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.includeInGlobalAddressList = true;
    o.ipWhitelisted = true;
    o.isAdmin = true;
    o.isDelegatedAdmin = true;
    o.isEnforcedIn2Sv = true;
    o.isEnrolledIn2Sv = true;
    o.isMailboxSetup = true;
    o.keywords = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.kind = 'foo';
    o.languages = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.lastLoginTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.locations = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.name = buildUserName();
    o.nonEditableAliases = buildUnnamed2000();
    o.notes = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.orgUnitPath = 'foo';
    o.organizations = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.password = 'foo';
    o.phones = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.posixAccounts = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.primaryEmail = 'foo';
    o.recoveryEmail = 'foo';
    o.recoveryPhone = 'foo';
    o.relations = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.sshPublicKeys = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.suspended = true;
    o.suspensionReason = 'foo';
    o.thumbnailPhotoEtag = 'foo';
    o.thumbnailPhotoUrl = 'foo';
    o.websites = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterUser--;
  return o;
}

void checkUser(api.User o) {
  buildCounterUser++;
  if (buildCounterUser < 3) {
    var casted4 = (o.addresses!) as core.Map;
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
    unittest.expect(o.agreedToTerms!, unittest.isTrue);
    checkUnnamed1998(o.aliases!);
    unittest.expect(o.archived!, unittest.isTrue);
    unittest.expect(o.changePasswordAtNextLogin!, unittest.isTrue);
    unittest.expect(
      o.creationTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed1999(o.customSchemas!);
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deletionTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    var casted5 = (o.emails!) as core.Map;
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
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    var casted6 = (o.externalIds!) as core.Map;
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
    var casted7 = (o.gender!) as core.Map;
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
    unittest.expect(
      o.hashFunction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    var casted8 = (o.ims!) as core.Map;
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
    unittest.expect(o.includeInGlobalAddressList!, unittest.isTrue);
    unittest.expect(o.ipWhitelisted!, unittest.isTrue);
    unittest.expect(o.isAdmin!, unittest.isTrue);
    unittest.expect(o.isDelegatedAdmin!, unittest.isTrue);
    unittest.expect(o.isEnforcedIn2Sv!, unittest.isTrue);
    unittest.expect(o.isEnrolledIn2Sv!, unittest.isTrue);
    unittest.expect(o.isMailboxSetup!, unittest.isTrue);
    var casted9 = (o.keywords!) as core.Map;
    unittest.expect(casted9, unittest.hasLength(3));
    unittest.expect(
      casted9['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted9['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted9['string'],
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    var casted10 = (o.languages!) as core.Map;
    unittest.expect(casted10, unittest.hasLength(3));
    unittest.expect(
      casted10['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted10['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted10['string'],
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastLoginTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    var casted11 = (o.locations!) as core.Map;
    unittest.expect(casted11, unittest.hasLength(3));
    unittest.expect(
      casted11['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted11['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted11['string'],
      unittest.equals('foo'),
    );
    checkUserName(o.name! as api.UserName);
    checkUnnamed2000(o.nonEditableAliases!);
    var casted12 = (o.notes!) as core.Map;
    unittest.expect(casted12, unittest.hasLength(3));
    unittest.expect(
      casted12['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted12['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted12['string'],
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orgUnitPath!,
      unittest.equals('foo'),
    );
    var casted13 = (o.organizations!) as core.Map;
    unittest.expect(casted13, unittest.hasLength(3));
    unittest.expect(
      casted13['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted13['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted13['string'],
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    var casted14 = (o.phones!) as core.Map;
    unittest.expect(casted14, unittest.hasLength(3));
    unittest.expect(
      casted14['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted14['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted14['string'],
      unittest.equals('foo'),
    );
    var casted15 = (o.posixAccounts!) as core.Map;
    unittest.expect(casted15, unittest.hasLength(3));
    unittest.expect(
      casted15['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted15['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted15['string'],
      unittest.equals('foo'),
    );
    unittest.expect(
      o.primaryEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recoveryEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recoveryPhone!,
      unittest.equals('foo'),
    );
    var casted16 = (o.relations!) as core.Map;
    unittest.expect(casted16, unittest.hasLength(3));
    unittest.expect(
      casted16['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted16['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted16['string'],
      unittest.equals('foo'),
    );
    var casted17 = (o.sshPublicKeys!) as core.Map;
    unittest.expect(casted17, unittest.hasLength(3));
    unittest.expect(
      casted17['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted17['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted17['string'],
      unittest.equals('foo'),
    );
    unittest.expect(o.suspended!, unittest.isTrue);
    unittest.expect(
      o.suspensionReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailPhotoEtag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailPhotoUrl!,
      unittest.equals('foo'),
    );
    var casted18 = (o.websites!) as core.Map;
    unittest.expect(casted18, unittest.hasLength(3));
    unittest.expect(
      casted18['list'],
      unittest.equals([1, 2, 3]),
    );
    unittest.expect(
      casted18['bool'],
      unittest.equals(true),
    );
    unittest.expect(
      casted18['string'],
      unittest.equals('foo'),
    );
  }
  buildCounterUser--;
}

core.int buildCounterUserAbout = 0;
api.UserAbout buildUserAbout() {
  var o = api.UserAbout();
  buildCounterUserAbout++;
  if (buildCounterUserAbout < 3) {
    o.contentType = 'foo';
    o.value = 'foo';
  }
  buildCounterUserAbout--;
  return o;
}

void checkUserAbout(api.UserAbout o) {
  buildCounterUserAbout++;
  if (buildCounterUserAbout < 3) {
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserAbout--;
}

core.int buildCounterUserAddress = 0;
api.UserAddress buildUserAddress() {
  var o = api.UserAddress();
  buildCounterUserAddress++;
  if (buildCounterUserAddress < 3) {
    o.country = 'foo';
    o.countryCode = 'foo';
    o.customType = 'foo';
    o.extendedAddress = 'foo';
    o.formatted = 'foo';
    o.locality = 'foo';
    o.poBox = 'foo';
    o.postalCode = 'foo';
    o.primary = true;
    o.region = 'foo';
    o.sourceIsStructured = true;
    o.streetAddress = 'foo';
    o.type = 'foo';
  }
  buildCounterUserAddress--;
  return o;
}

void checkUserAddress(api.UserAddress o) {
  buildCounterUserAddress++;
  if (buildCounterUserAddress < 3) {
    unittest.expect(
      o.country!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.countryCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.extendedAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formatted!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locality!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.poBox!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postalCode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sourceIsStructured!, unittest.isTrue);
    unittest.expect(
      o.streetAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserAddress--;
}

api.UserCustomProperties buildUserCustomProperties() {
  var o = api.UserCustomProperties();
  o["a"] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o["b"] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUserCustomProperties(api.UserCustomProperties o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted19 = (o["a"]!) as core.Map;
  unittest.expect(casted19, unittest.hasLength(3));
  unittest.expect(
    casted19['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted19['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted19['string'],
    unittest.equals('foo'),
  );
  var casted20 = (o["b"]!) as core.Map;
  unittest.expect(casted20, unittest.hasLength(3));
  unittest.expect(
    casted20['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted20['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted20['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterUserEmail = 0;
api.UserEmail buildUserEmail() {
  var o = api.UserEmail();
  buildCounterUserEmail++;
  if (buildCounterUserEmail < 3) {
    o.address = 'foo';
    o.customType = 'foo';
    o.primary = true;
    o.type = 'foo';
  }
  buildCounterUserEmail--;
  return o;
}

void checkUserEmail(api.UserEmail o) {
  buildCounterUserEmail++;
  if (buildCounterUserEmail < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserEmail--;
}

core.int buildCounterUserExternalId = 0;
api.UserExternalId buildUserExternalId() {
  var o = api.UserExternalId();
  buildCounterUserExternalId++;
  if (buildCounterUserExternalId < 3) {
    o.customType = 'foo';
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterUserExternalId--;
  return o;
}

void checkUserExternalId(api.UserExternalId o) {
  buildCounterUserExternalId++;
  if (buildCounterUserExternalId < 3) {
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserExternalId--;
}

core.int buildCounterUserGender = 0;
api.UserGender buildUserGender() {
  var o = api.UserGender();
  buildCounterUserGender++;
  if (buildCounterUserGender < 3) {
    o.addressMeAs = 'foo';
    o.customGender = 'foo';
    o.type = 'foo';
  }
  buildCounterUserGender--;
  return o;
}

void checkUserGender(api.UserGender o) {
  buildCounterUserGender++;
  if (buildCounterUserGender < 3) {
    unittest.expect(
      o.addressMeAs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customGender!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserGender--;
}

core.int buildCounterUserIm = 0;
api.UserIm buildUserIm() {
  var o = api.UserIm();
  buildCounterUserIm++;
  if (buildCounterUserIm < 3) {
    o.customProtocol = 'foo';
    o.customType = 'foo';
    o.im = 'foo';
    o.primary = true;
    o.protocol = 'foo';
    o.type = 'foo';
  }
  buildCounterUserIm--;
  return o;
}

void checkUserIm(api.UserIm o) {
  buildCounterUserIm++;
  if (buildCounterUserIm < 3) {
    unittest.expect(
      o.customProtocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.im!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserIm--;
}

core.int buildCounterUserKeyword = 0;
api.UserKeyword buildUserKeyword() {
  var o = api.UserKeyword();
  buildCounterUserKeyword++;
  if (buildCounterUserKeyword < 3) {
    o.customType = 'foo';
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterUserKeyword--;
  return o;
}

void checkUserKeyword(api.UserKeyword o) {
  buildCounterUserKeyword++;
  if (buildCounterUserKeyword < 3) {
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserKeyword--;
}

core.int buildCounterUserLanguage = 0;
api.UserLanguage buildUserLanguage() {
  var o = api.UserLanguage();
  buildCounterUserLanguage++;
  if (buildCounterUserLanguage < 3) {
    o.customLanguage = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterUserLanguage--;
  return o;
}

void checkUserLanguage(api.UserLanguage o) {
  buildCounterUserLanguage++;
  if (buildCounterUserLanguage < 3) {
    unittest.expect(
      o.customLanguage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserLanguage--;
}

core.int buildCounterUserLocation = 0;
api.UserLocation buildUserLocation() {
  var o = api.UserLocation();
  buildCounterUserLocation++;
  if (buildCounterUserLocation < 3) {
    o.area = 'foo';
    o.buildingId = 'foo';
    o.customType = 'foo';
    o.deskCode = 'foo';
    o.floorName = 'foo';
    o.floorSection = 'foo';
    o.type = 'foo';
  }
  buildCounterUserLocation--;
  return o;
}

void checkUserLocation(api.UserLocation o) {
  buildCounterUserLocation++;
  if (buildCounterUserLocation < 3) {
    unittest.expect(
      o.area!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.buildingId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deskCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floorName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floorSection!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserLocation--;
}

core.int buildCounterUserMakeAdmin = 0;
api.UserMakeAdmin buildUserMakeAdmin() {
  var o = api.UserMakeAdmin();
  buildCounterUserMakeAdmin++;
  if (buildCounterUserMakeAdmin < 3) {
    o.status = true;
  }
  buildCounterUserMakeAdmin--;
  return o;
}

void checkUserMakeAdmin(api.UserMakeAdmin o) {
  buildCounterUserMakeAdmin++;
  if (buildCounterUserMakeAdmin < 3) {
    unittest.expect(o.status!, unittest.isTrue);
  }
  buildCounterUserMakeAdmin--;
}

core.int buildCounterUserName = 0;
api.UserName buildUserName() {
  var o = api.UserName();
  buildCounterUserName++;
  if (buildCounterUserName < 3) {
    o.familyName = 'foo';
    o.fullName = 'foo';
    o.givenName = 'foo';
  }
  buildCounterUserName--;
  return o;
}

void checkUserName(api.UserName o) {
  buildCounterUserName++;
  if (buildCounterUserName < 3) {
    unittest.expect(
      o.familyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fullName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.givenName!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserName--;
}

core.int buildCounterUserOrganization = 0;
api.UserOrganization buildUserOrganization() {
  var o = api.UserOrganization();
  buildCounterUserOrganization++;
  if (buildCounterUserOrganization < 3) {
    o.costCenter = 'foo';
    o.customType = 'foo';
    o.department = 'foo';
    o.description = 'foo';
    o.domain = 'foo';
    o.fullTimeEquivalent = 42;
    o.location = 'foo';
    o.name = 'foo';
    o.primary = true;
    o.symbol = 'foo';
    o.title = 'foo';
    o.type = 'foo';
  }
  buildCounterUserOrganization--;
  return o;
}

void checkUserOrganization(api.UserOrganization o) {
  buildCounterUserOrganization++;
  if (buildCounterUserOrganization < 3) {
    unittest.expect(
      o.costCenter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.department!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fullTimeEquivalent!,
      unittest.equals(42),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.symbol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserOrganization--;
}

core.int buildCounterUserPhone = 0;
api.UserPhone buildUserPhone() {
  var o = api.UserPhone();
  buildCounterUserPhone++;
  if (buildCounterUserPhone < 3) {
    o.customType = 'foo';
    o.primary = true;
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterUserPhone--;
  return o;
}

void checkUserPhone(api.UserPhone o) {
  buildCounterUserPhone++;
  if (buildCounterUserPhone < 3) {
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserPhone--;
}

core.int buildCounterUserPhoto = 0;
api.UserPhoto buildUserPhoto() {
  var o = api.UserPhoto();
  buildCounterUserPhoto++;
  if (buildCounterUserPhoto < 3) {
    o.etag = 'foo';
    o.height = 42;
    o.id = 'foo';
    o.kind = 'foo';
    o.mimeType = 'foo';
    o.photoData = 'foo';
    o.primaryEmail = 'foo';
    o.width = 42;
  }
  buildCounterUserPhoto--;
  return o;
}

void checkUserPhoto(api.UserPhoto o) {
  buildCounterUserPhoto++;
  if (buildCounterUserPhoto < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.height!,
      unittest.equals(42),
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
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoData!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.primaryEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterUserPhoto--;
}

core.int buildCounterUserPosixAccount = 0;
api.UserPosixAccount buildUserPosixAccount() {
  var o = api.UserPosixAccount();
  buildCounterUserPosixAccount++;
  if (buildCounterUserPosixAccount < 3) {
    o.accountId = 'foo';
    o.gecos = 'foo';
    o.gid = 'foo';
    o.homeDirectory = 'foo';
    o.operatingSystemType = 'foo';
    o.primary = true;
    o.shell = 'foo';
    o.systemId = 'foo';
    o.uid = 'foo';
    o.username = 'foo';
  }
  buildCounterUserPosixAccount--;
  return o;
}

void checkUserPosixAccount(api.UserPosixAccount o) {
  buildCounterUserPosixAccount++;
  if (buildCounterUserPosixAccount < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gecos!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.homeDirectory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatingSystemType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.shell!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.systemId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserPosixAccount--;
}

core.int buildCounterUserRelation = 0;
api.UserRelation buildUserRelation() {
  var o = api.UserRelation();
  buildCounterUserRelation++;
  if (buildCounterUserRelation < 3) {
    o.customType = 'foo';
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterUserRelation--;
  return o;
}

void checkUserRelation(api.UserRelation o) {
  buildCounterUserRelation++;
  if (buildCounterUserRelation < 3) {
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserRelation--;
}

core.int buildCounterUserSshPublicKey = 0;
api.UserSshPublicKey buildUserSshPublicKey() {
  var o = api.UserSshPublicKey();
  buildCounterUserSshPublicKey++;
  if (buildCounterUserSshPublicKey < 3) {
    o.expirationTimeUsec = 'foo';
    o.fingerprint = 'foo';
    o.key = 'foo';
  }
  buildCounterUserSshPublicKey--;
  return o;
}

void checkUserSshPublicKey(api.UserSshPublicKey o) {
  buildCounterUserSshPublicKey++;
  if (buildCounterUserSshPublicKey < 3) {
    unittest.expect(
      o.expirationTimeUsec!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fingerprint!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserSshPublicKey--;
}

core.int buildCounterUserUndelete = 0;
api.UserUndelete buildUserUndelete() {
  var o = api.UserUndelete();
  buildCounterUserUndelete++;
  if (buildCounterUserUndelete < 3) {
    o.orgUnitPath = 'foo';
  }
  buildCounterUserUndelete--;
  return o;
}

void checkUserUndelete(api.UserUndelete o) {
  buildCounterUserUndelete++;
  if (buildCounterUserUndelete < 3) {
    unittest.expect(
      o.orgUnitPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserUndelete--;
}

core.int buildCounterUserWebsite = 0;
api.UserWebsite buildUserWebsite() {
  var o = api.UserWebsite();
  buildCounterUserWebsite++;
  if (buildCounterUserWebsite < 3) {
    o.customType = 'foo';
    o.primary = true;
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterUserWebsite--;
  return o;
}

void checkUserWebsite(api.UserWebsite o) {
  buildCounterUserWebsite++;
  if (buildCounterUserWebsite < 3) {
    unittest.expect(
      o.customType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.primary!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserWebsite--;
}

core.List<api.User> buildUnnamed2001() {
  var o = <api.User>[];
  o.add(buildUser());
  o.add(buildUser());
  return o;
}

void checkUnnamed2001(core.List<api.User> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUser(o[0] as api.User);
  checkUser(o[1] as api.User);
}

core.int buildCounterUsers = 0;
api.Users buildUsers() {
  var o = api.Users();
  buildCounterUsers++;
  if (buildCounterUsers < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.triggerEvent = 'foo';
    o.users = buildUnnamed2001();
  }
  buildCounterUsers--;
  return o;
}

void checkUsers(api.Users o) {
  buildCounterUsers++;
  if (buildCounterUsers < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.triggerEvent!,
      unittest.equals('foo'),
    );
    checkUnnamed2001(o.users!);
  }
  buildCounterUsers--;
}

core.int buildCounterVerificationCode = 0;
api.VerificationCode buildVerificationCode() {
  var o = api.VerificationCode();
  buildCounterVerificationCode++;
  if (buildCounterVerificationCode < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.userId = 'foo';
    o.verificationCode = 'foo';
  }
  buildCounterVerificationCode--;
  return o;
}

void checkVerificationCode(api.VerificationCode o) {
  buildCounterVerificationCode++;
  if (buildCounterVerificationCode < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterVerificationCode--;
}

core.List<api.VerificationCode> buildUnnamed2002() {
  var o = <api.VerificationCode>[];
  o.add(buildVerificationCode());
  o.add(buildVerificationCode());
  return o;
}

void checkUnnamed2002(core.List<api.VerificationCode> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkVerificationCode(o[0] as api.VerificationCode);
  checkVerificationCode(o[1] as api.VerificationCode);
}

core.int buildCounterVerificationCodes = 0;
api.VerificationCodes buildVerificationCodes() {
  var o = api.VerificationCodes();
  buildCounterVerificationCodes++;
  if (buildCounterVerificationCodes < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed2002();
    o.kind = 'foo';
  }
  buildCounterVerificationCodes--;
  return o;
}

void checkVerificationCodes(api.VerificationCodes o) {
  buildCounterVerificationCodes++;
  if (buildCounterVerificationCodes < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed2002(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterVerificationCodes--;
}

void main() {
  unittest.group('obj-schema-Alias', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAlias();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Alias.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAlias(od as api.Alias);
    });
  });

  unittest.group('obj-schema-Aliases', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAliases();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Aliases.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAliases(od as api.Aliases);
    });
  });

  unittest.group('obj-schema-Asp', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsp();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Asp.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAsp(od as api.Asp);
    });
  });

  unittest.group('obj-schema-Asps', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsps();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Asps.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAsps(od as api.Asps);
    });
  });

  unittest.group('obj-schema-AuxiliaryMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuxiliaryMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuxiliaryMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuxiliaryMessage(od as api.AuxiliaryMessage);
    });
  });

  unittest.group('obj-schema-BatchCreatePrintersRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchCreatePrintersRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchCreatePrintersRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchCreatePrintersRequest(od as api.BatchCreatePrintersRequest);
    });
  });

  unittest.group('obj-schema-BatchCreatePrintersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchCreatePrintersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchCreatePrintersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchCreatePrintersResponse(od as api.BatchCreatePrintersResponse);
    });
  });

  unittest.group('obj-schema-BatchDeletePrintersRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeletePrintersRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeletePrintersRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeletePrintersRequest(od as api.BatchDeletePrintersRequest);
    });
  });

  unittest.group('obj-schema-BatchDeletePrintersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeletePrintersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeletePrintersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeletePrintersResponse(od as api.BatchDeletePrintersResponse);
    });
  });

  unittest.group('obj-schema-Building', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuilding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Building.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBuilding(od as api.Building);
    });
  });

  unittest.group('obj-schema-BuildingAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildingAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildingAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildingAddress(od as api.BuildingAddress);
    });
  });

  unittest.group('obj-schema-BuildingCoordinates', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildingCoordinates();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BuildingCoordinates.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBuildingCoordinates(od as api.BuildingCoordinates);
    });
  });

  unittest.group('obj-schema-Buildings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuildings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Buildings.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBuildings(od as api.Buildings);
    });
  });

  unittest.group('obj-schema-CalendarResource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCalendarResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CalendarResource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCalendarResource(od as api.CalendarResource);
    });
  });

  unittest.group('obj-schema-CalendarResources', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCalendarResources();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CalendarResources.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCalendarResources(od as api.CalendarResources);
    });
  });

  unittest.group('obj-schema-Channel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Channel.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChannel(od as api.Channel);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceActiveTimeRanges', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceActiveTimeRanges();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceActiveTimeRanges.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceActiveTimeRanges(
          od as api.ChromeOsDeviceActiveTimeRanges);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceCpuStatusReportsCpuTemperatureInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceCpuStatusReportsCpuTemperatureInfo(
          od as api.ChromeOsDeviceCpuStatusReportsCpuTemperatureInfo);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceCpuStatusReports', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceCpuStatusReports();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceCpuStatusReports.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceCpuStatusReports(
          od as api.ChromeOsDeviceCpuStatusReports);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceDeviceFiles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceDeviceFiles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceDeviceFiles.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceDeviceFiles(od as api.ChromeOsDeviceDeviceFiles);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceDiskVolumeReportsVolumeInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceDiskVolumeReportsVolumeInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceDiskVolumeReportsVolumeInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceDiskVolumeReportsVolumeInfo(
          od as api.ChromeOsDeviceDiskVolumeReportsVolumeInfo);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceDiskVolumeReports', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceDiskVolumeReports();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceDiskVolumeReports.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceDiskVolumeReports(
          od as api.ChromeOsDeviceDiskVolumeReports);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceLastKnownNetwork', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceLastKnownNetwork();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceLastKnownNetwork.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceLastKnownNetwork(
          od as api.ChromeOsDeviceLastKnownNetwork);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceRecentUsers', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceRecentUsers();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceRecentUsers.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceRecentUsers(od as api.ChromeOsDeviceRecentUsers);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceScreenshotFiles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceScreenshotFiles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceScreenshotFiles.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceScreenshotFiles(
          od as api.ChromeOsDeviceScreenshotFiles);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceSystemRamFreeReports', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceSystemRamFreeReports();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceSystemRamFreeReports.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceSystemRamFreeReports(
          od as api.ChromeOsDeviceSystemRamFreeReports);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceTpmVersionInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceTpmVersionInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceTpmVersionInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceTpmVersionInfo(od as api.ChromeOsDeviceTpmVersionInfo);
    });
  });

  unittest.group('obj-schema-ChromeOsDevice', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDevice.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDevice(od as api.ChromeOsDevice);
    });
  });

  unittest.group('obj-schema-ChromeOsDeviceAction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDeviceAction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDeviceAction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDeviceAction(od as api.ChromeOsDeviceAction);
    });
  });

  unittest.group('obj-schema-ChromeOsDevices', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsDevices();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsDevices.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsDevices(od as api.ChromeOsDevices);
    });
  });

  unittest.group('obj-schema-ChromeOsMoveDevicesToOu', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChromeOsMoveDevicesToOu();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChromeOsMoveDevicesToOu.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChromeOsMoveDevicesToOu(od as api.ChromeOsMoveDevicesToOu);
    });
  });

  unittest.group('obj-schema-CreatePrinterRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreatePrinterRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreatePrinterRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreatePrinterRequest(od as api.CreatePrinterRequest);
    });
  });

  unittest.group('obj-schema-Customer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Customer.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCustomer(od as api.Customer);
    });
  });

  unittest.group('obj-schema-CustomerPostalAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerPostalAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerPostalAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerPostalAddress(od as api.CustomerPostalAddress);
    });
  });

  unittest.group('obj-schema-DirectoryChromeosdevicesCommand', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDirectoryChromeosdevicesCommand();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DirectoryChromeosdevicesCommand.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDirectoryChromeosdevicesCommand(
          od as api.DirectoryChromeosdevicesCommand);
    });
  });

  unittest.group('obj-schema-DirectoryChromeosdevicesCommandResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDirectoryChromeosdevicesCommandResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DirectoryChromeosdevicesCommandResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDirectoryChromeosdevicesCommandResult(
          od as api.DirectoryChromeosdevicesCommandResult);
    });
  });

  unittest.group('obj-schema-DirectoryChromeosdevicesIssueCommandRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDirectoryChromeosdevicesIssueCommandRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DirectoryChromeosdevicesIssueCommandRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDirectoryChromeosdevicesIssueCommandRequest(
          od as api.DirectoryChromeosdevicesIssueCommandRequest);
    });
  });

  unittest.group('obj-schema-DirectoryChromeosdevicesIssueCommandResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDirectoryChromeosdevicesIssueCommandResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DirectoryChromeosdevicesIssueCommandResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDirectoryChromeosdevicesIssueCommandResponse(
          od as api.DirectoryChromeosdevicesIssueCommandResponse);
    });
  });

  unittest.group('obj-schema-DomainAlias', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomainAlias();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DomainAlias.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDomainAlias(od as api.DomainAlias);
    });
  });

  unittest.group('obj-schema-DomainAliases', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomainAliases();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DomainAliases.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDomainAliases(od as api.DomainAliases);
    });
  });

  unittest.group('obj-schema-Domains', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomains();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Domains.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDomains(od as api.Domains);
    });
  });

  unittest.group('obj-schema-Domains2', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomains2();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Domains2.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDomains2(od as api.Domains2);
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

  unittest.group('obj-schema-FailureInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFailureInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FailureInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFailureInfo(od as api.FailureInfo);
    });
  });

  unittest.group('obj-schema-Feature', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeature();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Feature.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFeature(od as api.Feature);
    });
  });

  unittest.group('obj-schema-FeatureInstance', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatureInstance();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeatureInstance.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeatureInstance(od as api.FeatureInstance);
    });
  });

  unittest.group('obj-schema-FeatureRename', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatureRename();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeatureRename.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeatureRename(od as api.FeatureRename);
    });
  });

  unittest.group('obj-schema-Features', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatures();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Features.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFeatures(od as api.Features);
    });
  });

  unittest.group('obj-schema-Group', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Group.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGroup(od as api.Group);
    });
  });

  unittest.group('obj-schema-Groups', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroups();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Groups.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGroups(od as api.Groups);
    });
  });

  unittest.group('obj-schema-ListPrinterModelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPrinterModelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPrinterModelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPrinterModelsResponse(od as api.ListPrinterModelsResponse);
    });
  });

  unittest.group('obj-schema-ListPrintersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPrintersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPrintersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPrintersResponse(od as api.ListPrintersResponse);
    });
  });

  unittest.group('obj-schema-Member', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMember();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Member.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMember(od as api.Member);
    });
  });

  unittest.group('obj-schema-Members', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembers();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Members.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMembers(od as api.Members);
    });
  });

  unittest.group('obj-schema-MembersHasMember', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembersHasMember();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MembersHasMember.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMembersHasMember(od as api.MembersHasMember);
    });
  });

  unittest.group('obj-schema-MobileDeviceApplications', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMobileDeviceApplications();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MobileDeviceApplications.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMobileDeviceApplications(od as api.MobileDeviceApplications);
    });
  });

  unittest.group('obj-schema-MobileDevice', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMobileDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MobileDevice.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMobileDevice(od as api.MobileDevice);
    });
  });

  unittest.group('obj-schema-MobileDeviceAction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMobileDeviceAction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MobileDeviceAction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMobileDeviceAction(od as api.MobileDeviceAction);
    });
  });

  unittest.group('obj-schema-MobileDevices', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMobileDevices();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MobileDevices.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMobileDevices(od as api.MobileDevices);
    });
  });

  unittest.group('obj-schema-OrgUnit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrgUnit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OrgUnit.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOrgUnit(od as api.OrgUnit);
    });
  });

  unittest.group('obj-schema-OrgUnits', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrgUnits();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OrgUnits.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOrgUnits(od as api.OrgUnits);
    });
  });

  unittest.group('obj-schema-Printer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrinter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Printer.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrinter(od as api.Printer);
    });
  });

  unittest.group('obj-schema-PrinterModel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrinterModel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PrinterModel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrinterModel(od as api.PrinterModel);
    });
  });

  unittest.group('obj-schema-Privilege', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrivilege();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Privilege.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrivilege(od as api.Privilege);
    });
  });

  unittest.group('obj-schema-Privileges', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrivileges();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Privileges.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrivileges(od as api.Privileges);
    });
  });

  unittest.group('obj-schema-RoleRolePrivileges', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoleRolePrivileges();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoleRolePrivileges.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoleRolePrivileges(od as api.RoleRolePrivileges);
    });
  });

  unittest.group('obj-schema-Role', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRole();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Role.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRole(od as api.Role);
    });
  });

  unittest.group('obj-schema-RoleAssignment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoleAssignment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoleAssignment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoleAssignment(od as api.RoleAssignment);
    });
  });

  unittest.group('obj-schema-RoleAssignments', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoleAssignments();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoleAssignments.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoleAssignments(od as api.RoleAssignments);
    });
  });

  unittest.group('obj-schema-Roles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Roles.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRoles(od as api.Roles);
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

  unittest.group('obj-schema-SchemaFieldSpecNumericIndexingSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaFieldSpecNumericIndexingSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaFieldSpecNumericIndexingSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaFieldSpecNumericIndexingSpec(
          od as api.SchemaFieldSpecNumericIndexingSpec);
    });
  });

  unittest.group('obj-schema-SchemaFieldSpec', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaFieldSpec();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaFieldSpec.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaFieldSpec(od as api.SchemaFieldSpec);
    });
  });

  unittest.group('obj-schema-Schemas', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemas();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Schemas.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSchemas(od as api.Schemas);
    });
  });

  unittest.group('obj-schema-Token', () {
    unittest.test('to-json--from-json', () async {
      var o = buildToken();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Token.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkToken(od as api.Token);
    });
  });

  unittest.group('obj-schema-Tokens', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTokens();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Tokens.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTokens(od as api.Tokens);
    });
  });

  unittest.group('obj-schema-User', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.User.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUser(od as api.User);
    });
  });

  unittest.group('obj-schema-UserAbout', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserAbout();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserAbout.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserAbout(od as api.UserAbout);
    });
  });

  unittest.group('obj-schema-UserAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserAddress(od as api.UserAddress);
    });
  });

  unittest.group('obj-schema-UserCustomProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserCustomProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserCustomProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserCustomProperties(od as api.UserCustomProperties);
    });
  });

  unittest.group('obj-schema-UserEmail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserEmail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserEmail.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserEmail(od as api.UserEmail);
    });
  });

  unittest.group('obj-schema-UserExternalId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserExternalId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserExternalId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserExternalId(od as api.UserExternalId);
    });
  });

  unittest.group('obj-schema-UserGender', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserGender();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserGender.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserGender(od as api.UserGender);
    });
  });

  unittest.group('obj-schema-UserIm', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserIm();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserIm.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserIm(od as api.UserIm);
    });
  });

  unittest.group('obj-schema-UserKeyword', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserKeyword();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserKeyword.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserKeyword(od as api.UserKeyword);
    });
  });

  unittest.group('obj-schema-UserLanguage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserLanguage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserLanguage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserLanguage(od as api.UserLanguage);
    });
  });

  unittest.group('obj-schema-UserLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserLocation(od as api.UserLocation);
    });
  });

  unittest.group('obj-schema-UserMakeAdmin', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserMakeAdmin();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserMakeAdmin.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserMakeAdmin(od as api.UserMakeAdmin);
    });
  });

  unittest.group('obj-schema-UserName', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserName();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserName.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserName(od as api.UserName);
    });
  });

  unittest.group('obj-schema-UserOrganization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserOrganization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserOrganization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserOrganization(od as api.UserOrganization);
    });
  });

  unittest.group('obj-schema-UserPhone', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserPhone();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserPhone.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserPhone(od as api.UserPhone);
    });
  });

  unittest.group('obj-schema-UserPhoto', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserPhoto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UserPhoto.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUserPhoto(od as api.UserPhoto);
    });
  });

  unittest.group('obj-schema-UserPosixAccount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserPosixAccount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserPosixAccount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserPosixAccount(od as api.UserPosixAccount);
    });
  });

  unittest.group('obj-schema-UserRelation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserRelation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserRelation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserRelation(od as api.UserRelation);
    });
  });

  unittest.group('obj-schema-UserSshPublicKey', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserSshPublicKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserSshPublicKey.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserSshPublicKey(od as api.UserSshPublicKey);
    });
  });

  unittest.group('obj-schema-UserUndelete', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserUndelete();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserUndelete.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserUndelete(od as api.UserUndelete);
    });
  });

  unittest.group('obj-schema-UserWebsite', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserWebsite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserWebsite.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserWebsite(od as api.UserWebsite);
    });
  });

  unittest.group('obj-schema-Users', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsers();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Users.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUsers(od as api.Users);
    });
  });

  unittest.group('obj-schema-VerificationCode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerificationCode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerificationCode.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerificationCode(od as api.VerificationCode);
    });
  });

  unittest.group('obj-schema-VerificationCodes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVerificationCodes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VerificationCodes.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVerificationCodes(od as api.VerificationCodes);
    });
  });

  unittest.group('resource-AspsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).asps;
      var arg_userKey = 'foo';
      var arg_codeId = 42;
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/asps/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/asps/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_codeId'),
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
      await res.delete(arg_userKey, arg_codeId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).asps;
      var arg_userKey = 'foo';
      var arg_codeId = 42;
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/asps/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/asps/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_codeId'),
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
        var resp = convert.json.encode(buildAsp());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_userKey, arg_codeId, $fields: arg_$fields);
      checkAsp(response as api.Asp);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).asps;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/asps', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/asps"),
        );
        pathOffset += 5;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildAsps());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userKey, $fields: arg_$fields);
      checkAsps(response as api.Asps);
    });
  });

  unittest.group('resource-ChannelsResource', () {
    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).channels;
      var arg_request = buildChannel();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Channel.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChannel(obj as api.Channel);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("admin/directory_v1/channels/stop"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.stop(arg_request, $fields: arg_$fields);
    });
  });

  unittest.group('resource-ChromeosdevicesResource', () {
    unittest.test('method--action', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).chromeosdevices;
      var arg_request = buildChromeOsDeviceAction();
      var arg_customerId = 'foo';
      var arg_resourceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChromeOsDeviceAction.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChromeOsDeviceAction(obj as api.ChromeOsDeviceAction);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/devices/chromeos/"),
        );
        pathOffset += 18;
        index = path.indexOf('/action', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/action"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.action(arg_request, arg_customerId, arg_resourceId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).chromeosdevices;
      var arg_customerId = 'foo';
      var arg_deviceId = 'foo';
      var arg_projection = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/devices/chromeos/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deviceId'),
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
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChromeOsDevice());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customerId, arg_deviceId,
          projection: arg_projection, $fields: arg_$fields);
      checkChromeOsDevice(response as api.ChromeOsDevice);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).chromeosdevices;
      var arg_customerId = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
      var arg_orgUnitPath = 'foo';
      var arg_pageToken = 'foo';
      var arg_projection = 'foo';
      var arg_query = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/devices/chromeos"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["orgUnitPath"]!.first,
          unittest.equals(arg_orgUnitPath),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
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
        var resp = convert.json.encode(buildChromeOsDevices());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customerId,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          orgUnitPath: arg_orgUnitPath,
          pageToken: arg_pageToken,
          projection: arg_projection,
          query: arg_query,
          sortOrder: arg_sortOrder,
          $fields: arg_$fields);
      checkChromeOsDevices(response as api.ChromeOsDevices);
    });

    unittest.test('method--moveDevicesToOu', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).chromeosdevices;
      var arg_request = buildChromeOsMoveDevicesToOu();
      var arg_customerId = 'foo';
      var arg_orgUnitPath = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChromeOsMoveDevicesToOu.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChromeOsMoveDevicesToOu(obj as api.ChromeOsMoveDevicesToOu);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/moveDevicesToOu', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("/devices/chromeos/moveDevicesToOu"),
        );
        pathOffset += 33;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["orgUnitPath"]!.first,
          unittest.equals(arg_orgUnitPath),
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
      await res.moveDevicesToOu(arg_request, arg_customerId, arg_orgUnitPath,
          $fields: arg_$fields);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).chromeosdevices;
      var arg_request = buildChromeOsDevice();
      var arg_customerId = 'foo';
      var arg_deviceId = 'foo';
      var arg_projection = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChromeOsDevice.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChromeOsDevice(obj as api.ChromeOsDevice);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/devices/chromeos/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deviceId'),
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
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChromeOsDevice());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_customerId, arg_deviceId,
          projection: arg_projection, $fields: arg_$fields);
      checkChromeOsDevice(response as api.ChromeOsDevice);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).chromeosdevices;
      var arg_request = buildChromeOsDevice();
      var arg_customerId = 'foo';
      var arg_deviceId = 'foo';
      var arg_projection = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChromeOsDevice.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChromeOsDevice(obj as api.ChromeOsDevice);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/devices/chromeos/"),
        );
        pathOffset += 18;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deviceId'),
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
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChromeOsDevice());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_customerId, arg_deviceId,
          projection: arg_projection, $fields: arg_$fields);
      checkChromeOsDevice(response as api.ChromeOsDevice);
    });
  });

  unittest.group('resource-CustomerDevicesChromeosResource', () {
    unittest.test('method--issueCommand', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customer.devices.chromeos;
      var arg_request = buildDirectoryChromeosdevicesIssueCommandRequest();
      var arg_customerId = 'foo';
      var arg_deviceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DirectoryChromeosdevicesIssueCommandRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDirectoryChromeosdevicesIssueCommandRequest(
            obj as api.DirectoryChromeosdevicesIssueCommandRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/devices/chromeos/"),
        );
        pathOffset += 18;
        index = path.indexOf(':issueCommand', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deviceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals(":issueCommand"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildDirectoryChromeosdevicesIssueCommandResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.issueCommand(
          arg_request, arg_customerId, arg_deviceId,
          $fields: arg_$fields);
      checkDirectoryChromeosdevicesIssueCommandResponse(
          response as api.DirectoryChromeosdevicesIssueCommandResponse);
    });
  });

  unittest.group('resource-CustomerDevicesChromeosCommandsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customer.devices.chromeos.commands;
      var arg_customerId = 'foo';
      var arg_deviceId = 'foo';
      var arg_commandId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/chromeos/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/devices/chromeos/"),
        );
        pathOffset += 18;
        index = path.indexOf('/commands/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_deviceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/commands/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_commandId'),
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
        var resp = convert.json.encode(buildDirectoryChromeosdevicesCommand());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_customerId, arg_deviceId, arg_commandId,
          $fields: arg_$fields);
      checkDirectoryChromeosdevicesCommand(
          response as api.DirectoryChromeosdevicesCommand);
    });
  });

  unittest.group('resource-CustomersResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers;
      var arg_customerKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("admin/directory/v1/customers/"),
        );
        pathOffset += 29;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerKey'),
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
        var resp = convert.json.encode(buildCustomer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customerKey, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers;
      var arg_request = buildCustomer();
      var arg_customerKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Customer.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCustomer(obj as api.Customer);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("admin/directory/v1/customers/"),
        );
        pathOffset += 29;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerKey'),
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
        var resp = convert.json.encode(buildCustomer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_customerKey, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers;
      var arg_request = buildCustomer();
      var arg_customerKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Customer.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCustomer(obj as api.Customer);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("admin/directory/v1/customers/"),
        );
        pathOffset += 29;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerKey'),
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
        var resp = convert.json.encode(buildCustomer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_customerKey, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });
  });

  unittest.group('resource-CustomersChromePrintersResource', () {
    unittest.test('method--batchCreatePrinters', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
      var arg_request = buildBatchCreatePrintersRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchCreatePrintersRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchCreatePrintersRequest(obj as api.BatchCreatePrintersRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
        var resp = convert.json.encode(buildBatchCreatePrintersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchCreatePrinters(arg_request, arg_parent,
          $fields: arg_$fields);
      checkBatchCreatePrintersResponse(
          response as api.BatchCreatePrintersResponse);
    });

    unittest.test('method--batchDeletePrinters', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
      var arg_request = buildBatchDeletePrintersRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchDeletePrintersRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchDeletePrintersRequest(obj as api.BatchDeletePrintersRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
        var resp = convert.json.encode(buildBatchDeletePrintersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchDeletePrinters(arg_request, arg_parent,
          $fields: arg_$fields);
      checkBatchDeletePrintersResponse(
          response as api.BatchDeletePrintersResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
      var arg_request = buildPrinter();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Printer.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPrinter(obj as api.Printer);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
        var resp = convert.json.encode(buildPrinter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkPrinter(response as api.Printer);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
      var res = api.DirectoryApi(mock).customers.chrome.printers;
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
        var resp = convert.json.encode(buildPrinter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkPrinter(response as api.Printer);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
      var arg_parent = 'foo';
      var arg_filter = 'foo';
      var arg_orgUnitId = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
          queryMap["orgUnitId"]!.first,
          unittest.equals(arg_orgUnitId),
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
        var resp = convert.json.encode(buildListPrintersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          orgUnitId: arg_orgUnitId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPrintersResponse(response as api.ListPrintersResponse);
    });

    unittest.test('method--listPrinterModels', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
      var arg_parent = 'foo';
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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
        var resp = convert.json.encode(buildListPrinterModelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listPrinterModels(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPrinterModelsResponse(response as api.ListPrinterModelsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).customers.chrome.printers;
      var arg_request = buildPrinter();
      var arg_name = 'foo';
      var arg_clearMask = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Printer.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPrinter(obj as api.Printer);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("admin/directory/v1/"),
        );
        pathOffset += 19;
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
          queryMap["clearMask"]!.first,
          unittest.equals(arg_clearMask),
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
        var resp = convert.json.encode(buildPrinter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          clearMask: arg_clearMask,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkPrinter(response as api.Printer);
    });
  });

  unittest.group('resource-DomainAliasesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domainAliases;
      var arg_customer = 'foo';
      var arg_domainAliasName = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domainaliases/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/domainaliases/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainAliasName'),
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
      await res.delete(arg_customer, arg_domainAliasName, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domainAliases;
      var arg_customer = 'foo';
      var arg_domainAliasName = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domainaliases/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/domainaliases/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainAliasName'),
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
        var resp = convert.json.encode(buildDomainAlias());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customer, arg_domainAliasName,
          $fields: arg_$fields);
      checkDomainAlias(response as api.DomainAlias);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domainAliases;
      var arg_request = buildDomainAlias();
      var arg_customer = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DomainAlias.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDomainAlias(obj as api.DomainAlias);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domainaliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/domainaliases"),
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
        var resp = convert.json.encode(buildDomainAlias());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customer, $fields: arg_$fields);
      checkDomainAlias(response as api.DomainAlias);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domainAliases;
      var arg_customer = 'foo';
      var arg_parentDomainName = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domainaliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/domainaliases"),
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
          queryMap["parentDomainName"]!.first,
          unittest.equals(arg_parentDomainName),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDomainAliases());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer,
          parentDomainName: arg_parentDomainName, $fields: arg_$fields);
      checkDomainAliases(response as api.DomainAliases);
    });
  });

  unittest.group('resource-DomainsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domains;
      var arg_customer = 'foo';
      var arg_domainName = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domains/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/domains/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainName'),
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
      await res.delete(arg_customer, arg_domainName, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domains;
      var arg_customer = 'foo';
      var arg_domainName = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domains/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/domains/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_domainName'),
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
        var resp = convert.json.encode(buildDomains());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_customer, arg_domainName, $fields: arg_$fields);
      checkDomains(response as api.Domains);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domains;
      var arg_request = buildDomains();
      var arg_customer = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Domains.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDomains(obj as api.Domains);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domains', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/domains"),
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
        var resp = convert.json.encode(buildDomains());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customer, $fields: arg_$fields);
      checkDomains(response as api.Domains);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).domains;
      var arg_customer = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/domains', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/domains"),
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
        var resp = convert.json.encode(buildDomains2());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer, $fields: arg_$fields);
      checkDomains2(response as api.Domains2);
    });
  });

  unittest.group('resource-GroupsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups;
      var arg_groupKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
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
      await res.delete(arg_groupKey, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups;
      var arg_groupKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
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
        var resp = convert.json.encode(buildGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_groupKey, $fields: arg_$fields);
      checkGroup(response as api.Group);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups;
      var arg_request = buildGroup();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Group.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGroup(obj as api.Group);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/groups"),
        );
        pathOffset += 25;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkGroup(response as api.Group);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups;
      var arg_customer = 'foo';
      var arg_domain = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
      var arg_sortOrder = 'foo';
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/groups"),
        );
        pathOffset += 25;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["customer"]!.first,
          unittest.equals(arg_customer),
        );
        unittest.expect(
          queryMap["domain"]!.first,
          unittest.equals(arg_domain),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["sortOrder"]!.first,
          unittest.equals(arg_sortOrder),
        );
        unittest.expect(
          queryMap["userKey"]!.first,
          unittest.equals(arg_userKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGroups());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          customer: arg_customer,
          domain: arg_domain,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          query: arg_query,
          sortOrder: arg_sortOrder,
          userKey: arg_userKey,
          $fields: arg_$fields);
      checkGroups(response as api.Groups);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups;
      var arg_request = buildGroup();
      var arg_groupKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Group.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGroup(obj as api.Group);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
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
        var resp = convert.json.encode(buildGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_groupKey, $fields: arg_$fields);
      checkGroup(response as api.Group);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups;
      var arg_request = buildGroup();
      var arg_groupKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Group.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGroup(obj as api.Group);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
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
        var resp = convert.json.encode(buildGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_groupKey, $fields: arg_$fields);
      checkGroup(response as api.Group);
    });
  });

  unittest.group('resource-GroupsAliasesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups.aliases;
      var arg_groupKey = 'foo';
      var arg_alias = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/aliases/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/aliases/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_alias'),
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
      await res.delete(arg_groupKey, arg_alias, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups.aliases;
      var arg_request = buildAlias();
      var arg_groupKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Alias.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAlias(obj as api.Alias);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/aliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/aliases"),
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
        var resp = convert.json.encode(buildAlias());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_groupKey, $fields: arg_$fields);
      checkAlias(response as api.Alias);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).groups.aliases;
      var arg_groupKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/aliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/aliases"),
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
        var resp = convert.json.encode(buildAliases());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_groupKey, $fields: arg_$fields);
      checkAliases(response as api.Aliases);
    });
  });

  unittest.group('resource-MembersResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_groupKey = 'foo';
      var arg_memberKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/members/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/members/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_memberKey'),
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
      await res.delete(arg_groupKey, arg_memberKey, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_groupKey = 'foo';
      var arg_memberKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/members/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/members/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_memberKey'),
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
        var resp = convert.json.encode(buildMember());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_groupKey, arg_memberKey, $fields: arg_$fields);
      checkMember(response as api.Member);
    });

    unittest.test('method--hasMember', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_groupKey = 'foo';
      var arg_memberKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/hasMember/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/hasMember/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_memberKey'),
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
        var resp = convert.json.encode(buildMembersHasMember());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.hasMember(arg_groupKey, arg_memberKey,
          $fields: arg_$fields);
      checkMembersHasMember(response as api.MembersHasMember);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_request = buildMember();
      var arg_groupKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Member.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMember(obj as api.Member);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/members', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/members"),
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
        var resp = convert.json.encode(buildMember());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_groupKey, $fields: arg_$fields);
      checkMember(response as api.Member);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_groupKey = 'foo';
      var arg_includeDerivedMembership = true;
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_roles = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/members', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/members"),
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
          queryMap["includeDerivedMembership"]!.first,
          unittest.equals("$arg_includeDerivedMembership"),
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
          queryMap["roles"]!.first,
          unittest.equals(arg_roles),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMembers());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_groupKey,
          includeDerivedMembership: arg_includeDerivedMembership,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          roles: arg_roles,
          $fields: arg_$fields);
      checkMembers(response as api.Members);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_request = buildMember();
      var arg_groupKey = 'foo';
      var arg_memberKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Member.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMember(obj as api.Member);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/members/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/members/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_memberKey'),
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
        var resp = convert.json.encode(buildMember());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_groupKey, arg_memberKey,
          $fields: arg_$fields);
      checkMember(response as api.Member);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).members;
      var arg_request = buildMember();
      var arg_groupKey = 'foo';
      var arg_memberKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Member.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMember(obj as api.Member);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("admin/directory/v1/groups/"),
        );
        pathOffset += 26;
        index = path.indexOf('/members/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_groupKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/members/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_memberKey'),
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
        var resp = convert.json.encode(buildMember());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_groupKey, arg_memberKey,
          $fields: arg_$fields);
      checkMember(response as api.Member);
    });
  });

  unittest.group('resource-MobiledevicesResource', () {
    unittest.test('method--action', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).mobiledevices;
      var arg_request = buildMobileDeviceAction();
      var arg_customerId = 'foo';
      var arg_resourceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.MobileDeviceAction.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkMobileDeviceAction(obj as api.MobileDeviceAction);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/mobile/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/devices/mobile/"),
        );
        pathOffset += 16;
        index = path.indexOf('/action', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/action"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.action(arg_request, arg_customerId, arg_resourceId,
          $fields: arg_$fields);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).mobiledevices;
      var arg_customerId = 'foo';
      var arg_resourceId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/mobile/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/devices/mobile/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resourceId'),
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
      await res.delete(arg_customerId, arg_resourceId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).mobiledevices;
      var arg_customerId = 'foo';
      var arg_resourceId = 'foo';
      var arg_projection = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/mobile/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/devices/mobile/"),
        );
        pathOffset += 16;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resourceId'),
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
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMobileDevice());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customerId, arg_resourceId,
          projection: arg_projection, $fields: arg_$fields);
      checkMobileDevice(response as api.MobileDevice);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).mobiledevices;
      var arg_customerId = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
      var arg_pageToken = 'foo';
      var arg_projection = 'foo';
      var arg_query = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/devices/mobile', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/devices/mobile"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
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
        var resp = convert.json.encode(buildMobileDevices());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customerId,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          projection: arg_projection,
          query: arg_query,
          sortOrder: arg_sortOrder,
          $fields: arg_$fields);
      checkMobileDevices(response as api.MobileDevices);
    });
  });

  unittest.group('resource-OrgunitsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).orgunits;
      var arg_customerId = 'foo';
      var arg_orgUnitPath = 'foo';
      var arg_allowPlus = true;
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/orgunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/orgunits/"),
        );
        pathOffset += 10;
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
          queryMap["allowPlus"]!.first,
          unittest.equals("$arg_allowPlus"),
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
      await res.delete(arg_customerId, arg_orgUnitPath,
          allowPlus: arg_allowPlus, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).orgunits;
      var arg_customerId = 'foo';
      var arg_orgUnitPath = 'foo';
      var arg_allowPlus = true;
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/orgunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/orgunits/"),
        );
        pathOffset += 10;
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
          queryMap["allowPlus"]!.first,
          unittest.equals("$arg_allowPlus"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOrgUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customerId, arg_orgUnitPath,
          allowPlus: arg_allowPlus, $fields: arg_$fields);
      checkOrgUnit(response as api.OrgUnit);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).orgunits;
      var arg_request = buildOrgUnit();
      var arg_customerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.OrgUnit.fromJson(json as core.Map<core.String, core.dynamic>);
        checkOrgUnit(obj as api.OrgUnit);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/orgunits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/orgunits"),
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
        var resp = convert.json.encode(buildOrgUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customerId, $fields: arg_$fields);
      checkOrgUnit(response as api.OrgUnit);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).orgunits;
      var arg_customerId = 'foo';
      var arg_orgUnitPath = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/orgunits', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/orgunits"),
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
          queryMap["orgUnitPath"]!.first,
          unittest.equals(arg_orgUnitPath),
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
        var resp = convert.json.encode(buildOrgUnits());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customerId,
          orgUnitPath: arg_orgUnitPath, type: arg_type, $fields: arg_$fields);
      checkOrgUnits(response as api.OrgUnits);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).orgunits;
      var arg_request = buildOrgUnit();
      var arg_customerId = 'foo';
      var arg_orgUnitPath = 'foo';
      var arg_allowPlus = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.OrgUnit.fromJson(json as core.Map<core.String, core.dynamic>);
        checkOrgUnit(obj as api.OrgUnit);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/orgunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/orgunits/"),
        );
        pathOffset += 10;
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
          queryMap["allowPlus"]!.first,
          unittest.equals("$arg_allowPlus"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOrgUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_customerId, arg_orgUnitPath,
          allowPlus: arg_allowPlus, $fields: arg_$fields);
      checkOrgUnit(response as api.OrgUnit);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).orgunits;
      var arg_request = buildOrgUnit();
      var arg_customerId = 'foo';
      var arg_orgUnitPath = 'foo';
      var arg_allowPlus = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.OrgUnit.fromJson(json as core.Map<core.String, core.dynamic>);
        checkOrgUnit(obj as api.OrgUnit);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/orgunits/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/orgunits/"),
        );
        pathOffset += 10;
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
          queryMap["allowPlus"]!.first,
          unittest.equals("$arg_allowPlus"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOrgUnit());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_customerId, arg_orgUnitPath,
          allowPlus: arg_allowPlus, $fields: arg_$fields);
      checkOrgUnit(response as api.OrgUnit);
    });
  });

  unittest.group('resource-PrivilegesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).privileges;
      var arg_customer = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles/ALL/privileges', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/roles/ALL/privileges"),
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
        var resp = convert.json.encode(buildPrivileges());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer, $fields: arg_$fields);
      checkPrivileges(response as api.Privileges);
    });
  });

  unittest.group('resource-ResourcesBuildingsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.buildings;
      var arg_customer = 'foo';
      var arg_buildingId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/buildings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/buildings/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buildingId'),
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
      await res.delete(arg_customer, arg_buildingId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.buildings;
      var arg_customer = 'foo';
      var arg_buildingId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/buildings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/buildings/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buildingId'),
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
        var resp = convert.json.encode(buildBuilding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_customer, arg_buildingId, $fields: arg_$fields);
      checkBuilding(response as api.Building);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.buildings;
      var arg_request = buildBuilding();
      var arg_customer = 'foo';
      var arg_coordinatesSource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Building.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBuilding(obj as api.Building);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/buildings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/buildings"),
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
          queryMap["coordinatesSource"]!.first,
          unittest.equals(arg_coordinatesSource),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBuilding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_customer,
          coordinatesSource: arg_coordinatesSource, $fields: arg_$fields);
      checkBuilding(response as api.Building);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.buildings;
      var arg_customer = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/buildings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/buildings"),
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
        var resp = convert.json.encode(buildBuildings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkBuildings(response as api.Buildings);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.buildings;
      var arg_request = buildBuilding();
      var arg_customer = 'foo';
      var arg_buildingId = 'foo';
      var arg_coordinatesSource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Building.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBuilding(obj as api.Building);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/buildings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/buildings/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buildingId'),
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
          queryMap["coordinatesSource"]!.first,
          unittest.equals(arg_coordinatesSource),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBuilding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_customer, arg_buildingId,
          coordinatesSource: arg_coordinatesSource, $fields: arg_$fields);
      checkBuilding(response as api.Building);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.buildings;
      var arg_request = buildBuilding();
      var arg_customer = 'foo';
      var arg_buildingId = 'foo';
      var arg_coordinatesSource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Building.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBuilding(obj as api.Building);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/buildings/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/buildings/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buildingId'),
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
          queryMap["coordinatesSource"]!.first,
          unittest.equals(arg_coordinatesSource),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBuilding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_customer, arg_buildingId,
          coordinatesSource: arg_coordinatesSource, $fields: arg_$fields);
      checkBuilding(response as api.Building);
    });
  });

  unittest.group('resource-ResourcesCalendarsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.calendars;
      var arg_customer = 'foo';
      var arg_calendarResourceId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/calendars/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/calendars/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_calendarResourceId'),
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
      await res.delete(arg_customer, arg_calendarResourceId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.calendars;
      var arg_customer = 'foo';
      var arg_calendarResourceId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/calendars/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/calendars/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_calendarResourceId'),
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
        var resp = convert.json.encode(buildCalendarResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customer, arg_calendarResourceId,
          $fields: arg_$fields);
      checkCalendarResource(response as api.CalendarResource);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.calendars;
      var arg_request = buildCalendarResource();
      var arg_customer = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CalendarResource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCalendarResource(obj as api.CalendarResource);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/calendars', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/calendars"),
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
        var resp = convert.json.encode(buildCalendarResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customer, $fields: arg_$fields);
      checkCalendarResource(response as api.CalendarResource);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.calendars;
      var arg_customer = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/calendars', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/calendars"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCalendarResources());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          query: arg_query,
          $fields: arg_$fields);
      checkCalendarResources(response as api.CalendarResources);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.calendars;
      var arg_request = buildCalendarResource();
      var arg_customer = 'foo';
      var arg_calendarResourceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CalendarResource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCalendarResource(obj as api.CalendarResource);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/calendars/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/calendars/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_calendarResourceId'),
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
        var resp = convert.json.encode(buildCalendarResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_customer, arg_calendarResourceId,
          $fields: arg_$fields);
      checkCalendarResource(response as api.CalendarResource);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.calendars;
      var arg_request = buildCalendarResource();
      var arg_customer = 'foo';
      var arg_calendarResourceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CalendarResource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCalendarResource(obj as api.CalendarResource);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/calendars/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/resources/calendars/"),
        );
        pathOffset += 21;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_calendarResourceId'),
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
        var resp = convert.json.encode(buildCalendarResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_customer, arg_calendarResourceId,
          $fields: arg_$fields);
      checkCalendarResource(response as api.CalendarResource);
    });
  });

  unittest.group('resource-ResourcesFeaturesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_customer = 'foo';
      var arg_featureKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/features/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_featureKey'),
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
      await res.delete(arg_customer, arg_featureKey, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_customer = 'foo';
      var arg_featureKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/features/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_featureKey'),
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
        var resp = convert.json.encode(buildFeature());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_customer, arg_featureKey, $fields: arg_$fields);
      checkFeature(response as api.Feature);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_request = buildFeature();
      var arg_customer = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Feature.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFeature(obj as api.Feature);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/resources/features"),
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
        var resp = convert.json.encode(buildFeature());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customer, $fields: arg_$fields);
      checkFeature(response as api.Feature);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_customer = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/resources/features"),
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
        var resp = convert.json.encode(buildFeatures());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkFeatures(response as api.Features);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_request = buildFeature();
      var arg_customer = 'foo';
      var arg_featureKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Feature.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFeature(obj as api.Feature);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/features/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_featureKey'),
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
        var resp = convert.json.encode(buildFeature());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_customer, arg_featureKey,
          $fields: arg_$fields);
      checkFeature(response as api.Feature);
    });

    unittest.test('method--rename', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_request = buildFeatureRename();
      var arg_customer = 'foo';
      var arg_oldName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FeatureRename.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFeatureRename(obj as api.FeatureRename);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/features/"),
        );
        pathOffset += 20;
        index = path.indexOf('/rename', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_oldName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/rename"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.rename(arg_request, arg_customer, arg_oldName,
          $fields: arg_$fields);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).resources.features;
      var arg_request = buildFeature();
      var arg_customer = 'foo';
      var arg_featureKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Feature.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFeature(obj as api.Feature);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/resources/features/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/resources/features/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_featureKey'),
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
        var resp = convert.json.encode(buildFeature());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_customer, arg_featureKey,
          $fields: arg_$fields);
      checkFeature(response as api.Feature);
    });
  });

  unittest.group('resource-RoleAssignmentsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roleAssignments;
      var arg_customer = 'foo';
      var arg_roleAssignmentId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roleassignments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/roleassignments/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_roleAssignmentId'),
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
      await res.delete(arg_customer, arg_roleAssignmentId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roleAssignments;
      var arg_customer = 'foo';
      var arg_roleAssignmentId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roleassignments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/roleassignments/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_roleAssignmentId'),
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
        var resp = convert.json.encode(buildRoleAssignment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customer, arg_roleAssignmentId,
          $fields: arg_$fields);
      checkRoleAssignment(response as api.RoleAssignment);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roleAssignments;
      var arg_request = buildRoleAssignment();
      var arg_customer = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RoleAssignment.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRoleAssignment(obj as api.RoleAssignment);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roleassignments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/roleassignments"),
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
        var resp = convert.json.encode(buildRoleAssignment());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customer, $fields: arg_$fields);
      checkRoleAssignment(response as api.RoleAssignment);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roleAssignments;
      var arg_customer = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_roleId = 'foo';
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roleassignments', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/roleassignments"),
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["roleId"]!.first,
          unittest.equals(arg_roleId),
        );
        unittest.expect(
          queryMap["userKey"]!.first,
          unittest.equals(arg_userKey),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRoleAssignments());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          roleId: arg_roleId,
          userKey: arg_userKey,
          $fields: arg_$fields);
      checkRoleAssignments(response as api.RoleAssignments);
    });
  });

  unittest.group('resource-RolesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roles;
      var arg_customer = 'foo';
      var arg_roleId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/roles/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_roleId'),
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
      await res.delete(arg_customer, arg_roleId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roles;
      var arg_customer = 'foo';
      var arg_roleId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/roles/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_roleId'),
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_customer, arg_roleId, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roles;
      var arg_request = buildRole();
      var arg_customer = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Role.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRole(obj as api.Role);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/roles"),
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customer, $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roles;
      var arg_customer = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/roles"),
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
        var resp = convert.json.encode(buildRoles());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customer,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkRoles(response as api.Roles);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roles;
      var arg_request = buildRole();
      var arg_customer = 'foo';
      var arg_roleId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Role.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRole(obj as api.Role);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/roles/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_roleId'),
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_customer, arg_roleId,
          $fields: arg_$fields);
      checkRole(response as api.Role);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).roles;
      var arg_request = buildRole();
      var arg_customer = 'foo';
      var arg_roleId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Role.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRole(obj as api.Role);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/roles/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customer'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/roles/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_roleId'),
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
        var resp = convert.json.encode(buildRole());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_customer, arg_roleId,
          $fields: arg_$fields);
      checkRole(response as api.Role);
    });
  });

  unittest.group('resource-SchemasResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).schemas;
      var arg_customerId = 'foo';
      var arg_schemaKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/schemas/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/schemas/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_schemaKey'),
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
      await res.delete(arg_customerId, arg_schemaKey, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).schemas;
      var arg_customerId = 'foo';
      var arg_schemaKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/schemas/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/schemas/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_schemaKey'),
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
        var resp = convert.json.encode(buildSchema());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_customerId, arg_schemaKey, $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).schemas;
      var arg_request = buildSchema();
      var arg_customerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Schema.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSchema(obj as api.Schema);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/schemas', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/schemas"),
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
        var resp = convert.json.encode(buildSchema());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_customerId, $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).schemas;
      var arg_customerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/schemas', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/schemas"),
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
        var resp = convert.json.encode(buildSchemas());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_customerId, $fields: arg_$fields);
      checkSchemas(response as api.Schemas);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).schemas;
      var arg_request = buildSchema();
      var arg_customerId = 'foo';
      var arg_schemaKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Schema.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSchema(obj as api.Schema);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/schemas/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/schemas/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_schemaKey'),
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
        var resp = convert.json.encode(buildSchema());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_customerId, arg_schemaKey,
          $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).schemas;
      var arg_request = buildSchema();
      var arg_customerId = 'foo';
      var arg_schemaKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Schema.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSchema(obj as api.Schema);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("admin/directory/v1/customer/"),
        );
        pathOffset += 28;
        index = path.indexOf('/schemas/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/schemas/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_schemaKey'),
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
        var resp = convert.json.encode(buildSchema());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_customerId, arg_schemaKey,
          $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });
  });

  unittest.group('resource-TokensResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).tokens;
      var arg_userKey = 'foo';
      var arg_clientId = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_clientId'),
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
      await res.delete(arg_userKey, arg_clientId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).tokens;
      var arg_userKey = 'foo';
      var arg_clientId = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tokens/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_clientId'),
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
        var resp = convert.json.encode(buildToken());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_userKey, arg_clientId, $fields: arg_$fields);
      checkToken(response as api.Token);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).tokens;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/tokens', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tokens"),
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
        var resp = convert.json.encode(buildTokens());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userKey, $fields: arg_$fields);
      checkTokens(response as api.Tokens);
    });
  });

  unittest.group('resource-TwoStepVerificationResource', () {
    unittest.test('method--turnOff', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).twoStepVerification;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/twoStepVerification/turnOff', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 28),
          unittest.equals("/twoStepVerification/turnOff"),
        );
        pathOffset += 28;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
      await res.turnOff(arg_userKey, $fields: arg_$fields);
    });
  });

  unittest.group('resource-UsersResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
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
      await res.delete(arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_userKey = 'foo';
      var arg_customFieldMask = 'foo';
      var arg_projection = 'foo';
      var arg_viewType = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
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
          queryMap["customFieldMask"]!.first,
          unittest.equals(arg_customFieldMask),
        );
        unittest.expect(
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["viewType"]!.first,
          unittest.equals(arg_viewType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userKey,
          customFieldMask: arg_customFieldMask,
          projection: arg_projection,
          viewType: arg_viewType,
          $fields: arg_$fields);
      checkUser(response as api.User);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_request = buildUser();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.User.fromJson(json as core.Map<core.String, core.dynamic>);
        checkUser(obj as api.User);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("admin/directory/v1/users"),
        );
        pathOffset += 24;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkUser(response as api.User);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_customFieldMask = 'foo';
      var arg_customer = 'foo';
      var arg_domain = 'foo';
      var arg_event = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
      var arg_pageToken = 'foo';
      var arg_projection = 'foo';
      var arg_query = 'foo';
      var arg_showDeleted = 'foo';
      var arg_sortOrder = 'foo';
      var arg_viewType = 'foo';
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
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("admin/directory/v1/users"),
        );
        pathOffset += 24;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["customFieldMask"]!.first,
          unittest.equals(arg_customFieldMask),
        );
        unittest.expect(
          queryMap["customer"]!.first,
          unittest.equals(arg_customer),
        );
        unittest.expect(
          queryMap["domain"]!.first,
          unittest.equals(arg_domain),
        );
        unittest.expect(
          queryMap["event"]!.first,
          unittest.equals(arg_event),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["showDeleted"]!.first,
          unittest.equals(arg_showDeleted),
        );
        unittest.expect(
          queryMap["sortOrder"]!.first,
          unittest.equals(arg_sortOrder),
        );
        unittest.expect(
          queryMap["viewType"]!.first,
          unittest.equals(arg_viewType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUsers());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          customFieldMask: arg_customFieldMask,
          customer: arg_customer,
          domain: arg_domain,
          event: arg_event,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          projection: arg_projection,
          query: arg_query,
          showDeleted: arg_showDeleted,
          sortOrder: arg_sortOrder,
          viewType: arg_viewType,
          $fields: arg_$fields);
      checkUsers(response as api.Users);
    });

    unittest.test('method--makeAdmin', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_request = buildUserMakeAdmin();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserMakeAdmin.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserMakeAdmin(obj as api.UserMakeAdmin);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/makeAdmin', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/makeAdmin"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.makeAdmin(arg_request, arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_request = buildUser();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.User.fromJson(json as core.Map<core.String, core.dynamic>);
        checkUser(obj as api.User);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
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
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_userKey, $fields: arg_$fields);
      checkUser(response as api.User);
    });

    unittest.test('method--signOut', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/signOut', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/signOut"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.signOut(arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_request = buildUserUndelete();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UserUndelete.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUserUndelete(obj as api.UserUndelete);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/undelete', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/undelete"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.undelete(arg_request, arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_request = buildUser();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.User.fromJson(json as core.Map<core.String, core.dynamic>);
        checkUser(obj as api.User);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
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
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_userKey, $fields: arg_$fields);
      checkUser(response as api.User);
    });

    unittest.test('method--watch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users;
      var arg_request = buildChannel();
      var arg_customFieldMask = 'foo';
      var arg_customer = 'foo';
      var arg_domain = 'foo';
      var arg_event = 'foo';
      var arg_maxResults = 42;
      var arg_orderBy = 'foo';
      var arg_pageToken = 'foo';
      var arg_projection = 'foo';
      var arg_query = 'foo';
      var arg_showDeleted = 'foo';
      var arg_sortOrder = 'foo';
      var arg_viewType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Channel.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChannel(obj as api.Channel);

        var path = (req.url).path;
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
          unittest.equals("admin/directory/v1/users/watch"),
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
          queryMap["customFieldMask"]!.first,
          unittest.equals(arg_customFieldMask),
        );
        unittest.expect(
          queryMap["customer"]!.first,
          unittest.equals(arg_customer),
        );
        unittest.expect(
          queryMap["domain"]!.first,
          unittest.equals(arg_domain),
        );
        unittest.expect(
          queryMap["event"]!.first,
          unittest.equals(arg_event),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["showDeleted"]!.first,
          unittest.equals(arg_showDeleted),
        );
        unittest.expect(
          queryMap["sortOrder"]!.first,
          unittest.equals(arg_sortOrder),
        );
        unittest.expect(
          queryMap["viewType"]!.first,
          unittest.equals(arg_viewType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.watch(arg_request,
          customFieldMask: arg_customFieldMask,
          customer: arg_customer,
          domain: arg_domain,
          event: arg_event,
          maxResults: arg_maxResults,
          orderBy: arg_orderBy,
          pageToken: arg_pageToken,
          projection: arg_projection,
          query: arg_query,
          showDeleted: arg_showDeleted,
          sortOrder: arg_sortOrder,
          viewType: arg_viewType,
          $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });
  });

  unittest.group('resource-UsersAliasesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.aliases;
      var arg_userKey = 'foo';
      var arg_alias = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/aliases/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/aliases/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_alias'),
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
      await res.delete(arg_userKey, arg_alias, $fields: arg_$fields);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.aliases;
      var arg_request = buildAlias();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Alias.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAlias(obj as api.Alias);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/aliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/aliases"),
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
        var resp = convert.json.encode(buildAlias());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_userKey, $fields: arg_$fields);
      checkAlias(response as api.Alias);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.aliases;
      var arg_userKey = 'foo';
      var arg_event = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/aliases', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/aliases"),
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
          queryMap["event"]!.first,
          unittest.equals(arg_event),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAliases());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_userKey, event: arg_event, $fields: arg_$fields);
      checkAliases(response as api.Aliases);
    });

    unittest.test('method--watch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.aliases;
      var arg_request = buildChannel();
      var arg_userKey = 'foo';
      var arg_event = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Channel.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChannel(obj as api.Channel);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/aliases/watch', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/aliases/watch"),
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
          queryMap["event"]!.first,
          unittest.equals(arg_event),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.watch(arg_request, arg_userKey,
          event: arg_event, $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });
  });

  unittest.group('resource-UsersPhotosResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.photos;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/photos/thumbnail', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/photos/thumbnail"),
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
      await res.delete(arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.photos;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/photos/thumbnail', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/photos/thumbnail"),
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
        var resp = convert.json.encode(buildUserPhoto());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userKey, $fields: arg_$fields);
      checkUserPhoto(response as api.UserPhoto);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.photos;
      var arg_request = buildUserPhoto();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.UserPhoto.fromJson(json as core.Map<core.String, core.dynamic>);
        checkUserPhoto(obj as api.UserPhoto);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/photos/thumbnail', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/photos/thumbnail"),
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
        var resp = convert.json.encode(buildUserPhoto());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_userKey, $fields: arg_$fields);
      checkUserPhoto(response as api.UserPhoto);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).users.photos;
      var arg_request = buildUserPhoto();
      var arg_userKey = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.UserPhoto.fromJson(json as core.Map<core.String, core.dynamic>);
        checkUserPhoto(obj as api.UserPhoto);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/photos/thumbnail', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/photos/thumbnail"),
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
        var resp = convert.json.encode(buildUserPhoto());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_userKey, $fields: arg_$fields);
      checkUserPhoto(response as api.UserPhoto);
    });
  });

  unittest.group('resource-VerificationCodesResource', () {
    unittest.test('method--generate', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).verificationCodes;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/verificationCodes/generate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("/verificationCodes/generate"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.generate(arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--invalidate', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).verificationCodes;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/verificationCodes/invalidate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("/verificationCodes/invalidate"),
        );
        pathOffset += 29;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
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
      await res.invalidate(arg_userKey, $fields: arg_$fields);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DirectoryApi(mock).verificationCodes;
      var arg_userKey = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("admin/directory/v1/users/"),
        );
        pathOffset += 25;
        index = path.indexOf('/verificationCodes', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/verificationCodes"),
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
        var resp = convert.json.encode(buildVerificationCodes());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userKey, $fields: arg_$fields);
      checkVerificationCodes(response as api.VerificationCodes);
    });
  });
}
