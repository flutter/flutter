// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    const MaterialApp(
      title: 'Menu Tester',
      home: Material(
        child: Home(),
      ),
    ),
  );
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final MenuController _controller = MenuController();
  VisualDensity _density = VisualDensity.standard;
  TextDirection _textDirection = TextDirection.ltr;
  double _extraPadding = 0;
  bool _addItem = false;
  bool _transparent = false;
  bool _funkyTheme = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    MenuThemeData menuTheme = MenuTheme.of(context);
    MenuBarThemeData menuBarTheme = MenuBarTheme.of(context);
    MenuButtonThemeData menuButtonTheme = MenuButtonTheme.of(context);
    if (_funkyTheme) {
      menuTheme = const MenuThemeData(
        style: MenuStyle(
          shape: MaterialStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
          ),
          backgroundColor: MaterialStatePropertyAll<Color?>(Colors.blue),
          elevation: MaterialStatePropertyAll<double?>(10),
          padding: MaterialStatePropertyAll<EdgeInsetsDirectional>(
            EdgeInsetsDirectional.all(20),
          ),
        ),
      );
      menuButtonTheme = const MenuButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStatePropertyAll<OutlinedBorder>(StadiumBorder()),
          backgroundColor: MaterialStatePropertyAll<Color?>(Colors.green),
          foregroundColor: MaterialStatePropertyAll<Color?>(Colors.white),
        ),
      );
      menuBarTheme = const MenuBarThemeData(
        style: MenuStyle(
          shape: MaterialStatePropertyAll<OutlinedBorder>(RoundedRectangleBorder()),
          backgroundColor: MaterialStatePropertyAll<Color?>(Colors.blue),
          elevation: MaterialStatePropertyAll<double?>(10),
          padding: MaterialStatePropertyAll<EdgeInsetsDirectional>(
            EdgeInsetsDirectional.all(20),
          ),
        ),
      );
    }
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(_extraPadding),
        child: Directionality(
          textDirection: _textDirection,
          child: Theme(
            data: theme.copyWith(
              visualDensity: _density,
              menuTheme: _transparent
                  ? MenuThemeData(
                      style: MenuStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                          Colors.blue.withOpacity(0.12),
                        ),
                        elevation: const MaterialStatePropertyAll<double>(0),
                      ),
                    )
                  : menuTheme,
              menuBarTheme: menuBarTheme,
              menuButtonTheme: menuButtonTheme,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _TestMenus(
                  menuController: _controller,
                  addItem: _addItem,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: _Controls(
                      menuController: _controller,
                      density: _density,
                      addItem: _addItem,
                      transparent: _transparent,
                      funkyTheme: _funkyTheme,
                      extraPadding: _extraPadding,
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
                      onExtraPaddingChanged: (double value) {
                        setState(() {
                          _extraPadding = value;
                        });
                      },
                      onAddItemChanged: (bool value) {
                        setState(() {
                          _addItem = value;
                        });
                      },
                      onTransparentChanged: (bool value) {
                        setState(() {
                          _transparent = value;
                        });
                      },
                      onFunkyThemeChanged: (bool value) {
                        setState(() {
                          _funkyTheme = value;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Controls extends StatefulWidget {
  const _Controls({
    required this.density,
    required this.textDirection,
    required this.extraPadding,
    this.addItem = false,
    this.transparent = false,
    this.funkyTheme = false,
    required this.onDensityChanged,
    required this.onTextDirectionChanged,
    required this.onExtraPaddingChanged,
    required this.onAddItemChanged,
    required this.onTransparentChanged,
    required this.onFunkyThemeChanged,
    required this.menuController,
  });

  final VisualDensity density;
  final TextDirection textDirection;
  final double extraPadding;
  final bool addItem;
  final bool transparent;
  final bool funkyTheme;
  final ValueChanged<VisualDensity> onDensityChanged;
  final ValueChanged<TextDirection> onTextDirectionChanged;
  final ValueChanged<double> onExtraPaddingChanged;
  final ValueChanged<bool> onAddItemChanged;
  final ValueChanged<bool> onTransparentChanged;
  final ValueChanged<bool> onFunkyThemeChanged;
  final MenuController menuController;

  @override
  State<_Controls> createState() => _ControlsState();
}

class _ControlsState extends State<_Controls> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'Floating');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.lightBlueAccent,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MenuAnchor(
            childFocusNode: _focusNode,
            style: const MenuStyle(alignment: AlignmentDirectional.topEnd),
            alignmentOffset: const Offset(100, -8),
            menuChildren: <Widget>[
              MenuItemButton(
                shortcut: TestMenu.standaloneMenu1.shortcut,
                onPressed: () {
                  _itemSelected(TestMenu.standaloneMenu1);
                },
                child: Text(TestMenu.standaloneMenu1.label),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.send),
                trailingIcon: const Icon(Icons.mail),
                onPressed: () {
                  _itemSelected(TestMenu.standaloneMenu2);
                },
                child: Text(TestMenu.standaloneMenu2.label),
              ),
            ],
            builder: (BuildContext context, MenuController controller, Widget? child) {
              return TextButton(
                focusNode: _focusNode,
                onPressed: () {
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
                child: child!,
              );
            },
            child: const Text('Open Menu'),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ControlSlider(
                  label: 'Extra Padding: ${widget.extraPadding.toStringAsFixed(1)}',
                  value: widget.extraPadding,
                  max: 40,
                  divisions: 20,
                  onChanged: (double value) {
                    widget.onExtraPaddingChanged(value);
                  },
                ),
                _ControlSlider(
                  label: 'Horizontal Density: ${widget.density.horizontal.toStringAsFixed(1)}',
                  value: widget.density.horizontal,
                  max: 4,
                  min: -4,
                  divisions: 12,
                  onChanged: (double value) {
                    widget.onDensityChanged(
                      VisualDensity(
                        horizontal: value,
                        vertical: widget.density.vertical,
                      ),
                    );
                  },
                ),
                _ControlSlider(
                  label: 'Vertical Density: ${widget.density.vertical.toStringAsFixed(1)}',
                  value: widget.density.vertical,
                  max: 4,
                  min: -4,
                  divisions: 12,
                  onChanged: (double value) {
                    widget.onDensityChanged(
                      VisualDensity(
                        horizontal: widget.density.horizontal,
                        vertical: value,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.textDirection == TextDirection.rtl,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onTextDirectionChanged(TextDirection.rtl);
                      } else {
                        widget.onTextDirectionChanged(TextDirection.ltr);
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
                    value: widget.addItem,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onAddItemChanged(true);
                      } else {
                        widget.onAddItemChanged(false);
                      }
                    },
                  ),
                  const Text('Add Item')
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.transparent,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onTransparentChanged(true);
                      } else {
                        widget.onTransparentChanged(false);
                      }
                    },
                  ),
                  const Text('Transparent')
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Checkbox(
                    value: widget.funkyTheme,
                    onChanged: (bool? value) {
                      if (value ?? false) {
                        widget.onFunkyThemeChanged(true);
                      } else {
                        widget.onFunkyThemeChanged(false);
                      }
                    },
                  ),
                  const Text('Funky Theme')
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _itemSelected(TestMenu item) {
    debugPrint('App: Selected item ${item.label}');
  }
}

class _ControlSlider extends StatelessWidget {
  const _ControlSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Container(
          alignment: AlignmentDirectional.centerEnd,
          constraints: const BoxConstraints(minWidth: 150),
          child: Text(label),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TestMenus extends StatefulWidget {
  const _TestMenus({
    required this.menuController,
    this.addItem = false,
  });

  final MenuController menuController;
  final bool addItem;

  @override
  State<_TestMenus> createState() => _TestMenusState();
}

class _TestMenusState extends State<_TestMenus> {
  final TextEditingController textController = TextEditingController();
  bool? checkboxState = false;
  TestMenu? radioValue;
  ShortcutRegistryEntry? _shortcutsEntry;

  void _itemSelected(TestMenu item) {
    debugPrint('App: Selected item ${item.label}');
  }

  void _openItem(TestMenu item) {
    debugPrint('App: Opened item ${item.label}');
  }

  void _closeItem(TestMenu item) {
    debugPrint('App: Closed item ${item.label}');
  }

  void _setRadio(TestMenu item) {
    debugPrint('App: Set Radio item ${item.label}');
    setState(() {
      radioValue = item;
    });
  }

  void _setCheck(TestMenu item) {
    debugPrint('App: Set Checkbox item ${item.label}');
    setState(() {
        switch (checkboxState) {
          case false:
            checkboxState = true;
            break;
          case true:
            checkboxState = null;
            break;
          case null:
            checkboxState = false;
            break;
        }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shortcutsEntry?.dispose();
    final Map<ShortcutActivator, Intent> shortcuts = <ShortcutActivator, Intent>{};
    for (final TestMenu item in TestMenu.values) {
       if (item.shortcut == null) {
        continue;
       }
      switch (item) {
        case TestMenu.radioMenu1:
        case TestMenu.radioMenu2:
        case TestMenu.radioMenu3:
          shortcuts[item.shortcut!] = VoidCallbackIntent(() => _setRadio(item));
          break;
        case TestMenu.subMenu1:
          shortcuts[item.shortcut!] = VoidCallbackIntent(() => _setCheck(item));
          break;
        case TestMenu.mainMenu1:
        case TestMenu.mainMenu2:
        case TestMenu.mainMenu3:
        case TestMenu.mainMenu4:
        case TestMenu.subMenu2:
        case TestMenu.subMenu3:
        case TestMenu.subMenu4:
        case TestMenu.subMenu5:
        case TestMenu.subMenu6:
        case TestMenu.subMenu7:
        case TestMenu.subMenu8:
        case TestMenu.subSubMenu1:
        case TestMenu.subSubMenu2:
        case TestMenu.subSubMenu3:
        case TestMenu.subSubSubMenu1:
        case TestMenu.testButton:
        case TestMenu.standaloneMenu1:
        case TestMenu.standaloneMenu2:
          shortcuts[item.shortcut!] = VoidCallbackIntent(() => _itemSelected(item));
          break;
      }
    }
    _shortcutsEntry = ShortcutRegistry.of(context).addAll(shortcuts);
  }

  @override
  void dispose() {
    _shortcutsEntry?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: MenuBar(
            controller: widget.menuController,
            children: <Widget>[
              SubmenuButton(
                onOpen: () {
                  _openItem(TestMenu.mainMenu1);
                },
                onClose: () {
                  _closeItem(TestMenu.mainMenu1);
                },
                menuChildren: <Widget>[
                  CheckboxMenuButton(
                    value: checkboxState,
                    tristate: true,
                    shortcut: TestMenu.subMenu1.shortcut,
                    trailingIcon: const Icon(Icons.assessment),
                    onChanged: (bool? value) {
                      setState(() {
                        checkboxState = value;
                      });
                      _itemSelected(TestMenu.subMenu1);
                    },
                    child: Text(TestMenu.subMenu1.label),
                  ),
                  RadioMenuButton<TestMenu>(
                    value: TestMenu.radioMenu1,
                    groupValue: radioValue,
                    toggleable: true,
                    shortcut: TestMenu.radioMenu1.shortcut,
                    trailingIcon: const Icon(Icons.assessment),
                    onChanged: (TestMenu? value) {
                      setState(() {
                        radioValue = value;
                      });
                      _itemSelected(TestMenu.radioMenu1);
                    },
                    child: Text(TestMenu.radioMenu1.label),
                  ),
                  RadioMenuButton<TestMenu>(
                    value: TestMenu.radioMenu2,
                    groupValue: radioValue,
                    toggleable: true,
                    shortcut: TestMenu.radioMenu2.shortcut,
                    trailingIcon: const Icon(Icons.assessment),
                    onChanged: (TestMenu? value) {
                      setState(() {
                        radioValue = value;
                      });
                      _itemSelected(TestMenu.radioMenu2);
                    },
                    child: Text(TestMenu.radioMenu2.label),
                  ),
                  RadioMenuButton<TestMenu>(
                    value: TestMenu.radioMenu3,
                    groupValue: radioValue,
                    toggleable: true,
                    shortcut: TestMenu.radioMenu3.shortcut,
                    trailingIcon: const Icon(Icons.assessment),
                    onChanged: (TestMenu? value) {
                      setState(() {
                        radioValue = value;
                      });
                      _itemSelected(TestMenu.radioMenu3);
                    },
                    child: Text(TestMenu.radioMenu3.label),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.send),
                    trailingIcon: const Icon(Icons.mail),
                    onPressed: () {
                      _itemSelected(TestMenu.subMenu2);
                    },
                    child: Text(TestMenu.subMenu2.label),
                  ),
                ],
                child: Text(TestMenu.mainMenu1.label),
              ),
              SubmenuButton(
                onOpen: () {
                  _openItem(TestMenu.mainMenu2);
                },
                onClose: () {
                  _closeItem(TestMenu.mainMenu2);
                },
                menuChildren: <Widget>[
                  TextButton(
                    child: const Text('TEST'),
                    onPressed: () {
                      _itemSelected(TestMenu.testButton);
                      widget.menuController.close();
                    },
                  ),
                  MenuItemButton(
                    shortcut: TestMenu.subMenu3.shortcut,
                    onPressed: () {
                      _itemSelected(TestMenu.subMenu3);
                    },
                    child: Text(TestMenu.subMenu3.label),
                  ),
                ],
                child: Text(TestMenu.mainMenu2.label),
              ),
              SubmenuButton(
                onOpen: () {
                  _openItem(TestMenu.mainMenu3);
                },
                onClose: () {
                  _closeItem(TestMenu.mainMenu3);
                },
                menuChildren: <Widget>[
                  MenuItemButton(
                    child: Text(TestMenu.subMenu8.label),
                    onPressed: () {
                      _itemSelected(TestMenu.subMenu8);
                    },
                  ),
                ],
                child: Text(TestMenu.mainMenu3.label),
              ),
              SubmenuButton(
                onOpen: () {
                  _openItem(TestMenu.mainMenu4);
                },
                onClose: () {
                  _closeItem(TestMenu.mainMenu4);
                },
                menuChildren: <Widget>[
                  Actions(
                    actions: <Type, Action<Intent>>{
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (ActivateIntent? intent) {
                          debugPrint('Activated!');
                          return;
                        },
                      )
                    },
                    child: MenuItemButton(
                      onPressed: () {
                        debugPrint('Activated text input item with ${textController.text} as a value.');
                      },
                      child: SizedBox(
                        width: 200,
                        child: TextField(
                          controller: textController,
                          onSubmitted: (String value) {
                            debugPrint('String $value submitted.');
                          },
                        ),
                      ),
                    ),
                  ),
                  SubmenuButton(
                    onOpen: () {
                      _openItem(TestMenu.subMenu5);
                    },
                    onClose: () {
                      _closeItem(TestMenu.subMenu5);
                    },
                    menuChildren: <Widget>[
                      MenuItemButton(
                        shortcut: TestMenu.subSubMenu1.shortcut,
                        onPressed: () {
                          _itemSelected(TestMenu.subSubMenu1);
                        },
                        child: Text(TestMenu.subSubMenu1.label),
                      ),
                      MenuItemButton(
                        child: Text(TestMenu.subSubMenu2.label),
                        onPressed: () {
                          _itemSelected(TestMenu.subSubMenu2);
                        },
                      ),
                      if (widget.addItem)
                        SubmenuButton(
                          menuChildren: <Widget>[
                            MenuItemButton(
                              shortcut: TestMenu.subSubSubMenu1.shortcut,
                              onPressed: () {
                                _itemSelected(TestMenu.subSubSubMenu1);
                              },
                              child: Text(TestMenu.subSubSubMenu1.label),
                            ),
                          ],
                          child: Text(TestMenu.subSubMenu3.label),
                        ),
                    ],
                    child: Text(TestMenu.subMenu5.label),
                  ),
                  MenuItemButton(
                    // Disabled button
                    shortcut: TestMenu.subMenu6.shortcut,
                    child: Text(TestMenu.subMenu6.label),
                  ),
                  MenuItemButton(
                    child: Text(TestMenu.subMenu7.label),
                    onPressed: () {
                      _itemSelected(TestMenu.subMenu7);
                    },
                  ),
                  MenuItemButton(
                    child: Text(TestMenu.subMenu7.label),
                    onPressed: () {
                      _itemSelected(TestMenu.subMenu7);
                    },
                  ),
                  MenuItemButton(
                    child: Text(TestMenu.subMenu8.label),
                    onPressed: () {
                      _itemSelected(TestMenu.subMenu8);
                    },
                  ),
                ],
                child: Text(TestMenu.mainMenu4.label),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

enum TestMenu {
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  mainMenu3('Menu 3'),
  mainMenu4('Menu 4'),
  radioMenu1('Radio Menu One', SingleActivator(LogicalKeyboardKey.digit1, control: true)),
  radioMenu2('Radio Menu Two', SingleActivator(LogicalKeyboardKey.digit2, control: true)),
  radioMenu3('Radio Menu Three', SingleActivator(LogicalKeyboardKey.digit3, control: true)),
  subMenu1('Sub Menu 1', SingleActivator(LogicalKeyboardKey.keyB, control: true)),
  subMenu2('Sub Menu 2'),
  subMenu3('Sub Menu 3', SingleActivator(LogicalKeyboardKey.enter, control: true)),
  subMenu4('Sub Menu 4'),
  subMenu5('Sub Menu 5'),
  subMenu6('Sub Menu 6', SingleActivator(LogicalKeyboardKey.tab, control: true)),
  subMenu7('Sub Menu 7'),
  subMenu8('Sub Menu 8'),
  subSubMenu1('Sub Sub Menu 1', SingleActivator(LogicalKeyboardKey.f10, control: true)),
  subSubMenu2('Sub Sub Menu 2'),
  subSubMenu3('Sub Sub Menu 3'),
  subSubSubMenu1('Sub Sub Sub Menu 1', SingleActivator(LogicalKeyboardKey.f11, control: true)),
  testButton('TEST button'),
  standaloneMenu1('Standalone Menu 1', SingleActivator(LogicalKeyboardKey.keyC, control: true)),
  standaloneMenu2('Standalone Menu 2');

  const TestMenu(this.label, [this.shortcut]);
  final String label;
  final MenuSerializableShortcut? shortcut;
}
