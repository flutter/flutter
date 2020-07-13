// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// An [InheritedWidget] that defines visual properties like colors
/// and text styles, which the [child]'s subtree depends on.
///
/// The [wrap] method is used by [captureAll] to construct a widget
/// that will wrap a child in all of the inherited themes which
/// are present in a build context but are not present in the
/// context that the returned widget is eventually built in.
///
/// A widget that's shown in a different context from the one it's
/// built in, like the contents of a new route or an overlay, will
/// be able to depend on inherited widget ancestors of the context
/// it's built in.
///
/// {@tool dartpad --template=freeform}
/// This example demonstrates how `InheritedTheme.captureAll()` can be used
/// to wrap the contents of a new route with the inherited themes that
/// are present when the route is built - but are not present when route
/// is actually shown.
///
/// If the same code is run without `InheritedTheme.captureAll(), the
/// new route's Text widget will inherit the "something must be wrong"
/// fallback text style, rather than the default text style defined in MyApp.
///
/// ```dart imports
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart main
/// void main() {
///   runApp(MyApp());
/// }
/// ```
///
/// ```dart
/// class MyAppBody extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return GestureDetector(
///       onTap: () {
///         Navigator.of(context).push(
///           MaterialPageRoute(
///             builder: (BuildContext _) {
///               // InheritedTheme.captureAll() saves references to themes that
///               // are found above the context provided to this widget's build
///               // method, notably the DefaultTextStyle defined in MyApp. The
///               // context passed to the MaterialPageRoute's builder is not used,
///               // because its ancestors are above MyApp's home.
///               return InheritedTheme.captureAll(context, Container(
///                 alignment: Alignment.center,
///                 color: Theme.of(context).colorScheme.surface,
///                 child: Text('Hello World'),
///               ));
///             },
///           ),
///         );
///       },
///       child: Center(child: Text('Tap Here')),
///     );
///   }
/// }
///
/// class MyApp extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         // Override the DefaultTextStyle defined by the Scaffold.
///         // Descendant widgets will inherit this big blue text style.
///         body: DefaultTextStyle(
///           style: TextStyle(fontSize: 48, color: Colors.blue),
///           child: MyAppBody(),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
abstract class InheritedTheme extends InheritedWidget {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.

  const InheritedTheme({
    Key key,
    @required Widget child,
  }) : super(key: key, child: child);

  /// Return a copy of this inherited theme with the specified [child].
  ///
  /// If the identical inherited theme is already visible from [context] then
  /// just return the [child].
  ///
  /// This implementation for [TooltipTheme] is typical:
  /// ```dart
  /// Widget wrap(BuildContext context, Widget child) {
  ///   final TooltipTheme ancestorTheme = context.findAncestorWidgetOfExactType<TooltipTheme>());
  ///   return identical(this, ancestorTheme) ? child : TooltipTheme(data: data, child: child);
  /// }
  /// ```
  Widget wrap(BuildContext context, Widget child);

  /// Returns a widget that will [wrap] child in all of the inherited themes
  /// which are visible from [context].
  static Widget captureAll(BuildContext context, Widget child) {
    assert(child != null);
    assert(context != null);

    final List<InheritedTheme> themes = <InheritedTheme>[];
    final Set<Type> themeTypes = <Type>{};
    context.visitAncestorElements((Element ancestor) {
      if (ancestor is InheritedElement && ancestor.widget is InheritedTheme) {
        final InheritedTheme theme = ancestor.widget as InheritedTheme;
        final Type themeType = theme.runtimeType;
        // Only remember the first theme of any type. This assumes
        // that inherited themes completely shadow ancestors of the
        // same type.
        if (!themeTypes.contains(themeType)) {
          themeTypes.add(themeType);
          themes.add(theme);
        }
      }
      return true;
    });

    return _CaptureAll(themes: themes, child: child);
  }
}

class _CaptureAll extends StatelessWidget {
  const _CaptureAll({
    Key key,
    @required this.themes,
    @required this.child,
  }) : assert(themes != null), assert(child != null), super(key: key);

  final List<InheritedTheme> themes;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;
    for (final InheritedTheme theme in themes)
      wrappedChild = theme.wrap(context, wrappedChild);
    return wrappedChild;
  }
}
