// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';
import 'scaffold.dart';

bool debugCheckHasMaterial(BuildContext context) {
  assert(() {
    if (context.widget is! Material && context.ancestorWidgetOfExactType(Material) == null) {
      Element element = context;
      throw new FlutterError(
        'No Material widget found.\n'
        '${context.widget.runtimeType} widgets require a Material widget ancestor.\n'
        'In material design, most widgets are conceptually "printed" on a sheet of material. In Flutter\'s material library, '
        'that material is represented by the Material widget. It is the Material widget that renders ink splashes, for instance. '
        'Because of this, many material library widgets require that there be a Material widget in the tree above them.\n'
        'To introduce a Material widget, you can either directly include one, or use a widget that contains Material itself, '
        'such as a Card, Dialog, Drawer, or Scaffold.\n'
        'The specific widget that could not find a Material ancestor was:\n'
        '  ${context.widget}'
        'The ownership chain for the affected widget is:\n'
        '  ${element.debugGetCreatorChain(10)}'
      );
    }
    return true;
  });
  return true;
}


bool debugCheckHasScaffold(BuildContext context) {
  assert(() {
    if (Scaffold.of(context) == null) {
      Element element = context;
      throw new FlutterError(
        'No Scaffold widget found.\n'
        '${context.widget.runtimeType} widgets require a Scaffold widget ancestor.\n'
        'The specific widget that could not find a Scaffold ancestor was:\n'
        '  ${context.widget}'
        'The ownership chain for the affected widget is:\n'
        '  ${element.debugGetCreatorChain(10)}'
      );
    }
    return true;
  });
  return true;
}
