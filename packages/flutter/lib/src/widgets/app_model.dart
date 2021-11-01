// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'inherited_model.dart';

/// The type of the [AppModel.getValue] `init` parameter.
///
/// This callback is used to lazily create the initial value for
/// an [AppModel] keyword.
typedef AppModelInitCallback<T> = T Function();

/// Enables sharing key/value data with the all of the widgets below `child`.
///
/// - `AppModel.getValue(context, key, initCallback)` creates a dependency
/// on the key and returns the value for the key from the shared data table.
/// If no value exists for key then the initCallback is used to create
/// the initial value.
///
/// - `AppModel.setValue(context, key, value)` changes the value of an entry
/// in the shared data table and forces widgets that depend on that entry
/// to be rebuilt.
///
/// A widget whose build method uses AppModel.getValue(context, keyword, init)
/// creates a dependency on the AppModel: when the value of keyword
/// changes with AppModel.setValue(), the widget will be rebuilt.
///
/// An instance of this widget is created automatically by [WidgetsApp].
///
/// There are many ways to share data with a widget subtree. This
/// class is based on [InheritedModel], which is an [InheritedWidget].
/// It's intended to be used by packages that need to share a modest
/// number of values among their own components. It obviates the
/// need for package users to instantiate package-specific
/// data sharing "umbrella" widgets.
///
/// AppModel is not intended to be a substitute for Provider or any of
/// the other general purpose application state systems. AppModel is
/// for situations where a package's custom widgets need to share one
/// or a handful of immutable data objects that can be lazily
/// initialized. It exists so that packages like that can deliver
/// custom widgets without requiring the developer to add a
/// package-specific umbrella widget to their application.
///
/// A good way to create an AppModel key that avoids potential
/// collisions with other packages is to use a static `Object()` value.
/// The `SharedObject` example below does this.
///
/// {@tool dartpad}
/// The following sample demonstrates using the automatically created
/// `AppModel`. Button presses cause changes to the values for keys
/// 'foo', and 'bar', and those changes only cause the widgets that
/// depend on those keys to be rebuilt.
///
/// ** See code in examples/api/lib/widgets/app_model/app_model.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// The following sample demonstrates how a single lazily computed
/// value could be shared within an app. A Flutter package that
/// provided custom widgets might use this approach to share a (possibly
/// private) value with instances of those widgets.
///
/// ** See code in examples/api/lib/widgets/app_model/app_model.1.dart **
/// {@end-tool}
class AppModel extends StatefulWidget {
  /// Creates a widget based on [InheritedModel] that supports build
  /// dependencies qualified by keywords. Descendant widgets create
  /// such dependencies with [AppModel.getValue] and they trigger
  /// rebuilds with [AppModel.setValue].
  ///
  /// This widget is automatically created by the [WidgetsApp].
  const AppModel({ Key? key, required this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<StatefulWidget> createState() => _AppModelState();

  /// Returns the app model's value for `key` and ensures that each
  /// time the value of `key` is changed with [AppModel.setValue], the
  /// specified context will be rebuilt.
  ///
  /// If no value for `key` then the `init` callback is used to generate
  /// an initial value.
  ///
  /// A Widget that depends on the app model's value for `key` should use
  /// this method in their `build` methods to ensure that they are rebuilt
  /// if the value changes.
  ///
  /// The type parameter `K` is the type of the keyword and `V`
  /// is the type of the value.
  static V getValue<K extends Object, V>(BuildContext context, K key, AppModelInitCallback<V> init) {
    final _AppModelData? model = InheritedModel.inheritFrom<_AppModelData>(context, aspect: key);
    assert(_debugHasAppModel(model, context, 'getValue'));
    return model!.appModelState.getValue<K, V>(key, init);
  }

  /// Changes the app model's `value` for `key` and rebuilds any widgets
  /// that have created a dependency on `key` with [AppModel.getValue].
  ///
  /// If `value` is `==` to the current value of `key` then nothing
  /// is rebuilt.
  ///
  /// Unlike [AppModel.getValue], this method does _not_ create a dependency
  /// between `context` and `key`.
  ///
  /// The type parameter `K` is the type of the value's keyword and `V`
  /// is the type of the value.
  static void setValue<K extends Object, V>(BuildContext context, K key, V value) {
    final _AppModelData? model = context.getElementForInheritedWidgetOfExactType<_AppModelData>()?.widget as _AppModelData?;
    assert(_debugHasAppModel(model, context, 'setValue'));
    model!.appModelState.setValue<K, V>(key, value);
  }

  static bool _debugHasAppModel(_AppModelData? model, BuildContext context, String methodName) {
    assert(() {
      if (model == null) {
        throw FlutterError.fromParts(
          <DiagnosticsNode>[
            ErrorSummary('No AppModel widget found.'),
            ErrorDescription('AppModel.$methodName requires an AppModel widget ancestor.\n'),
            context.describeWidget('The specific widget that could not find an AppModel ancestor was'),
            context.describeOwnershipChain('The ownership chain for the affected widget is'),
            ErrorHint(
              'Typically, the AppModel widget is introduced by the MaterialApp '
              'or WidgetsApp widget at the top of your application widget tree. It '
              'provides a key/value map of data that is shared with the entire '
              'application.',
            ),
          ],
        );
      }
      return true;
    }());
    return true;
  }
}

class _AppModelState extends State<AppModel> {
  late Map<Object, Object?> data = <Object, Object?>{};

  @override
  Widget build(BuildContext context) {
    return _AppModelData(appModelState: this, child: widget.child);
  }

  V getValue<K extends Object, V>(K key, AppModelInitCallback<V> init) {
    data[key] ??= init();
    return data[key] as V;
  }

  void setValue<K extends Object, V>(K key, V value) {
    if (data[key] != value) {
      setState(() {
        data = Map<Object, Object?>.from(data);
        data[key] = value;
      });
    }
  }
}

class _AppModelData extends InheritedModel<Object> {
  _AppModelData({
    Key? key,
    required this.appModelState,
    required Widget child
  }) : data = appModelState.data, super(key: key, child: child);

  final _AppModelState appModelState;
  final Map<Object, Object?> data;

  @override
  bool updateShouldNotify(_AppModelData old) {
    return data != old.data;
  }

  @override
  bool updateShouldNotifyDependent(_AppModelData old, Set<Object> keys) {
    for (final Object key in keys) {
      if (data[key] != old.data[key]) {
        return true;
      }
    }
    return false;
  }
}
