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

import 'package:googleapis/adexchangebuyer/v1_4.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAccountBidderLocation = 0;
api.AccountBidderLocation buildAccountBidderLocation() {
  var o = api.AccountBidderLocation();
  buildCounterAccountBidderLocation++;
  if (buildCounterAccountBidderLocation < 3) {
    o.bidProtocol = 'foo';
    o.maximumQps = 42;
    o.region = 'foo';
    o.url = 'foo';
  }
  buildCounterAccountBidderLocation--;
  return o;
}

void checkAccountBidderLocation(api.AccountBidderLocation o) {
  buildCounterAccountBidderLocation++;
  if (buildCounterAccountBidderLocation < 3) {
    unittest.expect(
      o.bidProtocol!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maximumQps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccountBidderLocation--;
}

core.List<api.AccountBidderLocation> buildUnnamed2536() {
  var o = <api.AccountBidderLocation>[];
  o.add(buildAccountBidderLocation());
  o.add(buildAccountBidderLocation());
  return o;
}

void checkUnnamed2536(core.List<api.AccountBidderLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccountBidderLocation(o[0] as api.AccountBidderLocation);
  checkAccountBidderLocation(o[1] as api.AccountBidderLocation);
}

core.int buildCounterAccount = 0;
api.Account buildAccount() {
  var o = api.Account();
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    o.applyPretargetingToNonGuaranteedDeals = true;
    o.bidderLocation = buildUnnamed2536();
    o.cookieMatchingNid = 'foo';
    o.cookieMatchingUrl = 'foo';
    o.id = 42;
    o.kind = 'foo';
    o.maximumActiveCreatives = 42;
    o.maximumTotalQps = 42;
    o.numberActiveCreatives = 42;
  }
  buildCounterAccount--;
  return o;
}

void checkAccount(api.Account o) {
  buildCounterAccount++;
  if (buildCounterAccount < 3) {
    unittest.expect(o.applyPretargetingToNonGuaranteedDeals!, unittest.isTrue);
    checkUnnamed2536(o.bidderLocation!);
    unittest.expect(
      o.cookieMatchingNid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.cookieMatchingUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals(42),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maximumActiveCreatives!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maximumTotalQps!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numberActiveCreatives!,
      unittest.equals(42),
    );
  }
  buildCounterAccount--;
}

core.List<api.Account> buildUnnamed2537() {
  var o = <api.Account>[];
  o.add(buildAccount());
  o.add(buildAccount());
  return o;
}

void checkUnnamed2537(core.List<api.Account> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAccount(o[0] as api.Account);
  checkAccount(o[1] as api.Account);
}

core.int buildCounterAccountsList = 0;
api.AccountsList buildAccountsList() {
  var o = api.AccountsList();
  buildCounterAccountsList++;
  if (buildCounterAccountsList < 3) {
    o.items = buildUnnamed2537();
    o.kind = 'foo';
  }
  buildCounterAccountsList--;
  return o;
}

void checkAccountsList(api.AccountsList o) {
  buildCounterAccountsList++;
  if (buildCounterAccountsList < 3) {
    checkUnnamed2537(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterAccountsList--;
}

core.List<api.MarketplaceDeal> buildUnnamed2538() {
  var o = <api.MarketplaceDeal>[];
  o.add(buildMarketplaceDeal());
  o.add(buildMarketplaceDeal());
  return o;
}

void checkUnnamed2538(core.List<api.MarketplaceDeal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceDeal(o[0] as api.MarketplaceDeal);
  checkMarketplaceDeal(o[1] as api.MarketplaceDeal);
}

core.int buildCounterAddOrderDealsRequest = 0;
api.AddOrderDealsRequest buildAddOrderDealsRequest() {
  var o = api.AddOrderDealsRequest();
  buildCounterAddOrderDealsRequest++;
  if (buildCounterAddOrderDealsRequest < 3) {
    o.deals = buildUnnamed2538();
    o.proposalRevisionNumber = 'foo';
    o.updateAction = 'foo';
  }
  buildCounterAddOrderDealsRequest--;
  return o;
}

void checkAddOrderDealsRequest(api.AddOrderDealsRequest o) {
  buildCounterAddOrderDealsRequest++;
  if (buildCounterAddOrderDealsRequest < 3) {
    checkUnnamed2538(o.deals!);
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateAction!,
      unittest.equals('foo'),
    );
  }
  buildCounterAddOrderDealsRequest--;
}

core.List<api.MarketplaceDeal> buildUnnamed2539() {
  var o = <api.MarketplaceDeal>[];
  o.add(buildMarketplaceDeal());
  o.add(buildMarketplaceDeal());
  return o;
}

void checkUnnamed2539(core.List<api.MarketplaceDeal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceDeal(o[0] as api.MarketplaceDeal);
  checkMarketplaceDeal(o[1] as api.MarketplaceDeal);
}

core.int buildCounterAddOrderDealsResponse = 0;
api.AddOrderDealsResponse buildAddOrderDealsResponse() {
  var o = api.AddOrderDealsResponse();
  buildCounterAddOrderDealsResponse++;
  if (buildCounterAddOrderDealsResponse < 3) {
    o.deals = buildUnnamed2539();
    o.proposalRevisionNumber = 'foo';
  }
  buildCounterAddOrderDealsResponse--;
  return o;
}

void checkAddOrderDealsResponse(api.AddOrderDealsResponse o) {
  buildCounterAddOrderDealsResponse++;
  if (buildCounterAddOrderDealsResponse < 3) {
    checkUnnamed2539(o.deals!);
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterAddOrderDealsResponse--;
}

core.List<api.MarketplaceNote> buildUnnamed2540() {
  var o = <api.MarketplaceNote>[];
  o.add(buildMarketplaceNote());
  o.add(buildMarketplaceNote());
  return o;
}

void checkUnnamed2540(core.List<api.MarketplaceNote> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceNote(o[0] as api.MarketplaceNote);
  checkMarketplaceNote(o[1] as api.MarketplaceNote);
}

core.int buildCounterAddOrderNotesRequest = 0;
api.AddOrderNotesRequest buildAddOrderNotesRequest() {
  var o = api.AddOrderNotesRequest();
  buildCounterAddOrderNotesRequest++;
  if (buildCounterAddOrderNotesRequest < 3) {
    o.notes = buildUnnamed2540();
  }
  buildCounterAddOrderNotesRequest--;
  return o;
}

void checkAddOrderNotesRequest(api.AddOrderNotesRequest o) {
  buildCounterAddOrderNotesRequest++;
  if (buildCounterAddOrderNotesRequest < 3) {
    checkUnnamed2540(o.notes!);
  }
  buildCounterAddOrderNotesRequest--;
}

core.List<api.MarketplaceNote> buildUnnamed2541() {
  var o = <api.MarketplaceNote>[];
  o.add(buildMarketplaceNote());
  o.add(buildMarketplaceNote());
  return o;
}

void checkUnnamed2541(core.List<api.MarketplaceNote> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceNote(o[0] as api.MarketplaceNote);
  checkMarketplaceNote(o[1] as api.MarketplaceNote);
}

core.int buildCounterAddOrderNotesResponse = 0;
api.AddOrderNotesResponse buildAddOrderNotesResponse() {
  var o = api.AddOrderNotesResponse();
  buildCounterAddOrderNotesResponse++;
  if (buildCounterAddOrderNotesResponse < 3) {
    o.notes = buildUnnamed2541();
  }
  buildCounterAddOrderNotesResponse--;
  return o;
}

void checkAddOrderNotesResponse(api.AddOrderNotesResponse o) {
  buildCounterAddOrderNotesResponse++;
  if (buildCounterAddOrderNotesResponse < 3) {
    checkUnnamed2541(o.notes!);
  }
  buildCounterAddOrderNotesResponse--;
}

core.List<core.String> buildUnnamed2542() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2542(core.List<core.String> o) {
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

core.int buildCounterBillingInfo = 0;
api.BillingInfo buildBillingInfo() {
  var o = api.BillingInfo();
  buildCounterBillingInfo++;
  if (buildCounterBillingInfo < 3) {
    o.accountId = 42;
    o.accountName = 'foo';
    o.billingId = buildUnnamed2542();
    o.kind = 'foo';
  }
  buildCounterBillingInfo--;
  return o;
}

void checkBillingInfo(api.BillingInfo o) {
  buildCounterBillingInfo++;
  if (buildCounterBillingInfo < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.accountName!,
      unittest.equals('foo'),
    );
    checkUnnamed2542(o.billingId!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterBillingInfo--;
}

core.List<api.BillingInfo> buildUnnamed2543() {
  var o = <api.BillingInfo>[];
  o.add(buildBillingInfo());
  o.add(buildBillingInfo());
  return o;
}

void checkUnnamed2543(core.List<api.BillingInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBillingInfo(o[0] as api.BillingInfo);
  checkBillingInfo(o[1] as api.BillingInfo);
}

core.int buildCounterBillingInfoList = 0;
api.BillingInfoList buildBillingInfoList() {
  var o = api.BillingInfoList();
  buildCounterBillingInfoList++;
  if (buildCounterBillingInfoList < 3) {
    o.items = buildUnnamed2543();
    o.kind = 'foo';
  }
  buildCounterBillingInfoList--;
  return o;
}

void checkBillingInfoList(api.BillingInfoList o) {
  buildCounterBillingInfoList++;
  if (buildCounterBillingInfoList < 3) {
    checkUnnamed2543(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterBillingInfoList--;
}

core.int buildCounterBudget = 0;
api.Budget buildBudget() {
  var o = api.Budget();
  buildCounterBudget++;
  if (buildCounterBudget < 3) {
    o.accountId = 'foo';
    o.billingId = 'foo';
    o.budgetAmount = 'foo';
    o.currencyCode = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
  }
  buildCounterBudget--;
  return o;
}

void checkBudget(api.Budget o) {
  buildCounterBudget++;
  if (buildCounterBudget < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.billingId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.budgetAmount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.currencyCode!,
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
  buildCounterBudget--;
}

core.int buildCounterBuyer = 0;
api.Buyer buildBuyer() {
  var o = api.Buyer();
  buildCounterBuyer++;
  if (buildCounterBuyer < 3) {
    o.accountId = 'foo';
  }
  buildCounterBuyer--;
  return o;
}

void checkBuyer(api.Buyer o) {
  buildCounterBuyer++;
  if (buildCounterBuyer < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
  }
  buildCounterBuyer--;
}

core.int buildCounterContactInformation = 0;
api.ContactInformation buildContactInformation() {
  var o = api.ContactInformation();
  buildCounterContactInformation++;
  if (buildCounterContactInformation < 3) {
    o.email = 'foo';
    o.name = 'foo';
  }
  buildCounterContactInformation--;
  return o;
}

void checkContactInformation(api.ContactInformation o) {
  buildCounterContactInformation++;
  if (buildCounterContactInformation < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterContactInformation--;
}

core.List<api.Proposal> buildUnnamed2544() {
  var o = <api.Proposal>[];
  o.add(buildProposal());
  o.add(buildProposal());
  return o;
}

void checkUnnamed2544(core.List<api.Proposal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProposal(o[0] as api.Proposal);
  checkProposal(o[1] as api.Proposal);
}

core.int buildCounterCreateOrdersRequest = 0;
api.CreateOrdersRequest buildCreateOrdersRequest() {
  var o = api.CreateOrdersRequest();
  buildCounterCreateOrdersRequest++;
  if (buildCounterCreateOrdersRequest < 3) {
    o.proposals = buildUnnamed2544();
    o.webPropertyCode = 'foo';
  }
  buildCounterCreateOrdersRequest--;
  return o;
}

void checkCreateOrdersRequest(api.CreateOrdersRequest o) {
  buildCounterCreateOrdersRequest++;
  if (buildCounterCreateOrdersRequest < 3) {
    checkUnnamed2544(o.proposals!);
    unittest.expect(
      o.webPropertyCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateOrdersRequest--;
}

core.List<api.Proposal> buildUnnamed2545() {
  var o = <api.Proposal>[];
  o.add(buildProposal());
  o.add(buildProposal());
  return o;
}

void checkUnnamed2545(core.List<api.Proposal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProposal(o[0] as api.Proposal);
  checkProposal(o[1] as api.Proposal);
}

core.int buildCounterCreateOrdersResponse = 0;
api.CreateOrdersResponse buildCreateOrdersResponse() {
  var o = api.CreateOrdersResponse();
  buildCounterCreateOrdersResponse++;
  if (buildCounterCreateOrdersResponse < 3) {
    o.proposals = buildUnnamed2545();
  }
  buildCounterCreateOrdersResponse--;
  return o;
}

void checkCreateOrdersResponse(api.CreateOrdersResponse o) {
  buildCounterCreateOrdersResponse++;
  if (buildCounterCreateOrdersResponse < 3) {
    checkUnnamed2545(o.proposals!);
  }
  buildCounterCreateOrdersResponse--;
}

core.List<core.String> buildUnnamed2546() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2546(core.List<core.String> o) {
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

core.int buildCounterCreativeAdTechnologyProviders = 0;
api.CreativeAdTechnologyProviders buildCreativeAdTechnologyProviders() {
  var o = api.CreativeAdTechnologyProviders();
  buildCounterCreativeAdTechnologyProviders++;
  if (buildCounterCreativeAdTechnologyProviders < 3) {
    o.detectedProviderIds = buildUnnamed2546();
    o.hasUnidentifiedProvider = true;
  }
  buildCounterCreativeAdTechnologyProviders--;
  return o;
}

void checkCreativeAdTechnologyProviders(api.CreativeAdTechnologyProviders o) {
  buildCounterCreativeAdTechnologyProviders++;
  if (buildCounterCreativeAdTechnologyProviders < 3) {
    checkUnnamed2546(o.detectedProviderIds!);
    unittest.expect(o.hasUnidentifiedProvider!, unittest.isTrue);
  }
  buildCounterCreativeAdTechnologyProviders--;
}

core.List<core.String> buildUnnamed2547() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2547(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed2548() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2548(core.List<core.int> o) {
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

core.List<core.String> buildUnnamed2549() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2549(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2550() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2550(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed2551() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2551(core.List<core.int> o) {
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

core.List<core.String> buildUnnamed2552() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2552(core.List<core.String> o) {
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

core.int buildCounterCreativeCorrectionsContexts = 0;
api.CreativeCorrectionsContexts buildCreativeCorrectionsContexts() {
  var o = api.CreativeCorrectionsContexts();
  buildCounterCreativeCorrectionsContexts++;
  if (buildCounterCreativeCorrectionsContexts < 3) {
    o.auctionType = buildUnnamed2550();
    o.contextType = 'foo';
    o.geoCriteriaId = buildUnnamed2551();
    o.platform = buildUnnamed2552();
  }
  buildCounterCreativeCorrectionsContexts--;
  return o;
}

void checkCreativeCorrectionsContexts(api.CreativeCorrectionsContexts o) {
  buildCounterCreativeCorrectionsContexts++;
  if (buildCounterCreativeCorrectionsContexts < 3) {
    checkUnnamed2550(o.auctionType!);
    unittest.expect(
      o.contextType!,
      unittest.equals('foo'),
    );
    checkUnnamed2551(o.geoCriteriaId!);
    checkUnnamed2552(o.platform!);
  }
  buildCounterCreativeCorrectionsContexts--;
}

core.List<api.CreativeCorrectionsContexts> buildUnnamed2553() {
  var o = <api.CreativeCorrectionsContexts>[];
  o.add(buildCreativeCorrectionsContexts());
  o.add(buildCreativeCorrectionsContexts());
  return o;
}

void checkUnnamed2553(core.List<api.CreativeCorrectionsContexts> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeCorrectionsContexts(o[0] as api.CreativeCorrectionsContexts);
  checkCreativeCorrectionsContexts(o[1] as api.CreativeCorrectionsContexts);
}

core.List<core.String> buildUnnamed2554() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2554(core.List<core.String> o) {
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

core.int buildCounterCreativeCorrections = 0;
api.CreativeCorrections buildCreativeCorrections() {
  var o = api.CreativeCorrections();
  buildCounterCreativeCorrections++;
  if (buildCounterCreativeCorrections < 3) {
    o.contexts = buildUnnamed2553();
    o.details = buildUnnamed2554();
    o.reason = 'foo';
  }
  buildCounterCreativeCorrections--;
  return o;
}

void checkCreativeCorrections(api.CreativeCorrections o) {
  buildCounterCreativeCorrections++;
  if (buildCounterCreativeCorrections < 3) {
    checkUnnamed2553(o.contexts!);
    checkUnnamed2554(o.details!);
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreativeCorrections--;
}

core.List<api.CreativeCorrections> buildUnnamed2555() {
  var o = <api.CreativeCorrections>[];
  o.add(buildCreativeCorrections());
  o.add(buildCreativeCorrections());
  return o;
}

void checkUnnamed2555(core.List<api.CreativeCorrections> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeCorrections(o[0] as api.CreativeCorrections);
  checkCreativeCorrections(o[1] as api.CreativeCorrections);
}

core.List<core.String> buildUnnamed2556() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2556(core.List<core.String> o) {
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

core.int buildCounterCreativeFilteringReasonsReasons = 0;
api.CreativeFilteringReasonsReasons buildCreativeFilteringReasonsReasons() {
  var o = api.CreativeFilteringReasonsReasons();
  buildCounterCreativeFilteringReasonsReasons++;
  if (buildCounterCreativeFilteringReasonsReasons < 3) {
    o.filteringCount = 'foo';
    o.filteringStatus = 42;
  }
  buildCounterCreativeFilteringReasonsReasons--;
  return o;
}

void checkCreativeFilteringReasonsReasons(
    api.CreativeFilteringReasonsReasons o) {
  buildCounterCreativeFilteringReasonsReasons++;
  if (buildCounterCreativeFilteringReasonsReasons < 3) {
    unittest.expect(
      o.filteringCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filteringStatus!,
      unittest.equals(42),
    );
  }
  buildCounterCreativeFilteringReasonsReasons--;
}

core.List<api.CreativeFilteringReasonsReasons> buildUnnamed2557() {
  var o = <api.CreativeFilteringReasonsReasons>[];
  o.add(buildCreativeFilteringReasonsReasons());
  o.add(buildCreativeFilteringReasonsReasons());
  return o;
}

void checkUnnamed2557(core.List<api.CreativeFilteringReasonsReasons> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeFilteringReasonsReasons(
      o[0] as api.CreativeFilteringReasonsReasons);
  checkCreativeFilteringReasonsReasons(
      o[1] as api.CreativeFilteringReasonsReasons);
}

core.int buildCounterCreativeFilteringReasons = 0;
api.CreativeFilteringReasons buildCreativeFilteringReasons() {
  var o = api.CreativeFilteringReasons();
  buildCounterCreativeFilteringReasons++;
  if (buildCounterCreativeFilteringReasons < 3) {
    o.date = 'foo';
    o.reasons = buildUnnamed2557();
  }
  buildCounterCreativeFilteringReasons--;
  return o;
}

void checkCreativeFilteringReasons(api.CreativeFilteringReasons o) {
  buildCounterCreativeFilteringReasons++;
  if (buildCounterCreativeFilteringReasons < 3) {
    unittest.expect(
      o.date!,
      unittest.equals('foo'),
    );
    checkUnnamed2557(o.reasons!);
  }
  buildCounterCreativeFilteringReasons--;
}

core.List<core.String> buildUnnamed2558() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2558(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2559() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2559(core.List<core.String> o) {
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

core.int buildCounterCreativeNativeAdAppIcon = 0;
api.CreativeNativeAdAppIcon buildCreativeNativeAdAppIcon() {
  var o = api.CreativeNativeAdAppIcon();
  buildCounterCreativeNativeAdAppIcon++;
  if (buildCounterCreativeNativeAdAppIcon < 3) {
    o.height = 42;
    o.url = 'foo';
    o.width = 42;
  }
  buildCounterCreativeNativeAdAppIcon--;
  return o;
}

void checkCreativeNativeAdAppIcon(api.CreativeNativeAdAppIcon o) {
  buildCounterCreativeNativeAdAppIcon++;
  if (buildCounterCreativeNativeAdAppIcon < 3) {
    unittest.expect(
      o.height!,
      unittest.equals(42),
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
  buildCounterCreativeNativeAdAppIcon--;
}

core.int buildCounterCreativeNativeAdImage = 0;
api.CreativeNativeAdImage buildCreativeNativeAdImage() {
  var o = api.CreativeNativeAdImage();
  buildCounterCreativeNativeAdImage++;
  if (buildCounterCreativeNativeAdImage < 3) {
    o.height = 42;
    o.url = 'foo';
    o.width = 42;
  }
  buildCounterCreativeNativeAdImage--;
  return o;
}

void checkCreativeNativeAdImage(api.CreativeNativeAdImage o) {
  buildCounterCreativeNativeAdImage++;
  if (buildCounterCreativeNativeAdImage < 3) {
    unittest.expect(
      o.height!,
      unittest.equals(42),
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
  buildCounterCreativeNativeAdImage--;
}

core.List<core.String> buildUnnamed2560() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2560(core.List<core.String> o) {
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

core.int buildCounterCreativeNativeAdLogo = 0;
api.CreativeNativeAdLogo buildCreativeNativeAdLogo() {
  var o = api.CreativeNativeAdLogo();
  buildCounterCreativeNativeAdLogo++;
  if (buildCounterCreativeNativeAdLogo < 3) {
    o.height = 42;
    o.url = 'foo';
    o.width = 42;
  }
  buildCounterCreativeNativeAdLogo--;
  return o;
}

void checkCreativeNativeAdLogo(api.CreativeNativeAdLogo o) {
  buildCounterCreativeNativeAdLogo++;
  if (buildCounterCreativeNativeAdLogo < 3) {
    unittest.expect(
      o.height!,
      unittest.equals(42),
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
  buildCounterCreativeNativeAdLogo--;
}

core.int buildCounterCreativeNativeAd = 0;
api.CreativeNativeAd buildCreativeNativeAd() {
  var o = api.CreativeNativeAd();
  buildCounterCreativeNativeAd++;
  if (buildCounterCreativeNativeAd < 3) {
    o.advertiser = 'foo';
    o.appIcon = buildCreativeNativeAdAppIcon();
    o.body = 'foo';
    o.callToAction = 'foo';
    o.clickLinkUrl = 'foo';
    o.clickTrackingUrl = 'foo';
    o.headline = 'foo';
    o.image = buildCreativeNativeAdImage();
    o.impressionTrackingUrl = buildUnnamed2560();
    o.logo = buildCreativeNativeAdLogo();
    o.price = 'foo';
    o.starRating = 42.0;
    o.videoURL = 'foo';
  }
  buildCounterCreativeNativeAd--;
  return o;
}

void checkCreativeNativeAd(api.CreativeNativeAd o) {
  buildCounterCreativeNativeAd++;
  if (buildCounterCreativeNativeAd < 3) {
    unittest.expect(
      o.advertiser!,
      unittest.equals('foo'),
    );
    checkCreativeNativeAdAppIcon(o.appIcon! as api.CreativeNativeAdAppIcon);
    unittest.expect(
      o.body!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.callToAction!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clickLinkUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clickTrackingUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.headline!,
      unittest.equals('foo'),
    );
    checkCreativeNativeAdImage(o.image! as api.CreativeNativeAdImage);
    checkUnnamed2560(o.impressionTrackingUrl!);
    checkCreativeNativeAdLogo(o.logo! as api.CreativeNativeAdLogo);
    unittest.expect(
      o.price!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.starRating!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.videoURL!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreativeNativeAd--;
}

core.List<core.int> buildUnnamed2561() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2561(core.List<core.int> o) {
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

core.List<core.int> buildUnnamed2562() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2562(core.List<core.int> o) {
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

core.List<core.int> buildUnnamed2563() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2563(core.List<core.int> o) {
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

core.List<core.String> buildUnnamed2564() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2564(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed2565() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2565(core.List<core.int> o) {
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

core.List<core.String> buildUnnamed2566() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2566(core.List<core.String> o) {
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

core.int buildCounterCreativeServingRestrictionsContexts = 0;
api.CreativeServingRestrictionsContexts
    buildCreativeServingRestrictionsContexts() {
  var o = api.CreativeServingRestrictionsContexts();
  buildCounterCreativeServingRestrictionsContexts++;
  if (buildCounterCreativeServingRestrictionsContexts < 3) {
    o.auctionType = buildUnnamed2564();
    o.contextType = 'foo';
    o.geoCriteriaId = buildUnnamed2565();
    o.platform = buildUnnamed2566();
  }
  buildCounterCreativeServingRestrictionsContexts--;
  return o;
}

void checkCreativeServingRestrictionsContexts(
    api.CreativeServingRestrictionsContexts o) {
  buildCounterCreativeServingRestrictionsContexts++;
  if (buildCounterCreativeServingRestrictionsContexts < 3) {
    checkUnnamed2564(o.auctionType!);
    unittest.expect(
      o.contextType!,
      unittest.equals('foo'),
    );
    checkUnnamed2565(o.geoCriteriaId!);
    checkUnnamed2566(o.platform!);
  }
  buildCounterCreativeServingRestrictionsContexts--;
}

core.List<api.CreativeServingRestrictionsContexts> buildUnnamed2567() {
  var o = <api.CreativeServingRestrictionsContexts>[];
  o.add(buildCreativeServingRestrictionsContexts());
  o.add(buildCreativeServingRestrictionsContexts());
  return o;
}

void checkUnnamed2567(core.List<api.CreativeServingRestrictionsContexts> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeServingRestrictionsContexts(
      o[0] as api.CreativeServingRestrictionsContexts);
  checkCreativeServingRestrictionsContexts(
      o[1] as api.CreativeServingRestrictionsContexts);
}

core.List<core.String> buildUnnamed2568() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2568(core.List<core.String> o) {
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

core.int buildCounterCreativeServingRestrictionsDisapprovalReasons = 0;
api.CreativeServingRestrictionsDisapprovalReasons
    buildCreativeServingRestrictionsDisapprovalReasons() {
  var o = api.CreativeServingRestrictionsDisapprovalReasons();
  buildCounterCreativeServingRestrictionsDisapprovalReasons++;
  if (buildCounterCreativeServingRestrictionsDisapprovalReasons < 3) {
    o.details = buildUnnamed2568();
    o.reason = 'foo';
  }
  buildCounterCreativeServingRestrictionsDisapprovalReasons--;
  return o;
}

void checkCreativeServingRestrictionsDisapprovalReasons(
    api.CreativeServingRestrictionsDisapprovalReasons o) {
  buildCounterCreativeServingRestrictionsDisapprovalReasons++;
  if (buildCounterCreativeServingRestrictionsDisapprovalReasons < 3) {
    checkUnnamed2568(o.details!);
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreativeServingRestrictionsDisapprovalReasons--;
}

core.List<api.CreativeServingRestrictionsDisapprovalReasons>
    buildUnnamed2569() {
  var o = <api.CreativeServingRestrictionsDisapprovalReasons>[];
  o.add(buildCreativeServingRestrictionsDisapprovalReasons());
  o.add(buildCreativeServingRestrictionsDisapprovalReasons());
  return o;
}

void checkUnnamed2569(
    core.List<api.CreativeServingRestrictionsDisapprovalReasons> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeServingRestrictionsDisapprovalReasons(
      o[0] as api.CreativeServingRestrictionsDisapprovalReasons);
  checkCreativeServingRestrictionsDisapprovalReasons(
      o[1] as api.CreativeServingRestrictionsDisapprovalReasons);
}

core.int buildCounterCreativeServingRestrictions = 0;
api.CreativeServingRestrictions buildCreativeServingRestrictions() {
  var o = api.CreativeServingRestrictions();
  buildCounterCreativeServingRestrictions++;
  if (buildCounterCreativeServingRestrictions < 3) {
    o.contexts = buildUnnamed2567();
    o.disapprovalReasons = buildUnnamed2569();
    o.reason = 'foo';
  }
  buildCounterCreativeServingRestrictions--;
  return o;
}

void checkCreativeServingRestrictions(api.CreativeServingRestrictions o) {
  buildCounterCreativeServingRestrictions++;
  if (buildCounterCreativeServingRestrictions < 3) {
    checkUnnamed2567(o.contexts!);
    checkUnnamed2569(o.disapprovalReasons!);
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreativeServingRestrictions--;
}

core.List<api.CreativeServingRestrictions> buildUnnamed2570() {
  var o = <api.CreativeServingRestrictions>[];
  o.add(buildCreativeServingRestrictions());
  o.add(buildCreativeServingRestrictions());
  return o;
}

void checkUnnamed2570(core.List<api.CreativeServingRestrictions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeServingRestrictions(o[0] as api.CreativeServingRestrictions);
  checkCreativeServingRestrictions(o[1] as api.CreativeServingRestrictions);
}

core.List<core.int> buildUnnamed2571() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2571(core.List<core.int> o) {
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

core.int buildCounterCreative = 0;
api.Creative buildCreative() {
  var o = api.Creative();
  buildCounterCreative++;
  if (buildCounterCreative < 3) {
    o.HTMLSnippet = 'foo';
    o.accountId = 42;
    o.adChoicesDestinationUrl = 'foo';
    o.adTechnologyProviders = buildCreativeAdTechnologyProviders();
    o.advertiserId = buildUnnamed2547();
    o.advertiserName = 'foo';
    o.agencyId = 'foo';
    o.apiUploadTimestamp = core.DateTime.parse("2002-02-27T14:01:02");
    o.attribute = buildUnnamed2548();
    o.buyerCreativeId = 'foo';
    o.clickThroughUrl = buildUnnamed2549();
    o.corrections = buildUnnamed2555();
    o.creativeStatusIdentityType = 'foo';
    o.dealsStatus = 'foo';
    o.detectedDomains = buildUnnamed2556();
    o.filteringReasons = buildCreativeFilteringReasons();
    o.height = 42;
    o.impressionTrackingUrl = buildUnnamed2558();
    o.kind = 'foo';
    o.languages = buildUnnamed2559();
    o.nativeAd = buildCreativeNativeAd();
    o.openAuctionStatus = 'foo';
    o.productCategories = buildUnnamed2561();
    o.restrictedCategories = buildUnnamed2562();
    o.sensitiveCategories = buildUnnamed2563();
    o.servingRestrictions = buildUnnamed2570();
    o.vendorType = buildUnnamed2571();
    o.version = 42;
    o.videoURL = 'foo';
    o.videoVastXML = 'foo';
    o.width = 42;
  }
  buildCounterCreative--;
  return o;
}

void checkCreative(api.Creative o) {
  buildCounterCreative++;
  if (buildCounterCreative < 3) {
    unittest.expect(
      o.HTMLSnippet!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.accountId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.adChoicesDestinationUrl!,
      unittest.equals('foo'),
    );
    checkCreativeAdTechnologyProviders(
        o.adTechnologyProviders! as api.CreativeAdTechnologyProviders);
    checkUnnamed2547(o.advertiserId!);
    unittest.expect(
      o.advertiserName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.agencyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.apiUploadTimestamp!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    checkUnnamed2548(o.attribute!);
    unittest.expect(
      o.buyerCreativeId!,
      unittest.equals('foo'),
    );
    checkUnnamed2549(o.clickThroughUrl!);
    checkUnnamed2555(o.corrections!);
    unittest.expect(
      o.creativeStatusIdentityType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dealsStatus!,
      unittest.equals('foo'),
    );
    checkUnnamed2556(o.detectedDomains!);
    checkCreativeFilteringReasons(
        o.filteringReasons! as api.CreativeFilteringReasons);
    unittest.expect(
      o.height!,
      unittest.equals(42),
    );
    checkUnnamed2558(o.impressionTrackingUrl!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2559(o.languages!);
    checkCreativeNativeAd(o.nativeAd! as api.CreativeNativeAd);
    unittest.expect(
      o.openAuctionStatus!,
      unittest.equals('foo'),
    );
    checkUnnamed2561(o.productCategories!);
    checkUnnamed2562(o.restrictedCategories!);
    checkUnnamed2563(o.sensitiveCategories!);
    checkUnnamed2570(o.servingRestrictions!);
    checkUnnamed2571(o.vendorType!);
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
    unittest.expect(
      o.videoURL!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.videoVastXML!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterCreative--;
}

core.int buildCounterCreativeDealIdsDealStatuses = 0;
api.CreativeDealIdsDealStatuses buildCreativeDealIdsDealStatuses() {
  var o = api.CreativeDealIdsDealStatuses();
  buildCounterCreativeDealIdsDealStatuses++;
  if (buildCounterCreativeDealIdsDealStatuses < 3) {
    o.arcStatus = 'foo';
    o.dealId = 'foo';
    o.webPropertyId = 42;
  }
  buildCounterCreativeDealIdsDealStatuses--;
  return o;
}

void checkCreativeDealIdsDealStatuses(api.CreativeDealIdsDealStatuses o) {
  buildCounterCreativeDealIdsDealStatuses++;
  if (buildCounterCreativeDealIdsDealStatuses < 3) {
    unittest.expect(
      o.arcStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dealId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.webPropertyId!,
      unittest.equals(42),
    );
  }
  buildCounterCreativeDealIdsDealStatuses--;
}

core.List<api.CreativeDealIdsDealStatuses> buildUnnamed2572() {
  var o = <api.CreativeDealIdsDealStatuses>[];
  o.add(buildCreativeDealIdsDealStatuses());
  o.add(buildCreativeDealIdsDealStatuses());
  return o;
}

void checkUnnamed2572(core.List<api.CreativeDealIdsDealStatuses> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreativeDealIdsDealStatuses(o[0] as api.CreativeDealIdsDealStatuses);
  checkCreativeDealIdsDealStatuses(o[1] as api.CreativeDealIdsDealStatuses);
}

core.int buildCounterCreativeDealIds = 0;
api.CreativeDealIds buildCreativeDealIds() {
  var o = api.CreativeDealIds();
  buildCounterCreativeDealIds++;
  if (buildCounterCreativeDealIds < 3) {
    o.dealStatuses = buildUnnamed2572();
    o.kind = 'foo';
  }
  buildCounterCreativeDealIds--;
  return o;
}

void checkCreativeDealIds(api.CreativeDealIds o) {
  buildCounterCreativeDealIds++;
  if (buildCounterCreativeDealIds < 3) {
    checkUnnamed2572(o.dealStatuses!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreativeDealIds--;
}

core.List<api.Creative> buildUnnamed2573() {
  var o = <api.Creative>[];
  o.add(buildCreative());
  o.add(buildCreative());
  return o;
}

void checkUnnamed2573(core.List<api.Creative> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCreative(o[0] as api.Creative);
  checkCreative(o[1] as api.Creative);
}

core.int buildCounterCreativesList = 0;
api.CreativesList buildCreativesList() {
  var o = api.CreativesList();
  buildCounterCreativesList++;
  if (buildCounterCreativesList < 3) {
    o.items = buildUnnamed2573();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterCreativesList--;
  return o;
}

void checkCreativesList(api.CreativesList o) {
  buildCounterCreativesList++;
  if (buildCounterCreativesList < 3) {
    checkUnnamed2573(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreativesList--;
}

core.int buildCounterDealServingMetadata = 0;
api.DealServingMetadata buildDealServingMetadata() {
  var o = api.DealServingMetadata();
  buildCounterDealServingMetadata++;
  if (buildCounterDealServingMetadata < 3) {
    o.alcoholAdsAllowed = true;
    o.dealPauseStatus = buildDealServingMetadataDealPauseStatus();
  }
  buildCounterDealServingMetadata--;
  return o;
}

void checkDealServingMetadata(api.DealServingMetadata o) {
  buildCounterDealServingMetadata++;
  if (buildCounterDealServingMetadata < 3) {
    unittest.expect(o.alcoholAdsAllowed!, unittest.isTrue);
    checkDealServingMetadataDealPauseStatus(
        o.dealPauseStatus! as api.DealServingMetadataDealPauseStatus);
  }
  buildCounterDealServingMetadata--;
}

core.int buildCounterDealServingMetadataDealPauseStatus = 0;
api.DealServingMetadataDealPauseStatus
    buildDealServingMetadataDealPauseStatus() {
  var o = api.DealServingMetadataDealPauseStatus();
  buildCounterDealServingMetadataDealPauseStatus++;
  if (buildCounterDealServingMetadataDealPauseStatus < 3) {
    o.buyerPauseReason = 'foo';
    o.firstPausedBy = 'foo';
    o.hasBuyerPaused = true;
    o.hasSellerPaused = true;
    o.sellerPauseReason = 'foo';
  }
  buildCounterDealServingMetadataDealPauseStatus--;
  return o;
}

void checkDealServingMetadataDealPauseStatus(
    api.DealServingMetadataDealPauseStatus o) {
  buildCounterDealServingMetadataDealPauseStatus++;
  if (buildCounterDealServingMetadataDealPauseStatus < 3) {
    unittest.expect(
      o.buyerPauseReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.firstPausedBy!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hasBuyerPaused!, unittest.isTrue);
    unittest.expect(o.hasSellerPaused!, unittest.isTrue);
    unittest.expect(
      o.sellerPauseReason!,
      unittest.equals('foo'),
    );
  }
  buildCounterDealServingMetadataDealPauseStatus--;
}

core.int buildCounterDealTerms = 0;
api.DealTerms buildDealTerms() {
  var o = api.DealTerms();
  buildCounterDealTerms++;
  if (buildCounterDealTerms < 3) {
    o.brandingType = 'foo';
    o.crossListedExternalDealIdType = 'foo';
    o.description = 'foo';
    o.estimatedGrossSpend = buildPrice();
    o.estimatedImpressionsPerDay = 'foo';
    o.guaranteedFixedPriceTerms = buildDealTermsGuaranteedFixedPriceTerms();
    o.nonGuaranteedAuctionTerms = buildDealTermsNonGuaranteedAuctionTerms();
    o.nonGuaranteedFixedPriceTerms =
        buildDealTermsNonGuaranteedFixedPriceTerms();
    o.rubiconNonGuaranteedTerms = buildDealTermsRubiconNonGuaranteedTerms();
    o.sellerTimeZone = 'foo';
  }
  buildCounterDealTerms--;
  return o;
}

void checkDealTerms(api.DealTerms o) {
  buildCounterDealTerms++;
  if (buildCounterDealTerms < 3) {
    unittest.expect(
      o.brandingType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.crossListedExternalDealIdType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkPrice(o.estimatedGrossSpend! as api.Price);
    unittest.expect(
      o.estimatedImpressionsPerDay!,
      unittest.equals('foo'),
    );
    checkDealTermsGuaranteedFixedPriceTerms(
        o.guaranteedFixedPriceTerms! as api.DealTermsGuaranteedFixedPriceTerms);
    checkDealTermsNonGuaranteedAuctionTerms(
        o.nonGuaranteedAuctionTerms! as api.DealTermsNonGuaranteedAuctionTerms);
    checkDealTermsNonGuaranteedFixedPriceTerms(o.nonGuaranteedFixedPriceTerms!
        as api.DealTermsNonGuaranteedFixedPriceTerms);
    checkDealTermsRubiconNonGuaranteedTerms(
        o.rubiconNonGuaranteedTerms! as api.DealTermsRubiconNonGuaranteedTerms);
    unittest.expect(
      o.sellerTimeZone!,
      unittest.equals('foo'),
    );
  }
  buildCounterDealTerms--;
}

core.List<api.PricePerBuyer> buildUnnamed2574() {
  var o = <api.PricePerBuyer>[];
  o.add(buildPricePerBuyer());
  o.add(buildPricePerBuyer());
  return o;
}

void checkUnnamed2574(core.List<api.PricePerBuyer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPricePerBuyer(o[0] as api.PricePerBuyer);
  checkPricePerBuyer(o[1] as api.PricePerBuyer);
}

core.int buildCounterDealTermsGuaranteedFixedPriceTerms = 0;
api.DealTermsGuaranteedFixedPriceTerms
    buildDealTermsGuaranteedFixedPriceTerms() {
  var o = api.DealTermsGuaranteedFixedPriceTerms();
  buildCounterDealTermsGuaranteedFixedPriceTerms++;
  if (buildCounterDealTermsGuaranteedFixedPriceTerms < 3) {
    o.billingInfo = buildDealTermsGuaranteedFixedPriceTermsBillingInfo();
    o.fixedPrices = buildUnnamed2574();
    o.guaranteedImpressions = 'foo';
    o.guaranteedLooks = 'foo';
    o.minimumDailyLooks = 'foo';
  }
  buildCounterDealTermsGuaranteedFixedPriceTerms--;
  return o;
}

void checkDealTermsGuaranteedFixedPriceTerms(
    api.DealTermsGuaranteedFixedPriceTerms o) {
  buildCounterDealTermsGuaranteedFixedPriceTerms++;
  if (buildCounterDealTermsGuaranteedFixedPriceTerms < 3) {
    checkDealTermsGuaranteedFixedPriceTermsBillingInfo(
        o.billingInfo! as api.DealTermsGuaranteedFixedPriceTermsBillingInfo);
    checkUnnamed2574(o.fixedPrices!);
    unittest.expect(
      o.guaranteedImpressions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.guaranteedLooks!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumDailyLooks!,
      unittest.equals('foo'),
    );
  }
  buildCounterDealTermsGuaranteedFixedPriceTerms--;
}

core.int buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo = 0;
api.DealTermsGuaranteedFixedPriceTermsBillingInfo
    buildDealTermsGuaranteedFixedPriceTermsBillingInfo() {
  var o = api.DealTermsGuaranteedFixedPriceTermsBillingInfo();
  buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo++;
  if (buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo < 3) {
    o.currencyConversionTimeMs = 'foo';
    o.dfpLineItemId = 'foo';
    o.originalContractedQuantity = 'foo';
    o.price = buildPrice();
  }
  buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo--;
  return o;
}

void checkDealTermsGuaranteedFixedPriceTermsBillingInfo(
    api.DealTermsGuaranteedFixedPriceTermsBillingInfo o) {
  buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo++;
  if (buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo < 3) {
    unittest.expect(
      o.currencyConversionTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dfpLineItemId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originalContractedQuantity!,
      unittest.equals('foo'),
    );
    checkPrice(o.price! as api.Price);
  }
  buildCounterDealTermsGuaranteedFixedPriceTermsBillingInfo--;
}

core.List<api.PricePerBuyer> buildUnnamed2575() {
  var o = <api.PricePerBuyer>[];
  o.add(buildPricePerBuyer());
  o.add(buildPricePerBuyer());
  return o;
}

void checkUnnamed2575(core.List<api.PricePerBuyer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPricePerBuyer(o[0] as api.PricePerBuyer);
  checkPricePerBuyer(o[1] as api.PricePerBuyer);
}

core.int buildCounterDealTermsNonGuaranteedAuctionTerms = 0;
api.DealTermsNonGuaranteedAuctionTerms
    buildDealTermsNonGuaranteedAuctionTerms() {
  var o = api.DealTermsNonGuaranteedAuctionTerms();
  buildCounterDealTermsNonGuaranteedAuctionTerms++;
  if (buildCounterDealTermsNonGuaranteedAuctionTerms < 3) {
    o.autoOptimizePrivateAuction = true;
    o.reservePricePerBuyers = buildUnnamed2575();
  }
  buildCounterDealTermsNonGuaranteedAuctionTerms--;
  return o;
}

void checkDealTermsNonGuaranteedAuctionTerms(
    api.DealTermsNonGuaranteedAuctionTerms o) {
  buildCounterDealTermsNonGuaranteedAuctionTerms++;
  if (buildCounterDealTermsNonGuaranteedAuctionTerms < 3) {
    unittest.expect(o.autoOptimizePrivateAuction!, unittest.isTrue);
    checkUnnamed2575(o.reservePricePerBuyers!);
  }
  buildCounterDealTermsNonGuaranteedAuctionTerms--;
}

core.List<api.PricePerBuyer> buildUnnamed2576() {
  var o = <api.PricePerBuyer>[];
  o.add(buildPricePerBuyer());
  o.add(buildPricePerBuyer());
  return o;
}

void checkUnnamed2576(core.List<api.PricePerBuyer> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPricePerBuyer(o[0] as api.PricePerBuyer);
  checkPricePerBuyer(o[1] as api.PricePerBuyer);
}

core.int buildCounterDealTermsNonGuaranteedFixedPriceTerms = 0;
api.DealTermsNonGuaranteedFixedPriceTerms
    buildDealTermsNonGuaranteedFixedPriceTerms() {
  var o = api.DealTermsNonGuaranteedFixedPriceTerms();
  buildCounterDealTermsNonGuaranteedFixedPriceTerms++;
  if (buildCounterDealTermsNonGuaranteedFixedPriceTerms < 3) {
    o.fixedPrices = buildUnnamed2576();
  }
  buildCounterDealTermsNonGuaranteedFixedPriceTerms--;
  return o;
}

void checkDealTermsNonGuaranteedFixedPriceTerms(
    api.DealTermsNonGuaranteedFixedPriceTerms o) {
  buildCounterDealTermsNonGuaranteedFixedPriceTerms++;
  if (buildCounterDealTermsNonGuaranteedFixedPriceTerms < 3) {
    checkUnnamed2576(o.fixedPrices!);
  }
  buildCounterDealTermsNonGuaranteedFixedPriceTerms--;
}

core.int buildCounterDealTermsRubiconNonGuaranteedTerms = 0;
api.DealTermsRubiconNonGuaranteedTerms
    buildDealTermsRubiconNonGuaranteedTerms() {
  var o = api.DealTermsRubiconNonGuaranteedTerms();
  buildCounterDealTermsRubiconNonGuaranteedTerms++;
  if (buildCounterDealTermsRubiconNonGuaranteedTerms < 3) {
    o.priorityPrice = buildPrice();
    o.standardPrice = buildPrice();
  }
  buildCounterDealTermsRubiconNonGuaranteedTerms--;
  return o;
}

void checkDealTermsRubiconNonGuaranteedTerms(
    api.DealTermsRubiconNonGuaranteedTerms o) {
  buildCounterDealTermsRubiconNonGuaranteedTerms++;
  if (buildCounterDealTermsRubiconNonGuaranteedTerms < 3) {
    checkPrice(o.priorityPrice! as api.Price);
    checkPrice(o.standardPrice! as api.Price);
  }
  buildCounterDealTermsRubiconNonGuaranteedTerms--;
}

core.List<core.String> buildUnnamed2577() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2577(core.List<core.String> o) {
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

core.int buildCounterDeleteOrderDealsRequest = 0;
api.DeleteOrderDealsRequest buildDeleteOrderDealsRequest() {
  var o = api.DeleteOrderDealsRequest();
  buildCounterDeleteOrderDealsRequest++;
  if (buildCounterDeleteOrderDealsRequest < 3) {
    o.dealIds = buildUnnamed2577();
    o.proposalRevisionNumber = 'foo';
    o.updateAction = 'foo';
  }
  buildCounterDeleteOrderDealsRequest--;
  return o;
}

void checkDeleteOrderDealsRequest(api.DeleteOrderDealsRequest o) {
  buildCounterDeleteOrderDealsRequest++;
  if (buildCounterDeleteOrderDealsRequest < 3) {
    checkUnnamed2577(o.dealIds!);
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateAction!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteOrderDealsRequest--;
}

core.List<api.MarketplaceDeal> buildUnnamed2578() {
  var o = <api.MarketplaceDeal>[];
  o.add(buildMarketplaceDeal());
  o.add(buildMarketplaceDeal());
  return o;
}

void checkUnnamed2578(core.List<api.MarketplaceDeal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceDeal(o[0] as api.MarketplaceDeal);
  checkMarketplaceDeal(o[1] as api.MarketplaceDeal);
}

core.int buildCounterDeleteOrderDealsResponse = 0;
api.DeleteOrderDealsResponse buildDeleteOrderDealsResponse() {
  var o = api.DeleteOrderDealsResponse();
  buildCounterDeleteOrderDealsResponse++;
  if (buildCounterDeleteOrderDealsResponse < 3) {
    o.deals = buildUnnamed2578();
    o.proposalRevisionNumber = 'foo';
  }
  buildCounterDeleteOrderDealsResponse--;
  return o;
}

void checkDeleteOrderDealsResponse(api.DeleteOrderDealsResponse o) {
  buildCounterDeleteOrderDealsResponse++;
  if (buildCounterDeleteOrderDealsResponse < 3) {
    checkUnnamed2578(o.deals!);
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeleteOrderDealsResponse--;
}

core.List<api.DeliveryControlFrequencyCap> buildUnnamed2579() {
  var o = <api.DeliveryControlFrequencyCap>[];
  o.add(buildDeliveryControlFrequencyCap());
  o.add(buildDeliveryControlFrequencyCap());
  return o;
}

void checkUnnamed2579(core.List<api.DeliveryControlFrequencyCap> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeliveryControlFrequencyCap(o[0] as api.DeliveryControlFrequencyCap);
  checkDeliveryControlFrequencyCap(o[1] as api.DeliveryControlFrequencyCap);
}

core.int buildCounterDeliveryControl = 0;
api.DeliveryControl buildDeliveryControl() {
  var o = api.DeliveryControl();
  buildCounterDeliveryControl++;
  if (buildCounterDeliveryControl < 3) {
    o.creativeBlockingLevel = 'foo';
    o.deliveryRateType = 'foo';
    o.frequencyCaps = buildUnnamed2579();
  }
  buildCounterDeliveryControl--;
  return o;
}

void checkDeliveryControl(api.DeliveryControl o) {
  buildCounterDeliveryControl++;
  if (buildCounterDeliveryControl < 3) {
    unittest.expect(
      o.creativeBlockingLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deliveryRateType!,
      unittest.equals('foo'),
    );
    checkUnnamed2579(o.frequencyCaps!);
  }
  buildCounterDeliveryControl--;
}

core.int buildCounterDeliveryControlFrequencyCap = 0;
api.DeliveryControlFrequencyCap buildDeliveryControlFrequencyCap() {
  var o = api.DeliveryControlFrequencyCap();
  buildCounterDeliveryControlFrequencyCap++;
  if (buildCounterDeliveryControlFrequencyCap < 3) {
    o.maxImpressions = 42;
    o.numTimeUnits = 42;
    o.timeUnitType = 'foo';
  }
  buildCounterDeliveryControlFrequencyCap--;
  return o;
}

void checkDeliveryControlFrequencyCap(api.DeliveryControlFrequencyCap o) {
  buildCounterDeliveryControlFrequencyCap++;
  if (buildCounterDeliveryControlFrequencyCap < 3) {
    unittest.expect(
      o.maxImpressions!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numTimeUnits!,
      unittest.equals(42),
    );
    unittest.expect(
      o.timeUnitType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeliveryControlFrequencyCap--;
}

core.List<api.DimensionDimensionValue> buildUnnamed2580() {
  var o = <api.DimensionDimensionValue>[];
  o.add(buildDimensionDimensionValue());
  o.add(buildDimensionDimensionValue());
  return o;
}

void checkUnnamed2580(core.List<api.DimensionDimensionValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimensionDimensionValue(o[0] as api.DimensionDimensionValue);
  checkDimensionDimensionValue(o[1] as api.DimensionDimensionValue);
}

core.int buildCounterDimension = 0;
api.Dimension buildDimension() {
  var o = api.Dimension();
  buildCounterDimension++;
  if (buildCounterDimension < 3) {
    o.dimensionType = 'foo';
    o.dimensionValues = buildUnnamed2580();
  }
  buildCounterDimension--;
  return o;
}

void checkDimension(api.Dimension o) {
  buildCounterDimension++;
  if (buildCounterDimension < 3) {
    unittest.expect(
      o.dimensionType!,
      unittest.equals('foo'),
    );
    checkUnnamed2580(o.dimensionValues!);
  }
  buildCounterDimension--;
}

core.int buildCounterDimensionDimensionValue = 0;
api.DimensionDimensionValue buildDimensionDimensionValue() {
  var o = api.DimensionDimensionValue();
  buildCounterDimensionDimensionValue++;
  if (buildCounterDimensionDimensionValue < 3) {
    o.id = 42;
    o.name = 'foo';
    o.percentage = 42;
  }
  buildCounterDimensionDimensionValue--;
  return o;
}

void checkDimensionDimensionValue(api.DimensionDimensionValue o) {
  buildCounterDimensionDimensionValue++;
  if (buildCounterDimensionDimensionValue < 3) {
    unittest.expect(
      o.id!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.percentage!,
      unittest.equals(42),
    );
  }
  buildCounterDimensionDimensionValue--;
}

core.List<api.MarketplaceDeal> buildUnnamed2581() {
  var o = <api.MarketplaceDeal>[];
  o.add(buildMarketplaceDeal());
  o.add(buildMarketplaceDeal());
  return o;
}

void checkUnnamed2581(core.List<api.MarketplaceDeal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceDeal(o[0] as api.MarketplaceDeal);
  checkMarketplaceDeal(o[1] as api.MarketplaceDeal);
}

core.int buildCounterEditAllOrderDealsRequest = 0;
api.EditAllOrderDealsRequest buildEditAllOrderDealsRequest() {
  var o = api.EditAllOrderDealsRequest();
  buildCounterEditAllOrderDealsRequest++;
  if (buildCounterEditAllOrderDealsRequest < 3) {
    o.deals = buildUnnamed2581();
    o.proposal = buildProposal();
    o.proposalRevisionNumber = 'foo';
    o.updateAction = 'foo';
  }
  buildCounterEditAllOrderDealsRequest--;
  return o;
}

void checkEditAllOrderDealsRequest(api.EditAllOrderDealsRequest o) {
  buildCounterEditAllOrderDealsRequest++;
  if (buildCounterEditAllOrderDealsRequest < 3) {
    checkUnnamed2581(o.deals!);
    checkProposal(o.proposal! as api.Proposal);
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateAction!,
      unittest.equals('foo'),
    );
  }
  buildCounterEditAllOrderDealsRequest--;
}

core.List<api.MarketplaceDeal> buildUnnamed2582() {
  var o = <api.MarketplaceDeal>[];
  o.add(buildMarketplaceDeal());
  o.add(buildMarketplaceDeal());
  return o;
}

void checkUnnamed2582(core.List<api.MarketplaceDeal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceDeal(o[0] as api.MarketplaceDeal);
  checkMarketplaceDeal(o[1] as api.MarketplaceDeal);
}

core.int buildCounterEditAllOrderDealsResponse = 0;
api.EditAllOrderDealsResponse buildEditAllOrderDealsResponse() {
  var o = api.EditAllOrderDealsResponse();
  buildCounterEditAllOrderDealsResponse++;
  if (buildCounterEditAllOrderDealsResponse < 3) {
    o.deals = buildUnnamed2582();
    o.orderRevisionNumber = 'foo';
  }
  buildCounterEditAllOrderDealsResponse--;
  return o;
}

void checkEditAllOrderDealsResponse(api.EditAllOrderDealsResponse o) {
  buildCounterEditAllOrderDealsResponse++;
  if (buildCounterEditAllOrderDealsResponse < 3) {
    checkUnnamed2582(o.deals!);
    unittest.expect(
      o.orderRevisionNumber!,
      unittest.equals('foo'),
    );
  }
  buildCounterEditAllOrderDealsResponse--;
}

core.List<api.Product> buildUnnamed2583() {
  var o = <api.Product>[];
  o.add(buildProduct());
  o.add(buildProduct());
  return o;
}

void checkUnnamed2583(core.List<api.Product> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProduct(o[0] as api.Product);
  checkProduct(o[1] as api.Product);
}

core.int buildCounterGetOffersResponse = 0;
api.GetOffersResponse buildGetOffersResponse() {
  var o = api.GetOffersResponse();
  buildCounterGetOffersResponse++;
  if (buildCounterGetOffersResponse < 3) {
    o.products = buildUnnamed2583();
  }
  buildCounterGetOffersResponse--;
  return o;
}

void checkGetOffersResponse(api.GetOffersResponse o) {
  buildCounterGetOffersResponse++;
  if (buildCounterGetOffersResponse < 3) {
    checkUnnamed2583(o.products!);
  }
  buildCounterGetOffersResponse--;
}

core.List<api.MarketplaceDeal> buildUnnamed2584() {
  var o = <api.MarketplaceDeal>[];
  o.add(buildMarketplaceDeal());
  o.add(buildMarketplaceDeal());
  return o;
}

void checkUnnamed2584(core.List<api.MarketplaceDeal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceDeal(o[0] as api.MarketplaceDeal);
  checkMarketplaceDeal(o[1] as api.MarketplaceDeal);
}

core.int buildCounterGetOrderDealsResponse = 0;
api.GetOrderDealsResponse buildGetOrderDealsResponse() {
  var o = api.GetOrderDealsResponse();
  buildCounterGetOrderDealsResponse++;
  if (buildCounterGetOrderDealsResponse < 3) {
    o.deals = buildUnnamed2584();
  }
  buildCounterGetOrderDealsResponse--;
  return o;
}

void checkGetOrderDealsResponse(api.GetOrderDealsResponse o) {
  buildCounterGetOrderDealsResponse++;
  if (buildCounterGetOrderDealsResponse < 3) {
    checkUnnamed2584(o.deals!);
  }
  buildCounterGetOrderDealsResponse--;
}

core.List<api.MarketplaceNote> buildUnnamed2585() {
  var o = <api.MarketplaceNote>[];
  o.add(buildMarketplaceNote());
  o.add(buildMarketplaceNote());
  return o;
}

void checkUnnamed2585(core.List<api.MarketplaceNote> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceNote(o[0] as api.MarketplaceNote);
  checkMarketplaceNote(o[1] as api.MarketplaceNote);
}

core.int buildCounterGetOrderNotesResponse = 0;
api.GetOrderNotesResponse buildGetOrderNotesResponse() {
  var o = api.GetOrderNotesResponse();
  buildCounterGetOrderNotesResponse++;
  if (buildCounterGetOrderNotesResponse < 3) {
    o.notes = buildUnnamed2585();
  }
  buildCounterGetOrderNotesResponse--;
  return o;
}

void checkGetOrderNotesResponse(api.GetOrderNotesResponse o) {
  buildCounterGetOrderNotesResponse++;
  if (buildCounterGetOrderNotesResponse < 3) {
    checkUnnamed2585(o.notes!);
  }
  buildCounterGetOrderNotesResponse--;
}

core.List<api.Proposal> buildUnnamed2586() {
  var o = <api.Proposal>[];
  o.add(buildProposal());
  o.add(buildProposal());
  return o;
}

void checkUnnamed2586(core.List<api.Proposal> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProposal(o[0] as api.Proposal);
  checkProposal(o[1] as api.Proposal);
}

core.int buildCounterGetOrdersResponse = 0;
api.GetOrdersResponse buildGetOrdersResponse() {
  var o = api.GetOrdersResponse();
  buildCounterGetOrdersResponse++;
  if (buildCounterGetOrdersResponse < 3) {
    o.proposals = buildUnnamed2586();
  }
  buildCounterGetOrdersResponse--;
  return o;
}

void checkGetOrdersResponse(api.GetOrdersResponse o) {
  buildCounterGetOrdersResponse++;
  if (buildCounterGetOrdersResponse < 3) {
    checkUnnamed2586(o.proposals!);
  }
  buildCounterGetOrdersResponse--;
}

core.List<api.PublisherProfileApiProto> buildUnnamed2587() {
  var o = <api.PublisherProfileApiProto>[];
  o.add(buildPublisherProfileApiProto());
  o.add(buildPublisherProfileApiProto());
  return o;
}

void checkUnnamed2587(core.List<api.PublisherProfileApiProto> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPublisherProfileApiProto(o[0] as api.PublisherProfileApiProto);
  checkPublisherProfileApiProto(o[1] as api.PublisherProfileApiProto);
}

core.int buildCounterGetPublisherProfilesByAccountIdResponse = 0;
api.GetPublisherProfilesByAccountIdResponse
    buildGetPublisherProfilesByAccountIdResponse() {
  var o = api.GetPublisherProfilesByAccountIdResponse();
  buildCounterGetPublisherProfilesByAccountIdResponse++;
  if (buildCounterGetPublisherProfilesByAccountIdResponse < 3) {
    o.profiles = buildUnnamed2587();
  }
  buildCounterGetPublisherProfilesByAccountIdResponse--;
  return o;
}

void checkGetPublisherProfilesByAccountIdResponse(
    api.GetPublisherProfilesByAccountIdResponse o) {
  buildCounterGetPublisherProfilesByAccountIdResponse++;
  if (buildCounterGetPublisherProfilesByAccountIdResponse < 3) {
    checkUnnamed2587(o.profiles!);
  }
  buildCounterGetPublisherProfilesByAccountIdResponse--;
}

core.List<api.ContactInformation> buildUnnamed2588() {
  var o = <api.ContactInformation>[];
  o.add(buildContactInformation());
  o.add(buildContactInformation());
  return o;
}

void checkUnnamed2588(core.List<api.ContactInformation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactInformation(o[0] as api.ContactInformation);
  checkContactInformation(o[1] as api.ContactInformation);
}

core.List<api.SharedTargeting> buildUnnamed2589() {
  var o = <api.SharedTargeting>[];
  o.add(buildSharedTargeting());
  o.add(buildSharedTargeting());
  return o;
}

void checkUnnamed2589(core.List<api.SharedTargeting> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSharedTargeting(o[0] as api.SharedTargeting);
  checkSharedTargeting(o[1] as api.SharedTargeting);
}

core.int buildCounterMarketplaceDeal = 0;
api.MarketplaceDeal buildMarketplaceDeal() {
  var o = api.MarketplaceDeal();
  buildCounterMarketplaceDeal++;
  if (buildCounterMarketplaceDeal < 3) {
    o.buyerPrivateData = buildPrivateData();
    o.creationTimeMs = 'foo';
    o.creativePreApprovalPolicy = 'foo';
    o.creativeSafeFrameCompatibility = 'foo';
    o.dealId = 'foo';
    o.dealServingMetadata = buildDealServingMetadata();
    o.deliveryControl = buildDeliveryControl();
    o.externalDealId = 'foo';
    o.flightEndTimeMs = 'foo';
    o.flightStartTimeMs = 'foo';
    o.inventoryDescription = 'foo';
    o.isRfpTemplate = true;
    o.isSetupComplete = true;
    o.kind = 'foo';
    o.lastUpdateTimeMs = 'foo';
    o.makegoodRequestedReason = 'foo';
    o.name = 'foo';
    o.productId = 'foo';
    o.productRevisionNumber = 'foo';
    o.programmaticCreativeSource = 'foo';
    o.proposalId = 'foo';
    o.sellerContacts = buildUnnamed2588();
    o.sharedTargetings = buildUnnamed2589();
    o.syndicationProduct = 'foo';
    o.terms = buildDealTerms();
    o.webPropertyCode = 'foo';
  }
  buildCounterMarketplaceDeal--;
  return o;
}

void checkMarketplaceDeal(api.MarketplaceDeal o) {
  buildCounterMarketplaceDeal++;
  if (buildCounterMarketplaceDeal < 3) {
    checkPrivateData(o.buyerPrivateData! as api.PrivateData);
    unittest.expect(
      o.creationTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creativePreApprovalPolicy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creativeSafeFrameCompatibility!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dealId!,
      unittest.equals('foo'),
    );
    checkDealServingMetadata(o.dealServingMetadata! as api.DealServingMetadata);
    checkDeliveryControl(o.deliveryControl! as api.DeliveryControl);
    unittest.expect(
      o.externalDealId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.flightEndTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.flightStartTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inventoryDescription!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isRfpTemplate!, unittest.isTrue);
    unittest.expect(o.isSetupComplete!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastUpdateTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.makegoodRequestedReason!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productRevisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.programmaticCreativeSource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proposalId!,
      unittest.equals('foo'),
    );
    checkUnnamed2588(o.sellerContacts!);
    checkUnnamed2589(o.sharedTargetings!);
    unittest.expect(
      o.syndicationProduct!,
      unittest.equals('foo'),
    );
    checkDealTerms(o.terms! as api.DealTerms);
    unittest.expect(
      o.webPropertyCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterMarketplaceDeal--;
}

core.int buildCounterMarketplaceDealParty = 0;
api.MarketplaceDealParty buildMarketplaceDealParty() {
  var o = api.MarketplaceDealParty();
  buildCounterMarketplaceDealParty++;
  if (buildCounterMarketplaceDealParty < 3) {
    o.buyer = buildBuyer();
    o.seller = buildSeller();
  }
  buildCounterMarketplaceDealParty--;
  return o;
}

void checkMarketplaceDealParty(api.MarketplaceDealParty o) {
  buildCounterMarketplaceDealParty++;
  if (buildCounterMarketplaceDealParty < 3) {
    checkBuyer(o.buyer! as api.Buyer);
    checkSeller(o.seller! as api.Seller);
  }
  buildCounterMarketplaceDealParty--;
}

core.int buildCounterMarketplaceLabel = 0;
api.MarketplaceLabel buildMarketplaceLabel() {
  var o = api.MarketplaceLabel();
  buildCounterMarketplaceLabel++;
  if (buildCounterMarketplaceLabel < 3) {
    o.accountId = 'foo';
    o.createTimeMs = 'foo';
    o.deprecatedMarketplaceDealParty = buildMarketplaceDealParty();
    o.label = 'foo';
  }
  buildCounterMarketplaceLabel--;
  return o;
}

void checkMarketplaceLabel(api.MarketplaceLabel o) {
  buildCounterMarketplaceLabel++;
  if (buildCounterMarketplaceLabel < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.createTimeMs!,
      unittest.equals('foo'),
    );
    checkMarketplaceDealParty(
        o.deprecatedMarketplaceDealParty! as api.MarketplaceDealParty);
    unittest.expect(
      o.label!,
      unittest.equals('foo'),
    );
  }
  buildCounterMarketplaceLabel--;
}

core.int buildCounterMarketplaceNote = 0;
api.MarketplaceNote buildMarketplaceNote() {
  var o = api.MarketplaceNote();
  buildCounterMarketplaceNote++;
  if (buildCounterMarketplaceNote < 3) {
    o.creatorRole = 'foo';
    o.dealId = 'foo';
    o.kind = 'foo';
    o.note = 'foo';
    o.noteId = 'foo';
    o.proposalId = 'foo';
    o.proposalRevisionNumber = 'foo';
    o.timestampMs = 'foo';
  }
  buildCounterMarketplaceNote--;
  return o;
}

void checkMarketplaceNote(api.MarketplaceNote o) {
  buildCounterMarketplaceNote++;
  if (buildCounterMarketplaceNote < 3) {
    unittest.expect(
      o.creatorRole!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dealId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.note!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.noteId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proposalId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timestampMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterMarketplaceNote--;
}

core.int buildCounterMobileApplication = 0;
api.MobileApplication buildMobileApplication() {
  var o = api.MobileApplication();
  buildCounterMobileApplication++;
  if (buildCounterMobileApplication < 3) {
    o.appStore = 'foo';
    o.externalAppId = 'foo';
  }
  buildCounterMobileApplication--;
  return o;
}

void checkMobileApplication(api.MobileApplication o) {
  buildCounterMobileApplication++;
  if (buildCounterMobileApplication < 3) {
    unittest.expect(
      o.appStore!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.externalAppId!,
      unittest.equals('foo'),
    );
  }
  buildCounterMobileApplication--;
}

core.List<core.Object> buildUnnamed2590() {
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

void checkUnnamed2590(core.List<core.Object> o) {
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

core.List<core.Object> buildUnnamed2591() {
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

void checkUnnamed2591(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o[0]) as core.Map;
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
  var casted4 = (o[1]) as core.Map;
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

core.List<core.Object> buildUnnamed2592() {
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

void checkUnnamed2592(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted5 = (o[0]) as core.Map;
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
  var casted6 = (o[1]) as core.Map;
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

core.List<core.Object> buildUnnamed2593() {
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

void checkUnnamed2593(core.List<core.Object> o) {
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

core.int buildCounterPerformanceReport = 0;
api.PerformanceReport buildPerformanceReport() {
  var o = api.PerformanceReport();
  buildCounterPerformanceReport++;
  if (buildCounterPerformanceReport < 3) {
    o.bidRate = 42.0;
    o.bidRequestRate = 42.0;
    o.calloutStatusRate = buildUnnamed2590();
    o.cookieMatcherStatusRate = buildUnnamed2591();
    o.creativeStatusRate = buildUnnamed2592();
    o.filteredBidRate = 42.0;
    o.hostedMatchStatusRate = buildUnnamed2593();
    o.inventoryMatchRate = 42.0;
    o.kind = 'foo';
    o.latency50thPercentile = 42.0;
    o.latency85thPercentile = 42.0;
    o.latency95thPercentile = 42.0;
    o.noQuotaInRegion = 42.0;
    o.outOfQuota = 42.0;
    o.pixelMatchRequests = 42.0;
    o.pixelMatchResponses = 42.0;
    o.quotaConfiguredLimit = 42.0;
    o.quotaThrottledLimit = 42.0;
    o.region = 'foo';
    o.successfulRequestRate = 42.0;
    o.timestamp = 'foo';
    o.unsuccessfulRequestRate = 42.0;
  }
  buildCounterPerformanceReport--;
  return o;
}

void checkPerformanceReport(api.PerformanceReport o) {
  buildCounterPerformanceReport++;
  if (buildCounterPerformanceReport < 3) {
    unittest.expect(
      o.bidRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.bidRequestRate!,
      unittest.equals(42.0),
    );
    checkUnnamed2590(o.calloutStatusRate!);
    checkUnnamed2591(o.cookieMatcherStatusRate!);
    checkUnnamed2592(o.creativeStatusRate!);
    unittest.expect(
      o.filteredBidRate!,
      unittest.equals(42.0),
    );
    checkUnnamed2593(o.hostedMatchStatusRate!);
    unittest.expect(
      o.inventoryMatchRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.latency50thPercentile!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.latency85thPercentile!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.latency95thPercentile!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.noQuotaInRegion!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.outOfQuota!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.pixelMatchRequests!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.pixelMatchResponses!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.quotaConfiguredLimit!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.quotaThrottledLimit!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.region!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.successfulRequestRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.unsuccessfulRequestRate!,
      unittest.equals(42.0),
    );
  }
  buildCounterPerformanceReport--;
}

core.List<api.PerformanceReport> buildUnnamed2594() {
  var o = <api.PerformanceReport>[];
  o.add(buildPerformanceReport());
  o.add(buildPerformanceReport());
  return o;
}

void checkUnnamed2594(core.List<api.PerformanceReport> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPerformanceReport(o[0] as api.PerformanceReport);
  checkPerformanceReport(o[1] as api.PerformanceReport);
}

core.int buildCounterPerformanceReportList = 0;
api.PerformanceReportList buildPerformanceReportList() {
  var o = api.PerformanceReportList();
  buildCounterPerformanceReportList++;
  if (buildCounterPerformanceReportList < 3) {
    o.kind = 'foo';
    o.performanceReport = buildUnnamed2594();
  }
  buildCounterPerformanceReportList--;
  return o;
}

void checkPerformanceReportList(api.PerformanceReportList o) {
  buildCounterPerformanceReportList++;
  if (buildCounterPerformanceReportList < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2594(o.performanceReport!);
  }
  buildCounterPerformanceReportList--;
}

core.List<core.String> buildUnnamed2595() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2595(core.List<core.String> o) {
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

core.int buildCounterPretargetingConfigDimensions = 0;
api.PretargetingConfigDimensions buildPretargetingConfigDimensions() {
  var o = api.PretargetingConfigDimensions();
  buildCounterPretargetingConfigDimensions++;
  if (buildCounterPretargetingConfigDimensions < 3) {
    o.height = 'foo';
    o.width = 'foo';
  }
  buildCounterPretargetingConfigDimensions--;
  return o;
}

void checkPretargetingConfigDimensions(api.PretargetingConfigDimensions o) {
  buildCounterPretargetingConfigDimensions++;
  if (buildCounterPretargetingConfigDimensions < 3) {
    unittest.expect(
      o.height!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.width!,
      unittest.equals('foo'),
    );
  }
  buildCounterPretargetingConfigDimensions--;
}

core.List<api.PretargetingConfigDimensions> buildUnnamed2596() {
  var o = <api.PretargetingConfigDimensions>[];
  o.add(buildPretargetingConfigDimensions());
  o.add(buildPretargetingConfigDimensions());
  return o;
}

void checkUnnamed2596(core.List<api.PretargetingConfigDimensions> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPretargetingConfigDimensions(o[0] as api.PretargetingConfigDimensions);
  checkPretargetingConfigDimensions(o[1] as api.PretargetingConfigDimensions);
}

core.List<core.String> buildUnnamed2597() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2597(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2598() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2598(core.List<core.String> o) {
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

core.int buildCounterPretargetingConfigExcludedPlacements = 0;
api.PretargetingConfigExcludedPlacements
    buildPretargetingConfigExcludedPlacements() {
  var o = api.PretargetingConfigExcludedPlacements();
  buildCounterPretargetingConfigExcludedPlacements++;
  if (buildCounterPretargetingConfigExcludedPlacements < 3) {
    o.token = 'foo';
    o.type = 'foo';
  }
  buildCounterPretargetingConfigExcludedPlacements--;
  return o;
}

void checkPretargetingConfigExcludedPlacements(
    api.PretargetingConfigExcludedPlacements o) {
  buildCounterPretargetingConfigExcludedPlacements++;
  if (buildCounterPretargetingConfigExcludedPlacements < 3) {
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterPretargetingConfigExcludedPlacements--;
}

core.List<api.PretargetingConfigExcludedPlacements> buildUnnamed2599() {
  var o = <api.PretargetingConfigExcludedPlacements>[];
  o.add(buildPretargetingConfigExcludedPlacements());
  o.add(buildPretargetingConfigExcludedPlacements());
  return o;
}

void checkUnnamed2599(core.List<api.PretargetingConfigExcludedPlacements> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPretargetingConfigExcludedPlacements(
      o[0] as api.PretargetingConfigExcludedPlacements);
  checkPretargetingConfigExcludedPlacements(
      o[1] as api.PretargetingConfigExcludedPlacements);
}

core.List<core.String> buildUnnamed2600() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2600(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2601() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2601(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2602() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2602(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2603() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2603(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2604() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2604(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2605() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2605(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2606() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2606(core.List<core.String> o) {
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

core.int buildCounterPretargetingConfigPlacements = 0;
api.PretargetingConfigPlacements buildPretargetingConfigPlacements() {
  var o = api.PretargetingConfigPlacements();
  buildCounterPretargetingConfigPlacements++;
  if (buildCounterPretargetingConfigPlacements < 3) {
    o.token = 'foo';
    o.type = 'foo';
  }
  buildCounterPretargetingConfigPlacements--;
  return o;
}

void checkPretargetingConfigPlacements(api.PretargetingConfigPlacements o) {
  buildCounterPretargetingConfigPlacements++;
  if (buildCounterPretargetingConfigPlacements < 3) {
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterPretargetingConfigPlacements--;
}

core.List<api.PretargetingConfigPlacements> buildUnnamed2607() {
  var o = <api.PretargetingConfigPlacements>[];
  o.add(buildPretargetingConfigPlacements());
  o.add(buildPretargetingConfigPlacements());
  return o;
}

void checkUnnamed2607(core.List<api.PretargetingConfigPlacements> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPretargetingConfigPlacements(o[0] as api.PretargetingConfigPlacements);
  checkPretargetingConfigPlacements(o[1] as api.PretargetingConfigPlacements);
}

core.List<core.String> buildUnnamed2608() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2608(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2609() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2609(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2610() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2610(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2611() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2611(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2612() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2612(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2613() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2613(core.List<core.String> o) {
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

core.int buildCounterPretargetingConfigVideoPlayerSizes = 0;
api.PretargetingConfigVideoPlayerSizes
    buildPretargetingConfigVideoPlayerSizes() {
  var o = api.PretargetingConfigVideoPlayerSizes();
  buildCounterPretargetingConfigVideoPlayerSizes++;
  if (buildCounterPretargetingConfigVideoPlayerSizes < 3) {
    o.aspectRatio = 'foo';
    o.minHeight = 'foo';
    o.minWidth = 'foo';
  }
  buildCounterPretargetingConfigVideoPlayerSizes--;
  return o;
}

void checkPretargetingConfigVideoPlayerSizes(
    api.PretargetingConfigVideoPlayerSizes o) {
  buildCounterPretargetingConfigVideoPlayerSizes++;
  if (buildCounterPretargetingConfigVideoPlayerSizes < 3) {
    unittest.expect(
      o.aspectRatio!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minHeight!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minWidth!,
      unittest.equals('foo'),
    );
  }
  buildCounterPretargetingConfigVideoPlayerSizes--;
}

core.List<api.PretargetingConfigVideoPlayerSizes> buildUnnamed2614() {
  var o = <api.PretargetingConfigVideoPlayerSizes>[];
  o.add(buildPretargetingConfigVideoPlayerSizes());
  o.add(buildPretargetingConfigVideoPlayerSizes());
  return o;
}

void checkUnnamed2614(core.List<api.PretargetingConfigVideoPlayerSizes> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPretargetingConfigVideoPlayerSizes(
      o[0] as api.PretargetingConfigVideoPlayerSizes);
  checkPretargetingConfigVideoPlayerSizes(
      o[1] as api.PretargetingConfigVideoPlayerSizes);
}

core.int buildCounterPretargetingConfig = 0;
api.PretargetingConfig buildPretargetingConfig() {
  var o = api.PretargetingConfig();
  buildCounterPretargetingConfig++;
  if (buildCounterPretargetingConfig < 3) {
    o.billingId = 'foo';
    o.configId = 'foo';
    o.configName = 'foo';
    o.creativeType = buildUnnamed2595();
    o.dimensions = buildUnnamed2596();
    o.excludedContentLabels = buildUnnamed2597();
    o.excludedGeoCriteriaIds = buildUnnamed2598();
    o.excludedPlacements = buildUnnamed2599();
    o.excludedUserLists = buildUnnamed2600();
    o.excludedVerticals = buildUnnamed2601();
    o.geoCriteriaIds = buildUnnamed2602();
    o.isActive = true;
    o.kind = 'foo';
    o.languages = buildUnnamed2603();
    o.maximumQps = 'foo';
    o.minimumViewabilityDecile = 42;
    o.mobileCarriers = buildUnnamed2604();
    o.mobileDevices = buildUnnamed2605();
    o.mobileOperatingSystemVersions = buildUnnamed2606();
    o.placements = buildUnnamed2607();
    o.platforms = buildUnnamed2608();
    o.supportedCreativeAttributes = buildUnnamed2609();
    o.userIdentifierDataRequired = buildUnnamed2610();
    o.userLists = buildUnnamed2611();
    o.vendorTypes = buildUnnamed2612();
    o.verticals = buildUnnamed2613();
    o.videoPlayerSizes = buildUnnamed2614();
  }
  buildCounterPretargetingConfig--;
  return o;
}

void checkPretargetingConfig(api.PretargetingConfig o) {
  buildCounterPretargetingConfig++;
  if (buildCounterPretargetingConfig < 3) {
    unittest.expect(
      o.billingId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.configId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.configName!,
      unittest.equals('foo'),
    );
    checkUnnamed2595(o.creativeType!);
    checkUnnamed2596(o.dimensions!);
    checkUnnamed2597(o.excludedContentLabels!);
    checkUnnamed2598(o.excludedGeoCriteriaIds!);
    checkUnnamed2599(o.excludedPlacements!);
    checkUnnamed2600(o.excludedUserLists!);
    checkUnnamed2601(o.excludedVerticals!);
    checkUnnamed2602(o.geoCriteriaIds!);
    unittest.expect(o.isActive!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2603(o.languages!);
    unittest.expect(
      o.maximumQps!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumViewabilityDecile!,
      unittest.equals(42),
    );
    checkUnnamed2604(o.mobileCarriers!);
    checkUnnamed2605(o.mobileDevices!);
    checkUnnamed2606(o.mobileOperatingSystemVersions!);
    checkUnnamed2607(o.placements!);
    checkUnnamed2608(o.platforms!);
    checkUnnamed2609(o.supportedCreativeAttributes!);
    checkUnnamed2610(o.userIdentifierDataRequired!);
    checkUnnamed2611(o.userLists!);
    checkUnnamed2612(o.vendorTypes!);
    checkUnnamed2613(o.verticals!);
    checkUnnamed2614(o.videoPlayerSizes!);
  }
  buildCounterPretargetingConfig--;
}

core.List<api.PretargetingConfig> buildUnnamed2615() {
  var o = <api.PretargetingConfig>[];
  o.add(buildPretargetingConfig());
  o.add(buildPretargetingConfig());
  return o;
}

void checkUnnamed2615(core.List<api.PretargetingConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPretargetingConfig(o[0] as api.PretargetingConfig);
  checkPretargetingConfig(o[1] as api.PretargetingConfig);
}

core.int buildCounterPretargetingConfigList = 0;
api.PretargetingConfigList buildPretargetingConfigList() {
  var o = api.PretargetingConfigList();
  buildCounterPretargetingConfigList++;
  if (buildCounterPretargetingConfigList < 3) {
    o.items = buildUnnamed2615();
    o.kind = 'foo';
  }
  buildCounterPretargetingConfigList--;
  return o;
}

void checkPretargetingConfigList(api.PretargetingConfigList o) {
  buildCounterPretargetingConfigList++;
  if (buildCounterPretargetingConfigList < 3) {
    checkUnnamed2615(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterPretargetingConfigList--;
}

core.int buildCounterPrice = 0;
api.Price buildPrice() {
  var o = api.Price();
  buildCounterPrice++;
  if (buildCounterPrice < 3) {
    o.amountMicros = 42.0;
    o.currencyCode = 'foo';
    o.expectedCpmMicros = 42.0;
    o.pricingType = 'foo';
  }
  buildCounterPrice--;
  return o;
}

void checkPrice(api.Price o) {
  buildCounterPrice++;
  if (buildCounterPrice < 3) {
    unittest.expect(
      o.amountMicros!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expectedCpmMicros!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.pricingType!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrice--;
}

core.int buildCounterPricePerBuyer = 0;
api.PricePerBuyer buildPricePerBuyer() {
  var o = api.PricePerBuyer();
  buildCounterPricePerBuyer++;
  if (buildCounterPricePerBuyer < 3) {
    o.auctionTier = 'foo';
    o.billedBuyer = buildBuyer();
    o.buyer = buildBuyer();
    o.price = buildPrice();
  }
  buildCounterPricePerBuyer--;
  return o;
}

void checkPricePerBuyer(api.PricePerBuyer o) {
  buildCounterPricePerBuyer++;
  if (buildCounterPricePerBuyer < 3) {
    unittest.expect(
      o.auctionTier!,
      unittest.equals('foo'),
    );
    checkBuyer(o.billedBuyer! as api.Buyer);
    checkBuyer(o.buyer! as api.Buyer);
    checkPrice(o.price! as api.Price);
  }
  buildCounterPricePerBuyer--;
}

core.int buildCounterPrivateData = 0;
api.PrivateData buildPrivateData() {
  var o = api.PrivateData();
  buildCounterPrivateData++;
  if (buildCounterPrivateData < 3) {
    o.referenceId = 'foo';
    o.referencePayload = 'foo';
  }
  buildCounterPrivateData--;
  return o;
}

void checkPrivateData(api.PrivateData o) {
  buildCounterPrivateData++;
  if (buildCounterPrivateData < 3) {
    unittest.expect(
      o.referenceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referencePayload!,
      unittest.equals('foo'),
    );
  }
  buildCounterPrivateData--;
}

core.List<api.ContactInformation> buildUnnamed2616() {
  var o = <api.ContactInformation>[];
  o.add(buildContactInformation());
  o.add(buildContactInformation());
  return o;
}

void checkUnnamed2616(core.List<api.ContactInformation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactInformation(o[0] as api.ContactInformation);
  checkContactInformation(o[1] as api.ContactInformation);
}

core.List<api.MarketplaceLabel> buildUnnamed2617() {
  var o = <api.MarketplaceLabel>[];
  o.add(buildMarketplaceLabel());
  o.add(buildMarketplaceLabel());
  return o;
}

void checkUnnamed2617(core.List<api.MarketplaceLabel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceLabel(o[0] as api.MarketplaceLabel);
  checkMarketplaceLabel(o[1] as api.MarketplaceLabel);
}

core.List<api.SharedTargeting> buildUnnamed2618() {
  var o = <api.SharedTargeting>[];
  o.add(buildSharedTargeting());
  o.add(buildSharedTargeting());
  return o;
}

void checkUnnamed2618(core.List<api.SharedTargeting> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSharedTargeting(o[0] as api.SharedTargeting);
  checkSharedTargeting(o[1] as api.SharedTargeting);
}

core.int buildCounterProduct = 0;
api.Product buildProduct() {
  var o = api.Product();
  buildCounterProduct++;
  if (buildCounterProduct < 3) {
    o.billedBuyer = buildBuyer();
    o.buyer = buildBuyer();
    o.creationTimeMs = 'foo';
    o.creatorContacts = buildUnnamed2616();
    o.creatorRole = 'foo';
    o.deliveryControl = buildDeliveryControl();
    o.flightEndTimeMs = 'foo';
    o.flightStartTimeMs = 'foo';
    o.hasCreatorSignedOff = true;
    o.inventorySource = 'foo';
    o.kind = 'foo';
    o.labels = buildUnnamed2617();
    o.lastUpdateTimeMs = 'foo';
    o.legacyOfferId = 'foo';
    o.marketplacePublisherProfileId = 'foo';
    o.name = 'foo';
    o.privateAuctionId = 'foo';
    o.productId = 'foo';
    o.publisherProfileId = 'foo';
    o.publisherProvidedForecast = buildPublisherProvidedForecast();
    o.revisionNumber = 'foo';
    o.seller = buildSeller();
    o.sharedTargetings = buildUnnamed2618();
    o.state = 'foo';
    o.syndicationProduct = 'foo';
    o.terms = buildDealTerms();
    o.webPropertyCode = 'foo';
  }
  buildCounterProduct--;
  return o;
}

void checkProduct(api.Product o) {
  buildCounterProduct++;
  if (buildCounterProduct < 3) {
    checkBuyer(o.billedBuyer! as api.Buyer);
    checkBuyer(o.buyer! as api.Buyer);
    unittest.expect(
      o.creationTimeMs!,
      unittest.equals('foo'),
    );
    checkUnnamed2616(o.creatorContacts!);
    unittest.expect(
      o.creatorRole!,
      unittest.equals('foo'),
    );
    checkDeliveryControl(o.deliveryControl! as api.DeliveryControl);
    unittest.expect(
      o.flightEndTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.flightStartTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hasCreatorSignedOff!, unittest.isTrue);
    unittest.expect(
      o.inventorySource!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2617(o.labels!);
    unittest.expect(
      o.lastUpdateTimeMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.legacyOfferId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.marketplacePublisherProfileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privateAuctionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.productId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publisherProfileId!,
      unittest.equals('foo'),
    );
    checkPublisherProvidedForecast(
        o.publisherProvidedForecast! as api.PublisherProvidedForecast);
    unittest.expect(
      o.revisionNumber!,
      unittest.equals('foo'),
    );
    checkSeller(o.seller! as api.Seller);
    checkUnnamed2618(o.sharedTargetings!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.syndicationProduct!,
      unittest.equals('foo'),
    );
    checkDealTerms(o.terms! as api.DealTerms);
    unittest.expect(
      o.webPropertyCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterProduct--;
}

core.List<api.ContactInformation> buildUnnamed2619() {
  var o = <api.ContactInformation>[];
  o.add(buildContactInformation());
  o.add(buildContactInformation());
  return o;
}

void checkUnnamed2619(core.List<api.ContactInformation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactInformation(o[0] as api.ContactInformation);
  checkContactInformation(o[1] as api.ContactInformation);
}

core.List<core.String> buildUnnamed2620() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2620(core.List<core.String> o) {
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

core.List<api.MarketplaceLabel> buildUnnamed2621() {
  var o = <api.MarketplaceLabel>[];
  o.add(buildMarketplaceLabel());
  o.add(buildMarketplaceLabel());
  return o;
}

void checkUnnamed2621(core.List<api.MarketplaceLabel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMarketplaceLabel(o[0] as api.MarketplaceLabel);
  checkMarketplaceLabel(o[1] as api.MarketplaceLabel);
}

core.List<api.ContactInformation> buildUnnamed2622() {
  var o = <api.ContactInformation>[];
  o.add(buildContactInformation());
  o.add(buildContactInformation());
  return o;
}

void checkUnnamed2622(core.List<api.ContactInformation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContactInformation(o[0] as api.ContactInformation);
  checkContactInformation(o[1] as api.ContactInformation);
}

core.int buildCounterProposal = 0;
api.Proposal buildProposal() {
  var o = api.Proposal();
  buildCounterProposal++;
  if (buildCounterProposal < 3) {
    o.billedBuyer = buildBuyer();
    o.buyer = buildBuyer();
    o.buyerContacts = buildUnnamed2619();
    o.buyerPrivateData = buildPrivateData();
    o.dbmAdvertiserIds = buildUnnamed2620();
    o.hasBuyerSignedOff = true;
    o.hasSellerSignedOff = true;
    o.inventorySource = 'foo';
    o.isRenegotiating = true;
    o.isSetupComplete = true;
    o.kind = 'foo';
    o.labels = buildUnnamed2621();
    o.lastUpdaterOrCommentorRole = 'foo';
    o.name = 'foo';
    o.negotiationId = 'foo';
    o.originatorRole = 'foo';
    o.privateAuctionId = 'foo';
    o.proposalId = 'foo';
    o.proposalState = 'foo';
    o.revisionNumber = 'foo';
    o.revisionTimeMs = 'foo';
    o.seller = buildSeller();
    o.sellerContacts = buildUnnamed2622();
  }
  buildCounterProposal--;
  return o;
}

void checkProposal(api.Proposal o) {
  buildCounterProposal++;
  if (buildCounterProposal < 3) {
    checkBuyer(o.billedBuyer! as api.Buyer);
    checkBuyer(o.buyer! as api.Buyer);
    checkUnnamed2619(o.buyerContacts!);
    checkPrivateData(o.buyerPrivateData! as api.PrivateData);
    checkUnnamed2620(o.dbmAdvertiserIds!);
    unittest.expect(o.hasBuyerSignedOff!, unittest.isTrue);
    unittest.expect(o.hasSellerSignedOff!, unittest.isTrue);
    unittest.expect(
      o.inventorySource!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isRenegotiating!, unittest.isTrue);
    unittest.expect(o.isSetupComplete!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2621(o.labels!);
    unittest.expect(
      o.lastUpdaterOrCommentorRole!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.negotiationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originatorRole!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.privateAuctionId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proposalId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.proposalState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.revisionTimeMs!,
      unittest.equals('foo'),
    );
    checkSeller(o.seller! as api.Seller);
    checkUnnamed2622(o.sellerContacts!);
  }
  buildCounterProposal--;
}

core.List<core.String> buildUnnamed2623() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2623(core.List<core.String> o) {
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

core.List<api.MobileApplication> buildUnnamed2624() {
  var o = <api.MobileApplication>[];
  o.add(buildMobileApplication());
  o.add(buildMobileApplication());
  return o;
}

void checkUnnamed2624(core.List<api.MobileApplication> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMobileApplication(o[0] as api.MobileApplication);
  checkMobileApplication(o[1] as api.MobileApplication);
}

core.List<core.String> buildUnnamed2625() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2625(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2626() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2626(core.List<core.String> o) {
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

core.int buildCounterPublisherProfileApiProto = 0;
api.PublisherProfileApiProto buildPublisherProfileApiProto() {
  var o = api.PublisherProfileApiProto();
  buildCounterPublisherProfileApiProto++;
  if (buildCounterPublisherProfileApiProto < 3) {
    o.audience = 'foo';
    o.buyerPitchStatement = 'foo';
    o.directContact = 'foo';
    o.exchange = 'foo';
    o.forecastInventory = 'foo';
    o.googlePlusLink = 'foo';
    o.isParent = true;
    o.isPublished = true;
    o.kind = 'foo';
    o.logoUrl = 'foo';
    o.mediaKitLink = 'foo';
    o.name = 'foo';
    o.overview = 'foo';
    o.profileId = 42;
    o.programmaticContact = 'foo';
    o.publisherAppIds = buildUnnamed2623();
    o.publisherApps = buildUnnamed2624();
    o.publisherDomains = buildUnnamed2625();
    o.publisherProfileId = 'foo';
    o.publisherProvidedForecast = buildPublisherProvidedForecast();
    o.rateCardInfoLink = 'foo';
    o.samplePageLink = 'foo';
    o.seller = buildSeller();
    o.state = 'foo';
    o.topHeadlines = buildUnnamed2626();
  }
  buildCounterPublisherProfileApiProto--;
  return o;
}

void checkPublisherProfileApiProto(api.PublisherProfileApiProto o) {
  buildCounterPublisherProfileApiProto++;
  if (buildCounterPublisherProfileApiProto < 3) {
    unittest.expect(
      o.audience!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.buyerPitchStatement!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.directContact!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.exchange!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.forecastInventory!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.googlePlusLink!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isParent!, unittest.isTrue);
    unittest.expect(o.isPublished!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.logoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mediaKitLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.overview!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals(42),
    );
    unittest.expect(
      o.programmaticContact!,
      unittest.equals('foo'),
    );
    checkUnnamed2623(o.publisherAppIds!);
    checkUnnamed2624(o.publisherApps!);
    checkUnnamed2625(o.publisherDomains!);
    unittest.expect(
      o.publisherProfileId!,
      unittest.equals('foo'),
    );
    checkPublisherProvidedForecast(
        o.publisherProvidedForecast! as api.PublisherProvidedForecast);
    unittest.expect(
      o.rateCardInfoLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.samplePageLink!,
      unittest.equals('foo'),
    );
    checkSeller(o.seller! as api.Seller);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkUnnamed2626(o.topHeadlines!);
  }
  buildCounterPublisherProfileApiProto--;
}

core.List<api.Dimension> buildUnnamed2627() {
  var o = <api.Dimension>[];
  o.add(buildDimension());
  o.add(buildDimension());
  return o;
}

void checkUnnamed2627(core.List<api.Dimension> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDimension(o[0] as api.Dimension);
  checkDimension(o[1] as api.Dimension);
}

core.int buildCounterPublisherProvidedForecast = 0;
api.PublisherProvidedForecast buildPublisherProvidedForecast() {
  var o = api.PublisherProvidedForecast();
  buildCounterPublisherProvidedForecast++;
  if (buildCounterPublisherProvidedForecast < 3) {
    o.dimensions = buildUnnamed2627();
    o.weeklyImpressions = 'foo';
    o.weeklyUniques = 'foo';
  }
  buildCounterPublisherProvidedForecast--;
  return o;
}

void checkPublisherProvidedForecast(api.PublisherProvidedForecast o) {
  buildCounterPublisherProvidedForecast++;
  if (buildCounterPublisherProvidedForecast < 3) {
    checkUnnamed2627(o.dimensions!);
    unittest.expect(
      o.weeklyImpressions!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.weeklyUniques!,
      unittest.equals('foo'),
    );
  }
  buildCounterPublisherProvidedForecast--;
}

core.int buildCounterSeller = 0;
api.Seller buildSeller() {
  var o = api.Seller();
  buildCounterSeller++;
  if (buildCounterSeller < 3) {
    o.accountId = 'foo';
    o.subAccountId = 'foo';
  }
  buildCounterSeller--;
  return o;
}

void checkSeller(api.Seller o) {
  buildCounterSeller++;
  if (buildCounterSeller < 3) {
    unittest.expect(
      o.accountId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subAccountId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSeller--;
}

core.List<api.TargetingValue> buildUnnamed2628() {
  var o = <api.TargetingValue>[];
  o.add(buildTargetingValue());
  o.add(buildTargetingValue());
  return o;
}

void checkUnnamed2628(core.List<api.TargetingValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetingValue(o[0] as api.TargetingValue);
  checkTargetingValue(o[1] as api.TargetingValue);
}

core.List<api.TargetingValue> buildUnnamed2629() {
  var o = <api.TargetingValue>[];
  o.add(buildTargetingValue());
  o.add(buildTargetingValue());
  return o;
}

void checkUnnamed2629(core.List<api.TargetingValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetingValue(o[0] as api.TargetingValue);
  checkTargetingValue(o[1] as api.TargetingValue);
}

core.int buildCounterSharedTargeting = 0;
api.SharedTargeting buildSharedTargeting() {
  var o = api.SharedTargeting();
  buildCounterSharedTargeting++;
  if (buildCounterSharedTargeting < 3) {
    o.exclusions = buildUnnamed2628();
    o.inclusions = buildUnnamed2629();
    o.key = 'foo';
  }
  buildCounterSharedTargeting--;
  return o;
}

void checkSharedTargeting(api.SharedTargeting o) {
  buildCounterSharedTargeting++;
  if (buildCounterSharedTargeting < 3) {
    checkUnnamed2628(o.exclusions!);
    checkUnnamed2629(o.inclusions!);
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
  }
  buildCounterSharedTargeting--;
}

core.int buildCounterTargetingValue = 0;
api.TargetingValue buildTargetingValue() {
  var o = api.TargetingValue();
  buildCounterTargetingValue++;
  if (buildCounterTargetingValue < 3) {
    o.creativeSizeValue = buildTargetingValueCreativeSize();
    o.dayPartTargetingValue = buildTargetingValueDayPartTargeting();
    o.demogAgeCriteriaValue = buildTargetingValueDemogAgeCriteria();
    o.demogGenderCriteriaValue = buildTargetingValueDemogGenderCriteria();
    o.longValue = 'foo';
    o.requestPlatformTargetingValue =
        buildTargetingValueRequestPlatformTargeting();
    o.stringValue = 'foo';
  }
  buildCounterTargetingValue--;
  return o;
}

void checkTargetingValue(api.TargetingValue o) {
  buildCounterTargetingValue++;
  if (buildCounterTargetingValue < 3) {
    checkTargetingValueCreativeSize(
        o.creativeSizeValue! as api.TargetingValueCreativeSize);
    checkTargetingValueDayPartTargeting(
        o.dayPartTargetingValue! as api.TargetingValueDayPartTargeting);
    checkTargetingValueDemogAgeCriteria(
        o.demogAgeCriteriaValue! as api.TargetingValueDemogAgeCriteria);
    checkTargetingValueDemogGenderCriteria(
        o.demogGenderCriteriaValue! as api.TargetingValueDemogGenderCriteria);
    unittest.expect(
      o.longValue!,
      unittest.equals('foo'),
    );
    checkTargetingValueRequestPlatformTargeting(o.requestPlatformTargetingValue!
        as api.TargetingValueRequestPlatformTargeting);
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterTargetingValue--;
}

core.List<core.String> buildUnnamed2630() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2630(core.List<core.String> o) {
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

core.List<api.TargetingValueSize> buildUnnamed2631() {
  var o = <api.TargetingValueSize>[];
  o.add(buildTargetingValueSize());
  o.add(buildTargetingValueSize());
  return o;
}

void checkUnnamed2631(core.List<api.TargetingValueSize> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetingValueSize(o[0] as api.TargetingValueSize);
  checkTargetingValueSize(o[1] as api.TargetingValueSize);
}

core.int buildCounterTargetingValueCreativeSize = 0;
api.TargetingValueCreativeSize buildTargetingValueCreativeSize() {
  var o = api.TargetingValueCreativeSize();
  buildCounterTargetingValueCreativeSize++;
  if (buildCounterTargetingValueCreativeSize < 3) {
    o.allowedFormats = buildUnnamed2630();
    o.companionSizes = buildUnnamed2631();
    o.creativeSizeType = 'foo';
    o.nativeTemplate = 'foo';
    o.size = buildTargetingValueSize();
    o.skippableAdType = 'foo';
  }
  buildCounterTargetingValueCreativeSize--;
  return o;
}

void checkTargetingValueCreativeSize(api.TargetingValueCreativeSize o) {
  buildCounterTargetingValueCreativeSize++;
  if (buildCounterTargetingValueCreativeSize < 3) {
    checkUnnamed2630(o.allowedFormats!);
    checkUnnamed2631(o.companionSizes!);
    unittest.expect(
      o.creativeSizeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nativeTemplate!,
      unittest.equals('foo'),
    );
    checkTargetingValueSize(o.size! as api.TargetingValueSize);
    unittest.expect(
      o.skippableAdType!,
      unittest.equals('foo'),
    );
  }
  buildCounterTargetingValueCreativeSize--;
}

core.List<api.TargetingValueDayPartTargetingDayPart> buildUnnamed2632() {
  var o = <api.TargetingValueDayPartTargetingDayPart>[];
  o.add(buildTargetingValueDayPartTargetingDayPart());
  o.add(buildTargetingValueDayPartTargetingDayPart());
  return o;
}

void checkUnnamed2632(core.List<api.TargetingValueDayPartTargetingDayPart> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTargetingValueDayPartTargetingDayPart(
      o[0] as api.TargetingValueDayPartTargetingDayPart);
  checkTargetingValueDayPartTargetingDayPart(
      o[1] as api.TargetingValueDayPartTargetingDayPart);
}

core.int buildCounterTargetingValueDayPartTargeting = 0;
api.TargetingValueDayPartTargeting buildTargetingValueDayPartTargeting() {
  var o = api.TargetingValueDayPartTargeting();
  buildCounterTargetingValueDayPartTargeting++;
  if (buildCounterTargetingValueDayPartTargeting < 3) {
    o.dayParts = buildUnnamed2632();
    o.timeZoneType = 'foo';
  }
  buildCounterTargetingValueDayPartTargeting--;
  return o;
}

void checkTargetingValueDayPartTargeting(api.TargetingValueDayPartTargeting o) {
  buildCounterTargetingValueDayPartTargeting++;
  if (buildCounterTargetingValueDayPartTargeting < 3) {
    checkUnnamed2632(o.dayParts!);
    unittest.expect(
      o.timeZoneType!,
      unittest.equals('foo'),
    );
  }
  buildCounterTargetingValueDayPartTargeting--;
}

core.int buildCounterTargetingValueDayPartTargetingDayPart = 0;
api.TargetingValueDayPartTargetingDayPart
    buildTargetingValueDayPartTargetingDayPart() {
  var o = api.TargetingValueDayPartTargetingDayPart();
  buildCounterTargetingValueDayPartTargetingDayPart++;
  if (buildCounterTargetingValueDayPartTargetingDayPart < 3) {
    o.dayOfWeek = 'foo';
    o.endHour = 42;
    o.endMinute = 42;
    o.startHour = 42;
    o.startMinute = 42;
  }
  buildCounterTargetingValueDayPartTargetingDayPart--;
  return o;
}

void checkTargetingValueDayPartTargetingDayPart(
    api.TargetingValueDayPartTargetingDayPart o) {
  buildCounterTargetingValueDayPartTargetingDayPart++;
  if (buildCounterTargetingValueDayPartTargetingDayPart < 3) {
    unittest.expect(
      o.dayOfWeek!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endHour!,
      unittest.equals(42),
    );
    unittest.expect(
      o.endMinute!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startHour!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startMinute!,
      unittest.equals(42),
    );
  }
  buildCounterTargetingValueDayPartTargetingDayPart--;
}

core.List<core.String> buildUnnamed2633() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2633(core.List<core.String> o) {
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

core.int buildCounterTargetingValueDemogAgeCriteria = 0;
api.TargetingValueDemogAgeCriteria buildTargetingValueDemogAgeCriteria() {
  var o = api.TargetingValueDemogAgeCriteria();
  buildCounterTargetingValueDemogAgeCriteria++;
  if (buildCounterTargetingValueDemogAgeCriteria < 3) {
    o.demogAgeCriteriaIds = buildUnnamed2633();
  }
  buildCounterTargetingValueDemogAgeCriteria--;
  return o;
}

void checkTargetingValueDemogAgeCriteria(api.TargetingValueDemogAgeCriteria o) {
  buildCounterTargetingValueDemogAgeCriteria++;
  if (buildCounterTargetingValueDemogAgeCriteria < 3) {
    checkUnnamed2633(o.demogAgeCriteriaIds!);
  }
  buildCounterTargetingValueDemogAgeCriteria--;
}

core.List<core.String> buildUnnamed2634() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2634(core.List<core.String> o) {
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

core.int buildCounterTargetingValueDemogGenderCriteria = 0;
api.TargetingValueDemogGenderCriteria buildTargetingValueDemogGenderCriteria() {
  var o = api.TargetingValueDemogGenderCriteria();
  buildCounterTargetingValueDemogGenderCriteria++;
  if (buildCounterTargetingValueDemogGenderCriteria < 3) {
    o.demogGenderCriteriaIds = buildUnnamed2634();
  }
  buildCounterTargetingValueDemogGenderCriteria--;
  return o;
}

void checkTargetingValueDemogGenderCriteria(
    api.TargetingValueDemogGenderCriteria o) {
  buildCounterTargetingValueDemogGenderCriteria++;
  if (buildCounterTargetingValueDemogGenderCriteria < 3) {
    checkUnnamed2634(o.demogGenderCriteriaIds!);
  }
  buildCounterTargetingValueDemogGenderCriteria--;
}

core.List<core.String> buildUnnamed2635() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2635(core.List<core.String> o) {
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

core.int buildCounterTargetingValueRequestPlatformTargeting = 0;
api.TargetingValueRequestPlatformTargeting
    buildTargetingValueRequestPlatformTargeting() {
  var o = api.TargetingValueRequestPlatformTargeting();
  buildCounterTargetingValueRequestPlatformTargeting++;
  if (buildCounterTargetingValueRequestPlatformTargeting < 3) {
    o.requestPlatforms = buildUnnamed2635();
  }
  buildCounterTargetingValueRequestPlatformTargeting--;
  return o;
}

void checkTargetingValueRequestPlatformTargeting(
    api.TargetingValueRequestPlatformTargeting o) {
  buildCounterTargetingValueRequestPlatformTargeting++;
  if (buildCounterTargetingValueRequestPlatformTargeting < 3) {
    checkUnnamed2635(o.requestPlatforms!);
  }
  buildCounterTargetingValueRequestPlatformTargeting--;
}

core.int buildCounterTargetingValueSize = 0;
api.TargetingValueSize buildTargetingValueSize() {
  var o = api.TargetingValueSize();
  buildCounterTargetingValueSize++;
  if (buildCounterTargetingValueSize < 3) {
    o.height = 42;
    o.width = 42;
  }
  buildCounterTargetingValueSize--;
  return o;
}

void checkTargetingValueSize(api.TargetingValueSize o) {
  buildCounterTargetingValueSize++;
  if (buildCounterTargetingValueSize < 3) {
    unittest.expect(
      o.height!,
      unittest.equals(42),
    );
    unittest.expect(
      o.width!,
      unittest.equals(42),
    );
  }
  buildCounterTargetingValueSize--;
}

core.int buildCounterUpdatePrivateAuctionProposalRequest = 0;
api.UpdatePrivateAuctionProposalRequest
    buildUpdatePrivateAuctionProposalRequest() {
  var o = api.UpdatePrivateAuctionProposalRequest();
  buildCounterUpdatePrivateAuctionProposalRequest++;
  if (buildCounterUpdatePrivateAuctionProposalRequest < 3) {
    o.externalDealId = 'foo';
    o.note = buildMarketplaceNote();
    o.proposalRevisionNumber = 'foo';
    o.updateAction = 'foo';
  }
  buildCounterUpdatePrivateAuctionProposalRequest--;
  return o;
}

void checkUpdatePrivateAuctionProposalRequest(
    api.UpdatePrivateAuctionProposalRequest o) {
  buildCounterUpdatePrivateAuctionProposalRequest++;
  if (buildCounterUpdatePrivateAuctionProposalRequest < 3) {
    unittest.expect(
      o.externalDealId!,
      unittest.equals('foo'),
    );
    checkMarketplaceNote(o.note! as api.MarketplaceNote);
    unittest.expect(
      o.proposalRevisionNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateAction!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdatePrivateAuctionProposalRequest--;
}

core.List<core.int> buildUnnamed2636() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2636(core.List<core.int> o) {
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

core.List<core.String> buildUnnamed2637() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2637(core.List<core.String> o) {
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
  unittest.group('obj-schema-AccountBidderLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountBidderLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountBidderLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountBidderLocation(od as api.AccountBidderLocation);
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

  unittest.group('obj-schema-AccountsList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAccountsList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AccountsList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAccountsList(od as api.AccountsList);
    });
  });

  unittest.group('obj-schema-AddOrderDealsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddOrderDealsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddOrderDealsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddOrderDealsRequest(od as api.AddOrderDealsRequest);
    });
  });

  unittest.group('obj-schema-AddOrderDealsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddOrderDealsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddOrderDealsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddOrderDealsResponse(od as api.AddOrderDealsResponse);
    });
  });

  unittest.group('obj-schema-AddOrderNotesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddOrderNotesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddOrderNotesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddOrderNotesRequest(od as api.AddOrderNotesRequest);
    });
  });

  unittest.group('obj-schema-AddOrderNotesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAddOrderNotesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AddOrderNotesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAddOrderNotesResponse(od as api.AddOrderNotesResponse);
    });
  });

  unittest.group('obj-schema-BillingInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBillingInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BillingInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBillingInfo(od as api.BillingInfo);
    });
  });

  unittest.group('obj-schema-BillingInfoList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBillingInfoList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BillingInfoList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBillingInfoList(od as api.BillingInfoList);
    });
  });

  unittest.group('obj-schema-Budget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBudget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Budget.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBudget(od as api.Budget);
    });
  });

  unittest.group('obj-schema-Buyer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBuyer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Buyer.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBuyer(od as api.Buyer);
    });
  });

  unittest.group('obj-schema-ContactInformation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContactInformation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ContactInformation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkContactInformation(od as api.ContactInformation);
    });
  });

  unittest.group('obj-schema-CreateOrdersRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateOrdersRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateOrdersRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateOrdersRequest(od as api.CreateOrdersRequest);
    });
  });

  unittest.group('obj-schema-CreateOrdersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateOrdersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateOrdersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateOrdersResponse(od as api.CreateOrdersResponse);
    });
  });

  unittest.group('obj-schema-CreativeAdTechnologyProviders', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeAdTechnologyProviders();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeAdTechnologyProviders.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeAdTechnologyProviders(
          od as api.CreativeAdTechnologyProviders);
    });
  });

  unittest.group('obj-schema-CreativeCorrectionsContexts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeCorrectionsContexts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeCorrectionsContexts.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeCorrectionsContexts(od as api.CreativeCorrectionsContexts);
    });
  });

  unittest.group('obj-schema-CreativeCorrections', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeCorrections();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeCorrections.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeCorrections(od as api.CreativeCorrections);
    });
  });

  unittest.group('obj-schema-CreativeFilteringReasonsReasons', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeFilteringReasonsReasons();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeFilteringReasonsReasons.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeFilteringReasonsReasons(
          od as api.CreativeFilteringReasonsReasons);
    });
  });

  unittest.group('obj-schema-CreativeFilteringReasons', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeFilteringReasons();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeFilteringReasons.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeFilteringReasons(od as api.CreativeFilteringReasons);
    });
  });

  unittest.group('obj-schema-CreativeNativeAdAppIcon', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeNativeAdAppIcon();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeNativeAdAppIcon.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeNativeAdAppIcon(od as api.CreativeNativeAdAppIcon);
    });
  });

  unittest.group('obj-schema-CreativeNativeAdImage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeNativeAdImage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeNativeAdImage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeNativeAdImage(od as api.CreativeNativeAdImage);
    });
  });

  unittest.group('obj-schema-CreativeNativeAdLogo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeNativeAdLogo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeNativeAdLogo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeNativeAdLogo(od as api.CreativeNativeAdLogo);
    });
  });

  unittest.group('obj-schema-CreativeNativeAd', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeNativeAd();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeNativeAd.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeNativeAd(od as api.CreativeNativeAd);
    });
  });

  unittest.group('obj-schema-CreativeServingRestrictionsContexts', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeServingRestrictionsContexts();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeServingRestrictionsContexts.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeServingRestrictionsContexts(
          od as api.CreativeServingRestrictionsContexts);
    });
  });

  unittest.group('obj-schema-CreativeServingRestrictionsDisapprovalReasons',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeServingRestrictionsDisapprovalReasons();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeServingRestrictionsDisapprovalReasons.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeServingRestrictionsDisapprovalReasons(
          od as api.CreativeServingRestrictionsDisapprovalReasons);
    });
  });

  unittest.group('obj-schema-CreativeServingRestrictions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeServingRestrictions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeServingRestrictions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeServingRestrictions(od as api.CreativeServingRestrictions);
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

  unittest.group('obj-schema-CreativeDealIdsDealStatuses', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeDealIdsDealStatuses();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeDealIdsDealStatuses.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeDealIdsDealStatuses(od as api.CreativeDealIdsDealStatuses);
    });
  });

  unittest.group('obj-schema-CreativeDealIds', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativeDealIds();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativeDealIds.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativeDealIds(od as api.CreativeDealIds);
    });
  });

  unittest.group('obj-schema-CreativesList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreativesList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreativesList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreativesList(od as api.CreativesList);
    });
  });

  unittest.group('obj-schema-DealServingMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealServingMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealServingMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealServingMetadata(od as api.DealServingMetadata);
    });
  });

  unittest.group('obj-schema-DealServingMetadataDealPauseStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealServingMetadataDealPauseStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealServingMetadataDealPauseStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealServingMetadataDealPauseStatus(
          od as api.DealServingMetadataDealPauseStatus);
    });
  });

  unittest.group('obj-schema-DealTerms', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealTerms();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DealTerms.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDealTerms(od as api.DealTerms);
    });
  });

  unittest.group('obj-schema-DealTermsGuaranteedFixedPriceTerms', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealTermsGuaranteedFixedPriceTerms();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealTermsGuaranteedFixedPriceTerms.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealTermsGuaranteedFixedPriceTerms(
          od as api.DealTermsGuaranteedFixedPriceTerms);
    });
  });

  unittest.group('obj-schema-DealTermsGuaranteedFixedPriceTermsBillingInfo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealTermsGuaranteedFixedPriceTermsBillingInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealTermsGuaranteedFixedPriceTermsBillingInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealTermsGuaranteedFixedPriceTermsBillingInfo(
          od as api.DealTermsGuaranteedFixedPriceTermsBillingInfo);
    });
  });

  unittest.group('obj-schema-DealTermsNonGuaranteedAuctionTerms', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealTermsNonGuaranteedAuctionTerms();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealTermsNonGuaranteedAuctionTerms.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealTermsNonGuaranteedAuctionTerms(
          od as api.DealTermsNonGuaranteedAuctionTerms);
    });
  });

  unittest.group('obj-schema-DealTermsNonGuaranteedFixedPriceTerms', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealTermsNonGuaranteedFixedPriceTerms();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealTermsNonGuaranteedFixedPriceTerms.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealTermsNonGuaranteedFixedPriceTerms(
          od as api.DealTermsNonGuaranteedFixedPriceTerms);
    });
  });

  unittest.group('obj-schema-DealTermsRubiconNonGuaranteedTerms', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDealTermsRubiconNonGuaranteedTerms();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DealTermsRubiconNonGuaranteedTerms.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDealTermsRubiconNonGuaranteedTerms(
          od as api.DealTermsRubiconNonGuaranteedTerms);
    });
  });

  unittest.group('obj-schema-DeleteOrderDealsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteOrderDealsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteOrderDealsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteOrderDealsRequest(od as api.DeleteOrderDealsRequest);
    });
  });

  unittest.group('obj-schema-DeleteOrderDealsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeleteOrderDealsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeleteOrderDealsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeleteOrderDealsResponse(od as api.DeleteOrderDealsResponse);
    });
  });

  unittest.group('obj-schema-DeliveryControl', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeliveryControl();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeliveryControl.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeliveryControl(od as api.DeliveryControl);
    });
  });

  unittest.group('obj-schema-DeliveryControlFrequencyCap', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeliveryControlFrequencyCap();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeliveryControlFrequencyCap.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeliveryControlFrequencyCap(od as api.DeliveryControlFrequencyCap);
    });
  });

  unittest.group('obj-schema-Dimension', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimension();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Dimension.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDimension(od as api.Dimension);
    });
  });

  unittest.group('obj-schema-DimensionDimensionValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDimensionDimensionValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DimensionDimensionValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDimensionDimensionValue(od as api.DimensionDimensionValue);
    });
  });

  unittest.group('obj-schema-EditAllOrderDealsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEditAllOrderDealsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EditAllOrderDealsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEditAllOrderDealsRequest(od as api.EditAllOrderDealsRequest);
    });
  });

  unittest.group('obj-schema-EditAllOrderDealsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEditAllOrderDealsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EditAllOrderDealsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEditAllOrderDealsResponse(od as api.EditAllOrderDealsResponse);
    });
  });

  unittest.group('obj-schema-GetOffersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetOffersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetOffersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetOffersResponse(od as api.GetOffersResponse);
    });
  });

  unittest.group('obj-schema-GetOrderDealsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetOrderDealsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetOrderDealsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetOrderDealsResponse(od as api.GetOrderDealsResponse);
    });
  });

  unittest.group('obj-schema-GetOrderNotesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetOrderNotesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetOrderNotesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetOrderNotesResponse(od as api.GetOrderNotesResponse);
    });
  });

  unittest.group('obj-schema-GetOrdersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetOrdersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetOrdersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetOrdersResponse(od as api.GetOrdersResponse);
    });
  });

  unittest.group('obj-schema-GetPublisherProfilesByAccountIdResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetPublisherProfilesByAccountIdResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetPublisherProfilesByAccountIdResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetPublisherProfilesByAccountIdResponse(
          od as api.GetPublisherProfilesByAccountIdResponse);
    });
  });

  unittest.group('obj-schema-MarketplaceDeal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMarketplaceDeal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MarketplaceDeal.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMarketplaceDeal(od as api.MarketplaceDeal);
    });
  });

  unittest.group('obj-schema-MarketplaceDealParty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMarketplaceDealParty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MarketplaceDealParty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMarketplaceDealParty(od as api.MarketplaceDealParty);
    });
  });

  unittest.group('obj-schema-MarketplaceLabel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMarketplaceLabel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MarketplaceLabel.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMarketplaceLabel(od as api.MarketplaceLabel);
    });
  });

  unittest.group('obj-schema-MarketplaceNote', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMarketplaceNote();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MarketplaceNote.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMarketplaceNote(od as api.MarketplaceNote);
    });
  });

  unittest.group('obj-schema-MobileApplication', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMobileApplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MobileApplication.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMobileApplication(od as api.MobileApplication);
    });
  });

  unittest.group('obj-schema-PerformanceReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerformanceReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PerformanceReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPerformanceReport(od as api.PerformanceReport);
    });
  });

  unittest.group('obj-schema-PerformanceReportList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPerformanceReportList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PerformanceReportList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPerformanceReportList(od as api.PerformanceReportList);
    });
  });

  unittest.group('obj-schema-PretargetingConfigDimensions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPretargetingConfigDimensions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PretargetingConfigDimensions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPretargetingConfigDimensions(od as api.PretargetingConfigDimensions);
    });
  });

  unittest.group('obj-schema-PretargetingConfigExcludedPlacements', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPretargetingConfigExcludedPlacements();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PretargetingConfigExcludedPlacements.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPretargetingConfigExcludedPlacements(
          od as api.PretargetingConfigExcludedPlacements);
    });
  });

  unittest.group('obj-schema-PretargetingConfigPlacements', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPretargetingConfigPlacements();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PretargetingConfigPlacements.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPretargetingConfigPlacements(od as api.PretargetingConfigPlacements);
    });
  });

  unittest.group('obj-schema-PretargetingConfigVideoPlayerSizes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPretargetingConfigVideoPlayerSizes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PretargetingConfigVideoPlayerSizes.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPretargetingConfigVideoPlayerSizes(
          od as api.PretargetingConfigVideoPlayerSizes);
    });
  });

  unittest.group('obj-schema-PretargetingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPretargetingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PretargetingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPretargetingConfig(od as api.PretargetingConfig);
    });
  });

  unittest.group('obj-schema-PretargetingConfigList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPretargetingConfigList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PretargetingConfigList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPretargetingConfigList(od as api.PretargetingConfigList);
    });
  });

  unittest.group('obj-schema-Price', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Price.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPrice(od as api.Price);
    });
  });

  unittest.group('obj-schema-PricePerBuyer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPricePerBuyer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PricePerBuyer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPricePerBuyer(od as api.PricePerBuyer);
    });
  });

  unittest.group('obj-schema-PrivateData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPrivateData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PrivateData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPrivateData(od as api.PrivateData);
    });
  });

  unittest.group('obj-schema-Product', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProduct();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Product.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProduct(od as api.Product);
    });
  });

  unittest.group('obj-schema-Proposal', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProposal();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Proposal.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProposal(od as api.Proposal);
    });
  });

  unittest.group('obj-schema-PublisherProfileApiProto', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublisherProfileApiProto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublisherProfileApiProto.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublisherProfileApiProto(od as api.PublisherProfileApiProto);
    });
  });

  unittest.group('obj-schema-PublisherProvidedForecast', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublisherProvidedForecast();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublisherProvidedForecast.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublisherProvidedForecast(od as api.PublisherProvidedForecast);
    });
  });

  unittest.group('obj-schema-Seller', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSeller();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Seller.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSeller(od as api.Seller);
    });
  });

  unittest.group('obj-schema-SharedTargeting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSharedTargeting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SharedTargeting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSharedTargeting(od as api.SharedTargeting);
    });
  });

  unittest.group('obj-schema-TargetingValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValue(od as api.TargetingValue);
    });
  });

  unittest.group('obj-schema-TargetingValueCreativeSize', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueCreativeSize();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueCreativeSize.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueCreativeSize(od as api.TargetingValueCreativeSize);
    });
  });

  unittest.group('obj-schema-TargetingValueDayPartTargeting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueDayPartTargeting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueDayPartTargeting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueDayPartTargeting(
          od as api.TargetingValueDayPartTargeting);
    });
  });

  unittest.group('obj-schema-TargetingValueDayPartTargetingDayPart', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueDayPartTargetingDayPart();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueDayPartTargetingDayPart.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueDayPartTargetingDayPart(
          od as api.TargetingValueDayPartTargetingDayPart);
    });
  });

  unittest.group('obj-schema-TargetingValueDemogAgeCriteria', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueDemogAgeCriteria();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueDemogAgeCriteria.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueDemogAgeCriteria(
          od as api.TargetingValueDemogAgeCriteria);
    });
  });

  unittest.group('obj-schema-TargetingValueDemogGenderCriteria', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueDemogGenderCriteria();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueDemogGenderCriteria.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueDemogGenderCriteria(
          od as api.TargetingValueDemogGenderCriteria);
    });
  });

  unittest.group('obj-schema-TargetingValueRequestPlatformTargeting', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueRequestPlatformTargeting();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueRequestPlatformTargeting.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueRequestPlatformTargeting(
          od as api.TargetingValueRequestPlatformTargeting);
    });
  });

  unittest.group('obj-schema-TargetingValueSize', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTargetingValueSize();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TargetingValueSize.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTargetingValueSize(od as api.TargetingValueSize);
    });
  });

  unittest.group('obj-schema-UpdatePrivateAuctionProposalRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdatePrivateAuctionProposalRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdatePrivateAuctionProposalRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdatePrivateAuctionProposalRequest(
          od as api.UpdatePrivateAuctionProposalRequest);
    });
  });

  unittest.group('resource-AccountsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).accounts;
      var arg_id = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
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
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_id, $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).accounts;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("accounts"),
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
        var resp = convert.json.encode(buildAccountsList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkAccountsList(response as api.AccountsList);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).accounts;
      var arg_request = buildAccount();
      var arg_id = 42;
      var arg_confirmUnsafeAccountChange = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Account.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAccount(obj as api.Account);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
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
          queryMap["confirmUnsafeAccountChange"]!.first,
          unittest.equals("$arg_confirmUnsafeAccountChange"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_id,
          confirmUnsafeAccountChange: arg_confirmUnsafeAccountChange,
          $fields: arg_$fields);
      checkAccount(response as api.Account);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).accounts;
      var arg_request = buildAccount();
      var arg_id = 42;
      var arg_confirmUnsafeAccountChange = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Account.fromJson(json as core.Map<core.String, core.dynamic>);
        checkAccount(obj as api.Account);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("accounts/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
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
          queryMap["confirmUnsafeAccountChange"]!.first,
          unittest.equals("$arg_confirmUnsafeAccountChange"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildAccount());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_id,
          confirmUnsafeAccountChange: arg_confirmUnsafeAccountChange,
          $fields: arg_$fields);
      checkAccount(response as api.Account);
    });
  });

  unittest.group('resource-BillingInfoResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).billingInfo;
      var arg_accountId = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("billinginfo/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
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
        var resp = convert.json.encode(buildBillingInfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, $fields: arg_$fields);
      checkBillingInfo(response as api.BillingInfo);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).billingInfo;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("billinginfo"),
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
        var resp = convert.json.encode(buildBillingInfoList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkBillingInfoList(response as api.BillingInfoList);
    });
  });

  unittest.group('resource-BudgetResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).budget;
      var arg_accountId = 'foo';
      var arg_billingId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("billinginfo/"),
        );
        pathOffset += 12;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_billingId'),
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
        var resp = convert.json.encode(buildBudget());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_accountId, arg_billingId, $fields: arg_$fields);
      checkBudget(response as api.Budget);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).budget;
      var arg_request = buildBudget();
      var arg_accountId = 'foo';
      var arg_billingId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Budget.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBudget(obj as api.Budget);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("billinginfo/"),
        );
        pathOffset += 12;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_billingId'),
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
        var resp = convert.json.encode(buildBudget());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_accountId, arg_billingId,
          $fields: arg_$fields);
      checkBudget(response as api.Budget);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).budget;
      var arg_request = buildBudget();
      var arg_accountId = 'foo';
      var arg_billingId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Budget.fromJson(json as core.Map<core.String, core.dynamic>);
        checkBudget(obj as api.Budget);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("billinginfo/"),
        );
        pathOffset += 12;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_billingId'),
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
        var resp = convert.json.encode(buildBudget());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_billingId,
          $fields: arg_$fields);
      checkBudget(response as api.Budget);
    });
  });

  unittest.group('resource-CreativesResource', () {
    unittest.test('method--addDeal', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).creatives;
      var arg_accountId = 42;
      var arg_buyerCreativeId = 'foo';
      var arg_dealId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("creatives/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/addDeal/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buyerCreativeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/addDeal/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_dealId'),
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
      await res.addDeal(arg_accountId, arg_buyerCreativeId, arg_dealId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).creatives;
      var arg_accountId = 42;
      var arg_buyerCreativeId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("creatives/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buyerCreativeId'),
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
        var resp = convert.json.encode(buildCreative());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_accountId, arg_buyerCreativeId,
          $fields: arg_$fields);
      checkCreative(response as api.Creative);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).creatives;
      var arg_request = buildCreative();
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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("creatives"),
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
        var resp = convert.json.encode(buildCreative());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkCreative(response as api.Creative);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).creatives;
      var arg_accountId = buildUnnamed2636();
      var arg_buyerCreativeId = buildUnnamed2637();
      var arg_dealsStatusFilter = 'foo';
      var arg_maxResults = 42;
      var arg_openAuctionStatusFilter = 'foo';
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("creatives"),
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
          queryMap["accountId"]!.map(core.int.parse).toList(),
          unittest.equals(arg_accountId),
        );
        unittest.expect(
          queryMap["buyerCreativeId"]!,
          unittest.equals(arg_buyerCreativeId),
        );
        unittest.expect(
          queryMap["dealsStatusFilter"]!.first,
          unittest.equals(arg_dealsStatusFilter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["openAuctionStatusFilter"]!.first,
          unittest.equals(arg_openAuctionStatusFilter),
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
        var resp = convert.json.encode(buildCreativesList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          accountId: arg_accountId,
          buyerCreativeId: arg_buyerCreativeId,
          dealsStatusFilter: arg_dealsStatusFilter,
          maxResults: arg_maxResults,
          openAuctionStatusFilter: arg_openAuctionStatusFilter,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkCreativesList(response as api.CreativesList);
    });

    unittest.test('method--listDeals', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).creatives;
      var arg_accountId = 42;
      var arg_buyerCreativeId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("creatives/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/listDeals', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buyerCreativeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/listDeals"),
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
        var resp = convert.json.encode(buildCreativeDealIds());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.listDeals(arg_accountId, arg_buyerCreativeId,
          $fields: arg_$fields);
      checkCreativeDealIds(response as api.CreativeDealIds);
    });

    unittest.test('method--removeDeal', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).creatives;
      var arg_accountId = 42;
      var arg_buyerCreativeId = 'foo';
      var arg_dealId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("creatives/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/removeDeal/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_buyerCreativeId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/removeDeal/"),
        );
        pathOffset += 12;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_dealId'),
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
      await res.removeDeal(arg_accountId, arg_buyerCreativeId, arg_dealId,
          $fields: arg_$fields);
    });
  });

  unittest.group('resource-MarketplacedealsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplacedeals;
      var arg_request = buildDeleteOrderDealsRequest();
      var arg_proposalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DeleteOrderDealsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDeleteOrderDealsRequest(obj as api.DeleteOrderDealsRequest);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/deals/delete', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/deals/delete"),
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
        var resp = convert.json.encode(buildDeleteOrderDealsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_request, arg_proposalId, $fields: arg_$fields);
      checkDeleteOrderDealsResponse(response as api.DeleteOrderDealsResponse);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplacedeals;
      var arg_request = buildAddOrderDealsRequest();
      var arg_proposalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AddOrderDealsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAddOrderDealsRequest(obj as api.AddOrderDealsRequest);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/deals/insert', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/deals/insert"),
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
        var resp = convert.json.encode(buildAddOrderDealsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_proposalId, $fields: arg_$fields);
      checkAddOrderDealsResponse(response as api.AddOrderDealsResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplacedeals;
      var arg_proposalId = 'foo';
      var arg_pqlQuery = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/deals', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/deals"),
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
          queryMap["pqlQuery"]!.first,
          unittest.equals(arg_pqlQuery),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetOrderDealsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_proposalId,
          pqlQuery: arg_pqlQuery, $fields: arg_$fields);
      checkGetOrderDealsResponse(response as api.GetOrderDealsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplacedeals;
      var arg_request = buildEditAllOrderDealsRequest();
      var arg_proposalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.EditAllOrderDealsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkEditAllOrderDealsRequest(obj as api.EditAllOrderDealsRequest);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/deals/update', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/deals/update"),
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
        var resp = convert.json.encode(buildEditAllOrderDealsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.update(arg_request, arg_proposalId, $fields: arg_$fields);
      checkEditAllOrderDealsResponse(response as api.EditAllOrderDealsResponse);
    });
  });

  unittest.group('resource-MarketplacenotesResource', () {
    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplacenotes;
      var arg_request = buildAddOrderNotesRequest();
      var arg_proposalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AddOrderNotesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAddOrderNotesRequest(obj as api.AddOrderNotesRequest);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/notes/insert', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/notes/insert"),
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
        var resp = convert.json.encode(buildAddOrderNotesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_proposalId, $fields: arg_$fields);
      checkAddOrderNotesResponse(response as api.AddOrderNotesResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplacenotes;
      var arg_proposalId = 'foo';
      var arg_pqlQuery = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/notes', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/notes"),
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
          queryMap["pqlQuery"]!.first,
          unittest.equals(arg_pqlQuery),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetOrderNotesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_proposalId,
          pqlQuery: arg_pqlQuery, $fields: arg_$fields);
      checkGetOrderNotesResponse(response as api.GetOrderNotesResponse);
    });
  });

  unittest.group('resource-MarketplaceprivateauctionResource', () {
    unittest.test('method--updateproposal', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).marketplaceprivateauction;
      var arg_request = buildUpdatePrivateAuctionProposalRequest();
      var arg_privateAuctionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdatePrivateAuctionProposalRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdatePrivateAuctionProposalRequest(
            obj as api.UpdatePrivateAuctionProposalRequest);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("privateauction/"),
        );
        pathOffset += 15;
        index = path.indexOf('/updateproposal', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_privateAuctionId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/updateproposal"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.updateproposal(arg_request, arg_privateAuctionId,
          $fields: arg_$fields);
    });
  });

  unittest.group('resource-PerformanceReportResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).performanceReport;
      var arg_accountId = 'foo';
      var arg_endDateTime = 'foo';
      var arg_startDateTime = 'foo';
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("performancereport"),
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
          queryMap["accountId"]!.first,
          unittest.equals(arg_accountId),
        );
        unittest.expect(
          queryMap["endDateTime"]!.first,
          unittest.equals(arg_endDateTime),
        );
        unittest.expect(
          queryMap["startDateTime"]!.first,
          unittest.equals(arg_startDateTime),
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
        var resp = convert.json.encode(buildPerformanceReportList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          arg_accountId, arg_endDateTime, arg_startDateTime,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkPerformanceReportList(response as api.PerformanceReportList);
    });
  });

  unittest.group('resource-PretargetingConfigResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pretargetingConfig;
      var arg_accountId = 'foo';
      var arg_configId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("pretargetingconfigs/"),
        );
        pathOffset += 20;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_configId'),
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
      await res.delete(arg_accountId, arg_configId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pretargetingConfig;
      var arg_accountId = 'foo';
      var arg_configId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("pretargetingconfigs/"),
        );
        pathOffset += 20;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_configId'),
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
        var resp = convert.json.encode(buildPretargetingConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_accountId, arg_configId, $fields: arg_$fields);
      checkPretargetingConfig(response as api.PretargetingConfig);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pretargetingConfig;
      var arg_request = buildPretargetingConfig();
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PretargetingConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPretargetingConfig(obj as api.PretargetingConfig);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("pretargetingconfigs/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
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
        var resp = convert.json.encode(buildPretargetingConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_accountId, $fields: arg_$fields);
      checkPretargetingConfig(response as api.PretargetingConfig);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pretargetingConfig;
      var arg_accountId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("pretargetingconfigs/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
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
        var resp = convert.json.encode(buildPretargetingConfigList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, $fields: arg_$fields);
      checkPretargetingConfigList(response as api.PretargetingConfigList);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pretargetingConfig;
      var arg_request = buildPretargetingConfig();
      var arg_accountId = 'foo';
      var arg_configId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PretargetingConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPretargetingConfig(obj as api.PretargetingConfig);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("pretargetingconfigs/"),
        );
        pathOffset += 20;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_configId'),
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
        var resp = convert.json.encode(buildPretargetingConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_accountId, arg_configId,
          $fields: arg_$fields);
      checkPretargetingConfig(response as api.PretargetingConfig);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pretargetingConfig;
      var arg_request = buildPretargetingConfig();
      var arg_accountId = 'foo';
      var arg_configId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PretargetingConfig.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPretargetingConfig(obj as api.PretargetingConfig);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("pretargetingconfigs/"),
        );
        pathOffset += 20;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_accountId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_configId'),
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
        var resp = convert.json.encode(buildPretargetingConfig());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_accountId, arg_configId,
          $fields: arg_$fields);
      checkPretargetingConfig(response as api.PretargetingConfig);
    });
  });

  unittest.group('resource-ProductsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).products;
      var arg_productId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("products/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_productId'),
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
        var resp = convert.json.encode(buildProduct());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_productId, $fields: arg_$fields);
      checkProduct(response as api.Product);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).products;
      var arg_pqlQuery = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("products/search"),
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
          queryMap["pqlQuery"]!.first,
          unittest.equals(arg_pqlQuery),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetOffersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.search(pqlQuery: arg_pqlQuery, $fields: arg_$fields);
      checkGetOffersResponse(response as api.GetOffersResponse);
    });
  });

  unittest.group('resource-ProposalsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).proposals;
      var arg_proposalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
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
        var resp = convert.json.encode(buildProposal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_proposalId, $fields: arg_$fields);
      checkProposal(response as api.Proposal);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).proposals;
      var arg_request = buildCreateOrdersRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateOrdersRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateOrdersRequest(obj as api.CreateOrdersRequest);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("proposals/insert"),
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
        var resp = convert.json.encode(buildCreateOrdersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, $fields: arg_$fields);
      checkCreateOrdersResponse(response as api.CreateOrdersResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).proposals;
      var arg_request = buildProposal();
      var arg_proposalId = 'foo';
      var arg_revisionNumber = 'foo';
      var arg_updateAction = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Proposal.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProposal(obj as api.Proposal);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_revisionNumber'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_updateAction'),
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
        var resp = convert.json.encode(buildProposal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_proposalId, arg_revisionNumber, arg_updateAction,
          $fields: arg_$fields);
      checkProposal(response as api.Proposal);
    });

    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).proposals;
      var arg_pqlQuery = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("proposals/search"),
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
          queryMap["pqlQuery"]!.first,
          unittest.equals(arg_pqlQuery),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetOrdersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.search(pqlQuery: arg_pqlQuery, $fields: arg_$fields);
      checkGetOrdersResponse(response as api.GetOrdersResponse);
    });

    unittest.test('method--setupcomplete', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).proposals;
      var arg_proposalId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/setupcomplete', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/setupcomplete"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.setupcomplete(arg_proposalId, $fields: arg_$fields);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).proposals;
      var arg_request = buildProposal();
      var arg_proposalId = 'foo';
      var arg_revisionNumber = 'foo';
      var arg_updateAction = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Proposal.fromJson(json as core.Map<core.String, core.dynamic>);
        checkProposal(obj as api.Proposal);

        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("proposals/"),
        );
        pathOffset += 10;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_proposalId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_revisionNumber'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_updateAction'),
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
        var resp = convert.json.encode(buildProposal());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_proposalId, arg_revisionNumber, arg_updateAction,
          $fields: arg_$fields);
      checkProposal(response as api.Proposal);
    });
  });

  unittest.group('resource-PubprofilesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExchangeBuyerApi(mock).pubprofiles;
      var arg_accountId = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          unittest.equals("adexchangebuyer/v1.4/"),
        );
        pathOffset += 21;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("publisher/"),
        );
        pathOffset += 10;
        index = path.indexOf('/profiles', pathOffset);
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
        var resp =
            convert.json.encode(buildGetPublisherProfilesByAccountIdResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_accountId, $fields: arg_$fields);
      checkGetPublisherProfilesByAccountIdResponse(
          response as api.GetPublisherProfilesByAccountIdResponse);
    });
  });
}
