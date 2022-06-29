import 'package:flutter/widgets.dart';

class CupertinoLoupe extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Loupe(
      configuration: configuration,
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
