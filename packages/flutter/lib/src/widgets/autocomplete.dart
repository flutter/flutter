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

/// A type for getting a list of options based on a String.
///
/// See also:
///   * [AutocompleteController.buildOptions], which is of this type.
typedef AutocompleteBuildOptions<T> = List<T> Function(TextEditingValue textEditingValue);

/// A type for indicating the selection of an autocomplete option.
typedef AutocompleteOnSelected<T> = void Function(T? option);

/// A builder for the selectable options given the current autocomplete field
/// value.
typedef AutocompleteOptionsBuilder<T> = Widget Function(
  BuildContext context,
  AutocompleteOnSelected<T> onSelected,
  List<T> options,
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
/// choosing from among a list of options.
///
/// This is a core framework widget with very basic UI. Try using Autocomplete
/// or AutocompleteCupertino before resorting to this widget.
///
/// {@tool dartpad --template=freeform}
/// This example shows how to create a very basic autocomplete widget using the
/// [fieldBuilder] and [optionsBuilder] parameters.
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
///       fieldBuilder: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///         return TextFormField(
///           controller: textEditingController,
///           onFieldSubmitted: (String value) {
///             onFieldSubmitted();
///           },
///         );
///       },
///       optionsBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, List<String> options) {
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
///           fieldBuilder: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///             return TextFormField(
///               controller: _autocompleteController.textEditingController,
///               onFieldSubmitted: (String value) {
///                 onFieldSubmitted();
///               },
///             );
///           },
///           resultsBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, List<User> results) {
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
  /// [fieldBuilder] and [optionsBuilder] must not be null.
  const AutocompleteCore({
    required this.fieldBuilder,
    required this.optionsBuilder,
    required this.buildOptions,
    AutocompleteOptionToString<T>? displayStringForOption,
    this.onSelected,
  }) : assert(fieldBuilder != null),
       assert(optionsBuilder != null),
       displayStringForOption = displayStringForOption ?? _defaultStringForOption;

  /// Builds the field whose input is used to get the options.
  final AutocompleteFieldBuilder fieldBuilder;

  /// Builds the selectable options widgets from a list of options objects.
  final AutocompleteOptionsBuilder<T> optionsBuilder;

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

  /// Called when an option is selected by the user.
  final AutocompleteOnSelected<T>? onSelected;

  /// A function that returns the current selectable options objects given the
  /// current TextEditingValue.
  final AutocompleteBuildOptions<T> buildOptions;

  // The default way to convert an option to a string.
  static String _defaultStringForOption<T>(T option) {
    return option.toString();
  }

  @override
  _AutocompleteCoreState<T> createState() => _AutocompleteCoreState<T>();
}

class _AutocompleteCoreState<T> extends State<AutocompleteCore<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _optionsLayerLink = LayerLink();
  final TextEditingController _textEditingController = TextEditingController();
  List<T> _options = <T>[];
  T? _selection;

  // The OverlayEntry containing the options.
  OverlayEntry? _floatingOptions;

  // True iff the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    final TextSelection selection = _textEditingController.selection;
    final bool fieldIsFocused = selection.baseOffset >= 0
        && selection.extentOffset >= 0;
    final bool hasOptions = _options != null && _options.isNotEmpty;
    return fieldIsFocused && _selection == null && hasOptions;
  }

  // Called when _textEditingController changes.
  void _onChangedField() {
    final List<T> options = widget.buildOptions(
      _textEditingController.value,
    );
    assert(options != null);
    setState(() {
      _options = options;
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

  // Called from fieldBuilder when the user submits the field.
  void _onFieldSubmitted() {
    if (_options.isEmpty) {
      return;
    }
    _select(_options[0]);
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

  // Hide or show the options overlay, if needed.
  void _updateOverlay() {
    if (_shouldShowOptions) {
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      _floatingOptions?.remove();
      _floatingOptions= OverlayEntry(
        builder: (BuildContext context) {
          return _FloatingOptions<T>(
            optionsBuilder: widget.optionsBuilder,
            fieldSize: renderBox.size,
            layerLink: _optionsLayerLink,
            onSelected: _select,
            options: _options,
          );
        },
      );
      Overlay.of(context, rootOverlay: true)!.insert(_floatingOptions!);
    } else if (_floatingOptions != null) {
      _floatingOptions!.remove();
      _floatingOptions = null;
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
    _floatingOptions?.remove();
    _floatingOptions = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      key: _fieldKey,
      child: CompositedTransformTarget(
        link: _optionsLayerLink,
        child: widget.fieldBuilder(
          context,
          _textEditingController,
          _onFieldSubmitted,
        ),
      ),
    );
  }
}

class _FloatingOptions<T> extends StatelessWidget {
  const _FloatingOptions({
    Key? key,
    required this.optionsBuilder,
    required this.fieldSize,
    required this.layerLink,
    required this.onSelected,
    required this.options,
  }) : assert(optionsBuilder != null),
       assert(fieldSize != null),
       assert(layerLink != null),
       assert(onSelected != null),
       assert(options != null),
       super(key: key);

  final AutocompleteOptionsBuilder<T> optionsBuilder;
  final Size fieldSize;
  final LayerLink layerLink;
  final AutocompleteOnSelected<T> onSelected;
  final List<T> options;

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
        child: optionsBuilder(context, onSelected, options),
      ),
    );
  }
}
