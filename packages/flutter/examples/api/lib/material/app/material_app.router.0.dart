// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Flutter code sample for [MaterialApp.router].

void main() => runApp(const MaterialAppRouterExampleApp());

class MaterialAppRouterExampleApp extends StatefulWidget {
  const MaterialAppRouterExampleApp({super.key});

  @override
  State<MaterialAppRouterExampleApp> createState() =>
      _MaterialAppRouterExampleAppState();
}

class _MaterialAppRouterExampleAppState
    extends State<MaterialAppRouterExampleApp> {
  final MaterialAppRouteInformationParser _routeInformationParser =
      MaterialAppRouteInformationParser();
  final MaterialAppRouterDelegate _routerDelegate = MaterialAppRouterDelegate();

  @override
  void dispose() {
    _routerDelegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Router example',
      routeInformationParser: _routeInformationParser,
      routerDelegate: _routerDelegate,
    );
  }
}

/// The two locations this sample can show.
enum MaterialAppRouterPath { home, details }

/// Parses a URL path into a [MaterialAppRouterPath].
class MaterialAppRouteInformationParser
    extends RouteInformationParser<MaterialAppRouterPath> {
  @override
  Future<MaterialAppRouterPath> parseRouteInformation(
    RouteInformation routeInformation,
  ) {
    final MaterialAppRouterPath path = switch (routeInformation.uri.path) {
      '/details' => MaterialAppRouterPath.details,
      _ => MaterialAppRouterPath.home,
    };
    return Future<MaterialAppRouterPath>.value(path);
  }

  @override
  RouteInformation? restoreRouteInformation(
    MaterialAppRouterPath configuration,
  ) {
    return RouteInformation(
      uri: Uri.parse(switch (configuration) {
        MaterialAppRouterPath.home => '/',
        MaterialAppRouterPath.details => '/details',
      }),
    );
  }
}

/// Builds a [Navigator] from the current [MaterialAppRouterPath].
class MaterialAppRouterDelegate extends RouterDelegate<MaterialAppRouterPath>
    with
        ChangeNotifier,
        PopNavigatorRouterDelegateMixin<MaterialAppRouterPath> {
  @override
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MaterialAppRouterPath _path = MaterialAppRouterPath.home;

  /// Opens the details page.
  void showDetails() {
    if (_path == MaterialAppRouterPath.details) {
      return;
    }
    _path = MaterialAppRouterPath.details;
    notifyListeners();
  }

  @override
  MaterialAppRouterPath get currentConfiguration => _path;

  @override
  Future<void> setNewRoutePath(MaterialAppRouterPath configuration) {
    _path = configuration;
    return Future<void>.value();
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: <Page<void>>[
        MaterialPage<void>(
          key: const ValueKey<String>('home'),
          child: _HomePage(onViewDetails: showDetails),
        ),
        if (_path == MaterialAppRouterPath.details)
          const MaterialPage<void>(
            key: ValueKey<String>('details'),
            child: _DetailsPage(),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        if (_path == MaterialAppRouterPath.home) {
          return;
        }
        _path = MaterialAppRouterPath.home;
        notifyListeners();
      },
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.onViewDetails});

  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(
        child: FilledButton(
          onPressed: onViewDetails,
          child: const Text('View details'),
        ),
      ),
    );
  }
}

class _DetailsPage extends StatelessWidget {
  const _DetailsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: const Center(child: Text('Details page')),
    );
  }
}
