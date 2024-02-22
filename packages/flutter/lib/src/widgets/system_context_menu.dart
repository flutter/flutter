import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'editable_text.dart';
import 'framework.dart';

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
      anchor: _getSelectionRect(
        editableTextState.renderEditable,
        startGlyphHeight,
        endGlyphHeight,
        editableTextState.renderEditable.getEndpointsForSelection(editableTextState.textEditingValue.selection),
      ),
    );
  }

  /// The [Rect] that the context menu should point to.
  final Rect anchor;

  // TODO(justinmc): Deduplicate logic with TextSelectionToolbarAnchors.fromSelection?
  static Rect _getSelectionRect(
    RenderBox renderBox,
    double startGlyphHeight,
    double endGlyphHeight,
    List<TextSelectionPoint> selectionEndpoints,
  ) {
    final Rect editingRegion = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
    );

    if (editingRegion.left.isNaN || editingRegion.top.isNaN
      || editingRegion.right.isNaN || editingRegion.bottom.isNaN) {
      return Rect.zero;
    }

    final bool isMultiline = selectionEndpoints.last.point.dy - selectionEndpoints.first.point.dy >
        endGlyphHeight / 2;

    return Rect.fromLTRB(
      isMultiline
          ? editingRegion.left
          : editingRegion.left + selectionEndpoints.first.point.dx,
      editingRegion.top + selectionEndpoints.first.point.dy - startGlyphHeight,
      isMultiline
          ? editingRegion.right
          : editingRegion.left + selectionEndpoints.last.point.dx,
      editingRegion.top + selectionEndpoints.last.point.dy,
    );
  }

  @override
  State<SystemContextMenu> createState() => _SystemContextMenuState();
}

class _SystemContextMenuState extends State<SystemContextMenu> {
  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
