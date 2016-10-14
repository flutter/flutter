// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart';

import 'framework.dart';

/// A container for grouping together multiple form field widgets (e.g.
/// [Input] widgets).
///
/// When one form widget changes value, all the form widgets are rebuilt,
/// giving them an opportunity to rerun any [FormField.validator] callbacks.
class Form extends InheritedWidget {
  /// Creates a container for form fields.
  ///
  /// The [child] argument must not be null.
  Form({
    Key key,
    @required Widget child,
  }) : super(key: key, child: child);

  @override
  bool updateShouldNotify(Form oldWidget) => false;

  /// Registers a form field widget with the nearest enclosing form, if any.
  static void register(BuildContext context) {
    assert(context != null);
    context.inheritFromWidgetOfExactType(Form);
  }

  /// Notifies the form field widgets who have registered with the
  /// nearest enclosing form using [register] that they need to rebuild
  /// to take into account a form field's value having changed.
  ///
  /// If there is no such form, does nothing.
  static void fieldChanged(BuildContext context) {
    assert(context != null);
    InheritedElement form = context.ancestorInheritedElementForWidgetOfExactType(Form);
    form?.dispatchDependenciesChanged();
  }
}

/// Signature for validating a form field.
typedef String FormFieldValidator<T>(T value);

/// The value of a form field.
///
/// When provided to an editable widget (e.g. an [Input]), the editable widget
/// stores the value in the form field so that the parent doesn't have to maintain
/// that state manually.
class FormField<T> extends ChangeNotifier {
  /// Creates a form field value.
  FormField({
    T initialValue,
    this.validator,
  }) : _value = initialValue;

  T get value => _value;
  T _value;
  set value(T newValue) {
    if (newValue == _value)
      return;
    _value = newValue;
    notifyListeners();
  }

  /// An optional method that validates an input. Returns an error string to
  /// display if the input is invalid, or null otherwise.
  final FormFieldValidator<T> validator;
}
