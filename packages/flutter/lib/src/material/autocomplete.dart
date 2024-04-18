// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'ink_well.dart';
import 'material.dart';
import 'text_form_field.dart';
import 'theme.dart';

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
    required this.optionsBuilder,
    this.displayStringForOption = RawAutocomplete.defaultStringForOption,
    this.fieldViewBuilder = _defaultFieldViewBuilder,
    this.focusNode,
    this.onSelected,
    this.textEditingController,
    this.optionsMaxHeight = 200.0,
    this.optionsViewBuilder,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
    this.initialValue,
  }) : assert(
         fieldViewBuilder != null
            || (key != null && focusNode != null && textEditingController != null),
         'Pass in a fieldViewBuilder, or otherwise create a separate field and pass in the FocusNode, TextEditingController, and a key. Use the key with RawAutocomplete.onFieldSubmitted.',
        ),
       assert((focusNode == null) == (textEditingController == null)),
       assert(
         !(textEditingController != null && initialValue != null),
         'textEditingController and initialValue cannot be simultaneously defined.',
       );

  /// The [FocusNode] that is used for the text field.
  ///
  /// {@template flutter.widgets.RawAutocomplete.split}
  /// The main purpose of this parameter is to allow the use of a separate text
  /// field located in another part of the widget tree instead of the text
  /// field built by [fieldViewBuilder]. For example, it may be desirable to
  /// place the text field in the AppBar and the options below in the main body.
  ///
  /// When following this pattern, [fieldViewBuilder] can be omitted,
  /// so that a text field is not drawn where it would normally be.
  /// A separate text field can be created elsewhere, and a
  /// FocusNode and TextEditingController can be passed both to that text field
  /// and to RawAutocomplete.
  ///
  /// {@tool dartpad}
  /// This examples shows how to create an autocomplete widget with the text
  /// field in the AppBar and the results in the main body of the app.
  ///
  /// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.focus_node.0.dart **
  /// {@end-tool}
  /// {@endtemplate}
  ///
  /// If this parameter is not null, then [textEditingController] must also be
  /// not null.
  final FocusNode? focusNode;

  /// {@macro flutter.widgets.RawAutocomplete.displayStringForOption}
  final AutocompleteOptionToString<T> displayStringForOption;

  /// {@macro flutter.widgets.RawAutocomplete.fieldViewBuilder}
  ///
  /// If not provided, will build a standard Material-style text field by
  /// default.
  final AutocompleteFieldViewBuilder fieldViewBuilder;

  /// {@macro flutter.widgets.RawAutocomplete.onSelected}
  final AutocompleteOnSelected<T>? onSelected;

  /// {@macro flutter.widgets.RawAutocomplete.optionsBuilder}
  final AutocompleteOptionsBuilder<T> optionsBuilder;

  /// The [TextEditingController] that is used for the text field.
  ///
  /// {@macro flutter.widgets.RawAutocomplete.split}
  ///
  /// If this parameter is not null, then [focusNode] must also be not null.
  final TextEditingController? textEditingController;

  /// {@macro flutter.widgets.RawAutocomplete.optionsViewBuilder}
  ///
  /// If not provided, will build a standard Material-style list of results by
  /// default.
  final AutocompleteOptionsViewBuilder<T>? optionsViewBuilder;

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

  static Widget _defaultFieldViewBuilder(BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
    return _AutocompleteField(
      focusNode: focusNode,
      textEditingController: textEditingController,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      displayStringForOption: displayStringForOption,
      fieldViewBuilder: fieldViewBuilder,
      initialValue: initialValue,
      optionsBuilder: optionsBuilder,
      optionsViewOpenDirection: optionsViewOpenDirection,
      optionsViewBuilder: optionsViewBuilder ?? (BuildContext context, AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
        return _AutocompleteOptions<T>(
          displayStringForOption: displayStringForOption,
          onSelected: onSelected,
          options: options,
          openDirection: optionsViewOpenDirection,
          maxOptionsHeight: optionsMaxHeight,
        );
      },
      focusNode: focusNode,
      onSelected: onSelected,
      textEditingController: textEditingController,
    );
  }
}

// The default Material-style Autocomplete text field.
class _AutocompleteField extends StatelessWidget {
  const _AutocompleteField({
    required this.focusNode,
    required this.textEditingController,
    required this.onFieldSubmitted,
  });

  final FocusNode focusNode;

  final VoidCallback onFieldSubmitted;

  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: textEditingController,
      focusNode: focusNode,
      onFieldSubmitted: (String value) {
        onFieldSubmitted();
      },
    );
  }
}

// The default Material-style Autocomplete options.
class _AutocompleteOptions<T extends Object> extends StatelessWidget {
  const _AutocompleteOptions({
    super.key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.openDirection,
    required this.options,
    required this.maxOptionsHeight,
  });

  final AutocompleteOptionToString<T> displayStringForOption;

  final AutocompleteOnSelected<T> onSelected;
  final OptionsViewOpenDirection openDirection;

  final Iterable<T> options;
  final double maxOptionsHeight;

  @override
  Widget build(BuildContext context) {
    final AlignmentDirectional optionsAlignment = switch (openDirection) {
      OptionsViewOpenDirection.up => AlignmentDirectional.bottomStart,
      OptionsViewOpenDirection.down => AlignmentDirectional.topStart,
    };
    return Align(
      alignment: optionsAlignment,
      child: Material(
        elevation: 4.0,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxOptionsHeight),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final T option = options.elementAt(index);
              return InkWell(
                onTap: () {
                  onSelected(option);
                },
                child: Builder(
                  builder: (BuildContext context) {
                    final bool highlight = AutocompleteHighlightedOption.of(context) == index;
                    if (highlight) {
                      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
                        Scrollable.ensureVisible(context, alignment: 0.5);
                      }, debugLabel: 'AutocompleteOptions.ensureVisible');
                    }
                    return Container(
                      color: highlight ? Theme.of(context).focusColor : null,
                      padding: const EdgeInsets.all(16.0),
                      child: Text(displayStringForOption(option)),
                    );
                  }
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
