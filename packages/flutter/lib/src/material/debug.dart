// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'material.dart';

/// Asserts that the given context has a [Material] ancestor.
///
/// Used by many material design widgets to make sure that they are
/// only used in contexts where they can print ink onto some material.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasMaterial(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasMaterial(BuildContext context) {
  assert(() {
    if (context.widget is! Material && context.ancestorWidgetOfExactType(Material) == null) {
      final StringBuffer message = new StringBuffer();
      message.writeln('No Material widget found.');
      message.writeln(
        '${context.widget.runtimeType} widgets require a Material '
        'widget ancestor.'
      );
      message.writeln(
        'In material design, most widgets are conceptually "printed" on '
        'a sheet of material. In Flutter\'s material library, that '
        'material is represented by the Material widget. It is the '
        'Material widget that renders ink splashes, for instance. '
        'Because of this, many material library widgets require that '
        'there be a Material widget in the tree above them.'
      );
      message.writeln(
        'To introduce a Material widget, you can either directly '
        'include one, or use a widget that contains Material itself, '
        'such as a Card, Dialog, Drawer, or Scaffold.'
      );
      message.writeln(
        'The specific widget that could not find a Material ancestor was:'
      );
      message.writeln('  ${context.widget}');
      final List<Widget> ancestors = <Widget>[];
      context.visitAncestorElements((Element element) {
        ancestors.add(element.widget);
        return true;
      });
      if (ancestors.isNotEmpty) {
        message.write('The ancestors of this widget were:');
        for (Widget ancestor in ancestors)
          message.write('\n  $ancestor');
      } else {
        message.writeln(
          'This widget is the root of the tree, so it has no '
          'ancestors, let alone a "Material" ancestor.'
        );
      }
      throw new FlutterError(message.toString());
    }
    return true;
  }());
  return true;
}
