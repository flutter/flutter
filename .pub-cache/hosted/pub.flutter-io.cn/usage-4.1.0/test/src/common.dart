// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library usage.common_test;

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:usage/src/usage_impl.dart';

AnalyticsImplMock createMock({Map<String, dynamic>? props}) =>
    AnalyticsImplMock('UA-0', props: props);

void was(String m, String type) => expect(jsonDecode(m)['t'], type);
void has(String m, String key) => expect(jsonDecode(m)[key], isNotNull);
void hasnt(String m, String key) => expect(jsonDecode(m)[key], isNull);

class AnalyticsImplMock extends AnalyticsImpl {
  MockProperties get mockProperties => properties as MockProperties;
  MockPostHandler get mockPostHandler => postHandler as MockPostHandler;

  AnalyticsImplMock(String trackingId, {Map<String, dynamic>? props})
      : super(trackingId, MockProperties(props), MockPostHandler(),
            applicationName: 'Test App', applicationVersion: '0.1');

  String get last => mockPostHandler.last;
}

class StallingAnalyticsImplMock extends AnalyticsImpl {
  StallingAnalyticsImplMock(String trackingId, {Map<String, dynamic>? props})
      : super(trackingId, MockProperties(props), StallingPostHandler(),
            applicationName: 'Test App', applicationVersion: '0.1');
}

class StallingPostHandler extends PostHandler {
  @override
  void close() {}

  @override
  String encodeHit(Map<String, String> hit) => jsonEncode(hit);

  @override
  Future sendPost(String url, List<String> batch) => Completer().future;
}

class MockProperties extends PersistentProperties {
  Map<String, dynamic> props = {};

  MockProperties([Map<String, dynamic>? props]) : super('mock') {
    if (props != null) this.props.addAll(props);
  }

  @override
  dynamic operator [](String key) => props[key];

  @override
  void operator []=(String key, dynamic value) {
    props[key] = value;
  }

  @override
  void syncSettings() {}
}

class MockPostHandler extends PostHandler {
  List<String> sentValues = [];

  @override
  Future sendPost(String url, List<String> batch) {
    sentValues.addAll(batch);

    return Future.value();
  }

  String get last => sentValues.last;

  @override
  void close() {}

  @override
  String encodeHit(Map<String, String> hit) => jsonEncode(hit);
}
