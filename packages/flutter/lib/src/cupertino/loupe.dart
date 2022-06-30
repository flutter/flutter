import 'package:flutter/widgets.dart';

class CupertinoLoupe extends StatefulWidget {
  static const double _kVerticalFocalPointOffset = -20;
  static const Size _kLoupeSize = Size(77.5, 37.5);

  final LoupeController controller;

  /// Creates a [Loupe] in the Cupertino style.
  ///
  /// This loupe has a small drag delay, meaning the loupe takes
  /// some 
  CupertinoLoupe({
    super.key,
    required this.controller,
  });

  @override
  State<CupertinoLoupe> createState() => _CupertinoLoupeState();
}

class _CupertinoLoupeState extends State<CupertinoLoupe>
    with SingleTickerProviderStateMixin {
  late AnimationController _inOutAnimationController;
  late Offset _realLoupePosition = widget.controller.requestedPosition.value;

  @override 
  void initState() {
    widget.controller.requestedPosition.addListener(_updateRealLoupePosition);
    _inOutAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    super.initState();
  }

  @override
  void dispose() {
    widget.controller.requestedPosition
        .removeListener(_updateRealLoupePosition);
    _inOutAnimationController.dispose();
    super.dispose();
  }

  void _updateRealLoupePosition() {
    final Offset bottomCenterRawLoupePosition =
        widget.controller.requestedPosition.value;



    // TODO this math can be done w/ alginment so it is more clear
    // Since we want the bottom center of our loupe to be right where the requested
    // position is, create a new rect tha
    final Rect globalLoupeRect =
        (bottomCenterRawLoupePosition & CupertinoLoupe._kLoupeSize).shift(
            Offset(
                -CupertinoLoupe._kLoupeSize.width,
                -(CupertinoLoupe._kLoupeSize.height * 2) +
                    CupertinoLoupe._kVerticalFocalPointOffset));

    final Offset adjustedLoupePosition = LoupeController.shiftWithinBounds(
      bounds: Offset.zero & MediaQuery.of(context).size,
      rect: globalLoupeRect,
    ).bottomCenter;

    setState(() {
      _realLoupePosition = adjustedLoupePosition;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _realLoupePosition.dx,
      top: _realLoupePosition.dy,
      child: Transform.translate(
        offset: Offset(0, -37.5 * (_inOutAnimationController.value - 1)),
        child: Opacity(
          opacity: 0.6,
          child: Loupe(
            transitionAnimationController: _inOutAnimationController,
            controller: widget.controller,
            elevation: 6,
            focalPoint:
                const Offset(0, CupertinoLoupe._kVerticalFocalPointOffset),
            border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
            //borderRadius: const Radius.circular(36),
            shadowColor: const Color.fromARGB(108, 255, 255, 255),
            size: CupertinoLoupe._kLoupeSize,
            positionAnimation: Curves.easeIn,
            positionAnimationDuration: const Duration(milliseconds: 50),
          ),
        ),
      ),
    );
  }
}
