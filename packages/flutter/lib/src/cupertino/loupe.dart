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
  late Offset _realLoupePosition;

  @override 
  void initState() {
    widget.controller.requestedPosition.addListener(_updateRealLoupePosition);
    _inOutAnimationController = AnimationController(
      value: 0,
      vsync: this,
      duration: const Duration(milliseconds: 75),
    )..addListener(() => setState(() {}));
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
    _inOutAnimationController.dispose();
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
        duration: const Duration(milliseconds: 45),
        curve: Curves.easeOut,
        left: _realLoupePosition.dx,
        top: _realLoupePosition.dy,
        child: Loupe(
          transitionAnimationController: _inOutAnimationController,
          controller: widget.controller,
          focalPoint: Offset(
              0,
              CupertinoLoupe._kVerticalFocalPointOffset -
                  CupertinoLoupe._kLoupeSize.height / 2),
          decoration: ShapeDecoration(
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
        ));
  }
}
