// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Flutter code sample for [WidgetsApp.router] that shows how to set up nested
/// [Navigator]s.

void main() async {
  runApp(const WidgetsAppExample());
}

class WidgetsAppExample extends StatefulWidget {
  const WidgetsAppExample({
    super.key,
  });

  @override
  State<WidgetsAppExample> createState() => _WidgetsAppExampleState();
}

class _WidgetsAppExampleState extends State<WidgetsAppExample> {
  final _MyRouteInformationParser _routeInformationParser = _MyRouteInformationParser();
  final _MyRouterDelegate _routerDelegate = _MyRouterDelegate();

  @override
  Widget build(BuildContext context) {
    // TODO(justinmc): This should include state restoration.
    return WidgetsApp.router(
      color: Colors.red,
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        DefaultMaterialLocalizations.delegate,
      ],
      title: 'WidgetsApp.router Example',
      routeInformationParser: _routeInformationParser,
      routerDelegate: _routerDelegate,
    );
  }
}

class _MyRouteInformationParser extends RouteInformationParser<_MyPageConfiguration> {
  @override
  SynchronousFuture<_MyPageConfiguration> parseRouteInformation(RouteInformation routeInformation) {
    return SynchronousFuture<_MyPageConfiguration>(_MyPageConfiguration.values.firstWhere((_MyPageConfiguration pageConfiguration) {
      return pageConfiguration.uriString == routeInformation.uri.toString();
    },
      orElse: () => _MyPageConfiguration.unknown,
    ));
  }

  @override
  RouteInformation? restoreRouteInformation(_MyPageConfiguration configuration) {
    return RouteInformation(uri: configuration.uri);
  }
}

class _MyRouterDelegate extends RouterDelegate<_MyPageConfiguration> {
  final Set<VoidCallback> _listeners = <VoidCallback>{};
  final List<_MyPageConfiguration> _pages = <_MyPageConfiguration>[];
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _notifyListeners() {
    for (final VoidCallback listener in _listeners) {
      listener();
    }
  }

  // Why not just do `Navigator.of(context).pushNamed('/')`? That is handled by
  // Navigator.onGenerateRoute, which would interfere with this example's use of
  // Navigator.pages.
  void _onNavigateToHome() {
    _pages.clear();
    _pages.add(_MyPageConfiguration.home);
    _notifyListeners();
  }

  void _onNavigateToLeaf() {
    _pages.clear();
    _pages.add(_MyPageConfiguration.home);
    _pages.add(_MyPageConfiguration.leaf);
    _notifyListeners();
  }

  void _onNavigateToNested() {
    _pages.clear();
    _pages.add(_MyPageConfiguration.home);
    _pages.add(_MyPageConfiguration.leaf);
    _pages.add(_MyPageConfiguration.nestedNavigator);
    _notifyListeners();
  }

  @override
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  // Called for a system back event.
  @override
  Future<bool> popRoute() {
    // If you did this manually by removing from _pages, it wouldn't work in the
    // case where there's a nested Navigator.
    final NavigatorState navigator = _navigatorKey.currentState!;
    return navigator.maybePop();
  }

  @override
  Future<void> setNewRoutePath(_MyPageConfiguration configuration) {
    _pages.add(configuration);
    _notifyListeners();
    return SynchronousFuture<void>(null);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: _navigatorKey,
      restorationScopeId: 'root',
      onDidRemovePage: (Page<void> page) {
        final _MyPageConfiguration pageConfiguration = _MyPageConfiguration.fromName(page.name!);
        assert(!_pages.contains(pageConfiguration) || _pages.length > 1);
        _pages.remove(pageConfiguration);
      },
      pages: _pages.map((_MyPageConfiguration page) => switch (page) {
        _MyPageConfiguration.unknown => _MyUnknownPage(),
        _MyPageConfiguration.home => _MyHomePage(
          onNavigateToLeaf: _onNavigateToLeaf,
        ),
        _MyPageConfiguration.leaf => _MyLeafPage(
          onNavigateToHome: _onNavigateToHome,
          onNavigateToNested: _onNavigateToNested,
        ),
        _MyPageConfiguration.nestedNavigator => _MyNestedNavigatorPage(
          onNavigateToRootNavigator: _onNavigateToLeaf,
        ),
      }).toList(),
    );
  }
}

class _MyUnknownPage extends MaterialPage<dynamic> {
  _MyUnknownPage() : super(
    key: const ValueKey<String>('_MyUnknownPage'),
    restorationId: 'unknown-page',
    child: Scaffold(
      backgroundColor: const Color(0xff660000),
      appBar: AppBar(title: const Text('404')),
      body: const Center(
        child: Text('404'),
      ),
    ),
  );

  @override
  String get name => _MyPageConfiguration.unknown.name;
}

class _MyHomePage extends MaterialPage<dynamic> {
  _MyHomePage({
    required VoidCallback onNavigateToLeaf,
  }) : super(
    key: const ValueKey<String>('_MyHomePage'),
    restorationId: 'home-page',
    child: Scaffold(
      backgroundColor: const Color(0xffddddff),
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: onNavigateToLeaf,
          child: const Text('Go to leaf page'),
        ),
      ),
    ),
  );

  @override
  String get name => _MyPageConfiguration.home.name;
}

class _MyLeafPage extends MaterialPage<dynamic> {
  _MyLeafPage({
    required VoidCallback onNavigateToHome,
    required VoidCallback onNavigateToNested,
  }) : super(
    key: const ValueKey<String>('_MyLeafPage'),
    restorationId: 'leaf-page',
    child: Scaffold(
      backgroundColor: const Color(0xffaaaaff),
      appBar: AppBar(title: const Text('Leaf Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: onNavigateToNested,
              child: const Text('Go to nested Navigator page'),
            ),
            ElevatedButton(
              onPressed: onNavigateToHome,
              child: const Text('Go back to home'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  String get name => _MyPageConfiguration.leaf.name;
}

class _MyNestedNavigatorPage extends MaterialPage<dynamic> {
  _MyNestedNavigatorPage({
    required VoidCallback onNavigateToRootNavigator,
  }) : super(
    key: const ValueKey<String>('_MyNestedNavigatorPage'),
    restorationId: 'nested-navigator-page',
    child: _MyNestedNavigator(
      onNavigateToRootNavigator: onNavigateToRootNavigator,
    ),
  );

  @override
  String get name => _MyPageConfiguration.nestedNavigator.name;
}

class _MyNestedNavigator extends StatefulWidget {
  const _MyNestedNavigator({
    required this.onNavigateToRootNavigator,
  });

  final VoidCallback onNavigateToRootNavigator;

  @override
  State<_MyNestedNavigator> createState() => _MyNestedNavigatorState();
}

class _MyNestedNavigatorState extends State<_MyNestedNavigator> {
  final List<_MyNestedPageConfiguration> _pages = <_MyNestedPageConfiguration>[
    _MyNestedPageConfiguration.home,
  ];

  void _onNavigateToLeaf() {
    assert(!_pages.contains(_MyNestedPageConfiguration.leaf), 'Should not ever be two leaf pages on the navigation stack.');
    setState(() {
      _pages.add(_MyNestedPageConfiguration.leaf);
    });
  }

  void _onNavigateToHome() {
    setState(() {
      _pages.clear();
      _pages.add(_MyNestedPageConfiguration.home);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      restorationScopeId: 'nested',
      onDidRemovePage: (Page<void> page) {
        final _MyNestedPageConfiguration pageConfiguration = _MyNestedPageConfiguration.fromName(page.name!);
        assert(!_pages.contains(pageConfiguration) || _pages.length > 1);
        _pages.remove(pageConfiguration);
      },
      pages: _pages.map((_MyNestedPageConfiguration page) => switch (page) {
        _MyNestedPageConfiguration.unknown => _MyUnknownPage(),
        _MyNestedPageConfiguration.home => _MyNestedHomePage(
          onNavigateToLeaf: _onNavigateToLeaf,
          onNavigateToRootNavigator: widget.onNavigateToRootNavigator,
        ),
        _MyNestedPageConfiguration.leaf => _MyNestedLeafPage(
          onNavigateToHome: _onNavigateToHome,
        ),
      }).toList(),
  );
  }
}

class _MyNestedHomePage extends MaterialPage<dynamic> {
  _MyNestedHomePage({
    required VoidCallback onNavigateToLeaf,
    required VoidCallback onNavigateToRootNavigator,
  }) : super(
    key: const ValueKey<String>('_MyNestedHomePage'),
    restorationId: 'nested-home-page',
    child: Scaffold(
      backgroundColor: const Color(0xffddffdd),
      appBar: AppBar(title: const Text('Nested Home Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: onNavigateToLeaf,
              child: const Text('Go to nested leaf page'),
            ),
            ElevatedButton(
              onPressed: onNavigateToRootNavigator,
              child: const Text('Go back to root Navigator'),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  String get name => _MyPageConfiguration.home.name;
}

class _MyNestedLeafPage extends MaterialPage<dynamic> {
  _MyNestedLeafPage({
    required VoidCallback onNavigateToHome,
  }) : super(
    key: const ValueKey<String>('_MyNestedLeafPage'),
    restorationId: 'nested-leaf-page',
    child: Scaffold(
      backgroundColor: const Color(0xffaaffaa),
      appBar: AppBar(title: const Text('Nested Leaf Page')),
      body: Center(
        child: ElevatedButton(
          onPressed: onNavigateToHome,
          child: const Text('Go back to nested home'),
        ),
      ),
    ),
  );

  @override
  String get name => _MyPageConfiguration.leaf.name;
}

enum _MyPageConfiguration {
  home(uriString: '/'),
  leaf(uriString: '/leaf'),
  nestedNavigator(uriString: '/nested_navigator'),
  unknown(uriString: '/404');

  const _MyPageConfiguration({
    required this.uriString,
  });

  final String uriString;

  static _MyPageConfiguration fromName(String testName) {
    return values.firstWhere((_MyPageConfiguration page) => page.name == testName);
  }

  Uri get uri => Uri.parse(uriString);
}

enum _MyNestedPageConfiguration {
  home(uriString: '/'),
  leaf(uriString: '/leaf'),
  unknown(uriString: '/404');

  const _MyNestedPageConfiguration({
    required this.uriString,
  });

  final String uriString;

  static _MyNestedPageConfiguration fromName(String testName) {
    return values.firstWhere((_MyNestedPageConfiguration page) => page.name == testName);
  }

  Uri get uri => Uri.parse(uriString);
}
