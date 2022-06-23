// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:scenario_app/src/texture.dart';

import 'animated_color_square.dart';
import 'bogus_font_text.dart';
import 'initial_route_reply.dart';
import 'locale_initialization.dart';
import 'platform_view.dart';
import 'poppable_screen.dart';
import 'scenario.dart';
import 'touches_scenario.dart';

typedef ScenarioFactory = Scenario Function(); // ignore: public_member_api_docs

int _viewId = 0;

Map<String, ScenarioFactory> _scenarios = <String, ScenarioFactory>{
  'animated_color_square': () => AnimatedColorSquareScenario(PlatformDispatcher.instance),
  'locale_initialization': () => LocaleInitialization(PlatformDispatcher.instance),
  'platform_view': () => PlatformViewScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_no_overlay_intersection': () => PlatformViewNoOverlayIntersectionScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_larger_than_display_size': () => PlatformViewLargerThanDisplaySize(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_partial_intersection': () => PlatformViewPartialIntersectionScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_two_intersecting_overlays': () => PlatformViewTwoIntersectingOverlaysScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_one_overlay_two_intersecting_overlays': () => PlatformViewOneOverlayTwoIntersectingOverlaysScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_multiple_without_overlays': () => MultiPlatformViewWithoutOverlaysScenario(PlatformDispatcher.instance, firstId: _viewId++, secondId: _viewId++),
  'platform_view_max_overlays': () => PlatformViewMaxOverlaysScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_cliprect': () => PlatformViewClipRectScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_cliprrect': () => PlatformViewClipRRectScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_clippath': () => PlatformViewClipPathScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_transform': () => PlatformViewTransformScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_opacity': () => PlatformViewOpacityScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_with_other_backdrop_filter': () => PlatformViewWithOtherBackDropFilter(PlatformDispatcher.instance, id: _viewId++),
  'two_platform_views_with_other_backdrop_filter': () => TwoPlatformViewsWithOtherBackDropFilter(PlatformDispatcher.instance, firstId: _viewId++, secondId: _viewId++),
  'platform_view_multiple': () => MultiPlatformViewScenario(PlatformDispatcher.instance, firstId: _viewId++, secondId: _viewId++),
  'platform_view_multiple_background_foreground': () => MultiPlatformViewBackgroundForegroundScenario(PlatformDispatcher.instance, firstId: _viewId++, secondId: _viewId++),
  'non_full_screen_flutter_view_platform_view': () => NonFullScreenFlutterViewPlatformViewScenario(PlatformDispatcher.instance, id: _viewId++),
  'poppable_screen': () => PoppableScreenScenario(PlatformDispatcher.instance),
  'platform_view_rotate': () => PlatformViewScenario(PlatformDispatcher.instance, id: _viewId++),
  'platform_view_gesture_reject_eager': () => PlatformViewForTouchIOSScenario(PlatformDispatcher.instance,  id: _viewId++, accept: false),
  'platform_view_gesture_accept': () => PlatformViewForTouchIOSScenario(PlatformDispatcher.instance, id: _viewId++, accept: true),
  'platform_view_gesture_reject_after_touches_ended': () => PlatformViewForTouchIOSScenario(PlatformDispatcher.instance, id: _viewId++, accept: false, rejectUntilTouchesEnded: true),
  'platform_view_scrolling_under_widget':()=>PlatformViewScrollingUnderWidget(PlatformDispatcher.instance, firstPlatformViewId: _viewId++, lastPlatformViewId: _viewId+=16),
  'tap_status_bar': () => TouchesScenario(PlatformDispatcher.instance),
  'initial_route_reply': () => InitialRouteReply(PlatformDispatcher.instance),
  'platform_view_with_continuous_texture': () => PlatformViewWithContinuousTexture(PlatformDispatcher.instance, id: _viewId++),
  'bogus_font_text': () => BogusFontText(PlatformDispatcher.instance),
  'spawn_engine_works' : () => BogusFontText(PlatformDispatcher.instance),
  'pointer_events': () => TouchesScenario(PlatformDispatcher.instance),
  'display_texture': () => DisplayTexture(PlatformDispatcher.instance),
};

Map<String, dynamic> _currentScenarioParams = <String, dynamic>{};

Scenario? _currentScenarioInstance;

/// Loads an scenario.
/// The map must contain a `name` entry, which equals to the name of the scenario.
void loadScenario(Map<String, dynamic> scenario) {
  final String scenarioName = scenario['name'] as String;
  assert(_scenarios[scenarioName] != null);
  _currentScenarioParams = scenario;

  if (_currentScenarioInstance != null) {
    _currentScenarioInstance!.unmount();
  }

  _currentScenarioInstance = _scenarios[scenario['name']]!();
  window.scheduleFrame();
  print('Loading scenario $scenarioName');
}

/// Gets the loaded [Scenario].
Scenario? get currentScenario {
  return _currentScenarioInstance;
}

/// Gets the parameters passed to the app over the channel.
Map<String, dynamic> get scenarioParams {
  return Map<String, dynamic>.from(_currentScenarioParams);
}
