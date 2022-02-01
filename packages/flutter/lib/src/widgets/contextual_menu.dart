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
  );
  // TODO(justinmc): I think for mobile we would need a way to show this that's
  // not a separate route, because it's still possible to tap things behind the
  // contextual menu, unlike desktop.
  navigator.push(toolbarRoute);
}

class _ContextualMenuRoute extends PopupRoute<void> {
  _ContextualMenuRoute({
    required this.capturedThemes,
  });

  final CapturedThemes capturedThemes;
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
      // TODO(justinmc): Instead of this, bring in CupertinoTextSelectionToolbar.
      Center(
        child: Container(
          width: 100,
          height: 100,
          color: const Color(0xff8888ff),
          child: const Text('Im a menu!'),
        ),
      ),
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
