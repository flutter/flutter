// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'basic.dart';
import 'framework.dart';

/// A container for grouping together multiple form field widgets (e.g. Input).
class Form extends StatefulWidget {
  Form({
    Key key,
    this.child,
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

  void onFieldChanged() {
    setState(() {
      ++generation;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new FormScope(
      state: this,
      generation: generation,
      child: config.child
    );
  }
}

typedef String FormFieldValidator<T>(T value);
typedef void FormFieldSetter<T>(T newValue);

/// This contains identifying information for Input fields, required if the
/// Input is part of a Form.
class FormField<T> {
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

/// The root of all Forms. Used by form field widgets (e.g. Input) to
/// communicate changes back to the client.
class FormScope extends InheritedWidget {
  FormScope({
    Key key,
    Widget child,
    _FormState state,
    int generation
  }) : _state = state,
       _generation = generation,
       super(key: key, child: child);

  final _FormState _state;

  /// Incremented every time a form field has changed. This lets us know when
  /// to rebuild the form.
  final int _generation;

  /// The Form this widget belongs to.
  Form get form => _state.config;

  /// Finds the FormScope that encloses the widget being built from the given
  /// context.
  static FormScope of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(FormScope);
  }

  /// Use this to notify the Form that a form field has changed. This will
  /// cause all form fields to rebuild, useful if form fields have
  /// interdependencies.
  void onFieldChanged() => _state.onFieldChanged();

  @override
  bool updateShouldNotify(FormScope old) => _generation != old._generation;
}
