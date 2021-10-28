// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'framework.dart';
import 'inherited_model.dart';

/// Enables sharing key/value data with the all of the widgets below `child`.
///
/// - `AppModel.setValue(context, key, value)` changes the value of an entry
/// in the shared data table and forces widgets that depend on that entry
/// to be rebuilt.
///
/// - `AppModel.getValue(context, key)` creates a dependency on the key and
/// returns the value for the key from the shared data table.
///
/// - `AppModel.initValue(context, key, value)` changes the value of an entry
/// in the shared data table but does not force dependent widgets to be
/// rebuilt.
///
/// A widget whose build method uses AppModel.getValue(context, keyword)
/// creates a dependency on the AppModel: when the value of keyword
/// changes with AppModel.setValue(), the widget will be rebuilt.
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
  /// If no value for `key` is found then null is returned.
  ///
  /// A Widget that depends on the app model's value for `key` should use
  /// this method in their `build` methods to ensure that they are rebuilt
  /// if the value changes.
  ///
  /// The type parameter `K` is the type of the value's keyword and `V`
  /// is the type of the value. The value type is nullable, for example
  /// `AppModel.getValue<String, String>(key,value)` means that the key parameter
  /// must non-null but the value parameter can be null or a string.
  static V? getValue<K extends Object, V>(BuildContext context, K key) {
    final _AppModelData? model = InheritedModel.inheritFrom<_AppModelData>(context, aspect: key);
    assert(_debugHasAppModel(model, context, 'getValue'));
    return model!.appModelState.getValue<K, V>(key);
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
  /// is the type of the value. The value type is nullable, for example
  /// `AppModel.setValue<String, String>(key,value)` means that the key parameter
  /// must non-null but the value parameter can be null or a string.
  static void setValue<K extends Object, V>(BuildContext context, K key, V? value) {
    final _AppModelData? model = context.findAncestorWidgetOfExactType<_AppModelData>();
    assert(_debugHasAppModel(model, context, 'setValue'));
    model!.appModelState.setValue<K, V>(key, value);
  }

  /// Unconditionally changes the app model's `value` for `key`.
  ///
  /// This method should be used to lazily initialize a value that's
  /// needed at build time, when rebuilding dependent widgets isn't
  /// allowed or necessary. The `SharedObject` example above
  /// demonstrates this.
  ///
  /// Unlike [AppModel.setValue], this method does _not_ cause dependent widgets
  /// to be rebuilt.
  ///
  /// The type parameter `K` is the type of the value's keyword and `V`
  /// is the type of the value. The value type is nullable, for example
  /// `AppModel.initValue<String, String>(key,value)` means that the key parameter
  /// must non-null but the value parameter can be null or a string.
  static void initValue<K extends Object, V>(BuildContext context, K key, V? value) {
    final _AppModelData? model = context.findAncestorWidgetOfExactType<_AppModelData>();
    assert(_debugHasAppModel(model, context, 'initValue'));
    model!.appModelState.initValue<K, V>(key, value);
  }

  static bool _debugHasAppModel(_AppModelData? model, BuildContext context, String methodName) {
    assert(() {
      if (model != null)
        return true;
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

  V? getValue<K extends Object, V>(K key) => data[key] as V?;

  void setValue<K extends Object, V>(K key, V? value) {
    if (data[key] != value) {
      setState(() {
        data = Map<Object, Object?>.from(data);
        data[key] = value;
      });
    }
  }

  void initValue<K extends Object, V>(K key, V? value) {
    data = Map<Object, Object?>.from(data);
    data[key] = value;
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
