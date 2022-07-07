import 'package:flutter/widgets.dart';


/// A CupertinoLoupe, specifically for text editing.
/// 
/// Delegates styling to [CupertinoLoupe], but is positioned depending on
/// [loupeSelectionOverlayInfoBearer]. 
/// 
/// Specifically, the text editing loupe positions itself at the vertical center of the 
/// line the text editing handle is on, with some vertical tolerance. There are only global
/// constraints on the X axis based on the screen width, minus some threshold. This means
/// that the loupe positions itself exactly at the X of the touchpoint, but not off the screen.
class CupertinoTextEditingLoupe extends StatefulWidget {
  final LoupeController controller;
  final ValueNotifier<LoupeSelectionOverlayInfoBearer> loupeSelectionOverlayInfoBearer;

  const CupertinoTextEditingLoupe({
    super.key,
    required this.controller,
    required this.loupeSelectionOverlayInfoBearer
  });

  @override
  State<CupertinoTextEditingLoupe> createState() => _CupertinoTextEditingLoupeState();
}

class _CupertinoTextEditingLoupeState extends State<CupertinoTextEditingLoupe> {
  late Offset _currentAdjustedLoupePosition;

  @override
  void initState() {
    widget.loupeSelectionOverlayInfoBearer.addListener(_determineLoupePositionAndFocalPoint);
    super.initState();
  }

  @override
  void dispose() {
        widget.loupeSelectionOverlayInfoBearer
        .removeListener(_determineLoupePositionAndFocalPoint);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    _determineLoupePositionAndFocalPoint();
    super.didChangeDependencies();
  }


  void _determineLoupePositionAndFocalPoint() {
    final Offset requestedLoupeFocalPoint =
        widget.loupeSelectionOverlayInfoBearer.value.globalGesturePosition;

    final Offset rawLoupePosition = requestedLoupeFocalPoint -
        Offset(
            CupertinoLoupe._kLoupeSize.width / 2,
            CupertinoLoupe._kLoupeSize.height -
                CupertinoLoupe._kVerticalFocalPointOffset);

    final Rect screenRect = Offset.zero & MediaQuery.of(context).size;

    final Offset adjustedLoupePosition = LoupeController.shiftWithinBounds(
      bounds: Rect.fromLTRB(
          screenRect.left + CupertinoLoupe._horizontalScreenEdgePadding,
          screenRect.top,
          screenRect.right - CupertinoLoupe._horizontalScreenEdgePadding,
          screenRect.bottom),
      rect: rawLoupePosition & CupertinoLoupe._kLoupeSize,
    ).topLeft;

    setState(() {
      _currentAdjustedLoupePosition = adjustedLoupePosition;
    });
  }



  @override
  Widget build(BuildContext context) {
    return CupertinoLoupe(
      controller: widget.controller,
      position: _currentAdjustedLoupePosition,
    );
  }
}


/// A [Loupe] in the Cupertino style.
///
/// Control the position and display status of [CupertinoLoupe]
/// through a given [LoupeController].
///
/// [CupertinoLoupe] is a wrapper around [Loupe] that handles styling 
/// and trasitions. 
///
/// See also:
/// * [Loupe], the backing implementation.
/// * [CupertinoTextEditingLoupe], a widget that positions [CupertinoLoupe] based on 
/// [LoupeSelectionOverlayInfoBearer]. 
/// * [LoupeController], the controller for this loupe.
class CupertinoLoupe extends StatefulWidget {
  /// Creates a [Loupe] in the Cupertino style.
  ///
  /// This loupe has a small drag delay and remains within the bounds of
  /// [MediaQuery]'s size. This means that when this loupe is repositioned through
  /// [controller.requestedPosition], [CupertinoLoupe] may not position itself exactly
  /// at the requestedPosition immediately, or at all if any part of the loupe is determined
  /// to be out of bounds.
  ///
  /// The bounds shift is determined by [LoupeController.shiftWithinBounds], where the loupe
  /// is shifted within the bounds of the screen size.
  const CupertinoLoupe({
    super.key,
    required this.controller,
    required this.position,
  });
  // These constants were eyeballed on an iPhone XR iOS v15.5.
  static const double _kVerticalFocalPointOffset = -20;
  static const Size _kLoupeSize = Size(77.5, 37.5);
  static const Duration _kDragAnimationDuration = Duration(milliseconds: 45);
  static const Duration _kIoAnimationDuration = Duration(milliseconds: 150);
  static const double _horizontalScreenEdgePadding = 10;

  /// This [Loupe]'s controller.
  final LoupeController controller;

  /// The position of this [Loupe].
  /// 
  /// This position may not be precise, due to [CupertinoLoupe] having 
  /// a small drag delay (of [Duration] [_kDragAnimationDuration]).
  final Offset position;

  @override
  State<CupertinoLoupe> createState() => _CupertinoLoupeState();
}

class _CupertinoLoupeState extends State<CupertinoLoupe>
    with SingleTickerProviderStateMixin {
  late AnimationController _ioAnimationController;
  late Animation<double> _ioAnimation;

  @override 
  void initState() {
    _ioAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: CupertinoLoupe._kIoAnimationDuration,
    )..addListener(() => setState(() {}));

    _ioAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
        CurvedAnimation(parent: _ioAnimationController, curve: Curves.easeOut));

    super.initState();
  }

  @override
  void dispose() {
    _ioAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
        duration: CupertinoLoupe._kDragAnimationDuration,
        curve: Curves.easeOut,
        left: widget.position.dx,
        top: widget.position.dy,
        child: Transform.translate(
            offset: Offset.lerp(
              const Offset(0, -CupertinoLoupe._kVerticalFocalPointOffset),
              Offset.zero,
              _ioAnimation.value,
            )!,
            child: Loupe(
              transitionAnimationController: _ioAnimationController,
              controller: widget.controller,
              focalPoint: Offset(
                  0,
                  (CupertinoLoupe._kVerticalFocalPointOffset -
                          CupertinoLoupe._kLoupeSize.height / 2) *
                      _ioAnimation.value),
              decoration: LoupeDecoration(
                opacity: _ioAnimation.value,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(36),
                    side: const BorderSide(
                        color: Color.fromARGB(255, 235, 235, 235))),
                shadows: const <BoxShadow>[
                  BoxShadow(
                      color: Color.fromARGB(34, 0, 0, 0),
                      blurRadius: 5,
                      spreadRadius: 0.2,
                      offset: Offset(0, 3))
                ],
              ),
              size: CupertinoLoupe._kLoupeSize,
            )));
  }
}
