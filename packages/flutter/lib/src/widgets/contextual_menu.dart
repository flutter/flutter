import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'container.dart';
import 'framework.dart';
import 'inherited_theme.dart';
import 'navigator.dart';
import 'routes.dart';
import 'text.dart';

const Duration _kContextualMenuDuration = Duration.zero;

// TODO(justinmc): Document. Maybe return Future<T>.
/// Shows a [ContextualMenu] at the given location.
void showContextualMenu(BuildContext context) {
  final NavigatorState navigator = Navigator.of(context);
  final _ContextualMenuRoute toolbarRoute = _ContextualMenuRoute(
    capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
    // TODO(justinmc): Should I create a default menu here if no ContextualMenuConfiguration?
    contextualMenuConfiguration: ContextualMenuConfiguration.of(context),
  );
  // TODO(justinmc): I think for mobile we would need a way to show this that's
  // not a separate route, because it's still possible to tap things behind the
  // contextual menu, unlike desktop.
  navigator.push(toolbarRoute);
}

class _ContextualMenuRoute extends PopupRoute<void> {
  _ContextualMenuRoute({
    required this.capturedThemes,
    required this.contextualMenuConfiguration,
  });

  final CapturedThemes capturedThemes;
  final ContextualMenuConfiguration contextualMenuConfiguration;
  //final List<_MenuItem<T>> items;

  @override
  Duration get transitionDuration => _kContextualMenuDuration;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => null;

  // TODO(justinmc): Maybe pass this through from implementer. Like:
  // MaterialLocalizations.of(context).modalBarrierDismissLabel;
  @override
  final String? barrierLabel = null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {

    return capturedThemes.wrap(
      contextualMenuConfiguration.buildMenu(context),
    );
  }

  /*
  void _dismiss() {
    if (isActive) {
      navigator?.removeRoute(this);
    }
  }
  */
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
