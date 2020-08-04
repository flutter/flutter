// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';

// TODO(justinmc): Autocomplete should make it easy to do asynchronous searches.
// TODO(justinmc): Rename if we keep this.
typedef List<T> SearchFunction<T>(String query);

// TODO(justinmc): Rename if we keep this?
typedef void OnSelectedAutocomplete<T>(T result);

typedef Widget AutocompleteResultsBuilder<T>(
  BuildContext context,
  List<T> results,
  OnSelectedAutocomplete<T> onSelected,
);

typedef Widget FieldBuilder(
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
  final List<T> options;
  final TextEditingController textEditingController;
  final SearchFunction<T> search;
  final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

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

  void dispose() {
    textEditingController.removeListener(_onQueryChanged);
    textEditingController.dispose();
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
  final FieldBuilder buildField;
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
