// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/services.dart';
import 'test_step.dart';

Future<TestStepResult> basicStringMessaging(String messageSent) async {
  const BasicMessageChannel<String> channel = const BasicMessageChannel<String>(
    'basic-msg-string',
    const StringCodec(),
  );
  assert(messageSent != '-');
  final List<String> messages = <String>[];
  channel.setMessageHandler((String message) async {
    messages.add(message);
    return message;
  });
  final String messageEcho = await channel.send(messageSent);
  while (messages.length < 2) messages.add('-');
  TestStatus status = TestStatus.ok;
  if (messageEcho != messageSent ||
      messages.length != 2 ||
      messages[0] != messageSent ||
      messages[1] != messageSent) {
    status = TestStatus.failed;
  }
  return new TestStepResult(
    'Basic string message >$messageSent<',
    status,
    messageSent: messageSent,
    messageEcho: messageEcho,
    messageReceived: messages[0],
    replyEcho: messages[1],
  );
}

Future<TestStepResult> basicJsonMessaging(dynamic messageSent) async {
  const BasicMessageChannel<dynamic> channel =
      const BasicMessageChannel<dynamic>(
    'basic-msg-json',
    const JSONMessageCodec(),
  );
  assert(messageSent != '-');
  final List<dynamic> messages = <dynamic>[];
  channel.setMessageHandler((dynamic message) async {
    messages.add(message);
    return message;
  });
  final dynamic messageEcho = await channel.send(messageSent);
  while (messages.length < 2) messages.add('-');
  TestStatus status = TestStatus.ok;
  if (!_deepEquals(messageEcho, messageSent) ||
      messages.length != 2 ||
      !_deepEquals(messages[0], messageSent) ||
      !_deepEquals(messages[1], messageSent)) {
    status = TestStatus.failed;
  }
  return new TestStepResult(
    'Basic JSON message >$messageSent<',
    status,
    messageSent: '$messageSent',
    messageEcho: '$messageEcho',
    messageReceived: '${messages[0]}',
    replyEcho: '${messages[1]}',
  );
}

bool _deepEquals(dynamic a, dynamic b) {
  if (a == b) return true;
  if (a is List) return b is List && _deepEqualsList(a, b);
  if (a is Map) return b is Map && _deepEqualsMap(a, b);
  return false;
}

bool _deepEqualsList(List<dynamic> a, List<dynamic> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (!_deepEquals(a[i], b[i])) return false;
  }
  return true;
}

bool _deepEqualsMap(Map<dynamic, dynamic> a, Map<dynamic, dynamic> b) {
  if (a.length != b.length) return false;
  for (dynamic key in a.keys) {
    if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
  }
  return true;
}
