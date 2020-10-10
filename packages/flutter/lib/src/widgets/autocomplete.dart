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
///   * [AutocompleteCore.optionsBuilder], which is of this type.
typedef AutocompleteOptionsBuilder<T extends Object> = Iterable<T> Function(TextEditingValue textEditingValue);

/// A type for indicating the selection of an autocomplete option.
///
/// See also:
///   * [AutocompleteCore.onSelected], which is of this type.
typedef AutocompleteOnSelected<T extends Object> = void Function(T? option);

/// A builder for the selectable options given the current autocomplete field
/// value.
///
/// See also:
///   * [AutocompleteCore.optionsViewBuilder], which is of this type.
typedef AutocompleteOptionsViewBuilder<T extends Object> = Widget Function(
  BuildContext context,
  AutocompleteOnSelected<T> onSelected,
  Iterable<T> options,
);

/// A builder for the field in autocomplete.
///
/// See also:
///   * [AutocompleteCore.optionsFieldBuilder], which is of this type.
typedef AutocompleteFieldViewBuilder = Widget Function(
  BuildContext context,
  TextEditingController textEditingController,
  VoidCallback onFieldSubmitted,
);

/// A type for getting a String from some option.
///
/// See also:
///   * [AutocompleteCore.displayStringForOption], which is of this type.
typedef AutocompleteOptionToString<T extends Object> = String Function(T option);

// TODO(justinmc): Mention Autocomplete and AutocompleteCupertino when they are
// implemented.
/// A widget for helping the user make a selection by entering some text and
/// choosing from among a list of options.
///
/// This is a core framework widget with very basic UI. Try using Autocomplete
/// or AutocompleteCupertino before resorting to this widget.
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
///   final List<String> _kOptions = <String>[
///     'aardvark',
///     'bobcat',
///     'chameleon',
///   ];
///
///   @override
///   Widget build(BuildContext context) {
///     return AutocompleteCore<String>(
///       optionsBuilder: (TextEditingValue textEditingValue) {
///         return _kOptions.where((String option) {
///           return option.contains(textEditingValue.text.toLowerCase());
///         });
///       },
///       fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///         return TextFormField(
///           controller: textEditingController,
///           onFieldSubmitted: (String value) {
///             onFieldSubmitted();
///           },
///         );
///       },
///       optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
///         return Material(
///           elevation: 4.0,
///           child: Container(
///             height: 200.0,
///             child: ListView.builder(
///               padding: EdgeInsets.all(8.0),
///               itemCount: options.length,
///               itemBuilder: (BuildContext context, int index) {
///                 final String option = options.elementAt(index);
///                 return GestureDetector(
///                   onTap: () {
///                     onSelected(option);
///                   },
///                   child: ListTile(
///                     title: Text(option),
///                   ),
///                 );
///               },
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
///   // The displayStringForOption parameter can be used to get even more
///   // control over the strings that represent the options objects.
///   @override
///   String toString() {
///     return '$name, $email';
///   }
/// }
///
/// class AutocompleteCustomTypeExample extends StatelessWidget {
///   AutocompleteCustomTypeExample({Key key});
///
///   final List<User> _kUserOptions = <User>[
///     User(name: 'Alice', email: 'alice@example.com'),
///     User(name: 'Bob', email: 'bob@example.com'),
///     User(name: 'Charlie', email: 'charlie123@gmail.com'),
///   ];
///
///   static String _displayStringForOption(User option) => option.name;
///
///   @override
///   Widget build(BuildContext context) {
///     return AutocompleteCore<User>(
///       optionsBuilder: (TextEditingValue textEditingValue) {
///         return _kUserOptions.where((User option) {
///           return option.toString().contains(textEditingValue.text.toLowerCase());
///         });
///       },
///       displayStringForOption: _displayStringForOption,
///       fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///         return TextFormField(
///           controller: textEditingController,
///           onFieldSubmitted: (String value) {
///             onFieldSubmitted();
///           },
///         );
///       },
///       optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<User> onSelected, Iterable<User> options) {
///         return SizedBox(
///           height: 200.0,
///           child: Material(
///             elevation: 4.0,
///             child: ListView(
///               padding: EdgeInsets.all(8.0),
///               children: options.map((User option) => GestureDetector(
///                 onTap: () {
///                   onSelected(option);
///                 },
///                 child: ListTile(
///                   title: Text(_displayStringForOption(option)),
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
/// This example shows the use of AutocompleteCore in a form.
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
///   final List<String> _kOptions = <String>[
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
///               AutocompleteCore<String>(
///                 optionsBuilder: (TextEditingValue textEditingValue) {
///                   return _kOptions.where((String option) {
///                     return option.contains(textEditingValue.text.toLowerCase());
///                   });
///                 },
///                 onSelected: (String selection) {
///                   setState(() {
///                     _autocompleteSelection = selection;
///                   });
///                 },
///                 fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, VoidCallback onFieldSubmitted) {
///                   return TextFormField(
///                     controller: textEditingController,
///                     decoration: InputDecoration(
///                       hintText: 'This is an AutocompleteCore!',
///                     ),
///                     onFieldSubmitted: (String value) {
///                       onFieldSubmitted();
///                     },
///                     validator: (String value) {
///                       if (!_kOptions.contains(value)) {
///                         return 'Nothing selected.';
///                       }
///                       return null;
///                     },
///                   );
///                 },
///                 optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
///                   return Material(
///                     elevation: 4.0,
///                     child: SizedBox(
///                       height: 200.0,
///                       child: ListView(
///                         padding: EdgeInsets.all(8.0),
///                         children: options.map((String option) => GestureDetector(
///                           onTap: () {
///                             onSelected(option);
///                           },
///                           child: ListTile(
///                             title: Text(option),
///                           ),
///                         )).toList(),
///                       ),
///                     ),
///                   );
///                 },
///               ),
///               RaisedButton(
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
///                               Text('AutocompleteCore: "$_autocompleteSelection"'),
///                             ],
///                           ),
///                         ),
///                         actions: <Widget>[
///                           FlatButton(
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
class AutocompleteCore<T extends Object> extends StatefulWidget {
  /// Create an instance of AutocompleteCore.
  ///
  /// [fieldViewBuilder] and [optionsViewBuilder] must not be null.
  const AutocompleteCore({
    required this.fieldViewBuilder,
    required this.optionsViewBuilder,
    required this.optionsBuilder,
    this.displayStringForOption = _defaultStringForOption,
    this.onSelected,
  }) : assert(fieldViewBuilder != null),
       assert(optionsViewBuilder != null);

  /// Builds the field whose input is used to get the options.
  final AutocompleteFieldViewBuilder fieldViewBuilder;

  /// Builds the selectable options widgets from a list of options objects.
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
  /// [TextEditingController.onChanged] will not be called when the user selects
  /// an option, even though the field will update with the selected value, so
  /// use this to be informed of selection.
  final AutocompleteOnSelected<T>? onSelected;

  /// A function that returns the current selectable options objects given the
  /// current TextEditingValue.
  final AutocompleteOptionsBuilder<T> optionsBuilder;

  // The default way to convert an option to a string.
  static String _defaultStringForOption(dynamic option) {
    return option.toString();
  }

  @override
  _AutocompleteCoreState<T> createState() => _AutocompleteCoreState<T>();
}

class _AutocompleteCoreState<T extends Object> extends State<AutocompleteCore<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _optionsLayerLink = LayerLink();
  final TextEditingController _textEditingController = TextEditingController();
  Iterable<T> _options = Iterable<T>.empty();
  T? _selection;

  // The OverlayEntry containing the options.
  OverlayEntry? _floatingOptions;

  // True iff the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    final TextSelection selection = _textEditingController.selection;
    final bool fieldIsFocused = selection.baseOffset >= 0
        && selection.extentOffset >= 0;
    final bool hasOptions = _options.isNotEmpty;
    return fieldIsFocused && _selection == null && hasOptions;
  }

  // Called when _textEditingController changes.
  void _onChangedField() {
    final Iterable<T> options = widget.optionsBuilder(
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

  // Called from fieldViewBuilder when the user submits the field.
  void _onFieldSubmitted() {
    if (_options.isEmpty) {
      return;
    }
    _select(_options.first);
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
      final RenderBox renderBox = context.findRenderObject()! as RenderBox;
      _floatingOptions?.remove();
      _floatingOptions = OverlayEntry(
        builder: (BuildContext context) {
          return _FloatingOptions<T>(
            optionsViewBuilder: widget.optionsViewBuilder,
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
        child: widget.fieldViewBuilder(
          context,
          _textEditingController,
          _onFieldSubmitted,
        ),
      ),
    );
  }
}

// The floating options, meant to be built inside of an Overlay. Will position
// itself at the bottom of the field indicated by layerLink and fieldSize.
class _FloatingOptions<T extends Object> extends StatelessWidget {
  const _FloatingOptions({
    Key? key,
    required this.optionsViewBuilder,
    required this.fieldSize,
    required this.layerLink,
    required this.onSelected,
    required this.options,
  }) : assert(optionsViewBuilder != null),
       assert(fieldSize != null),
       assert(layerLink != null),
       assert(onSelected != null),
       assert(options != null),
       super(key: key);

  final AutocompleteOptionsViewBuilder<T> optionsViewBuilder;
  final Size fieldSize;
  final LayerLink layerLink;
  final AutocompleteOnSelected<T> onSelected;
  final Iterable<T> options;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: fieldSize.width,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        targetAnchor: Alignment.bottomLeft,
        child: optionsViewBuilder(context, onSelected, options),
      ),
    );
  }
}
