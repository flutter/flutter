// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Pages to test, keyed by the name used by the driver test.
final Map<String, WidgetBuilder> pages = <String, WidgetBuilder>{
  'button': (BuildContext context) => const _ButtonPage(),
  'checkbox': (BuildContext context) => const _CheckboxPage(),
  'slider': (BuildContext context) => const _SliderPage(),
  'text_field': (BuildContext context) => const _TextFieldPage(),
  'semantics': (BuildContext context) => const _SemanticsPage(),
};

class _ButtonPage extends StatefulWidget {
  const _ButtonPage();

  @override
  State<_ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<_ButtonPage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Pressed $_count times'),
        ElevatedButton(onPressed: () => setState(() => _count++), child: const Text('Increment')),
        const ElevatedButton(onPressed: null, child: Text('Disabled')),
      ],
    );
  }
}

class _CheckboxPage extends StatefulWidget {
  const _CheckboxPage();

  @override
  State<_CheckboxPage> createState() => _CheckboxPageState();
}

class _CheckboxPageState extends State<_CheckboxPage> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: CheckboxListTile(
        title: const Text('Check me'),
        value: _checked,
        onChanged: (bool? value) => setState(() => _checked = value!),
      ),
    );
  }
}

class _SliderPage extends StatefulWidget {
  const _SliderPage();

  @override
  State<_SliderPage> createState() => _SliderPageState();
}

class _SliderPageState extends State<_SliderPage> {
  double _value = 50;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Volume is ${_value.round()}'),
        SizedBox(
          width: 300,
          child: Slider(
            value: _value,
            max: 100,
            divisions: 10,
            label: 'Volume',
            onChanged: (double value) => setState(() => _value = value),
          ),
        ),
      ],
    );
  }
}

class _TextFieldPage extends StatelessWidget {
  const _TextFieldPage();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 300,
      child: TextField(decoration: InputDecoration(labelText: 'Name')),
    );
  }
}

// Uses Semantics widgets directly to set each semantics property, each on its
// own node.
class _SemanticsPage extends StatefulWidget {
  const _SemanticsPage();

  @override
  State<_SemanticsPage> createState() => _SemanticsPageState();
}

class _SemanticsPageState extends State<_SemanticsPage> {
  String _lastAction = 'none';

  void _setLastAction(String action) => setState(() => _lastAction = action);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text('Last action: $_lastAction'),
        Semantics(
          container: true,
          header: true,
          label: 'Settings',
          excludeSemantics: true,
          child: const Text('Settings'),
        ),
        Semantics(
          container: true,
          link: true,
          label: 'Help',
          onTap: () => _setLastAction('link'),
          excludeSemantics: true,
          child: const Text('Help'),
        ),
        Semantics(
          container: true,
          image: true,
          label: 'Flutter logo',
          excludeSemantics: true,
          child: const FlutterLogo(),
        ),
        Semantics(
          container: true,
          button: true,
          label: 'Custom button',
          onTap: () => _setLastAction('tap'),
          onLongPress: () => _setLastAction('long press'),
          onDismiss: () => _setLastAction('dismiss'),
          excludeSemantics: true,
          child: const Text('Custom button'),
        ),
        Semantics(
          container: true,
          toggled: true,
          label: 'Wi-Fi',
          excludeSemantics: true,
          child: const Text('Wi-Fi'),
        ),
        Semantics(
          container: true,
          selected: true,
          label: 'Selected item',
          excludeSemantics: true,
          child: const Text('Selected item'),
        ),
        Semantics(
          container: true,
          readOnly: true,
          label: 'Read only',
          excludeSemantics: true,
          child: const Text('Read only'),
        ),
        Semantics(
          container: true,
          label: 'Upload',
          hint: 'Uploads the file',
          excludeSemantics: true,
          child: const Text('Upload'),
        ),
        const MergeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[Text('Merged'), Text('label')],
          ),
        ),
        const ExcludeSemantics(child: Text('Excluded')),
      ],
    );
  }
}
