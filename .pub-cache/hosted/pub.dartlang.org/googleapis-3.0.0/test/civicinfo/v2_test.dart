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

import 'package:googleapis/civicinfo/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Source> buildUnnamed2812() {
  var o = <api.Source>[];
  o.add(buildSource());
  o.add(buildSource());
  return o;
}

void checkUnnamed2812(core.List<api.Source> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSource(o[0] as api.Source);
  checkSource(o[1] as api.Source);
}

core.int buildCounterAdministrationRegion = 0;
api.AdministrationRegion buildAdministrationRegion() {
  var o = api.AdministrationRegion();
  buildCounterAdministrationRegion++;
  if (buildCounterAdministrationRegion < 3) {
    o.electionAdministrationBody = buildAdministrativeBody();
    o.localJurisdiction = buildAdministrationRegion();
    o.name = 'foo';
    o.sources = buildUnnamed2812();
  }
  buildCounterAdministrationRegion--;
  return o;
}

void checkAdministrationRegion(api.AdministrationRegion o) {
  buildCounterAdministrationRegion++;
  if (buildCounterAdministrationRegion < 3) {
    checkAdministrativeBody(
        o.electionAdministrationBody! as api.AdministrativeBody);
    checkAdministrationRegion(o.localJurisdiction! as api.AdministrationRegion);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2812(o.sources!);
  }
  buildCounterAdministrationRegion--;
}

core.List<api.ElectionOfficial> buildUnnamed2813() {
  var o = <api.ElectionOfficial>[];
  o.add(buildElectionOfficial());
  o.add(buildElectionOfficial());
  return o;
}

void checkUnnamed2813(core.List<api.ElectionOfficial> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkElectionOfficial(o[0] as api.ElectionOfficial);
  checkElectionOfficial(o[1] as api.ElectionOfficial);
}

core.List<core.String> buildUnnamed2814() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2814(core.List<core.String> o) {
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

core.int buildCounterAdministrativeBody = 0;
api.AdministrativeBody buildAdministrativeBody() {
  var o = api.AdministrativeBody();
  buildCounterAdministrativeBody++;
  if (buildCounterAdministrativeBody < 3) {
    o.absenteeVotingInfoUrl = 'foo';
    o.ballotInfoUrl = 'foo';
    o.correspondenceAddress = buildSimpleAddressType();
    o.electionInfoUrl = 'foo';
    o.electionNoticeText = 'foo';
    o.electionNoticeUrl = 'foo';
    o.electionOfficials = buildUnnamed2813();
    o.electionRegistrationConfirmationUrl = 'foo';
    o.electionRegistrationUrl = 'foo';
    o.electionRulesUrl = 'foo';
    o.hoursOfOperation = 'foo';
    o.name = 'foo';
    o.physicalAddress = buildSimpleAddressType();
    o.voterServices = buildUnnamed2814();
    o.votingLocationFinderUrl = 'foo';
  }
  buildCounterAdministrativeBody--;
  return o;
}

void checkAdministrativeBody(api.AdministrativeBody o) {
  buildCounterAdministrativeBody++;
  if (buildCounterAdministrativeBody < 3) {
    unittest.expect(
      o.absenteeVotingInfoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ballotInfoUrl!,
      unittest.equals('foo'),
    );
    checkSimpleAddressType(o.correspondenceAddress! as api.SimpleAddressType);
    unittest.expect(
      o.electionInfoUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.electionNoticeText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.electionNoticeUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2813(o.electionOfficials!);
    unittest.expect(
      o.electionRegistrationConfirmationUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.electionRegistrationUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.electionRulesUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hoursOfOperation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSimpleAddressType(o.physicalAddress! as api.SimpleAddressType);
    checkUnnamed2814(o.voterServices!);
    unittest.expect(
      o.votingLocationFinderUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterAdministrativeBody--;
}

core.List<api.Channel> buildUnnamed2815() {
  var o = <api.Channel>[];
  o.add(buildChannel());
  o.add(buildChannel());
  return o;
}

void checkUnnamed2815(core.List<api.Channel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannel(o[0] as api.Channel);
  checkChannel(o[1] as api.Channel);
}

core.int buildCounterCandidate = 0;
api.Candidate buildCandidate() {
  var o = api.Candidate();
  buildCounterCandidate++;
  if (buildCounterCandidate < 3) {
    o.candidateUrl = 'foo';
    o.channels = buildUnnamed2815();
    o.email = 'foo';
    o.name = 'foo';
    o.orderOnBallot = 'foo';
    o.party = 'foo';
    o.phone = 'foo';
    o.photoUrl = 'foo';
  }
  buildCounterCandidate--;
  return o;
}

void checkCandidate(api.Candidate o) {
  buildCounterCandidate++;
  if (buildCounterCandidate < 3) {
    unittest.expect(
      o.candidateUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2815(o.channels!);
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderOnBallot!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.party!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.phone!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterCandidate--;
}

core.int buildCounterChannel = 0;
api.Channel buildChannel() {
  var o = api.Channel();
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    o.id = 'foo';
    o.type = 'foo';
  }
  buildCounterChannel--;
  return o;
}

void checkChannel(api.Channel o) {
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannel--;
}

core.List<api.Candidate> buildUnnamed2816() {
  var o = <api.Candidate>[];
  o.add(buildCandidate());
  o.add(buildCandidate());
  return o;
}

void checkUnnamed2816(core.List<api.Candidate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCandidate(o[0] as api.Candidate);
  checkCandidate(o[1] as api.Candidate);
}

core.List<core.String> buildUnnamed2817() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2817(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2818() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2818(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2819() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2819(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2820() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2820(core.List<core.String> o) {
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

core.List<api.Source> buildUnnamed2821() {
  var o = <api.Source>[];
  o.add(buildSource());
  o.add(buildSource());
  return o;
}

void checkUnnamed2821(core.List<api.Source> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSource(o[0] as api.Source);
  checkSource(o[1] as api.Source);
}

core.int buildCounterContest = 0;
api.Contest buildContest() {
  var o = api.Contest();
  buildCounterContest++;
  if (buildCounterContest < 3) {
    o.ballotPlacement = 'foo';
    o.ballotTitle = 'foo';
    o.candidates = buildUnnamed2816();
    o.district = buildElectoralDistrict();
    o.electorateSpecifications = 'foo';
    o.level = buildUnnamed2817();
    o.numberElected = 'foo';
    o.numberVotingFor = 'foo';
    o.office = 'foo';
    o.primaryParties = buildUnnamed2818();
    o.primaryParty = 'foo';
    o.referendumBallotResponses = buildUnnamed2819();
    o.referendumBrief = 'foo';
    o.referendumConStatement = 'foo';
    o.referendumEffectOfAbstain = 'foo';
    o.referendumPassageThreshold = 'foo';
    o.referendumProStatement = 'foo';
    o.referendumSubtitle = 'foo';
    o.referendumText = 'foo';
    o.referendumTitle = 'foo';
    o.referendumUrl = 'foo';
    o.roles = buildUnnamed2820();
    o.sources = buildUnnamed2821();
    o.special = 'foo';
    o.type = 'foo';
  }
  buildCounterContest--;
  return o;
}

void checkContest(api.Contest o) {
  buildCounterContest++;
  if (buildCounterContest < 3) {
    unittest.expect(
      o.ballotPlacement!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ballotTitle!,
      unittest.equals('foo'),
    );
    checkUnnamed2816(o.candidates!);
    checkElectoralDistrict(o.district! as api.ElectoralDistrict);
    unittest.expect(
      o.electorateSpecifications!,
      unittest.equals('foo'),
    );
    checkUnnamed2817(o.level!);
    unittest.expect(
      o.numberElected!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numberVotingFor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.office!,
      unittest.equals('foo'),
    );
    checkUnnamed2818(o.primaryParties!);
    unittest.expect(
      o.primaryParty!,
      unittest.equals('foo'),
    );
    checkUnnamed2819(o.referendumBallotResponses!);
    unittest.expect(
      o.referendumBrief!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumConStatement!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumEffectOfAbstain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumPassageThreshold!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumProStatement!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumSubtitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumTitle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referendumUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2820(o.roles!);
    checkUnnamed2821(o.sources!);
    unittest.expect(
      o.special!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterContest--;
}

core.List<api.DivisionSearchResult> buildUnnamed2822() {
  var o = <api.DivisionSearchResult>[];
  o.add(buildDivisionSearchResult());
  o.add(buildDivisionSearchResult());
  return o;
}

void checkUnnamed2822(core.List<api.DivisionSearchResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDivisionSearchResult(o[0] as api.DivisionSearchResult);
  checkDivisionSearchResult(o[1] as api.DivisionSearchResult);
}

core.int buildCounterDivisionSearchResponse = 0;
api.DivisionSearchResponse buildDivisionSearchResponse() {
  var o = api.DivisionSearchResponse();
  buildCounterDivisionSearchResponse++;
  if (buildCounterDivisionSearchResponse < 3) {
    o.kind = 'foo';
    o.results = buildUnnamed2822();
  }
  buildCounterDivisionSearchResponse--;
  return o;
}

void checkDivisionSearchResponse(api.DivisionSearchResponse o) {
  buildCounterDivisionSearchResponse++;
  if (buildCounterDivisionSearchResponse < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed2822(o.results!);
  }
  buildCounterDivisionSearchResponse--;
}

core.List<core.String> buildUnnamed2823() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2823(core.List<core.String> o) {
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

core.int buildCounterDivisionSearchResult = 0;
api.DivisionSearchResult buildDivisionSearchResult() {
  var o = api.DivisionSearchResult();
  buildCounterDivisionSearchResult++;
  if (buildCounterDivisionSearchResult < 3) {
    o.aliases = buildUnnamed2823();
    o.name = 'foo';
    o.ocdId = 'foo';
  }
  buildCounterDivisionSearchResult--;
  return o;
}

void checkDivisionSearchResult(api.DivisionSearchResult o) {
  buildCounterDivisionSearchResult++;
  if (buildCounterDivisionSearchResult < 3) {
    checkUnnamed2823(o.aliases!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ocdId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDivisionSearchResult--;
}

core.int buildCounterElection = 0;
api.Election buildElection() {
  var o = api.Election();
  buildCounterElection++;
  if (buildCounterElection < 3) {
    o.electionDay = 'foo';
    o.id = 'foo';
    o.name = 'foo';
    o.ocdDivisionId = 'foo';
  }
  buildCounterElection--;
  return o;
}

void checkElection(api.Election o) {
  buildCounterElection++;
  if (buildCounterElection < 3) {
    unittest.expect(
      o.electionDay!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ocdDivisionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterElection--;
}

core.int buildCounterElectionOfficial = 0;
api.ElectionOfficial buildElectionOfficial() {
  var o = api.ElectionOfficial();
  buildCounterElectionOfficial++;
  if (buildCounterElectionOfficial < 3) {
    o.emailAddress = 'foo';
    o.faxNumber = 'foo';
    o.name = 'foo';
    o.officePhoneNumber = 'foo';
    o.title = 'foo';
  }
  buildCounterElectionOfficial--;
  return o;
}

void checkElectionOfficial(api.ElectionOfficial o) {
  buildCounterElectionOfficial++;
  if (buildCounterElectionOfficial < 3) {
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.faxNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.officePhoneNumber!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterElectionOfficial--;
}

core.List<api.Election> buildUnnamed2824() {
  var o = <api.Election>[];
  o.add(buildElection());
  o.add(buildElection());
  return o;
}

void checkUnnamed2824(core.List<api.Election> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkElection(o[0] as api.Election);
  checkElection(o[1] as api.Election);
}

core.int buildCounterElectionsQueryResponse = 0;
api.ElectionsQueryResponse buildElectionsQueryResponse() {
  var o = api.ElectionsQueryResponse();
  buildCounterElectionsQueryResponse++;
  if (buildCounterElectionsQueryResponse < 3) {
    o.elections = buildUnnamed2824();
    o.kind = 'foo';
  }
  buildCounterElectionsQueryResponse--;
  return o;
}

void checkElectionsQueryResponse(api.ElectionsQueryResponse o) {
  buildCounterElectionsQueryResponse++;
  if (buildCounterElectionsQueryResponse < 3) {
    checkUnnamed2824(o.elections!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterElectionsQueryResponse--;
}

core.int buildCounterElectoralDistrict = 0;
api.ElectoralDistrict buildElectoralDistrict() {
  var o = api.ElectoralDistrict();
  buildCounterElectoralDistrict++;
  if (buildCounterElectoralDistrict < 3) {
    o.id = 'foo';
    o.name = 'foo';
    o.scope = 'foo';
  }
  buildCounterElectoralDistrict--;
  return o;
}

void checkElectoralDistrict(api.ElectoralDistrict o) {
  buildCounterElectoralDistrict++;
  if (buildCounterElectoralDistrict < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scope!,
      unittest.equals('foo'),
    );
  }
  buildCounterElectoralDistrict--;
}

core.List<core.String> buildUnnamed2825() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2825(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed2826() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2826(core.List<core.int> o) {
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

core.int buildCounterGeographicDivision = 0;
api.GeographicDivision buildGeographicDivision() {
  var o = api.GeographicDivision();
  buildCounterGeographicDivision++;
  if (buildCounterGeographicDivision < 3) {
    o.alsoKnownAs = buildUnnamed2825();
    o.name = 'foo';
    o.officeIndices = buildUnnamed2826();
  }
  buildCounterGeographicDivision--;
  return o;
}

void checkGeographicDivision(api.GeographicDivision o) {
  buildCounterGeographicDivision++;
  if (buildCounterGeographicDivision < 3) {
    checkUnnamed2825(o.alsoKnownAs!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2826(o.officeIndices!);
  }
  buildCounterGeographicDivision--;
}

core.List<core.String> buildUnnamed2827() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2827(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed2828() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed2828(core.List<core.int> o) {
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

core.List<core.String> buildUnnamed2829() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2829(core.List<core.String> o) {
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

core.List<api.Source> buildUnnamed2830() {
  var o = <api.Source>[];
  o.add(buildSource());
  o.add(buildSource());
  return o;
}

void checkUnnamed2830(core.List<api.Source> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSource(o[0] as api.Source);
  checkSource(o[1] as api.Source);
}

core.int buildCounterOffice = 0;
api.Office buildOffice() {
  var o = api.Office();
  buildCounterOffice++;
  if (buildCounterOffice < 3) {
    o.divisionId = 'foo';
    o.levels = buildUnnamed2827();
    o.name = 'foo';
    o.officialIndices = buildUnnamed2828();
    o.roles = buildUnnamed2829();
    o.sources = buildUnnamed2830();
  }
  buildCounterOffice--;
  return o;
}

void checkOffice(api.Office o) {
  buildCounterOffice++;
  if (buildCounterOffice < 3) {
    unittest.expect(
      o.divisionId!,
      unittest.equals('foo'),
    );
    checkUnnamed2827(o.levels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed2828(o.officialIndices!);
    checkUnnamed2829(o.roles!);
    checkUnnamed2830(o.sources!);
  }
  buildCounterOffice--;
}

core.List<api.SimpleAddressType> buildUnnamed2831() {
  var o = <api.SimpleAddressType>[];
  o.add(buildSimpleAddressType());
  o.add(buildSimpleAddressType());
  return o;
}

void checkUnnamed2831(core.List<api.SimpleAddressType> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSimpleAddressType(o[0] as api.SimpleAddressType);
  checkSimpleAddressType(o[1] as api.SimpleAddressType);
}

core.List<api.Channel> buildUnnamed2832() {
  var o = <api.Channel>[];
  o.add(buildChannel());
  o.add(buildChannel());
  return o;
}

void checkUnnamed2832(core.List<api.Channel> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkChannel(o[0] as api.Channel);
  checkChannel(o[1] as api.Channel);
}

core.List<core.String> buildUnnamed2833() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2833(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2834() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2834(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2835() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2835(core.List<core.String> o) {
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

core.int buildCounterOfficial = 0;
api.Official buildOfficial() {
  var o = api.Official();
  buildCounterOfficial++;
  if (buildCounterOfficial < 3) {
    o.address = buildUnnamed2831();
    o.channels = buildUnnamed2832();
    o.emails = buildUnnamed2833();
    o.name = 'foo';
    o.party = 'foo';
    o.phones = buildUnnamed2834();
    o.photoUrl = 'foo';
    o.urls = buildUnnamed2835();
  }
  buildCounterOfficial--;
  return o;
}

void checkOfficial(api.Official o) {
  buildCounterOfficial++;
  if (buildCounterOfficial < 3) {
    checkUnnamed2831(o.address!);
    checkUnnamed2832(o.channels!);
    checkUnnamed2833(o.emails!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.party!,
      unittest.equals('foo'),
    );
    checkUnnamed2834(o.phones!);
    unittest.expect(
      o.photoUrl!,
      unittest.equals('foo'),
    );
    checkUnnamed2835(o.urls!);
  }
  buildCounterOfficial--;
}

core.List<api.Source> buildUnnamed2836() {
  var o = <api.Source>[];
  o.add(buildSource());
  o.add(buildSource());
  return o;
}

void checkUnnamed2836(core.List<api.Source> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSource(o[0] as api.Source);
  checkSource(o[1] as api.Source);
}

core.int buildCounterPollingLocation = 0;
api.PollingLocation buildPollingLocation() {
  var o = api.PollingLocation();
  buildCounterPollingLocation++;
  if (buildCounterPollingLocation < 3) {
    o.address = buildSimpleAddressType();
    o.endDate = 'foo';
    o.latitude = 42.0;
    o.longitude = 42.0;
    o.name = 'foo';
    o.notes = 'foo';
    o.pollingHours = 'foo';
    o.sources = buildUnnamed2836();
    o.startDate = 'foo';
    o.voterServices = 'foo';
  }
  buildCounterPollingLocation--;
  return o;
}

void checkPollingLocation(api.PollingLocation o) {
  buildCounterPollingLocation++;
  if (buildCounterPollingLocation < 3) {
    checkSimpleAddressType(o.address! as api.SimpleAddressType);
    unittest.expect(
      o.endDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.notes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pollingHours!,
      unittest.equals('foo'),
    );
    checkUnnamed2836(o.sources!);
    unittest.expect(
      o.startDate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.voterServices!,
      unittest.equals('foo'),
    );
  }
  buildCounterPollingLocation--;
}

core.Map<core.String, api.GeographicDivision> buildUnnamed2837() {
  var o = <core.String, api.GeographicDivision>{};
  o['x'] = buildGeographicDivision();
  o['y'] = buildGeographicDivision();
  return o;
}

void checkUnnamed2837(core.Map<core.String, api.GeographicDivision> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGeographicDivision(o['x']! as api.GeographicDivision);
  checkGeographicDivision(o['y']! as api.GeographicDivision);
}

core.List<api.Office> buildUnnamed2838() {
  var o = <api.Office>[];
  o.add(buildOffice());
  o.add(buildOffice());
  return o;
}

void checkUnnamed2838(core.List<api.Office> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOffice(o[0] as api.Office);
  checkOffice(o[1] as api.Office);
}

core.List<api.Official> buildUnnamed2839() {
  var o = <api.Official>[];
  o.add(buildOfficial());
  o.add(buildOfficial());
  return o;
}

void checkUnnamed2839(core.List<api.Official> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOfficial(o[0] as api.Official);
  checkOfficial(o[1] as api.Official);
}

core.int buildCounterRepresentativeInfoData = 0;
api.RepresentativeInfoData buildRepresentativeInfoData() {
  var o = api.RepresentativeInfoData();
  buildCounterRepresentativeInfoData++;
  if (buildCounterRepresentativeInfoData < 3) {
    o.divisions = buildUnnamed2837();
    o.offices = buildUnnamed2838();
    o.officials = buildUnnamed2839();
  }
  buildCounterRepresentativeInfoData--;
  return o;
}

void checkRepresentativeInfoData(api.RepresentativeInfoData o) {
  buildCounterRepresentativeInfoData++;
  if (buildCounterRepresentativeInfoData < 3) {
    checkUnnamed2837(o.divisions!);
    checkUnnamed2838(o.offices!);
    checkUnnamed2839(o.officials!);
  }
  buildCounterRepresentativeInfoData--;
}

core.Map<core.String, api.GeographicDivision> buildUnnamed2840() {
  var o = <core.String, api.GeographicDivision>{};
  o['x'] = buildGeographicDivision();
  o['y'] = buildGeographicDivision();
  return o;
}

void checkUnnamed2840(core.Map<core.String, api.GeographicDivision> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGeographicDivision(o['x']! as api.GeographicDivision);
  checkGeographicDivision(o['y']! as api.GeographicDivision);
}

core.List<api.Office> buildUnnamed2841() {
  var o = <api.Office>[];
  o.add(buildOffice());
  o.add(buildOffice());
  return o;
}

void checkUnnamed2841(core.List<api.Office> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOffice(o[0] as api.Office);
  checkOffice(o[1] as api.Office);
}

core.List<api.Official> buildUnnamed2842() {
  var o = <api.Official>[];
  o.add(buildOfficial());
  o.add(buildOfficial());
  return o;
}

void checkUnnamed2842(core.List<api.Official> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOfficial(o[0] as api.Official);
  checkOfficial(o[1] as api.Official);
}

core.int buildCounterRepresentativeInfoResponse = 0;
api.RepresentativeInfoResponse buildRepresentativeInfoResponse() {
  var o = api.RepresentativeInfoResponse();
  buildCounterRepresentativeInfoResponse++;
  if (buildCounterRepresentativeInfoResponse < 3) {
    o.divisions = buildUnnamed2840();
    o.kind = 'foo';
    o.normalizedInput = buildSimpleAddressType();
    o.offices = buildUnnamed2841();
    o.officials = buildUnnamed2842();
  }
  buildCounterRepresentativeInfoResponse--;
  return o;
}

void checkRepresentativeInfoResponse(api.RepresentativeInfoResponse o) {
  buildCounterRepresentativeInfoResponse++;
  if (buildCounterRepresentativeInfoResponse < 3) {
    checkUnnamed2840(o.divisions!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkSimpleAddressType(o.normalizedInput! as api.SimpleAddressType);
    checkUnnamed2841(o.offices!);
    checkUnnamed2842(o.officials!);
  }
  buildCounterRepresentativeInfoResponse--;
}

core.int buildCounterSimpleAddressType = 0;
api.SimpleAddressType buildSimpleAddressType() {
  var o = api.SimpleAddressType();
  buildCounterSimpleAddressType++;
  if (buildCounterSimpleAddressType < 3) {
    o.city = 'foo';
    o.line1 = 'foo';
    o.line2 = 'foo';
    o.line3 = 'foo';
    o.locationName = 'foo';
    o.state = 'foo';
    o.zip = 'foo';
  }
  buildCounterSimpleAddressType--;
  return o;
}

void checkSimpleAddressType(api.SimpleAddressType o) {
  buildCounterSimpleAddressType++;
  if (buildCounterSimpleAddressType < 3) {
    unittest.expect(
      o.city!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.line1!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.line2!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.line3!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.zip!,
      unittest.equals('foo'),
    );
  }
  buildCounterSimpleAddressType--;
}

core.int buildCounterSource = 0;
api.Source buildSource() {
  var o = api.Source();
  buildCounterSource++;
  if (buildCounterSource < 3) {
    o.name = 'foo';
    o.official = true;
  }
  buildCounterSource--;
  return o;
}

void checkSource(api.Source o) {
  buildCounterSource++;
  if (buildCounterSource < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.official!, unittest.isTrue);
  }
  buildCounterSource--;
}

core.List<api.Contest> buildUnnamed2843() {
  var o = <api.Contest>[];
  o.add(buildContest());
  o.add(buildContest());
  return o;
}

void checkUnnamed2843(core.List<api.Contest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkContest(o[0] as api.Contest);
  checkContest(o[1] as api.Contest);
}

core.List<api.PollingLocation> buildUnnamed2844() {
  var o = <api.PollingLocation>[];
  o.add(buildPollingLocation());
  o.add(buildPollingLocation());
  return o;
}

void checkUnnamed2844(core.List<api.PollingLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPollingLocation(o[0] as api.PollingLocation);
  checkPollingLocation(o[1] as api.PollingLocation);
}

core.List<api.PollingLocation> buildUnnamed2845() {
  var o = <api.PollingLocation>[];
  o.add(buildPollingLocation());
  o.add(buildPollingLocation());
  return o;
}

void checkUnnamed2845(core.List<api.PollingLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPollingLocation(o[0] as api.PollingLocation);
  checkPollingLocation(o[1] as api.PollingLocation);
}

core.List<api.Election> buildUnnamed2846() {
  var o = <api.Election>[];
  o.add(buildElection());
  o.add(buildElection());
  return o;
}

void checkUnnamed2846(core.List<api.Election> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkElection(o[0] as api.Election);
  checkElection(o[1] as api.Election);
}

core.List<api.PollingLocation> buildUnnamed2847() {
  var o = <api.PollingLocation>[];
  o.add(buildPollingLocation());
  o.add(buildPollingLocation());
  return o;
}

void checkUnnamed2847(core.List<api.PollingLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPollingLocation(o[0] as api.PollingLocation);
  checkPollingLocation(o[1] as api.PollingLocation);
}

core.List<api.AdministrationRegion> buildUnnamed2848() {
  var o = <api.AdministrationRegion>[];
  o.add(buildAdministrationRegion());
  o.add(buildAdministrationRegion());
  return o;
}

void checkUnnamed2848(core.List<api.AdministrationRegion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAdministrationRegion(o[0] as api.AdministrationRegion);
  checkAdministrationRegion(o[1] as api.AdministrationRegion);
}

core.int buildCounterVoterInfoResponse = 0;
api.VoterInfoResponse buildVoterInfoResponse() {
  var o = api.VoterInfoResponse();
  buildCounterVoterInfoResponse++;
  if (buildCounterVoterInfoResponse < 3) {
    o.contests = buildUnnamed2843();
    o.dropOffLocations = buildUnnamed2844();
    o.earlyVoteSites = buildUnnamed2845();
    o.election = buildElection();
    o.kind = 'foo';
    o.mailOnly = true;
    o.normalizedInput = buildSimpleAddressType();
    o.otherElections = buildUnnamed2846();
    o.pollingLocations = buildUnnamed2847();
    o.precinctId = 'foo';
    o.state = buildUnnamed2848();
  }
  buildCounterVoterInfoResponse--;
  return o;
}

void checkVoterInfoResponse(api.VoterInfoResponse o) {
  buildCounterVoterInfoResponse++;
  if (buildCounterVoterInfoResponse < 3) {
    checkUnnamed2843(o.contests!);
    checkUnnamed2844(o.dropOffLocations!);
    checkUnnamed2845(o.earlyVoteSites!);
    checkElection(o.election! as api.Election);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(o.mailOnly!, unittest.isTrue);
    checkSimpleAddressType(o.normalizedInput! as api.SimpleAddressType);
    checkUnnamed2846(o.otherElections!);
    checkUnnamed2847(o.pollingLocations!);
    unittest.expect(
      o.precinctId!,
      unittest.equals('foo'),
    );
    checkUnnamed2848(o.state!);
  }
  buildCounterVoterInfoResponse--;
}

core.List<core.String> buildUnnamed2849() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2849(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2850() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2850(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2851() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2851(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed2852() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed2852(core.List<core.String> o) {
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
  unittest.group('obj-schema-AdministrationRegion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdministrationRegion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdministrationRegion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdministrationRegion(od as api.AdministrationRegion);
    });
  });

  unittest.group('obj-schema-AdministrativeBody', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAdministrativeBody();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AdministrativeBody.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAdministrativeBody(od as api.AdministrativeBody);
    });
  });

  unittest.group('obj-schema-Candidate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCandidate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Candidate.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCandidate(od as api.Candidate);
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

  unittest.group('obj-schema-Contest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildContest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Contest.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkContest(od as api.Contest);
    });
  });

  unittest.group('obj-schema-DivisionSearchResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDivisionSearchResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DivisionSearchResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDivisionSearchResponse(od as api.DivisionSearchResponse);
    });
  });

  unittest.group('obj-schema-DivisionSearchResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDivisionSearchResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DivisionSearchResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDivisionSearchResult(od as api.DivisionSearchResult);
    });
  });

  unittest.group('obj-schema-Election', () {
    unittest.test('to-json--from-json', () async {
      var o = buildElection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Election.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkElection(od as api.Election);
    });
  });

  unittest.group('obj-schema-ElectionOfficial', () {
    unittest.test('to-json--from-json', () async {
      var o = buildElectionOfficial();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ElectionOfficial.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkElectionOfficial(od as api.ElectionOfficial);
    });
  });

  unittest.group('obj-schema-ElectionsQueryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildElectionsQueryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ElectionsQueryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkElectionsQueryResponse(od as api.ElectionsQueryResponse);
    });
  });

  unittest.group('obj-schema-ElectoralDistrict', () {
    unittest.test('to-json--from-json', () async {
      var o = buildElectoralDistrict();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ElectoralDistrict.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkElectoralDistrict(od as api.ElectoralDistrict);
    });
  });

  unittest.group('obj-schema-GeographicDivision', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGeographicDivision();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GeographicDivision.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGeographicDivision(od as api.GeographicDivision);
    });
  });

  unittest.group('obj-schema-Office', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOffice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Office.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOffice(od as api.Office);
    });
  });

  unittest.group('obj-schema-Official', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOfficial();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Official.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOfficial(od as api.Official);
    });
  });

  unittest.group('obj-schema-PollingLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPollingLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PollingLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPollingLocation(od as api.PollingLocation);
    });
  });

  unittest.group('obj-schema-RepresentativeInfoData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepresentativeInfoData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RepresentativeInfoData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRepresentativeInfoData(od as api.RepresentativeInfoData);
    });
  });

  unittest.group('obj-schema-RepresentativeInfoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRepresentativeInfoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RepresentativeInfoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRepresentativeInfoResponse(od as api.RepresentativeInfoResponse);
    });
  });

  unittest.group('obj-schema-SimpleAddressType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSimpleAddressType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SimpleAddressType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSimpleAddressType(od as api.SimpleAddressType);
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

  unittest.group('obj-schema-VoterInfoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVoterInfoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VoterInfoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVoterInfoResponse(od as api.VoterInfoResponse);
    });
  });

  unittest.group('resource-DivisionsResource', () {
    unittest.test('method--search', () async {
      var mock = HttpServerMock();
      var res = api.CivicInfoApi(mock).divisions;
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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("civicinfo/v2/divisions"),
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
        var resp = convert.json.encode(buildDivisionSearchResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.search(query: arg_query, $fields: arg_$fields);
      checkDivisionSearchResponse(response as api.DivisionSearchResponse);
    });
  });

  unittest.group('resource-ElectionsResource', () {
    unittest.test('method--electionQuery', () async {
      var mock = HttpServerMock();
      var res = api.CivicInfoApi(mock).elections;
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
          unittest.equals("civicinfo/v2/elections"),
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
        var resp = convert.json.encode(buildElectionsQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.electionQuery($fields: arg_$fields);
      checkElectionsQueryResponse(response as api.ElectionsQueryResponse);
    });

    unittest.test('method--voterInfoQuery', () async {
      var mock = HttpServerMock();
      var res = api.CivicInfoApi(mock).elections;
      var arg_address = 'foo';
      var arg_electionId = 'foo';
      var arg_officialOnly = true;
      var arg_returnAllAvailableData = true;
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
          unittest.equals("civicinfo/v2/voterinfo"),
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
          queryMap["address"]!.first,
          unittest.equals(arg_address),
        );
        unittest.expect(
          queryMap["electionId"]!.first,
          unittest.equals(arg_electionId),
        );
        unittest.expect(
          queryMap["officialOnly"]!.first,
          unittest.equals("$arg_officialOnly"),
        );
        unittest.expect(
          queryMap["returnAllAvailableData"]!.first,
          unittest.equals("$arg_returnAllAvailableData"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildVoterInfoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.voterInfoQuery(arg_address,
          electionId: arg_electionId,
          officialOnly: arg_officialOnly,
          returnAllAvailableData: arg_returnAllAvailableData,
          $fields: arg_$fields);
      checkVoterInfoResponse(response as api.VoterInfoResponse);
    });
  });

  unittest.group('resource-RepresentativesResource', () {
    unittest.test('method--representativeInfoByAddress', () async {
      var mock = HttpServerMock();
      var res = api.CivicInfoApi(mock).representatives;
      var arg_address = 'foo';
      var arg_includeOffices = true;
      var arg_levels = buildUnnamed2849();
      var arg_roles = buildUnnamed2850();
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
          unittest.equals("civicinfo/v2/representatives"),
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
          queryMap["address"]!.first,
          unittest.equals(arg_address),
        );
        unittest.expect(
          queryMap["includeOffices"]!.first,
          unittest.equals("$arg_includeOffices"),
        );
        unittest.expect(
          queryMap["levels"]!,
          unittest.equals(arg_levels),
        );
        unittest.expect(
          queryMap["roles"]!,
          unittest.equals(arg_roles),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRepresentativeInfoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.representativeInfoByAddress(
          address: arg_address,
          includeOffices: arg_includeOffices,
          levels: arg_levels,
          roles: arg_roles,
          $fields: arg_$fields);
      checkRepresentativeInfoResponse(
          response as api.RepresentativeInfoResponse);
    });

    unittest.test('method--representativeInfoByDivision', () async {
      var mock = HttpServerMock();
      var res = api.CivicInfoApi(mock).representatives;
      var arg_ocdId = 'foo';
      var arg_levels = buildUnnamed2851();
      var arg_recursive = true;
      var arg_roles = buildUnnamed2852();
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
          unittest.equals("civicinfo/v2/representatives/"),
        );
        pathOffset += 29;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_ocdId'),
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
          queryMap["levels"]!,
          unittest.equals(arg_levels),
        );
        unittest.expect(
          queryMap["recursive"]!.first,
          unittest.equals("$arg_recursive"),
        );
        unittest.expect(
          queryMap["roles"]!,
          unittest.equals(arg_roles),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRepresentativeInfoData());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.representativeInfoByDivision(arg_ocdId,
          levels: arg_levels,
          recursive: arg_recursive,
          roles: arg_roles,
          $fields: arg_$fields);
      checkRepresentativeInfoData(response as api.RepresentativeInfoData);
    });
  });
}
