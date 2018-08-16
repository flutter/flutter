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
///   static MyModel of(BuildContext context, String aspect) {
///     return InheritedModel.inheritFrom<MyModel>(context, aspect: aspect);
///   }
/// }
/// ```
///
/// Calling `MyModel.of(context, 'foo')` means that `context` should only
/// be rebuilt when the `foo` aspect of `MyModel` changes. If the aspect
/// is null, then the the model supports all aspects.
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
///     return return super.updateShouldNotify(old) || a != old.a || b != old.b;
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
///
/// The `super.updateShouldNotify()` call, which is required, will return
/// true if the model's [aspects] have changed. By default the model's
/// [aspects] are null, which means the model supports all aspects.
abstract class InheritedModel<T> extends InheritedWidget {
  /// Creates an inherited widget that supports partial dependencies called "aspects".
  ///
  /// If [aspects] is null (the default) then this model is "universal",
  /// i.e. it supports all aspects.
  const InheritedModel({ Key key, Widget child, this.aspects }) : super(key: key, child: child);

  @override
  InheritedModelElement<T> createElement() => new InheritedModelElement<T>(this);

  /// The features of this model that widgets can depend on with [inheritFrom].
  ///
  /// This property is null by default, which means that the model supports
  /// all aspects.
  final Set<T> aspects;

  @mustCallSuper
  @override
  bool updateShouldNotify(covariant InheritedModel<T> oldWidget) {
    return _notEqual<T>(aspects, oldWidget.aspects);
  }

  /// Return true if the changes between this model and [oldWidget] match any
  /// of the [dependencies].
  @protected
  bool updateShouldNotifyDependent(covariant InheritedModel<T> oldWidget, Set<T> dependencies);

  // The [result] will be a list of all of context's type T ancestors concluding
  // with the one that supports the specified model [aspect].
  static void _findModels<T extends InheritedModel<Object>>(
    BuildContext context,
    Object aspect,
    List<InheritedElement> result,
  ) {
    final InheritedElement model = context.ancestorInheritedElementForWidgetOfExactType(T);
    if (model == null)
      return;

    result.add(model);

    assert(model.widget is T);
    final T modelWidget = model.widget;
    if (aspect == null || modelWidget.aspects == null || modelWidget.aspects.contains(aspect))
      return;

    Element modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    if (modelParent == null)
      return;
    _findModels<T>(modelParent, aspect, result);
  }

  /// Makes [context] dependent on the specified [aspect] of an [InheritedModel]
  /// of type T.
  ///
  /// When the given [aspect] of the model changes, the context will be
  /// rebuilt. The [updateShouldNotifyDependent] method must determine if a
  /// change in the model widget corresponds to an `aspect` value.
  ///
  /// The dependency created by this method targets the first
  /// [InheritedModel] ancestor of type T whose [InheritedModel.aspects] set
  /// is either null (the default) or contains [aspect]. If [aspect] is
  /// null then it's the first ancestor of type T.
  ///
  /// If [aspect] is null this method is the same as
  /// `context.inheritFromWidgetOfExactType(T)`.
  static T inheritFrom<T extends InheritedModel<Object>>(BuildContext context, { Object aspect }) {
    if (aspect == null)
      return context.inheritFromWidgetOfExactType(T);

    // Create a dependency on all of the type T ancestor models up until
    // a model is found whose aspects are null or contain the given aspect.
    // Rebuilding one of the intermediate models only causes its dependents
    // to be rebuilt if its aspects property changes (see _shouldNotify).
    final List<InheritedElement> models = <InheritedElement>[];
    _findModels<T>(context, aspect, models);
    if (models.isEmpty)
      return null;
    final InheritedElement lastModel = models.last;
    for (InheritedElement model in models) {
      final T value = context.inheritFromElement(model, aspect: aspect);
      if (model == lastModel)
        return value;
    }
    assert(false, 'Unreachable');
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
    final Set<T> dependencies = getDependencies(dependent);
    if (dependencies != null && dependencies.isEmpty)
      return;

    if (aspect == null) {
      setDependencies(dependent, new HashSet<T>());
    } else {
      assert(aspect is T);
      setDependencies(dependent, dependencies == null
        ? (new HashSet<T>()..add(aspect))
        : dependencies..add(aspect));
    }
  }

  bool _shouldNotify(InheritedModel<T> oldWidget, Element dependent, Set<T> aspects) {
    // If the aspects the model supports have changed, then rebuild.
    if (_notEqual<T>(widget.aspects, oldWidget.aspects))
      return true;

    // The aspects argument specifies the model aspects that the dependent element depends on.
    if (widget.aspects == null || widget.aspects.any((T aspect) => aspects.contains(aspect)))
      return widget.updateShouldNotifyDependent(oldWidget, aspects);

    return false;
  }

  @override
  void notifyDependent(InheritedModel<T> oldWidget, Element dependent) {
    final Set<T> dependencies = getDependencies(dependent);
    if (dependencies == null)
      return;
    if (dependencies.isEmpty || _shouldNotify(oldWidget, dependent, dependencies))
      dependent.didChangeDependencies();
  }
}

bool _notEqual<T>(Set<T> a, Set<T> b) {
  if (identical(a, b))
    return false;
  if (a?.length != b?.length)
    return true;
  for(T elementA in a) {
    if (!b.contains(elementA))
      return true;
  }
  return false;
}
