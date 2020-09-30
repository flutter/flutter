// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'container.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'overlay.dart';

/// A type for getting some list of results based on a String.
///
/// See also:
///   * [AutocompleteController.getResults], which is of this type.
typedef AutocompleteResultsGetter<T> = List<T> Function(TextEditingValue textEditingValue);

/// A type for indicating the selection of an autocomplete result.
typedef AutocompleteOnSelected<T> = void Function(T? result);

/// A builder for the selectable results given the current autocomplete field
/// text.
typedef AutocompleteResultsBuilder<T> = Widget Function(
  BuildContext context,
  AutocompleteOnSelected<T> onSelected,
  List<T> results,
);

/// A builder for the field in autocomplete.
typedef AutocompleteFieldBuilder = Widget Function(
  BuildContext context,
  TextEditingController textEditingController,
  VoidCallback onFieldSubmitted,
);

// A type for getting a String from some option.
typedef AutocompleteOptionToString<T> = String Function(T option);

// TODO(justinmc): Link to Autocomplete and AutocompleteCupertino when they are
// implemented.
/// A widget for helping the user to make a selection by entering some text and
/// choosing from among a list of results.
///
/// This is a core framework widget with very basic UI. Try using Autocomplete
/// or AutocompleteCupertino before resorting to this widget.
///
/// {@tool dartpad --template=freeform}
/// This example shows how to create a very basic autocomplete widget using the
/// [buildField] and [buildResults] parameters.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart
/// class AutocompleteCoreExample extends StatelessWidget {
///   AutocompleteCoreExample({Key key, this.title}) : super(key: key);
///
///   final String title;
///
///   @override
///   Widget build(BuildContext context) {
///     return AutocompleteCore<String>(
///       buildOptions: (TextEditingValue textEditingValue) {
///         return <String>['aardvark', 'bobcat', 'chameleon']
///            .contains(value.text.toLowerCase());
///       }
///       buildField: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///         return TextFormField(
///           controller: textEditingController,
///           onFieldSubmitted: (String value) {
///             onFieldSubmitted();
///           },
///         );
///       },
///       buildResults: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> results) {
///         return Material(
///           elevation: 4.0,
///           child: SizedBox(
///             height: 200.0,
///             child: ListView(
///               children: results.map((String result) => GestureDetector(
///                 onTap: () {
///                   onSelected(result);
///                 },
///                 child: ListTile(
///                   title: Text(result),
///                 ),
///               )).toList(),
///             ),
///           ),
///         );
///       },
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
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
/// // An example of a type that someone might want to autocomplete a list of.
/// class User {
///   const User({
///     this.email,
///     this.name,
///   });
///
///   final String email;
///   final String name;
///
///   // When using a default getResults function, the text will be matched
///   // directly with the output of this toString method. In this case,
///   // including both the email and name allows the user to filter by both.
///   // If you wanted even more advanced logic, you could pass a custom
///   // getResults function into AutocompleteController and/or
///   // filterStringForOption into AutocompleteCore.
///   @override
///   String toString() {
///     return '$name, $email';
///   }
/// }
///
/// class AutocompleteCoreCustomTypeExample extends StatelessWidget {
///   AutocompleteCoreCustomTypeExample({Key key, this.title}) : super(key: key);
///
///   final String title;
///   final AutocompleteController<User> _autocompleteController = AutocompleteController<User>(
///     options: <User>[
///       User(name: 'Alice', email: 'alice@example.com'),
///       User(name: 'Bob', email: 'bob@example.com'),
///       User(name: 'Charlie', email: 'charlie123@gmail.com'),
///     ],
///     // This shows just the name in the field, even though we can also filter
///     // by email address.
///     displayStringForOption: (User option) => option.name,
///   );
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text(title),
///       ),
///       body: Center(
///         child: AutocompleteCore<User>(
///           autocompleteController: _autocompleteController,
///           buildField: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///             return TextFormField(
///               controller: _autocompleteController.textEditingController,
///               onFieldSubmitted: (String value) {
///                 onFieldSubmitted();
///               },
///             );
///           },
///           buildResults: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> results) {
///             return SizedBox(
///               height: 200.0,
///               child: Material(
///                 elevation: 4.0,
///                 child: ListView(
///                   children: results.map((User result) => GestureDetector(
///                     onTap: () {
///                       onSelected(result);
///                     },
///                     child: ListTile(
///                       title: Text(_autocompleteController.displayStringForOption(result)),
///                     ),
///                   )).toList(),
///                 ),
///               ),
///             );
///           },
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
  /// [buildField] and [buildResults] must not be null.
  const AutocompleteCore({
    required this.buildField,
    required this.buildResults,
    required this.buildOptions,
    AutocompleteOptionToString<T>? displayStringForOption,
    this.onSelected,
  }) : assert(buildField != null),
       assert(buildResults != null),
       displayStringForOption = displayStringForOption ?? _defaultStringForOption;

  /// Builds the field whose input is used to find the results.
  final AutocompleteFieldBuilder buildField;

  /// Builds the selectable results of filtering.
  final AutocompleteResultsBuilder<T> buildResults;

  /// Returns the string to display in the field when the option is selected.
  ///
  /// This is useful when using a custom T type and the string to display is
  /// different than the string to search by.
  ///
  /// If not provided, will use `option.toString()`.
  ///
  /// See also:
  ///   * [filterStringForOption], which can be used to specify a custom string
  ///     to filter by.
  final AutocompleteOptionToString<T> displayStringForOption;

  /// Called when a result is selected by the user.
  final AutocompleteOnSelected<T>? onSelected;

  /// A function that returns the current selectable options given the current
  /// TextEditingValue.
  final AutocompleteResultsGetter<T> buildOptions;

  // The default way to convert an option to a string.
  static String _defaultStringForOption<T>(T option) {
    return option.toString();
  }

  @override
  _AutocompleteCoreState<T> createState() => _AutocompleteCoreState<T>();
}

class _AutocompleteCoreState<T> extends State<AutocompleteCore<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _resultsLayerLink = LayerLink();
  final TextEditingController _textEditingController = TextEditingController();
  List<T> _results = <T>[];
  T? _selection;


  /// The current results being returned by [getResults].
  ///
  /// This is a [ValueNotifier], so it can be listened to for changes.
  final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

  // The OverlayEntry containing the results.
  OverlayEntry? _floatingResults;

  // True iff the state indicates that the results should be visible.
  bool get _shouldShowResults {
    final TextSelection selection = _textEditingController.selection;
    final bool fieldIsFocused = selection.baseOffset >= 0
        && selection.extentOffset >= 0;
    final bool hasResults = _results != null && _results.isNotEmpty;
    return fieldIsFocused && _selection == null && hasResults;
  }

  // Called when _results changes.
  void _onChangedResults() {
    _updateOverlay();
  }

  // Called when _textEditingController changes.
  void _onChangedField() {
    final List<T> results = widget.buildOptions(
      _textEditingController.value,
    );
    assert(results != null);
    setState(() {
      _results = results;
      if (_selection != null) {
        final String selectionString = widget.displayStringForOption(_selection!);
        if (_textEditingController.text == selectionString) {
          return;
        }
      }
      _selection = null;
    });
    _updateOverlay();
  }

  // Called from buildField when the user submits the field.
  void _onFieldSubmitted() {
    if (_results.isEmpty) {
      return;
    }
    _select(_results[0]);
  }

  // Select the given option and update the widget.
  void _select(T? nextSelection) {
    if (nextSelection == _selection) {
      return;
    }
    setState(() {
      _selection = nextSelection;
      final String selectionString = nextSelection == null
          ? ''
          : widget.displayStringForOption(nextSelection);
      _textEditingController.value = TextEditingValue(
        selection: TextSelection.collapsed(offset: selectionString.length),
        text: selectionString,
      );
      widget.onSelected?.call(_selection);
    });
  }

  // Hide or show the results overlay, if needed.
  void _updateOverlay() {
    if (_shouldShowResults) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      _floatingResults?.remove();
      _floatingResults = OverlayEntry(
        builder: (BuildContext context) {
          return _FloatingResults<T>(
            buildResults: widget.buildResults,
            fieldSize: renderBox.size,
            layerLink: _resultsLayerLink,
            onSelected: _select,
            results: _results,
          );
        },
      );
      Overlay.of(context, rootOverlay: true)!.insert(_floatingResults!);
    } else if (_floatingResults != null) {
      _floatingResults!.remove();
      _floatingResults = null;
    }
  }

  @override
  void initState() {
    super.initState();
    _textEditingController.addListener(_onChangedField);
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void didUpdateWidget(AutocompleteCore<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onChangedField);
    _floatingResults?.remove();
    _floatingResults = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _fieldKey,
      child: CompositedTransformTarget(
        link: _resultsLayerLink,
        child: widget.buildField(
          context,
          _textEditingController,
          _onFieldSubmitted,
        ),
      ),
    );
  }
}

class _FloatingResults<T> extends StatelessWidget {
  const _FloatingResults({
    Key? key,
    required this.buildResults,
    required this.fieldSize,
    required this.layerLink,
    required this.onSelected,
    required this.results,
  }) : assert(buildResults != null),
       assert(fieldSize != null),
       assert(layerLink != null),
       assert(onSelected != null),
       assert(results != null),
       super(key: key);

  final AutocompleteResultsBuilder<T> buildResults;
  final Size fieldSize;
  final LayerLink layerLink;
  final AutocompleteOnSelected<T> onSelected;
  final List<T> results;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: fieldSize.width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: Offset(
          0.0,
          fieldSize.height,
        ),
        child: buildResults(context, onSelected, results),
      ),
    );
  }
}
