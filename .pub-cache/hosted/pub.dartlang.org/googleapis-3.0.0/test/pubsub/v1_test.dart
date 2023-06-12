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

import 'package:googleapis/pubsub/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed554() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed554(core.List<core.String> o) {
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

core.int buildCounterAcknowledgeRequest = 0;
api.AcknowledgeRequest buildAcknowledgeRequest() {
  var o = api.AcknowledgeRequest();
  buildCounterAcknowledgeRequest++;
  if (buildCounterAcknowledgeRequest < 3) {
    o.ackIds = buildUnnamed554();
  }
  buildCounterAcknowledgeRequest--;
  return o;
}

void checkAcknowledgeRequest(api.AcknowledgeRequest o) {
  buildCounterAcknowledgeRequest++;
  if (buildCounterAcknowledgeRequest < 3) {
    checkUnnamed554(o.ackIds!);
  }
  buildCounterAcknowledgeRequest--;
}

core.List<core.String> buildUnnamed555() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed555(core.List<core.String> o) {
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

core.int buildCounterBinding = 0;
api.Binding buildBinding() {
  var o = api.Binding();
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    o.condition = buildExpr();
    o.members = buildUnnamed555();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed555(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.Map<core.String, core.String> buildUnnamed556() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed556(core.Map<core.String, core.String> o) {
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

core.int buildCounterCreateSnapshotRequest = 0;
api.CreateSnapshotRequest buildCreateSnapshotRequest() {
  var o = api.CreateSnapshotRequest();
  buildCounterCreateSnapshotRequest++;
  if (buildCounterCreateSnapshotRequest < 3) {
    o.labels = buildUnnamed556();
    o.subscription = 'foo';
  }
  buildCounterCreateSnapshotRequest--;
  return o;
}

void checkCreateSnapshotRequest(api.CreateSnapshotRequest o) {
  buildCounterCreateSnapshotRequest++;
  if (buildCounterCreateSnapshotRequest < 3) {
    checkUnnamed556(o.labels!);
    unittest.expect(
      o.subscription!,
      unittest.equals('foo'),
    );
  }
  buildCounterCreateSnapshotRequest--;
}

core.int buildCounterDeadLetterPolicy = 0;
api.DeadLetterPolicy buildDeadLetterPolicy() {
  var o = api.DeadLetterPolicy();
  buildCounterDeadLetterPolicy++;
  if (buildCounterDeadLetterPolicy < 3) {
    o.deadLetterTopic = 'foo';
    o.maxDeliveryAttempts = 42;
  }
  buildCounterDeadLetterPolicy--;
  return o;
}

void checkDeadLetterPolicy(api.DeadLetterPolicy o) {
  buildCounterDeadLetterPolicy++;
  if (buildCounterDeadLetterPolicy < 3) {
    unittest.expect(
      o.deadLetterTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxDeliveryAttempts!,
      unittest.equals(42),
    );
  }
  buildCounterDeadLetterPolicy--;
}

core.int buildCounterDetachSubscriptionResponse = 0;
api.DetachSubscriptionResponse buildDetachSubscriptionResponse() {
  var o = api.DetachSubscriptionResponse();
  buildCounterDetachSubscriptionResponse++;
  if (buildCounterDetachSubscriptionResponse < 3) {}
  buildCounterDetachSubscriptionResponse--;
  return o;
}

void checkDetachSubscriptionResponse(api.DetachSubscriptionResponse o) {
  buildCounterDetachSubscriptionResponse++;
  if (buildCounterDetachSubscriptionResponse < 3) {}
  buildCounterDetachSubscriptionResponse--;
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

core.int buildCounterExpirationPolicy = 0;
api.ExpirationPolicy buildExpirationPolicy() {
  var o = api.ExpirationPolicy();
  buildCounterExpirationPolicy++;
  if (buildCounterExpirationPolicy < 3) {
    o.ttl = 'foo';
  }
  buildCounterExpirationPolicy--;
  return o;
}

void checkExpirationPolicy(api.ExpirationPolicy o) {
  buildCounterExpirationPolicy++;
  if (buildCounterExpirationPolicy < 3) {
    unittest.expect(
      o.ttl!,
      unittest.equals('foo'),
    );
  }
  buildCounterExpirationPolicy--;
}

core.int buildCounterExpr = 0;
api.Expr buildExpr() {
  var o = api.Expr();
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    o.description = 'foo';
    o.expression = 'foo';
    o.location = 'foo';
    o.title = 'foo';
  }
  buildCounterExpr--;
  return o;
}

void checkExpr(api.Expr o) {
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterExpr--;
}

core.List<api.Schema> buildUnnamed557() {
  var o = <api.Schema>[];
  o.add(buildSchema());
  o.add(buildSchema());
  return o;
}

void checkUnnamed557(core.List<api.Schema> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSchema(o[0] as api.Schema);
  checkSchema(o[1] as api.Schema);
}

core.int buildCounterListSchemasResponse = 0;
api.ListSchemasResponse buildListSchemasResponse() {
  var o = api.ListSchemasResponse();
  buildCounterListSchemasResponse++;
  if (buildCounterListSchemasResponse < 3) {
    o.nextPageToken = 'foo';
    o.schemas = buildUnnamed557();
  }
  buildCounterListSchemasResponse--;
  return o;
}

void checkListSchemasResponse(api.ListSchemasResponse o) {
  buildCounterListSchemasResponse++;
  if (buildCounterListSchemasResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed557(o.schemas!);
  }
  buildCounterListSchemasResponse--;
}

core.List<api.Snapshot> buildUnnamed558() {
  var o = <api.Snapshot>[];
  o.add(buildSnapshot());
  o.add(buildSnapshot());
  return o;
}

void checkUnnamed558(core.List<api.Snapshot> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSnapshot(o[0] as api.Snapshot);
  checkSnapshot(o[1] as api.Snapshot);
}

core.int buildCounterListSnapshotsResponse = 0;
api.ListSnapshotsResponse buildListSnapshotsResponse() {
  var o = api.ListSnapshotsResponse();
  buildCounterListSnapshotsResponse++;
  if (buildCounterListSnapshotsResponse < 3) {
    o.nextPageToken = 'foo';
    o.snapshots = buildUnnamed558();
  }
  buildCounterListSnapshotsResponse--;
  return o;
}

void checkListSnapshotsResponse(api.ListSnapshotsResponse o) {
  buildCounterListSnapshotsResponse++;
  if (buildCounterListSnapshotsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed558(o.snapshots!);
  }
  buildCounterListSnapshotsResponse--;
}

core.List<api.Subscription> buildUnnamed559() {
  var o = <api.Subscription>[];
  o.add(buildSubscription());
  o.add(buildSubscription());
  return o;
}

void checkUnnamed559(core.List<api.Subscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSubscription(o[0] as api.Subscription);
  checkSubscription(o[1] as api.Subscription);
}

core.int buildCounterListSubscriptionsResponse = 0;
api.ListSubscriptionsResponse buildListSubscriptionsResponse() {
  var o = api.ListSubscriptionsResponse();
  buildCounterListSubscriptionsResponse++;
  if (buildCounterListSubscriptionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.subscriptions = buildUnnamed559();
  }
  buildCounterListSubscriptionsResponse--;
  return o;
}

void checkListSubscriptionsResponse(api.ListSubscriptionsResponse o) {
  buildCounterListSubscriptionsResponse++;
  if (buildCounterListSubscriptionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed559(o.subscriptions!);
  }
  buildCounterListSubscriptionsResponse--;
}

core.List<core.String> buildUnnamed560() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed560(core.List<core.String> o) {
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

core.int buildCounterListTopicSnapshotsResponse = 0;
api.ListTopicSnapshotsResponse buildListTopicSnapshotsResponse() {
  var o = api.ListTopicSnapshotsResponse();
  buildCounterListTopicSnapshotsResponse++;
  if (buildCounterListTopicSnapshotsResponse < 3) {
    o.nextPageToken = 'foo';
    o.snapshots = buildUnnamed560();
  }
  buildCounterListTopicSnapshotsResponse--;
  return o;
}

void checkListTopicSnapshotsResponse(api.ListTopicSnapshotsResponse o) {
  buildCounterListTopicSnapshotsResponse++;
  if (buildCounterListTopicSnapshotsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed560(o.snapshots!);
  }
  buildCounterListTopicSnapshotsResponse--;
}

core.List<core.String> buildUnnamed561() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed561(core.List<core.String> o) {
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

core.int buildCounterListTopicSubscriptionsResponse = 0;
api.ListTopicSubscriptionsResponse buildListTopicSubscriptionsResponse() {
  var o = api.ListTopicSubscriptionsResponse();
  buildCounterListTopicSubscriptionsResponse++;
  if (buildCounterListTopicSubscriptionsResponse < 3) {
    o.nextPageToken = 'foo';
    o.subscriptions = buildUnnamed561();
  }
  buildCounterListTopicSubscriptionsResponse--;
  return o;
}

void checkListTopicSubscriptionsResponse(api.ListTopicSubscriptionsResponse o) {
  buildCounterListTopicSubscriptionsResponse++;
  if (buildCounterListTopicSubscriptionsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed561(o.subscriptions!);
  }
  buildCounterListTopicSubscriptionsResponse--;
}

core.List<api.Topic> buildUnnamed562() {
  var o = <api.Topic>[];
  o.add(buildTopic());
  o.add(buildTopic());
  return o;
}

void checkUnnamed562(core.List<api.Topic> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTopic(o[0] as api.Topic);
  checkTopic(o[1] as api.Topic);
}

core.int buildCounterListTopicsResponse = 0;
api.ListTopicsResponse buildListTopicsResponse() {
  var o = api.ListTopicsResponse();
  buildCounterListTopicsResponse++;
  if (buildCounterListTopicsResponse < 3) {
    o.nextPageToken = 'foo';
    o.topics = buildUnnamed562();
  }
  buildCounterListTopicsResponse--;
  return o;
}

void checkListTopicsResponse(api.ListTopicsResponse o) {
  buildCounterListTopicsResponse++;
  if (buildCounterListTopicsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed562(o.topics!);
  }
  buildCounterListTopicsResponse--;
}

core.List<core.String> buildUnnamed563() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed563(core.List<core.String> o) {
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

core.int buildCounterMessageStoragePolicy = 0;
api.MessageStoragePolicy buildMessageStoragePolicy() {
  var o = api.MessageStoragePolicy();
  buildCounterMessageStoragePolicy++;
  if (buildCounterMessageStoragePolicy < 3) {
    o.allowedPersistenceRegions = buildUnnamed563();
  }
  buildCounterMessageStoragePolicy--;
  return o;
}

void checkMessageStoragePolicy(api.MessageStoragePolicy o) {
  buildCounterMessageStoragePolicy++;
  if (buildCounterMessageStoragePolicy < 3) {
    checkUnnamed563(o.allowedPersistenceRegions!);
  }
  buildCounterMessageStoragePolicy--;
}

core.List<core.String> buildUnnamed564() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed564(core.List<core.String> o) {
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

core.int buildCounterModifyAckDeadlineRequest = 0;
api.ModifyAckDeadlineRequest buildModifyAckDeadlineRequest() {
  var o = api.ModifyAckDeadlineRequest();
  buildCounterModifyAckDeadlineRequest++;
  if (buildCounterModifyAckDeadlineRequest < 3) {
    o.ackDeadlineSeconds = 42;
    o.ackIds = buildUnnamed564();
  }
  buildCounterModifyAckDeadlineRequest--;
  return o;
}

void checkModifyAckDeadlineRequest(api.ModifyAckDeadlineRequest o) {
  buildCounterModifyAckDeadlineRequest++;
  if (buildCounterModifyAckDeadlineRequest < 3) {
    unittest.expect(
      o.ackDeadlineSeconds!,
      unittest.equals(42),
    );
    checkUnnamed564(o.ackIds!);
  }
  buildCounterModifyAckDeadlineRequest--;
}

core.int buildCounterModifyPushConfigRequest = 0;
api.ModifyPushConfigRequest buildModifyPushConfigRequest() {
  var o = api.ModifyPushConfigRequest();
  buildCounterModifyPushConfigRequest++;
  if (buildCounterModifyPushConfigRequest < 3) {
    o.pushConfig = buildPushConfig();
  }
  buildCounterModifyPushConfigRequest--;
  return o;
}

void checkModifyPushConfigRequest(api.ModifyPushConfigRequest o) {
  buildCounterModifyPushConfigRequest++;
  if (buildCounterModifyPushConfigRequest < 3) {
    checkPushConfig(o.pushConfig! as api.PushConfig);
  }
  buildCounterModifyPushConfigRequest--;
}

core.int buildCounterOidcToken = 0;
api.OidcToken buildOidcToken() {
  var o = api.OidcToken();
  buildCounterOidcToken++;
  if (buildCounterOidcToken < 3) {
    o.audience = 'foo';
    o.serviceAccountEmail = 'foo';
  }
  buildCounterOidcToken--;
  return o;
}

void checkOidcToken(api.OidcToken o) {
  buildCounterOidcToken++;
  if (buildCounterOidcToken < 3) {
    unittest.expect(
      o.audience!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.serviceAccountEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterOidcToken--;
}

core.List<api.Binding> buildUnnamed565() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed565(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.bindings = buildUnnamed565();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed565(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterPolicy--;
}

core.List<api.PubsubMessage> buildUnnamed566() {
  var o = <api.PubsubMessage>[];
  o.add(buildPubsubMessage());
  o.add(buildPubsubMessage());
  return o;
}

void checkUnnamed566(core.List<api.PubsubMessage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPubsubMessage(o[0] as api.PubsubMessage);
  checkPubsubMessage(o[1] as api.PubsubMessage);
}

core.int buildCounterPublishRequest = 0;
api.PublishRequest buildPublishRequest() {
  var o = api.PublishRequest();
  buildCounterPublishRequest++;
  if (buildCounterPublishRequest < 3) {
    o.messages = buildUnnamed566();
  }
  buildCounterPublishRequest--;
  return o;
}

void checkPublishRequest(api.PublishRequest o) {
  buildCounterPublishRequest++;
  if (buildCounterPublishRequest < 3) {
    checkUnnamed566(o.messages!);
  }
  buildCounterPublishRequest--;
}

core.List<core.String> buildUnnamed567() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed567(core.List<core.String> o) {
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

core.int buildCounterPublishResponse = 0;
api.PublishResponse buildPublishResponse() {
  var o = api.PublishResponse();
  buildCounterPublishResponse++;
  if (buildCounterPublishResponse < 3) {
    o.messageIds = buildUnnamed567();
  }
  buildCounterPublishResponse--;
  return o;
}

void checkPublishResponse(api.PublishResponse o) {
  buildCounterPublishResponse++;
  if (buildCounterPublishResponse < 3) {
    checkUnnamed567(o.messageIds!);
  }
  buildCounterPublishResponse--;
}

core.Map<core.String, core.String> buildUnnamed568() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed568(core.Map<core.String, core.String> o) {
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

core.int buildCounterPubsubMessage = 0;
api.PubsubMessage buildPubsubMessage() {
  var o = api.PubsubMessage();
  buildCounterPubsubMessage++;
  if (buildCounterPubsubMessage < 3) {
    o.attributes = buildUnnamed568();
    o.data = 'foo';
    o.messageId = 'foo';
    o.orderingKey = 'foo';
    o.publishTime = 'foo';
  }
  buildCounterPubsubMessage--;
  return o;
}

void checkPubsubMessage(api.PubsubMessage o) {
  buildCounterPubsubMessage++;
  if (buildCounterPubsubMessage < 3) {
    checkUnnamed568(o.attributes!);
    unittest.expect(
      o.data!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.messageId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.orderingKey!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.publishTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterPubsubMessage--;
}

core.int buildCounterPullRequest = 0;
api.PullRequest buildPullRequest() {
  var o = api.PullRequest();
  buildCounterPullRequest++;
  if (buildCounterPullRequest < 3) {
    o.maxMessages = 42;
    o.returnImmediately = true;
  }
  buildCounterPullRequest--;
  return o;
}

void checkPullRequest(api.PullRequest o) {
  buildCounterPullRequest++;
  if (buildCounterPullRequest < 3) {
    unittest.expect(
      o.maxMessages!,
      unittest.equals(42),
    );
    unittest.expect(o.returnImmediately!, unittest.isTrue);
  }
  buildCounterPullRequest--;
}

core.List<api.ReceivedMessage> buildUnnamed569() {
  var o = <api.ReceivedMessage>[];
  o.add(buildReceivedMessage());
  o.add(buildReceivedMessage());
  return o;
}

void checkUnnamed569(core.List<api.ReceivedMessage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReceivedMessage(o[0] as api.ReceivedMessage);
  checkReceivedMessage(o[1] as api.ReceivedMessage);
}

core.int buildCounterPullResponse = 0;
api.PullResponse buildPullResponse() {
  var o = api.PullResponse();
  buildCounterPullResponse++;
  if (buildCounterPullResponse < 3) {
    o.receivedMessages = buildUnnamed569();
  }
  buildCounterPullResponse--;
  return o;
}

void checkPullResponse(api.PullResponse o) {
  buildCounterPullResponse++;
  if (buildCounterPullResponse < 3) {
    checkUnnamed569(o.receivedMessages!);
  }
  buildCounterPullResponse--;
}

core.Map<core.String, core.String> buildUnnamed570() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed570(core.Map<core.String, core.String> o) {
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

core.int buildCounterPushConfig = 0;
api.PushConfig buildPushConfig() {
  var o = api.PushConfig();
  buildCounterPushConfig++;
  if (buildCounterPushConfig < 3) {
    o.attributes = buildUnnamed570();
    o.oidcToken = buildOidcToken();
    o.pushEndpoint = 'foo';
  }
  buildCounterPushConfig--;
  return o;
}

void checkPushConfig(api.PushConfig o) {
  buildCounterPushConfig++;
  if (buildCounterPushConfig < 3) {
    checkUnnamed570(o.attributes!);
    checkOidcToken(o.oidcToken! as api.OidcToken);
    unittest.expect(
      o.pushEndpoint!,
      unittest.equals('foo'),
    );
  }
  buildCounterPushConfig--;
}

core.int buildCounterReceivedMessage = 0;
api.ReceivedMessage buildReceivedMessage() {
  var o = api.ReceivedMessage();
  buildCounterReceivedMessage++;
  if (buildCounterReceivedMessage < 3) {
    o.ackId = 'foo';
    o.deliveryAttempt = 42;
    o.message = buildPubsubMessage();
  }
  buildCounterReceivedMessage--;
  return o;
}

void checkReceivedMessage(api.ReceivedMessage o) {
  buildCounterReceivedMessage++;
  if (buildCounterReceivedMessage < 3) {
    unittest.expect(
      o.ackId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deliveryAttempt!,
      unittest.equals(42),
    );
    checkPubsubMessage(o.message! as api.PubsubMessage);
  }
  buildCounterReceivedMessage--;
}

core.int buildCounterRetryPolicy = 0;
api.RetryPolicy buildRetryPolicy() {
  var o = api.RetryPolicy();
  buildCounterRetryPolicy++;
  if (buildCounterRetryPolicy < 3) {
    o.maximumBackoff = 'foo';
    o.minimumBackoff = 'foo';
  }
  buildCounterRetryPolicy--;
  return o;
}

void checkRetryPolicy(api.RetryPolicy o) {
  buildCounterRetryPolicy++;
  if (buildCounterRetryPolicy < 3) {
    unittest.expect(
      o.maximumBackoff!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minimumBackoff!,
      unittest.equals('foo'),
    );
  }
  buildCounterRetryPolicy--;
}

core.int buildCounterSchema = 0;
api.Schema buildSchema() {
  var o = api.Schema();
  buildCounterSchema++;
  if (buildCounterSchema < 3) {
    o.definition = 'foo';
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterSchema--;
  return o;
}

void checkSchema(api.Schema o) {
  buildCounterSchema++;
  if (buildCounterSchema < 3) {
    unittest.expect(
      o.definition!,
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
  buildCounterSchema--;
}

core.int buildCounterSchemaSettings = 0;
api.SchemaSettings buildSchemaSettings() {
  var o = api.SchemaSettings();
  buildCounterSchemaSettings++;
  if (buildCounterSchemaSettings < 3) {
    o.encoding = 'foo';
    o.schema = 'foo';
  }
  buildCounterSchemaSettings--;
  return o;
}

void checkSchemaSettings(api.SchemaSettings o) {
  buildCounterSchemaSettings++;
  if (buildCounterSchemaSettings < 3) {
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.schema!,
      unittest.equals('foo'),
    );
  }
  buildCounterSchemaSettings--;
}

core.int buildCounterSeekRequest = 0;
api.SeekRequest buildSeekRequest() {
  var o = api.SeekRequest();
  buildCounterSeekRequest++;
  if (buildCounterSeekRequest < 3) {
    o.snapshot = 'foo';
    o.time = 'foo';
  }
  buildCounterSeekRequest--;
  return o;
}

void checkSeekRequest(api.SeekRequest o) {
  buildCounterSeekRequest++;
  if (buildCounterSeekRequest < 3) {
    unittest.expect(
      o.snapshot!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.time!,
      unittest.equals('foo'),
    );
  }
  buildCounterSeekRequest--;
}

core.int buildCounterSeekResponse = 0;
api.SeekResponse buildSeekResponse() {
  var o = api.SeekResponse();
  buildCounterSeekResponse++;
  if (buildCounterSeekResponse < 3) {}
  buildCounterSeekResponse--;
  return o;
}

void checkSeekResponse(api.SeekResponse o) {
  buildCounterSeekResponse++;
  if (buildCounterSeekResponse < 3) {}
  buildCounterSeekResponse--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildPolicy();
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkPolicy(o.policy! as api.Policy);
  }
  buildCounterSetIamPolicyRequest--;
}

core.Map<core.String, core.String> buildUnnamed571() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed571(core.Map<core.String, core.String> o) {
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

core.int buildCounterSnapshot = 0;
api.Snapshot buildSnapshot() {
  var o = api.Snapshot();
  buildCounterSnapshot++;
  if (buildCounterSnapshot < 3) {
    o.expireTime = 'foo';
    o.labels = buildUnnamed571();
    o.name = 'foo';
    o.topic = 'foo';
  }
  buildCounterSnapshot--;
  return o;
}

void checkSnapshot(api.Snapshot o) {
  buildCounterSnapshot++;
  if (buildCounterSnapshot < 3) {
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    checkUnnamed571(o.labels!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.topic!,
      unittest.equals('foo'),
    );
  }
  buildCounterSnapshot--;
}

core.Map<core.String, core.String> buildUnnamed572() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed572(core.Map<core.String, core.String> o) {
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

core.int buildCounterSubscription = 0;
api.Subscription buildSubscription() {
  var o = api.Subscription();
  buildCounterSubscription++;
  if (buildCounterSubscription < 3) {
    o.ackDeadlineSeconds = 42;
    o.deadLetterPolicy = buildDeadLetterPolicy();
    o.detached = true;
    o.enableMessageOrdering = true;
    o.expirationPolicy = buildExpirationPolicy();
    o.filter = 'foo';
    o.labels = buildUnnamed572();
    o.messageRetentionDuration = 'foo';
    o.name = 'foo';
    o.pushConfig = buildPushConfig();
    o.retainAckedMessages = true;
    o.retryPolicy = buildRetryPolicy();
    o.topic = 'foo';
  }
  buildCounterSubscription--;
  return o;
}

void checkSubscription(api.Subscription o) {
  buildCounterSubscription++;
  if (buildCounterSubscription < 3) {
    unittest.expect(
      o.ackDeadlineSeconds!,
      unittest.equals(42),
    );
    checkDeadLetterPolicy(o.deadLetterPolicy! as api.DeadLetterPolicy);
    unittest.expect(o.detached!, unittest.isTrue);
    unittest.expect(o.enableMessageOrdering!, unittest.isTrue);
    checkExpirationPolicy(o.expirationPolicy! as api.ExpirationPolicy);
    unittest.expect(
      o.filter!,
      unittest.equals('foo'),
    );
    checkUnnamed572(o.labels!);
    unittest.expect(
      o.messageRetentionDuration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkPushConfig(o.pushConfig! as api.PushConfig);
    unittest.expect(o.retainAckedMessages!, unittest.isTrue);
    checkRetryPolicy(o.retryPolicy! as api.RetryPolicy);
    unittest.expect(
      o.topic!,
      unittest.equals('foo'),
    );
  }
  buildCounterSubscription--;
}

core.List<core.String> buildUnnamed573() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed573(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsRequest = 0;
api.TestIamPermissionsRequest buildTestIamPermissionsRequest() {
  var o = api.TestIamPermissionsRequest();
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    o.permissions = buildUnnamed573();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed573(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed574() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed574(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsResponse = 0;
api.TestIamPermissionsResponse buildTestIamPermissionsResponse() {
  var o = api.TestIamPermissionsResponse();
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    o.permissions = buildUnnamed574();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed574(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.Map<core.String, core.String> buildUnnamed575() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed575(core.Map<core.String, core.String> o) {
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

core.int buildCounterTopic = 0;
api.Topic buildTopic() {
  var o = api.Topic();
  buildCounterTopic++;
  if (buildCounterTopic < 3) {
    o.kmsKeyName = 'foo';
    o.labels = buildUnnamed575();
    o.messageStoragePolicy = buildMessageStoragePolicy();
    o.name = 'foo';
    o.satisfiesPzs = true;
    o.schemaSettings = buildSchemaSettings();
  }
  buildCounterTopic--;
  return o;
}

void checkTopic(api.Topic o) {
  buildCounterTopic++;
  if (buildCounterTopic < 3) {
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
    checkUnnamed575(o.labels!);
    checkMessageStoragePolicy(
        o.messageStoragePolicy! as api.MessageStoragePolicy);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.satisfiesPzs!, unittest.isTrue);
    checkSchemaSettings(o.schemaSettings! as api.SchemaSettings);
  }
  buildCounterTopic--;
}

core.int buildCounterUpdateSnapshotRequest = 0;
api.UpdateSnapshotRequest buildUpdateSnapshotRequest() {
  var o = api.UpdateSnapshotRequest();
  buildCounterUpdateSnapshotRequest++;
  if (buildCounterUpdateSnapshotRequest < 3) {
    o.snapshot = buildSnapshot();
    o.updateMask = 'foo';
  }
  buildCounterUpdateSnapshotRequest--;
  return o;
}

void checkUpdateSnapshotRequest(api.UpdateSnapshotRequest o) {
  buildCounterUpdateSnapshotRequest++;
  if (buildCounterUpdateSnapshotRequest < 3) {
    checkSnapshot(o.snapshot! as api.Snapshot);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateSnapshotRequest--;
}

core.int buildCounterUpdateSubscriptionRequest = 0;
api.UpdateSubscriptionRequest buildUpdateSubscriptionRequest() {
  var o = api.UpdateSubscriptionRequest();
  buildCounterUpdateSubscriptionRequest++;
  if (buildCounterUpdateSubscriptionRequest < 3) {
    o.subscription = buildSubscription();
    o.updateMask = 'foo';
  }
  buildCounterUpdateSubscriptionRequest--;
  return o;
}

void checkUpdateSubscriptionRequest(api.UpdateSubscriptionRequest o) {
  buildCounterUpdateSubscriptionRequest++;
  if (buildCounterUpdateSubscriptionRequest < 3) {
    checkSubscription(o.subscription! as api.Subscription);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateSubscriptionRequest--;
}

core.int buildCounterUpdateTopicRequest = 0;
api.UpdateTopicRequest buildUpdateTopicRequest() {
  var o = api.UpdateTopicRequest();
  buildCounterUpdateTopicRequest++;
  if (buildCounterUpdateTopicRequest < 3) {
    o.topic = buildTopic();
    o.updateMask = 'foo';
  }
  buildCounterUpdateTopicRequest--;
  return o;
}

void checkUpdateTopicRequest(api.UpdateTopicRequest o) {
  buildCounterUpdateTopicRequest++;
  if (buildCounterUpdateTopicRequest < 3) {
    checkTopic(o.topic! as api.Topic);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdateTopicRequest--;
}

core.int buildCounterValidateMessageRequest = 0;
api.ValidateMessageRequest buildValidateMessageRequest() {
  var o = api.ValidateMessageRequest();
  buildCounterValidateMessageRequest++;
  if (buildCounterValidateMessageRequest < 3) {
    o.encoding = 'foo';
    o.message = 'foo';
    o.name = 'foo';
    o.schema = buildSchema();
  }
  buildCounterValidateMessageRequest--;
  return o;
}

void checkValidateMessageRequest(api.ValidateMessageRequest o) {
  buildCounterValidateMessageRequest++;
  if (buildCounterValidateMessageRequest < 3) {
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkSchema(o.schema! as api.Schema);
  }
  buildCounterValidateMessageRequest--;
}

core.int buildCounterValidateMessageResponse = 0;
api.ValidateMessageResponse buildValidateMessageResponse() {
  var o = api.ValidateMessageResponse();
  buildCounterValidateMessageResponse++;
  if (buildCounterValidateMessageResponse < 3) {}
  buildCounterValidateMessageResponse--;
  return o;
}

void checkValidateMessageResponse(api.ValidateMessageResponse o) {
  buildCounterValidateMessageResponse++;
  if (buildCounterValidateMessageResponse < 3) {}
  buildCounterValidateMessageResponse--;
}

core.int buildCounterValidateSchemaRequest = 0;
api.ValidateSchemaRequest buildValidateSchemaRequest() {
  var o = api.ValidateSchemaRequest();
  buildCounterValidateSchemaRequest++;
  if (buildCounterValidateSchemaRequest < 3) {
    o.schema = buildSchema();
  }
  buildCounterValidateSchemaRequest--;
  return o;
}

void checkValidateSchemaRequest(api.ValidateSchemaRequest o) {
  buildCounterValidateSchemaRequest++;
  if (buildCounterValidateSchemaRequest < 3) {
    checkSchema(o.schema! as api.Schema);
  }
  buildCounterValidateSchemaRequest--;
}

core.int buildCounterValidateSchemaResponse = 0;
api.ValidateSchemaResponse buildValidateSchemaResponse() {
  var o = api.ValidateSchemaResponse();
  buildCounterValidateSchemaResponse++;
  if (buildCounterValidateSchemaResponse < 3) {}
  buildCounterValidateSchemaResponse--;
  return o;
}

void checkValidateSchemaResponse(api.ValidateSchemaResponse o) {
  buildCounterValidateSchemaResponse++;
  if (buildCounterValidateSchemaResponse < 3) {}
  buildCounterValidateSchemaResponse--;
}

void main() {
  unittest.group('obj-schema-AcknowledgeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAcknowledgeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AcknowledgeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAcknowledgeRequest(od as api.AcknowledgeRequest);
    });
  });

  unittest.group('obj-schema-Binding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Binding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBinding(od as api.Binding);
    });
  });

  unittest.group('obj-schema-CreateSnapshotRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCreateSnapshotRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CreateSnapshotRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCreateSnapshotRequest(od as api.CreateSnapshotRequest);
    });
  });

  unittest.group('obj-schema-DeadLetterPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeadLetterPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeadLetterPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeadLetterPolicy(od as api.DeadLetterPolicy);
    });
  });

  unittest.group('obj-schema-DetachSubscriptionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDetachSubscriptionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DetachSubscriptionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDetachSubscriptionResponse(od as api.DetachSubscriptionResponse);
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

  unittest.group('obj-schema-ExpirationPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpirationPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExpirationPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExpirationPolicy(od as api.ExpirationPolicy);
    });
  });

  unittest.group('obj-schema-Expr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Expr.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExpr(od as api.Expr);
    });
  });

  unittest.group('obj-schema-ListSchemasResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSchemasResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSchemasResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSchemasResponse(od as api.ListSchemasResponse);
    });
  });

  unittest.group('obj-schema-ListSnapshotsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSnapshotsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSnapshotsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSnapshotsResponse(od as api.ListSnapshotsResponse);
    });
  });

  unittest.group('obj-schema-ListSubscriptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSubscriptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSubscriptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSubscriptionsResponse(od as api.ListSubscriptionsResponse);
    });
  });

  unittest.group('obj-schema-ListTopicSnapshotsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTopicSnapshotsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTopicSnapshotsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTopicSnapshotsResponse(od as api.ListTopicSnapshotsResponse);
    });
  });

  unittest.group('obj-schema-ListTopicSubscriptionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTopicSubscriptionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTopicSubscriptionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTopicSubscriptionsResponse(
          od as api.ListTopicSubscriptionsResponse);
    });
  });

  unittest.group('obj-schema-ListTopicsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTopicsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTopicsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTopicsResponse(od as api.ListTopicsResponse);
    });
  });

  unittest.group('obj-schema-MessageStoragePolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessageStoragePolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MessageStoragePolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMessageStoragePolicy(od as api.MessageStoragePolicy);
    });
  });

  unittest.group('obj-schema-ModifyAckDeadlineRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyAckDeadlineRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyAckDeadlineRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyAckDeadlineRequest(od as api.ModifyAckDeadlineRequest);
    });
  });

  unittest.group('obj-schema-ModifyPushConfigRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModifyPushConfigRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModifyPushConfigRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModifyPushConfigRequest(od as api.ModifyPushConfigRequest);
    });
  });

  unittest.group('obj-schema-OidcToken', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOidcToken();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.OidcToken.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOidcToken(od as api.OidcToken);
    });
  });

  unittest.group('obj-schema-Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicy(od as api.Policy);
    });
  });

  unittest.group('obj-schema-PublishRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublishRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublishRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublishRequest(od as api.PublishRequest);
    });
  });

  unittest.group('obj-schema-PublishResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPublishResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PublishResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPublishResponse(od as api.PublishResponse);
    });
  });

  unittest.group('obj-schema-PubsubMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPubsubMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PubsubMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPubsubMessage(od as api.PubsubMessage);
    });
  });

  unittest.group('obj-schema-PullRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPullRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PullRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPullRequest(od as api.PullRequest);
    });
  });

  unittest.group('obj-schema-PullResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPullResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PullResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPullResponse(od as api.PullResponse);
    });
  });

  unittest.group('obj-schema-PushConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPushConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PushConfig.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPushConfig(od as api.PushConfig);
    });
  });

  unittest.group('obj-schema-ReceivedMessage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReceivedMessage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ReceivedMessage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkReceivedMessage(od as api.ReceivedMessage);
    });
  });

  unittest.group('obj-schema-RetryPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRetryPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RetryPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRetryPolicy(od as api.RetryPolicy);
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

  unittest.group('obj-schema-SchemaSettings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSchemaSettings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SchemaSettings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSchemaSettings(od as api.SchemaSettings);
    });
  });

  unittest.group('obj-schema-SeekRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSeekRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SeekRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSeekRequest(od as api.SeekRequest);
    });
  });

  unittest.group('obj-schema-SeekResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSeekResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SeekResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSeekResponse(od as api.SeekResponse);
    });
  });

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
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

  unittest.group('obj-schema-Subscription', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSubscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Subscription.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSubscription(od as api.Subscription);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsRequest(od as api.TestIamPermissionsRequest);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsResponse(od as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('obj-schema-Topic', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTopic();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Topic.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTopic(od as api.Topic);
    });
  });

  unittest.group('obj-schema-UpdateSnapshotRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSnapshotRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSnapshotRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSnapshotRequest(od as api.UpdateSnapshotRequest);
    });
  });

  unittest.group('obj-schema-UpdateSubscriptionRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateSubscriptionRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateSubscriptionRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateSubscriptionRequest(od as api.UpdateSubscriptionRequest);
    });
  });

  unittest.group('obj-schema-UpdateTopicRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdateTopicRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdateTopicRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdateTopicRequest(od as api.UpdateTopicRequest);
    });
  });

  unittest.group('obj-schema-ValidateMessageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValidateMessageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValidateMessageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValidateMessageRequest(od as api.ValidateMessageRequest);
    });
  });

  unittest.group('obj-schema-ValidateMessageResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValidateMessageResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValidateMessageResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValidateMessageResponse(od as api.ValidateMessageResponse);
    });
  });

  unittest.group('obj-schema-ValidateSchemaRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValidateSchemaRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValidateSchemaRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValidateSchemaRequest(od as api.ValidateSchemaRequest);
    });
  });

  unittest.group('obj-schema-ValidateSchemaResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValidateSchemaResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValidateSchemaResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValidateSchemaResponse(od as api.ValidateSchemaResponse);
    });
  });

  unittest.group('resource-ProjectsSchemasResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_request = buildSchema();
      var arg_parent = 'foo';
      var arg_schemaId = 'foo';
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
          queryMap["schemaId"]!.first,
          unittest.equals(arg_schemaId),
        );
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
      final response = await res.create(arg_request, arg_parent,
          schemaId: arg_schemaId, $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
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
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_name = 'foo';
      var arg_view = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
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
          await res.get(arg_name, view: arg_view, $fields: arg_$fields);
      checkSchema(response as api.Schema);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_resource = 'foo';
      var arg_options_requestedPolicyVersion = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          core.int.parse(queryMap["options.requestedPolicyVersion"]!.first),
          unittest.equals(arg_options_requestedPolicyVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_parent = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_view = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListSchemasResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListSchemasResponse(response as api.ListSchemasResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });

    unittest.test('method--validate', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_request = buildValidateSchemaRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ValidateSchemaRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkValidateSchemaRequest(obj as api.ValidateSchemaRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildValidateSchemaResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.validate(arg_request, arg_parent, $fields: arg_$fields);
      checkValidateSchemaResponse(response as api.ValidateSchemaResponse);
    });

    unittest.test('method--validateMessage', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.schemas;
      var arg_request = buildValidateMessageRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ValidateMessageRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkValidateMessageRequest(obj as api.ValidateMessageRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildValidateMessageResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.validateMessage(arg_request, arg_parent,
          $fields: arg_$fields);
      checkValidateMessageResponse(response as api.ValidateMessageResponse);
    });
  });

  unittest.group('resource-ProjectsSnapshotsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_request = buildCreateSnapshotRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CreateSnapshotRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCreateSnapshotRequest(obj as api.CreateSnapshotRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSnapshot());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_name, $fields: arg_$fields);
      checkSnapshot(response as api.Snapshot);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_snapshot = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
      final response = await res.delete(arg_snapshot, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_snapshot = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSnapshot());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_snapshot, $fields: arg_$fields);
      checkSnapshot(response as api.Snapshot);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_resource = 'foo';
      var arg_options_requestedPolicyVersion = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          core.int.parse(queryMap["options.requestedPolicyVersion"]!.first),
          unittest.equals(arg_options_requestedPolicyVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_project = 'foo';
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
        var resp = convert.json.encode(buildListSnapshotsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSnapshotsResponse(response as api.ListSnapshotsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_request = buildUpdateSnapshotRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateSnapshotRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateSnapshotRequest(obj as api.UpdateSnapshotRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSnapshot());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkSnapshot(response as api.Snapshot);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.snapshots;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('resource-ProjectsSubscriptionsResource', () {
    unittest.test('method--acknowledge', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildAcknowledgeRequest();
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AcknowledgeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAcknowledgeRequest(obj as api.AcknowledgeRequest);

        var path = (req.url).path;
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
      final response = await res.acknowledge(arg_request, arg_subscription,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildSubscription();
      var arg_name = 'foo';
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_name, $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
      final response = await res.delete(arg_subscription, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--detach', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
        var resp = convert.json.encode(buildDetachSubscriptionResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.detach(arg_subscription, $fields: arg_$fields);
      checkDetachSubscriptionResponse(
          response as api.DetachSubscriptionResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_subscription, $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_resource = 'foo';
      var arg_options_requestedPolicyVersion = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          core.int.parse(queryMap["options.requestedPolicyVersion"]!.first),
          unittest.equals(arg_options_requestedPolicyVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_project = 'foo';
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
        var resp = convert.json.encode(buildListSubscriptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListSubscriptionsResponse(response as api.ListSubscriptionsResponse);
    });

    unittest.test('method--modifyAckDeadline', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildModifyAckDeadlineRequest();
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyAckDeadlineRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyAckDeadlineRequest(obj as api.ModifyAckDeadlineRequest);

        var path = (req.url).path;
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
      final response = await res.modifyAckDeadline(
          arg_request, arg_subscription,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--modifyPushConfig', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildModifyPushConfigRequest();
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.ModifyPushConfigRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkModifyPushConfigRequest(obj as api.ModifyPushConfigRequest);

        var path = (req.url).path;
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
      final response = await res.modifyPushConfig(arg_request, arg_subscription,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildUpdateSubscriptionRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateSubscriptionRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateSubscriptionRequest(obj as api.UpdateSubscriptionRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSubscription());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkSubscription(response as api.Subscription);
    });

    unittest.test('method--pull', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildPullRequest();
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PullRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPullRequest(obj as api.PullRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPullResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.pull(arg_request, arg_subscription, $fields: arg_$fields);
      checkPullResponse(response as api.PullResponse);
    });

    unittest.test('method--seek', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildSeekRequest();
      var arg_subscription = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SeekRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSeekRequest(obj as api.SeekRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildSeekResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.seek(arg_request, arg_subscription, $fields: arg_$fields);
      checkSeekResponse(response as api.SeekResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.subscriptions;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('resource-ProjectsTopicsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_request = buildTopic();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Topic.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTopic(obj as api.Topic);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTopic());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_name, $fields: arg_$fields);
      checkTopic(response as api.Topic);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_topic = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
      final response = await res.delete(arg_topic, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_topic = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTopic());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_topic, $fields: arg_$fields);
      checkTopic(response as api.Topic);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_resource = 'foo';
      var arg_options_requestedPolicyVersion = 42;
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
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
          core.int.parse(queryMap["options.requestedPolicyVersion"]!.first),
          unittest.equals(arg_options_requestedPolicyVersion),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_resource,
          options_requestedPolicyVersion: arg_options_requestedPolicyVersion,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_project = 'foo';
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
        var resp = convert.json.encode(buildListTopicsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_project,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListTopicsResponse(response as api.ListTopicsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_request = buildUpdateTopicRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.UpdateTopicRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkUpdateTopicRequest(obj as api.UpdateTopicRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTopic());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.patch(arg_request, arg_name, $fields: arg_$fields);
      checkTopic(response as api.Topic);
    });

    unittest.test('method--publish', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_request = buildPublishRequest();
      var arg_topic = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.PublishRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkPublishRequest(obj as api.PublishRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPublishResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.publish(arg_request, arg_topic, $fields: arg_$fields);
      checkPublishResponse(response as api.PublishResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

        var path = (req.url).path;
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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('resource-ProjectsTopicsSnapshotsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics.snapshots;
      var arg_topic = 'foo';
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
        var resp = convert.json.encode(buildListTopicSnapshotsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_topic,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListTopicSnapshotsResponse(
          response as api.ListTopicSnapshotsResponse);
    });
  });

  unittest.group('resource-ProjectsTopicsSubscriptionsResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PubsubApi(mock).projects.topics.subscriptions;
      var arg_topic = 'foo';
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
        var resp = convert.json.encode(buildListTopicSubscriptionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_topic,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListTopicSubscriptionsResponse(
          response as api.ListTopicSubscriptionsResponse);
    });
  });
}
