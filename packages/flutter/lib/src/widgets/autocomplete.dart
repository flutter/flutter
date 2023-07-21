// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'basic.dart';
import 'container.dart';
import 'focus_manager.dart';
import 'framework.dart';
import 'inherited_notifier.dart';
import 'overlay.dart';
import 'shortcuts.dart';
import 'tap_region.dart';

// Examples can assume:
// late BuildContext context;

/// The type of the [RawAutocomplete] callback which returns a [Widget] that
/// displays the specified [options].
/// It should set [controller.selection] when the user selects an option.
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
  RawAutocompleteController<T> controller,
);

/// The type of the Autocomplete callback which returns the widget that
/// contains the input [TextField] or [TextFormField].
///
/// See also:
///
///   * [RawAutocomplete.fieldViewBuilder], which is of this type.
typedef AutocompleteFieldViewBuilder = Widget Function(
  BuildContext context,
  FocusNode focusNode,
);

/// A direction in which to open the options-view overlay.
///
/// See also:
///
///  * [RawAutocomplete.optionsViewOpenDirection], which is of this type.
///  * [RawAutocomplete.optionsViewBuilder] to specify how to build the
///    selectable-options widget.
///  * [RawAutocomplete.fieldViewBuilder] to optionally specify how to build the
///    corresponding field widget.
enum OptionsViewOpenDirection {
  /// Open upward.
  ///
  /// The bottom edge of the options view will align with the top edge
  /// of the text field built by [RawAutocomplete.fieldViewBuilder].
  up,

  /// Open downward.
  ///
  /// The top edge of the options view will align with the bottom edge
  /// of the text field built by [RawAutocomplete.fieldViewBuilder].
  down,
}

/// A controller for a [RawAutocomplete].
class RawAutocompleteController<T extends Object> extends ChangeNotifier {
  /// Creates a controller for a [RawAutocomplete].
  RawAutocompleteController({
    Iterable<T>? options,
    int? highlightedOptionIndex,
    T? selection,
  }) : _options = options ?? Iterable<T>.empty(),
       _highlightedOptionIndexNotifier = ValueNotifier<int>(highlightedOptionIndex ?? 0),
       _selection = selection;

  /// The options.
  Iterable<T> get options => _options;
  Iterable<T> _options;
  /// When [options] is replaced with something
  /// that is not == to the old value, listeners are notified.
  set options(Iterable<T> newOptions) {
    if (_options == newOptions) {
      return;
    }
    _options = newOptions;
    notifyListeners();
  }

  /// The index of the highlighted option.
  int get highlightedOptionIndex => _highlightedOptionIndexNotifier.value;
  final ValueNotifier<int> _highlightedOptionIndexNotifier;
  /// When [highlightedOptionIndex] is replaced with something
  /// that is not == to the old value, listeners are notified.
  set highlightedOptionIndex(int newIndex) {
    if (_highlightedOptionIndexNotifier.value == newIndex) {
      return;
    }
    _highlightedOptionIndexNotifier.value = newIndex;
    notifyListeners();
  }

  /// A [ValueNotifier] for [highlightedOptionIndex].
  ValueNotifier<int> get highlightedOptionIndexNotifier => _highlightedOptionIndexNotifier;

  /// The selected option.
  T? get selection => _selection;
  T? _selection;
  /// When [selection] is replaced with something
  /// that is not == to the old value, listeners are notified.
  set selection(T? newSelection) {
    if (_selection == newSelection) {
      return;
    }
    _selection = newSelection;
    notifyListeners();
  }
}

// TODO(justinmc): Mention AutocompleteCupertino when it is implemented.
/// {@template flutter.widgets.RawAutocomplete.RawAutocomplete}
/// A widget for helping the user make a selection by entering some text and
/// choosing from among a list of options.
///
/// The user's text input is received in a field built with the
/// [fieldViewBuilder] parameter. The options to be displayed are
/// [controller.options] and rendered with [optionsViewBuilder].
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
/// another type. Options will be compared using `==`, so it may be beneficial to override
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
  /// [controller] and [optionsViewBuilder] must not be null.
  const RawAutocomplete({
    super.key,
    required this.controller,
    required this.optionsViewBuilder,
    this.optionsViewOpenDirection = OptionsViewOpenDirection.down,
    this.fieldViewBuilder,
    this.focusNode,
  }) : assert(
         fieldViewBuilder != null
            || (key != null && focusNode != null),
         'Pass in a fieldViewBuilder, or otherwise create a separate field and pass in the FocusNode and a key. Use the key with RawAutocomplete.onFieldSubmitted.',
        );

  /// The controller.
  final RawAutocompleteController<T> controller;

  /// {@template flutter.widgets.RawAutocomplete.fieldViewBuilder}
  /// Builds the field whose input is used to get the options.
  /// {@endtemplate}
  ///
  /// If this parameter is null, then a [SizedBox.shrink] is built instead.
  /// For how that pattern can be useful, see [focusNode].
  final AutocompleteFieldViewBuilder? fieldViewBuilder;

  /// The [FocusNode] that is used for the text field.
  ///
  /// {@template flutter.widgets.RawAutocomplete.split}
  /// The main purpose of this parameter is to allow the use of a separate text
  /// field located in another part of the widget tree instead of the text
  /// field built by [fieldViewBuilder]. For example, it may be desirable to
  /// place the text field in the AppBar and the options below in the main body.
  ///
  /// When following this pattern, [fieldViewBuilder] can be omitted,
  /// so that a text field is not drawn where it would normally be.
  /// A separate text field can be created elsewhere, and a
  /// FocusNode can be passed both to that text field and to RawAutocomplete.
  ///
  /// {@tool dartpad}
  /// This examples shows how to create an autocomplete widget with the text
  /// field in the AppBar and the results in the main body of the app.
  ///
  /// ** See code in examples/api/lib/widgets/autocomplete/raw_autocomplete.focus_node.0.dart **
  /// {@end-tool}
  /// {@endtemplate}
  final FocusNode? focusNode;

  /// {@template flutter.widgets.RawAutocomplete.optionsViewBuilder}
  /// Builds the selectable options widgets from a list of options objects.
  ///
  /// The options are displayed floating below or above the field using a
  /// [CompositedTransformFollower] inside of an [Overlay], not at the same
  /// place in the widget tree as [RawAutocomplete]. To control whether it opens
  /// upward or downward, use [optionsViewOpenDirection].
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

  /// {@template flutter.widgets.RawAutocomplete.optionsViewOpenDirection}
  /// The direction in which to open the options-view overlay.
  ///
  /// Defaults to [OptionsViewOpenDirection.down].
  /// {@endtemplate}
  final OptionsViewOpenDirection optionsViewOpenDirection;

  @override
  State<RawAutocomplete<T>> createState() => _RawAutocompleteState<T>();
}

class _RawAutocompleteState<T extends Object> extends State<RawAutocomplete<T>> {
  final GlobalKey _fieldKey = GlobalKey();
  final LayerLink _optionsLayerLink = LayerLink();
  late FocusNode _focusNode;
  late final Map<Type, Action<Intent>> _actionMap;
  late final _AutocompleteCallbackAction<AutocompletePreviousOptionIntent> _previousOptionAction;
  late final _AutocompleteCallbackAction<AutocompleteNextOptionIntent> _nextOptionAction;
  late final _AutocompleteCallbackAction<DismissIntent> _hideOptionsAction;
  bool _userHidOptions = false;

  static const Map<ShortcutActivator, Intent> _shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowUp): AutocompletePreviousOptionIntent(),
    SingleActivator(LogicalKeyboardKey.arrowDown): AutocompleteNextOptionIntent(),
  };

  // The OverlayEntry containing the options.
  OverlayEntry? _floatingOptions;

  // True iff the state indicates that the options should be visible.
  bool get _shouldShowOptions {
    return !_userHidOptions && _focusNode.hasFocus && widget.controller.selection == null && widget.controller.options.isNotEmpty;
  }

  void _controllerChanged() {
    _updateOverlay();
  }

  // Called when the field's FocusNode changes.
  void _onChangedFocus() {
    // Options should no longer be hidden when the field is re-focused.
    _userHidOptions = !_focusNode.hasFocus;
    _updateActions();
    _updateOverlay();
  }

  void _updateHighlight(int newIndex) {
    widget.controller.highlightedOptionIndex = widget.controller.options.isEmpty ? 0 : newIndex % widget.controller.options.length;
  }

  void _highlightPreviousOption(AutocompletePreviousOptionIntent intent) {
    if (_userHidOptions) {
      _userHidOptions = false;
      _updateActions();
      _updateOverlay();
      return;
    }
    _updateHighlight(widget.controller.highlightedOptionIndex - 1);
  }

  void _highlightNextOption(AutocompleteNextOptionIntent intent) {
    if (_userHidOptions) {
      _userHidOptions = false;
      _updateActions();
      _updateOverlay();
      return;
    }
    _updateHighlight(widget.controller.highlightedOptionIndex + 1);
  }

  Object? _hideOptions(DismissIntent intent) {
    if (!_userHidOptions) {
      _userHidOptions = true;
      _updateActions();
      _updateOverlay();
      return null;
    }
    return Actions.invoke(context, intent);
  }

  void _setActionsEnabled(bool enabled) {
    // The enabled state determines whether the action will consume the
    // key shortcut or let it continue on to the underlying text field.
    // They should only be enabled when the options are showing so shortcuts
    // can be used to navigate them.
    _previousOptionAction.enabled = enabled;
    _nextOptionAction.enabled = enabled;
    _hideOptionsAction.enabled = enabled;
  }

  void _updateActions() {
    _setActionsEnabled(_focusNode.hasFocus && widget.controller.selection == null && widget.controller.options.isNotEmpty);
  }

  bool _floatingOptionsUpdateScheduled = false;
  // Hide or show the options overlay, if needed.
  void _updateOverlay() {
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      if (!_floatingOptionsUpdateScheduled) {
        _floatingOptionsUpdateScheduled = true;
        SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
          _floatingOptionsUpdateScheduled = false;
          _updateOverlay();
        });
      }
      return;
    }

    _floatingOptions?.remove();
    if (_shouldShowOptions) {
      final OverlayEntry newFloatingOptions = OverlayEntry(
        builder: (BuildContext context) {
          return CompositedTransformFollower(
            link: _optionsLayerLink,
            showWhenUnlinked: false,
            targetAnchor: switch (widget.optionsViewOpenDirection) {
              OptionsViewOpenDirection.up => Alignment.topLeft,
              OptionsViewOpenDirection.down => Alignment.bottomLeft,
            },
            followerAnchor: switch (widget.optionsViewOpenDirection) {
              OptionsViewOpenDirection.up => Alignment.bottomLeft,
              OptionsViewOpenDirection.down => Alignment.topLeft,
            },
            child: TextFieldTapRegion(
              child: AutocompleteHighlightedOption(
                highlightIndexNotifier: widget.controller.highlightedOptionIndexNotifier,
                child: Builder(
                  builder: (BuildContext context) {
                    return widget.optionsViewBuilder(context, widget.controller);
                  }
                )
              ),
            ),
          );
        },
      );
      Overlay.of(context, rootOverlay: true, debugRequiredFor: widget).insert(newFloatingOptions);
      _floatingOptions = newFloatingOptions;
    } else {
      _floatingOptions = null;
    }
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
    widget.controller.addListener(_controllerChanged);
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onChangedFocus);
    _previousOptionAction = _AutocompleteCallbackAction<AutocompletePreviousOptionIntent>(onInvoke: _highlightPreviousOption);
    _nextOptionAction = _AutocompleteCallbackAction<AutocompleteNextOptionIntent>(onInvoke: _highlightNextOption);
    _hideOptionsAction = _AutocompleteCallbackAction<DismissIntent>(onInvoke: _hideOptions);
    _actionMap = <Type, Action<Intent>> {
      AutocompletePreviousOptionIntent: _previousOptionAction,
      AutocompleteNextOptionIntent: _nextOptionAction,
      DismissIntent: _hideOptionsAction,
    };
    _updateActions();
    _updateOverlay();
  }

  @override
  void didUpdateWidget(RawAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateFocusNode(oldWidget.focusNode, widget.focusNode);
    _updateActions();
    _updateOverlay();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_controllerChanged);
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
    return TextFieldTapRegion(
      child: Container(
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
                    _focusNode,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AutocompleteCallbackAction<T extends Intent> extends CallbackAction<T> {
  _AutocompleteCallbackAction({
    required super.onInvoke,
    this.enabled = true,
  });

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
/// int highlightedIndex = AutocompleteHighlightedOption.of(context);
/// ```
///
/// which can then be used to tell which option should be given a visual
/// indication that will be the option selected with the keyboard.
class AutocompleteHighlightedOption extends InheritedNotifier<ValueNotifier<int>> {
  /// Create an instance of AutocompleteHighlightedOption inherited widget.
  const AutocompleteHighlightedOption({
    super.key,
    required ValueNotifier<int> highlightIndexNotifier,
    required super.child,
  }) : super(notifier: highlightIndexNotifier);

  /// Returns the index of the highlighted option from the closest
  /// [AutocompleteHighlightedOption] ancestor.
  ///
  /// If there is no ancestor, it returns 0.
  ///
  /// Typical usage is as follows:
  ///
  /// ```dart
  /// int highlightedIndex = AutocompleteHighlightedOption.of(context);
  /// ```
  static int of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AutocompleteHighlightedOption>()?.notifier?.value ?? 0;
  }
}
