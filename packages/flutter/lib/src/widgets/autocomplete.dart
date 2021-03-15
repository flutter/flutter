// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
///
///   * [RawAutocomplete.optionsBuilder], which is of this type.
typedef AutocompleteOptionsBuilder<T extends Object> = Iterable<T> Function(TextEditingValue textEditingValue);

/// The type of the callback used by the [RawAutocomplete] widget to indicate
/// that the user has selected an option.
///
/// See also:
///
///   * [RawAutocomplete.onSelected], which is of this type.
typedef AutocompleteOnSelected<T extends Object> = void Function(T option);

/// The type of the [RawAutocomplete] callback which returns a [Widget] that
/// displays the specified [options] and calls [onSelected] if the user
/// selects an option.
///
/// See also:
///
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
///
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
///
///   * [RawAutocomplete.displayStringForOption], which is of this type.
typedef AutocompleteOptionToString<T extends Object> = String Function(T option);

// TODO(justinmc): Mention AutocompleteCupertino when it is implemented.
/// {@template flutter.widgets.RawAutocomplete.RawAutocomplete}
/// A widget for helping the user make a selection by entering some text and
/// choosing from among a list of options.
///
/// The user's text input is received in a field built with the
/// [fieldViewBuilder] parameter. The options to be displayed are determined
/// using [optionsBuilder] and rendered with [optionsViewBuilder].
/// {@endtemplate}
///
/// This is a core framework widget with very basic UI.
///
/// {@tool dartpad --template=freeform}
/// This example shows how to create a very basic autocomplete widget using the
/// [fieldViewBuilder] and [optionsViewBuilder] parameters.
///
/// ```dart main
/// import 'package:flutter/material.dart';
/// import 'package:flutter/widgets.dart';
///
/// void main() => runApp(const AutocompleteExampleApp());
///
/// class AutocompleteExampleApp extends StatelessWidget {
///   const AutocompleteExampleApp({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         appBar: AppBar(
///           title: const Text('RawAutocomplete Basic'),
///         ),
///         body: const Center(
///           child: AutocompleteBasicExample(),
///         ),
///       ),
///     );
///   }
/// }
///
/// class AutocompleteBasicExample extends StatelessWidget {
///   const AutocompleteBasicExample({Key? key}) : super(key: key);
///
///   static const List<String> _options = <String>[
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
///             child: SizedBox(
///               height: 200.0,
///               child: ListView.builder(
///                 padding: const EdgeInsets.all(8.0),
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
/// ```dart main
/// import 'package:flutter/material.dart';
/// import 'package:flutter/widgets.dart';
///
/// void main() => runApp(const AutocompleteExampleApp());
///
/// class AutocompleteExampleApp extends StatelessWidget {
///   const AutocompleteExampleApp({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         appBar: AppBar(
///           title: const Text('RawAutocomplete Custom Type'),
///         ),
///         body: const Center(
///           child: AutocompleteCustomTypeExample(),
///         ),
///       ),
///     );
///   }
/// }
///
/// // An example of a type that someone might want to autocomplete a list of.
/// @immutable
/// class User {
///   const User({
///     required this.email,
///     required this.name,
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
///     if (other.runtimeType != runtimeType) {
///       return false;
///     }
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
///   const AutocompleteCustomTypeExample({Key? key}) : super(key: key);
///
///   static const List<User> _userOptions = <User>[
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
///             child: SizedBox(
///               height: 200.0,
///               child: ListView.builder(
///                 padding: const EdgeInsets.all(8.0),
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
/// ```dart main
/// import 'package:flutter/material.dart';
/// import 'package:flutter/widgets.dart';
///
/// void main() => runApp(const AutocompleteExampleApp());
///
/// class AutocompleteExampleApp extends StatelessWidget {
///   const AutocompleteExampleApp({Key? key}) : super(key: key);
///
///   @override
///   Widget build(BuildContext context) {
///     return MaterialApp(
///       home: Scaffold(
///         appBar: AppBar(
///           title: const Text('RawAutocomplete Form'),
///         ),
///         body: const Center(
///           child: AutocompleteFormExample(),
///         ),
///       ),
///     );
///   }
/// }
///
/// class AutocompleteFormExample extends StatefulWidget {
///   const AutocompleteFormExample({Key? key}) : super(key: key);
///
///   @override
///   AutocompleteFormExampleState createState() => AutocompleteFormExampleState();
/// }
///
/// class AutocompleteFormExampleState extends State<AutocompleteFormExample> {
///   final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
///   final TextEditingController _textEditingController = TextEditingController();
///   String? _dropdownValue;
///   String? _autocompleteSelection;
///
///   static const List<String> _options = <String>[
///     'aardvark',
///     'bobcat',
///     'chameleon',
///   ];
///
///   @override
///   Widget build(BuildContext context) {
///     return Form(
///       key: _formKey,
///       child: Column(
///         children: <Widget>[
///           DropdownButtonFormField<String>(
///             value: _dropdownValue,
///             icon: const Icon(Icons.arrow_downward),
///             hint: const Text('This is a regular DropdownButtonFormField'),
///             iconSize: 24,
///             elevation: 16,
///             style: const TextStyle(color: Colors.deepPurple),
///             onChanged: (String? newValue) {
///               setState(() {
///                 _dropdownValue = newValue;
///               });
///             },
///             items: <String>['One', 'Two', 'Free', 'Four']
///                 .map<DropdownMenuItem<String>>((String value) {
///               return DropdownMenuItem<String>(
///                 value: value,
///                 child: Text(value),
///               );
///             }).toList(),
///             validator: (String? value) {
///               if (value == null) {
///                 return 'Must make a selection.';
///               }
///               return null;
///             },
///           ),
///           TextFormField(
///             controller: _textEditingController,
///             decoration: const InputDecoration(
///               hintText: 'This is a regular TextFormField',
///             ),
///             validator: (String? value) {
///               if (value == null || value.isEmpty) {
///                 return 'Can\'t be empty.';
///               }
///               return null;
///             },
///           ),
///           RawAutocomplete<String>(
///             optionsBuilder: (TextEditingValue textEditingValue) {
///               return _options.where((String option) {
///                 return option.contains(textEditingValue.text.toLowerCase());
///               });
///             },
///             onSelected: (String selection) {
///               setState(() {
///                 _autocompleteSelection = selection;
///               });
///             },
///             fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
///               return TextFormField(
///                 controller: textEditingController,
///                 decoration: const InputDecoration(
///                   hintText: 'This is a RawAutocomplete!',
///                 ),
///                 focusNode: focusNode,
///                 onFieldSubmitted: (String value) {
///                   onFieldSubmitted();
///                 },
///                 validator: (String? value) {
///                   if (!_options.contains(value)) {
///                     return 'Nothing selected.';
///                   }
///                   return null;
///                 },
///               );
///             },
///             optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
///               return Align(
///                 alignment: Alignment.topLeft,
///                 child: Material(
///                   elevation: 4.0,
///                   child: SizedBox(
///                     height: 200.0,
///                     child: ListView.builder(
///                       padding: const EdgeInsets.all(8.0),
///                       itemCount: options.length,
///                       itemBuilder: (BuildContext context, int index) {
///                         final String option = options.elementAt(index);
///                         return GestureDetector(
///                           onTap: () {
///                             onSelected(option);
///                           },
///                           child: ListTile(
///                             title: Text(option),
///                           ),
///                         );
///                       },
///                     ),
///                   ),
///                 ),
///               );
///             },
///           ),
///           ElevatedButton(
///             onPressed: () {
///               FocusScope.of(context).requestFocus(new FocusNode());
///               if (!_formKey.currentState!.validate()) {
///                 return;
///               }
///               showDialog<void>(
///                 context: context,
///                 builder: (BuildContext context) {
///                   return AlertDialog(
///                     title: const Text('Successfully submitted'),
///                     content: SingleChildScrollView(
///                       child: ListBody(
///                         children: <Widget>[
///                           Text('DropdownButtonFormField: "$_dropdownValue"'),
///                           Text('TextFormField: "${_textEditingController.text}"'),
///                           Text('RawAutocomplete: "$_autocompleteSelection"'),
///                         ],
///                       ),
///                     ),
///                     actions: <Widget>[
///                       TextButton(
///                         child: const Text('Ok'),
///                         onPressed: () {
///                           Navigator.of(context).pop();
///                         },
///                       ),
///                     ],
///                   );
///                 },
///               );
///             },
///             child: const Text('Submit'),
///           ),
///         ],
///       ),
///     );
///   }
/// }
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [Autocomplete], which is a Material-styled implementation that is based
/// on RawAutocomplete.
class RawAutocomplete<T extends Object> extends StatefulWidget {
  /// Create an instance of RawAutocomplete.
  ///
  /// [displayStringForOption], [optionsBuilder] and [optionsViewBuilder] must
  /// not be null.
  const RawAutocomplete({
    Key? key,
    required this.optionsViewBuilder,
    required this.optionsBuilder,
    this.displayStringForOption = defaultStringForOption,
    this.fieldViewBuilder,
    this.focusNode,
    this.onSelected,
    this.textEditingController,
  }) : assert(displayStringForOption != null),
       assert(
         fieldViewBuilder != null
            || (key != null && focusNode != null && textEditingController != null),
         'Pass in a fieldViewBuilder, or otherwise create a separate field and pass in the FocusNode, TextEditingController, and a key. Use the key with RawAutocomplete.onFieldSubmitted.',
        ),
       assert(optionsBuilder != null),
       assert(optionsViewBuilder != null),
       assert((focusNode == null) == (textEditingController == null)),
       super(key: key);

  /// {@template flutter.widgets.RawAutocomplete.fieldViewBuilder}
  /// Builds the field whose input is used to get the options.
  ///
  /// Pass the provided [TextEditingController] to the field built here so that
  /// RawAutocomplete can listen for changes.
  /// {@endtemplate}
  final AutocompleteFieldViewBuilder? fieldViewBuilder;

  /// The [FocusNode] that is used for the text field.
  ///
  /// {@template flutter.widgets.RawAutocomplete.split}
  /// The main purpose of this parameter is to allow the use of a separate text
  /// field located in another part of the widget tree instead of the text
  /// field built by [fieldViewBuilder]. For example, it may be desirable to
  /// place the text field in the AppBar and the options below in the main body.
  ///
  /// When following this pattern, [fieldViewBuilder] can return
  /// `SizedBox.shrink()` so that nothing is drawn where the text field would
  /// normally be. A separate text field can be created elsewhere, and a
  /// FocusNode and TextEditingController can be passed both to that text field
  /// and to RawAutocomplete.
  ///
  /// {@tool dartpad --template=freeform}
  /// This examples shows how to create an autocomplete widget with the text
  /// field in the AppBar and the results in the main body of the app.
  ///
  /// ```dart main
  /// import 'package:flutter/material.dart';
  /// import 'package:flutter/widgets.dart';
  ///
  /// void main() => runApp(const AutocompleteExampleApp());
  ///
  /// class AutocompleteExampleApp extends StatelessWidget {
  ///   const AutocompleteExampleApp({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return const MaterialApp(
  ///       home: RawAutocompleteSplit(),
  ///     );
  ///   }
  /// }
  ///
  /// const List<String> _options = <String>[
  ///   'aardvark',
  ///   'bobcat',
  ///   'chameleon',
  /// ];
  ///
  /// class RawAutocompleteSplit extends StatefulWidget {
  ///   const RawAutocompleteSplit({Key? key}) : super(key: key);
  ///
  ///   @override
  ///   RawAutocompleteSplitState createState() => RawAutocompleteSplitState();
  /// }
  ///
  /// class RawAutocompleteSplitState extends State<RawAutocompleteSplit> {
  ///   final TextEditingController _textEditingController = TextEditingController();
  ///   final FocusNode _focusNode = FocusNode();
  ///   final GlobalKey _autocompleteKey = GlobalKey();
  ///
  ///   @override
  ///   Widget build(BuildContext context) {
  ///     return Scaffold(
  ///       appBar: AppBar(
  ///         // This is where the real field is being built.
  ///         title: TextFormField(
  ///           controller: _textEditingController,
  ///           focusNode: _focusNode,
  ///           decoration: const InputDecoration(
  ///             hintText: 'Split RawAutocomplete App',
  ///           ),
  ///           onFieldSubmitted: (String value) {
  ///             RawAutocomplete.onFieldSubmitted<String>(_autocompleteKey);
  ///           },
  ///         ),
  ///       ),
  ///       body: Align(
  ///         alignment: Alignment.topLeft,
  ///         child: RawAutocomplete<String>(
  ///           key: _autocompleteKey,
  ///           focusNode: _focusNode,
  ///           textEditingController: _textEditingController,
  ///           optionsBuilder: (TextEditingValue textEditingValue) {
  ///             return _options.where((String option) {
  ///               return option.contains(textEditingValue.text.toLowerCase());
  ///             }).toList();
  ///           },
  ///           optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
  ///             return Material(
  ///               elevation: 4.0,
  ///               child: ListView(
  ///                 children: options.map((String option) => GestureDetector(
  ///                   onTap: () {
  ///                     onSelected(option);
  ///                   },
  ///                   child: ListTile(
  ///                     title: Text(option),
  ///                   ),
  ///                 )).toList(),
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
  /// {@endtemplate}
  ///
  /// If this parameter is not null, then [textEditingController] must also be
  /// not null.
  final FocusNode? focusNode;

  /// {@template flutter.widgets.RawAutocomplete.optionsViewBuilder}
  /// Builds the selectable options widgets from a list of options objects.
  ///
  /// The options are displayed floating below the field using a
  /// [CompositedTransformFollower] inside of an [Overlay], not at the same
  /// place in the widget tree as [RawAutocomplete].
  /// {@endtemplate}
  final AutocompleteOptionsViewBuilder<T> optionsViewBuilder;

  /// {@template flutter.widgets.RawAutocomplete.displayStringForOption}
  /// Returns the string to display in the field when the option is selected.
  ///
  /// This is useful when using a custom T type and the string to display is
  /// different than the string to search by.
  ///
  /// If not provided, will use `option.toString()`.
  /// {@endtemplate}
  final AutocompleteOptionToString<T> displayStringForOption;

  /// {@template flutter.widgets.RawAutocomplete.onSelected}
  /// Called when an option is selected by the user.
  ///
  /// Any [TextEditingController] listeners will not be called when the user
  /// selects an option, even though the field will update with the selected
  /// value, so use this to be informed of selection.
  /// {@endtemplate}
  final AutocompleteOnSelected<T>? onSelected;

  /// {@template flutter.widgets.RawAutocomplete.optionsBuilder}
  /// A function that returns the current selectable options objects given the
  /// current TextEditingValue.
  /// {@endtemplate}
  final AutocompleteOptionsBuilder<T> optionsBuilder;

  /// The [TextEditingController] that is used for the text field.
  ///
  /// {@macro flutter.widgets.RawAutocomplete.split}
  ///
  /// If this parameter is not null, then [focusNode] must also be not null.
  final TextEditingController? textEditingController;

  /// Calls [AutocompleteFieldViewBuilder]'s onFieldSubmitted callback for the
  /// RawAutocomplete widget indicated by the given [GlobalKey].
  ///
  /// This is not typically used unless a custom field is implemented instead of
  /// using [fieldViewBuilder]. In the typical case, the onFieldSubmitted
  /// callback is passed via the [AutocompleteFieldViewBuilder] signature. When
  /// not using fieldViewBuilder, the same callback can be called by using this
  /// static method.
  ///
  /// See also:
  ///
  ///  * [focusNode] and [textEditingController], which contain a code example
  ///    showing how to create a separate field outside of fieldViewBuilder.
  static void onFieldSubmitted<T extends Object>(GlobalKey key) {
    final _RawAutocompleteState<T> rawAutocomplete = key.currentState! as _RawAutocompleteState<T>;
    rawAutocomplete._onFieldSubmitted();
  }

  /// The default way to convert an option to a string in
  /// [displayStringForOption].
  ///
  /// Simply uses the `toString` method on the option.
  static String defaultStringForOption(dynamic option) {
    return option.toString();
  }

  @override
  _RawAutocompleteState<T> createState() => _RawAutocompleteState<T>();
}

class _RawAutocompleteState<T extends Object> extends State<RawAutocomplete<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _optionsLayerLink = LayerLink();
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
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

  // Handle a potential change in textEditingController by properly disposing of
  // the old one and setting up the new one, if needed.
  void _updateTextEditingController(TextEditingController? old, TextEditingController? current) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController.dispose();
      _textEditingController = current!;
    } else if (current == null) {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController = TextEditingController();
    } else {
      _textEditingController.removeListener(_onChangedField);
      _textEditingController = current;
    }
    _textEditingController.addListener(_onChangedField);
  }

  // Handle a potential change in focusNode by properly disposing of the old one
  // and setting up the new one, if needed.
  void _updateFocusNode(FocusNode? old, FocusNode? current) {
    if ((old == null && current == null) || old == current) {
      return;
    }
    if (old == null) {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode.dispose();
      _focusNode = current!;
    } else if (current == null) {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode = FocusNode();
    } else {
      _focusNode.removeListener(_onChangedFocus);
      _focusNode = current;
    }
    _focusNode.addListener(_onChangedFocus);
  }

  @override
  void initState() {
    super.initState();
    _textEditingController = widget.textEditingController ?? TextEditingController();
    _textEditingController.addListener(_onChangedField);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onChangedFocus);
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void didUpdateWidget(RawAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTextEditingController(
      oldWidget.textEditingController,
      widget.textEditingController,
    );
    _updateFocusNode(oldWidget.focusNode, widget.focusNode);
    SchedulerBinding.instance!.addPostFrameCallback((Duration _) {
      _updateOverlay();
    });
  }

  @override
  void dispose() {
    _textEditingController.removeListener(_onChangedField);
    if (widget.textEditingController == null) {
      _textEditingController.dispose();
    }
    _focusNode.removeListener(_onChangedFocus);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
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
        child: widget.fieldViewBuilder == null
            ? const SizedBox.shrink()
            : widget.fieldViewBuilder!(
                context,
                _textEditingController,
                _focusNode,
                _onFieldSubmitted,
              ),
      ),
    );
  }
}
