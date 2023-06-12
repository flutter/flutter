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

import 'package:googleapis/reseller/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAddress = 0;
api.Address buildAddress() {
  var o = api.Address();
  buildCounterAddress++;
  if (buildCounterAddress < 3) {
    o.addressLine1 = 'foo';
    o.addressLine2 = 'foo';
    o.addressLine3 = 'foo';
    o.contactName = 'foo';
    o.countryCode = 'foo';
    o.kind = 'foo';
    o.locality = 'foo';
    o.organizationName = 'foo';
    o.postalCode = 'foo';
    o.region = 'foo';
  }
  buildCounterAddress--;
  return o;
}

void checkAddress(api.Address o) {
  buildCounterAddress++;
  if (buildCounterAddress < 3) {
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
      o.kind!,
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
  buildCounterAddress--;
}

core.int buildCounterChangePlanRequest = 0;
api.ChangePlanRequest buildChangePlanRequest() {
  var o = api.ChangePlanRequest();
  buildCounterChangePlanRequest++;
  if (buildCounterChangePlanRequest < 3) {
    o.dealCode = 'foo';
    o.kind = 'foo';
    o.planName = 'foo';
    o.purchaseOrderId = 'foo';
    o.seats = buildSeats();
  }
  buildCounterChangePlanRequest--;
  return o;
}

void checkChangePlanRequest(api.ChangePlanRequest o) {
  buildCounterChangePlanRequest++;
  if (buildCounterChangePlanRequest < 3) {
    unittest.expect(
      o.dealCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.planName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.purchaseOrderId!,
      unittest.equals('foo'),
    );
    checkSeats(o.seats! as api.Seats);
  }
  buildCounterChangePlanRequest--;
}

core.int buildCounterCustomer = 0;
api.Customer buildCustomer() {
  var o = api.Customer();
  buildCounterCustomer++;
  if (buildCounterCustomer < 3) {
    o.alternateEmail = 'foo';
    o.customerDomain = 'foo';
    o.customerDomainVerified = true;
    o.customerId = 'foo';
    o.kind = 'foo';
    o.phoneNumber = 'foo';
    o.postalAddress = buildAddress();
    o.resourceUiUrl = 'foo';
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
      o.customerDomain!,
      unittest.equals('foo'),
    );
    unittest.expect(o.customerDomainVerified!, unittest.isTrue);
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phoneNumber!,
      unittest.equals('foo'),
    );
    checkAddress(o.postalAddress! as api.Address);
    unittest.expect(
      o.resourceUiUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterCustomer--;
}

core.int buildCounterRenewalSettings = 0;
api.RenewalSettings buildRenewalSettings() {
  var o = api.RenewalSettings();
  buildCounterRenewalSettings++;
  if (buildCounterRenewalSettings < 3) {
    o.kind = 'foo';
    o.renewalType = 'foo';
  }
  buildCounterRenewalSettings--;
  return o;
}

void checkRenewalSettings(api.RenewalSettings o) {
  buildCounterRenewalSettings++;
  if (buildCounterRenewalSettings < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.renewalType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRenewalSettings--;
}

core.List<core.String> buildUnnamed4216() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4216(core.List<core.String> o) {
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

core.int buildCounterResellernotifyGetwatchdetailsResponse = 0;
api.ResellernotifyGetwatchdetailsResponse
    buildResellernotifyGetwatchdetailsResponse() {
  var o = api.ResellernotifyGetwatchdetailsResponse();
  buildCounterResellernotifyGetwatchdetailsResponse++;
  if (buildCounterResellernotifyGetwatchdetailsResponse < 3) {
    o.serviceAccountEmailAddresses = buildUnnamed4216();
    o.topicName = 'foo';
  }
  buildCounterResellernotifyGetwatchdetailsResponse--;
  return o;
}

void checkResellernotifyGetwatchdetailsResponse(
    api.ResellernotifyGetwatchdetailsResponse o) {
  buildCounterResellernotifyGetwatchdetailsResponse++;
  if (buildCounterResellernotifyGetwatchdetailsResponse < 3) {
    checkUnnamed4216(o.serviceAccountEmailAddresses!);
    unittest.expect(
      o.topicName!,
      unittest.equals('foo'),
    );
  }
  buildCounterResellernotifyGetwatchdetailsResponse--;
}

core.int buildCounterResellernotifyResource = 0;
api.ResellernotifyResource buildResellernotifyResource() {
  var o = api.ResellernotifyResource();
  buildCounterResellernotifyResource++;
  if (buildCounterResellernotifyResource < 3) {
    o.topicName = 'foo';
  }
  buildCounterResellernotifyResource--;
  return o;
}

void checkResellernotifyResource(api.ResellernotifyResource o) {
  buildCounterResellernotifyResource++;
  if (buildCounterResellernotifyResource < 3) {
    unittest.expect(
      o.topicName!,
      unittest.equals('foo'),
    );
  }
  buildCounterResellernotifyResource--;
}

core.int buildCounterSeats = 0;
api.Seats buildSeats() {
  var o = api.Seats();
  buildCounterSeats++;
  if (buildCounterSeats < 3) {
    o.kind = 'foo';
    o.licensedNumberOfSeats = 42;
    o.maximumNumberOfSeats = 42;
    o.numberOfSeats = 42;
  }
  buildCounterSeats--;
  return o;
}

void checkSeats(api.Seats o) {
  buildCounterSeats++;
  if (buildCounterSeats < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.licensedNumberOfSeats!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maximumNumberOfSeats!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numberOfSeats!,
      unittest.equals(42),
    );
  }
  buildCounterSeats--;
}

core.int buildCounterSubscriptionPlanCommitmentInterval = 0;
api.SubscriptionPlanCommitmentInterval
    buildSubscriptionPlanCommitmentInterval() {
  var o = api.SubscriptionPlanCommitmentInterval();
  buildCounterSubscriptionPlanCommitmentInterval++;
  if (buildCounterSubscriptionPlanCommitmentInterval < 3) {
    o.endTime = 'foo';
    o.startTime = 'foo';
  }
  buildCounterSubscriptionPlanCommitmentInterval--;
  return o;
}

void checkSubscriptionPlanCommitmentInterval(
    api.SubscriptionPlanCommitmentInterval o) {
  buildCounterSubscriptionPlanCommitmentInterval++;
  if (buildCounterSubscriptionPlanCommitmentInterval < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionPlanCommitmentInterval--;
}

core.int buildCounterSubscriptionPlan = 0;
api.SubscriptionPlan buildSubscriptionPlan() {
  var o = api.SubscriptionPlan();
  buildCounterSubscriptionPlan++;
  if (buildCounterSubscriptionPlan < 3) {
    o.commitmentInterval = buildSubscriptionPlanCommitmentInterval();
    o.isCommitmentPlan = true;
    o.planName = 'foo';
  }
  buildCounterSubscriptionPlan--;
  return o;
}

void checkSubscriptionPlan(api.SubscriptionPlan o) {
  buildCounterSubscriptionPlan++;
  if (buildCounterSubscriptionPlan < 3) {
    checkSubscriptionPlanCommitmentInterval(
        o.commitmentInterval! as api.SubscriptionPlanCommitmentInterval);
    unittest.expect(o.isCommitmentPlan!, unittest.isTrue);
    unittest.expect(
      o.planName!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionPlan--;
}

core.List<core.String> buildUnnamed4217() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4217(core.List<core.String> o) {
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

core.int buildCounterSubscriptionTransferInfo = 0;
api.SubscriptionTransferInfo buildSubscriptionTransferInfo() {
  var o = api.SubscriptionTransferInfo();
  buildCounterSubscriptionTransferInfo++;
  if (buildCounterSubscriptionTransferInfo < 3) {
    o.currentLegacySkuId = 'foo';
    o.minimumTransferableSeats = 42;
    o.transferabilityExpirationTime = 'foo';
  }
  buildCounterSubscriptionTransferInfo--;
  return o;
}

void checkSubscriptionTransferInfo(api.SubscriptionTransferInfo o) {
  buildCounterSubscriptionTransferInfo++;
  if (buildCounterSubscriptionTransferInfo < 3) {
    unittest.expect(
      o.currentLegacySkuId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumTransferableSeats!,
      unittest.equals(42),
    );
    unittest.expect(
      o.transferabilityExpirationTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionTransferInfo--;
}

core.int buildCounterSubscriptionTrialSettings = 0;
api.SubscriptionTrialSettings buildSubscriptionTrialSettings() {
  var o = api.SubscriptionTrialSettings();
  buildCounterSubscriptionTrialSettings++;
  if (buildCounterSubscriptionTrialSettings < 3) {
    o.isInTrial = true;
    o.trialEndTime = 'foo';
  }
  buildCounterSubscriptionTrialSettings--;
  return o;
}

void checkSubscriptionTrialSettings(api.SubscriptionTrialSettings o) {
  buildCounterSubscriptionTrialSettings++;
  if (buildCounterSubscriptionTrialSettings < 3) {
    unittest.expect(o.isInTrial!, unittest.isTrue);
    unittest.expect(
      o.trialEndTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscriptionTrialSettings--;
}

core.int buildCounterSubscription = 0;
api.Subscription buildSubscription() {
  var o = api.Subscription();
  buildCounterSubscription++;
  if (buildCounterSubscription < 3) {
    o.billingMethod = 'foo';
    o.creationTime = 'foo';
    o.customerDomain = 'foo';
    o.customerId = 'foo';
    o.dealCode = 'foo';
    o.kind = 'foo';
    o.plan = buildSubscriptionPlan();
    o.purchaseOrderId = 'foo';
    o.renewalSettings = buildRenewalSettings();
    o.resourceUiUrl = 'foo';
    o.seats = buildSeats();
    o.skuId = 'foo';
    o.skuName = 'foo';
    o.status = 'foo';
    o.subscriptionId = 'foo';
    o.suspensionReasons = buildUnnamed4217();
    o.transferInfo = buildSubscriptionTransferInfo();
    o.trialSettings = buildSubscriptionTrialSettings();
  }
  buildCounterSubscription--;
  return o;
}

void checkSubscription(api.Subscription o) {
  buildCounterSubscription++;
  if (buildCounterSubscription < 3) {
    unittest.expect(
      o.billingMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customerDomain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dealCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkSubscriptionPlan(o.plan! as api.SubscriptionPlan);
    unittest.expect(
      o.purchaseOrderId!,
      unittest.equals('foo'),
    );
    checkRenewalSettings(o.renewalSettings! as api.RenewalSettings);
    unittest.expect(
      o.resourceUiUrl!,
      unittest.equals('foo'),
    );
    checkSeats(o.seats! as api.Seats);
    unittest.expect(
      o.skuId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skuName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subscriptionId!,
      unittest.equals('foo'),
    );
    checkUnnamed4217(o.suspensionReasons!);
    checkSubscriptionTransferInfo(
        o.transferInfo! as api.SubscriptionTransferInfo);
    checkSubscriptionTrialSettings(
        o.trialSettings! as api.SubscriptionTrialSettings);
  }
  buildCounterSubscription--;
}

core.List<api.Subscription> buildUnnamed4218() {
  var o = <api.Subscription>[];
  o.add(buildSubscription());
  o.add(buildSubscription());
  return o;
}

void checkUnnamed4218(core.List<api.Subscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSubscription(o[0] as api.Subscription);
  checkSubscription(o[1] as api.Subscription);
}

core.int buildCounterSubscriptions = 0;
api.Subscriptions buildSubscriptions() {
  var o = api.Subscriptions();
  buildCounterSubscriptions++;
  if (buildCounterSubscriptions < 3) {
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.subscriptions = buildUnnamed4218();
  }
  buildCounterSubscriptions--;
  return o;
}

void checkSubscriptions(api.Subscriptions o) {
  buildCounterSubscriptions++;
  if (buildCounterSubscriptions < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4218(o.subscriptions!);
  }
  buildCounterSubscriptions--;
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

  unittest.group('obj-schema-ChangePlanRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChangePlanRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ChangePlanRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkChangePlanRequest(od as api.ChangePlanRequest);
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

  unittest.group('obj-schema-RenewalSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRenewalSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RenewalSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRenewalSettings(od as api.RenewalSettings);
    });
  });

  unittest.group('obj-schema-ResellernotifyGetwatchdetailsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResellernotifyGetwatchdetailsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResellernotifyGetwatchdetailsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResellernotifyGetwatchdetailsResponse(
          od as api.ResellernotifyGetwatchdetailsResponse);
    });
  });

  unittest.group('obj-schema-ResellernotifyResource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildResellernotifyResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ResellernotifyResource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkResellernotifyResource(od as api.ResellernotifyResource);
    });
  });

  unittest.group('obj-schema-Seats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSeats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Seats.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSeats(od as api.Seats);
    });
  });

  unittest.group('obj-schema-SubscriptionPlanCommitmentInterval', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPlanCommitmentInterval();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPlanCommitmentInterval.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPlanCommitmentInterval(
          od as api.SubscriptionPlanCommitmentInterval);
    });
  });

  unittest.group('obj-schema-SubscriptionPlan', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionPlan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionPlan.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionPlan(od as api.SubscriptionPlan);
    });
  });

  unittest.group('obj-schema-SubscriptionTransferInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionTransferInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionTransferInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionTransferInfo(od as api.SubscriptionTransferInfo);
    });
  });

  unittest.group('obj-schema-SubscriptionTrialSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptionTrialSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SubscriptionTrialSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptionTrialSettings(od as api.SubscriptionTrialSettings);
    });
  });

  unittest.group('obj-schema-Subscription', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Subscription.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscription(od as api.Subscription);
    });
  });

  unittest.group('obj-schema-Subscriptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscriptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Subscriptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscriptions(od as api.Subscriptions);
    });
  });

  unittest.group('resource-CustomersResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).customers;
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
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
      final response = await res.get(arg_customerId, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).customers;
      var arg_request = buildCustomer();
      var arg_customerAuthToken = 'foo';
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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("apps/reseller/v1/customers"),
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
          queryMap["customerAuthToken"]!.first,
          unittest.equals(arg_customerAuthToken),
        );
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
      final response = await res.insert(arg_request,
          customerAuthToken: arg_customerAuthToken, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).customers;
      var arg_request = buildCustomer();
      var arg_customerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
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
          await res.patch(arg_request, arg_customerId, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).customers;
      var arg_request = buildCustomer();
      var arg_customerId = 'foo';
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
          path.substring(pathOffset, pathOffset + 27),
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
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
          await res.update(arg_request, arg_customerId, $fields: arg_$fields);
      checkCustomer(response as api.Customer);
    });
  });

  unittest.group('resource-ResellernotifyResource_1', () {
    unittest.test('method--getwatchdetails', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).resellernotify;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 47),
          unittest.equals("apps/reseller/v1/resellernotify/getwatchdetails"),
        );
        pathOffset += 47;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
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
            convert.json.encode(buildResellernotifyGetwatchdetailsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getwatchdetails($fields: arg_$fields);
      checkResellernotifyGetwatchdetailsResponse(
          response as api.ResellernotifyGetwatchdetailsResponse);
    });

    unittest.test('method--register', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).resellernotify;
      var arg_serviceAccountEmailAddress = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 40),
          unittest.equals("apps/reseller/v1/resellernotify/register"),
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
          queryMap["serviceAccountEmailAddress"]!.first,
          unittest.equals(arg_serviceAccountEmailAddress),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResellernotifyResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.register(
          serviceAccountEmailAddress: arg_serviceAccountEmailAddress,
          $fields: arg_$fields);
      checkResellernotifyResource(response as api.ResellernotifyResource);
    });

    unittest.test('method--unregister', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).resellernotify;
      var arg_serviceAccountEmailAddress = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 42),
          unittest.equals("apps/reseller/v1/resellernotify/unregister"),
        );
        pathOffset += 42;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["serviceAccountEmailAddress"]!.first,
          unittest.equals(arg_serviceAccountEmailAddress),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildResellernotifyResource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.unregister(
          serviceAccountEmailAddress: arg_serviceAccountEmailAddress,
          $fields: arg_$fields);
      checkResellernotifyResource(response as api.ResellernotifyResource);
    });
  });

  unittest.group('resource-SubscriptionsResource', () {
    unittest.test('method--activate', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        index = path.indexOf('/activate', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/activate"),
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.activate(arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--changePlan', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_request = buildChangePlanRequest();
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ChangePlanRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkChangePlanRequest(obj as api.ChangePlanRequest);

        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        index = path.indexOf('/changePlan', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/changePlan"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.changePlan(
          arg_request, arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--changeRenewalSettings', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_request = buildRenewalSettings();
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RenewalSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRenewalSettings(obj as api.RenewalSettings);

        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        index = path.indexOf('/changeRenewalSettings', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("/changeRenewalSettings"),
        );
        pathOffset += 22;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.changeRenewalSettings(
          arg_request, arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--changeSeats', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_request = buildSeats();
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Seats.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSeats(obj as api.Seats);

        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        index = path.indexOf('/changeSeats', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/changeSeats"),
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.changeSeats(
          arg_request, arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_deletionType = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
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
          queryMap["deletionType"]!.first,
          unittest.equals(arg_deletionType),
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
      await res.delete(arg_customerId, arg_subscriptionId, arg_deletionType,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_request = buildSubscription();
      var arg_customerId = 'foo';
      var arg_customerAuthToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Subscription.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSubscription(obj as api.Subscription);

        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_customerId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/subscriptions"),
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
          queryMap["customerAuthToken"]!.first,
          unittest.equals(arg_customerAuthToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_customerId,
          customerAuthToken: arg_customerAuthToken, $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_customerAuthToken = 'foo';
      var arg_customerId = 'foo';
      var arg_customerNamePrefix = 'foo';
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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("apps/reseller/v1/subscriptions"),
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
          queryMap["customerAuthToken"]!.first,
          unittest.equals(arg_customerAuthToken),
        );
        unittest.expect(
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          queryMap["customerNamePrefix"]!.first,
          unittest.equals(arg_customerNamePrefix),
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
        var resp = convert.json.encode(buildSubscriptions());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          customerAuthToken: arg_customerAuthToken,
          customerId: arg_customerId,
          customerNamePrefix: arg_customerNamePrefix,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkSubscriptions(response as api.Subscriptions);
    });

    unittest.test('method--startPaidService', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        index = path.indexOf('/startPaidService', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/startPaidService"),
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.startPaidService(
          arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--suspend', () async {
      var mock = HttpServerMock();
      var res = api.ResellerApi(mock).subscriptions;
      var arg_customerId = 'foo';
      var arg_subscriptionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("apps/reseller/v1/customers/"),
        );
        pathOffset += 27;
        index = path.indexOf('/subscriptions/', pathOffset);
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
          unittest.equals("/subscriptions/"),
        );
        pathOffset += 15;
        index = path.indexOf('/suspend', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_subscriptionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/suspend"),
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.suspend(arg_customerId, arg_subscriptionId,
          $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });
  });
}
