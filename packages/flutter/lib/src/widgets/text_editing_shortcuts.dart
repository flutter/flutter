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
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): ArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): ArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowLeft): AltArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.arrowRight): AltArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowLeft): ControlArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.arrowRight): ControlArrowRightTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA): ControlATextIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC): ControlCTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyC): MetaCTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowLeft): ShiftArrowLeftTextIntent(),
        LogicalKeySet(LogicalKeyboardKey.shift, LogicalKeyboardKey.arrowRight): ShiftArrowRightTextIntent(),
      },
      child: child,
    );
  }
}
