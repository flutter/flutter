// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'route.dart';

/// A single tab with its own [Navigator] state and history.
///
/// A typical tab used as the content of each tab in a [CupertinoTabScaffold]
/// where multiple tabs with parallel navigation states and history can
/// co-exist.
///
/// [CupertinoTab] configures the top-level [Navigator] to search for routes
/// in the following order:
///
///  1. For the `/` route, the [home] property, if non-null, is used.
///
///  2. Otherwise, the [routes] table is used, if it has an entry for the route,
///     including `/` if [home] is not specified.
///
///  3. Otherwise, [onGenerateRoute] is called, if provided. It should return a
///     non-null value for any _valid_ route not handled by [home] and [routes].
///
///  4. Finally if all else fails [onUnknownRoute] is called.
///
/// These navigation properties is not shared with any sibling [CupertinoTab]
/// nor any ancestor or descendent [Navigator] instances.
///
/// Be sure to acquire a [BuildContext] that belongs to the [CupertinoTab] (such
/// as by using a [Builder]) to ensure that [Navigator.of] calls uses this
/// [CupertinoTab]'s [Navigator] rather than that of its parent.
///
/// See also:
///
///  * [CupertinoTabScaffold] a typical host that supports switching between tabs.
///  * [CupertinoPageRoute] a typical modal page route pushed onto the [CupertinoTab]'s
///    [Navigator].
class CupertinoTab extends StatelessWidget {
  const CupertinoTab({
    Key key,
    this.home,
    this.routes,
    this.onGenerateRoute,
    this.onUnknownRoute,
    this.navigatorObservers,
  }) : super(key: key);

  /// The widget for the default route of the tab ([Navigator.defaultRouteName],
  /// which is `/`).
  ///
  /// If [home] is specified, then [routes] must not include an entry for `/`,
  /// as [home] takes its place.
  final Widget home;

  /// This tab's routing table.
  ///
  /// When a named route is pushed with [Navigator.pushNamed] inside this tab,
  /// the route name is looked up in this map. If the name is present,
  /// the associated [WidgetBuilder] is used to construct a [CupertinoPageRoute]
  /// that performs an appropriate transition to the new route.
  ///
  /// If the tab only has one page, then you can specify it using [home] instead.
  ///
  /// When pushing named routes from [home] via [Navigator.of], be sure to use
  /// the [BuildContext] of this tab rather than this tab's ancestors by using
  /// a [Builder] widget.
  ///
  /// If [home] is specified, then it implies an entry in this table for the
  /// [Navigator.defaultRouteName] route (`/`), and it is an error to
  /// redundantly provide such a route in the [routes] table.
  ///
  /// If a route is requested that is not specified in this table (or by
  /// [home]), then the [onGenerateRoute] callback is called to build the page
  /// instead.
  ///
  /// This routing table is not shared with any routing tables of ancestor or
  /// descendent [Navigator]s.
  final Map<String, WidgetBuilder> routes;

  /// The route generator callback used when the tab is navigated to a named route.
  ///
  /// This is used if [routes] does not contain the requested route.
  final RouteFactory onGenerateRoute;

  /// Called when [onGenerateRoute] also fails to generate a route.
  ///
  /// This callback is typically used for error handling. For example, this
  /// callback might always generate a "not found" page that describes the route
  /// that wasn't found.
  ///
  /// The default implementation pushes a route that displays an ugly error
  /// message.
  final RouteFactory onUnknownRoute;

  /// The list of observers for the [Navigator] created in this tab.
  ///
  /// This list of observers is not shared with ancestor or descendent [Navigator]s.
  final List<NavigatorObserver> navigatorObservers;

  @override
  Widget build(BuildContext context) {
    return new Navigator(
      onGenerateRoute: _onGenerateRoute,
      onUnknownRoute: _onUnknownRoute,
      observers: navigatorObservers ?? const <NavigatorObserver>[], // Can't be null.
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    final String name = settings.name;
    WidgetBuilder builder;
    if (name == Navigator.defaultRouteName && home != null)
      builder = (BuildContext context) => home;
    else
      builder = routes[name];
    if (builder != null) {
      return new CupertinoPageRoute<dynamic>(
        builder: builder,
        settings: settings,
      );
    }
    if (onGenerateRoute != null)
      return onGenerateRoute(settings);
    return null;
  }

  Route<dynamic> _onUnknownRoute(RouteSettings settings) {
    assert(() {
      if (onUnknownRoute == null) {
        throw new FlutterError(
          'Could not find a generator for route $settings in the $runtimeType.\n'
          'Generators for routes are searched for in the following order:\n'
          ' 1. For the "/" route, the "home" property, if non-null, is used.\n'
          ' 2. Otherwise, the "routes" table is used, if it has an entry for '
          'the route.\n'
          ' 3. Otherwise, onGenerateRoute is called. It should return a '
          'non-null value for any valid route not handled by "home" and "routes".\n'
          ' 4. Finally if all else fails onUnknownRoute is called.\n'
          'Unfortunately, onUnknownRoute was not set.'
        );
      }
      return true;
    });
    final Route<dynamic> result = onUnknownRoute(settings);
    assert(() {
      if (result == null) {
        throw new FlutterError(
          'The onUnknownRoute callback returned null.\n'
          'When the $runtimeType requested the route $settings from its '
          'onUnknownRoute callback, the callback returned null. Such callbacks '
          'must never return null.'
        );
      }
      return true;
    });
    return result;
  }
}