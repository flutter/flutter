// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

const SnackBar _kTestSnackBar = SnackBar(content: Text('Yay! A SnackBar!'));

const List<FloatingActionButtonLocation> _kFABLocationConfigurations =
    <FloatingActionButtonLocation>[
  FloatingActionButtonLocation.centerDocked,
  FloatingActionButtonLocation.endDocked,
  FloatingActionButtonLocation.centerFloat,
  FloatingActionButtonLocation.endFloat,
  FloatingActionButtonLocation.endTop,
  FloatingActionButtonLocation.miniStartTop,
  FloatingActionButtonLocation.startTop
];

/// This demos the following configurations:
/// [FloatingActionButtonLocation]:
///  1. Docked:
///     a. Center
///     b. End
///  2. Float:
///     a. Center
///     b. Start
///  3. Top
///     a. Start
///     b. MiniStart
///     c. End
///
/// Toggle on and off for:
///   * [BottomAppBar]
///   * [SnackBar]
///   * [Scaffold]'s resizeToAvoidBottomInset
///   * KeyBoard
///
class FloatingActionButtonConfigurationsTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Floating Action Button Configurations Test',
      home: _ConfigurationRoute(),
    );
  }
}

class _ConfigurationRoute extends StatelessWidget {
  const _ConfigurationRoute();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Configuration'),
      ),
      body: Center(
        child: _ConfigurationOptions(),
      ),
    );
  }
}

class _FloatingActionButtonConfigurationsTestRoute extends StatelessWidget {
  const _FloatingActionButtonConfigurationsTestRoute(
      this.fabLocation, this.hasBab, this.resizeToAvoidBottomInset);

  final FloatingActionButtonLocation fabLocation;
  final bool hasBab;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
      ),
      body: _SnackBarPage(),
      bottomNavigationBar: buildBab(),
      floatingActionButton: buildFAB(),
      floatingActionButtonLocation: fabLocation,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }

  BottomAppBar buildBab() {
    if (!hasBab)
      return null;
    else
      return BottomAppBar(
        child: Container(
          height: 100,
          child: const Center(
            child: Text('Bottom App Bar'),
          ),
          color: Colors.amber,
        ),
      );
  }

  FloatingActionButton buildFAB() {
    return FloatingActionButton(
        child: const Icon(Icons.add),
        backgroundColor: Colors.red,
        onPressed: () {});
  }
}

class _SnackBarPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(40),
        children: <Widget>[
          RaisedButton(
              onPressed: () {
                Scaffold.of(context).showSnackBar(_kTestSnackBar);
              },
              color: Colors.lime,
              child: const Text('Show SnackBar')),
          TextFormField(
            autofocus: true,
            initialValue: 'Keyboard Trigger',
          )
        ],
      ),
    );
  }
}

class _ConfigurationOptions extends StatefulWidget {
  @override
  _ConfigurationOptionsState createState() {
    return _ConfigurationOptionsState();
  }
}

class _ConfigurationOptionsState extends State<_ConfigurationOptions> {
  FloatingActionButtonLocation fabLocation = _kFABLocationConfigurations[0];
  bool hasBab = false;
  bool resizeToAvoidBottomInset = true;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: <Widget>[
        buildFabDropDown(),
        buildBabToggle(),
        buildResetToAvoidBottomInsetToggle(),
        RaisedButton(
          child: const Text('Try Configuration'),
          color: Colors.green,
          onPressed: () {
            final _FloatingActionButtonConfigurationsTestRoute preview =
                _FloatingActionButtonConfigurationsTestRoute(
                    fabLocation, hasBab, resizeToAvoidBottomInset);
            final MaterialPageRoute<
                    _FloatingActionButtonConfigurationsTestRoute> nextRoute =
                MaterialPageRoute<_FloatingActionButtonConfigurationsTestRoute>(
                    builder: (BuildContext context) => preview);
            Navigator.push(context, nextRoute);
          },
        )
      ],
    );
  }

  Widget buildBabToggle() {
    return SwitchListTile.adaptive(
        title: const Text('BottomAppBar'),
        value: hasBab,
        onChanged: (bool value) {
          setState(() {
            hasBab = value;
          });
        });
  }

  Widget buildResetToAvoidBottomInsetToggle() {
    return SwitchListTile.adaptive(
        title: const Text('resizeToAvoidBottomInset'),
        value: resizeToAvoidBottomInset,
        onChanged: (bool value) {
          setState(() {
            resizeToAvoidBottomInset = value;
          });
        });
  }

  Widget buildFabDropDown() {
    return DropdownButton<FloatingActionButtonLocation>(
      items:
          _kFABLocationConfigurations.map((FloatingActionButtonLocation item) {
        return DropdownMenuItem<FloatingActionButtonLocation>(
          value: item,
          child: Text(item.toString()),
        );
      }).toList(),
      value: fabLocation,
      onChanged: (FloatingActionButtonLocation selectedItem) {
        setState(() {
          fabLocation = selectedItem;
        });
      },
    );
  }
}

void main() {
  runApp(FloatingActionButtonConfigurationsTestApp());
}
