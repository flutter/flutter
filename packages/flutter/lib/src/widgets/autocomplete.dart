// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'container.dart';
import 'editable_text.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'overlay.dart';

/// The type of the [RawAutocomplete] callback which computes the list of
/// optional completions for the widget's field based on the text the user has
/// entered so far.
///
/// See also:
///   * [RawAutocomplete.optionsBuilder], which is of this type.
typedef AutocompleteOptionsBuilder<T extends Object> = Iterable<T> Function(TextEditingValue textEditingValue);

/// The type of the callback used by the [RawAutocomplete] widget to indicate
/// that the user has selected an option.
///
/// See also:
///   * [RawAutocomplete.onSelected], which is of this type.
typedef AutocompleteOnSelected<T extends Object> = void Function(T option);

/// The type of the [RawAutocomplete] callback which returns a [Widget] that
/// displays the specified [options] and calls [onSelected] if the user
/// selects an option.
///
/// See also:
///   * [RawAutocomplete.optionsViewBuilder], which is of this type.
typedef AutocompleteOptionsViewBuilder<T extends Object> = Widget Function(
  BuildContext context,
  AutocompleteOnSelected<T> onSelected,
  Iterable<T> options,
);

/// The type of the Autocomplete callback which returns the widget that
/// contains the input [TextField] or [TextFormField].
///
/// See also:
///   * [RawAutocomplete.fieldViewBuilder], which is of this type.
typedef AutocompleteFieldViewBuilder = Widget Function(
  BuildContext context,
  TextEditingController textEditingController,
  FocusNode focusNode,
  VoidCallback onFieldSubmitted,
);

/// The type of the [RawAutocomplete] callback that converts an option value to
/// a string which can be displayed in the widget's options menu.
///
/// See also:
///   * [RawAutocomplete.displayStringForOption], which is of this type.
typedef AutocompleteOptionToString<T extends Object> = String Function(T option);

// TODO(justinmc): Link to Autocomplete and AutocompleteCupertino when they are
// implemented.
// TODO(justinmc): Update docs.
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
///   void _onChangedField() {
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
///       buildOptions: (TextEditingValue textEditingValue) {
///         return <String>['aardvark', 'bobcat', 'chameleon']
///            .contains(value.text.toLowerCase());
///       }
///     );
///     _autocompleteController.textEditingController.addListener(_onChangedField);
///     _autocompleteController.results.addListener(_onChangeResults);
///   }
///
///   @override
///   void dispose() {
///     _autocompleteController.textEditingController.removeListener(_onChangedField);
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
class AutocompleteController<T extends Object> {
  // TODO(justinmc): Update docs.
  /// Create an instance of AutocompleteController with a known list of options.
  ///
  /// When the text in the textEditingController changes, the options list will
  /// be filtered using simple case-insensitive string matching.
  ///
  /// See also:
  ///   * [AutocompleteController.generated], which generates the options with a
  ///     [getResults] method instead of specifying all possible options up
  ///     front.
  AutocompleteController({
    // TODO(justinmc): Rename to optionsBuilder.
    required this.buildOptions,
    AutocompleteOptionToString<T>? displayStringForOption,
    TextEditingController? textEditingController,
  }) : assert(buildOptions != null),
       displayStringForOption = displayStringForOption ?? _defaultStringForOption,
       _ownsTextEditingController = textEditingController == null,
       textEditingController = textEditingController ?? TextEditingController() {
    this.textEditingController.addListener(_onChangedField);
    selection.addListener(_onChangedSelection);
  }

  // TODO(justinmc): Update these docs.
  /// A function that returns the results given the text in the field.
  ///
  /// See also:
  ///   * [AutocompleteController()]'s options parameter, which can be used
  ///     instead to simply pass a list of all possible options and filter them
  ///     with string matching.
  final AutocompleteOptionsBuilder<T> buildOptions;

  // When the instance owns textEditingController, it is responsible for
  // disposing it.
  final bool _ownsTextEditingController;

  /// The [TextEditingController] that represents the field.
  final TextEditingController textEditingController;

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
  final AutocompleteOptionToString<T> displayStringForOption;

  /// The current results being returned by [getResults].
  ///
  /// This is a [ValueNotifier], so it can be listened to for changes.
  //final ValueNotifier<List<T>> results = ValueNotifier<List<T>>(<T>[]);

  /// A [ValueNotifier] for the current s
  final ValueNotifier<T?> selection = ValueNotifier<T?>(null);

  // TODO(justinmc): It's possible to set options.value and selection.value to something that
  // might not want make sense. It's up to the user to prevent that. I could ensure that
  // they must be set to something returned by buildOptions, but I think that
  // might not always be desired.
  /// A [ValueNotifier] for the current list of options being returned by
  /// [buildOptions].
  final ValueNotifier<Iterable<T>> options = ValueNotifier<Iterable<T>>(<T>[]);

  // The default way to convert an option to a string.
  static String _defaultStringForOption<T extends Object>(T option) {
    return option.toString();
  }

  // Simply filters based on case-insensitive string matching.
  static List<T> _filterByString<T extends Object>(
    List<T> options,
    TextEditingValue value,
    AutocompleteOptionToString<T> filterStringForOption,
  ) {
    return options
        .where((T option) {
          return filterStringForOption(option)
              .toLowerCase()
              .contains(value.text.toLowerCase());
        })
        .toList();
  }

  /// A convenience method for creating a simple default [buildOptions] given a
  /// list of potential options.
  ///
  /// Filters the given list using a case-insensitive string comparison.
  static AutocompleteOptionsBuilder<T> generateDefaultBuildOptions<T extends Object>(
    List<T> options,
    [AutocompleteOptionToString<T>? filterStringForOption]
  ) {
    return (TextEditingValue textEditingValue) {
      return _filterByString<T>(
        options,
        textEditingValue,
        filterStringForOption ?? _defaultStringForOption,
      );
    };
  }

  // Called when textEditingController reports a change in its value.
  void _onChangedField() {
    options.value = buildOptions(textEditingController.value);
    // Clear the selection if the field isn't an exact match for it.
    // TODO(justinmc): Will this work in fancy cases where the display string
    // isn't the same as what's being used in buildOptions?
    if (selection.value != null) {
      final String selectionString = displayStringForOption(selection.value!);
      if (selectionString != textEditingController.text) {
        selection.value = null;
      }
    }
  }

  void _onChangedSelection() {
    if (selection.value == null) {
      textEditingController.value = const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
        text: '',
      );
      return;
    }
    final String selectionText = displayStringForOption(selection.value!);
    textEditingController.value = TextEditingValue(
      selection: TextSelection.collapsed(offset: selectionText.length),
      text: selectionText,
    );
  }

  /// Clean up memory created by the AutocompleteController.
  ///
  /// Call this when the AutocompleteController is no longer needed, such as in
  // the dispose method of the widget it was created in.
  void dispose() {
    selection.removeListener(_onChangedSelection);
    textEditingController.removeListener(_onChangedField);
    if (_ownsTextEditingController) {
      textEditingController.dispose();
    }
  }
}

// TODO(justinmc): Mention Autocomplete and AutocompleteCupertino when they are
// implemented.
/// A widget for helping the user make a selection by entering some text and
/// choosing from among a list of options.
///
/// This is a core framework widget with very basic UI.
///
/// The user's text input is received in a field built with the
/// [fieldViewBuilder] parameter. The options to be displayed are determined
/// using [optionsBuilder] and rendered with [optionsViewBuilder].
///
/// {@tool dartpad --template=freeform}
/// This example shows how to create a very basic autocomplete widget using the
/// [fieldViewBuilder] and [optionsViewBuilder] parameters.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart
/// class AutocompleteBasicExample extends StatelessWidget {
///   AutocompleteBasicExample({Key key}) : super(key: key);
///
///   static final List<String> _options = <String>[
///     'aardvark',
///     'bobcat',
///     'chameleon',
///   ];
///
///   @override
///   Widget build(BuildContext context) {
///     return RawAutocomplete<String>(
///       optionsBuilder: (TextEditingValue textEditingValue) {
///         return _options.where((String option) {
///           return option.contains(textEditingValue.text.toLowerCase());
///         });
///       },
///       fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
///         return TextFormField(
///           controller: textEditingController,
///           focusNode: focusNode,
///           onFieldSubmitted: (String value) {
///             onFieldSubmitted();
///           },
///         );
///       },
///       optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
///         return Align(
///           alignment: Alignment.topLeft,
///           child: Material(
///             elevation: 4.0,
///             child: Container(
///               height: 200.0,
///               child: ListView.builder(
///                 padding: EdgeInsets.all(8.0),
///                 itemCount: options.length,
///                 itemBuilder: (BuildContext context, int index) {
///                   final String option = options.elementAt(index);
///                   return GestureDetector(
///                     onTap: () {
///                       onSelected(option);
///                     },
///                     child: ListTile(
///                       title: Text(option),
///                     ),
///                   );
///                 },
///               ),
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
/// The type parameter T represents the type of the options. Most commonly this
/// is a String, as in the example above. However, it's also possible to use
/// another type with a `toString` method, or a custom [displayStringForOption].
/// Options will be compared using `==`, so it may be beneficial to override
/// [Object.==] and [Object.hashCode] for custom types.
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
///   @override
///   String toString() {
///     return '$name, $email';
///   }
///
///   @override
///   bool operator ==(Object other) {
///     if (other.runtimeType != runtimeType)
///       return false;
///     return other is User
///         && other.name == name
///         && other.email == email;
///   }
///
///   @override
///   int get hashCode => hashValues(email, name);
/// }
///
/// class AutocompleteCustomTypeExample extends StatelessWidget {
///   AutocompleteCustomTypeExample({Key key});
///
///   static final List<User> _userOptions = <User>[
///     User(name: 'Alice', email: 'alice@example.com'),
///     User(name: 'Bob', email: 'bob@example.com'),
///     User(name: 'Charlie', email: 'charlie123@gmail.com'),
///   ];
///
///   static String _displayStringForOption(User option) => option.name;
///
///   @override
///   Widget build(BuildContext context) {
///     return RawAutocomplete<User>(
///       optionsBuilder: (TextEditingValue textEditingValue) {
///         return _userOptions.where((User option) {
///           // Search based on User.toString, which includes both name and
///           // email, even though the display string is just the name.
///           return option.toString().contains(textEditingValue.text.toLowerCase());
///         });
///       },
///       displayStringForOption: _displayStringForOption,
///       fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
///         return TextFormField(
///           controller: textEditingController,
///           focusNode: focusNode,
///           onFieldSubmitted: (String value) {
///             onFieldSubmitted();
///           },
///         );
///       },
///       optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, Iterable<User> options) {
///         return Align(
///           alignment: Alignment.topLeft,
///           child: Material(
///             elevation: 4.0,
///             child: Container(
///               height: 200.0,
///               child: ListView.builder(
///                 padding: EdgeInsets.all(8.0),
///                 itemCount: options.length,
///                 itemBuilder: (BuildContext context, int index) {
///                   final User option = options.elementAt(index);
///                   return GestureDetector(
///                     onTap: () {
///                       onSelected(option);
///                     },
///                     child: ListTile(
///                       title: Text(_displayStringForOption(option)),
///                     ),
///                   );
///                 },
///               ),
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
/// This example shows the use of RawAutocomplete in a form.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/material.dart';
/// ```
///
/// ```dart
/// class AutocompleteFormExamplePage extends StatefulWidget {
///   AutocompleteFormExamplePage({Key key}) : super(key: key);
///
///   @override
///   AutocompleteFormExample createState() => AutocompleteFormExample();
/// }
///
/// class AutocompleteFormExample extends State<AutocompleteFormExamplePage> {
///   final _formKey = GlobalKey<FormState>();
///   final TextEditingController _textEditingController = TextEditingController();
///   String _dropdownValue;
///   String _autocompleteSelection;
///
///   final List<String> _options = <String>[
///     'aardvark',
///     'bobcat',
///     'chameleon',
///   ];
///
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(
///         title: Text('Autocomplete Form Example'),
///       ),
///       body: Center(
///         child: Form(
///           key: _formKey,
///           child: Column(
///             children: <Widget>[
///               DropdownButtonFormField<String>(
///                 value: _dropdownValue,
///                 icon: Icon(Icons.arrow_downward),
///                 hint: const Text('This is a regular DropdownButtonFormField'),
///                 iconSize: 24,
///                 elevation: 16,
///                 style: TextStyle(color: Colors.deepPurple),
///                 onChanged: (String newValue) {
///                   setState(() {
///                     _dropdownValue = newValue;
///                   });
///                 },
///                 items: <String>['One', 'Two', 'Free', 'Four']
///                     .map<DropdownMenuItem<String>>((String value) {
///                   return DropdownMenuItem<String>(
///                     value: value,
///                     child: Text(value),
///                   );
///                 }).toList(),
///                 validator: (String value) {
///                   if (value == null) {
///                     return 'Must make a selection.';
///                   }
///                   return null;
///                 },
///               ),
///               TextFormField(
///                 controller: _textEditingController,
///                 decoration: InputDecoration(
///                   hintText: 'This is a regular TextFormField',
///                 ),
///                 validator: (String value) {
///                   if (value.isEmpty) {
///                     return 'Can\'t be empty.';
///                   }
///                   return null;
///                 },
///               ),
///               RawAutocomplete<String>(
///                 optionsBuilder: (TextEditingValue textEditingValue) {
///                   return _options.where((String option) {
///                     return option.contains(textEditingValue.text.toLowerCase());
///                   });
///                 },
///                 onSelected: (String selection) {
///                   setState(() {
///                     _autocompleteSelection = selection;
///                   });
///                 },
///                 fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
///                   return TextFormField(
///                     controller: textEditingController,
///                     decoration: InputDecoration(
///                       hintText: 'This is an RawAutocomplete!',
///                     ),
///                     focusNode: focusNode,
///                     onFieldSubmitted: (String value) {
///                       onFieldSubmitted();
///                     },
///                     validator: (String value) {
///                       if (!_options.contains(value)) {
///                         return 'Nothing selected.';
///                       }
///                       return null;
///                     },
///                   );
///                 },
///                 optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
///                   return Align(
///                     alignment: Alignment.topLeft,
///                     child: Material(
///                       elevation: 4.0,
///                       child: Container(
///                         height: 200.0,
///                         child: ListView.builder(
///                           padding: EdgeInsets.all(8.0),
///                           itemCount: options.length,
///                           itemBuilder: (BuildContext context, int index) {
///                             final String option = options.elementAt(index);
///                             return GestureDetector(
///                               onTap: () {
///                                 onSelected(option);
///                               },
///                               child: ListTile(
///                                 title: Text(option),
///                               ),
///                             );
///                           },
///                         ),
///                       ),
///                     ),
///                   );
///                 },
///               ),
///               ElevatedButton(
///                 onPressed: () {
///                   FocusScope.of(context).requestFocus(new FocusNode());
///                   if (!_formKey.currentState.validate()) {
///                     return;
///                   }
///                   showDialog<void>(
///                     context: context,
///                     builder: (BuildContext context) {
///                       return AlertDialog(
///                         title: Text('Successfully submitted'),
///                         content: SingleChildScrollView(
///                           child: ListBody(
///                             children: <Widget>[
///                               Text('DropdownButtonFormField: "$_dropdownValue"'),
///                               Text('TextFormField: "${_textEditingController.text}"'),
///                               Text('RawAutocomplete: "$_autocompleteSelection"'),
///                             ],
///                           ),
///                         ),
///                         actions: <Widget>[
///                           TextButton(
///                             child: Text('Ok'),
///                             onPressed: () {
///                               Navigator.of(context).pop();
///                             },
///                           ),
///                         ],
///                       );
///                     },
///                   );
///                 },
///                 child: Text('Submit'),
///               ),
///             ],
///           ),
///         ),
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
class RawAutocomplete<T extends Object> extends StatefulWidget {
  /// Create an instance of RawAutocomplete.
  ///
  /// [fieldViewBuilder] and [optionsViewBuilder] must not be null.
  const RawAutocomplete({
    Key? key,
    required this.fieldViewBuilder,
    required this.optionsViewBuilder,
    required this.optionsBuilder,
    this.displayStringForOption = _defaultStringForOption,
    this.onSelected,
  }) : assert(displayStringForOption != null),
       assert(fieldViewBuilder != null),
       assert(optionsBuilder != null),
       assert(optionsViewBuilder != null),
       super(key: key);

  /// Builds the field whose input is used to get the options.
  ///
  /// Pass the provided [TextEditingController] to the field built here so that
  /// RawAutocomplete can listen for changes.
  final AutocompleteFieldViewBuilder fieldViewBuilder;

  /// Builds the selectable options widgets from a list of options objects.
  ///
  /// The options are displayed floating below the field using a
  /// [CompositedTransformFollower] inside of an [Overlay], not at the same
  /// place in the widget tree as RawAutocomplete.
  final AutocompleteOptionsViewBuilder<T> optionsViewBuilder;

  /// Returns the string to display in the field when the option is selected.
  ///
  /// This is useful when using a custom T type and the string to display is
  /// different than the string to search by.
  ///
  /// If not provided, will use `option.toString()`.
  final AutocompleteOptionToString<T> displayStringForOption;

  /// Called when an option is selected by the user.
  ///
  /// Any [TextEditingController] listeners will not be called when the user
  /// selects an option, even though the field will update with the selected
  /// value, so use this to be informed of selection.
  final AutocompleteOnSelected<T>? onSelected;

  /// A function that returns the current selectable options objects given the
  /// current TextEditingValue.
  final AutocompleteOptionsBuilder<T> optionsBuilder;

  // The default way to convert an option to a string.
  static String _defaultStringForOption(dynamic option) {
    return option.toString();
  }

  @override
  _RawAutocompleteState<T> createState() => _RawAutocompleteState<T>();
}

class _RawAutocompleteState<T extends Object> extends State<RawAutocomplete<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _optionsLayerLink = LayerLink();
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Iterable<T> _options = Iterable<T>.empty();
  T? _selection;

  // The OverlayEntry containing the options.
  OverlayEntry? _floatingOptions;

  // True iff the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    return _focusNode.hasFocus && _selection == null && _options.isNotEmpty;
  }

  // Called when _textEditingController changes.
  void _onChangedField() {
    final Iterable<T> options = widget.optionsBuilder(
      _textEditingController.value,
    );
    _options = options;
    if (_selection != null
        && _textEditingController.text != widget.displayStringForOption(_selection!)) {
      _selection = null;
    }
    _updateOverlay();
  }

  // Called when the field's FocusNode changes.
  void _onChangedFocus() {
    _updateOverlay();
  }

  // Called from fieldViewBuilder when the user submits the field.
  void _onFieldSubmitted() {
    if (_options.isEmpty) {
      return;
    }
    _select(_options.first);
  }

  // Select the given option and update the widget.
  void _select(T nextSelection) {
    if (nextSelection == _selection) {
      return;
    }
    _selection = nextSelection;
    final String selectionString = widget.displayStringForOption(nextSelection);
    _textEditingController.value = TextEditingValue(
      selection: TextSelection.collapsed(offset: selectionString.length),
      text: selectionString,
    );
    widget.onSelected?.call(_selection!);
  }

  // Hide or show the options overlay, if needed.
  void _updateOverlay() {
    if (_shouldShowOptions) {
      _floatingOptions?.remove();
      _floatingOptions = OverlayEntry(
        builder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _optionsLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            child: widget.optionsViewBuilder(context, _select, _options),
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
    _focusNode.addListener(_onChangedFocus);
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void didUpdateWidget(RawAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onChangedField);
    _focusNode.removeListener(_onChangedFocus);
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
        child: widget.fieldViewBuilder(
          context,
          _textEditingController,
          _focusNode,
          _onFieldSubmitted,
        ),
      ),
    );
  }
}
