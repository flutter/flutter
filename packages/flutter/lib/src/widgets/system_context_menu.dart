import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'context_menu_controller.dart';
import 'framework.dart';
import 'placeholder.dart';

/// Displays the system context menu on top of the Flutter view.
///
/// Currently, only supports iOS and builds nothing on other platforms.
class SystemContextMenu extends StatefulWidget {
  SystemContextMenu({
    super.key,
    required RenderBox renderBox,
    required double startGlyphHeight,
    required double endGlyphHeight,
    required List<TextSelectionPoint> selectionEndpoints,
  }) : _selectionRect = _getSelectionRect(
         renderBox,
         startGlyphHeight,
         endGlyphHeight,
         selectionEndpoints,
       );

    final Rect _selectionRect;

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
    ContextMenuController.removeAny();

    ContextMenu.showSystemContextMenu(widget._selectionRect);
  }

  @override
  void didUpdateWidget(SystemContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    print('justin didupdate ${oldWidget._selectionRect}');
    if (widget._selectionRect != oldWidget._selectionRect) {
      ContextMenu.showSystemContextMenu(widget._selectionRect);
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

