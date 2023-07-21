// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'text_form_field.dart';

/// {@macro flutter.widgets.RawAutocomplete.RawAutocomplete}
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=-Nny8kzW380}
///
/// {@tool dartpad}
/// This example shows how to create a very basic Autocomplete widget using the
/// default UI.
///
/// ** See code in examples/api/lib/material/autocomplete/autocomplete.0.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to create an Autocomplete widget with a custom type.
/// Try searching with text from the name or email field.
///
/// ** See code in examples/api/lib/material/autocomplete/autocomplete.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to create an Autocomplete widget whose options are
/// fetched over the network.
///
/// ** See code in examples/api/lib/material/autocomplete/autocomplete.2.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to create an Autocomplete widget whose options are
/// fetched over the network. It uses debouncing to wait to perform the network
/// request until after the user finishes typing.
///
/// ** See code in examples/api/lib/material/autocomplete/autocomplete.3.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows how to create an Autocomplete widget whose options are
/// fetched over the network. It includes both debouncing and error handling, so
/// that failed network requests show an error to the user and can be recovered
/// from. Try toggling the network Switch widget to simulate going offline.
///
/// ** See code in examples/api/lib/material/autocomplete/autocomplete.4.dart **
/// {@end-tool}
///
/// See also:
///
///  * [RawAutocomplete], which is what Autocomplete is built upon, and which
///    contains more detailed examples.
class Autocomplete<T extends Object> extends StatelessWidget {
  /// Creates an instance of [Autocomplete].
  const Autocomplete({
    super.key,
    required this.controller,
    this.fieldViewBuilder = _defaultFieldViewBuilder,
    this.optionsMaxHeight = 200.0,
    required this.optionsViewBuilder,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
    this.initialValue,
  });

  /// The controller.
  final RawAutocompleteController<T> controller;

  /// {@macro flutter.widgets.RawAutocomplete.fieldViewBuilder}
  ///
  /// If not provided, will build a standard Material-style text field by
  /// default.
  final AutocompleteFieldViewBuilder fieldViewBuilder;

  /// {@macro flutter.widgets.RawAutocomplete.optionsViewBuilder}
  final AutocompleteOptionsViewBuilder<T> optionsViewBuilder;

  /// {@macro flutter.widgets.RawAutocomplete.optionsViewOpenDirection}
  final OptionsViewOpenDirection optionsViewOpenDirection;

  /// The maximum height used for the default Material options list widget.
  ///
  /// When [optionsViewBuilder] is `null`, this property sets the maximum height
  /// that the options widget can occupy.
  ///
  /// The default value is set to 200.
  final double optionsMaxHeight;

  /// {@macro flutter.widgets.RawAutocomplete.initialValue}
  final TextEditingValue? initialValue;

  static Widget _defaultFieldViewBuilder(BuildContext context, FocusNode focusNode) {
    return _AutocompleteField(
      focusNode: focusNode,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      controller: controller,
      fieldViewBuilder: fieldViewBuilder,
      optionsViewOpenDirection: optionsViewOpenDirection,
      optionsViewBuilder: optionsViewBuilder,
    );
  }
}

// The default Material-style Autocomplete text field.
class _AutocompleteField extends StatelessWidget {
  const _AutocompleteField({
    required this.focusNode,
  });

  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
    );
  }
}
