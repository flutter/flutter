import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable HoverBuilder widget that handles hover detection, cursor change,
/// and allows dynamic building of UI based on the hover state.
///
/// Can be used in Flutter Web/Desktop apps.
class HoverBuilder extends StatefulWidget {
  /// The builder function which gives access to the `isHovered` state.
  final Widget Function(BuildContext context, bool isHovered) builder;

  /// Optional mouse cursor to show when hovering.
  final MouseCursor cursor;

  /// Optional callback triggered when the mouse enters the widget.
  final VoidCallback? onEnter;

  /// Optional callback triggered when the mouse exits the widget.
  final VoidCallback? onExit;

  /// Optional callback triggered when the mouse hovers over the widget.
  final VoidCallback? onHover;

  /// Whether to show default cursor when not hovered (default: true)
  final bool useDefaultCursor;

  const HoverBuilder({
    super.key,
    required this.builder,
    this.cursor = SystemMouseCursors.click,
    this.onEnter,
    this.onExit,
    this.onHover,
    this.useDefaultCursor = true,
  });

  @override
  State<HoverBuilder> createState() => _HoverBuilderState();
}

class _HoverBuilderState extends State<HoverBuilder> {
  bool isHovered = false;

  void _handleEnter(PointerEnterEvent event) {
    setState(() => isHovered = true);
    if (widget.onEnter != null) widget.onEnter!();
  }

  void _handleExit(PointerExitEvent event) {
    setState(() => isHovered = false);
    if (widget.onExit != null) widget.onExit!();
  }

  void _handleHover(PointerHoverEvent event) {
    if (widget.onHover != null) widget.onHover!();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: _handleEnter,
      onExit: _handleExit,
      onHover: _handleHover,
      cursor:
          isHovered
              ? widget.cursor
              : (widget.useDefaultCursor ? SystemMouseCursors.basic : MouseCursor.defer),
      child: widget.builder(context, isHovered),
    );
  }
}
