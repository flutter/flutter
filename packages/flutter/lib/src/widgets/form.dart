// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'framework.dart';
import 'navigator.dart';
import 'will_pop_scope.dart';

/// An optional container for grouping together multiple form field widgets
/// (e.g. [TextField] widgets).
///
/// Each individual form field should be wrapped in a [FormField] widget, with
/// the [Form] widget as a common ancestor of all of those. Call methods on
/// [FormState] to save, reset, or validate each [FormField] that is a
/// descendant of this [Form]. To obtain the [FormState], you may use [Form.of]
/// with a context whose ancestor is the [Form], or pass a [GlobalKey] to the
/// [Form] constructor and call [GlobalKey.currentState].
class Form extends StatefulWidget {
  /// Creates a container for form fields.
  ///
  /// The [child] argument must not be null.
  const Form({
    Key key,
    @required this.child,
    this.autovalidate = false,
    this.onWillPop,
    this.onChanged,
  }) : assert(child != null),
       super(key: key);

  /// Returns the closest [FormState] which encloses the given context.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// FormState form = Form.of(context);
  /// form.save();
  /// ```
  static FormState of(BuildContext context) {
    final _FormScope scope = context.inheritFromWidgetOfExactType(_FormScope);
    return scope?._formState;
  }

  /// The widget below this widget in the tree.
  ///
  /// This is the root of the widget hierarchy that contains this form.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  /// If true, form fields will validate and update their error text
  /// immediately after every change. Otherwise, you must call
  /// [FormState.validate] to validate.
  final bool autovalidate;

  /// Enables the form to veto attempts by the user to dismiss the [ModalRoute]
  /// that contains the form.
  ///
  /// If the callback returns a Future that resolves to false, the form's route
  /// will not be popped.
  ///
  /// See also:
  ///
  ///  * [WillPopScope], another widget that provides a way to intercept the
  ///    back button.
  final WillPopCallback onWillPop;

  /// Called when one of the form fields changes.
  ///
  /// In addition to this callback being invoked, all the form fields themselves
  /// will rebuild.
  final VoidCallback onChanged;

  @override
  FormState createState() => FormState();
}

/// State associated with a [Form] widget.
///
/// A [FormState] object can be used to [save], [reset], and [validate] every
/// [FormField] that is a descendant of the associated [Form].
///
/// Typically obtained via [Form.of].
class FormState extends State<Form> {
  int _generation = 0;
  final Set<FormFieldState<dynamic>> _fields = Set<FormFieldState<dynamic>>();

  // Called when a form field has changed. This will cause all form fields
  // to rebuild, useful if form fields have interdependencies.
  void _fieldDidChange() {
    if (widget.onChanged != null)
      widget.onChanged();
    _forceRebuild();
  }

  void _forceRebuild() {
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
    if (widget.autovalidate)
      _validate();
    return WillPopScope(
      onWillPop: widget.onWillPop,
      child: _FormScope(
        formState: this,
        generation: _generation,
        child: widget.child,
      ),
    );
  }

  /// Saves every [FormField] that is a descendant of this [Form].
  void save() {
    for (FormFieldState<dynamic> field in _fields)
      field.save();
  }

  /// Resets every [FormField] that is a descendant of this [Form] back to its
  /// [FormField.initialState].
  ///
  /// The [Form.onChanged] callback will be called.
  ///
  /// If the form's [Form.autovalidate] property is true, the fields will all be
  /// revalidated after being reset.
  void reset() {
    for (FormFieldState<dynamic> field in _fields)
      field.reset();
    _fieldDidChange();
  }

  /// Validates every [FormField] that is a descendant of this [Form], and
  /// returns true if there are no errors.
  ///
  /// The form will rebuild to report the results.
  bool validate() {
    _forceRebuild();
    return _validate();
  }

  bool _validate() {
    bool hasError = false;
    for (FormFieldState<dynamic> field in _fields)
      hasError = !field.validate() || hasError;
    return !hasError;
  }
}

class _FormScope extends InheritedWidget {
  const _FormScope({
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
  Form get form => _formState.widget;

  @override
  bool updateShouldNotify(_FormScope old) => _generation != old._generation;
}

/// Signature for validating a form field.
///
/// Used by [FormField.validator].
typedef FormFieldValidator<T> = String Function(T value);

/// Signature for being notified when a form field changes value.
///
/// Used by [FormField.onSaved].
typedef FormFieldSetter<T> = void Function(T newValue);

/// Signature for building the widget representing the form field.
///
/// Used by [FormField.builder].
typedef FormFieldBuilder<T> = Widget Function(FormFieldState<T> field);

/// A single form field.
///
/// This widget maintains the current state of the form field, so that updates
/// and validation errors are visually reflected in the UI.
///
/// When used inside a [Form], you can use methods on [FormState] to query or
/// manipulate the form data as a whole. For example, calling [FormState.save]
/// will invoke each [FormField]'s [onSaved] callback in turn.
///
/// Use a [GlobalKey] with [FormField] if you want to retrieve its current
/// state, for example if you want one form field to depend on another.
///
/// A [Form] ancestor is not required. The [Form] simply makes it easier to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
///
/// See also:
///
///  * [Form], which is the widget that aggregates the form fields.
///  * [TextField], which is a commonly used form field for entering text.
class FormField<T> extends StatefulWidget {
  /// Creates a single form field.
  ///
  /// The [builder] argument must not be null.
  const FormField({
    Key key,
    @required this.builder,
    this.onSaved,
    this.validator,
    this.initialValue,
    this.autovalidate = false,
    this.enabled = true,
  }) : assert(builder != null),
       super(key: key);

  /// An optional method to call with the final value when the form is saved via
  /// [FormState.save].
  final FormFieldSetter<T> onSaved;

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  ///
  /// The returned value is exposed by the [FormFieldState.errorText] property.
  /// The [TextFormField] uses this to override the [InputDecoration.errorText]
  /// value.
  final FormFieldValidator<T> validator;

  /// Function that returns the widget representing this form field. It is
  /// passed the form field state as input, containing the current value and
  /// validation state of this field.
  final FormFieldBuilder<T> builder;

  /// An optional value to initialize the form field to, or null otherwise.
  final T initialValue;

  /// If true, this form field will validate and update its error text
  /// immediately after every change. Otherwise, you must call
  /// [FormFieldState.validate] to validate. If part of a [Form] that
  /// autovalidates, this value will be ignored.
  final bool autovalidate;

  /// Whether the form is able to receive user input.
  ///
  /// Defaults to true. If [autovalidate] is true, the field will be validated.
  /// Likewise, if this field is false, the widget will not be validated
  /// regardless of [autovalidate].
  final bool enabled;

  @override
  FormFieldState<T> createState() => FormFieldState<T>();
}

/// The current state of a [FormField]. Passed to the [FormFieldBuilder] method
/// for use in constructing the form field's widget.
class FormFieldState<T> extends State<FormField<T>> {
  T _value;
  String _errorText;

  /// The current value of the form field.
  T get value => _value;

  /// The current validation error returned by the [FormField.validator]
  /// callback, or null if no errors have been triggered. This only updates when
  /// [validate] is called.
  String get errorText => _errorText;

  /// True if this field has any validation errors.
  bool get hasError => _errorText != null;

  /// Calls the [FormField]'s onSaved method with the current value.
  void save() {
    if (widget.onSaved != null)
      widget.onSaved(value);
  }

  /// Resets the field to its initial value.
  void reset() {
    setState(() {
      _value = widget.initialValue;
      _errorText = null;
    });
  }

  /// Calls [FormField.validator] to set the [errorText]. Returns true if there
  /// were no errors.
  bool validate() {
    setState(() {
      _validate();
    });
    return !hasError;
  }

  bool _validate() {
    if (widget.validator != null)
      _errorText = widget.validator(_value);
    return !hasError;
  }

  /// Updates this field's state to the new value. Useful for responding to
  /// child widget changes, e.g. [Slider]'s [Slider.onChanged] argument.
  ///
  /// Triggers the [Form.onChanged] callback and, if the [Form.autovalidate]
  /// field is set, revalidates all the fields of the form.
  void didChange(T value) {
    setState(() {
      _value = value;
    });
    Form.of(context)?._fieldDidChange();
  }

  /// Sets the value associated with this form field.
  ///
  /// This method should be only be called by subclasses that need to update
  /// the form field value due to state changes identified during the widget
  /// build phase, when calling `setState` is prohibited. In all other cases,
  /// the value should be set by a call to [didChange], which ensures that
  /// `setState` is called.
  @protected
  void setValue(T value) {
    _value = value;
  }

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  void deactivate() {
    Form.of(context)?._unregister(this);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    // Only autovalidate if the widget is also enabled
    if (widget.autovalidate && widget.enabled)
      _validate();
    Form.of(context)?._register(this);
    return widget.builder(this);
  }
}
