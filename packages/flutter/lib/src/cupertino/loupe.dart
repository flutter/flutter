import 'package:flutter/widgets.dart';


/// A [Loupe] in the Cupertino style. 
/// 
/// Control the position and display status of [CupertinoLoupe]
/// through a given [LoupeController]. 
/// 
/// [CupertinoLoupe] is a wrapper around [Loupe], handling
/// positioning, animations, as well as syling.
/// 
/// See also:
/// * [Loupe], the backing implementation.
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
  });
  // These constants were eyeballed on an iPhone XR iOS v15.5.
  static const double _kVerticalFocalPointOffset = -20;
  static const Size _kLoupeSize = Size(77.5, 37.5);
  static const Duration _kDragAnimationDuration = Duration(milliseconds: 45);
  static const Duration _kIoAnimationDuration = Duration(milliseconds: 150);

  /// This [Loupe]'s controller.
  final LoupeController controller;

  @override
  State<CupertinoLoupe> createState() => _CupertinoLoupeState();
}

class _CupertinoLoupeState extends State<CupertinoLoupe>
    with SingleTickerProviderStateMixin {
  late AnimationController _ioAnimationController;
  late Animation<double> _ioAnimation;
  late Offset _realLoupePosition;

  @override 
  void initState() {
    widget.controller.requestedPosition.addListener(_updateRealLoupePosition);
    _ioAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: CupertinoLoupe._kIoAnimationDuration,
    )..addListener(() => setState(() {}));

    _ioAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ioAnimationController, curve: Curves.easeOut));

    super.initState();
  }

  @override
  void didChangeDependencies() {
    _updateRealLoupePosition();
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    widget.controller.requestedPosition
        .removeListener(_updateRealLoupePosition);
    _ioAnimationController.dispose();
    super.dispose();
  }

  void _updateRealLoupePosition() {
    final Offset requestedLoupeFocalPoint =
        widget.controller.requestedPosition.value;

    final Offset rawLoupePosition = requestedLoupeFocalPoint -
        Offset(
            CupertinoLoupe._kLoupeSize.width / 2,
            CupertinoLoupe._kLoupeSize.height -
                CupertinoLoupe._kVerticalFocalPointOffset);

    final Offset adjustedLoupePosition = LoupeController.shiftWithinBounds(
      bounds: Offset.zero & MediaQuery.of(context).size,
      rect: rawLoupePosition & CupertinoLoupe._kLoupeSize,
    ).topLeft;

    setState(() {
      _realLoupePosition = adjustedLoupePosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
        duration: CupertinoLoupe._kDragAnimationDuration,
        curve: Curves.easeOut,
        left: _realLoupePosition.dx,
        top: _realLoupePosition.dy,
        child: Transform.translate(
            offset: Offset.lerp(
                const Offset(0, -CupertinoLoupe._kVerticalFocalPointOffset),
                Offset.zero,
                _ioAnimation.value,)!,
            child: Loupe(
              transitionAnimationController: _ioAnimationController,
              controller: widget.controller,
              focalPoint: Offset(
                  0,
                  (CupertinoLoupe._kVerticalFocalPointOffset -
                      CupertinoLoupe._kLoupeSize.height / 2) * _ioAnimation.value),
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
