// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'playground/cupertino/cupertino.dart';
import 'playground/material/material.dart';
import 'playground/playground_scaffold.dart';

class MaterialPlaygroundDemo extends StatelessWidget {
  const MaterialPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/material';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => const MaterialPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) {
    return PlaygroundScaffold(
      title: 'Material Playground',
      demos: <String, Widget>{
        'RAISEDBUTTON': RaisedButtonDemo(),
        'FLATBUTTON': FlatButtonDemo(),
        'ICONBUTTON': IconButtonDemo(),
        'CHECKBOX': CheckboxDemo(),
        'SWITCH': SwitchDemo(),
        'SLIDER': SliderDemo(),
      },
    );
  }
}

class CupertinoPlaygroundDemo extends StatelessWidget {
  const CupertinoPlaygroundDemo({Key key}) : super(key: key);

  static const String routeName = '/playground/cupertino';

  static WidgetBuilder buildRoute() {
    return (BuildContext context) => const CupertinoPlaygroundDemo();
  }

  @override
  Widget build(BuildContext context) {
    return PlaygroundScaffold(
      title: 'Cupertino Playground',
      demos: <String, Widget>{
        'SEGEMENTEDCONTROL': CupertinoSegmentControlDemo(),
        'SLIDER': CupertinoSliderDemo(),
        'BUTTON': CupertinoButtonDemo(),
        'SWITCH': CupertinoSwitchDemo(),
      },
    );
  }
}
