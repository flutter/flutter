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

import 'package:googleapis/games/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAchievementDefinition = 0;
api.AchievementDefinition buildAchievementDefinition() {
  var o = api.AchievementDefinition();
  buildCounterAchievementDefinition++;
  if (buildCounterAchievementDefinition < 3) {
    o.achievementType = 'foo';
    o.description = 'foo';
    o.experiencePoints = 'foo';
    o.formattedTotalSteps = 'foo';
    o.id = 'foo';
    o.initialState = 'foo';
    o.isRevealedIconUrlDefault = true;
    o.isUnlockedIconUrlDefault = true;
    o.kind = 'foo';
    o.name = 'foo';
    o.revealedIconUrl = 'foo';
    o.totalSteps = 42;
    o.unlockedIconUrl = 'foo';
  }
  buildCounterAchievementDefinition--;
  return o;
}

void checkAchievementDefinition(api.AchievementDefinition o) {
  buildCounterAchievementDefinition++;
  if (buildCounterAchievementDefinition < 3) {
    unittest.expect(
      o.achievementType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.experiencePoints!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedTotalSteps!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.initialState!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isRevealedIconUrlDefault!, unittest.isTrue);
    unittest.expect(o.isUnlockedIconUrlDefault!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revealedIconUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSteps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.unlockedIconUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterAchievementDefinition--;
}

core.List<api.AchievementDefinition> buildUnnamed3442() {
  var o = <api.AchievementDefinition>[];
  o.add(buildAchievementDefinition());
  o.add(buildAchievementDefinition());
  return o;
}

void checkUnnamed3442(core.List<api.AchievementDefinition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAchievementDefinition(o[0] as api.AchievementDefinition);
  checkAchievementDefinition(o[1] as api.AchievementDefinition);
}

core.int buildCounterAchievementDefinitionsListResponse = 0;
api.AchievementDefinitionsListResponse
    buildAchievementDefinitionsListResponse() {
  var o = api.AchievementDefinitionsListResponse();
  buildCounterAchievementDefinitionsListResponse++;
  if (buildCounterAchievementDefinitionsListResponse < 3) {
    o.items = buildUnnamed3442();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterAchievementDefinitionsListResponse--;
  return o;
}

void checkAchievementDefinitionsListResponse(
    api.AchievementDefinitionsListResponse o) {
  buildCounterAchievementDefinitionsListResponse++;
  if (buildCounterAchievementDefinitionsListResponse < 3) {
    checkUnnamed3442(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterAchievementDefinitionsListResponse--;
}

core.int buildCounterAchievementIncrementResponse = 0;
api.AchievementIncrementResponse buildAchievementIncrementResponse() {
  var o = api.AchievementIncrementResponse();
  buildCounterAchievementIncrementResponse++;
  if (buildCounterAchievementIncrementResponse < 3) {
    o.currentSteps = 42;
    o.kind = 'foo';
    o.newlyUnlocked = true;
  }
  buildCounterAchievementIncrementResponse--;
  return o;
}

void checkAchievementIncrementResponse(api.AchievementIncrementResponse o) {
  buildCounterAchievementIncrementResponse++;
  if (buildCounterAchievementIncrementResponse < 3) {
    unittest.expect(
      o.currentSteps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.newlyUnlocked!, unittest.isTrue);
  }
  buildCounterAchievementIncrementResponse--;
}

core.int buildCounterAchievementRevealResponse = 0;
api.AchievementRevealResponse buildAchievementRevealResponse() {
  var o = api.AchievementRevealResponse();
  buildCounterAchievementRevealResponse++;
  if (buildCounterAchievementRevealResponse < 3) {
    o.currentState = 'foo';
    o.kind = 'foo';
  }
  buildCounterAchievementRevealResponse--;
  return o;
}

void checkAchievementRevealResponse(api.AchievementRevealResponse o) {
  buildCounterAchievementRevealResponse++;
  if (buildCounterAchievementRevealResponse < 3) {
    unittest.expect(
      o.currentState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAchievementRevealResponse--;
}

core.int buildCounterAchievementSetStepsAtLeastResponse = 0;
api.AchievementSetStepsAtLeastResponse
    buildAchievementSetStepsAtLeastResponse() {
  var o = api.AchievementSetStepsAtLeastResponse();
  buildCounterAchievementSetStepsAtLeastResponse++;
  if (buildCounterAchievementSetStepsAtLeastResponse < 3) {
    o.currentSteps = 42;
    o.kind = 'foo';
    o.newlyUnlocked = true;
  }
  buildCounterAchievementSetStepsAtLeastResponse--;
  return o;
}

void checkAchievementSetStepsAtLeastResponse(
    api.AchievementSetStepsAtLeastResponse o) {
  buildCounterAchievementSetStepsAtLeastResponse++;
  if (buildCounterAchievementSetStepsAtLeastResponse < 3) {
    unittest.expect(
      o.currentSteps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.newlyUnlocked!, unittest.isTrue);
  }
  buildCounterAchievementSetStepsAtLeastResponse--;
}

core.int buildCounterAchievementUnlockResponse = 0;
api.AchievementUnlockResponse buildAchievementUnlockResponse() {
  var o = api.AchievementUnlockResponse();
  buildCounterAchievementUnlockResponse++;
  if (buildCounterAchievementUnlockResponse < 3) {
    o.kind = 'foo';
    o.newlyUnlocked = true;
  }
  buildCounterAchievementUnlockResponse--;
  return o;
}

void checkAchievementUnlockResponse(api.AchievementUnlockResponse o) {
  buildCounterAchievementUnlockResponse++;
  if (buildCounterAchievementUnlockResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.newlyUnlocked!, unittest.isTrue);
  }
  buildCounterAchievementUnlockResponse--;
}

core.List<api.AchievementUpdateRequest> buildUnnamed3443() {
  var o = <api.AchievementUpdateRequest>[];
  o.add(buildAchievementUpdateRequest());
  o.add(buildAchievementUpdateRequest());
  return o;
}

void checkUnnamed3443(core.List<api.AchievementUpdateRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAchievementUpdateRequest(o[0] as api.AchievementUpdateRequest);
  checkAchievementUpdateRequest(o[1] as api.AchievementUpdateRequest);
}

core.int buildCounterAchievementUpdateMultipleRequest = 0;
api.AchievementUpdateMultipleRequest buildAchievementUpdateMultipleRequest() {
  var o = api.AchievementUpdateMultipleRequest();
  buildCounterAchievementUpdateMultipleRequest++;
  if (buildCounterAchievementUpdateMultipleRequest < 3) {
    o.kind = 'foo';
    o.updates = buildUnnamed3443();
  }
  buildCounterAchievementUpdateMultipleRequest--;
  return o;
}

void checkAchievementUpdateMultipleRequest(
    api.AchievementUpdateMultipleRequest o) {
  buildCounterAchievementUpdateMultipleRequest++;
  if (buildCounterAchievementUpdateMultipleRequest < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3443(o.updates!);
  }
  buildCounterAchievementUpdateMultipleRequest--;
}

core.List<api.AchievementUpdateResponse> buildUnnamed3444() {
  var o = <api.AchievementUpdateResponse>[];
  o.add(buildAchievementUpdateResponse());
  o.add(buildAchievementUpdateResponse());
  return o;
}

void checkUnnamed3444(core.List<api.AchievementUpdateResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAchievementUpdateResponse(o[0] as api.AchievementUpdateResponse);
  checkAchievementUpdateResponse(o[1] as api.AchievementUpdateResponse);
}

core.int buildCounterAchievementUpdateMultipleResponse = 0;
api.AchievementUpdateMultipleResponse buildAchievementUpdateMultipleResponse() {
  var o = api.AchievementUpdateMultipleResponse();
  buildCounterAchievementUpdateMultipleResponse++;
  if (buildCounterAchievementUpdateMultipleResponse < 3) {
    o.kind = 'foo';
    o.updatedAchievements = buildUnnamed3444();
  }
  buildCounterAchievementUpdateMultipleResponse--;
  return o;
}

void checkAchievementUpdateMultipleResponse(
    api.AchievementUpdateMultipleResponse o) {
  buildCounterAchievementUpdateMultipleResponse++;
  if (buildCounterAchievementUpdateMultipleResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3444(o.updatedAchievements!);
  }
  buildCounterAchievementUpdateMultipleResponse--;
}

core.int buildCounterAchievementUpdateRequest = 0;
api.AchievementUpdateRequest buildAchievementUpdateRequest() {
  var o = api.AchievementUpdateRequest();
  buildCounterAchievementUpdateRequest++;
  if (buildCounterAchievementUpdateRequest < 3) {
    o.achievementId = 'foo';
    o.incrementPayload = buildGamesAchievementIncrement();
    o.kind = 'foo';
    o.setStepsAtLeastPayload = buildGamesAchievementSetStepsAtLeast();
    o.updateType = 'foo';
  }
  buildCounterAchievementUpdateRequest--;
  return o;
}

void checkAchievementUpdateRequest(api.AchievementUpdateRequest o) {
  buildCounterAchievementUpdateRequest++;
  if (buildCounterAchievementUpdateRequest < 3) {
    unittest.expect(
      o.achievementId!,
      unittest.equals('foo'),
    );
    checkGamesAchievementIncrement(
        o.incrementPayload! as api.GamesAchievementIncrement);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkGamesAchievementSetStepsAtLeast(
        o.setStepsAtLeastPayload! as api.GamesAchievementSetStepsAtLeast);
    unittest.expect(
      o.updateType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAchievementUpdateRequest--;
}

core.int buildCounterAchievementUpdateResponse = 0;
api.AchievementUpdateResponse buildAchievementUpdateResponse() {
  var o = api.AchievementUpdateResponse();
  buildCounterAchievementUpdateResponse++;
  if (buildCounterAchievementUpdateResponse < 3) {
    o.achievementId = 'foo';
    o.currentState = 'foo';
    o.currentSteps = 42;
    o.kind = 'foo';
    o.newlyUnlocked = true;
    o.updateOccurred = true;
  }
  buildCounterAchievementUpdateResponse--;
  return o;
}

void checkAchievementUpdateResponse(api.AchievementUpdateResponse o) {
  buildCounterAchievementUpdateResponse++;
  if (buildCounterAchievementUpdateResponse < 3) {
    unittest.expect(
      o.achievementId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currentState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currentSteps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.newlyUnlocked!, unittest.isTrue);
    unittest.expect(o.updateOccurred!, unittest.isTrue);
  }
  buildCounterAchievementUpdateResponse--;
}

core.List<api.ImageAsset> buildUnnamed3445() {
  var o = <api.ImageAsset>[];
  o.add(buildImageAsset());
  o.add(buildImageAsset());
  return o;
}

void checkUnnamed3445(core.List<api.ImageAsset> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkImageAsset(o[0] as api.ImageAsset);
  checkImageAsset(o[1] as api.ImageAsset);
}

core.List<core.String> buildUnnamed3446() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3446(core.List<core.String> o) {
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

core.List<api.Instance> buildUnnamed3447() {
  var o = <api.Instance>[];
  o.add(buildInstance());
  o.add(buildInstance());
  return o;
}

void checkUnnamed3447(core.List<api.Instance> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInstance(o[0] as api.Instance);
  checkInstance(o[1] as api.Instance);
}

core.int buildCounterApplication = 0;
api.Application buildApplication() {
  var o = api.Application();
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    o.achievementCount = 42;
    o.assets = buildUnnamed3445();
    o.author = 'foo';
    o.category = buildApplicationCategory();
    o.description = 'foo';
    o.enabledFeatures = buildUnnamed3446();
    o.id = 'foo';
    o.instances = buildUnnamed3447();
    o.kind = 'foo';
    o.lastUpdatedTimestamp = 'foo';
    o.leaderboardCount = 42;
    o.name = 'foo';
    o.themeColor = 'foo';
  }
  buildCounterApplication--;
  return o;
}

void checkApplication(api.Application o) {
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    unittest.expect(
      o.achievementCount!,
      unittest.equals(42),
    );
    checkUnnamed3445(o.assets!);
    unittest.expect(
      o.author!,
      unittest.equals('foo'),
    );
    checkApplicationCategory(o.category! as api.ApplicationCategory);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed3446(o.enabledFeatures!);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed3447(o.instances!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastUpdatedTimestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.leaderboardCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.themeColor!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplication--;
}

core.int buildCounterApplicationCategory = 0;
api.ApplicationCategory buildApplicationCategory() {
  var o = api.ApplicationCategory();
  buildCounterApplicationCategory++;
  if (buildCounterApplicationCategory < 3) {
    o.kind = 'foo';
    o.primary = 'foo';
    o.secondary = 'foo';
  }
  buildCounterApplicationCategory--;
  return o;
}

void checkApplicationCategory(api.ApplicationCategory o) {
  buildCounterApplicationCategory++;
  if (buildCounterApplicationCategory < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.primary!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.secondary!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplicationCategory--;
}

core.int buildCounterApplicationVerifyResponse = 0;
api.ApplicationVerifyResponse buildApplicationVerifyResponse() {
  var o = api.ApplicationVerifyResponse();
  buildCounterApplicationVerifyResponse++;
  if (buildCounterApplicationVerifyResponse < 3) {
    o.alternatePlayerId = 'foo';
    o.kind = 'foo';
    o.playerId = 'foo';
  }
  buildCounterApplicationVerifyResponse--;
  return o;
}

void checkApplicationVerifyResponse(api.ApplicationVerifyResponse o) {
  buildCounterApplicationVerifyResponse++;
  if (buildCounterApplicationVerifyResponse < 3) {
    unittest.expect(
      o.alternatePlayerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.playerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplicationVerifyResponse--;
}

core.int buildCounterCategory = 0;
api.Category buildCategory() {
  var o = api.Category();
  buildCounterCategory++;
  if (buildCounterCategory < 3) {
    o.category = 'foo';
    o.experiencePoints = 'foo';
    o.kind = 'foo';
  }
  buildCounterCategory--;
  return o;
}

void checkCategory(api.Category o) {
  buildCounterCategory++;
  if (buildCounterCategory < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.experiencePoints!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategory--;
}

core.List<api.Category> buildUnnamed3448() {
  var o = <api.Category>[];
  o.add(buildCategory());
  o.add(buildCategory());
  return o;
}

void checkUnnamed3448(core.List<api.Category> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCategory(o[0] as api.Category);
  checkCategory(o[1] as api.Category);
}

core.int buildCounterCategoryListResponse = 0;
api.CategoryListResponse buildCategoryListResponse() {
  var o = api.CategoryListResponse();
  buildCounterCategoryListResponse++;
  if (buildCounterCategoryListResponse < 3) {
    o.items = buildUnnamed3448();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterCategoryListResponse--;
  return o;
}

void checkCategoryListResponse(api.CategoryListResponse o) {
  buildCounterCategoryListResponse++;
  if (buildCounterCategoryListResponse < 3) {
    checkUnnamed3448(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategoryListResponse--;
}

core.int buildCounterEndPoint = 0;
api.EndPoint buildEndPoint() {
  var o = api.EndPoint();
  buildCounterEndPoint++;
  if (buildCounterEndPoint < 3) {
    o.url = 'foo';
  }
  buildCounterEndPoint--;
  return o;
}

void checkEndPoint(api.EndPoint o) {
  buildCounterEndPoint++;
  if (buildCounterEndPoint < 3) {
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterEndPoint--;
}

core.int buildCounterEventBatchRecordFailure = 0;
api.EventBatchRecordFailure buildEventBatchRecordFailure() {
  var o = api.EventBatchRecordFailure();
  buildCounterEventBatchRecordFailure++;
  if (buildCounterEventBatchRecordFailure < 3) {
    o.failureCause = 'foo';
    o.kind = 'foo';
    o.range = buildEventPeriodRange();
  }
  buildCounterEventBatchRecordFailure--;
  return o;
}

void checkEventBatchRecordFailure(api.EventBatchRecordFailure o) {
  buildCounterEventBatchRecordFailure++;
  if (buildCounterEventBatchRecordFailure < 3) {
    unittest.expect(
      o.failureCause!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkEventPeriodRange(o.range! as api.EventPeriodRange);
  }
  buildCounterEventBatchRecordFailure--;
}

core.int buildCounterEventChild = 0;
api.EventChild buildEventChild() {
  var o = api.EventChild();
  buildCounterEventChild++;
  if (buildCounterEventChild < 3) {
    o.childId = 'foo';
    o.kind = 'foo';
  }
  buildCounterEventChild--;
  return o;
}

void checkEventChild(api.EventChild o) {
  buildCounterEventChild++;
  if (buildCounterEventChild < 3) {
    unittest.expect(
      o.childId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventChild--;
}

core.List<api.EventChild> buildUnnamed3449() {
  var o = <api.EventChild>[];
  o.add(buildEventChild());
  o.add(buildEventChild());
  return o;
}

void checkUnnamed3449(core.List<api.EventChild> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventChild(o[0] as api.EventChild);
  checkEventChild(o[1] as api.EventChild);
}

core.int buildCounterEventDefinition = 0;
api.EventDefinition buildEventDefinition() {
  var o = api.EventDefinition();
  buildCounterEventDefinition++;
  if (buildCounterEventDefinition < 3) {
    o.childEvents = buildUnnamed3449();
    o.description = 'foo';
    o.displayName = 'foo';
    o.id = 'foo';
    o.imageUrl = 'foo';
    o.isDefaultImageUrl = true;
    o.kind = 'foo';
    o.visibility = 'foo';
  }
  buildCounterEventDefinition--;
  return o;
}

void checkEventDefinition(api.EventDefinition o) {
  buildCounterEventDefinition++;
  if (buildCounterEventDefinition < 3) {
    checkUnnamed3449(o.childEvents!);
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
      o.imageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDefaultImageUrl!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.visibility!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventDefinition--;
}

core.List<api.EventDefinition> buildUnnamed3450() {
  var o = <api.EventDefinition>[];
  o.add(buildEventDefinition());
  o.add(buildEventDefinition());
  return o;
}

void checkUnnamed3450(core.List<api.EventDefinition> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventDefinition(o[0] as api.EventDefinition);
  checkEventDefinition(o[1] as api.EventDefinition);
}

core.int buildCounterEventDefinitionListResponse = 0;
api.EventDefinitionListResponse buildEventDefinitionListResponse() {
  var o = api.EventDefinitionListResponse();
  buildCounterEventDefinitionListResponse++;
  if (buildCounterEventDefinitionListResponse < 3) {
    o.items = buildUnnamed3450();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterEventDefinitionListResponse--;
  return o;
}

void checkEventDefinitionListResponse(api.EventDefinitionListResponse o) {
  buildCounterEventDefinitionListResponse++;
  if (buildCounterEventDefinitionListResponse < 3) {
    checkUnnamed3450(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventDefinitionListResponse--;
}

core.int buildCounterEventPeriodRange = 0;
api.EventPeriodRange buildEventPeriodRange() {
  var o = api.EventPeriodRange();
  buildCounterEventPeriodRange++;
  if (buildCounterEventPeriodRange < 3) {
    o.kind = 'foo';
    o.periodEndMillis = 'foo';
    o.periodStartMillis = 'foo';
  }
  buildCounterEventPeriodRange--;
  return o;
}

void checkEventPeriodRange(api.EventPeriodRange o) {
  buildCounterEventPeriodRange++;
  if (buildCounterEventPeriodRange < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.periodEndMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.periodStartMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventPeriodRange--;
}

core.List<api.EventUpdateRequest> buildUnnamed3451() {
  var o = <api.EventUpdateRequest>[];
  o.add(buildEventUpdateRequest());
  o.add(buildEventUpdateRequest());
  return o;
}

void checkUnnamed3451(core.List<api.EventUpdateRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventUpdateRequest(o[0] as api.EventUpdateRequest);
  checkEventUpdateRequest(o[1] as api.EventUpdateRequest);
}

core.int buildCounterEventPeriodUpdate = 0;
api.EventPeriodUpdate buildEventPeriodUpdate() {
  var o = api.EventPeriodUpdate();
  buildCounterEventPeriodUpdate++;
  if (buildCounterEventPeriodUpdate < 3) {
    o.kind = 'foo';
    o.timePeriod = buildEventPeriodRange();
    o.updates = buildUnnamed3451();
  }
  buildCounterEventPeriodUpdate--;
  return o;
}

void checkEventPeriodUpdate(api.EventPeriodUpdate o) {
  buildCounterEventPeriodUpdate++;
  if (buildCounterEventPeriodUpdate < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkEventPeriodRange(o.timePeriod! as api.EventPeriodRange);
    checkUnnamed3451(o.updates!);
  }
  buildCounterEventPeriodUpdate--;
}

core.int buildCounterEventRecordFailure = 0;
api.EventRecordFailure buildEventRecordFailure() {
  var o = api.EventRecordFailure();
  buildCounterEventRecordFailure++;
  if (buildCounterEventRecordFailure < 3) {
    o.eventId = 'foo';
    o.failureCause = 'foo';
    o.kind = 'foo';
  }
  buildCounterEventRecordFailure--;
  return o;
}

void checkEventRecordFailure(api.EventRecordFailure o) {
  buildCounterEventRecordFailure++;
  if (buildCounterEventRecordFailure < 3) {
    unittest.expect(
      o.eventId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.failureCause!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventRecordFailure--;
}

core.List<api.EventPeriodUpdate> buildUnnamed3452() {
  var o = <api.EventPeriodUpdate>[];
  o.add(buildEventPeriodUpdate());
  o.add(buildEventPeriodUpdate());
  return o;
}

void checkUnnamed3452(core.List<api.EventPeriodUpdate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventPeriodUpdate(o[0] as api.EventPeriodUpdate);
  checkEventPeriodUpdate(o[1] as api.EventPeriodUpdate);
}

core.int buildCounterEventRecordRequest = 0;
api.EventRecordRequest buildEventRecordRequest() {
  var o = api.EventRecordRequest();
  buildCounterEventRecordRequest++;
  if (buildCounterEventRecordRequest < 3) {
    o.currentTimeMillis = 'foo';
    o.kind = 'foo';
    o.requestId = 'foo';
    o.timePeriods = buildUnnamed3452();
  }
  buildCounterEventRecordRequest--;
  return o;
}

void checkEventRecordRequest(api.EventRecordRequest o) {
  buildCounterEventRecordRequest++;
  if (buildCounterEventRecordRequest < 3) {
    unittest.expect(
      o.currentTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
    checkUnnamed3452(o.timePeriods!);
  }
  buildCounterEventRecordRequest--;
}

core.int buildCounterEventUpdateRequest = 0;
api.EventUpdateRequest buildEventUpdateRequest() {
  var o = api.EventUpdateRequest();
  buildCounterEventUpdateRequest++;
  if (buildCounterEventUpdateRequest < 3) {
    o.definitionId = 'foo';
    o.kind = 'foo';
    o.updateCount = 'foo';
  }
  buildCounterEventUpdateRequest--;
  return o;
}

void checkEventUpdateRequest(api.EventUpdateRequest o) {
  buildCounterEventUpdateRequest++;
  if (buildCounterEventUpdateRequest < 3) {
    unittest.expect(
      o.definitionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterEventUpdateRequest--;
}

core.List<api.EventBatchRecordFailure> buildUnnamed3453() {
  var o = <api.EventBatchRecordFailure>[];
  o.add(buildEventBatchRecordFailure());
  o.add(buildEventBatchRecordFailure());
  return o;
}

void checkUnnamed3453(core.List<api.EventBatchRecordFailure> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventBatchRecordFailure(o[0] as api.EventBatchRecordFailure);
  checkEventBatchRecordFailure(o[1] as api.EventBatchRecordFailure);
}

core.List<api.EventRecordFailure> buildUnnamed3454() {
  var o = <api.EventRecordFailure>[];
  o.add(buildEventRecordFailure());
  o.add(buildEventRecordFailure());
  return o;
}

void checkUnnamed3454(core.List<api.EventRecordFailure> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEventRecordFailure(o[0] as api.EventRecordFailure);
  checkEventRecordFailure(o[1] as api.EventRecordFailure);
}

core.List<api.PlayerEvent> buildUnnamed3455() {
  var o = <api.PlayerEvent>[];
  o.add(buildPlayerEvent());
  o.add(buildPlayerEvent());
  return o;
}

void checkUnnamed3455(core.List<api.PlayerEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerEvent(o[0] as api.PlayerEvent);
  checkPlayerEvent(o[1] as api.PlayerEvent);
}

core.int buildCounterEventUpdateResponse = 0;
api.EventUpdateResponse buildEventUpdateResponse() {
  var o = api.EventUpdateResponse();
  buildCounterEventUpdateResponse++;
  if (buildCounterEventUpdateResponse < 3) {
    o.batchFailures = buildUnnamed3453();
    o.eventFailures = buildUnnamed3454();
    o.kind = 'foo';
    o.playerEvents = buildUnnamed3455();
  }
  buildCounterEventUpdateResponse--;
  return o;
}

void checkEventUpdateResponse(api.EventUpdateResponse o) {
  buildCounterEventUpdateResponse++;
  if (buildCounterEventUpdateResponse < 3) {
    checkUnnamed3453(o.batchFailures!);
    checkUnnamed3454(o.eventFailures!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3455(o.playerEvents!);
  }
  buildCounterEventUpdateResponse--;
}

core.int buildCounterGamesAchievementIncrement = 0;
api.GamesAchievementIncrement buildGamesAchievementIncrement() {
  var o = api.GamesAchievementIncrement();
  buildCounterGamesAchievementIncrement++;
  if (buildCounterGamesAchievementIncrement < 3) {
    o.kind = 'foo';
    o.requestId = 'foo';
    o.steps = 42;
  }
  buildCounterGamesAchievementIncrement--;
  return o;
}

void checkGamesAchievementIncrement(api.GamesAchievementIncrement o) {
  buildCounterGamesAchievementIncrement++;
  if (buildCounterGamesAchievementIncrement < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.steps!,
      unittest.equals(42),
    );
  }
  buildCounterGamesAchievementIncrement--;
}

core.int buildCounterGamesAchievementSetStepsAtLeast = 0;
api.GamesAchievementSetStepsAtLeast buildGamesAchievementSetStepsAtLeast() {
  var o = api.GamesAchievementSetStepsAtLeast();
  buildCounterGamesAchievementSetStepsAtLeast++;
  if (buildCounterGamesAchievementSetStepsAtLeast < 3) {
    o.kind = 'foo';
    o.steps = 42;
  }
  buildCounterGamesAchievementSetStepsAtLeast--;
  return o;
}

void checkGamesAchievementSetStepsAtLeast(
    api.GamesAchievementSetStepsAtLeast o) {
  buildCounterGamesAchievementSetStepsAtLeast++;
  if (buildCounterGamesAchievementSetStepsAtLeast < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.steps!,
      unittest.equals(42),
    );
  }
  buildCounterGamesAchievementSetStepsAtLeast--;
}

core.int buildCounterImageAsset = 0;
api.ImageAsset buildImageAsset() {
  var o = api.ImageAsset();
  buildCounterImageAsset++;
  if (buildCounterImageAsset < 3) {
    o.height = 42;
    o.kind = 'foo';
    o.name = 'foo';
    o.url = 'foo';
    o.width = 42;
  }
  buildCounterImageAsset--;
  return o;
}

void checkImageAsset(api.ImageAsset o) {
  buildCounterImageAsset++;
  if (buildCounterImageAsset < 3) {
    unittest.expect(
      o.height!,
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
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterImageAsset--;
}

core.int buildCounterInstance = 0;
api.Instance buildInstance() {
  var o = api.Instance();
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    o.acquisitionUri = 'foo';
    o.androidInstance = buildInstanceAndroidDetails();
    o.iosInstance = buildInstanceIosDetails();
    o.kind = 'foo';
    o.name = 'foo';
    o.platformType = 'foo';
    o.realtimePlay = true;
    o.turnBasedPlay = true;
    o.webInstance = buildInstanceWebDetails();
  }
  buildCounterInstance--;
  return o;
}

void checkInstance(api.Instance o) {
  buildCounterInstance++;
  if (buildCounterInstance < 3) {
    unittest.expect(
      o.acquisitionUri!,
      unittest.equals('foo'),
    );
    checkInstanceAndroidDetails(
        o.androidInstance! as api.InstanceAndroidDetails);
    checkInstanceIosDetails(o.iosInstance! as api.InstanceIosDetails);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platformType!,
      unittest.equals('foo'),
    );
    unittest.expect(o.realtimePlay!, unittest.isTrue);
    unittest.expect(o.turnBasedPlay!, unittest.isTrue);
    checkInstanceWebDetails(o.webInstance! as api.InstanceWebDetails);
  }
  buildCounterInstance--;
}

core.int buildCounterInstanceAndroidDetails = 0;
api.InstanceAndroidDetails buildInstanceAndroidDetails() {
  var o = api.InstanceAndroidDetails();
  buildCounterInstanceAndroidDetails++;
  if (buildCounterInstanceAndroidDetails < 3) {
    o.enablePiracyCheck = true;
    o.kind = 'foo';
    o.packageName = 'foo';
    o.preferred = true;
  }
  buildCounterInstanceAndroidDetails--;
  return o;
}

void checkInstanceAndroidDetails(api.InstanceAndroidDetails o) {
  buildCounterInstanceAndroidDetails++;
  if (buildCounterInstanceAndroidDetails < 3) {
    unittest.expect(o.enablePiracyCheck!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.preferred!, unittest.isTrue);
  }
  buildCounterInstanceAndroidDetails--;
}

core.int buildCounterInstanceIosDetails = 0;
api.InstanceIosDetails buildInstanceIosDetails() {
  var o = api.InstanceIosDetails();
  buildCounterInstanceIosDetails++;
  if (buildCounterInstanceIosDetails < 3) {
    o.bundleIdentifier = 'foo';
    o.itunesAppId = 'foo';
    o.kind = 'foo';
    o.preferredForIpad = true;
    o.preferredForIphone = true;
    o.supportIpad = true;
    o.supportIphone = true;
  }
  buildCounterInstanceIosDetails--;
  return o;
}

void checkInstanceIosDetails(api.InstanceIosDetails o) {
  buildCounterInstanceIosDetails++;
  if (buildCounterInstanceIosDetails < 3) {
    unittest.expect(
      o.bundleIdentifier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.itunesAppId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.preferredForIpad!, unittest.isTrue);
    unittest.expect(o.preferredForIphone!, unittest.isTrue);
    unittest.expect(o.supportIpad!, unittest.isTrue);
    unittest.expect(o.supportIphone!, unittest.isTrue);
  }
  buildCounterInstanceIosDetails--;
}

core.int buildCounterInstanceWebDetails = 0;
api.InstanceWebDetails buildInstanceWebDetails() {
  var o = api.InstanceWebDetails();
  buildCounterInstanceWebDetails++;
  if (buildCounterInstanceWebDetails < 3) {
    o.kind = 'foo';
    o.launchUrl = 'foo';
    o.preferred = true;
  }
  buildCounterInstanceWebDetails--;
  return o;
}

void checkInstanceWebDetails(api.InstanceWebDetails o) {
  buildCounterInstanceWebDetails++;
  if (buildCounterInstanceWebDetails < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.launchUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.preferred!, unittest.isTrue);
  }
  buildCounterInstanceWebDetails--;
}

core.int buildCounterLeaderboard = 0;
api.Leaderboard buildLeaderboard() {
  var o = api.Leaderboard();
  buildCounterLeaderboard++;
  if (buildCounterLeaderboard < 3) {
    o.iconUrl = 'foo';
    o.id = 'foo';
    o.isIconUrlDefault = true;
    o.kind = 'foo';
    o.name = 'foo';
    o.order = 'foo';
  }
  buildCounterLeaderboard--;
  return o;
}

void checkLeaderboard(api.Leaderboard o) {
  buildCounterLeaderboard++;
  if (buildCounterLeaderboard < 3) {
    unittest.expect(
      o.iconUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isIconUrlDefault!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.order!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboard--;
}

core.int buildCounterLeaderboardEntry = 0;
api.LeaderboardEntry buildLeaderboardEntry() {
  var o = api.LeaderboardEntry();
  buildCounterLeaderboardEntry++;
  if (buildCounterLeaderboardEntry < 3) {
    o.formattedScore = 'foo';
    o.formattedScoreRank = 'foo';
    o.kind = 'foo';
    o.player = buildPlayer();
    o.scoreRank = 'foo';
    o.scoreTag = 'foo';
    o.scoreValue = 'foo';
    o.timeSpan = 'foo';
    o.writeTimestampMillis = 'foo';
  }
  buildCounterLeaderboardEntry--;
  return o;
}

void checkLeaderboardEntry(api.LeaderboardEntry o) {
  buildCounterLeaderboardEntry++;
  if (buildCounterLeaderboardEntry < 3) {
    unittest.expect(
      o.formattedScore!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedScoreRank!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkPlayer(o.player! as api.Player);
    unittest.expect(
      o.scoreRank!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreValue!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeSpan!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.writeTimestampMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboardEntry--;
}

core.List<api.Leaderboard> buildUnnamed3456() {
  var o = <api.Leaderboard>[];
  o.add(buildLeaderboard());
  o.add(buildLeaderboard());
  return o;
}

void checkUnnamed3456(core.List<api.Leaderboard> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLeaderboard(o[0] as api.Leaderboard);
  checkLeaderboard(o[1] as api.Leaderboard);
}

core.int buildCounterLeaderboardListResponse = 0;
api.LeaderboardListResponse buildLeaderboardListResponse() {
  var o = api.LeaderboardListResponse();
  buildCounterLeaderboardListResponse++;
  if (buildCounterLeaderboardListResponse < 3) {
    o.items = buildUnnamed3456();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterLeaderboardListResponse--;
  return o;
}

void checkLeaderboardListResponse(api.LeaderboardListResponse o) {
  buildCounterLeaderboardListResponse++;
  if (buildCounterLeaderboardListResponse < 3) {
    checkUnnamed3456(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboardListResponse--;
}

core.int buildCounterLeaderboardScoreRank = 0;
api.LeaderboardScoreRank buildLeaderboardScoreRank() {
  var o = api.LeaderboardScoreRank();
  buildCounterLeaderboardScoreRank++;
  if (buildCounterLeaderboardScoreRank < 3) {
    o.formattedNumScores = 'foo';
    o.formattedRank = 'foo';
    o.kind = 'foo';
    o.numScores = 'foo';
    o.rank = 'foo';
  }
  buildCounterLeaderboardScoreRank--;
  return o;
}

void checkLeaderboardScoreRank(api.LeaderboardScoreRank o) {
  buildCounterLeaderboardScoreRank++;
  if (buildCounterLeaderboardScoreRank < 3) {
    unittest.expect(
      o.formattedNumScores!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedRank!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numScores!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rank!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboardScoreRank--;
}

core.List<api.LeaderboardEntry> buildUnnamed3457() {
  var o = <api.LeaderboardEntry>[];
  o.add(buildLeaderboardEntry());
  o.add(buildLeaderboardEntry());
  return o;
}

void checkUnnamed3457(core.List<api.LeaderboardEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLeaderboardEntry(o[0] as api.LeaderboardEntry);
  checkLeaderboardEntry(o[1] as api.LeaderboardEntry);
}

core.int buildCounterLeaderboardScores = 0;
api.LeaderboardScores buildLeaderboardScores() {
  var o = api.LeaderboardScores();
  buildCounterLeaderboardScores++;
  if (buildCounterLeaderboardScores < 3) {
    o.items = buildUnnamed3457();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.numScores = 'foo';
    o.playerScore = buildLeaderboardEntry();
    o.prevPageToken = 'foo';
  }
  buildCounterLeaderboardScores--;
  return o;
}

void checkLeaderboardScores(api.LeaderboardScores o) {
  buildCounterLeaderboardScores++;
  if (buildCounterLeaderboardScores < 3) {
    checkUnnamed3457(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numScores!,
      unittest.equals('foo'),
    );
    checkLeaderboardEntry(o.playerScore! as api.LeaderboardEntry);
    unittest.expect(
      o.prevPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboardScores--;
}

core.List<api.PlayerLevel> buildUnnamed3458() {
  var o = <api.PlayerLevel>[];
  o.add(buildPlayerLevel());
  o.add(buildPlayerLevel());
  return o;
}

void checkUnnamed3458(core.List<api.PlayerLevel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerLevel(o[0] as api.PlayerLevel);
  checkPlayerLevel(o[1] as api.PlayerLevel);
}

core.int buildCounterMetagameConfig = 0;
api.MetagameConfig buildMetagameConfig() {
  var o = api.MetagameConfig();
  buildCounterMetagameConfig++;
  if (buildCounterMetagameConfig < 3) {
    o.currentVersion = 42;
    o.kind = 'foo';
    o.playerLevels = buildUnnamed3458();
  }
  buildCounterMetagameConfig--;
  return o;
}

void checkMetagameConfig(api.MetagameConfig o) {
  buildCounterMetagameConfig++;
  if (buildCounterMetagameConfig < 3) {
    unittest.expect(
      o.currentVersion!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3458(o.playerLevels!);
  }
  buildCounterMetagameConfig--;
}

core.int buildCounterPlayerName = 0;
api.PlayerName buildPlayerName() {
  var o = api.PlayerName();
  buildCounterPlayerName++;
  if (buildCounterPlayerName < 3) {
    o.familyName = 'foo';
    o.givenName = 'foo';
  }
  buildCounterPlayerName--;
  return o;
}

void checkPlayerName(api.PlayerName o) {
  buildCounterPlayerName++;
  if (buildCounterPlayerName < 3) {
    unittest.expect(
      o.familyName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.givenName!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerName--;
}

core.int buildCounterPlayer = 0;
api.Player buildPlayer() {
  var o = api.Player();
  buildCounterPlayer++;
  if (buildCounterPlayer < 3) {
    o.avatarImageUrl = 'foo';
    o.bannerUrlLandscape = 'foo';
    o.bannerUrlPortrait = 'foo';
    o.displayName = 'foo';
    o.experienceInfo = buildPlayerExperienceInfo();
    o.friendStatus = 'foo';
    o.kind = 'foo';
    o.name = buildPlayerName();
    o.originalPlayerId = 'foo';
    o.playerId = 'foo';
    o.profileSettings = buildProfileSettings();
    o.title = 'foo';
  }
  buildCounterPlayer--;
  return o;
}

void checkPlayer(api.Player o) {
  buildCounterPlayer++;
  if (buildCounterPlayer < 3) {
    unittest.expect(
      o.avatarImageUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerUrlLandscape!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bannerUrlPortrait!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkPlayerExperienceInfo(o.experienceInfo! as api.PlayerExperienceInfo);
    unittest.expect(
      o.friendStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkPlayerName(o.name! as api.PlayerName);
    unittest.expect(
      o.originalPlayerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.playerId!,
      unittest.equals('foo'),
    );
    checkProfileSettings(o.profileSettings! as api.ProfileSettings);
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayer--;
}

core.int buildCounterPlayerAchievement = 0;
api.PlayerAchievement buildPlayerAchievement() {
  var o = api.PlayerAchievement();
  buildCounterPlayerAchievement++;
  if (buildCounterPlayerAchievement < 3) {
    o.achievementState = 'foo';
    o.currentSteps = 42;
    o.experiencePoints = 'foo';
    o.formattedCurrentStepsString = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.lastUpdatedTimestamp = 'foo';
  }
  buildCounterPlayerAchievement--;
  return o;
}

void checkPlayerAchievement(api.PlayerAchievement o) {
  buildCounterPlayerAchievement++;
  if (buildCounterPlayerAchievement < 3) {
    unittest.expect(
      o.achievementState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currentSteps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.experiencePoints!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedCurrentStepsString!,
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
      o.lastUpdatedTimestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerAchievement--;
}

core.List<api.PlayerAchievement> buildUnnamed3459() {
  var o = <api.PlayerAchievement>[];
  o.add(buildPlayerAchievement());
  o.add(buildPlayerAchievement());
  return o;
}

void checkUnnamed3459(core.List<api.PlayerAchievement> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerAchievement(o[0] as api.PlayerAchievement);
  checkPlayerAchievement(o[1] as api.PlayerAchievement);
}

core.int buildCounterPlayerAchievementListResponse = 0;
api.PlayerAchievementListResponse buildPlayerAchievementListResponse() {
  var o = api.PlayerAchievementListResponse();
  buildCounterPlayerAchievementListResponse++;
  if (buildCounterPlayerAchievementListResponse < 3) {
    o.items = buildUnnamed3459();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterPlayerAchievementListResponse--;
  return o;
}

void checkPlayerAchievementListResponse(api.PlayerAchievementListResponse o) {
  buildCounterPlayerAchievementListResponse++;
  if (buildCounterPlayerAchievementListResponse < 3) {
    checkUnnamed3459(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerAchievementListResponse--;
}

core.int buildCounterPlayerEvent = 0;
api.PlayerEvent buildPlayerEvent() {
  var o = api.PlayerEvent();
  buildCounterPlayerEvent++;
  if (buildCounterPlayerEvent < 3) {
    o.definitionId = 'foo';
    o.formattedNumEvents = 'foo';
    o.kind = 'foo';
    o.numEvents = 'foo';
    o.playerId = 'foo';
  }
  buildCounterPlayerEvent--;
  return o;
}

void checkPlayerEvent(api.PlayerEvent o) {
  buildCounterPlayerEvent++;
  if (buildCounterPlayerEvent < 3) {
    unittest.expect(
      o.definitionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formattedNumEvents!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numEvents!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.playerId!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerEvent--;
}

core.List<api.PlayerEvent> buildUnnamed3460() {
  var o = <api.PlayerEvent>[];
  o.add(buildPlayerEvent());
  o.add(buildPlayerEvent());
  return o;
}

void checkUnnamed3460(core.List<api.PlayerEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerEvent(o[0] as api.PlayerEvent);
  checkPlayerEvent(o[1] as api.PlayerEvent);
}

core.int buildCounterPlayerEventListResponse = 0;
api.PlayerEventListResponse buildPlayerEventListResponse() {
  var o = api.PlayerEventListResponse();
  buildCounterPlayerEventListResponse++;
  if (buildCounterPlayerEventListResponse < 3) {
    o.items = buildUnnamed3460();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterPlayerEventListResponse--;
  return o;
}

void checkPlayerEventListResponse(api.PlayerEventListResponse o) {
  buildCounterPlayerEventListResponse++;
  if (buildCounterPlayerEventListResponse < 3) {
    checkUnnamed3460(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerEventListResponse--;
}

core.int buildCounterPlayerExperienceInfo = 0;
api.PlayerExperienceInfo buildPlayerExperienceInfo() {
  var o = api.PlayerExperienceInfo();
  buildCounterPlayerExperienceInfo++;
  if (buildCounterPlayerExperienceInfo < 3) {
    o.currentExperiencePoints = 'foo';
    o.currentLevel = buildPlayerLevel();
    o.kind = 'foo';
    o.lastLevelUpTimestampMillis = 'foo';
    o.nextLevel = buildPlayerLevel();
  }
  buildCounterPlayerExperienceInfo--;
  return o;
}

void checkPlayerExperienceInfo(api.PlayerExperienceInfo o) {
  buildCounterPlayerExperienceInfo++;
  if (buildCounterPlayerExperienceInfo < 3) {
    unittest.expect(
      o.currentExperiencePoints!,
      unittest.equals('foo'),
    );
    checkPlayerLevel(o.currentLevel! as api.PlayerLevel);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastLevelUpTimestampMillis!,
      unittest.equals('foo'),
    );
    checkPlayerLevel(o.nextLevel! as api.PlayerLevel);
  }
  buildCounterPlayerExperienceInfo--;
}

core.int buildCounterPlayerLeaderboardScore = 0;
api.PlayerLeaderboardScore buildPlayerLeaderboardScore() {
  var o = api.PlayerLeaderboardScore();
  buildCounterPlayerLeaderboardScore++;
  if (buildCounterPlayerLeaderboardScore < 3) {
    o.friendsRank = buildLeaderboardScoreRank();
    o.kind = 'foo';
    o.leaderboardId = 'foo';
    o.publicRank = buildLeaderboardScoreRank();
    o.scoreString = 'foo';
    o.scoreTag = 'foo';
    o.scoreValue = 'foo';
    o.socialRank = buildLeaderboardScoreRank();
    o.timeSpan = 'foo';
    o.writeTimestamp = 'foo';
  }
  buildCounterPlayerLeaderboardScore--;
  return o;
}

void checkPlayerLeaderboardScore(api.PlayerLeaderboardScore o) {
  buildCounterPlayerLeaderboardScore++;
  if (buildCounterPlayerLeaderboardScore < 3) {
    checkLeaderboardScoreRank(o.friendsRank! as api.LeaderboardScoreRank);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.leaderboardId!,
      unittest.equals('foo'),
    );
    checkLeaderboardScoreRank(o.publicRank! as api.LeaderboardScoreRank);
    unittest.expect(
      o.scoreString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreValue!,
      unittest.equals('foo'),
    );
    checkLeaderboardScoreRank(o.socialRank! as api.LeaderboardScoreRank);
    unittest.expect(
      o.timeSpan!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.writeTimestamp!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerLeaderboardScore--;
}

core.List<api.PlayerLeaderboardScore> buildUnnamed3461() {
  var o = <api.PlayerLeaderboardScore>[];
  o.add(buildPlayerLeaderboardScore());
  o.add(buildPlayerLeaderboardScore());
  return o;
}

void checkUnnamed3461(core.List<api.PlayerLeaderboardScore> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerLeaderboardScore(o[0] as api.PlayerLeaderboardScore);
  checkPlayerLeaderboardScore(o[1] as api.PlayerLeaderboardScore);
}

core.int buildCounterPlayerLeaderboardScoreListResponse = 0;
api.PlayerLeaderboardScoreListResponse
    buildPlayerLeaderboardScoreListResponse() {
  var o = api.PlayerLeaderboardScoreListResponse();
  buildCounterPlayerLeaderboardScoreListResponse++;
  if (buildCounterPlayerLeaderboardScoreListResponse < 3) {
    o.items = buildUnnamed3461();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.player = buildPlayer();
  }
  buildCounterPlayerLeaderboardScoreListResponse--;
  return o;
}

void checkPlayerLeaderboardScoreListResponse(
    api.PlayerLeaderboardScoreListResponse o) {
  buildCounterPlayerLeaderboardScoreListResponse++;
  if (buildCounterPlayerLeaderboardScoreListResponse < 3) {
    checkUnnamed3461(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkPlayer(o.player! as api.Player);
  }
  buildCounterPlayerLeaderboardScoreListResponse--;
}

core.int buildCounterPlayerLevel = 0;
api.PlayerLevel buildPlayerLevel() {
  var o = api.PlayerLevel();
  buildCounterPlayerLevel++;
  if (buildCounterPlayerLevel < 3) {
    o.kind = 'foo';
    o.level = 42;
    o.maxExperiencePoints = 'foo';
    o.minExperiencePoints = 'foo';
  }
  buildCounterPlayerLevel--;
  return o;
}

void checkPlayerLevel(api.PlayerLevel o) {
  buildCounterPlayerLevel++;
  if (buildCounterPlayerLevel < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.level!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxExperiencePoints!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minExperiencePoints!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerLevel--;
}

core.List<api.Player> buildUnnamed3462() {
  var o = <api.Player>[];
  o.add(buildPlayer());
  o.add(buildPlayer());
  return o;
}

void checkUnnamed3462(core.List<api.Player> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayer(o[0] as api.Player);
  checkPlayer(o[1] as api.Player);
}

core.int buildCounterPlayerListResponse = 0;
api.PlayerListResponse buildPlayerListResponse() {
  var o = api.PlayerListResponse();
  buildCounterPlayerListResponse++;
  if (buildCounterPlayerListResponse < 3) {
    o.items = buildUnnamed3462();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterPlayerListResponse--;
  return o;
}

void checkPlayerListResponse(api.PlayerListResponse o) {
  buildCounterPlayerListResponse++;
  if (buildCounterPlayerListResponse < 3) {
    checkUnnamed3462(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerListResponse--;
}

core.int buildCounterPlayerScore = 0;
api.PlayerScore buildPlayerScore() {
  var o = api.PlayerScore();
  buildCounterPlayerScore++;
  if (buildCounterPlayerScore < 3) {
    o.formattedScore = 'foo';
    o.kind = 'foo';
    o.score = 'foo';
    o.scoreTag = 'foo';
    o.timeSpan = 'foo';
  }
  buildCounterPlayerScore--;
  return o;
}

void checkPlayerScore(api.PlayerScore o) {
  buildCounterPlayerScore++;
  if (buildCounterPlayerScore < 3) {
    unittest.expect(
      o.formattedScore!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.score!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeSpan!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlayerScore--;
}

core.List<api.PlayerScoreResponse> buildUnnamed3463() {
  var o = <api.PlayerScoreResponse>[];
  o.add(buildPlayerScoreResponse());
  o.add(buildPlayerScoreResponse());
  return o;
}

void checkUnnamed3463(core.List<api.PlayerScoreResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerScoreResponse(o[0] as api.PlayerScoreResponse);
  checkPlayerScoreResponse(o[1] as api.PlayerScoreResponse);
}

core.int buildCounterPlayerScoreListResponse = 0;
api.PlayerScoreListResponse buildPlayerScoreListResponse() {
  var o = api.PlayerScoreListResponse();
  buildCounterPlayerScoreListResponse++;
  if (buildCounterPlayerScoreListResponse < 3) {
    o.kind = 'foo';
    o.submittedScores = buildUnnamed3463();
  }
  buildCounterPlayerScoreListResponse--;
  return o;
}

void checkPlayerScoreListResponse(api.PlayerScoreListResponse o) {
  buildCounterPlayerScoreListResponse++;
  if (buildCounterPlayerScoreListResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3463(o.submittedScores!);
  }
  buildCounterPlayerScoreListResponse--;
}

core.List<core.String> buildUnnamed3464() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3464(core.List<core.String> o) {
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

core.List<api.PlayerScore> buildUnnamed3465() {
  var o = <api.PlayerScore>[];
  o.add(buildPlayerScore());
  o.add(buildPlayerScore());
  return o;
}

void checkUnnamed3465(core.List<api.PlayerScore> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlayerScore(o[0] as api.PlayerScore);
  checkPlayerScore(o[1] as api.PlayerScore);
}

core.int buildCounterPlayerScoreResponse = 0;
api.PlayerScoreResponse buildPlayerScoreResponse() {
  var o = api.PlayerScoreResponse();
  buildCounterPlayerScoreResponse++;
  if (buildCounterPlayerScoreResponse < 3) {
    o.beatenScoreTimeSpans = buildUnnamed3464();
    o.formattedScore = 'foo';
    o.kind = 'foo';
    o.leaderboardId = 'foo';
    o.scoreTag = 'foo';
    o.unbeatenScores = buildUnnamed3465();
  }
  buildCounterPlayerScoreResponse--;
  return o;
}

void checkPlayerScoreResponse(api.PlayerScoreResponse o) {
  buildCounterPlayerScoreResponse++;
  if (buildCounterPlayerScoreResponse < 3) {
    checkUnnamed3464(o.beatenScoreTimeSpans!);
    unittest.expect(
      o.formattedScore!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.leaderboardId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreTag!,
      unittest.equals('foo'),
    );
    checkUnnamed3465(o.unbeatenScores!);
  }
  buildCounterPlayerScoreResponse--;
}

core.List<api.ScoreSubmission> buildUnnamed3466() {
  var o = <api.ScoreSubmission>[];
  o.add(buildScoreSubmission());
  o.add(buildScoreSubmission());
  return o;
}

void checkUnnamed3466(core.List<api.ScoreSubmission> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScoreSubmission(o[0] as api.ScoreSubmission);
  checkScoreSubmission(o[1] as api.ScoreSubmission);
}

core.int buildCounterPlayerScoreSubmissionList = 0;
api.PlayerScoreSubmissionList buildPlayerScoreSubmissionList() {
  var o = api.PlayerScoreSubmissionList();
  buildCounterPlayerScoreSubmissionList++;
  if (buildCounterPlayerScoreSubmissionList < 3) {
    o.kind = 'foo';
    o.scores = buildUnnamed3466();
  }
  buildCounterPlayerScoreSubmissionList--;
  return o;
}

void checkPlayerScoreSubmissionList(api.PlayerScoreSubmissionList o) {
  buildCounterPlayerScoreSubmissionList++;
  if (buildCounterPlayerScoreSubmissionList < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3466(o.scores!);
  }
  buildCounterPlayerScoreSubmissionList--;
}

core.int buildCounterProfileSettings = 0;
api.ProfileSettings buildProfileSettings() {
  var o = api.ProfileSettings();
  buildCounterProfileSettings++;
  if (buildCounterProfileSettings < 3) {
    o.friendsListVisibility = 'foo';
    o.kind = 'foo';
    o.profileVisible = true;
  }
  buildCounterProfileSettings--;
  return o;
}

void checkProfileSettings(api.ProfileSettings o) {
  buildCounterProfileSettings++;
  if (buildCounterProfileSettings < 3) {
    unittest.expect(
      o.friendsListVisibility!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.profileVisible!, unittest.isTrue);
  }
  buildCounterProfileSettings--;
}

core.int buildCounterRevisionCheckResponse = 0;
api.RevisionCheckResponse buildRevisionCheckResponse() {
  var o = api.RevisionCheckResponse();
  buildCounterRevisionCheckResponse++;
  if (buildCounterRevisionCheckResponse < 3) {
    o.apiVersion = 'foo';
    o.kind = 'foo';
    o.revisionStatus = 'foo';
  }
  buildCounterRevisionCheckResponse--;
  return o;
}

void checkRevisionCheckResponse(api.RevisionCheckResponse o) {
  buildCounterRevisionCheckResponse++;
  if (buildCounterRevisionCheckResponse < 3) {
    unittest.expect(
      o.apiVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterRevisionCheckResponse--;
}

core.int buildCounterScoreSubmission = 0;
api.ScoreSubmission buildScoreSubmission() {
  var o = api.ScoreSubmission();
  buildCounterScoreSubmission++;
  if (buildCounterScoreSubmission < 3) {
    o.kind = 'foo';
    o.leaderboardId = 'foo';
    o.score = 'foo';
    o.scoreTag = 'foo';
    o.signature = 'foo';
  }
  buildCounterScoreSubmission--;
  return o;
}

void checkScoreSubmission(api.ScoreSubmission o) {
  buildCounterScoreSubmission++;
  if (buildCounterScoreSubmission < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.leaderboardId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.score!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreTag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
  }
  buildCounterScoreSubmission--;
}

core.int buildCounterSnapshot = 0;
api.Snapshot buildSnapshot() {
  var o = api.Snapshot();
  buildCounterSnapshot++;
  if (buildCounterSnapshot < 3) {
    o.coverImage = buildSnapshotImage();
    o.description = 'foo';
    o.driveId = 'foo';
    o.durationMillis = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.lastModifiedMillis = 'foo';
    o.progressValue = 'foo';
    o.title = 'foo';
    o.type = 'foo';
    o.uniqueName = 'foo';
  }
  buildCounterSnapshot--;
  return o;
}

void checkSnapshot(api.Snapshot o) {
  buildCounterSnapshot++;
  if (buildCounterSnapshot < 3) {
    checkSnapshotImage(o.coverImage! as api.SnapshotImage);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.driveId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.durationMillis!,
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
      o.lastModifiedMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressValue!,
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
    unittest.expect(
      o.uniqueName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSnapshot--;
}

core.int buildCounterSnapshotImage = 0;
api.SnapshotImage buildSnapshotImage() {
  var o = api.SnapshotImage();
  buildCounterSnapshotImage++;
  if (buildCounterSnapshotImage < 3) {
    o.height = 42;
    o.kind = 'foo';
    o.mimeType = 'foo';
    o.url = 'foo';
    o.width = 42;
  }
  buildCounterSnapshotImage--;
  return o;
}

void checkSnapshotImage(api.SnapshotImage o) {
  buildCounterSnapshotImage++;
  if (buildCounterSnapshotImage < 3) {
    unittest.expect(
      o.height!,
      unittest.equals(42),
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
      o.url!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterSnapshotImage--;
}

core.List<api.Snapshot> buildUnnamed3467() {
  var o = <api.Snapshot>[];
  o.add(buildSnapshot());
  o.add(buildSnapshot());
  return o;
}

void checkUnnamed3467(core.List<api.Snapshot> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSnapshot(o[0] as api.Snapshot);
  checkSnapshot(o[1] as api.Snapshot);
}

core.int buildCounterSnapshotListResponse = 0;
api.SnapshotListResponse buildSnapshotListResponse() {
  var o = api.SnapshotListResponse();
  buildCounterSnapshotListResponse++;
  if (buildCounterSnapshotListResponse < 3) {
    o.items = buildUnnamed3467();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterSnapshotListResponse--;
  return o;
}

void checkSnapshotListResponse(api.SnapshotListResponse o) {
  buildCounterSnapshotListResponse++;
  if (buildCounterSnapshotListResponse < 3) {
    checkUnnamed3467(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterSnapshotListResponse--;
}

core.int buildCounterStatsResponse = 0;
api.StatsResponse buildStatsResponse() {
  var o = api.StatsResponse();
  buildCounterStatsResponse++;
  if (buildCounterStatsResponse < 3) {
    o.avgSessionLengthMinutes = 42.0;
    o.churnProbability = 42.0;
    o.daysSinceLastPlayed = 42;
    o.highSpenderProbability = 42.0;
    o.kind = 'foo';
    o.numPurchases = 42;
    o.numSessions = 42;
    o.numSessionsPercentile = 42.0;
    o.spendPercentile = 42.0;
    o.spendProbability = 42.0;
    o.totalSpendNext28Days = 42.0;
  }
  buildCounterStatsResponse--;
  return o;
}

void checkStatsResponse(api.StatsResponse o) {
  buildCounterStatsResponse++;
  if (buildCounterStatsResponse < 3) {
    unittest.expect(
      o.avgSessionLengthMinutes!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.churnProbability!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.daysSinceLastPlayed!,
      unittest.equals(42),
    );
    unittest.expect(
      o.highSpenderProbability!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numPurchases!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numSessions!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numSessionsPercentile!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.spendPercentile!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.spendProbability!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.totalSpendNext28Days!,
      unittest.equals(42.0),
    );
  }
  buildCounterStatsResponse--;
}

void main() {
  unittest.group('obj-schema-AchievementDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementDefinition(od as api.AchievementDefinition);
    });
  });

  unittest.group('obj-schema-AchievementDefinitionsListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementDefinitionsListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementDefinitionsListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementDefinitionsListResponse(
          od as api.AchievementDefinitionsListResponse);
    });
  });

  unittest.group('obj-schema-AchievementIncrementResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementIncrementResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementIncrementResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementIncrementResponse(od as api.AchievementIncrementResponse);
    });
  });

  unittest.group('obj-schema-AchievementRevealResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementRevealResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementRevealResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementRevealResponse(od as api.AchievementRevealResponse);
    });
  });

  unittest.group('obj-schema-AchievementSetStepsAtLeastResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementSetStepsAtLeastResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementSetStepsAtLeastResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementSetStepsAtLeastResponse(
          od as api.AchievementSetStepsAtLeastResponse);
    });
  });

  unittest.group('obj-schema-AchievementUnlockResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementUnlockResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementUnlockResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementUnlockResponse(od as api.AchievementUnlockResponse);
    });
  });

  unittest.group('obj-schema-AchievementUpdateMultipleRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementUpdateMultipleRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementUpdateMultipleRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementUpdateMultipleRequest(
          od as api.AchievementUpdateMultipleRequest);
    });
  });

  unittest.group('obj-schema-AchievementUpdateMultipleResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementUpdateMultipleResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementUpdateMultipleResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementUpdateMultipleResponse(
          od as api.AchievementUpdateMultipleResponse);
    });
  });

  unittest.group('obj-schema-AchievementUpdateRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementUpdateRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementUpdateRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementUpdateRequest(od as api.AchievementUpdateRequest);
    });
  });

  unittest.group('obj-schema-AchievementUpdateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementUpdateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementUpdateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementUpdateResponse(od as api.AchievementUpdateResponse);
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

  unittest.group('obj-schema-ApplicationCategory', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationCategory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationCategory.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationCategory(od as api.ApplicationCategory);
    });
  });

  unittest.group('obj-schema-ApplicationVerifyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplicationVerifyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ApplicationVerifyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplicationVerifyResponse(od as api.ApplicationVerifyResponse);
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

  unittest.group('obj-schema-CategoryListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategoryListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CategoryListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCategoryListResponse(od as api.CategoryListResponse);
    });
  });

  unittest.group('obj-schema-EndPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEndPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.EndPoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEndPoint(od as api.EndPoint);
    });
  });

  unittest.group('obj-schema-EventBatchRecordFailure', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventBatchRecordFailure();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventBatchRecordFailure.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventBatchRecordFailure(od as api.EventBatchRecordFailure);
    });
  });

  unittest.group('obj-schema-EventChild', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventChild();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.EventChild.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEventChild(od as api.EventChild);
    });
  });

  unittest.group('obj-schema-EventDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventDefinition(od as api.EventDefinition);
    });
  });

  unittest.group('obj-schema-EventDefinitionListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventDefinitionListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventDefinitionListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventDefinitionListResponse(od as api.EventDefinitionListResponse);
    });
  });

  unittest.group('obj-schema-EventPeriodRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventPeriodRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventPeriodRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventPeriodRange(od as api.EventPeriodRange);
    });
  });

  unittest.group('obj-schema-EventPeriodUpdate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventPeriodUpdate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventPeriodUpdate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventPeriodUpdate(od as api.EventPeriodUpdate);
    });
  });

  unittest.group('obj-schema-EventRecordFailure', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventRecordFailure();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventRecordFailure.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventRecordFailure(od as api.EventRecordFailure);
    });
  });

  unittest.group('obj-schema-EventRecordRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventRecordRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventRecordRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventRecordRequest(od as api.EventRecordRequest);
    });
  });

  unittest.group('obj-schema-EventUpdateRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventUpdateRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventUpdateRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventUpdateRequest(od as api.EventUpdateRequest);
    });
  });

  unittest.group('obj-schema-EventUpdateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEventUpdateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EventUpdateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEventUpdateResponse(od as api.EventUpdateResponse);
    });
  });

  unittest.group('obj-schema-GamesAchievementIncrement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGamesAchievementIncrement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GamesAchievementIncrement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGamesAchievementIncrement(od as api.GamesAchievementIncrement);
    });
  });

  unittest.group('obj-schema-GamesAchievementSetStepsAtLeast', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGamesAchievementSetStepsAtLeast();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GamesAchievementSetStepsAtLeast.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGamesAchievementSetStepsAtLeast(
          od as api.GamesAchievementSetStepsAtLeast);
    });
  });

  unittest.group('obj-schema-ImageAsset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageAsset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ImageAsset.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkImageAsset(od as api.ImageAsset);
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

  unittest.group('obj-schema-InstanceAndroidDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstanceAndroidDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InstanceAndroidDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInstanceAndroidDetails(od as api.InstanceAndroidDetails);
    });
  });

  unittest.group('obj-schema-InstanceIosDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstanceIosDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InstanceIosDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInstanceIosDetails(od as api.InstanceIosDetails);
    });
  });

  unittest.group('obj-schema-InstanceWebDetails', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInstanceWebDetails();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InstanceWebDetails.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInstanceWebDetails(od as api.InstanceWebDetails);
    });
  });

  unittest.group('obj-schema-Leaderboard', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboard();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Leaderboard.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboard(od as api.Leaderboard);
    });
  });

  unittest.group('obj-schema-LeaderboardEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardEntry(od as api.LeaderboardEntry);
    });
  });

  unittest.group('obj-schema-LeaderboardListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardListResponse(od as api.LeaderboardListResponse);
    });
  });

  unittest.group('obj-schema-LeaderboardScoreRank', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardScoreRank();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardScoreRank.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardScoreRank(od as api.LeaderboardScoreRank);
    });
  });

  unittest.group('obj-schema-LeaderboardScores', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardScores();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardScores.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardScores(od as api.LeaderboardScores);
    });
  });

  unittest.group('obj-schema-MetagameConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetagameConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MetagameConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMetagameConfig(od as api.MetagameConfig);
    });
  });

  unittest.group('obj-schema-PlayerName', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerName();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PlayerName.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPlayerName(od as api.PlayerName);
    });
  });

  unittest.group('obj-schema-Player', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Player.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPlayer(od as api.Player);
    });
  });

  unittest.group('obj-schema-PlayerAchievement', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerAchievement();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerAchievement.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerAchievement(od as api.PlayerAchievement);
    });
  });

  unittest.group('obj-schema-PlayerAchievementListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerAchievementListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerAchievementListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerAchievementListResponse(
          od as api.PlayerAchievementListResponse);
    });
  });

  unittest.group('obj-schema-PlayerEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerEvent(od as api.PlayerEvent);
    });
  });

  unittest.group('obj-schema-PlayerEventListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerEventListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerEventListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerEventListResponse(od as api.PlayerEventListResponse);
    });
  });

  unittest.group('obj-schema-PlayerExperienceInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerExperienceInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerExperienceInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerExperienceInfo(od as api.PlayerExperienceInfo);
    });
  });

  unittest.group('obj-schema-PlayerLeaderboardScore', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerLeaderboardScore();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerLeaderboardScore.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerLeaderboardScore(od as api.PlayerLeaderboardScore);
    });
  });

  unittest.group('obj-schema-PlayerLeaderboardScoreListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerLeaderboardScoreListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerLeaderboardScoreListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerLeaderboardScoreListResponse(
          od as api.PlayerLeaderboardScoreListResponse);
    });
  });

  unittest.group('obj-schema-PlayerLevel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerLevel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerLevel(od as api.PlayerLevel);
    });
  });

  unittest.group('obj-schema-PlayerListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerListResponse(od as api.PlayerListResponse);
    });
  });

  unittest.group('obj-schema-PlayerScore', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerScore();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerScore.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerScore(od as api.PlayerScore);
    });
  });

  unittest.group('obj-schema-PlayerScoreListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerScoreListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerScoreListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerScoreListResponse(od as api.PlayerScoreListResponse);
    });
  });

  unittest.group('obj-schema-PlayerScoreResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerScoreResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerScoreResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerScoreResponse(od as api.PlayerScoreResponse);
    });
  });

  unittest.group('obj-schema-PlayerScoreSubmissionList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlayerScoreSubmissionList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlayerScoreSubmissionList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlayerScoreSubmissionList(od as api.PlayerScoreSubmissionList);
    });
  });

  unittest.group('obj-schema-ProfileSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfileSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProfileSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProfileSettings(od as api.ProfileSettings);
    });
  });

  unittest.group('obj-schema-RevisionCheckResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRevisionCheckResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RevisionCheckResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRevisionCheckResponse(od as api.RevisionCheckResponse);
    });
  });

  unittest.group('obj-schema-ScoreSubmission', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScoreSubmission();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScoreSubmission.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScoreSubmission(od as api.ScoreSubmission);
    });
  });

  unittest.group('obj-schema-Snapshot', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSnapshot();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Snapshot.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSnapshot(od as api.Snapshot);
    });
  });

  unittest.group('obj-schema-SnapshotImage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSnapshotImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SnapshotImage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSnapshotImage(od as api.SnapshotImage);
    });
  });

  unittest.group('obj-schema-SnapshotListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSnapshotListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SnapshotListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSnapshotListResponse(od as api.SnapshotListResponse);
    });
  });

  unittest.group('obj-schema-StatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStatsResponse(od as api.StatsResponse);
    });
  });

  unittest.group('resource-AchievementDefinitionsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievementDefinitions;
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("games/v1/achievements"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildAchievementDefinitionsListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAchievementDefinitionsListResponse(
          response as api.AchievementDefinitionsListResponse);
    });
  });

  unittest.group('resource-AchievementsResource', () {
    unittest.test('method--increment', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievements;
      var arg_achievementId = 'foo';
      var arg_stepsToIncrement = 42;
      var arg_requestId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/achievements/"),
        );
        pathOffset += 22;
        index = path.indexOf('/increment', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/increment"),
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
          core.int.parse(queryMap["stepsToIncrement"]!.first),
          unittest.equals(arg_stepsToIncrement),
        );
        unittest.expect(
          queryMap["requestId"]!.first,
          unittest.equals(arg_requestId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAchievementIncrementResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.increment(
          arg_achievementId, arg_stepsToIncrement,
          requestId: arg_requestId, $fields: arg_$fields);
      checkAchievementIncrementResponse(
          response as api.AchievementIncrementResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievements;
      var arg_playerId = 'foo';
      var arg_language = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_state = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/players/"),
        );
        pathOffset += 17;
        index = path.indexOf('/achievements', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_playerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/achievements"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["state"]!.first,
          unittest.equals(arg_state),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlayerAchievementListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_playerId,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          state: arg_state,
          $fields: arg_$fields);
      checkPlayerAchievementListResponse(
          response as api.PlayerAchievementListResponse);
    });

    unittest.test('method--reveal', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievements;
      var arg_achievementId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/achievements/"),
        );
        pathOffset += 22;
        index = path.indexOf('/reveal', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/reveal"),
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
        var resp = convert.json.encode(buildAchievementRevealResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.reveal(arg_achievementId, $fields: arg_$fields);
      checkAchievementRevealResponse(response as api.AchievementRevealResponse);
    });

    unittest.test('method--setStepsAtLeast', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievements;
      var arg_achievementId = 'foo';
      var arg_steps = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/achievements/"),
        );
        pathOffset += 22;
        index = path.indexOf('/setStepsAtLeast', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/setStepsAtLeast"),
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
          core.int.parse(queryMap["steps"]!.first),
          unittest.equals(arg_steps),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildAchievementSetStepsAtLeastResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setStepsAtLeast(arg_achievementId, arg_steps,
          $fields: arg_$fields);
      checkAchievementSetStepsAtLeastResponse(
          response as api.AchievementSetStepsAtLeastResponse);
    });

    unittest.test('method--unlock', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievements;
      var arg_achievementId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/achievements/"),
        );
        pathOffset += 22;
        index = path.indexOf('/unlock', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/unlock"),
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
        var resp = convert.json.encode(buildAchievementUnlockResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.unlock(arg_achievementId, $fields: arg_$fields);
      checkAchievementUnlockResponse(response as api.AchievementUnlockResponse);
    });

    unittest.test('method--updateMultiple', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).achievements;
      var arg_request = buildAchievementUpdateMultipleRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AchievementUpdateMultipleRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAchievementUpdateMultipleRequest(
            obj as api.AchievementUpdateMultipleRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 36),
          unittest.equals("games/v1/achievements/updateMultiple"),
        );
        pathOffset += 36;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
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
            convert.json.encode(buildAchievementUpdateMultipleResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.updateMultiple(arg_request, $fields: arg_$fields);
      checkAchievementUpdateMultipleResponse(
          response as api.AchievementUpdateMultipleResponse);
    });
  });

  unittest.group('resource-ApplicationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).applications;
      var arg_applicationId = 'foo';
      var arg_language = 'foo';
      var arg_platformType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/applications/"),
        );
        pathOffset += 22;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["platformType"]!.first,
          unittest.equals(arg_platformType),
        );
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
      final response = await res.get(arg_applicationId,
          language: arg_language,
          platformType: arg_platformType,
          $fields: arg_$fields);
      checkApplication(response as api.Application);
    });

    unittest.test('method--getEndPoint', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).applications;
      var arg_applicationId = 'foo';
      var arg_endPointType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 33),
          unittest.equals("games/v1/applications/getEndPoint"),
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
          queryMap["applicationId"]!.first,
          unittest.equals(arg_applicationId),
        );
        unittest.expect(
          queryMap["endPointType"]!.first,
          unittest.equals(arg_endPointType),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEndPoint());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getEndPoint(
          applicationId: arg_applicationId,
          endPointType: arg_endPointType,
          $fields: arg_$fields);
      checkEndPoint(response as api.EndPoint);
    });

    unittest.test('method--played', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).applications;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/applications/played"),
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
      await res.played($fields: arg_$fields);
    });

    unittest.test('method--verify', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).applications;
      var arg_applicationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/applications/"),
        );
        pathOffset += 22;
        index = path.indexOf('/verify', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/verify"),
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
        var resp = convert.json.encode(buildApplicationVerifyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.verify(arg_applicationId, $fields: arg_$fields);
      checkApplicationVerifyResponse(response as api.ApplicationVerifyResponse);
    });
  });

  unittest.group('resource-EventsResource', () {
    unittest.test('method--listByPlayer', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).events;
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("games/v1/events"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlayerEventListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listByPlayer(
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkPlayerEventListResponse(response as api.PlayerEventListResponse);
    });

    unittest.test('method--listDefinitions', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).events;
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 25),
          unittest.equals("games/v1/eventDefinitions"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEventDefinitionListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listDefinitions(
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkEventDefinitionListResponse(
          response as api.EventDefinitionListResponse);
    });

    unittest.test('method--record', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).events;
      var arg_request = buildEventRecordRequest();
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EventRecordRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEventRecordRequest(obj as api.EventRecordRequest);

        var path = (req.url).path;
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
          unittest.equals("games/v1/events"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEventUpdateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.record(arg_request,
          language: arg_language, $fields: arg_$fields);
      checkEventUpdateResponse(response as api.EventUpdateResponse);
    });
  });

  unittest.group('resource-LeaderboardsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).leaderboards;
      var arg_leaderboardId = 'foo';
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/leaderboards/"),
        );
        pathOffset += 22;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLeaderboard());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_leaderboardId,
          language: arg_language, $fields: arg_$fields);
      checkLeaderboard(response as api.Leaderboard);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).leaderboards;
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("games/v1/leaderboards"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLeaderboardListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkLeaderboardListResponse(response as api.LeaderboardListResponse);
    });
  });

  unittest.group('resource-MetagameResource', () {
    unittest.test('method--getMetagameConfig', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).metagame;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/metagameConfig"),
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
        var resp = convert.json.encode(buildMetagameConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getMetagameConfig($fields: arg_$fields);
      checkMetagameConfig(response as api.MetagameConfig);
    });

    unittest.test('method--listCategoriesByPlayer', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).metagame;
      var arg_playerId = 'foo';
      var arg_collection = 'foo';
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("games/v1/players/"),
        );
        pathOffset += 17;
        index = path.indexOf('/categories/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_playerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/categories/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_collection'),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildCategoryListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listCategoriesByPlayer(
          arg_playerId, arg_collection,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCategoryListResponse(response as api.CategoryListResponse);
    });
  });

  unittest.group('resource-PlayersResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).players;
      var arg_playerId = 'foo';
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/players/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_playerId'),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlayer());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_playerId,
          language: arg_language, $fields: arg_$fields);
      checkPlayer(response as api.Player);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).players;
      var arg_collection = 'foo';
      var arg_language = 'foo';
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
          unittest.equals("games/v1/players/me/players/"),
        );
        pathOffset += 28;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_collection'),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlayerListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_collection,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkPlayerListResponse(response as api.PlayerListResponse);
    });
  });

  unittest.group('resource-RevisionsResource', () {
    unittest.test('method--check', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).revisions;
      var arg_clientRevision = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/revisions/check"),
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
          queryMap["clientRevision"]!.first,
          unittest.equals(arg_clientRevision),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRevisionCheckResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.check(arg_clientRevision, $fields: arg_$fields);
      checkRevisionCheckResponse(response as api.RevisionCheckResponse);
    });
  });

  unittest.group('resource-ScoresResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).scores;
      var arg_playerId = 'foo';
      var arg_leaderboardId = 'foo';
      var arg_timeSpan = 'foo';
      var arg_includeRankType = 'foo';
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("games/v1/players/"),
        );
        pathOffset += 17;
        index = path.indexOf('/leaderboards/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_playerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/leaderboards/"),
        );
        pathOffset += 14;
        index = path.indexOf('/scores/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/scores/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_timeSpan'),
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
          queryMap["includeRankType"]!.first,
          unittest.equals(arg_includeRankType),
        );
        unittest.expect(
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp =
            convert.json.encode(buildPlayerLeaderboardScoreListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_playerId, arg_leaderboardId, arg_timeSpan,
          includeRankType: arg_includeRankType,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkPlayerLeaderboardScoreListResponse(
          response as api.PlayerLeaderboardScoreListResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).scores;
      var arg_leaderboardId = 'foo';
      var arg_collection = 'foo';
      var arg_timeSpan = 'foo';
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/leaderboards/"),
        );
        pathOffset += 22;
        index = path.indexOf('/scores/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/scores/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_collection'),
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
          queryMap["timeSpan"]!.first,
          unittest.equals(arg_timeSpan),
        );
        unittest.expect(
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLeaderboardScores());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_leaderboardId, arg_collection, arg_timeSpan,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkLeaderboardScores(response as api.LeaderboardScores);
    });

    unittest.test('method--listWindow', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).scores;
      var arg_leaderboardId = 'foo';
      var arg_collection = 'foo';
      var arg_timeSpan = 'foo';
      var arg_language = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_resultsAbove = 42;
      var arg_returnTopIfAbsent = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/leaderboards/"),
        );
        pathOffset += 22;
        index = path.indexOf('/window/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/window/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_collection'),
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
          queryMap["timeSpan"]!.first,
          unittest.equals(arg_timeSpan),
        );
        unittest.expect(
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          core.int.parse(queryMap["resultsAbove"]!.first),
          unittest.equals(arg_resultsAbove),
        );
        unittest.expect(
          queryMap["returnTopIfAbsent"]!.first,
          unittest.equals("$arg_returnTopIfAbsent"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildLeaderboardScores());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listWindow(
          arg_leaderboardId, arg_collection, arg_timeSpan,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          resultsAbove: arg_resultsAbove,
          returnTopIfAbsent: arg_returnTopIfAbsent,
          $fields: arg_$fields);
      checkLeaderboardScores(response as api.LeaderboardScores);
    });

    unittest.test('method--submit', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).scores;
      var arg_leaderboardId = 'foo';
      var arg_score = 'foo';
      var arg_language = 'foo';
      var arg_scoreTag = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("games/v1/leaderboards/"),
        );
        pathOffset += 22;
        index = path.indexOf('/scores', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/scores"),
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
          queryMap["score"]!.first,
          unittest.equals(arg_score),
        );
        unittest.expect(
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["scoreTag"]!.first,
          unittest.equals(arg_scoreTag),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlayerScoreResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.submit(arg_leaderboardId, arg_score,
          language: arg_language, scoreTag: arg_scoreTag, $fields: arg_$fields);
      checkPlayerScoreResponse(response as api.PlayerScoreResponse);
    });

    unittest.test('method--submitMultiple', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).scores;
      var arg_request = buildPlayerScoreSubmissionList();
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PlayerScoreSubmissionList.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPlayerScoreSubmissionList(obj as api.PlayerScoreSubmissionList);

        var path = (req.url).path;
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
          unittest.equals("games/v1/leaderboards/scores"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPlayerScoreListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.submitMultiple(arg_request,
          language: arg_language, $fields: arg_$fields);
      checkPlayerScoreListResponse(response as api.PlayerScoreListResponse);
    });
  });

  unittest.group('resource-SnapshotsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).snapshots;
      var arg_snapshotId = 'foo';
      var arg_language = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/snapshots/"),
        );
        pathOffset += 19;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_snapshotId'),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSnapshot());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_snapshotId,
          language: arg_language, $fields: arg_$fields);
      checkSnapshot(response as api.Snapshot);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).snapshots;
      var arg_playerId = 'foo';
      var arg_language = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("games/v1/players/"),
        );
        pathOffset += 17;
        index = path.indexOf('/snapshots', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_playerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/snapshots"),
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
          queryMap["language"]!.first,
          unittest.equals(arg_language),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSnapshotListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_playerId,
          language: arg_language,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSnapshotListResponse(response as api.SnapshotListResponse);
    });
  });

  unittest.group('resource-StatsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesApi(mock).stats;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("games/v1/stats"),
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
        var resp = convert.json.encode(buildStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get($fields: arg_$fields);
      checkStatsResponse(response as api.StatsResponse);
    });
  });
}
