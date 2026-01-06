// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'text_theme.dart';
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'dropdown_menu.dart';
import 'input_decorator.dart';
import 'menu_style.dart';

/// A [FormField] that contains a [DropdownMenu].
///
/// This is a convenience widget that wraps a [DropdownMenu] widget in a
/// [FormField].
///
/// A [Form] ancestor is not required. The [Form] allows one to
/// save, reset, or validate multiple fields at once. To use without a [Form],
/// pass a [GlobalKey] to the constructor and use [GlobalKey.currentState] to
/// save or reset the form field.
///
/// The `value` parameter maps to [FormField.initialValue].
///
/// See also:
///
///  * [DropdownMenu], which is the underlying text field without the [Form]
///    integration.
class DropdownMenuFormField<T extends Object> extends FormField<T> {
  /// Creates a [DropdownMenu] widget that is a [FormField].
  ///
  /// For a description of the `onSaved`, `validator`, or `autovalidateMode`
  /// parameters, see [FormField]. For the rest, see [DropdownMenu].
  DropdownMenuFormField({
    super.key,
    bool enabled = true,
    double? width,
    double? menuHeight,
    Widget? leadingIcon,
    Widget? trailingIcon,
    Widget? label,
    String? hintText,
    String? helperText,
    Widget? selectedTrailingIcon,
    bool enableFilter = false,
    bool enableSearch = true,
    TextInputType? keyboardType,
    TextStyle? textStyle,
    TextAlign textAlign = TextAlign.start,
    // TODO(bleroux): Clean this up once `InputDecorationTheme` is fully normalized.
    Object? inputDecorationTheme,
    DropdownMenuDecorationBuilder? decorationBuilder,
    MenuStyle? menuStyle,
    this.controller,
    T? initialSelection,
    this.onSelected,
    FocusNode? focusNode,
    bool? requestFocusOnTap,
    EdgeInsetsGeometry? expandedInsets,
    Offset? alignmentOffset,
    FilterCallback<T>? filterCallback,
    SearchCallback<T>? searchCallback,
    required this.dropdownMenuEntries,
    List<TextInputFormatter>? inputFormatters,
    DropdownMenuCloseBehavior closeBehavior = DropdownMenuCloseBehavior.all,
    int maxLines = 1,
    TextInputAction? textInputAction,
    super.restorationId,
    super.onSaved,
    AutovalidateMode autovalidateMode = AutovalidateMode.disabled,
    super.validator,
    super.forceErrorText,
    super.errorBuilder,
  }) : super(
         initialValue: initialSelection,
         autovalidateMode: autovalidateMode,
         builder: (FormFieldState<T> field) {
           final state = field as _DropdownMenuFormFieldState<T>;

           InputDecoration effectiveDecorationBuilder(
             BuildContext context,
             MenuController menuController,
           ) {
             final InputDecoration decoration =
                 decorationBuilder?.call(context, menuController) ?? const InputDecoration();
             final InputDecoration decorationWithLabels = decoration.copyWith(
               label: label,
               hintText: hintText,
               helperText: helperText,
             );

             final String? errorText = state.errorText;
             if (errorText == null) {
               return decorationWithLabels;
             }

             return errorBuilder != null
                 ? decorationWithLabels.copyWith(error: errorBuilder(state.context, errorText))
                 : decorationWithLabels.copyWith(errorText: errorText);
           }

           return UnmanagedRestorationScope(
             bucket: field.bucket,
             child: DropdownMenu<T>(
               restorationId: restorationId,
               enabled: enabled,
               width: width,
               menuHeight: menuHeight,
               leadingIcon: leadingIcon,
               trailingIcon: trailingIcon,
               selectedTrailingIcon: selectedTrailingIcon,
               enableFilter: enableFilter,
               enableSearch: enableSearch,
               keyboardType: keyboardType,
               textStyle: textStyle,
               textAlign: textAlign,
               inputDecorationTheme: inputDecorationTheme,
               decorationBuilder: effectiveDecorationBuilder,
               menuStyle: menuStyle,
               controller: state.textFieldController,
               initialSelection: state.value,
               onSelected: field.didChange,
               focusNode: focusNode,
               requestFocusOnTap: requestFocusOnTap,
               expandedInsets: expandedInsets,
               alignmentOffset: alignmentOffset,
               filterCallback: filterCallback,
               searchCallback: searchCallback,
               inputFormatters: inputFormatters,
               closeBehavior: closeBehavior,
               dropdownMenuEntries: dropdownMenuEntries,
               maxLines: maxLines,
               textInputAction: textInputAction,
             ),
           );
         },
       );

  /// The callback is called when a selection is made.
  ///
  /// The callback receives the selected entry's value of type `T` when the user
  /// chooses an item. It may also be invoked with `null` to indicate that the
  /// selection was cleared / that no item was chosen.
  ///
  /// Defaults to null. If this callback itself is null, the widget still updates
  /// the text field with the selected label.
  final ValueChanged<T?>? onSelected;

  /// Controls the text being edited.
  ///
  /// If null, this widget will create its own [TextEditingController].
  final TextEditingController? controller;

  /// Descriptions of the menu items in the [DropdownMenuFormField].
  ///
  /// This is a required parameter. It is recommended that at least one [DropdownMenuEntry]
  /// is provided. If this is an empty list, the menu will be empty and only
  /// contain space for padding.
  final List<DropdownMenuEntry<T>> dropdownMenuEntries;

  @override
  FormFieldState<T> createState() => _DropdownMenuFormFieldState<T>();
}

class _DropdownMenuFormFieldState<T extends Object> extends FormFieldState<T> {
  DropdownMenuFormField<T> get _dropdownMenuFormField => widget as DropdownMenuFormField<T>;

  // The controller used to restore the selected item.
  RestorableTextEditingController? _restorableController;

  // The controller used to reset the content of the DropdownMenu inner TextField.
  TextEditingController? _localTextFieldController;
  TextEditingController get textFieldController =>
      _dropdownMenuFormField.controller ?? (_localTextFieldController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _createRestorableController(widget.initialValue);
  }

  void _createRestorableController(T? initialValue) {
    assert(_restorableController == null);
    _restorableController = RestorableTextEditingController.fromValue(
      TextEditingValue(text: _findLabelByValue(initialValue)),
    );
    if (!restorePending) {
      _registerRestorableController();
    }
  }

  @override
  void didUpdateWidget(DropdownMenuFormField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue && !hasInteractedByUser) {
      setValue(widget.initialValue);
    }
    if (oldWidget.controller != _dropdownMenuFormField.controller) {
      _localTextFieldController?.dispose();
      _localTextFieldController = null;
    }
  }

  @override
  void dispose() {
    _restorableController?.dispose();
    _localTextFieldController?.dispose();
    super.dispose();
  }

  @override
  void didChange(T? value) {
    super.didChange(value);
    _dropdownMenuFormField.onSelected?.call(value);
    _updateRestorableController(value);
  }

  @override
  void reset() {
    super.reset();
    _dropdownMenuFormField.onSelected?.call(value);
    _updateRestorableController(widget.initialValue);
    if (widget.initialValue == null) {
      textFieldController.clear();
    }
  }

  void _updateRestorableController(T? value) {
    if (_restorableController != null) {
      _restorableController!.value.value = TextEditingValue(text: _findLabelByValue(value));
    }
  }

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    super.restoreState(oldBucket, initialRestore);
    if (_restorableController != null) {
      _registerRestorableController();
      // Make sure to update the internal [DropdownMenuFieldState] value to sync up with
      // text editing controller value if it matches one of the item label.
      final T? matchingValue = _findValueByLabel(_restorableController!.value.text);
      if (matchingValue != null) {
        setValue(matchingValue);
      }
    }
  }

  void _registerRestorableController() {
    assert(_restorableController != null);
    registerForRestoration(_restorableController!, 'controller');
  }

  T? _findValueByLabel(String label) {
    for (final DropdownMenuEntry<T> entry in _dropdownMenuFormField.dropdownMenuEntries) {
      if (entry.label == label) {
        return entry.value;
      }
    }
    return null;
  }

  String _findLabelByValue(T? value) {
    for (final DropdownMenuEntry<T> entry in _dropdownMenuFormField.dropdownMenuEntries) {
      if (entry.value == value) {
        return entry.label;
      }
    }
    return '';
  }
}
