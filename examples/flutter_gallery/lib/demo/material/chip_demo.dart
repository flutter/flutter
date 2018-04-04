// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const List<String> defaultMaterials = <String>[
  'poker',
  'tortilla',
  'fish and',
  'micro',
  'wood',
];

const List<String> defaultActions = <String>[
  'flake',
  'cut',
  'fragment',
  'splinter',
  'nick',
  'fry',
  'solder',
  'cash in',
  'eat',
];

const Map<String, String> results = <String, String>{
  'flake': 'flaking',
  'cut': 'cutting',
  'fragment': 'fragmenting',
  'splinter': 'splintering',
  'nick': 'nicking',
  'fry': 'frying',
  'solder': 'soldering',
  'cash in': 'cashing in',
  'eat': 'eating',
};

const List<String> defaultTools = <String>[
  'hammer',
  'chisel',
  'fryer',
  'fabricator',
  'customer',
];

const Map<String, String> avatars = <String, String>{
  'hammer': 'shrine/vendors/ali-connors.png',
  'chisel': 'shrine/vendors/sandra-adams.jpg',
  'fryer': 'shrine/vendors/zach.jpg',
  'fabricator': 'shrine/vendors/peter-carlsson.png',
  'customer': 'shrine/vendors/16c477b.jpg',
};
final Map<String, Set<String>> toolActions = <String, Set<String>>{
  'hammer': new Set<String>()..addAll(<String>['flake', 'fragment', 'splinter']),
  'chisel': new Set<String>()..addAll(<String>['flake', 'nick', 'splinter']),
  'fryer': new Set<String>()..addAll(<String>['fry']),
  'fabricator': new Set<String>()..addAll(<String>['solder']),
  'customer': new Set<String>()..addAll(<String>['cash in', 'eat']),
};

final Map<String, Set<String>> materialActions = <String, Set<String>>{
  'poker': new Set<String>()..addAll(<String>['cash in']),
  'tortilla': new Set<String>()..addAll(<String>['fry', 'eat']),
  'fish and': new Set<String>()..addAll(<String>['fry', 'eat']),
  'micro': new Set<String>()..addAll(<String>['solder', 'fragment']),
  'wood': new Set<String>()..addAll(<String>['flake', 'cut', 'splinter', 'nick']),
};

class ChipDemo extends StatefulWidget {
  static const String routeName = '/material/chip';

  @override
  _ChipDemoState createState() => new _ChipDemoState();
}

class _ChipDemoState extends State<ChipDemo> {
  _ChipDemoState() {
    _reset();
  }

  final List<String> materials = <String>[];
  String selectedMaterial = '';
  String selectedAction = '';
  final List<String> tools = <String>[];
  final List<String> selectedTools = <String>[];
  final List<String> actions = <String>[];
  bool showShapeBorder = false;

  // Initialize members with the default data.
  void _reset() {
    materials.clear();
    materials.addAll(defaultMaterials);
    actions.clear();
    actions.addAll(defaultActions);
    tools.clear();
    tools.addAll(defaultTools);
    selectedMaterial = '';
    selectedAction = '';
    selectedTools.clear();
  }

  // Wraps a list of chips into a ListTile for display as a section in the demo.
  Widget _wrapChips(String label, List<Widget> chips, ThemeData theme) {
    return new ListTile(
      title: Padding(
        padding: const EdgeInsets.only(top: 16.0, bottom: 4.0),
        child: new Text(label, textAlign: TextAlign.start),
      ),
      subtitle: chips.isEmpty
          ? new Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: new Text(
                  'None',
                  style: theme.textTheme.caption.copyWith(fontStyle: FontStyle.italic),
                ),
              ),
            )
          : new Wrap(
              children: chips
                  .map((Widget chip) => new Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: chip,
                      ))
                  .toList(),
            ),
    );
  }

  void _removeMaterial(String name) {
    if (materials.contains(name)) {
      materials.remove(name);
    }
    if (selectedMaterial == name) {
      selectedMaterial = '';
    }
  }

  void _removeTool(String name) {
    if (tools.contains(name)) {
      tools.remove(name);
    }
    if (selectedTools.contains(name)) {
      selectedTools.remove(name);
    }
  }

  String _capitalize(String name) {
    if (name == null || name.isEmpty) {
      return name;
    }
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }

  Color _nameToColor(String name) {
    assert(name.length > 1);
    final int hash = name.hashCode & 0xffff;
    final double hue = 360.0 * hash / (1 << 15);
    return new HSVColor.fromAHSV(1.0, hue, 0.4, 0.90).toColor();
  }

  AssetImage _nameToAvatar(String name) {
    assert(avatars.containsKey(name));
    return new AssetImage(
      avatars[name],
      package: 'flutter_gallery_assets',
    );
  }

  String _createResult() {
    if (selectedAction.isEmpty) {
      return '';
    }
    return _capitalize(results[selectedAction]) + '!';
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = materials.map<Widget>((String name) {
      return new Chip(
        key: new ValueKey<String>(name),
        backgroundColor: _nameToColor(name),
        label: new Text(_capitalize(name)),
        onDeleted: () {
          setState(() {
            _removeMaterial(name);
          });
        },
      );
    }).toList();

    final List<Widget> inputChips = tools.map<Widget>((String name) {
      return new InputChip(
          key: new ValueKey<String>(name),
          avatar: new CircleAvatar(
            backgroundImage: _nameToAvatar(name),
          ),
          label: new Text(_capitalize(name)),
          onDeleted: () {
            setState(() {
              _removeTool(name);
            });
          });
    }).toList();

    final List<Widget> choiceChips = materials.map<Widget>((String name) {
      return new ChoiceChip(
        key: new ValueKey<String>(name),
        backgroundColor: _nameToColor(name),
        label: new Text(_capitalize(name)),
        selected: selectedMaterial == name,
        onSelected: (bool value) {
          setState(() {
            if (!value) {
              selectedMaterial = '';
            } else {
              selectedMaterial = name;
            }
          });
        },
      );
    }).toList();

    final List<Widget> filterChips = defaultTools.map<Widget>((String name) {
      return new FilterChip(
        key: new ValueKey<String>(name),
        label: new Text(_capitalize(name)),
        selected: tools.contains(name) ? selectedTools.contains(name) : false,
        onSelected: tools.contains(name)
            ? (bool value) {
                setState(() {
                  if (!value) {
                    selectedTools.remove(name);
                  } else {
                    if (!selectedTools.contains(name)) {
                      selectedTools.add(name);
                    }
                  }
                });
              }
            : null,
      );
    }).toList();

    Set<String> allowedActions = new Set<String>();
    if (selectedMaterial != null && selectedMaterial.isNotEmpty) {
      for (String tool in selectedTools) {
        allowedActions = allowedActions.union(toolActions[tool]);
      }
      allowedActions = allowedActions.intersection(materialActions[selectedMaterial]);
    }

    final List<Widget> actionChips = allowedActions.map<Widget>((String name) {
      return new ActionChip(
        label: new Text(_capitalize(name)),
        onPressed: () {
          setState(() {
            selectedAction = name;
          });
        },
      );
    }).toList();

    final ThemeData theme = Theme.of(context);
    final List<Widget> tiles = <Widget>[
      const SizedBox(height: 8.0, width: 0.0),
      _wrapChips('Available Materials (Chip)', chips, theme),
      _wrapChips('Available Tools (InputChip)', inputChips, theme),
      _wrapChips('Choose a Material (ChoiceChip)', choiceChips, theme),
      _wrapChips('Choose Tools (FilterChip)', filterChips, theme),
      _wrapChips('Perform Allowed Action (ActionChip)', actionChips, theme),
      const Divider(),
      new Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Center(
          child: new Text(
            _createResult(),
            style: Theme.of(context).textTheme.title,
          ),
        ),
      ),
    ];

    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Chips'),
        actions: <Widget>[
          new IconButton(
            onPressed: () {
              setState(() {
                showShapeBorder = !showShapeBorder;
              });
            },
            icon: const Icon(Icons.vignette),
          )
        ],
      ),
      body: new ChipTheme(
        data: showShapeBorder
            ? Theme.of(context).chipTheme.copyWith(
                    shape: new BeveledRectangleBorder(
                  side: const BorderSide(width: 0.66, style: BorderStyle.solid, color: Colors.grey),
                  borderRadius: new BorderRadius.circular(10.0),
                ))
            : Theme.of(context).chipTheme.copyWith(shape: const StadiumBorder()),
        child: new ListView(children: tiles),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: () => setState(_reset),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
