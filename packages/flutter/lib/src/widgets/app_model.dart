// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'inherited_model.dart';

/// Enables sharing key/value data with the all of the widgets below [child].
///
/// `AppModel.set(context, key, value)` adds an entry to the shared data table.
///
/// `AppModel.get(context, key)` returns the value for key from the
/// shared data table, or null if there is no table entry for the key.
///
/// A widget whose build method uses AppModel.get(context, keyword)
/// creates a dependency on the AppModel: when the value of keyword
/// changes with AppModel.set(), the widget will be rebuilt.
///
/// An instance of this widget is created automatically by [WidgetsApp].
///
/// There are many ways to share data with a widget subtree. This
/// class is based on [InheritedModel], which is an [InheritedWidget].
/// It's intended to be used by packages that need to share a modest
/// number of values among their own components. It obviates the
/// need for app developers to instantiate a package-specific
/// data sharing "umbrella" widgets to enable the use of such
/// packages.
///
/// {@tool dartpad}
/// The following sample demonstrates using the automatically created
/// `AppModel`. Button presses cause changes to the values for keys
/// 'foo', and 'bar', and that only causes the widgets that depend on
/// those keys to be rebuilt.
///
/// ** See code in examples/api/lib/widgets/app_model/app_model.0.dart **
/// {@end-tool}
class AppModel extends StatefulWidget {
  /// Creates a widget based on [InheritedModel] that supports build
  /// dependencies qualified by keywords. Descendant widgets create
  /// such dependencies with [AppModel.get] and they trigger
  /// rebuilds with [AppModel.set].
  ///
  /// This widget is automatically created by the [WidgetsApp].
  const AppModel({ Key? key, required this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<StatefulWidget> createState() => _AppModelState();

  /// Returns the app model's value for [key] and ensures that each
  /// time the value of [key] is changed with [AppModel.set], the
  /// specified context will be rebuilt.
  ///
  /// If no value for [key] is found then null is returned.
  ///
  /// A Widget that depends on the app model's value for [key] should use this method
  /// in their `build` methods to ensure that they are rebuilt if the value
  /// changes.
  static V? get<K extends Object, V>(BuildContext context, K key) {
    final _AppModelData model = InheritedModel.inheritFrom<_AppModelData>(context, aspect: key)!;
    return model.appModelState.get<K, V>(key);
  }

  /// Changes the app model's [value] for [key] and rebuilds any widgets
  /// that have created a dependency on [key] with [AppModel.get].
  ///
  /// If [value] is `==` to the current value of [key] then nothing
  /// is rebuilt.
  ///
  /// Unlike [AppModel.get], this method does _not_ create a dependency
  /// between [context] and [key].
  static void set<K extends Object, V>(BuildContext context, K key, V? value) {
    final _AppModelData model = context.findAncestorWidgetOfExactType<_AppModelData>()!;
    model.appModelState.set<K, V>(key, value);
  }
}

class _AppModelState extends State<AppModel> {
  late Map<Object, Object?> data;

  @override
  void initState() {
    super.initState();
    data = <Object, Object?>{};
  }

  @override
  Widget build(BuildContext context) {
    return _AppModelData(appModelState: this, child: widget.child);
  }

  V? get<K extends Object, V>(K key) => data[key] as V?;

  void set<K extends Object, V>(K key, V? value) {
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
