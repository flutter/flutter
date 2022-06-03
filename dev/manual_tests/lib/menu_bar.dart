// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum TestMenu {
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  mainMenu3('Menu 3'),
  mainMenu4('Menu 4'),
  subMenu1('Sub Menu 1'),
  subMenu2('Sub Menu 2'),
  subMenu3('Sub Menu 3'),
  subMenu4('Sub Menu 4'),
  subMenu5('Sub Menu 5'),
  subMenu6('Sub Menu 6'),
  subMenu7('Sub Menu 7'),
  subMenu8('Sub Menu 8'),
  subSubMenu1('Sub Sub Menu 1'),
  subSubMenu2('Sub Sub Menu 2'),
  subSubMenu3('Sub Sub Menu 3');

  const TestMenu(this.label);
  final String label;
}

void main() {
  debugFocusChanges = false;
  runApp(const MaterialApp(
    title: 'Menu Tester',
    home: Material(child: Home()),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MenuBarController _controller = MenuBarController();
  VisualDensity _density = VisualDensity.standard;
  TextDirection _textDirection = TextDirection.ltr;
  bool _enabled = true;
  bool _addItem = false;

  void _itemSelected(TestMenu item) {
    debugPrint('App: Selected item ${item.label}');
  }

  void _openItem(TestMenu item) {
    debugPrint('App: Opened item ${item.label}');
  }

  void _closeItem(TestMenu item) {
    debugPrint('App: Closed item ${item.label}');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Directionality(
      textDirection: _textDirection,
      child: Builder(builder: (BuildContext context) {
        return Theme(
          data: theme.copyWith(visualDensity: _density),
          child: Column(
            children: <Widget>[
              MenuBar(
                enabled: _enabled,
                controller: _controller,
                menus: <MenuBarItem>[
                  MenuBarMenu(
                    label: TestMenu.mainMenu1.label,
                    onOpen: () {
                      _openItem(TestMenu.mainMenu1);
                    },
                    onClose: () {
                      _closeItem(TestMenu.mainMenu1);
                    },
                    menus: <MenuBarItem>[
                      MenuBarButton(
                        label: TestMenu.subMenu1.label,
                        shortcut: const SingleActivator(
                          LogicalKeyboardKey.keyB,
                          control: true,
                        ),
                        leadingIcon: _addItem ? const Icon(Icons.check_box) : const Icon(Icons.check_box_outline_blank),
                        trailingIcon: const Icon(Icons.assessment),
                        onSelected: () {
                          _itemSelected(TestMenu.subMenu1);
                          setState(() {
                            _addItem = !_addItem;
                          });
                        },
                      ),
                      MenuBarButton(
                        label: TestMenu.subMenu2.label,
                        leadingIcon: const Icon(Icons.send),
                        trailingIcon: const Icon(Icons.mail),
                        onSelected: () {
                          _itemSelected(TestMenu.subMenu2);
                        },
                      ),
                    ],
                  ),
                  MenuItemGroup(
                    members: <MenuBarItem>[
                      MenuBarMenu(
                        label: TestMenu.mainMenu2.label,
                        onOpen: () {
                          _openItem(TestMenu.mainMenu2);
                        },
                        onClose: () {
                          _closeItem(TestMenu.mainMenu2);
                        },
                        menus: <MenuBarItem>[
                          MenuBarButton(
                            label: TestMenu.subMenu3.label,
                            shortcut: const SingleActivator(
                              LogicalKeyboardKey.enter,
                              control: true,
                            ),
                            onSelected: () {
                              _itemSelected(TestMenu.subMenu3);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  MenuBarMenu(
                    label: TestMenu.mainMenu3.label,
                    onOpen: () {
                      _openItem(TestMenu.mainMenu3);
                    },
                    onClose: () {
                      _closeItem(TestMenu.mainMenu3);
                    },
                    menus: <MenuBarItem>[
                      MenuItemGroup(members: <MenuBarItem>[
                        MenuBarButton(
                          label: TestMenu.subMenu4.label,
                          shortcut: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                          onSelectedIntent: const ActivateIntent(),
                        ),
                      ]),
                      MenuBarMenu(
                        label: TestMenu.subMenu5.label,
                        onOpen: () {
                          _openItem(TestMenu.subMenu5);
                        },
                        onClose: () {
                          _closeItem(TestMenu.subMenu5);
                        },
                        menus: <MenuBarItem>[
                          MenuBarButton(
                            label: TestMenu.subSubMenu1.label,
                            shortcut: _addItem
                                ? const SingleActivator(
                                    LogicalKeyboardKey.f11,
                                    control: true,
                                  )
                                : const SingleActivator(
                                    LogicalKeyboardKey.f10,
                                    control: true,
                                  ),
                            onSelected: () {
                              _itemSelected(TestMenu.subSubMenu1);
                            },
                          ),
                          MenuBarButton(
                            label: TestMenu.subSubMenu2.label,
                            onSelected: () {
                              _itemSelected(TestMenu.subSubMenu2);
                            },
                          ),
                          if (_addItem)
                            MenuBarButton(
                              label: TestMenu.subSubMenu3.label,
                              onSelected: () {
                                _itemSelected(TestMenu.subSubMenu3);
                              },
                            ),
                        ],
                      ),
                      MenuBarButton(
                        label: TestMenu.subMenu6.label,
                        shortcut: const SingleActivator(
                          LogicalKeyboardKey.tab,
                          control: true,
                        ),
                      ),
                      MenuBarButton(
                        label: TestMenu.subMenu7.label,
                        onSelected: () {},
                      ),
                      MenuBarButton(
                        label: TestMenu.subMenu7.label,
                        onSelected: () {},
                      ),
                      MenuBarButton(
                        label: TestMenu.subMenu8.label,
                        onSelected: () {},
                      ),
                    ],
                  ),
                ],
              ),
              Expanded(
                child: _Controls(
                  density: _density,
                  enabled: _enabled,
                  addItem: _addItem,
                  textDirection: _textDirection,
                  onDensityChanged: (VisualDensity value) {
                    setState(() {
                      _density = value;
                    });
                  },
                  onTextDirectionChanged: (TextDirection value) {
                    setState(() {
                      _textDirection = value;
                    });
                  },
                  onEnabledChanged: (bool value) {
                    setState(() {
                      _enabled = value;
                    });
                  },
                  onAddItemChanged: (bool value) {
                    setState(() {
                      _addItem = value;
                    });
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.density,
    required this.textDirection,
    this.enabled = true,
    this.addItem = false,
    required this.onDensityChanged,
    required this.onTextDirectionChanged,
    required this.onEnabledChanged,
    required this.onAddItemChanged,
  });

  final VisualDensity density;
  final TextDirection textDirection;
  final bool enabled;
  final bool addItem;
  final ValueChanged<VisualDensity> onDensityChanged;
  final ValueChanged<TextDirection> onTextDirectionChanged;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onAddItemChanged;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text('Horizontal Density: ${density.horizontal.toStringAsFixed(1)}'),
                Slider(
                  value: density.horizontal,
                  max: 4,
                  min: -4,
                  divisions: 12,
                  onChanged: (double value) {
                    onDensityChanged(VisualDensity(horizontal: value, vertical: density.vertical));
                  },
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: 400),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Text('Vertical Density: ${density.vertical.toStringAsFixed(1)}'),
                Slider(
                  value: density.vertical,
                  max: 4,
                  min: -4,
                  divisions: 12,
                  onChanged: (double value) {
                    onDensityChanged(VisualDensity(horizontal: density.horizontal, vertical: value));
                  },
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Checkbox(
                value: textDirection == TextDirection.rtl,
                onChanged: (bool? value) {
                  if (value ?? false) {
                    onTextDirectionChanged(TextDirection.rtl);
                  } else {
                    onTextDirectionChanged(TextDirection.ltr);
                  }
                },
              ),
              const Text('RTL Text')
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Checkbox(
                value: enabled,
                onChanged: (bool? value) {
                  if (value ?? false) {
                    onEnabledChanged(true);
                  } else {
                    onEnabledChanged(false);
                  }
                },
              ),
              const Text('Enabled')
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Checkbox(
                value: addItem,
                onChanged: (bool? value) {
                  if (value ?? false) {
                    onAddItemChanged(true);
                  } else {
                    onAddItemChanged(false);
                  }
                },
              ),
              const Text('Add Item')
            ],
          ),
        ],
      ),
    );
  }
}
