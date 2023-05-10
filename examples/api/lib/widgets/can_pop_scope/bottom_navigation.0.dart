// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This sample demonstrates nested navigation in a bottom navigation bar.

import 'package:flutter/material.dart';

enum _Page {
  home,
  one,
  two,
}

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final GlobalKey key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    /*
    const _BottomNavPage page = _BottomNavPage(
      page: _Page.home,
    );
    */
    // TODO(justinmc): Navigating between tabs should push a route, but it
    // shouldn't like place a whole new visible page on the screen.
    return MaterialApp(
      initialRoute: '/home',
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => _BottomNavPage(
          key: key,
          page: _Page.home,
        ),
        '/one': (BuildContext context) => _BottomNavPage(
          key: key,
          page: _Page.one,
        ),
        '/two': (BuildContext context) => _BottomNavPage(
          key: key,
          page: _Page.two,
        ),
      },
    );
  }
}

class _BottomNavPage extends StatefulWidget {
  const _BottomNavPage({
    super.key,
    required this.page,
  });

  final _Page page;

  @override
  State<_BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<_BottomNavPage> {
  //_Page _page = _Page.home;

  BottomNavigationBarItem _itemForPage(_Page page) {
    switch (page) {
      case _Page.home:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        );
      case _Page.one:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.one_k),
          label: 'One',
        );
      case _Page.two:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.two_k),
          label: 'Two',
        );
    }
  }

  Widget _getPage(_Page page) {
    switch (page) {
      case _Page.home:
        return const _BottomNavTabHome(
        );
      case _Page.one:
        return const _BottomNavTabOne(
        );
      case _Page.two:
        return const _BottomNavTabTwo(
        );
    }
  }

  void _onItemTapped(int index) {
    Navigator.of(context).pushNamed('/home/${_Page.values.elementAt(index).toString().substring('_Page.'.length)}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _getPage(widget.page),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _Page.values.map(_itemForPage).toList(),
        currentIndex: _Page.values.indexOf(widget.page),
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class _BottomNavTabHome extends StatefulWidget {
  const _BottomNavTabHome();

  @override
  State<_BottomNavTabHome> createState() => _BottomNavTabHomeState();
}

class _BottomNavTabHomeState extends State<_BottomNavTabHome> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();
  bool popEnabled = true;

  @override
  Widget build(BuildContext context) {
    return CanPopScope(
      popEnabled: popEnabled,
      onPop: () {
        if (popEnabled) {
          return;
        }
        _nestedNavigatorKey.currentState!.pop();
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (NavigationNotification notification) {
          final bool nextPopEnabled = !notification.canPop;
          if (nextPopEnabled != popEnabled) {
            setState(() {
              popEnabled = nextPopEnabled;
            });
          }
          return false;
        },
        child: Navigator(
          key: _nestedNavigatorKey,
          initialRoute: 'original',
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case 'original':
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    return _LinksPage(
                      title: 'Bottom nav - tab home - home route',
                      backgroundColor: Colors.limeAccent,
                      buttons: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('original/one');
                          },
                          child: const Text('Go to another route in this nested Navigator'),
                        ),
                      ],
                    );
                  },
                );
              case 'original/one':
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    return _LinksPage(
                      backgroundColor: Colors.limeAccent.withRed(255),
                      title: 'Bottom nav - tab home - page one',
                    );
                  },
                );
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
          },
        ),
      ),
    );
  }
}

class _BottomNavTabOne extends StatefulWidget {
  const _BottomNavTabOne();

  @override
  State<_BottomNavTabOne> createState() => _BottomNavTabOneState();
}

class _BottomNavTabOneState extends State<_BottomNavTabOne> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();
  bool popEnabled = true;

  @override
  Widget build(BuildContext context) {
    return CanPopScope(
      popEnabled: popEnabled,
      onPop: () {
        if (popEnabled) {
          return;
        }
        _nestedNavigatorKey.currentState!.pop();
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (NavigationNotification notification) {
          final bool nextPopEnabled = !notification.canPop;
          if (nextPopEnabled != popEnabled) {
            setState(() {
              popEnabled = nextPopEnabled;
            });
          }
          return false;
        },
        child: Navigator(
          key: _nestedNavigatorKey,
          initialRoute: 'tabone',
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case 'tabone':
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    return _LinksPage(
                      title: 'Bottom nav - tab one - home route',
                      backgroundColor: Colors.deepPurpleAccent,
                      buttons: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('tabone/one');
                          },
                          child: const Text('Go to another route in this nested Navigator'),
                        ),
                      ],
                    );
                  },
                );
              case 'tabone/one':
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    return _LinksPage(
                      backgroundColor: Colors.deepPurpleAccent.withRed(255),
                      title: 'Bottom nav - tab one - page one',
                    );
                  },
                );
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
          },
        ),
      ),
    );
  }
}

class _BottomNavTabTwo extends StatefulWidget {
  const _BottomNavTabTwo();

  @override
  State<_BottomNavTabTwo> createState() => _BottomNavTabTwoState();
}

class _BottomNavTabTwoState extends State<_BottomNavTabTwo> {
  final GlobalKey<NavigatorState> _nestedNavigatorKey = GlobalKey<NavigatorState>();
  bool popEnabled = true;

  @override
  Widget build(BuildContext context) {
    return CanPopScope(
      popEnabled: popEnabled,
      onPop: () {
        if (popEnabled) {
          return;
        }
        _nestedNavigatorKey.currentState!.pop();
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (NavigationNotification notification) {
          final bool nextPopEnabled = !notification.canPop;
          if (nextPopEnabled != popEnabled) {
            setState(() {
              popEnabled = nextPopEnabled;
            });
          }
          return false;
        },
        child: Navigator(
          key: _nestedNavigatorKey,
          initialRoute: 'again',
          onGenerateRoute: (RouteSettings settings) {
            switch (settings.name) {
              case 'again':
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    return _LinksPage(
                      title: 'Bottom nav - tab two - home route',
                      backgroundColor: Colors.lightBlue,
                      buttons: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('again/one');
                          },
                          child: const Text('Go to another route in this nested Navigator'),
                        ),
                      ],
                    );
                  },
                );
              case 'again/one':
                return MaterialPageRoute(
                  builder: (BuildContext context) {
                    return _LinksPage(
                      backgroundColor: Colors.lightBlue.withRed(255),
                      title: 'Bottom nav - tab two - page one',
                    );
                  },
                );
              default:
                throw Exception('Invalid route: ${settings.name}');
            }
          },
        ),
      ),
    );
  }
}

class _LinksPage extends StatelessWidget {
  const _LinksPage ({
    required this.backgroundColor,
    this.buttons = const <Widget>[],
    required this.title,
  });

  final Color backgroundColor;
  final List<Widget> buttons;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(title),
            ...buttons,
            if (Navigator.of(context).canPop())
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Go back'),
              ),
          ],
        ),
      ),
    );
  }
}

