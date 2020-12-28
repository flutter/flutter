import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A [Shortcuts] widget with the shortcuts used for the default text editing
/// behavior.
///
/// See also:
///
///  * [textEditingActionsMap], which contains all of the actions that respond
///    to the [Intent]s in these shortcuts with the default text editing
///    behavior.
class TextEditingShortcuts extends StatelessWidget {
  /// Creates an instance of TextEditingShortcuts.
  const TextEditingShortcuts({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// The child [Widget].
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowLeftTextIntent(
          context: context,
        ),
      },
      child: child,
    );
  }
}
