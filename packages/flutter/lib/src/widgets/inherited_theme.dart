// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';

/// An [InheritedWidget] that defines visual properties like colors
/// and text styles, which the [child]'s subtree depends on.
///
/// The [wrap] method is used by [captureAll] and [CapturedThemes.wrap] to
/// construct a widget that will wrap a child in all of the inherited themes
/// which are present in a specified part of the widget tree.
///
/// A widget that's shown in a different context from the one it's built in,
/// like the contents of a new route or an overlay, will be able to see the
/// ancestor inherited themes of the context it was built in.
///
/// {@tool dartpad --template=freeform}
/// This example demonstrates how `InheritedTheme.capture()` can be used
/// to wrap the contents of a new route with the inherited themes that
/// are present when the route was built - but are not present when route
/// is actually shown.
///
/// If the same code is run without `InheritedTheme.capture(), the
/// new route's Text widget will inherit the "something must be wrong"
/// fallback text style, rather than the default text style defined in MyApp.
///
/// ```dart imports
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart main
/// void main() {
///   runApp(const MyApp());
/// }
/// ```
///
/// ```dart
/// class MyAppBody extends StatelessWidget {
///   const MyAppBody({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     final NavigatorState navigator = Navigator.of(context);
///     // This InheritedTheme.capture() saves references to themes that are
///     // found above the context provided to this widget's build method
///     // excluding themes are are found above the navigator. Those themes do
///     // not have to be captured, because they will already be visible from
///     // the new route pushed onto said navigator.
///     // Themes are captured outside of the route's builder because when the
///     // builder executes, the context may not be valid anymore.
///     final CapturedThemes themes = InheritedTheme.capture(from: context, to: navigator.context);
///     return GestureDetector(
///       onTap: () {
///         Navigator.of(context).push(
///           MaterialPageRoute<void>(
///             builder: (BuildContext _) {
///               // Wrap the actual child of the route in the previously
///               // captured themes.
///               return themes.wrap(
///                 Container(
///                   alignment: Alignment.center,
///                   color: Colors.white,
///                   child: const Text('Hello World'),
///                 ),
///               );
///             },
///           ),
///         );
///       },
///       child: const Center(child: Text('Tap Here')),
///     );
///   }
/// }
///
/// class MyApp extends StatelessWidget {
///   const MyApp({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return const MaterialApp(
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
    Key? key,
    required Widget child,
  }) : super(key: key, child: child);

  /// Return a copy of this inherited theme with the specified [child].
  ///
  /// This implementation for [TooltipTheme] is typical:
  ///
  /// ```dart
  /// Widget wrap(BuildContext context, Widget child) {
  ///   return TooltipTheme(data: data, child: child);
  /// }
  /// ```
  Widget wrap(BuildContext context, Widget child);

  /// Returns a widget that will [wrap] `child` in all of the inherited themes
  /// which are present between `context` and the specified `to`
  /// [BuildContext].
  ///
  /// The `to` context must be an ancestor of `context`. If `to` is not
  /// specified, all inherited themes up to the root of the widget tree are
  /// captured.
  ///
  /// After calling this method, the themes present between `context` and `to`
  /// are frozen for the provided `child`. If the themes (or their theme data)
  /// change in the original subtree, those changes will not be visible to
  /// the wrapped `child` - unless this method is called again to re-wrap the
  /// child.
  static Widget captureAll(BuildContext context, Widget child, {BuildContext? to}) {
    assert(child != null);
    assert(context != null);

    return capture(from: context, to: to).wrap(child);
  }

  /// Returns a [CapturedThemes] object that includes all the [InheritedTheme]s
  /// between the given `from` and `to` [BuildContext]s.
  ///
  /// The `to` context must be an ancestor of the `from` context. If `to` is
  /// null, all ancestor inherited themes of `from` up to the root of the
  /// widget tree are captured.
  ///
  /// After calling this method, the themes present between `from` and `to` are
  /// frozen in the returned [CapturedThemes] object. If the themes (or their
  /// theme data) change in the original subtree, those changes will not be
  /// applied to the themes captured in the [CapturedThemes] object - unless
  /// this method is called again to re-capture the updated themes.
  ///
  /// To wrap a [Widget] in the captured themes, call [CapturedThemes.wrap].
  static CapturedThemes capture({ required BuildContext from, required BuildContext? to }) {
    assert(from != null);

    if (from == to) {
      // Nothing to capture.
      return CapturedThemes._(const <InheritedTheme>[]);
    }

    final List<InheritedTheme> themes = <InheritedTheme>[];
    final Set<Type> themeTypes = <Type>{};
    late bool debugDidFindAncestor;
    assert(() {
      debugDidFindAncestor = to == null;
      return true;
    }());
    from.visitAncestorElements((Element ancestor) {
      if (ancestor == to) {
        assert(() {
          debugDidFindAncestor = true;
          return true;
        }());
        return false;
      }
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

    assert(debugDidFindAncestor, 'The provided `to` context must be an ancestor of the `from` context.');
    return CapturedThemes._(themes);
  }
}

/// Stores a list of captured [InheritedTheme]s that can be wrapped around a
/// child [Widget].
///
/// Used as return type by [InheritedTheme.capture].
class CapturedThemes {
  CapturedThemes._(this._themes);

  final List<InheritedTheme> _themes;

  /// Wraps a `child` [Widget] in the [InheritedTheme]s captured in this object.
  Widget wrap(Widget child) {
    return _CaptureAll(themes: _themes, child: child);
  }
}

class _CaptureAll extends StatelessWidget {
  const _CaptureAll({
    Key? key,
    required this.themes,
    required this.child,
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
