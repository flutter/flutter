// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// An inherited widget to manage shared state for its descendants.
///
/// This can be used for managing state when multiple widgets need their state
/// to be kept in sync. It is most useful when the closest common widget to the
/// widgets that need to share the state is several levels above the widgets
/// that are using it. When the state is close to the widgets using them, it is
/// often preferable to pass the needed state to the descendants that need it
/// directly instead of using this widget.
///
/// For complex applications, it may be more appropriate to use a package that
/// provides more features and a stream-oriented paradigm like Rx.
///
/// This widget doesn't keep the state itself, it uses the state passed in. It
/// calls the [valueChanged] callback when the state changes. You should then
/// pass the updated state to this widget on the next build as the [value].
///
/// When the shared state's [value] is updated, all of the widgets that depend
/// upon it will be rebuilt.
///
/// ## Sample code
///
/// ```dart
/// enum Thing {
///   raindrops,
///   whiskers,
///   kettles,
///   mittens,
///   kittens,
///   packages,
///   string,
/// }
/// 
/// class FavoritePage extends StatefulWidget {
///   const FavoritePage({Key key}) : super(key: key);
/// 
///   @override
///   _FavoritePageState createState() => new _FavoritePageState();
/// }
/// 
/// class _FavoritePageState extends State<FavoritePage> {
///   Thing _favoriteThing;
/// 
///   @override
///   Widget build(BuildContext context) {
///     return new SharedState<Thing>(
///       value: _favoriteThing,
///       valueChanged: (Thing thing) {
///         if (_favoriteThing != thing) {
///           setState(() {
///             _favoriteThing = thing;
///           });
///         }
///       },
///       // For this example, assume we don't wish to, or can't, pass
///       // _favoriteThing to FavoriteView.
///       child: const FavoriteView(),
///     );
///   }
/// }
/// 
/// class FavoriteView extends StatelessWidget {
///   const FavoriteView();
/// 
///   @override
///   Widget build(BuildContext context) {
///    return new ListView(
///       children: Thing.values.map<Widget>((Thing thing) {
///         return FavoriteTile(thing);
///       }).toList(),
///     );
///   }
/// }
/// 
/// class FavoriteTile extends StatelessWidget {
///   const FavoriteTile(this.thing);
/// 
///   final Thing thing;
/// 
///   @override
///   Widget build(BuildContext context) {
///     final Thing favoriteThing = SharedState.get<Thing>(context);
///     final bool isSelected = favoriteThing == thing;
///     return ListTile(
///       leading: new IconButton(
///         icon: new Icon(isSelected ? Icons.favorite : Icons.favorite_border),
///         onPressed: () {
///           SharedState.set<Thing>(context, isSelected ? null : thing);
///         },
///       ),
///       title: new Text(describeEnum(thing)),
///     );
///   }
/// }
/// ```
class SharedState<T> extends InheritedWidget {
  /// Creates a [SharedState].
  ///
  /// The `child` and `valueChanged` arguments are required and must not be null.
  const SharedState({
    Key key,
    this.value,
    @required this.valueChanged,
    @required Widget child,
  })  : assert(valueChanged != null),
        assert(child != null),
        super(key: key, child: child);

  /// The value of the shared state.
  final T value;

  /// The [ValueChanged] callback that is called when the shared state is
  /// changed.
  final ValueChanged<T> valueChanged;

  static SharedState<T> _getScope<T>(BuildContext context) {
    assert(context != null);
    final SharedState<T> controllerScope = context.inheritFromWidgetOfExactType(
      // TODO(gspencer): Remove ignore when https://github.com/dart-lang/sdk/issues/33289 is fixed.
      // ignore: prefer_const_constructors
      new TypeMatcher<SharedState<T>>().type,
    );
    return controllerScope;
  }

  /// Get the shared state of the nearest enclosing [SharedState] widget of the
  /// same type in the widget tree.
  static U get<U>(BuildContext context, {bool nullOk: false}) {
    final SharedState<U> controllerScope = _getScope(context);
    if (controllerScope != null) {
      return controllerScope.value;
    }
    if (nullOk) {
      return null;
    }
    throw new FlutterError('SharedState<$U>.get() called with a context that does not '
        'contain a SharedState of the right type.\n'
        'No SharedState ancestor could be found starting from the context that was passed '
        'to SharedState<$U>.get(). This can happen if you have not inserted a '
        'SharedState widget, or if the context you use comes from a widget above the '
        'SharedState widget.\n'
        'The context used was:\n'
        '  $context');
  }

  /// Sets the shared state, possibly scheduling a rebuild of the descendants
  /// that depend upon it.
  static void set<U>(BuildContext context, U newValue) {
    final SharedState<U> controllerScope = _getScope(context);
    assert(() {
      if (controllerScope == null) {
        throw new FlutterError('SharedState<$U>.set() called with a context that does '
            'not contain a SharedState of the right type.\n'
            'No SharedState ancestor could be found starting from the context that was passed '
            'to SharedState<$U>.set(). This can happen if you have not inserted a '
            'SharedState widget, or if the context you use comes from a widget above the '
            'SharedState widget.\n'
            'The context used was:\n'
            '  $context');
      }
      return controllerScope != null;
    }());
    if (controllerScope != null && newValue != controllerScope.value) {
      controllerScope.valueChanged(newValue);
    }
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    assert(runtimeType == oldWidget.runtimeType);
    final SharedState<T> oldSharedState = oldWidget;
    return value != oldSharedState.value;
  }
}