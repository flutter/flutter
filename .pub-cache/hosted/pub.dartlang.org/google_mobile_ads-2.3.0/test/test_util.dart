// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/src/ad_instance_manager.dart';

/// Shared test functions.
class TestUtil {
  /// Mocks sending an ad event to [instanceManager].
  ///
  /// Creates an `onAdEvent` [MethodCall] with [adId], [eventName] and
  /// [additionalArgs], encodes it into [ByteData] and sends it as a platform
  /// message to [instanceManager].
  static Future<void> sendAdEvent(
      int adId, String eventName, AdInstanceManager instanceManager,
      [Map<String, dynamic>? additionalArgs]) async {
    Map<String, dynamic> args = {
      'adId': adId,
      'eventName': eventName,
    };
    additionalArgs?.entries
        .forEach((element) => args[element.key] = element.value);
    final MethodCall methodCall = MethodCall('onAdEvent', args);
    final ByteData data =
        instanceManager.channel.codec.encodeMethodCall(methodCall);

    return instanceManager.channel.binaryMessenger.handlePlatformMessage(
      'plugins.flutter.io/google_mobile_ads',
      data,
      (ByteData? data) {},
    );
  }
}
