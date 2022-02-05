// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'basic.dart';
import 'container.dart';
import 'editable_text.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'inherited_notifier.dart';
import 'overlay.dart';
import 'shortcuts.dart';

/// The type of the [RawAutocomplete] callback which computes the list of
/// optional completions for the widget's field, based on the text the user has
/// entered so far.
///
/// See also:
///
///   * [RawAutocomplete.optionsBuilder], which is of this type.
typedef AutocompleteOptionsBuilder<T extends Object> = FutureOr<Iterable<T>> Function(TextEditingValue textEditingValue);

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
/// The returned widget from this callback will be wrapped in an
/// [AutocompleteHighlightedOption] inherited widget. This will allow
/// this callback to determine which option is currently highlighted for
/// keyboard navigation.
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
/// {@tool dartpad}
/// This example shows how to create a very basic autocomplete widget using the
/// [fieldViewBuilder] and [optionsViewBuilder] parameters.
///
/// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.0.dart **
/// {@end-tool}
///
/// The type parameter T represents the type of the options. Most commonly this
/// is a String, as in the example above. However, it's also possible to use
/// another type with a `toString` method, or a custom [displayStringForOption].
/// Options will be compared using `==`, so it may be beneficial to override
/// [Object.==] and [Object.hashCode] for custom types.
///
/// {@tool dartpad}
/// This example is similar to the previous example, but it uses a custom T data
/// type instead of directly using String.
///
/// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.1.dart **
/// {@end-tool}
///
/// {@tool dartpad}
/// This example shows the use of RawAutocomplete in a form.
///
/// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.2.dart **
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
    this.initialValue,
  }) : assert(displayStringForOption != null),
       assert(
         fieldViewBuilder != null
            || (key != null && focusNode != null && textEditingController != null),
         'Pass in a fieldViewBuilder, or otherwise create a separate field and pass in the FocusNode, TextEditingController, and a key. Use the key with RawAutocomplete.onFieldSubmitted.',
        ),
       assert(optionsBuilder != null),
       assert(optionsViewBuilder != null),
       assert((focusNode == null) == (textEditingController == null)),
       assert(
         !(textEditingController != null && initialValue != null),
         'textEditingController and initialValue cannot be simultaneously defined.',
       ),
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
  /// {@tool dartpad}
  /// This examples shows how to create an autocomplete widget with the text
  /// field in the AppBar and the results in the main body of the app.
  ///
  /// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.focus_node.0.dart **
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
  ///
  /// In order to track which item is highlighted by keyboard navigation, the
  /// resulting options will be wrapped in an inherited
  /// [AutocompleteHighlightedOption] widget.
  /// Inside this callback, the index of the highlighted option can be obtained
  /// from [AutocompleteHighlightedOption.of] to display the highlighted option
  /// with a visual highlight to indicate it will be the option selected from
  /// the keyboard.
  ///
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

  /// {@template flutter.widgets.RawAutocomplete.initialValue}
  /// The initial value to use for the text field.
  /// {@endtemplate}
  ///
  /// Setting the initial value does not notify [textEditingController]'s
  /// listeners, and thus will not cause the options UI to appear.
  ///
  /// This parameter is ignored if [textEditingController] is defined.
  final TextEditingValue? initialValue;

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
  State<RawAutocomplete<T>> createState() => _RawAutocompleteState<T>();
}

class _RawAutocompleteState<T extends Object> extends State<RawAutocomplete<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _optionsLayerLink = LayerLink();
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  late final Map<Type, Action<Intent>> _actionMap;
  late final _AutocompleteCallbackAction<AutocompletePreviousOptionIntent> _previousOptionAction;
  late final _AutocompleteCallbackAction<AutocompleteNextOptionIntent> _nextOptionAction;
  Iterable<T> _options = Iterable<T>.empty();
  T? _selection;
  final ValueNotifier<int> _highlightedOptionIndex = ValueNotifier<int>(0);

  static const Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): AutocompletePreviousOptionIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): AutocompleteNextOptionIntent(),
  };

  // The OverlayEntry containing the options.
  OverlayEntry? _floatingOptions;

  // True iff the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    return _focusNode.hasFocus && _selection == null && _options.isNotEmpty;
  }

  // Called when _textEditingController changes.
  Future<void> _onChangedField() async {
    final Iterable<T> options = await widget.optionsBuilder(
      _textEditingController.value,
    );
    _options = options;
    _updateHighlight(_highlightedOptionIndex.value);
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
    _select(_options.elementAt(_highlightedOptionIndex.value));
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

  void _updateHighlight(int newIndex) {
    _highlightedOptionIndex.value = _options.isEmpty ? 0 : newIndex % _options.length;
  }

  void _highlightPreviousOption(AutocompletePreviousOptionIntent intent) {
    _updateHighlight(_highlightedOptionIndex.value - 1);
  }

  void _highlightNextOption(AutocompleteNextOptionIntent intent) {
    _updateHighlight(_highlightedOptionIndex.value + 1);
  }

  void _setActionsEnabled(bool enabled) {
    // The enabled state determines whether the action will consume the
    // key shortcut or let it continue on to the underlying text field.
    // They should only be enabled when the options are showing so shortcuts
    // can be used to navigate them.
    _previousOptionAction.enabled = enabled;
    _nextOptionAction.enabled = enabled;
  }

  // Hide or show the options overlay, if needed.
  void _updateOverlay() {
    _setActionsEnabled(_shouldShowOptions);
    if (_shouldShowOptions) {
      _floatingOptions?.remove();
      _floatingOptions = OverlayEntry(
        builder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _optionsLayerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomLeft,
            child: AutocompleteHighlightedOption(
              highlightIndexNotifier: _highlightedOptionIndex,
              child: Builder(
                builder: (BuildContext context) {
                  return widget.optionsViewBuilder(context, _select, _options);
                }
              )
            ),
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
    _textEditingController = widget.textEditingController ?? TextEditingController.fromValue(widget.initialValue);
    _textEditingController.addListener(_onChangedField);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onChangedFocus);
    _previousOptionAction = _AutocompleteCallbackAction<AutocompletePreviousOptionIntent>(onInvoke: _highlightPreviousOption);
    _nextOptionAction = _AutocompleteCallbackAction<AutocompleteNextOptionIntent>(onInvoke: _highlightNextOption);
    _actionMap = <Type, Action<Intent>> {
      AutocompletePreviousOptionIntent: _previousOptionAction,
      AutocompleteNextOptionIntent: _nextOptionAction,
    };
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
      child: Shortcuts(
        shortcuts: _shortcuts,
        child: Actions(
          actions: _actionMap,
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
        ),
      ),
    );
  }
}

class _AutocompleteCallbackAction<T extends Intent> extends CallbackAction<T> {
  _AutocompleteCallbackAction({
    required OnInvokeCallback<T> onInvoke,
    this.enabled = true,
  }) : super(onInvoke: onInvoke);

  bool enabled;

  @override
  bool isEnabled(covariant T intent) => enabled;

  @override
  bool consumesKey(covariant T intent) => enabled;
}

/// An [Intent] to highlight the previous option in the autocomplete list.
class AutocompletePreviousOptionIntent extends Intent {
  /// Creates an instance of AutocompletePreviousOptionIntent.
  const AutocompletePreviousOptionIntent();
}

/// An [Intent] to highlight the next option in the autocomplete list.
class AutocompleteNextOptionIntent extends Intent {
  /// Creates an instance of AutocompleteNextOptionIntent.
  const AutocompleteNextOptionIntent();
}

/// An inherited widget used to indicate which autocomplete option should be
/// highlighted for keyboard navigation.
///
/// The `RawAutoComplete` widget will wrap the options view generated by the
/// `optionsViewBuilder` with this widget to provide the highlighted option's
/// index to the builder.
///
/// In the builder callback the index of the highlighted option can be obtained
/// by using the static [of] method:
///
/// ```dart
/// final highlightedIndex = AutocompleteHighlightedOption.of(context);
/// ```
///
/// which can then be used to tell which option should be given a visual
/// indication that will be the option selected with the keyboard.
class AutocompleteHighlightedOption extends InheritedNotifier<ValueNotifier<int>> {
  /// Create an instance of AutocompleteHighlightedOption inherited widget.
  const AutocompleteHighlightedOption({
    Key? key,
    required ValueNotifier<int> highlightIndexNotifier,
    required Widget child,
  }) : super(key: key, notifier: highlightIndexNotifier, child: child);

  /// Returns the index of the highlighted option from the closest
  /// [AutocompleteHighlightedOption] ancestor.
  ///
  /// If there is no ancestor, it returns 0.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// final highlightedIndex = AutocompleteHighlightedOption.of(context);
  /// ```
  static int of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AutocompleteHighlightedOption>()?.notifier?.value ?? 0;
  }
}
