// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'list_tile.dart';
import 'material.dart';
import 'text_form_field.dart';

// TODO(justinmc): Document.
class Autocomplete<T extends Object> extends StatefulWidget {
  /// Creates an instance of [Autocomplete].
  const Autocomplete({
    Key? key,
    required this.optionsBuilder,
    this.displayStringForOption = RawAutocomplete.defaultStringForOption,
    this.onSelected,
  }) : assert(displayStringForOption != null),
       assert(optionsBuilder != null),
       super(key: key);

  /// {@macro flutter.widgets.RawAutocomplete.displayStringForOption}
  final AutocompleteOptionToString<T> displayStringForOption;

  /// {@macro flutter.widgets.RawAutocomplete.onSelected}
  final AutocompleteOnSelected<T>? onSelected;

  /// {@macro flutter.widgets.RawAutocomplete.optionsBuilder}
  final AutocompleteOptionsBuilder<T> optionsBuilder;

  @override
  _AutocompleteState<T> createState() => _AutocompleteState<T>();
}

class _AutocompleteState<T extends Object> extends State<Autocomplete<T>> {
  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<T>(
      displayStringForOption: widget.displayStringForOption,
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
        return _AutocompleteField(
          focusNode: focusNode,
          textEditingController: textEditingController,
          onFieldSubmitted: onFieldSubmitted,
        );
      },
      optionsBuilder: widget.optionsBuilder,
      optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<T> onSelected, Iterable<T> options) {
        return _AutocompleteResults<T>(
          displayStringForOption: widget.displayStringForOption,
          onSelected: onSelected,
          options: options,
          //textEditingController: textEditingController,
        );
      },
      onSelected: widget.onSelected,
    );
  }
}

// The default Material-style Autocomplete text field.
class _AutocompleteField extends StatelessWidget {
  const _AutocompleteField({
    Key? key,
    required this.focusNode,
    required this.textEditingController,
    required this.onFieldSubmitted,
  }) : super(key: key);

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

// The default Material-style Autocomplete results.
class _AutocompleteResults<T extends Object> extends StatelessWidget {
  const _AutocompleteResults({
    Key? key,
    required this.displayStringForOption,
    required this.onSelected,
    required this.options,
    //required this.textEditingController,
  }) : super(key: key);

  final AutocompleteOptionToString<T> displayStringForOption;

  final AutocompleteOnSelected<T> onSelected;

  final Iterable<T> options;

  //final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Material(
        elevation: 4.0,
        child: Container(
          height: 200.0,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: options.length,
            itemBuilder: (BuildContext context, int index) {
              final T option = options.elementAt(index);
              return GestureDetector(
                onTap: () {
                  onSelected(option);
                },
                child: ListTile(
                  title: Text(displayStringForOption(option)),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
