// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

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
  }) : super(key: key) {
    assert(child != null);
  }

  /// Root of the widget hierarchy that contains this form.
  final Widget child;

  @override
  FormState createState() => new FormState();
}

class FormState extends State<Form> {
  int _generation = 0;
  Set<FormFieldState<dynamic>> _fields = new Set<FormFieldState<dynamic>>();

  /// Called when a form field has changed. This will cause all form fields
  /// to rebuild, useful if form fields have interdependencies.
  void _fieldDidChange() {
    setState(() {
      ++_generation;
    });
  }

  void _register(FormFieldState<dynamic> field) {
    _fields.add(field);
  }

  void _unregister(FormFieldState<dynamic> field) {
    _fields.remove(field);
  }

  @override
  Widget build(BuildContext context) {
    return new _FormScope(
      formState: this,
      generation: _generation,
      child: config.child
    );
  }

  /// Saves every FormField that is a descendant of this Form.
  void save() {
    for (FormFieldState<dynamic> field in _fields)
      field.save();
  }

  /// Resets every FormField that is a descendant of this Form back to its
  /// initialState.
  void reset() {
    for (FormFieldState<dynamic> field in _fields)
      field.reset();
    _fieldDidChange();
  }

  /// Returns true if any descendant FormField has an error, false otherwise.
  bool get hasErrors {
    for (FormFieldState<dynamic> field in _fields) {
      if (field.hasError)
        return true;
    }
    return false;
  }
}

class _FormScope extends InheritedWidget {
  _FormScope({
    Key key,
    Widget child,
    FormState formState,
    int generation
  }) : _formState = formState,
       _generation = generation,
       super(key: key, child: child);

  final FormState _formState;

  /// Incremented every time a form field has changed. This lets us know when
  /// to rebuild the form.
  final int _generation;

  /// The [Form] associated with this widget.
  Form get form => _formState.config;

  /// The closest [_FormScope] which encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// _FormScope form = _FormScope.of(context);
  /// ```
  static _FormScope of(BuildContext context) {
    return context.inheritFromWidgetOfExactType(_FormScope);
  }

  @override
  bool updateShouldNotify(_FormScope old) => _generation != old._generation;
}

/// Signature for validating a form field.
typedef String FormFieldValidator<T>(T value);

/// Signature for being notified when a form field changes value.
typedef void FormFieldSetter<T>(T newValue);

/// Signature for building the widget representing the form field.
typedef Widget FormFieldBuilder<T>(FormFieldState<T> field);

/// A single form field. This widget maintains the current state of the form
/// field, so that updates and validation errors are visually reflected in the
/// UI.
///
/// When used inside a [Form], you can use methods on [FormState] to query or
/// manipulate the form data as a whole. For example, calling [FormState.save]
/// will invoke each [FormField]'s [onSaved] callback in turn.
///
/// Use a [GlobalKey] with [FormField] if you want to retrieve its current
/// state, for example if you want one form field to depend on another.
///
/// See also: [Form], [InputFormField]
class FormField<T> extends StatefulWidget {
  FormField({
    Key key,
    @required this.builder,
    this.onSaved,
    this.validator,
    this.initialValue,
  }) : super(key: key) {
    assert(builder != null);
  }

  /// An optional method to call with the final value when the form is saved via
  /// Form.save().
  final FormFieldSetter<T> onSaved;

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  final FormFieldValidator<T> validator;

  /// Function that returns the widget representing this form field. It is
  /// passed the form field state as input, containing the current value and
  /// validation state of this field.
  final FormFieldBuilder<T> builder;

  /// An optional value to initialize the form field to, or null otherwise.
  final T initialValue;

  @override
  FormFieldState<T> createState() => new FormFieldState<T>();
}

class FormFieldState<T> extends State<FormField<T>> {
  T _value;
  String _errorText;

  /// The current value of the form field.
  T get value => _value;

  /// The current validation error returned by [FormField]'s [validator]
  /// callback, or null if no errors.
  String get errorText => _errorText;

  /// True if this field has any validation errors.
  bool get hasError => _errorText != null;

  /// Calls the [FormField]'s onSaved method with the current value.
  void save() {
    if (config.onSaved != null)
      config.onSaved(value);
  }

  /// Resets the field to its initial value.
  void reset() {
    setState(() {
      _value = config.initialValue;
      _errorText = null;
    });
  }

  /// Updates this field's state to the new value. Useful for responding to
  /// child widget changes, e.g. [Slider]'s onChanged argument.
  void onChanged(T value) {
    setState(() {
      _value = value;
    });
    _FormScope.of(context)?._formState?._fieldDidChange();
  }

  @override
  void initState() {
    super.initState();
    _value = config.initialValue;
  }

  @override
  void deactivate() {
    _FormScope formScope = _FormScope.of(context);
    if (formScope != null)
      formScope._formState._unregister(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (config.validator != null)
      _errorText = config.validator(_value);

    _FormScope.of(context)?._formState?._register(this);
    return config.builder(this);
  }
}
