// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

import 'basic.dart';
import 'framework.dart';

/// A container for grouping together multiple form field widgets (e.g.
/// [Input] widgets).
class Form extends StatefulWidget {
  /// Creates a container for form fields.
  ///
  /// The [child] argument must not be null.
  Form({
    Key key,
    @required this.child,
    this.onSubmitted
  }) : super(key: key) {
    assert(child != null);
  }

  /// Called when the input is accepted anywhere on the form.
  final VoidCallback onSubmitted;

  /// Root of the widget hierarchy that contains this form.
  final Widget child;

  @override
  _FormState createState() => new _FormState();
}

class _FormState extends State<Form> {
  int generation = 0;

  void _onFieldChanged() {
    setState(() {
      ++generation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new FormScope._(
      formState: this,
      generation: generation,
      child: config.child
    );
  }
}

/// Signature for validating a form field.
typedef String FormFieldValidator<T>(T value);

/// Signature for being notified when a form field changes value.
typedef void FormFieldSetter<T>(T newValue);

/// Identifying information for form controls.
class FormField<T> {
  /// Creates identifying information for form controls
  FormField({
    this.setter,
    this.validator
  });

  /// An optional method to call with the new value when the form field changes.
  final FormFieldSetter<T> setter;

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  final FormFieldValidator<T> validator;
}

/// A widget that establishes a scope for a [Form].
///
/// Cannot be created directly. Instead, create a [Form] widget, which builds
/// a [FormScope].
///
/// Useful for locating the closest enclosing [Form].
class FormScope extends InheritedWidget {
  FormScope._({
    Key key,
    Widget child,
    _FormState formState,
    int generation
  }) : _formState = formState,
       _generation = generation,
       super(key: key, child: child);

  final _FormState _formState;

  /// Incremented every time a form field has changed. This lets us know when
  /// to rebuild the form.
  final int _generation;

  /// The [Form] associated with this widget.
  Form get form => _formState.config;

  /// The closest [FormScope] encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// FormScope form = FormScope.of(context);
  /// ```
  static FormScope of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(FormScope);
  }

  /// Use this to notify the Form that a form field has changed. This will
  /// cause all form fields to rebuild, useful if form fields have
  /// interdependencies.
  void onFieldChanged() => _formState._onFieldChanged();

  @override
  bool updateShouldNotify(FormScope old) => _generation != old._generation;
}
