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

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

/// The app foreground/background state.
enum AppState {
  /// App is backgrounded.
  background,

  /// App is foregrounded.
  foreground
}

/// Notifies changes in app foreground/background.
///
/// Subscribe to [appStateStream] to get notified of changes in [AppState].
/// Use this when implementing app open ads instead of [WidgetsBindingObserver],
/// because the latter also notifies when the state of the Flutter
/// activity/view controller changes. This makes an interstitial taking control
/// of the screen indistinguishable from the app background/foreground.
class AppStateEventNotifier {
  static const _eventChannelName =
      'plugins.flutter.io/google_mobile_ads/app_state_event';
  static const _methodChannelName =
      'plugins.flutter.io/google_mobile_ads/app_state_method';
  static const EventChannel _eventChannel = EventChannel(_eventChannelName);
  static const MethodChannel _methodChannel = MethodChannel(_methodChannelName);

  /// Subscribe to this to get notified of changes in [AppState].
  ///
  /// Call [startListening] before subscribing to this stream to
  /// start listening to background/foreground events on the platform side.
  static Stream<AppState> get appStateStream =>
      _eventChannel.receiveBroadcastStream().map((event) =>
          event == 'foreground' ? AppState.foreground : AppState.background);

  /// Start listening to background/foreground events.
  static Future<void> startListening() async {
    return _methodChannel.invokeMethod('start');
  }

  /// Stop listening to background/foreground events.
  static Future<void> stopListening() async {
    return _methodChannel.invokeMethod('stop');
  }
}
