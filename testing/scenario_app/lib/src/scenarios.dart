// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:ui';

import 'animated_color_square.dart';
import 'initial_route_reply.dart';
import 'locale_initialization.dart';
import 'platform_view.dart';
import 'poppable_screen.dart';
import 'scenario.dart';
import 'send_text_focus_semantics.dart';
import 'touches_scenario.dart';

typedef ScenarioFactory = Scenario Function(); // ignore: public_member_api_docs

int _viewId = 0;

Map<String, ScenarioFactory> _scenarios = <String, ScenarioFactory>{
  'animated_color_square': () => AnimatedColorSquareScenario(PlatformDispatcher.instance),
  'locale_initialization': () => LocaleInitialization(PlatformDispatcher.instance),
  'platform_view': () => PlatformViewScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_no_overlay_intersection': () => PlatformViewNoOverlayIntersectionScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_partial_intersection': () => PlatformViewPartialIntersectionScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_two_intersecting_overlays': () => PlatformViewTwoIntersectingOverlaysScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_one_overlay_two_intersecting_overlays': () => PlatformViewOneOverlayTwoIntersectingOverlaysScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_multiple_without_overlays': () => MultiPlatformViewWithoutOverlaysScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', firstId: _viewId++, secondId: _viewId++),
  'platform_view_max_overlays': () => PlatformViewMaxOverlaysScenario(PlatformDispatcher.instance, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_cliprect': () => PlatformViewClipRectScenario(PlatformDispatcher.instance, 'PlatformViewClipRect', id: _viewId++),
  'platform_view_cliprrect': () => PlatformViewClipRRectScenario(PlatformDispatcher.instance, 'PlatformViewClipRRect', id: _viewId++),
  'platform_view_clippath': () => PlatformViewClipPathScenario(PlatformDispatcher.instance, 'PlatformViewClipPath', id: _viewId++),
  'platform_view_transform': () => PlatformViewTransformScenario(PlatformDispatcher.instance, 'PlatformViewTransform', id: _viewId++),
  'platform_view_opacity': () => PlatformViewOpacityScenario(PlatformDispatcher.instance, 'PlatformViewOpacity', id: _viewId++),
  'platform_view_multiple': () => MultiPlatformViewScenario(PlatformDispatcher.instance, firstId: 6, secondId: _viewId++),
  'platform_view_multiple_background_foreground': () => MultiPlatformViewBackgroundForegroundScenario(PlatformDispatcher.instance, firstId: _viewId++, secondId: _viewId++),
  'poppable_screen': () => PoppableScreenScenario(PlatformDispatcher.instance),
  'platform_view_rotate': () => PlatformViewScenario(PlatformDispatcher.instance, 'Rotate Platform View', id: _viewId++),
  'platform_view_gesture_reject_eager': () => PlatformViewForTouchIOSScenario(PlatformDispatcher.instance, 'platform view touch', id: _viewId++, accept: false),
  'platform_view_gesture_accept': () => PlatformViewForTouchIOSScenario(PlatformDispatcher.instance, 'platform view touch', id: _viewId++, accept: true),
  'platform_view_gesture_reject_after_touches_ended': () => PlatformViewForTouchIOSScenario(PlatformDispatcher.instance, 'platform view touch', id: _viewId++, accept: false, rejectUntilTouchesEnded: true),
  'tap_status_bar': () => TouchesScenario(PlatformDispatcher.instance),
  'text_semantics_focus': () => SendTextFocusSemantics(PlatformDispatcher.instance),
  'initial_route_reply': () => InitialRouteReply(PlatformDispatcher.instance),
};

Map<String, dynamic> _currentScenarioParams = <String, dynamic>{};

Scenario _currentScenarioInstance;

/// Loads an scenario.
/// The map must contain a `name` entry, which equals to the name of the scenario.
void loadScenario(Map<String, dynamic> scenario) {
  final String scenarioName = scenario['name'] as String;
  assert(_scenarios[scenarioName] != null);
  _currentScenarioParams = scenario;

  if (_currentScenarioInstance != null) {
    _currentScenarioInstance.unmount();
  }

  _currentScenarioInstance = _scenarios[scenario['name']]();
  window.scheduleFrame();
  print('Loading scenario $scenarioName');
}

/// Gets the loaded [Scenario].
Scenario get currentScenario {
  return _currentScenarioInstance;
}

/// Gets the parameters passed to the app over the channel.
Map<String, dynamic> get scenarioParams {
  return Map<String, dynamic>.from(_currentScenarioParams);
}
