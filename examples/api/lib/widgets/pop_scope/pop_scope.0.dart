// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This sample demonstrates nested navigation in a bottom navigation bar.

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

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

void main() => runApp(const PopScopeApp());

class PopScopeApp extends StatelessWidget {
  const PopScopeApp({super.key});

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
          label: 'Go to Home',
        );
      case _Tab.one:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.one_k),
          label: 'Go to One',
        );
      case _Tab.two:
        return const BottomNavigationBarItem(
          icon: Icon(Icons.two_k),
          label: 'Go to Two',
        );
    }
  }

  Widget _getPage(_Tab page) {
    switch (page) {
      case _Tab.home:
        return _BottomNavTab(
          key: _tabHomeKey,
          title: 'Home Tab',
          color: Colors.grey,
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
          title: 'Tab One',
          color: Colors.amber,
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
          title: 'Tab Two',
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

class _BottomNavTab extends StatefulWidget {
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

  @override
  State<_BottomNavTab> createState() => _BottomNavTabState();
}

class _BottomNavTabState extends State<_BottomNavTab> {
  bool _navigatorCanHandlePop = false;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool get _canPop => widget.pages.length <= 1 && !_navigatorCanHandlePop;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          return;
        }

        // The Navigator may be able to pop if a dialog is shown, for example.
        final NavigatorState navigatorState = _navigatorKey.currentState!;
        if (navigatorState.canPop()) {
          navigatorState.pop();
          return;
        }

        assert(widget.pages.isNotEmpty);
        widget.onChangedPages(<_TabPage>[
          ...widget.pages,
        ]..removeLast());
      },
      child: NotificationListener<NavigationNotification>(
        onNotification: (NavigationNotification notification) {
          if (mounted) {
            SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
              setState(() {
                _navigatorCanHandlePop = notification.canHandlePop;
              });
            });
          }
          return false;
        },
        child: Navigator(
          key: _navigatorKey,
          onPopPage: (Route<void> route, void result) {
            if (!route.didPop(null)) {
              return false;
            }
            widget.onChangedPages(<_TabPage>[
              ...widget.pages,
            ]..removeLast());
            return true;
          },
          pages: widget.pages.map((_TabPage page) {
            switch (page) {
              case _TabPage.home:
                return MaterialPage<void>(
                  child: _LinksPage(
                    title: 'Bottom nav - tab ${widget.title} - route $page',
                    backgroundColor: widget.color,
                    buttons: <Widget>[
                      TextButton(
                        onPressed: () {
                          widget.onChangedPages(<_TabPage>[
                            ...widget.pages,
                            _TabPage.one,
                          ]);
                        },
                        child: const Text('Go to another route in this nested Navigator'),
                      ),
                    ],
                  ),
                );
              case _TabPage.one:
                return MaterialPage<void>(
                  child: _LinksPage(
                    backgroundColor: widget.color,
                    title: 'Bottom nav - tab ${widget.title} - route $page',
                    buttons: <Widget>[
                      TextButton(
                        onPressed: () {
                          widget.onChangedPages(<_TabPage>[
                            ...widget.pages,
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
            TextButton(
              onPressed: () {
                showDialog<void>(
                  // This causes the nested Navigator to be used to handle the
                  // dialog's route.
                  useRootNavigator: false,
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Basic dialog title'),
                      content: const Text(
                        'A dialog is a type of modal window that\n'
                        'appears in front of app content to\n'
                        'provide critical information, or prompt\n'
                        'for a decision to be made.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          style: TextButton.styleFrom(
                            textStyle: Theme.of(context).textTheme.labelLarge,
                          ),
                          child: const Text('Close'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('Show dialog'),
            ),
          ],
        ),
      ),
    );
  }
}
