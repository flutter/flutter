import 'dart:ui' show Offset;

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'gesture_detector.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';

/// A function that builds a widget to use as a contextual menu.
typedef ContextualMenuBuilder = Widget Function(BuildContext, Offset, Offset?);

// TODO(justinmc): Figure out all the platforms and nested packages.
// Should a CupertinoTextField on Android show the iOS toolbar?? It seems to now
// before this PR.
/*
class ContextualMenuConfiguration extends InheritedWidget {
  const ContextualMenuConfiguration({
    Key? key,
    required this.buildMenu,
    required Widget child,
  }) : super(key: key, child: child);

  final ContextualMenuBuilder buildMenu;

  /// Get the [ContextualMenuConfiguration] that applies to the given
  /// [BuildContext].
  static ContextualMenuConfiguration of(BuildContext context) {
    final ContextualMenuConfiguration? result = context.dependOnInheritedWidgetOfExactType<ContextualMenuConfiguration>();
    assert(result != null, 'No ContextualMenuConfiguration found in context.');
    return result!;
  }

  @override
  bool updateShouldNotify(ContextualMenuConfiguration old) => buildMenu != old.buildMenu;
}
*/

/// Designates a part of the Widget tree to have the contextual menu given by
/// [buildMenu].
class ContextualMenuArea extends StatefulWidget {
  const ContextualMenuArea({
    Key? key,
    required this.buildMenu,
    required this.child,
  }) : super(key: key);

  final ContextualMenuBuilder buildMenu;
  final Widget child;

  // TODO(justinmc): Another option would be to return ContextualMenuController
  // but make it so that it exists even when the overlay isn't shown.
  /// Returns the nearest [ContextualMenuController] for the given
  /// [BuildContext], if any.
  static ContextualMenuAreaState? of(BuildContext context) {
    return context.findAncestorStateOfType<ContextualMenuAreaState>();
  }

  @override
  State<ContextualMenuArea> createState() => ContextualMenuAreaState();
}

class ContextualMenuAreaState extends State<ContextualMenuArea> {
  ContextualMenuController? _contextualMenuController;

  bool get contextualMenuIsVisible => _contextualMenuController != null;

  // TODO(justinmc): This kills any existing menu then creates a new one. Is
  // that ok? Do I ever need to move an existing menu?
  void showContextualMenu(Offset primaryAnchor, [Offset? secondaryAnchor]) {
    _contextualMenuController?.dispose();
    _contextualMenuController = ContextualMenuController(
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      context: context,
      buildMenu: widget.buildMenu,
    );
  }

  void disposeContextualMenu() {
    _contextualMenuController?.dispose();
    _contextualMenuController = null;
  }

  @override
  void dispose() {
    disposeContextualMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// TODO(justinmc): Ok public? Put in own file?
class ContextualMenuController {
  // TODO(justinmc): Pass in the anchor, and pass it through to buildMenu.
  // What other fields would I need to pass in to buildMenu? There are a ton on
  // buildToolbar...
  // Also, create an update method.
  ContextualMenuController({
    // TODO(justinmc): Accept these or just BuildContext?
    required ContextualMenuBuilder buildMenu,
    required Offset primaryAnchor,
    required BuildContext context,
    Offset? secondaryAnchor,
    Widget? debugRequiredFor
  }) {
    _insert(
      context: context,
      buildMenu: buildMenu,
      primaryAnchor: primaryAnchor,
      secondaryAnchor: secondaryAnchor,
      debugRequiredFor: debugRequiredFor,
    );
  }

  OverlayEntry? _menuOverlayEntry;

  // Insert the ContextualMenu into the given OverlayState.
  void _insert({
    required ContextualMenuBuilder buildMenu,
    required BuildContext context,
    required Offset primaryAnchor,
    Offset? secondaryAnchor,
    Widget? debugRequiredFor,
  }) {
    final OverlayState? overlayState = Overlay.of(
      context,
      rootOverlay: true,
      debugRequiredFor: debugRequiredFor,
    );
    // TODO(justinmc): Should I create a default menu here if no ContextualMenuConfiguration?
    /*
    final ContextualMenuConfiguration contextualMenuConfiguration =
      ContextualMenuConfiguration.of(context);
      */
    final CapturedThemes capturedThemes = InheritedTheme.capture(
      from: context,
      to: Navigator.of(context).context,
    );

    _menuOverlayEntry = OverlayEntry(
      builder: (BuildContext context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: dispose,
          onSecondaryTap: dispose,
          // TODO(justinmc): I'm using this to block taps on the menu from being
          // received by the above barrier. Is there a less weird way?
          child: GestureDetector(
            onTap: () {},
            onSecondaryTap: () {},
            child: capturedThemes.wrap(buildMenu(context, primaryAnchor, secondaryAnchor)),
          ),
        );
      },
    );
    overlayState!.insert(_menuOverlayEntry!);
  }

  /// True iff the menu is currently being displayed.
  bool get isVisible => _menuOverlayEntry != null;

  /// Remove the menu.
  void dispose() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }
}
