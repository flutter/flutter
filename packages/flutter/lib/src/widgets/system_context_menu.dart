import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'text_selection_toolbar_anchors.dart';

/// Displays the system context menu on top of the Flutter view.
///
/// Currently, only supports iOS and displays nothing on other platforms.
class SystemContextMenu extends StatefulWidget {
  /// Creates an instance of [SystemContextMenu] that points to the given
  /// [anchor].
  const SystemContextMenu._({
    super.key,
    required this.anchor,
  });

  /// Creates an instance of [SystemContextMenu] for the field indicated by the
  /// given [EditableTextState].
  factory SystemContextMenu.editableText({
    Key? key,
    required EditableTextState editableTextState,
  }) {
    final (
      startGlyphHeight: double startGlyphHeight,
      endGlyphHeight: double endGlyphHeight,
    ) = editableTextState.getGlyphHeights();
    return SystemContextMenu._(
      key: key,
      anchor: TextSelectionToolbarAnchors.getSelectionRect(
        editableTextState.renderEditable,
        startGlyphHeight,
        endGlyphHeight,
        editableTextState.renderEditable.getEndpointsForSelection(
          editableTextState.textEditingValue.selection,
        ),
      ),
    );
  }

  /// The [Rect] that the context menu should point to.
  final Rect anchor;

  @override
  State<SystemContextMenu> createState() => _SystemContextMenuState();
}

class _SystemContextMenuState extends State<SystemContextMenu> {
  @override
  void initState() {
    super.initState();
    // TODO(justinmc): This whole pattern of being tied to a widget is a little
    // confusing, because the user may dismiss the menu by tapping, but this
    // widget has no idea, and there's no good way to reshow the menu after
    // that. Also, building two of this widget will result in confusing
    // behavior.
    ContextMenu.showSystemContextMenu(widget.anchor);
  }

  @override
  void didUpdateWidget(SystemContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.anchor != oldWidget.anchor) {
      ContextMenu.showSystemContextMenu(widget.anchor);
    }
  }

  @override
  void dispose() {
    print('justin dispose');
    ContextMenu.hideSystemContextMenu();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
