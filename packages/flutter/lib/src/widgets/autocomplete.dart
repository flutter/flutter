// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/foundation.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';

/// A type for autocomplete filter functions.
///
/// [AutocompleteController] uses a filter function to filter
/// [AutocompleteController.options] and return a subset as results, given some
/// query string.
typedef AutocompleteFilter<T> = List<T> Function(String query);

/// A type for indicating the selection of an autocomplete result.
typedef OnSelectedAutocomplete<T> = void Function(T result);

/// A builder for the selectable results given the current autocomplete query.
typedef AutocompleteResultsBuilder<T> = Widget Function(
  BuildContext context,
  OnSelectedAutocomplete<T> onSelected,
  List<T> results,
);

/// A builder for the query field in autocomplete.
typedef AutocompleteFieldBuilder = Widget Function(
  BuildContext context,
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
    this.filter,
    TextEditingController textEditingController,
  }) : assert(
        filter == null || options == null,
        "It's unnecessary to pass options if you've passed a custom filter.",
      ),
      assert(
        filter != null || options != null,
        'Must pass either options or filter.',
      ),
       _ownsTextEditingController = textEditingController == null,
       textEditingController = textEditingController ?? TextEditingController() {
    this.textEditingController.addListener(_onQueryChanged);
  }

  final bool _ownsTextEditingController;

  /// All possible options that can be selected.
  ///
  /// If left null, a custom [filter] method must be provided that handles the
  /// options to be filtered on its own.
  final List<T> options;

  /// The [TextEditingController] that represents the query.
  final TextEditingController textEditingController;

  /// A filter function returns the possible results given a query string.
  ///
  /// If [options] is null, then this field must not be null. This may be the
  /// case when querying an external service for filter results, for example.
  ///
  /// Defaults to a simple string-matching filter of [options].
  final AutocompleteFilter<T> filter;

  /// The current results being returned by [filter].
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
    final List<T> resultsValue = filter == null
        ? _filterByString(textEditingController.value.text)
        : filter(textEditingController.value.text);
    assert(resultsValue != null);
    results.value = resultsValue;
  }

  // The default filter function, if one wasn't supplied.
  List<T> _filterByString(String query) {
    assert(options != null);
    return options
        .where((T option) => option.toString().contains(query))
        .toList();
  }
}

/// A widget for helping the user to filter a list of options and select a
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
/// final AutocompleteController<String> _autocompleteController =
///     AutocompleteController<String>(
///       options: <String>['aardvark', 'baboon', 'chameleon'],
///     );
///
/// @override
/// Widget build(BuildContext context) {
///   return AutocompleteCore(
///     autocompleteController: _autocompleteController,
///     buildField: (BuildContext context) {
///       return TextFormField(
///         controller: _autocompleteController.textEditingController,
///       );
///     },
///     buildResults: (BuildContext context, OnSelectedAutocomplete<String> onSelected, List<String> results) {
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
///   // When using a default filter function, the query will be matched
///   // directly with the output of this toString method. In this case,
///   // including both the email and name allows the user to filter by both.
///   // If you wanted even more advanced filter logic, you could pass a custom
///   // filter function into AutocompleteController.
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
///     return MaterialApp(
///       home: Scaffold(
///         appBar: AppBar(
///           title: Text('AutocompleteCore Example'),
///         ),
///         body: Center(
///           child: AutocompleteCore<User>(
///             autocompleteController: _autocompleteController,
///             // This custom onSelected callback allows the field to be set to
///             // just the name when selected, instead of User.toString by
///             // default.
///             onSelected: (User selected) {
///               _autocompleteController.textEditingController.value = TextEditingValue(
///                 selection: TextSelection.collapsed(offset: selected.name.length),
///                 text: selected.name,
///               );
///             },
///             buildField: (BuildContext context) {
///               return TextFormField(
///                 controller: _autocompleteController.textEditingController,
///               );
///             },
///             buildResults: (BuildContext context, OnSelectedAutocomplete<User> onSelected, List<User> results) {
///               return ListView(
///                 children: results.map((User result) => GestureDetector(
///                   onTap: () {
///                     onSelected(result);
///                   },
///                   child: ListTile(
///                     // Despite allowing filter on both name and email, here
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
    this.onSelected,
  }) : assert(autocompleteController != null),
       assert(buildField != null),
       assert(buildResults != null);

  /// The controller that provides access to the main autocomplete state and
  /// logic.
  final AutocompleteController<T> autocompleteController;

  /// Builds the field that is used to input the query.
  final AutocompleteFieldBuilder buildField;

  /// Builds the selectable results of filtering.
  final AutocompleteResultsBuilder<T> buildResults;

  /// Called when a result is selected by the user.
  ///
  /// This method is used to update the query field to reflect the selection, so
  /// if implemented, it should set `textEditingController.value`.
  final OnSelectedAutocomplete<T> onSelected;

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
    setState(() {
      _selection = null;
    });
  }

  void _onSelected (T result) {
    setState(() {
      if (widget.onSelected != null) {
        widget.onSelected(result);
      } else {
        final String resultString = result.toString();
        widget.autocompleteController.textEditingController.value = TextEditingValue(
          selection: TextSelection.collapsed(offset: resultString.length),
          text: resultString,
        );
      }
      _selection = result;
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
        widget.buildField(context),
        if (_selection == null)
          Expanded(
            child: widget.buildResults(
              context,
              _onSelected,
              widget.autocompleteController.results.value,
            ),
          ),
      ],
    );
  }
}
