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

import 'package:googleapis/mybusinesslodging/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccessibility = 0;
api.Accessibility buildAccessibility() {
  var o = api.Accessibility();
  buildCounterAccessibility++;
  if (buildCounterAccessibility < 3) {
    o.mobilityAccessible = true;
    o.mobilityAccessibleElevator = true;
    o.mobilityAccessibleElevatorException = 'foo';
    o.mobilityAccessibleException = 'foo';
    o.mobilityAccessibleParking = true;
    o.mobilityAccessibleParkingException = 'foo';
    o.mobilityAccessiblePool = true;
    o.mobilityAccessiblePoolException = 'foo';
  }
  buildCounterAccessibility--;
  return o;
}

void checkAccessibility(api.Accessibility o) {
  buildCounterAccessibility++;
  if (buildCounterAccessibility < 3) {
    unittest.expect(o.mobilityAccessible!, unittest.isTrue);
    unittest.expect(o.mobilityAccessibleElevator!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessibleElevatorException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mobilityAccessibleException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobilityAccessibleParking!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessibleParkingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobilityAccessiblePool!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessiblePoolException!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccessibility--;
}

core.int buildCounterActivities = 0;
api.Activities buildActivities() {
  var o = api.Activities();
  buildCounterActivities++;
  if (buildCounterActivities < 3) {
    o.beachAccess = true;
    o.beachAccessException = 'foo';
    o.beachFront = true;
    o.beachFrontException = 'foo';
    o.bicycleRental = true;
    o.bicycleRentalException = 'foo';
    o.boutiqueStores = true;
    o.boutiqueStoresException = 'foo';
    o.casino = true;
    o.casinoException = 'foo';
    o.freeBicycleRental = true;
    o.freeBicycleRentalException = 'foo';
    o.freeWatercraftRental = true;
    o.freeWatercraftRentalException = 'foo';
    o.gameRoom = true;
    o.gameRoomException = 'foo';
    o.golf = true;
    o.golfException = 'foo';
    o.horsebackRiding = true;
    o.horsebackRidingException = 'foo';
    o.nightclub = true;
    o.nightclubException = 'foo';
    o.privateBeach = true;
    o.privateBeachException = 'foo';
    o.scuba = true;
    o.scubaException = 'foo';
    o.snorkeling = true;
    o.snorkelingException = 'foo';
    o.tennis = true;
    o.tennisException = 'foo';
    o.waterSkiing = true;
    o.waterSkiingException = 'foo';
    o.watercraftRental = true;
    o.watercraftRentalException = 'foo';
  }
  buildCounterActivities--;
  return o;
}

void checkActivities(api.Activities o) {
  buildCounterActivities++;
  if (buildCounterActivities < 3) {
    unittest.expect(o.beachAccess!, unittest.isTrue);
    unittest.expect(
      o.beachAccessException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.beachFront!, unittest.isTrue);
    unittest.expect(
      o.beachFrontException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.bicycleRental!, unittest.isTrue);
    unittest.expect(
      o.bicycleRentalException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.boutiqueStores!, unittest.isTrue);
    unittest.expect(
      o.boutiqueStoresException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.casino!, unittest.isTrue);
    unittest.expect(
      o.casinoException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeBicycleRental!, unittest.isTrue);
    unittest.expect(
      o.freeBicycleRentalException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeWatercraftRental!, unittest.isTrue);
    unittest.expect(
      o.freeWatercraftRentalException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.gameRoom!, unittest.isTrue);
    unittest.expect(
      o.gameRoomException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.golf!, unittest.isTrue);
    unittest.expect(
      o.golfException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.horsebackRiding!, unittest.isTrue);
    unittest.expect(
      o.horsebackRidingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.nightclub!, unittest.isTrue);
    unittest.expect(
      o.nightclubException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.privateBeach!, unittest.isTrue);
    unittest.expect(
      o.privateBeachException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.scuba!, unittest.isTrue);
    unittest.expect(
      o.scubaException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.snorkeling!, unittest.isTrue);
    unittest.expect(
      o.snorkelingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.tennis!, unittest.isTrue);
    unittest.expect(
      o.tennisException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.waterSkiing!, unittest.isTrue);
    unittest.expect(
      o.waterSkiingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.watercraftRental!, unittest.isTrue);
    unittest.expect(
      o.watercraftRentalException!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivities--;
}

core.int buildCounterBusiness = 0;
api.Business buildBusiness() {
  var o = api.Business();
  buildCounterBusiness++;
  if (buildCounterBusiness < 3) {
    o.businessCenter = true;
    o.businessCenterException = 'foo';
    o.meetingRooms = true;
    o.meetingRoomsCount = 42;
    o.meetingRoomsCountException = 'foo';
    o.meetingRoomsException = 'foo';
  }
  buildCounterBusiness--;
  return o;
}

void checkBusiness(api.Business o) {
  buildCounterBusiness++;
  if (buildCounterBusiness < 3) {
    unittest.expect(o.businessCenter!, unittest.isTrue);
    unittest.expect(
      o.businessCenterException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.meetingRooms!, unittest.isTrue);
    unittest.expect(
      o.meetingRoomsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.meetingRoomsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.meetingRoomsException!,
      unittest.equals('foo'),
    );
  }
  buildCounterBusiness--;
}

core.int buildCounterConnectivity = 0;
api.Connectivity buildConnectivity() {
  var o = api.Connectivity();
  buildCounterConnectivity++;
  if (buildCounterConnectivity < 3) {
    o.freeWifi = true;
    o.freeWifiException = 'foo';
    o.publicAreaWifiAvailable = true;
    o.publicAreaWifiAvailableException = 'foo';
    o.publicInternetTerminal = true;
    o.publicInternetTerminalException = 'foo';
    o.wifiAvailable = true;
    o.wifiAvailableException = 'foo';
  }
  buildCounterConnectivity--;
  return o;
}

void checkConnectivity(api.Connectivity o) {
  buildCounterConnectivity++;
  if (buildCounterConnectivity < 3) {
    unittest.expect(o.freeWifi!, unittest.isTrue);
    unittest.expect(
      o.freeWifiException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.publicAreaWifiAvailable!, unittest.isTrue);
    unittest.expect(
      o.publicAreaWifiAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.publicInternetTerminal!, unittest.isTrue);
    unittest.expect(
      o.publicInternetTerminalException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.wifiAvailable!, unittest.isTrue);
    unittest.expect(
      o.wifiAvailableException!,
      unittest.equals('foo'),
    );
  }
  buildCounterConnectivity--;
}

core.int buildCounterEnhancedCleaning = 0;
api.EnhancedCleaning buildEnhancedCleaning() {
  var o = api.EnhancedCleaning();
  buildCounterEnhancedCleaning++;
  if (buildCounterEnhancedCleaning < 3) {
    o.commercialGradeDisinfectantCleaning = true;
    o.commercialGradeDisinfectantCleaningException = 'foo';
    o.commonAreasEnhancedCleaning = true;
    o.commonAreasEnhancedCleaningException = 'foo';
    o.employeesTrainedCleaningProcedures = true;
    o.employeesTrainedCleaningProceduresException = 'foo';
    o.employeesTrainedThoroughHandWashing = true;
    o.employeesTrainedThoroughHandWashingException = 'foo';
    o.employeesWearProtectiveEquipment = true;
    o.employeesWearProtectiveEquipmentException = 'foo';
    o.guestRoomsEnhancedCleaning = true;
    o.guestRoomsEnhancedCleaningException = 'foo';
  }
  buildCounterEnhancedCleaning--;
  return o;
}

void checkEnhancedCleaning(api.EnhancedCleaning o) {
  buildCounterEnhancedCleaning++;
  if (buildCounterEnhancedCleaning < 3) {
    unittest.expect(o.commercialGradeDisinfectantCleaning!, unittest.isTrue);
    unittest.expect(
      o.commercialGradeDisinfectantCleaningException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.commonAreasEnhancedCleaning!, unittest.isTrue);
    unittest.expect(
      o.commonAreasEnhancedCleaningException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.employeesTrainedCleaningProcedures!, unittest.isTrue);
    unittest.expect(
      o.employeesTrainedCleaningProceduresException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.employeesTrainedThoroughHandWashing!, unittest.isTrue);
    unittest.expect(
      o.employeesTrainedThoroughHandWashingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.employeesWearProtectiveEquipment!, unittest.isTrue);
    unittest.expect(
      o.employeesWearProtectiveEquipmentException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.guestRoomsEnhancedCleaning!, unittest.isTrue);
    unittest.expect(
      o.guestRoomsEnhancedCleaningException!,
      unittest.equals('foo'),
    );
  }
  buildCounterEnhancedCleaning--;
}

core.int buildCounterFamilies = 0;
api.Families buildFamilies() {
  var o = api.Families();
  buildCounterFamilies++;
  if (buildCounterFamilies < 3) {
    o.babysitting = true;
    o.babysittingException = 'foo';
    o.kidsActivities = true;
    o.kidsActivitiesException = 'foo';
    o.kidsClub = true;
    o.kidsClubException = 'foo';
  }
  buildCounterFamilies--;
  return o;
}

void checkFamilies(api.Families o) {
  buildCounterFamilies++;
  if (buildCounterFamilies < 3) {
    unittest.expect(o.babysitting!, unittest.isTrue);
    unittest.expect(
      o.babysittingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.kidsActivities!, unittest.isTrue);
    unittest.expect(
      o.kidsActivitiesException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.kidsClub!, unittest.isTrue);
    unittest.expect(
      o.kidsClubException!,
      unittest.equals('foo'),
    );
  }
  buildCounterFamilies--;
}

core.int buildCounterFoodAndDrink = 0;
api.FoodAndDrink buildFoodAndDrink() {
  var o = api.FoodAndDrink();
  buildCounterFoodAndDrink++;
  if (buildCounterFoodAndDrink < 3) {
    o.bar = true;
    o.barException = 'foo';
    o.breakfastAvailable = true;
    o.breakfastAvailableException = 'foo';
    o.breakfastBuffet = true;
    o.breakfastBuffetException = 'foo';
    o.buffet = true;
    o.buffetException = 'foo';
    o.dinnerBuffet = true;
    o.dinnerBuffetException = 'foo';
    o.freeBreakfast = true;
    o.freeBreakfastException = 'foo';
    o.restaurant = true;
    o.restaurantException = 'foo';
    o.restaurantsCount = 42;
    o.restaurantsCountException = 'foo';
    o.roomService = true;
    o.roomServiceException = 'foo';
    o.tableService = true;
    o.tableServiceException = 'foo';
    o.twentyFourHourRoomService = true;
    o.twentyFourHourRoomServiceException = 'foo';
    o.vendingMachine = true;
    o.vendingMachineException = 'foo';
  }
  buildCounterFoodAndDrink--;
  return o;
}

void checkFoodAndDrink(api.FoodAndDrink o) {
  buildCounterFoodAndDrink++;
  if (buildCounterFoodAndDrink < 3) {
    unittest.expect(o.bar!, unittest.isTrue);
    unittest.expect(
      o.barException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.breakfastAvailable!, unittest.isTrue);
    unittest.expect(
      o.breakfastAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.breakfastBuffet!, unittest.isTrue);
    unittest.expect(
      o.breakfastBuffetException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.buffet!, unittest.isTrue);
    unittest.expect(
      o.buffetException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dinnerBuffet!, unittest.isTrue);
    unittest.expect(
      o.dinnerBuffetException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeBreakfast!, unittest.isTrue);
    unittest.expect(
      o.freeBreakfastException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.restaurant!, unittest.isTrue);
    unittest.expect(
      o.restaurantException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.restaurantsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.restaurantsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.roomService!, unittest.isTrue);
    unittest.expect(
      o.roomServiceException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.tableService!, unittest.isTrue);
    unittest.expect(
      o.tableServiceException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.twentyFourHourRoomService!, unittest.isTrue);
    unittest.expect(
      o.twentyFourHourRoomServiceException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.vendingMachine!, unittest.isTrue);
    unittest.expect(
      o.vendingMachineException!,
      unittest.equals('foo'),
    );
  }
  buildCounterFoodAndDrink--;
}

core.int buildCounterGetGoogleUpdatedLodgingResponse = 0;
api.GetGoogleUpdatedLodgingResponse buildGetGoogleUpdatedLodgingResponse() {
  var o = api.GetGoogleUpdatedLodgingResponse();
  buildCounterGetGoogleUpdatedLodgingResponse++;
  if (buildCounterGetGoogleUpdatedLodgingResponse < 3) {
    o.diffMask = 'foo';
    o.lodging = buildLodging();
  }
  buildCounterGetGoogleUpdatedLodgingResponse--;
  return o;
}

void checkGetGoogleUpdatedLodgingResponse(
    api.GetGoogleUpdatedLodgingResponse o) {
  buildCounterGetGoogleUpdatedLodgingResponse++;
  if (buildCounterGetGoogleUpdatedLodgingResponse < 3) {
    unittest.expect(
      o.diffMask!,
      unittest.equals('foo'),
    );
    checkLodging(o.lodging! as api.Lodging);
  }
  buildCounterGetGoogleUpdatedLodgingResponse--;
}

core.int buildCounterGuestUnitFeatures = 0;
api.GuestUnitFeatures buildGuestUnitFeatures() {
  var o = api.GuestUnitFeatures();
  buildCounterGuestUnitFeatures++;
  if (buildCounterGuestUnitFeatures < 3) {
    o.bungalowOrVilla = true;
    o.bungalowOrVillaException = 'foo';
    o.connectingUnitAvailable = true;
    o.connectingUnitAvailableException = 'foo';
    o.executiveFloor = true;
    o.executiveFloorException = 'foo';
    o.maxAdultOccupantsCount = 42;
    o.maxAdultOccupantsCountException = 'foo';
    o.maxChildOccupantsCount = 42;
    o.maxChildOccupantsCountException = 'foo';
    o.maxOccupantsCount = 42;
    o.maxOccupantsCountException = 'foo';
    o.privateHome = true;
    o.privateHomeException = 'foo';
    o.suite = true;
    o.suiteException = 'foo';
    o.tier = 'foo';
    o.tierException = 'foo';
    o.totalLivingAreas = buildLivingArea();
    o.views = buildViewsFromUnit();
  }
  buildCounterGuestUnitFeatures--;
  return o;
}

void checkGuestUnitFeatures(api.GuestUnitFeatures o) {
  buildCounterGuestUnitFeatures++;
  if (buildCounterGuestUnitFeatures < 3) {
    unittest.expect(o.bungalowOrVilla!, unittest.isTrue);
    unittest.expect(
      o.bungalowOrVillaException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.connectingUnitAvailable!, unittest.isTrue);
    unittest.expect(
      o.connectingUnitAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.executiveFloor!, unittest.isTrue);
    unittest.expect(
      o.executiveFloorException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxAdultOccupantsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxAdultOccupantsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxChildOccupantsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxChildOccupantsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxOccupantsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxOccupantsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.privateHome!, unittest.isTrue);
    unittest.expect(
      o.privateHomeException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.suite!, unittest.isTrue);
    unittest.expect(
      o.suiteException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tier!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tierException!,
      unittest.equals('foo'),
    );
    checkLivingArea(o.totalLivingAreas! as api.LivingArea);
    checkViewsFromUnit(o.views! as api.ViewsFromUnit);
  }
  buildCounterGuestUnitFeatures--;
}

core.List<core.String> buildUnnamed4788() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4788(core.List<core.String> o) {
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

core.int buildCounterGuestUnitType = 0;
api.GuestUnitType buildGuestUnitType() {
  var o = api.GuestUnitType();
  buildCounterGuestUnitType++;
  if (buildCounterGuestUnitType < 3) {
    o.codes = buildUnnamed4788();
    o.features = buildGuestUnitFeatures();
    o.label = 'foo';
  }
  buildCounterGuestUnitType--;
  return o;
}

void checkGuestUnitType(api.GuestUnitType o) {
  buildCounterGuestUnitType++;
  if (buildCounterGuestUnitType < 3) {
    checkUnnamed4788(o.codes!);
    checkGuestUnitFeatures(o.features! as api.GuestUnitFeatures);
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
  }
  buildCounterGuestUnitType--;
}

core.int buildCounterHealthAndSafety = 0;
api.HealthAndSafety buildHealthAndSafety() {
  var o = api.HealthAndSafety();
  buildCounterHealthAndSafety++;
  if (buildCounterHealthAndSafety < 3) {
    o.enhancedCleaning = buildEnhancedCleaning();
    o.increasedFoodSafety = buildIncreasedFoodSafety();
    o.minimizedContact = buildMinimizedContact();
    o.personalProtection = buildPersonalProtection();
    o.physicalDistancing = buildPhysicalDistancing();
  }
  buildCounterHealthAndSafety--;
  return o;
}

void checkHealthAndSafety(api.HealthAndSafety o) {
  buildCounterHealthAndSafety++;
  if (buildCounterHealthAndSafety < 3) {
    checkEnhancedCleaning(o.enhancedCleaning! as api.EnhancedCleaning);
    checkIncreasedFoodSafety(o.increasedFoodSafety! as api.IncreasedFoodSafety);
    checkMinimizedContact(o.minimizedContact! as api.MinimizedContact);
    checkPersonalProtection(o.personalProtection! as api.PersonalProtection);
    checkPhysicalDistancing(o.physicalDistancing! as api.PhysicalDistancing);
  }
  buildCounterHealthAndSafety--;
}

core.int buildCounterHousekeeping = 0;
api.Housekeeping buildHousekeeping() {
  var o = api.Housekeeping();
  buildCounterHousekeeping++;
  if (buildCounterHousekeeping < 3) {
    o.dailyHousekeeping = true;
    o.dailyHousekeepingException = 'foo';
    o.housekeepingAvailable = true;
    o.housekeepingAvailableException = 'foo';
    o.turndownService = true;
    o.turndownServiceException = 'foo';
  }
  buildCounterHousekeeping--;
  return o;
}

void checkHousekeeping(api.Housekeeping o) {
  buildCounterHousekeeping++;
  if (buildCounterHousekeeping < 3) {
    unittest.expect(o.dailyHousekeeping!, unittest.isTrue);
    unittest.expect(
      o.dailyHousekeepingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.housekeepingAvailable!, unittest.isTrue);
    unittest.expect(
      o.housekeepingAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.turndownService!, unittest.isTrue);
    unittest.expect(
      o.turndownServiceException!,
      unittest.equals('foo'),
    );
  }
  buildCounterHousekeeping--;
}

core.int buildCounterIncreasedFoodSafety = 0;
api.IncreasedFoodSafety buildIncreasedFoodSafety() {
  var o = api.IncreasedFoodSafety();
  buildCounterIncreasedFoodSafety++;
  if (buildCounterIncreasedFoodSafety < 3) {
    o.diningAreasAdditionalSanitation = true;
    o.diningAreasAdditionalSanitationException = 'foo';
    o.disposableFlatware = true;
    o.disposableFlatwareException = 'foo';
    o.foodPreparationAndServingAdditionalSafety = true;
    o.foodPreparationAndServingAdditionalSafetyException = 'foo';
    o.individualPackagedMeals = true;
    o.individualPackagedMealsException = 'foo';
    o.singleUseFoodMenus = true;
    o.singleUseFoodMenusException = 'foo';
  }
  buildCounterIncreasedFoodSafety--;
  return o;
}

void checkIncreasedFoodSafety(api.IncreasedFoodSafety o) {
  buildCounterIncreasedFoodSafety++;
  if (buildCounterIncreasedFoodSafety < 3) {
    unittest.expect(o.diningAreasAdditionalSanitation!, unittest.isTrue);
    unittest.expect(
      o.diningAreasAdditionalSanitationException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.disposableFlatware!, unittest.isTrue);
    unittest.expect(
      o.disposableFlatwareException!,
      unittest.equals('foo'),
    );
    unittest.expect(
        o.foodPreparationAndServingAdditionalSafety!, unittest.isTrue);
    unittest.expect(
      o.foodPreparationAndServingAdditionalSafetyException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.individualPackagedMeals!, unittest.isTrue);
    unittest.expect(
      o.individualPackagedMealsException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.singleUseFoodMenus!, unittest.isTrue);
    unittest.expect(
      o.singleUseFoodMenusException!,
      unittest.equals('foo'),
    );
  }
  buildCounterIncreasedFoodSafety--;
}

core.int buildCounterLanguageSpoken = 0;
api.LanguageSpoken buildLanguageSpoken() {
  var o = api.LanguageSpoken();
  buildCounterLanguageSpoken++;
  if (buildCounterLanguageSpoken < 3) {
    o.languageCode = 'foo';
    o.spoken = true;
    o.spokenException = 'foo';
  }
  buildCounterLanguageSpoken--;
  return o;
}

void checkLanguageSpoken(api.LanguageSpoken o) {
  buildCounterLanguageSpoken++;
  if (buildCounterLanguageSpoken < 3) {
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.spoken!, unittest.isTrue);
    unittest.expect(
      o.spokenException!,
      unittest.equals('foo'),
    );
  }
  buildCounterLanguageSpoken--;
}

core.int buildCounterLivingArea = 0;
api.LivingArea buildLivingArea() {
  var o = api.LivingArea();
  buildCounterLivingArea++;
  if (buildCounterLivingArea < 3) {
    o.accessibility = buildLivingAreaAccessibility();
    o.eating = buildLivingAreaEating();
    o.features = buildLivingAreaFeatures();
    o.layout = buildLivingAreaLayout();
    o.sleeping = buildLivingAreaSleeping();
  }
  buildCounterLivingArea--;
  return o;
}

void checkLivingArea(api.LivingArea o) {
  buildCounterLivingArea++;
  if (buildCounterLivingArea < 3) {
    checkLivingAreaAccessibility(
        o.accessibility! as api.LivingAreaAccessibility);
    checkLivingAreaEating(o.eating! as api.LivingAreaEating);
    checkLivingAreaFeatures(o.features! as api.LivingAreaFeatures);
    checkLivingAreaLayout(o.layout! as api.LivingAreaLayout);
    checkLivingAreaSleeping(o.sleeping! as api.LivingAreaSleeping);
  }
  buildCounterLivingArea--;
}

core.int buildCounterLivingAreaAccessibility = 0;
api.LivingAreaAccessibility buildLivingAreaAccessibility() {
  var o = api.LivingAreaAccessibility();
  buildCounterLivingAreaAccessibility++;
  if (buildCounterLivingAreaAccessibility < 3) {
    o.adaCompliantUnit = true;
    o.adaCompliantUnitException = 'foo';
    o.hearingAccessibleDoorbell = true;
    o.hearingAccessibleDoorbellException = 'foo';
    o.hearingAccessibleFireAlarm = true;
    o.hearingAccessibleFireAlarmException = 'foo';
    o.hearingAccessibleUnit = true;
    o.hearingAccessibleUnitException = 'foo';
    o.mobilityAccessibleBathtub = true;
    o.mobilityAccessibleBathtubException = 'foo';
    o.mobilityAccessibleShower = true;
    o.mobilityAccessibleShowerException = 'foo';
    o.mobilityAccessibleToilet = true;
    o.mobilityAccessibleToiletException = 'foo';
    o.mobilityAccessibleUnit = true;
    o.mobilityAccessibleUnitException = 'foo';
  }
  buildCounterLivingAreaAccessibility--;
  return o;
}

void checkLivingAreaAccessibility(api.LivingAreaAccessibility o) {
  buildCounterLivingAreaAccessibility++;
  if (buildCounterLivingAreaAccessibility < 3) {
    unittest.expect(o.adaCompliantUnit!, unittest.isTrue);
    unittest.expect(
      o.adaCompliantUnitException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hearingAccessibleDoorbell!, unittest.isTrue);
    unittest.expect(
      o.hearingAccessibleDoorbellException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hearingAccessibleFireAlarm!, unittest.isTrue);
    unittest.expect(
      o.hearingAccessibleFireAlarmException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hearingAccessibleUnit!, unittest.isTrue);
    unittest.expect(
      o.hearingAccessibleUnitException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobilityAccessibleBathtub!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessibleBathtubException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobilityAccessibleShower!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessibleShowerException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobilityAccessibleToilet!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessibleToiletException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobilityAccessibleUnit!, unittest.isTrue);
    unittest.expect(
      o.mobilityAccessibleUnitException!,
      unittest.equals('foo'),
    );
  }
  buildCounterLivingAreaAccessibility--;
}

core.int buildCounterLivingAreaEating = 0;
api.LivingAreaEating buildLivingAreaEating() {
  var o = api.LivingAreaEating();
  buildCounterLivingAreaEating++;
  if (buildCounterLivingAreaEating < 3) {
    o.coffeeMaker = true;
    o.coffeeMakerException = 'foo';
    o.cookware = true;
    o.cookwareException = 'foo';
    o.dishwasher = true;
    o.dishwasherException = 'foo';
    o.indoorGrill = true;
    o.indoorGrillException = 'foo';
    o.kettle = true;
    o.kettleException = 'foo';
    o.kitchenAvailable = true;
    o.kitchenAvailableException = 'foo';
    o.microwave = true;
    o.microwaveException = 'foo';
    o.minibar = true;
    o.minibarException = 'foo';
    o.outdoorGrill = true;
    o.outdoorGrillException = 'foo';
    o.oven = true;
    o.ovenException = 'foo';
    o.refrigerator = true;
    o.refrigeratorException = 'foo';
    o.sink = true;
    o.sinkException = 'foo';
    o.snackbar = true;
    o.snackbarException = 'foo';
    o.stove = true;
    o.stoveException = 'foo';
    o.teaStation = true;
    o.teaStationException = 'foo';
    o.toaster = true;
    o.toasterException = 'foo';
  }
  buildCounterLivingAreaEating--;
  return o;
}

void checkLivingAreaEating(api.LivingAreaEating o) {
  buildCounterLivingAreaEating++;
  if (buildCounterLivingAreaEating < 3) {
    unittest.expect(o.coffeeMaker!, unittest.isTrue);
    unittest.expect(
      o.coffeeMakerException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cookware!, unittest.isTrue);
    unittest.expect(
      o.cookwareException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dishwasher!, unittest.isTrue);
    unittest.expect(
      o.dishwasherException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.indoorGrill!, unittest.isTrue);
    unittest.expect(
      o.indoorGrillException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.kettle!, unittest.isTrue);
    unittest.expect(
      o.kettleException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.kitchenAvailable!, unittest.isTrue);
    unittest.expect(
      o.kitchenAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.microwave!, unittest.isTrue);
    unittest.expect(
      o.microwaveException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.minibar!, unittest.isTrue);
    unittest.expect(
      o.minibarException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.outdoorGrill!, unittest.isTrue);
    unittest.expect(
      o.outdoorGrillException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.oven!, unittest.isTrue);
    unittest.expect(
      o.ovenException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.refrigerator!, unittest.isTrue);
    unittest.expect(
      o.refrigeratorException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sink!, unittest.isTrue);
    unittest.expect(
      o.sinkException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.snackbar!, unittest.isTrue);
    unittest.expect(
      o.snackbarException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.stove!, unittest.isTrue);
    unittest.expect(
      o.stoveException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.teaStation!, unittest.isTrue);
    unittest.expect(
      o.teaStationException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.toaster!, unittest.isTrue);
    unittest.expect(
      o.toasterException!,
      unittest.equals('foo'),
    );
  }
  buildCounterLivingAreaEating--;
}

core.int buildCounterLivingAreaFeatures = 0;
api.LivingAreaFeatures buildLivingAreaFeatures() {
  var o = api.LivingAreaFeatures();
  buildCounterLivingAreaFeatures++;
  if (buildCounterLivingAreaFeatures < 3) {
    o.airConditioning = true;
    o.airConditioningException = 'foo';
    o.bathtub = true;
    o.bathtubException = 'foo';
    o.bidet = true;
    o.bidetException = 'foo';
    o.dryer = true;
    o.dryerException = 'foo';
    o.electronicRoomKey = true;
    o.electronicRoomKeyException = 'foo';
    o.fireplace = true;
    o.fireplaceException = 'foo';
    o.hairdryer = true;
    o.hairdryerException = 'foo';
    o.heating = true;
    o.heatingException = 'foo';
    o.inunitSafe = true;
    o.inunitSafeException = 'foo';
    o.inunitWifiAvailable = true;
    o.inunitWifiAvailableException = 'foo';
    o.ironingEquipment = true;
    o.ironingEquipmentException = 'foo';
    o.payPerViewMovies = true;
    o.payPerViewMoviesException = 'foo';
    o.privateBathroom = true;
    o.privateBathroomException = 'foo';
    o.shower = true;
    o.showerException = 'foo';
    o.toilet = true;
    o.toiletException = 'foo';
    o.tv = true;
    o.tvCasting = true;
    o.tvCastingException = 'foo';
    o.tvException = 'foo';
    o.tvStreaming = true;
    o.tvStreamingException = 'foo';
    o.universalPowerAdapters = true;
    o.universalPowerAdaptersException = 'foo';
    o.washer = true;
    o.washerException = 'foo';
  }
  buildCounterLivingAreaFeatures--;
  return o;
}

void checkLivingAreaFeatures(api.LivingAreaFeatures o) {
  buildCounterLivingAreaFeatures++;
  if (buildCounterLivingAreaFeatures < 3) {
    unittest.expect(o.airConditioning!, unittest.isTrue);
    unittest.expect(
      o.airConditioningException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.bathtub!, unittest.isTrue);
    unittest.expect(
      o.bathtubException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.bidet!, unittest.isTrue);
    unittest.expect(
      o.bidetException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dryer!, unittest.isTrue);
    unittest.expect(
      o.dryerException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.electronicRoomKey!, unittest.isTrue);
    unittest.expect(
      o.electronicRoomKeyException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.fireplace!, unittest.isTrue);
    unittest.expect(
      o.fireplaceException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hairdryer!, unittest.isTrue);
    unittest.expect(
      o.hairdryerException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.heating!, unittest.isTrue);
    unittest.expect(
      o.heatingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.inunitSafe!, unittest.isTrue);
    unittest.expect(
      o.inunitSafeException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.inunitWifiAvailable!, unittest.isTrue);
    unittest.expect(
      o.inunitWifiAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.ironingEquipment!, unittest.isTrue);
    unittest.expect(
      o.ironingEquipmentException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.payPerViewMovies!, unittest.isTrue);
    unittest.expect(
      o.payPerViewMoviesException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.privateBathroom!, unittest.isTrue);
    unittest.expect(
      o.privateBathroomException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.shower!, unittest.isTrue);
    unittest.expect(
      o.showerException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.toilet!, unittest.isTrue);
    unittest.expect(
      o.toiletException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.tv!, unittest.isTrue);
    unittest.expect(o.tvCasting!, unittest.isTrue);
    unittest.expect(
      o.tvCastingException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tvException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.tvStreaming!, unittest.isTrue);
    unittest.expect(
      o.tvStreamingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.universalPowerAdapters!, unittest.isTrue);
    unittest.expect(
      o.universalPowerAdaptersException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.washer!, unittest.isTrue);
    unittest.expect(
      o.washerException!,
      unittest.equals('foo'),
    );
  }
  buildCounterLivingAreaFeatures--;
}

core.int buildCounterLivingAreaLayout = 0;
api.LivingAreaLayout buildLivingAreaLayout() {
  var o = api.LivingAreaLayout();
  buildCounterLivingAreaLayout++;
  if (buildCounterLivingAreaLayout < 3) {
    o.balcony = true;
    o.balconyException = 'foo';
    o.livingAreaSqMeters = 42.0;
    o.livingAreaSqMetersException = 'foo';
    o.loft = true;
    o.loftException = 'foo';
    o.nonSmoking = true;
    o.nonSmokingException = 'foo';
    o.patio = true;
    o.patioException = 'foo';
    o.stairs = true;
    o.stairsException = 'foo';
  }
  buildCounterLivingAreaLayout--;
  return o;
}

void checkLivingAreaLayout(api.LivingAreaLayout o) {
  buildCounterLivingAreaLayout++;
  if (buildCounterLivingAreaLayout < 3) {
    unittest.expect(o.balcony!, unittest.isTrue);
    unittest.expect(
      o.balconyException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.livingAreaSqMeters!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.livingAreaSqMetersException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.loft!, unittest.isTrue);
    unittest.expect(
      o.loftException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.nonSmoking!, unittest.isTrue);
    unittest.expect(
      o.nonSmokingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.patio!, unittest.isTrue);
    unittest.expect(
      o.patioException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.stairs!, unittest.isTrue);
    unittest.expect(
      o.stairsException!,
      unittest.equals('foo'),
    );
  }
  buildCounterLivingAreaLayout--;
}

core.int buildCounterLivingAreaSleeping = 0;
api.LivingAreaSleeping buildLivingAreaSleeping() {
  var o = api.LivingAreaSleeping();
  buildCounterLivingAreaSleeping++;
  if (buildCounterLivingAreaSleeping < 3) {
    o.bedsCount = 42;
    o.bedsCountException = 'foo';
    o.bunkBedsCount = 42;
    o.bunkBedsCountException = 'foo';
    o.cribsCount = 42;
    o.cribsCountException = 'foo';
    o.doubleBedsCount = 42;
    o.doubleBedsCountException = 'foo';
    o.featherPillows = true;
    o.featherPillowsException = 'foo';
    o.hypoallergenicBedding = true;
    o.hypoallergenicBeddingException = 'foo';
    o.kingBedsCount = 42;
    o.kingBedsCountException = 'foo';
    o.memoryFoamPillows = true;
    o.memoryFoamPillowsException = 'foo';
    o.otherBedsCount = 42;
    o.otherBedsCountException = 'foo';
    o.queenBedsCount = 42;
    o.queenBedsCountException = 'foo';
    o.rollAwayBedsCount = 42;
    o.rollAwayBedsCountException = 'foo';
    o.singleOrTwinBedsCount = 42;
    o.singleOrTwinBedsCountException = 'foo';
    o.sofaBedsCount = 42;
    o.sofaBedsCountException = 'foo';
    o.syntheticPillows = true;
    o.syntheticPillowsException = 'foo';
  }
  buildCounterLivingAreaSleeping--;
  return o;
}

void checkLivingAreaSleeping(api.LivingAreaSleeping o) {
  buildCounterLivingAreaSleeping++;
  if (buildCounterLivingAreaSleeping < 3) {
    unittest.expect(
      o.bedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.bedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bunkBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.bunkBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cribsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.cribsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.doubleBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.doubleBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.featherPillows!, unittest.isTrue);
    unittest.expect(
      o.featherPillowsException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hypoallergenicBedding!, unittest.isTrue);
    unittest.expect(
      o.hypoallergenicBeddingException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kingBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kingBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.memoryFoamPillows!, unittest.isTrue);
    unittest.expect(
      o.memoryFoamPillowsException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.otherBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.otherBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.queenBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.queenBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rollAwayBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.rollAwayBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.singleOrTwinBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.singleOrTwinBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sofaBedsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sofaBedsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.syntheticPillows!, unittest.isTrue);
    unittest.expect(
      o.syntheticPillowsException!,
      unittest.equals('foo'),
    );
  }
  buildCounterLivingAreaSleeping--;
}

core.List<api.GuestUnitType> buildUnnamed4789() {
  var o = <api.GuestUnitType>[];
  o.add(buildGuestUnitType());
  o.add(buildGuestUnitType());
  return o;
}

void checkUnnamed4789(core.List<api.GuestUnitType> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGuestUnitType(o[0] as api.GuestUnitType);
  checkGuestUnitType(o[1] as api.GuestUnitType);
}

core.int buildCounterLodging = 0;
api.Lodging buildLodging() {
  var o = api.Lodging();
  buildCounterLodging++;
  if (buildCounterLodging < 3) {
    o.accessibility = buildAccessibility();
    o.activities = buildActivities();
    o.allUnits = buildGuestUnitFeatures();
    o.business = buildBusiness();
    o.commonLivingArea = buildLivingArea();
    o.connectivity = buildConnectivity();
    o.families = buildFamilies();
    o.foodAndDrink = buildFoodAndDrink();
    o.guestUnits = buildUnnamed4789();
    o.healthAndSafety = buildHealthAndSafety();
    o.housekeeping = buildHousekeeping();
    o.metadata = buildLodgingMetadata();
    o.name = 'foo';
    o.parking = buildParking();
    o.pets = buildPets();
    o.policies = buildPolicies();
    o.pools = buildPools();
    o.property = buildProperty();
    o.services = buildServices();
    o.someUnits = buildGuestUnitFeatures();
    o.transportation = buildTransportation();
    o.wellness = buildWellness();
  }
  buildCounterLodging--;
  return o;
}

void checkLodging(api.Lodging o) {
  buildCounterLodging++;
  if (buildCounterLodging < 3) {
    checkAccessibility(o.accessibility! as api.Accessibility);
    checkActivities(o.activities! as api.Activities);
    checkGuestUnitFeatures(o.allUnits! as api.GuestUnitFeatures);
    checkBusiness(o.business! as api.Business);
    checkLivingArea(o.commonLivingArea! as api.LivingArea);
    checkConnectivity(o.connectivity! as api.Connectivity);
    checkFamilies(o.families! as api.Families);
    checkFoodAndDrink(o.foodAndDrink! as api.FoodAndDrink);
    checkUnnamed4789(o.guestUnits!);
    checkHealthAndSafety(o.healthAndSafety! as api.HealthAndSafety);
    checkHousekeeping(o.housekeeping! as api.Housekeeping);
    checkLodgingMetadata(o.metadata! as api.LodgingMetadata);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkParking(o.parking! as api.Parking);
    checkPets(o.pets! as api.Pets);
    checkPolicies(o.policies! as api.Policies);
    checkPools(o.pools! as api.Pools);
    checkProperty(o.property! as api.Property);
    checkServices(o.services! as api.Services);
    checkGuestUnitFeatures(o.someUnits! as api.GuestUnitFeatures);
    checkTransportation(o.transportation! as api.Transportation);
    checkWellness(o.wellness! as api.Wellness);
  }
  buildCounterLodging--;
}

core.int buildCounterLodgingMetadata = 0;
api.LodgingMetadata buildLodgingMetadata() {
  var o = api.LodgingMetadata();
  buildCounterLodgingMetadata++;
  if (buildCounterLodgingMetadata < 3) {
    o.updateTime = 'foo';
  }
  buildCounterLodgingMetadata--;
  return o;
}

void checkLodgingMetadata(api.LodgingMetadata o) {
  buildCounterLodgingMetadata++;
  if (buildCounterLodgingMetadata < 3) {
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterLodgingMetadata--;
}

core.int buildCounterMinimizedContact = 0;
api.MinimizedContact buildMinimizedContact() {
  var o = api.MinimizedContact();
  buildCounterMinimizedContact++;
  if (buildCounterMinimizedContact < 3) {
    o.contactlessCheckinCheckout = true;
    o.contactlessCheckinCheckoutException = 'foo';
    o.digitalGuestRoomKeys = true;
    o.digitalGuestRoomKeysException = 'foo';
    o.housekeepingScheduledRequestOnly = true;
    o.housekeepingScheduledRequestOnlyException = 'foo';
    o.noHighTouchItemsCommonAreas = true;
    o.noHighTouchItemsCommonAreasException = 'foo';
    o.noHighTouchItemsGuestRooms = true;
    o.noHighTouchItemsGuestRoomsException = 'foo';
    o.plasticKeycardsDisinfected = true;
    o.plasticKeycardsDisinfectedException = 'foo';
    o.roomBookingsBuffer = true;
    o.roomBookingsBufferException = 'foo';
  }
  buildCounterMinimizedContact--;
  return o;
}

void checkMinimizedContact(api.MinimizedContact o) {
  buildCounterMinimizedContact++;
  if (buildCounterMinimizedContact < 3) {
    unittest.expect(o.contactlessCheckinCheckout!, unittest.isTrue);
    unittest.expect(
      o.contactlessCheckinCheckoutException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.digitalGuestRoomKeys!, unittest.isTrue);
    unittest.expect(
      o.digitalGuestRoomKeysException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.housekeepingScheduledRequestOnly!, unittest.isTrue);
    unittest.expect(
      o.housekeepingScheduledRequestOnlyException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.noHighTouchItemsCommonAreas!, unittest.isTrue);
    unittest.expect(
      o.noHighTouchItemsCommonAreasException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.noHighTouchItemsGuestRooms!, unittest.isTrue);
    unittest.expect(
      o.noHighTouchItemsGuestRoomsException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.plasticKeycardsDisinfected!, unittest.isTrue);
    unittest.expect(
      o.plasticKeycardsDisinfectedException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.roomBookingsBuffer!, unittest.isTrue);
    unittest.expect(
      o.roomBookingsBufferException!,
      unittest.equals('foo'),
    );
  }
  buildCounterMinimizedContact--;
}

core.int buildCounterParking = 0;
api.Parking buildParking() {
  var o = api.Parking();
  buildCounterParking++;
  if (buildCounterParking < 3) {
    o.electricCarChargingStations = true;
    o.electricCarChargingStationsException = 'foo';
    o.freeParking = true;
    o.freeParkingException = 'foo';
    o.freeSelfParking = true;
    o.freeSelfParkingException = 'foo';
    o.freeValetParking = true;
    o.freeValetParkingException = 'foo';
    o.parkingAvailable = true;
    o.parkingAvailableException = 'foo';
    o.selfParkingAvailable = true;
    o.selfParkingAvailableException = 'foo';
    o.valetParkingAvailable = true;
    o.valetParkingAvailableException = 'foo';
  }
  buildCounterParking--;
  return o;
}

void checkParking(api.Parking o) {
  buildCounterParking++;
  if (buildCounterParking < 3) {
    unittest.expect(o.electricCarChargingStations!, unittest.isTrue);
    unittest.expect(
      o.electricCarChargingStationsException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeParking!, unittest.isTrue);
    unittest.expect(
      o.freeParkingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeSelfParking!, unittest.isTrue);
    unittest.expect(
      o.freeSelfParkingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeValetParking!, unittest.isTrue);
    unittest.expect(
      o.freeValetParkingException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.parkingAvailable!, unittest.isTrue);
    unittest.expect(
      o.parkingAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.selfParkingAvailable!, unittest.isTrue);
    unittest.expect(
      o.selfParkingAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.valetParkingAvailable!, unittest.isTrue);
    unittest.expect(
      o.valetParkingAvailableException!,
      unittest.equals('foo'),
    );
  }
  buildCounterParking--;
}

core.int buildCounterPaymentOptions = 0;
api.PaymentOptions buildPaymentOptions() {
  var o = api.PaymentOptions();
  buildCounterPaymentOptions++;
  if (buildCounterPaymentOptions < 3) {
    o.cash = true;
    o.cashException = 'foo';
    o.cheque = true;
    o.chequeException = 'foo';
    o.creditCard = true;
    o.creditCardException = 'foo';
    o.debitCard = true;
    o.debitCardException = 'foo';
    o.mobileNfc = true;
    o.mobileNfcException = 'foo';
  }
  buildCounterPaymentOptions--;
  return o;
}

void checkPaymentOptions(api.PaymentOptions o) {
  buildCounterPaymentOptions++;
  if (buildCounterPaymentOptions < 3) {
    unittest.expect(o.cash!, unittest.isTrue);
    unittest.expect(
      o.cashException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cheque!, unittest.isTrue);
    unittest.expect(
      o.chequeException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.creditCard!, unittest.isTrue);
    unittest.expect(
      o.creditCardException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.debitCard!, unittest.isTrue);
    unittest.expect(
      o.debitCardException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mobileNfc!, unittest.isTrue);
    unittest.expect(
      o.mobileNfcException!,
      unittest.equals('foo'),
    );
  }
  buildCounterPaymentOptions--;
}

core.int buildCounterPersonalProtection = 0;
api.PersonalProtection buildPersonalProtection() {
  var o = api.PersonalProtection();
  buildCounterPersonalProtection++;
  if (buildCounterPersonalProtection < 3) {
    o.commonAreasOfferSanitizingItems = true;
    o.commonAreasOfferSanitizingItemsException = 'foo';
    o.faceMaskRequired = true;
    o.faceMaskRequiredException = 'foo';
    o.guestRoomHygieneKitsAvailable = true;
    o.guestRoomHygieneKitsAvailableException = 'foo';
    o.protectiveEquipmentAvailable = true;
    o.protectiveEquipmentAvailableException = 'foo';
  }
  buildCounterPersonalProtection--;
  return o;
}

void checkPersonalProtection(api.PersonalProtection o) {
  buildCounterPersonalProtection++;
  if (buildCounterPersonalProtection < 3) {
    unittest.expect(o.commonAreasOfferSanitizingItems!, unittest.isTrue);
    unittest.expect(
      o.commonAreasOfferSanitizingItemsException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.faceMaskRequired!, unittest.isTrue);
    unittest.expect(
      o.faceMaskRequiredException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.guestRoomHygieneKitsAvailable!, unittest.isTrue);
    unittest.expect(
      o.guestRoomHygieneKitsAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.protectiveEquipmentAvailable!, unittest.isTrue);
    unittest.expect(
      o.protectiveEquipmentAvailableException!,
      unittest.equals('foo'),
    );
  }
  buildCounterPersonalProtection--;
}

core.int buildCounterPets = 0;
api.Pets buildPets() {
  var o = api.Pets();
  buildCounterPets++;
  if (buildCounterPets < 3) {
    o.catsAllowed = true;
    o.catsAllowedException = 'foo';
    o.dogsAllowed = true;
    o.dogsAllowedException = 'foo';
    o.petsAllowed = true;
    o.petsAllowedException = 'foo';
    o.petsAllowedFree = true;
    o.petsAllowedFreeException = 'foo';
  }
  buildCounterPets--;
  return o;
}

void checkPets(api.Pets o) {
  buildCounterPets++;
  if (buildCounterPets < 3) {
    unittest.expect(o.catsAllowed!, unittest.isTrue);
    unittest.expect(
      o.catsAllowedException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.dogsAllowed!, unittest.isTrue);
    unittest.expect(
      o.dogsAllowedException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.petsAllowed!, unittest.isTrue);
    unittest.expect(
      o.petsAllowedException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.petsAllowedFree!, unittest.isTrue);
    unittest.expect(
      o.petsAllowedFreeException!,
      unittest.equals('foo'),
    );
  }
  buildCounterPets--;
}

core.int buildCounterPhysicalDistancing = 0;
api.PhysicalDistancing buildPhysicalDistancing() {
  var o = api.PhysicalDistancing();
  buildCounterPhysicalDistancing++;
  if (buildCounterPhysicalDistancing < 3) {
    o.commonAreasPhysicalDistancingArranged = true;
    o.commonAreasPhysicalDistancingArrangedException = 'foo';
    o.physicalDistancingRequired = true;
    o.physicalDistancingRequiredException = 'foo';
    o.safetyDividers = true;
    o.safetyDividersException = 'foo';
    o.sharedAreasLimitedOccupancy = true;
    o.sharedAreasLimitedOccupancyException = 'foo';
    o.wellnessAreasHavePrivateSpaces = true;
    o.wellnessAreasHavePrivateSpacesException = 'foo';
  }
  buildCounterPhysicalDistancing--;
  return o;
}

void checkPhysicalDistancing(api.PhysicalDistancing o) {
  buildCounterPhysicalDistancing++;
  if (buildCounterPhysicalDistancing < 3) {
    unittest.expect(o.commonAreasPhysicalDistancingArranged!, unittest.isTrue);
    unittest.expect(
      o.commonAreasPhysicalDistancingArrangedException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.physicalDistancingRequired!, unittest.isTrue);
    unittest.expect(
      o.physicalDistancingRequiredException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.safetyDividers!, unittest.isTrue);
    unittest.expect(
      o.safetyDividersException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sharedAreasLimitedOccupancy!, unittest.isTrue);
    unittest.expect(
      o.sharedAreasLimitedOccupancyException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.wellnessAreasHavePrivateSpaces!, unittest.isTrue);
    unittest.expect(
      o.wellnessAreasHavePrivateSpacesException!,
      unittest.equals('foo'),
    );
  }
  buildCounterPhysicalDistancing--;
}

core.int buildCounterPolicies = 0;
api.Policies buildPolicies() {
  var o = api.Policies();
  buildCounterPolicies++;
  if (buildCounterPolicies < 3) {
    o.allInclusiveAvailable = true;
    o.allInclusiveAvailableException = 'foo';
    o.allInclusiveOnly = true;
    o.allInclusiveOnlyException = 'foo';
    o.checkinTime = buildTimeOfDay();
    o.checkinTimeException = 'foo';
    o.checkoutTime = buildTimeOfDay();
    o.checkoutTimeException = 'foo';
    o.kidsStayFree = true;
    o.kidsStayFreeException = 'foo';
    o.maxChildAge = 42;
    o.maxChildAgeException = 'foo';
    o.maxKidsStayFreeCount = 42;
    o.maxKidsStayFreeCountException = 'foo';
    o.paymentOptions = buildPaymentOptions();
    o.smokeFreeProperty = true;
    o.smokeFreePropertyException = 'foo';
  }
  buildCounterPolicies--;
  return o;
}

void checkPolicies(api.Policies o) {
  buildCounterPolicies++;
  if (buildCounterPolicies < 3) {
    unittest.expect(o.allInclusiveAvailable!, unittest.isTrue);
    unittest.expect(
      o.allInclusiveAvailableException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.allInclusiveOnly!, unittest.isTrue);
    unittest.expect(
      o.allInclusiveOnlyException!,
      unittest.equals('foo'),
    );
    checkTimeOfDay(o.checkinTime! as api.TimeOfDay);
    unittest.expect(
      o.checkinTimeException!,
      unittest.equals('foo'),
    );
    checkTimeOfDay(o.checkoutTime! as api.TimeOfDay);
    unittest.expect(
      o.checkoutTimeException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.kidsStayFree!, unittest.isTrue);
    unittest.expect(
      o.kidsStayFreeException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxChildAge!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxChildAgeException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxKidsStayFreeCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maxKidsStayFreeCountException!,
      unittest.equals('foo'),
    );
    checkPaymentOptions(o.paymentOptions! as api.PaymentOptions);
    unittest.expect(o.smokeFreeProperty!, unittest.isTrue);
    unittest.expect(
      o.smokeFreePropertyException!,
      unittest.equals('foo'),
    );
  }
  buildCounterPolicies--;
}

core.int buildCounterPools = 0;
api.Pools buildPools() {
  var o = api.Pools();
  buildCounterPools++;
  if (buildCounterPools < 3) {
    o.adultPool = true;
    o.adultPoolException = 'foo';
    o.hotTub = true;
    o.hotTubException = 'foo';
    o.indoorPool = true;
    o.indoorPoolException = 'foo';
    o.indoorPoolsCount = 42;
    o.indoorPoolsCountException = 'foo';
    o.lazyRiver = true;
    o.lazyRiverException = 'foo';
    o.lifeguard = true;
    o.lifeguardException = 'foo';
    o.outdoorPool = true;
    o.outdoorPoolException = 'foo';
    o.outdoorPoolsCount = 42;
    o.outdoorPoolsCountException = 'foo';
    o.pool = true;
    o.poolException = 'foo';
    o.poolsCount = 42;
    o.poolsCountException = 'foo';
    o.wadingPool = true;
    o.wadingPoolException = 'foo';
    o.waterPark = true;
    o.waterParkException = 'foo';
    o.waterslide = true;
    o.waterslideException = 'foo';
    o.wavePool = true;
    o.wavePoolException = 'foo';
  }
  buildCounterPools--;
  return o;
}

void checkPools(api.Pools o) {
  buildCounterPools++;
  if (buildCounterPools < 3) {
    unittest.expect(o.adultPool!, unittest.isTrue);
    unittest.expect(
      o.adultPoolException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hotTub!, unittest.isTrue);
    unittest.expect(
      o.hotTubException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.indoorPool!, unittest.isTrue);
    unittest.expect(
      o.indoorPoolException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.indoorPoolsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.indoorPoolsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.lazyRiver!, unittest.isTrue);
    unittest.expect(
      o.lazyRiverException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.lifeguard!, unittest.isTrue);
    unittest.expect(
      o.lifeguardException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.outdoorPool!, unittest.isTrue);
    unittest.expect(
      o.outdoorPoolException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outdoorPoolsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.outdoorPoolsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.pool!, unittest.isTrue);
    unittest.expect(
      o.poolException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.poolsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.poolsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.wadingPool!, unittest.isTrue);
    unittest.expect(
      o.wadingPoolException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.waterPark!, unittest.isTrue);
    unittest.expect(
      o.waterParkException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.waterslide!, unittest.isTrue);
    unittest.expect(
      o.waterslideException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.wavePool!, unittest.isTrue);
    unittest.expect(
      o.wavePoolException!,
      unittest.equals('foo'),
    );
  }
  buildCounterPools--;
}

core.int buildCounterProperty = 0;
api.Property buildProperty() {
  var o = api.Property();
  buildCounterProperty++;
  if (buildCounterProperty < 3) {
    o.builtYear = 42;
    o.builtYearException = 'foo';
    o.floorsCount = 42;
    o.floorsCountException = 'foo';
    o.lastRenovatedYear = 42;
    o.lastRenovatedYearException = 'foo';
    o.roomsCount = 42;
    o.roomsCountException = 'foo';
  }
  buildCounterProperty--;
  return o;
}

void checkProperty(api.Property o) {
  buildCounterProperty++;
  if (buildCounterProperty < 3) {
    unittest.expect(
      o.builtYear!,
      unittest.equals(42),
    );
    unittest.expect(
      o.builtYearException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.floorsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.floorsCountException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastRenovatedYear!,
      unittest.equals(42),
    );
    unittest.expect(
      o.lastRenovatedYearException!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.roomsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.roomsCountException!,
      unittest.equals('foo'),
    );
  }
  buildCounterProperty--;
}

core.List<api.LanguageSpoken> buildUnnamed4790() {
  var o = <api.LanguageSpoken>[];
  o.add(buildLanguageSpoken());
  o.add(buildLanguageSpoken());
  return o;
}

void checkUnnamed4790(core.List<api.LanguageSpoken> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLanguageSpoken(o[0] as api.LanguageSpoken);
  checkLanguageSpoken(o[1] as api.LanguageSpoken);
}

core.int buildCounterServices = 0;
api.Services buildServices() {
  var o = api.Services();
  buildCounterServices++;
  if (buildCounterServices < 3) {
    o.baggageStorage = true;
    o.baggageStorageException = 'foo';
    o.concierge = true;
    o.conciergeException = 'foo';
    o.convenienceStore = true;
    o.convenienceStoreException = 'foo';
    o.currencyExchange = true;
    o.currencyExchangeException = 'foo';
    o.elevator = true;
    o.elevatorException = 'foo';
    o.frontDesk = true;
    o.frontDeskException = 'foo';
    o.fullServiceLaundry = true;
    o.fullServiceLaundryException = 'foo';
    o.giftShop = true;
    o.giftShopException = 'foo';
    o.languagesSpoken = buildUnnamed4790();
    o.selfServiceLaundry = true;
    o.selfServiceLaundryException = 'foo';
    o.socialHour = true;
    o.socialHourException = 'foo';
    o.twentyFourHourFrontDesk = true;
    o.twentyFourHourFrontDeskException = 'foo';
    o.wakeUpCalls = true;
    o.wakeUpCallsException = 'foo';
  }
  buildCounterServices--;
  return o;
}

void checkServices(api.Services o) {
  buildCounterServices++;
  if (buildCounterServices < 3) {
    unittest.expect(o.baggageStorage!, unittest.isTrue);
    unittest.expect(
      o.baggageStorageException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.concierge!, unittest.isTrue);
    unittest.expect(
      o.conciergeException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.convenienceStore!, unittest.isTrue);
    unittest.expect(
      o.convenienceStoreException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.currencyExchange!, unittest.isTrue);
    unittest.expect(
      o.currencyExchangeException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.elevator!, unittest.isTrue);
    unittest.expect(
      o.elevatorException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.frontDesk!, unittest.isTrue);
    unittest.expect(
      o.frontDeskException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.fullServiceLaundry!, unittest.isTrue);
    unittest.expect(
      o.fullServiceLaundryException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.giftShop!, unittest.isTrue);
    unittest.expect(
      o.giftShopException!,
      unittest.equals('foo'),
    );
    checkUnnamed4790(o.languagesSpoken!);
    unittest.expect(o.selfServiceLaundry!, unittest.isTrue);
    unittest.expect(
      o.selfServiceLaundryException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.socialHour!, unittest.isTrue);
    unittest.expect(
      o.socialHourException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.twentyFourHourFrontDesk!, unittest.isTrue);
    unittest.expect(
      o.twentyFourHourFrontDeskException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.wakeUpCalls!, unittest.isTrue);
    unittest.expect(
      o.wakeUpCallsException!,
      unittest.equals('foo'),
    );
  }
  buildCounterServices--;
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

core.int buildCounterTransportation = 0;
api.Transportation buildTransportation() {
  var o = api.Transportation();
  buildCounterTransportation++;
  if (buildCounterTransportation < 3) {
    o.airportShuttle = true;
    o.airportShuttleException = 'foo';
    o.carRentalOnProperty = true;
    o.carRentalOnPropertyException = 'foo';
    o.freeAirportShuttle = true;
    o.freeAirportShuttleException = 'foo';
    o.freePrivateCarService = true;
    o.freePrivateCarServiceException = 'foo';
    o.localShuttle = true;
    o.localShuttleException = 'foo';
    o.privateCarService = true;
    o.privateCarServiceException = 'foo';
    o.transfer = true;
    o.transferException = 'foo';
  }
  buildCounterTransportation--;
  return o;
}

void checkTransportation(api.Transportation o) {
  buildCounterTransportation++;
  if (buildCounterTransportation < 3) {
    unittest.expect(o.airportShuttle!, unittest.isTrue);
    unittest.expect(
      o.airportShuttleException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.carRentalOnProperty!, unittest.isTrue);
    unittest.expect(
      o.carRentalOnPropertyException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeAirportShuttle!, unittest.isTrue);
    unittest.expect(
      o.freeAirportShuttleException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freePrivateCarService!, unittest.isTrue);
    unittest.expect(
      o.freePrivateCarServiceException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.localShuttle!, unittest.isTrue);
    unittest.expect(
      o.localShuttleException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.privateCarService!, unittest.isTrue);
    unittest.expect(
      o.privateCarServiceException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.transfer!, unittest.isTrue);
    unittest.expect(
      o.transferException!,
      unittest.equals('foo'),
    );
  }
  buildCounterTransportation--;
}

core.int buildCounterViewsFromUnit = 0;
api.ViewsFromUnit buildViewsFromUnit() {
  var o = api.ViewsFromUnit();
  buildCounterViewsFromUnit++;
  if (buildCounterViewsFromUnit < 3) {
    o.beachView = true;
    o.beachViewException = 'foo';
    o.cityView = true;
    o.cityViewException = 'foo';
    o.gardenView = true;
    o.gardenViewException = 'foo';
    o.lakeView = true;
    o.lakeViewException = 'foo';
    o.landmarkView = true;
    o.landmarkViewException = 'foo';
    o.oceanView = true;
    o.oceanViewException = 'foo';
    o.poolView = true;
    o.poolViewException = 'foo';
    o.valleyView = true;
    o.valleyViewException = 'foo';
  }
  buildCounterViewsFromUnit--;
  return o;
}

void checkViewsFromUnit(api.ViewsFromUnit o) {
  buildCounterViewsFromUnit++;
  if (buildCounterViewsFromUnit < 3) {
    unittest.expect(o.beachView!, unittest.isTrue);
    unittest.expect(
      o.beachViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cityView!, unittest.isTrue);
    unittest.expect(
      o.cityViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.gardenView!, unittest.isTrue);
    unittest.expect(
      o.gardenViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.lakeView!, unittest.isTrue);
    unittest.expect(
      o.lakeViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.landmarkView!, unittest.isTrue);
    unittest.expect(
      o.landmarkViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.oceanView!, unittest.isTrue);
    unittest.expect(
      o.oceanViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.poolView!, unittest.isTrue);
    unittest.expect(
      o.poolViewException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.valleyView!, unittest.isTrue);
    unittest.expect(
      o.valleyViewException!,
      unittest.equals('foo'),
    );
  }
  buildCounterViewsFromUnit--;
}

core.int buildCounterWellness = 0;
api.Wellness buildWellness() {
  var o = api.Wellness();
  buildCounterWellness++;
  if (buildCounterWellness < 3) {
    o.doctorOnCall = true;
    o.doctorOnCallException = 'foo';
    o.ellipticalMachine = true;
    o.ellipticalMachineException = 'foo';
    o.fitnessCenter = true;
    o.fitnessCenterException = 'foo';
    o.freeFitnessCenter = true;
    o.freeFitnessCenterException = 'foo';
    o.freeWeights = true;
    o.freeWeightsException = 'foo';
    o.massage = true;
    o.massageException = 'foo';
    o.salon = true;
    o.salonException = 'foo';
    o.sauna = true;
    o.saunaException = 'foo';
    o.spa = true;
    o.spaException = 'foo';
    o.treadmill = true;
    o.treadmillException = 'foo';
    o.weightMachine = true;
    o.weightMachineException = 'foo';
  }
  buildCounterWellness--;
  return o;
}

void checkWellness(api.Wellness o) {
  buildCounterWellness++;
  if (buildCounterWellness < 3) {
    unittest.expect(o.doctorOnCall!, unittest.isTrue);
    unittest.expect(
      o.doctorOnCallException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.ellipticalMachine!, unittest.isTrue);
    unittest.expect(
      o.ellipticalMachineException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.fitnessCenter!, unittest.isTrue);
    unittest.expect(
      o.fitnessCenterException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeFitnessCenter!, unittest.isTrue);
    unittest.expect(
      o.freeFitnessCenterException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.freeWeights!, unittest.isTrue);
    unittest.expect(
      o.freeWeightsException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.massage!, unittest.isTrue);
    unittest.expect(
      o.massageException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.salon!, unittest.isTrue);
    unittest.expect(
      o.salonException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sauna!, unittest.isTrue);
    unittest.expect(
      o.saunaException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.spa!, unittest.isTrue);
    unittest.expect(
      o.spaException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.treadmill!, unittest.isTrue);
    unittest.expect(
      o.treadmillException!,
      unittest.equals('foo'),
    );
    unittest.expect(o.weightMachine!, unittest.isTrue);
    unittest.expect(
      o.weightMachineException!,
      unittest.equals('foo'),
    );
  }
  buildCounterWellness--;
}

void main() {
  unittest.group('obj-schema-Accessibility', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccessibility();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Accessibility.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccessibility(od as api.Accessibility);
    });
  });

  unittest.group('obj-schema-Activities', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivities();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Activities.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActivities(od as api.Activities);
    });
  });

  unittest.group('obj-schema-Business', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBusiness();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Business.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBusiness(od as api.Business);
    });
  });

  unittest.group('obj-schema-Connectivity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConnectivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Connectivity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConnectivity(od as api.Connectivity);
    });
  });

  unittest.group('obj-schema-EnhancedCleaning', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEnhancedCleaning();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EnhancedCleaning.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEnhancedCleaning(od as api.EnhancedCleaning);
    });
  });

  unittest.group('obj-schema-Families', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFamilies();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Families.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFamilies(od as api.Families);
    });
  });

  unittest.group('obj-schema-FoodAndDrink', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFoodAndDrink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FoodAndDrink.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFoodAndDrink(od as api.FoodAndDrink);
    });
  });

  unittest.group('obj-schema-GetGoogleUpdatedLodgingResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetGoogleUpdatedLodgingResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetGoogleUpdatedLodgingResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetGoogleUpdatedLodgingResponse(
          od as api.GetGoogleUpdatedLodgingResponse);
    });
  });

  unittest.group('obj-schema-GuestUnitFeatures', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGuestUnitFeatures();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GuestUnitFeatures.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGuestUnitFeatures(od as api.GuestUnitFeatures);
    });
  });

  unittest.group('obj-schema-GuestUnitType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGuestUnitType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GuestUnitType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGuestUnitType(od as api.GuestUnitType);
    });
  });

  unittest.group('obj-schema-HealthAndSafety', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHealthAndSafety();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HealthAndSafety.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHealthAndSafety(od as api.HealthAndSafety);
    });
  });

  unittest.group('obj-schema-Housekeeping', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHousekeeping();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Housekeeping.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHousekeeping(od as api.Housekeeping);
    });
  });

  unittest.group('obj-schema-IncreasedFoodSafety', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIncreasedFoodSafety();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IncreasedFoodSafety.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIncreasedFoodSafety(od as api.IncreasedFoodSafety);
    });
  });

  unittest.group('obj-schema-LanguageSpoken', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageSpoken();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageSpoken.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageSpoken(od as api.LanguageSpoken);
    });
  });

  unittest.group('obj-schema-LivingArea', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivingArea();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LivingArea.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLivingArea(od as api.LivingArea);
    });
  });

  unittest.group('obj-schema-LivingAreaAccessibility', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivingAreaAccessibility();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LivingAreaAccessibility.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLivingAreaAccessibility(od as api.LivingAreaAccessibility);
    });
  });

  unittest.group('obj-schema-LivingAreaEating', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivingAreaEating();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LivingAreaEating.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLivingAreaEating(od as api.LivingAreaEating);
    });
  });

  unittest.group('obj-schema-LivingAreaFeatures', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivingAreaFeatures();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LivingAreaFeatures.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLivingAreaFeatures(od as api.LivingAreaFeatures);
    });
  });

  unittest.group('obj-schema-LivingAreaLayout', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivingAreaLayout();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LivingAreaLayout.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLivingAreaLayout(od as api.LivingAreaLayout);
    });
  });

  unittest.group('obj-schema-LivingAreaSleeping', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLivingAreaSleeping();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LivingAreaSleeping.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLivingAreaSleeping(od as api.LivingAreaSleeping);
    });
  });

  unittest.group('obj-schema-Lodging', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLodging();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Lodging.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLodging(od as api.Lodging);
    });
  });

  unittest.group('obj-schema-LodgingMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLodgingMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LodgingMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLodgingMetadata(od as api.LodgingMetadata);
    });
  });

  unittest.group('obj-schema-MinimizedContact', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMinimizedContact();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MinimizedContact.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMinimizedContact(od as api.MinimizedContact);
    });
  });

  unittest.group('obj-schema-Parking', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParking();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Parking.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkParking(od as api.Parking);
    });
  });

  unittest.group('obj-schema-PaymentOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPaymentOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PaymentOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPaymentOptions(od as api.PaymentOptions);
    });
  });

  unittest.group('obj-schema-PersonalProtection', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPersonalProtection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PersonalProtection.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPersonalProtection(od as api.PersonalProtection);
    });
  });

  unittest.group('obj-schema-Pets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Pets.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPets(od as api.Pets);
    });
  });

  unittest.group('obj-schema-PhysicalDistancing', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPhysicalDistancing();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PhysicalDistancing.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPhysicalDistancing(od as api.PhysicalDistancing);
    });
  });

  unittest.group('obj-schema-Policies', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicies();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policies.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicies(od as api.Policies);
    });
  });

  unittest.group('obj-schema-Pools', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPools();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Pools.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPools(od as api.Pools);
    });
  });

  unittest.group('obj-schema-Property', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Property.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProperty(od as api.Property);
    });
  });

  unittest.group('obj-schema-Services', () {
    unittest.test('to-json--from-json', () async {
      var o = buildServices();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Services.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkServices(od as api.Services);
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

  unittest.group('obj-schema-Transportation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransportation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Transportation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransportation(od as api.Transportation);
    });
  });

  unittest.group('obj-schema-ViewsFromUnit', () {
    unittest.test('to-json--from-json', () async {
      var o = buildViewsFromUnit();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ViewsFromUnit.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkViewsFromUnit(od as api.ViewsFromUnit);
    });
  });

  unittest.group('obj-schema-Wellness', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWellness();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Wellness.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkWellness(od as api.Wellness);
    });
  });

  unittest.group('resource-LocationsResource', () {
    unittest.test('method--getLodging', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessLodgingApi(mock).locations;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildLodging());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getLodging(arg_name,
          readMask: arg_readMask, $fields: arg_$fields);
      checkLodging(response as api.Lodging);
    });

    unittest.test('method--updateLodging', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessLodgingApi(mock).locations;
      var arg_request = buildLodging();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Lodging.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLodging(obj as api.Lodging);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildLodging());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateLodging(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkLodging(response as api.Lodging);
    });
  });

  unittest.group('resource-LocationsLodgingResource', () {
    unittest.test('method--getGoogleUpdated', () async {
      var mock = HttpServerMock();
      var res = api.MyBusinessLodgingApi(mock).locations.lodging;
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildGetGoogleUpdatedLodgingResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getGoogleUpdated(arg_name,
          readMask: arg_readMask, $fields: arg_$fields);
      checkGetGoogleUpdatedLodgingResponse(
          response as api.GetGoogleUpdatedLodgingResponse);
    });
  });
}
