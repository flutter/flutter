import 'dart:ui' show Offset;

import 'package:flutter/rendering.dart';

import 'framework.dart';
import 'gesture_detector.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';

typedef ContextualMenuBuilder = Widget Function(BuildContext, Offset);

// TODO(justinmc): Figure out all the platforms and nested packages.
// Should a CupertinoTextField on Android show the iOS toolbar?? It seems to now
// before this PR.
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

class ContextualMenuArea extends StatefulWidget {
  const ContextualMenuArea({
    Key? key,
    required this.buildMenu,
    required this.child,
  }) : super(key: key);

  final ContextualMenuBuilder buildMenu;
  final Widget child;

  @override
  State<ContextualMenuArea> createState() => _ContextualMenuAreaState();
}

class _ContextualMenuAreaState extends State<ContextualMenuArea> {
  ContextualMenuController? _contextualMenuController;

  void _onSecondaryTapUp(TapUpDetails details) {
    _contextualMenuController?.dispose();
    _contextualMenuController = ContextualMenuController(
      anchor: details.globalPosition,
      context: context,
      buildMenu: widget.buildMenu,
    );
  }

  void _onTap() {
    _disposeContextualMenu();
  }

  void _disposeContextualMenu() {
    _contextualMenuController?.dispose();
    _contextualMenuController = null;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _disposeContextualMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // TODO(justinmc): Secondary tapping when the menu is open should fade out
      // and then fade in to show again at the new location.
      onSecondaryTapUp: _onSecondaryTapUp,
      onTap: _contextualMenuController == null ? null : _onTap,
      child: widget.child,
    );
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
    required Offset anchor,
    required BuildContext context,
    Widget? debugRequiredFor
  }) {
    _insert(context, anchor, buildMenu, debugRequiredFor);
  }

  OverlayEntry? _menuOverlayEntry;

  // Insert the ContextualMenu into the given OverlayState.
  void _insert(BuildContext context, Offset anchor, ContextualMenuBuilder buildMenu, [Widget? debugRequiredFor]) {
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
            //child: capturedThemes.wrap(contextualMenuConfiguration.buildMenu(context, anchor)),
            child: capturedThemes.wrap(buildMenu(context, anchor)),
          ),
        );
      },
    );
    overlayState!.insert(_menuOverlayEntry!);
  }

  bool get isVisible => _menuOverlayEntry != null;

  void dispose() {
    _menuOverlayEntry?.remove();
    _menuOverlayEntry = null;
  }
}
