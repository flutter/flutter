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
///
/// {@tool dartpad --template=freeform}
/// This example shows how to build an autocomplete widget with your own UI
/// using AutocompleteController. Most typical use cases would instead pass the
/// AutocompleteController directly to [Autocomplete] or
/// [AutocompleteCupertino].
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart
/// class CustomUIAutocomplete extends StatefulWidget {
///   CustomUIAutocomplete({Key key}) : super(key: key);
///
///   @override
///   CustomUIAutocompleteState createState() => CustomUIAutocompleteState();
/// }
///
/// class CustomUIAutocompleteState extends State<CustomUIAutocomplete> {
///   AutocompleteController<String> _autocompleteController;
///   String _selection;
///
///   void _onChangeResults() {
///     setState(() {});
///   }
///
///   void _onChangeQuery() {
///     if (_autocompleteController.textEditingController.value.text != _selection) {
///       setState(() {
///         _selection = null;
///       });
///     }
///   }
///
///   @override
///   void initState() {
///     super.initState();
///     _autocompleteController = AutocompleteController<String>(
///       options: <String>['aardvark', 'baboon', 'chameleon'],
///     );
///     _autocompleteController.textEditingController.addListener(_onChangeQuery);
///     _autocompleteController.results.addListener(_onChangeResults);
///   }
///
///   @override
///   void dispose() {
///     _autocompleteController.textEditingController.removeListener(_onChangeQuery);
///     _autocompleteController.results.removeListener(_onChangeResults);
///     _autocompleteController.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: <Widget>[
///         // Query field.
///         TextFormField(
///           controller: _autocompleteController.textEditingController,
///         ),
///         // Results list.
///         if (_selection == null)
///           Expanded(
///             child: ListView(
///               children: _autocompleteController.results.value.map((String result) => GestureDetector(
///                 onTap: () {
///                   setState(() {
///                     _selection = result;
///                     _autocompleteController.textEditingController.text = result;
///                   });
///                 },
///                 child: ListTile(
///                   title: Text(result),
///                 ),
///               )).toList(),
///             ),
///           ),
///       ],
///     );
///   }
/// }
/// ```
/// {@end-tool}
@immutable
class AutocompleteController<T> {
  /// Create an instance of AutocompleteController.
  AutocompleteController({
    this.options,
    this.search,
    TextEditingController textEditingController,
  }) : assert(search != null || options != null, 'Must specify either options or search (or both).'),
       _ownsTextEditingController = textEditingController == null,
       textEditingController = textEditingController ?? TextEditingController() {
    this.textEditingController.addListener(_onQueryChanged);
  }

  final bool _ownsTextEditingController;

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
  /// This is a [ValueNotifier], so it can be listened to for changes.
  final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

  /// Clean up memory created by the AutocompleteController.
  ///
  /// Call this when the AutocompleteController is no longer needed, such as in
  // the dispose method of the widget it was created in.
  void dispose() {
    textEditingController.removeListener(_onQueryChanged);
    if (_ownsTextEditingController) {
      textEditingController.dispose();
    }
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

/// A widget for helping the user to search a list of options and select a
/// result.
///
/// This is a core framework widget with very basic UI. Try using [Autocomplete]
/// or [AutocompleteCupertino] before resorting to this widget.
///
/// {@tool dartpad --template=stateless_widget_scaffold}
/// This example shows how to create a very basic autocomplete widget using the
/// [buildField] and [buildResults] parameters.
///
/// ```dart
/// final AutocompleteController _autocompleteController =
///     AutocompleteController(
///       options: <String>['aardvark', 'baboon', 'chameleon'],
///     );
///
/// Widget build(BuildContext context) {
///   return AutocompleteCore(
///     autocompleteController: _autocompleteController,
///     buildField: (BuildContext context, TextEditingController textEditingController) {
///       return TextFormField(
///         controller: textEditingController,
///       );
///     },
///     buildResults: (BuildContext context, List<String> results, OnSelectedAutocomplete<String> onSelected) {
///       return ListView(
///         children: results.map((String result) => GestureDetector(
///           onTap: () {
///             onSelected(result);
///           },
///           child: ListTile(
///             title: Text(result),
///           ),
///         )).toList(),
///       );
///     },
///   );
/// }
/// ```
///
/// {@end-tool}
/// {@tool dartpad --template=freeform}
/// This example is similar to the previous example, but it uses a custom T data
/// type instead of directly using String.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart
/// class User {
///   const User({
///     this.email,
///     this.name,
///   });
///
///   final String email;
///   final String name;
///
///   // When using a default search function, the query will be matched
///   // directly with the output of this toString method. In this case,
///   // including both the email and name allows the user to search by both.
///   // If you wanted even more advanced search logic, you could pass a custom
///   // search function into AutocompleteController.
///   @override
///   String toString() {
///     return '$name, $email';
///   }
/// }
///
/// class AutocompleteCoreExample extends StatelessWidget {
///   AutocompleteCoreExample({Key key}) : super(key: key);
///   final AutocompleteController<User> _autocompleteController = AutocompleteController<User>(
///     options: <User>[
///       User(name: 'Alice', email: 'alice@example.com'),
///       User(name: 'Bob', email: 'bob@example.com'),
///       User(name: 'Charlie', email: 'charlie123@gmail.com'),
///     ],
///   );
///
///   @override
///   Widget build(BuildContext context) {
///     return Material(
///       home: Scaffold(
///         appBar: AppBar(
///           title: Text('AutocompleteCore Example'),
///         ),
///         body: Center(
///           child: AutocompleteCore<User>(
///             autocompleteController: _autocompleteController,
///             buildField: (BuildContext context, TextEditingController textEditingController) {
///               return TextFormField(
///                 controller: textEditingController,
///               );
///             },
///             buildResults: (BuildContext context, List<User> results, OnSelectedAutocomplete<User> onSelected) {
///               return ListView(
///                 children: results.map((User result) => GestureDetector(
///                   onTap: () {
///                     onSelected(result);
///                   },
///                   child: ListTile(
///                     // Despite allowing search on both name and email, here
///                     // only name is displayed in the results.
///                     title: Text(result.name),
///                   ),
///                 )).toList(),
///               );
///             },
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
class AutocompleteCore<T> extends StatefulWidget {
  /// Create an instance of AutocompleteCore.
  ///
  /// [autocompleteController], [buildField], and [buildResults] must not be
  /// null.
  const AutocompleteCore({
    @required this.autocompleteController,
    @required this.buildField,
    @required this.buildResults,
  }) : assert(autocompleteController != null),
       assert(buildField != null),
       assert(buildResults != null);

  /// The controller that provides access to the main autocomplete state and
  /// logic.
  final AutocompleteController<T> autocompleteController;

  /// Builds the field that is used to input the query.
  final AutocompleteFieldBuilder buildField;

  /// Builds the selectable results of searching.
  final AutocompleteResultsBuilder<T> buildResults;

  @override
  _AutocompleteCoreState<T> createState() =>
      _AutocompleteCoreState<T>();
}

class _AutocompleteCoreState<T> extends State<AutocompleteCore<T>> {
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

  void _onSelected (T result) {
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
              _onSelected,
            ),
          ),
      ],
    );
  }
}
