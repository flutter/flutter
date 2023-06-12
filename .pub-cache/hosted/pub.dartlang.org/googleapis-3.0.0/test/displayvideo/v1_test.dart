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

import 'package:googleapis/displayvideo/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterActivateManualTriggerRequest = 0;
api.ActivateManualTriggerRequest buildActivateManualTriggerRequest() {
  var o = api.ActivateManualTriggerRequest();
  buildCounterActivateManualTriggerRequest++;
  if (buildCounterActivateManualTriggerRequest < 3) {}
  buildCounterActivateManualTriggerRequest--;
  return o;
}

void checkActivateManualTriggerRequest(api.ActivateManualTriggerRequest o) {
  buildCounterActivateManualTriggerRequest++;
  if (buildCounterActivateManualTriggerRequest < 3) {}
  buildCounterActivateManualTriggerRequest--;
}

core.int buildCounterActiveViewVideoViewabilityMetricConfig = 0;
api.ActiveViewVideoViewabilityMetricConfig
    buildActiveViewVideoViewabilityMetricConfig() {
  var o = api.ActiveViewVideoViewabilityMetricConfig();
  buildCounterActiveViewVideoViewabilityMetricConfig++;
  if (buildCounterActiveViewVideoViewabilityMetricConfig < 3) {
    o.displayName = 'foo';
    o.minimumDuration = 'foo';
    o.minimumQuartile = 'foo';
    o.minimumViewability = 'foo';
    o.minimumVolume = 'foo';
  }
  buildCounterActiveViewVideoViewabilityMetricConfig--;
  return o;
}

void checkActiveViewVideoViewabilityMetricConfig(
    api.ActiveViewVideoViewabilityMetricConfig o) {
  buildCounterActiveViewVideoViewabilityMetricConfig++;
  if (buildCounterActiveViewVideoViewabilityMetricConfig < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumQuartile!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumViewability!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumVolume!,
      unittest.equals('foo'),
    );
  }
  buildCounterActiveViewVideoViewabilityMetricConfig--;
}

core.List<core.String> buildUnnamed5428() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5428(core.List<core.String> o) {
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

core.int buildCounterAdloox = 0;
api.Adloox buildAdloox() {
  var o = api.Adloox();
  buildCounterAdloox++;
  if (buildCounterAdloox < 3) {
    o.excludedAdlooxCategories = buildUnnamed5428();
  }
  buildCounterAdloox--;
  return o;
}

void checkAdloox(api.Adloox o) {
  buildCounterAdloox++;
  if (buildCounterAdloox < 3) {
    checkUnnamed5428(o.excludedAdlooxCategories!);
  }
  buildCounterAdloox--;
}

core.int buildCounterAdvertiser = 0;
api.Advertiser buildAdvertiser() {
  var o = api.Advertiser();
  buildCounterAdvertiser++;
  if (buildCounterAdvertiser < 3) {
    o.adServerConfig = buildAdvertiserAdServerConfig();
    o.advertiserId = 'foo';
    o.creativeConfig = buildAdvertiserCreativeConfig();
    o.dataAccessConfig = buildAdvertiserDataAccessConfig();
    o.displayName = 'foo';
    o.entityStatus = 'foo';
    o.generalConfig = buildAdvertiserGeneralConfig();
    o.integrationDetails = buildIntegrationDetails();
    o.name = 'foo';
    o.partnerId = 'foo';
    o.prismaEnabled = true;
    o.servingConfig = buildAdvertiserTargetingConfig();
    o.updateTime = 'foo';
  }
  buildCounterAdvertiser--;
  return o;
}

void checkAdvertiser(api.Advertiser o) {
  buildCounterAdvertiser++;
  if (buildCounterAdvertiser < 3) {
    checkAdvertiserAdServerConfig(
        o.adServerConfig! as api.AdvertiserAdServerConfig);
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkAdvertiserCreativeConfig(
        o.creativeConfig! as api.AdvertiserCreativeConfig);
    checkAdvertiserDataAccessConfig(
        o.dataAccessConfig! as api.AdvertiserDataAccessConfig);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    checkAdvertiserGeneralConfig(
        o.generalConfig! as api.AdvertiserGeneralConfig);
    checkIntegrationDetails(o.integrationDetails! as api.IntegrationDetails);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.prismaEnabled!, unittest.isTrue);
    checkAdvertiserTargetingConfig(
        o.servingConfig! as api.AdvertiserTargetingConfig);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdvertiser--;
}

core.int buildCounterAdvertiserAdServerConfig = 0;
api.AdvertiserAdServerConfig buildAdvertiserAdServerConfig() {
  var o = api.AdvertiserAdServerConfig();
  buildCounterAdvertiserAdServerConfig++;
  if (buildCounterAdvertiserAdServerConfig < 3) {
    o.cmHybridConfig = buildCmHybridConfig();
    o.thirdPartyOnlyConfig = buildThirdPartyOnlyConfig();
  }
  buildCounterAdvertiserAdServerConfig--;
  return o;
}

void checkAdvertiserAdServerConfig(api.AdvertiserAdServerConfig o) {
  buildCounterAdvertiserAdServerConfig++;
  if (buildCounterAdvertiserAdServerConfig < 3) {
    checkCmHybridConfig(o.cmHybridConfig! as api.CmHybridConfig);
    checkThirdPartyOnlyConfig(
        o.thirdPartyOnlyConfig! as api.ThirdPartyOnlyConfig);
  }
  buildCounterAdvertiserAdServerConfig--;
}

core.int buildCounterAdvertiserCreativeConfig = 0;
api.AdvertiserCreativeConfig buildAdvertiserCreativeConfig() {
  var o = api.AdvertiserCreativeConfig();
  buildCounterAdvertiserCreativeConfig++;
  if (buildCounterAdvertiserCreativeConfig < 3) {
    o.dynamicCreativeEnabled = true;
    o.iasClientId = 'foo';
    o.obaComplianceDisabled = true;
    o.videoCreativeDataSharingAuthorized = true;
  }
  buildCounterAdvertiserCreativeConfig--;
  return o;
}

void checkAdvertiserCreativeConfig(api.AdvertiserCreativeConfig o) {
  buildCounterAdvertiserCreativeConfig++;
  if (buildCounterAdvertiserCreativeConfig < 3) {
    unittest.expect(o.dynamicCreativeEnabled!, unittest.isTrue);
    unittest.expect(
      o.iasClientId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.obaComplianceDisabled!, unittest.isTrue);
    unittest.expect(o.videoCreativeDataSharingAuthorized!, unittest.isTrue);
  }
  buildCounterAdvertiserCreativeConfig--;
}

core.int buildCounterAdvertiserDataAccessConfig = 0;
api.AdvertiserDataAccessConfig buildAdvertiserDataAccessConfig() {
  var o = api.AdvertiserDataAccessConfig();
  buildCounterAdvertiserDataAccessConfig++;
  if (buildCounterAdvertiserDataAccessConfig < 3) {
    o.sdfConfig = buildAdvertiserSdfConfig();
  }
  buildCounterAdvertiserDataAccessConfig--;
  return o;
}

void checkAdvertiserDataAccessConfig(api.AdvertiserDataAccessConfig o) {
  buildCounterAdvertiserDataAccessConfig++;
  if (buildCounterAdvertiserDataAccessConfig < 3) {
    checkAdvertiserSdfConfig(o.sdfConfig! as api.AdvertiserSdfConfig);
  }
  buildCounterAdvertiserDataAccessConfig--;
}

core.int buildCounterAdvertiserGeneralConfig = 0;
api.AdvertiserGeneralConfig buildAdvertiserGeneralConfig() {
  var o = api.AdvertiserGeneralConfig();
  buildCounterAdvertiserGeneralConfig++;
  if (buildCounterAdvertiserGeneralConfig < 3) {
    o.currencyCode = 'foo';
    o.domainUrl = 'foo';
    o.timeZone = 'foo';
  }
  buildCounterAdvertiserGeneralConfig--;
  return o;
}

void checkAdvertiserGeneralConfig(api.AdvertiserGeneralConfig o) {
  buildCounterAdvertiserGeneralConfig++;
  if (buildCounterAdvertiserGeneralConfig < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.domainUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdvertiserGeneralConfig--;
}

core.int buildCounterAdvertiserSdfConfig = 0;
api.AdvertiserSdfConfig buildAdvertiserSdfConfig() {
  var o = api.AdvertiserSdfConfig();
  buildCounterAdvertiserSdfConfig++;
  if (buildCounterAdvertiserSdfConfig < 3) {
    o.overridePartnerSdfConfig = true;
    o.sdfConfig = buildSdfConfig();
  }
  buildCounterAdvertiserSdfConfig--;
  return o;
}

void checkAdvertiserSdfConfig(api.AdvertiserSdfConfig o) {
  buildCounterAdvertiserSdfConfig++;
  if (buildCounterAdvertiserSdfConfig < 3) {
    unittest.expect(o.overridePartnerSdfConfig!, unittest.isTrue);
    checkSdfConfig(o.sdfConfig! as api.SdfConfig);
  }
  buildCounterAdvertiserSdfConfig--;
}

core.int buildCounterAdvertiserTargetingConfig = 0;
api.AdvertiserTargetingConfig buildAdvertiserTargetingConfig() {
  var o = api.AdvertiserTargetingConfig();
  buildCounterAdvertiserTargetingConfig++;
  if (buildCounterAdvertiserTargetingConfig < 3) {
    o.exemptTvFromViewabilityTargeting = true;
  }
  buildCounterAdvertiserTargetingConfig--;
  return o;
}

void checkAdvertiserTargetingConfig(api.AdvertiserTargetingConfig o) {
  buildCounterAdvertiserTargetingConfig++;
  if (buildCounterAdvertiserTargetingConfig < 3) {
    unittest.expect(o.exemptTvFromViewabilityTargeting!, unittest.isTrue);
  }
  buildCounterAdvertiserTargetingConfig--;
}

core.int buildCounterAgeRangeAssignedTargetingOptionDetails = 0;
api.AgeRangeAssignedTargetingOptionDetails
    buildAgeRangeAssignedTargetingOptionDetails() {
  var o = api.AgeRangeAssignedTargetingOptionDetails();
  buildCounterAgeRangeAssignedTargetingOptionDetails++;
  if (buildCounterAgeRangeAssignedTargetingOptionDetails < 3) {
    o.ageRange = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterAgeRangeAssignedTargetingOptionDetails--;
  return o;
}

void checkAgeRangeAssignedTargetingOptionDetails(
    api.AgeRangeAssignedTargetingOptionDetails o) {
  buildCounterAgeRangeAssignedTargetingOptionDetails++;
  if (buildCounterAgeRangeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.ageRange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAgeRangeAssignedTargetingOptionDetails--;
}

core.int buildCounterAgeRangeTargetingOptionDetails = 0;
api.AgeRangeTargetingOptionDetails buildAgeRangeTargetingOptionDetails() {
  var o = api.AgeRangeTargetingOptionDetails();
  buildCounterAgeRangeTargetingOptionDetails++;
  if (buildCounterAgeRangeTargetingOptionDetails < 3) {
    o.ageRange = 'foo';
  }
  buildCounterAgeRangeTargetingOptionDetails--;
  return o;
}

void checkAgeRangeTargetingOptionDetails(api.AgeRangeTargetingOptionDetails o) {
  buildCounterAgeRangeTargetingOptionDetails++;
  if (buildCounterAgeRangeTargetingOptionDetails < 3) {
    unittest.expect(
      o.ageRange!,
      unittest.equals('foo'),
    );
  }
  buildCounterAgeRangeTargetingOptionDetails--;
}

core.int buildCounterAppAssignedTargetingOptionDetails = 0;
api.AppAssignedTargetingOptionDetails buildAppAssignedTargetingOptionDetails() {
  var o = api.AppAssignedTargetingOptionDetails();
  buildCounterAppAssignedTargetingOptionDetails++;
  if (buildCounterAppAssignedTargetingOptionDetails < 3) {
    o.appId = 'foo';
    o.appPlatform = 'foo';
    o.displayName = 'foo';
    o.negative = true;
  }
  buildCounterAppAssignedTargetingOptionDetails--;
  return o;
}

void checkAppAssignedTargetingOptionDetails(
    api.AppAssignedTargetingOptionDetails o) {
  buildCounterAppAssignedTargetingOptionDetails++;
  if (buildCounterAppAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.appId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appPlatform!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
  }
  buildCounterAppAssignedTargetingOptionDetails--;
}

core.int buildCounterAppCategoryAssignedTargetingOptionDetails = 0;
api.AppCategoryAssignedTargetingOptionDetails
    buildAppCategoryAssignedTargetingOptionDetails() {
  var o = api.AppCategoryAssignedTargetingOptionDetails();
  buildCounterAppCategoryAssignedTargetingOptionDetails++;
  if (buildCounterAppCategoryAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterAppCategoryAssignedTargetingOptionDetails--;
  return o;
}

void checkAppCategoryAssignedTargetingOptionDetails(
    api.AppCategoryAssignedTargetingOptionDetails o) {
  buildCounterAppCategoryAssignedTargetingOptionDetails++;
  if (buildCounterAppCategoryAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppCategoryAssignedTargetingOptionDetails--;
}

core.int buildCounterAppCategoryTargetingOptionDetails = 0;
api.AppCategoryTargetingOptionDetails buildAppCategoryTargetingOptionDetails() {
  var o = api.AppCategoryTargetingOptionDetails();
  buildCounterAppCategoryTargetingOptionDetails++;
  if (buildCounterAppCategoryTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterAppCategoryTargetingOptionDetails--;
  return o;
}

void checkAppCategoryTargetingOptionDetails(
    api.AppCategoryTargetingOptionDetails o) {
  buildCounterAppCategoryTargetingOptionDetails++;
  if (buildCounterAppCategoryTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterAppCategoryTargetingOptionDetails--;
}

core.int buildCounterAsset = 0;
api.Asset buildAsset() {
  var o = api.Asset();
  buildCounterAsset++;
  if (buildCounterAsset < 3) {
    o.content = 'foo';
    o.mediaId = 'foo';
  }
  buildCounterAsset--;
  return o;
}

void checkAsset(api.Asset o) {
  buildCounterAsset++;
  if (buildCounterAsset < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mediaId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAsset--;
}

core.int buildCounterAssetAssociation = 0;
api.AssetAssociation buildAssetAssociation() {
  var o = api.AssetAssociation();
  buildCounterAssetAssociation++;
  if (buildCounterAssetAssociation < 3) {
    o.asset = buildAsset();
    o.role = 'foo';
  }
  buildCounterAssetAssociation--;
  return o;
}

void checkAssetAssociation(api.AssetAssociation o) {
  buildCounterAssetAssociation++;
  if (buildCounterAssetAssociation < 3) {
    checkAsset(o.asset! as api.Asset);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterAssetAssociation--;
}

core.int buildCounterAssignedInventorySource = 0;
api.AssignedInventorySource buildAssignedInventorySource() {
  var o = api.AssignedInventorySource();
  buildCounterAssignedInventorySource++;
  if (buildCounterAssignedInventorySource < 3) {
    o.assignedInventorySourceId = 'foo';
    o.inventorySourceId = 'foo';
    o.name = 'foo';
  }
  buildCounterAssignedInventorySource--;
  return o;
}

void checkAssignedInventorySource(api.AssignedInventorySource o) {
  buildCounterAssignedInventorySource++;
  if (buildCounterAssignedInventorySource < 3) {
    unittest.expect(
      o.assignedInventorySourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inventorySourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterAssignedInventorySource--;
}

core.int buildCounterAssignedLocation = 0;
api.AssignedLocation buildAssignedLocation() {
  var o = api.AssignedLocation();
  buildCounterAssignedLocation++;
  if (buildCounterAssignedLocation < 3) {
    o.assignedLocationId = 'foo';
    o.name = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterAssignedLocation--;
  return o;
}

void checkAssignedLocation(api.AssignedLocation o) {
  buildCounterAssignedLocation++;
  if (buildCounterAssignedLocation < 3) {
    unittest.expect(
      o.assignedLocationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAssignedLocation--;
}

core.int buildCounterAssignedTargetingOption = 0;
api.AssignedTargetingOption buildAssignedTargetingOption() {
  var o = api.AssignedTargetingOption();
  buildCounterAssignedTargetingOption++;
  if (buildCounterAssignedTargetingOption < 3) {
    o.ageRangeDetails = buildAgeRangeAssignedTargetingOptionDetails();
    o.appCategoryDetails = buildAppCategoryAssignedTargetingOptionDetails();
    o.appDetails = buildAppAssignedTargetingOptionDetails();
    o.assignedTargetingOptionId = 'foo';
    o.audienceGroupDetails = buildAudienceGroupAssignedTargetingOptionDetails();
    o.authorizedSellerStatusDetails =
        buildAuthorizedSellerStatusAssignedTargetingOptionDetails();
    o.browserDetails = buildBrowserAssignedTargetingOptionDetails();
    o.carrierAndIspDetails = buildCarrierAndIspAssignedTargetingOptionDetails();
    o.categoryDetails = buildCategoryAssignedTargetingOptionDetails();
    o.channelDetails = buildChannelAssignedTargetingOptionDetails();
    o.contentInstreamPositionDetails =
        buildContentInstreamPositionAssignedTargetingOptionDetails();
    o.contentOutstreamPositionDetails =
        buildContentOutstreamPositionAssignedTargetingOptionDetails();
    o.dayAndTimeDetails = buildDayAndTimeAssignedTargetingOptionDetails();
    o.deviceMakeModelDetails =
        buildDeviceMakeModelAssignedTargetingOptionDetails();
    o.deviceTypeDetails = buildDeviceTypeAssignedTargetingOptionDetails();
    o.digitalContentLabelExclusionDetails =
        buildDigitalContentLabelAssignedTargetingOptionDetails();
    o.environmentDetails = buildEnvironmentAssignedTargetingOptionDetails();
    o.exchangeDetails = buildExchangeAssignedTargetingOptionDetails();
    o.genderDetails = buildGenderAssignedTargetingOptionDetails();
    o.geoRegionDetails = buildGeoRegionAssignedTargetingOptionDetails();
    o.householdIncomeDetails =
        buildHouseholdIncomeAssignedTargetingOptionDetails();
    o.inheritance = 'foo';
    o.inventorySourceDetails =
        buildInventorySourceAssignedTargetingOptionDetails();
    o.inventorySourceGroupDetails =
        buildInventorySourceGroupAssignedTargetingOptionDetails();
    o.keywordDetails = buildKeywordAssignedTargetingOptionDetails();
    o.languageDetails = buildLanguageAssignedTargetingOptionDetails();
    o.name = 'foo';
    o.nativeContentPositionDetails =
        buildNativeContentPositionAssignedTargetingOptionDetails();
    o.negativeKeywordListDetails =
        buildNegativeKeywordListAssignedTargetingOptionDetails();
    o.onScreenPositionDetails =
        buildOnScreenPositionAssignedTargetingOptionDetails();
    o.operatingSystemDetails =
        buildOperatingSystemAssignedTargetingOptionDetails();
    o.parentalStatusDetails =
        buildParentalStatusAssignedTargetingOptionDetails();
    o.proximityLocationListDetails =
        buildProximityLocationListAssignedTargetingOptionDetails();
    o.regionalLocationListDetails =
        buildRegionalLocationListAssignedTargetingOptionDetails();
    o.sensitiveCategoryExclusionDetails =
        buildSensitiveCategoryAssignedTargetingOptionDetails();
    o.subExchangeDetails = buildSubExchangeAssignedTargetingOptionDetails();
    o.targetingType = 'foo';
    o.thirdPartyVerifierDetails =
        buildThirdPartyVerifierAssignedTargetingOptionDetails();
    o.urlDetails = buildUrlAssignedTargetingOptionDetails();
    o.userRewardedContentDetails =
        buildUserRewardedContentAssignedTargetingOptionDetails();
    o.videoPlayerSizeDetails =
        buildVideoPlayerSizeAssignedTargetingOptionDetails();
    o.viewabilityDetails = buildViewabilityAssignedTargetingOptionDetails();
  }
  buildCounterAssignedTargetingOption--;
  return o;
}

void checkAssignedTargetingOption(api.AssignedTargetingOption o) {
  buildCounterAssignedTargetingOption++;
  if (buildCounterAssignedTargetingOption < 3) {
    checkAgeRangeAssignedTargetingOptionDetails(
        o.ageRangeDetails! as api.AgeRangeAssignedTargetingOptionDetails);
    checkAppCategoryAssignedTargetingOptionDetails(
        o.appCategoryDetails! as api.AppCategoryAssignedTargetingOptionDetails);
    checkAppAssignedTargetingOptionDetails(
        o.appDetails! as api.AppAssignedTargetingOptionDetails);
    unittest.expect(
      o.assignedTargetingOptionId!,
      unittest.equals('foo'),
    );
    checkAudienceGroupAssignedTargetingOptionDetails(o.audienceGroupDetails!
        as api.AudienceGroupAssignedTargetingOptionDetails);
    checkAuthorizedSellerStatusAssignedTargetingOptionDetails(
        o.authorizedSellerStatusDetails!
            as api.AuthorizedSellerStatusAssignedTargetingOptionDetails);
    checkBrowserAssignedTargetingOptionDetails(
        o.browserDetails! as api.BrowserAssignedTargetingOptionDetails);
    checkCarrierAndIspAssignedTargetingOptionDetails(o.carrierAndIspDetails!
        as api.CarrierAndIspAssignedTargetingOptionDetails);
    checkCategoryAssignedTargetingOptionDetails(
        o.categoryDetails! as api.CategoryAssignedTargetingOptionDetails);
    checkChannelAssignedTargetingOptionDetails(
        o.channelDetails! as api.ChannelAssignedTargetingOptionDetails);
    checkContentInstreamPositionAssignedTargetingOptionDetails(
        o.contentInstreamPositionDetails!
            as api.ContentInstreamPositionAssignedTargetingOptionDetails);
    checkContentOutstreamPositionAssignedTargetingOptionDetails(
        o.contentOutstreamPositionDetails!
            as api.ContentOutstreamPositionAssignedTargetingOptionDetails);
    checkDayAndTimeAssignedTargetingOptionDetails(
        o.dayAndTimeDetails! as api.DayAndTimeAssignedTargetingOptionDetails);
    checkDeviceMakeModelAssignedTargetingOptionDetails(o.deviceMakeModelDetails!
        as api.DeviceMakeModelAssignedTargetingOptionDetails);
    checkDeviceTypeAssignedTargetingOptionDetails(
        o.deviceTypeDetails! as api.DeviceTypeAssignedTargetingOptionDetails);
    checkDigitalContentLabelAssignedTargetingOptionDetails(
        o.digitalContentLabelExclusionDetails!
            as api.DigitalContentLabelAssignedTargetingOptionDetails);
    checkEnvironmentAssignedTargetingOptionDetails(
        o.environmentDetails! as api.EnvironmentAssignedTargetingOptionDetails);
    checkExchangeAssignedTargetingOptionDetails(
        o.exchangeDetails! as api.ExchangeAssignedTargetingOptionDetails);
    checkGenderAssignedTargetingOptionDetails(
        o.genderDetails! as api.GenderAssignedTargetingOptionDetails);
    checkGeoRegionAssignedTargetingOptionDetails(
        o.geoRegionDetails! as api.GeoRegionAssignedTargetingOptionDetails);
    checkHouseholdIncomeAssignedTargetingOptionDetails(o.householdIncomeDetails!
        as api.HouseholdIncomeAssignedTargetingOptionDetails);
    unittest.expect(
      o.inheritance!,
      unittest.equals('foo'),
    );
    checkInventorySourceAssignedTargetingOptionDetails(o.inventorySourceDetails!
        as api.InventorySourceAssignedTargetingOptionDetails);
    checkInventorySourceGroupAssignedTargetingOptionDetails(
        o.inventorySourceGroupDetails!
            as api.InventorySourceGroupAssignedTargetingOptionDetails);
    checkKeywordAssignedTargetingOptionDetails(
        o.keywordDetails! as api.KeywordAssignedTargetingOptionDetails);
    checkLanguageAssignedTargetingOptionDetails(
        o.languageDetails! as api.LanguageAssignedTargetingOptionDetails);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkNativeContentPositionAssignedTargetingOptionDetails(
        o.nativeContentPositionDetails!
            as api.NativeContentPositionAssignedTargetingOptionDetails);
    checkNegativeKeywordListAssignedTargetingOptionDetails(
        o.negativeKeywordListDetails!
            as api.NegativeKeywordListAssignedTargetingOptionDetails);
    checkOnScreenPositionAssignedTargetingOptionDetails(
        o.onScreenPositionDetails!
            as api.OnScreenPositionAssignedTargetingOptionDetails);
    checkOperatingSystemAssignedTargetingOptionDetails(o.operatingSystemDetails!
        as api.OperatingSystemAssignedTargetingOptionDetails);
    checkParentalStatusAssignedTargetingOptionDetails(o.parentalStatusDetails!
        as api.ParentalStatusAssignedTargetingOptionDetails);
    checkProximityLocationListAssignedTargetingOptionDetails(
        o.proximityLocationListDetails!
            as api.ProximityLocationListAssignedTargetingOptionDetails);
    checkRegionalLocationListAssignedTargetingOptionDetails(
        o.regionalLocationListDetails!
            as api.RegionalLocationListAssignedTargetingOptionDetails);
    checkSensitiveCategoryAssignedTargetingOptionDetails(
        o.sensitiveCategoryExclusionDetails!
            as api.SensitiveCategoryAssignedTargetingOptionDetails);
    checkSubExchangeAssignedTargetingOptionDetails(
        o.subExchangeDetails! as api.SubExchangeAssignedTargetingOptionDetails);
    unittest.expect(
      o.targetingType!,
      unittest.equals('foo'),
    );
    checkThirdPartyVerifierAssignedTargetingOptionDetails(
        o.thirdPartyVerifierDetails!
            as api.ThirdPartyVerifierAssignedTargetingOptionDetails);
    checkUrlAssignedTargetingOptionDetails(
        o.urlDetails! as api.UrlAssignedTargetingOptionDetails);
    checkUserRewardedContentAssignedTargetingOptionDetails(
        o.userRewardedContentDetails!
            as api.UserRewardedContentAssignedTargetingOptionDetails);
    checkVideoPlayerSizeAssignedTargetingOptionDetails(o.videoPlayerSizeDetails!
        as api.VideoPlayerSizeAssignedTargetingOptionDetails);
    checkViewabilityAssignedTargetingOptionDetails(
        o.viewabilityDetails! as api.ViewabilityAssignedTargetingOptionDetails);
  }
  buildCounterAssignedTargetingOption--;
}

core.int buildCounterAssignedUserRole = 0;
api.AssignedUserRole buildAssignedUserRole() {
  var o = api.AssignedUserRole();
  buildCounterAssignedUserRole++;
  if (buildCounterAssignedUserRole < 3) {
    o.advertiserId = 'foo';
    o.assignedUserRoleId = 'foo';
    o.partnerId = 'foo';
    o.userRole = 'foo';
  }
  buildCounterAssignedUserRole--;
  return o;
}

void checkAssignedUserRole(api.AssignedUserRole o) {
  buildCounterAssignedUserRole++;
  if (buildCounterAssignedUserRole < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.assignedUserRoleId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userRole!,
      unittest.equals('foo'),
    );
  }
  buildCounterAssignedUserRole--;
}

core.List<api.FirstAndThirdPartyAudienceGroup> buildUnnamed5429() {
  var o = <api.FirstAndThirdPartyAudienceGroup>[];
  o.add(buildFirstAndThirdPartyAudienceGroup());
  o.add(buildFirstAndThirdPartyAudienceGroup());
  return o;
}

void checkUnnamed5429(core.List<api.FirstAndThirdPartyAudienceGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFirstAndThirdPartyAudienceGroup(
      o[0] as api.FirstAndThirdPartyAudienceGroup);
  checkFirstAndThirdPartyAudienceGroup(
      o[1] as api.FirstAndThirdPartyAudienceGroup);
}

core.int buildCounterAudienceGroupAssignedTargetingOptionDetails = 0;
api.AudienceGroupAssignedTargetingOptionDetails
    buildAudienceGroupAssignedTargetingOptionDetails() {
  var o = api.AudienceGroupAssignedTargetingOptionDetails();
  buildCounterAudienceGroupAssignedTargetingOptionDetails++;
  if (buildCounterAudienceGroupAssignedTargetingOptionDetails < 3) {
    o.excludedFirstAndThirdPartyAudienceGroup =
        buildFirstAndThirdPartyAudienceGroup();
    o.excludedGoogleAudienceGroup = buildGoogleAudienceGroup();
    o.includedCombinedAudienceGroup = buildCombinedAudienceGroup();
    o.includedCustomListGroup = buildCustomListGroup();
    o.includedFirstAndThirdPartyAudienceGroups = buildUnnamed5429();
    o.includedGoogleAudienceGroup = buildGoogleAudienceGroup();
  }
  buildCounterAudienceGroupAssignedTargetingOptionDetails--;
  return o;
}

void checkAudienceGroupAssignedTargetingOptionDetails(
    api.AudienceGroupAssignedTargetingOptionDetails o) {
  buildCounterAudienceGroupAssignedTargetingOptionDetails++;
  if (buildCounterAudienceGroupAssignedTargetingOptionDetails < 3) {
    checkFirstAndThirdPartyAudienceGroup(
        o.excludedFirstAndThirdPartyAudienceGroup!
            as api.FirstAndThirdPartyAudienceGroup);
    checkGoogleAudienceGroup(
        o.excludedGoogleAudienceGroup! as api.GoogleAudienceGroup);
    checkCombinedAudienceGroup(
        o.includedCombinedAudienceGroup! as api.CombinedAudienceGroup);
    checkCustomListGroup(o.includedCustomListGroup! as api.CustomListGroup);
    checkUnnamed5429(o.includedFirstAndThirdPartyAudienceGroups!);
    checkGoogleAudienceGroup(
        o.includedGoogleAudienceGroup! as api.GoogleAudienceGroup);
  }
  buildCounterAudienceGroupAssignedTargetingOptionDetails--;
}

core.int buildCounterAudioVideoOffset = 0;
api.AudioVideoOffset buildAudioVideoOffset() {
  var o = api.AudioVideoOffset();
  buildCounterAudioVideoOffset++;
  if (buildCounterAudioVideoOffset < 3) {
    o.percentage = 'foo';
    o.seconds = 'foo';
  }
  buildCounterAudioVideoOffset--;
  return o;
}

void checkAudioVideoOffset(api.AudioVideoOffset o) {
  buildCounterAudioVideoOffset++;
  if (buildCounterAudioVideoOffset < 3) {
    unittest.expect(
      o.percentage!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.seconds!,
      unittest.equals('foo'),
    );
  }
  buildCounterAudioVideoOffset--;
}

core.int buildCounterAuditAdvertiserResponse = 0;
api.AuditAdvertiserResponse buildAuditAdvertiserResponse() {
  var o = api.AuditAdvertiserResponse();
  buildCounterAuditAdvertiserResponse++;
  if (buildCounterAuditAdvertiserResponse < 3) {
    o.adGroupCriteriaCount = 'foo';
    o.campaignCriteriaCount = 'foo';
    o.channelsCount = 'foo';
    o.negativeKeywordListsCount = 'foo';
    o.negativelyTargetedChannelsCount = 'foo';
    o.usedCampaignsCount = 'foo';
    o.usedInsertionOrdersCount = 'foo';
    o.usedLineItemsCount = 'foo';
  }
  buildCounterAuditAdvertiserResponse--;
  return o;
}

void checkAuditAdvertiserResponse(api.AuditAdvertiserResponse o) {
  buildCounterAuditAdvertiserResponse++;
  if (buildCounterAuditAdvertiserResponse < 3) {
    unittest.expect(
      o.adGroupCriteriaCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.campaignCriteriaCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelsCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.negativeKeywordListsCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.negativelyTargetedChannelsCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.usedCampaignsCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.usedInsertionOrdersCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.usedLineItemsCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditAdvertiserResponse--;
}

core.int buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails = 0;
api.AuthorizedSellerStatusAssignedTargetingOptionDetails
    buildAuthorizedSellerStatusAssignedTargetingOptionDetails() {
  var o = api.AuthorizedSellerStatusAssignedTargetingOptionDetails();
  buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails++;
  if (buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails < 3) {
    o.authorizedSellerStatus = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails--;
  return o;
}

void checkAuthorizedSellerStatusAssignedTargetingOptionDetails(
    api.AuthorizedSellerStatusAssignedTargetingOptionDetails o) {
  buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails++;
  if (buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.authorizedSellerStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuthorizedSellerStatusAssignedTargetingOptionDetails--;
}

core.int buildCounterAuthorizedSellerStatusTargetingOptionDetails = 0;
api.AuthorizedSellerStatusTargetingOptionDetails
    buildAuthorizedSellerStatusTargetingOptionDetails() {
  var o = api.AuthorizedSellerStatusTargetingOptionDetails();
  buildCounterAuthorizedSellerStatusTargetingOptionDetails++;
  if (buildCounterAuthorizedSellerStatusTargetingOptionDetails < 3) {
    o.authorizedSellerStatus = 'foo';
  }
  buildCounterAuthorizedSellerStatusTargetingOptionDetails--;
  return o;
}

void checkAuthorizedSellerStatusTargetingOptionDetails(
    api.AuthorizedSellerStatusTargetingOptionDetails o) {
  buildCounterAuthorizedSellerStatusTargetingOptionDetails++;
  if (buildCounterAuthorizedSellerStatusTargetingOptionDetails < 3) {
    unittest.expect(
      o.authorizedSellerStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuthorizedSellerStatusTargetingOptionDetails--;
}

core.int buildCounterBiddingStrategy = 0;
api.BiddingStrategy buildBiddingStrategy() {
  var o = api.BiddingStrategy();
  buildCounterBiddingStrategy++;
  if (buildCounterBiddingStrategy < 3) {
    o.fixedBid = buildFixedBidStrategy();
    o.maximizeSpendAutoBid = buildMaximizeSpendBidStrategy();
    o.performanceGoalAutoBid = buildPerformanceGoalBidStrategy();
  }
  buildCounterBiddingStrategy--;
  return o;
}

void checkBiddingStrategy(api.BiddingStrategy o) {
  buildCounterBiddingStrategy++;
  if (buildCounterBiddingStrategy < 3) {
    checkFixedBidStrategy(o.fixedBid! as api.FixedBidStrategy);
    checkMaximizeSpendBidStrategy(
        o.maximizeSpendAutoBid! as api.MaximizeSpendBidStrategy);
    checkPerformanceGoalBidStrategy(
        o.performanceGoalAutoBid! as api.PerformanceGoalBidStrategy);
  }
  buildCounterBiddingStrategy--;
}

core.int buildCounterBrowserAssignedTargetingOptionDetails = 0;
api.BrowserAssignedTargetingOptionDetails
    buildBrowserAssignedTargetingOptionDetails() {
  var o = api.BrowserAssignedTargetingOptionDetails();
  buildCounterBrowserAssignedTargetingOptionDetails++;
  if (buildCounterBrowserAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterBrowserAssignedTargetingOptionDetails--;
  return o;
}

void checkBrowserAssignedTargetingOptionDetails(
    api.BrowserAssignedTargetingOptionDetails o) {
  buildCounterBrowserAssignedTargetingOptionDetails++;
  if (buildCounterBrowserAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBrowserAssignedTargetingOptionDetails--;
}

core.int buildCounterBrowserTargetingOptionDetails = 0;
api.BrowserTargetingOptionDetails buildBrowserTargetingOptionDetails() {
  var o = api.BrowserTargetingOptionDetails();
  buildCounterBrowserTargetingOptionDetails++;
  if (buildCounterBrowserTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterBrowserTargetingOptionDetails--;
  return o;
}

void checkBrowserTargetingOptionDetails(api.BrowserTargetingOptionDetails o) {
  buildCounterBrowserTargetingOptionDetails++;
  if (buildCounterBrowserTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterBrowserTargetingOptionDetails--;
}

core.int buildCounterBudgetSummary = 0;
api.BudgetSummary buildBudgetSummary() {
  var o = api.BudgetSummary();
  buildCounterBudgetSummary++;
  if (buildCounterBudgetSummary < 3) {
    o.externalBudgetId = 'foo';
    o.preTaxAmountMicros = 'foo';
    o.prismaCpeCode = buildPrismaCpeCode();
    o.taxAmountMicros = 'foo';
    o.totalAmountMicros = 'foo';
  }
  buildCounterBudgetSummary--;
  return o;
}

void checkBudgetSummary(api.BudgetSummary o) {
  buildCounterBudgetSummary++;
  if (buildCounterBudgetSummary < 3) {
    unittest.expect(
      o.externalBudgetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.preTaxAmountMicros!,
      unittest.equals('foo'),
    );
    checkPrismaCpeCode(o.prismaCpeCode! as api.PrismaCpeCode);
    unittest.expect(
      o.taxAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalAmountMicros!,
      unittest.equals('foo'),
    );
  }
  buildCounterBudgetSummary--;
}

core.List<api.CreateAssignedTargetingOptionsRequest> buildUnnamed5430() {
  var o = <api.CreateAssignedTargetingOptionsRequest>[];
  o.add(buildCreateAssignedTargetingOptionsRequest());
  o.add(buildCreateAssignedTargetingOptionsRequest());
  return o;
}

void checkUnnamed5430(core.List<api.CreateAssignedTargetingOptionsRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreateAssignedTargetingOptionsRequest(
      o[0] as api.CreateAssignedTargetingOptionsRequest);
  checkCreateAssignedTargetingOptionsRequest(
      o[1] as api.CreateAssignedTargetingOptionsRequest);
}

core.List<api.DeleteAssignedTargetingOptionsRequest> buildUnnamed5431() {
  var o = <api.DeleteAssignedTargetingOptionsRequest>[];
  o.add(buildDeleteAssignedTargetingOptionsRequest());
  o.add(buildDeleteAssignedTargetingOptionsRequest());
  return o;
}

void checkUnnamed5431(core.List<api.DeleteAssignedTargetingOptionsRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeleteAssignedTargetingOptionsRequest(
      o[0] as api.DeleteAssignedTargetingOptionsRequest);
  checkDeleteAssignedTargetingOptionsRequest(
      o[1] as api.DeleteAssignedTargetingOptionsRequest);
}

core.int buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest = 0;
api.BulkEditAdvertiserAssignedTargetingOptionsRequest
    buildBulkEditAdvertiserAssignedTargetingOptionsRequest() {
  var o = api.BulkEditAdvertiserAssignedTargetingOptionsRequest();
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest++;
  if (buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest < 3) {
    o.createRequests = buildUnnamed5430();
    o.deleteRequests = buildUnnamed5431();
  }
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest--;
  return o;
}

void checkBulkEditAdvertiserAssignedTargetingOptionsRequest(
    api.BulkEditAdvertiserAssignedTargetingOptionsRequest o) {
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest++;
  if (buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest < 3) {
    checkUnnamed5430(o.createRequests!);
    checkUnnamed5431(o.deleteRequests!);
  }
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsRequest--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5432() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5432(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse = 0;
api.BulkEditAdvertiserAssignedTargetingOptionsResponse
    buildBulkEditAdvertiserAssignedTargetingOptionsResponse() {
  var o = api.BulkEditAdvertiserAssignedTargetingOptionsResponse();
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse++;
  if (buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse < 3) {
    o.createdAssignedTargetingOptions = buildUnnamed5432();
  }
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkEditAdvertiserAssignedTargetingOptionsResponse(
    api.BulkEditAdvertiserAssignedTargetingOptionsResponse o) {
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse++;
  if (buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5432(o.createdAssignedTargetingOptions!);
  }
  buildCounterBulkEditAdvertiserAssignedTargetingOptionsResponse--;
}

core.List<api.AssignedInventorySource> buildUnnamed5433() {
  var o = <api.AssignedInventorySource>[];
  o.add(buildAssignedInventorySource());
  o.add(buildAssignedInventorySource());
  return o;
}

void checkUnnamed5433(core.List<api.AssignedInventorySource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedInventorySource(o[0] as api.AssignedInventorySource);
  checkAssignedInventorySource(o[1] as api.AssignedInventorySource);
}

core.List<core.String> buildUnnamed5434() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5434(core.List<core.String> o) {
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

core.int buildCounterBulkEditAssignedInventorySourcesRequest = 0;
api.BulkEditAssignedInventorySourcesRequest
    buildBulkEditAssignedInventorySourcesRequest() {
  var o = api.BulkEditAssignedInventorySourcesRequest();
  buildCounterBulkEditAssignedInventorySourcesRequest++;
  if (buildCounterBulkEditAssignedInventorySourcesRequest < 3) {
    o.advertiserId = 'foo';
    o.createdAssignedInventorySources = buildUnnamed5433();
    o.deletedAssignedInventorySources = buildUnnamed5434();
    o.partnerId = 'foo';
  }
  buildCounterBulkEditAssignedInventorySourcesRequest--;
  return o;
}

void checkBulkEditAssignedInventorySourcesRequest(
    api.BulkEditAssignedInventorySourcesRequest o) {
  buildCounterBulkEditAssignedInventorySourcesRequest++;
  if (buildCounterBulkEditAssignedInventorySourcesRequest < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkUnnamed5433(o.createdAssignedInventorySources!);
    checkUnnamed5434(o.deletedAssignedInventorySources!);
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBulkEditAssignedInventorySourcesRequest--;
}

core.List<api.AssignedInventorySource> buildUnnamed5435() {
  var o = <api.AssignedInventorySource>[];
  o.add(buildAssignedInventorySource());
  o.add(buildAssignedInventorySource());
  return o;
}

void checkUnnamed5435(core.List<api.AssignedInventorySource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedInventorySource(o[0] as api.AssignedInventorySource);
  checkAssignedInventorySource(o[1] as api.AssignedInventorySource);
}

core.int buildCounterBulkEditAssignedInventorySourcesResponse = 0;
api.BulkEditAssignedInventorySourcesResponse
    buildBulkEditAssignedInventorySourcesResponse() {
  var o = api.BulkEditAssignedInventorySourcesResponse();
  buildCounterBulkEditAssignedInventorySourcesResponse++;
  if (buildCounterBulkEditAssignedInventorySourcesResponse < 3) {
    o.assignedInventorySources = buildUnnamed5435();
  }
  buildCounterBulkEditAssignedInventorySourcesResponse--;
  return o;
}

void checkBulkEditAssignedInventorySourcesResponse(
    api.BulkEditAssignedInventorySourcesResponse o) {
  buildCounterBulkEditAssignedInventorySourcesResponse++;
  if (buildCounterBulkEditAssignedInventorySourcesResponse < 3) {
    checkUnnamed5435(o.assignedInventorySources!);
  }
  buildCounterBulkEditAssignedInventorySourcesResponse--;
}

core.List<api.AssignedLocation> buildUnnamed5436() {
  var o = <api.AssignedLocation>[];
  o.add(buildAssignedLocation());
  o.add(buildAssignedLocation());
  return o;
}

void checkUnnamed5436(core.List<api.AssignedLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedLocation(o[0] as api.AssignedLocation);
  checkAssignedLocation(o[1] as api.AssignedLocation);
}

core.List<core.String> buildUnnamed5437() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5437(core.List<core.String> o) {
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

core.int buildCounterBulkEditAssignedLocationsRequest = 0;
api.BulkEditAssignedLocationsRequest buildBulkEditAssignedLocationsRequest() {
  var o = api.BulkEditAssignedLocationsRequest();
  buildCounterBulkEditAssignedLocationsRequest++;
  if (buildCounterBulkEditAssignedLocationsRequest < 3) {
    o.createdAssignedLocations = buildUnnamed5436();
    o.deletedAssignedLocations = buildUnnamed5437();
  }
  buildCounterBulkEditAssignedLocationsRequest--;
  return o;
}

void checkBulkEditAssignedLocationsRequest(
    api.BulkEditAssignedLocationsRequest o) {
  buildCounterBulkEditAssignedLocationsRequest++;
  if (buildCounterBulkEditAssignedLocationsRequest < 3) {
    checkUnnamed5436(o.createdAssignedLocations!);
    checkUnnamed5437(o.deletedAssignedLocations!);
  }
  buildCounterBulkEditAssignedLocationsRequest--;
}

core.List<api.AssignedLocation> buildUnnamed5438() {
  var o = <api.AssignedLocation>[];
  o.add(buildAssignedLocation());
  o.add(buildAssignedLocation());
  return o;
}

void checkUnnamed5438(core.List<api.AssignedLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedLocation(o[0] as api.AssignedLocation);
  checkAssignedLocation(o[1] as api.AssignedLocation);
}

core.int buildCounterBulkEditAssignedLocationsResponse = 0;
api.BulkEditAssignedLocationsResponse buildBulkEditAssignedLocationsResponse() {
  var o = api.BulkEditAssignedLocationsResponse();
  buildCounterBulkEditAssignedLocationsResponse++;
  if (buildCounterBulkEditAssignedLocationsResponse < 3) {
    o.assignedLocations = buildUnnamed5438();
  }
  buildCounterBulkEditAssignedLocationsResponse--;
  return o;
}

void checkBulkEditAssignedLocationsResponse(
    api.BulkEditAssignedLocationsResponse o) {
  buildCounterBulkEditAssignedLocationsResponse++;
  if (buildCounterBulkEditAssignedLocationsResponse < 3) {
    checkUnnamed5438(o.assignedLocations!);
  }
  buildCounterBulkEditAssignedLocationsResponse--;
}

core.List<api.AssignedUserRole> buildUnnamed5439() {
  var o = <api.AssignedUserRole>[];
  o.add(buildAssignedUserRole());
  o.add(buildAssignedUserRole());
  return o;
}

void checkUnnamed5439(core.List<api.AssignedUserRole> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedUserRole(o[0] as api.AssignedUserRole);
  checkAssignedUserRole(o[1] as api.AssignedUserRole);
}

core.List<core.String> buildUnnamed5440() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5440(core.List<core.String> o) {
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

core.int buildCounterBulkEditAssignedUserRolesRequest = 0;
api.BulkEditAssignedUserRolesRequest buildBulkEditAssignedUserRolesRequest() {
  var o = api.BulkEditAssignedUserRolesRequest();
  buildCounterBulkEditAssignedUserRolesRequest++;
  if (buildCounterBulkEditAssignedUserRolesRequest < 3) {
    o.createdAssignedUserRoles = buildUnnamed5439();
    o.deletedAssignedUserRoles = buildUnnamed5440();
  }
  buildCounterBulkEditAssignedUserRolesRequest--;
  return o;
}

void checkBulkEditAssignedUserRolesRequest(
    api.BulkEditAssignedUserRolesRequest o) {
  buildCounterBulkEditAssignedUserRolesRequest++;
  if (buildCounterBulkEditAssignedUserRolesRequest < 3) {
    checkUnnamed5439(o.createdAssignedUserRoles!);
    checkUnnamed5440(o.deletedAssignedUserRoles!);
  }
  buildCounterBulkEditAssignedUserRolesRequest--;
}

core.List<api.AssignedUserRole> buildUnnamed5441() {
  var o = <api.AssignedUserRole>[];
  o.add(buildAssignedUserRole());
  o.add(buildAssignedUserRole());
  return o;
}

void checkUnnamed5441(core.List<api.AssignedUserRole> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedUserRole(o[0] as api.AssignedUserRole);
  checkAssignedUserRole(o[1] as api.AssignedUserRole);
}

core.int buildCounterBulkEditAssignedUserRolesResponse = 0;
api.BulkEditAssignedUserRolesResponse buildBulkEditAssignedUserRolesResponse() {
  var o = api.BulkEditAssignedUserRolesResponse();
  buildCounterBulkEditAssignedUserRolesResponse++;
  if (buildCounterBulkEditAssignedUserRolesResponse < 3) {
    o.createdAssignedUserRoles = buildUnnamed5441();
  }
  buildCounterBulkEditAssignedUserRolesResponse--;
  return o;
}

void checkBulkEditAssignedUserRolesResponse(
    api.BulkEditAssignedUserRolesResponse o) {
  buildCounterBulkEditAssignedUserRolesResponse++;
  if (buildCounterBulkEditAssignedUserRolesResponse < 3) {
    checkUnnamed5441(o.createdAssignedUserRoles!);
  }
  buildCounterBulkEditAssignedUserRolesResponse--;
}

core.List<api.CreateAssignedTargetingOptionsRequest> buildUnnamed5442() {
  var o = <api.CreateAssignedTargetingOptionsRequest>[];
  o.add(buildCreateAssignedTargetingOptionsRequest());
  o.add(buildCreateAssignedTargetingOptionsRequest());
  return o;
}

void checkUnnamed5442(core.List<api.CreateAssignedTargetingOptionsRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreateAssignedTargetingOptionsRequest(
      o[0] as api.CreateAssignedTargetingOptionsRequest);
  checkCreateAssignedTargetingOptionsRequest(
      o[1] as api.CreateAssignedTargetingOptionsRequest);
}

core.List<api.DeleteAssignedTargetingOptionsRequest> buildUnnamed5443() {
  var o = <api.DeleteAssignedTargetingOptionsRequest>[];
  o.add(buildDeleteAssignedTargetingOptionsRequest());
  o.add(buildDeleteAssignedTargetingOptionsRequest());
  return o;
}

void checkUnnamed5443(core.List<api.DeleteAssignedTargetingOptionsRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeleteAssignedTargetingOptionsRequest(
      o[0] as api.DeleteAssignedTargetingOptionsRequest);
  checkDeleteAssignedTargetingOptionsRequest(
      o[1] as api.DeleteAssignedTargetingOptionsRequest);
}

core.int buildCounterBulkEditLineItemAssignedTargetingOptionsRequest = 0;
api.BulkEditLineItemAssignedTargetingOptionsRequest
    buildBulkEditLineItemAssignedTargetingOptionsRequest() {
  var o = api.BulkEditLineItemAssignedTargetingOptionsRequest();
  buildCounterBulkEditLineItemAssignedTargetingOptionsRequest++;
  if (buildCounterBulkEditLineItemAssignedTargetingOptionsRequest < 3) {
    o.createRequests = buildUnnamed5442();
    o.deleteRequests = buildUnnamed5443();
  }
  buildCounterBulkEditLineItemAssignedTargetingOptionsRequest--;
  return o;
}

void checkBulkEditLineItemAssignedTargetingOptionsRequest(
    api.BulkEditLineItemAssignedTargetingOptionsRequest o) {
  buildCounterBulkEditLineItemAssignedTargetingOptionsRequest++;
  if (buildCounterBulkEditLineItemAssignedTargetingOptionsRequest < 3) {
    checkUnnamed5442(o.createRequests!);
    checkUnnamed5443(o.deleteRequests!);
  }
  buildCounterBulkEditLineItemAssignedTargetingOptionsRequest--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5444() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5444(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkEditLineItemAssignedTargetingOptionsResponse = 0;
api.BulkEditLineItemAssignedTargetingOptionsResponse
    buildBulkEditLineItemAssignedTargetingOptionsResponse() {
  var o = api.BulkEditLineItemAssignedTargetingOptionsResponse();
  buildCounterBulkEditLineItemAssignedTargetingOptionsResponse++;
  if (buildCounterBulkEditLineItemAssignedTargetingOptionsResponse < 3) {
    o.createdAssignedTargetingOptions = buildUnnamed5444();
  }
  buildCounterBulkEditLineItemAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkEditLineItemAssignedTargetingOptionsResponse(
    api.BulkEditLineItemAssignedTargetingOptionsResponse o) {
  buildCounterBulkEditLineItemAssignedTargetingOptionsResponse++;
  if (buildCounterBulkEditLineItemAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5444(o.createdAssignedTargetingOptions!);
  }
  buildCounterBulkEditLineItemAssignedTargetingOptionsResponse--;
}

core.List<api.NegativeKeyword> buildUnnamed5445() {
  var o = <api.NegativeKeyword>[];
  o.add(buildNegativeKeyword());
  o.add(buildNegativeKeyword());
  return o;
}

void checkUnnamed5445(core.List<api.NegativeKeyword> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNegativeKeyword(o[0] as api.NegativeKeyword);
  checkNegativeKeyword(o[1] as api.NegativeKeyword);
}

core.List<core.String> buildUnnamed5446() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5446(core.List<core.String> o) {
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

core.int buildCounterBulkEditNegativeKeywordsRequest = 0;
api.BulkEditNegativeKeywordsRequest buildBulkEditNegativeKeywordsRequest() {
  var o = api.BulkEditNegativeKeywordsRequest();
  buildCounterBulkEditNegativeKeywordsRequest++;
  if (buildCounterBulkEditNegativeKeywordsRequest < 3) {
    o.createdNegativeKeywords = buildUnnamed5445();
    o.deletedNegativeKeywords = buildUnnamed5446();
  }
  buildCounterBulkEditNegativeKeywordsRequest--;
  return o;
}

void checkBulkEditNegativeKeywordsRequest(
    api.BulkEditNegativeKeywordsRequest o) {
  buildCounterBulkEditNegativeKeywordsRequest++;
  if (buildCounterBulkEditNegativeKeywordsRequest < 3) {
    checkUnnamed5445(o.createdNegativeKeywords!);
    checkUnnamed5446(o.deletedNegativeKeywords!);
  }
  buildCounterBulkEditNegativeKeywordsRequest--;
}

core.List<api.NegativeKeyword> buildUnnamed5447() {
  var o = <api.NegativeKeyword>[];
  o.add(buildNegativeKeyword());
  o.add(buildNegativeKeyword());
  return o;
}

void checkUnnamed5447(core.List<api.NegativeKeyword> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNegativeKeyword(o[0] as api.NegativeKeyword);
  checkNegativeKeyword(o[1] as api.NegativeKeyword);
}

core.int buildCounterBulkEditNegativeKeywordsResponse = 0;
api.BulkEditNegativeKeywordsResponse buildBulkEditNegativeKeywordsResponse() {
  var o = api.BulkEditNegativeKeywordsResponse();
  buildCounterBulkEditNegativeKeywordsResponse++;
  if (buildCounterBulkEditNegativeKeywordsResponse < 3) {
    o.negativeKeywords = buildUnnamed5447();
  }
  buildCounterBulkEditNegativeKeywordsResponse--;
  return o;
}

void checkBulkEditNegativeKeywordsResponse(
    api.BulkEditNegativeKeywordsResponse o) {
  buildCounterBulkEditNegativeKeywordsResponse++;
  if (buildCounterBulkEditNegativeKeywordsResponse < 3) {
    checkUnnamed5447(o.negativeKeywords!);
  }
  buildCounterBulkEditNegativeKeywordsResponse--;
}

core.List<api.CreateAssignedTargetingOptionsRequest> buildUnnamed5448() {
  var o = <api.CreateAssignedTargetingOptionsRequest>[];
  o.add(buildCreateAssignedTargetingOptionsRequest());
  o.add(buildCreateAssignedTargetingOptionsRequest());
  return o;
}

void checkUnnamed5448(core.List<api.CreateAssignedTargetingOptionsRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreateAssignedTargetingOptionsRequest(
      o[0] as api.CreateAssignedTargetingOptionsRequest);
  checkCreateAssignedTargetingOptionsRequest(
      o[1] as api.CreateAssignedTargetingOptionsRequest);
}

core.List<api.DeleteAssignedTargetingOptionsRequest> buildUnnamed5449() {
  var o = <api.DeleteAssignedTargetingOptionsRequest>[];
  o.add(buildDeleteAssignedTargetingOptionsRequest());
  o.add(buildDeleteAssignedTargetingOptionsRequest());
  return o;
}

void checkUnnamed5449(core.List<api.DeleteAssignedTargetingOptionsRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeleteAssignedTargetingOptionsRequest(
      o[0] as api.DeleteAssignedTargetingOptionsRequest);
  checkDeleteAssignedTargetingOptionsRequest(
      o[1] as api.DeleteAssignedTargetingOptionsRequest);
}

core.int buildCounterBulkEditPartnerAssignedTargetingOptionsRequest = 0;
api.BulkEditPartnerAssignedTargetingOptionsRequest
    buildBulkEditPartnerAssignedTargetingOptionsRequest() {
  var o = api.BulkEditPartnerAssignedTargetingOptionsRequest();
  buildCounterBulkEditPartnerAssignedTargetingOptionsRequest++;
  if (buildCounterBulkEditPartnerAssignedTargetingOptionsRequest < 3) {
    o.createRequests = buildUnnamed5448();
    o.deleteRequests = buildUnnamed5449();
  }
  buildCounterBulkEditPartnerAssignedTargetingOptionsRequest--;
  return o;
}

void checkBulkEditPartnerAssignedTargetingOptionsRequest(
    api.BulkEditPartnerAssignedTargetingOptionsRequest o) {
  buildCounterBulkEditPartnerAssignedTargetingOptionsRequest++;
  if (buildCounterBulkEditPartnerAssignedTargetingOptionsRequest < 3) {
    checkUnnamed5448(o.createRequests!);
    checkUnnamed5449(o.deleteRequests!);
  }
  buildCounterBulkEditPartnerAssignedTargetingOptionsRequest--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5450() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5450(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkEditPartnerAssignedTargetingOptionsResponse = 0;
api.BulkEditPartnerAssignedTargetingOptionsResponse
    buildBulkEditPartnerAssignedTargetingOptionsResponse() {
  var o = api.BulkEditPartnerAssignedTargetingOptionsResponse();
  buildCounterBulkEditPartnerAssignedTargetingOptionsResponse++;
  if (buildCounterBulkEditPartnerAssignedTargetingOptionsResponse < 3) {
    o.createdAssignedTargetingOptions = buildUnnamed5450();
  }
  buildCounterBulkEditPartnerAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkEditPartnerAssignedTargetingOptionsResponse(
    api.BulkEditPartnerAssignedTargetingOptionsResponse o) {
  buildCounterBulkEditPartnerAssignedTargetingOptionsResponse++;
  if (buildCounterBulkEditPartnerAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5450(o.createdAssignedTargetingOptions!);
  }
  buildCounterBulkEditPartnerAssignedTargetingOptionsResponse--;
}

core.List<api.Site> buildUnnamed5451() {
  var o = <api.Site>[];
  o.add(buildSite());
  o.add(buildSite());
  return o;
}

void checkUnnamed5451(core.List<api.Site> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSite(o[0] as api.Site);
  checkSite(o[1] as api.Site);
}

core.List<core.String> buildUnnamed5452() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5452(core.List<core.String> o) {
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

core.int buildCounterBulkEditSitesRequest = 0;
api.BulkEditSitesRequest buildBulkEditSitesRequest() {
  var o = api.BulkEditSitesRequest();
  buildCounterBulkEditSitesRequest++;
  if (buildCounterBulkEditSitesRequest < 3) {
    o.advertiserId = 'foo';
    o.createdSites = buildUnnamed5451();
    o.deletedSites = buildUnnamed5452();
    o.partnerId = 'foo';
  }
  buildCounterBulkEditSitesRequest--;
  return o;
}

void checkBulkEditSitesRequest(api.BulkEditSitesRequest o) {
  buildCounterBulkEditSitesRequest++;
  if (buildCounterBulkEditSitesRequest < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkUnnamed5451(o.createdSites!);
    checkUnnamed5452(o.deletedSites!);
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBulkEditSitesRequest--;
}

core.List<api.Site> buildUnnamed5453() {
  var o = <api.Site>[];
  o.add(buildSite());
  o.add(buildSite());
  return o;
}

void checkUnnamed5453(core.List<api.Site> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSite(o[0] as api.Site);
  checkSite(o[1] as api.Site);
}

core.int buildCounterBulkEditSitesResponse = 0;
api.BulkEditSitesResponse buildBulkEditSitesResponse() {
  var o = api.BulkEditSitesResponse();
  buildCounterBulkEditSitesResponse++;
  if (buildCounterBulkEditSitesResponse < 3) {
    o.sites = buildUnnamed5453();
  }
  buildCounterBulkEditSitesResponse--;
  return o;
}

void checkBulkEditSitesResponse(api.BulkEditSitesResponse o) {
  buildCounterBulkEditSitesResponse++;
  if (buildCounterBulkEditSitesResponse < 3) {
    checkUnnamed5453(o.sites!);
  }
  buildCounterBulkEditSitesResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5454() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5454(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse = 0;
api.BulkListAdvertiserAssignedTargetingOptionsResponse
    buildBulkListAdvertiserAssignedTargetingOptionsResponse() {
  var o = api.BulkListAdvertiserAssignedTargetingOptionsResponse();
  buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5454();
    o.nextPageToken = 'foo';
  }
  buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkListAdvertiserAssignedTargetingOptionsResponse(
    api.BulkListAdvertiserAssignedTargetingOptionsResponse o) {
  buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5454(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterBulkListAdvertiserAssignedTargetingOptionsResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5455() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5455(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkListCampaignAssignedTargetingOptionsResponse = 0;
api.BulkListCampaignAssignedTargetingOptionsResponse
    buildBulkListCampaignAssignedTargetingOptionsResponse() {
  var o = api.BulkListCampaignAssignedTargetingOptionsResponse();
  buildCounterBulkListCampaignAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListCampaignAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5455();
    o.nextPageToken = 'foo';
  }
  buildCounterBulkListCampaignAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkListCampaignAssignedTargetingOptionsResponse(
    api.BulkListCampaignAssignedTargetingOptionsResponse o) {
  buildCounterBulkListCampaignAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListCampaignAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5455(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterBulkListCampaignAssignedTargetingOptionsResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5456() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5456(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse = 0;
api.BulkListInsertionOrderAssignedTargetingOptionsResponse
    buildBulkListInsertionOrderAssignedTargetingOptionsResponse() {
  var o = api.BulkListInsertionOrderAssignedTargetingOptionsResponse();
  buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5456();
    o.nextPageToken = 'foo';
  }
  buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkListInsertionOrderAssignedTargetingOptionsResponse(
    api.BulkListInsertionOrderAssignedTargetingOptionsResponse o) {
  buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5456(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterBulkListInsertionOrderAssignedTargetingOptionsResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5457() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5457(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterBulkListLineItemAssignedTargetingOptionsResponse = 0;
api.BulkListLineItemAssignedTargetingOptionsResponse
    buildBulkListLineItemAssignedTargetingOptionsResponse() {
  var o = api.BulkListLineItemAssignedTargetingOptionsResponse();
  buildCounterBulkListLineItemAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListLineItemAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5457();
    o.nextPageToken = 'foo';
  }
  buildCounterBulkListLineItemAssignedTargetingOptionsResponse--;
  return o;
}

void checkBulkListLineItemAssignedTargetingOptionsResponse(
    api.BulkListLineItemAssignedTargetingOptionsResponse o) {
  buildCounterBulkListLineItemAssignedTargetingOptionsResponse++;
  if (buildCounterBulkListLineItemAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5457(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterBulkListLineItemAssignedTargetingOptionsResponse--;
}

core.List<api.CampaignBudget> buildUnnamed5458() {
  var o = <api.CampaignBudget>[];
  o.add(buildCampaignBudget());
  o.add(buildCampaignBudget());
  return o;
}

void checkUnnamed5458(core.List<api.CampaignBudget> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCampaignBudget(o[0] as api.CampaignBudget);
  checkCampaignBudget(o[1] as api.CampaignBudget);
}

core.int buildCounterCampaign = 0;
api.Campaign buildCampaign() {
  var o = api.Campaign();
  buildCounterCampaign++;
  if (buildCounterCampaign < 3) {
    o.advertiserId = 'foo';
    o.campaignBudgets = buildUnnamed5458();
    o.campaignFlight = buildCampaignFlight();
    o.campaignGoal = buildCampaignGoal();
    o.campaignId = 'foo';
    o.displayName = 'foo';
    o.entityStatus = 'foo';
    o.frequencyCap = buildFrequencyCap();
    o.name = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterCampaign--;
  return o;
}

void checkCampaign(api.Campaign o) {
  buildCounterCampaign++;
  if (buildCounterCampaign < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkUnnamed5458(o.campaignBudgets!);
    checkCampaignFlight(o.campaignFlight! as api.CampaignFlight);
    checkCampaignGoal(o.campaignGoal! as api.CampaignGoal);
    unittest.expect(
      o.campaignId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    checkFrequencyCap(o.frequencyCap! as api.FrequencyCap);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterCampaign--;
}

core.int buildCounterCampaignBudget = 0;
api.CampaignBudget buildCampaignBudget() {
  var o = api.CampaignBudget();
  buildCounterCampaignBudget++;
  if (buildCounterCampaignBudget < 3) {
    o.budgetAmountMicros = 'foo';
    o.budgetId = 'foo';
    o.budgetUnit = 'foo';
    o.dateRange = buildDateRange();
    o.displayName = 'foo';
    o.externalBudgetId = 'foo';
    o.externalBudgetSource = 'foo';
    o.invoiceGroupingId = 'foo';
    o.prismaConfig = buildPrismaConfig();
  }
  buildCounterCampaignBudget--;
  return o;
}

void checkCampaignBudget(api.CampaignBudget o) {
  buildCounterCampaignBudget++;
  if (buildCounterCampaignBudget < 3) {
    unittest.expect(
      o.budgetAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.budgetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.budgetUnit!,
      unittest.equals('foo'),
    );
    checkDateRange(o.dateRange! as api.DateRange);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalBudgetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalBudgetSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invoiceGroupingId!,
      unittest.equals('foo'),
    );
    checkPrismaConfig(o.prismaConfig! as api.PrismaConfig);
  }
  buildCounterCampaignBudget--;
}

core.int buildCounterCampaignFlight = 0;
api.CampaignFlight buildCampaignFlight() {
  var o = api.CampaignFlight();
  buildCounterCampaignFlight++;
  if (buildCounterCampaignFlight < 3) {
    o.plannedDates = buildDateRange();
    o.plannedSpendAmountMicros = 'foo';
  }
  buildCounterCampaignFlight--;
  return o;
}

void checkCampaignFlight(api.CampaignFlight o) {
  buildCounterCampaignFlight++;
  if (buildCounterCampaignFlight < 3) {
    checkDateRange(o.plannedDates! as api.DateRange);
    unittest.expect(
      o.plannedSpendAmountMicros!,
      unittest.equals('foo'),
    );
  }
  buildCounterCampaignFlight--;
}

core.int buildCounterCampaignGoal = 0;
api.CampaignGoal buildCampaignGoal() {
  var o = api.CampaignGoal();
  buildCounterCampaignGoal++;
  if (buildCounterCampaignGoal < 3) {
    o.campaignGoalType = 'foo';
    o.performanceGoal = buildPerformanceGoal();
  }
  buildCounterCampaignGoal--;
  return o;
}

void checkCampaignGoal(api.CampaignGoal o) {
  buildCounterCampaignGoal++;
  if (buildCounterCampaignGoal < 3) {
    unittest.expect(
      o.campaignGoalType!,
      unittest.equals('foo'),
    );
    checkPerformanceGoal(o.performanceGoal! as api.PerformanceGoal);
  }
  buildCounterCampaignGoal--;
}

core.int buildCounterCarrierAndIspAssignedTargetingOptionDetails = 0;
api.CarrierAndIspAssignedTargetingOptionDetails
    buildCarrierAndIspAssignedTargetingOptionDetails() {
  var o = api.CarrierAndIspAssignedTargetingOptionDetails();
  buildCounterCarrierAndIspAssignedTargetingOptionDetails++;
  if (buildCounterCarrierAndIspAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterCarrierAndIspAssignedTargetingOptionDetails--;
  return o;
}

void checkCarrierAndIspAssignedTargetingOptionDetails(
    api.CarrierAndIspAssignedTargetingOptionDetails o) {
  buildCounterCarrierAndIspAssignedTargetingOptionDetails++;
  if (buildCounterCarrierAndIspAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCarrierAndIspAssignedTargetingOptionDetails--;
}

core.int buildCounterCarrierAndIspTargetingOptionDetails = 0;
api.CarrierAndIspTargetingOptionDetails
    buildCarrierAndIspTargetingOptionDetails() {
  var o = api.CarrierAndIspTargetingOptionDetails();
  buildCounterCarrierAndIspTargetingOptionDetails++;
  if (buildCounterCarrierAndIspTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.type = 'foo';
  }
  buildCounterCarrierAndIspTargetingOptionDetails--;
  return o;
}

void checkCarrierAndIspTargetingOptionDetails(
    api.CarrierAndIspTargetingOptionDetails o) {
  buildCounterCarrierAndIspTargetingOptionDetails++;
  if (buildCounterCarrierAndIspTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterCarrierAndIspTargetingOptionDetails--;
}

core.int buildCounterCategoryAssignedTargetingOptionDetails = 0;
api.CategoryAssignedTargetingOptionDetails
    buildCategoryAssignedTargetingOptionDetails() {
  var o = api.CategoryAssignedTargetingOptionDetails();
  buildCounterCategoryAssignedTargetingOptionDetails++;
  if (buildCounterCategoryAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterCategoryAssignedTargetingOptionDetails--;
  return o;
}

void checkCategoryAssignedTargetingOptionDetails(
    api.CategoryAssignedTargetingOptionDetails o) {
  buildCounterCategoryAssignedTargetingOptionDetails++;
  if (buildCounterCategoryAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategoryAssignedTargetingOptionDetails--;
}

core.int buildCounterCategoryTargetingOptionDetails = 0;
api.CategoryTargetingOptionDetails buildCategoryTargetingOptionDetails() {
  var o = api.CategoryTargetingOptionDetails();
  buildCounterCategoryTargetingOptionDetails++;
  if (buildCounterCategoryTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterCategoryTargetingOptionDetails--;
  return o;
}

void checkCategoryTargetingOptionDetails(api.CategoryTargetingOptionDetails o) {
  buildCounterCategoryTargetingOptionDetails++;
  if (buildCounterCategoryTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategoryTargetingOptionDetails--;
}

core.int buildCounterChannel = 0;
api.Channel buildChannel() {
  var o = api.Channel();
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    o.advertiserId = 'foo';
    o.channelId = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
    o.negativelyTargetedLineItemCount = 'foo';
    o.partnerId = 'foo';
    o.positivelyTargetedLineItemCount = 'foo';
  }
  buildCounterChannel--;
  return o;
}

void checkChannel(api.Channel o) {
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.channelId!,
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
      o.negativelyTargetedLineItemCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.positivelyTargetedLineItemCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannel--;
}

core.int buildCounterChannelAssignedTargetingOptionDetails = 0;
api.ChannelAssignedTargetingOptionDetails
    buildChannelAssignedTargetingOptionDetails() {
  var o = api.ChannelAssignedTargetingOptionDetails();
  buildCounterChannelAssignedTargetingOptionDetails++;
  if (buildCounterChannelAssignedTargetingOptionDetails < 3) {
    o.channelId = 'foo';
    o.negative = true;
  }
  buildCounterChannelAssignedTargetingOptionDetails--;
  return o;
}

void checkChannelAssignedTargetingOptionDetails(
    api.ChannelAssignedTargetingOptionDetails o) {
  buildCounterChannelAssignedTargetingOptionDetails++;
  if (buildCounterChannelAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.channelId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
  }
  buildCounterChannelAssignedTargetingOptionDetails--;
}

core.List<core.String> buildUnnamed5459() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5459(core.List<core.String> o) {
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

core.int buildCounterCmHybridConfig = 0;
api.CmHybridConfig buildCmHybridConfig() {
  var o = api.CmHybridConfig();
  buildCounterCmHybridConfig++;
  if (buildCounterCmHybridConfig < 3) {
    o.cmAccountId = 'foo';
    o.cmFloodlightConfigId = 'foo';
    o.cmFloodlightLinkingAuthorized = true;
    o.cmSyncableSiteIds = buildUnnamed5459();
    o.dv360ToCmCostReportingEnabled = true;
    o.dv360ToCmDataSharingEnabled = true;
  }
  buildCounterCmHybridConfig--;
  return o;
}

void checkCmHybridConfig(api.CmHybridConfig o) {
  buildCounterCmHybridConfig++;
  if (buildCounterCmHybridConfig < 3) {
    unittest.expect(
      o.cmAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cmFloodlightConfigId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cmFloodlightLinkingAuthorized!, unittest.isTrue);
    checkUnnamed5459(o.cmSyncableSiteIds!);
    unittest.expect(o.dv360ToCmCostReportingEnabled!, unittest.isTrue);
    unittest.expect(o.dv360ToCmDataSharingEnabled!, unittest.isTrue);
  }
  buildCounterCmHybridConfig--;
}

core.int buildCounterCmTrackingAd = 0;
api.CmTrackingAd buildCmTrackingAd() {
  var o = api.CmTrackingAd();
  buildCounterCmTrackingAd++;
  if (buildCounterCmTrackingAd < 3) {
    o.cmAdId = 'foo';
    o.cmCreativeId = 'foo';
    o.cmPlacementId = 'foo';
  }
  buildCounterCmTrackingAd--;
  return o;
}

void checkCmTrackingAd(api.CmTrackingAd o) {
  buildCounterCmTrackingAd++;
  if (buildCounterCmTrackingAd < 3) {
    unittest.expect(
      o.cmAdId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cmCreativeId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cmPlacementId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCmTrackingAd--;
}

core.int buildCounterCombinedAudience = 0;
api.CombinedAudience buildCombinedAudience() {
  var o = api.CombinedAudience();
  buildCounterCombinedAudience++;
  if (buildCounterCombinedAudience < 3) {
    o.combinedAudienceId = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
  }
  buildCounterCombinedAudience--;
  return o;
}

void checkCombinedAudience(api.CombinedAudience o) {
  buildCounterCombinedAudience++;
  if (buildCounterCombinedAudience < 3) {
    unittest.expect(
      o.combinedAudienceId!,
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
  }
  buildCounterCombinedAudience--;
}

core.List<api.CombinedAudienceTargetingSetting> buildUnnamed5460() {
  var o = <api.CombinedAudienceTargetingSetting>[];
  o.add(buildCombinedAudienceTargetingSetting());
  o.add(buildCombinedAudienceTargetingSetting());
  return o;
}

void checkUnnamed5460(core.List<api.CombinedAudienceTargetingSetting> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCombinedAudienceTargetingSetting(
      o[0] as api.CombinedAudienceTargetingSetting);
  checkCombinedAudienceTargetingSetting(
      o[1] as api.CombinedAudienceTargetingSetting);
}

core.int buildCounterCombinedAudienceGroup = 0;
api.CombinedAudienceGroup buildCombinedAudienceGroup() {
  var o = api.CombinedAudienceGroup();
  buildCounterCombinedAudienceGroup++;
  if (buildCounterCombinedAudienceGroup < 3) {
    o.settings = buildUnnamed5460();
  }
  buildCounterCombinedAudienceGroup--;
  return o;
}

void checkCombinedAudienceGroup(api.CombinedAudienceGroup o) {
  buildCounterCombinedAudienceGroup++;
  if (buildCounterCombinedAudienceGroup < 3) {
    checkUnnamed5460(o.settings!);
  }
  buildCounterCombinedAudienceGroup--;
}

core.int buildCounterCombinedAudienceTargetingSetting = 0;
api.CombinedAudienceTargetingSetting buildCombinedAudienceTargetingSetting() {
  var o = api.CombinedAudienceTargetingSetting();
  buildCounterCombinedAudienceTargetingSetting++;
  if (buildCounterCombinedAudienceTargetingSetting < 3) {
    o.combinedAudienceId = 'foo';
  }
  buildCounterCombinedAudienceTargetingSetting--;
  return o;
}

void checkCombinedAudienceTargetingSetting(
    api.CombinedAudienceTargetingSetting o) {
  buildCounterCombinedAudienceTargetingSetting++;
  if (buildCounterCombinedAudienceTargetingSetting < 3) {
    unittest.expect(
      o.combinedAudienceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCombinedAudienceTargetingSetting--;
}

core.int buildCounterContentInstreamPositionAssignedTargetingOptionDetails = 0;
api.ContentInstreamPositionAssignedTargetingOptionDetails
    buildContentInstreamPositionAssignedTargetingOptionDetails() {
  var o = api.ContentInstreamPositionAssignedTargetingOptionDetails();
  buildCounterContentInstreamPositionAssignedTargetingOptionDetails++;
  if (buildCounterContentInstreamPositionAssignedTargetingOptionDetails < 3) {
    o.adType = 'foo';
    o.contentInstreamPosition = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterContentInstreamPositionAssignedTargetingOptionDetails--;
  return o;
}

void checkContentInstreamPositionAssignedTargetingOptionDetails(
    api.ContentInstreamPositionAssignedTargetingOptionDetails o) {
  buildCounterContentInstreamPositionAssignedTargetingOptionDetails++;
  if (buildCounterContentInstreamPositionAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.adType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contentInstreamPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterContentInstreamPositionAssignedTargetingOptionDetails--;
}

core.int buildCounterContentInstreamPositionTargetingOptionDetails = 0;
api.ContentInstreamPositionTargetingOptionDetails
    buildContentInstreamPositionTargetingOptionDetails() {
  var o = api.ContentInstreamPositionTargetingOptionDetails();
  buildCounterContentInstreamPositionTargetingOptionDetails++;
  if (buildCounterContentInstreamPositionTargetingOptionDetails < 3) {
    o.contentInstreamPosition = 'foo';
  }
  buildCounterContentInstreamPositionTargetingOptionDetails--;
  return o;
}

void checkContentInstreamPositionTargetingOptionDetails(
    api.ContentInstreamPositionTargetingOptionDetails o) {
  buildCounterContentInstreamPositionTargetingOptionDetails++;
  if (buildCounterContentInstreamPositionTargetingOptionDetails < 3) {
    unittest.expect(
      o.contentInstreamPosition!,
      unittest.equals('foo'),
    );
  }
  buildCounterContentInstreamPositionTargetingOptionDetails--;
}

core.int buildCounterContentOutstreamPositionAssignedTargetingOptionDetails = 0;
api.ContentOutstreamPositionAssignedTargetingOptionDetails
    buildContentOutstreamPositionAssignedTargetingOptionDetails() {
  var o = api.ContentOutstreamPositionAssignedTargetingOptionDetails();
  buildCounterContentOutstreamPositionAssignedTargetingOptionDetails++;
  if (buildCounterContentOutstreamPositionAssignedTargetingOptionDetails < 3) {
    o.adType = 'foo';
    o.contentOutstreamPosition = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterContentOutstreamPositionAssignedTargetingOptionDetails--;
  return o;
}

void checkContentOutstreamPositionAssignedTargetingOptionDetails(
    api.ContentOutstreamPositionAssignedTargetingOptionDetails o) {
  buildCounterContentOutstreamPositionAssignedTargetingOptionDetails++;
  if (buildCounterContentOutstreamPositionAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.adType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contentOutstreamPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterContentOutstreamPositionAssignedTargetingOptionDetails--;
}

core.int buildCounterContentOutstreamPositionTargetingOptionDetails = 0;
api.ContentOutstreamPositionTargetingOptionDetails
    buildContentOutstreamPositionTargetingOptionDetails() {
  var o = api.ContentOutstreamPositionTargetingOptionDetails();
  buildCounterContentOutstreamPositionTargetingOptionDetails++;
  if (buildCounterContentOutstreamPositionTargetingOptionDetails < 3) {
    o.contentOutstreamPosition = 'foo';
  }
  buildCounterContentOutstreamPositionTargetingOptionDetails--;
  return o;
}

void checkContentOutstreamPositionTargetingOptionDetails(
    api.ContentOutstreamPositionTargetingOptionDetails o) {
  buildCounterContentOutstreamPositionTargetingOptionDetails++;
  if (buildCounterContentOutstreamPositionTargetingOptionDetails < 3) {
    unittest.expect(
      o.contentOutstreamPosition!,
      unittest.equals('foo'),
    );
  }
  buildCounterContentOutstreamPositionTargetingOptionDetails--;
}

core.List<api.TrackingFloodlightActivityConfig> buildUnnamed5461() {
  var o = <api.TrackingFloodlightActivityConfig>[];
  o.add(buildTrackingFloodlightActivityConfig());
  o.add(buildTrackingFloodlightActivityConfig());
  return o;
}

void checkUnnamed5461(core.List<api.TrackingFloodlightActivityConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrackingFloodlightActivityConfig(
      o[0] as api.TrackingFloodlightActivityConfig);
  checkTrackingFloodlightActivityConfig(
      o[1] as api.TrackingFloodlightActivityConfig);
}

core.int buildCounterConversionCountingConfig = 0;
api.ConversionCountingConfig buildConversionCountingConfig() {
  var o = api.ConversionCountingConfig();
  buildCounterConversionCountingConfig++;
  if (buildCounterConversionCountingConfig < 3) {
    o.floodlightActivityConfigs = buildUnnamed5461();
    o.postViewCountPercentageMillis = 'foo';
  }
  buildCounterConversionCountingConfig--;
  return o;
}

void checkConversionCountingConfig(api.ConversionCountingConfig o) {
  buildCounterConversionCountingConfig++;
  if (buildCounterConversionCountingConfig < 3) {
    checkUnnamed5461(o.floodlightActivityConfigs!);
    unittest.expect(
      o.postViewCountPercentageMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterConversionCountingConfig--;
}

core.int buildCounterCounterEvent = 0;
api.CounterEvent buildCounterEvent() {
  var o = api.CounterEvent();
  buildCounterCounterEvent++;
  if (buildCounterCounterEvent < 3) {
    o.name = 'foo';
    o.reportingName = 'foo';
  }
  buildCounterCounterEvent--;
  return o;
}

void checkCounterEvent(api.CounterEvent o) {
  buildCounterCounterEvent++;
  if (buildCounterCounterEvent < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingName!,
      unittest.equals('foo'),
    );
  }
  buildCounterCounterEvent--;
}

core.int buildCounterCreateAssetRequest = 0;
api.CreateAssetRequest buildCreateAssetRequest() {
  var o = api.CreateAssetRequest();
  buildCounterCreateAssetRequest++;
  if (buildCounterCreateAssetRequest < 3) {
    o.filename = 'foo';
  }
  buildCounterCreateAssetRequest--;
  return o;
}

void checkCreateAssetRequest(api.CreateAssetRequest o) {
  buildCounterCreateAssetRequest++;
  if (buildCounterCreateAssetRequest < 3) {
    unittest.expect(
      o.filename!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateAssetRequest--;
}

core.int buildCounterCreateAssetResponse = 0;
api.CreateAssetResponse buildCreateAssetResponse() {
  var o = api.CreateAssetResponse();
  buildCounterCreateAssetResponse++;
  if (buildCounterCreateAssetResponse < 3) {
    o.asset = buildAsset();
  }
  buildCounterCreateAssetResponse--;
  return o;
}

void checkCreateAssetResponse(api.CreateAssetResponse o) {
  buildCounterCreateAssetResponse++;
  if (buildCounterCreateAssetResponse < 3) {
    checkAsset(o.asset! as api.Asset);
  }
  buildCounterCreateAssetResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5462() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5462(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterCreateAssignedTargetingOptionsRequest = 0;
api.CreateAssignedTargetingOptionsRequest
    buildCreateAssignedTargetingOptionsRequest() {
  var o = api.CreateAssignedTargetingOptionsRequest();
  buildCounterCreateAssignedTargetingOptionsRequest++;
  if (buildCounterCreateAssignedTargetingOptionsRequest < 3) {
    o.assignedTargetingOptions = buildUnnamed5462();
    o.targetingType = 'foo';
  }
  buildCounterCreateAssignedTargetingOptionsRequest--;
  return o;
}

void checkCreateAssignedTargetingOptionsRequest(
    api.CreateAssignedTargetingOptionsRequest o) {
  buildCounterCreateAssignedTargetingOptionsRequest++;
  if (buildCounterCreateAssignedTargetingOptionsRequest < 3) {
    checkUnnamed5462(o.assignedTargetingOptions!);
    unittest.expect(
      o.targetingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateAssignedTargetingOptionsRequest--;
}

core.int buildCounterCreateSdfDownloadTaskRequest = 0;
api.CreateSdfDownloadTaskRequest buildCreateSdfDownloadTaskRequest() {
  var o = api.CreateSdfDownloadTaskRequest();
  buildCounterCreateSdfDownloadTaskRequest++;
  if (buildCounterCreateSdfDownloadTaskRequest < 3) {
    o.advertiserId = 'foo';
    o.idFilter = buildIdFilter();
    o.inventorySourceFilter = buildInventorySourceFilter();
    o.parentEntityFilter = buildParentEntityFilter();
    o.partnerId = 'foo';
    o.version = 'foo';
  }
  buildCounterCreateSdfDownloadTaskRequest--;
  return o;
}

void checkCreateSdfDownloadTaskRequest(api.CreateSdfDownloadTaskRequest o) {
  buildCounterCreateSdfDownloadTaskRequest++;
  if (buildCounterCreateSdfDownloadTaskRequest < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkIdFilter(o.idFilter! as api.IdFilter);
    checkInventorySourceFilter(
        o.inventorySourceFilter! as api.InventorySourceFilter);
    checkParentEntityFilter(o.parentEntityFilter! as api.ParentEntityFilter);
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateSdfDownloadTaskRequest--;
}

core.List<api.Dimensions> buildUnnamed5463() {
  var o = <api.Dimensions>[];
  o.add(buildDimensions());
  o.add(buildDimensions());
  return o;
}

void checkUnnamed5463(core.List<api.Dimensions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensions(o[0] as api.Dimensions);
  checkDimensions(o[1] as api.Dimensions);
}

core.List<api.AssetAssociation> buildUnnamed5464() {
  var o = <api.AssetAssociation>[];
  o.add(buildAssetAssociation());
  o.add(buildAssetAssociation());
  return o;
}

void checkUnnamed5464(core.List<api.AssetAssociation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssetAssociation(o[0] as api.AssetAssociation);
  checkAssetAssociation(o[1] as api.AssetAssociation);
}

core.List<core.String> buildUnnamed5465() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5465(core.List<core.String> o) {
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

core.List<api.CounterEvent> buildUnnamed5466() {
  var o = <api.CounterEvent>[];
  o.add(buildCounterEvent());
  o.add(buildCounterEvent());
  return o;
}

void checkUnnamed5466(core.List<api.CounterEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCounterEvent(o[0] as api.CounterEvent);
  checkCounterEvent(o[1] as api.CounterEvent);
}

core.List<core.String> buildUnnamed5467() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5467(core.List<core.String> o) {
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

core.List<api.ExitEvent> buildUnnamed5468() {
  var o = <api.ExitEvent>[];
  o.add(buildExitEvent());
  o.add(buildExitEvent());
  return o;
}

void checkUnnamed5468(core.List<api.ExitEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExitEvent(o[0] as api.ExitEvent);
  checkExitEvent(o[1] as api.ExitEvent);
}

core.List<core.String> buildUnnamed5469() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5469(core.List<core.String> o) {
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

core.List<api.ThirdPartyUrl> buildUnnamed5470() {
  var o = <api.ThirdPartyUrl>[];
  o.add(buildThirdPartyUrl());
  o.add(buildThirdPartyUrl());
  return o;
}

void checkUnnamed5470(core.List<api.ThirdPartyUrl> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkThirdPartyUrl(o[0] as api.ThirdPartyUrl);
  checkThirdPartyUrl(o[1] as api.ThirdPartyUrl);
}

core.List<api.TimerEvent> buildUnnamed5471() {
  var o = <api.TimerEvent>[];
  o.add(buildTimerEvent());
  o.add(buildTimerEvent());
  return o;
}

void checkUnnamed5471(core.List<api.TimerEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTimerEvent(o[0] as api.TimerEvent);
  checkTimerEvent(o[1] as api.TimerEvent);
}

core.List<core.String> buildUnnamed5472() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5472(core.List<core.String> o) {
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

core.List<api.Transcode> buildUnnamed5473() {
  var o = <api.Transcode>[];
  o.add(buildTranscode());
  o.add(buildTranscode());
  return o;
}

void checkUnnamed5473(core.List<api.Transcode> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTranscode(o[0] as api.Transcode);
  checkTranscode(o[1] as api.Transcode);
}

core.int buildCounterCreative = 0;
api.Creative buildCreative() {
  var o = api.Creative();
  buildCounterCreative++;
  if (buildCounterCreative < 3) {
    o.additionalDimensions = buildUnnamed5463();
    o.advertiserId = 'foo';
    o.appendedTag = 'foo';
    o.assets = buildUnnamed5464();
    o.cmPlacementId = 'foo';
    o.cmTrackingAd = buildCmTrackingAd();
    o.companionCreativeIds = buildUnnamed5465();
    o.counterEvents = buildUnnamed5466();
    o.createTime = 'foo';
    o.creativeAttributes = buildUnnamed5467();
    o.creativeId = 'foo';
    o.creativeType = 'foo';
    o.dimensions = buildDimensions();
    o.displayName = 'foo';
    o.dynamic = true;
    o.entityStatus = 'foo';
    o.exitEvents = buildUnnamed5468();
    o.expandOnHover = true;
    o.expandingDirection = 'foo';
    o.hostingSource = 'foo';
    o.html5Video = true;
    o.iasCampaignMonitoring = true;
    o.integrationCode = 'foo';
    o.jsTrackerUrl = 'foo';
    o.lineItemIds = buildUnnamed5469();
    o.mediaDuration = 'foo';
    o.mp3Audio = true;
    o.name = 'foo';
    o.notes = 'foo';
    o.obaIcon = buildObaIcon();
    o.oggAudio = true;
    o.progressOffset = buildAudioVideoOffset();
    o.requireHtml5 = true;
    o.requireMraid = true;
    o.requirePingForAttribution = true;
    o.reviewStatus = buildReviewStatusInfo();
    o.skipOffset = buildAudioVideoOffset();
    o.skippable = true;
    o.thirdPartyTag = 'foo';
    o.thirdPartyUrls = buildUnnamed5470();
    o.timerEvents = buildUnnamed5471();
    o.trackerUrls = buildUnnamed5472();
    o.transcodes = buildUnnamed5473();
    o.universalAdId = buildUniversalAdId();
    o.updateTime = 'foo';
    o.vastTagUrl = 'foo';
    o.vpaid = true;
  }
  buildCounterCreative--;
  return o;
}

void checkCreative(api.Creative o) {
  buildCounterCreative++;
  if (buildCounterCreative < 3) {
    checkUnnamed5463(o.additionalDimensions!);
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.appendedTag!,
      unittest.equals('foo'),
    );
    checkUnnamed5464(o.assets!);
    unittest.expect(
      o.cmPlacementId!,
      unittest.equals('foo'),
    );
    checkCmTrackingAd(o.cmTrackingAd! as api.CmTrackingAd);
    checkUnnamed5465(o.companionCreativeIds!);
    checkUnnamed5466(o.counterEvents!);
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    checkUnnamed5467(o.creativeAttributes!);
    unittest.expect(
      o.creativeId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creativeType!,
      unittest.equals('foo'),
    );
    checkDimensions(o.dimensions! as api.Dimensions);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dynamic!, unittest.isTrue);
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    checkUnnamed5468(o.exitEvents!);
    unittest.expect(o.expandOnHover!, unittest.isTrue);
    unittest.expect(
      o.expandingDirection!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hostingSource!,
      unittest.equals('foo'),
    );
    unittest.expect(o.html5Video!, unittest.isTrue);
    unittest.expect(o.iasCampaignMonitoring!, unittest.isTrue);
    unittest.expect(
      o.integrationCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jsTrackerUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed5469(o.lineItemIds!);
    unittest.expect(
      o.mediaDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mp3Audio!, unittest.isTrue);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    checkObaIcon(o.obaIcon! as api.ObaIcon);
    unittest.expect(o.oggAudio!, unittest.isTrue);
    checkAudioVideoOffset(o.progressOffset! as api.AudioVideoOffset);
    unittest.expect(o.requireHtml5!, unittest.isTrue);
    unittest.expect(o.requireMraid!, unittest.isTrue);
    unittest.expect(o.requirePingForAttribution!, unittest.isTrue);
    checkReviewStatusInfo(o.reviewStatus! as api.ReviewStatusInfo);
    checkAudioVideoOffset(o.skipOffset! as api.AudioVideoOffset);
    unittest.expect(o.skippable!, unittest.isTrue);
    unittest.expect(
      o.thirdPartyTag!,
      unittest.equals('foo'),
    );
    checkUnnamed5470(o.thirdPartyUrls!);
    checkUnnamed5471(o.timerEvents!);
    checkUnnamed5472(o.trackerUrls!);
    checkUnnamed5473(o.transcodes!);
    checkUniversalAdId(o.universalAdId! as api.UniversalAdId);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.vastTagUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.vpaid!, unittest.isTrue);
  }
  buildCounterCreative--;
}

core.int buildCounterCreativeConfig = 0;
api.CreativeConfig buildCreativeConfig() {
  var o = api.CreativeConfig();
  buildCounterCreativeConfig++;
  if (buildCounterCreativeConfig < 3) {
    o.creativeType = 'foo';
    o.displayCreativeConfig = buildInventorySourceDisplayCreativeConfig();
    o.videoCreativeConfig = buildInventorySourceVideoCreativeConfig();
  }
  buildCounterCreativeConfig--;
  return o;
}

void checkCreativeConfig(api.CreativeConfig o) {
  buildCounterCreativeConfig++;
  if (buildCounterCreativeConfig < 3) {
    unittest.expect(
      o.creativeType!,
      unittest.equals('foo'),
    );
    checkInventorySourceDisplayCreativeConfig(
        o.displayCreativeConfig! as api.InventorySourceDisplayCreativeConfig);
    checkInventorySourceVideoCreativeConfig(
        o.videoCreativeConfig! as api.InventorySourceVideoCreativeConfig);
  }
  buildCounterCreativeConfig--;
}

core.int buildCounterCustomBiddingAlgorithm = 0;
api.CustomBiddingAlgorithm buildCustomBiddingAlgorithm() {
  var o = api.CustomBiddingAlgorithm();
  buildCounterCustomBiddingAlgorithm++;
  if (buildCounterCustomBiddingAlgorithm < 3) {
    o.advertiserId = 'foo';
    o.customBiddingAlgorithmId = 'foo';
    o.customBiddingAlgorithmType = 'foo';
    o.displayName = 'foo';
    o.entityStatus = 'foo';
    o.name = 'foo';
    o.partnerId = 'foo';
  }
  buildCounterCustomBiddingAlgorithm--;
  return o;
}

void checkCustomBiddingAlgorithm(api.CustomBiddingAlgorithm o) {
  buildCounterCustomBiddingAlgorithm++;
  if (buildCounterCustomBiddingAlgorithm < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customBiddingAlgorithmId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customBiddingAlgorithmType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomBiddingAlgorithm--;
}

core.int buildCounterCustomList = 0;
api.CustomList buildCustomList() {
  var o = api.CustomList();
  buildCounterCustomList++;
  if (buildCounterCustomList < 3) {
    o.customListId = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
  }
  buildCounterCustomList--;
  return o;
}

void checkCustomList(api.CustomList o) {
  buildCounterCustomList++;
  if (buildCounterCustomList < 3) {
    unittest.expect(
      o.customListId!,
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
  }
  buildCounterCustomList--;
}

core.List<api.CustomListTargetingSetting> buildUnnamed5474() {
  var o = <api.CustomListTargetingSetting>[];
  o.add(buildCustomListTargetingSetting());
  o.add(buildCustomListTargetingSetting());
  return o;
}

void checkUnnamed5474(core.List<api.CustomListTargetingSetting> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomListTargetingSetting(o[0] as api.CustomListTargetingSetting);
  checkCustomListTargetingSetting(o[1] as api.CustomListTargetingSetting);
}

core.int buildCounterCustomListGroup = 0;
api.CustomListGroup buildCustomListGroup() {
  var o = api.CustomListGroup();
  buildCounterCustomListGroup++;
  if (buildCounterCustomListGroup < 3) {
    o.settings = buildUnnamed5474();
  }
  buildCounterCustomListGroup--;
  return o;
}

void checkCustomListGroup(api.CustomListGroup o) {
  buildCounterCustomListGroup++;
  if (buildCounterCustomListGroup < 3) {
    checkUnnamed5474(o.settings!);
  }
  buildCounterCustomListGroup--;
}

core.int buildCounterCustomListTargetingSetting = 0;
api.CustomListTargetingSetting buildCustomListTargetingSetting() {
  var o = api.CustomListTargetingSetting();
  buildCounterCustomListTargetingSetting++;
  if (buildCounterCustomListTargetingSetting < 3) {
    o.customListId = 'foo';
  }
  buildCounterCustomListTargetingSetting--;
  return o;
}

void checkCustomListTargetingSetting(api.CustomListTargetingSetting o) {
  buildCounterCustomListTargetingSetting++;
  if (buildCounterCustomListTargetingSetting < 3) {
    unittest.expect(
      o.customListId!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomListTargetingSetting--;
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

core.int buildCounterDateRange = 0;
api.DateRange buildDateRange() {
  var o = api.DateRange();
  buildCounterDateRange++;
  if (buildCounterDateRange < 3) {
    o.endDate = buildDate();
    o.startDate = buildDate();
  }
  buildCounterDateRange--;
  return o;
}

void checkDateRange(api.DateRange o) {
  buildCounterDateRange++;
  if (buildCounterDateRange < 3) {
    checkDate(o.endDate! as api.Date);
    checkDate(o.startDate! as api.Date);
  }
  buildCounterDateRange--;
}

core.int buildCounterDayAndTimeAssignedTargetingOptionDetails = 0;
api.DayAndTimeAssignedTargetingOptionDetails
    buildDayAndTimeAssignedTargetingOptionDetails() {
  var o = api.DayAndTimeAssignedTargetingOptionDetails();
  buildCounterDayAndTimeAssignedTargetingOptionDetails++;
  if (buildCounterDayAndTimeAssignedTargetingOptionDetails < 3) {
    o.dayOfWeek = 'foo';
    o.endHour = 42;
    o.startHour = 42;
    o.timeZoneResolution = 'foo';
  }
  buildCounterDayAndTimeAssignedTargetingOptionDetails--;
  return o;
}

void checkDayAndTimeAssignedTargetingOptionDetails(
    api.DayAndTimeAssignedTargetingOptionDetails o) {
  buildCounterDayAndTimeAssignedTargetingOptionDetails++;
  if (buildCounterDayAndTimeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.dayOfWeek!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endHour!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startHour!,
      unittest.equals(42),
    );
    unittest.expect(
      o.timeZoneResolution!,
      unittest.equals('foo'),
    );
  }
  buildCounterDayAndTimeAssignedTargetingOptionDetails--;
}

core.int buildCounterDeactivateManualTriggerRequest = 0;
api.DeactivateManualTriggerRequest buildDeactivateManualTriggerRequest() {
  var o = api.DeactivateManualTriggerRequest();
  buildCounterDeactivateManualTriggerRequest++;
  if (buildCounterDeactivateManualTriggerRequest < 3) {}
  buildCounterDeactivateManualTriggerRequest--;
  return o;
}

void checkDeactivateManualTriggerRequest(api.DeactivateManualTriggerRequest o) {
  buildCounterDeactivateManualTriggerRequest++;
  if (buildCounterDeactivateManualTriggerRequest < 3) {}
  buildCounterDeactivateManualTriggerRequest--;
}

core.List<core.String> buildUnnamed5475() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5475(core.List<core.String> o) {
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

core.int buildCounterDeleteAssignedTargetingOptionsRequest = 0;
api.DeleteAssignedTargetingOptionsRequest
    buildDeleteAssignedTargetingOptionsRequest() {
  var o = api.DeleteAssignedTargetingOptionsRequest();
  buildCounterDeleteAssignedTargetingOptionsRequest++;
  if (buildCounterDeleteAssignedTargetingOptionsRequest < 3) {
    o.assignedTargetingOptionIds = buildUnnamed5475();
    o.targetingType = 'foo';
  }
  buildCounterDeleteAssignedTargetingOptionsRequest--;
  return o;
}

void checkDeleteAssignedTargetingOptionsRequest(
    api.DeleteAssignedTargetingOptionsRequest o) {
  buildCounterDeleteAssignedTargetingOptionsRequest++;
  if (buildCounterDeleteAssignedTargetingOptionsRequest < 3) {
    checkUnnamed5475(o.assignedTargetingOptionIds!);
    unittest.expect(
      o.targetingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteAssignedTargetingOptionsRequest--;
}

core.int buildCounterDeviceMakeModelAssignedTargetingOptionDetails = 0;
api.DeviceMakeModelAssignedTargetingOptionDetails
    buildDeviceMakeModelAssignedTargetingOptionDetails() {
  var o = api.DeviceMakeModelAssignedTargetingOptionDetails();
  buildCounterDeviceMakeModelAssignedTargetingOptionDetails++;
  if (buildCounterDeviceMakeModelAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterDeviceMakeModelAssignedTargetingOptionDetails--;
  return o;
}

void checkDeviceMakeModelAssignedTargetingOptionDetails(
    api.DeviceMakeModelAssignedTargetingOptionDetails o) {
  buildCounterDeviceMakeModelAssignedTargetingOptionDetails++;
  if (buildCounterDeviceMakeModelAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceMakeModelAssignedTargetingOptionDetails--;
}

core.int buildCounterDeviceMakeModelTargetingOptionDetails = 0;
api.DeviceMakeModelTargetingOptionDetails
    buildDeviceMakeModelTargetingOptionDetails() {
  var o = api.DeviceMakeModelTargetingOptionDetails();
  buildCounterDeviceMakeModelTargetingOptionDetails++;
  if (buildCounterDeviceMakeModelTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterDeviceMakeModelTargetingOptionDetails--;
  return o;
}

void checkDeviceMakeModelTargetingOptionDetails(
    api.DeviceMakeModelTargetingOptionDetails o) {
  buildCounterDeviceMakeModelTargetingOptionDetails++;
  if (buildCounterDeviceMakeModelTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceMakeModelTargetingOptionDetails--;
}

core.int buildCounterDeviceTypeAssignedTargetingOptionDetails = 0;
api.DeviceTypeAssignedTargetingOptionDetails
    buildDeviceTypeAssignedTargetingOptionDetails() {
  var o = api.DeviceTypeAssignedTargetingOptionDetails();
  buildCounterDeviceTypeAssignedTargetingOptionDetails++;
  if (buildCounterDeviceTypeAssignedTargetingOptionDetails < 3) {
    o.deviceType = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterDeviceTypeAssignedTargetingOptionDetails--;
  return o;
}

void checkDeviceTypeAssignedTargetingOptionDetails(
    api.DeviceTypeAssignedTargetingOptionDetails o) {
  buildCounterDeviceTypeAssignedTargetingOptionDetails++;
  if (buildCounterDeviceTypeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.deviceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceTypeAssignedTargetingOptionDetails--;
}

core.int buildCounterDeviceTypeTargetingOptionDetails = 0;
api.DeviceTypeTargetingOptionDetails buildDeviceTypeTargetingOptionDetails() {
  var o = api.DeviceTypeTargetingOptionDetails();
  buildCounterDeviceTypeTargetingOptionDetails++;
  if (buildCounterDeviceTypeTargetingOptionDetails < 3) {
    o.deviceType = 'foo';
  }
  buildCounterDeviceTypeTargetingOptionDetails--;
  return o;
}

void checkDeviceTypeTargetingOptionDetails(
    api.DeviceTypeTargetingOptionDetails o) {
  buildCounterDeviceTypeTargetingOptionDetails++;
  if (buildCounterDeviceTypeTargetingOptionDetails < 3) {
    unittest.expect(
      o.deviceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeviceTypeTargetingOptionDetails--;
}

core.int buildCounterDigitalContentLabelAssignedTargetingOptionDetails = 0;
api.DigitalContentLabelAssignedTargetingOptionDetails
    buildDigitalContentLabelAssignedTargetingOptionDetails() {
  var o = api.DigitalContentLabelAssignedTargetingOptionDetails();
  buildCounterDigitalContentLabelAssignedTargetingOptionDetails++;
  if (buildCounterDigitalContentLabelAssignedTargetingOptionDetails < 3) {
    o.contentRatingTier = 'foo';
    o.excludedTargetingOptionId = 'foo';
  }
  buildCounterDigitalContentLabelAssignedTargetingOptionDetails--;
  return o;
}

void checkDigitalContentLabelAssignedTargetingOptionDetails(
    api.DigitalContentLabelAssignedTargetingOptionDetails o) {
  buildCounterDigitalContentLabelAssignedTargetingOptionDetails++;
  if (buildCounterDigitalContentLabelAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.contentRatingTier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedTargetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDigitalContentLabelAssignedTargetingOptionDetails--;
}

core.int buildCounterDigitalContentLabelTargetingOptionDetails = 0;
api.DigitalContentLabelTargetingOptionDetails
    buildDigitalContentLabelTargetingOptionDetails() {
  var o = api.DigitalContentLabelTargetingOptionDetails();
  buildCounterDigitalContentLabelTargetingOptionDetails++;
  if (buildCounterDigitalContentLabelTargetingOptionDetails < 3) {
    o.contentRatingTier = 'foo';
  }
  buildCounterDigitalContentLabelTargetingOptionDetails--;
  return o;
}

void checkDigitalContentLabelTargetingOptionDetails(
    api.DigitalContentLabelTargetingOptionDetails o) {
  buildCounterDigitalContentLabelTargetingOptionDetails++;
  if (buildCounterDigitalContentLabelTargetingOptionDetails < 3) {
    unittest.expect(
      o.contentRatingTier!,
      unittest.equals('foo'),
    );
  }
  buildCounterDigitalContentLabelTargetingOptionDetails--;
}

core.int buildCounterDimensions = 0;
api.Dimensions buildDimensions() {
  var o = api.Dimensions();
  buildCounterDimensions++;
  if (buildCounterDimensions < 3) {
    o.heightPixels = 42;
    o.widthPixels = 42;
  }
  buildCounterDimensions--;
  return o;
}

void checkDimensions(api.Dimensions o) {
  buildCounterDimensions++;
  if (buildCounterDimensions < 3) {
    unittest.expect(
      o.heightPixels!,
      unittest.equals(42),
    );
    unittest.expect(
      o.widthPixels!,
      unittest.equals(42),
    );
  }
  buildCounterDimensions--;
}

core.List<core.String> buildUnnamed5476() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5476(core.List<core.String> o) {
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

core.int buildCounterDoubleVerify = 0;
api.DoubleVerify buildDoubleVerify() {
  var o = api.DoubleVerify();
  buildCounterDoubleVerify++;
  if (buildCounterDoubleVerify < 3) {
    o.appStarRating = buildDoubleVerifyAppStarRating();
    o.avoidedAgeRatings = buildUnnamed5476();
    o.brandSafetyCategories = buildDoubleVerifyBrandSafetyCategories();
    o.customSegmentId = 'foo';
    o.displayViewability = buildDoubleVerifyDisplayViewability();
    o.fraudInvalidTraffic = buildDoubleVerifyFraudInvalidTraffic();
    o.videoViewability = buildDoubleVerifyVideoViewability();
  }
  buildCounterDoubleVerify--;
  return o;
}

void checkDoubleVerify(api.DoubleVerify o) {
  buildCounterDoubleVerify++;
  if (buildCounterDoubleVerify < 3) {
    checkDoubleVerifyAppStarRating(
        o.appStarRating! as api.DoubleVerifyAppStarRating);
    checkUnnamed5476(o.avoidedAgeRatings!);
    checkDoubleVerifyBrandSafetyCategories(
        o.brandSafetyCategories! as api.DoubleVerifyBrandSafetyCategories);
    unittest.expect(
      o.customSegmentId!,
      unittest.equals('foo'),
    );
    checkDoubleVerifyDisplayViewability(
        o.displayViewability! as api.DoubleVerifyDisplayViewability);
    checkDoubleVerifyFraudInvalidTraffic(
        o.fraudInvalidTraffic! as api.DoubleVerifyFraudInvalidTraffic);
    checkDoubleVerifyVideoViewability(
        o.videoViewability! as api.DoubleVerifyVideoViewability);
  }
  buildCounterDoubleVerify--;
}

core.int buildCounterDoubleVerifyAppStarRating = 0;
api.DoubleVerifyAppStarRating buildDoubleVerifyAppStarRating() {
  var o = api.DoubleVerifyAppStarRating();
  buildCounterDoubleVerifyAppStarRating++;
  if (buildCounterDoubleVerifyAppStarRating < 3) {
    o.avoidInsufficientStarRating = true;
    o.avoidedStarRating = 'foo';
  }
  buildCounterDoubleVerifyAppStarRating--;
  return o;
}

void checkDoubleVerifyAppStarRating(api.DoubleVerifyAppStarRating o) {
  buildCounterDoubleVerifyAppStarRating++;
  if (buildCounterDoubleVerifyAppStarRating < 3) {
    unittest.expect(o.avoidInsufficientStarRating!, unittest.isTrue);
    unittest.expect(
      o.avoidedStarRating!,
      unittest.equals('foo'),
    );
  }
  buildCounterDoubleVerifyAppStarRating--;
}

core.List<core.String> buildUnnamed5477() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5477(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5478() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5478(core.List<core.String> o) {
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

core.int buildCounterDoubleVerifyBrandSafetyCategories = 0;
api.DoubleVerifyBrandSafetyCategories buildDoubleVerifyBrandSafetyCategories() {
  var o = api.DoubleVerifyBrandSafetyCategories();
  buildCounterDoubleVerifyBrandSafetyCategories++;
  if (buildCounterDoubleVerifyBrandSafetyCategories < 3) {
    o.avoidUnknownBrandSafetyCategory = true;
    o.avoidedHighSeverityCategories = buildUnnamed5477();
    o.avoidedMediumSeverityCategories = buildUnnamed5478();
  }
  buildCounterDoubleVerifyBrandSafetyCategories--;
  return o;
}

void checkDoubleVerifyBrandSafetyCategories(
    api.DoubleVerifyBrandSafetyCategories o) {
  buildCounterDoubleVerifyBrandSafetyCategories++;
  if (buildCounterDoubleVerifyBrandSafetyCategories < 3) {
    unittest.expect(o.avoidUnknownBrandSafetyCategory!, unittest.isTrue);
    checkUnnamed5477(o.avoidedHighSeverityCategories!);
    checkUnnamed5478(o.avoidedMediumSeverityCategories!);
  }
  buildCounterDoubleVerifyBrandSafetyCategories--;
}

core.int buildCounterDoubleVerifyDisplayViewability = 0;
api.DoubleVerifyDisplayViewability buildDoubleVerifyDisplayViewability() {
  var o = api.DoubleVerifyDisplayViewability();
  buildCounterDoubleVerifyDisplayViewability++;
  if (buildCounterDoubleVerifyDisplayViewability < 3) {
    o.iab = 'foo';
    o.viewableDuring = 'foo';
  }
  buildCounterDoubleVerifyDisplayViewability--;
  return o;
}

void checkDoubleVerifyDisplayViewability(api.DoubleVerifyDisplayViewability o) {
  buildCounterDoubleVerifyDisplayViewability++;
  if (buildCounterDoubleVerifyDisplayViewability < 3) {
    unittest.expect(
      o.iab!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewableDuring!,
      unittest.equals('foo'),
    );
  }
  buildCounterDoubleVerifyDisplayViewability--;
}

core.int buildCounterDoubleVerifyFraudInvalidTraffic = 0;
api.DoubleVerifyFraudInvalidTraffic buildDoubleVerifyFraudInvalidTraffic() {
  var o = api.DoubleVerifyFraudInvalidTraffic();
  buildCounterDoubleVerifyFraudInvalidTraffic++;
  if (buildCounterDoubleVerifyFraudInvalidTraffic < 3) {
    o.avoidInsufficientOption = true;
    o.avoidedFraudOption = 'foo';
  }
  buildCounterDoubleVerifyFraudInvalidTraffic--;
  return o;
}

void checkDoubleVerifyFraudInvalidTraffic(
    api.DoubleVerifyFraudInvalidTraffic o) {
  buildCounterDoubleVerifyFraudInvalidTraffic++;
  if (buildCounterDoubleVerifyFraudInvalidTraffic < 3) {
    unittest.expect(o.avoidInsufficientOption!, unittest.isTrue);
    unittest.expect(
      o.avoidedFraudOption!,
      unittest.equals('foo'),
    );
  }
  buildCounterDoubleVerifyFraudInvalidTraffic--;
}

core.int buildCounterDoubleVerifyVideoViewability = 0;
api.DoubleVerifyVideoViewability buildDoubleVerifyVideoViewability() {
  var o = api.DoubleVerifyVideoViewability();
  buildCounterDoubleVerifyVideoViewability++;
  if (buildCounterDoubleVerifyVideoViewability < 3) {
    o.playerImpressionRate = 'foo';
    o.videoIab = 'foo';
    o.videoViewableRate = 'foo';
  }
  buildCounterDoubleVerifyVideoViewability--;
  return o;
}

void checkDoubleVerifyVideoViewability(api.DoubleVerifyVideoViewability o) {
  buildCounterDoubleVerifyVideoViewability++;
  if (buildCounterDoubleVerifyVideoViewability < 3) {
    unittest.expect(
      o.playerImpressionRate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoIab!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoViewableRate!,
      unittest.equals('foo'),
    );
  }
  buildCounterDoubleVerifyVideoViewability--;
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

core.int buildCounterEnvironmentAssignedTargetingOptionDetails = 0;
api.EnvironmentAssignedTargetingOptionDetails
    buildEnvironmentAssignedTargetingOptionDetails() {
  var o = api.EnvironmentAssignedTargetingOptionDetails();
  buildCounterEnvironmentAssignedTargetingOptionDetails++;
  if (buildCounterEnvironmentAssignedTargetingOptionDetails < 3) {
    o.environment = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterEnvironmentAssignedTargetingOptionDetails--;
  return o;
}

void checkEnvironmentAssignedTargetingOptionDetails(
    api.EnvironmentAssignedTargetingOptionDetails o) {
  buildCounterEnvironmentAssignedTargetingOptionDetails++;
  if (buildCounterEnvironmentAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.environment!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnvironmentAssignedTargetingOptionDetails--;
}

core.int buildCounterEnvironmentTargetingOptionDetails = 0;
api.EnvironmentTargetingOptionDetails buildEnvironmentTargetingOptionDetails() {
  var o = api.EnvironmentTargetingOptionDetails();
  buildCounterEnvironmentTargetingOptionDetails++;
  if (buildCounterEnvironmentTargetingOptionDetails < 3) {
    o.environment = 'foo';
  }
  buildCounterEnvironmentTargetingOptionDetails--;
  return o;
}

void checkEnvironmentTargetingOptionDetails(
    api.EnvironmentTargetingOptionDetails o) {
  buildCounterEnvironmentTargetingOptionDetails++;
  if (buildCounterEnvironmentTargetingOptionDetails < 3) {
    unittest.expect(
      o.environment!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnvironmentTargetingOptionDetails--;
}

core.int buildCounterExchangeAssignedTargetingOptionDetails = 0;
api.ExchangeAssignedTargetingOptionDetails
    buildExchangeAssignedTargetingOptionDetails() {
  var o = api.ExchangeAssignedTargetingOptionDetails();
  buildCounterExchangeAssignedTargetingOptionDetails++;
  if (buildCounterExchangeAssignedTargetingOptionDetails < 3) {
    o.targetingOptionId = 'foo';
  }
  buildCounterExchangeAssignedTargetingOptionDetails--;
  return o;
}

void checkExchangeAssignedTargetingOptionDetails(
    api.ExchangeAssignedTargetingOptionDetails o) {
  buildCounterExchangeAssignedTargetingOptionDetails++;
  if (buildCounterExchangeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterExchangeAssignedTargetingOptionDetails--;
}

core.List<api.ExchangeConfigEnabledExchange> buildUnnamed5479() {
  var o = <api.ExchangeConfigEnabledExchange>[];
  o.add(buildExchangeConfigEnabledExchange());
  o.add(buildExchangeConfigEnabledExchange());
  return o;
}

void checkUnnamed5479(core.List<api.ExchangeConfigEnabledExchange> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExchangeConfigEnabledExchange(o[0] as api.ExchangeConfigEnabledExchange);
  checkExchangeConfigEnabledExchange(o[1] as api.ExchangeConfigEnabledExchange);
}

core.int buildCounterExchangeConfig = 0;
api.ExchangeConfig buildExchangeConfig() {
  var o = api.ExchangeConfig();
  buildCounterExchangeConfig++;
  if (buildCounterExchangeConfig < 3) {
    o.enabledExchanges = buildUnnamed5479();
  }
  buildCounterExchangeConfig--;
  return o;
}

void checkExchangeConfig(api.ExchangeConfig o) {
  buildCounterExchangeConfig++;
  if (buildCounterExchangeConfig < 3) {
    checkUnnamed5479(o.enabledExchanges!);
  }
  buildCounterExchangeConfig--;
}

core.int buildCounterExchangeConfigEnabledExchange = 0;
api.ExchangeConfigEnabledExchange buildExchangeConfigEnabledExchange() {
  var o = api.ExchangeConfigEnabledExchange();
  buildCounterExchangeConfigEnabledExchange++;
  if (buildCounterExchangeConfigEnabledExchange < 3) {
    o.exchange = 'foo';
    o.googleAdManagerAgencyId = 'foo';
    o.googleAdManagerBuyerNetworkId = 'foo';
    o.seatId = 'foo';
  }
  buildCounterExchangeConfigEnabledExchange--;
  return o;
}

void checkExchangeConfigEnabledExchange(api.ExchangeConfigEnabledExchange o) {
  buildCounterExchangeConfigEnabledExchange++;
  if (buildCounterExchangeConfigEnabledExchange < 3) {
    unittest.expect(
      o.exchange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googleAdManagerAgencyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googleAdManagerBuyerNetworkId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.seatId!,
      unittest.equals('foo'),
    );
  }
  buildCounterExchangeConfigEnabledExchange--;
}

core.int buildCounterExchangeReviewStatus = 0;
api.ExchangeReviewStatus buildExchangeReviewStatus() {
  var o = api.ExchangeReviewStatus();
  buildCounterExchangeReviewStatus++;
  if (buildCounterExchangeReviewStatus < 3) {
    o.exchange = 'foo';
    o.status = 'foo';
  }
  buildCounterExchangeReviewStatus--;
  return o;
}

void checkExchangeReviewStatus(api.ExchangeReviewStatus o) {
  buildCounterExchangeReviewStatus++;
  if (buildCounterExchangeReviewStatus < 3) {
    unittest.expect(
      o.exchange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterExchangeReviewStatus--;
}

core.int buildCounterExchangeTargetingOptionDetails = 0;
api.ExchangeTargetingOptionDetails buildExchangeTargetingOptionDetails() {
  var o = api.ExchangeTargetingOptionDetails();
  buildCounterExchangeTargetingOptionDetails++;
  if (buildCounterExchangeTargetingOptionDetails < 3) {
    o.exchange = 'foo';
  }
  buildCounterExchangeTargetingOptionDetails--;
  return o;
}

void checkExchangeTargetingOptionDetails(api.ExchangeTargetingOptionDetails o) {
  buildCounterExchangeTargetingOptionDetails++;
  if (buildCounterExchangeTargetingOptionDetails < 3) {
    unittest.expect(
      o.exchange!,
      unittest.equals('foo'),
    );
  }
  buildCounterExchangeTargetingOptionDetails--;
}

core.int buildCounterExitEvent = 0;
api.ExitEvent buildExitEvent() {
  var o = api.ExitEvent();
  buildCounterExitEvent++;
  if (buildCounterExitEvent < 3) {
    o.name = 'foo';
    o.reportingName = 'foo';
    o.type = 'foo';
    o.url = 'foo';
  }
  buildCounterExitEvent--;
  return o;
}

void checkExitEvent(api.ExitEvent o) {
  buildCounterExitEvent++;
  if (buildCounterExitEvent < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterExitEvent--;
}

core.int buildCounterFirstAndThirdPartyAudience = 0;
api.FirstAndThirdPartyAudience buildFirstAndThirdPartyAudience() {
  var o = api.FirstAndThirdPartyAudience();
  buildCounterFirstAndThirdPartyAudience++;
  if (buildCounterFirstAndThirdPartyAudience < 3) {
    o.activeDisplayAudienceSize = 'foo';
    o.audienceSource = 'foo';
    o.audienceType = 'foo';
    o.description = 'foo';
    o.displayAudienceSize = 'foo';
    o.displayDesktopAudienceSize = 'foo';
    o.displayMobileAppAudienceSize = 'foo';
    o.displayMobileWebAudienceSize = 'foo';
    o.displayName = 'foo';
    o.firstAndThirdPartyAudienceId = 'foo';
    o.firstAndThirdPartyAudienceType = 'foo';
    o.gmailAudienceSize = 'foo';
    o.membershipDurationDays = 'foo';
    o.name = 'foo';
    o.youtubeAudienceSize = 'foo';
  }
  buildCounterFirstAndThirdPartyAudience--;
  return o;
}

void checkFirstAndThirdPartyAudience(api.FirstAndThirdPartyAudience o) {
  buildCounterFirstAndThirdPartyAudience++;
  if (buildCounterFirstAndThirdPartyAudience < 3) {
    unittest.expect(
      o.activeDisplayAudienceSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.audienceSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.audienceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayAudienceSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayDesktopAudienceSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayMobileAppAudienceSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayMobileWebAudienceSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firstAndThirdPartyAudienceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firstAndThirdPartyAudienceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.gmailAudienceSize!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.membershipDurationDays!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.youtubeAudienceSize!,
      unittest.equals('foo'),
    );
  }
  buildCounterFirstAndThirdPartyAudience--;
}

core.List<api.FirstAndThirdPartyAudienceTargetingSetting> buildUnnamed5480() {
  var o = <api.FirstAndThirdPartyAudienceTargetingSetting>[];
  o.add(buildFirstAndThirdPartyAudienceTargetingSetting());
  o.add(buildFirstAndThirdPartyAudienceTargetingSetting());
  return o;
}

void checkUnnamed5480(
    core.List<api.FirstAndThirdPartyAudienceTargetingSetting> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFirstAndThirdPartyAudienceTargetingSetting(
      o[0] as api.FirstAndThirdPartyAudienceTargetingSetting);
  checkFirstAndThirdPartyAudienceTargetingSetting(
      o[1] as api.FirstAndThirdPartyAudienceTargetingSetting);
}

core.int buildCounterFirstAndThirdPartyAudienceGroup = 0;
api.FirstAndThirdPartyAudienceGroup buildFirstAndThirdPartyAudienceGroup() {
  var o = api.FirstAndThirdPartyAudienceGroup();
  buildCounterFirstAndThirdPartyAudienceGroup++;
  if (buildCounterFirstAndThirdPartyAudienceGroup < 3) {
    o.settings = buildUnnamed5480();
  }
  buildCounterFirstAndThirdPartyAudienceGroup--;
  return o;
}

void checkFirstAndThirdPartyAudienceGroup(
    api.FirstAndThirdPartyAudienceGroup o) {
  buildCounterFirstAndThirdPartyAudienceGroup++;
  if (buildCounterFirstAndThirdPartyAudienceGroup < 3) {
    checkUnnamed5480(o.settings!);
  }
  buildCounterFirstAndThirdPartyAudienceGroup--;
}

core.int buildCounterFirstAndThirdPartyAudienceTargetingSetting = 0;
api.FirstAndThirdPartyAudienceTargetingSetting
    buildFirstAndThirdPartyAudienceTargetingSetting() {
  var o = api.FirstAndThirdPartyAudienceTargetingSetting();
  buildCounterFirstAndThirdPartyAudienceTargetingSetting++;
  if (buildCounterFirstAndThirdPartyAudienceTargetingSetting < 3) {
    o.firstAndThirdPartyAudienceId = 'foo';
    o.recency = 'foo';
  }
  buildCounterFirstAndThirdPartyAudienceTargetingSetting--;
  return o;
}

void checkFirstAndThirdPartyAudienceTargetingSetting(
    api.FirstAndThirdPartyAudienceTargetingSetting o) {
  buildCounterFirstAndThirdPartyAudienceTargetingSetting++;
  if (buildCounterFirstAndThirdPartyAudienceTargetingSetting < 3) {
    unittest.expect(
      o.firstAndThirdPartyAudienceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recency!,
      unittest.equals('foo'),
    );
  }
  buildCounterFirstAndThirdPartyAudienceTargetingSetting--;
}

core.int buildCounterFixedBidStrategy = 0;
api.FixedBidStrategy buildFixedBidStrategy() {
  var o = api.FixedBidStrategy();
  buildCounterFixedBidStrategy++;
  if (buildCounterFixedBidStrategy < 3) {
    o.bidAmountMicros = 'foo';
  }
  buildCounterFixedBidStrategy--;
  return o;
}

void checkFixedBidStrategy(api.FixedBidStrategy o) {
  buildCounterFixedBidStrategy++;
  if (buildCounterFixedBidStrategy < 3) {
    unittest.expect(
      o.bidAmountMicros!,
      unittest.equals('foo'),
    );
  }
  buildCounterFixedBidStrategy--;
}

core.Map<core.String, core.Object> buildUnnamed5481() {
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

void checkUnnamed5481(core.Map<core.String, core.Object> o) {
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

core.int buildCounterFloodlightGroup = 0;
api.FloodlightGroup buildFloodlightGroup() {
  var o = api.FloodlightGroup();
  buildCounterFloodlightGroup++;
  if (buildCounterFloodlightGroup < 3) {
    o.activeViewConfig = buildActiveViewVideoViewabilityMetricConfig();
    o.customVariables = buildUnnamed5481();
    o.displayName = 'foo';
    o.floodlightGroupId = 'foo';
    o.lookbackWindow = buildLookbackWindow();
    o.name = 'foo';
    o.webTagType = 'foo';
  }
  buildCounterFloodlightGroup--;
  return o;
}

void checkFloodlightGroup(api.FloodlightGroup o) {
  buildCounterFloodlightGroup++;
  if (buildCounterFloodlightGroup < 3) {
    checkActiveViewVideoViewabilityMetricConfig(
        o.activeViewConfig! as api.ActiveViewVideoViewabilityMetricConfig);
    checkUnnamed5481(o.customVariables!);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floodlightGroupId!,
      unittest.equals('foo'),
    );
    checkLookbackWindow(o.lookbackWindow! as api.LookbackWindow);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webTagType!,
      unittest.equals('foo'),
    );
  }
  buildCounterFloodlightGroup--;
}

core.int buildCounterFrequencyCap = 0;
api.FrequencyCap buildFrequencyCap() {
  var o = api.FrequencyCap();
  buildCounterFrequencyCap++;
  if (buildCounterFrequencyCap < 3) {
    o.maxImpressions = 42;
    o.timeUnit = 'foo';
    o.timeUnitCount = 42;
    o.unlimited = true;
  }
  buildCounterFrequencyCap--;
  return o;
}

void checkFrequencyCap(api.FrequencyCap o) {
  buildCounterFrequencyCap++;
  if (buildCounterFrequencyCap < 3) {
    unittest.expect(
      o.maxImpressions!,
      unittest.equals(42),
    );
    unittest.expect(
      o.timeUnit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeUnitCount!,
      unittest.equals(42),
    );
    unittest.expect(o.unlimited!, unittest.isTrue);
  }
  buildCounterFrequencyCap--;
}

core.int buildCounterGenderAssignedTargetingOptionDetails = 0;
api.GenderAssignedTargetingOptionDetails
    buildGenderAssignedTargetingOptionDetails() {
  var o = api.GenderAssignedTargetingOptionDetails();
  buildCounterGenderAssignedTargetingOptionDetails++;
  if (buildCounterGenderAssignedTargetingOptionDetails < 3) {
    o.gender = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterGenderAssignedTargetingOptionDetails--;
  return o;
}

void checkGenderAssignedTargetingOptionDetails(
    api.GenderAssignedTargetingOptionDetails o) {
  buildCounterGenderAssignedTargetingOptionDetails++;
  if (buildCounterGenderAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.gender!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGenderAssignedTargetingOptionDetails--;
}

core.int buildCounterGenderTargetingOptionDetails = 0;
api.GenderTargetingOptionDetails buildGenderTargetingOptionDetails() {
  var o = api.GenderTargetingOptionDetails();
  buildCounterGenderTargetingOptionDetails++;
  if (buildCounterGenderTargetingOptionDetails < 3) {
    o.gender = 'foo';
  }
  buildCounterGenderTargetingOptionDetails--;
  return o;
}

void checkGenderTargetingOptionDetails(api.GenderTargetingOptionDetails o) {
  buildCounterGenderTargetingOptionDetails++;
  if (buildCounterGenderTargetingOptionDetails < 3) {
    unittest.expect(
      o.gender!,
      unittest.equals('foo'),
    );
  }
  buildCounterGenderTargetingOptionDetails--;
}

core.int buildCounterGenerateDefaultLineItemRequest = 0;
api.GenerateDefaultLineItemRequest buildGenerateDefaultLineItemRequest() {
  var o = api.GenerateDefaultLineItemRequest();
  buildCounterGenerateDefaultLineItemRequest++;
  if (buildCounterGenerateDefaultLineItemRequest < 3) {
    o.displayName = 'foo';
    o.insertionOrderId = 'foo';
    o.lineItemType = 'foo';
    o.mobileApp = buildMobileApp();
  }
  buildCounterGenerateDefaultLineItemRequest--;
  return o;
}

void checkGenerateDefaultLineItemRequest(api.GenerateDefaultLineItemRequest o) {
  buildCounterGenerateDefaultLineItemRequest++;
  if (buildCounterGenerateDefaultLineItemRequest < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertionOrderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lineItemType!,
      unittest.equals('foo'),
    );
    checkMobileApp(o.mobileApp! as api.MobileApp);
  }
  buildCounterGenerateDefaultLineItemRequest--;
}

core.int buildCounterGeoRegionAssignedTargetingOptionDetails = 0;
api.GeoRegionAssignedTargetingOptionDetails
    buildGeoRegionAssignedTargetingOptionDetails() {
  var o = api.GeoRegionAssignedTargetingOptionDetails();
  buildCounterGeoRegionAssignedTargetingOptionDetails++;
  if (buildCounterGeoRegionAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.geoRegionType = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterGeoRegionAssignedTargetingOptionDetails--;
  return o;
}

void checkGeoRegionAssignedTargetingOptionDetails(
    api.GeoRegionAssignedTargetingOptionDetails o) {
  buildCounterGeoRegionAssignedTargetingOptionDetails++;
  if (buildCounterGeoRegionAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.geoRegionType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGeoRegionAssignedTargetingOptionDetails--;
}

core.int buildCounterGeoRegionSearchTerms = 0;
api.GeoRegionSearchTerms buildGeoRegionSearchTerms() {
  var o = api.GeoRegionSearchTerms();
  buildCounterGeoRegionSearchTerms++;
  if (buildCounterGeoRegionSearchTerms < 3) {
    o.geoRegionQuery = 'foo';
  }
  buildCounterGeoRegionSearchTerms--;
  return o;
}

void checkGeoRegionSearchTerms(api.GeoRegionSearchTerms o) {
  buildCounterGeoRegionSearchTerms++;
  if (buildCounterGeoRegionSearchTerms < 3) {
    unittest.expect(
      o.geoRegionQuery!,
      unittest.equals('foo'),
    );
  }
  buildCounterGeoRegionSearchTerms--;
}

core.int buildCounterGeoRegionTargetingOptionDetails = 0;
api.GeoRegionTargetingOptionDetails buildGeoRegionTargetingOptionDetails() {
  var o = api.GeoRegionTargetingOptionDetails();
  buildCounterGeoRegionTargetingOptionDetails++;
  if (buildCounterGeoRegionTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.geoRegionType = 'foo';
  }
  buildCounterGeoRegionTargetingOptionDetails--;
  return o;
}

void checkGeoRegionTargetingOptionDetails(
    api.GeoRegionTargetingOptionDetails o) {
  buildCounterGeoRegionTargetingOptionDetails++;
  if (buildCounterGeoRegionTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.geoRegionType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGeoRegionTargetingOptionDetails--;
}

core.int buildCounterGoogleAudience = 0;
api.GoogleAudience buildGoogleAudience() {
  var o = api.GoogleAudience();
  buildCounterGoogleAudience++;
  if (buildCounterGoogleAudience < 3) {
    o.displayName = 'foo';
    o.googleAudienceId = 'foo';
    o.googleAudienceType = 'foo';
    o.name = 'foo';
  }
  buildCounterGoogleAudience--;
  return o;
}

void checkGoogleAudience(api.GoogleAudience o) {
  buildCounterGoogleAudience++;
  if (buildCounterGoogleAudience < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googleAudienceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googleAudienceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAudience--;
}

core.List<api.GoogleAudienceTargetingSetting> buildUnnamed5482() {
  var o = <api.GoogleAudienceTargetingSetting>[];
  o.add(buildGoogleAudienceTargetingSetting());
  o.add(buildGoogleAudienceTargetingSetting());
  return o;
}

void checkUnnamed5482(core.List<api.GoogleAudienceTargetingSetting> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleAudienceTargetingSetting(
      o[0] as api.GoogleAudienceTargetingSetting);
  checkGoogleAudienceTargetingSetting(
      o[1] as api.GoogleAudienceTargetingSetting);
}

core.int buildCounterGoogleAudienceGroup = 0;
api.GoogleAudienceGroup buildGoogleAudienceGroup() {
  var o = api.GoogleAudienceGroup();
  buildCounterGoogleAudienceGroup++;
  if (buildCounterGoogleAudienceGroup < 3) {
    o.settings = buildUnnamed5482();
  }
  buildCounterGoogleAudienceGroup--;
  return o;
}

void checkGoogleAudienceGroup(api.GoogleAudienceGroup o) {
  buildCounterGoogleAudienceGroup++;
  if (buildCounterGoogleAudienceGroup < 3) {
    checkUnnamed5482(o.settings!);
  }
  buildCounterGoogleAudienceGroup--;
}

core.int buildCounterGoogleAudienceTargetingSetting = 0;
api.GoogleAudienceTargetingSetting buildGoogleAudienceTargetingSetting() {
  var o = api.GoogleAudienceTargetingSetting();
  buildCounterGoogleAudienceTargetingSetting++;
  if (buildCounterGoogleAudienceTargetingSetting < 3) {
    o.googleAudienceId = 'foo';
  }
  buildCounterGoogleAudienceTargetingSetting--;
  return o;
}

void checkGoogleAudienceTargetingSetting(api.GoogleAudienceTargetingSetting o) {
  buildCounterGoogleAudienceTargetingSetting++;
  if (buildCounterGoogleAudienceTargetingSetting < 3) {
    unittest.expect(
      o.googleAudienceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleAudienceTargetingSetting--;
}

core.int buildCounterGoogleBytestreamMedia = 0;
api.GoogleBytestreamMedia buildGoogleBytestreamMedia() {
  var o = api.GoogleBytestreamMedia();
  buildCounterGoogleBytestreamMedia++;
  if (buildCounterGoogleBytestreamMedia < 3) {
    o.resourceName = 'foo';
  }
  buildCounterGoogleBytestreamMedia--;
  return o;
}

void checkGoogleBytestreamMedia(api.GoogleBytestreamMedia o) {
  buildCounterGoogleBytestreamMedia++;
  if (buildCounterGoogleBytestreamMedia < 3) {
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleBytestreamMedia--;
}

core.int buildCounterHouseholdIncomeAssignedTargetingOptionDetails = 0;
api.HouseholdIncomeAssignedTargetingOptionDetails
    buildHouseholdIncomeAssignedTargetingOptionDetails() {
  var o = api.HouseholdIncomeAssignedTargetingOptionDetails();
  buildCounterHouseholdIncomeAssignedTargetingOptionDetails++;
  if (buildCounterHouseholdIncomeAssignedTargetingOptionDetails < 3) {
    o.householdIncome = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterHouseholdIncomeAssignedTargetingOptionDetails--;
  return o;
}

void checkHouseholdIncomeAssignedTargetingOptionDetails(
    api.HouseholdIncomeAssignedTargetingOptionDetails o) {
  buildCounterHouseholdIncomeAssignedTargetingOptionDetails++;
  if (buildCounterHouseholdIncomeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.householdIncome!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterHouseholdIncomeAssignedTargetingOptionDetails--;
}

core.int buildCounterHouseholdIncomeTargetingOptionDetails = 0;
api.HouseholdIncomeTargetingOptionDetails
    buildHouseholdIncomeTargetingOptionDetails() {
  var o = api.HouseholdIncomeTargetingOptionDetails();
  buildCounterHouseholdIncomeTargetingOptionDetails++;
  if (buildCounterHouseholdIncomeTargetingOptionDetails < 3) {
    o.householdIncome = 'foo';
  }
  buildCounterHouseholdIncomeTargetingOptionDetails--;
  return o;
}

void checkHouseholdIncomeTargetingOptionDetails(
    api.HouseholdIncomeTargetingOptionDetails o) {
  buildCounterHouseholdIncomeTargetingOptionDetails++;
  if (buildCounterHouseholdIncomeTargetingOptionDetails < 3) {
    unittest.expect(
      o.householdIncome!,
      unittest.equals('foo'),
    );
  }
  buildCounterHouseholdIncomeTargetingOptionDetails--;
}

core.List<core.String> buildUnnamed5483() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5483(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5484() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5484(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5485() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5485(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5486() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5486(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5487() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5487(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5488() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5488(core.List<core.String> o) {
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

core.int buildCounterIdFilter = 0;
api.IdFilter buildIdFilter() {
  var o = api.IdFilter();
  buildCounterIdFilter++;
  if (buildCounterIdFilter < 3) {
    o.adGroupAdIds = buildUnnamed5483();
    o.adGroupIds = buildUnnamed5484();
    o.campaignIds = buildUnnamed5485();
    o.insertionOrderIds = buildUnnamed5486();
    o.lineItemIds = buildUnnamed5487();
    o.mediaProductIds = buildUnnamed5488();
  }
  buildCounterIdFilter--;
  return o;
}

void checkIdFilter(api.IdFilter o) {
  buildCounterIdFilter++;
  if (buildCounterIdFilter < 3) {
    checkUnnamed5483(o.adGroupAdIds!);
    checkUnnamed5484(o.adGroupIds!);
    checkUnnamed5485(o.campaignIds!);
    checkUnnamed5486(o.insertionOrderIds!);
    checkUnnamed5487(o.lineItemIds!);
    checkUnnamed5488(o.mediaProductIds!);
  }
  buildCounterIdFilter--;
}

core.List<api.PartnerCost> buildUnnamed5489() {
  var o = <api.PartnerCost>[];
  o.add(buildPartnerCost());
  o.add(buildPartnerCost());
  return o;
}

void checkUnnamed5489(core.List<api.PartnerCost> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPartnerCost(o[0] as api.PartnerCost);
  checkPartnerCost(o[1] as api.PartnerCost);
}

core.int buildCounterInsertionOrder = 0;
api.InsertionOrder buildInsertionOrder() {
  var o = api.InsertionOrder();
  buildCounterInsertionOrder++;
  if (buildCounterInsertionOrder < 3) {
    o.advertiserId = 'foo';
    o.bidStrategy = buildBiddingStrategy();
    o.budget = buildInsertionOrderBudget();
    o.campaignId = 'foo';
    o.displayName = 'foo';
    o.entityStatus = 'foo';
    o.frequencyCap = buildFrequencyCap();
    o.insertionOrderId = 'foo';
    o.insertionOrderType = 'foo';
    o.integrationDetails = buildIntegrationDetails();
    o.name = 'foo';
    o.pacing = buildPacing();
    o.partnerCosts = buildUnnamed5489();
    o.performanceGoal = buildPerformanceGoal();
    o.updateTime = 'foo';
  }
  buildCounterInsertionOrder--;
  return o;
}

void checkInsertionOrder(api.InsertionOrder o) {
  buildCounterInsertionOrder++;
  if (buildCounterInsertionOrder < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkBiddingStrategy(o.bidStrategy! as api.BiddingStrategy);
    checkInsertionOrderBudget(o.budget! as api.InsertionOrderBudget);
    unittest.expect(
      o.campaignId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    checkFrequencyCap(o.frequencyCap! as api.FrequencyCap);
    unittest.expect(
      o.insertionOrderId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.insertionOrderType!,
      unittest.equals('foo'),
    );
    checkIntegrationDetails(o.integrationDetails! as api.IntegrationDetails);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPacing(o.pacing! as api.Pacing);
    checkUnnamed5489(o.partnerCosts!);
    checkPerformanceGoal(o.performanceGoal! as api.PerformanceGoal);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertionOrder--;
}

core.List<api.InsertionOrderBudgetSegment> buildUnnamed5490() {
  var o = <api.InsertionOrderBudgetSegment>[];
  o.add(buildInsertionOrderBudgetSegment());
  o.add(buildInsertionOrderBudgetSegment());
  return o;
}

void checkUnnamed5490(core.List<api.InsertionOrderBudgetSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInsertionOrderBudgetSegment(o[0] as api.InsertionOrderBudgetSegment);
  checkInsertionOrderBudgetSegment(o[1] as api.InsertionOrderBudgetSegment);
}

core.int buildCounterInsertionOrderBudget = 0;
api.InsertionOrderBudget buildInsertionOrderBudget() {
  var o = api.InsertionOrderBudget();
  buildCounterInsertionOrderBudget++;
  if (buildCounterInsertionOrderBudget < 3) {
    o.automationType = 'foo';
    o.budgetSegments = buildUnnamed5490();
    o.budgetUnit = 'foo';
  }
  buildCounterInsertionOrderBudget--;
  return o;
}

void checkInsertionOrderBudget(api.InsertionOrderBudget o) {
  buildCounterInsertionOrderBudget++;
  if (buildCounterInsertionOrderBudget < 3) {
    unittest.expect(
      o.automationType!,
      unittest.equals('foo'),
    );
    checkUnnamed5490(o.budgetSegments!);
    unittest.expect(
      o.budgetUnit!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertionOrderBudget--;
}

core.int buildCounterInsertionOrderBudgetSegment = 0;
api.InsertionOrderBudgetSegment buildInsertionOrderBudgetSegment() {
  var o = api.InsertionOrderBudgetSegment();
  buildCounterInsertionOrderBudgetSegment++;
  if (buildCounterInsertionOrderBudgetSegment < 3) {
    o.budgetAmountMicros = 'foo';
    o.campaignBudgetId = 'foo';
    o.dateRange = buildDateRange();
    o.description = 'foo';
  }
  buildCounterInsertionOrderBudgetSegment--;
  return o;
}

void checkInsertionOrderBudgetSegment(api.InsertionOrderBudgetSegment o) {
  buildCounterInsertionOrderBudgetSegment++;
  if (buildCounterInsertionOrderBudgetSegment < 3) {
    unittest.expect(
      o.budgetAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.campaignBudgetId!,
      unittest.equals('foo'),
    );
    checkDateRange(o.dateRange! as api.DateRange);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
  }
  buildCounterInsertionOrderBudgetSegment--;
}

core.List<core.String> buildUnnamed5491() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5491(core.List<core.String> o) {
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

core.int buildCounterIntegralAdScience = 0;
api.IntegralAdScience buildIntegralAdScience() {
  var o = api.IntegralAdScience();
  buildCounterIntegralAdScience++;
  if (buildCounterIntegralAdScience < 3) {
    o.customSegmentId = buildUnnamed5491();
    o.displayViewability = 'foo';
    o.excludeUnrateable = true;
    o.excludedAdFraudRisk = 'foo';
    o.excludedAdultRisk = 'foo';
    o.excludedAlcoholRisk = 'foo';
    o.excludedDrugsRisk = 'foo';
    o.excludedGamblingRisk = 'foo';
    o.excludedHateSpeechRisk = 'foo';
    o.excludedIllegalDownloadsRisk = 'foo';
    o.excludedOffensiveLanguageRisk = 'foo';
    o.excludedViolenceRisk = 'foo';
    o.traqScoreOption = 'foo';
    o.videoViewability = 'foo';
  }
  buildCounterIntegralAdScience--;
  return o;
}

void checkIntegralAdScience(api.IntegralAdScience o) {
  buildCounterIntegralAdScience++;
  if (buildCounterIntegralAdScience < 3) {
    checkUnnamed5491(o.customSegmentId!);
    unittest.expect(
      o.displayViewability!,
      unittest.equals('foo'),
    );
    unittest.expect(o.excludeUnrateable!, unittest.isTrue);
    unittest.expect(
      o.excludedAdFraudRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedAdultRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedAlcoholRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedDrugsRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedGamblingRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedHateSpeechRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedIllegalDownloadsRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedOffensiveLanguageRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.excludedViolenceRisk!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.traqScoreOption!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoViewability!,
      unittest.equals('foo'),
    );
  }
  buildCounterIntegralAdScience--;
}

core.int buildCounterIntegrationDetails = 0;
api.IntegrationDetails buildIntegrationDetails() {
  var o = api.IntegrationDetails();
  buildCounterIntegrationDetails++;
  if (buildCounterIntegrationDetails < 3) {
    o.details = 'foo';
    o.integrationCode = 'foo';
  }
  buildCounterIntegrationDetails--;
  return o;
}

void checkIntegrationDetails(api.IntegrationDetails o) {
  buildCounterIntegrationDetails++;
  if (buildCounterIntegrationDetails < 3) {
    unittest.expect(
      o.details!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.integrationCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterIntegrationDetails--;
}

core.List<api.CreativeConfig> buildUnnamed5492() {
  var o = <api.CreativeConfig>[];
  o.add(buildCreativeConfig());
  o.add(buildCreativeConfig());
  return o;
}

void checkUnnamed5492(core.List<api.CreativeConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeConfig(o[0] as api.CreativeConfig);
  checkCreativeConfig(o[1] as api.CreativeConfig);
}

core.int buildCounterInventorySource = 0;
api.InventorySource buildInventorySource() {
  var o = api.InventorySource();
  buildCounterInventorySource++;
  if (buildCounterInventorySource < 3) {
    o.commitment = 'foo';
    o.creativeConfigs = buildUnnamed5492();
    o.dealId = 'foo';
    o.deliveryMethod = 'foo';
    o.displayName = 'foo';
    o.exchange = 'foo';
    o.inventorySourceId = 'foo';
    o.inventorySourceType = 'foo';
    o.name = 'foo';
    o.publisherName = 'foo';
    o.rateDetails = buildRateDetails();
    o.status = buildInventorySourceStatus();
    o.timeRange = buildTimeRange();
    o.updateTime = 'foo';
  }
  buildCounterInventorySource--;
  return o;
}

void checkInventorySource(api.InventorySource o) {
  buildCounterInventorySource++;
  if (buildCounterInventorySource < 3) {
    unittest.expect(
      o.commitment!,
      unittest.equals('foo'),
    );
    checkUnnamed5492(o.creativeConfigs!);
    unittest.expect(
      o.dealId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deliveryMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.exchange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inventorySourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inventorySourceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publisherName!,
      unittest.equals('foo'),
    );
    checkRateDetails(o.rateDetails! as api.RateDetails);
    checkInventorySourceStatus(o.status! as api.InventorySourceStatus);
    checkTimeRange(o.timeRange! as api.TimeRange);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventorySource--;
}

core.int buildCounterInventorySourceAssignedTargetingOptionDetails = 0;
api.InventorySourceAssignedTargetingOptionDetails
    buildInventorySourceAssignedTargetingOptionDetails() {
  var o = api.InventorySourceAssignedTargetingOptionDetails();
  buildCounterInventorySourceAssignedTargetingOptionDetails++;
  if (buildCounterInventorySourceAssignedTargetingOptionDetails < 3) {
    o.inventorySourceId = 'foo';
  }
  buildCounterInventorySourceAssignedTargetingOptionDetails--;
  return o;
}

void checkInventorySourceAssignedTargetingOptionDetails(
    api.InventorySourceAssignedTargetingOptionDetails o) {
  buildCounterInventorySourceAssignedTargetingOptionDetails++;
  if (buildCounterInventorySourceAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.inventorySourceId!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventorySourceAssignedTargetingOptionDetails--;
}

core.int buildCounterInventorySourceDisplayCreativeConfig = 0;
api.InventorySourceDisplayCreativeConfig
    buildInventorySourceDisplayCreativeConfig() {
  var o = api.InventorySourceDisplayCreativeConfig();
  buildCounterInventorySourceDisplayCreativeConfig++;
  if (buildCounterInventorySourceDisplayCreativeConfig < 3) {
    o.creativeSize = buildDimensions();
  }
  buildCounterInventorySourceDisplayCreativeConfig--;
  return o;
}

void checkInventorySourceDisplayCreativeConfig(
    api.InventorySourceDisplayCreativeConfig o) {
  buildCounterInventorySourceDisplayCreativeConfig++;
  if (buildCounterInventorySourceDisplayCreativeConfig < 3) {
    checkDimensions(o.creativeSize! as api.Dimensions);
  }
  buildCounterInventorySourceDisplayCreativeConfig--;
}

core.List<core.String> buildUnnamed5493() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5493(core.List<core.String> o) {
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

core.int buildCounterInventorySourceFilter = 0;
api.InventorySourceFilter buildInventorySourceFilter() {
  var o = api.InventorySourceFilter();
  buildCounterInventorySourceFilter++;
  if (buildCounterInventorySourceFilter < 3) {
    o.inventorySourceIds = buildUnnamed5493();
  }
  buildCounterInventorySourceFilter--;
  return o;
}

void checkInventorySourceFilter(api.InventorySourceFilter o) {
  buildCounterInventorySourceFilter++;
  if (buildCounterInventorySourceFilter < 3) {
    checkUnnamed5493(o.inventorySourceIds!);
  }
  buildCounterInventorySourceFilter--;
}

core.int buildCounterInventorySourceGroup = 0;
api.InventorySourceGroup buildInventorySourceGroup() {
  var o = api.InventorySourceGroup();
  buildCounterInventorySourceGroup++;
  if (buildCounterInventorySourceGroup < 3) {
    o.displayName = 'foo';
    o.inventorySourceGroupId = 'foo';
    o.name = 'foo';
  }
  buildCounterInventorySourceGroup--;
  return o;
}

void checkInventorySourceGroup(api.InventorySourceGroup o) {
  buildCounterInventorySourceGroup++;
  if (buildCounterInventorySourceGroup < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inventorySourceGroupId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventorySourceGroup--;
}

core.int buildCounterInventorySourceGroupAssignedTargetingOptionDetails = 0;
api.InventorySourceGroupAssignedTargetingOptionDetails
    buildInventorySourceGroupAssignedTargetingOptionDetails() {
  var o = api.InventorySourceGroupAssignedTargetingOptionDetails();
  buildCounterInventorySourceGroupAssignedTargetingOptionDetails++;
  if (buildCounterInventorySourceGroupAssignedTargetingOptionDetails < 3) {
    o.inventorySourceGroupId = 'foo';
  }
  buildCounterInventorySourceGroupAssignedTargetingOptionDetails--;
  return o;
}

void checkInventorySourceGroupAssignedTargetingOptionDetails(
    api.InventorySourceGroupAssignedTargetingOptionDetails o) {
  buildCounterInventorySourceGroupAssignedTargetingOptionDetails++;
  if (buildCounterInventorySourceGroupAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.inventorySourceGroupId!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventorySourceGroupAssignedTargetingOptionDetails--;
}

core.int buildCounterInventorySourceStatus = 0;
api.InventorySourceStatus buildInventorySourceStatus() {
  var o = api.InventorySourceStatus();
  buildCounterInventorySourceStatus++;
  if (buildCounterInventorySourceStatus < 3) {
    o.configStatus = 'foo';
    o.entityPauseReason = 'foo';
    o.entityStatus = 'foo';
    o.sellerPauseReason = 'foo';
    o.sellerStatus = 'foo';
  }
  buildCounterInventorySourceStatus--;
  return o;
}

void checkInventorySourceStatus(api.InventorySourceStatus o) {
  buildCounterInventorySourceStatus++;
  if (buildCounterInventorySourceStatus < 3) {
    unittest.expect(
      o.configStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityPauseReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sellerPauseReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sellerStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventorySourceStatus--;
}

core.int buildCounterInventorySourceVideoCreativeConfig = 0;
api.InventorySourceVideoCreativeConfig
    buildInventorySourceVideoCreativeConfig() {
  var o = api.InventorySourceVideoCreativeConfig();
  buildCounterInventorySourceVideoCreativeConfig++;
  if (buildCounterInventorySourceVideoCreativeConfig < 3) {
    o.duration = 'foo';
  }
  buildCounterInventorySourceVideoCreativeConfig--;
  return o;
}

void checkInventorySourceVideoCreativeConfig(
    api.InventorySourceVideoCreativeConfig o) {
  buildCounterInventorySourceVideoCreativeConfig++;
  if (buildCounterInventorySourceVideoCreativeConfig < 3) {
    unittest.expect(
      o.duration!,
      unittest.equals('foo'),
    );
  }
  buildCounterInventorySourceVideoCreativeConfig--;
}

core.List<api.BudgetSummary> buildUnnamed5494() {
  var o = <api.BudgetSummary>[];
  o.add(buildBudgetSummary());
  o.add(buildBudgetSummary());
  return o;
}

void checkUnnamed5494(core.List<api.BudgetSummary> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBudgetSummary(o[0] as api.BudgetSummary);
  checkBudgetSummary(o[1] as api.BudgetSummary);
}

core.List<core.String> buildUnnamed5495() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5495(core.List<core.String> o) {
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

core.int buildCounterInvoice = 0;
api.Invoice buildInvoice() {
  var o = api.Invoice();
  buildCounterInvoice++;
  if (buildCounterInvoice < 3) {
    o.budgetInvoiceGroupingId = 'foo';
    o.budgetSummaries = buildUnnamed5494();
    o.correctedInvoiceId = 'foo';
    o.currencyCode = 'foo';
    o.displayName = 'foo';
    o.dueDate = buildDate();
    o.invoiceId = 'foo';
    o.invoiceType = 'foo';
    o.issueDate = buildDate();
    o.name = 'foo';
    o.nonBudgetMicros = 'foo';
    o.paymentsAccountId = 'foo';
    o.paymentsProfileId = 'foo';
    o.pdfUrl = 'foo';
    o.purchaseOrderNumber = 'foo';
    o.replacedInvoiceIds = buildUnnamed5495();
    o.serviceDateRange = buildDateRange();
    o.subtotalAmountMicros = 'foo';
    o.totalAmountMicros = 'foo';
    o.totalTaxAmountMicros = 'foo';
  }
  buildCounterInvoice--;
  return o;
}

void checkInvoice(api.Invoice o) {
  buildCounterInvoice++;
  if (buildCounterInvoice < 3) {
    unittest.expect(
      o.budgetInvoiceGroupingId!,
      unittest.equals('foo'),
    );
    checkUnnamed5494(o.budgetSummaries!);
    unittest.expect(
      o.correctedInvoiceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkDate(o.dueDate! as api.Date);
    unittest.expect(
      o.invoiceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invoiceType!,
      unittest.equals('foo'),
    );
    checkDate(o.issueDate! as api.Date);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nonBudgetMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paymentsAccountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.paymentsProfileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pdfUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseOrderNumber!,
      unittest.equals('foo'),
    );
    checkUnnamed5495(o.replacedInvoiceIds!);
    checkDateRange(o.serviceDateRange! as api.DateRange);
    unittest.expect(
      o.subtotalAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalTaxAmountMicros!,
      unittest.equals('foo'),
    );
  }
  buildCounterInvoice--;
}

core.int buildCounterKeywordAssignedTargetingOptionDetails = 0;
api.KeywordAssignedTargetingOptionDetails
    buildKeywordAssignedTargetingOptionDetails() {
  var o = api.KeywordAssignedTargetingOptionDetails();
  buildCounterKeywordAssignedTargetingOptionDetails++;
  if (buildCounterKeywordAssignedTargetingOptionDetails < 3) {
    o.keyword = 'foo';
    o.negative = true;
  }
  buildCounterKeywordAssignedTargetingOptionDetails--;
  return o;
}

void checkKeywordAssignedTargetingOptionDetails(
    api.KeywordAssignedTargetingOptionDetails o) {
  buildCounterKeywordAssignedTargetingOptionDetails++;
  if (buildCounterKeywordAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.keyword!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
  }
  buildCounterKeywordAssignedTargetingOptionDetails--;
}

core.int buildCounterLanguageAssignedTargetingOptionDetails = 0;
api.LanguageAssignedTargetingOptionDetails
    buildLanguageAssignedTargetingOptionDetails() {
  var o = api.LanguageAssignedTargetingOptionDetails();
  buildCounterLanguageAssignedTargetingOptionDetails++;
  if (buildCounterLanguageAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterLanguageAssignedTargetingOptionDetails--;
  return o;
}

void checkLanguageAssignedTargetingOptionDetails(
    api.LanguageAssignedTargetingOptionDetails o) {
  buildCounterLanguageAssignedTargetingOptionDetails++;
  if (buildCounterLanguageAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLanguageAssignedTargetingOptionDetails--;
}

core.int buildCounterLanguageTargetingOptionDetails = 0;
api.LanguageTargetingOptionDetails buildLanguageTargetingOptionDetails() {
  var o = api.LanguageTargetingOptionDetails();
  buildCounterLanguageTargetingOptionDetails++;
  if (buildCounterLanguageTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterLanguageTargetingOptionDetails--;
  return o;
}

void checkLanguageTargetingOptionDetails(api.LanguageTargetingOptionDetails o) {
  buildCounterLanguageTargetingOptionDetails++;
  if (buildCounterLanguageTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterLanguageTargetingOptionDetails--;
}

core.List<core.String> buildUnnamed5496() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5496(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5497() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5497(core.List<core.String> o) {
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

core.List<api.PartnerCost> buildUnnamed5498() {
  var o = <api.PartnerCost>[];
  o.add(buildPartnerCost());
  o.add(buildPartnerCost());
  return o;
}

void checkUnnamed5498(core.List<api.PartnerCost> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPartnerCost(o[0] as api.PartnerCost);
  checkPartnerCost(o[1] as api.PartnerCost);
}

core.List<core.String> buildUnnamed5499() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5499(core.List<core.String> o) {
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

core.int buildCounterLineItem = 0;
api.LineItem buildLineItem() {
  var o = api.LineItem();
  buildCounterLineItem++;
  if (buildCounterLineItem < 3) {
    o.advertiserId = 'foo';
    o.bidStrategy = buildBiddingStrategy();
    o.budget = buildLineItemBudget();
    o.campaignId = 'foo';
    o.conversionCounting = buildConversionCountingConfig();
    o.creativeIds = buildUnnamed5496();
    o.displayName = 'foo';
    o.entityStatus = 'foo';
    o.flight = buildLineItemFlight();
    o.frequencyCap = buildFrequencyCap();
    o.insertionOrderId = 'foo';
    o.integrationDetails = buildIntegrationDetails();
    o.inventorySourceIds = buildUnnamed5497();
    o.lineItemId = 'foo';
    o.lineItemType = 'foo';
    o.mobileApp = buildMobileApp();
    o.name = 'foo';
    o.pacing = buildPacing();
    o.partnerCosts = buildUnnamed5498();
    o.partnerRevenueModel = buildPartnerRevenueModel();
    o.targetingExpansion = buildTargetingExpansionConfig();
    o.updateTime = 'foo';
    o.warningMessages = buildUnnamed5499();
  }
  buildCounterLineItem--;
  return o;
}

void checkLineItem(api.LineItem o) {
  buildCounterLineItem++;
  if (buildCounterLineItem < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkBiddingStrategy(o.bidStrategy! as api.BiddingStrategy);
    checkLineItemBudget(o.budget! as api.LineItemBudget);
    unittest.expect(
      o.campaignId!,
      unittest.equals('foo'),
    );
    checkConversionCountingConfig(
        o.conversionCounting! as api.ConversionCountingConfig);
    checkUnnamed5496(o.creativeIds!);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    checkLineItemFlight(o.flight! as api.LineItemFlight);
    checkFrequencyCap(o.frequencyCap! as api.FrequencyCap);
    unittest.expect(
      o.insertionOrderId!,
      unittest.equals('foo'),
    );
    checkIntegrationDetails(o.integrationDetails! as api.IntegrationDetails);
    checkUnnamed5497(o.inventorySourceIds!);
    unittest.expect(
      o.lineItemId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lineItemType!,
      unittest.equals('foo'),
    );
    checkMobileApp(o.mobileApp! as api.MobileApp);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPacing(o.pacing! as api.Pacing);
    checkUnnamed5498(o.partnerCosts!);
    checkPartnerRevenueModel(o.partnerRevenueModel! as api.PartnerRevenueModel);
    checkTargetingExpansionConfig(
        o.targetingExpansion! as api.TargetingExpansionConfig);
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
    checkUnnamed5499(o.warningMessages!);
  }
  buildCounterLineItem--;
}

core.int buildCounterLineItemBudget = 0;
api.LineItemBudget buildLineItemBudget() {
  var o = api.LineItemBudget();
  buildCounterLineItemBudget++;
  if (buildCounterLineItemBudget < 3) {
    o.budgetAllocationType = 'foo';
    o.budgetUnit = 'foo';
    o.maxAmount = 'foo';
  }
  buildCounterLineItemBudget--;
  return o;
}

void checkLineItemBudget(api.LineItemBudget o) {
  buildCounterLineItemBudget++;
  if (buildCounterLineItemBudget < 3) {
    unittest.expect(
      o.budgetAllocationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.budgetUnit!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxAmount!,
      unittest.equals('foo'),
    );
  }
  buildCounterLineItemBudget--;
}

core.int buildCounterLineItemFlight = 0;
api.LineItemFlight buildLineItemFlight() {
  var o = api.LineItemFlight();
  buildCounterLineItemFlight++;
  if (buildCounterLineItemFlight < 3) {
    o.dateRange = buildDateRange();
    o.flightDateType = 'foo';
    o.triggerId = 'foo';
  }
  buildCounterLineItemFlight--;
  return o;
}

void checkLineItemFlight(api.LineItemFlight o) {
  buildCounterLineItemFlight++;
  if (buildCounterLineItemFlight < 3) {
    checkDateRange(o.dateRange! as api.DateRange);
    unittest.expect(
      o.flightDateType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.triggerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLineItemFlight--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5500() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5500(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterListAdvertiserAssignedTargetingOptionsResponse = 0;
api.ListAdvertiserAssignedTargetingOptionsResponse
    buildListAdvertiserAssignedTargetingOptionsResponse() {
  var o = api.ListAdvertiserAssignedTargetingOptionsResponse();
  buildCounterListAdvertiserAssignedTargetingOptionsResponse++;
  if (buildCounterListAdvertiserAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5500();
    o.nextPageToken = 'foo';
  }
  buildCounterListAdvertiserAssignedTargetingOptionsResponse--;
  return o;
}

void checkListAdvertiserAssignedTargetingOptionsResponse(
    api.ListAdvertiserAssignedTargetingOptionsResponse o) {
  buildCounterListAdvertiserAssignedTargetingOptionsResponse++;
  if (buildCounterListAdvertiserAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5500(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAdvertiserAssignedTargetingOptionsResponse--;
}

core.List<api.Advertiser> buildUnnamed5501() {
  var o = <api.Advertiser>[];
  o.add(buildAdvertiser());
  o.add(buildAdvertiser());
  return o;
}

void checkUnnamed5501(core.List<api.Advertiser> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdvertiser(o[0] as api.Advertiser);
  checkAdvertiser(o[1] as api.Advertiser);
}

core.int buildCounterListAdvertisersResponse = 0;
api.ListAdvertisersResponse buildListAdvertisersResponse() {
  var o = api.ListAdvertisersResponse();
  buildCounterListAdvertisersResponse++;
  if (buildCounterListAdvertisersResponse < 3) {
    o.advertisers = buildUnnamed5501();
    o.nextPageToken = 'foo';
  }
  buildCounterListAdvertisersResponse--;
  return o;
}

void checkListAdvertisersResponse(api.ListAdvertisersResponse o) {
  buildCounterListAdvertisersResponse++;
  if (buildCounterListAdvertisersResponse < 3) {
    checkUnnamed5501(o.advertisers!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAdvertisersResponse--;
}

core.List<api.AssignedInventorySource> buildUnnamed5502() {
  var o = <api.AssignedInventorySource>[];
  o.add(buildAssignedInventorySource());
  o.add(buildAssignedInventorySource());
  return o;
}

void checkUnnamed5502(core.List<api.AssignedInventorySource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedInventorySource(o[0] as api.AssignedInventorySource);
  checkAssignedInventorySource(o[1] as api.AssignedInventorySource);
}

core.int buildCounterListAssignedInventorySourcesResponse = 0;
api.ListAssignedInventorySourcesResponse
    buildListAssignedInventorySourcesResponse() {
  var o = api.ListAssignedInventorySourcesResponse();
  buildCounterListAssignedInventorySourcesResponse++;
  if (buildCounterListAssignedInventorySourcesResponse < 3) {
    o.assignedInventorySources = buildUnnamed5502();
    o.nextPageToken = 'foo';
  }
  buildCounterListAssignedInventorySourcesResponse--;
  return o;
}

void checkListAssignedInventorySourcesResponse(
    api.ListAssignedInventorySourcesResponse o) {
  buildCounterListAssignedInventorySourcesResponse++;
  if (buildCounterListAssignedInventorySourcesResponse < 3) {
    checkUnnamed5502(o.assignedInventorySources!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAssignedInventorySourcesResponse--;
}

core.List<api.AssignedLocation> buildUnnamed5503() {
  var o = <api.AssignedLocation>[];
  o.add(buildAssignedLocation());
  o.add(buildAssignedLocation());
  return o;
}

void checkUnnamed5503(core.List<api.AssignedLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedLocation(o[0] as api.AssignedLocation);
  checkAssignedLocation(o[1] as api.AssignedLocation);
}

core.int buildCounterListAssignedLocationsResponse = 0;
api.ListAssignedLocationsResponse buildListAssignedLocationsResponse() {
  var o = api.ListAssignedLocationsResponse();
  buildCounterListAssignedLocationsResponse++;
  if (buildCounterListAssignedLocationsResponse < 3) {
    o.assignedLocations = buildUnnamed5503();
    o.nextPageToken = 'foo';
  }
  buildCounterListAssignedLocationsResponse--;
  return o;
}

void checkListAssignedLocationsResponse(api.ListAssignedLocationsResponse o) {
  buildCounterListAssignedLocationsResponse++;
  if (buildCounterListAssignedLocationsResponse < 3) {
    checkUnnamed5503(o.assignedLocations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListAssignedLocationsResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5504() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5504(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterListCampaignAssignedTargetingOptionsResponse = 0;
api.ListCampaignAssignedTargetingOptionsResponse
    buildListCampaignAssignedTargetingOptionsResponse() {
  var o = api.ListCampaignAssignedTargetingOptionsResponse();
  buildCounterListCampaignAssignedTargetingOptionsResponse++;
  if (buildCounterListCampaignAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5504();
    o.nextPageToken = 'foo';
  }
  buildCounterListCampaignAssignedTargetingOptionsResponse--;
  return o;
}

void checkListCampaignAssignedTargetingOptionsResponse(
    api.ListCampaignAssignedTargetingOptionsResponse o) {
  buildCounterListCampaignAssignedTargetingOptionsResponse++;
  if (buildCounterListCampaignAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5504(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCampaignAssignedTargetingOptionsResponse--;
}

core.List<api.Campaign> buildUnnamed5505() {
  var o = <api.Campaign>[];
  o.add(buildCampaign());
  o.add(buildCampaign());
  return o;
}

void checkUnnamed5505(core.List<api.Campaign> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCampaign(o[0] as api.Campaign);
  checkCampaign(o[1] as api.Campaign);
}

core.int buildCounterListCampaignsResponse = 0;
api.ListCampaignsResponse buildListCampaignsResponse() {
  var o = api.ListCampaignsResponse();
  buildCounterListCampaignsResponse++;
  if (buildCounterListCampaignsResponse < 3) {
    o.campaigns = buildUnnamed5505();
    o.nextPageToken = 'foo';
  }
  buildCounterListCampaignsResponse--;
  return o;
}

void checkListCampaignsResponse(api.ListCampaignsResponse o) {
  buildCounterListCampaignsResponse++;
  if (buildCounterListCampaignsResponse < 3) {
    checkUnnamed5505(o.campaigns!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCampaignsResponse--;
}

core.List<api.Channel> buildUnnamed5506() {
  var o = <api.Channel>[];
  o.add(buildChannel());
  o.add(buildChannel());
  return o;
}

void checkUnnamed5506(core.List<api.Channel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannel(o[0] as api.Channel);
  checkChannel(o[1] as api.Channel);
}

core.int buildCounterListChannelsResponse = 0;
api.ListChannelsResponse buildListChannelsResponse() {
  var o = api.ListChannelsResponse();
  buildCounterListChannelsResponse++;
  if (buildCounterListChannelsResponse < 3) {
    o.channels = buildUnnamed5506();
    o.nextPageToken = 'foo';
  }
  buildCounterListChannelsResponse--;
  return o;
}

void checkListChannelsResponse(api.ListChannelsResponse o) {
  buildCounterListChannelsResponse++;
  if (buildCounterListChannelsResponse < 3) {
    checkUnnamed5506(o.channels!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListChannelsResponse--;
}

core.List<api.CombinedAudience> buildUnnamed5507() {
  var o = <api.CombinedAudience>[];
  o.add(buildCombinedAudience());
  o.add(buildCombinedAudience());
  return o;
}

void checkUnnamed5507(core.List<api.CombinedAudience> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCombinedAudience(o[0] as api.CombinedAudience);
  checkCombinedAudience(o[1] as api.CombinedAudience);
}

core.int buildCounterListCombinedAudiencesResponse = 0;
api.ListCombinedAudiencesResponse buildListCombinedAudiencesResponse() {
  var o = api.ListCombinedAudiencesResponse();
  buildCounterListCombinedAudiencesResponse++;
  if (buildCounterListCombinedAudiencesResponse < 3) {
    o.combinedAudiences = buildUnnamed5507();
    o.nextPageToken = 'foo';
  }
  buildCounterListCombinedAudiencesResponse--;
  return o;
}

void checkListCombinedAudiencesResponse(api.ListCombinedAudiencesResponse o) {
  buildCounterListCombinedAudiencesResponse++;
  if (buildCounterListCombinedAudiencesResponse < 3) {
    checkUnnamed5507(o.combinedAudiences!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCombinedAudiencesResponse--;
}

core.List<api.Creative> buildUnnamed5508() {
  var o = <api.Creative>[];
  o.add(buildCreative());
  o.add(buildCreative());
  return o;
}

void checkUnnamed5508(core.List<api.Creative> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreative(o[0] as api.Creative);
  checkCreative(o[1] as api.Creative);
}

core.int buildCounterListCreativesResponse = 0;
api.ListCreativesResponse buildListCreativesResponse() {
  var o = api.ListCreativesResponse();
  buildCounterListCreativesResponse++;
  if (buildCounterListCreativesResponse < 3) {
    o.creatives = buildUnnamed5508();
    o.nextPageToken = 'foo';
  }
  buildCounterListCreativesResponse--;
  return o;
}

void checkListCreativesResponse(api.ListCreativesResponse o) {
  buildCounterListCreativesResponse++;
  if (buildCounterListCreativesResponse < 3) {
    checkUnnamed5508(o.creatives!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCreativesResponse--;
}

core.List<api.CustomBiddingAlgorithm> buildUnnamed5509() {
  var o = <api.CustomBiddingAlgorithm>[];
  o.add(buildCustomBiddingAlgorithm());
  o.add(buildCustomBiddingAlgorithm());
  return o;
}

void checkUnnamed5509(core.List<api.CustomBiddingAlgorithm> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomBiddingAlgorithm(o[0] as api.CustomBiddingAlgorithm);
  checkCustomBiddingAlgorithm(o[1] as api.CustomBiddingAlgorithm);
}

core.int buildCounterListCustomBiddingAlgorithmsResponse = 0;
api.ListCustomBiddingAlgorithmsResponse
    buildListCustomBiddingAlgorithmsResponse() {
  var o = api.ListCustomBiddingAlgorithmsResponse();
  buildCounterListCustomBiddingAlgorithmsResponse++;
  if (buildCounterListCustomBiddingAlgorithmsResponse < 3) {
    o.customBiddingAlgorithms = buildUnnamed5509();
    o.nextPageToken = 'foo';
  }
  buildCounterListCustomBiddingAlgorithmsResponse--;
  return o;
}

void checkListCustomBiddingAlgorithmsResponse(
    api.ListCustomBiddingAlgorithmsResponse o) {
  buildCounterListCustomBiddingAlgorithmsResponse++;
  if (buildCounterListCustomBiddingAlgorithmsResponse < 3) {
    checkUnnamed5509(o.customBiddingAlgorithms!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCustomBiddingAlgorithmsResponse--;
}

core.List<api.CustomList> buildUnnamed5510() {
  var o = <api.CustomList>[];
  o.add(buildCustomList());
  o.add(buildCustomList());
  return o;
}

void checkUnnamed5510(core.List<api.CustomList> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCustomList(o[0] as api.CustomList);
  checkCustomList(o[1] as api.CustomList);
}

core.int buildCounterListCustomListsResponse = 0;
api.ListCustomListsResponse buildListCustomListsResponse() {
  var o = api.ListCustomListsResponse();
  buildCounterListCustomListsResponse++;
  if (buildCounterListCustomListsResponse < 3) {
    o.customLists = buildUnnamed5510();
    o.nextPageToken = 'foo';
  }
  buildCounterListCustomListsResponse--;
  return o;
}

void checkListCustomListsResponse(api.ListCustomListsResponse o) {
  buildCounterListCustomListsResponse++;
  if (buildCounterListCustomListsResponse < 3) {
    checkUnnamed5510(o.customLists!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListCustomListsResponse--;
}

core.List<api.FirstAndThirdPartyAudience> buildUnnamed5511() {
  var o = <api.FirstAndThirdPartyAudience>[];
  o.add(buildFirstAndThirdPartyAudience());
  o.add(buildFirstAndThirdPartyAudience());
  return o;
}

void checkUnnamed5511(core.List<api.FirstAndThirdPartyAudience> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFirstAndThirdPartyAudience(o[0] as api.FirstAndThirdPartyAudience);
  checkFirstAndThirdPartyAudience(o[1] as api.FirstAndThirdPartyAudience);
}

core.int buildCounterListFirstAndThirdPartyAudiencesResponse = 0;
api.ListFirstAndThirdPartyAudiencesResponse
    buildListFirstAndThirdPartyAudiencesResponse() {
  var o = api.ListFirstAndThirdPartyAudiencesResponse();
  buildCounterListFirstAndThirdPartyAudiencesResponse++;
  if (buildCounterListFirstAndThirdPartyAudiencesResponse < 3) {
    o.firstAndThirdPartyAudiences = buildUnnamed5511();
    o.nextPageToken = 'foo';
  }
  buildCounterListFirstAndThirdPartyAudiencesResponse--;
  return o;
}

void checkListFirstAndThirdPartyAudiencesResponse(
    api.ListFirstAndThirdPartyAudiencesResponse o) {
  buildCounterListFirstAndThirdPartyAudiencesResponse++;
  if (buildCounterListFirstAndThirdPartyAudiencesResponse < 3) {
    checkUnnamed5511(o.firstAndThirdPartyAudiences!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListFirstAndThirdPartyAudiencesResponse--;
}

core.List<api.GoogleAudience> buildUnnamed5512() {
  var o = <api.GoogleAudience>[];
  o.add(buildGoogleAudience());
  o.add(buildGoogleAudience());
  return o;
}

void checkUnnamed5512(core.List<api.GoogleAudience> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleAudience(o[0] as api.GoogleAudience);
  checkGoogleAudience(o[1] as api.GoogleAudience);
}

core.int buildCounterListGoogleAudiencesResponse = 0;
api.ListGoogleAudiencesResponse buildListGoogleAudiencesResponse() {
  var o = api.ListGoogleAudiencesResponse();
  buildCounterListGoogleAudiencesResponse++;
  if (buildCounterListGoogleAudiencesResponse < 3) {
    o.googleAudiences = buildUnnamed5512();
    o.nextPageToken = 'foo';
  }
  buildCounterListGoogleAudiencesResponse--;
  return o;
}

void checkListGoogleAudiencesResponse(api.ListGoogleAudiencesResponse o) {
  buildCounterListGoogleAudiencesResponse++;
  if (buildCounterListGoogleAudiencesResponse < 3) {
    checkUnnamed5512(o.googleAudiences!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListGoogleAudiencesResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5513() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5513(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterListInsertionOrderAssignedTargetingOptionsResponse = 0;
api.ListInsertionOrderAssignedTargetingOptionsResponse
    buildListInsertionOrderAssignedTargetingOptionsResponse() {
  var o = api.ListInsertionOrderAssignedTargetingOptionsResponse();
  buildCounterListInsertionOrderAssignedTargetingOptionsResponse++;
  if (buildCounterListInsertionOrderAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5513();
    o.nextPageToken = 'foo';
  }
  buildCounterListInsertionOrderAssignedTargetingOptionsResponse--;
  return o;
}

void checkListInsertionOrderAssignedTargetingOptionsResponse(
    api.ListInsertionOrderAssignedTargetingOptionsResponse o) {
  buildCounterListInsertionOrderAssignedTargetingOptionsResponse++;
  if (buildCounterListInsertionOrderAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5513(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInsertionOrderAssignedTargetingOptionsResponse--;
}

core.List<api.InsertionOrder> buildUnnamed5514() {
  var o = <api.InsertionOrder>[];
  o.add(buildInsertionOrder());
  o.add(buildInsertionOrder());
  return o;
}

void checkUnnamed5514(core.List<api.InsertionOrder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInsertionOrder(o[0] as api.InsertionOrder);
  checkInsertionOrder(o[1] as api.InsertionOrder);
}

core.int buildCounterListInsertionOrdersResponse = 0;
api.ListInsertionOrdersResponse buildListInsertionOrdersResponse() {
  var o = api.ListInsertionOrdersResponse();
  buildCounterListInsertionOrdersResponse++;
  if (buildCounterListInsertionOrdersResponse < 3) {
    o.insertionOrders = buildUnnamed5514();
    o.nextPageToken = 'foo';
  }
  buildCounterListInsertionOrdersResponse--;
  return o;
}

void checkListInsertionOrdersResponse(api.ListInsertionOrdersResponse o) {
  buildCounterListInsertionOrdersResponse++;
  if (buildCounterListInsertionOrdersResponse < 3) {
    checkUnnamed5514(o.insertionOrders!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInsertionOrdersResponse--;
}

core.List<api.InventorySourceGroup> buildUnnamed5515() {
  var o = <api.InventorySourceGroup>[];
  o.add(buildInventorySourceGroup());
  o.add(buildInventorySourceGroup());
  return o;
}

void checkUnnamed5515(core.List<api.InventorySourceGroup> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInventorySourceGroup(o[0] as api.InventorySourceGroup);
  checkInventorySourceGroup(o[1] as api.InventorySourceGroup);
}

core.int buildCounterListInventorySourceGroupsResponse = 0;
api.ListInventorySourceGroupsResponse buildListInventorySourceGroupsResponse() {
  var o = api.ListInventorySourceGroupsResponse();
  buildCounterListInventorySourceGroupsResponse++;
  if (buildCounterListInventorySourceGroupsResponse < 3) {
    o.inventorySourceGroups = buildUnnamed5515();
    o.nextPageToken = 'foo';
  }
  buildCounterListInventorySourceGroupsResponse--;
  return o;
}

void checkListInventorySourceGroupsResponse(
    api.ListInventorySourceGroupsResponse o) {
  buildCounterListInventorySourceGroupsResponse++;
  if (buildCounterListInventorySourceGroupsResponse < 3) {
    checkUnnamed5515(o.inventorySourceGroups!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInventorySourceGroupsResponse--;
}

core.List<api.InventorySource> buildUnnamed5516() {
  var o = <api.InventorySource>[];
  o.add(buildInventorySource());
  o.add(buildInventorySource());
  return o;
}

void checkUnnamed5516(core.List<api.InventorySource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInventorySource(o[0] as api.InventorySource);
  checkInventorySource(o[1] as api.InventorySource);
}

core.int buildCounterListInventorySourcesResponse = 0;
api.ListInventorySourcesResponse buildListInventorySourcesResponse() {
  var o = api.ListInventorySourcesResponse();
  buildCounterListInventorySourcesResponse++;
  if (buildCounterListInventorySourcesResponse < 3) {
    o.inventorySources = buildUnnamed5516();
    o.nextPageToken = 'foo';
  }
  buildCounterListInventorySourcesResponse--;
  return o;
}

void checkListInventorySourcesResponse(api.ListInventorySourcesResponse o) {
  buildCounterListInventorySourcesResponse++;
  if (buildCounterListInventorySourcesResponse < 3) {
    checkUnnamed5516(o.inventorySources!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInventorySourcesResponse--;
}

core.List<api.Invoice> buildUnnamed5517() {
  var o = <api.Invoice>[];
  o.add(buildInvoice());
  o.add(buildInvoice());
  return o;
}

void checkUnnamed5517(core.List<api.Invoice> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInvoice(o[0] as api.Invoice);
  checkInvoice(o[1] as api.Invoice);
}

core.int buildCounterListInvoicesResponse = 0;
api.ListInvoicesResponse buildListInvoicesResponse() {
  var o = api.ListInvoicesResponse();
  buildCounterListInvoicesResponse++;
  if (buildCounterListInvoicesResponse < 3) {
    o.invoices = buildUnnamed5517();
    o.nextPageToken = 'foo';
  }
  buildCounterListInvoicesResponse--;
  return o;
}

void checkListInvoicesResponse(api.ListInvoicesResponse o) {
  buildCounterListInvoicesResponse++;
  if (buildCounterListInvoicesResponse < 3) {
    checkUnnamed5517(o.invoices!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListInvoicesResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5518() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5518(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterListLineItemAssignedTargetingOptionsResponse = 0;
api.ListLineItemAssignedTargetingOptionsResponse
    buildListLineItemAssignedTargetingOptionsResponse() {
  var o = api.ListLineItemAssignedTargetingOptionsResponse();
  buildCounterListLineItemAssignedTargetingOptionsResponse++;
  if (buildCounterListLineItemAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5518();
    o.nextPageToken = 'foo';
  }
  buildCounterListLineItemAssignedTargetingOptionsResponse--;
  return o;
}

void checkListLineItemAssignedTargetingOptionsResponse(
    api.ListLineItemAssignedTargetingOptionsResponse o) {
  buildCounterListLineItemAssignedTargetingOptionsResponse++;
  if (buildCounterListLineItemAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5518(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLineItemAssignedTargetingOptionsResponse--;
}

core.List<api.LineItem> buildUnnamed5519() {
  var o = <api.LineItem>[];
  o.add(buildLineItem());
  o.add(buildLineItem());
  return o;
}

void checkUnnamed5519(core.List<api.LineItem> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLineItem(o[0] as api.LineItem);
  checkLineItem(o[1] as api.LineItem);
}

core.int buildCounterListLineItemsResponse = 0;
api.ListLineItemsResponse buildListLineItemsResponse() {
  var o = api.ListLineItemsResponse();
  buildCounterListLineItemsResponse++;
  if (buildCounterListLineItemsResponse < 3) {
    o.lineItems = buildUnnamed5519();
    o.nextPageToken = 'foo';
  }
  buildCounterListLineItemsResponse--;
  return o;
}

void checkListLineItemsResponse(api.ListLineItemsResponse o) {
  buildCounterListLineItemsResponse++;
  if (buildCounterListLineItemsResponse < 3) {
    checkUnnamed5519(o.lineItems!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLineItemsResponse--;
}

core.List<api.LocationList> buildUnnamed5520() {
  var o = <api.LocationList>[];
  o.add(buildLocationList());
  o.add(buildLocationList());
  return o;
}

void checkUnnamed5520(core.List<api.LocationList> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocationList(o[0] as api.LocationList);
  checkLocationList(o[1] as api.LocationList);
}

core.int buildCounterListLocationListsResponse = 0;
api.ListLocationListsResponse buildListLocationListsResponse() {
  var o = api.ListLocationListsResponse();
  buildCounterListLocationListsResponse++;
  if (buildCounterListLocationListsResponse < 3) {
    o.locationLists = buildUnnamed5520();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationListsResponse--;
  return o;
}

void checkListLocationListsResponse(api.ListLocationListsResponse o) {
  buildCounterListLocationListsResponse++;
  if (buildCounterListLocationListsResponse < 3) {
    checkUnnamed5520(o.locationLists!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationListsResponse--;
}

core.List<api.ManualTrigger> buildUnnamed5521() {
  var o = <api.ManualTrigger>[];
  o.add(buildManualTrigger());
  o.add(buildManualTrigger());
  return o;
}

void checkUnnamed5521(core.List<api.ManualTrigger> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkManualTrigger(o[0] as api.ManualTrigger);
  checkManualTrigger(o[1] as api.ManualTrigger);
}

core.int buildCounterListManualTriggersResponse = 0;
api.ListManualTriggersResponse buildListManualTriggersResponse() {
  var o = api.ListManualTriggersResponse();
  buildCounterListManualTriggersResponse++;
  if (buildCounterListManualTriggersResponse < 3) {
    o.manualTriggers = buildUnnamed5521();
    o.nextPageToken = 'foo';
  }
  buildCounterListManualTriggersResponse--;
  return o;
}

void checkListManualTriggersResponse(api.ListManualTriggersResponse o) {
  buildCounterListManualTriggersResponse++;
  if (buildCounterListManualTriggersResponse < 3) {
    checkUnnamed5521(o.manualTriggers!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListManualTriggersResponse--;
}

core.List<api.NegativeKeywordList> buildUnnamed5522() {
  var o = <api.NegativeKeywordList>[];
  o.add(buildNegativeKeywordList());
  o.add(buildNegativeKeywordList());
  return o;
}

void checkUnnamed5522(core.List<api.NegativeKeywordList> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNegativeKeywordList(o[0] as api.NegativeKeywordList);
  checkNegativeKeywordList(o[1] as api.NegativeKeywordList);
}

core.int buildCounterListNegativeKeywordListsResponse = 0;
api.ListNegativeKeywordListsResponse buildListNegativeKeywordListsResponse() {
  var o = api.ListNegativeKeywordListsResponse();
  buildCounterListNegativeKeywordListsResponse++;
  if (buildCounterListNegativeKeywordListsResponse < 3) {
    o.negativeKeywordLists = buildUnnamed5522();
    o.nextPageToken = 'foo';
  }
  buildCounterListNegativeKeywordListsResponse--;
  return o;
}

void checkListNegativeKeywordListsResponse(
    api.ListNegativeKeywordListsResponse o) {
  buildCounterListNegativeKeywordListsResponse++;
  if (buildCounterListNegativeKeywordListsResponse < 3) {
    checkUnnamed5522(o.negativeKeywordLists!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListNegativeKeywordListsResponse--;
}

core.List<api.NegativeKeyword> buildUnnamed5523() {
  var o = <api.NegativeKeyword>[];
  o.add(buildNegativeKeyword());
  o.add(buildNegativeKeyword());
  return o;
}

void checkUnnamed5523(core.List<api.NegativeKeyword> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNegativeKeyword(o[0] as api.NegativeKeyword);
  checkNegativeKeyword(o[1] as api.NegativeKeyword);
}

core.int buildCounterListNegativeKeywordsResponse = 0;
api.ListNegativeKeywordsResponse buildListNegativeKeywordsResponse() {
  var o = api.ListNegativeKeywordsResponse();
  buildCounterListNegativeKeywordsResponse++;
  if (buildCounterListNegativeKeywordsResponse < 3) {
    o.negativeKeywords = buildUnnamed5523();
    o.nextPageToken = 'foo';
  }
  buildCounterListNegativeKeywordsResponse--;
  return o;
}

void checkListNegativeKeywordsResponse(api.ListNegativeKeywordsResponse o) {
  buildCounterListNegativeKeywordsResponse++;
  if (buildCounterListNegativeKeywordsResponse < 3) {
    checkUnnamed5523(o.negativeKeywords!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListNegativeKeywordsResponse--;
}

core.List<api.AssignedTargetingOption> buildUnnamed5524() {
  var o = <api.AssignedTargetingOption>[];
  o.add(buildAssignedTargetingOption());
  o.add(buildAssignedTargetingOption());
  return o;
}

void checkUnnamed5524(core.List<api.AssignedTargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedTargetingOption(o[0] as api.AssignedTargetingOption);
  checkAssignedTargetingOption(o[1] as api.AssignedTargetingOption);
}

core.int buildCounterListPartnerAssignedTargetingOptionsResponse = 0;
api.ListPartnerAssignedTargetingOptionsResponse
    buildListPartnerAssignedTargetingOptionsResponse() {
  var o = api.ListPartnerAssignedTargetingOptionsResponse();
  buildCounterListPartnerAssignedTargetingOptionsResponse++;
  if (buildCounterListPartnerAssignedTargetingOptionsResponse < 3) {
    o.assignedTargetingOptions = buildUnnamed5524();
    o.nextPageToken = 'foo';
  }
  buildCounterListPartnerAssignedTargetingOptionsResponse--;
  return o;
}

void checkListPartnerAssignedTargetingOptionsResponse(
    api.ListPartnerAssignedTargetingOptionsResponse o) {
  buildCounterListPartnerAssignedTargetingOptionsResponse++;
  if (buildCounterListPartnerAssignedTargetingOptionsResponse < 3) {
    checkUnnamed5524(o.assignedTargetingOptions!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListPartnerAssignedTargetingOptionsResponse--;
}

core.List<api.Partner> buildUnnamed5525() {
  var o = <api.Partner>[];
  o.add(buildPartner());
  o.add(buildPartner());
  return o;
}

void checkUnnamed5525(core.List<api.Partner> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPartner(o[0] as api.Partner);
  checkPartner(o[1] as api.Partner);
}

core.int buildCounterListPartnersResponse = 0;
api.ListPartnersResponse buildListPartnersResponse() {
  var o = api.ListPartnersResponse();
  buildCounterListPartnersResponse++;
  if (buildCounterListPartnersResponse < 3) {
    o.nextPageToken = 'foo';
    o.partners = buildUnnamed5525();
  }
  buildCounterListPartnersResponse--;
  return o;
}

void checkListPartnersResponse(api.ListPartnersResponse o) {
  buildCounterListPartnersResponse++;
  if (buildCounterListPartnersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5525(o.partners!);
  }
  buildCounterListPartnersResponse--;
}

core.List<api.Site> buildUnnamed5526() {
  var o = <api.Site>[];
  o.add(buildSite());
  o.add(buildSite());
  return o;
}

void checkUnnamed5526(core.List<api.Site> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSite(o[0] as api.Site);
  checkSite(o[1] as api.Site);
}

core.int buildCounterListSitesResponse = 0;
api.ListSitesResponse buildListSitesResponse() {
  var o = api.ListSitesResponse();
  buildCounterListSitesResponse++;
  if (buildCounterListSitesResponse < 3) {
    o.nextPageToken = 'foo';
    o.sites = buildUnnamed5526();
  }
  buildCounterListSitesResponse--;
  return o;
}

void checkListSitesResponse(api.ListSitesResponse o) {
  buildCounterListSitesResponse++;
  if (buildCounterListSitesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5526(o.sites!);
  }
  buildCounterListSitesResponse--;
}

core.List<api.TargetingOption> buildUnnamed5527() {
  var o = <api.TargetingOption>[];
  o.add(buildTargetingOption());
  o.add(buildTargetingOption());
  return o;
}

void checkUnnamed5527(core.List<api.TargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetingOption(o[0] as api.TargetingOption);
  checkTargetingOption(o[1] as api.TargetingOption);
}

core.int buildCounterListTargetingOptionsResponse = 0;
api.ListTargetingOptionsResponse buildListTargetingOptionsResponse() {
  var o = api.ListTargetingOptionsResponse();
  buildCounterListTargetingOptionsResponse++;
  if (buildCounterListTargetingOptionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.targetingOptions = buildUnnamed5527();
  }
  buildCounterListTargetingOptionsResponse--;
  return o;
}

void checkListTargetingOptionsResponse(api.ListTargetingOptionsResponse o) {
  buildCounterListTargetingOptionsResponse++;
  if (buildCounterListTargetingOptionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5527(o.targetingOptions!);
  }
  buildCounterListTargetingOptionsResponse--;
}

core.List<api.User> buildUnnamed5528() {
  var o = <api.User>[];
  o.add(buildUser());
  o.add(buildUser());
  return o;
}

void checkUnnamed5528(core.List<api.User> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUser(o[0] as api.User);
  checkUser(o[1] as api.User);
}

core.int buildCounterListUsersResponse = 0;
api.ListUsersResponse buildListUsersResponse() {
  var o = api.ListUsersResponse();
  buildCounterListUsersResponse++;
  if (buildCounterListUsersResponse < 3) {
    o.nextPageToken = 'foo';
    o.users = buildUnnamed5528();
  }
  buildCounterListUsersResponse--;
  return o;
}

void checkListUsersResponse(api.ListUsersResponse o) {
  buildCounterListUsersResponse++;
  if (buildCounterListUsersResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5528(o.users!);
  }
  buildCounterListUsersResponse--;
}

core.int buildCounterLocationList = 0;
api.LocationList buildLocationList() {
  var o = api.LocationList();
  buildCounterLocationList++;
  if (buildCounterLocationList < 3) {
    o.advertiserId = 'foo';
    o.displayName = 'foo';
    o.locationListId = 'foo';
    o.locationType = 'foo';
    o.name = 'foo';
  }
  buildCounterLocationList--;
  return o;
}

void checkLocationList(api.LocationList o) {
  buildCounterLocationList++;
  if (buildCounterLocationList < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationListId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocationList--;
}

core.int buildCounterLookbackWindow = 0;
api.LookbackWindow buildLookbackWindow() {
  var o = api.LookbackWindow();
  buildCounterLookbackWindow++;
  if (buildCounterLookbackWindow < 3) {
    o.clickDays = 42;
    o.impressionDays = 42;
  }
  buildCounterLookbackWindow--;
  return o;
}

void checkLookbackWindow(api.LookbackWindow o) {
  buildCounterLookbackWindow++;
  if (buildCounterLookbackWindow < 3) {
    unittest.expect(
      o.clickDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.impressionDays!,
      unittest.equals(42),
    );
  }
  buildCounterLookbackWindow--;
}

core.int buildCounterLookupInvoiceCurrencyResponse = 0;
api.LookupInvoiceCurrencyResponse buildLookupInvoiceCurrencyResponse() {
  var o = api.LookupInvoiceCurrencyResponse();
  buildCounterLookupInvoiceCurrencyResponse++;
  if (buildCounterLookupInvoiceCurrencyResponse < 3) {
    o.currencyCode = 'foo';
  }
  buildCounterLookupInvoiceCurrencyResponse--;
  return o;
}

void checkLookupInvoiceCurrencyResponse(api.LookupInvoiceCurrencyResponse o) {
  buildCounterLookupInvoiceCurrencyResponse++;
  if (buildCounterLookupInvoiceCurrencyResponse < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterLookupInvoiceCurrencyResponse--;
}

core.int buildCounterManualTrigger = 0;
api.ManualTrigger buildManualTrigger() {
  var o = api.ManualTrigger();
  buildCounterManualTrigger++;
  if (buildCounterManualTrigger < 3) {
    o.activationDurationMinutes = 'foo';
    o.advertiserId = 'foo';
    o.displayName = 'foo';
    o.latestActivationTime = 'foo';
    o.name = 'foo';
    o.state = 'foo';
    o.triggerId = 'foo';
  }
  buildCounterManualTrigger--;
  return o;
}

void checkManualTrigger(api.ManualTrigger o) {
  buildCounterManualTrigger++;
  if (buildCounterManualTrigger < 3) {
    unittest.expect(
      o.activationDurationMinutes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.latestActivationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.triggerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterManualTrigger--;
}

core.int buildCounterMaximizeSpendBidStrategy = 0;
api.MaximizeSpendBidStrategy buildMaximizeSpendBidStrategy() {
  var o = api.MaximizeSpendBidStrategy();
  buildCounterMaximizeSpendBidStrategy++;
  if (buildCounterMaximizeSpendBidStrategy < 3) {
    o.customBiddingAlgorithmId = 'foo';
    o.maxAverageCpmBidAmountMicros = 'foo';
    o.performanceGoalType = 'foo';
  }
  buildCounterMaximizeSpendBidStrategy--;
  return o;
}

void checkMaximizeSpendBidStrategy(api.MaximizeSpendBidStrategy o) {
  buildCounterMaximizeSpendBidStrategy++;
  if (buildCounterMaximizeSpendBidStrategy < 3) {
    unittest.expect(
      o.customBiddingAlgorithmId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxAverageCpmBidAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.performanceGoalType!,
      unittest.equals('foo'),
    );
  }
  buildCounterMaximizeSpendBidStrategy--;
}

core.int buildCounterMeasurementConfig = 0;
api.MeasurementConfig buildMeasurementConfig() {
  var o = api.MeasurementConfig();
  buildCounterMeasurementConfig++;
  if (buildCounterMeasurementConfig < 3) {
    o.dv360ToCmCostReportingEnabled = true;
    o.dv360ToCmDataSharingEnabled = true;
  }
  buildCounterMeasurementConfig--;
  return o;
}

void checkMeasurementConfig(api.MeasurementConfig o) {
  buildCounterMeasurementConfig++;
  if (buildCounterMeasurementConfig < 3) {
    unittest.expect(o.dv360ToCmCostReportingEnabled!, unittest.isTrue);
    unittest.expect(o.dv360ToCmDataSharingEnabled!, unittest.isTrue);
  }
  buildCounterMeasurementConfig--;
}

core.int buildCounterMobileApp = 0;
api.MobileApp buildMobileApp() {
  var o = api.MobileApp();
  buildCounterMobileApp++;
  if (buildCounterMobileApp < 3) {
    o.appId = 'foo';
    o.displayName = 'foo';
    o.platform = 'foo';
    o.publisher = 'foo';
  }
  buildCounterMobileApp--;
  return o;
}

void checkMobileApp(api.MobileApp o) {
  buildCounterMobileApp++;
  if (buildCounterMobileApp < 3) {
    unittest.expect(
      o.appId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platform!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publisher!,
      unittest.equals('foo'),
    );
  }
  buildCounterMobileApp--;
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

core.int buildCounterNativeContentPositionAssignedTargetingOptionDetails = 0;
api.NativeContentPositionAssignedTargetingOptionDetails
    buildNativeContentPositionAssignedTargetingOptionDetails() {
  var o = api.NativeContentPositionAssignedTargetingOptionDetails();
  buildCounterNativeContentPositionAssignedTargetingOptionDetails++;
  if (buildCounterNativeContentPositionAssignedTargetingOptionDetails < 3) {
    o.contentPosition = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterNativeContentPositionAssignedTargetingOptionDetails--;
  return o;
}

void checkNativeContentPositionAssignedTargetingOptionDetails(
    api.NativeContentPositionAssignedTargetingOptionDetails o) {
  buildCounterNativeContentPositionAssignedTargetingOptionDetails++;
  if (buildCounterNativeContentPositionAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.contentPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterNativeContentPositionAssignedTargetingOptionDetails--;
}

core.int buildCounterNativeContentPositionTargetingOptionDetails = 0;
api.NativeContentPositionTargetingOptionDetails
    buildNativeContentPositionTargetingOptionDetails() {
  var o = api.NativeContentPositionTargetingOptionDetails();
  buildCounterNativeContentPositionTargetingOptionDetails++;
  if (buildCounterNativeContentPositionTargetingOptionDetails < 3) {
    o.contentPosition = 'foo';
  }
  buildCounterNativeContentPositionTargetingOptionDetails--;
  return o;
}

void checkNativeContentPositionTargetingOptionDetails(
    api.NativeContentPositionTargetingOptionDetails o) {
  buildCounterNativeContentPositionTargetingOptionDetails++;
  if (buildCounterNativeContentPositionTargetingOptionDetails < 3) {
    unittest.expect(
      o.contentPosition!,
      unittest.equals('foo'),
    );
  }
  buildCounterNativeContentPositionTargetingOptionDetails--;
}

core.int buildCounterNegativeKeyword = 0;
api.NegativeKeyword buildNegativeKeyword() {
  var o = api.NegativeKeyword();
  buildCounterNegativeKeyword++;
  if (buildCounterNegativeKeyword < 3) {
    o.keywordValue = 'foo';
    o.name = 'foo';
  }
  buildCounterNegativeKeyword--;
  return o;
}

void checkNegativeKeyword(api.NegativeKeyword o) {
  buildCounterNegativeKeyword++;
  if (buildCounterNegativeKeyword < 3) {
    unittest.expect(
      o.keywordValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterNegativeKeyword--;
}

core.int buildCounterNegativeKeywordList = 0;
api.NegativeKeywordList buildNegativeKeywordList() {
  var o = api.NegativeKeywordList();
  buildCounterNegativeKeywordList++;
  if (buildCounterNegativeKeywordList < 3) {
    o.advertiserId = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
    o.negativeKeywordListId = 'foo';
    o.targetedLineItemCount = 'foo';
  }
  buildCounterNegativeKeywordList--;
  return o;
}

void checkNegativeKeywordList(api.NegativeKeywordList o) {
  buildCounterNegativeKeywordList++;
  if (buildCounterNegativeKeywordList < 3) {
    unittest.expect(
      o.advertiserId!,
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
      o.negativeKeywordListId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetedLineItemCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterNegativeKeywordList--;
}

core.int buildCounterNegativeKeywordListAssignedTargetingOptionDetails = 0;
api.NegativeKeywordListAssignedTargetingOptionDetails
    buildNegativeKeywordListAssignedTargetingOptionDetails() {
  var o = api.NegativeKeywordListAssignedTargetingOptionDetails();
  buildCounterNegativeKeywordListAssignedTargetingOptionDetails++;
  if (buildCounterNegativeKeywordListAssignedTargetingOptionDetails < 3) {
    o.negativeKeywordListId = 'foo';
  }
  buildCounterNegativeKeywordListAssignedTargetingOptionDetails--;
  return o;
}

void checkNegativeKeywordListAssignedTargetingOptionDetails(
    api.NegativeKeywordListAssignedTargetingOptionDetails o) {
  buildCounterNegativeKeywordListAssignedTargetingOptionDetails++;
  if (buildCounterNegativeKeywordListAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.negativeKeywordListId!,
      unittest.equals('foo'),
    );
  }
  buildCounterNegativeKeywordListAssignedTargetingOptionDetails--;
}

core.int buildCounterObaIcon = 0;
api.ObaIcon buildObaIcon() {
  var o = api.ObaIcon();
  buildCounterObaIcon++;
  if (buildCounterObaIcon < 3) {
    o.clickTrackingUrl = 'foo';
    o.dimensions = buildDimensions();
    o.landingPageUrl = 'foo';
    o.position = 'foo';
    o.program = 'foo';
    o.resourceMimeType = 'foo';
    o.resourceUrl = 'foo';
    o.viewTrackingUrl = 'foo';
  }
  buildCounterObaIcon--;
  return o;
}

void checkObaIcon(api.ObaIcon o) {
  buildCounterObaIcon++;
  if (buildCounterObaIcon < 3) {
    unittest.expect(
      o.clickTrackingUrl!,
      unittest.equals('foo'),
    );
    checkDimensions(o.dimensions! as api.Dimensions);
    unittest.expect(
      o.landingPageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.position!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.program!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceMimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewTrackingUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterObaIcon--;
}

core.int buildCounterOnScreenPositionAssignedTargetingOptionDetails = 0;
api.OnScreenPositionAssignedTargetingOptionDetails
    buildOnScreenPositionAssignedTargetingOptionDetails() {
  var o = api.OnScreenPositionAssignedTargetingOptionDetails();
  buildCounterOnScreenPositionAssignedTargetingOptionDetails++;
  if (buildCounterOnScreenPositionAssignedTargetingOptionDetails < 3) {
    o.adType = 'foo';
    o.onScreenPosition = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterOnScreenPositionAssignedTargetingOptionDetails--;
  return o;
}

void checkOnScreenPositionAssignedTargetingOptionDetails(
    api.OnScreenPositionAssignedTargetingOptionDetails o) {
  buildCounterOnScreenPositionAssignedTargetingOptionDetails++;
  if (buildCounterOnScreenPositionAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.adType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.onScreenPosition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterOnScreenPositionAssignedTargetingOptionDetails--;
}

core.int buildCounterOnScreenPositionTargetingOptionDetails = 0;
api.OnScreenPositionTargetingOptionDetails
    buildOnScreenPositionTargetingOptionDetails() {
  var o = api.OnScreenPositionTargetingOptionDetails();
  buildCounterOnScreenPositionTargetingOptionDetails++;
  if (buildCounterOnScreenPositionTargetingOptionDetails < 3) {
    o.onScreenPosition = 'foo';
  }
  buildCounterOnScreenPositionTargetingOptionDetails--;
  return o;
}

void checkOnScreenPositionTargetingOptionDetails(
    api.OnScreenPositionTargetingOptionDetails o) {
  buildCounterOnScreenPositionTargetingOptionDetails++;
  if (buildCounterOnScreenPositionTargetingOptionDetails < 3) {
    unittest.expect(
      o.onScreenPosition!,
      unittest.equals('foo'),
    );
  }
  buildCounterOnScreenPositionTargetingOptionDetails--;
}

core.int buildCounterOperatingSystemAssignedTargetingOptionDetails = 0;
api.OperatingSystemAssignedTargetingOptionDetails
    buildOperatingSystemAssignedTargetingOptionDetails() {
  var o = api.OperatingSystemAssignedTargetingOptionDetails();
  buildCounterOperatingSystemAssignedTargetingOptionDetails++;
  if (buildCounterOperatingSystemAssignedTargetingOptionDetails < 3) {
    o.displayName = 'foo';
    o.negative = true;
    o.targetingOptionId = 'foo';
  }
  buildCounterOperatingSystemAssignedTargetingOptionDetails--;
  return o;
}

void checkOperatingSystemAssignedTargetingOptionDetails(
    api.OperatingSystemAssignedTargetingOptionDetails o) {
  buildCounterOperatingSystemAssignedTargetingOptionDetails++;
  if (buildCounterOperatingSystemAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperatingSystemAssignedTargetingOptionDetails--;
}

core.int buildCounterOperatingSystemTargetingOptionDetails = 0;
api.OperatingSystemTargetingOptionDetails
    buildOperatingSystemTargetingOptionDetails() {
  var o = api.OperatingSystemTargetingOptionDetails();
  buildCounterOperatingSystemTargetingOptionDetails++;
  if (buildCounterOperatingSystemTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterOperatingSystemTargetingOptionDetails--;
  return o;
}

void checkOperatingSystemTargetingOptionDetails(
    api.OperatingSystemTargetingOptionDetails o) {
  buildCounterOperatingSystemTargetingOptionDetails++;
  if (buildCounterOperatingSystemTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterOperatingSystemTargetingOptionDetails--;
}

core.Map<core.String, core.Object> buildUnnamed5529() {
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

void checkUnnamed5529(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed5530() {
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

void checkUnnamed5530(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed5529();
    o.name = 'foo';
    o.response = buildUnnamed5530();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed5529(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5530(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterPacing = 0;
api.Pacing buildPacing() {
  var o = api.Pacing();
  buildCounterPacing++;
  if (buildCounterPacing < 3) {
    o.dailyMaxImpressions = 'foo';
    o.dailyMaxMicros = 'foo';
    o.pacingPeriod = 'foo';
    o.pacingType = 'foo';
  }
  buildCounterPacing--;
  return o;
}

void checkPacing(api.Pacing o) {
  buildCounterPacing++;
  if (buildCounterPacing < 3) {
    unittest.expect(
      o.dailyMaxImpressions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dailyMaxMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pacingPeriod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pacingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPacing--;
}

core.List<core.String> buildUnnamed5531() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5531(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5532() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5532(core.List<core.String> o) {
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

core.int buildCounterParentEntityFilter = 0;
api.ParentEntityFilter buildParentEntityFilter() {
  var o = api.ParentEntityFilter();
  buildCounterParentEntityFilter++;
  if (buildCounterParentEntityFilter < 3) {
    o.fileType = buildUnnamed5531();
    o.filterIds = buildUnnamed5532();
    o.filterType = 'foo';
  }
  buildCounterParentEntityFilter--;
  return o;
}

void checkParentEntityFilter(api.ParentEntityFilter o) {
  buildCounterParentEntityFilter++;
  if (buildCounterParentEntityFilter < 3) {
    checkUnnamed5531(o.fileType!);
    checkUnnamed5532(o.filterIds!);
    unittest.expect(
      o.filterType!,
      unittest.equals('foo'),
    );
  }
  buildCounterParentEntityFilter--;
}

core.int buildCounterParentalStatusAssignedTargetingOptionDetails = 0;
api.ParentalStatusAssignedTargetingOptionDetails
    buildParentalStatusAssignedTargetingOptionDetails() {
  var o = api.ParentalStatusAssignedTargetingOptionDetails();
  buildCounterParentalStatusAssignedTargetingOptionDetails++;
  if (buildCounterParentalStatusAssignedTargetingOptionDetails < 3) {
    o.parentalStatus = 'foo';
    o.targetingOptionId = 'foo';
  }
  buildCounterParentalStatusAssignedTargetingOptionDetails--;
  return o;
}

void checkParentalStatusAssignedTargetingOptionDetails(
    api.ParentalStatusAssignedTargetingOptionDetails o) {
  buildCounterParentalStatusAssignedTargetingOptionDetails++;
  if (buildCounterParentalStatusAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.parentalStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterParentalStatusAssignedTargetingOptionDetails--;
}

core.int buildCounterParentalStatusTargetingOptionDetails = 0;
api.ParentalStatusTargetingOptionDetails
    buildParentalStatusTargetingOptionDetails() {
  var o = api.ParentalStatusTargetingOptionDetails();
  buildCounterParentalStatusTargetingOptionDetails++;
  if (buildCounterParentalStatusTargetingOptionDetails < 3) {
    o.parentalStatus = 'foo';
  }
  buildCounterParentalStatusTargetingOptionDetails--;
  return o;
}

void checkParentalStatusTargetingOptionDetails(
    api.ParentalStatusTargetingOptionDetails o) {
  buildCounterParentalStatusTargetingOptionDetails++;
  if (buildCounterParentalStatusTargetingOptionDetails < 3) {
    unittest.expect(
      o.parentalStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterParentalStatusTargetingOptionDetails--;
}

core.int buildCounterPartner = 0;
api.Partner buildPartner() {
  var o = api.Partner();
  buildCounterPartner++;
  if (buildCounterPartner < 3) {
    o.adServerConfig = buildPartnerAdServerConfig();
    o.dataAccessConfig = buildPartnerDataAccessConfig();
    o.displayName = 'foo';
    o.entityStatus = 'foo';
    o.exchangeConfig = buildExchangeConfig();
    o.generalConfig = buildPartnerGeneralConfig();
    o.name = 'foo';
    o.partnerId = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterPartner--;
  return o;
}

void checkPartner(api.Partner o) {
  buildCounterPartner++;
  if (buildCounterPartner < 3) {
    checkPartnerAdServerConfig(o.adServerConfig! as api.PartnerAdServerConfig);
    checkPartnerDataAccessConfig(
        o.dataAccessConfig! as api.PartnerDataAccessConfig);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityStatus!,
      unittest.equals('foo'),
    );
    checkExchangeConfig(o.exchangeConfig! as api.ExchangeConfig);
    checkPartnerGeneralConfig(o.generalConfig! as api.PartnerGeneralConfig);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartner--;
}

core.int buildCounterPartnerAdServerConfig = 0;
api.PartnerAdServerConfig buildPartnerAdServerConfig() {
  var o = api.PartnerAdServerConfig();
  buildCounterPartnerAdServerConfig++;
  if (buildCounterPartnerAdServerConfig < 3) {
    o.measurementConfig = buildMeasurementConfig();
  }
  buildCounterPartnerAdServerConfig--;
  return o;
}

void checkPartnerAdServerConfig(api.PartnerAdServerConfig o) {
  buildCounterPartnerAdServerConfig++;
  if (buildCounterPartnerAdServerConfig < 3) {
    checkMeasurementConfig(o.measurementConfig! as api.MeasurementConfig);
  }
  buildCounterPartnerAdServerConfig--;
}

core.int buildCounterPartnerCost = 0;
api.PartnerCost buildPartnerCost() {
  var o = api.PartnerCost();
  buildCounterPartnerCost++;
  if (buildCounterPartnerCost < 3) {
    o.costType = 'foo';
    o.feeAmount = 'foo';
    o.feePercentageMillis = 'foo';
    o.feeType = 'foo';
    o.invoiceType = 'foo';
  }
  buildCounterPartnerCost--;
  return o;
}

void checkPartnerCost(api.PartnerCost o) {
  buildCounterPartnerCost++;
  if (buildCounterPartnerCost < 3) {
    unittest.expect(
      o.costType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.feeAmount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.feePercentageMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.feeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.invoiceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartnerCost--;
}

core.int buildCounterPartnerDataAccessConfig = 0;
api.PartnerDataAccessConfig buildPartnerDataAccessConfig() {
  var o = api.PartnerDataAccessConfig();
  buildCounterPartnerDataAccessConfig++;
  if (buildCounterPartnerDataAccessConfig < 3) {
    o.sdfConfig = buildSdfConfig();
  }
  buildCounterPartnerDataAccessConfig--;
  return o;
}

void checkPartnerDataAccessConfig(api.PartnerDataAccessConfig o) {
  buildCounterPartnerDataAccessConfig++;
  if (buildCounterPartnerDataAccessConfig < 3) {
    checkSdfConfig(o.sdfConfig! as api.SdfConfig);
  }
  buildCounterPartnerDataAccessConfig--;
}

core.int buildCounterPartnerGeneralConfig = 0;
api.PartnerGeneralConfig buildPartnerGeneralConfig() {
  var o = api.PartnerGeneralConfig();
  buildCounterPartnerGeneralConfig++;
  if (buildCounterPartnerGeneralConfig < 3) {
    o.currencyCode = 'foo';
    o.timeZone = 'foo';
  }
  buildCounterPartnerGeneralConfig--;
  return o;
}

void checkPartnerGeneralConfig(api.PartnerGeneralConfig o) {
  buildCounterPartnerGeneralConfig++;
  if (buildCounterPartnerGeneralConfig < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartnerGeneralConfig--;
}

core.int buildCounterPartnerRevenueModel = 0;
api.PartnerRevenueModel buildPartnerRevenueModel() {
  var o = api.PartnerRevenueModel();
  buildCounterPartnerRevenueModel++;
  if (buildCounterPartnerRevenueModel < 3) {
    o.markupAmount = 'foo';
    o.markupType = 'foo';
  }
  buildCounterPartnerRevenueModel--;
  return o;
}

void checkPartnerRevenueModel(api.PartnerRevenueModel o) {
  buildCounterPartnerRevenueModel++;
  if (buildCounterPartnerRevenueModel < 3) {
    unittest.expect(
      o.markupAmount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.markupType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPartnerRevenueModel--;
}

core.int buildCounterPerformanceGoal = 0;
api.PerformanceGoal buildPerformanceGoal() {
  var o = api.PerformanceGoal();
  buildCounterPerformanceGoal++;
  if (buildCounterPerformanceGoal < 3) {
    o.performanceGoalAmountMicros = 'foo';
    o.performanceGoalPercentageMicros = 'foo';
    o.performanceGoalString = 'foo';
    o.performanceGoalType = 'foo';
  }
  buildCounterPerformanceGoal--;
  return o;
}

void checkPerformanceGoal(api.PerformanceGoal o) {
  buildCounterPerformanceGoal++;
  if (buildCounterPerformanceGoal < 3) {
    unittest.expect(
      o.performanceGoalAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.performanceGoalPercentageMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.performanceGoalString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.performanceGoalType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPerformanceGoal--;
}

core.int buildCounterPerformanceGoalBidStrategy = 0;
api.PerformanceGoalBidStrategy buildPerformanceGoalBidStrategy() {
  var o = api.PerformanceGoalBidStrategy();
  buildCounterPerformanceGoalBidStrategy++;
  if (buildCounterPerformanceGoalBidStrategy < 3) {
    o.customBiddingAlgorithmId = 'foo';
    o.maxAverageCpmBidAmountMicros = 'foo';
    o.performanceGoalAmountMicros = 'foo';
    o.performanceGoalType = 'foo';
  }
  buildCounterPerformanceGoalBidStrategy--;
  return o;
}

void checkPerformanceGoalBidStrategy(api.PerformanceGoalBidStrategy o) {
  buildCounterPerformanceGoalBidStrategy++;
  if (buildCounterPerformanceGoalBidStrategy < 3) {
    unittest.expect(
      o.customBiddingAlgorithmId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxAverageCpmBidAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.performanceGoalAmountMicros!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.performanceGoalType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPerformanceGoalBidStrategy--;
}

core.int buildCounterPrismaConfig = 0;
api.PrismaConfig buildPrismaConfig() {
  var o = api.PrismaConfig();
  buildCounterPrismaConfig++;
  if (buildCounterPrismaConfig < 3) {
    o.prismaCpeCode = buildPrismaCpeCode();
    o.prismaType = 'foo';
    o.supplier = 'foo';
  }
  buildCounterPrismaConfig--;
  return o;
}

void checkPrismaConfig(api.PrismaConfig o) {
  buildCounterPrismaConfig++;
  if (buildCounterPrismaConfig < 3) {
    checkPrismaCpeCode(o.prismaCpeCode! as api.PrismaCpeCode);
    unittest.expect(
      o.prismaType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.supplier!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrismaConfig--;
}

core.int buildCounterPrismaCpeCode = 0;
api.PrismaCpeCode buildPrismaCpeCode() {
  var o = api.PrismaCpeCode();
  buildCounterPrismaCpeCode++;
  if (buildCounterPrismaCpeCode < 3) {
    o.prismaClientCode = 'foo';
    o.prismaEstimateCode = 'foo';
    o.prismaProductCode = 'foo';
  }
  buildCounterPrismaCpeCode--;
  return o;
}

void checkPrismaCpeCode(api.PrismaCpeCode o) {
  buildCounterPrismaCpeCode++;
  if (buildCounterPrismaCpeCode < 3) {
    unittest.expect(
      o.prismaClientCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.prismaEstimateCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.prismaProductCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrismaCpeCode--;
}

core.int buildCounterProximityLocationListAssignedTargetingOptionDetails = 0;
api.ProximityLocationListAssignedTargetingOptionDetails
    buildProximityLocationListAssignedTargetingOptionDetails() {
  var o = api.ProximityLocationListAssignedTargetingOptionDetails();
  buildCounterProximityLocationListAssignedTargetingOptionDetails++;
  if (buildCounterProximityLocationListAssignedTargetingOptionDetails < 3) {
    o.proximityLocationListId = 'foo';
    o.proximityRadiusRange = 'foo';
  }
  buildCounterProximityLocationListAssignedTargetingOptionDetails--;
  return o;
}

void checkProximityLocationListAssignedTargetingOptionDetails(
    api.ProximityLocationListAssignedTargetingOptionDetails o) {
  buildCounterProximityLocationListAssignedTargetingOptionDetails++;
  if (buildCounterProximityLocationListAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.proximityLocationListId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proximityRadiusRange!,
      unittest.equals('foo'),
    );
  }
  buildCounterProximityLocationListAssignedTargetingOptionDetails--;
}

core.int buildCounterPublisherReviewStatus = 0;
api.PublisherReviewStatus buildPublisherReviewStatus() {
  var o = api.PublisherReviewStatus();
  buildCounterPublisherReviewStatus++;
  if (buildCounterPublisherReviewStatus < 3) {
    o.publisherName = 'foo';
    o.status = 'foo';
  }
  buildCounterPublisherReviewStatus--;
  return o;
}

void checkPublisherReviewStatus(api.PublisherReviewStatus o) {
  buildCounterPublisherReviewStatus++;
  if (buildCounterPublisherReviewStatus < 3) {
    unittest.expect(
      o.publisherName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
  }
  buildCounterPublisherReviewStatus--;
}

core.int buildCounterRateDetails = 0;
api.RateDetails buildRateDetails() {
  var o = api.RateDetails();
  buildCounterRateDetails++;
  if (buildCounterRateDetails < 3) {
    o.inventorySourceRateType = 'foo';
    o.minimumSpend = buildMoney();
    o.rate = buildMoney();
    o.unitsPurchased = 'foo';
  }
  buildCounterRateDetails--;
  return o;
}

void checkRateDetails(api.RateDetails o) {
  buildCounterRateDetails++;
  if (buildCounterRateDetails < 3) {
    unittest.expect(
      o.inventorySourceRateType!,
      unittest.equals('foo'),
    );
    checkMoney(o.minimumSpend! as api.Money);
    checkMoney(o.rate! as api.Money);
    unittest.expect(
      o.unitsPurchased!,
      unittest.equals('foo'),
    );
  }
  buildCounterRateDetails--;
}

core.int buildCounterRegionalLocationListAssignedTargetingOptionDetails = 0;
api.RegionalLocationListAssignedTargetingOptionDetails
    buildRegionalLocationListAssignedTargetingOptionDetails() {
  var o = api.RegionalLocationListAssignedTargetingOptionDetails();
  buildCounterRegionalLocationListAssignedTargetingOptionDetails++;
  if (buildCounterRegionalLocationListAssignedTargetingOptionDetails < 3) {
    o.negative = true;
    o.regionalLocationListId = 'foo';
  }
  buildCounterRegionalLocationListAssignedTargetingOptionDetails--;
  return o;
}

void checkRegionalLocationListAssignedTargetingOptionDetails(
    api.RegionalLocationListAssignedTargetingOptionDetails o) {
  buildCounterRegionalLocationListAssignedTargetingOptionDetails++;
  if (buildCounterRegionalLocationListAssignedTargetingOptionDetails < 3) {
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.regionalLocationListId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRegionalLocationListAssignedTargetingOptionDetails--;
}

core.List<api.NegativeKeyword> buildUnnamed5533() {
  var o = <api.NegativeKeyword>[];
  o.add(buildNegativeKeyword());
  o.add(buildNegativeKeyword());
  return o;
}

void checkUnnamed5533(core.List<api.NegativeKeyword> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNegativeKeyword(o[0] as api.NegativeKeyword);
  checkNegativeKeyword(o[1] as api.NegativeKeyword);
}

core.int buildCounterReplaceNegativeKeywordsRequest = 0;
api.ReplaceNegativeKeywordsRequest buildReplaceNegativeKeywordsRequest() {
  var o = api.ReplaceNegativeKeywordsRequest();
  buildCounterReplaceNegativeKeywordsRequest++;
  if (buildCounterReplaceNegativeKeywordsRequest < 3) {
    o.newNegativeKeywords = buildUnnamed5533();
  }
  buildCounterReplaceNegativeKeywordsRequest--;
  return o;
}

void checkReplaceNegativeKeywordsRequest(api.ReplaceNegativeKeywordsRequest o) {
  buildCounterReplaceNegativeKeywordsRequest++;
  if (buildCounterReplaceNegativeKeywordsRequest < 3) {
    checkUnnamed5533(o.newNegativeKeywords!);
  }
  buildCounterReplaceNegativeKeywordsRequest--;
}

core.List<api.NegativeKeyword> buildUnnamed5534() {
  var o = <api.NegativeKeyword>[];
  o.add(buildNegativeKeyword());
  o.add(buildNegativeKeyword());
  return o;
}

void checkUnnamed5534(core.List<api.NegativeKeyword> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNegativeKeyword(o[0] as api.NegativeKeyword);
  checkNegativeKeyword(o[1] as api.NegativeKeyword);
}

core.int buildCounterReplaceNegativeKeywordsResponse = 0;
api.ReplaceNegativeKeywordsResponse buildReplaceNegativeKeywordsResponse() {
  var o = api.ReplaceNegativeKeywordsResponse();
  buildCounterReplaceNegativeKeywordsResponse++;
  if (buildCounterReplaceNegativeKeywordsResponse < 3) {
    o.negativeKeywords = buildUnnamed5534();
  }
  buildCounterReplaceNegativeKeywordsResponse--;
  return o;
}

void checkReplaceNegativeKeywordsResponse(
    api.ReplaceNegativeKeywordsResponse o) {
  buildCounterReplaceNegativeKeywordsResponse++;
  if (buildCounterReplaceNegativeKeywordsResponse < 3) {
    checkUnnamed5534(o.negativeKeywords!);
  }
  buildCounterReplaceNegativeKeywordsResponse--;
}

core.List<api.Site> buildUnnamed5535() {
  var o = <api.Site>[];
  o.add(buildSite());
  o.add(buildSite());
  return o;
}

void checkUnnamed5535(core.List<api.Site> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSite(o[0] as api.Site);
  checkSite(o[1] as api.Site);
}

core.int buildCounterReplaceSitesRequest = 0;
api.ReplaceSitesRequest buildReplaceSitesRequest() {
  var o = api.ReplaceSitesRequest();
  buildCounterReplaceSitesRequest++;
  if (buildCounterReplaceSitesRequest < 3) {
    o.advertiserId = 'foo';
    o.newSites = buildUnnamed5535();
    o.partnerId = 'foo';
  }
  buildCounterReplaceSitesRequest--;
  return o;
}

void checkReplaceSitesRequest(api.ReplaceSitesRequest o) {
  buildCounterReplaceSitesRequest++;
  if (buildCounterReplaceSitesRequest < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkUnnamed5535(o.newSites!);
    unittest.expect(
      o.partnerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterReplaceSitesRequest--;
}

core.List<api.Site> buildUnnamed5536() {
  var o = <api.Site>[];
  o.add(buildSite());
  o.add(buildSite());
  return o;
}

void checkUnnamed5536(core.List<api.Site> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSite(o[0] as api.Site);
  checkSite(o[1] as api.Site);
}

core.int buildCounterReplaceSitesResponse = 0;
api.ReplaceSitesResponse buildReplaceSitesResponse() {
  var o = api.ReplaceSitesResponse();
  buildCounterReplaceSitesResponse++;
  if (buildCounterReplaceSitesResponse < 3) {
    o.sites = buildUnnamed5536();
  }
  buildCounterReplaceSitesResponse--;
  return o;
}

void checkReplaceSitesResponse(api.ReplaceSitesResponse o) {
  buildCounterReplaceSitesResponse++;
  if (buildCounterReplaceSitesResponse < 3) {
    checkUnnamed5536(o.sites!);
  }
  buildCounterReplaceSitesResponse--;
}

core.List<api.ExchangeReviewStatus> buildUnnamed5537() {
  var o = <api.ExchangeReviewStatus>[];
  o.add(buildExchangeReviewStatus());
  o.add(buildExchangeReviewStatus());
  return o;
}

void checkUnnamed5537(core.List<api.ExchangeReviewStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExchangeReviewStatus(o[0] as api.ExchangeReviewStatus);
  checkExchangeReviewStatus(o[1] as api.ExchangeReviewStatus);
}

core.List<api.PublisherReviewStatus> buildUnnamed5538() {
  var o = <api.PublisherReviewStatus>[];
  o.add(buildPublisherReviewStatus());
  o.add(buildPublisherReviewStatus());
  return o;
}

void checkUnnamed5538(core.List<api.PublisherReviewStatus> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPublisherReviewStatus(o[0] as api.PublisherReviewStatus);
  checkPublisherReviewStatus(o[1] as api.PublisherReviewStatus);
}

core.int buildCounterReviewStatusInfo = 0;
api.ReviewStatusInfo buildReviewStatusInfo() {
  var o = api.ReviewStatusInfo();
  buildCounterReviewStatusInfo++;
  if (buildCounterReviewStatusInfo < 3) {
    o.approvalStatus = 'foo';
    o.contentAndPolicyReviewStatus = 'foo';
    o.creativeAndLandingPageReviewStatus = 'foo';
    o.exchangeReviewStatuses = buildUnnamed5537();
    o.publisherReviewStatuses = buildUnnamed5538();
  }
  buildCounterReviewStatusInfo--;
  return o;
}

void checkReviewStatusInfo(api.ReviewStatusInfo o) {
  buildCounterReviewStatusInfo++;
  if (buildCounterReviewStatusInfo < 3) {
    unittest.expect(
      o.approvalStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.contentAndPolicyReviewStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creativeAndLandingPageReviewStatus!,
      unittest.equals('foo'),
    );
    checkUnnamed5537(o.exchangeReviewStatuses!);
    checkUnnamed5538(o.publisherReviewStatuses!);
  }
  buildCounterReviewStatusInfo--;
}

core.int buildCounterSdfConfig = 0;
api.SdfConfig buildSdfConfig() {
  var o = api.SdfConfig();
  buildCounterSdfConfig++;
  if (buildCounterSdfConfig < 3) {
    o.adminEmail = 'foo';
    o.version = 'foo';
  }
  buildCounterSdfConfig--;
  return o;
}

void checkSdfConfig(api.SdfConfig o) {
  buildCounterSdfConfig++;
  if (buildCounterSdfConfig < 3) {
    unittest.expect(
      o.adminEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterSdfConfig--;
}

core.int buildCounterSdfDownloadTask = 0;
api.SdfDownloadTask buildSdfDownloadTask() {
  var o = api.SdfDownloadTask();
  buildCounterSdfDownloadTask++;
  if (buildCounterSdfDownloadTask < 3) {
    o.resourceName = 'foo';
  }
  buildCounterSdfDownloadTask--;
  return o;
}

void checkSdfDownloadTask(api.SdfDownloadTask o) {
  buildCounterSdfDownloadTask++;
  if (buildCounterSdfDownloadTask < 3) {
    unittest.expect(
      o.resourceName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSdfDownloadTask--;
}

core.int buildCounterSdfDownloadTaskMetadata = 0;
api.SdfDownloadTaskMetadata buildSdfDownloadTaskMetadata() {
  var o = api.SdfDownloadTaskMetadata();
  buildCounterSdfDownloadTaskMetadata++;
  if (buildCounterSdfDownloadTaskMetadata < 3) {
    o.createTime = 'foo';
    o.endTime = 'foo';
    o.version = 'foo';
  }
  buildCounterSdfDownloadTaskMetadata--;
  return o;
}

void checkSdfDownloadTaskMetadata(api.SdfDownloadTaskMetadata o) {
  buildCounterSdfDownloadTaskMetadata++;
  if (buildCounterSdfDownloadTaskMetadata < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterSdfDownloadTaskMetadata--;
}

core.int buildCounterSearchTargetingOptionsRequest = 0;
api.SearchTargetingOptionsRequest buildSearchTargetingOptionsRequest() {
  var o = api.SearchTargetingOptionsRequest();
  buildCounterSearchTargetingOptionsRequest++;
  if (buildCounterSearchTargetingOptionsRequest < 3) {
    o.advertiserId = 'foo';
    o.geoRegionSearchTerms = buildGeoRegionSearchTerms();
    o.pageSize = 42;
    o.pageToken = 'foo';
  }
  buildCounterSearchTargetingOptionsRequest--;
  return o;
}

void checkSearchTargetingOptionsRequest(api.SearchTargetingOptionsRequest o) {
  buildCounterSearchTargetingOptionsRequest++;
  if (buildCounterSearchTargetingOptionsRequest < 3) {
    unittest.expect(
      o.advertiserId!,
      unittest.equals('foo'),
    );
    checkGeoRegionSearchTerms(
        o.geoRegionSearchTerms! as api.GeoRegionSearchTerms);
    unittest.expect(
      o.pageSize!,
      unittest.equals(42),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSearchTargetingOptionsRequest--;
}

core.List<api.TargetingOption> buildUnnamed5539() {
  var o = <api.TargetingOption>[];
  o.add(buildTargetingOption());
  o.add(buildTargetingOption());
  return o;
}

void checkUnnamed5539(core.List<api.TargetingOption> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetingOption(o[0] as api.TargetingOption);
  checkTargetingOption(o[1] as api.TargetingOption);
}

core.int buildCounterSearchTargetingOptionsResponse = 0;
api.SearchTargetingOptionsResponse buildSearchTargetingOptionsResponse() {
  var o = api.SearchTargetingOptionsResponse();
  buildCounterSearchTargetingOptionsResponse++;
  if (buildCounterSearchTargetingOptionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.targetingOptions = buildUnnamed5539();
  }
  buildCounterSearchTargetingOptionsResponse--;
  return o;
}

void checkSearchTargetingOptionsResponse(api.SearchTargetingOptionsResponse o) {
  buildCounterSearchTargetingOptionsResponse++;
  if (buildCounterSearchTargetingOptionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5539(o.targetingOptions!);
  }
  buildCounterSearchTargetingOptionsResponse--;
}

core.int buildCounterSensitiveCategoryAssignedTargetingOptionDetails = 0;
api.SensitiveCategoryAssignedTargetingOptionDetails
    buildSensitiveCategoryAssignedTargetingOptionDetails() {
  var o = api.SensitiveCategoryAssignedTargetingOptionDetails();
  buildCounterSensitiveCategoryAssignedTargetingOptionDetails++;
  if (buildCounterSensitiveCategoryAssignedTargetingOptionDetails < 3) {
    o.excludedTargetingOptionId = 'foo';
    o.sensitiveCategory = 'foo';
  }
  buildCounterSensitiveCategoryAssignedTargetingOptionDetails--;
  return o;
}

void checkSensitiveCategoryAssignedTargetingOptionDetails(
    api.SensitiveCategoryAssignedTargetingOptionDetails o) {
  buildCounterSensitiveCategoryAssignedTargetingOptionDetails++;
  if (buildCounterSensitiveCategoryAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.excludedTargetingOptionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sensitiveCategory!,
      unittest.equals('foo'),
    );
  }
  buildCounterSensitiveCategoryAssignedTargetingOptionDetails--;
}

core.int buildCounterSensitiveCategoryTargetingOptionDetails = 0;
api.SensitiveCategoryTargetingOptionDetails
    buildSensitiveCategoryTargetingOptionDetails() {
  var o = api.SensitiveCategoryTargetingOptionDetails();
  buildCounterSensitiveCategoryTargetingOptionDetails++;
  if (buildCounterSensitiveCategoryTargetingOptionDetails < 3) {
    o.sensitiveCategory = 'foo';
  }
  buildCounterSensitiveCategoryTargetingOptionDetails--;
  return o;
}

void checkSensitiveCategoryTargetingOptionDetails(
    api.SensitiveCategoryTargetingOptionDetails o) {
  buildCounterSensitiveCategoryTargetingOptionDetails++;
  if (buildCounterSensitiveCategoryTargetingOptionDetails < 3) {
    unittest.expect(
      o.sensitiveCategory!,
      unittest.equals('foo'),
    );
  }
  buildCounterSensitiveCategoryTargetingOptionDetails--;
}

core.int buildCounterSite = 0;
api.Site buildSite() {
  var o = api.Site();
  buildCounterSite++;
  if (buildCounterSite < 3) {
    o.name = 'foo';
    o.urlOrAppId = 'foo';
  }
  buildCounterSite--;
  return o;
}

void checkSite(api.Site o) {
  buildCounterSite++;
  if (buildCounterSite < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.urlOrAppId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSite--;
}

core.Map<core.String, core.Object> buildUnnamed5540() {
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

void checkUnnamed5540(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed5541() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed5540());
  o.add(buildUnnamed5540());
  return o;
}

void checkUnnamed5541(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5540(o[0]);
  checkUnnamed5540(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed5541();
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
    checkUnnamed5541(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterSubExchangeAssignedTargetingOptionDetails = 0;
api.SubExchangeAssignedTargetingOptionDetails
    buildSubExchangeAssignedTargetingOptionDetails() {
  var o = api.SubExchangeAssignedTargetingOptionDetails();
  buildCounterSubExchangeAssignedTargetingOptionDetails++;
  if (buildCounterSubExchangeAssignedTargetingOptionDetails < 3) {
    o.targetingOptionId = 'foo';
  }
  buildCounterSubExchangeAssignedTargetingOptionDetails--;
  return o;
}

void checkSubExchangeAssignedTargetingOptionDetails(
    api.SubExchangeAssignedTargetingOptionDetails o) {
  buildCounterSubExchangeAssignedTargetingOptionDetails++;
  if (buildCounterSubExchangeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubExchangeAssignedTargetingOptionDetails--;
}

core.int buildCounterSubExchangeTargetingOptionDetails = 0;
api.SubExchangeTargetingOptionDetails buildSubExchangeTargetingOptionDetails() {
  var o = api.SubExchangeTargetingOptionDetails();
  buildCounterSubExchangeTargetingOptionDetails++;
  if (buildCounterSubExchangeTargetingOptionDetails < 3) {
    o.displayName = 'foo';
  }
  buildCounterSubExchangeTargetingOptionDetails--;
  return o;
}

void checkSubExchangeTargetingOptionDetails(
    api.SubExchangeTargetingOptionDetails o) {
  buildCounterSubExchangeTargetingOptionDetails++;
  if (buildCounterSubExchangeTargetingOptionDetails < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubExchangeTargetingOptionDetails--;
}

core.int buildCounterTargetingExpansionConfig = 0;
api.TargetingExpansionConfig buildTargetingExpansionConfig() {
  var o = api.TargetingExpansionConfig();
  buildCounterTargetingExpansionConfig++;
  if (buildCounterTargetingExpansionConfig < 3) {
    o.excludeFirstPartyAudience = true;
    o.targetingExpansionLevel = 'foo';
  }
  buildCounterTargetingExpansionConfig--;
  return o;
}

void checkTargetingExpansionConfig(api.TargetingExpansionConfig o) {
  buildCounterTargetingExpansionConfig++;
  if (buildCounterTargetingExpansionConfig < 3) {
    unittest.expect(o.excludeFirstPartyAudience!, unittest.isTrue);
    unittest.expect(
      o.targetingExpansionLevel!,
      unittest.equals('foo'),
    );
  }
  buildCounterTargetingExpansionConfig--;
}

core.int buildCounterTargetingOption = 0;
api.TargetingOption buildTargetingOption() {
  var o = api.TargetingOption();
  buildCounterTargetingOption++;
  if (buildCounterTargetingOption < 3) {
    o.ageRangeDetails = buildAgeRangeTargetingOptionDetails();
    o.appCategoryDetails = buildAppCategoryTargetingOptionDetails();
    o.authorizedSellerStatusDetails =
        buildAuthorizedSellerStatusTargetingOptionDetails();
    o.browserDetails = buildBrowserTargetingOptionDetails();
    o.carrierAndIspDetails = buildCarrierAndIspTargetingOptionDetails();
    o.categoryDetails = buildCategoryTargetingOptionDetails();
    o.contentInstreamPositionDetails =
        buildContentInstreamPositionTargetingOptionDetails();
    o.contentOutstreamPositionDetails =
        buildContentOutstreamPositionTargetingOptionDetails();
    o.deviceMakeModelDetails = buildDeviceMakeModelTargetingOptionDetails();
    o.deviceTypeDetails = buildDeviceTypeTargetingOptionDetails();
    o.digitalContentLabelDetails =
        buildDigitalContentLabelTargetingOptionDetails();
    o.environmentDetails = buildEnvironmentTargetingOptionDetails();
    o.exchangeDetails = buildExchangeTargetingOptionDetails();
    o.genderDetails = buildGenderTargetingOptionDetails();
    o.geoRegionDetails = buildGeoRegionTargetingOptionDetails();
    o.householdIncomeDetails = buildHouseholdIncomeTargetingOptionDetails();
    o.languageDetails = buildLanguageTargetingOptionDetails();
    o.name = 'foo';
    o.nativeContentPositionDetails =
        buildNativeContentPositionTargetingOptionDetails();
    o.onScreenPositionDetails = buildOnScreenPositionTargetingOptionDetails();
    o.operatingSystemDetails = buildOperatingSystemTargetingOptionDetails();
    o.parentalStatusDetails = buildParentalStatusTargetingOptionDetails();
    o.sensitiveCategoryDetails = buildSensitiveCategoryTargetingOptionDetails();
    o.subExchangeDetails = buildSubExchangeTargetingOptionDetails();
    o.targetingOptionId = 'foo';
    o.targetingType = 'foo';
    o.userRewardedContentDetails =
        buildUserRewardedContentTargetingOptionDetails();
    o.videoPlayerSizeDetails = buildVideoPlayerSizeTargetingOptionDetails();
    o.viewabilityDetails = buildViewabilityTargetingOptionDetails();
  }
  buildCounterTargetingOption--;
  return o;
}

void checkTargetingOption(api.TargetingOption o) {
  buildCounterTargetingOption++;
  if (buildCounterTargetingOption < 3) {
    checkAgeRangeTargetingOptionDetails(
        o.ageRangeDetails! as api.AgeRangeTargetingOptionDetails);
    checkAppCategoryTargetingOptionDetails(
        o.appCategoryDetails! as api.AppCategoryTargetingOptionDetails);
    checkAuthorizedSellerStatusTargetingOptionDetails(
        o.authorizedSellerStatusDetails!
            as api.AuthorizedSellerStatusTargetingOptionDetails);
    checkBrowserTargetingOptionDetails(
        o.browserDetails! as api.BrowserTargetingOptionDetails);
    checkCarrierAndIspTargetingOptionDetails(
        o.carrierAndIspDetails! as api.CarrierAndIspTargetingOptionDetails);
    checkCategoryTargetingOptionDetails(
        o.categoryDetails! as api.CategoryTargetingOptionDetails);
    checkContentInstreamPositionTargetingOptionDetails(
        o.contentInstreamPositionDetails!
            as api.ContentInstreamPositionTargetingOptionDetails);
    checkContentOutstreamPositionTargetingOptionDetails(
        o.contentOutstreamPositionDetails!
            as api.ContentOutstreamPositionTargetingOptionDetails);
    checkDeviceMakeModelTargetingOptionDetails(
        o.deviceMakeModelDetails! as api.DeviceMakeModelTargetingOptionDetails);
    checkDeviceTypeTargetingOptionDetails(
        o.deviceTypeDetails! as api.DeviceTypeTargetingOptionDetails);
    checkDigitalContentLabelTargetingOptionDetails(o.digitalContentLabelDetails!
        as api.DigitalContentLabelTargetingOptionDetails);
    checkEnvironmentTargetingOptionDetails(
        o.environmentDetails! as api.EnvironmentTargetingOptionDetails);
    checkExchangeTargetingOptionDetails(
        o.exchangeDetails! as api.ExchangeTargetingOptionDetails);
    checkGenderTargetingOptionDetails(
        o.genderDetails! as api.GenderTargetingOptionDetails);
    checkGeoRegionTargetingOptionDetails(
        o.geoRegionDetails! as api.GeoRegionTargetingOptionDetails);
    checkHouseholdIncomeTargetingOptionDetails(
        o.householdIncomeDetails! as api.HouseholdIncomeTargetingOptionDetails);
    checkLanguageTargetingOptionDetails(
        o.languageDetails! as api.LanguageTargetingOptionDetails);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkNativeContentPositionTargetingOptionDetails(
        o.nativeContentPositionDetails!
            as api.NativeContentPositionTargetingOptionDetails);
    checkOnScreenPositionTargetingOptionDetails(o.onScreenPositionDetails!
        as api.OnScreenPositionTargetingOptionDetails);
    checkOperatingSystemTargetingOptionDetails(
        o.operatingSystemDetails! as api.OperatingSystemTargetingOptionDetails);
    checkParentalStatusTargetingOptionDetails(
        o.parentalStatusDetails! as api.ParentalStatusTargetingOptionDetails);
    checkSensitiveCategoryTargetingOptionDetails(o.sensitiveCategoryDetails!
        as api.SensitiveCategoryTargetingOptionDetails);
    checkSubExchangeTargetingOptionDetails(
        o.subExchangeDetails! as api.SubExchangeTargetingOptionDetails);
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetingType!,
      unittest.equals('foo'),
    );
    checkUserRewardedContentTargetingOptionDetails(o.userRewardedContentDetails!
        as api.UserRewardedContentTargetingOptionDetails);
    checkVideoPlayerSizeTargetingOptionDetails(
        o.videoPlayerSizeDetails! as api.VideoPlayerSizeTargetingOptionDetails);
    checkViewabilityTargetingOptionDetails(
        o.viewabilityDetails! as api.ViewabilityTargetingOptionDetails);
  }
  buildCounterTargetingOption--;
}

core.int buildCounterThirdPartyOnlyConfig = 0;
api.ThirdPartyOnlyConfig buildThirdPartyOnlyConfig() {
  var o = api.ThirdPartyOnlyConfig();
  buildCounterThirdPartyOnlyConfig++;
  if (buildCounterThirdPartyOnlyConfig < 3) {
    o.pixelOrderIdReportingEnabled = true;
  }
  buildCounterThirdPartyOnlyConfig--;
  return o;
}

void checkThirdPartyOnlyConfig(api.ThirdPartyOnlyConfig o) {
  buildCounterThirdPartyOnlyConfig++;
  if (buildCounterThirdPartyOnlyConfig < 3) {
    unittest.expect(o.pixelOrderIdReportingEnabled!, unittest.isTrue);
  }
  buildCounterThirdPartyOnlyConfig--;
}

core.int buildCounterThirdPartyUrl = 0;
api.ThirdPartyUrl buildThirdPartyUrl() {
  var o = api.ThirdPartyUrl();
  buildCounterThirdPartyUrl++;
  if (buildCounterThirdPartyUrl < 3) {
    o.type = 'foo';
    o.url = 'foo';
  }
  buildCounterThirdPartyUrl--;
  return o;
}

void checkThirdPartyUrl(api.ThirdPartyUrl o) {
  buildCounterThirdPartyUrl++;
  if (buildCounterThirdPartyUrl < 3) {
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterThirdPartyUrl--;
}

core.int buildCounterThirdPartyVerifierAssignedTargetingOptionDetails = 0;
api.ThirdPartyVerifierAssignedTargetingOptionDetails
    buildThirdPartyVerifierAssignedTargetingOptionDetails() {
  var o = api.ThirdPartyVerifierAssignedTargetingOptionDetails();
  buildCounterThirdPartyVerifierAssignedTargetingOptionDetails++;
  if (buildCounterThirdPartyVerifierAssignedTargetingOptionDetails < 3) {
    o.adloox = buildAdloox();
    o.doubleVerify = buildDoubleVerify();
    o.integralAdScience = buildIntegralAdScience();
  }
  buildCounterThirdPartyVerifierAssignedTargetingOptionDetails--;
  return o;
}

void checkThirdPartyVerifierAssignedTargetingOptionDetails(
    api.ThirdPartyVerifierAssignedTargetingOptionDetails o) {
  buildCounterThirdPartyVerifierAssignedTargetingOptionDetails++;
  if (buildCounterThirdPartyVerifierAssignedTargetingOptionDetails < 3) {
    checkAdloox(o.adloox! as api.Adloox);
    checkDoubleVerify(o.doubleVerify! as api.DoubleVerify);
    checkIntegralAdScience(o.integralAdScience! as api.IntegralAdScience);
  }
  buildCounterThirdPartyVerifierAssignedTargetingOptionDetails--;
}

core.int buildCounterTimeRange = 0;
api.TimeRange buildTimeRange() {
  var o = api.TimeRange();
  buildCounterTimeRange++;
  if (buildCounterTimeRange < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterTimeRange--;
  return o;
}

void checkTimeRange(api.TimeRange o) {
  buildCounterTimeRange++;
  if (buildCounterTimeRange < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimeRange--;
}

core.int buildCounterTimerEvent = 0;
api.TimerEvent buildTimerEvent() {
  var o = api.TimerEvent();
  buildCounterTimerEvent++;
  if (buildCounterTimerEvent < 3) {
    o.name = 'foo';
    o.reportingName = 'foo';
  }
  buildCounterTimerEvent--;
  return o;
}

void checkTimerEvent(api.TimerEvent o) {
  buildCounterTimerEvent++;
  if (buildCounterTimerEvent < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportingName!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimerEvent--;
}

core.int buildCounterTrackingFloodlightActivityConfig = 0;
api.TrackingFloodlightActivityConfig buildTrackingFloodlightActivityConfig() {
  var o = api.TrackingFloodlightActivityConfig();
  buildCounterTrackingFloodlightActivityConfig++;
  if (buildCounterTrackingFloodlightActivityConfig < 3) {
    o.floodlightActivityId = 'foo';
    o.postClickLookbackWindowDays = 42;
    o.postViewLookbackWindowDays = 42;
  }
  buildCounterTrackingFloodlightActivityConfig--;
  return o;
}

void checkTrackingFloodlightActivityConfig(
    api.TrackingFloodlightActivityConfig o) {
  buildCounterTrackingFloodlightActivityConfig++;
  if (buildCounterTrackingFloodlightActivityConfig < 3) {
    unittest.expect(
      o.floodlightActivityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.postClickLookbackWindowDays!,
      unittest.equals(42),
    );
    unittest.expect(
      o.postViewLookbackWindowDays!,
      unittest.equals(42),
    );
  }
  buildCounterTrackingFloodlightActivityConfig--;
}

core.int buildCounterTranscode = 0;
api.Transcode buildTranscode() {
  var o = api.Transcode();
  buildCounterTranscode++;
  if (buildCounterTranscode < 3) {
    o.audioBitRateKbps = 'foo';
    o.audioSampleRateHz = 'foo';
    o.bitRateKbps = 'foo';
    o.dimensions = buildDimensions();
    o.fileSizeBytes = 'foo';
    o.frameRate = 42.0;
    o.mimeType = 'foo';
    o.name = 'foo';
    o.transcoded = true;
  }
  buildCounterTranscode--;
  return o;
}

void checkTranscode(api.Transcode o) {
  buildCounterTranscode++;
  if (buildCounterTranscode < 3) {
    unittest.expect(
      o.audioBitRateKbps!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.audioSampleRateHz!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bitRateKbps!,
      unittest.equals('foo'),
    );
    checkDimensions(o.dimensions! as api.Dimensions);
    unittest.expect(
      o.fileSizeBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.frameRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.transcoded!, unittest.isTrue);
  }
  buildCounterTranscode--;
}

core.int buildCounterUniversalAdId = 0;
api.UniversalAdId buildUniversalAdId() {
  var o = api.UniversalAdId();
  buildCounterUniversalAdId++;
  if (buildCounterUniversalAdId < 3) {
    o.id = 'foo';
    o.registry = 'foo';
  }
  buildCounterUniversalAdId--;
  return o;
}

void checkUniversalAdId(api.UniversalAdId o) {
  buildCounterUniversalAdId++;
  if (buildCounterUniversalAdId < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.registry!,
      unittest.equals('foo'),
    );
  }
  buildCounterUniversalAdId--;
}

core.int buildCounterUrlAssignedTargetingOptionDetails = 0;
api.UrlAssignedTargetingOptionDetails buildUrlAssignedTargetingOptionDetails() {
  var o = api.UrlAssignedTargetingOptionDetails();
  buildCounterUrlAssignedTargetingOptionDetails++;
  if (buildCounterUrlAssignedTargetingOptionDetails < 3) {
    o.negative = true;
    o.url = 'foo';
  }
  buildCounterUrlAssignedTargetingOptionDetails--;
  return o;
}

void checkUrlAssignedTargetingOptionDetails(
    api.UrlAssignedTargetingOptionDetails o) {
  buildCounterUrlAssignedTargetingOptionDetails++;
  if (buildCounterUrlAssignedTargetingOptionDetails < 3) {
    unittest.expect(o.negative!, unittest.isTrue);
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlAssignedTargetingOptionDetails--;
}

core.List<api.AssignedUserRole> buildUnnamed5542() {
  var o = <api.AssignedUserRole>[];
  o.add(buildAssignedUserRole());
  o.add(buildAssignedUserRole());
  return o;
}

void checkUnnamed5542(core.List<api.AssignedUserRole> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAssignedUserRole(o[0] as api.AssignedUserRole);
  checkAssignedUserRole(o[1] as api.AssignedUserRole);
}

core.int buildCounterUser = 0;
api.User buildUser() {
  var o = api.User();
  buildCounterUser++;
  if (buildCounterUser < 3) {
    o.assignedUserRoles = buildUnnamed5542();
    o.displayName = 'foo';
    o.email = 'foo';
    o.name = 'foo';
    o.userId = 'foo';
  }
  buildCounterUser--;
  return o;
}

void checkUser(api.User o) {
  buildCounterUser++;
  if (buildCounterUser < 3) {
    checkUnnamed5542(o.assignedUserRoles!);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userId!,
      unittest.equals('foo'),
    );
  }
  buildCounterUser--;
}

core.int buildCounterUserRewardedContentAssignedTargetingOptionDetails = 0;
api.UserRewardedContentAssignedTargetingOptionDetails
    buildUserRewardedContentAssignedTargetingOptionDetails() {
  var o = api.UserRewardedContentAssignedTargetingOptionDetails();
  buildCounterUserRewardedContentAssignedTargetingOptionDetails++;
  if (buildCounterUserRewardedContentAssignedTargetingOptionDetails < 3) {
    o.targetingOptionId = 'foo';
    o.userRewardedContent = 'foo';
  }
  buildCounterUserRewardedContentAssignedTargetingOptionDetails--;
  return o;
}

void checkUserRewardedContentAssignedTargetingOptionDetails(
    api.UserRewardedContentAssignedTargetingOptionDetails o) {
  buildCounterUserRewardedContentAssignedTargetingOptionDetails++;
  if (buildCounterUserRewardedContentAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userRewardedContent!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserRewardedContentAssignedTargetingOptionDetails--;
}

core.int buildCounterUserRewardedContentTargetingOptionDetails = 0;
api.UserRewardedContentTargetingOptionDetails
    buildUserRewardedContentTargetingOptionDetails() {
  var o = api.UserRewardedContentTargetingOptionDetails();
  buildCounterUserRewardedContentTargetingOptionDetails++;
  if (buildCounterUserRewardedContentTargetingOptionDetails < 3) {
    o.userRewardedContent = 'foo';
  }
  buildCounterUserRewardedContentTargetingOptionDetails--;
  return o;
}

void checkUserRewardedContentTargetingOptionDetails(
    api.UserRewardedContentTargetingOptionDetails o) {
  buildCounterUserRewardedContentTargetingOptionDetails++;
  if (buildCounterUserRewardedContentTargetingOptionDetails < 3) {
    unittest.expect(
      o.userRewardedContent!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserRewardedContentTargetingOptionDetails--;
}

core.int buildCounterVideoPlayerSizeAssignedTargetingOptionDetails = 0;
api.VideoPlayerSizeAssignedTargetingOptionDetails
    buildVideoPlayerSizeAssignedTargetingOptionDetails() {
  var o = api.VideoPlayerSizeAssignedTargetingOptionDetails();
  buildCounterVideoPlayerSizeAssignedTargetingOptionDetails++;
  if (buildCounterVideoPlayerSizeAssignedTargetingOptionDetails < 3) {
    o.targetingOptionId = 'foo';
    o.videoPlayerSize = 'foo';
  }
  buildCounterVideoPlayerSizeAssignedTargetingOptionDetails--;
  return o;
}

void checkVideoPlayerSizeAssignedTargetingOptionDetails(
    api.VideoPlayerSizeAssignedTargetingOptionDetails o) {
  buildCounterVideoPlayerSizeAssignedTargetingOptionDetails++;
  if (buildCounterVideoPlayerSizeAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoPlayerSize!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoPlayerSizeAssignedTargetingOptionDetails--;
}

core.int buildCounterVideoPlayerSizeTargetingOptionDetails = 0;
api.VideoPlayerSizeTargetingOptionDetails
    buildVideoPlayerSizeTargetingOptionDetails() {
  var o = api.VideoPlayerSizeTargetingOptionDetails();
  buildCounterVideoPlayerSizeTargetingOptionDetails++;
  if (buildCounterVideoPlayerSizeTargetingOptionDetails < 3) {
    o.videoPlayerSize = 'foo';
  }
  buildCounterVideoPlayerSizeTargetingOptionDetails--;
  return o;
}

void checkVideoPlayerSizeTargetingOptionDetails(
    api.VideoPlayerSizeTargetingOptionDetails o) {
  buildCounterVideoPlayerSizeTargetingOptionDetails++;
  if (buildCounterVideoPlayerSizeTargetingOptionDetails < 3) {
    unittest.expect(
      o.videoPlayerSize!,
      unittest.equals('foo'),
    );
  }
  buildCounterVideoPlayerSizeTargetingOptionDetails--;
}

core.int buildCounterViewabilityAssignedTargetingOptionDetails = 0;
api.ViewabilityAssignedTargetingOptionDetails
    buildViewabilityAssignedTargetingOptionDetails() {
  var o = api.ViewabilityAssignedTargetingOptionDetails();
  buildCounterViewabilityAssignedTargetingOptionDetails++;
  if (buildCounterViewabilityAssignedTargetingOptionDetails < 3) {
    o.targetingOptionId = 'foo';
    o.viewability = 'foo';
  }
  buildCounterViewabilityAssignedTargetingOptionDetails--;
  return o;
}

void checkViewabilityAssignedTargetingOptionDetails(
    api.ViewabilityAssignedTargetingOptionDetails o) {
  buildCounterViewabilityAssignedTargetingOptionDetails++;
  if (buildCounterViewabilityAssignedTargetingOptionDetails < 3) {
    unittest.expect(
      o.targetingOptionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.viewability!,
      unittest.equals('foo'),
    );
  }
  buildCounterViewabilityAssignedTargetingOptionDetails--;
}

core.int buildCounterViewabilityTargetingOptionDetails = 0;
api.ViewabilityTargetingOptionDetails buildViewabilityTargetingOptionDetails() {
  var o = api.ViewabilityTargetingOptionDetails();
  buildCounterViewabilityTargetingOptionDetails++;
  if (buildCounterViewabilityTargetingOptionDetails < 3) {
    o.viewability = 'foo';
  }
  buildCounterViewabilityTargetingOptionDetails--;
  return o;
}

void checkViewabilityTargetingOptionDetails(
    api.ViewabilityTargetingOptionDetails o) {
  buildCounterViewabilityTargetingOptionDetails++;
  if (buildCounterViewabilityTargetingOptionDetails < 3) {
    unittest.expect(
      o.viewability!,
      unittest.equals('foo'),
    );
  }
  buildCounterViewabilityTargetingOptionDetails--;
}

void main() {
  unittest.group('obj-schema-ActivateManualTriggerRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivateManualTriggerRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivateManualTriggerRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivateManualTriggerRequest(od as api.ActivateManualTriggerRequest);
    });
  });

  unittest.group('obj-schema-ActiveViewVideoViewabilityMetricConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActiveViewVideoViewabilityMetricConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActiveViewVideoViewabilityMetricConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActiveViewVideoViewabilityMetricConfig(
          od as api.ActiveViewVideoViewabilityMetricConfig);
    });
  });

  unittest.group('obj-schema-Adloox', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdloox();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Adloox.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdloox(od as api.Adloox);
    });
  });

  unittest.group('obj-schema-Advertiser', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiser();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Advertiser.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiser(od as api.Advertiser);
    });
  });

  unittest.group('obj-schema-AdvertiserAdServerConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiserAdServerConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdvertiserAdServerConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiserAdServerConfig(od as api.AdvertiserAdServerConfig);
    });
  });

  unittest.group('obj-schema-AdvertiserCreativeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiserCreativeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdvertiserCreativeConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiserCreativeConfig(od as api.AdvertiserCreativeConfig);
    });
  });

  unittest.group('obj-schema-AdvertiserDataAccessConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiserDataAccessConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdvertiserDataAccessConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiserDataAccessConfig(od as api.AdvertiserDataAccessConfig);
    });
  });

  unittest.group('obj-schema-AdvertiserGeneralConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiserGeneralConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdvertiserGeneralConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiserGeneralConfig(od as api.AdvertiserGeneralConfig);
    });
  });

  unittest.group('obj-schema-AdvertiserSdfConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiserSdfConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdvertiserSdfConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiserSdfConfig(od as api.AdvertiserSdfConfig);
    });
  });

  unittest.group('obj-schema-AdvertiserTargetingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdvertiserTargetingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdvertiserTargetingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdvertiserTargetingConfig(od as api.AdvertiserTargetingConfig);
    });
  });

  unittest.group('obj-schema-AgeRangeAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAgeRangeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AgeRangeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAgeRangeAssignedTargetingOptionDetails(
          od as api.AgeRangeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-AgeRangeTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAgeRangeTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AgeRangeTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAgeRangeTargetingOptionDetails(
          od as api.AgeRangeTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-AppAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppAssignedTargetingOptionDetails(
          od as api.AppAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-AppCategoryAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppCategoryAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppCategoryAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppCategoryAssignedTargetingOptionDetails(
          od as api.AppCategoryAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-AppCategoryTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAppCategoryTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AppCategoryTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAppCategoryTargetingOptionDetails(
          od as api.AppCategoryTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-Asset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAsset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Asset.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAsset(od as api.Asset);
    });
  });

  unittest.group('obj-schema-AssetAssociation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssetAssociation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssetAssociation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssetAssociation(od as api.AssetAssociation);
    });
  });

  unittest.group('obj-schema-AssignedInventorySource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssignedInventorySource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssignedInventorySource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssignedInventorySource(od as api.AssignedInventorySource);
    });
  });

  unittest.group('obj-schema-AssignedLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssignedLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssignedLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssignedLocation(od as api.AssignedLocation);
    });
  });

  unittest.group('obj-schema-AssignedTargetingOption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssignedTargetingOption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssignedTargetingOption.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssignedTargetingOption(od as api.AssignedTargetingOption);
    });
  });

  unittest.group('obj-schema-AssignedUserRole', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAssignedUserRole();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AssignedUserRole.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAssignedUserRole(od as api.AssignedUserRole);
    });
  });

  unittest.group('obj-schema-AudienceGroupAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAudienceGroupAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AudienceGroupAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAudienceGroupAssignedTargetingOptionDetails(
          od as api.AudienceGroupAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-AudioVideoOffset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAudioVideoOffset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AudioVideoOffset.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAudioVideoOffset(od as api.AudioVideoOffset);
    });
  });

  unittest.group('obj-schema-AuditAdvertiserResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditAdvertiserResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditAdvertiserResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditAdvertiserResponse(od as api.AuditAdvertiserResponse);
    });
  });

  unittest.group(
      'obj-schema-AuthorizedSellerStatusAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthorizedSellerStatusAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.AuthorizedSellerStatusAssignedTargetingOptionDetails.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkAuthorizedSellerStatusAssignedTargetingOptionDetails(
          od as api.AuthorizedSellerStatusAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-AuthorizedSellerStatusTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuthorizedSellerStatusTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuthorizedSellerStatusTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuthorizedSellerStatusTargetingOptionDetails(
          od as api.AuthorizedSellerStatusTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-BiddingStrategy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBiddingStrategy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BiddingStrategy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBiddingStrategy(od as api.BiddingStrategy);
    });
  });

  unittest.group('obj-schema-BrowserAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBrowserAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BrowserAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBrowserAssignedTargetingOptionDetails(
          od as api.BrowserAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-BrowserTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBrowserTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BrowserTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBrowserTargetingOptionDetails(
          od as api.BrowserTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-BudgetSummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBudgetSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BudgetSummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBudgetSummary(od as api.BudgetSummary);
    });
  });

  unittest.group('obj-schema-BulkEditAdvertiserAssignedTargetingOptionsRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAdvertiserAssignedTargetingOptionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAdvertiserAssignedTargetingOptionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAdvertiserAssignedTargetingOptionsRequest(
          od as api.BulkEditAdvertiserAssignedTargetingOptionsRequest);
    });
  });

  unittest.group(
      'obj-schema-BulkEditAdvertiserAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAdvertiserAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAdvertiserAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAdvertiserAssignedTargetingOptionsResponse(
          od as api.BulkEditAdvertiserAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-BulkEditAssignedInventorySourcesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAssignedInventorySourcesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAssignedInventorySourcesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAssignedInventorySourcesRequest(
          od as api.BulkEditAssignedInventorySourcesRequest);
    });
  });

  unittest.group('obj-schema-BulkEditAssignedInventorySourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAssignedInventorySourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAssignedInventorySourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAssignedInventorySourcesResponse(
          od as api.BulkEditAssignedInventorySourcesResponse);
    });
  });

  unittest.group('obj-schema-BulkEditAssignedLocationsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAssignedLocationsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAssignedLocationsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAssignedLocationsRequest(
          od as api.BulkEditAssignedLocationsRequest);
    });
  });

  unittest.group('obj-schema-BulkEditAssignedLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAssignedLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAssignedLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAssignedLocationsResponse(
          od as api.BulkEditAssignedLocationsResponse);
    });
  });

  unittest.group('obj-schema-BulkEditAssignedUserRolesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAssignedUserRolesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAssignedUserRolesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAssignedUserRolesRequest(
          od as api.BulkEditAssignedUserRolesRequest);
    });
  });

  unittest.group('obj-schema-BulkEditAssignedUserRolesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditAssignedUserRolesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditAssignedUserRolesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditAssignedUserRolesResponse(
          od as api.BulkEditAssignedUserRolesResponse);
    });
  });

  unittest.group('obj-schema-BulkEditLineItemAssignedTargetingOptionsRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditLineItemAssignedTargetingOptionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditLineItemAssignedTargetingOptionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditLineItemAssignedTargetingOptionsRequest(
          od as api.BulkEditLineItemAssignedTargetingOptionsRequest);
    });
  });

  unittest.group('obj-schema-BulkEditLineItemAssignedTargetingOptionsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditLineItemAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditLineItemAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditLineItemAssignedTargetingOptionsResponse(
          od as api.BulkEditLineItemAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-BulkEditNegativeKeywordsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditNegativeKeywordsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditNegativeKeywordsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditNegativeKeywordsRequest(
          od as api.BulkEditNegativeKeywordsRequest);
    });
  });

  unittest.group('obj-schema-BulkEditNegativeKeywordsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditNegativeKeywordsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditNegativeKeywordsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditNegativeKeywordsResponse(
          od as api.BulkEditNegativeKeywordsResponse);
    });
  });

  unittest.group('obj-schema-BulkEditPartnerAssignedTargetingOptionsRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditPartnerAssignedTargetingOptionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditPartnerAssignedTargetingOptionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditPartnerAssignedTargetingOptionsRequest(
          od as api.BulkEditPartnerAssignedTargetingOptionsRequest);
    });
  });

  unittest.group('obj-schema-BulkEditPartnerAssignedTargetingOptionsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditPartnerAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditPartnerAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditPartnerAssignedTargetingOptionsResponse(
          od as api.BulkEditPartnerAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-BulkEditSitesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditSitesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditSitesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditSitesRequest(od as api.BulkEditSitesRequest);
    });
  });

  unittest.group('obj-schema-BulkEditSitesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkEditSitesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkEditSitesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkEditSitesResponse(od as api.BulkEditSitesResponse);
    });
  });

  unittest.group(
      'obj-schema-BulkListAdvertiserAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkListAdvertiserAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkListAdvertiserAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkListAdvertiserAssignedTargetingOptionsResponse(
          od as api.BulkListAdvertiserAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-BulkListCampaignAssignedTargetingOptionsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkListCampaignAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkListCampaignAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkListCampaignAssignedTargetingOptionsResponse(
          od as api.BulkListCampaignAssignedTargetingOptionsResponse);
    });
  });

  unittest.group(
      'obj-schema-BulkListInsertionOrderAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkListInsertionOrderAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.BulkListInsertionOrderAssignedTargetingOptionsResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkBulkListInsertionOrderAssignedTargetingOptionsResponse(
          od as api.BulkListInsertionOrderAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-BulkListLineItemAssignedTargetingOptionsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildBulkListLineItemAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BulkListLineItemAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBulkListLineItemAssignedTargetingOptionsResponse(
          od as api.BulkListLineItemAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-Campaign', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCampaign();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Campaign.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCampaign(od as api.Campaign);
    });
  });

  unittest.group('obj-schema-CampaignBudget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCampaignBudget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CampaignBudget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCampaignBudget(od as api.CampaignBudget);
    });
  });

  unittest.group('obj-schema-CampaignFlight', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCampaignFlight();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CampaignFlight.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCampaignFlight(od as api.CampaignFlight);
    });
  });

  unittest.group('obj-schema-CampaignGoal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCampaignGoal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CampaignGoal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCampaignGoal(od as api.CampaignGoal);
    });
  });

  unittest.group('obj-schema-CarrierAndIspAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCarrierAndIspAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CarrierAndIspAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCarrierAndIspAssignedTargetingOptionDetails(
          od as api.CarrierAndIspAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-CarrierAndIspTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCarrierAndIspTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CarrierAndIspTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCarrierAndIspTargetingOptionDetails(
          od as api.CarrierAndIspTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-CategoryAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategoryAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CategoryAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCategoryAssignedTargetingOptionDetails(
          od as api.CategoryAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-CategoryTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategoryTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CategoryTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCategoryTargetingOptionDetails(
          od as api.CategoryTargetingOptionDetails);
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

  unittest.group('obj-schema-ChannelAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannelAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChannelAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChannelAssignedTargetingOptionDetails(
          od as api.ChannelAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-CmHybridConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCmHybridConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CmHybridConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCmHybridConfig(od as api.CmHybridConfig);
    });
  });

  unittest.group('obj-schema-CmTrackingAd', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCmTrackingAd();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CmTrackingAd.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCmTrackingAd(od as api.CmTrackingAd);
    });
  });

  unittest.group('obj-schema-CombinedAudience', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCombinedAudience();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CombinedAudience.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCombinedAudience(od as api.CombinedAudience);
    });
  });

  unittest.group('obj-schema-CombinedAudienceGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCombinedAudienceGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CombinedAudienceGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCombinedAudienceGroup(od as api.CombinedAudienceGroup);
    });
  });

  unittest.group('obj-schema-CombinedAudienceTargetingSetting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCombinedAudienceTargetingSetting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CombinedAudienceTargetingSetting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCombinedAudienceTargetingSetting(
          od as api.CombinedAudienceTargetingSetting);
    });
  });

  unittest.group(
      'obj-schema-ContentInstreamPositionAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContentInstreamPositionAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ContentInstreamPositionAssignedTargetingOptionDetails.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkContentInstreamPositionAssignedTargetingOptionDetails(
          od as api.ContentInstreamPositionAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ContentInstreamPositionTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildContentInstreamPositionTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContentInstreamPositionTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContentInstreamPositionTargetingOptionDetails(
          od as api.ContentInstreamPositionTargetingOptionDetails);
    });
  });

  unittest.group(
      'obj-schema-ContentOutstreamPositionAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContentOutstreamPositionAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ContentOutstreamPositionAssignedTargetingOptionDetails.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkContentOutstreamPositionAssignedTargetingOptionDetails(
          od as api.ContentOutstreamPositionAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ContentOutstreamPositionTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildContentOutstreamPositionTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContentOutstreamPositionTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContentOutstreamPositionTargetingOptionDetails(
          od as api.ContentOutstreamPositionTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ConversionCountingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConversionCountingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConversionCountingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConversionCountingConfig(od as api.ConversionCountingConfig);
    });
  });

  unittest.group('obj-schema-CounterEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCounterEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CounterEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCounterEvent(od as api.CounterEvent);
    });
  });

  unittest.group('obj-schema-CreateAssetRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateAssetRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateAssetRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateAssetRequest(od as api.CreateAssetRequest);
    });
  });

  unittest.group('obj-schema-CreateAssetResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateAssetResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateAssetResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateAssetResponse(od as api.CreateAssetResponse);
    });
  });

  unittest.group('obj-schema-CreateAssignedTargetingOptionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateAssignedTargetingOptionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateAssignedTargetingOptionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateAssignedTargetingOptionsRequest(
          od as api.CreateAssignedTargetingOptionsRequest);
    });
  });

  unittest.group('obj-schema-CreateSdfDownloadTaskRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSdfDownloadTaskRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSdfDownloadTaskRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSdfDownloadTaskRequest(od as api.CreateSdfDownloadTaskRequest);
    });
  });

  unittest.group('obj-schema-Creative', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Creative.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCreative(od as api.Creative);
    });
  });

  unittest.group('obj-schema-CreativeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeConfig(od as api.CreativeConfig);
    });
  });

  unittest.group('obj-schema-CustomBiddingAlgorithm', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomBiddingAlgorithm();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomBiddingAlgorithm.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomBiddingAlgorithm(od as api.CustomBiddingAlgorithm);
    });
  });

  unittest.group('obj-schema-CustomList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CustomList.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCustomList(od as api.CustomList);
    });
  });

  unittest.group('obj-schema-CustomListGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomListGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomListGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomListGroup(od as api.CustomListGroup);
    });
  });

  unittest.group('obj-schema-CustomListTargetingSetting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCustomListTargetingSetting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CustomListTargetingSetting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCustomListTargetingSetting(od as api.CustomListTargetingSetting);
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

  unittest.group('obj-schema-DateRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDateRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DateRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDateRange(od as api.DateRange);
    });
  });

  unittest.group('obj-schema-DayAndTimeAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDayAndTimeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DayAndTimeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDayAndTimeAssignedTargetingOptionDetails(
          od as api.DayAndTimeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-DeactivateManualTriggerRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeactivateManualTriggerRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeactivateManualTriggerRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeactivateManualTriggerRequest(
          od as api.DeactivateManualTriggerRequest);
    });
  });

  unittest.group('obj-schema-DeleteAssignedTargetingOptionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteAssignedTargetingOptionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteAssignedTargetingOptionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteAssignedTargetingOptionsRequest(
          od as api.DeleteAssignedTargetingOptionsRequest);
    });
  });

  unittest.group('obj-schema-DeviceMakeModelAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceMakeModelAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceMakeModelAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceMakeModelAssignedTargetingOptionDetails(
          od as api.DeviceMakeModelAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-DeviceMakeModelTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceMakeModelTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceMakeModelTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceMakeModelTargetingOptionDetails(
          od as api.DeviceMakeModelTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-DeviceTypeAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceTypeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceTypeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceTypeAssignedTargetingOptionDetails(
          od as api.DeviceTypeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-DeviceTypeTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeviceTypeTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeviceTypeTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeviceTypeTargetingOptionDetails(
          od as api.DeviceTypeTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-DigitalContentLabelAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildDigitalContentLabelAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DigitalContentLabelAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDigitalContentLabelAssignedTargetingOptionDetails(
          od as api.DigitalContentLabelAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-DigitalContentLabelTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDigitalContentLabelTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DigitalContentLabelTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDigitalContentLabelTargetingOptionDetails(
          od as api.DigitalContentLabelTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-Dimensions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Dimensions.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDimensions(od as api.Dimensions);
    });
  });

  unittest.group('obj-schema-DoubleVerify', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleVerify();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleVerify.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleVerify(od as api.DoubleVerify);
    });
  });

  unittest.group('obj-schema-DoubleVerifyAppStarRating', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleVerifyAppStarRating();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleVerifyAppStarRating.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleVerifyAppStarRating(od as api.DoubleVerifyAppStarRating);
    });
  });

  unittest.group('obj-schema-DoubleVerifyBrandSafetyCategories', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleVerifyBrandSafetyCategories();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleVerifyBrandSafetyCategories.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleVerifyBrandSafetyCategories(
          od as api.DoubleVerifyBrandSafetyCategories);
    });
  });

  unittest.group('obj-schema-DoubleVerifyDisplayViewability', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleVerifyDisplayViewability();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleVerifyDisplayViewability.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleVerifyDisplayViewability(
          od as api.DoubleVerifyDisplayViewability);
    });
  });

  unittest.group('obj-schema-DoubleVerifyFraudInvalidTraffic', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleVerifyFraudInvalidTraffic();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleVerifyFraudInvalidTraffic.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleVerifyFraudInvalidTraffic(
          od as api.DoubleVerifyFraudInvalidTraffic);
    });
  });

  unittest.group('obj-schema-DoubleVerifyVideoViewability', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDoubleVerifyVideoViewability();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DoubleVerifyVideoViewability.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDoubleVerifyVideoViewability(od as api.DoubleVerifyVideoViewability);
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

  unittest.group('obj-schema-EnvironmentAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironmentAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnvironmentAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironmentAssignedTargetingOptionDetails(
          od as api.EnvironmentAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-EnvironmentTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnvironmentTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnvironmentTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnvironmentTargetingOptionDetails(
          od as api.EnvironmentTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ExchangeAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExchangeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExchangeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExchangeAssignedTargetingOptionDetails(
          od as api.ExchangeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ExchangeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExchangeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExchangeConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExchangeConfig(od as api.ExchangeConfig);
    });
  });

  unittest.group('obj-schema-ExchangeConfigEnabledExchange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExchangeConfigEnabledExchange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExchangeConfigEnabledExchange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExchangeConfigEnabledExchange(
          od as api.ExchangeConfigEnabledExchange);
    });
  });

  unittest.group('obj-schema-ExchangeReviewStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExchangeReviewStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExchangeReviewStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExchangeReviewStatus(od as api.ExchangeReviewStatus);
    });
  });

  unittest.group('obj-schema-ExchangeTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExchangeTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExchangeTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExchangeTargetingOptionDetails(
          od as api.ExchangeTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ExitEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExitEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ExitEvent.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExitEvent(od as api.ExitEvent);
    });
  });

  unittest.group('obj-schema-FirstAndThirdPartyAudience', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirstAndThirdPartyAudience();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirstAndThirdPartyAudience.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirstAndThirdPartyAudience(od as api.FirstAndThirdPartyAudience);
    });
  });

  unittest.group('obj-schema-FirstAndThirdPartyAudienceGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirstAndThirdPartyAudienceGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirstAndThirdPartyAudienceGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirstAndThirdPartyAudienceGroup(
          od as api.FirstAndThirdPartyAudienceGroup);
    });
  });

  unittest.group('obj-schema-FirstAndThirdPartyAudienceTargetingSetting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFirstAndThirdPartyAudienceTargetingSetting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FirstAndThirdPartyAudienceTargetingSetting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFirstAndThirdPartyAudienceTargetingSetting(
          od as api.FirstAndThirdPartyAudienceTargetingSetting);
    });
  });

  unittest.group('obj-schema-FixedBidStrategy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFixedBidStrategy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FixedBidStrategy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFixedBidStrategy(od as api.FixedBidStrategy);
    });
  });

  unittest.group('obj-schema-FloodlightGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFloodlightGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FloodlightGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFloodlightGroup(od as api.FloodlightGroup);
    });
  });

  unittest.group('obj-schema-FrequencyCap', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFrequencyCap();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FrequencyCap.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFrequencyCap(od as api.FrequencyCap);
    });
  });

  unittest.group('obj-schema-GenderAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenderAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenderAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenderAssignedTargetingOptionDetails(
          od as api.GenderAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-GenderTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenderTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenderTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenderTargetingOptionDetails(od as api.GenderTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-GenerateDefaultLineItemRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGenerateDefaultLineItemRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GenerateDefaultLineItemRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGenerateDefaultLineItemRequest(
          od as api.GenerateDefaultLineItemRequest);
    });
  });

  unittest.group('obj-schema-GeoRegionAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeoRegionAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GeoRegionAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGeoRegionAssignedTargetingOptionDetails(
          od as api.GeoRegionAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-GeoRegionSearchTerms', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeoRegionSearchTerms();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GeoRegionSearchTerms.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGeoRegionSearchTerms(od as api.GeoRegionSearchTerms);
    });
  });

  unittest.group('obj-schema-GeoRegionTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeoRegionTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GeoRegionTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGeoRegionTargetingOptionDetails(
          od as api.GeoRegionTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-GoogleAudience', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAudience();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAudience.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAudience(od as api.GoogleAudience);
    });
  });

  unittest.group('obj-schema-GoogleAudienceGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAudienceGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAudienceGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAudienceGroup(od as api.GoogleAudienceGroup);
    });
  });

  unittest.group('obj-schema-GoogleAudienceTargetingSetting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleAudienceTargetingSetting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleAudienceTargetingSetting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleAudienceTargetingSetting(
          od as api.GoogleAudienceTargetingSetting);
    });
  });

  unittest.group('obj-schema-GoogleBytestreamMedia', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleBytestreamMedia();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleBytestreamMedia.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleBytestreamMedia(od as api.GoogleBytestreamMedia);
    });
  });

  unittest.group('obj-schema-HouseholdIncomeAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildHouseholdIncomeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HouseholdIncomeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHouseholdIncomeAssignedTargetingOptionDetails(
          od as api.HouseholdIncomeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-HouseholdIncomeTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHouseholdIncomeTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HouseholdIncomeTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHouseholdIncomeTargetingOptionDetails(
          od as api.HouseholdIncomeTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-IdFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIdFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.IdFilter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkIdFilter(od as api.IdFilter);
    });
  });

  unittest.group('obj-schema-InsertionOrder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertionOrder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertionOrder.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertionOrder(od as api.InsertionOrder);
    });
  });

  unittest.group('obj-schema-InsertionOrderBudget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertionOrderBudget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertionOrderBudget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertionOrderBudget(od as api.InsertionOrderBudget);
    });
  });

  unittest.group('obj-schema-InsertionOrderBudgetSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInsertionOrderBudgetSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InsertionOrderBudgetSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInsertionOrderBudgetSegment(od as api.InsertionOrderBudgetSegment);
    });
  });

  unittest.group('obj-schema-IntegralAdScience', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntegralAdScience();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntegralAdScience.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntegralAdScience(od as api.IntegralAdScience);
    });
  });

  unittest.group('obj-schema-IntegrationDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIntegrationDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IntegrationDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIntegrationDetails(od as api.IntegrationDetails);
    });
  });

  unittest.group('obj-schema-InventorySource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySource(od as api.InventorySource);
    });
  });

  unittest.group('obj-schema-InventorySourceAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceAssignedTargetingOptionDetails(
          od as api.InventorySourceAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-InventorySourceDisplayCreativeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceDisplayCreativeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceDisplayCreativeConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceDisplayCreativeConfig(
          od as api.InventorySourceDisplayCreativeConfig);
    });
  });

  unittest.group('obj-schema-InventorySourceFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceFilter(od as api.InventorySourceFilter);
    });
  });

  unittest.group('obj-schema-InventorySourceGroup', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceGroup();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceGroup.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceGroup(od as api.InventorySourceGroup);
    });
  });

  unittest.group(
      'obj-schema-InventorySourceGroupAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceGroupAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceGroupAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceGroupAssignedTargetingOptionDetails(
          od as api.InventorySourceGroupAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-InventorySourceStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceStatus(od as api.InventorySourceStatus);
    });
  });

  unittest.group('obj-schema-InventorySourceVideoCreativeConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInventorySourceVideoCreativeConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InventorySourceVideoCreativeConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInventorySourceVideoCreativeConfig(
          od as api.InventorySourceVideoCreativeConfig);
    });
  });

  unittest.group('obj-schema-Invoice', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInvoice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Invoice.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkInvoice(od as api.Invoice);
    });
  });

  unittest.group('obj-schema-KeywordAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKeywordAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.KeywordAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkKeywordAssignedTargetingOptionDetails(
          od as api.KeywordAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-LanguageAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageAssignedTargetingOptionDetails(
          od as api.LanguageAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-LanguageTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageTargetingOptionDetails(
          od as api.LanguageTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-LineItem', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineItem();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LineItem.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLineItem(od as api.LineItem);
    });
  });

  unittest.group('obj-schema-LineItemBudget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineItemBudget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LineItemBudget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLineItemBudget(od as api.LineItemBudget);
    });
  });

  unittest.group('obj-schema-LineItemFlight', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLineItemFlight();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LineItemFlight.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLineItemFlight(od as api.LineItemFlight);
    });
  });

  unittest.group('obj-schema-ListAdvertiserAssignedTargetingOptionsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAdvertiserAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAdvertiserAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAdvertiserAssignedTargetingOptionsResponse(
          od as api.ListAdvertiserAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-ListAdvertisersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAdvertisersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAdvertisersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAdvertisersResponse(od as api.ListAdvertisersResponse);
    });
  });

  unittest.group('obj-schema-ListAssignedInventorySourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAssignedInventorySourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAssignedInventorySourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAssignedInventorySourcesResponse(
          od as api.ListAssignedInventorySourcesResponse);
    });
  });

  unittest.group('obj-schema-ListAssignedLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListAssignedLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListAssignedLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListAssignedLocationsResponse(
          od as api.ListAssignedLocationsResponse);
    });
  });

  unittest.group('obj-schema-ListCampaignAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCampaignAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCampaignAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCampaignAssignedTargetingOptionsResponse(
          od as api.ListCampaignAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-ListCampaignsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCampaignsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCampaignsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCampaignsResponse(od as api.ListCampaignsResponse);
    });
  });

  unittest.group('obj-schema-ListChannelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListChannelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListChannelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListChannelsResponse(od as api.ListChannelsResponse);
    });
  });

  unittest.group('obj-schema-ListCombinedAudiencesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCombinedAudiencesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCombinedAudiencesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCombinedAudiencesResponse(
          od as api.ListCombinedAudiencesResponse);
    });
  });

  unittest.group('obj-schema-ListCreativesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCreativesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCreativesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCreativesResponse(od as api.ListCreativesResponse);
    });
  });

  unittest.group('obj-schema-ListCustomBiddingAlgorithmsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCustomBiddingAlgorithmsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCustomBiddingAlgorithmsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCustomBiddingAlgorithmsResponse(
          od as api.ListCustomBiddingAlgorithmsResponse);
    });
  });

  unittest.group('obj-schema-ListCustomListsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListCustomListsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListCustomListsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListCustomListsResponse(od as api.ListCustomListsResponse);
    });
  });

  unittest.group('obj-schema-ListFirstAndThirdPartyAudiencesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFirstAndThirdPartyAudiencesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFirstAndThirdPartyAudiencesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFirstAndThirdPartyAudiencesResponse(
          od as api.ListFirstAndThirdPartyAudiencesResponse);
    });
  });

  unittest.group('obj-schema-ListGoogleAudiencesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGoogleAudiencesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGoogleAudiencesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGoogleAudiencesResponse(od as api.ListGoogleAudiencesResponse);
    });
  });

  unittest.group(
      'obj-schema-ListInsertionOrderAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInsertionOrderAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInsertionOrderAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInsertionOrderAssignedTargetingOptionsResponse(
          od as api.ListInsertionOrderAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-ListInsertionOrdersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInsertionOrdersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInsertionOrdersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInsertionOrdersResponse(od as api.ListInsertionOrdersResponse);
    });
  });

  unittest.group('obj-schema-ListInventorySourceGroupsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInventorySourceGroupsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInventorySourceGroupsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInventorySourceGroupsResponse(
          od as api.ListInventorySourceGroupsResponse);
    });
  });

  unittest.group('obj-schema-ListInventorySourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInventorySourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInventorySourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInventorySourcesResponse(od as api.ListInventorySourcesResponse);
    });
  });

  unittest.group('obj-schema-ListInvoicesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListInvoicesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListInvoicesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListInvoicesResponse(od as api.ListInvoicesResponse);
    });
  });

  unittest.group('obj-schema-ListLineItemAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLineItemAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLineItemAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLineItemAssignedTargetingOptionsResponse(
          od as api.ListLineItemAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-ListLineItemsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLineItemsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLineItemsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLineItemsResponse(od as api.ListLineItemsResponse);
    });
  });

  unittest.group('obj-schema-ListLocationListsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationListsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationListsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationListsResponse(od as api.ListLocationListsResponse);
    });
  });

  unittest.group('obj-schema-ListManualTriggersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListManualTriggersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListManualTriggersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListManualTriggersResponse(od as api.ListManualTriggersResponse);
    });
  });

  unittest.group('obj-schema-ListNegativeKeywordListsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListNegativeKeywordListsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListNegativeKeywordListsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListNegativeKeywordListsResponse(
          od as api.ListNegativeKeywordListsResponse);
    });
  });

  unittest.group('obj-schema-ListNegativeKeywordsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListNegativeKeywordsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListNegativeKeywordsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListNegativeKeywordsResponse(od as api.ListNegativeKeywordsResponse);
    });
  });

  unittest.group('obj-schema-ListPartnerAssignedTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPartnerAssignedTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPartnerAssignedTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPartnerAssignedTargetingOptionsResponse(
          od as api.ListPartnerAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-ListPartnersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPartnersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPartnersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPartnersResponse(od as api.ListPartnersResponse);
    });
  });

  unittest.group('obj-schema-ListSitesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSitesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSitesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSitesResponse(od as api.ListSitesResponse);
    });
  });

  unittest.group('obj-schema-ListTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTargetingOptionsResponse(od as api.ListTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-ListUsersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListUsersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListUsersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListUsersResponse(od as api.ListUsersResponse);
    });
  });

  unittest.group('obj-schema-LocationList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocationList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocationList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocationList(od as api.LocationList);
    });
  });

  unittest.group('obj-schema-LookbackWindow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLookbackWindow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LookbackWindow.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLookbackWindow(od as api.LookbackWindow);
    });
  });

  unittest.group('obj-schema-LookupInvoiceCurrencyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLookupInvoiceCurrencyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LookupInvoiceCurrencyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLookupInvoiceCurrencyResponse(
          od as api.LookupInvoiceCurrencyResponse);
    });
  });

  unittest.group('obj-schema-ManualTrigger', () {
    unittest.test('to-json--from-json', () async {
      var o = buildManualTrigger();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ManualTrigger.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkManualTrigger(od as api.ManualTrigger);
    });
  });

  unittest.group('obj-schema-MaximizeSpendBidStrategy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMaximizeSpendBidStrategy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MaximizeSpendBidStrategy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMaximizeSpendBidStrategy(od as api.MaximizeSpendBidStrategy);
    });
  });

  unittest.group('obj-schema-MeasurementConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMeasurementConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MeasurementConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMeasurementConfig(od as api.MeasurementConfig);
    });
  });

  unittest.group('obj-schema-MobileApp', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMobileApp();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.MobileApp.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMobileApp(od as api.MobileApp);
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

  unittest.group(
      'obj-schema-NativeContentPositionAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNativeContentPositionAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NativeContentPositionAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNativeContentPositionAssignedTargetingOptionDetails(
          od as api.NativeContentPositionAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-NativeContentPositionTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNativeContentPositionTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NativeContentPositionTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNativeContentPositionTargetingOptionDetails(
          od as api.NativeContentPositionTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-NegativeKeyword', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNegativeKeyword();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NegativeKeyword.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNegativeKeyword(od as api.NegativeKeyword);
    });
  });

  unittest.group('obj-schema-NegativeKeywordList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNegativeKeywordList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NegativeKeywordList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNegativeKeywordList(od as api.NegativeKeywordList);
    });
  });

  unittest.group('obj-schema-NegativeKeywordListAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildNegativeKeywordListAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NegativeKeywordListAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNegativeKeywordListAssignedTargetingOptionDetails(
          od as api.NegativeKeywordListAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ObaIcon', () {
    unittest.test('to-json--from-json', () async {
      var o = buildObaIcon();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ObaIcon.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkObaIcon(od as api.ObaIcon);
    });
  });

  unittest.group('obj-schema-OnScreenPositionAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildOnScreenPositionAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OnScreenPositionAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOnScreenPositionAssignedTargetingOptionDetails(
          od as api.OnScreenPositionAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-OnScreenPositionTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOnScreenPositionTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OnScreenPositionTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOnScreenPositionTargetingOptionDetails(
          od as api.OnScreenPositionTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-OperatingSystemAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperatingSystemAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperatingSystemAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperatingSystemAssignedTargetingOptionDetails(
          od as api.OperatingSystemAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-OperatingSystemTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperatingSystemTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OperatingSystemTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOperatingSystemTargetingOptionDetails(
          od as api.OperatingSystemTargetingOptionDetails);
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

  unittest.group('obj-schema-Pacing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPacing();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Pacing.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPacing(od as api.Pacing);
    });
  });

  unittest.group('obj-schema-ParentEntityFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParentEntityFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParentEntityFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParentEntityFilter(od as api.ParentEntityFilter);
    });
  });

  unittest.group('obj-schema-ParentalStatusAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParentalStatusAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParentalStatusAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParentalStatusAssignedTargetingOptionDetails(
          od as api.ParentalStatusAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ParentalStatusTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParentalStatusTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParentalStatusTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParentalStatusTargetingOptionDetails(
          od as api.ParentalStatusTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-Partner', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartner();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Partner.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPartner(od as api.Partner);
    });
  });

  unittest.group('obj-schema-PartnerAdServerConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerAdServerConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerAdServerConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerAdServerConfig(od as api.PartnerAdServerConfig);
    });
  });

  unittest.group('obj-schema-PartnerCost', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerCost();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerCost.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerCost(od as api.PartnerCost);
    });
  });

  unittest.group('obj-schema-PartnerDataAccessConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerDataAccessConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerDataAccessConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerDataAccessConfig(od as api.PartnerDataAccessConfig);
    });
  });

  unittest.group('obj-schema-PartnerGeneralConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerGeneralConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerGeneralConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerGeneralConfig(od as api.PartnerGeneralConfig);
    });
  });

  unittest.group('obj-schema-PartnerRevenueModel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPartnerRevenueModel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PartnerRevenueModel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPartnerRevenueModel(od as api.PartnerRevenueModel);
    });
  });

  unittest.group('obj-schema-PerformanceGoal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerformanceGoal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PerformanceGoal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPerformanceGoal(od as api.PerformanceGoal);
    });
  });

  unittest.group('obj-schema-PerformanceGoalBidStrategy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerformanceGoalBidStrategy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PerformanceGoalBidStrategy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPerformanceGoalBidStrategy(od as api.PerformanceGoalBidStrategy);
    });
  });

  unittest.group('obj-schema-PrismaConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrismaConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PrismaConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrismaConfig(od as api.PrismaConfig);
    });
  });

  unittest.group('obj-schema-PrismaCpeCode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrismaCpeCode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PrismaCpeCode.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrismaCpeCode(od as api.PrismaCpeCode);
    });
  });

  unittest.group(
      'obj-schema-ProximityLocationListAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProximityLocationListAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProximityLocationListAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProximityLocationListAssignedTargetingOptionDetails(
          od as api.ProximityLocationListAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-PublisherReviewStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublisherReviewStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublisherReviewStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublisherReviewStatus(od as api.PublisherReviewStatus);
    });
  });

  unittest.group('obj-schema-RateDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRateDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RateDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRateDetails(od as api.RateDetails);
    });
  });

  unittest.group(
      'obj-schema-RegionalLocationListAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegionalLocationListAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegionalLocationListAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegionalLocationListAssignedTargetingOptionDetails(
          od as api.RegionalLocationListAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ReplaceNegativeKeywordsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceNegativeKeywordsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceNegativeKeywordsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceNegativeKeywordsRequest(
          od as api.ReplaceNegativeKeywordsRequest);
    });
  });

  unittest.group('obj-schema-ReplaceNegativeKeywordsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceNegativeKeywordsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceNegativeKeywordsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceNegativeKeywordsResponse(
          od as api.ReplaceNegativeKeywordsResponse);
    });
  });

  unittest.group('obj-schema-ReplaceSitesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceSitesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceSitesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceSitesRequest(od as api.ReplaceSitesRequest);
    });
  });

  unittest.group('obj-schema-ReplaceSitesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReplaceSitesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReplaceSitesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReplaceSitesResponse(od as api.ReplaceSitesResponse);
    });
  });

  unittest.group('obj-schema-ReviewStatusInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReviewStatusInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReviewStatusInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReviewStatusInfo(od as api.ReviewStatusInfo);
    });
  });

  unittest.group('obj-schema-SdfConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSdfConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SdfConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSdfConfig(od as api.SdfConfig);
    });
  });

  unittest.group('obj-schema-SdfDownloadTask', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSdfDownloadTask();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SdfDownloadTask.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSdfDownloadTask(od as api.SdfDownloadTask);
    });
  });

  unittest.group('obj-schema-SdfDownloadTaskMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSdfDownloadTaskMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SdfDownloadTaskMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSdfDownloadTaskMetadata(od as api.SdfDownloadTaskMetadata);
    });
  });

  unittest.group('obj-schema-SearchTargetingOptionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchTargetingOptionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchTargetingOptionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchTargetingOptionsRequest(
          od as api.SearchTargetingOptionsRequest);
    });
  });

  unittest.group('obj-schema-SearchTargetingOptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSearchTargetingOptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SearchTargetingOptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSearchTargetingOptionsResponse(
          od as api.SearchTargetingOptionsResponse);
    });
  });

  unittest.group('obj-schema-SensitiveCategoryAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildSensitiveCategoryAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SensitiveCategoryAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSensitiveCategoryAssignedTargetingOptionDetails(
          od as api.SensitiveCategoryAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-SensitiveCategoryTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSensitiveCategoryTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SensitiveCategoryTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSensitiveCategoryTargetingOptionDetails(
          od as api.SensitiveCategoryTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-Site', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSite();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Site.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSite(od as api.Site);
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

  unittest.group('obj-schema-SubExchangeAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubExchangeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubExchangeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubExchangeAssignedTargetingOptionDetails(
          od as api.SubExchangeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-SubExchangeTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubExchangeTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubExchangeTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubExchangeTargetingOptionDetails(
          od as api.SubExchangeTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-TargetingExpansionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingExpansionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingExpansionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingExpansionConfig(od as api.TargetingExpansionConfig);
    });
  });

  unittest.group('obj-schema-TargetingOption', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingOption();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingOption.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingOption(od as api.TargetingOption);
    });
  });

  unittest.group('obj-schema-ThirdPartyOnlyConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyOnlyConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyOnlyConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyOnlyConfig(od as api.ThirdPartyOnlyConfig);
    });
  });

  unittest.group('obj-schema-ThirdPartyUrl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyUrl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyUrl.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyUrl(od as api.ThirdPartyUrl);
    });
  });

  unittest.group('obj-schema-ThirdPartyVerifierAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildThirdPartyVerifierAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ThirdPartyVerifierAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkThirdPartyVerifierAssignedTargetingOptionDetails(
          od as api.ThirdPartyVerifierAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-TimeRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeRange.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeRange(od as api.TimeRange);
    });
  });

  unittest.group('obj-schema-TimerEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimerEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimerEvent.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimerEvent(od as api.TimerEvent);
    });
  });

  unittest.group('obj-schema-TrackingFloodlightActivityConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrackingFloodlightActivityConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrackingFloodlightActivityConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrackingFloodlightActivityConfig(
          od as api.TrackingFloodlightActivityConfig);
    });
  });

  unittest.group('obj-schema-Transcode', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTranscode();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Transcode.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTranscode(od as api.Transcode);
    });
  });

  unittest.group('obj-schema-UniversalAdId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUniversalAdId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UniversalAdId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUniversalAdId(od as api.UniversalAdId);
    });
  });

  unittest.group('obj-schema-UrlAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrlAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UrlAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUrlAssignedTargetingOptionDetails(
          od as api.UrlAssignedTargetingOptionDetails);
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

  unittest.group('obj-schema-UserRewardedContentAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserRewardedContentAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserRewardedContentAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserRewardedContentAssignedTargetingOptionDetails(
          od as api.UserRewardedContentAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-UserRewardedContentTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserRewardedContentTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserRewardedContentTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserRewardedContentTargetingOptionDetails(
          od as api.UserRewardedContentTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-VideoPlayerSizeAssignedTargetingOptionDetails',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoPlayerSizeAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoPlayerSizeAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoPlayerSizeAssignedTargetingOptionDetails(
          od as api.VideoPlayerSizeAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-VideoPlayerSizeTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVideoPlayerSizeTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VideoPlayerSizeTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVideoPlayerSizeTargetingOptionDetails(
          od as api.VideoPlayerSizeTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ViewabilityAssignedTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildViewabilityAssignedTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ViewabilityAssignedTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkViewabilityAssignedTargetingOptionDetails(
          od as api.ViewabilityAssignedTargetingOptionDetails);
    });
  });

  unittest.group('obj-schema-ViewabilityTargetingOptionDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildViewabilityTargetingOptionDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ViewabilityTargetingOptionDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkViewabilityTargetingOptionDetails(
          od as api.ViewabilityTargetingOptionDetails);
    });
  });

  unittest.group('resource-AdvertisersResource', () {
    unittest.test('method--audit', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_advertiserId = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildAuditAdvertiserResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.audit(arg_advertiserId,
          readMask: arg_readMask, $fields: arg_$fields);
      checkAuditAdvertiserResponse(response as api.AuditAdvertiserResponse);
    });

    unittest.test('method--bulkEditAdvertiserAssignedTargetingOptions',
        () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_request =
          buildBulkEditAdvertiserAssignedTargetingOptionsRequest();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.BulkEditAdvertiserAssignedTargetingOptionsRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkBulkEditAdvertiserAssignedTargetingOptionsRequest(
            obj as api.BulkEditAdvertiserAssignedTargetingOptionsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildBulkEditAdvertiserAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEditAdvertiserAssignedTargetingOptions(
          arg_request, arg_advertiserId,
          $fields: arg_$fields);
      checkBulkEditAdvertiserAssignedTargetingOptionsResponse(
          response as api.BulkEditAdvertiserAssignedTargetingOptionsResponse);
    });

    unittest.test('method--bulkListAdvertiserAssignedTargetingOptions',
        () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildBulkListAdvertiserAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkListAdvertiserAssignedTargetingOptions(
          arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkBulkListAdvertiserAssignedTargetingOptionsResponse(
          response as api.BulkListAdvertiserAssignedTargetingOptionsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_request = buildAdvertiser();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Advertiser.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAdvertiser(obj as api.Advertiser);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers"),
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
        var resp = convert.json.encode(buildAdvertiser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkAdvertiser(response as api.Advertiser);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_advertiserId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_advertiserId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_advertiserId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAdvertiser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_advertiserId, $fields: arg_$fields);
      checkAdvertiser(response as api.Advertiser);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/advertisers"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListAdvertisersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListAdvertisersResponse(response as api.ListAdvertisersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers;
      var arg_request = buildAdvertiser();
      var arg_advertiserId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Advertiser.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAdvertiser(obj as api.Advertiser);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildAdvertiser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_advertiserId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkAdvertiser(response as api.Advertiser);
    });
  });

  unittest.group('resource-AdvertisersAssetsResource', () {
    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.assets;
      var arg_request = buildCreateAssetRequest();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateAssetRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateAssetRequest(obj as api.CreateAssetRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCreateAssetResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upload(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkCreateAssetResponse(response as api.CreateAssetResponse);
    });
  });

  unittest.group('resource-AdvertisersCampaignsResource', () {
    unittest.test('method--bulkListCampaignAssignedTargetingOptions', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.campaigns;
      var arg_advertiserId = 'foo';
      var arg_campaignId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildBulkListCampaignAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkListCampaignAssignedTargetingOptions(
          arg_advertiserId, arg_campaignId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkBulkListCampaignAssignedTargetingOptionsResponse(
          response as api.BulkListCampaignAssignedTargetingOptionsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.campaigns;
      var arg_request = buildCampaign();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Campaign.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCampaign(obj as api.Campaign);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCampaign());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkCampaign(response as api.Campaign);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.campaigns;
      var arg_advertiserId = 'foo';
      var arg_campaignId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_advertiserId, arg_campaignId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.campaigns;
      var arg_advertiserId = 'foo';
      var arg_campaignId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCampaign());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_advertiserId, arg_campaignId, $fields: arg_$fields);
      checkCampaign(response as api.Campaign);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.campaigns;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListCampaignsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCampaignsResponse(response as api.ListCampaignsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.campaigns;
      var arg_request = buildCampaign();
      var arg_advertiserId = 'foo';
      var arg_campaignId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Campaign.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCampaign(obj as api.Campaign);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildCampaign());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_campaignId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCampaign(response as api.Campaign);
    });
  });

  unittest.group(
      'resource-AdvertisersCampaignsTargetingTypesAssignedTargetingOptionsResource',
      () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .campaigns
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_campaignId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_advertiserId, arg_campaignId,
          arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .campaigns
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_campaignId = 'foo';
      var arg_targetingType = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildListCampaignAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_advertiserId, arg_campaignId, arg_targetingType,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCampaignAssignedTargetingOptionsResponse(
          response as api.ListCampaignAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('resource-AdvertisersChannelsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels;
      var arg_request = buildChannel();
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
      final response = await res.create(arg_request, arg_advertiserId,
          partnerId: arg_partnerId, $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels;
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
      final response = await res.get(arg_advertiserId, arg_channelId,
          partnerId: arg_partnerId, $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListChannelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListChannelsResponse(response as api.ListChannelsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels;
      var arg_request = buildChannel();
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_partnerId = 'foo';
      var arg_updateMask = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
        var resp = convert.json.encode(buildChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_channelId,
          partnerId: arg_partnerId,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });
  });

  unittest.group('resource-AdvertisersChannelsSitesResource', () {
    unittest.test('method--bulkEdit', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels.sites;
      var arg_request = buildBulkEditSitesRequest();
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditSitesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditSitesRequest(obj as api.BulkEditSitesRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBulkEditSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEdit(
          arg_request, arg_advertiserId, arg_channelId,
          $fields: arg_$fields);
      checkBulkEditSitesResponse(response as api.BulkEditSitesResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels.sites;
      var arg_request = buildSite();
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Site.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSite(obj as api.Site);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSite());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_advertiserId, arg_channelId,
          partnerId: arg_partnerId, $fields: arg_$fields);
      checkSite(response as api.Site);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels.sites;
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_urlOrAppId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
      final response = await res.delete(
          arg_advertiserId, arg_channelId, arg_urlOrAppId,
          partnerId: arg_partnerId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels.sites;
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId, arg_channelId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListSitesResponse(response as api.ListSitesResponse);
    });

    unittest.test('method--replace', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.channels.sites;
      var arg_request = buildReplaceSitesRequest();
      var arg_advertiserId = 'foo';
      var arg_channelId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReplaceSitesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReplaceSitesRequest(obj as api.ReplaceSitesRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReplaceSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.replace(
          arg_request, arg_advertiserId, arg_channelId,
          $fields: arg_$fields);
      checkReplaceSitesResponse(response as api.ReplaceSitesResponse);
    });
  });

  unittest.group('resource-AdvertisersCreativesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.creatives;
      var arg_request = buildCreative();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Creative.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCreative(obj as api.Creative);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCreative());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkCreative(response as api.Creative);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.creatives;
      var arg_advertiserId = 'foo';
      var arg_creativeId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_advertiserId, arg_creativeId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.creatives;
      var arg_advertiserId = 'foo';
      var arg_creativeId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCreative());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_advertiserId, arg_creativeId, $fields: arg_$fields);
      checkCreative(response as api.Creative);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.creatives;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListCreativesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCreativesResponse(response as api.ListCreativesResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.creatives;
      var arg_request = buildCreative();
      var arg_advertiserId = 'foo';
      var arg_creativeId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Creative.fromJson(json as core.Map<core.String, core.dynamic>);
        checkCreative(obj as api.Creative);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildCreative());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_creativeId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkCreative(response as api.Creative);
    });
  });

  unittest.group('resource-AdvertisersInsertionOrdersResource', () {
    unittest.test('method--bulkListInsertionOrderAssignedTargetingOptions',
        () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.insertionOrders;
      var arg_advertiserId = 'foo';
      var arg_insertionOrderId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(
            buildBulkListInsertionOrderAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkListInsertionOrderAssignedTargetingOptions(
          arg_advertiserId, arg_insertionOrderId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkBulkListInsertionOrderAssignedTargetingOptionsResponse(response
          as api.BulkListInsertionOrderAssignedTargetingOptionsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.insertionOrders;
      var arg_request = buildInsertionOrder();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InsertionOrder.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInsertionOrder(obj as api.InsertionOrder);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInsertionOrder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkInsertionOrder(response as api.InsertionOrder);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.insertionOrders;
      var arg_advertiserId = 'foo';
      var arg_insertionOrderId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_advertiserId, arg_insertionOrderId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.insertionOrders;
      var arg_advertiserId = 'foo';
      var arg_insertionOrderId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInsertionOrder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_advertiserId, arg_insertionOrderId,
          $fields: arg_$fields);
      checkInsertionOrder(response as api.InsertionOrder);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.insertionOrders;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListInsertionOrdersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInsertionOrdersResponse(
          response as api.ListInsertionOrdersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.insertionOrders;
      var arg_request = buildInsertionOrder();
      var arg_advertiserId = 'foo';
      var arg_insertionOrderId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InsertionOrder.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInsertionOrder(obj as api.InsertionOrder);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildInsertionOrder());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_insertionOrderId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkInsertionOrder(response as api.InsertionOrder);
    });
  });

  unittest.group(
      'resource-AdvertisersInsertionOrdersTargetingTypesAssignedTargetingOptionsResource',
      () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .insertionOrders
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_insertionOrderId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_advertiserId, arg_insertionOrderId,
          arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .insertionOrders
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_insertionOrderId = 'foo';
      var arg_targetingType = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildListInsertionOrderAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_advertiserId, arg_insertionOrderId, arg_targetingType,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInsertionOrderAssignedTargetingOptionsResponse(
          response as api.ListInsertionOrderAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('resource-AdvertisersInvoicesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.invoices;
      var arg_advertiserId = 'foo';
      var arg_issueMonth = 'foo';
      var arg_loiSapinInvoiceType = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["issueMonth"]!.first,
          unittest.equals(arg_issueMonth),
        );
        unittest.expect(
          queryMap["loiSapinInvoiceType"]!.first,
          unittest.equals(arg_loiSapinInvoiceType),
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
        var resp = convert.json.encode(buildListInvoicesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          issueMonth: arg_issueMonth,
          loiSapinInvoiceType: arg_loiSapinInvoiceType,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListInvoicesResponse(response as api.ListInvoicesResponse);
    });

    unittest.test('method--lookupInvoiceCurrency', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.invoices;
      var arg_advertiserId = 'foo';
      var arg_invoiceMonth = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["invoiceMonth"]!.first,
          unittest.equals(arg_invoiceMonth),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLookupInvoiceCurrencyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.lookupInvoiceCurrency(arg_advertiserId,
          invoiceMonth: arg_invoiceMonth, $fields: arg_$fields);
      checkLookupInvoiceCurrencyResponse(
          response as api.LookupInvoiceCurrencyResponse);
    });
  });

  unittest.group('resource-AdvertisersLineItemsResource', () {
    unittest.test('method--bulkEditLineItemAssignedTargetingOptions', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_request = buildBulkEditLineItemAssignedTargetingOptionsRequest();
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditLineItemAssignedTargetingOptionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditLineItemAssignedTargetingOptionsRequest(
            obj as api.BulkEditLineItemAssignedTargetingOptionsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json
            .encode(buildBulkEditLineItemAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEditLineItemAssignedTargetingOptions(
          arg_request, arg_advertiserId, arg_lineItemId,
          $fields: arg_$fields);
      checkBulkEditLineItemAssignedTargetingOptionsResponse(
          response as api.BulkEditLineItemAssignedTargetingOptionsResponse);
    });

    unittest.test('method--bulkListLineItemAssignedTargetingOptions', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildBulkListLineItemAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkListLineItemAssignedTargetingOptions(
          arg_advertiserId, arg_lineItemId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkBulkListLineItemAssignedTargetingOptionsResponse(
          response as api.BulkListLineItemAssignedTargetingOptionsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_request = buildLineItem();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.LineItem.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLineItem(obj as api.LineItem);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLineItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkLineItem(response as api.LineItem);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_advertiserId, arg_lineItemId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--generateDefault', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_request = buildGenerateDefaultLineItemRequest();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GenerateDefaultLineItemRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGenerateDefaultLineItemRequest(
            obj as api.GenerateDefaultLineItemRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLineItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.generateDefault(arg_request, arg_advertiserId,
          $fields: arg_$fields);
      checkLineItem(response as api.LineItem);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLineItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_advertiserId, arg_lineItemId, $fields: arg_$fields);
      checkLineItem(response as api.LineItem);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListLineItemsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLineItemsResponse(response as api.ListLineItemsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.lineItems;
      var arg_request = buildLineItem();
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.LineItem.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLineItem(obj as api.LineItem);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildLineItem());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_lineItemId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkLineItem(response as api.LineItem);
    });
  });

  unittest.group(
      'resource-AdvertisersLineItemsTargetingTypesAssignedTargetingOptionsResource',
      () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .lineItems
          .targetingTypes
          .assignedTargetingOptions;
      var arg_request = buildAssignedTargetingOption();
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_targetingType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AssignedTargetingOption.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAssignedTargetingOption(obj as api.AssignedTargetingOption);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_advertiserId, arg_lineItemId, arg_targetingType,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .lineItems
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_advertiserId, arg_lineItemId,
          arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .lineItems
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_advertiserId, arg_lineItemId,
          arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .lineItems
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_lineItemId = 'foo';
      var arg_targetingType = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildListLineItemAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_advertiserId, arg_lineItemId, arg_targetingType,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLineItemAssignedTargetingOptionsResponse(
          response as api.ListLineItemAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('resource-AdvertisersLocationListsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.locationLists;
      var arg_request = buildLocationList();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LocationList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLocationList(obj as api.LocationList);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLocationList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkLocationList(response as api.LocationList);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.locationLists;
      var arg_advertiserId = 'foo';
      var arg_locationListId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLocationList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_advertiserId, arg_locationListId,
          $fields: arg_$fields);
      checkLocationList(response as api.LocationList);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.locationLists;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListLocationListsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationListsResponse(response as api.ListLocationListsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.locationLists;
      var arg_request = buildLocationList();
      var arg_advertiserId = 'foo';
      var arg_locationListId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LocationList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLocationList(obj as api.LocationList);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildLocationList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_locationListId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkLocationList(response as api.LocationList);
    });
  });

  unittest.group('resource-AdvertisersLocationListsAssignedLocationsResource',
      () {
    unittest.test('method--bulkEdit', () async {
      var mock = HttpServerMock();
      var res =
          api.DisplayVideoApi(mock).advertisers.locationLists.assignedLocations;
      var arg_request = buildBulkEditAssignedLocationsRequest();
      var arg_advertiserId = 'foo';
      var arg_locationListId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditAssignedLocationsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditAssignedLocationsRequest(
            obj as api.BulkEditAssignedLocationsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/locationLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/locationLists/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildBulkEditAssignedLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEdit(
          arg_request, arg_advertiserId, arg_locationListId,
          $fields: arg_$fields);
      checkBulkEditAssignedLocationsResponse(
          response as api.BulkEditAssignedLocationsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res =
          api.DisplayVideoApi(mock).advertisers.locationLists.assignedLocations;
      var arg_request = buildAssignedLocation();
      var arg_advertiserId = 'foo';
      var arg_locationListId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AssignedLocation.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAssignedLocation(obj as api.AssignedLocation);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/locationLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/locationLists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/assignedLocations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_locationListId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/assignedLocations"),
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
        var resp = convert.json.encode(buildAssignedLocation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_advertiserId, arg_locationListId,
          $fields: arg_$fields);
      checkAssignedLocation(response as api.AssignedLocation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.DisplayVideoApi(mock).advertisers.locationLists.assignedLocations;
      var arg_advertiserId = 'foo';
      var arg_locationListId = 'foo';
      var arg_assignedLocationId = 'foo';
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/locationLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/locationLists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/assignedLocations/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_locationListId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/assignedLocations/"),
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
      final response = await res.delete(
          arg_advertiserId, arg_locationListId, arg_assignedLocationId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.DisplayVideoApi(mock).advertisers.locationLists.assignedLocations;
      var arg_advertiserId = 'foo';
      var arg_locationListId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/locationLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/locationLists/"),
        );
        pathOffset += 15;
        index = path.indexOf('/assignedLocations', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_locationListId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/assignedLocations"),
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
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListAssignedLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId, arg_locationListId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAssignedLocationsResponse(
          response as api.ListAssignedLocationsResponse);
    });
  });

  unittest.group('resource-AdvertisersManualTriggersResource', () {
    unittest.test('method--activate', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.manualTriggers;
      var arg_request = buildActivateManualTriggerRequest();
      var arg_advertiserId = 'foo';
      var arg_triggerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ActivateManualTriggerRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkActivateManualTriggerRequest(
            obj as api.ActivateManualTriggerRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildManualTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.activate(
          arg_request, arg_advertiserId, arg_triggerId,
          $fields: arg_$fields);
      checkManualTrigger(response as api.ManualTrigger);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.manualTriggers;
      var arg_request = buildManualTrigger();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ManualTrigger.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkManualTrigger(obj as api.ManualTrigger);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildManualTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkManualTrigger(response as api.ManualTrigger);
    });

    unittest.test('method--deactivate', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.manualTriggers;
      var arg_request = buildDeactivateManualTriggerRequest();
      var arg_advertiserId = 'foo';
      var arg_triggerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeactivateManualTriggerRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeactivateManualTriggerRequest(
            obj as api.DeactivateManualTriggerRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildManualTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.deactivate(
          arg_request, arg_advertiserId, arg_triggerId,
          $fields: arg_$fields);
      checkManualTrigger(response as api.ManualTrigger);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.manualTriggers;
      var arg_advertiserId = 'foo';
      var arg_triggerId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildManualTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_advertiserId, arg_triggerId, $fields: arg_$fields);
      checkManualTrigger(response as api.ManualTrigger);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.manualTriggers;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListManualTriggersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListManualTriggersResponse(
          response as api.ListManualTriggersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.manualTriggers;
      var arg_request = buildManualTrigger();
      var arg_advertiserId = 'foo';
      var arg_triggerId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ManualTrigger.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkManualTrigger(obj as api.ManualTrigger);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildManualTrigger());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_triggerId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkManualTrigger(response as api.ManualTrigger);
    });
  });

  unittest.group('resource-AdvertisersNegativeKeywordListsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.negativeKeywordLists;
      var arg_request = buildNegativeKeywordList();
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.NegativeKeywordList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkNegativeKeywordList(obj as api.NegativeKeywordList);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildNegativeKeywordList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_advertiserId, $fields: arg_$fields);
      checkNegativeKeywordList(response as api.NegativeKeywordList);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.negativeKeywordLists;
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          arg_advertiserId, arg_negativeKeywordListId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.negativeKeywordLists;
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildNegativeKeywordList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_advertiserId, arg_negativeKeywordListId,
          $fields: arg_$fields);
      checkNegativeKeywordList(response as api.NegativeKeywordList);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.negativeKeywordLists;
      var arg_advertiserId = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildListNegativeKeywordListsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListNegativeKeywordListsResponse(
          response as api.ListNegativeKeywordListsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).advertisers.negativeKeywordLists;
      var arg_request = buildNegativeKeywordList();
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.NegativeKeywordList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkNegativeKeywordList(obj as api.NegativeKeywordList);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
        var resp = convert.json.encode(buildNegativeKeywordList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_advertiserId, arg_negativeKeywordListId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkNegativeKeywordList(response as api.NegativeKeywordList);
    });
  });

  unittest.group(
      'resource-AdvertisersNegativeKeywordListsNegativeKeywordsResource', () {
    unittest.test('method--bulkEdit', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .negativeKeywordLists
          .negativeKeywords;
      var arg_request = buildBulkEditNegativeKeywordsRequest();
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditNegativeKeywordsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditNegativeKeywordsRequest(
            obj as api.BulkEditNegativeKeywordsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/negativeKeywordLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/negativeKeywordLists/"),
        );
        pathOffset += 22;
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
        var resp = convert.json.encode(buildBulkEditNegativeKeywordsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEdit(
          arg_request, arg_advertiserId, arg_negativeKeywordListId,
          $fields: arg_$fields);
      checkBulkEditNegativeKeywordsResponse(
          response as api.BulkEditNegativeKeywordsResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .negativeKeywordLists
          .negativeKeywords;
      var arg_request = buildNegativeKeyword();
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.NegativeKeyword.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkNegativeKeyword(obj as api.NegativeKeyword);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/negativeKeywordLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/negativeKeywordLists/"),
        );
        pathOffset += 22;
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
        var resp = convert.json.encode(buildNegativeKeyword());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_advertiserId, arg_negativeKeywordListId,
          $fields: arg_$fields);
      checkNegativeKeyword(response as api.NegativeKeyword);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .negativeKeywordLists
          .negativeKeywords;
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
      var arg_keywordValue = 'foo';
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/negativeKeywordLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/negativeKeywordLists/"),
        );
        pathOffset += 22;
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
      final response = await res.delete(
          arg_advertiserId, arg_negativeKeywordListId, arg_keywordValue,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .negativeKeywordLists
          .negativeKeywords;
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListNegativeKeywordsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_advertiserId, arg_negativeKeywordListId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListNegativeKeywordsResponse(
          response as api.ListNegativeKeywordsResponse);
    });

    unittest.test('method--replace', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .negativeKeywordLists
          .negativeKeywords;
      var arg_request = buildReplaceNegativeKeywordsRequest();
      var arg_advertiserId = 'foo';
      var arg_negativeKeywordListId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReplaceNegativeKeywordsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReplaceNegativeKeywordsRequest(
            obj as api.ReplaceNegativeKeywordsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
        );
        pathOffset += 15;
        index = path.indexOf('/negativeKeywordLists/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_advertiserId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/negativeKeywordLists/"),
        );
        pathOffset += 22;
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
        var resp = convert.json.encode(buildReplaceNegativeKeywordsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.replace(
          arg_request, arg_advertiserId, arg_negativeKeywordListId,
          $fields: arg_$fields);
      checkReplaceNegativeKeywordsResponse(
          response as api.ReplaceNegativeKeywordsResponse);
    });
  });

  unittest.group(
      'resource-AdvertisersTargetingTypesAssignedTargetingOptionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .targetingTypes
          .assignedTargetingOptions;
      var arg_request = buildAssignedTargetingOption();
      var arg_advertiserId = 'foo';
      var arg_targetingType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AssignedTargetingOption.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAssignedTargetingOption(obj as api.AssignedTargetingOption);

        var path = (req.url).path;
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_advertiserId, arg_targetingType,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          arg_advertiserId, arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          unittest.equals("v1/advertisers/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_advertiserId, arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .advertisers
          .targetingTypes
          .assignedTargetingOptions;
      var arg_advertiserId = 'foo';
      var arg_targetingType = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("v1/advertisers/"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildListAdvertiserAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_advertiserId, arg_targetingType,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListAdvertiserAssignedTargetingOptionsResponse(
          response as api.ListAdvertiserAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('resource-CombinedAudiencesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).combinedAudiences;
      var arg_combinedAudienceId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("v1/combinedAudiences/"),
        );
        pathOffset += 21;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCombinedAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_combinedAudienceId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkCombinedAudience(response as api.CombinedAudience);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).combinedAudiences;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/combinedAudiences"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListCombinedAudiencesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListCombinedAudiencesResponse(
          response as api.ListCombinedAudiencesResponse);
    });
  });

  unittest.group('resource-CustomBiddingAlgorithmsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).customBiddingAlgorithms;
      var arg_customBiddingAlgorithmId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("v1/customBiddingAlgorithms/"),
        );
        pathOffset += 27;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomBiddingAlgorithm());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customBiddingAlgorithmId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkCustomBiddingAlgorithm(response as api.CustomBiddingAlgorithm);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).customBiddingAlgorithms;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/customBiddingAlgorithms"),
        );
        pathOffset += 26;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildListCustomBiddingAlgorithmsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListCustomBiddingAlgorithmsResponse(
          response as api.ListCustomBiddingAlgorithmsResponse);
    });
  });

  unittest.group('resource-CustomListsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).customLists;
      var arg_customListId = 'foo';
      var arg_advertiserId = 'foo';
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
          unittest.equals("v1/customLists/"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCustomList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customListId,
          advertiserId: arg_advertiserId, $fields: arg_$fields);
      checkCustomList(response as api.CustomList);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).customLists;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/customLists"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListCustomListsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListCustomListsResponse(response as api.ListCustomListsResponse);
    });
  });

  unittest.group('resource-FirstAndThirdPartyAudiencesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).firstAndThirdPartyAudiences;
      var arg_firstAndThirdPartyAudienceId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/firstAndThirdPartyAudiences/"),
        );
        pathOffset += 31;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFirstAndThirdPartyAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_firstAndThirdPartyAudienceId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkFirstAndThirdPartyAudience(
          response as api.FirstAndThirdPartyAudience);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).firstAndThirdPartyAudiences;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/firstAndThirdPartyAudiences"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildListFirstAndThirdPartyAudiencesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListFirstAndThirdPartyAudiencesResponse(
          response as api.ListFirstAndThirdPartyAudiencesResponse);
    });
  });

  unittest.group('resource-FloodlightGroupsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).floodlightGroups;
      var arg_floodlightGroupId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/floodlightGroups/"),
        );
        pathOffset += 20;
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildFloodlightGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_floodlightGroupId,
          partnerId: arg_partnerId, $fields: arg_$fields);
      checkFloodlightGroup(response as api.FloodlightGroup);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).floodlightGroups;
      var arg_request = buildFloodlightGroup();
      var arg_floodlightGroupId = 'foo';
      var arg_partnerId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.FloodlightGroup.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkFloodlightGroup(obj as api.FloodlightGroup);

        var path = (req.url).path;
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
          unittest.equals("v1/floodlightGroups/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_floodlightGroupId'),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
        var resp = convert.json.encode(buildFloodlightGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_floodlightGroupId,
          partnerId: arg_partnerId,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkFloodlightGroup(response as api.FloodlightGroup);
    });
  });

  unittest.group('resource-GoogleAudiencesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).googleAudiences;
      var arg_googleAudienceId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/googleAudiences/"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGoogleAudience());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_googleAudienceId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkGoogleAudience(response as api.GoogleAudience);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).googleAudiences;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/googleAudiences"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListGoogleAudiencesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListGoogleAudiencesResponse(
          response as api.ListGoogleAudiencesResponse);
    });
  });

  unittest.group('resource-InventorySourceGroupsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySourceGroups;
      var arg_request = buildInventorySourceGroup();
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InventorySourceGroup.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInventorySourceGroup(obj as api.InventorySourceGroup);

        var path = (req.url).path;
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
          unittest.equals("v1/inventorySourceGroups"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInventorySourceGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkInventorySourceGroup(response as api.InventorySourceGroup);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySourceGroups;
      var arg_inventorySourceGroupId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
      final response = await res.delete(arg_inventorySourceGroupId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySourceGroups;
      var arg_inventorySourceGroupId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInventorySourceGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_inventorySourceGroupId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkInventorySourceGroup(response as api.InventorySourceGroup);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySourceGroups;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySourceGroups"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildListInventorySourceGroupsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListInventorySourceGroupsResponse(
          response as api.ListInventorySourceGroupsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySourceGroups;
      var arg_request = buildInventorySourceGroup();
      var arg_inventorySourceGroupId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.InventorySourceGroup.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkInventorySourceGroup(obj as api.InventorySourceGroup);

        var path = (req.url).path;
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_inventorySourceGroupId'),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
        var resp = convert.json.encode(buildInventorySourceGroup());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_inventorySourceGroupId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkInventorySourceGroup(response as api.InventorySourceGroup);
    });
  });

  unittest.group(
      'resource-InventorySourceGroupsAssignedInventorySourcesResource', () {
    unittest.test('method--bulkEdit', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .inventorySourceGroups
          .assignedInventorySources;
      var arg_request = buildBulkEditAssignedInventorySourcesRequest();
      var arg_inventorySourceGroupId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditAssignedInventorySourcesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditAssignedInventorySourcesRequest(
            obj as api.BulkEditAssignedInventorySourcesRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
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
        var resp = convert.json
            .encode(buildBulkEditAssignedInventorySourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEdit(
          arg_request, arg_inventorySourceGroupId,
          $fields: arg_$fields);
      checkBulkEditAssignedInventorySourcesResponse(
          response as api.BulkEditAssignedInventorySourcesResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .inventorySourceGroups
          .assignedInventorySources;
      var arg_request = buildAssignedInventorySource();
      var arg_inventorySourceGroupId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AssignedInventorySource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAssignedInventorySource(obj as api.AssignedInventorySource);

        var path = (req.url).path;
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedInventorySource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_inventorySourceGroupId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkAssignedInventorySource(response as api.AssignedInventorySource);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .inventorySourceGroups
          .assignedInventorySources;
      var arg_inventorySourceGroupId = 'foo';
      var arg_assignedInventorySourceId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
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
      final response = await res.delete(
          arg_inventorySourceGroupId, arg_assignedInventorySourceId,
          advertiserId: arg_advertiserId,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .inventorySourceGroups
          .assignedInventorySources;
      var arg_inventorySourceGroupId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySourceGroups/"),
        );
        pathOffset += 25;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildListAssignedInventorySourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_inventorySourceGroupId,
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListAssignedInventorySourcesResponse(
          response as api.ListAssignedInventorySourcesResponse);
    });
  });

  unittest.group('resource-InventorySourcesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySources;
      var arg_inventorySourceId = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySources/"),
        );
        pathOffset += 20;
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildInventorySource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_inventorySourceId,
          partnerId: arg_partnerId, $fields: arg_$fields);
      checkInventorySource(response as api.InventorySource);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).inventorySources;
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_partnerId = 'foo';
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
          unittest.equals("v1/inventorySources"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
          queryMap["partnerId"]!.first,
          unittest.equals(arg_partnerId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListInventorySourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          partnerId: arg_partnerId,
          $fields: arg_$fields);
      checkListInventorySourcesResponse(
          response as api.ListInventorySourcesResponse);
    });
  });

  unittest.group('resource-MediaResource', () {
    unittest.test('method--download', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).media;
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("download/"),
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
        var resp = convert.json.encode(buildGoogleBytestreamMedia());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.download(arg_resourceName, $fields: arg_$fields);
      checkGoogleBytestreamMedia(response as api.GoogleBytestreamMedia);
    });
  });

  unittest.group('resource-PartnersResource', () {
    unittest.test('method--bulkEditPartnerAssignedTargetingOptions', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners;
      var arg_request = buildBulkEditPartnerAssignedTargetingOptionsRequest();
      var arg_partnerId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditPartnerAssignedTargetingOptionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditPartnerAssignedTargetingOptionsRequest(
            obj as api.BulkEditPartnerAssignedTargetingOptionsRequest);

        var path = (req.url).path;
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
        var resp = convert.json
            .encode(buildBulkEditPartnerAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEditPartnerAssignedTargetingOptions(
          arg_request, arg_partnerId,
          $fields: arg_$fields);
      checkBulkEditPartnerAssignedTargetingOptionsResponse(
          response as api.BulkEditPartnerAssignedTargetingOptionsResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners;
      var arg_partnerId = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPartner());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_partnerId, $fields: arg_$fields);
      checkPartner(response as api.Partner);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners;
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          unittest.equals("v1/partners"),
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
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListPartnersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPartnersResponse(response as api.ListPartnersResponse);
    });
  });

  unittest.group('resource-PartnersChannelsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels;
      var arg_request = buildChannel();
      var arg_partnerId = 'foo';
      var arg_advertiserId = 'foo';
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
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
      final response = await res.create(arg_request, arg_partnerId,
          advertiserId: arg_advertiserId, $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels;
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_advertiserId = 'foo';
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
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
      final response = await res.get(arg_partnerId, arg_channelId,
          advertiserId: arg_advertiserId, $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels;
      var arg_partnerId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListChannelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_partnerId,
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListChannelsResponse(response as api.ListChannelsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels;
      var arg_request = buildChannel();
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_updateMask = 'foo';
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
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
        var resp = convert.json.encode(buildChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_partnerId, arg_channelId,
          advertiserId: arg_advertiserId,
          updateMask: arg_updateMask,
          $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });
  });

  unittest.group('resource-PartnersChannelsSitesResource', () {
    unittest.test('method--bulkEdit', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels.sites;
      var arg_request = buildBulkEditSitesRequest();
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditSitesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditSitesRequest(obj as api.BulkEditSitesRequest);

        var path = (req.url).path;
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
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_partnerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBulkEditSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEdit(
          arg_request, arg_partnerId, arg_channelId,
          $fields: arg_$fields);
      checkBulkEditSitesResponse(response as api.BulkEditSitesResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels.sites;
      var arg_request = buildSite();
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Site.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSite(obj as api.Site);

        var path = (req.url).path;
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
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_partnerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSite());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_partnerId, arg_channelId,
          advertiserId: arg_advertiserId, $fields: arg_$fields);
      checkSite(response as api.Site);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels.sites;
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_urlOrAppId = 'foo';
      var arg_advertiserId = 'foo';
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
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_partnerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
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
      final response = await res.delete(
          arg_partnerId, arg_channelId, arg_urlOrAppId,
          advertiserId: arg_advertiserId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels.sites;
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_partnerId, arg_channelId,
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSitesResponse(response as api.ListSitesResponse);
    });

    unittest.test('method--replace', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).partners.channels.sites;
      var arg_request = buildReplaceSitesRequest();
      var arg_partnerId = 'foo';
      var arg_channelId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ReplaceSitesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkReplaceSitesRequest(obj as api.ReplaceSitesRequest);

        var path = (req.url).path;
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
        index = path.indexOf('/channels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_partnerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/channels/"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReplaceSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.replace(
          arg_request, arg_partnerId, arg_channelId,
          $fields: arg_$fields);
      checkReplaceSitesResponse(response as api.ReplaceSitesResponse);
    });
  });

  unittest.group(
      'resource-PartnersTargetingTypesAssignedTargetingOptionsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .partners
          .targetingTypes
          .assignedTargetingOptions;
      var arg_request = buildAssignedTargetingOption();
      var arg_partnerId = 'foo';
      var arg_targetingType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AssignedTargetingOption.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAssignedTargetingOption(obj as api.AssignedTargetingOption);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(
          arg_request, arg_partnerId, arg_targetingType,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .partners
          .targetingTypes
          .assignedTargetingOptions;
      var arg_partnerId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          arg_partnerId, arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .partners
          .targetingTypes
          .assignedTargetingOptions;
      var arg_partnerId = 'foo';
      var arg_targetingType = 'foo';
      var arg_assignedTargetingOptionId = 'foo';
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAssignedTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_partnerId, arg_targetingType, arg_assignedTargetingOptionId,
          $fields: arg_$fields);
      checkAssignedTargetingOption(response as api.AssignedTargetingOption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock)
          .partners
          .targetingTypes
          .assignedTargetingOptions;
      var arg_partnerId = 'foo';
      var arg_targetingType = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json
            .encode(buildListPartnerAssignedTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_partnerId, arg_targetingType,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListPartnerAssignedTargetingOptionsResponse(
          response as api.ListPartnerAssignedTargetingOptionsResponse);
    });
  });

  unittest.group('resource-SdfdownloadtasksResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).sdfdownloadtasks;
      var arg_request = buildCreateSdfDownloadTaskRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateSdfDownloadTaskRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateSdfDownloadTaskRequest(
            obj as api.CreateSdfDownloadTaskRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/sdfdownloadtasks"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-SdfdownloadtasksOperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).sdfdownloadtasks.operations;
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

  unittest.group('resource-TargetingTypesTargetingOptionsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).targetingTypes.targetingOptions;
      var arg_targetingType = 'foo';
      var arg_targetingOptionId = 'foo';
      var arg_advertiserId = 'foo';
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
          unittest.equals("v1/targetingTypes/"),
        );
        pathOffset += 18;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTargetingOption());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_targetingType, arg_targetingOptionId,
          advertiserId: arg_advertiserId, $fields: arg_$fields);
      checkTargetingOption(response as api.TargetingOption);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).targetingTypes.targetingOptions;
      var arg_targetingType = 'foo';
      var arg_advertiserId = 'foo';
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          unittest.equals("v1/targetingTypes/"),
        );
        pathOffset += 18;
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
          queryMap["advertiserId"]!.first,
          unittest.equals(arg_advertiserId),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_targetingType,
          advertiserId: arg_advertiserId,
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListTargetingOptionsResponse(
          response as api.ListTargetingOptionsResponse);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).targetingTypes.targetingOptions;
      var arg_request = buildSearchTargetingOptionsRequest();
      var arg_targetingType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SearchTargetingOptionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSearchTargetingOptionsRequest(
            obj as api.SearchTargetingOptionsRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/targetingTypes/"),
        );
        pathOffset += 18;
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
        var resp = convert.json.encode(buildSearchTargetingOptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(arg_request, arg_targetingType,
          $fields: arg_$fields);
      checkSearchTargetingOptionsResponse(
          response as api.SearchTargetingOptionsResponse);
    });
  });

  unittest.group('resource-UsersResource', () {
    unittest.test('method--bulkEditAssignedUserRoles', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).users;
      var arg_request = buildBulkEditAssignedUserRolesRequest();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BulkEditAssignedUserRolesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBulkEditAssignedUserRolesRequest(
            obj as api.BulkEditAssignedUserRolesRequest);

        var path = (req.url).path;
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
          unittest.equals("v1/users/"),
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
        var resp =
            convert.json.encode(buildBulkEditAssignedUserRolesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.bulkEditAssignedUserRoles(
          arg_request, arg_userId,
          $fields: arg_$fields);
      checkBulkEditAssignedUserRolesResponse(
          response as api.BulkEditAssignedUserRolesResponse);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).users;
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
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/users"),
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
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkUser(response as api.User);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).users;
      var arg_userId = 'foo';
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
          unittest.equals("v1/users/"),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_userId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).users;
      var arg_userId = 'foo';
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
          unittest.equals("v1/users/"),
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
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, $fields: arg_$fields);
      checkUser(response as api.User);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).users;
      var arg_filter = 'foo';
      var arg_orderBy = 'foo';
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
          unittest.equals("v1/users"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["orderBy"]!.first,
          unittest.equals(arg_orderBy),
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
        var resp = convert.json.encode(buildListUsersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          orderBy: arg_orderBy,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListUsersResponse(response as api.ListUsersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.DisplayVideoApi(mock).users;
      var arg_request = buildUser();
      var arg_userId = 'foo';
      var arg_updateMask = 'foo';
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
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/users/"),
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
        var resp = convert.json.encode(buildUser());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_userId,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkUser(response as api.User);
    });
  });
}
