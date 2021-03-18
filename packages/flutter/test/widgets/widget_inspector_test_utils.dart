// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class TestWidgetInspectorService extends Object with WidgetInspectorService {
  final Map<String, ServiceExtensionCallback> extensions = <String, ServiceExtensionCallback>{};

  final Map<String, List<Map<Object, Object?>>> eventsDispatched = <String, List<Map<Object, Object?>>>{};

  @override
  void registerServiceExtension({
    required String name,
    required ServiceExtensionCallback callback,
  }) {
    assert(!extensions.containsKey(name));
    extensions[name] = callback;
  }

  @override
  void postEvent(String eventKind, Map<Object, Object?> eventData) {
    getEventsDispatched(eventKind).add(eventData);
  }

  List<Map<Object, Object?>> getEventsDispatched(String eventKind) {
    return eventsDispatched.putIfAbsent(eventKind, () => <Map<Object, Object?>>[]);
  }

  Iterable<Map<Object, Object?>> getServiceExtensionStateChangedEvents(String extensionName) {
    return getEventsDispatched('Flutter.ServiceExtensionStateChanged')
      .where((Map<Object, Object?> event) => event['extension'] == extensionName);
  }

  Future<Object?> testExtension(String name, Map<String, String> arguments) async {
    expect(extensions, contains(name));
    // Encode and decode to JSON to match behavior using a real service
    // extension where only JSON is allowed.
    return (json.decode(json.encode(await extensions[name]!(arguments))) as Map<String, dynamic>)['result'];
  }

  Future<String> testBoolExtension(String name, Map<String, String> arguments) async {
    expect(extensions, contains(name));
    // Encode and decode to JSON to match behavior using a real service
    // extension where only JSON is allowed.
    return (json.decode(json.encode(await extensions[name]!(arguments))) as Map<String, dynamic>)['enabled'] as String;
  }

  int rebuildCount = 0;

  @override
  Future<void> forceRebuild() async {
    rebuildCount++;
    final WidgetsBinding binding = WidgetsBinding.instance;

    if (binding.renderViewElement != null) {
      binding.buildOwner!.reassemble(binding.renderViewElement!, null);
    }
  }

  @override
  void resetAllState() {
    super.resetAllState();
    eventsDispatched.clear();
    rebuildCount = 0;
  }
}
