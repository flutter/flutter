// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'framework.dart';

/// An [InheritedWidget] that's intended to be used as the base class for
/// models whose dependents may only depend on one part or "aspect" of the
/// overall model.
///
/// An inherited widget's dependents are unconditionally rebuilt when the
/// inherited widget changes per [InheritedWidget.updateShouldNotify].
/// This widget is similar except that dependents aren't rebuilt
/// unconditionally.
///
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
/// is null, then the model supports all aspects.
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
///   bool updateShouldNotify(ABModel old) {
///     return a != old.a || b != old.b;
///   }
///
///   @override
///   bool updateShouldNotifyDependent(ABModel old, Set<String> aspects) {
///     return (a != old.a && aspects.contains('a'))
///         || (b != old.b && aspects.contains('b'))
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
/// See also:
///
///  * [InheritedWidget], an inherited widget that only notifies dependents
///    when its value is different.
///  * [InheritedNotifier], an inherited widget whose value can be a
///    [Listenable], and which will notify dependents whenever the value
///    sends notifications.
abstract class InheritedModel<T> extends InheritedWidget {
  /// Creates an inherited widget that supports dependencies qualified by
  /// "aspects", i.e. a descendant widget can indicate that it should
  /// only be rebuilt if a specific aspect of the model changes.
  const InheritedModel({ Key key, Widget child }) : super(key: key, child: child);

  @override
  InheritedModelElement<T> createElement() => InheritedModelElement<T>(this);

  /// Return true if the changes between this model and [oldWidget] match any
  /// of the [dependencies].
  @protected
  bool updateShouldNotifyDependent(covariant InheritedModel<T> oldWidget, Set<T> dependencies);

  /// Returns true if this model supports the given [aspect].
  ///
  /// Returns true by default: this model supports all aspects.
  ///
  /// Subclasses may override this method to indicate that they do not support
  /// all model aspects. This is typically done when a model can be used
  /// to "shadow" some aspects of an ancestor.
  @protected
  bool isSupportedAspect(Object aspect) => true;

  // The [result] will be a list of all of context's type T ancestors concluding
  // with the one that supports the specified model [aspect].
  static Iterable<InheritedElement> _findModels<T extends InheritedModel<Object>>(BuildContext context, Object aspect) sync* {
    final InheritedElement model = context.ancestorInheritedElementForWidgetOfExactType(T);
    if (model == null)
      return;

    yield model;

    assert(model.widget is T);
    final T modelWidget = model.widget;
    if (modelWidget.isSupportedAspect(aspect))
      return;

    Element modelParent;
    model.visitAncestorElements((Element ancestor) {
      modelParent = ancestor;
      return false;
    });
    if (modelParent == null)
      return;

    yield* _findModels<T>(modelParent, aspect);
  }

  /// Makes [context] dependent on the specified [aspect] of an [InheritedModel]
  /// of type T.
  ///
  /// When the given [aspect] of the model changes, the [context] will be
  /// rebuilt. The [updateShouldNotifyDependent] method must determine if a
  /// change in the model widget corresponds to an [aspect] value.
  ///
  /// The dependencies created by this method target all [InheritedModel] ancestors
  /// of type T up to and including the first one for which [isSupportedAspect]
  /// returns true.
  ///
  /// If [aspect] is null this method is the same as
  /// `context.inheritFromWidgetOfExactType(T)`.
  static T inheritFrom<T extends InheritedModel<Object>>(BuildContext context, { Object aspect }) {
    if (aspect == null)
      return context.inheritFromWidgetOfExactType(T);

    // Create a dependency on all of the type T ancestor models up until
    // a model is found for which isSupportedAspect(aspect) is true.
    final List<InheritedElement> models = _findModels<T>(context, aspect).toList();
    final InheritedElement lastModel = models.last;
    for (InheritedElement model in models) {
      final T value = context.inheritFromElement(model, aspect: aspect);
      if (model == lastModel)
        return value;
    }

    assert(false);
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
      setDependencies(dependent, HashSet<T>());
    } else {
      assert(aspect is T);
      setDependencies(dependent, (dependencies ?? HashSet<T>())..add(aspect));
    }
  }

  @override
  void notifyDependent(InheritedModel<T> oldWidget, Element dependent) {
    final Set<T> dependencies = getDependencies(dependent);
    if (dependencies == null)
      return;
    if (dependencies.isEmpty || widget.updateShouldNotifyDependent(oldWidget, dependencies))
      dependent.didChangeDependencies();
  }
}
