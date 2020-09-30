// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../stock_home.dart';
import '../stock_settings.dart';
import '../stock_symbol_viewer.dart';
import 'router_state.dart';

const String _kSettingsPageLocation = '/settings';
const String _kStockPageLocation = '/stock';
const String _kHomePageLocation = '/';

class _RouterConfiguration {
  _RouterConfiguration(this.path, this.browserState);
  StockRoutePath path;
  Map<String, dynamic> browserState;
}

class StockRouteInformationParser extends RouteInformationParser<_RouterConfiguration> {
  @override
  Future<_RouterConfiguration> parseRouteInformation(RouteInformation routeInformation) {
    final Uri url = Uri.parse(routeInformation.location);
    Map<String, dynamic> state = routeInformation.state as Map<String, dynamic>;
    state ??= <String, dynamic>{};
    if (url.path == _kSettingsPageLocation) {
      return SynchronousFuture<_RouterConfiguration>(
        _RouterConfiguration(const StockSettingsPath(), state)
      );
    }

    if (url.path == _kStockPageLocation) {
      final String symbol = url.queryParameters['symbol'];
      if (symbol != null && symbol.isNotEmpty)
        return SynchronousFuture<_RouterConfiguration>(
          _RouterConfiguration(StockSymbolPath(symbol), state)
        );
    }
    return SynchronousFuture<_RouterConfiguration>(
      _RouterConfiguration(const StockHomePath(), state)
    );
  }

  @override
  RouteInformation restoreRouteInformation(_RouterConfiguration configuration) {
    if (configuration.path is StockSettingsPath)
      return RouteInformation(location: _kSettingsPageLocation, state: configuration.browserState);
    if (configuration.path is StockHomePath)
      return RouteInformation(location: _kHomePageLocation, state: configuration.browserState);
    if (configuration.path is StockSymbolPath) {
      final StockSymbolPath path = configuration.path as StockSymbolPath;
      return RouteInformation(
        location: '$_kStockPageLocation?symbol=${const HtmlEscape().convert(path.symbol)}',
        state: configuration.browserState,
      );
    }
    assert(false);
    return null;
  }
}

class StockRouterDelegate extends RouterDelegate<_RouterConfiguration> with ChangeNotifier, PopNavigatorRouterDelegateMixin<_RouterConfiguration>{
  StockRouterDelegate(
    this.routerState
  ) : navigatorKey = GlobalObjectKey<NavigatorState>(routerState) {
    routerState.addListener(notifyListeners);
  }

  final RouterState routerState;

  @override
  final GlobalObjectKey<NavigatorState> navigatorKey;

  @override
  _RouterConfiguration get currentConfiguration {
    return _RouterConfiguration(routerState.routePath, routerState.browserState);
  }

  @override
  Future<void> setNewRoutePath(_RouterConfiguration configuration) {
    assert(configuration != null);
    routerState.routePath = configuration.path;
    routerState.browserState = configuration.browserState;
    return SynchronousFuture<void>(null);
  }

  bool _handlePopPage(Route<dynamic> route, dynamic result) {
    // _handlePopPage will not be called on the home page because the
    // PopNavigatorRouterDelegateMixin will bubble up the pop to the
    // SystemNavigator if there is only one route in the navigator.
    assert(route.willHandlePopInternally ||
           routerState.routePath is StockSettingsPath ||
           routerState.routePath is StockSymbolPath);

    final bool success = route.didPop(result);
    if (success) {
      routerState.routePath = const StockHomePath();
    }
    return success;
  }

  @override
  void dispose() {
    routerState.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    assert(routerState.routePath != null);
    return RouterStateScope(
      routerState: routerState,
      child: Navigator(
        key: navigatorKey,
        pages: <Page<void>>[
          const StockHomePage(),
          if (routerState.routePath is StockSettingsPath)
            const StockSettingsPage(),
          if (routerState.routePath is StockSymbolPath)
            StockPage((routerState.routePath as StockSymbolPath).symbol),
        ],
        onPopPage: _handlePopPage,
      ),
    );
  }
}
