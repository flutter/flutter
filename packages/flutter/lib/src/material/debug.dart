// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'material.dart';
import 'material_localizations.dart';
import 'scaffold.dart' show Scaffold;

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
    if (context.widget is! Material && context.findAncestorWidgetOfExactType<Material>() == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No Material widget found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require a Material '
          'widget ancestor.\n'
          'In material design, most widgets are conceptually "printed" on '
          "a sheet of material. In Flutter's material library, that "
          'material is represented by the Material widget. It is the '
          'Material widget that renders ink splashes, for instance. '
          'Because of this, many material library widgets require that '
          'there be a Material widget in the tree above them.'
        ),
        ErrorHint(
          'To introduce a Material widget, you can either directly '
          'include one, or use a widget that contains Material itself, '
          'such as a Card, Dialog, Drawer, or Scaffold.',
        ),
        ...context.describeMissingAncestor(expectedAncestorType: Material)
      ]
      );
    }
    return true;
  }());
  return true;
}


/// Asserts that the given context has a [Localizations] ancestor that contains
/// a [MaterialLocalizations] delegate.
///
/// Used by many material design widgets to make sure that they are
/// only used in contexts where they have access to localizations.
///
/// To call this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasMaterialLocalizations(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasMaterialLocalizations(BuildContext context) {
  assert(() {
    if (Localizations.of<MaterialLocalizations>(context, MaterialLocalizations) == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No MaterialLocalizations found.'),
        ErrorDescription(
          '${context.widget.runtimeType} widgets require MaterialLocalizations '
          'to be provided by a Localizations widget ancestor.'
        ),
        ErrorDescription(
          'The material library uses Localizations to generate messages, '
          'labels, and abbreviations.'
        ),
        ErrorHint(
          'To introduce a MaterialLocalizations, either use a '
          'MaterialApp at the root of your application to include them '
          'automatically, or add a Localization widget with a '
          'MaterialLocalizations delegate.'
        ),
        ...context.describeMissingAncestor(expectedAncestorType: MaterialLocalizations)
      ]);
    }
    return true;
  }());
  return true;
}

/// Asserts that the given context has a [Scaffold] ancestor.
///
/// Used by various widgets to make sure that they are only used in an
/// appropriate context.
///
/// To invoke this function, use the following pattern, typically in the
/// relevant Widget's build method:
///
/// ```dart
/// assert(debugCheckHasScaffold(context));
/// ```
///
/// Does nothing if asserts are disabled. Always returns true.
bool debugCheckHasScaffold(BuildContext context) {
  assert(() {
    if (context.widget is! Scaffold && context.findAncestorWidgetOfExactType<Scaffold>() == null) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('No Scaffold widget found.'),
        ErrorDescription('${context.widget.runtimeType} widgets require a Scaffold widget ancestor.'),
        ...context.describeMissingAncestor(expectedAncestorType: Scaffold),
        ErrorHint(
          'Typically, the Scaffold widget is introduced by the MaterialApp or '
          'WidgetsApp widget at the top of your application widget tree.'
        )
      ]);
    }
    return true;
  }());
  return true;
}
