// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This sample demonstrates nested navigation in a bottom navigation bar.

import 'package:flutter/material.dart';

// There are three possible tabs.
enum _Tab {
  home,
  one,
  two,
}

// Each tab has two possible pages.
enum _TabPage {
  home,
  one,
}

typedef _TabPageCallback = void Function(List<_TabPage> pages);

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/home',
      routes: <String, WidgetBuilder>{
        '/home': (BuildContext context) => const _BottomNavPage(
        ),
      },
    );
  }
}

class _BottomNavPage extends StatefulWidget {
  const _BottomNavPage();

  @override
  State<_BottomNavPage> createState() => _BottomNavPageState();
}

class _BottomNavPageState extends State<_BottomNavPage> {
  _Tab _tab = _Tab.home;

  final GlobalKey _tabHomeKey = GlobalKey();
  final GlobalKey _tabOneKey = GlobalKey();
  final GlobalKey _tabTwoKey = GlobalKey();

  List<_TabPage> _tabHomePages = <_TabPage>[_TabPage.home];
  List<_TabPage> _tabOnePages = <_TabPage>[_TabPage.home];
  List<_TabPage> _tabTwoPages = <_TabPage>[_TabPage.home];

  BottomNavigationBarItem _itemForPage(_Tab page) {
    switch (page) {
      case _Tab.home:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        );
      case _Tab.one:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.one_k),
          label: 'One',
        );
      case _Tab.two:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.two_k),
          label: 'Two',
        );
    }
  }

  Widget _getPage(_Tab page) {
    switch (page) {
      case _Tab.home:
        return _BottomNavTab(
          key: _tabHomeKey,
          title: 'Home',
          color: Colors.brown,
          pages: _tabHomePages,
          onChangedPages: (List<_TabPage> pages) {
            setState(() {
              _tabHomePages = pages;
            });
          },
        );
      case _Tab.one:
        return _BottomNavTab(
          key: _tabOneKey,
          title: 'One',
          color: Colors.deepPurple,
          pages: _tabOnePages,
          onChangedPages: (List<_TabPage> pages) {
            setState(() {
              _tabOnePages = pages;
            });
          },
        );
      case _Tab.two:
        return _BottomNavTab(
          key: _tabTwoKey,
          title: 'Two',
          color: Colors.blueGrey,
          pages: _tabTwoPages,
          onChangedPages: (List<_TabPage> pages) {
            setState(() {
              _tabTwoPages = pages;
            });
          },
        );
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _tab = _Tab.values.elementAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _getPage(_tab),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _Tab.values.map(_itemForPage).toList(),
        currentIndex: _Tab.values.indexOf(_tab),
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class _BottomNavTab extends StatelessWidget {
  const _BottomNavTab({
    super.key,
    required this.color,
    required this.onChangedPages,
    required this.pages,
    required this.title,
  });

  final Color color;
  final _TabPageCallback onChangedPages;
  final List<_TabPage> pages;
  final String title;

  bool get _popEnabled => pages.length <= 1;

  @override
  Widget build(BuildContext context) {
    return CanPopScope(
      popEnabled: _popEnabled,
      onPop: () {
        if (_popEnabled) {
          return;
        }
        onChangedPages(<_TabPage>[
          ...pages,
        ]..removeLast());
      },
      child: Navigator(
        onPopPage: (Route<void> route, void result) {
          if (!route.didPop(null)) {
            return false;
          }
          onChangedPages(<_TabPage>[
            ...pages,
          ]..removeLast());
          return true;
        },
        pages: pages.map((_TabPage page) {
          switch (page) {
            case _TabPage.home:
              return MaterialPage(
                child: _LinksPage(
                  title: 'Bottom nav - tab $title - route $page',
                  backgroundColor: color,
                  buttons: <Widget>[
                    TextButton(
                      onPressed: () {
                        onChangedPages(<_TabPage>[
                          ...pages,
                          _TabPage.one,
                        ]);
                      },
                      child: const Text('Go to another route in this nested Navigator'),
                    ),
                  ],
                ),
              );
            case _TabPage.one:
              return MaterialPage(
                child: _LinksPage(
                  backgroundColor: color,
                  title: 'Bottom nav - tab $title - route $page',
                  buttons: <Widget>[
                    TextButton(
                      onPressed: () {
                        onChangedPages(<_TabPage>[
                          ...pages,
                        ]..removeLast());
                      },
                      child: const Text('Go back'),
                    ),
                  ],
                ),
              );
          }
        }).toList(),
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
          ],
        ),
      ),
    );
  }
}
