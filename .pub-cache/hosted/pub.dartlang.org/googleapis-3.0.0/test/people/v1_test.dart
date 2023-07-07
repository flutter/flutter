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

import 'package:googleapis/people/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAddress = 0;
api.Address buildAddress() {
  var o = api.Address();
  buildCounterAddress++;
  if (buildCounterAddress < 3) {
    o.city = 'foo';
    o.country = 'foo';
    o.countryCode = 'foo';
    o.extendedAddress = 'foo';
    o.formattedType = 'foo';
    o.formattedValue = 'foo';
    o.metadata = buildFieldMetadata();
    o.poBox = 'foo';
    o.postalCode = 'foo';
    o.region = 'foo';
    o.streetAddress = 'foo';
    o.type = 'foo';
  }
  buildCounterAddress--;
  return o;
}

void checkAddress(api.Address o) {
  buildCounterAddress++;
  if (buildCounterAddress < 3) {
    unittest.expect(
      o.city!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.country!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.countryCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.extendedAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedValue!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.poBox!,
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
    unittest.expect(
      o.streetAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAddress--;
}

core.int buildCounterAgeRangeType = 0;
api.AgeRangeType buildAgeRangeType() {
  var o = api.AgeRangeType();
  buildCounterAgeRangeType++;
  if (buildCounterAgeRangeType < 3) {
    o.ageRange = 'foo';
    o.metadata = buildFieldMetadata();
  }
  buildCounterAgeRangeType--;
  return o;
}

void checkAgeRangeType(api.AgeRangeType o) {
  buildCounterAgeRangeType++;
  if (buildCounterAgeRangeType < 3) {
    unittest.expect(
      o.ageRange!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
  }
  buildCounterAgeRangeType--;
}

core.List<api.ContactToCreate> buildUnnamed5813() {
  var o = <api.ContactToCreate>[];
  o.add(buildContactToCreate());
  o.add(buildContactToCreate());
  return o;
}

void checkUnnamed5813(core.List<api.ContactToCreate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactToCreate(o[0] as api.ContactToCreate);
  checkContactToCreate(o[1] as api.ContactToCreate);
}

core.List<core.String> buildUnnamed5814() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5814(core.List<core.String> o) {
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

core.int buildCounterBatchCreateContactsRequest = 0;
api.BatchCreateContactsRequest buildBatchCreateContactsRequest() {
  var o = api.BatchCreateContactsRequest();
  buildCounterBatchCreateContactsRequest++;
  if (buildCounterBatchCreateContactsRequest < 3) {
    o.contacts = buildUnnamed5813();
    o.readMask = 'foo';
    o.sources = buildUnnamed5814();
  }
  buildCounterBatchCreateContactsRequest--;
  return o;
}

void checkBatchCreateContactsRequest(api.BatchCreateContactsRequest o) {
  buildCounterBatchCreateContactsRequest++;
  if (buildCounterBatchCreateContactsRequest < 3) {
    checkUnnamed5813(o.contacts!);
    unittest.expect(
      o.readMask!,
      unittest.equals('foo'),
    );
    checkUnnamed5814(o.sources!);
  }
  buildCounterBatchCreateContactsRequest--;
}

core.List<api.PersonResponse> buildUnnamed5815() {
  var o = <api.PersonResponse>[];
  o.add(buildPersonResponse());
  o.add(buildPersonResponse());
  return o;
}

void checkUnnamed5815(core.List<api.PersonResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPersonResponse(o[0] as api.PersonResponse);
  checkPersonResponse(o[1] as api.PersonResponse);
}

core.int buildCounterBatchCreateContactsResponse = 0;
api.BatchCreateContactsResponse buildBatchCreateContactsResponse() {
  var o = api.BatchCreateContactsResponse();
  buildCounterBatchCreateContactsResponse++;
  if (buildCounterBatchCreateContactsResponse < 3) {
    o.createdPeople = buildUnnamed5815();
  }
  buildCounterBatchCreateContactsResponse--;
  return o;
}

void checkBatchCreateContactsResponse(api.BatchCreateContactsResponse o) {
  buildCounterBatchCreateContactsResponse++;
  if (buildCounterBatchCreateContactsResponse < 3) {
    checkUnnamed5815(o.createdPeople!);
  }
  buildCounterBatchCreateContactsResponse--;
}

core.List<core.String> buildUnnamed5816() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5816(core.List<core.String> o) {
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

core.int buildCounterBatchDeleteContactsRequest = 0;
api.BatchDeleteContactsRequest buildBatchDeleteContactsRequest() {
  var o = api.BatchDeleteContactsRequest();
  buildCounterBatchDeleteContactsRequest++;
  if (buildCounterBatchDeleteContactsRequest < 3) {
    o.resourceNames = buildUnnamed5816();
  }
  buildCounterBatchDeleteContactsRequest--;
  return o;
}

void checkBatchDeleteContactsRequest(api.BatchDeleteContactsRequest o) {
  buildCounterBatchDeleteContactsRequest++;
  if (buildCounterBatchDeleteContactsRequest < 3) {
    checkUnnamed5816(o.resourceNames!);
  }
  buildCounterBatchDeleteContactsRequest--;
}

core.List<api.ContactGroupResponse> buildUnnamed5817() {
  var o = <api.ContactGroupResponse>[];
  o.add(buildContactGroupResponse());
  o.add(buildContactGroupResponse());
  return o;
}

void checkUnnamed5817(core.List<api.ContactGroupResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactGroupResponse(o[0] as api.ContactGroupResponse);
  checkContactGroupResponse(o[1] as api.ContactGroupResponse);
}

core.int buildCounterBatchGetContactGroupsResponse = 0;
api.BatchGetContactGroupsResponse buildBatchGetContactGroupsResponse() {
  var o = api.BatchGetContactGroupsResponse();
  buildCounterBatchGetContactGroupsResponse++;
  if (buildCounterBatchGetContactGroupsResponse < 3) {
    o.responses = buildUnnamed5817();
  }
  buildCounterBatchGetContactGroupsResponse--;
  return o;
}

void checkBatchGetContactGroupsResponse(api.BatchGetContactGroupsResponse o) {
  buildCounterBatchGetContactGroupsResponse++;
  if (buildCounterBatchGetContactGroupsResponse < 3) {
    checkUnnamed5817(o.responses!);
  }
  buildCounterBatchGetContactGroupsResponse--;
}

core.Map<core.String, api.Person> buildUnnamed5818() {
  var o = <core.String, api.Person>{};
  o['x'] = buildPerson();
  o['y'] = buildPerson();
  return o;
}

void checkUnnamed5818(core.Map<core.String, api.Person> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerson(o['x']! as api.Person);
  checkPerson(o['y']! as api.Person);
}

core.List<core.String> buildUnnamed5819() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5819(core.List<core.String> o) {
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

core.int buildCounterBatchUpdateContactsRequest = 0;
api.BatchUpdateContactsRequest buildBatchUpdateContactsRequest() {
  var o = api.BatchUpdateContactsRequest();
  buildCounterBatchUpdateContactsRequest++;
  if (buildCounterBatchUpdateContactsRequest < 3) {
    o.contacts = buildUnnamed5818();
    o.readMask = 'foo';
    o.sources = buildUnnamed5819();
    o.updateMask = 'foo';
  }
  buildCounterBatchUpdateContactsRequest--;
  return o;
}

void checkBatchUpdateContactsRequest(api.BatchUpdateContactsRequest o) {
  buildCounterBatchUpdateContactsRequest++;
  if (buildCounterBatchUpdateContactsRequest < 3) {
    checkUnnamed5818(o.contacts!);
    unittest.expect(
      o.readMask!,
      unittest.equals('foo'),
    );
    checkUnnamed5819(o.sources!);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterBatchUpdateContactsRequest--;
}

core.Map<core.String, api.PersonResponse> buildUnnamed5820() {
  var o = <core.String, api.PersonResponse>{};
  o['x'] = buildPersonResponse();
  o['y'] = buildPersonResponse();
  return o;
}

void checkUnnamed5820(core.Map<core.String, api.PersonResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPersonResponse(o['x']! as api.PersonResponse);
  checkPersonResponse(o['y']! as api.PersonResponse);
}

core.int buildCounterBatchUpdateContactsResponse = 0;
api.BatchUpdateContactsResponse buildBatchUpdateContactsResponse() {
  var o = api.BatchUpdateContactsResponse();
  buildCounterBatchUpdateContactsResponse++;
  if (buildCounterBatchUpdateContactsResponse < 3) {
    o.updateResult = buildUnnamed5820();
  }
  buildCounterBatchUpdateContactsResponse--;
  return o;
}

void checkBatchUpdateContactsResponse(api.BatchUpdateContactsResponse o) {
  buildCounterBatchUpdateContactsResponse++;
  if (buildCounterBatchUpdateContactsResponse < 3) {
    checkUnnamed5820(o.updateResult!);
  }
  buildCounterBatchUpdateContactsResponse--;
}

core.int buildCounterBiography = 0;
api.Biography buildBiography() {
  var o = api.Biography();
  buildCounterBiography++;
  if (buildCounterBiography < 3) {
    o.contentType = 'foo';
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterBiography--;
  return o;
}

void checkBiography(api.Biography o) {
  buildCounterBiography++;
  if (buildCounterBiography < 3) {
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterBiography--;
}

core.int buildCounterBirthday = 0;
api.Birthday buildBirthday() {
  var o = api.Birthday();
  buildCounterBirthday++;
  if (buildCounterBirthday < 3) {
    o.date = buildDate();
    o.metadata = buildFieldMetadata();
    o.text = 'foo';
  }
  buildCounterBirthday--;
  return o;
}

void checkBirthday(api.Birthday o) {
  buildCounterBirthday++;
  if (buildCounterBirthday < 3) {
    checkDate(o.date! as api.Date);
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterBirthday--;
}

core.int buildCounterBraggingRights = 0;
api.BraggingRights buildBraggingRights() {
  var o = api.BraggingRights();
  buildCounterBraggingRights++;
  if (buildCounterBraggingRights < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterBraggingRights--;
  return o;
}

void checkBraggingRights(api.BraggingRights o) {
  buildCounterBraggingRights++;
  if (buildCounterBraggingRights < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterBraggingRights--;
}

core.int buildCounterCalendarUrl = 0;
api.CalendarUrl buildCalendarUrl() {
  var o = api.CalendarUrl();
  buildCounterCalendarUrl++;
  if (buildCounterCalendarUrl < 3) {
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.url = 'foo';
  }
  buildCounterCalendarUrl--;
  return o;
}

void checkCalendarUrl(api.CalendarUrl o) {
  buildCounterCalendarUrl++;
  if (buildCounterCalendarUrl < 3) {
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterCalendarUrl--;
}

core.int buildCounterClientData = 0;
api.ClientData buildClientData() {
  var o = api.ClientData();
  buildCounterClientData++;
  if (buildCounterClientData < 3) {
    o.key = 'foo';
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterClientData--;
  return o;
}

void checkClientData(api.ClientData o) {
  buildCounterClientData++;
  if (buildCounterClientData < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterClientData--;
}

core.List<api.GroupClientData> buildUnnamed5821() {
  var o = <api.GroupClientData>[];
  o.add(buildGroupClientData());
  o.add(buildGroupClientData());
  return o;
}

void checkUnnamed5821(core.List<api.GroupClientData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGroupClientData(o[0] as api.GroupClientData);
  checkGroupClientData(o[1] as api.GroupClientData);
}

core.List<core.String> buildUnnamed5822() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5822(core.List<core.String> o) {
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

core.int buildCounterContactGroup = 0;
api.ContactGroup buildContactGroup() {
  var o = api.ContactGroup();
  buildCounterContactGroup++;
  if (buildCounterContactGroup < 3) {
    o.clientData = buildUnnamed5821();
    o.etag = 'foo';
    o.formattedName = 'foo';
    o.groupType = 'foo';
    o.memberCount = 42;
    o.memberResourceNames = buildUnnamed5822();
    o.metadata = buildContactGroupMetadata();
    o.name = 'foo';
    o.resourceName = 'foo';
  }
  buildCounterContactGroup--;
  return o;
}

void checkContactGroup(api.ContactGroup o) {
  buildCounterContactGroup++;
  if (buildCounterContactGroup < 3) {
    checkUnnamed5821(o.clientData!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.groupType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.memberCount!,
      unittest.equals(42),
    );
    checkUnnamed5822(o.memberResourceNames!);
    checkContactGroupMetadata(o.metadata! as api.ContactGroupMetadata);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterContactGroup--;
}

core.int buildCounterContactGroupMembership = 0;
api.ContactGroupMembership buildContactGroupMembership() {
  var o = api.ContactGroupMembership();
  buildCounterContactGroupMembership++;
  if (buildCounterContactGroupMembership < 3) {
    o.contactGroupId = 'foo';
    o.contactGroupResourceName = 'foo';
  }
  buildCounterContactGroupMembership--;
  return o;
}

void checkContactGroupMembership(api.ContactGroupMembership o) {
  buildCounterContactGroupMembership++;
  if (buildCounterContactGroupMembership < 3) {
    unittest.expect(
      o.contactGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contactGroupResourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterContactGroupMembership--;
}

core.int buildCounterContactGroupMetadata = 0;
api.ContactGroupMetadata buildContactGroupMetadata() {
  var o = api.ContactGroupMetadata();
  buildCounterContactGroupMetadata++;
  if (buildCounterContactGroupMetadata < 3) {
    o.deleted = true;
    o.updateTime = 'foo';
  }
  buildCounterContactGroupMetadata--;
  return o;
}

void checkContactGroupMetadata(api.ContactGroupMetadata o) {
  buildCounterContactGroupMetadata++;
  if (buildCounterContactGroupMetadata < 3) {
    unittest.expect(o.deleted!, unittest.isTrue);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterContactGroupMetadata--;
}

core.int buildCounterContactGroupResponse = 0;
api.ContactGroupResponse buildContactGroupResponse() {
  var o = api.ContactGroupResponse();
  buildCounterContactGroupResponse++;
  if (buildCounterContactGroupResponse < 3) {
    o.contactGroup = buildContactGroup();
    o.requestedResourceName = 'foo';
    o.status = buildStatus();
  }
  buildCounterContactGroupResponse--;
  return o;
}

void checkContactGroupResponse(api.ContactGroupResponse o) {
  buildCounterContactGroupResponse++;
  if (buildCounterContactGroupResponse < 3) {
    checkContactGroup(o.contactGroup! as api.ContactGroup);
    unittest.expect(
      o.requestedResourceName!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
  }
  buildCounterContactGroupResponse--;
}

core.int buildCounterContactToCreate = 0;
api.ContactToCreate buildContactToCreate() {
  var o = api.ContactToCreate();
  buildCounterContactToCreate++;
  if (buildCounterContactToCreate < 3) {
    o.contactPerson = buildPerson();
  }
  buildCounterContactToCreate--;
  return o;
}

void checkContactToCreate(api.ContactToCreate o) {
  buildCounterContactToCreate++;
  if (buildCounterContactToCreate < 3) {
    checkPerson(o.contactPerson! as api.Person);
  }
  buildCounterContactToCreate--;
}

core.List<core.String> buildUnnamed5823() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5823(core.List<core.String> o) {
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

core.int buildCounterCopyOtherContactToMyContactsGroupRequest = 0;
api.CopyOtherContactToMyContactsGroupRequest
    buildCopyOtherContactToMyContactsGroupRequest() {
  var o = api.CopyOtherContactToMyContactsGroupRequest();
  buildCounterCopyOtherContactToMyContactsGroupRequest++;
  if (buildCounterCopyOtherContactToMyContactsGroupRequest < 3) {
    o.copyMask = 'foo';
    o.readMask = 'foo';
    o.sources = buildUnnamed5823();
  }
  buildCounterCopyOtherContactToMyContactsGroupRequest--;
  return o;
}

void checkCopyOtherContactToMyContactsGroupRequest(
    api.CopyOtherContactToMyContactsGroupRequest o) {
  buildCounterCopyOtherContactToMyContactsGroupRequest++;
  if (buildCounterCopyOtherContactToMyContactsGroupRequest < 3) {
    unittest.expect(
      o.copyMask!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readMask!,
      unittest.equals('foo'),
    );
    checkUnnamed5823(o.sources!);
  }
  buildCounterCopyOtherContactToMyContactsGroupRequest--;
}

core.int buildCounterCoverPhoto = 0;
api.CoverPhoto buildCoverPhoto() {
  var o = api.CoverPhoto();
  buildCounterCoverPhoto++;
  if (buildCounterCoverPhoto < 3) {
    o.default_ = true;
    o.metadata = buildFieldMetadata();
    o.url = 'foo';
  }
  buildCounterCoverPhoto--;
  return o;
}

void checkCoverPhoto(api.CoverPhoto o) {
  buildCounterCoverPhoto++;
  if (buildCounterCoverPhoto < 3) {
    unittest.expect(o.default_!, unittest.isTrue);
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterCoverPhoto--;
}

core.int buildCounterCreateContactGroupRequest = 0;
api.CreateContactGroupRequest buildCreateContactGroupRequest() {
  var o = api.CreateContactGroupRequest();
  buildCounterCreateContactGroupRequest++;
  if (buildCounterCreateContactGroupRequest < 3) {
    o.contactGroup = buildContactGroup();
    o.readGroupFields = 'foo';
  }
  buildCounterCreateContactGroupRequest--;
  return o;
}

void checkCreateContactGroupRequest(api.CreateContactGroupRequest o) {
  buildCounterCreateContactGroupRequest++;
  if (buildCounterCreateContactGroupRequest < 3) {
    checkContactGroup(o.contactGroup! as api.ContactGroup);
    unittest.expect(
      o.readGroupFields!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateContactGroupRequest--;
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

core.int buildCounterDeleteContactPhotoResponse = 0;
api.DeleteContactPhotoResponse buildDeleteContactPhotoResponse() {
  var o = api.DeleteContactPhotoResponse();
  buildCounterDeleteContactPhotoResponse++;
  if (buildCounterDeleteContactPhotoResponse < 3) {
    o.person = buildPerson();
  }
  buildCounterDeleteContactPhotoResponse--;
  return o;
}

void checkDeleteContactPhotoResponse(api.DeleteContactPhotoResponse o) {
  buildCounterDeleteContactPhotoResponse++;
  if (buildCounterDeleteContactPhotoResponse < 3) {
    checkPerson(o.person! as api.Person);
  }
  buildCounterDeleteContactPhotoResponse--;
}

core.int buildCounterDomainMembership = 0;
api.DomainMembership buildDomainMembership() {
  var o = api.DomainMembership();
  buildCounterDomainMembership++;
  if (buildCounterDomainMembership < 3) {
    o.inViewerDomain = true;
  }
  buildCounterDomainMembership--;
  return o;
}

void checkDomainMembership(api.DomainMembership o) {
  buildCounterDomainMembership++;
  if (buildCounterDomainMembership < 3) {
    unittest.expect(o.inViewerDomain!, unittest.isTrue);
  }
  buildCounterDomainMembership--;
}

core.int buildCounterEmailAddress = 0;
api.EmailAddress buildEmailAddress() {
  var o = api.EmailAddress();
  buildCounterEmailAddress++;
  if (buildCounterEmailAddress < 3) {
    o.displayName = 'foo';
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterEmailAddress--;
  return o;
}

void checkEmailAddress(api.EmailAddress o) {
  buildCounterEmailAddress++;
  if (buildCounterEmailAddress < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterEmailAddress--;
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

core.int buildCounterEvent = 0;
api.Event buildEvent() {
  var o = api.Event();
  buildCounterEvent++;
  if (buildCounterEvent < 3) {
    o.date = buildDate();
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
  }
  buildCounterEvent--;
  return o;
}

void checkEvent(api.Event o) {
  buildCounterEvent++;
  if (buildCounterEvent < 3) {
    checkDate(o.date! as api.Date);
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterEvent--;
}

core.int buildCounterExternalId = 0;
api.ExternalId buildExternalId() {
  var o = api.ExternalId();
  buildCounterExternalId++;
  if (buildCounterExternalId < 3) {
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterExternalId--;
  return o;
}

void checkExternalId(api.ExternalId o) {
  buildCounterExternalId++;
  if (buildCounterExternalId < 3) {
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterExternalId--;
}

core.int buildCounterFieldMetadata = 0;
api.FieldMetadata buildFieldMetadata() {
  var o = api.FieldMetadata();
  buildCounterFieldMetadata++;
  if (buildCounterFieldMetadata < 3) {
    o.primary = true;
    o.source = buildSource();
    o.verified = true;
  }
  buildCounterFieldMetadata--;
  return o;
}

void checkFieldMetadata(api.FieldMetadata o) {
  buildCounterFieldMetadata++;
  if (buildCounterFieldMetadata < 3) {
    unittest.expect(o.primary!, unittest.isTrue);
    checkSource(o.source! as api.Source);
    unittest.expect(o.verified!, unittest.isTrue);
  }
  buildCounterFieldMetadata--;
}

core.int buildCounterFileAs = 0;
api.FileAs buildFileAs() {
  var o = api.FileAs();
  buildCounterFileAs++;
  if (buildCounterFileAs < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterFileAs--;
  return o;
}

void checkFileAs(api.FileAs o) {
  buildCounterFileAs++;
  if (buildCounterFileAs < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterFileAs--;
}

core.int buildCounterGender = 0;
api.Gender buildGender() {
  var o = api.Gender();
  buildCounterGender++;
  if (buildCounterGender < 3) {
    o.addressMeAs = 'foo';
    o.formattedValue = 'foo';
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterGender--;
  return o;
}

void checkGender(api.Gender o) {
  buildCounterGender++;
  if (buildCounterGender < 3) {
    unittest.expect(
      o.addressMeAs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedValue!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGender--;
}

core.List<api.PersonResponse> buildUnnamed5824() {
  var o = <api.PersonResponse>[];
  o.add(buildPersonResponse());
  o.add(buildPersonResponse());
  return o;
}

void checkUnnamed5824(core.List<api.PersonResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPersonResponse(o[0] as api.PersonResponse);
  checkPersonResponse(o[1] as api.PersonResponse);
}

core.int buildCounterGetPeopleResponse = 0;
api.GetPeopleResponse buildGetPeopleResponse() {
  var o = api.GetPeopleResponse();
  buildCounterGetPeopleResponse++;
  if (buildCounterGetPeopleResponse < 3) {
    o.responses = buildUnnamed5824();
  }
  buildCounterGetPeopleResponse--;
  return o;
}

void checkGetPeopleResponse(api.GetPeopleResponse o) {
  buildCounterGetPeopleResponse++;
  if (buildCounterGetPeopleResponse < 3) {
    checkUnnamed5824(o.responses!);
  }
  buildCounterGetPeopleResponse--;
}

core.int buildCounterGroupClientData = 0;
api.GroupClientData buildGroupClientData() {
  var o = api.GroupClientData();
  buildCounterGroupClientData++;
  if (buildCounterGroupClientData < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterGroupClientData--;
  return o;
}

void checkGroupClientData(api.GroupClientData o) {
  buildCounterGroupClientData++;
  if (buildCounterGroupClientData < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGroupClientData--;
}

core.int buildCounterImClient = 0;
api.ImClient buildImClient() {
  var o = api.ImClient();
  buildCounterImClient++;
  if (buildCounterImClient < 3) {
    o.formattedProtocol = 'foo';
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.protocol = 'foo';
    o.type = 'foo';
    o.username = 'foo';
  }
  buildCounterImClient--;
  return o;
}

void checkImClient(api.ImClient o) {
  buildCounterImClient++;
  if (buildCounterImClient < 3) {
    unittest.expect(
      o.formattedProtocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.protocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterImClient--;
}

core.int buildCounterInterest = 0;
api.Interest buildInterest() {
  var o = api.Interest();
  buildCounterInterest++;
  if (buildCounterInterest < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterInterest--;
  return o;
}

void checkInterest(api.Interest o) {
  buildCounterInterest++;
  if (buildCounterInterest < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterInterest--;
}

core.List<api.Person> buildUnnamed5825() {
  var o = <api.Person>[];
  o.add(buildPerson());
  o.add(buildPerson());
  return o;
}

void checkUnnamed5825(core.List<api.Person> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerson(o[0] as api.Person);
  checkPerson(o[1] as api.Person);
}

core.int buildCounterListConnectionsResponse = 0;
api.ListConnectionsResponse buildListConnectionsResponse() {
  var o = api.ListConnectionsResponse();
  buildCounterListConnectionsResponse++;
  if (buildCounterListConnectionsResponse < 3) {
    o.connections = buildUnnamed5825();
    o.nextPageToken = 'foo';
    o.nextSyncToken = 'foo';
    o.totalItems = 42;
    o.totalPeople = 42;
  }
  buildCounterListConnectionsResponse--;
  return o;
}

void checkListConnectionsResponse(api.ListConnectionsResponse o) {
  buildCounterListConnectionsResponse++;
  if (buildCounterListConnectionsResponse < 3) {
    checkUnnamed5825(o.connections!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextSyncToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalItems!,
      unittest.equals(42),
    );
    unittest.expect(
      o.totalPeople!,
      unittest.equals(42),
    );
  }
  buildCounterListConnectionsResponse--;
}

core.List<api.ContactGroup> buildUnnamed5826() {
  var o = <api.ContactGroup>[];
  o.add(buildContactGroup());
  o.add(buildContactGroup());
  return o;
}

void checkUnnamed5826(core.List<api.ContactGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactGroup(o[0] as api.ContactGroup);
  checkContactGroup(o[1] as api.ContactGroup);
}

core.int buildCounterListContactGroupsResponse = 0;
api.ListContactGroupsResponse buildListContactGroupsResponse() {
  var o = api.ListContactGroupsResponse();
  buildCounterListContactGroupsResponse++;
  if (buildCounterListContactGroupsResponse < 3) {
    o.contactGroups = buildUnnamed5826();
    o.nextPageToken = 'foo';
    o.nextSyncToken = 'foo';
    o.totalItems = 42;
  }
  buildCounterListContactGroupsResponse--;
  return o;
}

void checkListContactGroupsResponse(api.ListContactGroupsResponse o) {
  buildCounterListContactGroupsResponse++;
  if (buildCounterListContactGroupsResponse < 3) {
    checkUnnamed5826(o.contactGroups!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextSyncToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalItems!,
      unittest.equals(42),
    );
  }
  buildCounterListContactGroupsResponse--;
}

core.List<api.Person> buildUnnamed5827() {
  var o = <api.Person>[];
  o.add(buildPerson());
  o.add(buildPerson());
  return o;
}

void checkUnnamed5827(core.List<api.Person> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerson(o[0] as api.Person);
  checkPerson(o[1] as api.Person);
}

core.int buildCounterListDirectoryPeopleResponse = 0;
api.ListDirectoryPeopleResponse buildListDirectoryPeopleResponse() {
  var o = api.ListDirectoryPeopleResponse();
  buildCounterListDirectoryPeopleResponse++;
  if (buildCounterListDirectoryPeopleResponse < 3) {
    o.nextPageToken = 'foo';
    o.nextSyncToken = 'foo';
    o.people = buildUnnamed5827();
  }
  buildCounterListDirectoryPeopleResponse--;
  return o;
}

void checkListDirectoryPeopleResponse(api.ListDirectoryPeopleResponse o) {
  buildCounterListDirectoryPeopleResponse++;
  if (buildCounterListDirectoryPeopleResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextSyncToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5827(o.people!);
  }
  buildCounterListDirectoryPeopleResponse--;
}

core.List<api.Person> buildUnnamed5828() {
  var o = <api.Person>[];
  o.add(buildPerson());
  o.add(buildPerson());
  return o;
}

void checkUnnamed5828(core.List<api.Person> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerson(o[0] as api.Person);
  checkPerson(o[1] as api.Person);
}

core.int buildCounterListOtherContactsResponse = 0;
api.ListOtherContactsResponse buildListOtherContactsResponse() {
  var o = api.ListOtherContactsResponse();
  buildCounterListOtherContactsResponse++;
  if (buildCounterListOtherContactsResponse < 3) {
    o.nextPageToken = 'foo';
    o.nextSyncToken = 'foo';
    o.otherContacts = buildUnnamed5828();
    o.totalSize = 42;
  }
  buildCounterListOtherContactsResponse--;
  return o;
}

void checkListOtherContactsResponse(api.ListOtherContactsResponse o) {
  buildCounterListOtherContactsResponse++;
  if (buildCounterListOtherContactsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextSyncToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5828(o.otherContacts!);
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListOtherContactsResponse--;
}

core.int buildCounterLocale = 0;
api.Locale buildLocale() {
  var o = api.Locale();
  buildCounterLocale++;
  if (buildCounterLocale < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterLocale--;
  return o;
}

void checkLocale(api.Locale o) {
  buildCounterLocale++;
  if (buildCounterLocale < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocale--;
}

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.buildingId = 'foo';
    o.current = true;
    o.deskCode = 'foo';
    o.floor = 'foo';
    o.floorSection = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    unittest.expect(
      o.buildingId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.current!, unittest.isTrue);
    unittest.expect(
      o.deskCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floorSection!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.int buildCounterMembership = 0;
api.Membership buildMembership() {
  var o = api.Membership();
  buildCounterMembership++;
  if (buildCounterMembership < 3) {
    o.contactGroupMembership = buildContactGroupMembership();
    o.domainMembership = buildDomainMembership();
    o.metadata = buildFieldMetadata();
  }
  buildCounterMembership--;
  return o;
}

void checkMembership(api.Membership o) {
  buildCounterMembership++;
  if (buildCounterMembership < 3) {
    checkContactGroupMembership(
        o.contactGroupMembership! as api.ContactGroupMembership);
    checkDomainMembership(o.domainMembership! as api.DomainMembership);
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
  }
  buildCounterMembership--;
}

core.int buildCounterMiscKeyword = 0;
api.MiscKeyword buildMiscKeyword() {
  var o = api.MiscKeyword();
  buildCounterMiscKeyword++;
  if (buildCounterMiscKeyword < 3) {
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterMiscKeyword--;
  return o;
}

void checkMiscKeyword(api.MiscKeyword o) {
  buildCounterMiscKeyword++;
  if (buildCounterMiscKeyword < 3) {
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterMiscKeyword--;
}

core.List<core.String> buildUnnamed5829() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5829(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5830() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5830(core.List<core.String> o) {
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

core.int buildCounterModifyContactGroupMembersRequest = 0;
api.ModifyContactGroupMembersRequest buildModifyContactGroupMembersRequest() {
  var o = api.ModifyContactGroupMembersRequest();
  buildCounterModifyContactGroupMembersRequest++;
  if (buildCounterModifyContactGroupMembersRequest < 3) {
    o.resourceNamesToAdd = buildUnnamed5829();
    o.resourceNamesToRemove = buildUnnamed5830();
  }
  buildCounterModifyContactGroupMembersRequest--;
  return o;
}

void checkModifyContactGroupMembersRequest(
    api.ModifyContactGroupMembersRequest o) {
  buildCounterModifyContactGroupMembersRequest++;
  if (buildCounterModifyContactGroupMembersRequest < 3) {
    checkUnnamed5829(o.resourceNamesToAdd!);
    checkUnnamed5830(o.resourceNamesToRemove!);
  }
  buildCounterModifyContactGroupMembersRequest--;
}

core.List<core.String> buildUnnamed5831() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5831(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5832() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5832(core.List<core.String> o) {
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

core.int buildCounterModifyContactGroupMembersResponse = 0;
api.ModifyContactGroupMembersResponse buildModifyContactGroupMembersResponse() {
  var o = api.ModifyContactGroupMembersResponse();
  buildCounterModifyContactGroupMembersResponse++;
  if (buildCounterModifyContactGroupMembersResponse < 3) {
    o.canNotRemoveLastContactGroupResourceNames = buildUnnamed5831();
    o.notFoundResourceNames = buildUnnamed5832();
  }
  buildCounterModifyContactGroupMembersResponse--;
  return o;
}

void checkModifyContactGroupMembersResponse(
    api.ModifyContactGroupMembersResponse o) {
  buildCounterModifyContactGroupMembersResponse++;
  if (buildCounterModifyContactGroupMembersResponse < 3) {
    checkUnnamed5831(o.canNotRemoveLastContactGroupResourceNames!);
    checkUnnamed5832(o.notFoundResourceNames!);
  }
  buildCounterModifyContactGroupMembersResponse--;
}

core.int buildCounterName = 0;
api.Name buildName() {
  var o = api.Name();
  buildCounterName++;
  if (buildCounterName < 3) {
    o.displayName = 'foo';
    o.displayNameLastFirst = 'foo';
    o.familyName = 'foo';
    o.givenName = 'foo';
    o.honorificPrefix = 'foo';
    o.honorificSuffix = 'foo';
    o.metadata = buildFieldMetadata();
    o.middleName = 'foo';
    o.phoneticFamilyName = 'foo';
    o.phoneticFullName = 'foo';
    o.phoneticGivenName = 'foo';
    o.phoneticHonorificPrefix = 'foo';
    o.phoneticHonorificSuffix = 'foo';
    o.phoneticMiddleName = 'foo';
    o.unstructuredName = 'foo';
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
    unittest.expect(
      o.displayNameLastFirst!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.familyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.givenName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.honorificPrefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.honorificSuffix!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.middleName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticFamilyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticFullName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticGivenName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticHonorificPrefix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticHonorificSuffix!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticMiddleName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.unstructuredName!,
      unittest.equals('foo'),
    );
  }
  buildCounterName--;
}

core.int buildCounterNickname = 0;
api.Nickname buildNickname() {
  var o = api.Nickname();
  buildCounterNickname++;
  if (buildCounterNickname < 3) {
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterNickname--;
  return o;
}

void checkNickname(api.Nickname o) {
  buildCounterNickname++;
  if (buildCounterNickname < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterNickname--;
}

core.int buildCounterOccupation = 0;
api.Occupation buildOccupation() {
  var o = api.Occupation();
  buildCounterOccupation++;
  if (buildCounterOccupation < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterOccupation--;
  return o;
}

void checkOccupation(api.Occupation o) {
  buildCounterOccupation++;
  if (buildCounterOccupation < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterOccupation--;
}

core.int buildCounterOrganization = 0;
api.Organization buildOrganization() {
  var o = api.Organization();
  buildCounterOrganization++;
  if (buildCounterOrganization < 3) {
    o.current = true;
    o.department = 'foo';
    o.domain = 'foo';
    o.endDate = buildDate();
    o.formattedType = 'foo';
    o.jobDescription = 'foo';
    o.location = 'foo';
    o.metadata = buildFieldMetadata();
    o.name = 'foo';
    o.phoneticName = 'foo';
    o.startDate = buildDate();
    o.symbol = 'foo';
    o.title = 'foo';
    o.type = 'foo';
  }
  buildCounterOrganization--;
  return o;
}

void checkOrganization(api.Organization o) {
  buildCounterOrganization++;
  if (buildCounterOrganization < 3) {
    unittest.expect(o.current!, unittest.isTrue);
    unittest.expect(
      o.department!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    checkDate(o.endDate! as api.Date);
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneticName!,
      unittest.equals('foo'),
    );
    checkDate(o.startDate! as api.Date);
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
  buildCounterOrganization--;
}

core.List<api.Address> buildUnnamed5833() {
  var o = <api.Address>[];
  o.add(buildAddress());
  o.add(buildAddress());
  return o;
}

void checkUnnamed5833(core.List<api.Address> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAddress(o[0] as api.Address);
  checkAddress(o[1] as api.Address);
}

core.List<api.AgeRangeType> buildUnnamed5834() {
  var o = <api.AgeRangeType>[];
  o.add(buildAgeRangeType());
  o.add(buildAgeRangeType());
  return o;
}

void checkUnnamed5834(core.List<api.AgeRangeType> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAgeRangeType(o[0] as api.AgeRangeType);
  checkAgeRangeType(o[1] as api.AgeRangeType);
}

core.List<api.Biography> buildUnnamed5835() {
  var o = <api.Biography>[];
  o.add(buildBiography());
  o.add(buildBiography());
  return o;
}

void checkUnnamed5835(core.List<api.Biography> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBiography(o[0] as api.Biography);
  checkBiography(o[1] as api.Biography);
}

core.List<api.Birthday> buildUnnamed5836() {
  var o = <api.Birthday>[];
  o.add(buildBirthday());
  o.add(buildBirthday());
  return o;
}

void checkUnnamed5836(core.List<api.Birthday> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBirthday(o[0] as api.Birthday);
  checkBirthday(o[1] as api.Birthday);
}

core.List<api.BraggingRights> buildUnnamed5837() {
  var o = <api.BraggingRights>[];
  o.add(buildBraggingRights());
  o.add(buildBraggingRights());
  return o;
}

void checkUnnamed5837(core.List<api.BraggingRights> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBraggingRights(o[0] as api.BraggingRights);
  checkBraggingRights(o[1] as api.BraggingRights);
}

core.List<api.CalendarUrl> buildUnnamed5838() {
  var o = <api.CalendarUrl>[];
  o.add(buildCalendarUrl());
  o.add(buildCalendarUrl());
  return o;
}

void checkUnnamed5838(core.List<api.CalendarUrl> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCalendarUrl(o[0] as api.CalendarUrl);
  checkCalendarUrl(o[1] as api.CalendarUrl);
}

core.List<api.ClientData> buildUnnamed5839() {
  var o = <api.ClientData>[];
  o.add(buildClientData());
  o.add(buildClientData());
  return o;
}

void checkUnnamed5839(core.List<api.ClientData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClientData(o[0] as api.ClientData);
  checkClientData(o[1] as api.ClientData);
}

core.List<api.CoverPhoto> buildUnnamed5840() {
  var o = <api.CoverPhoto>[];
  o.add(buildCoverPhoto());
  o.add(buildCoverPhoto());
  return o;
}

void checkUnnamed5840(core.List<api.CoverPhoto> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCoverPhoto(o[0] as api.CoverPhoto);
  checkCoverPhoto(o[1] as api.CoverPhoto);
}

core.List<api.EmailAddress> buildUnnamed5841() {
  var o = <api.EmailAddress>[];
  o.add(buildEmailAddress());
  o.add(buildEmailAddress());
  return o;
}

void checkUnnamed5841(core.List<api.EmailAddress> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEmailAddress(o[0] as api.EmailAddress);
  checkEmailAddress(o[1] as api.EmailAddress);
}

core.List<api.Event> buildUnnamed5842() {
  var o = <api.Event>[];
  o.add(buildEvent());
  o.add(buildEvent());
  return o;
}

void checkUnnamed5842(core.List<api.Event> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEvent(o[0] as api.Event);
  checkEvent(o[1] as api.Event);
}

core.List<api.ExternalId> buildUnnamed5843() {
  var o = <api.ExternalId>[];
  o.add(buildExternalId());
  o.add(buildExternalId());
  return o;
}

void checkUnnamed5843(core.List<api.ExternalId> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExternalId(o[0] as api.ExternalId);
  checkExternalId(o[1] as api.ExternalId);
}

core.List<api.FileAs> buildUnnamed5844() {
  var o = <api.FileAs>[];
  o.add(buildFileAs());
  o.add(buildFileAs());
  return o;
}

void checkUnnamed5844(core.List<api.FileAs> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFileAs(o[0] as api.FileAs);
  checkFileAs(o[1] as api.FileAs);
}

core.List<api.Gender> buildUnnamed5845() {
  var o = <api.Gender>[];
  o.add(buildGender());
  o.add(buildGender());
  return o;
}

void checkUnnamed5845(core.List<api.Gender> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGender(o[0] as api.Gender);
  checkGender(o[1] as api.Gender);
}

core.List<api.ImClient> buildUnnamed5846() {
  var o = <api.ImClient>[];
  o.add(buildImClient());
  o.add(buildImClient());
  return o;
}

void checkUnnamed5846(core.List<api.ImClient> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImClient(o[0] as api.ImClient);
  checkImClient(o[1] as api.ImClient);
}

core.List<api.Interest> buildUnnamed5847() {
  var o = <api.Interest>[];
  o.add(buildInterest());
  o.add(buildInterest());
  return o;
}

void checkUnnamed5847(core.List<api.Interest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInterest(o[0] as api.Interest);
  checkInterest(o[1] as api.Interest);
}

core.List<api.Locale> buildUnnamed5848() {
  var o = <api.Locale>[];
  o.add(buildLocale());
  o.add(buildLocale());
  return o;
}

void checkUnnamed5848(core.List<api.Locale> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocale(o[0] as api.Locale);
  checkLocale(o[1] as api.Locale);
}

core.List<api.Location> buildUnnamed5849() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed5849(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.List<api.Membership> buildUnnamed5850() {
  var o = <api.Membership>[];
  o.add(buildMembership());
  o.add(buildMembership());
  return o;
}

void checkUnnamed5850(core.List<api.Membership> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMembership(o[0] as api.Membership);
  checkMembership(o[1] as api.Membership);
}

core.List<api.MiscKeyword> buildUnnamed5851() {
  var o = <api.MiscKeyword>[];
  o.add(buildMiscKeyword());
  o.add(buildMiscKeyword());
  return o;
}

void checkUnnamed5851(core.List<api.MiscKeyword> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMiscKeyword(o[0] as api.MiscKeyword);
  checkMiscKeyword(o[1] as api.MiscKeyword);
}

core.List<api.Name> buildUnnamed5852() {
  var o = <api.Name>[];
  o.add(buildName());
  o.add(buildName());
  return o;
}

void checkUnnamed5852(core.List<api.Name> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkName(o[0] as api.Name);
  checkName(o[1] as api.Name);
}

core.List<api.Nickname> buildUnnamed5853() {
  var o = <api.Nickname>[];
  o.add(buildNickname());
  o.add(buildNickname());
  return o;
}

void checkUnnamed5853(core.List<api.Nickname> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNickname(o[0] as api.Nickname);
  checkNickname(o[1] as api.Nickname);
}

core.List<api.Occupation> buildUnnamed5854() {
  var o = <api.Occupation>[];
  o.add(buildOccupation());
  o.add(buildOccupation());
  return o;
}

void checkUnnamed5854(core.List<api.Occupation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOccupation(o[0] as api.Occupation);
  checkOccupation(o[1] as api.Occupation);
}

core.List<api.Organization> buildUnnamed5855() {
  var o = <api.Organization>[];
  o.add(buildOrganization());
  o.add(buildOrganization());
  return o;
}

void checkUnnamed5855(core.List<api.Organization> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOrganization(o[0] as api.Organization);
  checkOrganization(o[1] as api.Organization);
}

core.List<api.PhoneNumber> buildUnnamed5856() {
  var o = <api.PhoneNumber>[];
  o.add(buildPhoneNumber());
  o.add(buildPhoneNumber());
  return o;
}

void checkUnnamed5856(core.List<api.PhoneNumber> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPhoneNumber(o[0] as api.PhoneNumber);
  checkPhoneNumber(o[1] as api.PhoneNumber);
}

core.List<api.Photo> buildUnnamed5857() {
  var o = <api.Photo>[];
  o.add(buildPhoto());
  o.add(buildPhoto());
  return o;
}

void checkUnnamed5857(core.List<api.Photo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPhoto(o[0] as api.Photo);
  checkPhoto(o[1] as api.Photo);
}

core.List<api.Relation> buildUnnamed5858() {
  var o = <api.Relation>[];
  o.add(buildRelation());
  o.add(buildRelation());
  return o;
}

void checkUnnamed5858(core.List<api.Relation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRelation(o[0] as api.Relation);
  checkRelation(o[1] as api.Relation);
}

core.List<api.RelationshipInterest> buildUnnamed5859() {
  var o = <api.RelationshipInterest>[];
  o.add(buildRelationshipInterest());
  o.add(buildRelationshipInterest());
  return o;
}

void checkUnnamed5859(core.List<api.RelationshipInterest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRelationshipInterest(o[0] as api.RelationshipInterest);
  checkRelationshipInterest(o[1] as api.RelationshipInterest);
}

core.List<api.RelationshipStatus> buildUnnamed5860() {
  var o = <api.RelationshipStatus>[];
  o.add(buildRelationshipStatus());
  o.add(buildRelationshipStatus());
  return o;
}

void checkUnnamed5860(core.List<api.RelationshipStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRelationshipStatus(o[0] as api.RelationshipStatus);
  checkRelationshipStatus(o[1] as api.RelationshipStatus);
}

core.List<api.Residence> buildUnnamed5861() {
  var o = <api.Residence>[];
  o.add(buildResidence());
  o.add(buildResidence());
  return o;
}

void checkUnnamed5861(core.List<api.Residence> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkResidence(o[0] as api.Residence);
  checkResidence(o[1] as api.Residence);
}

core.List<api.SipAddress> buildUnnamed5862() {
  var o = <api.SipAddress>[];
  o.add(buildSipAddress());
  o.add(buildSipAddress());
  return o;
}

void checkUnnamed5862(core.List<api.SipAddress> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSipAddress(o[0] as api.SipAddress);
  checkSipAddress(o[1] as api.SipAddress);
}

core.List<api.Skill> buildUnnamed5863() {
  var o = <api.Skill>[];
  o.add(buildSkill());
  o.add(buildSkill());
  return o;
}

void checkUnnamed5863(core.List<api.Skill> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSkill(o[0] as api.Skill);
  checkSkill(o[1] as api.Skill);
}

core.List<api.Tagline> buildUnnamed5864() {
  var o = <api.Tagline>[];
  o.add(buildTagline());
  o.add(buildTagline());
  return o;
}

void checkUnnamed5864(core.List<api.Tagline> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTagline(o[0] as api.Tagline);
  checkTagline(o[1] as api.Tagline);
}

core.List<api.Url> buildUnnamed5865() {
  var o = <api.Url>[];
  o.add(buildUrl());
  o.add(buildUrl());
  return o;
}

void checkUnnamed5865(core.List<api.Url> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUrl(o[0] as api.Url);
  checkUrl(o[1] as api.Url);
}

core.List<api.UserDefined> buildUnnamed5866() {
  var o = <api.UserDefined>[];
  o.add(buildUserDefined());
  o.add(buildUserDefined());
  return o;
}

void checkUnnamed5866(core.List<api.UserDefined> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserDefined(o[0] as api.UserDefined);
  checkUserDefined(o[1] as api.UserDefined);
}

core.int buildCounterPerson = 0;
api.Person buildPerson() {
  var o = api.Person();
  buildCounterPerson++;
  if (buildCounterPerson < 3) {
    o.addresses = buildUnnamed5833();
    o.ageRange = 'foo';
    o.ageRanges = buildUnnamed5834();
    o.biographies = buildUnnamed5835();
    o.birthdays = buildUnnamed5836();
    o.braggingRights = buildUnnamed5837();
    o.calendarUrls = buildUnnamed5838();
    o.clientData = buildUnnamed5839();
    o.coverPhotos = buildUnnamed5840();
    o.emailAddresses = buildUnnamed5841();
    o.etag = 'foo';
    o.events = buildUnnamed5842();
    o.externalIds = buildUnnamed5843();
    o.fileAses = buildUnnamed5844();
    o.genders = buildUnnamed5845();
    o.imClients = buildUnnamed5846();
    o.interests = buildUnnamed5847();
    o.locales = buildUnnamed5848();
    o.locations = buildUnnamed5849();
    o.memberships = buildUnnamed5850();
    o.metadata = buildPersonMetadata();
    o.miscKeywords = buildUnnamed5851();
    o.names = buildUnnamed5852();
    o.nicknames = buildUnnamed5853();
    o.occupations = buildUnnamed5854();
    o.organizations = buildUnnamed5855();
    o.phoneNumbers = buildUnnamed5856();
    o.photos = buildUnnamed5857();
    o.relations = buildUnnamed5858();
    o.relationshipInterests = buildUnnamed5859();
    o.relationshipStatuses = buildUnnamed5860();
    o.residences = buildUnnamed5861();
    o.resourceName = 'foo';
    o.sipAddresses = buildUnnamed5862();
    o.skills = buildUnnamed5863();
    o.taglines = buildUnnamed5864();
    o.urls = buildUnnamed5865();
    o.userDefined = buildUnnamed5866();
  }
  buildCounterPerson--;
  return o;
}

void checkPerson(api.Person o) {
  buildCounterPerson++;
  if (buildCounterPerson < 3) {
    checkUnnamed5833(o.addresses!);
    unittest.expect(
      o.ageRange!,
      unittest.equals('foo'),
    );
    checkUnnamed5834(o.ageRanges!);
    checkUnnamed5835(o.biographies!);
    checkUnnamed5836(o.birthdays!);
    checkUnnamed5837(o.braggingRights!);
    checkUnnamed5838(o.calendarUrls!);
    checkUnnamed5839(o.clientData!);
    checkUnnamed5840(o.coverPhotos!);
    checkUnnamed5841(o.emailAddresses!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed5842(o.events!);
    checkUnnamed5843(o.externalIds!);
    checkUnnamed5844(o.fileAses!);
    checkUnnamed5845(o.genders!);
    checkUnnamed5846(o.imClients!);
    checkUnnamed5847(o.interests!);
    checkUnnamed5848(o.locales!);
    checkUnnamed5849(o.locations!);
    checkUnnamed5850(o.memberships!);
    checkPersonMetadata(o.metadata! as api.PersonMetadata);
    checkUnnamed5851(o.miscKeywords!);
    checkUnnamed5852(o.names!);
    checkUnnamed5853(o.nicknames!);
    checkUnnamed5854(o.occupations!);
    checkUnnamed5855(o.organizations!);
    checkUnnamed5856(o.phoneNumbers!);
    checkUnnamed5857(o.photos!);
    checkUnnamed5858(o.relations!);
    checkUnnamed5859(o.relationshipInterests!);
    checkUnnamed5860(o.relationshipStatuses!);
    checkUnnamed5861(o.residences!);
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
    checkUnnamed5862(o.sipAddresses!);
    checkUnnamed5863(o.skills!);
    checkUnnamed5864(o.taglines!);
    checkUnnamed5865(o.urls!);
    checkUnnamed5866(o.userDefined!);
  }
  buildCounterPerson--;
}

core.List<core.String> buildUnnamed5867() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5867(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5868() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5868(core.List<core.String> o) {
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

core.List<api.Source> buildUnnamed5869() {
  var o = <api.Source>[];
  o.add(buildSource());
  o.add(buildSource());
  return o;
}

void checkUnnamed5869(core.List<api.Source> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSource(o[0] as api.Source);
  checkSource(o[1] as api.Source);
}

core.int buildCounterPersonMetadata = 0;
api.PersonMetadata buildPersonMetadata() {
  var o = api.PersonMetadata();
  buildCounterPersonMetadata++;
  if (buildCounterPersonMetadata < 3) {
    o.deleted = true;
    o.linkedPeopleResourceNames = buildUnnamed5867();
    o.objectType = 'foo';
    o.previousResourceNames = buildUnnamed5868();
    o.sources = buildUnnamed5869();
  }
  buildCounterPersonMetadata--;
  return o;
}

void checkPersonMetadata(api.PersonMetadata o) {
  buildCounterPersonMetadata++;
  if (buildCounterPersonMetadata < 3) {
    unittest.expect(o.deleted!, unittest.isTrue);
    checkUnnamed5867(o.linkedPeopleResourceNames!);
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    checkUnnamed5868(o.previousResourceNames!);
    checkUnnamed5869(o.sources!);
  }
  buildCounterPersonMetadata--;
}

core.int buildCounterPersonResponse = 0;
api.PersonResponse buildPersonResponse() {
  var o = api.PersonResponse();
  buildCounterPersonResponse++;
  if (buildCounterPersonResponse < 3) {
    o.httpStatusCode = 42;
    o.person = buildPerson();
    o.requestedResourceName = 'foo';
    o.status = buildStatus();
  }
  buildCounterPersonResponse--;
  return o;
}

void checkPersonResponse(api.PersonResponse o) {
  buildCounterPersonResponse++;
  if (buildCounterPersonResponse < 3) {
    unittest.expect(
      o.httpStatusCode!,
      unittest.equals(42),
    );
    checkPerson(o.person! as api.Person);
    unittest.expect(
      o.requestedResourceName!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
  }
  buildCounterPersonResponse--;
}

core.int buildCounterPhoneNumber = 0;
api.PhoneNumber buildPhoneNumber() {
  var o = api.PhoneNumber();
  buildCounterPhoneNumber++;
  if (buildCounterPhoneNumber < 3) {
    o.canonicalForm = 'foo';
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterPhoneNumber--;
  return o;
}

void checkPhoneNumber(api.PhoneNumber o) {
  buildCounterPhoneNumber++;
  if (buildCounterPhoneNumber < 3) {
    unittest.expect(
      o.canonicalForm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterPhoneNumber--;
}

core.int buildCounterPhoto = 0;
api.Photo buildPhoto() {
  var o = api.Photo();
  buildCounterPhoto++;
  if (buildCounterPhoto < 3) {
    o.default_ = true;
    o.metadata = buildFieldMetadata();
    o.url = 'foo';
  }
  buildCounterPhoto--;
  return o;
}

void checkPhoto(api.Photo o) {
  buildCounterPhoto++;
  if (buildCounterPhoto < 3) {
    unittest.expect(o.default_!, unittest.isTrue);
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterPhoto--;
}

core.List<core.String> buildUnnamed5870() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5870(core.List<core.String> o) {
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

core.int buildCounterProfileMetadata = 0;
api.ProfileMetadata buildProfileMetadata() {
  var o = api.ProfileMetadata();
  buildCounterProfileMetadata++;
  if (buildCounterProfileMetadata < 3) {
    o.objectType = 'foo';
    o.userTypes = buildUnnamed5870();
  }
  buildCounterProfileMetadata--;
  return o;
}

void checkProfileMetadata(api.ProfileMetadata o) {
  buildCounterProfileMetadata++;
  if (buildCounterProfileMetadata < 3) {
    unittest.expect(
      o.objectType!,
      unittest.equals('foo'),
    );
    checkUnnamed5870(o.userTypes!);
  }
  buildCounterProfileMetadata--;
}

core.int buildCounterRelation = 0;
api.Relation buildRelation() {
  var o = api.Relation();
  buildCounterRelation++;
  if (buildCounterRelation < 3) {
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.person = 'foo';
    o.type = 'foo';
  }
  buildCounterRelation--;
  return o;
}

void checkRelation(api.Relation o) {
  buildCounterRelation++;
  if (buildCounterRelation < 3) {
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.person!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterRelation--;
}

core.int buildCounterRelationshipInterest = 0;
api.RelationshipInterest buildRelationshipInterest() {
  var o = api.RelationshipInterest();
  buildCounterRelationshipInterest++;
  if (buildCounterRelationshipInterest < 3) {
    o.formattedValue = 'foo';
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterRelationshipInterest--;
  return o;
}

void checkRelationshipInterest(api.RelationshipInterest o) {
  buildCounterRelationshipInterest++;
  if (buildCounterRelationshipInterest < 3) {
    unittest.expect(
      o.formattedValue!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterRelationshipInterest--;
}

core.int buildCounterRelationshipStatus = 0;
api.RelationshipStatus buildRelationshipStatus() {
  var o = api.RelationshipStatus();
  buildCounterRelationshipStatus++;
  if (buildCounterRelationshipStatus < 3) {
    o.formattedValue = 'foo';
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterRelationshipStatus--;
  return o;
}

void checkRelationshipStatus(api.RelationshipStatus o) {
  buildCounterRelationshipStatus++;
  if (buildCounterRelationshipStatus < 3) {
    unittest.expect(
      o.formattedValue!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterRelationshipStatus--;
}

core.int buildCounterResidence = 0;
api.Residence buildResidence() {
  var o = api.Residence();
  buildCounterResidence++;
  if (buildCounterResidence < 3) {
    o.current = true;
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterResidence--;
  return o;
}

void checkResidence(api.Residence o) {
  buildCounterResidence++;
  if (buildCounterResidence < 3) {
    unittest.expect(o.current!, unittest.isTrue);
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterResidence--;
}

core.List<api.Person> buildUnnamed5871() {
  var o = <api.Person>[];
  o.add(buildPerson());
  o.add(buildPerson());
  return o;
}

void checkUnnamed5871(core.List<api.Person> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerson(o[0] as api.Person);
  checkPerson(o[1] as api.Person);
}

core.int buildCounterSearchDirectoryPeopleResponse = 0;
api.SearchDirectoryPeopleResponse buildSearchDirectoryPeopleResponse() {
  var o = api.SearchDirectoryPeopleResponse();
  buildCounterSearchDirectoryPeopleResponse++;
  if (buildCounterSearchDirectoryPeopleResponse < 3) {
    o.nextPageToken = 'foo';
    o.people = buildUnnamed5871();
    o.totalSize = 42;
  }
  buildCounterSearchDirectoryPeopleResponse--;
  return o;
}

void checkSearchDirectoryPeopleResponse(api.SearchDirectoryPeopleResponse o) {
  buildCounterSearchDirectoryPeopleResponse++;
  if (buildCounterSearchDirectoryPeopleResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5871(o.people!);
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterSearchDirectoryPeopleResponse--;
}

core.List<api.SearchResult> buildUnnamed5872() {
  var o = <api.SearchResult>[];
  o.add(buildSearchResult());
  o.add(buildSearchResult());
  return o;
}

void checkUnnamed5872(core.List<api.SearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSearchResult(o[0] as api.SearchResult);
  checkSearchResult(o[1] as api.SearchResult);
}

core.int buildCounterSearchResponse = 0;
api.SearchResponse buildSearchResponse() {
  var o = api.SearchResponse();
  buildCounterSearchResponse++;
  if (buildCounterSearchResponse < 3) {
    o.results = buildUnnamed5872();
  }
  buildCounterSearchResponse--;
  return o;
}

void checkSearchResponse(api.SearchResponse o) {
  buildCounterSearchResponse++;
  if (buildCounterSearchResponse < 3) {
    checkUnnamed5872(o.results!);
  }
  buildCounterSearchResponse--;
}

core.int buildCounterSearchResult = 0;
api.SearchResult buildSearchResult() {
  var o = api.SearchResult();
  buildCounterSearchResult++;
  if (buildCounterSearchResult < 3) {
    o.person = buildPerson();
  }
  buildCounterSearchResult--;
  return o;
}

void checkSearchResult(api.SearchResult o) {
  buildCounterSearchResult++;
  if (buildCounterSearchResult < 3) {
    checkPerson(o.person! as api.Person);
  }
  buildCounterSearchResult--;
}

core.int buildCounterSipAddress = 0;
api.SipAddress buildSipAddress() {
  var o = api.SipAddress();
  buildCounterSipAddress++;
  if (buildCounterSipAddress < 3) {
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterSipAddress--;
  return o;
}

void checkSipAddress(api.SipAddress o) {
  buildCounterSipAddress++;
  if (buildCounterSipAddress < 3) {
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterSipAddress--;
}

core.int buildCounterSkill = 0;
api.Skill buildSkill() {
  var o = api.Skill();
  buildCounterSkill++;
  if (buildCounterSkill < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterSkill--;
  return o;
}

void checkSkill(api.Skill o) {
  buildCounterSkill++;
  if (buildCounterSkill < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterSkill--;
}

core.int buildCounterSource = 0;
api.Source buildSource() {
  var o = api.Source();
  buildCounterSource++;
  if (buildCounterSource < 3) {
    o.etag = 'foo';
    o.id = 'foo';
    o.profileMetadata = buildProfileMetadata();
    o.type = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterSource--;
  return o;
}

void checkSource(api.Source o) {
  buildCounterSource++;
  if (buildCounterSource < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkProfileMetadata(o.profileMetadata! as api.ProfileMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSource--;
}

core.Map<core.String, core.Object> buildUnnamed5873() {
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

void checkUnnamed5873(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed5874() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed5873());
  o.add(buildUnnamed5873());
  return o;
}

void checkUnnamed5874(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5873(o[0]);
  checkUnnamed5873(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed5874();
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
    checkUnnamed5874(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTagline = 0;
api.Tagline buildTagline() {
  var o = api.Tagline();
  buildCounterTagline++;
  if (buildCounterTagline < 3) {
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterTagline--;
  return o;
}

void checkTagline(api.Tagline o) {
  buildCounterTagline++;
  if (buildCounterTagline < 3) {
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterTagline--;
}

core.int buildCounterUpdateContactGroupRequest = 0;
api.UpdateContactGroupRequest buildUpdateContactGroupRequest() {
  var o = api.UpdateContactGroupRequest();
  buildCounterUpdateContactGroupRequest++;
  if (buildCounterUpdateContactGroupRequest < 3) {
    o.contactGroup = buildContactGroup();
    o.readGroupFields = 'foo';
    o.updateGroupFields = 'foo';
  }
  buildCounterUpdateContactGroupRequest--;
  return o;
}

void checkUpdateContactGroupRequest(api.UpdateContactGroupRequest o) {
  buildCounterUpdateContactGroupRequest++;
  if (buildCounterUpdateContactGroupRequest < 3) {
    checkContactGroup(o.contactGroup! as api.ContactGroup);
    unittest.expect(
      o.readGroupFields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateGroupFields!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateContactGroupRequest--;
}

core.List<core.String> buildUnnamed5875() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5875(core.List<core.String> o) {
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

core.int buildCounterUpdateContactPhotoRequest = 0;
api.UpdateContactPhotoRequest buildUpdateContactPhotoRequest() {
  var o = api.UpdateContactPhotoRequest();
  buildCounterUpdateContactPhotoRequest++;
  if (buildCounterUpdateContactPhotoRequest < 3) {
    o.personFields = 'foo';
    o.photoBytes = 'foo';
    o.sources = buildUnnamed5875();
  }
  buildCounterUpdateContactPhotoRequest--;
  return o;
}

void checkUpdateContactPhotoRequest(api.UpdateContactPhotoRequest o) {
  buildCounterUpdateContactPhotoRequest++;
  if (buildCounterUpdateContactPhotoRequest < 3) {
    unittest.expect(
      o.personFields!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoBytes!,
      unittest.equals('foo'),
    );
    checkUnnamed5875(o.sources!);
  }
  buildCounterUpdateContactPhotoRequest--;
}

core.int buildCounterUpdateContactPhotoResponse = 0;
api.UpdateContactPhotoResponse buildUpdateContactPhotoResponse() {
  var o = api.UpdateContactPhotoResponse();
  buildCounterUpdateContactPhotoResponse++;
  if (buildCounterUpdateContactPhotoResponse < 3) {
    o.person = buildPerson();
  }
  buildCounterUpdateContactPhotoResponse--;
  return o;
}

void checkUpdateContactPhotoResponse(api.UpdateContactPhotoResponse o) {
  buildCounterUpdateContactPhotoResponse++;
  if (buildCounterUpdateContactPhotoResponse < 3) {
    checkPerson(o.person! as api.Person);
  }
  buildCounterUpdateContactPhotoResponse--;
}

core.int buildCounterUrl = 0;
api.Url buildUrl() {
  var o = api.Url();
  buildCounterUrl++;
  if (buildCounterUrl < 3) {
    o.formattedType = 'foo';
    o.metadata = buildFieldMetadata();
    o.type = 'foo';
    o.value = 'foo';
  }
  buildCounterUrl--;
  return o;
}

void checkUrl(api.Url o) {
  buildCounterUrl++;
  if (buildCounterUrl < 3) {
    unittest.expect(
      o.formattedType!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrl--;
}

core.int buildCounterUserDefined = 0;
api.UserDefined buildUserDefined() {
  var o = api.UserDefined();
  buildCounterUserDefined++;
  if (buildCounterUserDefined < 3) {
    o.key = 'foo';
    o.metadata = buildFieldMetadata();
    o.value = 'foo';
  }
  buildCounterUserDefined--;
  return o;
}

void checkUserDefined(api.UserDefined o) {
  buildCounterUserDefined++;
  if (buildCounterUserDefined < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkFieldMetadata(o.metadata! as api.FieldMetadata);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserDefined--;
}

core.List<core.String> buildUnnamed5876() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5876(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5877() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5877(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5878() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5878(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5879() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5879(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5880() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5880(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5881() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5881(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5882() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5882(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5883() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5883(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5884() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5884(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5885() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5885(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5886() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5886(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5887() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5887(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5888() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5888(core.List<core.String> o) {
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
  unittest.group('obj-schema-Address', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Address.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAddress(od as api.Address);
    });
  });

  unittest.group('obj-schema-AgeRangeType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAgeRangeType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AgeRangeType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAgeRangeType(od as api.AgeRangeType);
    });
  });

  unittest.group('obj-schema-BatchCreateContactsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchCreateContactsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchCreateContactsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchCreateContactsRequest(od as api.BatchCreateContactsRequest);
    });
  });

  unittest.group('obj-schema-BatchCreateContactsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchCreateContactsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchCreateContactsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchCreateContactsResponse(od as api.BatchCreateContactsResponse);
    });
  });

  unittest.group('obj-schema-BatchDeleteContactsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeleteContactsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeleteContactsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeleteContactsRequest(od as api.BatchDeleteContactsRequest);
    });
  });

  unittest.group('obj-schema-BatchGetContactGroupsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetContactGroupsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetContactGroupsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetContactGroupsResponse(
          od as api.BatchGetContactGroupsResponse);
    });
  });

  unittest.group('obj-schema-BatchUpdateContactsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateContactsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateContactsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateContactsRequest(od as api.BatchUpdateContactsRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdateContactsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdateContactsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdateContactsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdateContactsResponse(od as api.BatchUpdateContactsResponse);
    });
  });

  unittest.group('obj-schema-Biography', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBiography();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Biography.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBiography(od as api.Biography);
    });
  });

  unittest.group('obj-schema-Birthday', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBirthday();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Birthday.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBirthday(od as api.Birthday);
    });
  });

  unittest.group('obj-schema-BraggingRights', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBraggingRights();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BraggingRights.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBraggingRights(od as api.BraggingRights);
    });
  });

  unittest.group('obj-schema-CalendarUrl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCalendarUrl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CalendarUrl.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCalendarUrl(od as api.CalendarUrl);
    });
  });

  unittest.group('obj-schema-ClientData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClientData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ClientData.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkClientData(od as api.ClientData);
    });
  });

  unittest.group('obj-schema-ContactGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContactGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContactGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContactGroup(od as api.ContactGroup);
    });
  });

  unittest.group('obj-schema-ContactGroupMembership', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContactGroupMembership();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContactGroupMembership.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContactGroupMembership(od as api.ContactGroupMembership);
    });
  });

  unittest.group('obj-schema-ContactGroupMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContactGroupMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContactGroupMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContactGroupMetadata(od as api.ContactGroupMetadata);
    });
  });

  unittest.group('obj-schema-ContactGroupResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContactGroupResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContactGroupResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContactGroupResponse(od as api.ContactGroupResponse);
    });
  });

  unittest.group('obj-schema-ContactToCreate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContactToCreate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContactToCreate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContactToCreate(od as api.ContactToCreate);
    });
  });

  unittest.group('obj-schema-CopyOtherContactToMyContactsGroupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCopyOtherContactToMyContactsGroupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CopyOtherContactToMyContactsGroupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCopyOtherContactToMyContactsGroupRequest(
          od as api.CopyOtherContactToMyContactsGroupRequest);
    });
  });

  unittest.group('obj-schema-CoverPhoto', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCoverPhoto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CoverPhoto.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCoverPhoto(od as api.CoverPhoto);
    });
  });

  unittest.group('obj-schema-CreateContactGroupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateContactGroupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateContactGroupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateContactGroupRequest(od as api.CreateContactGroupRequest);
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

  unittest.group('obj-schema-DeleteContactPhotoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteContactPhotoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteContactPhotoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteContactPhotoResponse(od as api.DeleteContactPhotoResponse);
    });
  });

  unittest.group('obj-schema-DomainMembership', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomainMembership();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DomainMembership.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDomainMembership(od as api.DomainMembership);
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

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-Event', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Event.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEvent(od as api.Event);
    });
  });

  unittest.group('obj-schema-ExternalId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExternalId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ExternalId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExternalId(od as api.ExternalId);
    });
  });

  unittest.group('obj-schema-FieldMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFieldMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FieldMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFieldMetadata(od as api.FieldMetadata);
    });
  });

  unittest.group('obj-schema-FileAs', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFileAs();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.FileAs.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFileAs(od as api.FileAs);
    });
  });

  unittest.group('obj-schema-Gender', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGender();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Gender.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGender(od as api.Gender);
    });
  });

  unittest.group('obj-schema-GetPeopleResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetPeopleResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetPeopleResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetPeopleResponse(od as api.GetPeopleResponse);
    });
  });

  unittest.group('obj-schema-GroupClientData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGroupClientData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GroupClientData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGroupClientData(od as api.GroupClientData);
    });
  });

  unittest.group('obj-schema-ImClient', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImClient();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ImClient.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImClient(od as api.ImClient);
    });
  });

  unittest.group('obj-schema-Interest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInterest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Interest.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInterest(od as api.Interest);
    });
  });

  unittest.group('obj-schema-ListConnectionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListConnectionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListConnectionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListConnectionsResponse(od as api.ListConnectionsResponse);
    });
  });

  unittest.group('obj-schema-ListContactGroupsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListContactGroupsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListContactGroupsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListContactGroupsResponse(od as api.ListContactGroupsResponse);
    });
  });

  unittest.group('obj-schema-ListDirectoryPeopleResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDirectoryPeopleResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDirectoryPeopleResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDirectoryPeopleResponse(od as api.ListDirectoryPeopleResponse);
    });
  });

  unittest.group('obj-schema-ListOtherContactsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOtherContactsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOtherContactsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOtherContactsResponse(od as api.ListOtherContactsResponse);
    });
  });

  unittest.group('obj-schema-Locale', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocale();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Locale.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocale(od as api.Locale);
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

  unittest.group('obj-schema-Membership', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMembership();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Membership.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMembership(od as api.Membership);
    });
  });

  unittest.group('obj-schema-MiscKeyword', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMiscKeyword();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MiscKeyword.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMiscKeyword(od as api.MiscKeyword);
    });
  });

  unittest.group('obj-schema-ModifyContactGroupMembersRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyContactGroupMembersRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyContactGroupMembersRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyContactGroupMembersRequest(
          od as api.ModifyContactGroupMembersRequest);
    });
  });

  unittest.group('obj-schema-ModifyContactGroupMembersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyContactGroupMembersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyContactGroupMembersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyContactGroupMembersResponse(
          od as api.ModifyContactGroupMembersResponse);
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

  unittest.group('obj-schema-Nickname', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNickname();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Nickname.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkNickname(od as api.Nickname);
    });
  });

  unittest.group('obj-schema-Occupation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOccupation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Occupation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOccupation(od as api.Occupation);
    });
  });

  unittest.group('obj-schema-Organization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOrganization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Organization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOrganization(od as api.Organization);
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

  unittest.group('obj-schema-PersonMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPersonMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PersonMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPersonMetadata(od as api.PersonMetadata);
    });
  });

  unittest.group('obj-schema-PersonResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPersonResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PersonResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPersonResponse(od as api.PersonResponse);
    });
  });

  unittest.group('obj-schema-PhoneNumber', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPhoneNumber();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PhoneNumber.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPhoneNumber(od as api.PhoneNumber);
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

  unittest.group('obj-schema-ProfileMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileMetadata(od as api.ProfileMetadata);
    });
  });

  unittest.group('obj-schema-Relation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Relation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRelation(od as api.Relation);
    });
  });

  unittest.group('obj-schema-RelationshipInterest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelationshipInterest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RelationshipInterest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRelationshipInterest(od as api.RelationshipInterest);
    });
  });

  unittest.group('obj-schema-RelationshipStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRelationshipStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RelationshipStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRelationshipStatus(od as api.RelationshipStatus);
    });
  });

  unittest.group('obj-schema-Residence', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResidence();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Residence.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkResidence(od as api.Residence);
    });
  });

  unittest.group('obj-schema-SearchDirectoryPeopleResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchDirectoryPeopleResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchDirectoryPeopleResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchDirectoryPeopleResponse(
          od as api.SearchDirectoryPeopleResponse);
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

  unittest.group('obj-schema-SipAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSipAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SipAddress.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSipAddress(od as api.SipAddress);
    });
  });

  unittest.group('obj-schema-Skill', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSkill();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Skill.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSkill(od as api.Skill);
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

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-Tagline', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTagline();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Tagline.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTagline(od as api.Tagline);
    });
  });

  unittest.group('obj-schema-UpdateContactGroupRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateContactGroupRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateContactGroupRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateContactGroupRequest(od as api.UpdateContactGroupRequest);
    });
  });

  unittest.group('obj-schema-UpdateContactPhotoRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateContactPhotoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateContactPhotoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateContactPhotoRequest(od as api.UpdateContactPhotoRequest);
    });
  });

  unittest.group('obj-schema-UpdateContactPhotoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateContactPhotoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateContactPhotoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateContactPhotoResponse(od as api.UpdateContactPhotoResponse);
    });
  });

  unittest.group('obj-schema-Url', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Url.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUrl(od as api.Url);
    });
  });

  unittest.group('obj-schema-UserDefined', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserDefined();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserDefined.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserDefined(od as api.UserDefined);
    });
  });

  unittest.group('resource-ContactGroupsResource', () {
    unittest.test('method--batchGet', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups;
      var arg_groupFields = 'foo';
      var arg_maxMembers = 42;
      var arg_resourceNames = buildUnnamed5876();
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
          unittest.equals("v1/contactGroups:batchGet"),
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
          queryMap["groupFields"]!.first,
          unittest.equals(arg_groupFields),
        );
        unittest.expect(
          core.int.parse(queryMap["maxMembers"]!.first),
          unittest.equals(arg_maxMembers),
        );
        unittest.expect(
          queryMap["resourceNames"]!,
          unittest.equals(arg_resourceNames),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchGetContactGroupsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchGet(
          groupFields: arg_groupFields,
          maxMembers: arg_maxMembers,
          resourceNames: arg_resourceNames,
          $fields: arg_$fields);
      checkBatchGetContactGroupsResponse(
          response as api.BatchGetContactGroupsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups;
      var arg_request = buildCreateContactGroupRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateContactGroupRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateContactGroupRequest(obj as api.CreateContactGroupRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/contactGroups"),
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
        var resp = convert.json.encode(buildContactGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkContactGroup(response as api.ContactGroup);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups;
      var arg_resourceName = 'foo';
      var arg_deleteContacts = true;
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
          queryMap["deleteContacts"]!.first,
          unittest.equals("$arg_deleteContacts"),
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
      final response = await res.delete(arg_resourceName,
          deleteContacts: arg_deleteContacts, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups;
      var arg_resourceName = 'foo';
      var arg_groupFields = 'foo';
      var arg_maxMembers = 42;
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
          queryMap["groupFields"]!.first,
          unittest.equals(arg_groupFields),
        );
        unittest.expect(
          core.int.parse(queryMap["maxMembers"]!.first),
          unittest.equals(arg_maxMembers),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildContactGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_resourceName,
          groupFields: arg_groupFields,
          maxMembers: arg_maxMembers,
          $fields: arg_$fields);
      checkContactGroup(response as api.ContactGroup);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups;
      var arg_groupFields = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_syncToken = 'foo';
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
          unittest.equals("v1/contactGroups"),
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
          queryMap["groupFields"]!.first,
          unittest.equals(arg_groupFields),
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
          queryMap["syncToken"]!.first,
          unittest.equals(arg_syncToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListContactGroupsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          groupFields: arg_groupFields,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          syncToken: arg_syncToken,
          $fields: arg_$fields);
      checkListContactGroupsResponse(response as api.ListContactGroupsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups;
      var arg_request = buildUpdateContactGroupRequest();
      var arg_resourceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateContactGroupRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateContactGroupRequest(obj as api.UpdateContactGroupRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildContactGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_resourceName, $fields: arg_$fields);
      checkContactGroup(response as api.ContactGroup);
    });
  });

  unittest.group('resource-ContactGroupsMembersResource', () {
    unittest.test('method--modify', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).contactGroups.members;
      var arg_request = buildModifyContactGroupMembersRequest();
      var arg_resourceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyContactGroupMembersRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyContactGroupMembersRequest(
            obj as api.ModifyContactGroupMembersRequest);

        var path = (req.url).path;
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
        var resp =
            convert.json.encode(buildModifyContactGroupMembersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.modify(arg_request, arg_resourceName, $fields: arg_$fields);
      checkModifyContactGroupMembersResponse(
          response as api.ModifyContactGroupMembersResponse);
    });
  });

  unittest.group('resource-OtherContactsResource', () {
    unittest.test('method--copyOtherContactToMyContactsGroup', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).otherContacts;
      var arg_request = buildCopyOtherContactToMyContactsGroupRequest();
      var arg_resourceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CopyOtherContactToMyContactsGroupRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCopyOtherContactToMyContactsGroupRequest(
            obj as api.CopyOtherContactToMyContactsGroupRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPerson());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.copyOtherContactToMyContactsGroup(
          arg_request, arg_resourceName,
          $fields: arg_$fields);
      checkPerson(response as api.Person);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).otherContacts;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_readMask = 'foo';
      var arg_requestSyncToken = true;
      var arg_syncToken = 'foo';
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
          unittest.equals("v1/otherContacts"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
        unittest.expect(
          queryMap["requestSyncToken"]!.first,
          unittest.equals("$arg_requestSyncToken"),
        );
        unittest.expect(
          queryMap["syncToken"]!.first,
          unittest.equals(arg_syncToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListOtherContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readMask: arg_readMask,
          requestSyncToken: arg_requestSyncToken,
          syncToken: arg_syncToken,
          $fields: arg_$fields);
      checkListOtherContactsResponse(response as api.ListOtherContactsResponse);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).otherContacts;
      var arg_pageSize = 42;
      var arg_query = 'foo';
      var arg_readMask = 'foo';
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
          unittest.equals("v1/otherContacts:search"),
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
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
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
      final response = await res.search(
          pageSize: arg_pageSize,
          query: arg_query,
          readMask: arg_readMask,
          $fields: arg_$fields);
      checkSearchResponse(response as api.SearchResponse);
    });
  });

  unittest.group('resource-PeopleResource', () {
    unittest.test('method--batchCreateContacts', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_request = buildBatchCreateContactsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchCreateContactsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchCreateContactsRequest(obj as api.BatchCreateContactsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/people:batchCreateContacts"),
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
        var resp = convert.json.encode(buildBatchCreateContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.batchCreateContacts(arg_request, $fields: arg_$fields);
      checkBatchCreateContactsResponse(
          response as api.BatchCreateContactsResponse);
    });

    unittest.test('method--batchDeleteContacts', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_request = buildBatchDeleteContactsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchDeleteContactsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchDeleteContactsRequest(obj as api.BatchDeleteContactsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/people:batchDeleteContacts"),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.batchDeleteContacts(arg_request, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--batchUpdateContacts', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_request = buildBatchUpdateContactsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdateContactsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdateContactsRequest(obj as api.BatchUpdateContactsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/people:batchUpdateContacts"),
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
        var resp = convert.json.encode(buildBatchUpdateContactsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.batchUpdateContacts(arg_request, $fields: arg_$fields);
      checkBatchUpdateContactsResponse(
          response as api.BatchUpdateContactsResponse);
    });

    unittest.test('method--createContact', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_request = buildPerson();
      var arg_personFields = 'foo';
      var arg_sources = buildUnnamed5877();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Person.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPerson(obj as api.Person);

        var path = (req.url).path;
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
          unittest.equals("v1/people:createContact"),
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
          queryMap["personFields"]!.first,
          unittest.equals(arg_personFields),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPerson());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.createContact(arg_request,
          personFields: arg_personFields,
          sources: arg_sources,
          $fields: arg_$fields);
      checkPerson(response as api.Person);
    });

    unittest.test('method--deleteContact', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_resourceName = 'foo';
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
      final response =
          await res.deleteContact(arg_resourceName, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--deleteContactPhoto', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_resourceName = 'foo';
      var arg_personFields = 'foo';
      var arg_sources = buildUnnamed5878();
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
          queryMap["personFields"]!.first,
          unittest.equals(arg_personFields),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDeleteContactPhotoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.deleteContactPhoto(arg_resourceName,
          personFields: arg_personFields,
          sources: arg_sources,
          $fields: arg_$fields);
      checkDeleteContactPhotoResponse(
          response as api.DeleteContactPhotoResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_resourceName = 'foo';
      var arg_personFields = 'foo';
      var arg_requestMask_includeField = 'foo';
      var arg_sources = buildUnnamed5879();
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
          queryMap["personFields"]!.first,
          unittest.equals(arg_personFields),
        );
        unittest.expect(
          queryMap["requestMask.includeField"]!.first,
          unittest.equals(arg_requestMask_includeField),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPerson());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_resourceName,
          personFields: arg_personFields,
          requestMask_includeField: arg_requestMask_includeField,
          sources: arg_sources,
          $fields: arg_$fields);
      checkPerson(response as api.Person);
    });

    unittest.test('method--getBatchGet', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_personFields = 'foo';
      var arg_requestMask_includeField = 'foo';
      var arg_resourceNames = buildUnnamed5880();
      var arg_sources = buildUnnamed5881();
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
          unittest.equals("v1/people:batchGet"),
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
          queryMap["personFields"]!.first,
          unittest.equals(arg_personFields),
        );
        unittest.expect(
          queryMap["requestMask.includeField"]!.first,
          unittest.equals(arg_requestMask_includeField),
        );
        unittest.expect(
          queryMap["resourceNames"]!,
          unittest.equals(arg_resourceNames),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetPeopleResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getBatchGet(
          personFields: arg_personFields,
          requestMask_includeField: arg_requestMask_includeField,
          resourceNames: arg_resourceNames,
          sources: arg_sources,
          $fields: arg_$fields);
      checkGetPeopleResponse(response as api.GetPeopleResponse);
    });

    unittest.test('method--listDirectoryPeople', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_mergeSources = buildUnnamed5882();
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_readMask = 'foo';
      var arg_requestSyncToken = true;
      var arg_sources = buildUnnamed5883();
      var arg_syncToken = 'foo';
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
          unittest.equals("v1/people:listDirectoryPeople"),
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
          queryMap["mergeSources"]!,
          unittest.equals(arg_mergeSources),
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
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
        unittest.expect(
          queryMap["requestSyncToken"]!.first,
          unittest.equals("$arg_requestSyncToken"),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["syncToken"]!.first,
          unittest.equals(arg_syncToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListDirectoryPeopleResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listDirectoryPeople(
          mergeSources: arg_mergeSources,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          readMask: arg_readMask,
          requestSyncToken: arg_requestSyncToken,
          sources: arg_sources,
          syncToken: arg_syncToken,
          $fields: arg_$fields);
      checkListDirectoryPeopleResponse(
          response as api.ListDirectoryPeopleResponse);
    });

    unittest.test('method--searchContacts', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_pageSize = 42;
      var arg_query = 'foo';
      var arg_readMask = 'foo';
      var arg_sources = buildUnnamed5884();
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
          unittest.equals("v1/people:searchContacts"),
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
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
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
      final response = await res.searchContacts(
          pageSize: arg_pageSize,
          query: arg_query,
          readMask: arg_readMask,
          sources: arg_sources,
          $fields: arg_$fields);
      checkSearchResponse(response as api.SearchResponse);
    });

    unittest.test('method--searchDirectoryPeople', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_mergeSources = buildUnnamed5885();
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_query = 'foo';
      var arg_readMask = 'foo';
      var arg_sources = buildUnnamed5886();
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
          unittest.equals("v1/people:searchDirectoryPeople"),
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
          queryMap["mergeSources"]!,
          unittest.equals(arg_mergeSources),
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
          queryMap["query"]!.first,
          unittest.equals(arg_query),
        );
        unittest.expect(
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSearchDirectoryPeopleResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.searchDirectoryPeople(
          mergeSources: arg_mergeSources,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          query: arg_query,
          readMask: arg_readMask,
          sources: arg_sources,
          $fields: arg_$fields);
      checkSearchDirectoryPeopleResponse(
          response as api.SearchDirectoryPeopleResponse);
    });

    unittest.test('method--updateContact', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_request = buildPerson();
      var arg_resourceName = 'foo';
      var arg_personFields = 'foo';
      var arg_sources = buildUnnamed5887();
      var arg_updatePersonFields = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Person.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPerson(obj as api.Person);

        var path = (req.url).path;
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
          queryMap["personFields"]!.first,
          unittest.equals(arg_personFields),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["updatePersonFields"]!.first,
          unittest.equals(arg_updatePersonFields),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPerson());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateContact(arg_request, arg_resourceName,
          personFields: arg_personFields,
          sources: arg_sources,
          updatePersonFields: arg_updatePersonFields,
          $fields: arg_$fields);
      checkPerson(response as api.Person);
    });

    unittest.test('method--updateContactPhoto', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people;
      var arg_request = buildUpdateContactPhotoRequest();
      var arg_resourceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateContactPhotoRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateContactPhotoRequest(obj as api.UpdateContactPhotoRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildUpdateContactPhotoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateContactPhoto(
          arg_request, arg_resourceName,
          $fields: arg_$fields);
      checkUpdateContactPhotoResponse(
          response as api.UpdateContactPhotoResponse);
    });
  });

  unittest.group('resource-PeopleConnectionsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PeopleServiceApi(mock).people.connections;
      var arg_resourceName = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_personFields = 'foo';
      var arg_requestMask_includeField = 'foo';
      var arg_requestSyncToken = true;
      var arg_sortOrder = 'foo';
      var arg_sources = buildUnnamed5888();
      var arg_syncToken = 'foo';
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
          queryMap["personFields"]!.first,
          unittest.equals(arg_personFields),
        );
        unittest.expect(
          queryMap["requestMask.includeField"]!.first,
          unittest.equals(arg_requestMask_includeField),
        );
        unittest.expect(
          queryMap["requestSyncToken"]!.first,
          unittest.equals("$arg_requestSyncToken"),
        );
        unittest.expect(
          queryMap["sortOrder"]!.first,
          unittest.equals(arg_sortOrder),
        );
        unittest.expect(
          queryMap["sources"]!,
          unittest.equals(arg_sources),
        );
        unittest.expect(
          queryMap["syncToken"]!.first,
          unittest.equals(arg_syncToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListConnectionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_resourceName,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          personFields: arg_personFields,
          requestMask_includeField: arg_requestMask_includeField,
          requestSyncToken: arg_requestSyncToken,
          sortOrder: arg_sortOrder,
          sources: arg_sources,
          syncToken: arg_syncToken,
          $fields: arg_$fields);
      checkListConnectionsResponse(response as api.ListConnectionsResponse);
    });
  });
}
