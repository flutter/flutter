import 'package:flutter/widgets.dart';

/// A Material styled loupe.
/// 
/// These constants were gotten from the Android souce code.
class MaterialLoupe extends StatelessWidget {
  final ValueNotifier<Offset> position;
  
  
  /// Creates a [Loupe] in the Material style. 
  MaterialLoupe({
    super.key,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return Loupe(
      position: position,
      elevation: 4,
      magnificationScale: 1.25,
      verticalOffset: -18,
      borderRadius: const Radius.circular(36),
      shadowColor: Color.fromARGB(175, 0, 0, 0),
      size: const Size(100, 48),
    );
  }
}
