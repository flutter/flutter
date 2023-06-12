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

import 'package:googleapis/androiddeviceprovisioning/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterClaimDeviceRequest = 0;
api.ClaimDeviceRequest buildClaimDeviceRequest() {
  var o = api.ClaimDeviceRequest();
  buildCounterClaimDeviceRequest++;
  if (buildCounterClaimDeviceRequest < 3) {
    o.customerId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
    o.deviceMetadata = buildDeviceMetadata();
    o.sectionType = 'foo';
  }
  buildCounterClaimDeviceRequest--;
  return o;
}

void checkClaimDeviceRequest(api.ClaimDeviceRequest o) {
  buildCounterClaimDeviceRequest++;
  if (buildCounterClaimDeviceRequest < 3) {
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    checkDeviceMetadata(o.deviceMetadata! as api.DeviceMetadata);
    unittest.expect(
      o.sectionType!,
      unittest.equals('foo'),
    );
  }
  buildCounterClaimDeviceRequest--;
}

core.int buildCounterClaimDeviceResponse = 0;
api.ClaimDeviceResponse buildClaimDeviceResponse() {
  var o = api.ClaimDeviceResponse();
  buildCounterClaimDeviceResponse++;
  if (buildCounterClaimDeviceResponse < 3) {
    o.deviceId = 'foo';
    o.deviceName = 'foo';
  }
  buildCounterClaimDeviceResponse--;
  return o;
}

void checkClaimDeviceResponse(api.ClaimDeviceResponse o) {
  buildCounterClaimDeviceResponse++;
  if (buildCounterClaimDeviceResponse < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterClaimDeviceResponse--;
}

core.List<api.PartnerClaim> buildUnnamed4007() {
  var o = <api.PartnerClaim>[];
  o.add(buildPartnerClaim());
  o.add(buildPartnerClaim());
  return o;
}

void checkUnnamed4007(core.List<api.PartnerClaim> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPartnerClaim(o[0] as api.PartnerClaim);
  checkPartnerClaim(o[1] as api.PartnerClaim);
}

core.int buildCounterClaimDevicesRequest = 0;
api.ClaimDevicesRequest buildClaimDevicesRequest() {
  var o = api.ClaimDevicesRequest();
  buildCounterClaimDevicesRequest++;
  if (buildCounterClaimDevicesRequest < 3) {
    o.claims = buildUnnamed4007();
  }
  buildCounterClaimDevicesRequest--;
  return o;
}

void checkClaimDevicesRequest(api.ClaimDevicesRequest o) {
  buildCounterClaimDevicesRequest++;
  if (buildCounterClaimDevicesRequest < 3) {
    checkUnnamed4007(o.claims!);
  }
  buildCounterClaimDevicesRequest--;
}

core.List<core.String> buildUnnamed4008() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4008(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4009() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4009(core.List<core.String> o) {
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
    o.adminEmails = buildUnnamed4008();
    o.companyId = 'foo';
    o.companyName = 'foo';
    o.name = 'foo';
    o.ownerEmails = buildUnnamed4009();
    o.termsStatus = 'foo';
  }
  buildCounterCompany--;
  return o;
}

void checkCompany(api.Company o) {
  buildCounterCompany++;
  if (buildCounterCompany < 3) {
    checkUnnamed4008(o.adminEmails!);
    unittest.expect(
      o.companyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.companyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4009(o.ownerEmails!);
    unittest.expect(
      o.termsStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterCompany--;
}

core.int buildCounterConfiguration = 0;
api.Configuration buildConfiguration() {
  var o = api.Configuration();
  buildCounterConfiguration++;
  if (buildCounterConfiguration < 3) {
    o.companyName = 'foo';
    o.configurationId = 'foo';
    o.configurationName = 'foo';
    o.contactEmail = 'foo';
    o.contactPhone = 'foo';
    o.customMessage = 'foo';
    o.dpcExtras = 'foo';
    o.dpcResourcePath = 'foo';
    o.isDefault = true;
    o.name = 'foo';
  }
  buildCounterConfiguration--;
  return o;
}

void checkConfiguration(api.Configuration o) {
  buildCounterConfiguration++;
  if (buildCounterConfiguration < 3) {
    unittest.expect(
      o.companyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.configurationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.configurationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contactEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contactPhone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dpcExtras!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dpcResourcePath!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDefault!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterConfiguration--;
}

core.int buildCounterCreateCustomerRequest = 0;
api.CreateCustomerRequest buildCreateCustomerRequest() {
  var o = api.CreateCustomerRequest();
  buildCounterCreateCustomerRequest++;
  if (buildCounterCreateCustomerRequest < 3) {
    o.customer = buildCompany();
  }
  buildCounterCreateCustomerRequest--;
  return o;
}

void checkCreateCustomerRequest(api.CreateCustomerRequest o) {
  buildCounterCreateCustomerRequest++;
  if (buildCounterCreateCustomerRequest < 3) {
    checkCompany(o.customer! as api.Company);
  }
  buildCounterCreateCustomerRequest--;
}

core.int buildCounterCustomerApplyConfigurationRequest = 0;
api.CustomerApplyConfigurationRequest buildCustomerApplyConfigurationRequest() {
  var o = api.CustomerApplyConfigurationRequest();
  buildCounterCustomerApplyConfigurationRequest++;
  if (buildCounterCustomerApplyConfigurationRequest < 3) {
    o.configuration = 'foo';
    o.device = buildDeviceReference();
  }
  buildCounterCustomerApplyConfigurationRequest--;
  return o;
}

void checkCustomerApplyConfigurationRequest(
    api.CustomerApplyConfigurationRequest o) {
  buildCounterCustomerApplyConfigurationRequest++;
  if (buildCounterCustomerApplyConfigurationRequest < 3) {
    unittest.expect(
      o.configuration!,
      unittest.equals('foo'),
    );
    checkDeviceReference(o.device! as api.DeviceReference);
  }
  buildCounterCustomerApplyConfigurationRequest--;
}

core.List<api.Configuration> buildUnnamed4010() {
  var o = <api.Configuration>[];
  o.add(buildConfiguration());
  o.add(buildConfiguration());
  return o;
}

void checkUnnamed4010(core.List<api.Configuration> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConfiguration(o[0] as api.Configuration);
  checkConfiguration(o[1] as api.Configuration);
}

core.int buildCounterCustomerListConfigurationsResponse = 0;
api.CustomerListConfigurationsResponse
    buildCustomerListConfigurationsResponse() {
  var o = api.CustomerListConfigurationsResponse();
  buildCounterCustomerListConfigurationsResponse++;
  if (buildCounterCustomerListConfigurationsResponse < 3) {
    o.configurations = buildUnnamed4010();
  }
  buildCounterCustomerListConfigurationsResponse--;
  return o;
}

void checkCustomerListConfigurationsResponse(
    api.CustomerListConfigurationsResponse o) {
  buildCounterCustomerListConfigurationsResponse++;
  if (buildCounterCustomerListConfigurationsResponse < 3) {
    checkUnnamed4010(o.configurations!);
  }
  buildCounterCustomerListConfigurationsResponse--;
}

core.List<api.Company> buildUnnamed4011() {
  var o = <api.Company>[];
  o.add(buildCompany());
  o.add(buildCompany());
  return o;
}

void checkUnnamed4011(core.List<api.Company> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompany(o[0] as api.Company);
  checkCompany(o[1] as api.Company);
}

core.int buildCounterCustomerListCustomersResponse = 0;
api.CustomerListCustomersResponse buildCustomerListCustomersResponse() {
  var o = api.CustomerListCustomersResponse();
  buildCounterCustomerListCustomersResponse++;
  if (buildCounterCustomerListCustomersResponse < 3) {
    o.customers = buildUnnamed4011();
    o.nextPageToken = 'foo';
  }
  buildCounterCustomerListCustomersResponse--;
  return o;
}

void checkCustomerListCustomersResponse(api.CustomerListCustomersResponse o) {
  buildCounterCustomerListCustomersResponse++;
  if (buildCounterCustomerListCustomersResponse < 3) {
    checkUnnamed4011(o.customers!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerListCustomersResponse--;
}

core.List<api.Device> buildUnnamed4012() {
  var o = <api.Device>[];
  o.add(buildDevice());
  o.add(buildDevice());
  return o;
}

void checkUnnamed4012(core.List<api.Device> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDevice(o[0] as api.Device);
  checkDevice(o[1] as api.Device);
}

core.int buildCounterCustomerListDevicesResponse = 0;
api.CustomerListDevicesResponse buildCustomerListDevicesResponse() {
  var o = api.CustomerListDevicesResponse();
  buildCounterCustomerListDevicesResponse++;
  if (buildCounterCustomerListDevicesResponse < 3) {
    o.devices = buildUnnamed4012();
    o.nextPageToken = 'foo';
  }
  buildCounterCustomerListDevicesResponse--;
  return o;
}

void checkCustomerListDevicesResponse(api.CustomerListDevicesResponse o) {
  buildCounterCustomerListDevicesResponse++;
  if (buildCounterCustomerListDevicesResponse < 3) {
    checkUnnamed4012(o.devices!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomerListDevicesResponse--;
}

core.List<api.Dpc> buildUnnamed4013() {
  var o = <api.Dpc>[];
  o.add(buildDpc());
  o.add(buildDpc());
  return o;
}

void checkUnnamed4013(core.List<api.Dpc> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDpc(o[0] as api.Dpc);
  checkDpc(o[1] as api.Dpc);
}

core.int buildCounterCustomerListDpcsResponse = 0;
api.CustomerListDpcsResponse buildCustomerListDpcsResponse() {
  var o = api.CustomerListDpcsResponse();
  buildCounterCustomerListDpcsResponse++;
  if (buildCounterCustomerListDpcsResponse < 3) {
    o.dpcs = buildUnnamed4013();
  }
  buildCounterCustomerListDpcsResponse--;
  return o;
}

void checkCustomerListDpcsResponse(api.CustomerListDpcsResponse o) {
  buildCounterCustomerListDpcsResponse++;
  if (buildCounterCustomerListDpcsResponse < 3) {
    checkUnnamed4013(o.dpcs!);
  }
  buildCounterCustomerListDpcsResponse--;
}

core.int buildCounterCustomerRemoveConfigurationRequest = 0;
api.CustomerRemoveConfigurationRequest
    buildCustomerRemoveConfigurationRequest() {
  var o = api.CustomerRemoveConfigurationRequest();
  buildCounterCustomerRemoveConfigurationRequest++;
  if (buildCounterCustomerRemoveConfigurationRequest < 3) {
    o.device = buildDeviceReference();
  }
  buildCounterCustomerRemoveConfigurationRequest--;
  return o;
}

void checkCustomerRemoveConfigurationRequest(
    api.CustomerRemoveConfigurationRequest o) {
  buildCounterCustomerRemoveConfigurationRequest++;
  if (buildCounterCustomerRemoveConfigurationRequest < 3) {
    checkDeviceReference(o.device! as api.DeviceReference);
  }
  buildCounterCustomerRemoveConfigurationRequest--;
}

core.int buildCounterCustomerUnclaimDeviceRequest = 0;
api.CustomerUnclaimDeviceRequest buildCustomerUnclaimDeviceRequest() {
  var o = api.CustomerUnclaimDeviceRequest();
  buildCounterCustomerUnclaimDeviceRequest++;
  if (buildCounterCustomerUnclaimDeviceRequest < 3) {
    o.device = buildDeviceReference();
  }
  buildCounterCustomerUnclaimDeviceRequest--;
  return o;
}

void checkCustomerUnclaimDeviceRequest(api.CustomerUnclaimDeviceRequest o) {
  buildCounterCustomerUnclaimDeviceRequest++;
  if (buildCounterCustomerUnclaimDeviceRequest < 3) {
    checkDeviceReference(o.device! as api.DeviceReference);
  }
  buildCounterCustomerUnclaimDeviceRequest--;
}

core.List<api.DeviceClaim> buildUnnamed4014() {
  var o = <api.DeviceClaim>[];
  o.add(buildDeviceClaim());
  o.add(buildDeviceClaim());
  return o;
}

void checkUnnamed4014(core.List<api.DeviceClaim> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeviceClaim(o[0] as api.DeviceClaim);
  checkDeviceClaim(o[1] as api.DeviceClaim);
}

core.int buildCounterDevice = 0;
api.Device buildDevice() {
  var o = api.Device();
  buildCounterDevice++;
  if (buildCounterDevice < 3) {
    o.claims = buildUnnamed4014();
    o.configuration = 'foo';
    o.deviceId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
    o.deviceMetadata = buildDeviceMetadata();
    o.name = 'foo';
  }
  buildCounterDevice--;
  return o;
}

void checkDevice(api.Device o) {
  buildCounterDevice++;
  if (buildCounterDevice < 3) {
    checkUnnamed4014(o.claims!);
    unittest.expect(
      o.configuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    checkDeviceMetadata(o.deviceMetadata! as api.DeviceMetadata);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterDevice--;
}

core.int buildCounterDeviceClaim = 0;
api.DeviceClaim buildDeviceClaim() {
  var o = api.DeviceClaim();
  buildCounterDeviceClaim++;
  if (buildCounterDeviceClaim < 3) {
    o.ownerCompanyId = 'foo';
    o.resellerId = 'foo';
    o.sectionType = 'foo';
    o.vacationModeExpireTime = 'foo';
    o.vacationModeStartTime = 'foo';
  }
  buildCounterDeviceClaim--;
  return o;
}

void checkDeviceClaim(api.DeviceClaim o) {
  buildCounterDeviceClaim++;
  if (buildCounterDeviceClaim < 3) {
    unittest.expect(
      o.ownerCompanyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resellerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sectionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vacationModeExpireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vacationModeStartTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceClaim--;
}

core.int buildCounterDeviceIdentifier = 0;
api.DeviceIdentifier buildDeviceIdentifier() {
  var o = api.DeviceIdentifier();
  buildCounterDeviceIdentifier++;
  if (buildCounterDeviceIdentifier < 3) {
    o.imei = 'foo';
    o.manufacturer = 'foo';
    o.meid = 'foo';
    o.model = 'foo';
    o.serialNumber = 'foo';
  }
  buildCounterDeviceIdentifier--;
  return o;
}

void checkDeviceIdentifier(api.DeviceIdentifier o) {
  buildCounterDeviceIdentifier++;
  if (buildCounterDeviceIdentifier < 3) {
    unittest.expect(
      o.imei!,
      unittest.equals('foo'),
    );
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
    unittest.expect(
      o.serialNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceIdentifier--;
}

core.Map<core.String, core.String> buildUnnamed4015() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed4015(core.Map<core.String, core.String> o) {
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

core.int buildCounterDeviceMetadata = 0;
api.DeviceMetadata buildDeviceMetadata() {
  var o = api.DeviceMetadata();
  buildCounterDeviceMetadata++;
  if (buildCounterDeviceMetadata < 3) {
    o.entries = buildUnnamed4015();
  }
  buildCounterDeviceMetadata--;
  return o;
}

void checkDeviceMetadata(api.DeviceMetadata o) {
  buildCounterDeviceMetadata++;
  if (buildCounterDeviceMetadata < 3) {
    checkUnnamed4015(o.entries!);
  }
  buildCounterDeviceMetadata--;
}

core.int buildCounterDeviceReference = 0;
api.DeviceReference buildDeviceReference() {
  var o = api.DeviceReference();
  buildCounterDeviceReference++;
  if (buildCounterDeviceReference < 3) {
    o.deviceId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
  }
  buildCounterDeviceReference--;
  return o;
}

void checkDeviceReference(api.DeviceReference o) {
  buildCounterDeviceReference++;
  if (buildCounterDeviceReference < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
  }
  buildCounterDeviceReference--;
}

core.int buildCounterDevicesLongRunningOperationMetadata = 0;
api.DevicesLongRunningOperationMetadata
    buildDevicesLongRunningOperationMetadata() {
  var o = api.DevicesLongRunningOperationMetadata();
  buildCounterDevicesLongRunningOperationMetadata++;
  if (buildCounterDevicesLongRunningOperationMetadata < 3) {
    o.devicesCount = 42;
    o.processingStatus = 'foo';
    o.progress = 42;
  }
  buildCounterDevicesLongRunningOperationMetadata--;
  return o;
}

void checkDevicesLongRunningOperationMetadata(
    api.DevicesLongRunningOperationMetadata o) {
  buildCounterDevicesLongRunningOperationMetadata++;
  if (buildCounterDevicesLongRunningOperationMetadata < 3) {
    unittest.expect(
      o.devicesCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.processingStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progress!,
      unittest.equals(42),
    );
  }
  buildCounterDevicesLongRunningOperationMetadata--;
}

core.List<api.OperationPerDevice> buildUnnamed4016() {
  var o = <api.OperationPerDevice>[];
  o.add(buildOperationPerDevice());
  o.add(buildOperationPerDevice());
  return o;
}

void checkUnnamed4016(core.List<api.OperationPerDevice> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperationPerDevice(o[0] as api.OperationPerDevice);
  checkOperationPerDevice(o[1] as api.OperationPerDevice);
}

core.int buildCounterDevicesLongRunningOperationResponse = 0;
api.DevicesLongRunningOperationResponse
    buildDevicesLongRunningOperationResponse() {
  var o = api.DevicesLongRunningOperationResponse();
  buildCounterDevicesLongRunningOperationResponse++;
  if (buildCounterDevicesLongRunningOperationResponse < 3) {
    o.perDeviceStatus = buildUnnamed4016();
    o.successCount = 42;
  }
  buildCounterDevicesLongRunningOperationResponse--;
  return o;
}

void checkDevicesLongRunningOperationResponse(
    api.DevicesLongRunningOperationResponse o) {
  buildCounterDevicesLongRunningOperationResponse++;
  if (buildCounterDevicesLongRunningOperationResponse < 3) {
    checkUnnamed4016(o.perDeviceStatus!);
    unittest.expect(
      o.successCount!,
      unittest.equals(42),
    );
  }
  buildCounterDevicesLongRunningOperationResponse--;
}

core.int buildCounterDpc = 0;
api.Dpc buildDpc() {
  var o = api.Dpc();
  buildCounterDpc++;
  if (buildCounterDpc < 3) {
    o.dpcName = 'foo';
    o.name = 'foo';
    o.packageName = 'foo';
  }
  buildCounterDpc--;
  return o;
}

void checkDpc(api.Dpc o) {
  buildCounterDpc++;
  if (buildCounterDpc < 3) {
    unittest.expect(
      o.dpcName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
  }
  buildCounterDpc--;
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

core.int buildCounterFindDevicesByDeviceIdentifierRequest = 0;
api.FindDevicesByDeviceIdentifierRequest
    buildFindDevicesByDeviceIdentifierRequest() {
  var o = api.FindDevicesByDeviceIdentifierRequest();
  buildCounterFindDevicesByDeviceIdentifierRequest++;
  if (buildCounterFindDevicesByDeviceIdentifierRequest < 3) {
    o.deviceIdentifier = buildDeviceIdentifier();
    o.limit = 'foo';
    o.pageToken = 'foo';
  }
  buildCounterFindDevicesByDeviceIdentifierRequest--;
  return o;
}

void checkFindDevicesByDeviceIdentifierRequest(
    api.FindDevicesByDeviceIdentifierRequest o) {
  buildCounterFindDevicesByDeviceIdentifierRequest++;
  if (buildCounterFindDevicesByDeviceIdentifierRequest < 3) {
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    unittest.expect(
      o.limit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterFindDevicesByDeviceIdentifierRequest--;
}

core.List<api.Device> buildUnnamed4017() {
  var o = <api.Device>[];
  o.add(buildDevice());
  o.add(buildDevice());
  return o;
}

void checkUnnamed4017(core.List<api.Device> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDevice(o[0] as api.Device);
  checkDevice(o[1] as api.Device);
}

core.int buildCounterFindDevicesByDeviceIdentifierResponse = 0;
api.FindDevicesByDeviceIdentifierResponse
    buildFindDevicesByDeviceIdentifierResponse() {
  var o = api.FindDevicesByDeviceIdentifierResponse();
  buildCounterFindDevicesByDeviceIdentifierResponse++;
  if (buildCounterFindDevicesByDeviceIdentifierResponse < 3) {
    o.devices = buildUnnamed4017();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterFindDevicesByDeviceIdentifierResponse--;
  return o;
}

void checkFindDevicesByDeviceIdentifierResponse(
    api.FindDevicesByDeviceIdentifierResponse o) {
  buildCounterFindDevicesByDeviceIdentifierResponse++;
  if (buildCounterFindDevicesByDeviceIdentifierResponse < 3) {
    checkUnnamed4017(o.devices!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterFindDevicesByDeviceIdentifierResponse--;
}

core.List<core.String> buildUnnamed4018() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4018(core.List<core.String> o) {
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

core.int buildCounterFindDevicesByOwnerRequest = 0;
api.FindDevicesByOwnerRequest buildFindDevicesByOwnerRequest() {
  var o = api.FindDevicesByOwnerRequest();
  buildCounterFindDevicesByOwnerRequest++;
  if (buildCounterFindDevicesByOwnerRequest < 3) {
    o.customerId = buildUnnamed4018();
    o.limit = 'foo';
    o.pageToken = 'foo';
    o.sectionType = 'foo';
  }
  buildCounterFindDevicesByOwnerRequest--;
  return o;
}

void checkFindDevicesByOwnerRequest(api.FindDevicesByOwnerRequest o) {
  buildCounterFindDevicesByOwnerRequest++;
  if (buildCounterFindDevicesByOwnerRequest < 3) {
    checkUnnamed4018(o.customerId!);
    unittest.expect(
      o.limit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sectionType!,
      unittest.equals('foo'),
    );
  }
  buildCounterFindDevicesByOwnerRequest--;
}

core.List<api.Device> buildUnnamed4019() {
  var o = <api.Device>[];
  o.add(buildDevice());
  o.add(buildDevice());
  return o;
}

void checkUnnamed4019(core.List<api.Device> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDevice(o[0] as api.Device);
  checkDevice(o[1] as api.Device);
}

core.int buildCounterFindDevicesByOwnerResponse = 0;
api.FindDevicesByOwnerResponse buildFindDevicesByOwnerResponse() {
  var o = api.FindDevicesByOwnerResponse();
  buildCounterFindDevicesByOwnerResponse++;
  if (buildCounterFindDevicesByOwnerResponse < 3) {
    o.devices = buildUnnamed4019();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterFindDevicesByOwnerResponse--;
  return o;
}

void checkFindDevicesByOwnerResponse(api.FindDevicesByOwnerResponse o) {
  buildCounterFindDevicesByOwnerResponse++;
  if (buildCounterFindDevicesByOwnerResponse < 3) {
    checkUnnamed4019(o.devices!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterFindDevicesByOwnerResponse--;
}

core.List<api.Company> buildUnnamed4020() {
  var o = <api.Company>[];
  o.add(buildCompany());
  o.add(buildCompany());
  return o;
}

void checkUnnamed4020(core.List<api.Company> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompany(o[0] as api.Company);
  checkCompany(o[1] as api.Company);
}

core.int buildCounterListCustomersResponse = 0;
api.ListCustomersResponse buildListCustomersResponse() {
  var o = api.ListCustomersResponse();
  buildCounterListCustomersResponse++;
  if (buildCounterListCustomersResponse < 3) {
    o.customers = buildUnnamed4020();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterListCustomersResponse--;
  return o;
}

void checkListCustomersResponse(api.ListCustomersResponse o) {
  buildCounterListCustomersResponse++;
  if (buildCounterListCustomersResponse < 3) {
    checkUnnamed4020(o.customers!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListCustomersResponse--;
}

core.List<api.Company> buildUnnamed4021() {
  var o = <api.Company>[];
  o.add(buildCompany());
  o.add(buildCompany());
  return o;
}

void checkUnnamed4021(core.List<api.Company> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompany(o[0] as api.Company);
  checkCompany(o[1] as api.Company);
}

core.int buildCounterListVendorCustomersResponse = 0;
api.ListVendorCustomersResponse buildListVendorCustomersResponse() {
  var o = api.ListVendorCustomersResponse();
  buildCounterListVendorCustomersResponse++;
  if (buildCounterListVendorCustomersResponse < 3) {
    o.customers = buildUnnamed4021();
    o.nextPageToken = 'foo';
    o.totalSize = 42;
  }
  buildCounterListVendorCustomersResponse--;
  return o;
}

void checkListVendorCustomersResponse(api.ListVendorCustomersResponse o) {
  buildCounterListVendorCustomersResponse++;
  if (buildCounterListVendorCustomersResponse < 3) {
    checkUnnamed4021(o.customers!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
  }
  buildCounterListVendorCustomersResponse--;
}

core.List<api.Company> buildUnnamed4022() {
  var o = <api.Company>[];
  o.add(buildCompany());
  o.add(buildCompany());
  return o;
}

void checkUnnamed4022(core.List<api.Company> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCompany(o[0] as api.Company);
  checkCompany(o[1] as api.Company);
}

core.int buildCounterListVendorsResponse = 0;
api.ListVendorsResponse buildListVendorsResponse() {
  var o = api.ListVendorsResponse();
  buildCounterListVendorsResponse++;
  if (buildCounterListVendorsResponse < 3) {
    o.nextPageToken = 'foo';
    o.totalSize = 42;
    o.vendors = buildUnnamed4022();
  }
  buildCounterListVendorsResponse--;
  return o;
}

void checkListVendorsResponse(api.ListVendorsResponse o) {
  buildCounterListVendorsResponse++;
  if (buildCounterListVendorsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSize!,
      unittest.equals(42),
    );
    checkUnnamed4022(o.vendors!);
  }
  buildCounterListVendorsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed4023() {
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

void checkUnnamed4023(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed4024() {
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

void checkUnnamed4024(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed4023();
    o.name = 'foo';
    o.response = buildUnnamed4024();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed4023(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed4024(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOperationPerDevice = 0;
api.OperationPerDevice buildOperationPerDevice() {
  var o = api.OperationPerDevice();
  buildCounterOperationPerDevice++;
  if (buildCounterOperationPerDevice < 3) {
    o.claim = buildPartnerClaim();
    o.result = buildPerDeviceStatusInBatch();
    o.unclaim = buildPartnerUnclaim();
    o.updateMetadata = buildUpdateMetadataArguments();
  }
  buildCounterOperationPerDevice--;
  return o;
}

void checkOperationPerDevice(api.OperationPerDevice o) {
  buildCounterOperationPerDevice++;
  if (buildCounterOperationPerDevice < 3) {
    checkPartnerClaim(o.claim! as api.PartnerClaim);
    checkPerDeviceStatusInBatch(o.result! as api.PerDeviceStatusInBatch);
    checkPartnerUnclaim(o.unclaim! as api.PartnerUnclaim);
    checkUpdateMetadataArguments(
        o.updateMetadata! as api.UpdateMetadataArguments);
  }
  buildCounterOperationPerDevice--;
}

core.int buildCounterPartnerClaim = 0;
api.PartnerClaim buildPartnerClaim() {
  var o = api.PartnerClaim();
  buildCounterPartnerClaim++;
  if (buildCounterPartnerClaim < 3) {
    o.customerId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
    o.deviceMetadata = buildDeviceMetadata();
    o.sectionType = 'foo';
  }
  buildCounterPartnerClaim--;
  return o;
}

void checkPartnerClaim(api.PartnerClaim o) {
  buildCounterPartnerClaim++;
  if (buildCounterPartnerClaim < 3) {
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    checkDeviceMetadata(o.deviceMetadata! as api.DeviceMetadata);
    unittest.expect(
      o.sectionType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartnerClaim--;
}

core.int buildCounterPartnerUnclaim = 0;
api.PartnerUnclaim buildPartnerUnclaim() {
  var o = api.PartnerUnclaim();
  buildCounterPartnerUnclaim++;
  if (buildCounterPartnerUnclaim < 3) {
    o.deviceId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
    o.sectionType = 'foo';
    o.vacationModeDays = 42;
    o.vacationModeExpireTime = 'foo';
  }
  buildCounterPartnerUnclaim--;
  return o;
}

void checkPartnerUnclaim(api.PartnerUnclaim o) {
  buildCounterPartnerUnclaim++;
  if (buildCounterPartnerUnclaim < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    unittest.expect(
      o.sectionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vacationModeDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.vacationModeExpireTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartnerUnclaim--;
}

core.int buildCounterPerDeviceStatusInBatch = 0;
api.PerDeviceStatusInBatch buildPerDeviceStatusInBatch() {
  var o = api.PerDeviceStatusInBatch();
  buildCounterPerDeviceStatusInBatch++;
  if (buildCounterPerDeviceStatusInBatch < 3) {
    o.deviceId = 'foo';
    o.errorIdentifier = 'foo';
    o.errorMessage = 'foo';
    o.status = 'foo';
  }
  buildCounterPerDeviceStatusInBatch--;
  return o;
}

void checkPerDeviceStatusInBatch(api.PerDeviceStatusInBatch o) {
  buildCounterPerDeviceStatusInBatch++;
  if (buildCounterPerDeviceStatusInBatch < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorIdentifier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorMessage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterPerDeviceStatusInBatch--;
}

core.Map<core.String, core.Object> buildUnnamed4025() {
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

void checkUnnamed4025(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed4026() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed4025());
  o.add(buildUnnamed4025());
  return o;
}

void checkUnnamed4026(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed4025(o[0]);
  checkUnnamed4025(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed4026();
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
    checkUnnamed4026(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterUnclaimDeviceRequest = 0;
api.UnclaimDeviceRequest buildUnclaimDeviceRequest() {
  var o = api.UnclaimDeviceRequest();
  buildCounterUnclaimDeviceRequest++;
  if (buildCounterUnclaimDeviceRequest < 3) {
    o.deviceId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
    o.sectionType = 'foo';
    o.vacationModeDays = 42;
    o.vacationModeExpireTime = 'foo';
  }
  buildCounterUnclaimDeviceRequest--;
  return o;
}

void checkUnclaimDeviceRequest(api.UnclaimDeviceRequest o) {
  buildCounterUnclaimDeviceRequest++;
  if (buildCounterUnclaimDeviceRequest < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    unittest.expect(
      o.sectionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vacationModeDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.vacationModeExpireTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterUnclaimDeviceRequest--;
}

core.List<api.PartnerUnclaim> buildUnnamed4027() {
  var o = <api.PartnerUnclaim>[];
  o.add(buildPartnerUnclaim());
  o.add(buildPartnerUnclaim());
  return o;
}

void checkUnnamed4027(core.List<api.PartnerUnclaim> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPartnerUnclaim(o[0] as api.PartnerUnclaim);
  checkPartnerUnclaim(o[1] as api.PartnerUnclaim);
}

core.int buildCounterUnclaimDevicesRequest = 0;
api.UnclaimDevicesRequest buildUnclaimDevicesRequest() {
  var o = api.UnclaimDevicesRequest();
  buildCounterUnclaimDevicesRequest++;
  if (buildCounterUnclaimDevicesRequest < 3) {
    o.unclaims = buildUnnamed4027();
  }
  buildCounterUnclaimDevicesRequest--;
  return o;
}

void checkUnclaimDevicesRequest(api.UnclaimDevicesRequest o) {
  buildCounterUnclaimDevicesRequest++;
  if (buildCounterUnclaimDevicesRequest < 3) {
    checkUnnamed4027(o.unclaims!);
  }
  buildCounterUnclaimDevicesRequest--;
}

core.List<api.UpdateMetadataArguments> buildUnnamed4028() {
  var o = <api.UpdateMetadataArguments>[];
  o.add(buildUpdateMetadataArguments());
  o.add(buildUpdateMetadataArguments());
  return o;
}

void checkUnnamed4028(core.List<api.UpdateMetadataArguments> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUpdateMetadataArguments(o[0] as api.UpdateMetadataArguments);
  checkUpdateMetadataArguments(o[1] as api.UpdateMetadataArguments);
}

core.int buildCounterUpdateDeviceMetadataInBatchRequest = 0;
api.UpdateDeviceMetadataInBatchRequest
    buildUpdateDeviceMetadataInBatchRequest() {
  var o = api.UpdateDeviceMetadataInBatchRequest();
  buildCounterUpdateDeviceMetadataInBatchRequest++;
  if (buildCounterUpdateDeviceMetadataInBatchRequest < 3) {
    o.updates = buildUnnamed4028();
  }
  buildCounterUpdateDeviceMetadataInBatchRequest--;
  return o;
}

void checkUpdateDeviceMetadataInBatchRequest(
    api.UpdateDeviceMetadataInBatchRequest o) {
  buildCounterUpdateDeviceMetadataInBatchRequest++;
  if (buildCounterUpdateDeviceMetadataInBatchRequest < 3) {
    checkUnnamed4028(o.updates!);
  }
  buildCounterUpdateDeviceMetadataInBatchRequest--;
}

core.int buildCounterUpdateDeviceMetadataRequest = 0;
api.UpdateDeviceMetadataRequest buildUpdateDeviceMetadataRequest() {
  var o = api.UpdateDeviceMetadataRequest();
  buildCounterUpdateDeviceMetadataRequest++;
  if (buildCounterUpdateDeviceMetadataRequest < 3) {
    o.deviceMetadata = buildDeviceMetadata();
  }
  buildCounterUpdateDeviceMetadataRequest--;
  return o;
}

void checkUpdateDeviceMetadataRequest(api.UpdateDeviceMetadataRequest o) {
  buildCounterUpdateDeviceMetadataRequest++;
  if (buildCounterUpdateDeviceMetadataRequest < 3) {
    checkDeviceMetadata(o.deviceMetadata! as api.DeviceMetadata);
  }
  buildCounterUpdateDeviceMetadataRequest--;
}

core.int buildCounterUpdateMetadataArguments = 0;
api.UpdateMetadataArguments buildUpdateMetadataArguments() {
  var o = api.UpdateMetadataArguments();
  buildCounterUpdateMetadataArguments++;
  if (buildCounterUpdateMetadataArguments < 3) {
    o.deviceId = 'foo';
    o.deviceIdentifier = buildDeviceIdentifier();
    o.deviceMetadata = buildDeviceMetadata();
  }
  buildCounterUpdateMetadataArguments--;
  return o;
}

void checkUpdateMetadataArguments(api.UpdateMetadataArguments o) {
  buildCounterUpdateMetadataArguments++;
  if (buildCounterUpdateMetadataArguments < 3) {
    unittest.expect(
      o.deviceId!,
      unittest.equals('foo'),
    );
    checkDeviceIdentifier(o.deviceIdentifier! as api.DeviceIdentifier);
    checkDeviceMetadata(o.deviceMetadata! as api.DeviceMetadata);
  }
  buildCounterUpdateMetadataArguments--;
}

void main() {
  unittest.group('obj-schema-ClaimDeviceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClaimDeviceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClaimDeviceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClaimDeviceRequest(od as api.ClaimDeviceRequest);
    });
  });

  unittest.group('obj-schema-ClaimDeviceResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClaimDeviceResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClaimDeviceResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClaimDeviceResponse(od as api.ClaimDeviceResponse);
    });
  });

  unittest.group('obj-schema-ClaimDevicesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClaimDevicesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClaimDevicesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClaimDevicesRequest(od as api.ClaimDevicesRequest);
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

  unittest.group('obj-schema-Configuration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Configuration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConfiguration(od as api.Configuration);
    });
  });

  unittest.group('obj-schema-CreateCustomerRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateCustomerRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateCustomerRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateCustomerRequest(od as api.CreateCustomerRequest);
    });
  });

  unittest.group('obj-schema-CustomerApplyConfigurationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerApplyConfigurationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerApplyConfigurationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerApplyConfigurationRequest(
          od as api.CustomerApplyConfigurationRequest);
    });
  });

  unittest.group('obj-schema-CustomerListConfigurationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerListConfigurationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerListConfigurationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerListConfigurationsResponse(
          od as api.CustomerListConfigurationsResponse);
    });
  });

  unittest.group('obj-schema-CustomerListCustomersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerListCustomersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerListCustomersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerListCustomersResponse(
          od as api.CustomerListCustomersResponse);
    });
  });

  unittest.group('obj-schema-CustomerListDevicesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerListDevicesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerListDevicesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerListDevicesResponse(od as api.CustomerListDevicesResponse);
    });
  });

  unittest.group('obj-schema-CustomerListDpcsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerListDpcsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerListDpcsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerListDpcsResponse(od as api.CustomerListDpcsResponse);
    });
  });

  unittest.group('obj-schema-CustomerRemoveConfigurationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerRemoveConfigurationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerRemoveConfigurationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerRemoveConfigurationRequest(
          od as api.CustomerRemoveConfigurationRequest);
    });
  });

  unittest.group('obj-schema-CustomerUnclaimDeviceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomerUnclaimDeviceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomerUnclaimDeviceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomerUnclaimDeviceRequest(od as api.CustomerUnclaimDeviceRequest);
    });
  });

  unittest.group('obj-schema-Device', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Device.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDevice(od as api.Device);
    });
  });

  unittest.group('obj-schema-DeviceClaim', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceClaim();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceClaim.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceClaim(od as api.DeviceClaim);
    });
  });

  unittest.group('obj-schema-DeviceIdentifier', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceIdentifier();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceIdentifier.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceIdentifier(od as api.DeviceIdentifier);
    });
  });

  unittest.group('obj-schema-DeviceMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceMetadata(od as api.DeviceMetadata);
    });
  });

  unittest.group('obj-schema-DeviceReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceReference(od as api.DeviceReference);
    });
  });

  unittest.group('obj-schema-DevicesLongRunningOperationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDevicesLongRunningOperationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DevicesLongRunningOperationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDevicesLongRunningOperationMetadata(
          od as api.DevicesLongRunningOperationMetadata);
    });
  });

  unittest.group('obj-schema-DevicesLongRunningOperationResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDevicesLongRunningOperationResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DevicesLongRunningOperationResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDevicesLongRunningOperationResponse(
          od as api.DevicesLongRunningOperationResponse);
    });
  });

  unittest.group('obj-schema-Dpc', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDpc();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Dpc.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDpc(od as api.Dpc);
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

  unittest.group('obj-schema-FindDevicesByDeviceIdentifierRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindDevicesByDeviceIdentifierRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindDevicesByDeviceIdentifierRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindDevicesByDeviceIdentifierRequest(
          od as api.FindDevicesByDeviceIdentifierRequest);
    });
  });

  unittest.group('obj-schema-FindDevicesByDeviceIdentifierResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindDevicesByDeviceIdentifierResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindDevicesByDeviceIdentifierResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindDevicesByDeviceIdentifierResponse(
          od as api.FindDevicesByDeviceIdentifierResponse);
    });
  });

  unittest.group('obj-schema-FindDevicesByOwnerRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindDevicesByOwnerRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindDevicesByOwnerRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindDevicesByOwnerRequest(od as api.FindDevicesByOwnerRequest);
    });
  });

  unittest.group('obj-schema-FindDevicesByOwnerResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFindDevicesByOwnerResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FindDevicesByOwnerResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFindDevicesByOwnerResponse(od as api.FindDevicesByOwnerResponse);
    });
  });

  unittest.group('obj-schema-ListCustomersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCustomersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCustomersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCustomersResponse(od as api.ListCustomersResponse);
    });
  });

  unittest.group('obj-schema-ListVendorCustomersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListVendorCustomersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListVendorCustomersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListVendorCustomersResponse(od as api.ListVendorCustomersResponse);
    });
  });

  unittest.group('obj-schema-ListVendorsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListVendorsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListVendorsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListVendorsResponse(od as api.ListVendorsResponse);
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

  unittest.group('obj-schema-OperationPerDevice', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperationPerDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperationPerDevice.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperationPerDevice(od as api.OperationPerDevice);
    });
  });

  unittest.group('obj-schema-PartnerClaim', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerClaim();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerClaim.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerClaim(od as api.PartnerClaim);
    });
  });

  unittest.group('obj-schema-PartnerUnclaim', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerUnclaim();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerUnclaim.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerUnclaim(od as api.PartnerUnclaim);
    });
  });

  unittest.group('obj-schema-PerDeviceStatusInBatch', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerDeviceStatusInBatch();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PerDeviceStatusInBatch.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPerDeviceStatusInBatch(od as api.PerDeviceStatusInBatch);
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

  unittest.group('obj-schema-UnclaimDeviceRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnclaimDeviceRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnclaimDeviceRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnclaimDeviceRequest(od as api.UnclaimDeviceRequest);
    });
  });

  unittest.group('obj-schema-UnclaimDevicesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUnclaimDevicesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UnclaimDevicesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUnclaimDevicesRequest(od as api.UnclaimDevicesRequest);
    });
  });

  unittest.group('obj-schema-UpdateDeviceMetadataInBatchRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDeviceMetadataInBatchRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDeviceMetadataInBatchRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDeviceMetadataInBatchRequest(
          od as api.UpdateDeviceMetadataInBatchRequest);
    });
  });

  unittest.group('obj-schema-UpdateDeviceMetadataRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateDeviceMetadataRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateDeviceMetadataRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateDeviceMetadataRequest(od as api.UpdateDeviceMetadataRequest);
    });
  });

  unittest.group('obj-schema-UpdateMetadataArguments', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateMetadataArguments();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateMetadataArguments.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateMetadataArguments(od as api.UpdateMetadataArguments);
    });
  });

  unittest.group('resource-CustomersResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers;
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
          unittest.equals("v1/customers"),
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
        var resp = convert.json.encode(buildCustomerListCustomersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCustomerListCustomersResponse(
          response as api.CustomerListCustomersResponse);
    });
  });

  unittest.group('resource-CustomersConfigurationsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.AndroidProvisioningPartnerApi(mock).customers.configurations;
      var arg_request = buildConfiguration();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Configuration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConfiguration(obj as api.Configuration);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkConfiguration(response as api.Configuration);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.AndroidProvisioningPartnerApi(mock).customers.configurations;
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.AndroidProvisioningPartnerApi(mock).customers.configurations;
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
        var resp = convert.json.encode(buildConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkConfiguration(response as api.Configuration);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.AndroidProvisioningPartnerApi(mock).customers.configurations;
      var arg_parent = 'foo';
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
        var resp =
            convert.json.encode(buildCustomerListConfigurationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkCustomerListConfigurationsResponse(
          response as api.CustomerListConfigurationsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res =
          api.AndroidProvisioningPartnerApi(mock).customers.configurations;
      var arg_request = buildConfiguration();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Configuration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkConfiguration(obj as api.Configuration);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkConfiguration(response as api.Configuration);
    });
  });

  unittest.group('resource-CustomersDevicesResource', () {
    unittest.test('method--applyConfiguration', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers.devices;
      var arg_request = buildCustomerApplyConfigurationRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomerApplyConfigurationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomerApplyConfigurationRequest(
            obj as api.CustomerApplyConfigurationRequest);

        var path = (req.url).path;
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
      final response = await res.applyConfiguration(arg_request, arg_parent,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers.devices;
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
        var resp = convert.json.encode(buildDevice());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkDevice(response as api.Device);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers.devices;
      var arg_parent = 'foo';
      var arg_pageSize = 'foo';
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
          queryMap["pageSize"]!.first,
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
        var resp = convert.json.encode(buildCustomerListDevicesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCustomerListDevicesResponse(
          response as api.CustomerListDevicesResponse);
    });

    unittest.test('method--removeConfiguration', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers.devices;
      var arg_request = buildCustomerRemoveConfigurationRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomerRemoveConfigurationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomerRemoveConfigurationRequest(
            obj as api.CustomerRemoveConfigurationRequest);

        var path = (req.url).path;
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
      final response = await res.removeConfiguration(arg_request, arg_parent,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--unclaim', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers.devices;
      var arg_request = buildCustomerUnclaimDeviceRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CustomerUnclaimDeviceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCustomerUnclaimDeviceRequest(
            obj as api.CustomerUnclaimDeviceRequest);

        var path = (req.url).path;
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
          await res.unclaim(arg_request, arg_parent, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });
  });

  unittest.group('resource-CustomersDpcsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).customers.dpcs;
      var arg_parent = 'foo';
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
        var resp = convert.json.encode(buildCustomerListDpcsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent, $fields: arg_$fields);
      checkCustomerListDpcsResponse(response as api.CustomerListDpcsResponse);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).operations;
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

  unittest.group('resource-PartnersCustomersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.customers;
      var arg_request = buildCreateCustomerRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateCustomerRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateCustomerRequest(obj as api.CreateCustomerRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildCompany());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkCompany(response as api.Company);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.customers;
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/partners/"),
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
        var resp = convert.json.encode(buildListCustomersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_partnerId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCustomersResponse(response as api.ListCustomersResponse);
    });
  });

  unittest.group('resource-PartnersDevicesResource', () {
    unittest.test('method--claim', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildClaimDeviceRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClaimDeviceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClaimDeviceRequest(obj as api.ClaimDeviceRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
        var resp = convert.json.encode(buildClaimDeviceResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.claim(arg_request, arg_partnerId, $fields: arg_$fields);
      checkClaimDeviceResponse(response as api.ClaimDeviceResponse);
    });

    unittest.test('method--claimAsync', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildClaimDevicesRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ClaimDevicesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkClaimDevicesRequest(obj as api.ClaimDevicesRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
      final response = await res.claimAsync(arg_request, arg_partnerId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--findByIdentifier', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildFindDevicesByDeviceIdentifierRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FindDevicesByDeviceIdentifierRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFindDevicesByDeviceIdentifierRequest(
            obj as api.FindDevicesByDeviceIdentifierRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
        var resp =
            convert.json.encode(buildFindDevicesByDeviceIdentifierResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.findByIdentifier(arg_request, arg_partnerId,
          $fields: arg_$fields);
      checkFindDevicesByDeviceIdentifierResponse(
          response as api.FindDevicesByDeviceIdentifierResponse);
    });

    unittest.test('method--findByOwner', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildFindDevicesByOwnerRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FindDevicesByOwnerRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFindDevicesByOwnerRequest(obj as api.FindDevicesByOwnerRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
        var resp = convert.json.encode(buildFindDevicesByOwnerResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.findByOwner(arg_request, arg_partnerId,
          $fields: arg_$fields);
      checkFindDevicesByOwnerResponse(
          response as api.FindDevicesByOwnerResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
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
        var resp = convert.json.encode(buildDevice());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkDevice(response as api.Device);
    });

    unittest.test('method--metadata', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildUpdateDeviceMetadataRequest();
      var arg_metadataOwnerId = 'foo';
      var arg_deviceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateDeviceMetadataRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateDeviceMetadataRequest(
            obj as api.UpdateDeviceMetadataRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
        var resp = convert.json.encode(buildDeviceMetadata());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.metadata(
          arg_request, arg_metadataOwnerId, arg_deviceId,
          $fields: arg_$fields);
      checkDeviceMetadata(response as api.DeviceMetadata);
    });

    unittest.test('method--unclaim', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildUnclaimDeviceRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UnclaimDeviceRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUnclaimDeviceRequest(obj as api.UnclaimDeviceRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.unclaim(arg_request, arg_partnerId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--unclaimAsync', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildUnclaimDevicesRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UnclaimDevicesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUnclaimDevicesRequest(obj as api.UnclaimDevicesRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
      final response = await res.unclaimAsync(arg_request, arg_partnerId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--updateMetadataAsync', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.devices;
      var arg_request = buildUpdateDeviceMetadataInBatchRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateDeviceMetadataInBatchRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateDeviceMetadataInBatchRequest(
            obj as api.UpdateDeviceMetadataInBatchRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/partners/"),
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
      final response = await res.updateMetadataAsync(arg_request, arg_partnerId,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-PartnersVendorsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AndroidProvisioningPartnerApi(mock).partners.vendors;
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
        var resp = convert.json.encode(buildListVendorsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListVendorsResponse(response as api.ListVendorsResponse);
    });
  });

  unittest.group('resource-PartnersVendorsCustomersResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.AndroidProvisioningPartnerApi(mock).partners.vendors.customers;
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
        var resp = convert.json.encode(buildListVendorCustomersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListVendorCustomersResponse(
          response as api.ListVendorCustomersResponse);
    });
  });
}
