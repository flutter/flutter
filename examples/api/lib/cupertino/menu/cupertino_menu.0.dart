// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';

/// Flutter code sample for [CupertinoMenuButton]
///
void main() => runApp(const CupertinoMenuApp());
class CupertinoMenuApp extends StatelessWidget {
  const CupertinoMenuApp({super.key});
  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      theme: CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoMenuExample(),
    );
  }
}

class CupertinoMenuExample extends StatefulWidget {
  const CupertinoMenuExample({super.key});

  @override
  State<CupertinoMenuExample> createState() => _CupertinoMenuExampleState();
}

class _CupertinoMenuExampleState extends State<CupertinoMenuExample> {
  String _checkedValue = 'Cat';
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('CupertinoContextMenu Sample'),
      ),
      child: Align(
        alignment: const Alignment(0, -0.5),
        child: SizedBox(
          width: 100,
          height: 100,
          child:  CupertinoMenuButton<String>(
            itemBuilder: (BuildContext context) {
              return <CupertinoMenuEntry<String>>[
                CupertinoStickyMenuHeader(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration:  ShapeDecoration(
                      shape: const CircleBorder(),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          CupertinoColors.activeBlue,
                          CupertinoColors.activeBlue.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                  trailing: CupertinoButton(
                    minSize: 34,
                    padding: EdgeInsets.zero,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: ShapeDecoration(
                        shape: const CircleBorder(),
                        color: CupertinoColors.systemFill.resolveFrom(context),
                      ),
                      child: Icon(
                        CupertinoIcons.share,
                        color: CupertinoColors.label.resolveFrom(context),
                        size: 16,
                        semanticLabel: 'Triangle',
                      ),
                    ),
                    onPressed: () {},
                  ),
                  subtitle: const Text('Folder'),
                  child: const Text('Downloads'),
                ),
                CupertinoNestedMenu<String>(
                  itemBuilder: (BuildContext context) => <CupertinoMenuEntry<String>>[
                    CupertinoCheckedMenuItem<String>(
                      value: 'Cat',
                      checked: _checkedValue == 'Cat',
                      shouldPopMenuOnPressed: false,
                      onTap: (){
                        setState(() {
                          _checkedValue = 'Cat';
                        });
                      },
                      child: const Text('Cat'),
                    ),
                    CupertinoCheckedMenuItem<String>(
                      value: 'Feline',
                      checked: _checkedValue == 'Feline',
                      onTap: (){
                        setState(() {
                          _checkedValue = 'Feline';
                        });
                      },
                      shouldPopMenuOnPressed: false,
                      child: const Text('Feline'),
                    ),
                    CupertinoCheckedMenuItem<String>(
                      value: 'Kitten',
                      checked: _checkedValue == 'Kitten',
                      onTap: (){
                        setState(() {
                          _checkedValue = 'Kitten';
                        });
                      },
                      shouldPopMenuOnPressed: false,
                      child: const Text('Kitten'),
                    ),
                  ],
                  subtitle:  Text(_checkedValue),
                  title: const TextSpan(text: 'Favorite Animal'),
                ),
                CupertinoMenuItem<String>(
                  trailing: const Icon(
                    CupertinoIcons.textformat_size,
                  ),
                  child: const Text(
                    'Simple',
                  ),
                  onTap: () {},
                ),
                const CupertinoMenuItem<String>(
                  shouldPopMenuOnPressed: false,
                  trailing: Icon(
                    CupertinoIcons.textformat_size,
                  ),
                  isDefaultAction: true,
                  child: Text('Default'),
                ),
                const CupertinoMenuItem<String>(
                  trailing: Icon(CupertinoIcons.cloud_upload),
                  value: 'Disabled',
                  enabled: false,
                  child: Text('Disabled'),
                ),
                const CupertinoMenuActionItem<String>(
                  icon: Icon(
                    CupertinoIcons.triangle,
                    semanticLabel: 'Triangle',
                  ),
                  value: 'Triangle',
                  child: Text('Triangle'),
                ),
                const CupertinoMenuActionItem<String>(
                  icon: Icon(
                    CupertinoIcons.square,
                    semanticLabel: 'Square',
                  ),
                  value: 'Square',
                  child: Text('Square'),
                ),
                const CupertinoMenuActionItem<String>(
                  icon: Icon(
                    CupertinoIcons.circle,
                    semanticLabel: 'Circle',
                  ),
                  value: 'Circle',
                  child: Text('Circle'),
                ),
                const CupertinoMenuActionItem<String>(
                  icon: Icon(
                    CupertinoIcons.star,
                    semanticLabel: 'Star',
                  ),
                  value: 'Star',
                  child: Text('Star'),
                ),
                const CupertinoMenuLargeDivider(),
                const CupertinoMenuItem<String>(
                  value: 'Delete',
                  isDestructiveAction: true,
                  trailing: Icon(
                    CupertinoIcons.delete,
                    semanticLabel: 'Delete',
                  ),
                  child: Text('Delete'),
                ),
              ];
            },
          ),
        ),
      ),
    );
  }
}
