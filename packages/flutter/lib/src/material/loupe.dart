import 'package:flutter/widgets.dart';

/// A Material styled loupe.
/// 
/// These constants were gotten from the Android souce code.
class MaterialLoupe extends StatelessWidget {
  final LoupeConfiguration configuration;
  
  
  /// Creates a [Loupe] in the Material style. 
  MaterialLoupe({
    super.key,
    required this.configuration,
  });

  @override
  Widget build(BuildContext context) {
    return Loupe(
      configuration: configuration,
      elevation: 4,
      magnificationScale: 1.25,
      verticalOffset: -18,
      borderRadius: const Radius.circular(36),
      shadowColor: const Color.fromARGB(175, 0, 0, 0),
      size: const Size(100, 48),
    );
  }
}
