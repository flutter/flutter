import 'package:flutter/widgets.dart';

class CupertinoLoupe extends StatefulWidget {
  final LoupeConfiguration configuration;
  
  
  /// Creates a [Loupe] in the Cupertino style. 
  /// 
  /// This loupe has a small drag delay, meaning the loupe takes
  /// some 
  CupertinoLoupe({
    super.key,
    required this.configuration,
  });

  @override
  State<CupertinoLoupe> createState() => _CupertinoLoupeState();
}

class _CupertinoLoupeState extends State<CupertinoLoupe> {
  //late AnimationController _inOutAnimationController;

  @override 
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Loupe(
      // transitionAnimationController: _inOutAnimationController,
      configuration: widget.configuration,
      elevation: 6,
      verticalOffset: -20,
      border: Border.all(color: const Color.fromARGB(255, 235, 235, 235)),
      borderRadius: const Radius.circular(36),
      shadowColor: const Color.fromARGB(108, 255, 255, 255),
      size: const Size(77.5, 37.5),
      positionAnimation: Curves.easeIn,
      positionAnimationDuration: const Duration(milliseconds: 50),
    );
  }
}
