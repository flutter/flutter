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

typedef ScenarioFactory = Scenario Function();

int _viewId = 0;

Map<String, ScenarioFactory> _scenarios = <String, ScenarioFactory>{
  'animated_color_square': () => AnimatedColorSquareScenario(window),
  'locale_initialization': () => LocaleInitialization(window),
  'platform_view': () => PlatformViewScenario(window, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_no_overlay_intersection': () => PlatformViewNoOverlayIntersectionScenario(window, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_partial_intersection': () => PlatformViewPartialIntersectionScenario(window, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_two_intersecting_overlays': () => PlatformViewTwoIntersectingOverlaysScenario(window, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_one_overlay_two_intersecting_overlays': () => PlatformViewOneOverlayTwoIntersectingOverlaysScenario(window, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_multiple_without_overlays': () => MultiPlatformViewWithoutOverlaysScenario(window, 'Hello from Scenarios (Platform View)', firstId: _viewId++, secondId: _viewId++),
  'platform_view_max_overlays': () => PlatformViewMaxOverlaysScenario(window, 'Hello from Scenarios (Platform View)', id: _viewId++),
  'platform_view_cliprect': () => PlatformViewClipRectScenario(window, 'PlatformViewClipRect', id: _viewId++),
  'platform_view_cliprrect': () => PlatformViewClipRRectScenario(window, 'PlatformViewClipRRect', id: _viewId++),
  'platform_view_clippath': () => PlatformViewClipPathScenario(window, 'PlatformViewClipPath', id: _viewId++),
  'platform_view_transform': () => PlatformViewTransformScenario(window, 'PlatformViewTransform', id: _viewId++),
  'platform_view_opacity': () => PlatformViewOpacityScenario(window, 'PlatformViewOpacity', id: _viewId++),
  'platform_view_multiple': () => MultiPlatformViewScenario(window, firstId: 6, secondId: _viewId++),
  'platform_view_multiple_background_foreground': () => MultiPlatformViewBackgroundForegroundScenario(window, firstId: _viewId++, secondId: _viewId++),
  'poppable_screen': () => PoppableScreenScenario(window),
  'platform_view_rotate': () => PlatformViewScenario(window, 'Rotate Platform View', id: _viewId++),
  'platform_view_gesture_reject_eager': () => PlatformViewForTouchIOSScenario(window, 'platform view touch', id: _viewId++, accept: false),
  'platform_view_gesture_accept': () => PlatformViewForTouchIOSScenario(window, 'platform view touch', id: _viewId++, accept: true),
  'platform_view_gesture_reject_after_touches_ended': () => PlatformViewForTouchIOSScenario(window, 'platform view touch', id: _viewId++, accept: false, rejectUntilTouchesEnded: true),
  'tap_status_bar': () => TouchesScenario(window),
  'text_semantics_focus': () => SendTextFocusScemantics(window),
  'initial_route_reply': () => InitialRouteReply(window),
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
