// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// An [InheritedWidget] that's intended to be used as the base class for data
/// models which are scoped to a widget tree.
///
/// An inherited widget's dependents are unconditionally rebuilt when the
/// inherited widget changes per [InheritedWidget.updateShouldNotify].
/// Widgets that depend on an [InheritedModel] qualify their dependence
/// with a value that indicates what "aspect" of the model they depend
/// on. When the model is rebuilt, dependents will also be rebuilt, but
/// only if there was a change in the model that corresponds to the aspect
/// they provided.
///
/// The type parameter `T` is the type of the model aspect objects.
///
/// Widgets create a dependency on an [InheritedModel] with a static method:
/// [InheritedModel.inheritFrom]. This method's `context` parameter
/// defines the subtree that will be rebuilt when the model changes.
/// Typically the `inheritFrom` method is called from a model-specific
/// static `of` method. For example:
///
/// ```dart
/// class MyModel extends InheritedModel<String> {
///   // ...
///   static MyModel of(BuildContext context, String dependency) {
///     return InheritedModel.inheritFrom<MyModel>(context, aspect: dependency);
///   }
/// }
/// ```
///
/// Calling `MyModel.of(context, 'foo')` means that `context` should only
/// be rebuilt when the `foo` aspect of `MyModel` changes.
///
/// When the inherited model is rebuilt the [updateShouldNotify] and
/// [updateShouldNotifyDependent] methods are used to decide what
/// should be rebuilt.  If [updateShouldNotify] returns true, then the
/// inherited model's [updateShouldNotifyDependent] method is tested for
/// each dependent and the set of aspect objects it depends on.
/// The [updateShouldNotifyDependent] method must compare the set of aspect
/// dependencies with the changes in the model itself.
///
/// For example:
///
/// ```dart
/// class ABModel extends InheritedModel<String> {
///   ABModel({ this.a, this.b, Widget child }) : super(child: child);
///
///   final int a;
///   final int b;
///
///   @override
///   bool updateShouldNotify(ABCModel old) {
///     return a != old.a || b != old.b;
///   }
///
///   @override
///   bool updateShouldNotifyDependent(ABCModel old, Set<String> dependencies) {
///     return (a != old.a && dependencies.contains('a'))
///         || (b != old.b && dependencies.contains('b'))
///   }
///
///   // ...
/// }
/// ```
///
/// In the previous example the dependencies checked by
/// [updateShouldNotifyDependent] are just the aspect strings passed to
/// `inheritFromWidgetOfExactType`. They're represented as a [Set] because
/// one Widget can depend on more than one aspect of the model.
/// If a widget depends on the model but doesn't specify an aspect,
/// then changes in the model will cause the widget to be rebuilt
/// unconditionally.
abstract class InheritedModel<T> extends InheritedWidget {
  const InheritedModel({ Key key, Widget child }) : super(key: key, child: child);

  @override
  InheritedModelElement<T> createElement() => new InheritedModelElement<T>(this);

  /// Return true if the changes between this model and [oldWidget] match any
  /// of the [dependencies].
  @protected
  bool updateShouldNotifyDependent(
    covariant InheritedModel<T> oldWidget, Set<T> dependencies);

  // Return the first ancestor of context whose widget is type T and for which
  // visitor(widget) returns false. If visitor is null then this function is the
  // same as: context.ancestorInheritedElementForWidgetOfExactType(T).
  static InheritedElement _findModel<T extends InheritedModel<Object>>(
    BuildContext context,
    bool visitor(T widget)
  ) {
    final InheritedElement model = context.ancestorInheritedElementForWidgetOfExactType(T);
    if (model == null)
      return null;

    assert(model.widget is T);
    final T modelWidget = model.widget;
    if (visitor == null || !visitor(modelWidget))
      return model;

    Element modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    if (modelParent == null)
      return null;
    return _findModel<T>(modelParent, visitor);
  }

  /// Makes [context] dependent on the specified [aspect] of an [InheritedModel]
  /// of type T.
  ///
  /// When the given [aspect] of the model changes, the context will be
  /// rebuilt. The [updateShouldNotifyDependent] method must determine if a
  /// change in the model widget corresponds to an `aspect` value.
  ///
  /// By default, the dependency created by this method targets the first
  /// [InheritedModel] ancestor of type T. If [visitor] is specified then
  /// it's the first [InheritedModel] ancestor of type T for which
  /// [vistor] returns false. The vistor parameter can be used to create
  /// models that override some values and delegate the rest to an
  /// ancestor model.
  ///
  /// In the following example the model's static `valueOf` method returns the
  /// first non-null value of `path`. By doing so the caller will have created
  /// a `context` dependency on the first model ancestor that has a non-null
  /// value for the specified path.
  ///
  /// ```dart
  /// class IntegerModel extends InheritedModel<String> {
  ///   // ...
  ///   int valueOf(String path) => _model.valueOf(path);
  ///
  ///   static int valueOf(BuildContext context, String path) {
  ///     int value;
  ///     InheritedModel.inheritFrom<IntegerModel>(context,
  ///       aspect: path,
  ///       visitor: (IntegerModel widget) => (value = widget.valueOf(path)) == null,
  ///     );
  ///     return value;
  ///   }
  /// }
  /// ```
  ///
  /// If [aspect] and [visitor] are null this method is the same as:
  /// `context.inheritFromWidgetOfExactType(T)`.
  static T inheritFrom<T extends InheritedModel<Object>>(
    BuildContext context, {
    Object aspect,
    bool visitor(T widget),
  }) {
    final InheritedElement model = _findModel<T>(context, visitor);
    if (model != null)
      return context.inheritFromWidgetOfExactType(T, aspect: aspect, target: model);
    return null;
  }
}

/// An [Element] that uses a [InheritedModel] as its configuration.
class InheritedModelElement<T> extends InheritedElement {
  /// Creates an element that uses the given widget as its configuration.
  InheritedModelElement(InheritedModel<T> widget) : super(widget);

  @override
  InheritedModel<T> get widget => super.widget;

  @override
  void updateDependencies(Element dependent, Object aspect) {
    final _Dependencies<T> dependencies = getDependencies(dependent);
    if (dependencies != null && dependencies.isGlobal)
      return;

    if (aspect == null) {
      setDependencies(dependent, new _Dependencies<T>(isGlobal: true));
    } else {
      assert(aspect is T);
      setDependencies(dependent, dependencies == null
        ? (new _Dependencies<T>()..add(aspect))
        : dependencies..add(aspect)
      );
    }
  }

  @override
  void notifyDependent(InheritedWidget oldWidget, Element dependent) {
    final _Dependencies<T> dependencies = getDependencies(dependent);
    if (dependencies.isGlobal || widget.updateShouldNotifyDependent(oldWidget, dependencies.values))
      dependent.didChangeDependencies();
  }
}

class _Dependencies<T> extends InheritedDependencies {
  _Dependencies({ this.isGlobal = false });

  @override
  final bool isGlobal;

  final Set<T> values = new HashSet<T>();

  bool contains(T dependency) => values.contains(dependency);

  void add(T dependency) {
    assert(isGlobal);
    values.add(dependency);
  }
}
