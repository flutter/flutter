// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'framework.dart';
import 'navigator.dart';
import 'will_pop_scope.dart';

/// This is an example class demonstrates what an autofillable form will look
/// like.
class ExampleAutofillForm extends StatefulWidget {
  /// Creates a container for form fields.
  ///
  /// The [child] argument must not be null.
  const ExampleAutofillForm({
    Key key,
    @required this.uniqueIdentifier,
    @required this.child,
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
  static ExampleAutofillFormState of(BuildContext context) {
    final _FormScope scope = context.dependOnInheritedWidgetOfExactType<_FormScope>();
    return scope?._formState;
  }

  /// The widget below this widget in the tree.
  ///
  /// This is the root of the widget hierarchy that contains this form.
  ///
  /// {@macro flutter.widgets.child}
  final Widget child;

  final String uniqueIdentifier;
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
  ExampleAutofillFormState createState() => ExampleAutofillFormState();
}

/// State associated with a [Form] widget.
///
/// A [FormState] object can be used to [save], [reset], and [validate] every
/// [FormField] that is a descendant of the associated [Form].
///
/// Typically obtained via [Form.of].
class ExampleAutofillFormState extends State<ExampleAutofillForm> with AutofillScopeMixin implements AutofillScope {
  int _generation = 0;

  @override
  String get uniqueIdentifier => widget.uniqueIdentifier;

  final Map<String, AutofillClient> _fields = <String, AutofillClient>{};

  // Called when a form field has changed. This will cause all form fields
  // to rebuild, useful if form fields have interdependencies.
  void _fieldDidChange() {
    if (widget.onChanged != null)
      widget.onChanged();
    markNeedsTextInputConfigurationUpdate();
    _forceRebuild();
  }

  void _forceRebuild() {
    setState(() {
      ++_generation;
    });
  }

  void register(AutofillClient client) {
    registerAutofillClient(client);
    final String identifier = client.uniqueIdentifier;
    assert(identifier != null);
    // Remove from and then put back to the Map,
    // because the order of the fields matters to autofill.
    _fields.remove(identifier);
    _fields.putIfAbsent(identifier, () => client);
  }

  void unregister(String identifier) {
    _fields.remove(identifier);
    unregisterAutofillClient(identifier);
  }

  @override
  Widget build(BuildContext context) {
    updateTextInputConfigurationIfNeeded();
    return WillPopScope(
      onWillPop: widget.onWillPop,
      child: _FormScope(
        formState: this,
        generation: _generation,
        child: widget.child,
      ),
    );
  }

  @override
  void markNeedsTextInputConfigurationUpdate() {
    super.markNeedsTextInputConfigurationUpdate();
    setState(() {});
  }
}

class _FormScope extends InheritedWidget {
  const _FormScope({
    Key key,
    Widget child,
    ExampleAutofillFormState formState,
    int generation,
  }) : _formState = formState,
       _generation = generation,
       super(key: key, child: child);

  final ExampleAutofillFormState _formState;

  /// Incremented every time a form field has changed. This lets us know when
  /// to rebuild the form.
  final int _generation;

  /// The [Form] associated with this widget.
  ExampleAutofillForm get form => _formState.widget;

  @override
  bool updateShouldNotify(_FormScope old) => _generation != old._generation;
}

