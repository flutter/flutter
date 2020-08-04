// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';

// TODO(justinmc): Autocomplete should make it easy to do asynchronous searches.
/// A type for autocomplete search functions.
///
/// [AutocompleteController] uses a search function to search through
/// [AutocompleteController.options] and return a subset as results.
typedef AutocompleteSearchFunction<T> = List<T> Function(String query);

/// A type for indicating the selection of an autocomplete result.
typedef OnSelectedAutocomplete<T> = void Function(T result);

/// A builder for the selectable results given the current autocomplete query.
typedef AutocompleteResultsBuilder<T> = Widget Function(
  BuildContext context,
  List<T> results,
  OnSelectedAutocomplete<T> onSelected,
);

/// A builder for the query field in autocomplete.
typedef AutocompleteFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController textEditingController,
);

/// A controller for the [AutocompleteCore] widget.
///
/// Can also be used in a stand-alone manner to implement autocomplete behavior
/// in a fully custom UI.
class AutocompleteController<T> {
  /// Create an instance of AutocompleteController.
  AutocompleteController({
    this.options,
    this.search,
    TextEditingController textEditingController,
  }) : assert(search != null || options != null, "If a search function isn't specified, Autocomplete will search by string on the given options."),
       textEditingController = textEditingController ?? TextEditingController() {
    this.textEditingController.addListener(_onQueryChanged);
  }

  /// All possible options that can be searched.
  ///
  /// If left null, a custom [search] method must be provided that handles the
  /// options to be searched on its own.
  final List<T> options;

  /// The [TextEditingController] that represents the query.
  final TextEditingController textEditingController;

  /// A search function that takes some [options] and returns a subset as
  /// results.
  ///
  /// If [options] is null, then this field must not be null. This may be the
  /// case when querying an external service for search results, for example.
  ///
  /// Defaults to a simple string-matching search of [options].
  final AutocompleteSearchFunction<T> search;

  /// The current results being returned by [search].
  ///
  /// This is a [ValueNotifier] so that UI may be updated when results change.
  final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

  /// Clean up memory created by the AutocompleteController.
  ///
  /// Call this when the AutocompleteController is no longer needed, such as in
  // the dispose method of the widget it was created in.
  void dispose() {
    textEditingController.removeListener(_onQueryChanged);
    // TODO(justinmc): Shouldn't be disposed if it wasn't created here.
    textEditingController.dispose();
  }

  // Called when textEditingController reports a change in its value.
  void _onQueryChanged() {
    final List<T> resultsValue = search == null
        ? _searchByString(textEditingController.value.text)
        : search(textEditingController.value.text);
    assert(resultsValue != null);
    results.value = resultsValue;
  }

  // The default search function, if one wasn't supplied.
  List<T> _searchByString(String query) {
    return options
        .where((T option) => option.toString().contains(query))
        .toList();
  }
}

class AutocompleteCore<T> extends StatefulWidget {
  AutocompleteCore({
    @required this.autocompleteController,
    @required this.buildField,
    @required this.buildResults,
  }) : assert(autocompleteController != null),
       assert(buildField != null),
       assert(buildResults != null);

  final AutocompleteController<T> autocompleteController;
  final AutocompleteFieldBuilder buildField;
  final AutocompleteResultsBuilder<T> buildResults;

  @override
  AutocompleteCoreState<T> createState() =>
      AutocompleteCoreState<T>();
}

class AutocompleteCoreState<T> extends State<AutocompleteCore<T>> {
  T _selection;

  void _onChangeResults() {
    setState(() {});
  }

  void _onChangeQuery() {
    if (widget.autocompleteController.textEditingController.value.text == _selection) {
      return;
    }
    setState(() {
      _selection = null;
    });
  }

  void onSelected (T result) {
    setState(() {
      _selection = result;
      widget.autocompleteController.textEditingController.text = result.toString();
    });
  }

  void _listenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.addListener(_onChangeResults);
    autocompleteController.textEditingController.addListener(_onChangeQuery);
  }

  void _unlistenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.removeListener(_onChangeResults);
    autocompleteController.textEditingController.removeListener(_onChangeQuery);
  }

  @override
  void initState() {
    super.initState();
    _listenToController(widget.autocompleteController);
  }

  @override
  void didUpdateWidget(AutocompleteCore<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autocompleteController != oldWidget.autocompleteController) {
      _unlistenToController(oldWidget.autocompleteController);
      _listenToController(widget.autocompleteController);
    }
  }

  @override
  void dispose() {
    _unlistenToController(widget.autocompleteController);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        widget.buildField(
          context,
          widget.autocompleteController.textEditingController,
        ),
        if (_selection == null)
          // TODO(justinmc): should this expanded be here?
          Expanded(
            child: widget.buildResults(
              context,
              widget.autocompleteController.results.value,
              onSelected,
            ),
          ),
      ],
    );
  }
}
