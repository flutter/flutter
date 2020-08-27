// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

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
typedef AutocompleteResultsGetter<T> = List<T> Function(String text);

/// A type for indicating the selection of an autocomplete result.
typedef AutocompleteOnSelected<T> = void Function(T result);

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
typedef _AutocompleteOptionToString<T> = String Function(T option);

// TODO(justinmc): Link to Autocomplete and AutocompleteCupertino when they are
// implemented.
/// A controller for the [AutocompleteCore] widget.
///
/// Can also be used in a stand-alone manner to implement autocomplete behavior
/// in a fully custom UI.
///
/// {@tool dartpad --template=freeform}
/// This example shows how to build an autocomplete widget with your own UI
/// using AutocompleteController. Most typical use cases would instead pass the
/// AutocompleteController directly to Autocomplete or
/// AutocompleteCupertino.
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
///   void _onChangeField() {
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
///       options: <String>['aardvark', 'bobcat', 'chameleon'],
///     );
///     _autocompleteController.textEditingController.addListener(_onChangeField);
///     _autocompleteController.results.addListener(_onChangeResults);
///   }
///
///   @override
///   void dispose() {
///     _autocompleteController.textEditingController.removeListener(_onChangeField);
///     _autocompleteController.results.removeListener(_onChangeResults);
///     _autocompleteController.dispose();
///     super.dispose();
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: <Widget>[
///         TextFormField(
///           controller: _autocompleteController.textEditingController,
///         ),
///         if (_selection == null)
///           Expanded(
///             child: ListView(
///               children: _autocompleteController.results.value.map((String result) => GestureDetector(
///                 onTap: () {
///                   setState(() {
///                     _selection = result;
///                     _autocompleteController.textEditingController.value = TextEditingValue(
///                       selection: TextSelection.collapsed(offset: result.length),
///                       text: result,
///                     );
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
    this.getResults,
    this.options,
    _AutocompleteOptionToString<T> displayStringForOption,
    _AutocompleteOptionToString<T> filterStringForOption,
    TextEditingController textEditingController,
  }) : assert(
         getResults == null || options == null,
         "It's unnecessary to pass options if you've passed a custom getResults.",
       ),
       assert(
         getResults != null || options != null,
         'Must pass either options or getResults.',
       ),
       displayStringForOption = displayStringForOption ?? _defaultStringForOption,
       filterStringForOption = filterStringForOption ?? _defaultStringForOption,
       _ownsTextEditingController = textEditingController == null,
       textEditingController = textEditingController ?? TextEditingController() {
    this.textEditingController.addListener(_onChangedField);
  }

  final bool _ownsTextEditingController;

  /// All possible options that can be selected.
  ///
  /// If left null, a custom [getResults] method must be provided that handles
  /// generating some results based on the text in the field.
  final List<T> options;

  /// The [TextEditingController] that represents the field.
  final TextEditingController textEditingController;

  /// A function that returns the possible results given the text in the field.
  ///
  /// If [options] is null, then this field must not be null. This may be the
  /// case when querying an external service for results, for example.
  ///
  /// Defaults to a simple string-matching filter of [options].
  final AutocompleteResultsGetter<T> getResults;

  /// Returns the string to display in the field when the option is selected.
  ///
  /// This is useful when using a custom T type for AutocompleteController and
  /// the string to display is different than the string to search by.
  ///
  /// If not provided, will use `option.toString()`.
  ///
  /// See also:
  ///   * [filterStringForOption], which can be used to specify a custom string
  ///     to filter by.
  final _AutocompleteOptionToString<T> displayStringForOption;

  /// Returns the string to match against when filtering the given option.
  ///
  /// This is useful when using a custom T type for AutocompleteController and
  /// the string to display is different than the string to search by. This is
  /// only used when [getResults] is null and the default getResults filter is
  /// used.
  ///
  /// If not provided, will use `option.toString()`.
  ///
  /// See also:
  ///   * [displayStringForOption], which can be used to specify a custom String
  ///     to be shown in the field.
  final _AutocompleteOptionToString<T> filterStringForOption;

  /// The current results being returned by [getResults].
  ///
  /// This is a [ValueNotifier], so it can be listened to for changes.
  final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

  // The default way to convert an option to a string.
  static String _defaultStringForOption<T>(T option) {
    return option.toString();
  }

  /// Clean up memory created by the AutocompleteController.
  ///
  /// Call this when the AutocompleteController is no longer needed, such as in
  // the dispose method of the widget it was created in.
  void dispose() {
    textEditingController.removeListener(_onChangedField);
    if (_ownsTextEditingController) {
      textEditingController.dispose();
    }
  }

  // Called when textEditingController reports a change in its value.
  void _onChangedField() {
    final List<T> resultsValue = getResults == null
        ? _filterByString(textEditingController.value.text)
        : getResults(textEditingController.value.text);
    assert(resultsValue != null);
    results.value = resultsValue;
  }

  // The default getResults function, if one wasn't supplied.
  List<T> _filterByString(String text) {
    assert(options != null);
    return options
        .where((T option) {
          return filterStringForOption(option)
              .toLowerCase()
              .contains(text.toLowerCase());
        })
        .toList();
  }
}

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
///       options: <String>['aardvark', 'bobcat', 'chameleon'],
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
  /// [autocompleteController], [buildField], and [buildResults] must not be
  /// null.
  const AutocompleteCore({
    this.autocompleteController,
    @required this.buildField,
    @required this.buildResults,
    this.options,
    this.onSelected,
  }) : assert(
         autocompleteController != null || options != null,
         'If not providing autocompleteController, options must be passed.',
       ),
       assert(
         autocompleteController == null || options == null,
         'No need to pass options if providing an AutocompleteController',
       ),
       assert(buildField != null),
       assert(buildResults != null);

  /// The controller that provides access to the main autocomplete state and
  /// logic.
  ///
  /// The owner of autocompleteController must call
  /// [AutocompleteController.dispose] on this when it's no longer needed.
  final AutocompleteController<T> autocompleteController;

  /// Builds the field whose input is used to find the results.
  final AutocompleteFieldBuilder buildField;

  /// Builds the selectable results of filtering.
  final AutocompleteResultsBuilder<T> buildResults;

  /// Called when a result is selected by the user.
  final AutocompleteOnSelected<T> onSelected;

  /// All possible options that can be selected.
  ///
  /// If passing an AutocompleteController, use
  /// [AutocompleteController.options] instead.
  final List<T> options;

  @override
  _AutocompleteCoreState<T> createState() =>
      _AutocompleteCoreState<T>();
}

class _AutocompleteCoreState<T> extends State<AutocompleteCore<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _resultsLayerLink = LayerLink();
  AutocompleteController<T> _autocompleteController;
  T _selection;

  // The OverlayEntry containing the results.
  OverlayEntry _floatingResults;

  // True iff the state indicates that the results should be visible.
  bool get _shouldShowResults {
    final List<T> results = _autocompleteController.results.value;
    final TextSelection selection =
        _autocompleteController.textEditingController.selection;
    final bool fieldIsFocused = selection.baseOffset >= 0
        && selection.extentOffset >= 0;
    final bool hasResults = results != null && results.isNotEmpty;
    return fieldIsFocused && _selection == null && hasResults;
  }

  // Called when _autocompleteController.results changes.
  void _onChangedResults() {
    _updateOverlay();
  }

  // Called when _autocompleteController.textEditingController changes.
  void _onChangedField() {
    if (_selection != null) {
      final String selectionString =
          _autocompleteController.displayStringForOption(_selection);
      if (_autocompleteController.textEditingController.text == selectionString) {
        return;
      }
    }
    setState(() {
      _selection = null;
    });
    _updateOverlay();
  }

  // Called from buildField when the user submits the field.
  void _onFieldSubmitted() {
    final List<T> results = _autocompleteController.results.value;
    if (results.isEmpty) {
      return;
    }
    _select(results[0]);
  }

  // Select the given option and update the widget.
  void _select(T nextSelection) {
    if (nextSelection == _selection) {
      return;
    }
    setState(() {
      _selection = nextSelection;
      final String selectionString =
          _autocompleteController.displayStringForOption(nextSelection);
      _autocompleteController.textEditingController.value = TextEditingValue(
        selection: TextSelection.collapsed(offset: selectionString.length),
        text: selectionString,
      );
      if (widget.onSelected != null) {
        widget.onSelected(_selection);
      }
    });
  }

  // Hide or show the results overlay, if needed.
  void _updateOverlay() {
    if (_shouldShowResults) {
      assert(_fieldKey.currentContext != null);
      final RenderBox renderBox = _fieldKey.currentContext.findRenderObject() as RenderBox;
      _floatingResults?.remove();
      _floatingResults = OverlayEntry(
        builder: (BuildContext context) {
          return _FloatingResults<T>(
            buildResults: widget.buildResults,
            fieldSize: renderBox.size,
            layerLink: _resultsLayerLink,
            onSelected: _select,
            results: _autocompleteController.results.value,
          );
        },
      );
      Overlay.of(context, rootOverlay: true).insert(_floatingResults);
    } else if (_floatingResults != null) {
      _floatingResults.remove();
      _floatingResults = null;
    }
  }

  void _listenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.addListener(_onChangedResults);
    autocompleteController.textEditingController.addListener(_onChangedField);
  }

  void _unlistenToController(AutocompleteController<T> autocompleteController) {
    autocompleteController.results.removeListener(_onChangedResults);
    autocompleteController.textEditingController.removeListener(_onChangedField);
  }

  @override
  void initState() {
    super.initState();
    _autocompleteController = widget.autocompleteController
        ?? AutocompleteController<T>(options: widget.options);
    _listenToController(_autocompleteController);

    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void didUpdateWidget(AutocompleteCore<T> oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Handle changes in the AutocompleteController.
    if (widget.autocompleteController == null && oldWidget.autocompleteController != null) {
      _unlistenToController(oldWidget.autocompleteController);
      _autocompleteController = AutocompleteController<T>(
        options: widget.options,
      );
      _listenToController(_autocompleteController);
    } else if (widget.autocompleteController != null && oldWidget.autocompleteController == null) {
      _unlistenToController(_autocompleteController);
      _autocompleteController.dispose();
      _autocompleteController = widget.autocompleteController;
      _listenToController(_autocompleteController);
    } else if (widget.autocompleteController != oldWidget.autocompleteController) {
      _unlistenToController(oldWidget.autocompleteController);
      _autocompleteController = widget.autocompleteController;
      _listenToController(_autocompleteController);
    }

    SchedulerBinding.instance.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void dispose() {
    _unlistenToController(_autocompleteController);
    if (widget.autocompleteController == null) {
      _autocompleteController.dispose();
    }
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
          _autocompleteController.textEditingController,
          _onFieldSubmitted,
        ),
      ),
    );
  }
}

class _FloatingResults<T> extends StatelessWidget {
  const _FloatingResults({
    Key key,
    @required this.buildResults,
    @required this.fieldSize,
    @required this.layerLink,
    @required this.onSelected,
    @required this.results,
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
