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

import 'package:googleapis/gmail/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAutoForwarding = 0;
api.AutoForwarding buildAutoForwarding() {
  var o = api.AutoForwarding();
  buildCounterAutoForwarding++;
  if (buildCounterAutoForwarding < 3) {
    o.disposition = 'foo';
    o.emailAddress = 'foo';
    o.enabled = true;
  }
  buildCounterAutoForwarding--;
  return o;
}

void checkAutoForwarding(api.AutoForwarding o) {
  buildCounterAutoForwarding++;
  if (buildCounterAutoForwarding < 3) {
    unittest.expect(
      o.disposition!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(o.enabled!, unittest.isTrue);
  }
  buildCounterAutoForwarding--;
}

core.List<core.String> buildUnnamed3970() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3970(core.List<core.String> o) {
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

core.int buildCounterBatchDeleteMessagesRequest = 0;
api.BatchDeleteMessagesRequest buildBatchDeleteMessagesRequest() {
  var o = api.BatchDeleteMessagesRequest();
  buildCounterBatchDeleteMessagesRequest++;
  if (buildCounterBatchDeleteMessagesRequest < 3) {
    o.ids = buildUnnamed3970();
  }
  buildCounterBatchDeleteMessagesRequest--;
  return o;
}

void checkBatchDeleteMessagesRequest(api.BatchDeleteMessagesRequest o) {
  buildCounterBatchDeleteMessagesRequest++;
  if (buildCounterBatchDeleteMessagesRequest < 3) {
    checkUnnamed3970(o.ids!);
  }
  buildCounterBatchDeleteMessagesRequest--;
}

core.List<core.String> buildUnnamed3971() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3971(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3972() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3972(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3973() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3973(core.List<core.String> o) {
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

core.int buildCounterBatchModifyMessagesRequest = 0;
api.BatchModifyMessagesRequest buildBatchModifyMessagesRequest() {
  var o = api.BatchModifyMessagesRequest();
  buildCounterBatchModifyMessagesRequest++;
  if (buildCounterBatchModifyMessagesRequest < 3) {
    o.addLabelIds = buildUnnamed3971();
    o.ids = buildUnnamed3972();
    o.removeLabelIds = buildUnnamed3973();
  }
  buildCounterBatchModifyMessagesRequest--;
  return o;
}

void checkBatchModifyMessagesRequest(api.BatchModifyMessagesRequest o) {
  buildCounterBatchModifyMessagesRequest++;
  if (buildCounterBatchModifyMessagesRequest < 3) {
    checkUnnamed3971(o.addLabelIds!);
    checkUnnamed3972(o.ids!);
    checkUnnamed3973(o.removeLabelIds!);
  }
  buildCounterBatchModifyMessagesRequest--;
}

core.int buildCounterDelegate = 0;
api.Delegate buildDelegate() {
  var o = api.Delegate();
  buildCounterDelegate++;
  if (buildCounterDelegate < 3) {
    o.delegateEmail = 'foo';
    o.verificationStatus = 'foo';
  }
  buildCounterDelegate--;
  return o;
}

void checkDelegate(api.Delegate o) {
  buildCounterDelegate++;
  if (buildCounterDelegate < 3) {
    unittest.expect(
      o.delegateEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterDelegate--;
}

core.int buildCounterDraft = 0;
api.Draft buildDraft() {
  var o = api.Draft();
  buildCounterDraft++;
  if (buildCounterDraft < 3) {
    o.id = 'foo';
    o.message = buildMessage();
  }
  buildCounterDraft--;
  return o;
}

void checkDraft(api.Draft o) {
  buildCounterDraft++;
  if (buildCounterDraft < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkMessage(o.message! as api.Message);
  }
  buildCounterDraft--;
}

core.int buildCounterFilter = 0;
api.Filter buildFilter() {
  var o = api.Filter();
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    o.action = buildFilterAction();
    o.criteria = buildFilterCriteria();
    o.id = 'foo';
  }
  buildCounterFilter--;
  return o;
}

void checkFilter(api.Filter o) {
  buildCounterFilter++;
  if (buildCounterFilter < 3) {
    checkFilterAction(o.action! as api.FilterAction);
    checkFilterCriteria(o.criteria! as api.FilterCriteria);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilter--;
}

core.List<core.String> buildUnnamed3974() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3974(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3975() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3975(core.List<core.String> o) {
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

core.int buildCounterFilterAction = 0;
api.FilterAction buildFilterAction() {
  var o = api.FilterAction();
  buildCounterFilterAction++;
  if (buildCounterFilterAction < 3) {
    o.addLabelIds = buildUnnamed3974();
    o.forward = 'foo';
    o.removeLabelIds = buildUnnamed3975();
  }
  buildCounterFilterAction--;
  return o;
}

void checkFilterAction(api.FilterAction o) {
  buildCounterFilterAction++;
  if (buildCounterFilterAction < 3) {
    checkUnnamed3974(o.addLabelIds!);
    unittest.expect(
      o.forward!,
      unittest.equals('foo'),
    );
    checkUnnamed3975(o.removeLabelIds!);
  }
  buildCounterFilterAction--;
}

core.int buildCounterFilterCriteria = 0;
api.FilterCriteria buildFilterCriteria() {
  var o = api.FilterCriteria();
  buildCounterFilterCriteria++;
  if (buildCounterFilterCriteria < 3) {
    o.excludeChats = true;
    o.from = 'foo';
    o.hasAttachment = true;
    o.negatedQuery = 'foo';
    o.query = 'foo';
    o.size = 42;
    o.sizeComparison = 'foo';
    o.subject = 'foo';
    o.to = 'foo';
  }
  buildCounterFilterCriteria--;
  return o;
}

void checkFilterCriteria(api.FilterCriteria o) {
  buildCounterFilterCriteria++;
  if (buildCounterFilterCriteria < 3) {
    unittest.expect(o.excludeChats!, unittest.isTrue);
    unittest.expect(
      o.from!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hasAttachment!, unittest.isTrue);
    unittest.expect(
      o.negatedQuery!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sizeComparison!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.subject!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.to!,
      unittest.equals('foo'),
    );
  }
  buildCounterFilterCriteria--;
}

core.int buildCounterForwardingAddress = 0;
api.ForwardingAddress buildForwardingAddress() {
  var o = api.ForwardingAddress();
  buildCounterForwardingAddress++;
  if (buildCounterForwardingAddress < 3) {
    o.forwardingEmail = 'foo';
    o.verificationStatus = 'foo';
  }
  buildCounterForwardingAddress--;
  return o;
}

void checkForwardingAddress(api.ForwardingAddress o) {
  buildCounterForwardingAddress++;
  if (buildCounterForwardingAddress < 3) {
    unittest.expect(
      o.forwardingEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.verificationStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterForwardingAddress--;
}

core.List<api.HistoryLabelAdded> buildUnnamed3976() {
  var o = <api.HistoryLabelAdded>[];
  o.add(buildHistoryLabelAdded());
  o.add(buildHistoryLabelAdded());
  return o;
}

void checkUnnamed3976(core.List<api.HistoryLabelAdded> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistoryLabelAdded(o[0] as api.HistoryLabelAdded);
  checkHistoryLabelAdded(o[1] as api.HistoryLabelAdded);
}

core.List<api.HistoryLabelRemoved> buildUnnamed3977() {
  var o = <api.HistoryLabelRemoved>[];
  o.add(buildHistoryLabelRemoved());
  o.add(buildHistoryLabelRemoved());
  return o;
}

void checkUnnamed3977(core.List<api.HistoryLabelRemoved> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistoryLabelRemoved(o[0] as api.HistoryLabelRemoved);
  checkHistoryLabelRemoved(o[1] as api.HistoryLabelRemoved);
}

core.List<api.Message> buildUnnamed3978() {
  var o = <api.Message>[];
  o.add(buildMessage());
  o.add(buildMessage());
  return o;
}

void checkUnnamed3978(core.List<api.Message> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMessage(o[0] as api.Message);
  checkMessage(o[1] as api.Message);
}

core.List<api.HistoryMessageAdded> buildUnnamed3979() {
  var o = <api.HistoryMessageAdded>[];
  o.add(buildHistoryMessageAdded());
  o.add(buildHistoryMessageAdded());
  return o;
}

void checkUnnamed3979(core.List<api.HistoryMessageAdded> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistoryMessageAdded(o[0] as api.HistoryMessageAdded);
  checkHistoryMessageAdded(o[1] as api.HistoryMessageAdded);
}

core.List<api.HistoryMessageDeleted> buildUnnamed3980() {
  var o = <api.HistoryMessageDeleted>[];
  o.add(buildHistoryMessageDeleted());
  o.add(buildHistoryMessageDeleted());
  return o;
}

void checkUnnamed3980(core.List<api.HistoryMessageDeleted> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistoryMessageDeleted(o[0] as api.HistoryMessageDeleted);
  checkHistoryMessageDeleted(o[1] as api.HistoryMessageDeleted);
}

core.int buildCounterHistory = 0;
api.History buildHistory() {
  var o = api.History();
  buildCounterHistory++;
  if (buildCounterHistory < 3) {
    o.id = 'foo';
    o.labelsAdded = buildUnnamed3976();
    o.labelsRemoved = buildUnnamed3977();
    o.messages = buildUnnamed3978();
    o.messagesAdded = buildUnnamed3979();
    o.messagesDeleted = buildUnnamed3980();
  }
  buildCounterHistory--;
  return o;
}

void checkHistory(api.History o) {
  buildCounterHistory++;
  if (buildCounterHistory < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed3976(o.labelsAdded!);
    checkUnnamed3977(o.labelsRemoved!);
    checkUnnamed3978(o.messages!);
    checkUnnamed3979(o.messagesAdded!);
    checkUnnamed3980(o.messagesDeleted!);
  }
  buildCounterHistory--;
}

core.List<core.String> buildUnnamed3981() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3981(core.List<core.String> o) {
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

core.int buildCounterHistoryLabelAdded = 0;
api.HistoryLabelAdded buildHistoryLabelAdded() {
  var o = api.HistoryLabelAdded();
  buildCounterHistoryLabelAdded++;
  if (buildCounterHistoryLabelAdded < 3) {
    o.labelIds = buildUnnamed3981();
    o.message = buildMessage();
  }
  buildCounterHistoryLabelAdded--;
  return o;
}

void checkHistoryLabelAdded(api.HistoryLabelAdded o) {
  buildCounterHistoryLabelAdded++;
  if (buildCounterHistoryLabelAdded < 3) {
    checkUnnamed3981(o.labelIds!);
    checkMessage(o.message! as api.Message);
  }
  buildCounterHistoryLabelAdded--;
}

core.List<core.String> buildUnnamed3982() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3982(core.List<core.String> o) {
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

core.int buildCounterHistoryLabelRemoved = 0;
api.HistoryLabelRemoved buildHistoryLabelRemoved() {
  var o = api.HistoryLabelRemoved();
  buildCounterHistoryLabelRemoved++;
  if (buildCounterHistoryLabelRemoved < 3) {
    o.labelIds = buildUnnamed3982();
    o.message = buildMessage();
  }
  buildCounterHistoryLabelRemoved--;
  return o;
}

void checkHistoryLabelRemoved(api.HistoryLabelRemoved o) {
  buildCounterHistoryLabelRemoved++;
  if (buildCounterHistoryLabelRemoved < 3) {
    checkUnnamed3982(o.labelIds!);
    checkMessage(o.message! as api.Message);
  }
  buildCounterHistoryLabelRemoved--;
}

core.int buildCounterHistoryMessageAdded = 0;
api.HistoryMessageAdded buildHistoryMessageAdded() {
  var o = api.HistoryMessageAdded();
  buildCounterHistoryMessageAdded++;
  if (buildCounterHistoryMessageAdded < 3) {
    o.message = buildMessage();
  }
  buildCounterHistoryMessageAdded--;
  return o;
}

void checkHistoryMessageAdded(api.HistoryMessageAdded o) {
  buildCounterHistoryMessageAdded++;
  if (buildCounterHistoryMessageAdded < 3) {
    checkMessage(o.message! as api.Message);
  }
  buildCounterHistoryMessageAdded--;
}

core.int buildCounterHistoryMessageDeleted = 0;
api.HistoryMessageDeleted buildHistoryMessageDeleted() {
  var o = api.HistoryMessageDeleted();
  buildCounterHistoryMessageDeleted++;
  if (buildCounterHistoryMessageDeleted < 3) {
    o.message = buildMessage();
  }
  buildCounterHistoryMessageDeleted--;
  return o;
}

void checkHistoryMessageDeleted(api.HistoryMessageDeleted o) {
  buildCounterHistoryMessageDeleted++;
  if (buildCounterHistoryMessageDeleted < 3) {
    checkMessage(o.message! as api.Message);
  }
  buildCounterHistoryMessageDeleted--;
}

core.int buildCounterImapSettings = 0;
api.ImapSettings buildImapSettings() {
  var o = api.ImapSettings();
  buildCounterImapSettings++;
  if (buildCounterImapSettings < 3) {
    o.autoExpunge = true;
    o.enabled = true;
    o.expungeBehavior = 'foo';
    o.maxFolderSize = 42;
  }
  buildCounterImapSettings--;
  return o;
}

void checkImapSettings(api.ImapSettings o) {
  buildCounterImapSettings++;
  if (buildCounterImapSettings < 3) {
    unittest.expect(o.autoExpunge!, unittest.isTrue);
    unittest.expect(o.enabled!, unittest.isTrue);
    unittest.expect(
      o.expungeBehavior!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxFolderSize!,
      unittest.equals(42),
    );
  }
  buildCounterImapSettings--;
}

core.int buildCounterLabel = 0;
api.Label buildLabel() {
  var o = api.Label();
  buildCounterLabel++;
  if (buildCounterLabel < 3) {
    o.color = buildLabelColor();
    o.id = 'foo';
    o.labelListVisibility = 'foo';
    o.messageListVisibility = 'foo';
    o.messagesTotal = 42;
    o.messagesUnread = 42;
    o.name = 'foo';
    o.threadsTotal = 42;
    o.threadsUnread = 42;
    o.type = 'foo';
  }
  buildCounterLabel--;
  return o;
}

void checkLabel(api.Label o) {
  buildCounterLabel++;
  if (buildCounterLabel < 3) {
    checkLabelColor(o.color! as api.LabelColor);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.labelListVisibility!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messageListVisibility!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messagesTotal!,
      unittest.equals(42),
    );
    unittest.expect(
      o.messagesUnread!,
      unittest.equals(42),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.threadsTotal!,
      unittest.equals(42),
    );
    unittest.expect(
      o.threadsUnread!,
      unittest.equals(42),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterLabel--;
}

core.int buildCounterLabelColor = 0;
api.LabelColor buildLabelColor() {
  var o = api.LabelColor();
  buildCounterLabelColor++;
  if (buildCounterLabelColor < 3) {
    o.backgroundColor = 'foo';
    o.textColor = 'foo';
  }
  buildCounterLabelColor--;
  return o;
}

void checkLabelColor(api.LabelColor o) {
  buildCounterLabelColor++;
  if (buildCounterLabelColor < 3) {
    unittest.expect(
      o.backgroundColor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.textColor!,
      unittest.equals('foo'),
    );
  }
  buildCounterLabelColor--;
}

core.int buildCounterLanguageSettings = 0;
api.LanguageSettings buildLanguageSettings() {
  var o = api.LanguageSettings();
  buildCounterLanguageSettings++;
  if (buildCounterLanguageSettings < 3) {
    o.displayLanguage = 'foo';
  }
  buildCounterLanguageSettings--;
  return o;
}

void checkLanguageSettings(api.LanguageSettings o) {
  buildCounterLanguageSettings++;
  if (buildCounterLanguageSettings < 3) {
    unittest.expect(
      o.displayLanguage!,
      unittest.equals('foo'),
    );
  }
  buildCounterLanguageSettings--;
}

core.List<api.Delegate> buildUnnamed3983() {
  var o = <api.Delegate>[];
  o.add(buildDelegate());
  o.add(buildDelegate());
  return o;
}

void checkUnnamed3983(core.List<api.Delegate> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDelegate(o[0] as api.Delegate);
  checkDelegate(o[1] as api.Delegate);
}

core.int buildCounterListDelegatesResponse = 0;
api.ListDelegatesResponse buildListDelegatesResponse() {
  var o = api.ListDelegatesResponse();
  buildCounterListDelegatesResponse++;
  if (buildCounterListDelegatesResponse < 3) {
    o.delegates = buildUnnamed3983();
  }
  buildCounterListDelegatesResponse--;
  return o;
}

void checkListDelegatesResponse(api.ListDelegatesResponse o) {
  buildCounterListDelegatesResponse++;
  if (buildCounterListDelegatesResponse < 3) {
    checkUnnamed3983(o.delegates!);
  }
  buildCounterListDelegatesResponse--;
}

core.List<api.Draft> buildUnnamed3984() {
  var o = <api.Draft>[];
  o.add(buildDraft());
  o.add(buildDraft());
  return o;
}

void checkUnnamed3984(core.List<api.Draft> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDraft(o[0] as api.Draft);
  checkDraft(o[1] as api.Draft);
}

core.int buildCounterListDraftsResponse = 0;
api.ListDraftsResponse buildListDraftsResponse() {
  var o = api.ListDraftsResponse();
  buildCounterListDraftsResponse++;
  if (buildCounterListDraftsResponse < 3) {
    o.drafts = buildUnnamed3984();
    o.nextPageToken = 'foo';
    o.resultSizeEstimate = 42;
  }
  buildCounterListDraftsResponse--;
  return o;
}

void checkListDraftsResponse(api.ListDraftsResponse o) {
  buildCounterListDraftsResponse++;
  if (buildCounterListDraftsResponse < 3) {
    checkUnnamed3984(o.drafts!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resultSizeEstimate!,
      unittest.equals(42),
    );
  }
  buildCounterListDraftsResponse--;
}

core.List<api.Filter> buildUnnamed3985() {
  var o = <api.Filter>[];
  o.add(buildFilter());
  o.add(buildFilter());
  return o;
}

void checkUnnamed3985(core.List<api.Filter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFilter(o[0] as api.Filter);
  checkFilter(o[1] as api.Filter);
}

core.int buildCounterListFiltersResponse = 0;
api.ListFiltersResponse buildListFiltersResponse() {
  var o = api.ListFiltersResponse();
  buildCounterListFiltersResponse++;
  if (buildCounterListFiltersResponse < 3) {
    o.filter = buildUnnamed3985();
  }
  buildCounterListFiltersResponse--;
  return o;
}

void checkListFiltersResponse(api.ListFiltersResponse o) {
  buildCounterListFiltersResponse++;
  if (buildCounterListFiltersResponse < 3) {
    checkUnnamed3985(o.filter!);
  }
  buildCounterListFiltersResponse--;
}

core.List<api.ForwardingAddress> buildUnnamed3986() {
  var o = <api.ForwardingAddress>[];
  o.add(buildForwardingAddress());
  o.add(buildForwardingAddress());
  return o;
}

void checkUnnamed3986(core.List<api.ForwardingAddress> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkForwardingAddress(o[0] as api.ForwardingAddress);
  checkForwardingAddress(o[1] as api.ForwardingAddress);
}

core.int buildCounterListForwardingAddressesResponse = 0;
api.ListForwardingAddressesResponse buildListForwardingAddressesResponse() {
  var o = api.ListForwardingAddressesResponse();
  buildCounterListForwardingAddressesResponse++;
  if (buildCounterListForwardingAddressesResponse < 3) {
    o.forwardingAddresses = buildUnnamed3986();
  }
  buildCounterListForwardingAddressesResponse--;
  return o;
}

void checkListForwardingAddressesResponse(
    api.ListForwardingAddressesResponse o) {
  buildCounterListForwardingAddressesResponse++;
  if (buildCounterListForwardingAddressesResponse < 3) {
    checkUnnamed3986(o.forwardingAddresses!);
  }
  buildCounterListForwardingAddressesResponse--;
}

core.List<api.History> buildUnnamed3987() {
  var o = <api.History>[];
  o.add(buildHistory());
  o.add(buildHistory());
  return o;
}

void checkUnnamed3987(core.List<api.History> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkHistory(o[0] as api.History);
  checkHistory(o[1] as api.History);
}

core.int buildCounterListHistoryResponse = 0;
api.ListHistoryResponse buildListHistoryResponse() {
  var o = api.ListHistoryResponse();
  buildCounterListHistoryResponse++;
  if (buildCounterListHistoryResponse < 3) {
    o.history = buildUnnamed3987();
    o.historyId = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterListHistoryResponse--;
  return o;
}

void checkListHistoryResponse(api.ListHistoryResponse o) {
  buildCounterListHistoryResponse++;
  if (buildCounterListHistoryResponse < 3) {
    checkUnnamed3987(o.history!);
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListHistoryResponse--;
}

core.List<api.Label> buildUnnamed3988() {
  var o = <api.Label>[];
  o.add(buildLabel());
  o.add(buildLabel());
  return o;
}

void checkUnnamed3988(core.List<api.Label> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLabel(o[0] as api.Label);
  checkLabel(o[1] as api.Label);
}

core.int buildCounterListLabelsResponse = 0;
api.ListLabelsResponse buildListLabelsResponse() {
  var o = api.ListLabelsResponse();
  buildCounterListLabelsResponse++;
  if (buildCounterListLabelsResponse < 3) {
    o.labels = buildUnnamed3988();
  }
  buildCounterListLabelsResponse--;
  return o;
}

void checkListLabelsResponse(api.ListLabelsResponse o) {
  buildCounterListLabelsResponse++;
  if (buildCounterListLabelsResponse < 3) {
    checkUnnamed3988(o.labels!);
  }
  buildCounterListLabelsResponse--;
}

core.List<api.Message> buildUnnamed3989() {
  var o = <api.Message>[];
  o.add(buildMessage());
  o.add(buildMessage());
  return o;
}

void checkUnnamed3989(core.List<api.Message> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMessage(o[0] as api.Message);
  checkMessage(o[1] as api.Message);
}

core.int buildCounterListMessagesResponse = 0;
api.ListMessagesResponse buildListMessagesResponse() {
  var o = api.ListMessagesResponse();
  buildCounterListMessagesResponse++;
  if (buildCounterListMessagesResponse < 3) {
    o.messages = buildUnnamed3989();
    o.nextPageToken = 'foo';
    o.resultSizeEstimate = 42;
  }
  buildCounterListMessagesResponse--;
  return o;
}

void checkListMessagesResponse(api.ListMessagesResponse o) {
  buildCounterListMessagesResponse++;
  if (buildCounterListMessagesResponse < 3) {
    checkUnnamed3989(o.messages!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resultSizeEstimate!,
      unittest.equals(42),
    );
  }
  buildCounterListMessagesResponse--;
}

core.List<api.SendAs> buildUnnamed3990() {
  var o = <api.SendAs>[];
  o.add(buildSendAs());
  o.add(buildSendAs());
  return o;
}

void checkUnnamed3990(core.List<api.SendAs> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSendAs(o[0] as api.SendAs);
  checkSendAs(o[1] as api.SendAs);
}

core.int buildCounterListSendAsResponse = 0;
api.ListSendAsResponse buildListSendAsResponse() {
  var o = api.ListSendAsResponse();
  buildCounterListSendAsResponse++;
  if (buildCounterListSendAsResponse < 3) {
    o.sendAs = buildUnnamed3990();
  }
  buildCounterListSendAsResponse--;
  return o;
}

void checkListSendAsResponse(api.ListSendAsResponse o) {
  buildCounterListSendAsResponse++;
  if (buildCounterListSendAsResponse < 3) {
    checkUnnamed3990(o.sendAs!);
  }
  buildCounterListSendAsResponse--;
}

core.List<api.SmimeInfo> buildUnnamed3991() {
  var o = <api.SmimeInfo>[];
  o.add(buildSmimeInfo());
  o.add(buildSmimeInfo());
  return o;
}

void checkUnnamed3991(core.List<api.SmimeInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSmimeInfo(o[0] as api.SmimeInfo);
  checkSmimeInfo(o[1] as api.SmimeInfo);
}

core.int buildCounterListSmimeInfoResponse = 0;
api.ListSmimeInfoResponse buildListSmimeInfoResponse() {
  var o = api.ListSmimeInfoResponse();
  buildCounterListSmimeInfoResponse++;
  if (buildCounterListSmimeInfoResponse < 3) {
    o.smimeInfo = buildUnnamed3991();
  }
  buildCounterListSmimeInfoResponse--;
  return o;
}

void checkListSmimeInfoResponse(api.ListSmimeInfoResponse o) {
  buildCounterListSmimeInfoResponse++;
  if (buildCounterListSmimeInfoResponse < 3) {
    checkUnnamed3991(o.smimeInfo!);
  }
  buildCounterListSmimeInfoResponse--;
}

core.List<api.Thread> buildUnnamed3992() {
  var o = <api.Thread>[];
  o.add(buildThread());
  o.add(buildThread());
  return o;
}

void checkUnnamed3992(core.List<api.Thread> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkThread(o[0] as api.Thread);
  checkThread(o[1] as api.Thread);
}

core.int buildCounterListThreadsResponse = 0;
api.ListThreadsResponse buildListThreadsResponse() {
  var o = api.ListThreadsResponse();
  buildCounterListThreadsResponse++;
  if (buildCounterListThreadsResponse < 3) {
    o.nextPageToken = 'foo';
    o.resultSizeEstimate = 42;
    o.threads = buildUnnamed3992();
  }
  buildCounterListThreadsResponse--;
  return o;
}

void checkListThreadsResponse(api.ListThreadsResponse o) {
  buildCounterListThreadsResponse++;
  if (buildCounterListThreadsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resultSizeEstimate!,
      unittest.equals(42),
    );
    checkUnnamed3992(o.threads!);
  }
  buildCounterListThreadsResponse--;
}

core.List<core.String> buildUnnamed3993() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3993(core.List<core.String> o) {
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

core.int buildCounterMessage = 0;
api.Message buildMessage() {
  var o = api.Message();
  buildCounterMessage++;
  if (buildCounterMessage < 3) {
    o.historyId = 'foo';
    o.id = 'foo';
    o.internalDate = 'foo';
    o.labelIds = buildUnnamed3993();
    o.payload = buildMessagePart();
    o.raw = 'foo';
    o.sizeEstimate = 42;
    o.snippet = 'foo';
    o.threadId = 'foo';
  }
  buildCounterMessage--;
  return o;
}

void checkMessage(api.Message o) {
  buildCounterMessage++;
  if (buildCounterMessage < 3) {
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.internalDate!,
      unittest.equals('foo'),
    );
    checkUnnamed3993(o.labelIds!);
    checkMessagePart(o.payload! as api.MessagePart);
    unittest.expect(
      o.raw!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sizeEstimate!,
      unittest.equals(42),
    );
    unittest.expect(
      o.snippet!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.threadId!,
      unittest.equals('foo'),
    );
  }
  buildCounterMessage--;
}

core.List<api.MessagePartHeader> buildUnnamed3994() {
  var o = <api.MessagePartHeader>[];
  o.add(buildMessagePartHeader());
  o.add(buildMessagePartHeader());
  return o;
}

void checkUnnamed3994(core.List<api.MessagePartHeader> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMessagePartHeader(o[0] as api.MessagePartHeader);
  checkMessagePartHeader(o[1] as api.MessagePartHeader);
}

core.List<api.MessagePart> buildUnnamed3995() {
  var o = <api.MessagePart>[];
  o.add(buildMessagePart());
  o.add(buildMessagePart());
  return o;
}

void checkUnnamed3995(core.List<api.MessagePart> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMessagePart(o[0] as api.MessagePart);
  checkMessagePart(o[1] as api.MessagePart);
}

core.int buildCounterMessagePart = 0;
api.MessagePart buildMessagePart() {
  var o = api.MessagePart();
  buildCounterMessagePart++;
  if (buildCounterMessagePart < 3) {
    o.body = buildMessagePartBody();
    o.filename = 'foo';
    o.headers = buildUnnamed3994();
    o.mimeType = 'foo';
    o.partId = 'foo';
    o.parts = buildUnnamed3995();
  }
  buildCounterMessagePart--;
  return o;
}

void checkMessagePart(api.MessagePart o) {
  buildCounterMessagePart++;
  if (buildCounterMessagePart < 3) {
    checkMessagePartBody(o.body! as api.MessagePartBody);
    unittest.expect(
      o.filename!,
      unittest.equals('foo'),
    );
    checkUnnamed3994(o.headers!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.partId!,
      unittest.equals('foo'),
    );
    checkUnnamed3995(o.parts!);
  }
  buildCounterMessagePart--;
}

core.int buildCounterMessagePartBody = 0;
api.MessagePartBody buildMessagePartBody() {
  var o = api.MessagePartBody();
  buildCounterMessagePartBody++;
  if (buildCounterMessagePartBody < 3) {
    o.attachmentId = 'foo';
    o.data = 'foo';
    o.size = 42;
  }
  buildCounterMessagePartBody--;
  return o;
}

void checkMessagePartBody(api.MessagePartBody o) {
  buildCounterMessagePartBody++;
  if (buildCounterMessagePartBody < 3) {
    unittest.expect(
      o.attachmentId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.size!,
      unittest.equals(42),
    );
  }
  buildCounterMessagePartBody--;
}

core.int buildCounterMessagePartHeader = 0;
api.MessagePartHeader buildMessagePartHeader() {
  var o = api.MessagePartHeader();
  buildCounterMessagePartHeader++;
  if (buildCounterMessagePartHeader < 3) {
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterMessagePartHeader--;
  return o;
}

void checkMessagePartHeader(api.MessagePartHeader o) {
  buildCounterMessagePartHeader++;
  if (buildCounterMessagePartHeader < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterMessagePartHeader--;
}

core.List<core.String> buildUnnamed3996() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3996(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3997() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3997(core.List<core.String> o) {
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

core.int buildCounterModifyMessageRequest = 0;
api.ModifyMessageRequest buildModifyMessageRequest() {
  var o = api.ModifyMessageRequest();
  buildCounterModifyMessageRequest++;
  if (buildCounterModifyMessageRequest < 3) {
    o.addLabelIds = buildUnnamed3996();
    o.removeLabelIds = buildUnnamed3997();
  }
  buildCounterModifyMessageRequest--;
  return o;
}

void checkModifyMessageRequest(api.ModifyMessageRequest o) {
  buildCounterModifyMessageRequest++;
  if (buildCounterModifyMessageRequest < 3) {
    checkUnnamed3996(o.addLabelIds!);
    checkUnnamed3997(o.removeLabelIds!);
  }
  buildCounterModifyMessageRequest--;
}

core.List<core.String> buildUnnamed3998() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3998(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed3999() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3999(core.List<core.String> o) {
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

core.int buildCounterModifyThreadRequest = 0;
api.ModifyThreadRequest buildModifyThreadRequest() {
  var o = api.ModifyThreadRequest();
  buildCounterModifyThreadRequest++;
  if (buildCounterModifyThreadRequest < 3) {
    o.addLabelIds = buildUnnamed3998();
    o.removeLabelIds = buildUnnamed3999();
  }
  buildCounterModifyThreadRequest--;
  return o;
}

void checkModifyThreadRequest(api.ModifyThreadRequest o) {
  buildCounterModifyThreadRequest++;
  if (buildCounterModifyThreadRequest < 3) {
    checkUnnamed3998(o.addLabelIds!);
    checkUnnamed3999(o.removeLabelIds!);
  }
  buildCounterModifyThreadRequest--;
}

core.int buildCounterPopSettings = 0;
api.PopSettings buildPopSettings() {
  var o = api.PopSettings();
  buildCounterPopSettings++;
  if (buildCounterPopSettings < 3) {
    o.accessWindow = 'foo';
    o.disposition = 'foo';
  }
  buildCounterPopSettings--;
  return o;
}

void checkPopSettings(api.PopSettings o) {
  buildCounterPopSettings++;
  if (buildCounterPopSettings < 3) {
    unittest.expect(
      o.accessWindow!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.disposition!,
      unittest.equals('foo'),
    );
  }
  buildCounterPopSettings--;
}

core.int buildCounterProfile = 0;
api.Profile buildProfile() {
  var o = api.Profile();
  buildCounterProfile++;
  if (buildCounterProfile < 3) {
    o.emailAddress = 'foo';
    o.historyId = 'foo';
    o.messagesTotal = 42;
    o.threadsTotal = 42;
  }
  buildCounterProfile--;
  return o;
}

void checkProfile(api.Profile o) {
  buildCounterProfile++;
  if (buildCounterProfile < 3) {
    unittest.expect(
      o.emailAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messagesTotal!,
      unittest.equals(42),
    );
    unittest.expect(
      o.threadsTotal!,
      unittest.equals(42),
    );
  }
  buildCounterProfile--;
}

core.int buildCounterSendAs = 0;
api.SendAs buildSendAs() {
  var o = api.SendAs();
  buildCounterSendAs++;
  if (buildCounterSendAs < 3) {
    o.displayName = 'foo';
    o.isDefault = true;
    o.isPrimary = true;
    o.replyToAddress = 'foo';
    o.sendAsEmail = 'foo';
    o.signature = 'foo';
    o.smtpMsa = buildSmtpMsa();
    o.treatAsAlias = true;
    o.verificationStatus = 'foo';
  }
  buildCounterSendAs--;
  return o;
}

void checkSendAs(api.SendAs o) {
  buildCounterSendAs++;
  if (buildCounterSendAs < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isDefault!, unittest.isTrue);
    unittest.expect(o.isPrimary!, unittest.isTrue);
    unittest.expect(
      o.replyToAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sendAsEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.signature!,
      unittest.equals('foo'),
    );
    checkSmtpMsa(o.smtpMsa! as api.SmtpMsa);
    unittest.expect(o.treatAsAlias!, unittest.isTrue);
    unittest.expect(
      o.verificationStatus!,
      unittest.equals('foo'),
    );
  }
  buildCounterSendAs--;
}

core.int buildCounterSmimeInfo = 0;
api.SmimeInfo buildSmimeInfo() {
  var o = api.SmimeInfo();
  buildCounterSmimeInfo++;
  if (buildCounterSmimeInfo < 3) {
    o.encryptedKeyPassword = 'foo';
    o.expiration = 'foo';
    o.id = 'foo';
    o.isDefault = true;
    o.issuerCn = 'foo';
    o.pem = 'foo';
    o.pkcs12 = 'foo';
  }
  buildCounterSmimeInfo--;
  return o;
}

void checkSmimeInfo(api.SmimeInfo o) {
  buildCounterSmimeInfo++;
  if (buildCounterSmimeInfo < 3) {
    unittest.expect(
      o.encryptedKeyPassword!,
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
    unittest.expect(o.isDefault!, unittest.isTrue);
    unittest.expect(
      o.issuerCn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pem!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pkcs12!,
      unittest.equals('foo'),
    );
  }
  buildCounterSmimeInfo--;
}

core.int buildCounterSmtpMsa = 0;
api.SmtpMsa buildSmtpMsa() {
  var o = api.SmtpMsa();
  buildCounterSmtpMsa++;
  if (buildCounterSmtpMsa < 3) {
    o.host = 'foo';
    o.password = 'foo';
    o.port = 42;
    o.securityMode = 'foo';
    o.username = 'foo';
  }
  buildCounterSmtpMsa--;
  return o;
}

void checkSmtpMsa(api.SmtpMsa o) {
  buildCounterSmtpMsa++;
  if (buildCounterSmtpMsa < 3) {
    unittest.expect(
      o.host!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.password!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.port!,
      unittest.equals(42),
    );
    unittest.expect(
      o.securityMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.username!,
      unittest.equals('foo'),
    );
  }
  buildCounterSmtpMsa--;
}

core.List<api.Message> buildUnnamed4000() {
  var o = <api.Message>[];
  o.add(buildMessage());
  o.add(buildMessage());
  return o;
}

void checkUnnamed4000(core.List<api.Message> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMessage(o[0] as api.Message);
  checkMessage(o[1] as api.Message);
}

core.int buildCounterThread = 0;
api.Thread buildThread() {
  var o = api.Thread();
  buildCounterThread++;
  if (buildCounterThread < 3) {
    o.historyId = 'foo';
    o.id = 'foo';
    o.messages = buildUnnamed4000();
    o.snippet = 'foo';
  }
  buildCounterThread--;
  return o;
}

void checkThread(api.Thread o) {
  buildCounterThread++;
  if (buildCounterThread < 3) {
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed4000(o.messages!);
    unittest.expect(
      o.snippet!,
      unittest.equals('foo'),
    );
  }
  buildCounterThread--;
}

core.int buildCounterVacationSettings = 0;
api.VacationSettings buildVacationSettings() {
  var o = api.VacationSettings();
  buildCounterVacationSettings++;
  if (buildCounterVacationSettings < 3) {
    o.enableAutoReply = true;
    o.endTime = 'foo';
    o.responseBodyHtml = 'foo';
    o.responseBodyPlainText = 'foo';
    o.responseSubject = 'foo';
    o.restrictToContacts = true;
    o.restrictToDomain = true;
    o.startTime = 'foo';
  }
  buildCounterVacationSettings--;
  return o;
}

void checkVacationSettings(api.VacationSettings o) {
  buildCounterVacationSettings++;
  if (buildCounterVacationSettings < 3) {
    unittest.expect(o.enableAutoReply!, unittest.isTrue);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseBodyHtml!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseBodyPlainText!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.responseSubject!,
      unittest.equals('foo'),
    );
    unittest.expect(o.restrictToContacts!, unittest.isTrue);
    unittest.expect(o.restrictToDomain!, unittest.isTrue);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterVacationSettings--;
}

core.List<core.String> buildUnnamed4001() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4001(core.List<core.String> o) {
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

core.int buildCounterWatchRequest = 0;
api.WatchRequest buildWatchRequest() {
  var o = api.WatchRequest();
  buildCounterWatchRequest++;
  if (buildCounterWatchRequest < 3) {
    o.labelFilterAction = 'foo';
    o.labelIds = buildUnnamed4001();
    o.topicName = 'foo';
  }
  buildCounterWatchRequest--;
  return o;
}

void checkWatchRequest(api.WatchRequest o) {
  buildCounterWatchRequest++;
  if (buildCounterWatchRequest < 3) {
    unittest.expect(
      o.labelFilterAction!,
      unittest.equals('foo'),
    );
    checkUnnamed4001(o.labelIds!);
    unittest.expect(
      o.topicName!,
      unittest.equals('foo'),
    );
  }
  buildCounterWatchRequest--;
}

core.int buildCounterWatchResponse = 0;
api.WatchResponse buildWatchResponse() {
  var o = api.WatchResponse();
  buildCounterWatchResponse++;
  if (buildCounterWatchResponse < 3) {
    o.expiration = 'foo';
    o.historyId = 'foo';
  }
  buildCounterWatchResponse--;
  return o;
}

void checkWatchResponse(api.WatchResponse o) {
  buildCounterWatchResponse++;
  if (buildCounterWatchResponse < 3) {
    unittest.expect(
      o.expiration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.historyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterWatchResponse--;
}

core.List<core.String> buildUnnamed4002() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4002(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4003() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4003(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4004() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4004(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4005() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4005(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed4006() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4006(core.List<core.String> o) {
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
  unittest.group('obj-schema-AutoForwarding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAutoForwarding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AutoForwarding.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAutoForwarding(od as api.AutoForwarding);
    });
  });

  unittest.group('obj-schema-BatchDeleteMessagesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeleteMessagesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeleteMessagesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeleteMessagesRequest(od as api.BatchDeleteMessagesRequest);
    });
  });

  unittest.group('obj-schema-BatchModifyMessagesRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchModifyMessagesRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchModifyMessagesRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchModifyMessagesRequest(od as api.BatchModifyMessagesRequest);
    });
  });

  unittest.group('obj-schema-Delegate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDelegate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Delegate.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDelegate(od as api.Delegate);
    });
  });

  unittest.group('obj-schema-Draft', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDraft();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Draft.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDraft(od as api.Draft);
    });
  });

  unittest.group('obj-schema-Filter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Filter.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkFilter(od as api.Filter);
    });
  });

  unittest.group('obj-schema-FilterAction', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterAction();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterAction.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterAction(od as api.FilterAction);
    });
  });

  unittest.group('obj-schema-FilterCriteria', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFilterCriteria();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FilterCriteria.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFilterCriteria(od as api.FilterCriteria);
    });
  });

  unittest.group('obj-schema-ForwardingAddress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildForwardingAddress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ForwardingAddress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkForwardingAddress(od as api.ForwardingAddress);
    });
  });

  unittest.group('obj-schema-History', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistory();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.History.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkHistory(od as api.History);
    });
  });

  unittest.group('obj-schema-HistoryLabelAdded', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistoryLabelAdded();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistoryLabelAdded.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistoryLabelAdded(od as api.HistoryLabelAdded);
    });
  });

  unittest.group('obj-schema-HistoryLabelRemoved', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistoryLabelRemoved();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistoryLabelRemoved.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistoryLabelRemoved(od as api.HistoryLabelRemoved);
    });
  });

  unittest.group('obj-schema-HistoryMessageAdded', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistoryMessageAdded();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistoryMessageAdded.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistoryMessageAdded(od as api.HistoryMessageAdded);
    });
  });

  unittest.group('obj-schema-HistoryMessageDeleted', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHistoryMessageDeleted();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HistoryMessageDeleted.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHistoryMessageDeleted(od as api.HistoryMessageDeleted);
    });
  });

  unittest.group('obj-schema-ImapSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImapSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImapSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImapSettings(od as api.ImapSettings);
    });
  });

  unittest.group('obj-schema-Label', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLabel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Label.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLabel(od as api.Label);
    });
  });

  unittest.group('obj-schema-LabelColor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLabelColor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LabelColor.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLabelColor(od as api.LabelColor);
    });
  });

  unittest.group('obj-schema-LanguageSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageSettings(od as api.LanguageSettings);
    });
  });

  unittest.group('obj-schema-ListDelegatesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDelegatesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDelegatesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDelegatesResponse(od as api.ListDelegatesResponse);
    });
  });

  unittest.group('obj-schema-ListDraftsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDraftsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDraftsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDraftsResponse(od as api.ListDraftsResponse);
    });
  });

  unittest.group('obj-schema-ListFiltersResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListFiltersResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListFiltersResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListFiltersResponse(od as api.ListFiltersResponse);
    });
  });

  unittest.group('obj-schema-ListForwardingAddressesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListForwardingAddressesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListForwardingAddressesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListForwardingAddressesResponse(
          od as api.ListForwardingAddressesResponse);
    });
  });

  unittest.group('obj-schema-ListHistoryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListHistoryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListHistoryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListHistoryResponse(od as api.ListHistoryResponse);
    });
  });

  unittest.group('obj-schema-ListLabelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLabelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLabelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLabelsResponse(od as api.ListLabelsResponse);
    });
  });

  unittest.group('obj-schema-ListMessagesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListMessagesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListMessagesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListMessagesResponse(od as api.ListMessagesResponse);
    });
  });

  unittest.group('obj-schema-ListSendAsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSendAsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSendAsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSendAsResponse(od as api.ListSendAsResponse);
    });
  });

  unittest.group('obj-schema-ListSmimeInfoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSmimeInfoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSmimeInfoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSmimeInfoResponse(od as api.ListSmimeInfoResponse);
    });
  });

  unittest.group('obj-schema-ListThreadsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListThreadsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListThreadsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListThreadsResponse(od as api.ListThreadsResponse);
    });
  });

  unittest.group('obj-schema-Message', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Message.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMessage(od as api.Message);
    });
  });

  unittest.group('obj-schema-MessagePart', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessagePart();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MessagePart.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMessagePart(od as api.MessagePart);
    });
  });

  unittest.group('obj-schema-MessagePartBody', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessagePartBody();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MessagePartBody.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMessagePartBody(od as api.MessagePartBody);
    });
  });

  unittest.group('obj-schema-MessagePartHeader', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessagePartHeader();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MessagePartHeader.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMessagePartHeader(od as api.MessagePartHeader);
    });
  });

  unittest.group('obj-schema-ModifyMessageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyMessageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyMessageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyMessageRequest(od as api.ModifyMessageRequest);
    });
  });

  unittest.group('obj-schema-ModifyThreadRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyThreadRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyThreadRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyThreadRequest(od as api.ModifyThreadRequest);
    });
  });

  unittest.group('obj-schema-PopSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPopSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PopSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPopSettings(od as api.PopSettings);
    });
  });

  unittest.group('obj-schema-Profile', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProfile();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Profile.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkProfile(od as api.Profile);
    });
  });

  unittest.group('obj-schema-SendAs', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSendAs();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SendAs.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSendAs(od as api.SendAs);
    });
  });

  unittest.group('obj-schema-SmimeInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSmimeInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SmimeInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSmimeInfo(od as api.SmimeInfo);
    });
  });

  unittest.group('obj-schema-SmtpMsa', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSmtpMsa();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.SmtpMsa.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSmtpMsa(od as api.SmtpMsa);
    });
  });

  unittest.group('obj-schema-Thread', () {
    unittest.test('to-json--from-json', () async {
      var o = buildThread();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Thread.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkThread(od as api.Thread);
    });
  });

  unittest.group('obj-schema-VacationSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildVacationSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.VacationSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkVacationSettings(od as api.VacationSettings);
    });
  });

  unittest.group('obj-schema-WatchRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWatchRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WatchRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWatchRequest(od as api.WatchRequest);
    });
  });

  unittest.group('obj-schema-WatchResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWatchResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WatchResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWatchResponse(od as api.WatchResponse);
    });
  });

  unittest.group('resource-UsersResource', () {
    unittest.test('method--getProfile', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/profile', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/profile"),
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
        var resp = convert.json.encode(buildProfile());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getProfile(arg_userId, $fields: arg_$fields);
      checkProfile(response as api.Profile);
    });

    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/stop', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/stop"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.stop(arg_userId, $fields: arg_$fields);
    });

    unittest.test('method--watch', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users;
      var arg_request = buildWatchRequest();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WatchRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWatchRequest(obj as api.WatchRequest);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/watch', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/watch"),
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
        var resp = convert.json.encode(buildWatchResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.watch(arg_request, arg_userId, $fields: arg_$fields);
      checkWatchResponse(response as api.WatchResponse);
    });
  });

  unittest.group('resource-UsersDraftsResource', () {
    unittest.test('method--create', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.drafts;
      var arg_request = buildDraft();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Draft.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDraft(obj as api.Draft);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/drafts', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/drafts"),
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
        var resp = convert.json.encode(buildDraft());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkDraft(response as api.Draft);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.drafts;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/drafts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/drafts/"),
        );
        pathOffset += 8;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_userId, arg_id, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.drafts;
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_format = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/drafts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/drafts/"),
        );
        pathOffset += 8;
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
          queryMap["format"]!.first,
          unittest.equals(arg_format),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDraft());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_id,
          format: arg_format, $fields: arg_$fields);
      checkDraft(response as api.Draft);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.drafts;
      var arg_userId = 'foo';
      var arg_includeSpamTrash = true;
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_q = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/drafts', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/drafts"),
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
          queryMap["includeSpamTrash"]!.first,
          unittest.equals("$arg_includeSpamTrash"),
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
          queryMap["q"]!.first,
          unittest.equals(arg_q),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListDraftsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId,
          includeSpamTrash: arg_includeSpamTrash,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          q: arg_q,
          $fields: arg_$fields);
      checkListDraftsResponse(response as api.ListDraftsResponse);
    });

    unittest.test('method--send', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.drafts;
      var arg_request = buildDraft();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Draft.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDraft(obj as api.Draft);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/drafts/send', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("/drafts/send"),
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.send(arg_request, arg_userId, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--update', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.drafts;
      var arg_request = buildDraft();
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Draft.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDraft(obj as api.Draft);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/drafts/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/drafts/"),
        );
        pathOffset += 8;
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
        var resp = convert.json.encode(buildDraft());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_userId, arg_id,
          $fields: arg_$fields);
      checkDraft(response as api.Draft);
    });
  });

  unittest.group('resource-UsersHistoryResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.history;
      var arg_userId = 'foo';
      var arg_historyTypes = buildUnnamed4002();
      var arg_labelId = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_startHistoryId = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/history', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/history"),
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
          queryMap["historyTypes"]!,
          unittest.equals(arg_historyTypes),
        );
        unittest.expect(
          queryMap["labelId"]!.first,
          unittest.equals(arg_labelId),
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
          queryMap["startHistoryId"]!.first,
          unittest.equals(arg_startHistoryId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListHistoryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId,
          historyTypes: arg_historyTypes,
          labelId: arg_labelId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          startHistoryId: arg_startHistoryId,
          $fields: arg_$fields);
      checkListHistoryResponse(response as api.ListHistoryResponse);
    });
  });

  unittest.group('resource-UsersLabelsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.labels;
      var arg_request = buildLabel();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Label.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLabel(obj as api.Label);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/labels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/labels"),
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
        var resp = convert.json.encode(buildLabel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkLabel(response as api.Label);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.labels;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/labels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/labels/"),
        );
        pathOffset += 8;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_userId, arg_id, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.labels;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/labels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/labels/"),
        );
        pathOffset += 8;
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
        var resp = convert.json.encode(buildLabel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_id, $fields: arg_$fields);
      checkLabel(response as api.Label);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.labels;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/labels', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/labels"),
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
        var resp = convert.json.encode(buildListLabelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId, $fields: arg_$fields);
      checkListLabelsResponse(response as api.ListLabelsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.labels;
      var arg_request = buildLabel();
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Label.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLabel(obj as api.Label);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/labels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/labels/"),
        );
        pathOffset += 8;
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
        var resp = convert.json.encode(buildLabel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_userId, arg_id,
          $fields: arg_$fields);
      checkLabel(response as api.Label);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.labels;
      var arg_request = buildLabel();
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Label.fromJson(json as core.Map<core.String, core.dynamic>);
        checkLabel(obj as api.Label);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/labels/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/labels/"),
        );
        pathOffset += 8;
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
        var resp = convert.json.encode(buildLabel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_userId, arg_id,
          $fields: arg_$fields);
      checkLabel(response as api.Label);
    });
  });

  unittest.group('resource-UsersMessagesResource', () {
    unittest.test('method--batchDelete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_request = buildBatchDeleteMessagesRequest();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchDeleteMessagesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchDeleteMessagesRequest(obj as api.BatchDeleteMessagesRequest);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/batchDelete', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/messages/batchDelete"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.batchDelete(arg_request, arg_userId, $fields: arg_$fields);
    });

    unittest.test('method--batchModify', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_request = buildBatchModifyMessagesRequest();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchModifyMessagesRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchModifyMessagesRequest(obj as api.BatchModifyMessagesRequest);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/batchModify', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("/messages/batchModify"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.batchModify(arg_request, arg_userId, $fields: arg_$fields);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/messages/"),
        );
        pathOffset += 10;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_userId, arg_id, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_format = 'foo';
      var arg_metadataHeaders = buildUnnamed4003();
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/messages/"),
        );
        pathOffset += 10;
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
          queryMap["format"]!.first,
          unittest.equals(arg_format),
        );
        unittest.expect(
          queryMap["metadataHeaders"]!,
          unittest.equals(arg_metadataHeaders),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_id,
          format: arg_format,
          metadataHeaders: arg_metadataHeaders,
          $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--import', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_request = buildMessage();
      var arg_userId = 'foo';
      var arg_deleted = true;
      var arg_internalDateSource = 'foo';
      var arg_neverMarkSpam = true;
      var arg_processForCalendar = true;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/import', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/messages/import"),
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
          queryMap["deleted"]!.first,
          unittest.equals("$arg_deleted"),
        );
        unittest.expect(
          queryMap["internalDateSource"]!.first,
          unittest.equals(arg_internalDateSource),
        );
        unittest.expect(
          queryMap["neverMarkSpam"]!.first,
          unittest.equals("$arg_neverMarkSpam"),
        );
        unittest.expect(
          queryMap["processForCalendar"]!.first,
          unittest.equals("$arg_processForCalendar"),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.import(arg_request, arg_userId,
          deleted: arg_deleted,
          internalDateSource: arg_internalDateSource,
          neverMarkSpam: arg_neverMarkSpam,
          processForCalendar: arg_processForCalendar,
          $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--insert', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_request = buildMessage();
      var arg_userId = 'foo';
      var arg_deleted = true;
      var arg_internalDateSource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/messages"),
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
          queryMap["deleted"]!.first,
          unittest.equals("$arg_deleted"),
        );
        unittest.expect(
          queryMap["internalDateSource"]!.first,
          unittest.equals(arg_internalDateSource),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_userId,
          deleted: arg_deleted,
          internalDateSource: arg_internalDateSource,
          $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_userId = 'foo';
      var arg_includeSpamTrash = true;
      var arg_labelIds = buildUnnamed4004();
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_q = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/messages"),
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
          queryMap["includeSpamTrash"]!.first,
          unittest.equals("$arg_includeSpamTrash"),
        );
        unittest.expect(
          queryMap["labelIds"]!,
          unittest.equals(arg_labelIds),
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
          queryMap["q"]!.first,
          unittest.equals(arg_q),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListMessagesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId,
          includeSpamTrash: arg_includeSpamTrash,
          labelIds: arg_labelIds,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          q: arg_q,
          $fields: arg_$fields);
      checkListMessagesResponse(response as api.ListMessagesResponse);
    });

    unittest.test('method--modify', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_request = buildModifyMessageRequest();
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyMessageRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyMessageRequest(obj as api.ModifyMessageRequest);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/messages/"),
        );
        pathOffset += 10;
        index = path.indexOf('/modify', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/modify"),
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.modify(arg_request, arg_userId, arg_id,
          $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--send', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_request = buildMessage();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Message.fromJson(json as core.Map<core.String, core.dynamic>);
        checkMessage(obj as api.Message);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/send', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/messages/send"),
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.send(arg_request, arg_userId, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--trash', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/messages/"),
        );
        pathOffset += 10;
        index = path.indexOf('/trash', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/trash"),
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.trash(arg_userId, arg_id, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });

    unittest.test('method--untrash', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/messages/"),
        );
        pathOffset += 10;
        index = path.indexOf('/untrash', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/untrash"),
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
        var resp = convert.json.encode(buildMessage());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.untrash(arg_userId, arg_id, $fields: arg_$fields);
      checkMessage(response as api.Message);
    });
  });

  unittest.group('resource-UsersMessagesAttachmentsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.messages.attachments;
      var arg_userId = 'foo';
      var arg_messageId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/messages/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/messages/"),
        );
        pathOffset += 10;
        index = path.indexOf('/attachments/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_messageId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/attachments/"),
        );
        pathOffset += 13;
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
        var resp = convert.json.encode(buildMessagePartBody());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_messageId, arg_id,
          $fields: arg_$fields);
      checkMessagePartBody(response as api.MessagePartBody);
    });
  });

  unittest.group('resource-UsersSettingsResource', () {
    unittest.test('method--getAutoForwarding', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/autoForwarding', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("/settings/autoForwarding"),
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
        var resp = convert.json.encode(buildAutoForwarding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getAutoForwarding(arg_userId, $fields: arg_$fields);
      checkAutoForwarding(response as api.AutoForwarding);
    });

    unittest.test('method--getImap', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/imap', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/settings/imap"),
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
        var resp = convert.json.encode(buildImapSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getImap(arg_userId, $fields: arg_$fields);
      checkImapSettings(response as api.ImapSettings);
    });

    unittest.test('method--getLanguage', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/language', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/settings/language"),
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
        var resp = convert.json.encode(buildLanguageSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getLanguage(arg_userId, $fields: arg_$fields);
      checkLanguageSettings(response as api.LanguageSettings);
    });

    unittest.test('method--getPop', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/pop', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/settings/pop"),
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
        var resp = convert.json.encode(buildPopSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getPop(arg_userId, $fields: arg_$fields);
      checkPopSettings(response as api.PopSettings);
    });

    unittest.test('method--getVacation', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/vacation', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/settings/vacation"),
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
        var resp = convert.json.encode(buildVacationSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getVacation(arg_userId, $fields: arg_$fields);
      checkVacationSettings(response as api.VacationSettings);
    });

    unittest.test('method--updateAutoForwarding', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
      var arg_request = buildAutoForwarding();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AutoForwarding.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAutoForwarding(obj as api.AutoForwarding);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/autoForwarding', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 24),
          unittest.equals("/settings/autoForwarding"),
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
        var resp = convert.json.encode(buildAutoForwarding());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateAutoForwarding(arg_request, arg_userId,
          $fields: arg_$fields);
      checkAutoForwarding(response as api.AutoForwarding);
    });

    unittest.test('method--updateImap', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
      var arg_request = buildImapSettings();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ImapSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkImapSettings(obj as api.ImapSettings);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/imap', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/settings/imap"),
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
        var resp = convert.json.encode(buildImapSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.updateImap(arg_request, arg_userId, $fields: arg_$fields);
      checkImapSettings(response as api.ImapSettings);
    });

    unittest.test('method--updateLanguage', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
      var arg_request = buildLanguageSettings();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LanguageSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLanguageSettings(obj as api.LanguageSettings);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/language', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/settings/language"),
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
        var resp = convert.json.encode(buildLanguageSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateLanguage(arg_request, arg_userId,
          $fields: arg_$fields);
      checkLanguageSettings(response as api.LanguageSettings);
    });

    unittest.test('method--updatePop', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
      var arg_request = buildPopSettings();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PopSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPopSettings(obj as api.PopSettings);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/pop', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/settings/pop"),
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
        var resp = convert.json.encode(buildPopSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.updatePop(arg_request, arg_userId, $fields: arg_$fields);
      checkPopSettings(response as api.PopSettings);
    });

    unittest.test('method--updateVacation', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings;
      var arg_request = buildVacationSettings();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.VacationSettings.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkVacationSettings(obj as api.VacationSettings);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/vacation', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/settings/vacation"),
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
        var resp = convert.json.encode(buildVacationSettings());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.updateVacation(arg_request, arg_userId,
          $fields: arg_$fields);
      checkVacationSettings(response as api.VacationSettings);
    });
  });

  unittest.group('resource-UsersSettingsDelegatesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.delegates;
      var arg_request = buildDelegate();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Delegate.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDelegate(obj as api.Delegate);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/delegates', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/settings/delegates"),
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
        var resp = convert.json.encode(buildDelegate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkDelegate(response as api.Delegate);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.delegates;
      var arg_userId = 'foo';
      var arg_delegateEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/delegates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/settings/delegates/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_delegateEmail'),
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
      await res.delete(arg_userId, arg_delegateEmail, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.delegates;
      var arg_userId = 'foo';
      var arg_delegateEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/delegates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("/settings/delegates/"),
        );
        pathOffset += 20;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_delegateEmail'),
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
        var resp = convert.json.encode(buildDelegate());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_userId, arg_delegateEmail, $fields: arg_$fields);
      checkDelegate(response as api.Delegate);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.delegates;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/delegates', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("/settings/delegates"),
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
        var resp = convert.json.encode(buildListDelegatesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId, $fields: arg_$fields);
      checkListDelegatesResponse(response as api.ListDelegatesResponse);
    });
  });

  unittest.group('resource-UsersSettingsFiltersResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.filters;
      var arg_request = buildFilter();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Filter.fromJson(json as core.Map<core.String, core.dynamic>);
        checkFilter(obj as api.Filter);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/filters', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/filters"),
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
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.filters;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/filters/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/settings/filters/"),
        );
        pathOffset += 18;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_userId, arg_id, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.filters;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/filters/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("/settings/filters/"),
        );
        pathOffset += 18;
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
        var resp = convert.json.encode(buildFilter());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_id, $fields: arg_$fields);
      checkFilter(response as api.Filter);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.filters;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/filters', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/filters"),
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
        var resp = convert.json.encode(buildListFiltersResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId, $fields: arg_$fields);
      checkListFiltersResponse(response as api.ListFiltersResponse);
    });
  });

  unittest.group('resource-UsersSettingsForwardingAddressesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.forwardingAddresses;
      var arg_request = buildForwardingAddress();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ForwardingAddress.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkForwardingAddress(obj as api.ForwardingAddress);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/forwardingAddresses', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("/settings/forwardingAddresses"),
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
        var resp = convert.json.encode(buildForwardingAddress());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkForwardingAddress(response as api.ForwardingAddress);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.forwardingAddresses;
      var arg_userId = 'foo';
      var arg_forwardingEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/forwardingAddresses/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("/settings/forwardingAddresses/"),
        );
        pathOffset += 30;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_forwardingEmail'),
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
      await res.delete(arg_userId, arg_forwardingEmail, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.forwardingAddresses;
      var arg_userId = 'foo';
      var arg_forwardingEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/forwardingAddresses/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("/settings/forwardingAddresses/"),
        );
        pathOffset += 30;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_forwardingEmail'),
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
        var resp = convert.json.encode(buildForwardingAddress());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_userId, arg_forwardingEmail, $fields: arg_$fields);
      checkForwardingAddress(response as api.ForwardingAddress);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.forwardingAddresses;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/forwardingAddresses', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("/settings/forwardingAddresses"),
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
        var resp = convert.json.encode(buildListForwardingAddressesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId, $fields: arg_$fields);
      checkListForwardingAddressesResponse(
          response as api.ListForwardingAddressesResponse);
    });
  });

  unittest.group('resource-UsersSettingsSendAsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
      var arg_request = buildSendAs();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.SendAs.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSendAs(obj as api.SendAs);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/settings/sendAs"),
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
        var resp = convert.json.encode(buildSendAs());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkSendAs(response as api.SendAs);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
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
      await res.delete(arg_userId, arg_sendAsEmail, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
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
        var resp = convert.json.encode(buildSendAs());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_userId, arg_sendAsEmail, $fields: arg_$fields);
      checkSendAs(response as api.SendAs);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
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
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 16),
          unittest.equals("/settings/sendAs"),
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
        var resp = convert.json.encode(buildListSendAsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId, $fields: arg_$fields);
      checkListSendAsResponse(response as api.ListSendAsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
      var arg_request = buildSendAs();
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.SendAs.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSendAs(obj as api.SendAs);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
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
        var resp = convert.json.encode(buildSendAs());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_userId, arg_sendAsEmail,
          $fields: arg_$fields);
      checkSendAs(response as api.SendAs);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
      var arg_request = buildSendAs();
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.SendAs.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSendAs(obj as api.SendAs);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
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
        var resp = convert.json.encode(buildSendAs());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_userId, arg_sendAsEmail,
          $fields: arg_$fields);
      checkSendAs(response as api.SendAs);
    });

    unittest.test('method--verify', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        index = path.indexOf('/verify', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.verify(arg_userId, arg_sendAsEmail, $fields: arg_$fields);
    });
  });

  unittest.group('resource-UsersSettingsSendAsSmimeInfoResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs.smimeInfo;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        index = path.indexOf('/smimeInfo/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/smimeInfo/"),
        );
        pathOffset += 11;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_userId, arg_sendAsEmail, arg_id,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs.smimeInfo;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        index = path.indexOf('/smimeInfo/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/smimeInfo/"),
        );
        pathOffset += 11;
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
        var resp = convert.json.encode(buildSmimeInfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_sendAsEmail, arg_id,
          $fields: arg_$fields);
      checkSmimeInfo(response as api.SmimeInfo);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs.smimeInfo;
      var arg_request = buildSmimeInfo();
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.SmimeInfo.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSmimeInfo(obj as api.SmimeInfo);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        index = path.indexOf('/smimeInfo', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/smimeInfo"),
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
        var resp = convert.json.encode(buildSmimeInfo());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_userId, arg_sendAsEmail,
          $fields: arg_$fields);
      checkSmimeInfo(response as api.SmimeInfo);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs.smimeInfo;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        index = path.indexOf('/smimeInfo', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/smimeInfo"),
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
        var resp = convert.json.encode(buildListSmimeInfoResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.list(arg_userId, arg_sendAsEmail, $fields: arg_$fields);
      checkListSmimeInfoResponse(response as api.ListSmimeInfoResponse);
    });

    unittest.test('method--setDefault', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.settings.sendAs.smimeInfo;
      var arg_userId = 'foo';
      var arg_sendAsEmail = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/settings/sendAs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("/settings/sendAs/"),
        );
        pathOffset += 17;
        index = path.indexOf('/smimeInfo/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_sendAsEmail'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/smimeInfo/"),
        );
        pathOffset += 11;
        index = path.indexOf('/setDefault', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/setDefault"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.setDefault(arg_userId, arg_sendAsEmail, arg_id,
          $fields: arg_$fields);
    });
  });

  unittest.group('resource-UsersThreadsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.threads;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/threads/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/threads/"),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_userId, arg_id, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.threads;
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_format = 'foo';
      var arg_metadataHeaders = buildUnnamed4005();
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/threads/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/threads/"),
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
          queryMap["format"]!.first,
          unittest.equals(arg_format),
        );
        unittest.expect(
          queryMap["metadataHeaders"]!,
          unittest.equals(arg_metadataHeaders),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildThread());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userId, arg_id,
          format: arg_format,
          metadataHeaders: arg_metadataHeaders,
          $fields: arg_$fields);
      checkThread(response as api.Thread);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.threads;
      var arg_userId = 'foo';
      var arg_includeSpamTrash = true;
      var arg_labelIds = buildUnnamed4006();
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_q = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/threads', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/threads"),
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
          queryMap["includeSpamTrash"]!.first,
          unittest.equals("$arg_includeSpamTrash"),
        );
        unittest.expect(
          queryMap["labelIds"]!,
          unittest.equals(arg_labelIds),
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
          queryMap["q"]!.first,
          unittest.equals(arg_q),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListThreadsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId,
          includeSpamTrash: arg_includeSpamTrash,
          labelIds: arg_labelIds,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          q: arg_q,
          $fields: arg_$fields);
      checkListThreadsResponse(response as api.ListThreadsResponse);
    });

    unittest.test('method--modify', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.threads;
      var arg_request = buildModifyThreadRequest();
      var arg_userId = 'foo';
      var arg_id = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyThreadRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyThreadRequest(obj as api.ModifyThreadRequest);

        var path = (req.url).path;
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/threads/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/threads/"),
        );
        pathOffset += 9;
        index = path.indexOf('/modify', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/modify"),
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
        var resp = convert.json.encode(buildThread());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.modify(arg_request, arg_userId, arg_id,
          $fields: arg_$fields);
      checkThread(response as api.Thread);
    });

    unittest.test('method--trash', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.threads;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/threads/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/threads/"),
        );
        pathOffset += 9;
        index = path.indexOf('/trash', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/trash"),
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
        var resp = convert.json.encode(buildThread());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.trash(arg_userId, arg_id, $fields: arg_$fields);
      checkThread(response as api.Thread);
    });

    unittest.test('method--untrash', () async {
      var mock = HttpServerMock();
      var res = api.GmailApi(mock).users.threads;
      var arg_userId = 'foo';
      var arg_id = 'foo';
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
          unittest.equals("gmail/v1/users/"),
        );
        pathOffset += 15;
        index = path.indexOf('/threads/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/threads/"),
        );
        pathOffset += 9;
        index = path.indexOf('/untrash', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/untrash"),
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
        var resp = convert.json.encode(buildThread());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.untrash(arg_userId, arg_id, $fields: arg_$fields);
      checkThread(response as api.Thread);
    });
  });
}
