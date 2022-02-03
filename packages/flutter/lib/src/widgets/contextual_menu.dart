import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'overlay.dart';
import 'routes.dart';

const Duration _kContextualMenuDuration = Duration.zero;

late OverlayEntry _menuOverlayEntry;

// TODO(justinmc): Document. Maybe return Future<T>.
/// Shows a [ContextualMenu] at the given location.
void showContextualMenu(BuildContext context, [Widget? debugRequiredFor]) {
  // TODO(justinmc): Should I create a default menu here if no ContextualMenuConfiguration?
  final OverlayState? overlayState = Overlay.of(
    context,
    rootOverlay: true,
    debugRequiredFor: debugRequiredFor,
  );
  final ContextualMenuConfiguration contextualMenuConfiguration =
    ContextualMenuConfiguration.of(context);
  final CapturedThemes capturedThemes = InheritedTheme.capture(
    from: context,
    to: Navigator.of(context).context,
  );
  _menuOverlayEntry = OverlayEntry(
    builder: (BuildContext context) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _menuOverlayEntry.remove,
        onSecondaryTap: _menuOverlayEntry.remove,
        // TODO(justinmc): I'm using this to block taps on the menu from being
        // received by the above barrier. Is there a less weird way?
        child: GestureDetector(
          onTap: () {},
          onSecondaryTap: () {},
          child: capturedThemes.wrap(contextualMenuConfiguration.buildMenu(context)),
        ),
      );
    },
  );
  overlayState!.insert(_menuOverlayEntry);
}

typedef ContextualMenuBuilder = Widget Function(BuildContext);

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
