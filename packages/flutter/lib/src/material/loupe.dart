import 'package:flutter/widgets.dart';

/// A Material styled loupe.
/// 
/// These constants were gotten from the Android souce code.
class MaterialLoupe extends StatelessWidget {
  static const kVerticalOffset = -18;

  final LoupeController controller;
  
  
  /// Creates a [Loupe] in the Material style. 
  MaterialLoupe({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
    /*
    return Loupe(
      controller: controller,
      elevation: 4,
      magnificationScale: 1.25,
      focalPoint: const Offset(0, -18),
      //borderRadius: const Radius.circular(36),
      shadowColor: const Color.fromARGB(175, 0, 0, 0),
      size: const Size(100, 48),
      //TODO: child needs to be a gray film
    );
    */
  }
}
