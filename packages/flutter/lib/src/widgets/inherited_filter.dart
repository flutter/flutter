// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/material.dart';
library;

import 'package:collection/collection.dart';

import 'framework.dart';

export 'package:collection/collection.dart' show Equality;

/// An object that specifies an [Equality].
///
/// If a selector for an [InheritedFilter] implements this interface,
/// its equality is used in place of the inherited filter's default
/// to determine whether rebuilding takes place.
abstract interface class EqualityFilter {
  /// The [Equality] to use when using this equality filter
  /// to compare two values.
  Equality<Object?>? get equality;
}

/// An `InheritedWidget` that notifies dependents based on their [Selector]s
/// and a configurable [Equality] relationship.
///
/// {@template flutter.widgets.InheritedFilter}
/// Classes that extend [InheritedWidget] / [InheritedModel] compare
/// the current widget's fields to the fields from the `oldWidget`, via
/// [InheritedWidget.updateShouldNotify] / [InheritedModel.updateShouldNotifyDependent]
/// respectively.
///
/// Conversely, [InheritedFilter] uses **selectors**: dependents are notified
/// when the widget is rebuilt, unless [InheritedFilter.select] outputs a value
/// equal to the previous one.
///
/// (For more detailed information, see [InheritedFilter.select].)
/// {@endtemplate}
///
/// {@tool snippet}
/// ## `.of(context)` method
///
/// To depend on an [InheritedFilter] widget, pass the selector as the `aspect`
/// in [BuildContext.dependOnInheritedWidgetOfExactType], and then use it in a
/// [InheritedFilter.select] call.
///
/// ```dart
/// typedef LabelSelector = String Function(Map<String, dynamic> json);
///
/// class MyLabel extends InheritedFilter<LabelSelector> {
///   const MyLabel({
///     super.key,
///     required this.json,
///     required super.child,
///   });
///
///   final Map<String, dynamic> json;
///
///   static String of(BuildContext context, LabelSelector selector) {
///     final MyLabel label = context.dependOnInheritedWidgetOfExactType<MyLabel>(aspect: selector)!;
///     return label.select(selector);
///   }
///
///   @override
///   String select(LabelSelector selector) => selector(json);
/// }
/// ```
/// {@end-tool}
abstract class InheritedFilter<Selector> extends ProxyWidget implements InheritedWidget, EqualityFilter {
  /// Creates an `InheritedWidget` that notifies dependents
  /// based on their [Selector]s.
  const InheritedFilter({super.key, required super.child});

  /// [InheritedFilter] subclasses override this method so that dependents
  /// are notified when there's a change to the output of any of their [Selector]s.
  ///
  /// {@tool snippet}
  /// Often, the [selector] is a [Function], and [select] just returns its output.
  /// Example:
  ///
  /// ```dart
  /// typedef LabelSelector = String Function(Map<String, dynamic> json);
  ///
  /// class MyLabel extends InheritedFilter<LabelSelector> {
  ///   const MyLabel({
  ///     super.key,
  ///     required this.json,
  ///     required super.child,
  ///   });
  ///
  ///   final Map<String, dynamic> json;
  ///
  ///   static String of(BuildContext context, LabelSelector selector) {
  ///     final MyLabel label = context.dependOnInheritedWidgetOfExactType<MyLabel>(aspect: selector)!;
  ///     return label.select(selector);
  ///   }
  ///
  ///   @override
  ///   String select(LabelSelector selector) => selector(json);
  /// }
  /// ```
  /// {@end-tool}
  ///
  /// There are a few ways for the [InheritedFilter.select] method to engender
  /// useful equality checks, so dependents are notified to rebuild only when
  /// there's a relevant change:
  ///
  ///  1. Return a `const` value, such as [Brightness.dark],
  ///     [MouseCursor.defer], or `const SawTooth(3)`.
  ///  2. Return an object that supports stable equality checks, e.g.
  ///     an instance of [num], [EdgeInsets], [TextStyle], or [BoxDecoration].
  ///     A custom class declaration can be set up the same way, by overriding
  ///     the [Object.operator==] and [Object.hashCode] fields. Alternatively,
  ///     [Record] types support stable equality without additional setup.
  ///  3. Override the [EqualityFilter.equality] getter to define a custom
  ///     relationship, such as [MapEquality] or [CaseInsensitiveEquality].
  ///     This can be done with the [InheritedFilter] class, or alternatively,
  ///     any selector object that implements the [EqualityFilter] interface
  ///     can individually customize the [Equality] relationship for its results.
  //
  // TODO(nate-thegrate): example app!
  Object? select(Selector selector);

  /// Compares the result of [select] with the previous result to determine
  /// whether the dependent should rebuild.
  ///
  /// The default implementation, [DefaultEquality], uses the existing
  /// [Object.operator==] to determine equality.
  @override
  Equality<Object?> get equality => const DefaultEquality<Object?>();

  /// Throws an [UnsupportedError] when called.
  ///
  /// Whether an update to this widget should notify dependents
  /// is determined by evaluating [select], and comparing the result with
  /// its evaluation against the previous widget based on the configured
  /// [equality] relationship.
  @override
  bool updateShouldNotify(Widget oldWidget) {
    throw UnsupportedError(
      'The updateShouldNotify() method is required by the InheritedWidget interface, '
      'but is not used for InheritedFilter objects.',
    );
  }

  @override
  InheritedFilterElement<Selector> createElement() => InheritedFilterElement<Selector>(this);
}
